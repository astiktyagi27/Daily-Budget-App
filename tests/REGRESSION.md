# Regression Checklist

Owned by the Tester. Run in full **after every bug fix** and **at the end of every phase**.

A full regression run means:
1. `flutter analyze` → 0 issues
2. `flutter test` → every automated test passes (this includes every automated test case from every file in `tests/`)
3. Integration tests on the emulator → all pass
4. Every **Manual** test case marked *Regression: yes* in the `tests/F-xxx-*.md` files, plus the checks below

## Results of the last full run
| Date | Trigger (bug fix / phase end) | Automated | Manual | Result |
|---|---|---|---|---|
| 2026-11-01 | F-001 Step 8 (run R1, T-001…T-007 + T-011; no bug fix) | `flutter analyze` 0 issues · `flutter test` 5/5 · `tool/check.ps1` ALL CHECKS PASSED, exit 0 · integration tests: none yet (no Android SDK) | Checks 1–8 below pass; check 9 (emulator) Blocked — no Android SDK | Green (AC-13 Blocked) |
| 2026-11-01 | F-001 T-008 + full regression (run R2; Android SDK, NDK 30.0.16248370 and emulator now installed; no bug fix) | `tool/check.ps1` ALL CHECKS PASSED, exit 0 · `flutter analyze` 0 issues · `flutter test` 5/5 · integration tests: none exist yet | Checks 1–9 pass, incl. check 9: `flutter run -d emulator-5554` (Android 17 / API 37) shows the placeholder, no app exceptions in logcat (`docs/reviews/r2-emulator.png`); all Regression-yes cases in `tests/F-001-project-foundation.md` pass | Green |

## Core manual checks
Key user flows, added as features are completed.

| # | Area | Check | From feature |
|---|---|---|---|
| 1 | Whole project | From root: `& ".\tool\check.ps1"` (Flutter on PATH or at `C:\src\flutter`) → every step PASS (pub get → format → analyze → test names → `flutter test`), `ALL CHECKS PASSED`, exit 0. Counts as evidence for TC-001-08, -10, -11 | F-001 (TC-001-44 step 1) |
| 2 | Structure | `lib/` holds only `core`, `data`, `domain`, `features` + `main.dart`, `app.dart`; no `web/ windows/ linux/ macos/ ios/`; package `daily_budget`; app ID `com.dailybudget.app`, no `com.example` | F-001 (TC-001-01, -03, -04, -05, -36, -37) |
| 3 | Permissions | Main `AndroidManifest.xml` has no `uses-permission` unless a feature doc approves it | F-001 (TC-001-17) |
| 4 | Git and secrets | One repo at root (`git rev-parse --show-toplevel` from root and `app/`); `origin` = `https://github.com/astiktyagi27/Daily-Budget-App.git`; `git check-ignore -v` on the TC-001-21 paths (build outputs, `local.properties`, `key.properties`, `*.jks`, `*.keystore`, `.env*`, `*.pem`, `*.p12`, `*.db*`, `*.sqlite3`) all ignored; `app/pubspec.lock` **not** ignored; no `build/` or `.dart_tool/` in `git status` | F-001 (TC-001-18, -21, -22, -23, -40, -47) |
| 5 | Dependencies | Every package in `pubspec.yaml` has a DECISIONS row with the same exact version as `pubspec.lock`; toolchain in DECISIONS = `flutter --version` | F-001 (TC-001-24, -25) |
| 6 | Code hygiene | `lint` config: only `public_member_api_docs` overridden, excludes only `build/**`, `android/**`; no `print(`, no TODO without task ID, no counter-sample leftovers, no hard-coded machine paths in app code | F-001 (TC-001-07, -09, -31, -35, -42) |
| 7 | Line endings | `git check-attr text eol` on `.dart` files → `eol: lf` | F-001 (TC-001-39) |
| 8 | Test names | Every `test`/`testWidgets` name starts with its TC ID (`flutter test --reporter expanded`) | F-001 (TC-001-12) |
| 9 | Runs on device | `flutter run` on the emulator shows the current home screen, no exceptions (until Phase 1: the placeholder title and status text) | F-001 (TC-001-29) — runs since R2 (2026-11-01). Use `flutter run -d emulator-5554 --no-resident`, then `adb logcat -d` (no `FATAL`/`AndroidRuntime`/`E/flutter`); screenshot via `adb shell screencap -p /sdcard/x.png` + `adb pull` |
