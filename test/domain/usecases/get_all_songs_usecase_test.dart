import 'package:flutter_test/flutter_test.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/usecases/get_all_songs_usecase.dart';
import 'package:nexo/domain/usecases/use_case.dart';
import 'package:nexo/domain/value_objects/artist_id.dart';
import 'package:nexo/domain/value_objects/song_id.dart';

import '../repositories/fakes/fake_song_repository.dart';

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
  group('GetAllSongsUseCase', () {
    test('delegates to the repository and returns every song', () async {
      final repo = FakeSongRepository(initialSongs: [_song('a'), _song('b')]);
      final useCase = GetAllSongsUseCase(repo);

      final result = await useCase.call(const NoParams());

      expect(result.valueOrNull?.length, 2);
    });
  });
}