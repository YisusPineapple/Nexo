# Next task

- Task 0.1 is complete (verified locally and via CI Run #99).
- Hotfix phase (see CURRENT_STATE.md) is closed: `+102`, `+103`, `+104`.
- **Current work: Contract Hardening (Slice B) — before Task 0.2.**
  - Done: `PlaybackRepositoryImpl` (6 methods wrapped, regression tests added).
  - Pending: `SongRepositoryImpl.getSongById` (Slice B2).
  - Pending: Race condition in `PlaybackController.onQueueAdvanced` (Slice B3).
  - Pending: `onQueueEnded` decision (Slice B4 — requires product decision first).
- After Slice B is closed: Phase 0 / Task 0.2 — Restore Safety.
- Do not begin Task 0.2 until Slice B is closed and committed.
- Begin Restore Safety only after an explicit handoff. Do not interpret local verification or CI success as proof of a successful hosted release.