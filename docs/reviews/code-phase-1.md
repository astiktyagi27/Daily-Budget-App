# Code review (Gate 3): Phase 1

One file for the phase, with a section for each batch of tasks. Reviewer: Project Manager.

---

## T-101 + T-102 (2026-11-05)

**Verdict: Approved → Ready for test.** No Must-fix items.

**Files:**
- T-101: `app/pubspec.yaml`, `app/pubspec.lock`, `app/analysis_options.yaml`, `app/android/app/build.gradle.kts`, `app/lib/main.dart`, `docs/DECISIONS.md`
- T-102: `app/lib/data/preferences/` (4 files), `app/lib/core/providers/preferences_providers.dart`, and three test files under `app/test/data/preferences/` and `app/test/core/providers/`

**What I ran:** the Developer is building T-103…T-108 in the same working tree, so I did not run `tool/check.ps1` across the whole tree. Instead:
- `flutter test test/data test/core/providers test/architecture`: 12/12 pass.
- `dart analyze` on the T-101/T-102 files: no issues.
- The Developer's full run before handover: `check.ps1` passed with 16 tests.
- The [P] debug build: OK on `flutter.ndkVersion` (28.2.13676358) in 47 s.

| Check | Result |
|---|---|
| Correct | Matches plan F-002 §1.2, §3, §5 and Gate 1 §10 points 2–4 and 6. Back on `flutter.ndkVersion`, so the NDK fallback was not needed. `riverpod_lint` is under `plugins:`. D-026…D-030 are added. Reads are total: a missing key, an unlisted key or a wrong type gives `null`. Writes never throw (`false`). `openPreferencesStore()` falls back to memory. The provider throws without an override. |
| Clean | Small files. The plugin is imported in one file only. The allow-list check happens before the plugin call, so nothing is caught for normal reads. Pattern `switch` handles type checks. No dead code, and comments explain why. |
| Modern | `SharedPreferencesWithCache` (not the legacy API), Dart 3 `final class` / `abstract interface class`, `const new` constructors, and Riverpod 3 `ProviderException` handled correctly in the test. |
| Tested | 11 new tests, named by TC ID. The adapter is tested on `InMemorySharedPreferencesAsync` plus throwing platforms (unreadable store, write failure), so it runs in plain `flutter test` with no device. |
| UX | Not applicable (no UI). |
| Safe | No logging and no network. The allow list blocks stray keys. No permission is added (main manifest unchanged). |

### Deviations (plan F-002 §11), decided
| # | Item | Decision |
|---|---|---|
| D1 | **`ProviderScope` added to `main.dart` in T-101 (§11 T-101 item 4).** It is needed to keep analyze at zero once `riverpod_lint` is active (`missing_provider_scope`). This is the shape T-108 builds on. | **Approved.** |
| D2 | **`flutter analyze` does not run analyzer plugins (§11 T-101 item 3).** Only `dart analyze` shows `riverpod_lint` findings, so `check.ps1` does not enforce D-027 today. | **Approved: add a step.** Keep `flutter analyze` (TC-001-08 and the F-001 docs refer to it). Add a `dart analyze --fatal-infos` step right after it, with the same PASS/FAIL pattern. `--fatal-infos` is required: many lints are info level, and `dart analyze` exits 0 on infos by default. Prove it with a temporary probe (for example `runApp` without `ProviderScope` in a scratch file) that makes the step FAIL, then remove the probe. → **T-129**. |
| D3 | **Test-name check false positive on `ProviderContainer.test(` (§11 T-102 item 5).** | **Approved:** use `(?<![.\w])(?:test\|testWidgets)\(`. It still matches `test(` at the start of a line or after whitespace, `(` or `,`. Prove it both ways: an unnamed `test('x'…)` still FAILS, and `ProviderContainer.test(` no longer does. After that, provider tests may use `ProviderContainer.test()` (auto-dispose), but they don't have to. → **T-129**. The Tester's manual TC-001-12 scan pattern must change the same way (T-130). |
| D4 | Keys added per feature, not ahead of time (§11 T-102 item 1). | **Approved.** T-118 and T-121 add their keys to `PreferenceKeys` and the allow list. |
| D5 | `writeBool(key, value:)` named parameter; `open({allowList})` factory (§11 T-102 items 2–3). | **Approved** (lint-driven; the test-only `allowList` parameter is fine). |
| D6 | **Several automated tests under one TC ID with store-level titles (§11 T-102 item 4).** | **Approved as a rule for the phase:** a TC may have more than one automated test (unit and widget levels), as long as each test name starts with that TC ID. The Tester lists every file in the case's "Automated test" column (T-130). The app-level widget tests in T-108 use the Tester's exact titles. |

### Nice to have
- **N1 (Developer, any later store task, e.g. T-118):** `InMemoryPreferencesStore` accepts any key, but the real store refuses keys that are not on the allow list. Give the fake an optional `allowList` (default: no check) and use `PreferenceKeys.allowList` in the app-level harness (T-106/T-108). A feature that forgets to register its key would then fail in widget tests, not only on the device.

### Follow-up tasks created
- **T-129** (Developer): the two `check.ps1` changes D2 and D3.
- **T-130** (Tester): add the T-102 test files to TC-002-10/-13/-14/-36; update the TC-001-12 scan regex (D3) and the TC-001-44 / REGRESSION check 1 step list (D2), after T-129.

---

## T-103 … T-108 (2026-11-05)

**Verdict: all six approved → Ready for test.** No Must-fix items for these tasks. Two conditions are passed on to later tasks (C1, C2 below).

**What I ran:**
- `flutter test` (whole suite): 58 of 58 pass.
- `dart analyze --fatal-infos`: no issues. One run reported 1 issue while the Developer was saving T-129 files; the re-run was clean.
- The Developer's `check.ps1` run was green, and the debug build was OK.
- I re-measured the font files with my own small TrueType reader (scratch, outside the project).

### T-103 decision: Plex has ₹ but no `tnum`
**Option (a) accepted.** My own measurement agrees with the Developer's:
- IBM Plex Sans Regular, Medium and SemiBold: all ten default digits are **600 units** wide, and ₹ is in `cmap`.
- Bricolage (the control): digits from 333 to 665 units wide, so its digits are proportional.

The design's goal, that amounts line up digit for digit, is therefore met by default. A missing `tnum` feature changes nothing on screen. Switching font (option b) would throw away an approved design for no visible gain.

What changes:
- **DECISIONS D-028:** the check is now "₹ present and tabular figures (equal default digit widths **or** `tnum`)", decided by me.
- **Design §4.1:** says the same, with a change-history line.
- **Code:** `FontFeature.tabularFigures()` stays on the money styles. It is harmless, and it covers a later font that needs it.
- **TC-002-42:** the expected result is reworded by the Tester (T-130). The test already checks exactly this, and the Bricolage check proves the test can fail.

### Deviations (plan F-002 §11)
| # | Item | Decision |
|---|---|---|
| E1 | `.gitattributes`: `app/assets/fonts/*.txt -text`, so the CRLF Plex licence stays byte-exact and its SHA-256 still matches | **Approved.** The scope is narrow (one folder, `.txt` only) and it is recorded in D-022. |
| E2 | `ThemeChoice` created in T-105 instead of T-108 | **Approved.** It was needed by `themeConfigFor`, and it is pure Dart (TC-001-06 holds). |
| E3 | `ThemeData(fontFamily: 'Plex')`, then the heading slots set back to Bricolage with `copyWith` | **Approved.** This is the correct way round the way `fontFamily` overrides every style. TC-002-29 proves that only `displaySmall`, `headlineSmall` and `titleLarge` are Bricolage. |
| E4 | Elevation 0 on the bottom sheet and snackbar; the `BudgetElevation` shadows are drawn by the floating parts themselves | **Approved,** with condition **C1**. |
| E5 | `BudgetListRow` is one merged semantics node (label, description and tag; the trailing `Switch` is part of the labelled target) | **Approved for T-107,** with condition **C2**. |
| E6 | Interim test titles for cases whose full steps need later screens (TC-002-02, -05, -07, -09, -10, -13, -14, -31, -33, -36; component-level TC-002-23/-24) | **Approved** under the D6 rule: several tests may share one case ID. **Condition:** a test with the Tester's exact title must exist for each of these cases by the end of T-109 (picker cases) or T-114 (tab cases). I check this at their Gate 3, and Gate 4 checks it too. |
| E7 | AC-4 "within 1 second" tested as 4 frames × 250 ms | **Approved.** A single `pump(1 s)` is one frame, on which the switch only starts. The Tester puts this in TC-002-05's steps (T-130). |
| E8 | Remove animations done in `DailyBudgetApp` through `didChangeAccessibilityFeatures`; test named **TC-002-45** | **Approved.** The case row moves from T-127 into **T-130**, so T-127 no longer needs to add it. |
| E9 | FakeStore = `InMemoryPreferencesStore` + `test/helpers/failing_preferences_store.dart` (the failing store throws on purpose) | **Approved.** The plan's file names apply; the Tester updates test file §0 (T-130). |
| E10 | Extra automated aids under TC-002-26, which is a manual case; TC-002-29 here covers font loading only | **Approved** (D6 rule). The Tester lists them. |
| E11 | Other small choices: `BudgetTypeScale` holds all 12 styles; `BudgetMotion.full`/`.off`; `BudgetElevation.lerp` snaps to the end values (no leftover shadow in Dark); hover/focus overlays transparent (the ring shows focus); `systemNavigationBarContrastEnforced: false`; theme saves chained so the last tap wins; the repository also catches a store that throws; grouping as you type waits for Phase 2 | **Approved.** All are simpler or safer than the plan text. |

### Conditions for later tasks (Must fix at those tasks' Gate 3)
- **C1 (T-117, T-109):** a sheet opened through `showBudgetSheet` must draw `BudgetElevation.sheet` in Light, and nothing in Dark or Dim (design §5.3). It must not look flat on the Light theme. Add a check to the help-sheet and picker tests.
- **C2 (T-117, also T-113):** the (i) must stay a **separate** semantics node, "More about <label>, button" (F-004 AC-4, settings.md §2.2). `MergeSemantics` would swallow it into the row. Put the `info` slot outside the merged node, or wrap the (i) in its own `Semantics(container: true, explicitChildNodes: true)` boundary, and prove it with a semantics test. For the Coming-soon rows in T-113, the merged node must read exactly `<Label>, coming soon, not available yet. <Description>`.

### Nice to have
- **N2 (Developer, T-107 follow-up, no rush):** the tag-reflow rule assumes a trailing width of 120 dp. Measuring the actual tag (an `IntrinsicWidth` / `LayoutBuilder` pass) would remove the guess. TC-003-16 at 2.0× will show whether the guess is good enough.

---

## T-129 (2026-11-05)

**Verdict: approved → Ready for test.** No Must-fix items.

- **Change:** only `tool/check.ps1`.
  - New step `dart analyze --fatal-infos` right after `flutter analyze`. It uses `$dart` (already resolved by `Find-FlutterTool`), sits inside the existing `try/finally` and uses the same PASS/FAIL pattern.
  - The test-name call pattern is now `(?<![.\w])(?:test|testWidgets)\(`.
  - The header comment and step list are updated. The file is still CRLF with PS 5.1 syntax.
- **Proof:** three temporary probes, all deleted afterwards.
  1. A `riverpod_lint` info: `flutter analyze` passes, `dart analyze --fatal-infos` FAILS, exit 1.
  2. `test('x', …)`: the name check FAILS, exit 1.
  3. A TC-named test using `ProviderContainer.test()`: the name check passes.
- **Clean run:** ALL CHECKS PASSED from PowerShell and Git Bash, 58 tests.
- **Review D2 and D3 are closed.**
- **Note:** `\w` includes `_`, so `my_test(` and `_test(` helpers are also not taken for test declarations. That is correct. A bare `test(` at the start of a line, or after whitespace, `(` or `,`, is still caught.

**Nice to have N3 (Developer, the next time the file is touched, e.g. T-118 provider tests):** switch `test/core/providers/preferences_providers_test.dart` to `ProviderContainer.test()`. It disposes the container itself, so the workaround comment can go. This is not worth a task of its own.

**Tester:** T-130 (b) can now go ahead. It covers the TC-001-12 scan pattern, plus TC-001-44 and REGRESSION check 1 gaining the `dart analyze --fatal-infos` step.

---

## T-116 … T-114 (shell batch) (2026-11-06)

Tasks: T-116, T-117 (F-004), T-111, T-112, T-113, T-114 (F-003).

| Task | Verdict |
|---|---|
| T-116 Help copy, `LabelDescription`, `NavTooltip` | **Approved → Ready for test** |
| T-117 (i) button and help sheet | **Changes requested → In progress** (M1, M2) |
| T-111 Shell, bottom bar, back | **Changes requested → In progress** (M3, one-line fix) |
| T-112 Placeholder tabs | **Approved → Ready for test** |
| T-113 Settings list | **Approved → Ready for test** |
| T-114 Remove placeholder, app name | **Approved → Ready for test** |

Conditions **C1** and **C2** from the T-103…T-108 review are **met**. Condition **E6** is **met** for the tab cases. The picker cases are checked at T-109.

**What I ran**
- `tool/check.ps1` from PowerShell, with Flutter at `C:\src\flutter\bin`: **ALL CHECKS PASSED**. That covers `flutter analyze`, `dart analyze --fatal-infos`, format, the test-name check and **85/85 tests**. I did not repeat the debug build. The Developer's `flutter build apk --debug` was OK (35 s).
- `git diff d11fd32` / `git status` under `app/`. Changed tracked files: `lib/app.dart`, `lib/main.dart`, the manifest (`android:label="Daily Budget App"` + `android:enableOnBackInvokedCallback="true"`, nothing else), `pubspec.*`, `analysis_options.yaml`, `build.gradle.kts`. Deleted: `lib/features/placeholder/placeholder_screen.dart` and `test/features/placeholder/placeholder_screen_test.dart`. All other files are new.
- **Line endings:** `git status` lists `res/drawable/launch_background.xml`, `res/drawable-v21/launch_background.xml`, `res/values/styles.xml` and `res/values-night/styles.xml` as modified. However, `git diff d11fd32 --exit-code` on them is empty, `--stat` is identical with and without `--ignore-cr-at-eol`, and `git ls-files --eol` shows `i/lf w/lf`. Only the files' stat info changed, not their content, so nothing will be committed for them. ✔
- I checked two Flutter framework details against the source in `C:\src\flutter`: `Text` applies `MediaQuery.boldTextOf` (`widgets/text.dart:722`), and `ModalBottomSheetRoute.barrierDismissible => isDismissible`.

| Check | Result |
|---|---|
| Correct | Every AC in the tasks' scope is met. There are two edge-case bugs in T-117 (M1, M2). C1/C2 met. The Coming-soon string is exact and is asserted for all 7 rows (TC-003-07) and in the reading order (TC-003-17). |
| Clean | Small widgets, the right layers, and comments that explain *why*. One dead field (M3). `TODO(T-109)` carries a task ID (STANDARDS §5). |
| Modern | Dart 3.13 `new` constructors, records (`HelpInfo`), null-aware list elements (`?tag`), `switch` expressions, `case final x?` patterns, `TextScaler.clamp`, `PopScope.onPopInvokedWithResult`, `AnimationStyle`, `WidgetStateProperty.fromMap`. No deprecated APIs. |
| Tested | 27 new tests, all named by TC ID. Exact literals come from the docs, never from the app's constants. The semantics tests prove C2, and the decoration tests prove C1 per theme. |
| UX | Matches app-shell, settings and help-pattern. The ink tick slides; selection has three non-colour cues; back goes to Home and then leaves. The (i) is 4 dp after the last word. |
| Safe | No logging, no network, no new permission. `enableOnBackInvokedCallback` is not a permission. |

### Conditions from earlier reviews
- **C1, the sheet shadow in Light only: met.** `BudgetSheetFrame` paints `context.budgetElevation.sheet`. TC-004-16 checks the exact Light literal (`0 −8 32`, `#1C1B22` at 12 %) and an empty list in Dark and Dim (5 theme cases), and TC-004-19 checks that the shadow disappears on a live switch to Dark. The T-109 picker must open through `showBudgetSheet` (it gets the frame for free), and its test repeats the C1 check (still owed at T-109).
- **C2, the (i) as its own node: met.** The Developer is right that nothing escapes a `MergeSemantics`. The fix is to use an explicit container node for any row that has an (i). TC-004-05 asserts `More about Theme` (button, tap action) with a node id different from the row's, and the row reads `Theme. Auto (follows your phone)` without "More about", in 5 themes × 1.0/2.0. Rows without an (i) keep the approved E5 merge. The Coming-soon string `<Label>, coming soon, not available yet. <Description>` is exact (`HelpCopy.comingSoon`; TC-003-07 checks all 7 rows).
- **E6, tab-level F-002 cases: met.** TC-002-02, -05, -10, -13, -14, -31 and -36 have tests with the Tester's exact titles. TC-002-09/-33 (picker) are checked at T-109.

### Deviations, decided

**Plan F-004 §11**

| # | Item | Decision |
|---|---|---|
| F4-1 | `_BudgetSheetRoute` (a `ModalBottomSheetRoute` subclass): the scrim ignores taps until the entrance animation completes | **Approved,** subject to **M2**. The subclass is small and correct: the status listener is added in `install` and removed in `dispose`, the rebuild is guarded by `isActive`, and Back still pops during the animation. It is safer than tricks in the caller, because the stray second tap really does land on the scrim. Recorded as **D-031**. |
| F4-2 | `BudgetSheetFrame` draws fill, corners, shadow and handle; no Material drag handle, so no handle "Dismiss" action | **Approved. The accessibility trade-off is acceptable.** (1) The stock M3 sheet has no handle unless `showDragHandle` is set, so we lose nothing compared with the default. (2) TalkBack users still have three close paths: the visible **Got it** (with its hint), the Back gesture, and the scrim node ("Close Bottom Sheet" once the sheet is open). (3) A second "Dismiss" stop would duplicate Got it. **Rule (D-031):** every sheet opened through `showBudgetSheet` must contain its own visible close button. The help sheet has Got it, and the T-109 picker has Done. TC-004-04 (manual) also confirms the handle is not a focus stop. |
| F4-3 | A row with an (i) uses one explicit container node; its `trailing` is excluded from semantics, so it must be decorative | **Approved** (see C2), recorded in **D-032**. The constraint is documented on `BudgetListRow.info`. If a later row ever needs an (i) plus an interactive trailing control (a switch), that needs a design change, not a workaround. |
| F4-4 | The (i) placed by measuring the label with a `TextPainter`; the 48 dp target is kept inside by a vertical inset, which is taken off the row padding | **Approved,** with **M1** (the measurement must use the same style as the `Text` it mirrors). The row height stays the same: the 72 dp minimum dominates at 1.0, and the inset shrinks at 2.0. Note: the placement assumes left-to-right text. That is fine for the English-only app; an RTL locale would need `last.left` mirrored. |
| F4-5 | `ScreenCopy` created in T-116 | **Approved.** |
| F4-6 | `BudgetButton.semanticsHint`; `NavTooltip` merges its hint into the control's node and excludes the `Tooltip`'s own semantics | **Approved.** The text is read once, as the control's hint. |
| F4-7 | Component-level tests on a host row until T-109 | **Approved** (D6 rule). The Settings-level steps of TC-004-02/-03/-05 are owed at T-109's Gate 3. |
| F4-8 | `InkResponse` instead of `IconButton` | **Approved.** `IconButton` would bring M3 state layers and its own sizing and semantics, which we would have to undo for an 18 dp icon in a 48 dp target with a 40 dp ripple. `InkResponse` + an explicit `Semantics` node is simpler, and TC-004-08's guard bans `IconButton(` in `features/` anyway. Keyboard focus visibility is a Nice to have (N4). |

**Plan F-003 §11**

| # | Item | Decision |
|---|---|---|
| F3-1 | No separate `ComingSoonTag`; N2 (measure the tag) deferred | **Approved.** TC-003-16 proves that every tag stays inside its row at 2.0 in all 5 theme cases. N2 stays open as a polish item (T-132). |
| F3-2 | One shell `AnimationController` + `FadeTransition` on the selected tab only | **Approved.** This is the right fix: an `AnimatedOpacity` under `TickerMode` off would not animate. It is fade-in, not a true cross-fade, which was already accepted at Gate 1 (plan §10 point 12; polish in Phase 6). With Remove animations it takes 0 ms. |
| F3-3 | One `BudgetNavTick` sliding with `AnimatedAlign` in a layer over the slots | **Approved.** This matches app-shell §3.4 "tick slides", and the space is reserved in every slot, so nothing jumps. The alignment maths (`-1 + 2i/3`, width ¼) is correct. Bar height is 64 dp at 1.0. |
| F3-4 | Test layout and helper | **Approved.** |
| F3-5 | TC-003-15 automated aid | **Approved** (D6 rule). |
| F3-6 | Route count in shell tests = root `Navigator.canPop()` | **Approved.** For the root navigator, "cannot pop" is exactly "nothing was pushed". The sheet tests use a real `NavigatorObserver`. |
| F3-7 | E6 renames | **Approved** (see above). |
| F3-8 | `TODO(T-109)` placeholder for the Theme row | **Approved.** It carries the task ID (STANDARDS §5), and §10 point 9 expects it. T-109's Gate 3 checks that the TODO is gone. |
| F3-9 | Material Icons outlined/filled instead of Material Symbols Rounded 300 | **Approved.** This already matches design system §6 (Gate 2 correction). app-shell.md §3 still names "Material Symbols Rounded, weight 300". That is a doc mismatch, so the Designer fixes it (T-133). |
| F3-10 | Extra TC-003-26 accessibility test | **Approved** (D6 rule). It is the interim proof for the retired TC-001-16. |

**T-114 retirement of TC-001-14/-15/-16/-43: correct.** The placeholder code and its test file are deleted. TC-003-15 checks that both folders are gone and that no `PlaceholderScreen` or Phase 0 text is left in `lib/` or `test/`. The Tester's retired rows (T-131) match `tests/F-003…` §2.2 exactly: 14 → TC-003-01/-05/-13; 15 → no successor; 16 → TC-002-03 (interim TC-003-26); 43 → TC-003-29 (all four tabs plus the end of Settings at 3.0× on 320×568) + TC-002-24. No ID is reused.

### Must fix

**M1 (T-117), the (i) is misplaced when the phone's Bold text setting is on.** `Text` makes its style bold when `MediaQuery.boldTextOf(context)` is true (Android 12+ "Bold text"). `LabelDescription._withInfo` measures with `DefaultTextStyle.of(context).style.merge(labelStyle)` and **does not** do this. The label style is 14/20 **w500**. With Bold text on, the real text is wider than the measurement, and it can wrap differently, so the (i) overlaps the last word or sits on the wrong line. F-002 §4 says the Bold text setting "must not break layout".
- *Fix:* resolve the measured style exactly as `Text` does:
  ```dart
  var style = DefaultTextStyle.of(context).style.merge(labelStyle);
  if (MediaQuery.boldTextOf(context)) {
    style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
  }
  ```
  Also pass `textWidthBasis` / `textHeightBehavior` from `DefaultTextStyle.of(context)` to the `TextPainter`, so the two layouts cannot drift apart.
- *Test:* in TC-004-05, add a `boldText: true` pass at 1.0 and 2.0 (`pumpBudgetWidget` already supports it). It asserts that the gap between the (i)'s ink and the end of the **real** label's last line (from the `RenderParagraph`'s boxes) is 4 ± 1.5 dp, on the same line. Use a label long enough to wrap at 2.0 (e.g. `How this app works` in a narrow host), because one short word hides the wrap case.

**M2 (T-117), double tap on (i) with Remove animations on: the sheet opens and closes at once.** With `AnimationStyle.noAnimation` the entrance animation completes in the push frame, so `barrierDismissible` is true at once. The second tap of a double tap (TC-004-17: within 100 ms) then lands on the scrim and closes the sheet it just opened. That leaves zero explanations instead of exactly one. Users who turn animations off are among those most likely to double-tap by accident.
- *Fix:* make the scrim dismissible only when the entrance animation **has completed** and **at least `kDoubleTapTimeout` (300 ms) has passed since the push**. For example, start a `Timer(kDoubleTapTimeout, …)` in `didPush` that sets `_minDelayPassed = true` and calls `changedInternalState()` if `isActive`; `barrierDismissible => _minDelayPassed && (animation?.isCompleted ?? false)`; cancel the timer in `dispose`. Back and Got it are not affected. Update the doc comment.
- *Test:* add a second test under **TC-004-17** (D6 rule), e.g. `TC-004-17 double tap with remove animations opens one explanation`. It pumps with Remove animations on, taps twice 50 ms apart, settles, and expects exactly one sheet and a route count of +1. Then it pumps 300 ms, taps the scrim and expects the sheet to close, so the guard never blocks the scrim for good. TC-004-03 must stay green; if needed, pump `kDoubleTapTimeout` there before the scrim tap.

**M3 (T-111), dead field `AppTab.title`.** Nothing in `lib/` or `test/` reads it. Each tab widget passes its own title (`ScreenCopy.appName`, `ScreenCopy.tabDashboard`, …) to `TabPage`, so the same copy has two sources of truth. STANDARDS §5: no dead code.
- *Fix (preferred):* make the field the only source: `HomeTab` → `TabPage(title: AppTab.home.title, …)` and the same for the other three tabs. Otherwise, delete the field and its doc line. The tests stay unchanged, because TC-003-01/-13 already assert the literal titles.

After M1–M3, the Developer runs `check.ps1`, records the result in the task notes and adds the items to plan §11. I re-review only those diffs.

### Nice to have (follow-up tasks)
- **N4 (Developer, T-132): visible keyboard focus on the (i) and on list rows.** Design §7.1 shows focus as a 2 dp `focus` ring, offset 2 dp. `InfoButton` shows only Flutter's default 12 % focus overlay. `BudgetListRow`'s `InkWell` maps every state except pressed to transparent, so a focused row shows nothing. Reuse `FocusRingPainter` (`budget_button.dart`) through a small shared focus-ring wrapper. TalkBack draws its own focus box, so this only affects keyboard and D-pad users, which is why it does not block.
- **N2 (still open, now in T-132):** measure the tag width instead of the 120 dp estimate.
- **N5 (Designer, T-133):** app-shell.md §3: change "Material Symbols Rounded, weight 300" to "Material Icons, outlined; filled when selected (design system §6)". §3.4: change "the body cross-fades" to "the new tab's body fades in (`motionBase`)", as accepted at Gate 1 point 12. Docs only.
- N1 and N3 from earlier reviews are still open; they go with T-118 as already noted.

### For the Tester
1. **Ready for test now:** T-116, T-112, T-113, T-114. T-111's cases can be run too, since M3 changes no behaviour, but T-111 only moves to Ready for test after the re-review. T-117's cases wait for M1/M2.
2. **Test-file updates after M1/M2:** TC-004-05 gains the Bold text step (M1). TC-004-17 gains the Remove-animations variant and its test name (M2). TC-004-04 (manual TalkBack) also checks that the drag handle is **not** a focus stop and that the scrim closes the open sheet (F4-2).
3. **Stale references in `tests/F-001-project-foundation.md`** (you are editing it now):
   - TC-001-39's command still names `app/test/features/placeholder/placeholder_screen_test.dart`. Point it at a file that exists, e.g. `app/test/features/shell/app_shell_test.dart`.
   - §0's "per plan: …placeholder_screen_test.dart" and the `TC-001-14 placeholder…` naming example need a "(Phase 0; retired in T-114)" note or a current example.
   - Past run rows stay as history.
4. The Settings-level steps of TC-004-02/-03/-05, the Theme-row parts of TC-003-06/-07, and TC-003-21 still wait for T-109 / T-118.

---

## Re-review T-117/T-111, T-109, T-118, T-127 tests, F-005 phase B1 (2026-11-10)

| Task | Verdict |
|---|---|
| T-117 (M1, M2 re-review) | **Approved → Ready for test** |
| T-111 (M3 re-review) | **Approved → Ready for test** |
| T-109 Theme row + picker | **Approved → Ready for test** |
| T-118 First-time hints | **Approved → Ready for test**, with risk **R1** for T-120 |
| T-127 extra tests (TC-002-46, -47, TC-003-31) | **Approved** (the task stays Done) |
| T-122 Welcome tour (B1) | **Approved → Ready for test** (interim scope, see B1-8) |
| T-123 Explainers + disclaimer (B1) | **Approved → Ready for test** (interim scope) |
| T-124 No-permission guard (B1) | **Approved → Ready for test** |

**No Must-fix items in this batch.** Conditions for T-121 are below (**C3–C6**). **T-121 can start now.**

**What I ran**
- `tool/check.ps1` (PowerShell, Flutter at `C:\src\flutter\bin`): **ALL CHECKS PASSED**, **163/163 tests**. That covers pub get, format, `flutter analyze`, `dart analyze --fatal-infos` and the test-name check. I did not repeat the debug build; the Developers report it OK.
- `git status` / `git diff d11fd32`: the only tracked app changes are still `app.dart`, `main.dart`, the manifest and `pubspec.*`. `pubspec.yaml` has **no new package** (same diff as at the last review), so the SHA-256 helper really avoids a dependency. Everything else is new files.

### Re-review
- **M1 resolved.** `_withInfo` now resolves the measured style the way `Text` does: `DefaultTextStyle` merged with the label style, plus `FontWeight.bold` under `MediaQuery.boldTextOf`. It also passes `textWidthBasis` and `textHeightBehavior` (falling back to `DefaultTextHeightBehavior`) to the `TextPainter`.
  - The new test uses a wrapping label in a 240 dp host, Bold text off and on × 1.0 and 2.0, and measures against the real `RenderParagraph`.
  - Loading the bundled fonts (`test/helpers/bundled_fonts.dart`) was the right call. With the square test font the check could never fail. It is proven to fail without the fix (gap 1.96 dp).
- **M2 resolved.** `barrierDismissible = _doubleTapWindowOver && animation.isCompleted`. The timer starts in `didPush`, rebuilds only while the route is active, and is cancelled in `dispose`.
  - The new TC-004-17 test is proven to fail without the time guard. It also shows that the scrim works again after 300 ms.
  - TC-004-03 is green unchanged, because the 320 ms entrance outlasts the 300 ms guard.
- **M3 resolved.** `AppTab.title` is now the only source of the four tab titles.

### T-109 Theme row and picker
| Check | Result |
|---|---|
| Correct | settings.md §2.2/§3/§4. The row description is the current choice, with a chevron and the hint `Opens theme options`. The (i) opens the explanation, never the picker. The picker applies and saves at once and stays open. **Done** is pinned (D-031 close button). The announcement `Theme changed to <name>` is sent only on a real change. The single-open guard works, and focus returns to the row. **`TODO(T-109)` is gone.** |
| C1 on the picker | **Met.** The picker opens through `showBudgetSheet`. The exact Light shadow, and none in Dark/Dim, is asserted in TC-002-37 (live Light → Dark) and in the T5 sweep. |
| C2 on the real row | **Met.** `theme_setting_row_test.dart` TC-004-05: `More about Theme` is its own button node, the row reads `Theme. <choice>` without "More about", across T5 × 1.0/2.0. TC-004-02/-03 run on the real row: the (i) does not open the picker; four close ways at 2.0 on Small with the list scrolled; focus back on the (i). |
| E6 picker titles | **Met.** I compared them one by one with `tests/F-002…`: TC-002-01, -07, -08, -09, -33, -34, -35, -37 match exactly, and -36 is in `theme_choice_test.dart`. |
| Modern | `RadioGroup` (the current radio API; no deprecated `groupValue` on `Radio`), `SemanticsService.sendAnnouncement(View.of(context), …)` (the non-deprecated form), `WidgetStateProperty.fromMap`, `Color.withValues`. |
| UX | Selection shows three non-colour cues (dot, check, w600). The check slot keeps its width, so the text never jumps. The radio is the only keyboard stop per option (`canRequestFocus: false` on the `InkWell`). |

New TC-003-21 (Back closes the picker or the explanation first, then goes Home): good. Parts (a)–(c) are all automated now.

### T-118 First-time hints
| Check | Result |
|---|---|
| Correct | `HintId` with `.v1` suffixes; keys are in the allow list. The repository treats unreadable or wrong-type values as not seen and never throws. `dismiss()` hides the hint first, then saves; a second call writes nothing; a failed save keeps the hint hidden for the session and shows it again next launch (AC-12). Viewing a tab writes nothing (AC-9). Back with a hint visible changes nothing (TC-003-21 c). |
| Card | help-pattern §4.1: `accentSoft`, lightbulb + `Tip`, × in a 48 dp target with `Dismiss tip`, Got it with its hint. The tip reads as one item `Tip. <text>`, then the two buttons. The `Tooltip` on × lives in `core/`, so the T-119 guard on `features/` holds. |
| Collapse (§11 item 10) | **Approved.** The `AnimatedSwitcher` with size + fade from the top is simpler than `AnimatedSize` plus keeping the old card by hand. It is instant with Remove animations (TC-002-45). |
| Focus after dismissal (§11 item 11) | **Approved, with risk R1.** Keyboard focus and the Settings case are correct and tested; a finger tap moves nothing. |
| N1 (§11 item 12) | **Done well.** The named constructor `InMemoryPreferencesStore.allowing(…)` leaves the unrestricted fake untouched for store-level tests. The app harness and the **runtime fallback** in `openPreferencesStore()` both use `PreferenceKeys.allowList`, so the fallback can no longer store keys the device store would refuse. |
| N3 | **Done.** `ProviderContainer.test()`, and the workaround comment is gone. |

**R1 (condition for T-120's manual TalkBack walk; not blocking).** The focus move steps through *keyboard* traversal. On Settings the next stop is the Theme row, which is correct. On **Home, Dashboard and Transactions** the next keyboard stop after the card is the **bottom bar** (`Home, tab 1 of 4`), because the empty state is text, not a focus stop. So with TalkBack on, a dismissal there probably moves TalkBack focus to the tab bar and skips the empty state. help-pattern §4.3 asks for "the first item after where the card was", which is the empty state. Home is the very first screen after onboarding, so this matters.
- In **T-120**, check this on the emulator on Home.
- If TalkBack lands on the tab bar, file a bug (Medium). The likely fix: on the screen-reader path, when the next keyboard stop is outside the tab page, send the `FocusSemanticEvent` from the render object of the body's first semantics node instead. For example, `TabPage` keys its body, and `EmptyState` (later, each body's first item) owns that node.
- Widget tests cannot see TalkBack focus, which is why this is a device check and not a Must-fix now.

### T-127 extra tests
- **TC-002-46:** the exact title. It checks `onError` against the hex literals, `ColorScheme.error = overspent` and the contrast ratios. Good.
- **TC-002-47:** the exact title. It checks every bundled file has exactly one `SOURCES.md` row whose SHA-256 equals the file's bytes, with 7 files and 7 rows.
  - **SHA-256 helper instead of `package:crypto`: accepted.** It is test-only, short, and checked against the FIPS 180-2 vectors in the same test: the empty string, `abc`, and the 56-byte two-block message, which covers the padding edge. It adds nothing to the app.
  - However, `crypto` is **already in `pubspec.lock` as a transitive package** (Dart-team maintained). A `dev_dependencies: crypto` entry would cost no new download and would remove 86 lines of hash code we have to trust. This is Nice to have **N7**, not a block.
- **TC-003-31 (optional):** measures where the glyphs really start (`getBoxesForSelection`), not the paragraph box. That is the correct way to prove left alignment.

### F-005 phase B1 (Developer B): T-122, T-123, T-124
Overall it is clean and well guarded. Reading order uses `OrdinalSortKey`, button descriptions are read once as hints, and no permission API, package, channel or manifest entry was added.

**Deviations (plan F-005 §11)**

| # | Decision |
|---|---|
| B1-1 `OnboardingActions` interface, built before T-121 | **Approved.** It is a good seam: the screens report intent, and the gate owns navigation. The provider throws until it is overridden, so a forgotten wiring fails loudly. T-121's notifier implements it (C5). |
| B1-2 Copy in a new `core/copy/onboarding_copy.dart` | **Approved as interim only.** F-004 AC-6 says *all help strings come from the single help-copy location*. **C3 (T-121):** move the F-005 help strings (button hints, descriptions, tooltips) into `HelpCopy` and the screen strings (titles, labels, slide texts, card texts) into `ScreenCopy`, then delete `onboarding_copy.dart`. Developer A's files are free once this review is done. T-119's copy-table test then covers F-005 from those two files. |
| B1-3 Explainers ignore taps for `kDoubleTapTimeout` after they appear, plus `isCurrent` | **Approved.** This is the same reasoning as M2, and TC-005-18 caught the real bug. |
| B1-4 300 ms cooldown on Next; Get started ignored while Next is in progress | **Approved.** It is needed with Remove animations, and TC-005-18 runs with animations both on and off. |
| B1-5 No overscroll indicator on the tour | **Approved** (welcome-tour §2.4). Removing the stretch from the slides' own vertical scroll is acceptable. |
| B1-6 Explainer descriptions as the button's hint, caption excluded | **Approved.** It is read once, with the control (F-004 §2.3). |
| B1-7 No U+2060 in slide 2 | **Approved.** TC-005-26 proves `₹24,900` never splits at 2.0 on 360/320 dp, so the copy stays identical to F-005 §5. |
| B1-8 Interim tests under the same IDs with a fake gate | **Approved** (D6 rule). **C6 (T-121):** the Tester's exact-title tests for TC-005-01, -04, -05, -06, -13, -14, -15, -22, -27 and TC-005-18's "I understand → Home → back" are due at T-121's Gate 3. |
| B1-9 Test file names follow the Tester's proposals | **Approved.** The Tester updates the case rows (T-134). |
| B1-10 Broader guard (more banned names, all `src/*/AndroidManifest.xml`) | **Approved.** Both probes failed as they should. Note: bare-substring checks (`telephony`, `Permission.`) can also hit a comment one day. That is a safe failure; reword the comment rather than weaken the guard. |

**Decision: double tap on "I understand" passing through to Home.** I accept Developer B's suggestion, in this form (**C4, T-121**; recorded as **D-044**):
- **`AppGate` owns the guard, not `AppShell`/Home.** When the stage changes to `finished` *during the session* (not on a cold start that is already finished), the gate wraps the new Home in `AbsorbPointer` for `kDoubleTapTimeout` (300 ms), then removes it. The shell stays unaware of onboarding, and nothing changes for a normal app start.
- `AbsorbPointer` blocks only pointer hit-testing. TalkBack's double-tap uses semantics actions, and TalkBack users are not the ones racing here, so accessibility is unaffected.
- Prefer this over keeping the disclaimer absorbing: `popUntil` drives the exit transition, and a popping `ModalRoute` ignores pointers by design.
- **Test:** under TC-005-18 with the real Home. Double tap on I understand, with animations on and off: Home is shown, **Home tab still selected**, no route pushed, and `finish()` reported once (persisted once). Then, after 300 ms, a tap on a tab works.
- Also do the open Nice to have §10 point 6 here (I understand → Home reads as a fade). The gate's `AnimatedSwitcher` (fade + 16 dp rise, `motionBase`, instant with Remove animations) is the place for it.

### Can T-121 start? **Yes, now.**
Its dependencies T-102, T-108 and T-114 are approved. T-109 and T-118 are approved in this review, so `preference_keys.dart`, `preferences_providers.dart`, `app.dart`, `main.dart` and the test harness (`pump_app.dart`, `shell.dart`) are no longer in flight. T-121 builds on the current tree. One Developer owns those shared files for the duration of T-121; no parallel edits to them (D-033). Conditions to check at its Gate 3:
- **C3:** copy merge (above).
- **C4:** the post-onboarding tap guard in `AppGate` + test (above).
- **C5:** the onboarding notifier implements `OnboardingActions`, and `onboardingActionsProvider` returns it. The onboarding keys go into `PreferenceKeys` + `allowList` (the `allowing` harness will catch a miss). The F-003/F-004 harness seeds "onboarding finished" by default (plan F-005 §8). `completeTour()`/`finish()` are idempotent and set state before saving, like `HintSeenNotifier.dismiss()`.
- **C6:** the B1-8 exact-title tests.

### Nice to have
- **N7 (Developer, any time):** replace `test/helpers/sha256.dart` with `package:crypto` as a dev dependency (already resolved transitively). Record it in DECISIONS (one line).
- **N8 (Developer, with T-121):** there are now four hand-made "double-tap window" guards: the sheet route, the tour Next, the explainers, and the gate (C4). The tour and explainers use an empty `Timer(kDoubleTapTimeout, () {})` as a flag. Extract one small `core/` helper (e.g. `TapCooldown` with `start()` / `isActive` / `dispose()`) and use it in all four. That gives one place to tune and test it.
- **R1:** see T-118 (a T-120 device check).
- N4 / N2 (T-132) and N5 (T-133) are still open.

### For the Tester
1. **Ready for test now:** T-117, T-111, T-109, T-118, T-122, T-123, T-124 (B1 interim scope; the B1-8 parts wait for T-121).
2. **The test-file records are already done** in T-134 and T-135, which name the new test files and mark the F-005 interim cases. Nothing to repeat. Only one check: the TC-004-05 and TC-004-17 rows must name the two new M1/M2 tests by their exact titles: `TC-004-05 info button follows the last word with bold text on` and `TC-004-17 double tap with remove animations opens one explanation`.
3. **New, T-136:**
   - TC-004-04 / T-120 manual: add the **R1** check. On Home, Dashboard and Transactions, after dismissing the hint with TalkBack, focus lands on the empty state, not on the tab bar.
   - TC-005-18: add the **C4** step (double tap on I understand → Home tab still selected, no route pushed, `finish()` once; a tab tap works after 300 ms), for T-121.

---

## T-121 Onboarding state, gate and wiring (2026-11-10)

**Verdict: approved → Ready for test.** No Must-fix items.

**What I ran:**
- `tool/check.ps1`: **ALL CHECKS PASSED, 182/182 tests**.
- `pubspec.yaml`: no new package.
- I did not repeat the debug build; Developer B reports it OK.

### Conditions
| # | Result |
|---|---|
| **C3** copy merge | **Met.** `lib/core/copy/` holds only `help_copy.dart` and `screen_copy.dart`. Nothing in `lib/` or `test/` refers to `OnboardingCopy` any more, so F-004 AC-6 (one home for help strings) holds again. |
| **C4** Home tap guard | **Met** (D-044). `ref.listen` starts the cooldown only on a change *into* `finished`, so a cold start is never delayed. `AbsorbPointer` wraps a `const AppShell`, so turning it off does not rebuild the shell. The gate's fade + 16 dp rise (instant with Remove animations) also closes plan §10 point 6. The probe shows TC-005-18 fails without the guard: the second tap selected Settings. |
| **C5** notifier and keys | **Met.** `OnboardingNotifier implements OnboardingActions`, and `onboardingActionsProvider` returns it. `completeTour()` acts only from `tour` and `finish()` only from `explainers`; each sets the state first and then saves. So both are idempotent, and a failed save still moves on for the session (AC-15). `onboarding.tour_seen` / `onboarding.finished` are in `PreferenceKeys` and `allowList`. The repository never throws, and "finished" wins in `fromFlags`. |
| **C6** exact-title tests | **Met.** I compared all ten titles in `onboarding_routing_test.dart` with `tests/F-005…`: TC-005-01, -04, -05, -06, -13, -14, -15, -18, -22, -27 match exactly. TC-005-18 runs with the real Home, with animations on and off. |
| **N8** shared guard | **Done.** `core/widgets/tap_cooldown.dart` is used by all four guards, and each owner disposes it. |

### Deviations (plan F-005 §11 "T-121")
| # | Decision |
|---|---|
| T121-1 `OnboardedStore` answers the two flags as `true` in the harness | **Approved.** It is the right choice: writing real flags would have broken the tests that use `FailingPreferencesStore` or compare exact store contents. Production code is untouched: the wrapper lives in `test/helpers/` only. The routing tests opt out with `onboarded: false`. |
| T121-2 Interim B1 tests renamed "(screen level)" | **Approved** (D6 rule). Each Tester title now exists exactly once. |
| T121-3 `OnboardingActions` stay `void`, saves `unawaited` | **Approved.** The screens never wait for a save (AC-15). |
| T121-4 `TapCooldown` in `core/widgets/`, replacing the sheet route's timer | **Approved.** Behaviour is the same, and both TC-004-17 tests are green. One small leftover: the sheet route keeps a `_doubleTapWindowOver` flag next to the cooldown. That is correct, because "the window is over" is not the same as "not active" before `didPush`, so leave it. |
| T121-5 TC-005-16 (real-plugin integration test) not written | **Approved.** It needs the emulator, so it **moves to T-125** (noted in that row). |
| T121-6 The outgoing page stays in the tree for the 200 ms swap | **Accepted, with Nice to have N9.** Taps reach the incoming page, and the explainers' own cooldown covers a double tap. However, during the swap the outgoing screen is still in the semantics tree, and its `PopScope` still counts for Back. **N9 (added to T-132):** a `layoutBuilder` that wraps previous children in `IgnorePointer` + `ExcludeSemantics`. |

### For the Tester
- **Ready for test now:** T-121 and every B1-8 case that was waiting for it (TC-005-01, -04, -05, -06, -13, -14, -15, -18, -22, -27).
- **TC-005-16** runs in T-125.
- **TC-004-14** (no hints during onboarding) comes with T-119. The hints live only inside `AppShell`, so the test should pass at once.

---

## T-132 shell batch, T-137 crypto, T-119 rule checks (2026-11-11)

**Verdict: Approved. No Must fix.** T-132, T-137 and T-119 all go to Ready for test.

| Task | Verdict | Status |
|---|---|---|
| T-132 `FocusRing`, `BudgetTag.widthOf`, `AppGate` `layoutBuilder` (N4, N2, N9) | Approved | Ready for test |
| T-137 `package:crypto` dev dependency (N7, D-061) | Approved | Ready for test |
| T-119 rule, copy and shared-component checks (TC-004-06, -08, -14) | Approved | Ready for test |

**What I ran (2026-11-11, Flutter 3.47.9):** `tool/check.ps1` ALL CHECKS PASSED, exit 0 (format, `flutter analyze`, `dart analyze --fatal-infos`, test-name check on 62 files, 328 tests).

### T-132
| Check | Result |
|---|---|
| **N4 focus ring** | `core/widgets/focus_ring.dart`: `FocusRing` listens to the node and to Flutter's highlight mode, and paints `FocusRingPainter` (2 dp stroke, 2 dp gap, `focus` token) only for primary focus in keyboard (traditional) mode. Touch users never see it. It sits in a `Stack` over the child with `IgnorePointer`, so it changes neither size nor hit area. `InfoButton` uses it outside (radius 24 around the 48 dp target); `BudgetListRow` uses it `inside` so the card does not clip it, and the row does not light up while its (i) holds the focus. Listeners are added and removed correctly (`didUpdateWidget`, `dispose`). `BudgetListRow` creates its own `FocusNode` only when none is passed, and disposes only that one. Matches design §7.1 |
| **N2 tag width** | `BudgetTag.widthOf` measures the tag with the same style, text scaler, bold-text setting, locale and padding as `build`, so it follows the M1 lesson from T-117. `BudgetListRow` now decides "tag below" from the measured width. TC-003-16 checks the reflow |
| **N9 AppGate** | `layoutBuilder` wraps each page in `_GatePage`: the outgoing page gets `IgnorePointer`, `ExcludeFocus` and `ExcludeSemantics`, and `RootPageScope(current: false)` so its `PopScope` lets Back through. Each wrapper keeps the page's key, so the page keeps its state while it fades out. The test checks TalkBack's tree, pointers, focus and Back in the middle of the 200 ms swap |
| **Tests** | `TC-004-05` and `TC-002-19` in `focus_ring_test.dart` (all 5 theme cases, touch vs keyboard, ring colour, offset, size, row to row), `TC-003-16` in `budget_list_row_test.dart`, N9 in `app_gate_test.dart`. All green |
| **No deviations.** Plan F-003 §11 item 13 and F-005 §11 are accurate | Confirmed |

### T-137
`crypto: ^3.0.8` is under `dev_dependencies` and the lock shows `direct dev`, so nothing ships in the app. `test/helpers/sha256.dart` is gone, nothing else imported it, and `fonts_test.dart` (TC-002-47) uses `sha256.convert` with the same FIPS 180-2 vectors and the same per-file check against `SOURCES.md`. D-061 is recorded. A maintained package is better than our own hash code. No cost, no data leaves the device, so no Owner decision is needed.

### T-119
| Check | Result |
|---|---|
| **State** | It was in Code review and never reviewed. It is tests only: no app code or copy changed. I reviewed it now |
| **TC-004-06** `help_rule_test.dart` | Walks all 18 Phase 1 states through the real app and `AppGate`. Every semantics node with a tap action must match test cases F-004 §1.2 one to one, by exact label and hint, written as literals (not read from the app's copy). An extra or missing control fails. A control without a hint must carry its description in its label, be `More about …` or be the hint card's ×. Also checks the visible descriptions, the long-press tooltips on the four tabs and the ×, and the seven Coming soon rows (disabled, exact string). A strong test |
| **TC-004-08** `shared_components_test.dart` | Guard list agrees with the Gate 1 Must fix (`Tooltip(`, `showModalBottomSheet(`, `showBottomSheet(`, `showDialog(`, `ListTile(`, `IconButton(`; `Icons.info` is not banned); word boundary so `NavTooltip(` passes. The second test parses every `HelpCopy` constant (floor of 30, so a broken parse cannot pass) and the template parts, and requires each to appear in exactly one `lib/` file. The Developer proved both fail on a probe file |
| **TC-004-14** in `hints_test.dart` | No hint card and none of the four hint texts on slides 1 to 4, both explainers and the disclaimer; Home then shows its hint; no hint flag saved |
| **Copy test** | Complete for F-002 to F-005 (every `static` string in both copy files needs a literal in the test) |
| **Plan F-004 §11 items 14 to 18** | **Approved.** 14: one driver `P1Screen` (18 states) and a 400 × 1400 view for TC-004-06, because the traversal leaves out off-screen items of a scrolling page. 15: the sheet scrim is an allowed extra node, exactly once on the two sheets. 16: word boundary. 17: copy home checked from the file. 18: TC-004-14 lives in `hints_test.dart` |
| **TC-002-03/-22/-23/-24 sweeps** | **Not part of T-119 and no task owned them.** New task **T-138** (Developer) below |

### New and follow-up tasks
- **T-138 (Developer): Phase 1 screen sweeps** for TC-002-03, -22, -23 and -24 (and the same driver for TC-002-38, -39, -40, which plan F-002 §11 T-106 item 2 also says "come with the screens"; the Tester confirms which of those are already covered elsewhere). It loops `P1Screen.values` from `test/support/p1_screens.dart` over the 5 theme cases, with the existing `expectAccessible` / overflow helpers. It starts after T-132 (done now), because T-132 changed list-row and (i) visuals.
- **Nice to have N1 (Designer decision, no task yet):** TalkBack reads the sheet scrim as "Scrim", the stock Material label (set in `core/widgets/budget_sheet.dart`). Plain language such as "Close" would fit the rule that every control says what it does. Put it in the Phase 1 Owner walk-through list; the Designer decides the word.
- **Nice to have N2 (Developer, any later UI task):** `BudgetListRow._trailingAllowance` still estimates a trailing widget next to a tag as 48 dp (a chevron is 20 dp and a switch is wider). Only a tag plus a trailing widget is affected, and no screen has that today. Measure it when one does.
- **Nice to have N3 (Tester):** the N9 test is titled `TC-005-18 …` (the Home tap-guard case). That is allowed by D6, but the case is about a different thing. Give it its own case ID in `tests/F-005-…` (for example TC-005-28) and rename the test, so a failure points to the right case. The Tester adds it in the next test-record pass.

### For the Tester
1. **Ready for test now:** T-132, T-137 and T-119.
2. T-119: TC-004-06 names `test/architecture/help_rule_test.dart`; TC-004-08 names `test/architecture/shared_components_test.dart` (two tests; the row's title is the second) and its §1.1 command needs a word boundary before `Tooltip(` and the five others (as written it matches the three `NavTooltip(` calls); TC-004-14 names `test/core/help/hints_test.dart`; §1.2 could list the sheet scrim (`Scrim`, tap hint `Close Bottom Sheet`).
3. T-132: TC-004-05 and TC-002-19 name `test/core/widgets/focus_ring_test.dart`; TC-003-16 names `test/core/widgets/budget_list_row_test.dart`; add the manual keyboard step to TC-004-04 if a keyboard is available on the emulator (N4); add the N9 case (N3 above).
4. T-137: TC-002-47 unchanged; its row can say "uses `package:crypto`".

---

## T-138 screen sweeps (2026-11-11)

**Verdict: Changes requested. 1 Must fix.** T-138 goes back to In progress (rejection 1 of 3).

**What I ran:** `flutter test test/features/screens/p1_screen_sweeps_test.dart`: all 7 tests pass. The Developer's `tool/check.ps1` result (335 tests) was not re-run in full; this review is on the new file only.

### Deviations
| Deviation (plan F-002 §11 T-138) | Verdict |
|---|---|
| 1. Last element reached by scroll plus a tap-lands-on-it hit test at the visible centre, not `hitTestable()` | **Approved.** `hitTestable` fails for an element taller than the viewport (landscape at X2). The helper still proves the end of the element is on screen and a tap lands on it. It is stricter than "scrolled into view". |
| 2. Last element is a literal per screen (empty-state copy via `ScreenCopy`, `Disclaimer`, main button) | **Approved.** The table is explicit and a renamed or removed element fails the test, which is what we want. Nice to have only: none. |
| 3. One `testWidgets` per TC that loops all states and themes, 10 min timeout | **Approved.** Titles match the Tester's exactly, failure reasons name state and theme. Cost: first failure hides the rest (noted by the Developer). Runs in under 50 s total. |
| 4. TC-002-40 sets bold and high contrast with `setUpScreen` before `P1Screen.open` | **Approved in principle, see Must fix 1.** It works only because `pumpBudgetApp` skips `setUpScreen` flags when all are false; the app reads bold text only, so no extra test value is needed. |

### Must fix
**M1. State leaks between loop iterations, so the "X1" cases are not X1.** `setUpScreen` only *sets* `textScaleFactorTestValue` and the view size when they differ from default, and never resets them inside a test. Each sweep is one `testWidgets`, so after the first X2 / small-phone iteration every later "X1" or "default view" iteration still runs at scale 2 on the small view. I proved it with a temporary probe test (deleted): open Home at 320 x 568 scale 2, then open Home at 320 x 640 with no scale; the app reports text scale 2.0 (`scale(10) == 20`) at 320 x 640.
Affected: TC-002-23 (X1 default view runs as X2 360 x 640 after the first theme), TC-002-38 X1 (runs at scale 2 except the first), TC-002-39 X1 (same), TC-002-40 scale 1.0 (same). So X1 at 320 dp, X1 landscape and X1 bold are effectively untested, and TC-002-24's X1 coverage in -23 is lost. Everything still passes only because X2 is the harsher case; the gap is real for anything that behaves differently at X1 (e.g. an overflow that only appears with a wider text box).
**Fix (tests only):** make the helper deterministic per iteration. Smallest change: in `P1Screen.open` (or a small wrapper in the sweep file) reset before pumping: `tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); tester.platformDispatcher.clearTextScaleFactorTestValue(); tester.platformDispatcher.clearAccessibilityFeaturesTestValue();` and have the sweeps call `setUpScreen` for bold after that reset. Alternative: give `setUpScreen` an unconditional assignment of text scale (including 1) and a size reset when `size == null`. Check no other caller of `setUpScreen` relies on the leak. Then re-run all 7 sweeps and `tool/check.ps1`.

**Can-it-fail probe: this is a Must fix as part of M1 (item 2 below).** Earlier tests in this project were proven by a probe, the sweeps are the only automated proof of AC-2/-12/-13/-14, and M1 shows a sweep can pass while testing less than it claims. After fixing M1, run these temporary probes (app code reverted after each; record the result in plan F-002 §11 T-138 as the earlier tasks did):
1. **Overflow (TC-002-24, -38, -39):** make one Settings row or the Home empty-state description non-wrapping and too wide (for example wrap its `Text` in `SizedBox(width: 1000)` or a `Row` without `Expanded`). Expect TC-002-24 and TC-002-38 to fail naming that screen/theme, and TC-002-38 at X1 specifically (this proves the M1 fix, since before the fix X1 ran at X2).
2. **Tap target (TC-002-23):** shrink one control below 48 dp (for example the Theme row or the `I understand` button to height 40, or an `InfoButton` target to 32). Expect TC-002-23 to fail on that state.
3. **Contrast (TC-002-22):** temporarily set one text colour on one screen to a low-contrast value (e.g. `textSecondary` equal to `bg` on Home). Expect TC-002-22 to fail. If it does not, record that the guideline cannot see it (the Tester's note says it can skip text it cannot measure, and TC-002-21 is the main proof).
4. **Background (TC-002-03):** change one theme's `bg` token or the Scaffold colour on one screen; expect failure.
5. **Last element (TC-002-24/-38/-39):** wrap the Settings list in a fixed-height `SizedBox` or remove the `Disclaimer` row from reach; expect the last-element check to fail.
6. **Bold (TC-002-40):** make a widget break only when `MediaQuery.boldTextOf` is true (or just check by a temporary `expect(MediaQuery.boldTextOf(context), isTrue)` inside the sweep) to prove bold is really on.
Revert every probe and confirm the 7 sweeps pass again.

### Other checks
| Check | Result |
|---|---|
| Titles match `tests/F-002-design-system-themes.md` exactly | Yes, all 7 |
| No app code changed; analyzer and format | Reported clean by the Developer (not re-run by me) |
| `TC-002-23` source table says 85 combinations; the test also runs X2 | Fine, stricter than the case |
| Duplicated `Offset.zero & ...` viewport logic in `_expectLastElementReachable` | Acceptable |

### Nice to have
- **N1 (Tester):** add the file name and the probe note to the rows of TC-002-03/-22/-23/-24/-38/-39/-40 once M1 is done.
- **N2 (Developer, later):** if one sweep failing hiding the others becomes painful, move to one `testWidgets` per theme (5 per TC). Not now.

### For the Owner
Nothing to decide. This is a test-quality fix; no app change is expected unless a probe or the corrected X1 runs reveal a real layout problem (then it becomes a bug and I will tell you).

### T-138 re-review (2026-11-11, rejection 1 resolved)

**Verdict: Approved. T-138 is Ready for test.** Review by reading files only (no flutter run; another agent was using the build). Developer's `tool/check.ps1` result (336 tests, all pass) taken as reported, to be re-run by the Tester.

| Item | Result |
|---|---|
| M1 leak | Fixed in `P1Screen.open` (`test/support/p1_screens.dart`): resets size, pixel ratio, text scale and accessibility flags before every open; new `boldText`/`highContrast` parameters used by TC-002-40. A reset-proof temporary test is recorded. |
| Deviation: `setUpScreen` unchanged | **Approved.** `hints_test.dart` TC-004-22 relies on its set-and-keep behaviour; fixing the leak in the sweep driver is smaller and safer. |
| Probes 1-6 | All six done, each with state/theme-naming failure evidence and a byte-identical revert: overflow (TC-002-24 and -38 at X1), tap target (48 to 30 dp), contrast (1.00 vs 4.5), background (red Scaffold), last element (Settings clipped), bold (`boldTextOf` true in all 72 runs). |
| Recorded limit, TC-002-03 | **Accepted.** The expected `bg` is read from the same token, so a token value edit is not caught by the sweep; `theme_tokens_test.dart` covers token values. |
| TC-002-29 added | **Accepted.** `TC-002-29 every screen uses the bundled font families` (18 states x 5 themes, every `RenderParagraph` family, icon glyphs skipped) with a `Courier` probe that failed and was reverted. Limit (resolved family, not glyph source) is covered by `fonts_test.dart`. |

No Must fix. Nice to have: Tester to add the file name to the TC-002-29 row (and the earlier N1 rows).

## T-233 sheet scrim label and T-232 Step 9 (2026-11-11)

**Verdict: both approved.** Review by reading the changed files and re-running `tool/check.ps1` (see the Gate 5 section of `plans/phase-1-overview.md` for the result).

### T-233 (`app/lib/core/widgets/budget_sheet.dart`, `app/test/architecture/help_rule_test.dart`)
| Check | Result |
|---|---|
| Correct | `showBudgetSheet` sets `barrierLabel: 'Close'`; the tap hint stays the stock `Close Bottom Sheet`. Matches design system §7.8 and `design-phase-1-evidence.md` N1. |
| Tested | `_scrimLabel = 'Close'` in `help_rule_test.dart`; TC-004-06 matches the scrim node by that label (exactly once on the picker and the explanation, never elsewhere), so any other label fails it. No other test, copy table or doc still says "Scrim" as the screen-reader label (F-004 tests §1.2, plan F-004 §11 item 19 and `PHASE-1-SUMMARY.md` updated). |
| Clean | One literal, one comment; no new code path. No deprecated API. |
| Safe | No data, permission or visual change. |
- **Nice to have (not blocking):** the literal `'Close'` lives in the widget while the rest of the copy is in `ScreenCopy`/`HelpCopy`. Moving it to a constant in `screen_copy.dart` would let the copy-table test cover it. Do it with the next change in `budget_sheet.dart` (Phase 3). The label is also the exact word on the real Close buttons, so a future screen with a button labelled `Close` inside a sheet would be miscounted by TC-004-06's scrim counter; keep that in mind when adding sheets.

### T-232 (section 7 of F-002 to F-005 and the INDEX)
- Section 7 in all four docs is complete (what was built, main files, data stored, decisions, deviations, how tested, depends on, known limitations) and agrees with plan section 11, the test counts (47, 31, 25, 32) and `tests/PHASE-1-SUMMARY.md`. The four TalkBack cases are named as Blocked-needs-human (D-066); Designer N2 to N5 are named and map to T-234 to T-237.
- **INDEX F-002 to F-005 = Done: agreed.** WORKFLOW step 9 says the Developer completes section 7 and sets Done after a Gate 4 pass. Gate 4 was passed for all four (F-002 Pass, F-005 Pass, F-003 and F-004 Pass with accepted open items, in the PM verdicts in their test files). D-066 explicitly says the Blocked TalkBack cases do not block Gate 4 or Gate 5, and the open items are recorded in the feature docs and will be in the phase report. Nothing needs changing.
