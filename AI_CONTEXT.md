# AI context

- Project: Nexo
- Task 0.1 status: Local implementation and verification are complete. A hosted GitHub Actions run and real release publication remain unverified.
- Implemented: mandatory signing validation before APK, AAB and universal APK packaging; Flutter quality gates; scoped GitHub Actions permissions; keystore password and alias validation; and cleanup of signing files.
- Unverified in this environment: any GitHub-hosted workflow execution and any real remote GitHub Release publication. This workspace does not have a live GitHub runner, and no real signing secrets were used.
- Scope: harden Android release signing, add quality gates to build and release workflows, and document the signing contract without changing the app architecture.
- Important constraint: `AGENTS.md` is normative and was not modified.
- Known drift: version metadata is inconsistent between `pubspec.yaml` and `ARCHITECTURE.md` and was left unchanged for this task.
- Next task: Phase 0 / Task 0.2 — Restore Safety. It has not started. Hosted workflow verification remains pending.
