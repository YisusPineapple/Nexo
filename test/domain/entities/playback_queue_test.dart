import 'package:test/test.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/entities/playback_queue.dart';
import 'package:nexo/domain/entities/queue_source.dart';
import 'package:nexo/domain/entities/repeat_mode.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/value_objects/artist_id.dart';
import 'package:nexo/domain/value_objects/queue_id.dart';
import 'package:nexo/domain/value_objects/song_id.dart';

Song _song(String id) {
  return Song.create(
    id: SongId(id),
    title: 'Title $id',
    trackArtistId: const ArtistId('artist-1'),
    duration: const Duration(minutes: 3),
    filePath: '/music/$id.mp3',
    format: AudioFormat.mp3,
    fileSizeBytes: 1000,
    dateAddedUtc: DateTime.utc(2026, 1, 1),
  ).valueOrNull!;
}

void main() {
  group('PlaybackQueue.create', () {
    test('defaults currentIndex to -1 for an empty queue', () {
      final result = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: const [],
        source: const ManualQueueSource(),
      );
      expect(result.valueOrNull?.currentIndex, -1);
      expect(result.valueOrNull?.isEmpty, isTrue);
    });

    test('rejects an out-of-bounds currentIndex', () {
      final result = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [_song('a')],
        currentIndex: 5,
        source: const ManualQueueSource(),
      );
      expect(result.isErr, isTrue);
    });

    test('currentSong returns the song at currentIndex', () {
      final a = _song('a');
      final b = _song('b');
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [a, b],
        currentIndex: 1,
        source: const ManualQueueSource(),
      ).valueOrNull!;

      expect(queue.currentSong, b);
    });
  });

  group('PlaybackQueue.withSongMoved', () {
    test('moves a song forward and shifts a tracked index correctly', () {
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [_song('a'), _song('b'), _song('c')],
        currentIndex: 1, // b
        source: const ManualQueueSource(),
      ).valueOrNull!;

      // Move `a` (index 0) to the end (index 2).
      final moved = queue.withSongMoved(oldIndex: 0, newIndex: 2).valueOrNull!;

      expect(moved.songs.map((s) => s.id.value), ['b', 'c', 'a']);
      expect(moved.currentIndex, 0); // b shifted left from 1 to 0
    });

    test('moves a song backward and shifts a tracked index correctly', () {
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [_song('a'), _song('b'), _song('c')],
        currentIndex: 1, // b
        source: const ManualQueueSource(),
      ).valueOrNull!;

      // Move `c` (index 2) to the front (index 0).
      final moved = queue.withSongMoved(oldIndex: 2, newIndex: 0).valueOrNull!;

      expect(moved.songs.map((s) => s.id.value), ['c', 'a', 'b']);
      expect(moved.currentIndex, 2); // b shifted right from 1 to 2
    });

    test('moving the currently-playing song follows it to newIndex', () {
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [_song('a'), _song('b'), _song('c')],
        currentIndex: 0, // a
        source: const ManualQueueSource(),
      ).valueOrNull!;

      final moved = queue.withSongMoved(oldIndex: 0, newIndex: 2).valueOrNull!;

      expect(moved.currentIndex, 2);
      expect(moved.currentSong?.id.value, 'a');
    });

    test('tracks the correct occurrence even with a duplicated song', () {
      final a = _song('dup');
      final b = _song('other');
      // `a` appears twice — a legitimate real-world queue state.
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [a, b, a],
        currentIndex: 2, // the SECOND occurrence of `a`
        source: const ManualQueueSource(),
      ).valueOrNull!;

      final moved = queue.withSongMoved(oldIndex: 1, newIndex: 0).valueOrNull!;

      // A content-matching (indexOf) implementation could snap to
      // the FIRST `a` here; positional tracking must not.
      expect(moved.currentIndex, 2);
    });

    test('rejects an out-of-bounds oldIndex or newIndex', () {
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [_song('a')],
        source: const ManualQueueSource(),
      ).valueOrNull!;

      expect(queue.withSongMoved(oldIndex: 5, newIndex: 0).isErr, isTrue);
      expect(queue.withSongMoved(oldIndex: 0, newIndex: 5).isErr, isTrue);
    });
  });

  group('PlaybackQueue shuffle', () {
    test('withShuffleEnabled snapshots pre-shuffle order and index', () {
      final a = _song('a');
      final b = _song('b');
      final c = _song('c');
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [a, b, c],
        currentIndex: 1, // b
        source: const ManualQueueSource(),
      ).valueOrNull!;

      final shuffled = queue
          .withShuffleEnabled(shuffled: [c, a, b], newCurrentIndex: 2)
          .valueOrNull!;

      expect(shuffled.songs, [c, a, b]);
      expect(shuffled.currentIndex, 2);
      expect(shuffled.shuffleEnabled, isTrue);
    });

    test('withShuffleDisabled restores the exact pre-shuffle state', () {
      final a = _song('a');
      final b = _song('b');
      final c = _song('c');
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [a, b, c],
        currentIndex: 1,
        source: const ManualQueueSource(),
      ).valueOrNull!;

      final shuffled = queue
          .withShuffleEnabled(shuffled: [c, a, b], newCurrentIndex: 2)
          .valueOrNull!;
      final restored = shuffled.withShuffleDisabled();

      expect(restored.songs, [a, b, c]);
      expect(restored.currentIndex, 1);
      expect(restored.shuffleEnabled, isFalse);
    });

    test('withShuffleEnabled rejects a shuffled list of the wrong length',
        () {
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [_song('a'), _song('b')],
        source: const ManualQueueSource(),
      ).valueOrNull!;

      final result = queue.withShuffleEnabled(
        shuffled: [_song('a')],
        newCurrentIndex: 0,
      );
      expect(result.isErr, isTrue);
    });
  });

  group('PlaybackQueue.withRepeatMode / withCurrentIndex', () {
    test('withRepeatMode changes only repeatMode', () {
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [_song('a')],
        source: const ManualQueueSource(),
      ).valueOrNull!;

      final updated = queue.withRepeatMode(RepeatMode.all);

      expect(updated.repeatMode, RepeatMode.all);
      expect(updated.songs, queue.songs);
    });

    test('withCurrentIndex rejects an empty queue', () {
      final queue = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: const [],
        source: const ManualQueueSource(),
      ).valueOrNull!;

      expect(queue.withCurrentIndex(0).isErr, isTrue);
    });
  });

  group('PlaybackQueue equality', () {
    test('two queues with the same id are equal regardless of songs', () {
      final q1 = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [_song('a')],
        source: const ManualQueueSource(),
      ).valueOrNull!;
      final q2 = PlaybackQueue.create(
        id: const QueueId('q1'),
        songs: [_song('b'), _song('c')],
        source: const ManualQueueSource(),
      ).valueOrNull!;

      expect(q1, equals(q2));
    });
  });
}