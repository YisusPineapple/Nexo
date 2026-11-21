# CI build numbering

## Policy

The current `pubspec.yaml` version is `0.0.12-beta+114`. The semantic
version remains the user-facing version name. The `+114` suffix remains
the fallback for local builds; CI does not edit or commit `pubspec.yaml`.

All installable artifacts are produced by one stable workflow:
`.github/workflows/build.yml`. It handles pushes to `main`, pull requests,
manual runs, and `v*` version tags. For each workflow run, the `compute_build_number` job calculates
`114 + GITHUB_RUN_NUMBER` in Bash, validates it, and exposes one job
output. Every platform build consumes that same output as `--build-number`. Because normal
builds and tagged releases share the same workflow, they share one
monotonically increasing run counter instead of using separate counters
from separate workflows. Pull-request runs and failed runs can create gaps;
gaps are expected and harmless.

Do not create a separate workflow that builds installable artifacts, and
do not rename, delete, or recreate `build.yml` without deliberately
migrating the sequence. GitHub's `run_number` belongs to one workflow. A
rerun keeps the original run number; do not redistribute an old rerun as a
newer update after a later run has been published.

## Android constraints

Android uses Flutter's `--build-number` as `versionCode`. The workflow
checks that the resulting number is positive and no greater than
`2,100,000,000`. The offset of 114 is based on the current `pubspec.yaml`
`+114` fallback; if a higher versionCode has already been distributed
outside this repository snapshot, the offset must be raised before the
first CI build is published.

For tagged releases, the workflow builds the universal APK and three
split-ABI APKs. The split build uses
`-P force-version-code-ignoring-abi=true`, so all APK variants from the
same run share the same versionCode. The app's `applicationId` and
release signing key must remain stable for Android in-place updates.

Local builds that omit `--build-number` still use `+114`; that fallback
may be lower than a CI build already installed on a device. Use a CI
artifact for update testing, or explicitly provide a build number greater
than the installed build when producing a local release build.

## Verification

1. Create a temporary branch from `main`, commit the workflow changes,
   and push that branch.
2. Manually run `Nexo Build & Release` from GitHub Actions, selecting
   that branch. This exercises the platform builds and split APKs
   without publishing a GitHub Release.
3. Confirm `compute_build_number` emits one validated number and that
   Android, Linux, and Windows consume the same output.
4. Inspect the generated APK versionCode.
5. Do not push a `v*` tag merely for testing: matching tags trigger
   the GitHub Release publisher. Exercise that path only during an
   intentional release or in a disposable test repository.
6. Install a later CI APK over an earlier CI APK using the same
   signing key and `applicationId` to verify an in-place update.

The addition is deliberately performed in Bash, not in a GitHub Actions
expression. The single `compute_build_number` job validates the result
and exports it for all platform build jobs.
