// ignore_for_file: avoid_print

// Sprint 9 / T2 — Pagination & reactivity benchmark suite.
//
// This file deliberately does heavy work (seeds 15,000 + 3,500 rows, fires
// thousands of sequential UPDATEs) and is NOT part of the normal
// `flutter test` run. It is skip-gated and tag-gated; see below.
//
// Run explicitly:
//
//   flutter test --tags=benchmark --run-skipped -r expanded \
//     test/data/repositories/song_repository_pagination_benchmark_test.dart
//
// Output is printed; no numeric assertions are made. The numbers feed §11
// ("Registro de la decisión") of Sprint9_P0_T2.md and decide between
// pagination strategy A (LIMIT/OFFSET), A + A.1 (add LOWER() indexes), or
// B (keyset).
//
// §5.2 additionally measures the real cost of removing `.distinct()` from
// `watchSongsWindow` (Sprint9_P0_T2.md §2.3) under the adverse scenario of
// a freshly-scanned library with background cover extraction running while
// the user has the screen open.
//
// §5.3 re-measures the §5.1 OFFSET sweep AFTER adding functional indexes on
// LOWER(title) and LOWER(track_artist_id). The index is required regardless
// of route (A+A.1 or B), so this is not a speculative experiment: it answers
// whether the user-facing cost of the OFFSET-based pagination drops below
// the §2.1.3 pre-committed threshold once the index is in place.
//
// IMPORTANT — this file must run BEFORE `watchSongsWindow` is written. It
// deliberately inlines the exact SQL that production will use (route A) and
// mirrors it via `customSelect(...).watch()` + `SongMapper`, so that the
// numbers are meaningful regardless of whether production has landed yet.

@Tags(['benchmark'])
@Skip('Run explicitly: flutter test --tags=benchmark --run-skipped -r expanded '
    'test/data/repositories/song_repository_pagination_benchmark_test.dart')
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexo/data/local/app_database.dart';
import 'package:nexo/data/local/mappers/song_mapper.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/entities/song.dart';

const _mapper = SongMapper();

// ─────────────────────────────────────────────────────────────────────────────
// Realistic title generator
// ─────────────────────────────────────────────────────────────────────────────

/// Produces a deterministic title distribution that resembles a real
/// library: mostly ASCII letters, with a minority of digit-leading titles,
/// accented titles, and symbol-leading titles. Exercises `LOWER()` (a
/// no-op on ASCII but a real transform on accented letters) and section_key
/// computation realistically.
String _realisticTitle(int i) {
  // 12,000 A-Z  /  1,500 digits  /  1,000 accented  /  500 symbol-led
  if (i < 12000) {
    final letter = String.fromCharCode(0x41 + (i % 26)); // A-Z
    return '$letter Track ${i.toString().padLeft(5, '0')}';
  }
  if (i < 13500) {
    final n = i - 12000;
    return '${n % 100} Problems ${n.toString().padLeft(4, '0')}';
  }
  if (i < 14500) {
    const accented = ['Ángel', 'Época', 'Índice', 'Ópera', 'Último', 'Ñandú'];
    final n = i - 13500;
    return '${accented[n % accented.length]} ${n.toString().padLeft(4, '0')}';
  }
  const symbols = ['#1 Hit', r'$100 Bill', '@ Night', '% Pure', '& More'];
  final n = i - 14500;
  return '${symbols[n % symbols.length]} ${n.toString().padLeft(4, '0')}';
}

/// Approximation of the production `_computeSectionKey`. The benchmark only
/// needs `section_key` to be populated so the SQL index participates; the
/// exact accent→ASCII mapping is irrelevant to what §5.1 measures.
String _sectionKeyFor(String title) {
  if (title.isEmpty) return '#';
  final first = title[0].toUpperCase();
  if (RegExp(r'[A-Z]').hasMatch(first)) return first;
  return '#';
}

// ─────────────────────────────────────────────────────────────────────────────
// Seeding + materialization helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _seedSongs(AppDatabase db, int count) async {
  await db.transaction(() async {
    await db.batch((batch) {
      for (var i = 0; i < count; i++) {
        final title = _realisticTitle(i);
        batch.insert(
          db.songs,
          SongsCompanion.insert(
            id: Value(i + 1),
            title: title,
            trackArtistId: 'Artist ${i % 200}',
            albumId: Value('Album ${i % 500}'),
            durationMs: 120000 + (i * 37) % 240000,
            filePath: '/music/track_${i.toString().padLeft(6, '0')}.mp3',
            format: AudioFormat.mp3,
            fileSizeBytes: 1000000 + (i * 13) % 5000000,
            genreNames: const [],
            dateAddedUtcMs: i * 1000,
            sectionKey: Value(_sectionKeyFor(title)),
          ),
        );
      }
    });
  });
}

List<Song> _materialize(AppDatabase db, List<QueryRow> rows) {
  final songs = <Song>[];
  for (final row in rows) {
    final songRow = db.songs.map(row.data);
    final result = _mapper.toEntity(songRow);
    if (result.isOk) {
      songs.add(result.valueOrNull!);
    }
  }
  return songs;
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats
// ─────────────────────────────────────────────────────────────────────────────

class _Stats {
  _Stats(this.samples);
  final List<double> samples;

  double get median {
    final sorted = List<double>.of(samples)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }

  double get p95 {
    final sorted = List<double>.of(samples)..sort();
    final idx = math.min((sorted.length * 0.95).floor(), sorted.length - 1);
    return sorted[idx];
  }

  double get mean => samples.reduce((a, b) => a + b) / samples.length;
}

void _printRow(String label, _Stats stats) {
  print('  ${label.padRight(28)} '
      'median=${stats.median.toStringAsFixed(2)}ms  '
      'p95=${stats.p95.toStringAsFixed(2)}ms  '
      'mean=${stats.mean.toStringAsFixed(2)}ms');
}

Future<_Stats> _measureOffset({
  required AppDatabase db,
  required String orderColumn,
  required int offset,
  int iterations = 100,
}) async {
  // Warm-up: prime SQLite's page cache and the prepared-statement cache.
  for (var i = 0; i < 5; i++) {
    await db.customSelect(
      'SELECT * FROM songs ORDER BY $orderColumn ASC LIMIT 50 OFFSET ?',
      variables: [Variable.withInt(offset)],
      readsFrom: {db.songs},
    ).get();
  }

  final samples = <double>[];
  for (var i = 0; i < iterations; i++) {
    final sw = Stopwatch()..start();
    await db.customSelect(
      'SELECT * FROM songs ORDER BY $orderColumn ASC LIMIT 50 OFFSET ?',
      variables: [Variable.withInt(offset)],
      readsFrom: {db.songs},
    ).get();
    sw.stop();
    samples.add(sw.elapsedMicroseconds / 1000.0);
  }
  return _Stats(samples);
}

// ─────────────────────────────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('§5.1 — LIMIT/OFFSET pagination strategy (baseline, no indexes)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      // Migration runs lazily on first query.
      await db.customSelect('SELECT 1').get();
      await _seedSongs(db, 15000);
    });

    tearDown(() async {
      await db.close();
    });

    test('seed 15k songs and measure LIMIT/OFFSET latency', () async {
      final countRow =
          await db.customSelect('SELECT COUNT(*) AS n FROM songs').getSingle();
      final n = countRow.data['n'];

      print('\n══════════════════════════════════════════════════════════════');
      print('§5.1 — LIMIT/OFFSET pagination over $n songs (NO indexes)');
      print('Machine: dev box (NOT the Helio G85 / Pentium E5800 target).');
      print('Per §2.1.3, extrapolate ×3–5 for the target hardware.');
      print('══════════════════════════════════════════════════════════════');

      for (final sortColumn in [
        'LOWER(title)',
        'LOWER(track_artist_id)',
        'duration_ms',
      ]) {
        print('\nORDER BY $sortColumn:');
        for (final offset in [0, 5000, 10000, 14000]) {
          final stats = await _measureOffset(
            db: db,
            orderColumn: sortColumn,
            offset: offset,
          );
          _printRow('OFFSET $offset', stats);
        }
      }

      final countSamples = <double>[];
      for (var i = 0; i < 100; i++) {
        final sw = Stopwatch()..start();
        await db.customSelect('SELECT COUNT(*) AS n FROM songs').getSingle();
        sw.stop();
        countSamples.add(sw.elapsedMicroseconds / 1000.0);
      }
      print('\nSELECT COUNT(*):');
      _printRow('full count', _Stats(countSamples));

      print('\n──────────────────────────────────────────────────────────────');
      print('Decision rule (pre-committed in Sprint9_P0_T2.md §2.1.3):');
      print('  median OFFSET 10000 <  5ms  → route A  (LIMIT/OFFSET)');
      print('  median OFFSET 10000 ∈ [5,15]ms → route A + A.1 (LOWER idx)');
      print('  median OFFSET 10000 > 15ms   → route B  (keyset)');
      print('──────────────────────────────────────────────────────────────\n');
    }, timeout: const Timeout(Duration(minutes: 10)));
  });

  group('§5.2 — cost of removing .distinct() from watchSongsWindow', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await db.customSelect('SELECT 1').get();
      await _seedSongs(db, 3500);
    });

    tearDown(() async {
      await db.close();
    });

    test('3,500 sequential cover_art_path UPDATEs against 4 open windows',
        () async {
      print('\n══════════════════════════════════════════════════════════════');
      print('§5.2 — No-distinct re-emission cost (adverse scenario)');
      print('  3,500 songs, 4 subscriptions, 3,500 sequential UPDATEs');
      print('  Simulates fresh scan + background cover extraction + UI open.');
      print('══════════════════════════════════════════════════════════════');

      // The 4 LRU pages of Sprint9_P0_T2.md §2.4, worst case.
      final offsets = [0, 50, 100, 150];
      final subs = <StreamSubscription<List<Song>>>[];
      final emissionsPerSub = <int>[0, 0, 0, 0];
      final songsPerSub = <int>[0, 0, 0, 0];
      final cpuMicrosPerSub = <int>[0, 0, 0, 0];

      for (var s = 0; s < offsets.length; s++) {
        final idx = s;
        final stream = db
            .customSelect(
              'SELECT * FROM songs '
              'ORDER BY LOWER(title) ASC '
              'LIMIT 50 OFFSET ?',
              variables: [Variable.withInt(offsets[idx])],
              readsFrom: {db.songs},
            )
            .watch()
            .map((rows) {
              final sw = Stopwatch()..start();
              final songs = _materialize(db, rows);
              sw.stop();
              cpuMicrosPerSub[idx] += sw.elapsedMicroseconds;
              return songs;
            });

        subs.add(stream.listen((songs) {
          emissionsPerSub[idx]++;
          songsPerSub[idx] += songs.length;
        }));
      }

      // Let initial emissions land before taking a baseline, so we don't
      // count the first "here's the initial page" as a spurious re-emission.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final emissionBaseline = List<int>.of(emissionsPerSub);
      final songsBaseline = List<int>.of(songsPerSub);
      final cpuBaseline = List<int>.of(cpuMicrosPerSub);

      final wallClock = Stopwatch()..start();
      for (var id = 1; id <= 3500; id++) {
        await (db.update(db.songs)..where((t) => t.id.equals(id)))
            .write(SongsCompanion(coverArtPath: Value('/covers/$id.jpg')));
      }
      wallClock.stop();

      // Drain any in-flight re-emissions before measuring.
      await Future<void>.delayed(const Duration(milliseconds: 500));

      for (final sub in subs) {
        await sub.cancel();
      }

      final totalEmissions = emissionsPerSub.reduce((a, b) => a + b) -
          emissionBaseline.reduce((a, b) => a + b);
      final totalSongs = songsPerSub.reduce((a, b) => a + b) -
          songsBaseline.reduce((a, b) => a + b);
      final totalCpuMicros = cpuMicrosPerSub.reduce((a, b) => a + b) -
          cpuBaseline.reduce((a, b) => a + b);

      print('\nPer-subscription deltas (post-baseline):');
      for (var s = 0; s < offsets.length; s++) {
        final em = emissionsPerSub[s] - emissionBaseline[s];
        final so = songsPerSub[s] - songsBaseline[s];
        final cpuMs = (cpuMicrosPerSub[s] - cpuBaseline[s]) / 1000.0;
        print('  offset ${offsets[s].toString().padLeft(5)}: '
            'emissions=$em  songs=$so  '
            'cpu-in-map=${cpuMs.toStringAsFixed(1)}ms');
      }

      final perEmissionSongs =
          totalEmissions == 0 ? 0.0 : totalSongs / totalEmissions;

      print('\nAggregate across 4 subscriptions:');
      print('  Total re-emissions:           $totalEmissions');
      print('    (theoretical upper bound:   ${3500 * 4} = 3,500 × 4)');
      print('  Total Songs rebuilt:          $totalSongs '
          '(~${perEmissionSongs.toStringAsFixed(1)} per emission)');
      print('  Total CPU inside .map:        '
          '${(totalCpuMicros / 1000).toStringAsFixed(1)} ms');
      print(
          '  Wall-clock for 3,500 UPDATEs: ${wallClock.elapsedMilliseconds} ms '
          '(${(wallClock.elapsedMilliseconds / 3500).toStringAsFixed(2)} ms/UPDATE)');

      print('\nInterpretation guide for §11:');
      print('  • Total re-emissions ≪ 14,000 → Drift is coalescing between');
      print('    await points. The .distinct() removal costs less than the');
      print('    theoretical upper bound suggests.');
      print('  • Total re-emissions ≈ 14,000 → no coalescing; every UPDATE');
      print('    fans out to every window. If CPU-in-map is still small in');
      print('    absolute terms (ms total, not seconds), design §2.3 (A)');
      print('    holds; if it climbs into seconds, T2.1 (batch the writes)');
      print('    becomes justified.');
      print('  • CPU-in-map is the marginal cost of NOT having .distinct().');
      print('    Compare against wall-clock above — if it is a small');
      print('    fraction, the design decision is confirmed empirically.');
      print('══════════════════════════════════════════════════════════════\n');
    }, timeout: const Timeout(Duration(minutes: 15)));
  });

  group('§5.3 — §5.1 sweep re-run with functional indexes (A.1)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await db.customSelect('SELECT 1').get();
      await _seedSongs(db, 15000);

      // The exact DDL that migration v15 → v16 would emit under route A+A.1.
      // Under route B, the same indexes are also required for the keyset
      // WHERE clause to hit a B-tree rather than a full scan — so these
      // indexes are needed regardless of which route wins. This benchmark
      // only answers "does OFFSET-over-index meet the §2.1.3 threshold".
      await db.customStatement(
        'CREATE INDEX idx_songs_title_lower ON songs (LOWER(title));',
      );
      await db.customStatement(
        'CREATE INDEX idx_songs_artist_lower ON songs (LOWER(track_artist_id));',
      );

      // ANALYZE primes SQLite's planner statistics so it picks the index
      // rather than falling back to a full scan + sort. Production would
      // run this once after the migration; the benchmark mirrors that.
      await db.customStatement('ANALYZE;');
    });

    tearDown(() async {
      await db.close();
    });

    test('re-measure OFFSET sweep with LOWER() functional indexes', () async {
      final countRow =
          await db.customSelect('SELECT COUNT(*) AS n FROM songs').getSingle();
      final n = countRow.data['n'];

      print('\n══════════════════════════════════════════════════════════════');
      print('§5.3 — LIMIT/OFFSET pagination over $n songs (A.1: indexed)');
      print('  Indexes: idx_songs_title_lower, idx_songs_artist_lower');
      print('  Duration sort omitted — it is a plain int column, no');
      print('  LOWER() transform, so no functional index applies; the');
      print('  baseline §5.1 number stands for it.');
      print('  ANALYZE was run before measurement (production parity).');
      print('══════════════════════════════════════════════════════════════');

      for (final sortColumn in [
        'LOWER(title)',
        'LOWER(track_artist_id)',
      ]) {
        print('\nORDER BY $sortColumn:');
        for (final offset in [0, 5000, 10000, 14000]) {
          final stats = await _measureOffset(
            db: db,
            orderColumn: sortColumn,
            offset: offset,
          );
          _printRow('OFFSET $offset', stats);
        }
      }

      print('\n──────────────────────────────────────────────────────────────');
      print('Compare against §5.1 baseline (same query, NO indexes):');
      print('  LOWER(title) OFFSET 10000:  §5.1 = 38.12 ms → §5.3 = ?');
      print('  LOWER(artist) OFFSET 10000: §5.1 = 37.77 ms → §5.3 = ?');
      print('');
      print('Decision rule extended (per user-approved §5.3 criterion):');
      print('  §5.3 median OFFSET 10000 <  5ms  → route A + A.1');
      print('    (≤ 25 ms on Helio G85 after ×3–5 extrapolation;');
      print('     prefer A+A.1 over B for lower implementation complexity)');
      print('  §5.3 median OFFSET 10000 ≥  5ms  → route B (keyset)');
      print('──────────────────────────────────────────────────────────────\n');
    }, timeout: const Timeout(Duration(minutes: 10)));
  });
}
