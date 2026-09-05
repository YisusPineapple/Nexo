import 'package:flutter_test/flutter_test.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/usecases/search_library_usecase.dart';
import 'package:nexo/domain/value_objects/album_id.dart';
import 'package:nexo/domain/value_objects/artist_id.dart';
import 'package:nexo/domain/value_objects/song_id.dart';

import '../repositories/fakes/fake_song_repository.dart';

Song _song(String id, String title, String artist, String album) {
  return Song.create(
    id: SongId(id),
    title: title,
    trackArtistId: ArtistId(artist),
    albumId: AlbumId(album),
    duration: const Duration(minutes: 3),
    filePath: '/music/$id.mp3',
    format: AudioFormat.mp3,
    fileSizeBytes: 1000,
    dateAddedUtc: DateTime.utc(2026, 1, 1),
  ).valueOrNull!;
}

void main() {
  group('SearchLibraryUseCase', () {
    test('returns empty results for empty query', () async {
      final repo = FakeSongRepository();
      final useCase = SearchLibraryUseCase(repo);

      final result = await useCase.call('   ');

      expect(result.isOk, isTrue);
      expect(result.valueOrNull?.songs, isEmpty);
      expect(result.valueOrNull?.artists, isEmpty);
      expect(result.valueOrNull?.albums, isEmpty);
    });

    test('delegates to repository and aggregates results', () async {
      final repo = FakeSongRepository(
        initialSongs: [
          _song('1', 'Purple Rain', 'Prince', 'Purple Rain'),
          _song('2', 'Yellow', 'Coldplay', 'Parachutes'),
        ],
      );
      final useCase = SearchLibraryUseCase(repo);

      final result = await useCase.call('purple');

      expect(result.isOk, isTrue);
      final data = result.valueOrNull!;

      expect(data.songs.map((s) => s.id.value), ['1']);
      expect(data.artists, ['Prince']);
      expect(data.albums, ['Purple Rain']);
    });
  });
}
