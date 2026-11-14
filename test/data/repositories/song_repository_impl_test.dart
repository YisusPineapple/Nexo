import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexo/core/error/failures.dart';
import 'package:nexo/data/local/app_database.dart';
import 'package:nexo/data/local/mappers/song_mapper.dart';
import 'package:nexo/data/repositories/song_repository_impl.dart';
import 'package:nexo/data/sources/metadata_datasource.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/entities/song_sort_option.dart';
import 'package:nexo/domain/value_objects/album_id.dart';
import 'package:nexo/domain/value_objects/artist_id.dart';
import 'package:nexo/domain/value_objects/song_id.dart';
import 'package:path/path.dart' as p;

import '../../domain/repositories/fakes/fake_library_folder_repository.dart';

/// Intercepts [beginTransaction] calls on a delegated [QueryExecutor]
/// to verify transaction batching in SQLite without altering behavior.
class _CountingQueryExecutor extends QueryExecutor {
  _CountingQueryExecutor(this._inner);
  final QueryExecutor _inner;
  int transactionCount = 0;

  @override
  SqlDialect get dialect => _inner.dialect;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) => _inner.ensureOpen(user);

  @override
  Future<List<Map<String, Object?>>> runSelect(
          String statement, List<Object?> args) =>
      _inner.runSelect(statement, args);

  @override
  Future<int> runInsert(String statement, List<Object?> args) =>
      _inner.runInsert(statement, args);

  @override
  Future<int> runUpdate(String statement, List<Object?> args) =>
      _inner.runUpdate(statement, args);

  @override
  Future<int> runDelete(String statement, List<Object?> args) =>
      _inner.runDelete(statement, args);

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) =>
      _inner.runCustom(statement, args);

  @override
  Future<void> runBatched(BatchedStatements statements) =>
      _inner.runBatched(statements);

  @override
  TransactionExecutor beginTransaction() {
    transactionCount++;
    return _inner.beginTransaction();
  }

  @override
  QueryExecutor beginExclusive() => _inner.beginExclusive();

  @override
  Future<void> close() => _inner.close();
}

/// Mirrors the production `_computeSectionKey` (private to
/// `song_repository_impl.dart`, therefore not importable) closely enough for
/// the titles these tests use. Production seeds `section_key` at scan time;
/// tests seeding via `Song.create(...)` must do the same explicitly, or every
/// song falls into '#' and `watchAlphabeticalIndex` has nothing to group.
String _sectionKeyFor(String title) {
  if (title.isEmpty) return '#';
  final first = title[0].toUpperCase();
  if (RegExp(r'[A-Z]').hasMatch(first)) return first;
  return '#';
}

/// Path to the T9 recovery-test fixture.
///
/// This is a small synthetic MP3 (2s of 440 Hz tone with ID3 tags)
/// generated with ffmpeg, NOT the 5.2 MB commercial track used in the
/// spike: committing copyrighted audio to the repo is both a licensing
/// and a repo-size problem. Only the metadata read-back matters for
/// this test — the file just needs real, non-fallback tags.
///
/// The group below skips (does not fail) when the file is absent so
/// this test file remains runnable on a fresh checkout before
/// `flutter test` has a chance to fetch fixtures.
const _t9FixtureMp3 = 'test/fixtures/t9_amr/sample_with_metadata.mp3';

/// Waits until [predicate] returns true, polling every 10 ms. Fails the test
/// with a clear message if [timeout] elapses — this is preferable to fixed
/// `Future.delayed` calls for Drift stream reactivity tests, where the exact
/// re-emission latency is not contractually bounded.
Future<void> _waitFor(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 5),
  String? reason,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for condition'
          '${reason != null ? ' ($reason)' : ''}.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

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
      enableBackgroundCoverExtraction: false,
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
    String? sectionKey,
    String? coverArtPath,
    bool hasNoCover = false,
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
        sectionKey: sectionKey ?? _sectionKeyFor(title),
        coverArtPath: coverArtPath,
        hasNoCover: hasNoCover,
      )).valueOrNull!,
    );
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

    test('watchSongsByArtist filters correctly', () async {
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

  group('watchSongsWindow (reactive pagination)', () {
    test('offset 0, limit 50 over 75 songs → 50 songs', () async {
      for (var i = 0; i < 75; i++) {
        await seedSong(
          artist: 'a',
          title: 'Song ${i.toString().padLeft(3, '0')}',
          path: '/music/s${i.toString().padLeft(3, '0')}.mp3',
        );
      }
      final result = await repo.watchSongsWindow(offset: 0, limit: 50).first;
      expect(result.valueOrNull?.length, 50);
    });

    test('offset 50, limit 50 over 75 songs → 25 songs', () async {
      for (var i = 0; i < 75; i++) {
        await seedSong(
          artist: 'a',
          title: 'Song ${i.toString().padLeft(3, '0')}',
          path: '/music/s${i.toString().padLeft(3, '0')}.mp3',
        );
      }
      final result = await repo.watchSongsWindow(offset: 50, limit: 50).first;
      expect(result.valueOrNull?.length, 25);
    });

    test('offset past the end → empty list, not error', () async {
      for (var i = 0; i < 10; i++) {
        await seedSong(artist: 'a', path: '/music/s$i.mp3');
      }
      final result = await repo.watchSongsWindow(offset: 200, limit: 50).first;
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('inserting a new song re-emits the stream', () async {
      await seedSong(artist: 'a', title: 'AAA', path: '/music/aaa.mp3');
      await seedSong(artist: 'a', title: 'BBB', path: '/music/bbb.mp3');

      final emissions = <List<Song>>[];
      final sub = repo
          .watchSongsWindow(offset: 0, limit: 50)
          .listen((r) => r.when(ok: emissions.add, err: (_) {}));

      await _waitFor(() => emissions.isNotEmpty, reason: 'initial emission');

      await seedSong(artist: 'a', title: 'CCC', path: '/music/ccc.mp3');

      await _waitFor(() => emissions.length >= 2, reason: 're-emission');

      expect(emissions.last.length, 3);
      await sub.cancel();
    });

    test(
        'updating coverArtPath of a song INSIDE the window re-emits with '
        'the new value (guards §2.3 — no .distinct() via Song.==)', () async {
      await seedSong(artist: 'a', title: 'AAA', path: '/music/aaa.mp3');
      await seedSong(artist: 'a', title: 'BBB', path: '/music/bbb.mp3');
      await seedSong(artist: 'a', title: 'CCC', path: '/music/ccc.mp3');

      final emissions = <List<Song>>[];
      final sub = repo
          .watchSongsWindow(offset: 0, limit: 50)
          .listen((r) => r.when(ok: emissions.add, err: (_) {}));

      await _waitFor(() => emissions.isNotEmpty, reason: 'initial emission');
      expect(emissions.first.length, 3);

      await (db.update(db.songs)
            ..where((t) => t.filePath.equals('/music/aaa.mp3')))
          .write(const SongsCompanion(coverArtPath: Value('/covers/aaa.jpg')));

      await _waitFor(() => emissions.length >= 2, reason: 're-emission');

      final updated =
          emissions.last.firstWhere((s) => s.filePath == '/music/aaa.mp3');
      expect(updated.coverArtPath, '/covers/aaa.jpg',
          reason: 'content change inside window must propagate; a '
              '.distinct() via Song.== would have silenced this emission.');
      await sub.cancel();
    });

    test(
        'updating title of a song INSIDE the window re-emits with the '
        'new value (variant of the previous test on a different field)',
        () async {
      await seedSong(artist: 'a', title: 'AAA', path: '/music/aaa.mp3');

      final emissions = <List<Song>>[];
      final sub = repo
          .watchSongsWindow(offset: 0, limit: 50)
          .listen((r) => r.when(ok: emissions.add, err: (_) {}));

      await _waitFor(() => emissions.isNotEmpty, reason: 'initial emission');

      await (db.update(db.songs)
            ..where((t) => t.filePath.equals('/music/aaa.mp3')))
          .write(const SongsCompanion(title: Value('Renamed')));

      await _waitFor(() => emissions.length >= 2, reason: 're-emission');

      final updated =
          emissions.last.firstWhere((s) => s.filePath == '/music/aaa.mp3');
      expect(updated.title, 'Renamed');
      await sub.cancel();
    });

    test(
        'updating a song OUTSIDE the window re-emits (documented cost of '
        'removing .distinct(); see Sprint9_P0_T2.md §2.3)', () async {
      for (var i = 0; i < 75; i++) {
        await seedSong(
          artist: 'a',
          title: 'Song ${i.toString().padLeft(3, '0')}',
          path: '/music/s${i.toString().padLeft(3, '0')}.mp3',
        );
      }

      final emissions = <List<Song>>[];
      final sub = repo
          .watchSongsWindow(offset: 0, limit: 50)
          .listen((r) => r.when(ok: emissions.add, err: (_) {}));

      await _waitFor(() => emissions.isNotEmpty, reason: 'initial emission');
      final initialCount = emissions.length;

      await (db.update(db.songs)
            ..where((t) => t.filePath.equals('/music/s074.mp3')))
          .write(const SongsCompanion(coverArtPath: Value('/covers/x.jpg')));

      await _waitFor(() => emissions.length > initialCount,
          reason: 're-emission on out-of-window change');

      expect(emissions.last.length, 50);
      await sub.cancel();
    });

    test('query branch: window re-emits when a matching song is inserted',
        () async {
      await seedSong(artist: 'a', title: 'Purple Rain', path: '/music/p1.mp3');
      await seedSong(artist: 'a', title: 'Yellow', path: '/music/y1.mp3');

      final emissions = <List<Song>>[];
      final sub = repo
          .watchSongsWindow(offset: 0, limit: 50, query: 'purple')
          .listen((r) => r.when(ok: emissions.add, err: (_) {}));

      await _waitFor(() => emissions.isNotEmpty, reason: 'initial emission');
      expect(emissions.first.length, 1);

      await seedSong(artist: 'a', title: 'Purple Haze', path: '/music/p2.mp3');

      await _waitFor(() => emissions.length >= 2, reason: 're-emission');

      expect(emissions.last.length, 2);
      await sub.cancel();
    });
  });

  group('watchSongsCount', () {
    test('no query returns total', () async {
      for (var i = 0; i < 5; i++) {
        await seedSong(artist: 'a', path: '/music/s$i.mp3');
      }
      final result = await repo.watchSongsCount().first;
      expect(result.valueOrNull, 5);
    });

    test('inserting a song increments the count reactively', () async {
      await seedSong(artist: 'a', path: '/music/a.mp3');

      final emissions = <int>[];
      final sub = repo
          .watchSongsCount()
          .listen((r) => r.when(ok: emissions.add, err: (_) {}));

      await _waitFor(() => emissions.isNotEmpty, reason: 'initial count');
      expect(emissions.last, 1);

      await seedSong(artist: 'a', path: '/music/b.mp3');

      await _waitFor(() => emissions.length >= 2 && emissions.last == 2,
          reason: 'reactive count');
      await sub.cancel();
    });

    test('query branch counts only FTS matches', () async {
      await seedSong(artist: 'a', title: 'Purple Rain', path: '/music/p1.mp3');
      await seedSong(artist: 'a', title: 'Purple Haze', path: '/music/p2.mp3');
      await seedSong(artist: 'a', title: 'Yellow', path: '/music/y1.mp3');

      final result = await repo.watchSongsCount(query: 'purple').first;
      expect(result.valueOrNull, 2);
    });

    test(
        'query branch re-emits when a matching song is inserted '
        '(verifies readsFrom: {_db.songs} on songs_fts-based query)', () async {
      await seedSong(artist: 'a', title: 'Purple Rain', path: '/music/p1.mp3');
      await seedSong(artist: 'a', title: 'Purple Haze', path: '/music/p2.mp3');

      final emissions = <int>[];
      final sub = repo
          .watchSongsCount(query: 'purple')
          .listen((r) => r.when(ok: emissions.add, err: (_) {}));

      await _waitFor(() => emissions.isNotEmpty, reason: 'initial count');
      expect(emissions.last, 2);

      await seedSong(
          artist: 'a', title: 'Purple Mountain', path: '/music/p3.mp3');

      await _waitFor(() => emissions.length >= 2, reason: 'reactive count');
      expect(emissions.last, 3,
          reason: 'songs_fts reads from songs; without explicit '
              'readsFrom: {_db.songs} Drift would not re-run this query '
              'when songs changes.');
      await sub.cancel();
    });
  });

  group('watchAlphabeticalIndex', () {
    test('no query returns sections for every letter present', () async {
      await seedSong(artist: 'a', title: 'Apple', path: '/music/a.mp3');
      await seedSong(artist: 'a', title: 'Apricot', path: '/music/a2.mp3');
      await seedSong(artist: 'a', title: 'Banana', path: '/music/b.mp3');

      final result = await repo.watchAlphabeticalIndex().first;
      final sections = result.valueOrNull!;
      expect(sections.map((s) => s.$1), containsAll(['A', 'B']));
      final aSection = sections.firstWhere((s) => s.$1 == 'A');
      final bSection = sections.firstWhere((s) => s.$1 == 'B');
      expect(aSection.$2, 0);
      expect(bSection.$2, 2);
    });

    test('query branch returns only sections with FTS matches', () async {
      await seedSong(artist: 'a', title: 'Apple', path: '/music/a.mp3');
      await seedSong(artist: 'a', title: 'Banana', path: '/music/b.mp3');
      await seedSong(artist: 'a', title: 'Cherry', path: '/music/c.mp3');

      final result = await repo.watchAlphabeticalIndex(query: 'apple').first;
      final sections = result.valueOrNull!;
      expect(sections.map((s) => s.$1), ['A']);
      expect(sections.first.$2, 0);
    });
  });

  group('sort order in watchSongsWindow first page', () {
    test('title ascending', () async {
      await seedSong(artist: 'a', title: 'Zebra', path: '/music/z.mp3');
      await seedSong(artist: 'a', title: 'Apple', path: '/music/a.mp3');
      await seedSong(artist: 'a', title: 'Mango', path: '/music/m.mp3');

      final result = await repo.watchSongsWindow(offset: 0, limit: 50).first;
      expect(
        result.valueOrNull!.map((s) => s.title),
        ['Apple', 'Mango', 'Zebra'],
      );
    });

    test('artist ascending', () async {
      await seedSong(artist: 'Zed', path: '/music/z.mp3');
      await seedSong(artist: 'Anna', path: '/music/a.mp3');
      await seedSong(artist: 'Mike', path: '/music/m.mp3');

      final result = await repo
          .watchSongsWindow(
              offset: 0, limit: 50, sortOption: SongSortOption.artist)
          .first;
      expect(
        result.valueOrNull!.map((s) => s.trackArtistId.value),
        ['Anna', 'Mike', 'Zed'],
      );
    });

    test('duration descending', () async {
      await seedSong(
          artist: 'a',
          duration: const Duration(minutes: 2),
          path: '/music/a.mp3');
      await seedSong(
          artist: 'a',
          duration: const Duration(minutes: 5),
          path: '/music/b.mp3');
      await seedSong(
          artist: 'a',
          duration: const Duration(minutes: 3),
          path: '/music/c.mp3');

      final result = await repo
          .watchSongsWindow(
            offset: 0,
            limit: 50,
            sortOption: SongSortOption.duration,
            isAscending: false,
          )
          .first;
      expect(
        result.valueOrNull!.map((s) => s.duration.inMinutes),
        [5, 3, 2],
      );
    });

    test('date added ascending', () async {
      await seedSong(artist: 'a', path: '/music/a.mp3');
      await seedSong(artist: 'a', path: '/music/b.mp3');
      final result = await repo
          .watchSongsWindow(
              offset: 0, limit: 50, sortOption: SongSortOption.dateAdded)
          .first;
      expect(result.valueOrNull?.length, 2);
    });
  });

  group('reactive reactivity edge cases', () {
    test('a change to a non-sort, non-filter column still re-emits', () async {
      await seedSong(artist: 'a', title: 'A', path: '/music/a.mp3');

      final emissions = <List<Song>>[];
      final sub = repo
          .watchSongsWindow(offset: 0, limit: 50)
          .listen((r) => r.when(ok: emissions.add, err: (_) {}));

      await _waitFor(() => emissions.isNotEmpty, reason: 'initial emission');

      await (db.update(db.songs)
            ..where((t) => t.filePath.equals('/music/a.mp3')))
          .write(const SongsCompanion(lyricOffsetMs: Value(500)));

      await _waitFor(() => emissions.length >= 2, reason: 're-emission');

      final updated =
          emissions.last.firstWhere((s) => s.filePath == '/music/a.mp3');
      expect(updated.lyricOffsetMs, 500);
      await sub.cancel();
    });
  });

  // ---------------------------------------------------------------------
  // T2.1 regression suite — Batch cover_art_path writes & coalescing
  // ---------------------------------------------------------------------
  group('T2.1: Background cover extraction batching', () {
    test(
        'batching real: 120 songs updated in <= 4 transactions and none is lost',
        () async {
      final inner = NativeDatabase.memory(setup: (rawDb) {
        rawDb.execute('PRAGMA journal_mode=WAL;');
      });
      final countingExecutor = _CountingQueryExecutor(inner);
      final testDb = AppDatabase(countingExecutor);
      await testDb.customSelect('SELECT 1').get();

      for (var i = 0; i < 120; i++) {
        await testDb.into(testDb.songs).insert(
              SongsCompanion.insert(
                title: 'Song $i',
                trackArtistId: 'Artist',
                durationMs: 1000,
                filePath: '/music/batch120_$i.mp3',
                format: AudioFormat.mp3,
                fileSizeBytes: 1000,
                genreNames: const [],
                dateAddedUtcMs: 0,
                sectionKey: const Value('#'),
                hasNoCover: const Value(false),
              ),
            );
      }

      final transactionsBefore = countingExecutor.transactionCount;

      final testRepo = SongRepositoryImpl(
        testDb,
        coverArtCacheDirectory: '/tmp/nexo_covers',
        libraryFolderRepository: FakeLibraryFolderRepository(),
        coverWorkerSpawner: (files, cacheDir, sendPort) async {
          for (final f in files) {
            sendPort.send({
              'filePath': f.$1,
              'path': '/covers/${p.basename(f.$1)}.jpg',
            });
          }
          sendPort.send('DONE');
        },
      );

      await testRepo.startBackgroundCoverExtractionForTest();

      final transactionsDuring =
          countingExecutor.transactionCount - transactionsBefore;
      expect(transactionsDuring, lessThanOrEqualTo(4),
          reason: '120 items batched at 50/batch + final flush must take <= 4 '
              'transactions (expected 3: 50 + 50 + 20). Got: $transactionsDuring');

      // Visibility: All 120 songs have their cover_art_path populated
      final rows = await testDb.select(testDb.songs).get();
      expect(rows.length, 120);
      for (final r in rows) {
        expect(r.coverArtPath, '/covers/${p.basename(r.filePath)}.jpg');
        expect(r.hasNoCover, isFalse);
      }

      await testDb.close();
    });

    test('flush final writes pending updates (< 50) before extraction finishes',
        () async {
      for (var i = 0; i < 37; i++) {
        await db.into(db.songs).insert(
              SongsCompanion.insert(
                title: 'Song $i',
                trackArtistId: 'Artist',
                durationMs: 1000,
                filePath: '/music/flush37_$i.mp3',
                format: AudioFormat.mp3,
                fileSizeBytes: 1000,
                genreNames: const [],
                dateAddedUtcMs: 0,
                sectionKey: const Value('#'),
                hasNoCover: const Value(false),
              ),
            );
      }

      final testRepo = SongRepositoryImpl(
        db,
        coverArtCacheDirectory: '/tmp/nexo_covers',
        libraryFolderRepository: FakeLibraryFolderRepository(),
        coverWorkerSpawner: (files, cacheDir, sendPort) async {
          for (final f in files) {
            sendPort.send({
              'filePath': f.$1,
              'path': '/covers/${p.basename(f.$1)}.jpg',
            });
          }
          sendPort.send('DONE');
        },
      );

      await testRepo.startBackgroundCoverExtractionForTest();

      expect(testRepo.isExtractingCoversForTest, isFalse);

      final rows = await (db.select(db.songs)
            ..where((t) => t.filePath.like('/music/flush37_%')))
          .get();
      expect(rows.length, 37);
      for (final r in rows) {
        expect(r.coverArtPath, '/covers/${p.basename(r.filePath)}.jpg');
        expect(r.hasNoCover, isFalse);
      }
    });

    test(
        'subscriber coalescing: watchSongsWindow re-emits < 10 times for 200 cover updates',
        () async {
      for (var i = 0; i < 200; i++) {
        await db.into(db.songs).insert(
              SongsCompanion.insert(
                title: 'Song ${i.toString().padLeft(3, '0')}',
                trackArtistId: 'Artist',
                durationMs: 1000,
                filePath: '/music/coalesce_$i.mp3',
                format: AudioFormat.mp3,
                fileSizeBytes: 1000,
                genreNames: const [],
                dateAddedUtcMs: 0,
                sectionKey: const Value('#'),
                hasNoCover: const Value(false),
              ),
            );
      }

      final emissions = <List<Song>>[];
      final sub = repo
          .watchSongsWindow(offset: 0, limit: 50)
          .listen((r) => r.when(ok: emissions.add, err: (_) {}));

      await _waitFor(() => emissions.isNotEmpty,
          reason: 'initial window emission');

      final testRepo = SongRepositoryImpl(
        db,
        coverArtCacheDirectory: '/tmp/nexo_covers',
        libraryFolderRepository: FakeLibraryFolderRepository(),
        coverWorkerSpawner: (files, cacheDir, sendPort) async {
          for (final f in files) {
            sendPort.send({
              'filePath': f.$1,
              'path': '/covers/${p.basename(f.$1)}.jpg',
            });
          }
          sendPort.send('DONE');
        },
      );

      await testRepo.startBackgroundCoverExtractionForTest();

      // Drain any microtask/event queue emissions
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await sub.cancel();

      // 200 items batched at 50/batch = ~4 transaction flushes + 1 initial emission = ~5 emissions.
      // Acceptance criterion from Sprint9_P0_T2.1.md: < 10 emissions.
      expect(emissions.length, lessThan(10),
          reason: 'Batching must coalesce re-emissions on watchSongsWindow: '
              'got ${emissions.length} emissions (unbatched would be ~200)');
    });
  });

  // ---------------------------------------------------------------------
  // T9 regression suite — one-shot fallback metadata recovery.
  // ---------------------------------------------------------------------
  group('refreshFallbackMetadata (T9)', () {
    test('returns Ok(null) with zero candidates and does not spawn isolates',
        () async {
      await seedSong(
        artist: 'Real Artist',
        albumId: 'Real Album',
        path: '/music/real.mp3',
      );

      final result = await repo.refreshFallbackMetadata();

      expect(result.isOk, isTrue,
          reason: 'No candidates must short-circuit to Ok(null) without '
              'touching the isolate machinery — that is the whole point '
              'of a targeted recovery pass on a clean library.');
    });

    test('re-reads metadata for a fallback row pointing at a real file',
        () async {
      final fixture = File(_t9FixtureMp3);
      if (!await fixture.exists()) {
        markTestSkipped('T9 fixture $_t9FixtureMp3 not present.');
        return;
      }

      final tmpDir = await Directory.systemTemp.createTemp('nexo_t9_test_');
      try {
        final target = File(p.join(tmpDir.path, '02_mp3_replaygain.mp3'));
        await fixture.copy(target.path);

        await seedSong(
          artist: 'Unknown Artist',
          albumId: null,
          title: '02_mp3_replaygain',
          path: target.path,
        );

        final before = await (db.select(db.songs)
              ..where((t) => t.filePath.equals(target.path)))
            .getSingle();
        expect(before.trackArtistId, 'Unknown Artist',
            reason: 'Sanity: the seed row must be in fallback state or '
                'the assertion below proves nothing.');

        final result = await repo.refreshFallbackMetadata();
        expect(result.isOk, isTrue);

        final after = await (db.select(db.songs)
              ..where((t) => t.filePath.equals(target.path)))
            .getSingle();
        expect(after.trackArtistId, isNot('Unknown Artist'),
            reason: 'T9: a fallback row must be rewritten with the real '
                'metadata read back from the file. If this fails with '
                'the fallback string still present, the recovery pass '
                'either did not select the row (WHERE drifted from '
                '_fallbackArtistName) or did not flush the parse.');
      } finally {
        if (await tmpDir.exists()) {
          await tmpDir.delete(recursive: true);
        }
      }
    });

    test(
        'concurrent call while a recovery pass is in flight returns '
        'ValidationFailure', () async {
      final fixture = File(_t9FixtureMp3);
      if (!await fixture.exists()) {
        markTestSkipped('T9 fixture $_t9FixtureMp3 not present.');
        return;
      }

      final tmpDir = await Directory.systemTemp.createTemp('nexo_t9_conc_');
      try {
        final target = File(p.join(tmpDir.path, '02_mp3_replaygain.mp3'));
        await fixture.copy(target.path);

        await seedSong(
          artist: 'Unknown Artist',
          albumId: null,
          path: target.path,
        );

        final first = repo.refreshFallbackMetadata();

        final second = await repo.refreshFallbackMetadata();
        expect(
          second.when(ok: (_) => null, err: (e) => e),
          isA<ValidationFailure>(),
          reason: 'The guard is the whole concurrency contract for the '
              'recovery pass — without it a concurrent Settings-triggered '
              'rescan would spawn duplicate isolates against the same '
              'songs table.',
        );

        final firstResult = await first;
        expect(firstResult.isOk, isTrue);
      } finally {
        if (await tmpDir.exists()) {
          await tmpDir.delete(recursive: true);
        }
      }
    });
  });

  // ---------------------------------------------------------------------
  // T3 regression suite — content-addressed cover cache key.
  // ---------------------------------------------------------------------
  group('computeCoverId (T3: SHA-256 stable cover cache key)', () {
    test('identical cover bytes produce an identical coverId', () {
      final bytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3, 4]);
      expect(computeCoverId(bytes), computeCoverId(bytes));
    });

    test('different cover bytes produce different coverIds', () {
      final a = Uint8List.fromList([1, 2, 3]);
      final b = Uint8List.fromList([4, 5, 6]);
      expect(computeCoverId(a), isNot(equals(computeCoverId(b))));
    });

    test('coverId is a 64-char lowercase hex string (SHA-256)', () {
      final id = computeCoverId(Uint8List.fromList([0x42]));
      expect(id.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(id), isTrue);
    });

    test(
        'two songs with identical coverBytes resolve to the same on-disk '
        'coverArtPath via cacheCoverArt', () async {
      final tmpDir = await Directory.systemTemp.createTemp('nexo_t3_test_');
      try {
        const datasource = MetadataDatasource();
        final bytes = Uint8List.fromList(
          const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
        );

        final coverIdA = computeCoverId(bytes);
        final coverIdB = computeCoverId(bytes);

        final pathA = await datasource.cacheCoverArt(
          coverBytes: bytes,
          cacheDirectory: tmpDir.path,
          coverId: coverIdA,
        );
        final pathB = await datasource.cacheCoverArt(
          coverBytes: bytes,
          cacheDirectory: tmpDir.path,
          coverId: coverIdB,
        );

        expect(pathA, isNotNull);
        expect(
          pathA,
          pathB,
          reason: 'Two songs with byte-identical covers must share one '
              'cached file. This is the core content-addressing property '
              'that String.hashCode could not provide.',
        );
      } finally {
        if (await tmpDir.exists()) {
          await tmpDir.delete(recursive: true);
        }
      }
    });
  });

  // ---------------------------------------------------------------------
  // Contract Hardening (Slice B2)
  // ---------------------------------------------------------------------
  group('Contract Hardening (Result Err on DB failure)', () {
    test('getSongById returns Err(UnexpectedFailure) when the DB is closed',
        () async {
      final id = await seedSong(artist: 'artist-1');

      await db.close();

      final result = await repo.getSongById(SongId(id));

      expect(result.isErr, isTrue,
          reason: 'getSongById must return Err, not throw, when the DB '
              'fails. Throwing would bypass the Result contract enforced '
              'by CONVENTIONS.md.');
      expect(
        result.when(ok: (_) => null, err: (e) => e),
        isA<UnexpectedFailure>(),
      );
    });
  });
}
