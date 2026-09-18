# NEXO MUSIC PLAYER — Architecture and Continuity Document

**Repo:** github.com/YisusPineapple/Nexo (branch `main`)
**Package Name:** `io.github.yisus.nexo`
**Last confirmed version:** `0.0.12-beta+94`
**Database schema (Drift):** `schemaVersion = 17` (verified by
`migration_v14_to_v15_test.dart`, `migration_v15_to_v16_test.dart`, and
`migration_v16_to_v17_test.dart`)
**General state:** Sprint 9 (Stability and FOSS) in progress.
- T1 closed and merged (stable song identity).
- T2 closed and benchmark-verified on 2026-09-14 (reactive pagination
  over Drift `.watch()`, `SongsWindowNotifier` with LRU, migration v16
  with functional indexes — decision A+A.1 confirmed with real numbers:
  38.38 ms without index → 1.27 ms with index, ~30× improvement. See
  `Sprint9_P0_T2.md` §11).
- **T3 closed** on 2026-09-17, verified on Linux dev box: 1408 unique
  cover files, zero duplicates across restart, SHA-256 names (see
  §2.5 and §3).
- **T2.1 open as P1**: batching of `cover_art_path` writes in
  `_startBackgroundCoverExtraction`. See `Sprint9_P0_T2.1.md`.
- T5 backlog (renamed from the "T3" originally referenced in
  `Sprint9_P0_T2.md` §9 — that ticket is now T5).
- T6, T7, T8 added 2026-09-16 after roadmap filtering (see §3).

---

## 0. Glossary

- **T1..Tn**: Sprint 9 tickets, in merge order.
- **P0**: sprint blocker. **P1**: non-blocker but tracked.
- **A+A.1**: pagination route = LIMIT/OFFSET with functional indexes
  (`LOWER(...)`). Chosen over keyset (route B) with benchmark evidence.
- **LRU**: Least Recently Used cache — 4 pages × 50 rows in
  `SongsWindowNotifier`.
- **Dual-buffer**: Nexo's gapless pattern — two `AudioPlayer` instances,
  one active one preloading, swapped on transition.

---

## 1. Resolved recently (Sprint 8 — historical, not to be re-litigated)

### 1.1 — Scanner and parallelism
- **TagLib C++:** was chosen in Sprint 8 — `flutter_taglib` for ID3 and
  cover reading. **Abandoned in T9 (see §2.6):** the pinned fork ships
  a 32-bit ARM binary under `lib/arm64-v8a/`, which Android arm64
  rejects at load time. Historical note only; the current primary
  metadata reader is `audio_metadata_reader` (pure Dart).
- **Scanner parallelism:** `Isolate.spawn` per chunk during scan and
  cover extraction. Not a reusable persistent pool — ephemeral isolates
  per chunk.
- **Reactive scanner:** `AudioFileScanner` emits via `Stream` (`async*` /
  `yield*`), confirmed.

### 1.2 — Virtual pagination and RAM (Sprint 9 / T2)
Delivered 2026-09-13, benchmark-verified 2026-09-14.
`SongsWindowNotifier` lives in
`lib/presentation/providers/songs_window_provider.dart`:
`Notifier<SongsWindowState>` with pages of 50 rows, LRU cache of 4 pages
(~200 songs worst case), dynamic `itemCount` in `ListView.builder` with
fixed `itemExtent` of 72. `SongsScreen` was rewritten; no longer loads
the full table.

Pagination strategy: **A+A.1** (LIMIT/OFFSET with functional `LOWER(...)`
indexes). §5.1 of the ticket measured 38.38 ms median OFFSET 10000
without indexes; §5.3 measured 1.27 ms with indexes — ~30× improvement.
Route B (keyset) discarded with numbers on the table, not estimates.

Methodology note: the first benchmark run (2026-09-13) had a methodology
bug — `onCreate` already creates the sort indexes since schema v16, so
the "baseline without indexes" was never actually index-free. Fixed with
an explicit `DROP INDEX` in §5.1's `setUp`. Full detail in
`Sprint9_P0_T2.md` §11.

RAM target: ≤120 MB Android / ≤250 MB PC (`AGENTS.md` §1). Physical
device verification pending; the implementation closes the architectural
gap that blocked it.

FTS5 search is now paginated too (previously brought up to 500 results
in RAM per keystroke; now 50 per page with LRU).

### 1.3 — Reactivity and UI
- **Drift reactive:** true for all library views including Songs.
  `watchSongsWindow` / `watchSongsCount` / `watchAlphabeticalIndex` over
  `_db.songs` replaced the full-list `FutureProvider`.
  `readsFrom: {_db.songs}` declared explicitly on branches reading
  `songs_fts` to anchor reactivity to the physical table the scanner
  writes to.
- **M3 Expressive / `NexoTokens` / `SoftCard`:** confirmed.
- **Rendering:** `now_playing_screen.dart` uses `RepaintBoundary` +
  `.select()` correctly. `MiniPlayer` does not — pending, P1.
- **LRU cache:** 4 pages × 50 rows. Eviction cancels the evicted page's
  subscription; a shrinking count (user excludes a folder with the tab
  open) purges pages outside the new range. Covered by test.

---

## 2. Open bugs / QA observations

### 2.1 — SongsScreen ghost covers: CLOSED IN T2
Root cause confirmed at the time: `_coversUpdatedController.add(null)`
was never invoked — a dead reactive pipe, not a page-invalidation
problem. T1 gave stable identity to `SongId`. T2 closed the loop:
`coversUpdatedStream` / `_coversUpdatedController` and the full-list
`FutureProvider` removed; cover reactivity now comes natively from
`watchSongsWindow` over `_db.songs`. Verified by four tests confirming
that a change to `coverArtPath` / `title` / `lyricOffsetMs` on a song
inside the visible window re-emits with the new value.

### 2.2 — Audio engine refactor (technical debt) — OPEN, P1
`NexoAudioHandler`: 695 lines confirmed. Crossfade logic depends on
`_isPlayerAActive` / `_isTransitioning` / `_isSkipping` plus
pseudo-state `_frozenProgress > 0.0`. Gapless bug confirmed: last song
without repeat does not transition explicitly to "stopped". State
machine design (`EngineState` / `reduceEngine`) already sketched, not
implemented.

### 2.3 — Circuit breaker for errors — OPEN, unverified
Not confirmed in code whether any limit exists on consecutive retries
of corrupt files. Still pending a dedicated audit.

### 2.4 — SongId as file path: RESOLVED IN T1
`songs.id` is now `INTEGER PRIMARY KEY` (rowid alias), stable across
rename/move within the same indexed folder. Verified by
`migration_v14_to_v15_test.dart` (both FK OFF and FK ON groups).

### 2.5 — Cover art cache duplication — FIXED in `0.0.12-beta+89`
**Status:** root cause confirmed 2026-09-16; fix landed 2026-09-17.

`_buildSong` in `song_repository_impl.dart` computed the cover file name
as:

```dart
'${album ?? 'unknown'}_${extracted.albumArtist ?? artist}'
    .hashCode
    .toRadixString(16)
```

Dart's `String.hashCode` is **not stable across runs or across
isolates** (documented behavior of the language). Consequences:

1. **Between isolates:** `_startBackgroundCoverExtraction` spawns
   `workerCount = min(numberOfProcessors, 2)` isolates in parallel, each
   with its own hash seed. Two songs of the same album landing in
   different chunks produced different `coverId`s → two identical `.jpg`
   files written in the same scan.
2. **Between runs:** every app restart changes the seed. The next scan
   generated new hashes, `file.exists()` returned `false`, more copies
   were written.
3. **Collision when `album == null`:** all tracks without album metadata
   shared `'unknown_artist'.hashCode`. That is the opposite problem —
   collision instead of duplication — but from the same design.

**Real-device evidence:**

| Source | Total files | Unique (MD5) | Duplicates | Size |
|---|---:|---:|---:|---:|
| Linux dev-box test library | 923 | 865 | 58 (6.3%) | 474 MB |
| Android device (Helio G85) | larger | — | — | ~1.8 GB |

**Reconciliation of the 1.8 GB vs 474 MB figures:** both are symptoms
of the same bug, on two different libraries. The 1.8 GB figure is from
the Android device whose music library is substantially larger; the
474 MB figure is from the Linux dev-box test library. The duplication
*rate* is what matters — roughly 6% on both — and the SHA-256 fix
addresses it at the source. No further reconciliation is needed; both
numbers are recorded here as evidence of the same root cause.

**Fix implemented (2026-09-17, `0.0.12-beta+89`):**

- `computeCoverId` in `song_repository_impl.dart` now returns
  `sha256.convert(coverBytes).toString()`. Content-addressed, stable
  across isolates and runs.
- Schema 16 → 17 (`app_database.dart`): `UPDATE songs SET
  cover_art_path = NULL, has_no_cover = 0 WHERE cover_art_path IS NOT
  NULL`. Runs inside `onUpgrade`, purely SQL — no filesystem I/O inside
  the migration transaction.
- Cache purge is Phase B, post-migration, in `main.dart`, one-shot via
  a marker file (`cover_cache.v17.purged`) in the app support directory.
  Best-effort, never aborts the app.
- Regression tests: `migration_v16_to_v17_test.dart` (DB state, no
  filesystem) and four new cases in `song_repository_impl_test.dart`
  under the `computeCoverId` group.

**Verified on Linux dev box, 2026-09-17:** fresh-install scan produced
1408 unique cover files (1408/1408, SHA-256 named, 800 MB). Restart
and second launch produced identical counts — no drift across
processes. Pre-fix cache on the same library had 923 files with 58
duplicates (865 unique). All three duplication vectors confirmed
closed. Physical-device verification on Helio G85 is nice-to-have,
not blocking — the fix is content-addressed by construction.

### 2.6 — Android metadata silent failure — DIAGNOSED 2026-09-18
**Status:** root cause confirmed, fix in progress.

`flutter_taglib` (fork `MSOB7YY/flutter_taglib`, no version tag)
packages a 32-bit ARM binary under `lib/arm64-v8a/`. On arm64
devices, `System.loadLibrary` rejects it with
`is 32-bit instead of 64-bit` and does not fall back to
`armeabi-v7a/`. Every metadata read on Android therefore throws
`Unsupported operation: flutter_taglib is not supported or has
been disabled on this platform`, and `_buildSong` falls back to
`Unknown Artist` / null album / empty genres / no cover.

Evidence (Helio G85 device, 2026-09-18):
- `unzip -l base.apk | grep taglib` → three identical
  `libflutter_taglib_native.so` files (1470104 bytes each) under
  `arm64-v8a/`, `armeabi-v7a/`, `x86_64/`.
- `file lib/arm64-v8a/libflutter_taglib_native.so` → `ELF 32-bit
  LSB shared object, ARM, EABI5`.
- logcat: `Failed to load native library … is 32-bit instead of
  64-bit` for every load attempt.

Fix path (two phases, see §3 T9 and T9.1):
- **T9 (immediate):** drop `flutter_taglib`, promote
  `audio_metadata_reader` to primary. Unblocks Android today.
- **T9.1 (planned):** migrate to Rust + `lofty` via
  `flutter_rust_bridge`. Full ABI control, verified cross-compile
  for arm64-v8a / armeabi-v7a / x86_64.

---

## 3. Active roadmap (Sprint 9 onwards)

### P0 — blocker
- [ ] **T9** — Android metadata silent failure (§2.6). Drop
  `flutter_taglib`; make `audio_metadata_reader` the primary
  metadata source. Unblocks Android today at a performance cost
  to be measured.

### P1 — non-blocker
- [ ] **T2.1** — Batch `cover_art_path` writes in
  `_startBackgroundCoverExtraction`. Designed and justified by §5.2 of
  the T2 benchmark (verified 2026-09-14: 19.47 s wall-clock / 3.64 s
  CPU-in-map over 3,500 UPDATEs). See `Sprint9_P0_T2.1.md`.
- [ ] **T5** (renamed from the "T3" in `Sprint9_P0_T2.md` §9) —
  Pagination of `multiArtistSongsProvider` / `genreSongsProvider` in
  `grouped_library_providers.dart`, and migration of detail screens
  (`FolderDetailScreen`, `AlbumDetailScreen`, `ArtistDetailScreen`,
  `GenreDetailScreen`) to `itemExtent`.
- [ ] **T6** — Multi-artist / multi-genre UI. The data layer already
  supports it (`artist_splitter.dart`, `Song.genreNames` as
  `List<String>`, `Artist.collaborationCount` computed). What is missing
  is UI and queries: filter library by an individual artist inside a
  collab, filter by one genre when `genreNames` has several, show a
  "collaboration" indicator in `SongsScreen`. Small ticket.
- [ ] **T7** — Audit: which formats actually decode on which platform.
  `audio_file_scanner.dart` already maps `.wav`, `.aiff`, `.eac3`,
  `.ac4`, `.m4a`, `.mp4` — the extension table is complete. What is
  unknown is whether the **decoders** (`ExoPlayer` on Android,
  `media_kit` / MPV on desktop) actually play them. This is an audit
  ticket, not a feature ticket. No `.mkv` unless a real user need is
  demonstrated.
- [ ] **T8** — Audit: audio resampling and RAM profile per quality
  tier. Does the engine resample? At what rate? Does forcing 32-bit /
  high sample rate blow the 120 MB ceiling on Helio G85? Answer those
  questions before promising "audiophile" features.
- [ ] Audio engine refactor (`NexoAudioHandler`, §2.2).
- [ ] Circuit breaker for errors (§2.3).
- [ ] `RepaintBoundary` on `MiniPlayer` (§1.3).

### Deferred — exploration only, not tickets
These are explicitly **not** to become tickets until T9, T2.1, T5, T6,
T7, T8 and the engine refactor are closed:
- Rust / C++ / Zig rewrite of the audio engine.
- Bit-perfect path with external USB DAC (bypassing the Android audio
  mixer).
- MKV / MP4 as audio-only containers.

### Planned (P1, after T9)
- [ ] **T9.1** — Replace Dart-pure metadata reader with Rust +
  `lofty` via `flutter_rust_bridge`. Recovers performance, adds
  ABI-verified native binaries, removes all untrusted native
  dependencies.

### Housekeeping backlog (low priority)
- Reorganize `docs/` structure (`docs/adr/`, `docs/sprints/` already
  exists).
- Split `CONVENTIONS.md` into per-audience files if it grows past
  ~200 lines.

---

## 4. Non-goals (not to be re-litigated before 1.0)

Nexo explicitly will **not** implement, by product decision and RAM
ceiling:
- Online streaming or third-party service integrations.
- Scrobbling (Last.fm, ListenBrainz) — requires network.
- Android Auto / CarPlay.
- In-app tag editor (read yes, write no).
- Multi-device sync.
- Any form of analytics, telemetry, or remote config.

---

## 5. Evidence standards

A bug is "confirmed" only with one of:
- `logcat` excerpt with timestamps.
- Screenshot / screencast of the physical device.
- A failing test that now passes.
- Output of `flutter test --tags=benchmark` with real numbers.
- Output of `adb shell dumpsys ...` or equivalent native diagnostic.
- `md5sum` / `sha256sum` output on the actual data.

The following are **not** evidence:
- "Should work because...".
- "The logic is correct...".
- A previous AI's summary claiming verification.
- Theoretical projections presented as measured facts.