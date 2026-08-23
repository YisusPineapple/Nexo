import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../value_objects/queue_id.dart';
import 'queue_source.dart';
import 'repeat_mode.dart';
import 'song.dart';

/// An ordered, playable list of songs plus the state needed to play
/// through it: current position, repeat behavior, and (optionally) a
/// true-shuffle order.
///
/// PlaybackQueue is an Entity: identity is [id], not the songs it
/// currently holds. This matters because the app supports up to five
/// simultaneous queues (REPRODUCCIÓN §2) — the UI needs to tell queue
/// #2 apart from queue #3 even if, by coincidence, they hold the same
/// songs in the same order at some moment.
///
/// Crossfade and playback speed are deliberately NOT modeled here.
/// The spec describes them as engine-wide behaviors, not per-queue
/// ones, so they live on [PlaybackSettings] instead (introduced
/// alongside PlaybackRepository in Sub-fase 1.3).
final class PlaybackQueue {
  const PlaybackQueue._({
    required this.id,
    required this.songs,
    required this.currentIndex,
    required this.repeatMode,
    required this.source,
    required this.shuffleEnabled,
    required this.preShuffleOrder,
    required this.preShuffleCurrentIndex,
  });

  final QueueId id;

  /// Current playback order. While [shuffleEnabled] is true, this is
  /// the shuffled order; the order and index from before shuffling
  /// are preserved separately so turning shuffle off restores them
  /// exactly, without re-deriving anything from song content.
  final List<Song> songs;

  /// Index into [songs] of the currently playing/selected track. -1
  /// when [songs] is empty, OR when a non-empty queue has simply run
  /// out of songs to advance to (RepeatMode.off reaching the end —
  /// see [withAdvancedToNext]). [isEmpty] checks [songs] directly, not
  /// this field, so the two cases stay distinguishable to callers that
  /// need to tell them apart.
  final int currentIndex;

  final RepeatMode repeatMode;
  final QueueSource source;
  final bool shuffleEnabled;

  /// Non-null only while [shuffleEnabled] is true.
  final List<Song>? preShuffleOrder;

  /// Non-null only while [shuffleEnabled] is true. Snapshotted
  /// alongside [preShuffleOrder] so disabling shuffle never has to
  /// re-locate the current song by content — which is provably
  /// ambiguous if the queue contains the same Song twice.
  final int? preShuffleCurrentIndex;

  Song? get currentSong => (currentIndex >= 0 && currentIndex < songs.length)
      ? songs[currentIndex]
      : null;

  bool get isEmpty => songs.isEmpty;

  static Result<PlaybackQueue, Failure> create({
    required QueueId id,
    required List<Song> songs,
    int currentIndex = 0,
    RepeatMode repeatMode = RepeatMode.off,
    required QueueSource source,
  }) {
    if (songs.isNotEmpty &&
        (currentIndex < 0 || currentIndex >= songs.length)) {
      return Err(ValidationFailure(
        'currentIndex $currentIndex is out of bounds for a queue of '
        '${songs.length} songs.',
      ));
    }
    return Ok(PlaybackQueue._(
      id: id,
      songs: List.unmodifiable(songs),
      currentIndex: songs.isEmpty ? -1 : currentIndex,
      repeatMode: repeatMode,
      source: source,
      shuffleEnabled: false,
      preShuffleOrder: null,
      preShuffleCurrentIndex: null,
    ));
  }

  /// Moves the song at [oldIndex] to [newIndex] — the same
  /// oldIndex/newIndex pair Flutter's `ReorderableListView.onReorder`
  /// provides directly. Deliberately positional, not content-based:
  /// an earlier draft tried to re-locate the current song afterward
  /// via `indexOf`, which breaks the moment the queue contains the
  /// same Song twice (a real case — a user can queue the same track
  /// twice on purpose). Tracking the fixed position through the move
  /// arithmetically sidesteps that ambiguity entirely.
  Result<PlaybackQueue, Failure> withSongMoved({
    required int oldIndex,
    required int newIndex,
  }) {
    if (oldIndex < 0 || oldIndex >= songs.length) {
      return Err(ValidationFailure(
        'oldIndex $oldIndex is out of bounds for a queue of '
        '${songs.length} songs.',
      ));
    }
    if (newIndex < 0 || newIndex >= songs.length) {
      return Err(ValidationFailure(
        'newIndex $newIndex is out of bounds for a queue of '
        '${songs.length} songs.',
      ));
    }

    final reordered = List<Song>.of(songs);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    return Ok(PlaybackQueue._(
      id: id,
      songs: List.unmodifiable(reordered),
      currentIndex: _adjustIndexAfterMove(currentIndex, oldIndex, newIndex),
      repeatMode: repeatMode,
      source: source,
      shuffleEnabled: shuffleEnabled,
      preShuffleOrder: preShuffleOrder,
      preShuffleCurrentIndex: preShuffleCurrentIndex,
    ));
  }

  /// Tracks where a fixed position ends up after a single item moves
  /// from [oldIndex] to [newIndex]. Pure index arithmetic — never
  /// compares Song content, so duplicate entries can't confuse it.
  static int _adjustIndexAfterMove(
    int trackedIndex,
    int oldIndex,
    int newIndex,
  ) {
    if (trackedIndex == oldIndex) return newIndex;
    if (oldIndex < trackedIndex && trackedIndex <= newIndex) {
      return trackedIndex - 1;
    }
    if (newIndex <= trackedIndex && trackedIndex < oldIndex) {
      return trackedIndex + 1;
    }
    return trackedIndex;
  }

  /// Enables true shuffle: the ENTIRE queue is reordered once
  /// (REPRODUCCIÓN §2: "Aleatorio verdadero... no aleatorio por
  /// canción"), not re-randomized per track change. Both [shuffled]
  /// and [newCurrentIndex] are supplied by the caller
  /// (ShuffleQueueUseCase, holding the actual RNG and permutation) —
  /// this entity only validates and stores the result. It doesn't try
  /// to re-derive "where did the current song end up" from content,
  /// because that's ambiguous with duplicate songs; the use case that
  /// performs the shuffle already knows the answer directly from its
  /// own permutation.
  Result<PlaybackQueue, Failure> withShuffleEnabled({
    required List<Song> shuffled,
    required int newCurrentIndex,
  }) {
    if (shuffleEnabled) return Ok(this);
    if (shuffled.length != songs.length) {
      return Err(ValidationFailure(
        'Shuffled list must contain the same ${songs.length} songs, '
        'got ${shuffled.length}.',
      ));
    }
    // newCurrentIndex == -1 is accepted even when `shuffled` is
    // non-empty: it means "the queue had already run out of songs to
    // play" (see currentIndex's docs) BEFORE being shuffled, which is
    // a legitimate state to shuffle from — a user can still want to
    // shuffle a queue for next time after it finished playing. Any
    // other negative value, or anything >= shuffled.length, remains
    // rejected as a genuine out-of-bounds error.
    if (shuffled.isNotEmpty &&
        newCurrentIndex != -1 &&
        (newCurrentIndex < 0 || newCurrentIndex >= shuffled.length)) {
      return Err(ValidationFailure(
        'newCurrentIndex $newCurrentIndex is out of bounds for a '
        'shuffled queue of ${shuffled.length} songs.',
      ));
    }
    return Ok(PlaybackQueue._(
      id: id,
      songs: List.unmodifiable(shuffled),
      currentIndex: shuffled.isEmpty ? -1 : newCurrentIndex,
      repeatMode: repeatMode,
      source: source,
      shuffleEnabled: true,
      preShuffleOrder: songs,
      preShuffleCurrentIndex: currentIndex,
    ));
  }

  /// Restores the exact order and index captured before shuffle was
  /// enabled. A no-op if shuffle wasn't enabled.
  PlaybackQueue withShuffleDisabled() {
    if (!shuffleEnabled || preShuffleOrder == null) return this;
    return PlaybackQueue._(
      id: id,
      songs: preShuffleOrder!,
      currentIndex: preShuffleCurrentIndex ?? -1,
      repeatMode: repeatMode,
      source: source,
      shuffleEnabled: false,
      preShuffleOrder: null,
      preShuffleCurrentIndex: null,
    );
  }

  PlaybackQueue withRepeatMode(RepeatMode mode) {
    return PlaybackQueue._(
      id: id,
      songs: songs,
      currentIndex: currentIndex,
      repeatMode: mode,
      source: source,
      shuffleEnabled: shuffleEnabled,
      preShuffleOrder: preShuffleOrder,
      preShuffleCurrentIndex: preShuffleCurrentIndex,
    );
  }

  Result<PlaybackQueue, Failure> withCurrentIndex(int index) {
    if (songs.isEmpty) {
      return const Err(
        ValidationFailure('Cannot set currentIndex on an empty queue.'),
      );
    }
    if (index < 0 || index >= songs.length) {
      return Err(ValidationFailure(
        'currentIndex $index is out of bounds for a queue of '
        '${songs.length} songs.',
      ));
    }
    return Ok(PlaybackQueue._(
      id: id,
      songs: songs,
      currentIndex: index,
      repeatMode: repeatMode,
      source: source,
      shuffleEnabled: shuffleEnabled,
      preShuffleOrder: preShuffleOrder,
      preShuffleCurrentIndex: preShuffleCurrentIndex,
    ));
  }

  /// Computes the next current-song position once the current song
  /// finishes naturally, honoring [repeatMode]:
  /// - [RepeatMode.one]: no-op, the same song plays again.
  /// - Otherwise, advances to the next index; at the end of the list,
  ///   [RepeatMode.all] wraps to 0, while [RepeatMode.off] sets
  ///   currentIndex to -1 (queue finished — see that field's docs).
  ///
  /// Calling this AGAIN on an already-finished (-1) queue wraps back
  /// to song 0 regardless of [repeatMode]. This only happens via an
  /// explicit second call, which in practice means a manual "skip
  /// next" press after the queue stopped — a deliberately different
  /// user action from the natural end-of-song trigger that finished
  /// it, and wrapping there keeps a manual skip from becoming
  /// permanently inert once repeat is off.
  Result<PlaybackQueue, Failure> withAdvancedToNext() {
    if (songs.isEmpty) {
      return const Err(ValidationFailure('Cannot advance an empty queue.'));
    }
    if (repeatMode == RepeatMode.one) {
      return Ok(this);
    }
    final isLastSong = currentIndex == songs.length - 1;
    if (!isLastSong) {
      return withCurrentIndex(currentIndex + 1);
    }
    if (repeatMode == RepeatMode.all) {
      return withCurrentIndex(0);
    }
    // FIX: RepeatMode.off, reached the natural end.
    // Return to index 0 instead of -1 to keep the player open.
    return withCurrentIndex(0);
  }

  /// Symmetric to [withAdvancedToNext] for skipping backward. Unlike
  /// advancing past the end, going backward past the start does NOT
  /// stop the queue even with [RepeatMode.off] — conventionally,
  /// "previous" from the first song just restarts that song, matching
  /// the behavior most media players already give a "previous"
  /// button. From an already-finished (-1) queue, previous resumes at
  /// the last song, since that's the one that was just playing.
  Result<PlaybackQueue, Failure> withAdvancedToPrevious() {
    if (songs.isEmpty) {
      return const Err(ValidationFailure('Cannot advance an empty queue.'));
    }
    if (repeatMode == RepeatMode.one) {
      return Ok(this);
    }
    if (currentIndex < 0) {
      return withCurrentIndex(songs.length - 1);
    }
    final isFirstSong = currentIndex == 0;
    if (!isFirstSong) {
      return withCurrentIndex(currentIndex - 1);
    }
    if (repeatMode == RepeatMode.all) {
      return withCurrentIndex(songs.length - 1);
    }
    return withCurrentIndex(0); // restart the first song
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PlaybackQueue && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
