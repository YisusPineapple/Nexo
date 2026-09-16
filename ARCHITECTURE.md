# NEXO MUSIC PLAYER — Architecture and Continuity Document

**Repo:** github.com/YisusPineapple/Nexo (branch `main`)
**Package Name:** `io.github.yisus.nexo`
**Last confirmed version:** `0.0.12-beta+88`
**Database schema (Drift):** `schemaVersion = 16` (verified by
`migration_v14_to_v15_test.dart` and `migration_v15_to_v16_test.dart`)
**General state:** Sprint 9 (Stability and FOSS) in progress.
- T1 closed and merged (stable song identity).
- T2 closed and benchmark-verified on 2026-09-14 (reactive pagination
  over Drift `.watch()`, `SongsWindowNotifier` with LRU, migration v16
  with functional indexes — decision A+A.1 confirmed with real numbers:
  38.38 ms without index → 1.27 ms with index, ~30× improvement. See
  `Sprint9_P0_T2.md` §11).
- **T3 open**: cover art cache bug — diagnosis confirmed on 2026-09-16
  (see §2.5). Fix pending.
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
- **TagLib C++:** confirmed in code — `flutter_taglib` for ID3/cover
  reading.
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

### 2.5 — Cover art cache duplication — DIAGNOSIS CONFIRMED 2026-09-16
**Status:** root cause confirmed, fix pending.

`_buildSong` in `song_repository_impl.dart` computes the cover file name
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
   different chunks produce different `coverId`s → two identical `.jpg`
   files written in the same scan.
2. **Between runs:** every app restart changes the seed. The next scan
   generates new hashes, `file.exists()` returns `false`, more copies
   are written.
3. **Collision when `album == null`:** all tracks without album metadata
   share `'unknown_artist'.hashCode`. That is the opposite problem —
   collision instead of duplication — but from the same design.

**Real-device evidence (Linux dev box, 2026-09-16):**

| Metric | Value |
|---|---|
| Total files in cache | 923 |
| Unique files (by MD5) | 865 |
| Duplicated files | 58 (6.3%) |
| Total size | 474 MB |
| Reclaimable after dedup | ~30 MB |

**Pending reconciliation:** `ARCHITECTURE.md` previously claimed ~1.8 GB
of duplicated art "on device". The local Linux measurement shows 474 MB
/ 58 duplicates. Either the 1.8 GB figure came from the Android device
with a much larger library, or it was a theoretical projection that was
never measured. **This discrepancy must be resolved before T3 can be
declared closed.** Ticket T3 now tracks both: (a) the SHA-256 fix and
(b) reconciling the 1.8 GB figure.

**Fix direction:** replace `String.hashCode` with **SHA-256 of the
`coverBytes` content** as the cache filename. Stable across runs and
isolates by construction, provides content-based deduplication
(two songs with the same cover share one file automatically), and
avoids the `album == null` collision.

Secondary cleanup: after the fix lands, the existing cache directory
must be purged once (a one-shot migration, or a documented manual step)
so the 58 stale duplicates are removed.

---

## 3. Active roadmap (Sprint 9 onwards)

### P0 — blocker
- [ ] **T3** — SHA-256 cover cache fix (§2.5) AND reconcile the 1.8 GB
  vs 474 MB discrepancy. Both are part of the same ticket.

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
These are explicitly **not** to become tickets until T3, T2.1, T5, T6,
T7, T8 and the engine refactor are closed:
- Rust / C++ / Zig rewrite of the audio engine.
- Bit-perfect path with external USB DAC (bypassing the Android audio
  mixer).
- MKV / MP4 as audio-only containers.

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
```