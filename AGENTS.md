# Nexo — Non-Negotiable Rules for AI Agents and Contributors

This file is loaded as read-only context by AI assistants (Claude, Gemini,
DeepSeek, ChatGPT, etc.) and human contributors. Do not edit it yourself;
ask Piñá to update it if a rule changes.

**Rule 0 — Context loading (do this first):**
Read `ARCHITECTURE.md` before proposing or reviewing any code. It holds
the current state, the open tickets, and the definition of "confirmed"
vs. "pending". Read `CONVENTIONS.md` for the non-negotiable code rules.
If the task touches a file you have not seen in full in this session,
request it before editing.

---

## 1. Target hardware and performance

- **Android:** MediaTek Helio G85, 2 GB RAM. Memory ceiling: ≤120 MB.
- **PC:** Intel Pentium E5800 (2010), 4 GB RAM. Memory ceiling: ≤250 MB.
- **UI rendering:** zero real-time heavy GPU shaders. `BackdropFilter`
  and glassmorphism are **forbidden**. Use Soft UI / M3 Expressive
  (subtle `BoxShadow`, tonal surface colors like
  `surfaceContainerHighest`).
- **Lists:** always `ListView.builder` / `GridView.builder` /
  `SliverFixedExtentList` with fixed `itemExtent` for O(1) scroll
  performance on 15,000+ item lists.
- **`CustomPainter`:** allowed only for single, non-repeating,
  functional visualizations with a correct `shouldRepaint` (e.g.
  `_EqCurvePainter`). Never inside repeated list/grid items.
- **RAM protection:** every `Image.file` / `Image.asset` must use
  `cacheWidth` multiplied by
  `MediaQuery.devicePixelRatioOf(context).round()`.
- **CPU protection:** constantly updating UI (progress slider, marquee
  text) must be wrapped in `RepaintBoundary`.
- **Isolate protection:** heavy background loops must include
  `await Future.delayed(const Duration(milliseconds: 50))` to prevent
  100% CPU and thermal throttling.
- **Scanner protection:** directory scanners must emit via `Stream`
  (`async*` / `yield*`), never block to return a massive `List`.

---

## 2. Architecture (strict Clean Architecture)

- **Domain** (`lib/domain/`): pure Dart. ZERO Flutter dependencies, ZERO
  imports from `data/` or `presentation/`.
- **Data** (`lib/data/`): implements interfaces from
  `domain/repositories/`. Never the reverse.
- **Presentation** (`lib/presentation/`): Riverpod (`Notifier`,
  `AsyncNotifier`, `FutureProvider`, `StreamProvider`). Never
  `StateNotifier` (deprecated). Never import repositories or the
  database directly — always go through a `UseCase`.
- Every repository and use case returns `Result<T, Failure>`
  (`lib/core/utils/result.dart`). Throwing exceptions or using
  `try-catch` to bubble business errors up across these layers is
  strictly forbidden. Use `.unwrapOrThrow()` **only** inside Riverpod
  providers.

---

## 3. Audio engine (`NexoAudioHandler`)

- Never unify `_playerA` / `_playerB` into a single player. The
  double-buffer architecture is intentional for gapless playback and
  crossfade transitions.
- Never call `.stop()` on the active playing player that sustains the
  visible foreground service during a transition — it breaks the
  double-buffer pattern and causes notification flicker.
- Live configuration changes (crossfade, performance profile) must be
  applied via live setters called from `ref.listen`, never read only
  once at startup.
- Audio focus handling lives in `NexoAudioHandler`, not in the UI layer.
  `AUDIOFOCUS_LOSS` → pause. `AUDIOFOCUS_LOSS_TRANSIENT` → pause and
  resume on gain. `ACTION_AUDIO_BECOMING_NOISY` (headphones unplugged)
  → pause. Never keep playing.

---

## 4. Database (Drift)

- Never edit `*.g.dart` files manually — they are generated.
- If you change a table or `TypeConverter`, state it explicitly and run:
  `dart run build_runner build --delete-conflicting-outputs`
- All schema migrations go into `MigrationStrategy.onUpgrade` in
  `app_database.dart`, incrementing `schemaVersion`. **Never modify an
  existing, already-released `if (from < N)` migration block** — always
  add a new one.
- Every migration requires a migration test following the pattern of
  `migration_v14_to_v15_test.dart` and `migration_v15_to_v16_test.dart`.

---

## 5. Coding standards

- ALL code, variables, classes, comments, docstrings, and commit
  messages: in **English**. Conversational chat responses to Piñá: in
  **Spanish**.
- Commit format: Conventional Commits, English, imperative mood.
  `<type>(<scope>): <description>` with types `feat`, `fix`, `refactor`,
  `perf`, `test`, `docs`, `chore`, `build`.
- Deliver **full, complete files** ready to copy-paste. Placeholders
  like `// rest of code` or `// ... existing code` are strictly
  forbidden. If you modify a file, output the entire file.
- Always run a mental `flutter analyze` before outputting code. Ensure
  all `if` statements have curly braces `{}`.

---

## 6. Testing

- Any change to `lib/domain/` or `lib/data/` requires a test in `test/`
  mirroring the same path.
- Any bug fix requires a regression test that fails before the fix.
- Migrations require a migration test.
- UI changes are manually verified with a 30-second screencast attached
  to the PR.

---

## 7. Dependencies

- New runtime dependencies require explicit justification:
  - License compatible with GPLv3 (MIT / BSD / Apache-2.0 OK, no
    proprietary).
  - Supports Android + Linux + Windows (or has a documented desktop
    fallback).
  - Does not require network permission at runtime.
  - Does not add more than 2 MB per platform to the release artifact.
- No analytics, no telemetry, no remote config packages. Ever.

---

## 8. Release signing

- The release build MUST be signed with a stable, persisted keystore
  referenced via `android/key.properties` (gitignored). **Never** with
  `signingConfigs.getByName("debug")`. A debug keystore regenerated on
  every CI run produces a different signature per build, making the app
  impossible to update without uninstalling first.
- If `android/key.properties` is missing, the release build must fail
  loudly, not fall back to debug signing.
- See `README.md` §"Release signing" for the exact secret names
  (`RELEASE_KEYSTORE_BASE64`, `RELEASE_KEYSTORE_PASSWORD`,
  `RELEASE_KEY_ALIAS`, `RELEASE_KEY_PASSWORD`) and the CI workflow that
  consumes them.

---

## 9. Versioning policy

- Build number (`+N` in `pubspec.yaml`, maps to Android `versionCode`):
  increment on **every** commit, without exception, strictly
  increasing.
- Semantic version (`0.0.X-beta`): increment the patch digit only when
  a full sprint closes with meaningful shipped functionality.
- Example: during a sprint, `0.0.11-beta+51`, `+52`, `+53` stay at
  `0.0.11` until the sprint closes; the next sprint starts at
  `0.0.12-beta+N`.

---

## 10. Debugging philosophy

- Never declare a platform-specific or OEM-specific bug "fixed" without
  real evidence from the physical device (native diagnostics, `logcat`,
  reproducible manual test). A fix that "should work" based on theory
  alone is not confirmed.
- When another AI reports a fix as complete, treat it as unconfirmed
  until there is real evidence — apply independent technical judgment,
  do not accept external proposals at face value.
- See `ARCHITECTURE.md` §5 for the exact list of what counts as
  evidence.

---

## 11. What to do when in doubt

Ask before assuming. A short pause is always better than a fix that
violates any of the above rules.
```