import 'package:flutter_test/flutter_test.dart';
import 'package:nexo/core/error/failures.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/value_objects/album_id.dart';
import 'package:nexo/domain/value_objects/artist_id.dart';
import 'package:nexo/domain/value_objects/song_id.dart';

import 'fakes/fake_song_repository.dart';

Song _song(int id, {ArtistId? artistId, AlbumId? albumId, String? path}) {
  return Song.create(
    id: SongId(id),
    title: 'Title $id',
    trackArtistId: artistId ?? const ArtistId('artist-1'),
    albumId: albumId,
    duration: const Duration(minutes: 3),
    filePath: path ?? '/music/$id.mp3',
    format: AudioFormat.mp3,
    fileSizeBytes: 1000,
    dateAddedUtc: DateTime.utc(2026, 1, 1),
  ).valueOrNull!;
}

void main() {
  group('SongRepository contract (via FakeSongRepository)', () {
    test('getAllSongs returns every seeded song', () async {
      final repo = FakeSongRepository(initialSongs: [_song(1), _song(2)]);
      final result = await repo.getAllSongs();
      expect(result.valueOrNull?.length, 2);
    });

    test('getSongById returns Ok for an existing id', () async {
      final repo = FakeSongRepository(initialSongs: [_song(1)]);
      final result = await repo.getSongById(const SongId(1));
      expect(result.valueOrNull?.id.value, 1);
    });

    test('getSongById returns NotFoundFailure for a missing id', () async {
      final repo = FakeSongRepository(initialSongs: [_song(1)]);
      final result = await repo.getSongById(const SongId(999));
      expect(
        result.when(ok: (_) => null, err: (e) => e),
        isA<NotFoundFailure>(),
      );
    });

    test('watchSongsByArtist filters by ArtistId', () async {
      final repo = FakeSongRepository(initialSongs: [
        _song(1, artistId: const ArtistId('artist-1')),
        _song(2, artistId: const ArtistId('artist-2')),
      ]);
      final result =
          await repo.watchSongsByArtist(const ArtistId('artist-1')).first;
      expect(result.valueOrNull?.map((s) => s.id.value), [1]);
    });

    test('watchSongsByAlbum filters by AlbumId', () async {
      final repo = FakeSongRepository(initialSongs: [
        _song(1, albumId: const AlbumId('album-1')),
        _song(2, albumId: const AlbumId('album-2')),
      ]);
      final result =
          await repo.watchSongsByAlbum(const AlbumId('album-1')).first;
      expect(result.valueOrNull?.map((s) => s.id.value), [1]);
    });

    test('watchSongsByFolder filters by path prefix', () async {
      final repo = FakeSongRepository(initialSongs: [
        _song(1, path: '/music/jazz/a.mp3'),
        _song(2, path: '/music/rock/b.mp3'),
      ]);
      final result = await repo.watchSongsByFolder('/music/jazz').first;
      expect(result.valueOrNull?.map((s) => s.id.value), [1]);
    });

    test('searchSongs matches title case-insensitively', () async {
      final repo = FakeSongRepository(initialSongs: [_song(1)]);
      final result = await repo.searchSongs('title 1');
      expect(result.valueOrNull?.length, 1);
    });

    test('indexDirectories surfaces failure when the fake is set to fail',
        () async {
      final repo = FakeSongRepository()..failIndexing = true;
      final result = await repo.indexDirectories(['/music']);
      expect(result.isErr, isTrue);
    });

    test('refresh surfaces failure when the fake is set to fail', () async {
      final repo = FakeSongRepository()..failIndexing = true;
      final result = await repo.refresh();
      expect(result.isErr, isTrue);
    });
  });
}
