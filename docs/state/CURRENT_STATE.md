# Current state

## Baseline anchors

- Current HEAD: `038c8b4` (= origin/main), version `0.0.12-beta+113`.
- Documentation reconciliation build: `0.0.12-beta+114`.
- Read-only technical audit baseline: `9669e61` (+112), completed 2026-11-20.
- Toolchain pinned in `9669e61`: Flutter 3.44.7 / Dart 3.12.2. Drift `schemaVersion = 17`.
- Local verification at `038c8b4` with docs in tree: `flutter analyze` clean; `flutter test` 258 passed + 1 skipped.
- The audit itself modified no files. The queue-end fix `038c8b4` was authored and pushed outside the audit session (Jesús Piña, 2026-11-19), consuming +113 before this reconciliation. This docs commit is +114.

## Task 0.1 — complete

- Implemented: release signing validation before APK/AAB/universal APK; quality gates in both workflows; least-privilege permissions; keytool password/alias validation; cleanup after artifact publication. No debug-signing release fallback.
- Verified locally and via GitHub Actions Run #99 (commit `375b30e`). CI artifacts: nexo-android-apk, nexo-linux-x64, nexo-windows-x64.
- Real remote GitHub Release publication remains unverified. CI artifacts are not a hosted release claim.

## Maintenance pending

- Node.js 20/24 warnings; setup-java v4→v5; ubuntu-latest→Ubuntu 26.

## Hotfix phase — closed

- `+102`: broken relative imports in for_you_screen.dart.
- `+103`: duplicate Hero tag crash (np_ prefix).
- `+104`: Result contract in PlaybackRepositoryImpl, with regression tests.
- Verification gap: `+103` is a UI change with no recorded screencast. Not reopened, but not claimed device-verified.
- No schema/migration changes in the hotfix phase.

## Version reconciliation — closed

| Commit | Version | Note |
|---|---|---|
| `9a1e734` | +105 | State doc claimed +104; text was stale at write time. Docs commit did increment. |
| `1520afc` | +106 | B2 |
| `ddce8bc` | +107 | B3 |
| `c2422f5` | +109 | +108 never committed (phantom working-tree build). |
| `fa92796` | +110 | B4 part 2 |
| `2744227` | +111 | T2.1 closure |
| `9669e61` | +112 | Flutter pin |
| `038c8b4` | +113 | Queue-end fix (F1/F7) |
| this commit | +114 | Documentation reconciliation |

- §9 strict monotonic increase satisfied across all commits.
- `c2422f5` is not self-consistent without `fa92796` (working-tree desync admitted in fa92796 message). B4 pre-fix history is the logical unit c2422f5+fa92796; bisection between +109/+110 unreliable. Historical note; do not rewrite.

## Queue-end fix — `038c8b4` (+113)

Status: IMPLEMENTED. Controller contract tested; engine changes inspected; physical Android verification PENDING. B4 remains open.

What landed (verified in diff):
- F7: `_playerA`/`_playerB` completion listeners now require `identical(player, _activePlayer)`. Stale completed from the outgoing player after a crossfade flip or instant skip is ignored. Reasoning is sound: the flip and flag-clear are one synchronous block; stream events deliver afterward.
- F1 engine: `_isEnded` latch set at queue end and in stop(); suppresses a second onQueueEnded; makes play()/advanceToNext()/advanceToPrevious() no-ops; cleared only by syncQueue/loadDirectly. Engine keeps `_currentIndex` at the last track (deliberate, documented divergence from domain -1).
- F1 controller: extracted `PlaybackQueueCallbacks` seam. Both callbacks share one SerializedTaskQueue; drop events on a finished queue (currentIndex < 0); commit state BEFORE awaiting persistence. Wiring is 1:1 (handler.onQueueAdvanced = queueCallbacks.onAdvanced).
- Callbacks remain `void` fire-and-forget (audit §10.3 answered by the robust-handler alternative, not a signature change).

Tests: 8 new contract tests in playback_queue_callbacks_test.dart (happy path ×2, F1 regression ×4, null state ×2). Suite 250→258. These pin the NEW seam contract; they are not fails-before tests against the old code (the seam did not exist pre-fix). Same limitation category as B3, but the exact F1 interleavings are deterministically pinned (gated save + shared FIFO barrier).

Decisions embodied in code comments (citing audit §10.x), owner ratification PENDING:
- §10.1 both callbacks share one serializer.
- §10.2 inactive-player completed ignored.
- §10.3 engine never awaits callbacks; safety via serializer + guards + latch.
- §10.4 engine keeps index; finished = transport no-op; re-entry only via explicit load.
- §10.7 play/next/previous no-op on finished.
- Persistence best-effort; Err logging policy deferred ("audit Fix 5").

These references point to a decision record that does not yet exist in the repo. This reconciliation records them as embodied-in-code, pending ratification. A formal decision record must be created so the code citations resolve.

## Open items after 038c8b4 (do not declare closed)

- F2: crossfade-completion `else { _currentIndex++; }` + unguarded `_queue[_currentIndex]` — UNTOUCHED by 038c8b4. Deduced trigger: live repeat-all→off during wrap crossfade. Repro pending.
- Fix 5: Err policy for discarded saveQueue/stop Results — deferred explicitly in code comment. Open debt.
- N1: indexing error feedback regression (c2422f5 removed HomeShell SnackBar; library hub has no AsyncError surface) — UNTOUCHED. Independent fix, test + screencast required.
- syncQueue(-1) safety: visible body indexes `_queue[currentIndex]` with no confirmed negative guard (elided lines may contain one). Any controller path syncing a finished queue could hit `_queue[-1]`. UNVERIFIED — needs full playback_providers.dart + nexo_audio_handler.dart.
- Finished-queue re-entry paths: latch clears only via syncQueue/loadDirectly. Must confirm all user routes (tap song, jumpToIndex, shuffle, repeat) reach those. UNVERIFIED.
- `[VERIFICAR]` AI-artifact comment in nexo_audio_handler.dart (integration instruction shipped as code comment) — cleanup pending in a follow-up commit; do not rewrite published history.
- B4 closure: decision ratification + screencast (§6) + physical Android teardown verification.
- B3 closure: owner acceptance of test limitation (now partially covered by seam tests).

## Slice B status

- B1: closed as previously recorded; four Err tests confirmed. Symmetry debt: getAllQueues/deleteQueue lack Err tests.
- B2: closed on evidence (1520afc, test :936, fails-before by inspection).
- B3: implemented; closure pending owner acceptance.
- B4: OPEN (see above).

## H3 / queue-end audit findings status

H3 is an audit label, not a repo ticket ID. Queue-end item remains unnumbered.
- F1: closed at controller-contract level (8 tests) + engine latch inspected. Device pending.
- F7: closed at code-inspection level. No automated test (native players), no device evidence.
- F2: OPEN, untouched.
- Restore (N5): resolved — RestoreSessionUseCase preserves finished queue without loading engine. Depends on persistence whose Result is discarded (Fix 5).

## Sprint 9 track

- T2.1 closed 2026-11-14 (2744227) with benchmark evidence.
- T9 P0 open: fix shipped, pending Helio G85 smoke test. Independent of H3; may proceed in parallel.
- Sprint 9 and Phase 0 tracks interleaved in time, separate tracking systems.

## Drift warning in T2.1 test

- Benign false positive: setUp db and testDb use distinct NativeDatabase.memory executors; testDb.close() present; setUp db idle. Shared-executor condition absent. T2.1 closure stands. Optional hygiene: close setUp db first or scope a justified suppression.

## Test-count reconciliation

- Static declarations: 2809360=242, 9a1e734=246, 9669e61=254, 038c8b4=262 (254+8).
- No test files deleted. +4 = B1 Err tests; +8 (to 9669e61) = B2(1)+helper(3)+T2.1(4); +8 (to 038c8b4) = seam tests.
- HEAD runtime: benchmark file has 4 tests under @Skip reported as 1 → 262 − 4 + 1 = 259 = 258 passed + 1 skipped. ✓
- Skipped test: song_repository_pagination_benchmark_test.dart:43 (@Skip, requires --tags=benchmark --run-skipped).
- Historical "259 tests passing" (2026-09-21, §2.6) is NOT reconcilable with later static counts; @Skip already existed at 2809360; T9 suite has no loops. Measurement conditions unrecorded. Preserve as historical annotation, not current evidence. (Coincidence: current runtime total is also 259 items — distinct from the historical claim.)
- No evidence of coverage loss by deletion.

## Pending decisions / process notes

- Owner ratification of the §10 decisions embodied in 038c8b4 — PENDING.
- Formal decision record must be created (code cites §10.x / Fix 5 which do not exist as docs).
- External second review (Qwen/DeepSeek) not recorded; if skipped, record as explicit owner decision.
- B3/B4 closure decisions pending.
- H3 formal ticket identity pending owner decision; no number invented.
- N1 priority pending owner decision.
- Task 0.2 not started; requires Slice B closure + explicit handoff.