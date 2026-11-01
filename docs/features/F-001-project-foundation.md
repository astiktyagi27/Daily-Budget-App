# F-001: Project foundation

| | |
|---|---|
| **Phase** | 0 |
| **Status** | Done (Gate 4 passed 2026-11-01, 13/13 ACs; Phase 0 signed off at Gate 5) |
| **Plan** | [`plans/F-001-project-foundation.md`](../../plans/F-001-project-foundation.md) |
| **Test cases** | [`tests/F-001-project-foundation.md`](../../tests/F-001-project-foundation.md) |
| **Tasks** | T-001 … T-008 (Developer), T-009 (Tester), T-010 (Orchestrator, phase-end commit + push) — see `docs/TASKS.md` |

## 1. What it is *(Product Manager)*
The empty but correctly built starting point for the app. It creates the Flutter project in `app/`, sets up the folder layout every later feature will use, switches on strict automatic code checks and the test runner, adds one plain placeholder screen so there is something to launch, starts a git repository linked to the project's GitHub remote (agents commit nothing during the phase; the Orchestrator makes one phase commit and push at the end, CLAUDE.md rule 9), and records the core library choices in `docs/DECISIONS.md`. Nobody outside the team will ever see this feature directly; its value is that every later phase starts from a clean, checked, testable base instead of fixing foundations mid-way.

**User stories:**
- As the **Owner**, I want to see a real Flutter app that starts and passes its checks with zero problems, and read which libraries were chosen and why, so that I know the project is set up properly before any features are built.
- As the **team** (Developer, Tester, Project Manager), I want a fixed folder layout, strict lint rules, a working test setup and version control from day one, so that every later feature is built, tested and reviewed the same way.

## 2. How it behaves *(Product Manager)*
All steps below run on the Owner's Windows laptop (Flutter 3.47.9 stable / Dart 3.13.7 at `C:\src\flutter`), from the project folder `C:\Users\mayan\Documents\Idea bank\daily-budget-app` (note the space in `Idea bank`). The Android SDK is **not** installed yet, so everything except step 8 must work without it.

1. **Project exists.** `app/` contains a Flutter project with an Android target (`app/pubspec.yaml`, `app/lib/main.dart`, `app/android/`).
2. **Folder layout.** `app/lib/` contains exactly the four layer folders from `docs/STANDARDS.md` §3 — `core/`, `data/`, `domain/`, `features/` — plus `main.dart` (and, if the Developer chooses, a single top-level app file such as `app.dart`). `domain/` contains only pure Dart (no `package:flutter` imports).
3. **Strict checks.** From `app/`, `flutter analyze` prints `No issues found!`. The lint set is stricter than Flutter's default and is named in `DECISIONS.md`. `dart format` changes nothing.
4. **Tests run.** From `app/`, `flutter test` runs and passes. Every test name starts with a test case ID, e.g. `TC-001-05 placeholder screen shows app title`. Flutter's generated "counter" sample test is gone.
5. **Placeholder screen.** The app opens one plain screen showing the working title and one line saying setup is in progress (exact text in section 5). No buttons, no navigation, no theme work, no real data.
6. **Git.** The project root is a git repository with a `.gitignore` that keeps build outputs and local machine files out. Remote `origin` is `https://github.com/astiktyagi27/Daily-Budget-App.git` (branch `main`). During the phase `git log` shows **no commits** — agents never commit. At the end of the phase, after the Project Manager's sign-off and the CEO report, the Orchestrator makes exactly one commit (`Phase 0: Project foundation`) and pushes it to `origin main` (CLAUDE.md rule 9).
7. **Decisions recorded.** `docs/DECISIONS.md` has one row per core library choice (state management, local database, logging, lint set, and any test helper added) with the exact version, a one-line reason, date and "decided by". Flutter and Dart versions are recorded too. Everything is free and open source.
8. **Emulator (later).** Once Android Studio, the Android SDK and an emulator are installed (README §13), `flutter run` starts the app on the emulator and the placeholder screen appears. Until then this item is **Blocked**, not failed, and Phase 0 cannot be signed off.

Example of what the Owner should see when the Tester runs the checks (illustrative, not exact):
```
> flutter analyze
Analyzing app...
No issues found!

> flutter test
00:03 +1: All tests passed!
```

## 3. Acceptance criteria *(Product Manager)*
All commands are run from `app/` unless stated otherwise. "Pass" means exactly what is written; anything else is a fail.

| ID | Given / When / Then |
|---|---|
| AC-1 | **Flutter project with Android target.** Given the repository, when the Tester lists `app/`, then `pubspec.yaml`, `lib/main.dart`, `test/` and `android/` exist; `pubspec.yaml` has an SDK constraint that accepts Dart 3.13.7; and there are **no** `web/`, `windows/`, `linux/` or `macos/` folders (Android-only target; `ios/` is also absent unless the plan gives a reason). |
| AC-2 | **Folder structure per STANDARDS.md §3.** Given `app/lib/`, when the Tester lists it, then the folders `core/`, `data/`, `domain/` and `features/` all exist, each contains at least one file (so git can track it), and there are no other folders directly under `lib/`. |
| AC-3 | **Domain is pure Dart.** Given `app/lib/domain/`, when the Tester searches every `.dart` file in it for `package:flutter` and `dart:ui`, then there are 0 matches. |
| AC-4 | **Strict lints, zero issues.** Given `app/analysis_options.yaml`, when the Tester opens it, then it enables a lint set stricter than the default `flutter_lints` (the set is named, with version, in `DECISIONS.md`); and when the Tester runs `flutter analyze`, then it prints `No issues found!` and exits with code 0 (0 errors, 0 warnings, 0 infos). |
| AC-5 | **Formatting clean.** When the Tester runs `dart format --output=none --set-exit-if-changed .`, then it exits with code 0 and reports 0 changed files. |
| AC-6 | **Test setup works and tests are named by TC ID.** When the Tester runs `flutter test`, then at least 1 test runs, all tests pass, and the command exits with code 0; and every `test(…)` / `testWidgets(…)` name in `app/test/` starts with `TC-001-` followed by two digits. The generated counter test (`Counter increments smoke test`) no longer exists. |
| AC-7 | **Placeholder screen.** Given the app widget is pumped in a widget test, when the first frame is shown, then exactly two `Text` widgets are in the tree — the title text and the status text from section 5, each matching character for character — so any extra text (sample text, version line, label) fails; there are no buttons or text fields, and no exceptions are thrown. This widget test passes as part of AC-6. |
| AC-8 | **No permissions requested.** When the Tester opens `app/android/app/src/main/AndroidManifest.xml`, then it contains no `<uses-permission>` entries (the debug/profile manifests generated by Flutter for hot reload are allowed). |
| AC-9 | **Git initialised, remote set, no commits during the phase.** Given the project root `daily-budget-app/`, when the Tester runs `git rev-parse --show-toplevel`, then it prints the project root (not `app/` and not a parent folder); `git remote get-url origin` prints `https://github.com/astiktyagi27/Daily-Budget-App.git`; `.gitignore` exists; and **before the phase-end commit** `git log` reports that there are no commits yet. **After the phase-end push** there is exactly one commit, `Phase 0: Project foundation`, made by the Orchestrator; `git log origin/main -1` shows the same commit as local `HEAD`; and `git status` is clean. |
| AC-10 | **.gitignore excludes build outputs and local files.** When the Tester runs `git check-ignore -v` on each of these paths, then every one is reported as ignored: `app/build/`, `app/.dart_tool/`, `app/android/local.properties`, `app/android/.gradle/`, `app/android/key.properties`, a `*.jks` keystore, a `*.keystore` keystore, `app/.flutter-plugins-dependencies`, `*.iml`, `.idea/`. And `git status --porcelain` lists **no** file under `build/` or `.dart_tool/`. `app/pubspec.lock` is **not** ignored. |
| AC-11 | **Core library choices recorded.** When the Tester reads `docs/DECISIONS.md`, then it contains rows for: Flutter + Dart versions, state management, local database, logging, and the lint set — each with an exact version number (e.g. `x.y.z`), a one-line reason, the date and "decided by". Every package in `app/pubspec.yaml` `dependencies` / `dev_dependencies` (other than `flutter`/`flutter_test` SDK entries) has a matching row with the same version; a choice not yet added to `pubspec.yaml` is marked "added in Phase N". No chosen package is paid or has a cost. |
| AC-12 | **Works without the Android SDK.** Given the laptop has no Android SDK and the project path contains a space (`Idea bank`), when the Tester runs `flutter pub get`, `flutter analyze` and `flutter test`, then all three succeed. (`flutter doctor` showing the Android toolchain as missing is expected and is not a fail.) The "no Android SDK" precondition can only be reproduced before README §13 is done: if the SDK is already installed when the case is first run, the Tester records "precondition no longer reproducible", and the case passes if the three commands succeed from the path with the space. |
| AC-13 | **Runs on the Android emulator** *(verifiable only after Android Studio, the Android SDK and an emulator are installed — until then recorded as **Blocked**, not Fail; Phase 0 cannot be signed off while Blocked)*. Given an Android emulator is running, when the Tester runs `flutter run` and waits for the build to finish, then the app opens on the emulator showing the section 5 placeholder text, and the terminal shows no exceptions. |

## 4. Edge cases *(Product Manager)*
- **Windows host.** All commands are written so they work in Windows PowerShell and Git Bash. Paths in docs and scripts must not assume Linux/macOS (no hard-coded `/` root paths).
- **Project path contains a space** (`C:\Users\mayan\Documents\Idea bank\…`). Every command, script and config must quote paths. If Gradle or any tool fails because of the space (AC-12 or AC-13), the Developer records it as a bug with the exact error; the README fallback is to move the project to a path without spaces — that move is an Owner decision, not done silently.
- **Flutter not on PATH in already-open shells.** Terminals opened before Flutter was added to PATH will say `flutter` is not recognised. Fix: open a new terminal, or call `C:\src\flutter\bin\flutter` directly. The Tester must record which way commands were run. This is not a product bug.
- **Android SDK missing.** `flutter create` still generates `android/`; `flutter analyze`/`flutter test` work (AC-12); `flutter doctor` shows Android items as missing; `flutter run`/`flutter build apk` fail — AC-13 stays **Blocked** until README §13 is done.
- **Windows Developer Mode / symlinks off.** If any chosen package is a Flutter plugin, `flutter pub get` may warn "Building with plugins requires symlink support". The placeholder app must still pass AC-4 to AC-7; the warning is noted for the Owner (README §13 step 4).
- **Generated sample code.** `flutter create` adds a counter app and a counter test that break AC-6 (test name) and AC-7 (buttons). Both must be replaced, not left alongside.
- **Strict lints vs generated files.** Generated or platform files must not be excluded from analysis just to reach zero issues, except files the lint package itself documents as generated and the build/platform folders the Flutter tool adds to `exclude:` automatically (`build/**`, `android/**`); any `exclude:` entry in `analysis_options.yaml` needs a reason in the plan.
- **Empty layer folders.** Git does not track empty folders, so each of `core/`, `data/`, `domain/`, `features/` needs at least one file (AC-2) without adding dead code (STANDARDS §5).
- **Dart package name.** Must be a valid lowercase_with_underscores name chosen explicitly, not derived from the folder path with the space.
- **Line endings (CRLF vs LF).** Git on Windows may convert line endings; `dart format` (AC-5) must still report 0 changes after a fresh checkout.
- **Long Windows paths.** Gradle builds under a deep user path can hit the 260-character limit; if AC-13 fails for this reason it is logged as a bug with the exact error.
- **Git repository location.** Exactly one repository, at the project root, so `docs/`, `plans/`, `tests/` and `app/` are all under version control; no nested repository inside `app/`.
- **Secrets / local files.** Keystores, `key.properties` and `local.properties` (which holds the local SDK path) must be ignored before any commit is ever made (AC-10); the Orchestrator checks `git status` for them again before the phase-end commit.
- **Version drift.** If a newer stable Flutter or package version appears between the decision and the build, `DECISIONS.md` and `pubspec.yaml` must still agree (AC-11).

## 5. Help text & copy *(Product Manager, finalised by Designer)*
Not applicable — no user-facing controls in this feature. The only copy is the placeholder screen text, which tests check exactly:

| Control | Label | Description / tooltip |
|---|---|---|
| Placeholder screen — title text | `Daily Budget App` | — (working title, README; replaced when the final name is chosen) |
| Placeholder screen — status text | `Setting things up. Your daily budget will appear here soon.` | — |

## 6. Out of scope
- Design system, colours, fonts, the four themes, custom icons, app icon (Phase 1).
- Navigation shell and any real screens: onboarding, home, calendar, settings (Phases 1–3).
- Database tables, budget engine, money logic (Phase 2). Libraries are only **chosen** here.
- SMS reading, permissions, notifications (Phases 4–5).
- Commits by agents during the phase, force-pushes, other branches, and CI. (The single phase-end commit + push by the Orchestrator is in scope — AC-9, CLAUDE.md rule 9.)
- Real-phone testing, release builds and signing (Phases 6–7).
- iOS target.

## 7. How it works — technical *(Developer, filled in when the feature is Done)*
- **Main files and classes** (all paths under `app/` unless stated):
  - `lib/main.dart` — entry point; `main()` only calls `runApp(const DailyBudgetApp())`.
  - `lib/app.dart` — `DailyBudgetApp`, a `StatelessWidget` returning a plain `MaterialApp` (title `Daily Budget App`, home `PlaceholderScreen`). No theme, no routes yet.
  - `lib/features/placeholder/placeholder_screen.dart` — `PlaceholderScreen`: exactly two `Text` widgets (title + status text from §5), no buttons or fields. To be removed when the first real screen arrives.
  - `lib/core/`, `lib/data/`, `lib/domain/`, `lib/features/` — the four layers from STANDARDS §3; each holds a `README.md` describing what belongs there (keeps the folder in git without dead code).
  - `test/features/placeholder/placeholder_screen_test.dart` — widget tests for the placeholder (TC-001-14, -15, -16, -43).
  - `test/architecture/domain_purity_test.dart` — TC-001-06: fails if any `.dart` file under `lib/domain/` imports `package:flutter` or `dart:ui`. Guards the pure-Dart domain rule for every later feature.
  - `tool/check.ps1` (project root) — one-command check: `pub get` → `dart format` check → `flutter analyze` → test-name check (every test starts with a TC ID) → `flutter test`; PASS/FAIL per step, exit 0/1. Works in Windows PowerShell 5.1 and from Git Bash; finds Flutter on PATH or at `C:\src\flutter`.
  - `.gitignore` / `.gitattributes` (project root) — ignore build outputs, local SDK paths, keystores and IDE files; force LF line endings (CRLF only for `.bat`/`.cmd`/`.ps1`) so `dart format` stays clean on Windows.
  - `analysis_options.yaml` — `very_good_analysis` 11 (D-016), with `public_member_api_docs` off (D-013).
  - `android/app/build.gradle.kts` — namespace / application ID `com.dailybudget.app` (D-021); `ndkVersion = "30.0.16248370"` (D-025).
- **Data stored:** none. No database, files, preferences or permissions (0 `<uses-permission>` in the main manifest).
- **Depends on / used by:** depends on no other feature. It is the foundation for every later feature: the folder layout, lint set, test naming, `tool/check.ps1` and the domain-purity test apply to all of them.
- **Known limitations:**
  - Application ID `com.dailybudget.app` is a placeholder until the final app name is chosen in Phase 7, before the first Play upload (D-021); it cannot change after release.
  - The NDK is pinned to 30.0.16248370 instead of Flutter's default 28.2.13676358, which could not be auto-installed (D-025). Every new machine must install that NDK (README §13 Step 1.4); switch back to `flutter.ndkVersion` once Flutter's default is ≥ 30, and re-verify native SQLite builds in Phase 2.
  - `analysis_options.yaml` excludes `build/**` and `android/**` because the Flutter tool re-adds them on every `pub get` (D-016); no hand-written Dart is excluded.
  - Windows Developer Mode is still off. Not needed now (no plugins), but it must be switched on (README §13 Step 4) before the first Flutter plugin is added, or `flutter pub get` warns about symlink support.

## 8. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-01 | First version of the spec | Product Manager |
| 2026-11-01 | Gate 1 clarifications: AC-7 "exactly the title and status text" = exactly two `Text` widgets; AC-10 also covers `*.keystore`; AC-12 states what happens once the SDK is installed. Status → Plan approved; tasks T-001…T-008 | Project Manager |
| 2026-11-01 | Owner decision (CLAUDE.md rule 9, D-014): GitHub remote `origin` set in T-001; agents never commit during the phase; one Orchestrator phase commit + push at phase end. AC-9, §1, §2 step 6, §4 secrets and §6 out of scope updated; task T-010 added | Project Manager |
| 2026-11-01 | Gate 4 (run R2): 13/13 ACs pass. Status → Done. §7 test list corrected to include TC-001-16 and -43 | Project Manager |
| 2026-11-01 | Gate 3: §4 "Strict lints vs generated files" also allows the `build/**`, `android/**` excludes that Flutter 3.47 re-adds on every `pub get` (verified in `flutter_tools` `AnalysisOptionsMigration`); no hand-written code excluded. No AC changed | Project Manager |
| 2026-11-01 | Step 9: §7 technical section filled in (main files, no data stored, foundation for all features, known limitations D-021/D-025/D-016/Developer Mode). README §13 now names NDK 30.0.16248370 (N5) | Developer |

## Suggested additions *(for the CEO — not in scope until approved)*
- **Android application ID.** `flutter create` defaults to `com.example.*`, which Google Play rejects. Suggest the Developer proposes a final application ID (e.g. reverse domain of the Owner's choice) and records it in `DECISIONS.md` now, since changing it after release is impossible. Needs Owner input because it relates to publishing identity.
- **`.gitattributes`** to fix line endings (LF for Dart files) so formatting checks stay stable on Windows.
- **A one-line "check everything" command** (e.g. a small script) the Owner can run to see analyze + format + test results in one go.
