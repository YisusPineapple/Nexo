import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../value_objects/queue_id.dart';
import 'queue_source.dart';
import 'repeat_mode.dart';
import 'song.dart';

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
  final List<Song> songs;
  final int currentIndex;
  final RepeatMode repeatMode;
  final QueueSource source;
  final bool shuffleEnabled;
  final List<Song>? preShuffleOrder;
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

  Result<PlaybackQueue, Failure> withSongAddedNext(Song song) {
    final newSongs = List<Song>.of(songs);
    final insertIndex = (currentIndex >= 0 && currentIndex < songs.length)
        ? currentIndex + 1
        : songs.length;
    newSongs.insert(insertIndex, song);

    List<Song>? newPreShuffle;
    if (shuffleEnabled && preShuffleOrder != null) {
      newPreShuffle = List<Song>.of(preShuffleOrder!);
      final preIndex = (preShuffleCurrentIndex != null &&
              preShuffleCurrentIndex! >= 0 &&
              preShuffleCurrentIndex! < preShuffleOrder!.length)
          ? preShuffleCurrentIndex! + 1
          : preShuffleOrder!.length;
      newPreShuffle.insert(preIndex, song);
    }

    return Ok(PlaybackQueue._(
      id: id,
      songs: List.unmodifiable(newSongs),
      currentIndex: currentIndex < 0 ? 0 : currentIndex,
      repeatMode: repeatMode,
      source: source,
      shuffleEnabled: shuffleEnabled,
      preShuffleOrder:
          newPreShuffle != null ? List.unmodifiable(newPreShuffle) : null,
      preShuffleCurrentIndex: preShuffleCurrentIndex,
    ));
  }

  Result<PlaybackQueue, Failure> withSongAddedLast(Song song) {
    final newSongs = List<Song>.of(songs)..add(song);

    List<Song>? newPreShuffle;
    if (shuffleEnabled && preShuffleOrder != null) {
      newPreShuffle = List<Song>.of(preShuffleOrder!)..add(song);
    }

    return Ok(PlaybackQueue._(
      id: id,
      songs: List.unmodifiable(newSongs),
      currentIndex: currentIndex < 0 ? 0 : currentIndex,
      repeatMode: repeatMode,
      source: source,
      shuffleEnabled: shuffleEnabled,
      preShuffleOrder:
          newPreShuffle != null ? List.unmodifiable(newPreShuffle) : null,
      preShuffleCurrentIndex: preShuffleCurrentIndex,
    ));
  }

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

  Result<PlaybackQueue, Failure> withAdvancedToNext() {
    if (songs.isEmpty) {
      return const Err(ValidationFailure('Cannot advance an empty queue.'));
    }
    if (repeatMode == RepeatMode.one) {
      return Ok(this);
    }
    if (currentIndex < 0) {
      return withCurrentIndex(0);
    }
    final isLastSong = currentIndex == songs.length - 1;
    if (!isLastSong) {
      return withCurrentIndex(currentIndex + 1);
    }
    if (repeatMode == RepeatMode.all) {
      return withCurrentIndex(0);
    }
    return Ok(PlaybackQueue._(
      id: id,
      songs: songs,
      currentIndex: -1,
      repeatMode: repeatMode,
      source: source,
      shuffleEnabled: shuffleEnabled,
      preShuffleOrder: preShuffleOrder,
      preShuffleCurrentIndex: preShuffleCurrentIndex,
    ));
  }

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
    return withCurrentIndex(0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PlaybackQueue && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
