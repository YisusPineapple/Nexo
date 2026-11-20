# Current blockers

## Resolved

- Remote CI verification (Run #99).
- Version reconciliation (+105 real at 9a1e734, +108 phantom, B4 pre-fix unit c2422f5+fa92796, +113 fix, +114 docs).
- HEAD test-count reconciliation (262 − 4 + 1 = 259 = 258 + 1 skipped).
- Drift T2.1 warning diagnosed as benign false positive.
- F1 closed at controller-contract level; F7 closed at code-inspection level (038c8b4).

## Open blockers / decision gates

- Real remote GitHub Release publication unverified.
- T9 P0 pending Helio G85 smoke test.
- Slice B not closed: B3 acceptance pending; B4 open.
- Owner ratification of §10 decisions PENDING; formal decision record missing (code cites §10.x / Fix 5).
- B4/H3 physical Android verification pending (service/notification teardown, no phantom state, no premature end) + screencast (§6).
- syncQueue(-1) safety and finished-queue re-entry paths UNVERIFIED.

## Open items (not automatic P0)

- F2: crossfade-completion unguarded index access — untouched, repro pending.
- Fix 5: Err logging policy for discarded Results — deferred.
- N1: indexing error feedback regression — untouched; test + screencast required.
- `[VERIFICAR]` AI-artifact comment cleanup.

## Historical evidence note

- "259 tests passing" (2026-09-21) not reconcilable; measurement conditions unrecorded. Preserve as annotation, not current evidence.

## Next planned task

- Phase 0 / Task 0.2 — Restore Safety, after Slice B closure + explicit handoff. Not started.