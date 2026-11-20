# Next task

## Gate status

- Task 0.1 complete (Run #99). Hotfix phase closed (+102/+103/+104).
- Queue-end fix 038c8b4 (+113) landed and pushed; documentation reconciled at +114.
- Current work: ratify decisions, verify open items, close Slice B, formalize H3 — before Task 0.2.
- Do not begin Task 0.2 until Slice B is closed and committed, with explicit handoff.
- Do not interpret CI success as a hosted release.

## Slice B status

- B1: closed (symmetry debt recorded).
- B2: closed on evidence.
- B3: implemented; closure pending owner acceptance of test limitation (seam tests now partially cover it).
- B4: OPEN. Fix implemented + controller contract tested; engine inspected. Missing: ratification, screencast, Android verification.

## Required before B4 / H3 closure

1. Ratify the §10 decisions embodied in 038c8b4 and create a formal decision record (so code citations §10.x / Fix 5 resolve).
2. Verify syncQueue(-1) safety and all finished-queue re-entry paths (need full playback_providers.dart + nexo_audio_handler.dart).
3. Reproduce or refute F2 (untouched by 038c8b4); if confirmed, regression test first, then fix.
4. Physical Android verification: queue-end teardown, no phantom mini-player, no premature end, screencast (§6).
5. Decide Fix 5 (Err logging policy) — implement or formally defer with owner sign-off.
6. Update state docs with evidence, not commit-title claims.

## Independent items

- N1: restore indexing error feedback (regression test + screencast). Do not mix with H3 without justification.
- `[VERIFICAR]` comment cleanup in nexo_audio_handler.dart (follow-up commit; no history rewrite).
- T9 Helio G85 smoke test (Sprint 9 P0, parallel, independent).

## After Slice B closure

- Explicit handoff, then Phase 0 / Task 0.2 — Restore Safety.
- Task 0.2 starts by verifying backup hypotheses with tests; do not promote them to confirmed defects before execution evidence.