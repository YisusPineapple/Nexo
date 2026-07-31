import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexo/core/error/failures.dart';
import 'package:nexo/data/local/app_database.dart';
import 'package:nexo/data/local/mappers/song_mapper.dart';
import 'package:nexo/data/repositories/song_repository_impl.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/value_objects/album_id.dart';
import 'package:nexo/domain/value_objects/artist_id.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/value_objects/song_id.dart';

void main() {
  late AppDatabase db;
  late SongRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = SongRepositoryImpl(db, coverArtCacheDirectory: '/tmp/nexo_covers');
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedSong({
    required String id,
    required String artist,
    String? albumId,
    String title = 'Song',
  }) async {
    await db.into(db.songs).insert(const SongMapper().toCompanion(
          (Song.create(
            id: SongId(id),
            title: title,
            trackArtistId: ArtistId(artist),
            albumId: albumId == null ? null : AlbumId(albumId),
            duration: const Duration(minutes: 3),
            filePath: '/music/$id.mp3',
            format: AudioFormat.mp3,
            fileSizeBytes: 1000,
            dateAddedUtc: DateTime.utc(2026, 1, 1),
          )).valueOrNull!,
        ));
  }

  group('read methods (no real audio needed)', () {
    test('getSongById returns Ok for an existing id', () async {
      await seedSong(id: 's1', artist: 'artist-1');
      final result = await repo.getSongById(const SongId('s1'));
      expect(result.valueOrNull?.id, const SongId('s1'));
    });

    test('getSongById returns NotFoundFailure for a missing id', () async {
      final result = await repo.getSongById(const SongId('missing'));
      expect(
        result.when(ok: (_) => null, err: (e) => e),
        isA<NotFoundFailure>(),
      );
    });

    test('getSongsByArtist filters correctly', () async {
      await seedSong(id: 's1', artist: 'artist-1');
      await seedSong(id: 's2', artist: 'artist-2');
      final result = await repo.getSongsByArtist(const ArtistId('artist-1'));
      expect(result.valueOrNull?.map((s) => s.id.value), ['s1']);
    });

    test('searchSongs matches title case-insensitively', () async {
      await seedSong(id: 's1', artist: 'artist-1', title: 'Purple Rain');
      final result = await repo.searchSongs('purple');
      expect(result.valueOrNull?.length, 1);
    });

    test('getAllSongs returns every seeded song', () async {
      await seedSong(id: 's1', artist: 'artist-1');
      await seedSong(id: 's2', artist: 'artist-2');
      final result = await repo.getAllSongs();
      expect(result.valueOrNull?.length, 2);
    });
  });

  // Uncomment and point this at a real audio file on your machine to
  // exercise the actual scan + tag-reading path — this is the one
  // part of Sub-fase 2.2 that genuinely needs real audio content, not
  // just a real filename, to prove anything.
  //
  // test('indexDirectories reads real tags from disk', () async {
  //   final result = await repo.indexDirectories(['TU_CARPETA_DE_PRUEBA_AQUI']);
  //   expect(result.isOk, isTrue);
  //   final songs = await repo.getAllSongs();
  //   expect(songs.valueOrNull, isNotEmpty);
  // });
}
