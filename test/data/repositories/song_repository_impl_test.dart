import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexo/core/error/failures.dart';
import 'package:nexo/data/local/app_database.dart';
import 'package:nexo/data/local/mappers/song_mapper.dart';
import 'package:nexo/data/repositories/song_repository_impl.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/entities/song_sort_option.dart';
import 'package:nexo/domain/value_objects/album_id.dart';
import 'package:nexo/domain/value_objects/artist_id.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/value_objects/song_id.dart';

import '../../domain/repositories/fakes/fake_library_folder_repository.dart';

void main() {
  late AppDatabase db;
  late SongRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(setup: (db) {
      db.execute('PRAGMA journal_mode=WAL;');
    }));

    repo = SongRepositoryImpl(
      db,
      coverArtCacheDirectory: '/tmp/nexo_covers',
      libraryFolderRepository: FakeLibraryFolderRepository(),
    );

    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedSong({
    int? id,
    required String artist,
    String? albumId,
    String title = 'Song',
    String path = '/music/song.mp3',
    Duration duration = const Duration(minutes: 3),
  }) async {
    final companion = const SongMapper().toCompanion(
      (Song.create(
        id: SongId(id ?? 0),
        title: title,
        trackArtistId: ArtistId(artist),
        albumId: albumId == null ? null : AlbumId(albumId),
        duration: duration,
        filePath: path,
        format: AudioFormat.mp3,
        fileSizeBytes: 1000,
        dateAddedUtc: DateTime.utc(2026, 1, 1),
      )).valueOrNull!,
    );
    // Use toCompanionForUpsert-style: omit id, let SQLite assign it.
    final insertCompanion = companion.copyWith(id: const Value.absent());
    await db.into(db.songs).insert(insertCompanion);
    final row = await (db.select(db.songs)
          ..where((t) => t.filePath.equals(path)))
        .getSingle();
    return row.id;
  }

  group('read methods (no real audio needed)', () {
    test('getSongById returns Ok for an existing id', () async {
      final id = await seedSong(artist: 'artist-1');
      final result = await repo.getSongById(SongId(id));
      expect(result.valueOrNull?.id.value, id);
    });

    test('getSongById returns NotFoundFailure for a missing id', () async {
      final result = await repo.getSongById(const SongId(99999));
      expect(
        result.when(ok: (_) => null, err: (e) => e),
        isA<NotFoundFailure>(),
      );
    });

    test('getSongsByArtist filters correctly', () async {
      await seedSong(artist: 'artist-1', path: '/music/a.mp3');
      await seedSong(artist: 'artist-2', path: '/music/b.mp3');
      final result =
          await repo.watchSongsByArtist(const ArtistId('artist-1')).first;
      expect(result.valueOrNull?.length, 1);
      expect(result.valueOrNull?.first.filePath, '/music/a.mp3');
    });

    test('searchSongs matches title case-insensitively using FTS5', () async {
      await seedSong(artist: 'artist-1', title: 'Purple Rain');
      final result = await repo.searchSongs('purple');
      expect(result.valueOrNull?.length, 1);
    });

    test('searchSongs also matches by artist using FTS5', () async {
      await seedSong(artist: 'unique artist', path: '/music/a.mp3');
      await seedSong(artist: 'someone else', path: '/music/b.mp3');
      final result = await repo.searchSongs('unique');
      expect(result.valueOrNull?.length, 1);
    });

    test('searchSongs also matches by album using FTS5', () async {
      await seedSong(
          artist: 'artist-1', albumId: 'Purple Album', path: '/music/a.mp3');
      await seedSong(
          artist: 'artist-1', albumId: 'Yellow Album', path: '/music/b.mp3');
      final result = await repo.searchSongs('purple album');
      expect(result.valueOrNull?.length, 1);
    });

    test('getSongsByFolder filters by path prefix using SQL LIKE', () async {
      await seedSong(artist: 'art', path: '/music/jazz/a.mp3');
      await seedSong(artist: 'art', path: '/music/rock/b.mp3');
      final result = await repo.watchSongsByFolder('/music/jazz').first;
      expect(result.valueOrNull?.length, 1);
      expect(result.valueOrNull?.first.filePath, '/music/jazz/a.mp3');
    });

    test('getAllSongs returns every seeded song', () async {
      await seedSong(artist: 'artist-1', path: '/music/a.mp3');
      await seedSong(artist: 'artist-2', path: '/music/b.mp3');
      final result = await repo.getAllSongs();
      expect(result.valueOrNull?.length, 2);
    });

    test('getAllSongs sorts by duration descending via SQLite', () async {
      await seedSong(
          artist: 'a',
          duration: const Duration(minutes: 2),
          path: '/music/a.mp3');
      await seedSong(
          artist: 'a',
          duration: const Duration(minutes: 5),
          path: '/music/b.mp3');
      final result = await repo.getAllSongs(
        sortOption: SongSortOption.duration,
        isAscending: false,
      );
      expect(result.valueOrNull?.first.duration, const Duration(minutes: 5));
    });
  });
}
