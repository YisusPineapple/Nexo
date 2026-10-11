# AI context

- Project: Nexo
- Task 0.1 status: Complete. Verified locally and via GitHub Actions Run #99 (commit 375b30e, workflow 'Nexo Build & Release').
- Implemented: mandatory signing validation before APK, AAB and universal APK packaging; Flutter quality gates; scoped GitHub Actions permissions; keystore password and alias validation; and cleanup of signing files.
- Unverified in this environment: real remote GitHub Release publication remains unverified. The local workspace does not store signing secrets or provide a GitHub-hosted runner; the remote CI execution successfully generated the Android APK.
- Maintenance pending: Node.js 20/24 warnings, migration of `actions/setup-java@v4` to `v5`, and future migration of `ubuntu-latest` to Ubuntu 26.
- Scope: harden Android release signing, add quality gates to build and release workflows, and document the signing contract without changing the app architecture.
- Important constraint: `AGENTS.md` is normative and was not modified.
- Known drift: version metadata is inconsistent between `pubspec.yaml` and `ARCHITECTURE.md` and was left unchanged for this task.
- Next task: Phase 0 / Task 0.2 — Restore Safety. It has not started.
