# AI context

Project: Nexo

Current HEAD: `038c8b4` (origin/main), version `0.0.12-beta+113`.
Documentation reconciliation build: `0.0.12-beta+114`.
Audit baseline: `9669e61` (+112). Toolchain: Flutter 3.44.7 / Dart 3.12.2. Drift `schemaVersion = 17`.

Task 0.1 status: Complete. Verified locally and via GitHub Actions Run #99 (commit `375b30e`).

Hotfix phase (post-0.1, pre-0.2): closed. `+102` (imports), `+103` (Hero tag), `+104` (Result contract in PlaybackRepositoryImpl).

Queue-end fix: `038c8b4` (+113) implements the F1/F7 audit findings.
- F7: completion listeners require the emitting player to be active.
- F1: engine `_isEnded` latch + controller `PlaybackQueueCallbacks` seam (shared FIFO, finished-queue guards, state committed before persistence).
- 8 contract tests added (`playback_queue_callbacks_test.dart`); suite now 258 passed + 1 skipped.
- Decisions are embodied in code comments citing audit §10.1/§10.2/§10.3/§10.4/§10.7; owner ratification is PENDING and must be recorded.

Slice B status:
- B1: closed (four Err tests confirmed; symmetry debt for getAllQueues/deleteQueue).
- B2: closed on evidence (`1520afc`, test at song_repository_impl_test.dart:936).
- B3: implemented; closure pending owner acceptance of the test limitation (now partially covered by the new seam tests).
- B4: OPEN. Fix implemented and contract-tested at controller level; engine changes verified by inspection only. Still missing: decision ratification, 30s screencast (§6), physical Android verification of service/notification teardown.

Open items (do not declare closed):
- F2: crossfade-completion `_currentIndex++` unguarded access — untouched by 038c8b4.
- Fix 5: Err logging policy for discarded saveQueue/stop Results — deferred in code comment.
- N1: indexing error feedback regression — untouched.
- syncQueue(-1) safety and finished-queue re-entry paths — unverified.
- `[VERIFICAR]` AI-artifact comment in nexo_audio_handler.dart — cleanup pending.
- T9: P0 open, pending Helio G85 smoke test.

Unverified: real remote GitHub Release publication. No hosted release claim.

Maintenance pending: Node.js 20/24 warnings, setup-java v4→v5, ubuntu-latest→Ubuntu 26.

Scope: harden before Task 0.2 without architecture changes. AGENTS.md is normative and was not modified.

Next: ratify decisions, verify open items, close Slice B, explicit handoff to Phase 0 / Task 0.2 — Restore Safety. Do not begin 0.2 before closure.