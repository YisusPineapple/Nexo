import 'package:flutter_test/flutter_test.dart';

import 'package:nexo/data/local/app_database.dart';
import 'package:nexo/data/local/mappers/playback_queue_mapper.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/entities/queue_source.dart';
import 'package:nexo/domain/entities/repeat_mode.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/value_objects/artist_id.dart';
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
  const mapper = PlaybackQueueMapper();

  test('toEntity rebuilds an unshuffled queue from row + current songs', () {
    final row = PlaybackQueueRow(
      id: 'q1',
      currentIndex: 1,
      repeatMode: RepeatMode.all,
      source: const ManualQueueSource(),
      shuffleEnabled: false,
      preShuffleCurrentIndex: null,
    );
    final songs = [_song('a'), _song('b'), _song('c')];

    final result = mapper.toEntity(row: row, currentSongs: songs);

    expect(result.isOk, isTrue);
    expect(result.valueOrNull?.songs, songs);
    expect(result.valueOrNull?.currentIndex, 1);
    expect(result.valueOrNull?.repeatMode, RepeatMode.all);
    expect(result.valueOrNull?.shuffleEnabled, isFalse);
  });

  test(
      'toEntity rebuilds a shuffled queue with its exact pre-shuffle '
      'snapshot', () {
    final row = PlaybackQueueRow(
      id: 'q1',
      currentIndex: 2,
      repeatMode: RepeatMode.off,
      source: const ManualQueueSource(),
      shuffleEnabled: true,
      preShuffleCurrentIndex: 0,
    );
    final a = _song('a');
    final b = _song('b');
    final c = _song('c');

    final result = mapper.toEntity(
      row: row,
      currentSongs: [c, a, b], // live shuffled order
      preShuffleSongs: [a, b, c], // original order before shuffling
    );

    expect(result.isOk, isTrue);
    final queue = result.valueOrNull!;
    expect(queue.songs.map((s) => s.id.value), ['c', 'a', 'b']);
    expect(queue.currentIndex, 2);
    expect(queue.shuffleEnabled, isTrue);

    final restored = queue.withShuffleDisabled();
    expect(restored.songs.map((s) => s.id.value), ['a', 'b', 'c']);
    expect(restored.currentIndex, 0);
  });

  test('toQueueSongCompanions flattens current and preShuffle lists', () {
    final a = _song('a');
    final b = _song('b');
    final queue = mapper
        .toEntity(
          row: PlaybackQueueRow(
            id: 'q1',
            currentIndex: 0,
            repeatMode: RepeatMode.off,
            source: const ManualQueueSource(),
            shuffleEnabled: false,
            preShuffleCurrentIndex: null,
          ),
          currentSongs: [a, b],
        )
        .valueOrNull!
        .withShuffleEnabled(shuffled: [b, a], newCurrentIndex: 1)
        .valueOrNull!;

    final companions = mapper.toQueueSongCompanions(queue);

    expect(companions.length, 4); // 2 current + 2 preShuffle
    expect(
      companions.where((c) => c.listKind.value == 'current').length,
      2,
    );
    expect(
      companions.where((c) => c.listKind.value == 'preShuffle').length,
      2,
    );
  });
}
