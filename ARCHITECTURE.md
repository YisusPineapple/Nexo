# NEXO MUSIC PLAYER — Architecture and Continuity Document

Repo: `github.com/YisusPineapple/Nexo` (branch `main`)
Package Name: `io.github.yisus.nexo`
Current HEAD: `038c8b4`, version `0.0.12-beta+113`.
Documentation reconciliation build: `0.0.12-beta+114`.
Audit baseline: `9669e61` (+112). Toolchain: Flutter 3.44.7 / Dart 3.12.2.
Database schema (Drift): `schemaVersion = 17` (verified by `migration_v14_to_v15_test.dart`, `migration_v15_to_v16_test.dart`, `migration_v16_to_v17_test.dart`).

General state: Sprint 9 (Stability and FOSS) remains the engineering track, while Phase 0 / Task N covers operational safety and release readiness work.

T1 closed and merged (stable song identity).

T2 closed and benchmark-verified on 2026-09-14 (reactive pagination over Drift `.watch()`, `SongsWindowNotifier` with LRU, migration v16 with functional indexes — decision A+A.1 confirmed with real numbers: 38.38 ms without index → 1.27 ms with index, ~30× improvement. See `Sprint9_P0_T2.md` §11).

T3 closed on 2026-09-17, verified on Linux dev box: 1408 unique cover files, zero duplicates across restart, SHA-256 names (see §2.5 and §3).

T2.1 closed on 2026-11-14: batching of `cover_art_path` writes in `_startBackgroundCoverExtraction` verified in benchmark §5.4 (re-emisiones reducidas de 14.000 a 280 [50×], wall-clock de 21.97 s a 1.65 s [13,3×], CPU-in-map de 4.056 ms a 80,5 ms [98% reducción]). Ver `Sprint9_P0_T2.1.md`.

2026-11-20 read-only technical audit of Slice B/H3 and N1 completed against baseline `9669e61`. Queue-end fix `038c8b4` (+113) subsequently landed and was pushed, implementing F1/F7. Documentation reconciled at +114. B1/B2 closed on evidence; B3 closure pending owner acceptance; B4/H3 remains open pending ratification, screencast, and physical Android verification. See `docs/state/`.

T4 has no recovered ticket record or implementation evidence in the repo history; this is intentionally documented as an evidence gap rather than a fictional scope item.

T5 backlog (renamed from the "T3" originally referenced in `Sprint9_P0_T2.md` §9 — that ticket is now T5).

T6, T7, T8 added 2026-09-16 after roadmap filtering (see §3).

## 0. Glossary

T1..Tn: Sprint 9 tickets, in merge order.

Phase 0 / Task N: operational continuity tasks (safety, backups, restore validation, release-readiness checks) that are not Sprint 9 engineering tickets.

Slice B: Phase 0 contract-hardening work between Task 0.1 and Task 0.2. Not a Sprint 9 ticket; does not renumber the Sprint 9 sequence.

Sprint 9 / Ticket: product engineering work within the sprint; separate tracking system from Phase 0 / Task N; not renumbered or merged.

P0: sprint blocker. P1: non-blocker but tracked.

A+A.1: pagination route = LIMIT/OFFSET with functional indexes (`LOWER(...)`). Chosen over keyset (route B) with benchmark evidence.

LRU: Least Recently Used cache — 4 pages × 50 rows in `SongsWindowNotifier`.

Dual-buffer: Nexo's gapless pattern — two `AudioPlayer` instances, one active one preloading, swapped on transition.

H3 / N1 / F1 / F2 / F7: audit labels only, not repository ticket IDs unless the owner formally assigns identity. F-labels denote audit findings; F1/F7 addressed by `038c8b4`, F2 still open.

## 1. Resolved recently (Sprint 8 — historical, not to be re-litigated)

### 1.1 — Scanner and parallelism

TagLib C++: was chosen in Sprint 8 — `flutter_taglib` for ID3 and cover reading. Abandoned in T9 (see §2.6): the pinned fork ships a 32-bit ARM binary under `lib/arm64-v8a/`, which Android arm64 rejects at load time. Historical note only; the current primary metadata reader is `audio_metadata_reader` (pure Dart).

Scanner parallelism: `Isolate.spawn` per chunk during scan and cover extraction. Not a reusable persistent pool — ephemeral isolates per chunk.

Reactive scanner: `AudioFileScanner` emits via `Stream` (`async*` / `yield*`), confirmed.

### 1.2 — Virtual pagination and RAM (Sprint 9 / T2)

Delivered 2026-09-13, benchmark-verified 2026-09-14.

`SongsWindowNotifier` lives in `lib/presentation/providers/songs_window_provider.dart`: `Notifier<SongsWindowState>` with pages of 50 rows, LRU cache of 4 pages (~200 songs worst case), dynamic `itemCount` in `ListView.builder` with fixed `itemExtent` of 72. `SongsScreen` was rewritten; no longer loads the full table.

Pagination strategy: A+A.1 (LIMIT/OFFSET with functional `LOWER(...)` indexes). §5.1 of the ticket measured 38.38 ms median OFFSET 10000 without indexes; §5.3 measured 1.27 ms with indexes — ~30× improvement. Route B (keyset) discarded with numbers on the table, not estimates.

Methodology note: the first benchmark run (2026-09-13) had a methodology bug — `onCreate` already creates the sort indexes since schema v16, so the "baseline without indexes" was never actually index-free. Fixed with an explicit `DROP INDEX` in §5.1's `setUp`. Full detail in `Sprint9_P0_T2.md` §11.

RAM target: ≤120 MB Android / ≤250 MB PC (`AGENTS.md` §1). Physical device verification pending; the implementation closes the architectural gap that blocked it.

FTS5 search is now paginated too (previously brought up to 500 results in RAM per keystroke; now 50 per page with LRU).

### 1.3 — Reactivity and UI

Drift reactive: true for all library views including Songs. `watchSongsWindow` / `watchSongsCount` / `watchAlphabeticalIndex` over `_db.songs` replaced the full-list `FutureProvider`. `readsFrom: {_db.songs}` declared explicitly on branches reading `songs_fts` to anchor reactivity to the physical table the scanner writes to.

M3 Expressive / `NexoTokens` / `SoftCard`: confirmed.

Rendering: `now_playing_screen.dart` uses `RepaintBoundary` + `.select()` correctly. `MiniPlayer` is already wrapped in a `RepaintBoundary` in `home_shell.dart`; this specific item is not an open P1.

LRU cache: 4 pages × 50 rows. Eviction cancels the evicted page's subscription; a shrinking count (user excludes a folder with the tab open) purges pages outside the new range. Covered by test.

## 2. Open bugs / QA observations

### 2.1 — SongsScreen ghost covers: CLOSED IN T2

Root cause confirmed at the time: `_coversUpdatedController.add(null)` was never invoked — a dead reactive pipe, not a page-invalidation problem. T1 gave stable identity to `SongId`. T2 closed the loop: `coversUpdatedStream` / `_coversUpdatedController` and the full-list `FutureProvider` removed; cover reactivity now comes natively from `watchSongsWindow` over `_db.songs`. Verified by four tests confirming that a change to `coverArtPath` / `title` / `lyricOffsetMs` on a song inside the visible window re-emits with the new value.

### 2.2 — Audio engine refactor and queue-end transition — OPEN, no stable ticket ID assigned

`NexoAudioHandler`: crossfade logic depends on `_isPlayerAActive` / `_isTransitioning` / `_isSkipping` plus pseudo-state `_frozenProgress > 0.0`.

The queue-end gapless transition was a visible bug: when the final track ends with repeat disabled, the player did not transition explicitly to the stopped state. This is not the same work item as the broader engine refactor and remains separately trackable.

No new ticket ID is assigned because the roadmap keeps historical identifiers fixed and does not define a safe successor sequence. The audio engine refactor, the queue-end issue, and the circuit breaker remain intentionally unnumbered backlog notes until that decision is formally made.

2026-11-20 audit + fix `038c8b4` addendum:

- Pre-fix presentation commits `c2422f5` (+109) and `fa92796` (+110) were partial mitigation only; `c2422f5` was not self-consistent without `fa92796` (working-tree desync; +108 never committed).
- Fix `038c8b4` (+113) implements:
  - F7: completion listeners require `identical(player, _activePlayer)`; stale completed from the outgoing player is ignored. Verified by code inspection (synchronous flip + flag-clear; stream events deliver afterward). No automated test (native players); no device evidence yet.
  - F1 engine: `_isEnded` latch set at queue end and stop(); fires onQueueEnded once; play/next/previous no-ops on finished; cleared only by syncQueue/loadDirectly; engine keeps `_currentIndex` at last track.
  - F1 controller: `PlaybackQueueCallbacks` seam; both callbacks share one SerializedTaskQueue; drop events on finished queue; commit state before awaiting persistence. 8 contract tests pin the F1 interleavings.
- Callbacks remain `void` fire-and-forget (audit §10.3 answered by robust-handler design, not signature change).
- Decisions embodied in code comments cite audit §10.1/§10.2/§10.3/§10.4/§10.7 and "Fix 5"; owner ratification PENDING and a formal decision record must be created.
- STILL OPEN: F2 (crossfade-completion `_currentIndex++` unguarded `_queue[_currentIndex]`, untouched); Fix 5 (Err logging policy, deferred); syncQueue(-1) safety and re-entry paths (unverified); physical Android teardown verification; screencast (§6).
- B4 remains open. The commit-message claim of closure is not accepted under §5; controller contract is tested, engine is inspected, device is pending.

### 2.3 — Circuit breaker for errors — OPEN, unverified

Not confirmed in code whether any limit exists on consecutive retries of corrupt files. Still pending a dedicated audit.

### 2.4 — SongId as file path: RESOLVED IN T1

`songs.id` is now `INTEGER PRIMARY KEY` (rowid alias), stable across rename/move within the same indexed folder. Verified by `migration_v14_to_v15_test.dart` (both FK OFF and FK ON groups).

### 2.5 — Cover art cache duplication — FIXED in `0.0.12-beta+89`

Status: root cause confirmed 2026-09-16; fix landed 2026-09-17.

`_buildSong` in `song_repository_impl.dart` computed the cover file name as:

'${album ?? 'unknown'}_${extracted.albumArtist ?? artist}'
    .hashCode
    .toRadixString(16)

Dart's `String.hashCode` is not stable across runs or across isolates (documented behavior of the language). Consequences:

Between isolates: `_startBackgroundCoverExtraction` spawns `workerCount = min(numberOfProcessors, 2)` isolates in parallel, each with its own hash seed. Two songs of the same album landing in different chunks produced different `coverId`s → two identical `.jpg` files written in the same scan.

Between runs: every app restart changes the seed. The next scan generated new hashes, `file.exists()` returned `false`, more copies were written.

Collision when `album == null`: all tracks without album metadata shared `'unknown_artist'.hashCode`. That is the opposite problem — collision instead of duplication — but from the same design.

Real-device evidence:

| Source | Total files | Unique (MD5) | Duplicates | Size |
|---|---|---|---|---|
| Linux dev-box test library | 923 | 865 | 58 (6.3%) | 474 MB |
| Android device (Helio G85) | larger | — | — | ~1.8 GB |

Reconciliation of the 1.8 GB vs 474 MB figures: both are symptoms of the same bug, on two different libraries. The 1.8 GB figure is from the Android device whose music library is substantially larger; the 474 MB figure is from the Linux dev-box test library. The duplication rate is what matters — roughly 6% on both — and the SHA-256 fix addresses it at the source. No further reconciliation is needed; both numbers are recorded here as evidence of the same root cause.

Fix implemented (2026-09-17, `0.0.12-beta+89`):

`computeCoverId` in `song_repository_impl.dart` now returns `sha256.convert(coverBytes).toString()`. Content-addressed, stable across isolates and runs.

Schema 16 → 17 (`app_database.dart`): `UPDATE songs SET cover_art_path = NULL, has_no_cover = 0 WHERE cover_art_path IS NOT NULL`. Runs inside `onUpgrade`, purely SQL — no filesystem I/O inside the migration transaction.

Cache purge is Phase B, post-migration, in `main.dart`, one-shot via a marker file (`cover_cache.v17.purged`) in the app support directory. Best-effort, never aborts the app.

Regression tests: `migration_v16_to_v17_test.dart` (DB state, no filesystem) and four new cases in `song_repository_impl_test.dart` under the `computeCoverId` group.

Verified on Linux dev box, 2026-09-17: fresh-install scan produced 1408 unique cover files (1408/1408, SHA-256 named, 800 MB). Restart and second launch produced identical counts — no drift across processes. Pre-fix cache on the same library had 923 files with 58 duplicates (865 unique). All three duplication vectors confirmed closed. Physical-device verification on Helio G85 is nice-to-have, not blocking — the fix is content-addressed by construction.

### 2.6 — Android metadata silent failure — FIX SHIPPED, PENDING DEVICE VERIFICATION

Status: root cause confirmed 2026-09-18; fix implemented and verified in the Linux dev box 2026-09-21 (`flutter analyze` clean, 259 tests passing). NOT closed — pending smoke test on a physical Helio G85 device, per §5 evidence standards. See §2.6.1 for the delivery record.

Audit note 2026-11-20: the historical "259 tests passing" figure is not reconcilable with later static declaration counts (242 at `2809360`, 246 at `9a1e734`, 254 at `9669e61`, 262 at `038c8b4`) and default-run conditions. The skipped item is the benchmark group under `@Skip`. Measurement conditions for the historical 259 were not recorded. Preserve as historical annotation, not current evidence. See `docs/state/CURRENT_STATE.md` §"Test-count reconciliation".

`flutter_taglib` (fork `MSOB7YY/flutter_taglib`, no version tag) packages a 32-bit ARM binary under `lib/arm64-v8a/`. On arm64 devices, `System.loadLibrary` rejects it with `is 32-bit instead of 64-bit` and does not fall back to `armeabi-v7a/`. Every metadata read on Android therefore throws `Unsupported operation: flutter_taglib is not supported or has been disabled on this platform`, and `_buildSong` falls back to `Unknown Artist` / null album / empty genres / no cover.

Evidence (Helio G85 device, 2026-09-18):

`unzip -l base.apk | grep taglib` → three identical `libflutter_taglib_native.so` files (1470104 bytes each) under `arm64-v8a/`, `armeabi-v7a/`, `x86_64/`.

`file lib/arm64-v8a/libflutter_taglib_native.so` → `ELF 32-bit LSB shared object, ARM, EABI5`.

logcat: `Failed to load native library … is 32-bit instead of 64-bit` for every load attempt.

Fix path (two phases, see §3 T9 and T9.1):

T9 (immediate): drop `flutter_taglib`, promote `audio_metadata_reader` to primary. Unblocks Android today.

T9.1 (planned): migrate to Rust + `lofty` via `flutter_rust_bridge`. Full ABI control, verified cross-compile for arm64-v8a / armeabi-v7a / x86_64.

#### 2.6.1 — T9 delivery record

Implemented across six commits on 2026-09-21/22:

`201bc3e` chore(deps): remove flutter_taglib dependency

`b86b7ee` refactor(data): replace TagLibMetadataDatasource with MetadataDatasource

`c85adf2` feat(data): one-shot T9 fallback metadata recovery

`be08591` test(data): cover MetadataDatasource with T9 fixture suite

`b212c6f` docs: initial T9 write-up (status corrected to "pending device verification" in the commit below)

`2809360` fix(data): restore cover extraction trigger after reparse; correct §2.6 status

Reader. `lib/data/sources/metadata_datasource.dart` is the single backend, using `audio_metadata_reader` (pure Dart). Its public surface is `Future<ExtractedMetadata> read(File, {bool extractCover = true})` — async even though the current backend is synchronous, so a future swap (T9.1) does not touch call sites. `ExtractedMetadata.albumArtist` is always null (`amr` does not expose `ALBUMARTIST`); the field is retained only because `_buildSong`'s signature references it, and `_buildSong` never read it even before T9. A future ticket that surfaces album artist should populate it here, not reintroduce a second reader.

Recovery. `SongRepository.refreshFallbackMetadata` rewrites rows left with placeholder values (`'Unknown Artist'`, null album) by a failed pre-T9 read. It is a targeted DB query, not a directory rescan, and runs once per install behind the `metadata_recovery.t9.done` marker in the app support directory, fired from `main()` under `unawaited()` so it cannot delay `runApp` past the platform ANR budget. The marker is written only on `Ok`; a failed pass retries on next launch.

On a successful pass, the shared `_reparseAndUpsert` tail also fires `_startBackgroundCoverExtraction()` — the cover pass already operates on the full `songs` table rather than on the batch just processed, so it is the correct follow-up for any successful reparse. This closes the "no cover" symptom of the original TagLib bug: recovered rows with a null cover get their art populated without a manual rescan.

Accepted limitation — the recovery predicate is not free on album-less libraries. The candidate query matches rows where `trackArtistId == 'Unknown Artist'` OR (`albumId IS NULL` AND `hasNoCover == false`). The second clause catches legitimately album-less tracks (singles, loose folder imports) that have not yet been flagged as no-cover, so on a library full of such rows the "one-shot" re-parses all of them once. Bounded by the marker file to a single pass. Separately, the recovery instance built in `main()` and the Riverpod `songRepositoryProvider` instance do not share `_isScanning`, so a Settings-triggered "Force Library Rescan" during the recovery window can spawn redundant isolates against the same `songs` table. SQLite WAL serializes writes; worst case is wasted work, not corruption. Tightening the predicate to `trackArtistId == 'Unknown Artist'` alone, or making `_isScanning` `static` with a reset hook for tests, are candidate follow-ups if either is observed in practice. Neither blocks T9.

Known coverage gap. No test asserts positively that a successful `_reparseAndUpsert` fires `_startBackgroundCoverExtraction` when `enableBackgroundCoverExtraction` is left at its default `true`. This is a pre-existing gap — not introduced by T9. Worth closing with a dedicated test in a follow-up; the pass spawns real isolates, so a test would need to either inject a spawner or observe DB state changes with a timeout.

Regression contract. `test/data/sources/metadata_datasource_test.dart` (19 tests over 11 fixtures regenerated by `tool/generate_t9_fixtures.sh`) pins the measured behavior: Vorbis comment ReplayGain is surfaced for FLAC and Opus, and deliberately not for MP3/M4A/WAV/AIFF — even when the tags are present in the file (fixture 03 carries ID3v2 TXXX frames and still reads back null). A future backend swap has to flip these assertions deliberately rather than regress silently.

#### 2.6.2 — Spike evidence (2026-09-18 / 2026-09-19)

Raw stdout from `tool/t9_amr_spike.dart` over the `/tmp/t9-corpus/` corpus is preserved verbatim in the PR description for this commit, not in the repo. Summary of findings, all measured on the same Helio G85 device that exposed the original bug:

ReplayGain. FLAC and Opus expose it via `VorbisMetadata` (`replayGainTrackGain` / `replayGainAlbumGain`). MP3, M4A, WAV and AIFF do not — `Mp3Metadata`, `Mp4Metadata` and `RiffMetadata` have no equivalent. This is a regression vs. the pre-T9 TagLib path on desktop, where TagLib DID load and read MP3 ReplayGain; tracked as a separate P1. On Android the MP3 ReplayGain never worked, so this is not a regression on the target device.

Corrupt input. A truncated MP3 surfaces `MetadataParserException` wrapping a `RangeError` from `Buffer.read`. The datasource's try-catch collapses it to `ExtractedMetadata.empty()`, and `_buildSong` assigns the fallback artist. That row is what the recovery pass rewrites on next launch. Fixture 07 in the regression suite exercises this path.

Duration. 7 of 8 formats land within 30 ms of ffprobe. Opus is off by -348 ms (marginal; tolerated). All other deltas are ≤ 26 ms.

OGG. A raw fixture reported `durationMs: 0` and a -194 s delta; a second iteration reported -211 s. Root cause was a silence-only Ogg produced by `ffmpeg` when the source `.flac` was piped through a raw `pcm_s16le` intermediate without `-map_metadata -1`. Regenerated cleanly through `-c:a libvorbis -q:a 5` from a source with metadata, the OGG path measures a 0 ms delta (report 3). Not a reader bug.

AIFF mojibake. The `"AdiÃ³s"` title in report 1 was an FLAC→AIFF transcoding interaction (UTF-8 bytes reinterpreted as Latin-1), not a general reader bug. The synthetic AIFF fixture in the regression suite does not exhibit it.

## 3. Active roadmap (Sprint 9 onwards)

### P0 — blocker

[ ] T9 — Android metadata silent failure (§2.6). Fix shipped, pending Helio G85 smoke test before closing.

### P1 — non-blocker

[x] T2.1 — Batch `cover_art_path` writes in `_startBackgroundCoverExtraction`. Closed on 2026-11-14 with benchmark §5.4 verified. Ver `Sprint9_P0_T2.1.md`.

[ ] T4 — No reliable source or Git evidence recovered. The absence of evidence is the documented finding: do not invent historic scope.

[ ] T5 (renamed from the "T3" in `Sprint9_P0_T2.md` §9) — Pagination of `multiArtistSongsProvider` / `genreSongsProvider` in `grouped_library_providers.dart`, and migration of detail screens to `itemExtent`.

[ ] T6 — Multi-artist / multi-genre UI. Data layer supports it; missing UI and queries.

[ ] T7 — Audit: which formats actually decode on which platform. Extension table complete; decoder behavior unknown. Audit ticket, not feature.

[ ] T8 — Audit: audio resampling and RAM profile per quality tier against the 120 MB ceiling.

[ ] No stable ticket ID assigned yet: audio engine refactor (`NexoAudioHandler`, §2.2).

[ ] No stable ticket ID assigned yet: circuit breaker for errors (§2.3).

[ ] No stable ticket ID assigned yet: queue-end transition (§2.2). Fix `038c8b4` implemented F1/F7; B4 open pending ratification, screencast, Android verification. F2 remains open.

[ ] No stable ticket ID assigned yet: indexing error feedback regression (audit label N1). `c2422f5` removed the HomeShell error SnackBar; library hub has no AsyncError surface. Fix requires regression test + screencast. Independent from H3.

[x] `MiniPlayer` repaint fix — resolved by the `RepaintBoundary` wrapper in `home_shell.dart`; no open backlog item.

### Deferred — exploration only, not tickets

Not to become tickets until T5, T6, T7, T8 and the engine refactor are closed:

Rust / C++ / Zig rewrite of the audio engine.

Bit-perfect path with external USB DAC.

MKV / MP4 as audio-only containers.

### Planned (P1)

[ ] T9.1 — Proposed evaluation: Rust + `lofty` via `flutter_rust_bridge` only if measured benefit justifies ABI/maintenance/distribution costs. Research task, not irreversible decision.

### Housekeeping backlog (low priority)

Reorganize `docs/` structure. Split `CONVENTIONS.md` if it grows past ~200 lines. Clean up the `[VERIFICAR]` AI-artifact comment in `nexo_audio_handler.dart`.

### Sprint 9 Exit Criteria

Sprint 9 is not complete until all required tickets have explicit status and supporting evidence recorded:

implementation completed and verified, or explicitly open with a documented evidence gap;

acceptance criteria checked against code and measured output, not assumed from narrative;

quality gates run and recorded (`flutter analyze`, target tests/benchmarks, required hardware verification);

no open P0 blockers at closure;

status, debt, and documentation updated after the change, including pending verification notes;

local verification, CI verification, and published release kept distinct, with no release claim unless the hosted artifact is verified.

If a condition cannot yet be checked, it stays pending rather than declared satisfied.

### Technical debt and review findings

Known coverage gap. The successful `_reparseAndUpsert` trigger path is not positively asserted in tests. Genuine gap, not a claim the path is broken.

2026-11-20 audit debt:
- F2: crossfade-completion unguarded index access — open, untouched by 038c8b4.
- Fix 5: Err logging policy for discarded saveQueue/stop Results — deferred in code; owner decision required.
- syncQueue(-1) safety and finished-queue re-entry paths — unverified.
- B3 test limitation: seam tests now partially cover onAdvanced; closure pending owner acceptance.
- B1 Err-test symmetry: getAllQueues/deleteQueue lack DB-closed Err tests.
- Drift test hygiene: T2.1 multiple-AppDatabase warning is a benign false positive; optional cleanup.
- Historical test count: 259 preserved with non-reconciled annotation; current default-run evidence 258 passed + 1 skipped.
- `[VERIFICAR]` AI-artifact comment in nexo_audio_handler.dart — cleanup pending.

Backup review note (pending verification during Restore Safety). Reviewing `lib/data/repositories/backup_repository_impl.dart` surfaced code-level hypotheses not yet proven by execution or regression test:

`createBackup` appears to ignore `includePlaylists` and `includeSettings` when `includeLibrary` is true (single archive payload, no branching on non-library flags).

The UI exposes content toggles, but the repository appears to treat the archive as effectively library-only.

`restoreBackup` closes the active database and copies the extracted SQLite file into place without validating the archive beyond the presence of `nexo.sqlite`.

These are observed code behaviors, not confirmed defects; verify during Phase 0 / Task 0.2 — Restore Safety; treat as hypotheses until proven or disconfirmed.

## 4. Non-goals (not to be re-litigated before 1.0)

Nexo explicitly will not implement, by product decision and RAM ceiling:

Online streaming or third-party service integrations.

Scrobbling (Last.fm, ListenBrainz) — requires network.

Android Auto / CarPlay.

In-app tag editor (read yes, write no).

Multi-device sync.

Any form of analytics, telemetry, or remote config.

## 5. Evidence standards

A bug is "confirmed" only with one of:

`logcat` excerpt with timestamps.

Screenshot / screencast of the physical device.

A failing test that now passes.

Output of `flutter test --tags=benchmark` with real numbers.

Output of `adb shell dumpsys ...` or equivalent native diagnostic.

`md5sum` / `sha256sum` output on the actual data.

The following are not evidence:

"Should work because...".

"The logic is correct...".

A previous AI's summary claiming verification.

Theoretical projections presented as measured facts.