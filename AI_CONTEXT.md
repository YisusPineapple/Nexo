# AI context

- Project: Nexo
- Task 0.1 status: Complete. Verified locally and via GitHub Actions Run #99 (commit 375b30e, workflow 'Nexo Build & Release').
- Hotfix phase (post-0.1, pre-0.2): `+102` (broken imports), `+103` (duplicate Hero tag), `+104` (Result contract in PlaybackRepositoryImpl).
- Current work: Contract Hardening (Slice B). See `docs/state/NEXT_TASK.md` for open sub-items.
- Unverified in this environment: real remote GitHub Release publication. No hosted release claim is made.
- Maintenance pending: Node.js 20/24 warnings, migration of `actions/setup-java@v4` to `v5`, and future migration of `ubuntu-latest` to Ubuntu 26.
- Scope: harden the codebase before Task 0.2 (Restore Safety), without changing the app architecture.
- Important constraint: `AGENTS.md` is normative and was not modified.
- Next task: close Slice B, then Phase 0 / Task 0.2 — Restore Safety.