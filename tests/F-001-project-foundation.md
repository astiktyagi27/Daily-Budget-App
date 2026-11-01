# Test Cases — F-001: Project foundation

| | |
|---|---|
| **Feature doc** | [`docs/features/F-001-project-foundation.md`](../docs/features/F-001-project-foundation.md) |
| **Plan** | [`plans/F-001-project-foundation.md`](../plans/F-001-project-foundation.md) *(read after drafting; names, files and IDs aligned — see 2.3)* |
| **Author** | Tester (written **before** development, approved by Project Manager at Gate 1) |
| **Status** | Approved (Gate 1, 2026-11-01). T-009 tidy-up applied 2026-11-01 (plan §10 points 9 and 13): TC-001-13, -20, -26, -45 retired (merged, IDs never reused); TC-001-47/-48 added; no automated test name changed. **44 active cases.** **Step 8 run R1 (2026-11-01): 40 Pass, 0 Fail, 2 Blocked, 1 Pending, 1 N/A.** **Run R2 (2026-11-01, T-008 + full regression with the Android SDK/emulator): 35 run, 35 Pass, 0 Fail; feature total 41 Pass, 0 Fail, 0 Blocked, 1 Pending (TC-001-48), 1 N/A (TC-001-34), 1 Superseded (TC-001-33) — see sections 4–5.** Gate 3 (2026-11-01, Project Manager): TC-001-09 accepts the Flutter-tool-forced `build/**`, `android/**` excludes; TC-001-35 searches `FloatingActionButton` in `lib/` only. |

## 0. How to run these cases

**Environment:** Windows 11, Windows PowerShell 5.1, Flutter 3.47.9 stable / Dart 3.13.7 at `C:\src\flutter`. Android SDK **not** installed at R1; **installed from R2 on** (README §13; NDK 30.0.16248370 per D-025; emulator AVD `Medium_Phone_API_37.0` = `emulator-5554`, Android 17 / API 37). Project root: `C:\Users\mayan\Documents\Idea bank\daily-budget-app` (space in `Idea bank` — always quote paths).

**Setup S1 (before every run, in a PowerShell window):**
```powershell
# Already-open shells do not have Flutter on PATH. Add it for this session only:
$env:Path += ';C:\src\flutter\bin'
flutter --version          # must show Flutter 3.47.9 / Dart 3.13.7 — record the output
Set-Location "C:\Users\mayan\Documents\Idea bank\daily-budget-app\app"
```
Record in section 4 **which way Flutter was reached** (PATH added as above, new terminal, or full path `C:\src\flutter\bin\flutter.bat`).

**Conventions**
- All commands run from `app/` unless the step says "from root" (`C:\Users\mayan\Documents\Idea bank\daily-budget-app`).
- "Exit 0" is checked with `$LASTEXITCODE` straight after the command.
- **Manual (command)** = a Manual case whose step is an exact command; the Tester runs it and compares output with Expected. Commands containing `|` are written out in section 1.1 (tables can't hold them).
- **Auto-widget** cases are implemented by the Developer in `app/test/` (per plan: `app/test/features/placeholder/placeholder_screen_test.dart` pumping `DailyBudgetApp`, and `app/test/architecture/domain_purity_test.dart`), with the test name starting with the TC ID exactly as given in the "Automated test" column.
- **Git rule:** no case ever runs `git add`, `git commit`, `git push`, or anything that changes git history or config. Only read-only git commands are used (the single phase-end commit + push is the Orchestrator's T-010, not a test step).
- **Retired cases** keep their row, marked "Retired — merged into …". Their IDs are never renumbered or reused; they are not run and not counted.
- Temporary files the Tester creates (TC-001-38, -40, -44) are removed at the end of the case and the removal is recorded.

## 1. Test cases
Types: **Auto-unit** · **Auto-widget** · **Auto-integration** · **Manual** (incl. **Manual (command)**).
Automated tests include the TC ID in their name, e.g. `testWidgets('TC-001-14 placeholder shows title and status text', …)`.
**Regression = yes** means the case is re-run in every full regression (automated cases always are; mark important manual cases yes).

| ID | AC | Scenario | Test data | Steps | Expected | Type | Automated test | Regression |
|---|---|---|---|---|---|---|---|---|
| TC-001-01 | AC-1 | Flutter project files exist | — | S1, then: `Test-Path pubspec.yaml, lib\main.dart, test, android` | Four lines, all `True` | Manual (command) | — | yes |
| TC-001-02 | AC-1 | SDK constraint accepts Dart 3.13.7 | Dart 3.13.7 | 1. Open `pubspec.yaml`, read `environment: sdk:`. 2. `flutter pub get`; check `$LASTEXITCODE` | 1. Constraint includes 3.13.7 (e.g. `^3.13.0` or `>=3.13.0 <4.0.0`; lower bound ≤ 3.13.7, upper bound > 3.13.7). 2. Exit 0, no "The current Dart SDK version is … because … requires SDK version" error | Manual (command) | — | yes |
| TC-001-03 | AC-1 | Android-only target | — | `Test-Path web, windows, linux, macos, ios` | All five `False`. If `ios` is `True`, the plan must give a reason; no reason → Fail | Manual (command) | — | yes |
| TC-001-04 | AC-2 | `lib/` has exactly the four layer folders | — | See 1.1 → TC-001-04 | Folders listed are exactly `core`, `data`, `domain`, `features` (no others, e.g. no `src`, `screens`, `widgets`). Files directly in `lib/`: `main.dart`, plus at most one top-level app file (e.g. `app.dart`) if the plan names it | Manual (command) | — | yes |
| TC-001-05 | AC-2 | Each layer folder holds a file git can see | — | From root, see 1.1 → TC-001-05 | Every one of `core/`, `data/`, `domain/`, `features/` shows ≥ 1 file in the listing (proves git tracks it, or will — the listing covers files before and after the phase-end commit). Files are not dead/commented-out code (STANDARDS §5) — open each and confirm | Manual (command) | — | yes |
| TC-001-06 | AC-3 | `domain/` is pure Dart | All `.dart` files under `lib/domain/` | See 1.1 → TC-001-06 | Count = `0` for both `package:flutter` and `dart:ui`. Record the `.dart` file count: in Phase 0 it is expected to be `0` (the plan puts only a `README.md` in `domain/`), so the search is vacuous today — the automated guard test keeps it meaningful for later phases and must pass | Manual (command) + Auto-unit | `TC-001-06 domain contains no Flutter or dart:ui imports` (`test/architecture/domain_purity_test.dart`) | yes |
| TC-001-07 | AC-4 | Lint set stricter than default and recorded | — | 1. Open `analysis_options.yaml`. 2. Open `pubspec.yaml` `dev_dependencies`. 3. Open `docs/DECISIONS.md` | 1. `include: package:very_good_analysis/analysis_options.yaml` (plan); the only rule override is `public_member_api_docs: false` (approved, plan §10 point 2, D-013) — any other disabled rule → Fail unless the plan gives a reason; `flutter_lints` no longer in `pubspec.yaml`. 2. `very_good_analysis` is in `dev_dependencies` (plan: `^11.0.0`). 3. DECISIONS has a row naming `very_good_analysis` with the same version (`11.0.0`) | Manual | — | yes |
| TC-001-08 | AC-4 | Analyzer reports zero issues | — | `flutter analyze`; then `$LASTEXITCODE` | Output ends with `No issues found!`; exit code `0`. Any error, warning **or info** → Fail | Manual (command) | — | yes |
| TC-001-09 | AC-4 | No files excluded just to get zero issues | — | Open `analysis_options.yaml`, look for `analyzer: exclude:` | No `exclude:` entry, **or** every entry has a reason in the plan and covers only generated files (e.g. `**/*.g.dart`) the lint package documents, **or** is one the Flutter tool adds automatically on every `pub get` (`build/**` and platform folders such as `android/**` — Gate 3, F-001 plan §11 item 2). Today's expected list: exactly `build/**`, `android/**`. Excluding `lib/`, `test/` or any hand-written file → Fail | Manual | — | yes |
| TC-001-10 | AC-5 | Formatting clean | — | `dart format --output=none --set-exit-if-changed .`; then `$LASTEXITCODE` | Prints `Formatted N files (0 changed)`; exit code `0` | Manual (command) | — | yes |
| TC-001-11 | AC-6 | Test runner works | — | `flutter test`; then `$LASTEXITCODE` | ≥ 1 test runs; last line `All tests passed!`; exit `0`; no "No tests ran" | Manual (command) | — | yes |
| TC-001-12 | AC-6 | Every test name starts with `TC-001-NN` | All `.dart` files under `app/test/` | 1. See 1.1 → TC-001-12 (static scan). 2. `flutter test --reporter expanded` and read every test name | 1. Scan prints nothing. 2. Every reported test name starts with `TC-001-` + two digits + space (e.g. `TC-001-14 …`). If `group()` is used the group prefix is allowed only if the plan says so — flag otherwise | Manual (command) | — | yes |
| TC-001-13 | AC-6 | ~~Generated counter test removed~~ **Retired — merged into TC-001-35** (T-009) | — | — | — | — | — | — |
| TC-001-14 | AC-7, AC-6 | Placeholder shows exactly two `Text` widgets: the title and status text | Title `Daily Budget App`; status `Setting things up. Your daily budget will appear here soon.` | Widget test: `pumpWidget(const DailyBudgetApp())`, `pumpAndSettle()`; assert `find.text('Daily Budget App')` → `findsOneWidget`, `find.text('Setting things up. Your daily budget will appear here soon.')` → `findsOneWidget`, and `find.byType(Text)` → exactly 2 widgets | All assertions pass. Text compared character-for-character against string literals in the test (incl. final full stop, no trailing spaces). Any extra text (sample `Hello World!`, version line, label) → Fail | Auto-widget | `TC-001-14 placeholder shows title and status text` (`test/features/placeholder/placeholder_screen_test.dart`) | yes |
| TC-001-15 | AC-7 | Placeholder has no buttons or text fields | — | Same pump; assert `findsNothing` for: `ButtonStyleButton` (covers Elevated/Filled/Outlined/Text buttons), `IconButton`, `FloatingActionButton`, `TextField`, `TextFormField`, `EditableText`, `BottomNavigationBar`, `NavigationBar`, `Drawer`; then `tester.ensureSemantics()` and assert `find.semantics.byAction(SemanticsAction.tap)` → `findsNothing` (T-011 N4: nothing on screen is tappable) | All `findsNothing` (widget types and tap-action semantics nodes) | Auto-widget | `TC-001-15 placeholder has no buttons or text fields` (`test/features/placeholder/placeholder_screen_test.dart`) | yes |
| TC-001-16 | AC-7 | First frame throws no exceptions | — | Same pump; `expect(tester.takeException(), isNull)` after the first `pump()` and after `pumpAndSettle()` | Both `null`; test passes | Auto-widget | `TC-001-16 placeholder renders without exceptions` (`test/features/placeholder/placeholder_screen_test.dart`) | yes |
| TC-001-17 | AC-8 | Main manifest requests no permissions | `android/app/src/main/AndroidManifest.xml` | `Select-String -Path android\app\src\main\AndroidManifest.xml -Pattern 'uses-permission'` | No output (0 matches). Matches in `src/debug/` or `src/profile/` manifests are allowed and not checked | Manual (command) | — | yes |
| TC-001-18 | AC-9 | Repository top level is the project root | — | From `app/`: `git rev-parse --show-toplevel`. From root: same command | Both print `C:/Users/mayan/Documents/Idea bank/daily-budget-app` (forward slashes are normal). Printing `…/app` or `…/Idea bank` → Fail | Manual (command) | — | yes |
| TC-001-19 | AC-9 | 0 commits before the phase-end commit (agents never commit during the phase) | Run any time **before** T-010 | From root: 1. `git log` 2. `git rev-list --all --count` | 1. `fatal: your current branch 'main' does not have any commits yet` (exit 128 is expected here). 2. Prints `0` (or the same fatal message — both mean zero commits) | Manual (command) | — | yes *(only until T-010; after the phase-end commit the PM retires this case and TC-001-48 takes over)* |
| TC-001-20 | AC-9 | ~~`.gitignore` exists at root~~ **Retired — merged into TC-001-21** (T-009) | — | — | — | — | — | — |
| TC-001-21 | AC-9, AC-10 | Root `.gitignore` exists; build outputs, local files and secrets are ignored | 18 paths (see 1.1), incl. a `*.jks` and a `*.keystore` keystore, plus (T-011) `.env`, `.env.local`, `key.pem`, `cert.p12` and local data files `app/x.db`, `app/x.db-wal`, `app/x.sqlite3` | From root: 1. `Test-Path .gitignore`. 2. See 1.1 → TC-001-21 | 1. `True` (a Flutter-generated `app/.gitignore` may also exist; that is fine). 2. 18 lines of output, one per path, each `<source>:<line>:<pattern>	<path>`; exit 0; at least one line's `<source>` is the root `.gitignore`. Any path without a line → Fail (name it) | Manual (command) | — | yes |
| TC-001-22 | AC-10 | `pubspec.lock` is **not** ignored | — | From root: `git check-ignore -v app/pubspec.lock`; then `$LASTEXITCODE` | No output; exit code `1` | Manual (command) | — | yes |
| TC-001-23 | AC-10 | Generated folders never show as untracked | Run after TC-001-11 so `build/` and `.dart_tool/` exist | From root, see 1.1 → TC-001-23 | 1. `Test-Path` shows `.dart_tool` = `True` (so the check is meaningful). 2. Filter prints nothing | Manual (command) | — | yes |
| TC-001-24 | AC-11 | DECISIONS has every required row; toolchain versions match the machine | `docs/DECISIONS.md`; `flutter --version` output recorded in S1 | 1. Read the file; tick each: Flutter version, Dart version, state management, local database, logging, lint set (+ any test helper in `dev_dependencies`). 2. Compare with the `flutter --version` output recorded in S1 | 1. Each row has: exact version `x.y.z` (no `^`, no `latest`), a one-line reason, a date (`YYYY-MM-DD`), "decided by". Flutter `3.47.9`, Dart `3.13.7`. 2. Machine shows Flutter `3.47.9` and Dart `3.13.7`, same as DECISIONS | Manual | — | yes |
| TC-001-25 | AC-11 | `pubspec.yaml`, `pubspec.lock` and DECISIONS agree (incl. version drift) | — | From `app/`: 1. List every package under `dependencies` and `dev_dependencies` except `flutter`/`flutter_test` SDK entries. 2. For each, find its DECISIONS row. 3. Compare with the resolved version in `pubspec.lock`. 4. `flutter pub outdated` (informational) | 1–3. Every package has a row; DECISIONS version = version in the `pubspec.yaml` constraint (e.g. `^2.6.1` ↔ `2.6.1`) = resolved version in `pubspec.lock`. Choices not yet in `pubspec.yaml` (e.g. database) say "added in Phase N". 4. Newer versions listed are recorded as a note, not a fail | Manual | — | yes |
| TC-001-26 | AC-11 | ~~Toolchain versions recorded match the machine~~ **Retired — merged into TC-001-24** (T-009) | — | — | — | — | — | — |
| TC-001-27 | AC-11 | All chosen packages are free and open source | — | For each DECISIONS package, open `https://pub.dev/packages/<name>` → License | Every licence is an OSI open-source licence (MIT, BSD-3-Clause, Apache-2.0, …); none needs payment, an API key or a paid account | Manual | — | no |
| TC-001-28 | AC-12 | Works without the Android SDK, from a path with a space | Path `…\Idea bank\…` | 1. `flutter doctor` (record). 2. `flutter pub get` 3. `flutter analyze` 4. `flutter test` — check `$LASTEXITCODE` after 2–4 | 1. Android toolchain shown as missing/✗ is expected, not a fail. If the SDK is already installed, record "precondition no longer reproducible" — the case then passes if 2–4 succeed from the path with the space. 2–4. All exit `0`; no error mentioning the path, spaces, or `ANDROID_HOME` | Manual (command) | — | no *(run once — the first Step 8 run, before the SDK if still possible; TC-001-08/-10/-11 re-check the path with the space in every regression)* |
| TC-001-29 | AC-13 | App runs on the Android emulator | Emulator from README §13 | 1. Start emulator. 2. `flutter devices` (emulator listed). 3. `flutter run`; wait for build. 4. Look at emulator screen and terminal | Emulator shows `Daily Budget App` and `Setting things up. Your daily budget will appear here soon.`; terminal has no `Exception`/`Error` lines (Gradle info/warnings are recorded but not a fail). **Expected result today: `Blocked`** (no Android SDK) — never `Fail` for that reason | Manual | — | yes |
| TC-001-47 | AC-9 | GitHub remote `origin` is set to the project repository | — | From root: `git remote get-url origin`; then `$LASTEXITCODE` | Prints exactly `https://github.com/astiktyagi27/Daily-Budget-App.git`; exit `0`. No other URL, no `error: No such remote 'origin'` | Manual (command) | — | yes |
| TC-001-48 | AC-9 | After the phase-end push: one commit, pushed, working tree clean | Run once, **after T-010** (Orchestrator's commit + push) | From root (read-only; no `fetch`/`pull`): 1. `git ls-remote origin refs/heads/main` (live remote). 2. `git rev-parse HEAD` and `git rev-parse origin/main`. 3. `git log origin/main -1 --format='%H %s'`. 4. `git rev-list --count HEAD`. 5. `git log -1 --format=%s`. 6. `git status --porcelain` | 1–3. All hashes identical (remote `main`, `origin/main`, local `HEAD`); subject `Phase 0: Project foundation`. 4. `1`. 5. `Phase 0: Project foundation`. 6. No output (clean). Any mismatch, extra commit, or listed file → Fail | Manual (command) | — | no *(run once after each phase push; not part of every regression)* |

### 1.1 Command details (commands containing `|`)

**TC-001-04** (from `app/`)
```powershell
Get-ChildItem lib -Directory | Select-Object -ExpandProperty Name
Get-ChildItem lib -File      | Select-Object -ExpandProperty Name
```

**TC-001-05** (from root — lists files git tracks or would track, i.e. tracked + untracked-but-not-ignored; nothing is staged)
```powershell
git ls-files --cached --others --exclude-standard -- app/lib
```

**TC-001-06** (from `app/`)
```powershell
(Get-ChildItem lib\domain -Recurse -Filter *.dart | Select-String -Pattern 'package:flutter' -SimpleMatch | Measure-Object).Count
(Get-ChildItem lib\domain -Recurse -Filter *.dart | Select-String -Pattern 'dart:ui' -SimpleMatch | Measure-Object).Count
(Get-ChildItem lib\domain -Recurse -Filter *.dart | Measure-Object).Count   # record the count (0 expected in Phase 0)
```

**TC-001-12** (from `app/` — prints any test/testWidgets line whose name does not start with a TC ID)
```powershell
Get-ChildItem test -Recurse -Filter *.dart |
  Select-String -Pattern '\b(test|testWidgets)\(' |
  Where-Object { $_.Line -notmatch "\b(test|testWidgets)\(\s*['""]TC-001-\d{2} " }
```
A name written on the line after `testWidgets(` is reported by this scan; the Tester then checks it by eye and with step 2.

**TC-001-13** — Retired (merged into TC-001-35; its `integration_test/` search now lives in 2.1 → TC-001-35).

**TC-001-21** (from root — paths need not exist; `git check-ignore` tests the patterns)
```powershell
git check-ignore -v app/build/ app/.dart_tool/ app/android/local.properties app/android/.gradle/ app/android/key.properties app/android/app/upload-keystore.jks app/android/app/release.keystore app/.flutter-plugins-dependencies app/daily_budget.iml .idea/ app/.idea/ .env .env.local key.pem cert.p12 app/x.db app/x.db-wal app/x.sqlite3
```
The last seven paths were added at Step 8 (T-011 / Gate 3 N1: env files, certificates, local SMS data). `app/pubspec.lock` must still **not** be ignored (TC-001-22).

**TC-001-23** (from root, after `flutter test` has run)
```powershell
Test-Path app\.dart_tool, app\build
git status --porcelain --untracked-files=all | Select-String -Pattern '(^|/)(build|\.dart_tool)/'
```

## 2. Edge cases
Same columns. The standard money/date/SMS/theme edge cases (₹0, paise rounding, month lengths, leap year, SMS, 4 themes, permission denied) do **not** apply to F-001 — there is no money logic, data, theme work or permission here (feature doc §6). Largest system font is covered by TC-001-43.

| ID | AC | Scenario | Test data | Steps | Expected | Type | Automated test | Regression |
|---|---|---|---|---|---|---|---|---|
| TC-001-30 | AC-12 | Windows host: same checks pass from **Git Bash** | Quoted path | In Git Bash: `export PATH="$PATH:/c/src/flutter/bin"`; `cd "/c/Users/mayan/Documents/Idea bank/daily-budget-app/app"`; `flutter analyze`; `flutter test`; `dart format --output=none --set-exit-if-changed .`; `echo $?` after each | All three exit `0`, same results as in PowerShell | Manual (command) | — | no |
| TC-001-31 | Edge (space in path) | No hard-coded absolute or machine paths in tracked files | String `Idea bank`, `C:\Users`, `mayan` | From root: see 2.1 → TC-001-31 | No match in any file git tracks or would track (matches only inside ignored files such as `app/android/local.properties` are fine — confirm each with `git check-ignore -v <file>`) | Manual (command) | — | yes |
| TC-001-32 | Edge (PATH) | Flutter not on PATH in an already-open shell | A PowerShell window opened before Flutter was added to PATH (or a new one where PATH was not changed) | 1. `flutter --version` 2. `& 'C:\src\flutter\bin\flutter.bat' --version` 3. `& 'C:\src\flutter\bin\flutter.bat' analyze` from `app/` | 1. `flutter : The term 'flutter' is not recognized…` (expected, **not** a product bug). 2. Shows 3.47.9. 3. `No issues found!`. Record in section 4 which way was used | Manual (command) | — | no |
| TC-001-33 | AC-12, AC-13 | Android SDK missing: Android build fails cleanly, Dart-side checks unaffected | No SDK | 1. `flutter doctor` 2. `flutter build apk --debug` | 1. Android toolchain ✗ / "Unable to locate Android SDK". 2. Fails with an SDK-not-found message (not a Dart compile error, not a pubspec error). Recorded as "expected — AC-13 Blocked", no bug logged | Manual (command) | — | no |
| TC-001-34 | Edge (symlinks) | Windows Developer Mode off + plugin packages | Only if `pubspec.yaml` contains a Flutter plugin package | `flutter pub get` and read the output | If warning `Building with plugins requires symlink support` appears: noted for the Owner (README §13 step 4), **and** TC-001-08, -10, -11, -14…16 still pass. If no plugin packages: mark N/A | Manual (command) | — | no |
| TC-001-35 | AC-6, AC-7 | Generated counter sample and counter test not left behind (incl. merged TC-001-13) | Strings from `flutter create` template | From `app/`: see 2.1 → TC-001-35 | 0 matches for `MyHomePage`, `_incrementCounter`, `You have pushed the button`, `Flutter Demo`, `Counter increments` (covers `Counter increments smoke test`) in `lib/`, `test/` and `integration_test/` (if present), and 0 matches for `FloatingActionButton` in `lib/` (in `test/` it legitimately appears in TC-001-15's absence assertion — this case targets leftover counter-sample code, not assertions). No leftover `test/widget_test.dart` containing counter code | Manual (command) | — | yes |
| TC-001-36 | Edge (package name) | Dart package name is valid and chosen explicitly | `pubspec.yaml` `name:` | Open `pubspec.yaml`; check `name:`. Then from `app/`: `Select-String -Path lib\*.dart, test\*.dart -Pattern "import 'package:"` | `name:` matches `^[a-z][a-z0-9_]*$`, is `daily_budget` (the name stated in the plan), not `idea_bank…` or derived from the folder path; package imports use that same name | Manual (command) | — | yes |
| TC-001-37 | Edge (application ID) | Android application ID is `com.dailybudget.app`, no `com.example` left | — | From `app/`: see 2.1 → TC-001-37 | `applicationId` and `namespace` in `android/app/build.gradle(.kts)` = `com.dailybudget.app`; `MainActivity` sits in a matching package folder (`…/com/dailybudget/app/`) and declares `package com.dailybudget.app`; 0 matches for `com.example` under `android/`; DECISIONS has a row for the application ID | Manual (command) | — | yes |
| TC-001-38 | AC-5 | CRLF line endings (simulated fresh checkout with `core.autocrlf=true`) | Copy of `lib/` and `test/` in the Tester's scratch folder | See 2.1 → TC-001-38 | `dart format --output=none --set-exit-if-changed` on the CRLF copy exits `0` (0 changed). Scratch copy removed afterwards. Also record the value of `git config core.autocrlf` | Manual (command) | — | no |
| TC-001-39 | AC-5 | `.gitattributes` forces LF for Dart files — **only if present per plan** | `.gitattributes` at root | From root: `git check-attr text eol -- app/lib/main.dart app/test/features/placeholder/placeholder_screen_test.dart` | Shows `eol: lf` (and `text: set` or `auto`) for `.dart` files. If the plan has no `.gitattributes`: mark N/A | Manual (command) | — | yes (if present) |
| TC-001-40 | AC-10 | Secrets and local files never show up even when they exist | Dummy files with fake content: `app/android/key.properties`, `app/android/app/upload-keystore.jks`, `app/android/app/release.keystore` | See 2.1 → TC-001-40 | 1. `local.properties` exists after `flutter pub get` (holds the local SDK path). 2. `git status` filter prints nothing — none of the four files appear. 3. Dummy files removed. Any of them showing (incl. `release.keystore` — AC-10 covers `*.keystore`) → Fail, bug logged | Manual (command) | — | yes |
| TC-001-41 | AC-9 | Exactly one git repository, at the root (none nested, none in a parent) | — | See 2.1 → TC-001-41 | 1. Exactly one `.git` folder found: `daily-budget-app\.git`. 2. `app\.git` → `False`. 3. Parent `Idea bank` is **not** a repo: `fatal: not a git repository` (exit 128). 4. Before T-010: `git status` from root lists `app/`, `docs/`, `plans/`, `tests/` as untracked (nothing committed). After T-010: step 4 is covered by TC-001-48 | Manual (command) | — | no *(one-time structure check; TC-001-18 stays in regression)* |
| TC-001-42 | AC-4 (STANDARDS §5) | No `print`, no TODO without task ID in app code | `lib/`, `test/` | From `app/`: see 2.1 → TC-001-42 | Both searches print nothing | Manual (command) | — | yes |
| TC-001-43 | AC-7 | Placeholder survives largest system font on a small screen | Text scale 3.0 (Android max is ~2.0; 3.0 gives margin); surface 320×568 logical px | Widget test: set `tester.view.physicalSize`/`devicePixelRatio` for 320×568, wrap with `MediaQuery(textScaler: TextScaler.linear(3.0))` or set `tester.platformDispatcher.textScaleFactorTestValue = 3.0`; pump app; reset view in `addTearDown` | Both texts still found; `tester.takeException()` is `null` (no `RenderFlex overflowed`) | Auto-widget | `TC-001-43 placeholder fits at text scale 3.0 on small screen` (`test/features/placeholder/placeholder_screen_test.dart`) | yes |
| TC-001-44 | AC-4, AC-5, AC-6 | "Check everything" script — **only if present per plan** (e.g. `tool/check.ps1`) | Path from plan | See 2.1 → TC-001-44 | 1. Clean run from root (path with a space): runs, in this order, `flutter pub get` → format check → `flutter analyze` → test-name check → `flutter test` (the name check runs **before** `flutter test` since T-011 N3), prints PASS per step, exits `0`. 2. With a temporary badly-formatted file in `app/test/`: exits non-zero and names the format step. 3. Temporary file removed; script exits `0` again. If no script in the plan: N/A | Manual (command) | — | yes — **step 1 only** (steps 2–3 run once). In regression a passing step 1 may be recorded as evidence for TC-001-08, -10, -11 |
| TC-001-45 | AC-11 | ~~Version drift: lock file vs DECISIONS~~ **Retired — merged into TC-001-25** (T-009) | — | — | — | — | — | — |
| TC-001-46 | AC-13 | Long Windows path during Gradle build | Run together with TC-001-29 | 1. `git config core.longpaths` (record). 2. Watch `flutter run` output for `Filename too long` / path-length errors | No path-length error. If it occurs: log a bug with the exact error (feature doc §4); moving the project is an Owner decision. **Blocked** until AC-13 can run | Manual | — | no |

### 2.1 Command details

**TC-001-31** (from root — searches files git tracks or would track: tracked + untracked-but-not-ignored, so it works before and after the phase-end commit)
```powershell
git ls-files --cached --others --exclude-standard |
  ForEach-Object { Select-String -LiteralPath $_ -Pattern 'Idea bank','C:\Users','mayan' -SimpleMatch -ErrorAction SilentlyContinue } |
  Where-Object { $_.Path -notmatch '\\(docs|plans|tests)\\|README\.md|CLAUDE\.md|\\\.claude\\' }
```
(Team docs under `docs/`, `plans/`, `tests/`, `README.md`, `CLAUDE.md`, `.claude/` legitimately mention the path; only files under `app/` and any script such as `tool/` are checked.)

**TC-001-35** (from `app/`)
```powershell
Get-ChildItem lib, test, integration_test -Recurse -Filter *.dart -ErrorAction SilentlyContinue |
  Select-String -Pattern 'MyHomePage','_incrementCounter','You have pushed the button','Flutter Demo','Counter increments' -SimpleMatch
Get-ChildItem lib -Recurse -Filter *.dart | Select-String -Pattern 'FloatingActionButton' -SimpleMatch
```
Both commands: no output. (`FloatingActionButton` is searched in `lib/` only — TC-001-15 asserts its absence in `test/`; clarified at Gate 3, 2026-11-01.)

**TC-001-37** (from `app/`)
```powershell
Get-ChildItem android\app -Filter 'build.gradle*' | Select-String -Pattern 'applicationId','namespace'
Get-ChildItem android -Recurse -File -Include *.gradle,*.kts,*.xml,*.kt,*.java -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\(build|\.gradle)\\' } |
  Select-String -Pattern 'com.example' -SimpleMatch
Get-ChildItem android\app\src\main -Recurse -Filter 'MainActivity.*' | Select-Object FullName
```

**TC-001-38** (from `app/`; `$scratch` = a new empty folder outside the project, e.g. under `$env:TEMP`)
```powershell
$scratch = Join-Path $env:TEMP 'tc-001-38'
New-Item -ItemType Directory -Force $scratch | Out-Null
Copy-Item lib, test, analysis_options.yaml, pubspec.yaml -Destination $scratch -Recurse
Get-ChildItem $scratch -Recurse -Filter *.dart | ForEach-Object {
  $t = [IO.File]::ReadAllText($_.FullName) -replace "`r?`n", "`r`n"
  [IO.File]::WriteAllText($_.FullName, $t)
}
dart format --output=none --set-exit-if-changed "$scratch"; $LASTEXITCODE
Remove-Item -Recurse -Force $scratch
git config core.autocrlf
```

**TC-001-40** (from root; fake content only)
```powershell
Test-Path app\android\local.properties
'storePassword=fake' | Set-Content app\android\key.properties
'fake' | Set-Content app\android\app\upload-keystore.jks
'fake' | Set-Content app\android\app\release.keystore
git status --porcelain --untracked-files=all |
  Select-String -Pattern 'local\.properties|key\.properties|\.jks|\.keystore'
Remove-Item app\android\key.properties, app\android\app\upload-keystore.jks, app\android\app\release.keystore
```

**TC-001-41** (from root)
```powershell
Get-ChildItem -Recurse -Force -Directory -Filter .git | Select-Object -ExpandProperty FullName
Test-Path app\.git
git -C "C:\Users\mayan\Documents\Idea bank" rev-parse --show-toplevel; $LASTEXITCODE
git status --porcelain
```
Step 3 only means something if `Idea bank` itself has no `.git`; if git walks up from `Idea bank` to a repo in `C:\Users\mayan\Documents` or above, that is also a Fail (a parent repository would swallow the project).

**TC-001-42** (from `app/`)
```powershell
Get-ChildItem lib, test -Recurse -Filter *.dart | Select-String -Pattern '\bprint\('
Get-ChildItem lib, test -Recurse -Filter *.dart | Select-String -Pattern 'TODO' | Where-Object { $_.Line -notmatch 'TODO\(T-\d{3}\)' }
```

**TC-001-44** (from root; path to script per plan. This laptop's policy is `RemoteSigned`, so `& .\tool\check.ps1` runs; if it is ever blocked, use `powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\check.ps1` (process-only) and record it — never change the policy setting. Regression runs only the first line.)
```powershell
& ".\tool\check.ps1"; $LASTEXITCODE
"void main(){print('x');}" | Set-Content app\test\tc_001_44_tmp_test.dart   # badly formatted on purpose
& ".\tool\check.ps1"; $LASTEXITCODE                                          # expect non-zero
Remove-Item app\test\tc_001_44_tmp_test.dart
& ".\tool\check.ps1"; $LASTEXITCODE                                          # expect 0 again
```

### 2.2 Impact on existing features (plan section 8)
None — F-001 is the first feature; there are no earlier test files to re-run. Plan section 8 agrees ("None"). Its suggestion to add "run `tool/check.ps1` — all steps PASS" to `tests/REGRESSION.md` is accepted in principle; the Tester adds it at Step 8 once TC-001-44 has passed.

### 2.3 Notes for the Project Manager / Product Manager
- **TC IDs:** this file is the source of truth; plan §6 was reconciled by the PM at Gate 1. Retired IDs (never reused): TC-001-13 → -35, -20 → -21, -26 → -24, -45 → -25. Added by T-009: TC-001-47, -48 (AC-9, D-014). Automated test names the Developer must use: `TC-001-06` (domain purity guard), `TC-001-14`, `TC-001-15`, `TC-001-16` (placeholder widget tests), `TC-001-43` (large text scale).
- The plan's `tool/check.ps1` also checks test names; TC-001-12 still runs independently so the check is not only proven by the script that implements it.
- Plan adds a `README.md` to each layer folder (AC-2). TC-001-05 accepts that; TC-001-06 is therefore vacuous today (no `.dart` files in `domain/`), which is why the automated guard counts as the real proof.
- **AC-7 "exactly the title and status text are visible"** is interpreted as: exactly two `Text` widgets in the tree, with exactly those strings (TC-001-14). If the Developer uses an `AppBar` with the title, that still gives 2 `Text` widgets and passes; any extra text (e.g. a debug label, version line) fails. The debug banner is not a `Text` widget and is not checked. *Confirmed by the PM at Gate 1; AC-7 now says this explicitly.*
- **AC-12** has a precondition ("no Android SDK") that stops being reproducible once README §13 is done. AC-12 now says what happens then; TC-001-28 is run once (before the SDK if still possible) and records "precondition no longer reproducible" if needed. TC-001-08/-10/-11 keep checking the path with a space in every regression.
- **AC-9 (D-014):** agents never commit during the phase. TC-001-19 checks 0 commits only until T-010; TC-001-47 checks `origin`; TC-001-48 checks the pushed phase commit once after T-010. TC-001-05 and TC-001-31 use `git ls-files --cached --others --exclude-standard` so they work both before and after the commit.
- **AC-13** (TC-001-29, TC-001-46) is expected `Blocked` until the Android SDK and emulator exist; Phase 0 cannot be signed off while Blocked.
- **AC-10 / CRLF "after a fresh checkout"** cannot be tested literally because commits are not allowed. TC-001-38 simulates it by converting a copy to CRLF.
- **AC-10** now lists `*.keystore` (Gate 1); TC-001-21 checks `app/android/app/release.keystore` and TC-001-40 checks a real dummy one.
- **AC-11 "no paid package"** can only be checked by reading each package's licence on pub.dev (TC-001-27) — manual, not part of every regression.

## 3. Regression cases from bugs
Every bug found in this feature adds a case here. It is never deleted.

| ID | Bug | Scenario | Expected | Automated test |
|---|---|---|---|---|
| — | — | No bugs found in runs R1 and R2 (2026-11-01) | — | — |

## 4. Test runs *(Tester)*
| Run | Date | Build / task | Passed | Failed | Notes |
|---|---|---|---|---|---|
| R1 | 2026-11-01 | Step 8, T-001…T-007 + T-011 (uncommitted working tree, 0 commits) | 40 | 0 | 44 active cases: 40 Pass, 0 Fail, 2 Blocked (TC-001-29, -46: no Android SDK), 1 Pending (TC-001-48: runs after T-010), 1 N/A (TC-001-34: no plugin packages). Flutter reached by `$env:Path += ';C:\src\flutter\bin'` per PowerShell call (TC-001-32 by full path; TC-001-30 by `export PATH` in Git Bash). `flutter --version`: Flutter 3.47.9 stable, rev c197ca5199, Dart 3.13.7, DevTools 2.60.0. Before the run the T-011 follow-ups were applied to this file: TC-001-21 +7 paths (18 total), TC-001-15 semantics tap check, TC-001-44 step order. |
| R2 | 2026-11-01 | T-008 (`Ready for test`: `ndkVersion = "30.0.16248370"`, D-025) + full regression on the machine with Android SDK, NDK 30.0.16248370 and emulator `emulator-5554` (uncommitted working tree, 0 commits) | 35 | 0 | 35 cases run (all Regression-yes cases + TC-001-29, -46), all Pass. Not re-run (Regression = no, R1 result stands): TC-001-27, -28 (run once), -30, -32, -38, -41 (Pass); TC-001-34 N/A; TC-001-33 **Superseded** (its "no SDK" precondition no longer exists — not a failure); TC-001-48 Pending (after T-010). Feature total (44 active): **41 Pass, 0 Fail, 0 Blocked, 1 Pending, 1 N/A, 1 Superseded.** Flutter reached by `$env:Path += ';C:\src\flutter\bin'` per PowerShell call; `flutter --version`: Flutter 3.47.9 stable, rev c197ca5199, Dart 3.13.7, DevTools 2.60.0. No bugs. |

### Latest run — detailed results (R2)
Run R2, 2026-11-01. Commands exactly as in sections 1, 1.1, 2, 2.1, from `app/` unless stated. Emulator `emulator-5554` (`sdk gphone64 x86 64`, Android 17 / API 37), already booted (`sys.boot_completed` = 1).

| ID | Result | Evidence / bug |
|---|---|---|
| TC-001-01 | Pass | `True` ×4 |
| TC-001-02 | Pass | `sdk: ^3.13.7`; `flutter pub get` exit 0, no SDK-version error |
| TC-001-03 | Pass | `False` ×5 |
| TC-001-04 | Pass | Folders `core`, `data`, `domain`, `features`; files `app.dart`, `main.dart` |
| TC-001-05 | Pass | From root: `app/lib/app.dart`, `core/README.md`, `data/README.md`, `domain/README.md`, `features/README.md`, `features/placeholder/placeholder_screen.dart`, `main.dart` — every layer folder has a file |
| TC-001-06 | Pass | Counts 0 / 0 / 0 `.dart` files (vacuous, as expected); automated guard passes |
| TC-001-07 | Pass | `analysis_options.yaml` unchanged from R1: include `very_good_analysis`, only override `public_member_api_docs: false`; `pubspec.yaml` `very_good_analysis: ^11.0.0`, no `flutter_lints`; DECISIONS D-016 = 11.0.0 |
| TC-001-08 | Pass | `flutter analyze` → `No issues found! (ran in 6.6s)`, exit 0 (also PASS inside `check.ps1`) |
| TC-001-09 | Pass | `exclude:` = exactly `build/**`, `android/**`, with reason comment |
| TC-001-10 | Pass | `Formatted 5 files (0 changed)`, exit 0 |
| TC-001-11 | Pass | `flutter test` → `+5: All tests passed!`, exit 0 |
| TC-001-12 | Pass | Static scan printed nothing; `--reporter expanded`: 5 names, all `TC-001-NN ` (06, 14, 15, 16, 43) |
| TC-001-14 | Pass | Automated test passes |
| TC-001-15 | Pass | Automated test passes |
| TC-001-16 | Pass | Automated test passes |
| TC-001-17 | Pass | No `uses-permission` in the main manifest |
| TC-001-18 | Pass | From `app/` and root: `C:/Users/mayan/Documents/Idea bank/daily-budget-app` |
| TC-001-19 | Pass | `git log` → `fatal: your current branch 'main' does not have any commits yet` (exit 128); `git rev-list --all --count` → `0` |
| TC-001-21 | Pass | `Test-Path .gitignore` → `True`; `git check-ignore -v` 18 paths → 18 lines, exit 0; root `.gitignore` is the source for `.idea/`, `.env`, `.env.*`, `*.pem`, `*.p12`, `*.db`, `*.db-wal`, `*.sqlite3` |
| TC-001-22 | Pass | `app/pubspec.lock` → no output, exit 1 |
| TC-001-23 | Pass | `app\.dart_tool`, `app\build` → `True`, `True` (build now also holds the Gradle APK output); `git status` filter printed nothing |
| TC-001-24 | Pass | DECISIONS D-015 Flutter 3.47.9 / Dart 3.13.7 = machine; D-016…D-019 rows unchanged from R1 (exact versions, reason, date, decided by). New D-025 (NDK 30.0.16248370) is a toolchain pin, not a package — has version, reason, date |
| TC-001-25 | Pass | Only non-SDK package `very_good_analysis`: `^11.0.0` = DECISIONS 11.0.0 = `pubspec.lock` `"11.0.0"`. Same 4 transitive packages have newer versions (SDK-pinned; note only) |
| TC-001-29 | **Pass** | `flutter devices` lists `sdk gphone64 x86 64 • emulator-5554 • android-x64 • Android 17 (API 37) (emulator)`. `flutter build apk --debug` → `√ Built build\app\outputs\flutter-apk\app-debug.apk`, exit 0 (9.6 s, warm Gradle). App force-stopped, `adb logcat -c`, then `flutter run -d emulator-5554 --no-resident` → built (16.0 s), `Installing … 4.1s`, launched, `Syncing files to device … 86ms`, exit 0. `dumpsys activity`: `topResumedActivity = com.dailybudget.app/.MainActivity`, pid 8347. Screenshot `docs/reviews/r2-emulator.png` (Tester's own, 1080×2400): `Daily Budget App` and `Setting things up. Your daily budget will appear here soon.` centred; only other mark is the debug banner (not a `Text`). Terminal: no `Exception`/`Error` lines from the app (only PowerShell's `NativeCommandError` wrapper around Gradle's JDK "restricted method" stderr warning — a host-JDK warning, recorded, not a fail). Logcat (1,326 lines): no `FATAL`, no `AndroidRuntime`, no `E/flutter`, no error-level line from pid 8347; app-pid warnings only from the emulator GPU/SELinux (`HWUI 101010-2`, `vendor.mesa.virtgpu.kumquat`, `max_map_count` avc denied, `Unknown dataspace 0`). Other `Exception` lines belong to system processes (`WindowManager` DeadObjectException for the force-stopped previous instance, Play Store `Finsky`, `NullBinder`) — not the app |
| TC-001-31 | Pass | Search printed nothing |
| TC-001-35 | Pass | Both searches no output; `test\widget_test.dart` → `False` |
| TC-001-36 | Pass | `name: daily_budget`; imports only `package:daily_budget/…`, `flutter`, `flutter_test` |
| TC-001-37 | Pass | `namespace` (l.8) and `applicationId` (l.21) = `com.dailybudget.app`; `com.example` → no output; `MainActivity.kt` in `…\kotlin\com\dailybudget\app\`, `package com.dailybudget.app`. (`ndkVersion = "30.0.16248370"` l.11 with D-025 comment — T-008's change) |
| TC-001-39 | Pass | `text: auto`, `eol: lf` for both `.dart` files |
| TC-001-40 | Pass | `local.properties` → `True` (now holds `sdk.dir`); with the 3 fake dummies, `git status` filter printed nothing; dummies removed (`False` ×3) |
| TC-001-42 | Pass | Both searches no output |
| TC-001-43 | Pass | Automated test passes |
| TC-001-44 | Pass | Step 1 only (regression): from root `& ".\tool\check.ps1"` → PASS pub get → format (`0 changed`) → analyze → test names (`Checked 2 test file(s).`) → `flutter test` (5/5); `ALL CHECKS PASSED`, exit 0; location unchanged. Steps 2–3 ran once in R1 (Pass) |
| TC-001-46 | **Pass** | `git config core.longpaths` → not set (exit 1), unchanged. `flutter build apk --debug` and `flutter run` logs searched for `too long`, `path length`, `MAX_PATH` → no match; Gradle built from the path with the space with no path errors |
| TC-001-47 | Pass | `https://github.com/astiktyagi27/Daily-Budget-App.git`, exit 0 |
| TC-001-27 | Pass (R1, not re-run) | Regression = no |
| TC-001-28 | Pass (R1, not re-run) | Run once (R1, under the original no-SDK precondition) — not re-run by design |
| TC-001-30 | Pass (R1, not re-run) | Regression = no |
| TC-001-32 | Pass (R1, not re-run) | Regression = no |
| TC-001-33 | Superseded | Precondition "no Android SDK" no longer exists (SDK installed for T-008). R1 Pass stands as the record of the clean SDK-missing failure; the Android build now succeeds (TC-001-29). Not a failure |
| TC-001-34 | N/A | Still no plugin packages in `pubspec.yaml` |
| TC-001-38 | Pass (R1, not re-run) | Regression = no |
| TC-001-41 | Pass (R1, not re-run) | Regression = no. Today `git status --porcelain` still lists only untracked top-level entries (`.claude/ .gitattributes .gitignore CLAUDE.md README.md app/ docs/ plans/ tests/ tool/`), nothing committed |
| TC-001-48 | Pending | Runs once after T-010 |

**Count (44 active):** R2 ran 35 → 35 Pass, 0 Fail. Feature total: Pass 41 · Fail 0 · Blocked 0 · Pending 1 (TC-001-48) · N/A 1 (TC-001-34) · Superseded 1 (TC-001-33). Retired, not run: TC-001-13, -20, -26, -45. Integration tests: none exist yet (`integration_test/` absent).

### Run R1 — detailed results
Run R1, 2026-11-01. Commands exactly as in sections 1, 1.1, 2, 2.1, from `app/` unless stated.

| ID | Result | Evidence / bug |
|---|---|---|
| TC-001-01 | Pass | `Test-Path pubspec.yaml, lib\main.dart, test, android` → `True` ×4 |
| TC-001-02 | Pass | `environment: sdk: ^3.13.7` (lower bound 3.13.7 ≤ 3.13.7, upper < 4.0.0). `flutter pub get` → `Got dependencies!`, exit 0, no SDK-version error |
| TC-001-03 | Pass | `Test-Path web, windows, linux, macos, ios` → `False` ×5 |
| TC-001-04 | Pass | Folders: `core`, `data`, `domain`, `features`. Files: `app.dart`, `main.dart` (`app.dart` named in plan / T-005) |
| TC-001-05 | Pass | From root, `git ls-files --cached --others --exclude-standard -- app/lib` → `core/README.md`, `data/README.md`, `domain/README.md`, `features/README.md` (+ `features/placeholder/placeholder_screen.dart`, `app.dart`, `main.dart`). READMEs opened: real layer descriptions, no dead or commented-out code |
| TC-001-06 | Pass | Counts: `package:flutter` 0, `dart:ui` 0, `.dart` files in `lib/domain` 0 (vacuous, as expected in Phase 0). Automated guard `TC-001-06 domain contains no Flutter or dart:ui imports` passes |
| TC-001-07 | Pass | `analysis_options.yaml`: `include: package:very_good_analysis/analysis_options.yaml`; only rule override `public_member_api_docs: false` (D-013). `pubspec.yaml` dev_dependencies: `very_good_analysis: ^11.0.0`, no `flutter_lints`. DECISIONS D-016 names `very_good_analysis` 11.0.0 |
| TC-001-08 | Pass | `flutter analyze` → `No issues found! (ran in 9.3s)`, exit 0 |
| TC-001-09 | Pass | `analyzer: exclude:` = exactly `build/**`, `android/**`, with a comment giving the reason (Gate 3, plan §11 item 2). `lib/`, `test/` not excluded |
| TC-001-10 | Pass | `dart format --output=none --set-exit-if-changed .` → `Formatted 5 files (0 changed)`, exit 0 |
| TC-001-11 | Pass | `flutter test` → 5 tests, `+5: All tests passed!`, exit 0 |
| TC-001-12 | Pass | 1. Static scan printed nothing. 2. `flutter test --reporter expanded`: all 5 names start `TC-001-NN ` (06, 14, 15, 16, 43); no `group()` used; exit 0 |
| TC-001-14 | Pass | Automated `TC-001-14 placeholder shows title and status text` passes; source checked: string literals, `find.byType(Text)` → `findsNWidgets(2)` |
| TC-001-15 | Pass | Automated `TC-001-15 placeholder has no buttons or text fields` passes; source checked: all 9 widget types `findsNothing`, plus `ensureSemantics()` and `find.semantics.byAction(SemanticsAction.tap)` → `findsNothing` (T-011 N4) |
| TC-001-16 | Pass | Automated `TC-001-16 placeholder renders without exceptions` passes; `takeException()` checked after `pump()` and after `pumpAndSettle()` |
| TC-001-17 | Pass | `Select-String … AndroidManifest.xml -Pattern 'uses-permission'` → no output |
| TC-001-18 | Pass | From `app/` and from root: `C:/Users/mayan/Documents/Idea bank/daily-budget-app` |
| TC-001-19 | Pass | `git log` → `fatal: your current branch 'main' does not have any commits yet` (exit 128); `git rev-list --all --count` → `0` |
| TC-001-21 | Pass | `Test-Path .gitignore` → `True`. `git check-ignore -v` with the 18 paths → 18 lines, exit 0. Root `.gitignore` is the source for `.idea/` (l.10), `.env` (l.24), `.env.*` (l.25), `*.p12` (l.26), `*.pem` (l.27), `*.db` (l.32), `*.db-wal` (l.34), `*.sqlite3` (l.37); the rest match Flutter's `app/.gitignore` / `app/android/.gitignore` first (git shows the first match; root patterns also cover them) |
| TC-001-22 | Pass | `git check-ignore -v app/pubspec.lock` → no output, exit 1 |
| TC-001-23 | Pass | `Test-Path app\.dart_tool, app\build` → `True`, `True`; `git status` filter printed nothing |
| TC-001-24 | Pass | DECISIONS D-015 Flutter 3.47.9 / Dart 3.13.7; D-016 lint `very_good_analysis` 11.0.0; D-017 Riverpod 3.4.3 (+ riverpod_lint 3.1.9); D-018 drift 2.35.3 / drift_flutter 0.3.1 / drift_dev 2.35.2 / build_runner 2.17.1; D-019 logging 1.3.0. Each row: exact x.y.z, reason, date 2026-11-01, decided by. No test helper in dev_dependencies. Machine (S1): Flutter 3.47.9, Dart 3.13.7 — match |
| TC-001-25 | Pass | Only non-SDK package: `very_good_analysis` — `pubspec.yaml` `^11.0.0` = DECISIONS 11.0.0 = `pubspec.lock` `version: "11.0.0"`. The other choices say "added in Phase 1 / Phase 2 / first feature that logs". `flutter pub outdated`: direct and dev deps up to date; note only — transitive `material_color_utilities` 0.13.0→0.13.1, `meta` 1.18.3→1.19.0, `vector_math` 2.4.0→2.4.4, `test_api` 0.7.12→0.7.15 (pinned by the Flutter SDK) |
| TC-001-27 | Pass | pub.dev checked 2026-11-01: very_good_analysis 11.0.0 MIT; flutter_riverpod 3.4.3 MIT; riverpod_lint 3.1.9 MIT; drift 2.35.3 MIT; drift_flutter 0.3.1 MIT; drift_dev 2.35.2 MIT; build_runner 2.17.1 BSD-3-Clause; logging 1.3.0 BSD-3-Clause. All OSI open source, none paid. Latest versions = DECISIONS versions |
| TC-001-28 | Pass | **Original precondition still holds** (SDK still absent): `flutter doctor` → `[X] Android toolchain … Unable to locate Android SDK`; `ANDROID_HOME` / `ANDROID_SDK_ROOT` unset; `%LOCALAPPDATA%\Android\Sdk` → `False`. From the path with the space: `flutter pub get` exit 0, `flutter analyze` exit 0 (`No issues found!`), `flutter test` exit 0 (5/5). No path, space or `ANDROID_HOME` error |
| TC-001-29 | Blocked | Android SDK and emulator not installed (README §13; T-008 Blocked). Not a Fail |
| TC-001-47 | Pass | `git remote get-url origin` → `https://github.com/astiktyagi27/Daily-Budget-App.git`, exit 0 |
| TC-001-48 | Pending | Runs once after the Orchestrator's phase-end commit + push (T-010) |
| TC-001-30 | Pass | Git Bash (`export PATH="$PATH:/c/src/flutter/bin"`, quoted `cd`): `flutter analyze` → `No issues found!`, 0; `flutter test` → `All tests passed!`, 0; `dart format …` → `0 changed`, 0 |
| TC-001-31 | Pass | Search over tracked + untracked-not-ignored files (team docs excluded) printed nothing |
| TC-001-32 | Pass | PowerShell without the PATH change: 1. `The term 'flutter' is not recognized…` (expected). 2. `& 'C:\src\flutter\bin\flutter.bat' --version` → 3.47.9 / Dart 3.13.7. 3. `… analyze` from `app/` → `No issues found!`, exit 0 |
| TC-001-33 | Pass | `flutter doctor` → Android toolchain `[X] Unable to locate Android SDK`. `flutter build apk --debug` → `[!] No Android SDK found. Try setting the ANDROID_HOME environment variable.`, exit 1 — SDK message, not a Dart or pubspec error. Expected — AC-13 Blocked, no bug |
| TC-001-34 | N/A | No Flutter plugin packages in `pubspec.yaml` (only `very_good_analysis`, dev); `pub get` printed no symlink warning |
| TC-001-35 | Pass | Counter-sample search in `lib/`, `test/` (`integration_test/` absent) → no output; `FloatingActionButton` in `lib/` → no output; `test\widget_test.dart` → `False` |
| TC-001-36 | Pass | `name: daily_budget` (matches `^[a-z][a-z0-9_]*$`, as in plan). All package imports in `lib/` and `test/` (checked recursively too) use `package:daily_budget/…` or flutter / flutter_test |
| TC-001-37 | Pass | `build.gradle.kts`: `namespace = "com.dailybudget.app"` (l.8), `applicationId = "com.dailybudget.app"` (l.20). `com.example` search → no output. `MainActivity.kt` at `…\kotlin\com\dailybudget\app\`, first line `package com.dailybudget.app`. DECISIONS D-021 |
| TC-001-38 | Pass | Scratch copy at `%TEMP%\tc-001-38`; all 5 `.dart` files confirmed CRLF; `dart format --output=none --set-exit-if-changed` → `Formatted 5 files (0 changed)`, exit 0 (it also printed "Package resolution error … very_good_analysis" warnings because the bare copy has no `.dart_tool` — expected for a copy, not a product issue). Scratch removed (`Test-Path` → `False`). `git config core.autocrlf` → `true` |
| TC-001-39 | Pass | `git check-attr text eol` → `text: auto`, `eol: lf` for both `.dart` files (`.gitattributes` per plan) |
| TC-001-40 | Pass | 1. `Test-Path app\android\local.properties` → `True`. 2. With the 3 fake dummy files created, the `git status` filter printed nothing. 3. Dummies removed (`Test-Path` → `False` ×3) |
| TC-001-41 | Pass | 1. One `.git`: `…\daily-budget-app\.git`. 2. `app\.git` → `False`. 3. `git -C "…\Idea bank" rev-parse --show-toplevel` → `fatal: not a git repository (or any of the parent directories)`, exit 128. 4. `git status --porcelain` → `?? .claude/ .gitattributes .gitignore CLAUDE.md README.md app/ docs/ plans/ tests/ tool/` — all untracked, nothing committed |
| TC-001-42 | Pass | `print(` search and TODO-without-task-ID search in `lib/`, `test/` → no output |
| TC-001-43 | Pass | Automated `TC-001-43 placeholder fits at text scale 3.0 on small screen` passes (320×568, text scale 3, view reset in `addTearDown`) |
| TC-001-44 | Pass | From root (path with a space), PowerShell 5.1, policy `RemoteSigned`, no bypass needed. 1. `& ".\tool\check.ps1"` → PASS pub get → format → analyze → test names (`Checked 2 test file(s).`) → `flutter test` (5/5); `ALL CHECKS PASSED`, exit 0; caller location unchanged. 2. With `app\test\tc_001_44_tmp_test.dart` (badly formatted): `Changed test\tc_001_44_tmp_test.dart`, `FAIL  dart format (check only)`, `CHECK FAILED at step: dart format (check only)`, exit 1; location restored. 3. Temp file removed (`Test-Path` → `False`); re-run `ALL CHECKS PASSED`, exit 0 |
| TC-001-46 | Blocked | Runs with TC-001-29 (no SDK / emulator). Recorded now: `git config core.longpaths` → not set (no output, exit 1) |

**Count (44 active):** Pass 40 · Fail 0 · Blocked 2 (TC-001-29, -46) · Pending 1 (TC-001-48) · N/A 1 (TC-001-34). Retired, not run: TC-001-13, -20, -26, -45.

## 5. Test report to Project Manager *(Gate 4)*

### Report for run R2 (2026-11-01) — T-008 + full regression
- **Verdict:** **Pass.** T-008 passes (TC-001-29, TC-001-46), and the full regression on the machine that now has the Android SDK is green. **T-008 → Done.** F-001 is ready for the PM's short Gate 4 re-review of AC-13.
- **ACs covered:** **13 / 13 pass** (AC-1 … AC-13). AC-13: the app builds from the path with the space, installs and launches on `emulator-5554` (Android 17 / API 37), shows exactly the placeholder title and status text (`docs/reviews/r2-emulator.png`), and logcat has no app exceptions; no path-length errors with `core.longpaths` unset. AC-9's post-push check TC-001-48 is still Pending until T-010 (pre-commit checks TC-001-18, -19, -47 pass).
- **Bugs logged:** none.
- **Full regression:** **green** — `tool/check.ps1` ALL CHECKS PASSED (exit 0), `flutter analyze` 0 issues, `flutter test` 5/5, all 34 Regression-yes cases pass (incl. TC-001-29 and TC-001-44 step 1; plus TC-001-46), `REGRESSION.md` checks 1–9 pass (check 9 = emulator, now run). Integration tests: none exist yet. Affected existing features: none.
- **Counts (44 active):** R2 ran 35, 35 Pass, 0 Fail. Feature total 41 Pass · 0 Fail · 0 Blocked · 1 Pending (TC-001-48) · 1 N/A (TC-001-34) · 1 Superseded (TC-001-33).
- **Notes:**
  1. **TC-001-28** ran once in R1 (original no-SDK precondition) and is not re-run, by design.
  2. **TC-001-33** (Android build without the SDK) is **Superseded**, not failed: its precondition no longer exists. Its R1 Pass remains the record.
  3. **Terminal noise, not a fail:** Gradle's host JDK prints `WARNING: A restricted method in java.lang.System has been called` (native-platform loader); PowerShell 5.1 wraps that stderr line as `NativeCommandError`. Build and run exit 0. Logcat warnings from the app's pid are emulator GPU/SELinux noise (`HWUI 101010-2`, `virtgpu.kumquat`, `max_map_count`), as the PM noted at Gate 3.
  4. **Screenshot tip for later runs:** in PowerShell 5.1, `adb exec-out screencap -p > file.png` corrupts the PNG (text re-encoding). Use `adb shell screencap -p /sdcard/x.png` + `adb pull`.
  5. **TC-001-29 / -46 wording** still says "Expected result today: Blocked" / "Blocked until AC-13 can run" — historical; both now run. The Tester can drop those phrases in a later tidy-up (no ID or test-name change).
  6. Review N5 (README §13 should name NDK 30.0.16248370) is the Developer's, before T-010 — not a test item.

### Project Manager — Gate 4 re-review (2026-11-01, run R2)
**Verdict: Pass — F-001 complete, 13 / 13 ACs.** F-001 → Done.
- [x] AC-13 is now proven. TC-001-29 and TC-001-46 pass. Both screenshots (`docs/reviews/t-008-emulator.png`, `docs/reviews/r2-emulator.png`) show exactly the two placeholder texts plus the framework debug banner. The logcat has no app exceptions, and the build had no space-in-path or long-path errors.
- [x] The statuses are correct:
  - TC-001-33 is Superseded, not failed: its "no SDK" precondition no longer exists, and its R1 Pass stands.
  - TC-001-34 N/A is correct, because there are no plugin packages.
  - TC-001-48 is Pending by design and runs once after T-010.
  - Cases marked Regression = no keep their R1 Pass.
- [x] Full regression is green on the machine with the SDK, and `REGRESSION.md` checks 1–9 pass. The PM re-ran `tool/check.ps1` independently at Gate 5: ALL CHECKS PASSED, 5/5. No bugs are open.
- Nice to have, Tester, next time this file is touched: remove the now-historical "Expected result today: Blocked" wording from TC-001-29 and TC-001-46. No ID or test name changes.
- After T-010: the Tester runs TC-001-48 once, and the PM retires TC-001-19 (it only holds before the first commit).

### Report for run R1 (2026-11-01) — superseded by R2 for AC-13
- **Verdict:** **Pass** for T-001…T-007 and T-011 — every case that can run today passes; no bugs. F-001 as a whole is **not complete**: AC-13 (app runs on the emulator) is **Blocked** until the Owner installs Android Studio / SDK / emulator (README §13), so Phase 0 cannot be signed off yet (T-008 stays Blocked).
- **ACs covered:** 13 / 13 have test cases; **12 / 13 pass** (AC-1 … AC-12). AC-13 Blocked (TC-001-29, -46; TC-001-33 confirms the Android build fails cleanly with an SDK-not-found message). AC-9's post-push check TC-001-48 is Pending until T-010; its pre-commit checks (TC-001-18, -19, -41, -47) pass.
- **Bugs logged:** none.
- **Full regression** (all automated tests + `REGRESSION.md`): **green** — `flutter analyze` 0 issues, `flutter test` 5/5, `tool/check.ps1` ALL CHECKS PASSED (PowerShell; Git Bash equivalents via TC-001-30), every Regression-yes manual case that can run today passes. Integration tests on the emulator: none exist yet and cannot run (no SDK). Affected existing features (plan §8): none — F-001 is the first feature.
- **Notes:**
  1. **TC-001-28** ran under its original precondition — the Android SDK is still absent today (same as at T-002, plan §11 item 1). It is not re-run after the SDK is installed; TC-001-08/-10/-11 keep checking the path with a space.
  2. **T-011 follow-ups** applied to this file before the run: TC-001-21 now checks 18 paths (adds `.env`, `.env.local`, `key.pem`, `cert.p12`, `app/x.db`, `app/x.db-wal`, `app/x.sqlite3` — all ignored by the root `.gitignore`); TC-001-15 mentions the semantics tap-action check; TC-001-44 states the `check.ps1` step order (test-name check before `flutter test`). No automated test name changed.
  3. **TC-001-46 pre-read:** `git config core.longpaths` is not set. If the first emulator build (T-008) hits "Filename too long", that is the first thing to look at; no action now.
  4. **TC-001-25:** four transitive packages have newer versions (pinned by the Flutter SDK, not by the app) — informational only.
  5. **TC-001-19** passes now (0 commits); after T-010 the PM retires it and TC-001-48 (Pending) takes over — the Tester runs it once after the push.
  6. `tests/REGRESSION.md` now lists F-001's key manual checks and the `tool/check.ps1` line; run R1 is recorded there.

### Project Manager — Gate 4 review (2026-11-01, run R1)
**Verdict: Pass (partial — AC-1 … AC-12).** F-001 is **not Done**: AC-13 is Blocked, so neither the feature nor Phase 0 can be signed off yet.

Checked:
- [x] Every active case has a recorded result with evidence (44 active: 40 Pass, 0 Fail, 2 Blocked, 1 Pending, 1 N/A; 4 retired not run).
- [x] Every AC has at least one case; AC-1 … AC-12 pass. AC-13 Blocked (TC-001-29, -46), and the Blocked status is justified: TC-001-33 shows the Android build stops with "No Android SDK found", which is an environment gap, not a product defect.
- [x] Full regression green (`flutter analyze` 0 issues, `flutter test` 5/5, `tool/check.ps1` ALL CHECKS PASSED, `REGRESSION.md` checks 1–8); check 9 (emulator) Blocked. Logged in `tests/REGRESSION.md`.
- [x] No failures, so no bugs needed; `docs/BUGS.md` has none open for F-001.
- [x] TC-001-34 N/A is correct (no plugin packages). TC-001-48 Pending is correct (it can only run after the push). TC-001-28 ran under its original "no SDK" precondition, which is the strongest evidence for AC-12.
- [x] T-011 test-file follow-ups applied (TC-001-21 18 paths, TC-001-15 tap check, TC-001-44 step order); no automated test name changed.

**Still to do before Gate 5 (phase sign-off), in order:**
1. **Owner:** install Android Studio, the Android SDK and an emulator (README §13).
2. **Developer — T-008:** `flutter run` from `app/` on the emulator. The placeholder must appear with no exceptions. If Gradle fails on the path with the space or on path length, log a bug with the exact error. Changing `core.longpaths` or moving the project is an Owner decision.
3. **Tester — run R2:** run TC-001-29 and TC-001-46 and `REGRESSION.md` check 9. Re-run the full regression on the machine that now has the SDK: `tool/check.ps1`, plus the Regression-yes manual cases. Record the results in §4/§5.
4. **Project Manager:** a short Gate 4 re-review of R2, covering only the AC-13 cases.
5. **Developer:** complete feature doc §7 (technical) and set the INDEX status to `Done`.
6. **Project Manager — Gate 5:** sign off Phase 0 in `plans/phase-0-overview.md`, then the CEO writes the phase report for the Owner.

**After Gate 5 and the CEO report (does not block sign-off):** the Orchestrator does T-010 (one phase commit and push). The Tester then runs TC-001-48 once. The PM retires TC-001-19 after the push, because it only holds before the first commit.
