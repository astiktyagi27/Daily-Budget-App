# Bug List

Owned by the Tester. Statuses: `Open → Fixed – awaiting review → Re-testing → Closed` (or `Reopened`).
Severity: **Critical** (wrong money, data loss, crash) · **High** (feature broken) · **Medium** (wrong in some cases) · **Low** (cosmetic).

## Summary
| ID | Title | Task | Severity | Status |
|---|---|---|---|---|
| B-001 | Predictive back on Settings shows only the back chip, no Home preview | T-111/T-115 | Low | **Closed 2026-11-11** (option b, D-065; no code change) |
| B-002 | Dashboard first open with 500 spends is over 500 ms on the emulator | T-384 | Medium | **Closed by ruling D-100** (2026-11-23, Project Manager B: AC-17 is measured in profile, 83 and 89 ms; Tester records the closure, T-391) |
| B-003 | Device flow: after editing a refund to ₹300 the Today line never shows `spent ₹120 · ₹710 left today` | T-442 / T-443 | Medium | **Closed 2026-11-24** (Tester 1: money_back_flow 3 of 3 green, `s9-money_back_flow-1..3.log`) |
| B-004 | Calendar grid with 500 spends is 495-548 ms in profile mode (limit 500 ms) | T-325 / T-326 | Medium | **Closed 2026-11-24** (profile, T-491: worst of 5 grid 333 ms, limit 500 unchanged; `s9-profile-calendar_500.log`) |
| B-005 | `month_setup_flow_test.dart` waits for the Home text T-305 removed | T-305 | Medium | **Closed 2026-11-24** (month_setup_flow 5 of 6 clean runs green after one first-run flake, see note) |
| B-006 | Home text breaks badly at text 2.0 on a 360 dp phone | T-302 / T-305 | Low | **Closed 2026-11-24** (device check at 2.0x on 360 dp and at default size, `s9-b006-*.png`) |

## Details
<!-- Use this format:
### B-001: <short title>
Task: T-xxx · Severity: … · Status: Open
Steps to reproduce: 1… 2… 3…
Expected: …
Actual: …
Evidence: …
Cause & fix (Developer): …
Regression test: <test name>
-->

### B-001: Predictive back on a tab other than Home shows no Home preview
Task: T-115 (T-111 shell) · Feature: F-003 · Severity: Low · Status: Closed (2026-11-11, option b, D-065)
Steps to reproduce: 1. Android 17 emulator (API 37), gesture navigation, debug build. 2. Open Settings. 3. Start a back swipe from the screen edge and hold it. 4. Compare with a held back swipe on Home.
Expected: `docs/features/F-003-app-shell-navigation.md` edge case: "the back preview animation must show the correct destination (Home, or leaving the app). It must never show a blank screen." TC-003-22: on Settings the preview shows Home.
Actual: On Home the window shrinks over the launcher (correct). On Settings only the round back chip appears at the left edge; the Settings page does not shrink and Home is not previewed. It is never blank or black, and the back action itself works (goes Home). The tab Back is handled inside the app, so Android has no previous destination to preview.
Evidence: `docs/reviews/emulator-phase-1/tc-003-22-predictive-back-settings-mid-gesture.png` (Settings, back chip only) and `tc-003-22-predictive-back-home-mid-gesture.png` (Home, correct); Developer note in `docs/TASKS.md` T-115. `docs/design/screens/app-shell.md` does not describe a preview, so the Designer has not specified one.
Decision needed (PM + Designer): (a) fix it so Android 14+ can animate the Home preview for tab Back; or (b) relax the F-003 sentence (never blank; preview only when leaving the app) and reword TC-003-22. Closing rule: (a) retest on the emulator, full regression; (b) feature doc and TC-003-22 updated, then Tester closes.
PM decision (Gate 4, 2026-11-11): option (b), D-065. No code change. Closing rule: feature doc sentence reworded (T-229), TC-003-22/-32 already reworded by the PM, Tester closes (T-230).
Cause & fix (Developer): none needed; the in-app tab Back (`PopScope`) is handled by the app, so Android has no destination to animate.
Closed (Tester, T-230, 2026-11-11): the PM chose option (b) (D-065). F-003 section 4 now reads "The back preview must never be a blank screen. Leaving the app from Home shows the system preview of the app shrinking over the launcher. On Dashboard, Transactions or Settings the system's back chip alone is acceptable; releasing goes to Home." (T-229); TC-003-22 and TC-003-32 carry the same wording. Re-run against the reworded text: Home shows the app shrinking over the launcher, Settings shows only the back chip and is never blank, release goes Home (R2 screenshots, opened by the Tester, plus TC-003-10/-11/-20 for the Back result). Full regression run 2026-11-11 (R3): `tool/check.ps1` ALL CHECKS PASSED (336 tests), integration tests 2 of 2, `tests/REGRESSION.md` run R3. No open bugs remain.
Regression test: TC-003-32 in `tests/F-003-app-shell-navigation.md` section 3 (manual on the emulator; an automated test with this ID after a fix).

### B-002: Dashboard first open with 500 spends is over 500 ms on the emulator
Task: T-384 (screen), T-385 (speed test) · Feature: F-013 (AC-17) · Severity: Medium · Status: Closed by ruling (D-100, 2026-11-23)
Steps to reproduce: 1. Emulator `Medium_Phone_API_37.0` (emulator-5554), debug build, emulator date 4 Dec 2026. 2. `flutter test integration_test/dashboard_500_test.dart -d emulator-5554` from `app/` (seed E2 + 500 spends over 9 categories). 3. Read the five "final figures after … ms" lines.
Expected: first frame with the final figures under 500 ms, worst of 5 (F-013 AC-17, TC-013-32); each switch and month change under 500 ms.
Actual: run 0 (the cold first open after a restart) is 562 to 723 ms in five runs; runs 1 to 4 are 205 to 347 ms. Worst of 5 fails in every run: 576, 562, 673, 607 ms (four runs before Tester 2 loaded the machine) and 723 ms (step 8 re-run). Figures and nine rows are correct; only the time is over. Debug build, so a profile build may be faster, but the test and D-083 define the check on this build and no profile exception was ruled for the Dashboard.
Evidence: `docs/reviews/emulator-phase-3/integration-dashboard-500.log`, `integration-dashboard-500-rerun1.log` to `rerun3.log`, `step8-rerun-dashboard_500.log` (Tester 1's logs). The `step8-dashboard_500.log` run failed differently (a finder error at `dashboard_500_test.dart:111`, while the machine was loaded) and is not counted.
Tester 1 profile-mode result (2026-11-21, `flutter drive --profile`): worst of 5 = 89 ms (89 / 54 / 62 / 53 / 67). The debug fail is a debug-build cold start; the profile build is well under 500 ms. Log `step8-profile-dashboard_500.log`. PM to rule whether the profile result closes AC-17 (the debug test is not loosened).
PM ruling (Gate 4, 2026-11-23, D-100): **closed, no app change.** F-013 AC-17 names no build mode; D-083 (profile mode, worst of 5, limit not loosened) is extended to it. Profile worst of 5 is 89 ms and 83 ms (`step8-profile-dashboard_500.log`, `step8-clean-profile-dashboard_500.log`), against 500 ms; the debug cold first open (562 to 1,349 ms) is the debug build, not the app. Run 0 stays in the worst-of-5 (no run dropped). T-474 is not needed. T-390 (Developer) makes `dashboard_500_test.dart` apply the 500 ms limit under `--profile` and keep only a loose guard in debug, and writes the profile command into TC-013-32; Tester records the closure (T-391).
Cause & fix (Developer): none needed (debug cold start; see the ruling).
Closure (Tester 2, T-391, 2026-11-23): closed per D-100. TC-013-32 recorded Pass in profile mode: worst of 5 = 89 ms (`step8-profile-dashboard_500.log`) and 83 ms (clean run 2026-11-23 18:35, `step8-clean-profile-dashboard_500.log`) against 500 ms; debug figures are logged only. Profile command is written into the TC-013-32 case in `tests/F-013-dashboard.md`; `dashboard_500_test.dart` applies the limit under `kProfileMode` (T-390).
Regression test: `TC-013-32 dashboard with five hundred spends is fast` (`integration_test/dashboard_500_test.dart`), listed in `tests/F-013-dashboard.md` section 3. Full regression after the fix.

### B-003: Money back device flow stops after editing the refund to ₹300
Task: T-442 (editor), T-443 (flow test) · Feature: F-016 (AC-3, AC-7, AC-8) · Severity: Medium (cause: test script, not the app) · Status: Closed 2026-11-24
Steps to reproduce: 1. Emulator-5554, emulator date Fri 13 Nov 2026, A seeded through the app. 2. `flutter test integration_test/money_back_flow_test.dart -d emulator-5554` from `app/`. 3. The test adds ₹500 `Amazon return` as money back (line `spent −₹80 · ₹910 left today`), restarts, then edits the refund to ₹300.
Expected: after the edit the Today line reads `budget ₹830 · spent ₹120 · ₹710 left today` (TC-016-34).
Actual: the test times out after 25 s waiting for that line; the line text reads `null` (the Today line is not on screen), at `money_back_flow_test.dart` line 84. Same failure in both runs, the second with the machine mostly idle. The widget-level cases TC-016-10 (editing a money back updates the day) and TC-016-11 pass, so the logic is right; either the real app does not return to the screen with the Today line after the edit, or the test script taps the wrong thing.
Evidence: `docs/reviews/emulator-phase-3/step8-money_back_flow.log`, `step8-rerun-money_back_flow.log` (Tester 1's logs).
Tester 1 device repro (2026-11-21, A13, 13 Nov): add money back ₹500 (Today line `spent ₹20`), open the row, edit to ₹300 and Save changes: the app returns to Transactions with the Today line `budget ₹830, spent ₹220, ₹610 left today` (220 because a ₹100 spend was also added) and the refund row `Refund, ₹300`; Home shows `Includes ₹300 back from refunds`. So the APP behaves correctly; the test script is the likely fault (amount replace or finder). Not edited.
Cause & fix (Developer, 2026-11-23): TEST SCRIPT, not the app. `_openRow` scrolls the Transactions list down to find the `Amazon return` row; after Save the app returns to the same scroll position, where the Today line (a lazily built list item) is not built, so `find.byKey(TodayLineView.lineKey)` was empty (`null`). The line shows the right text once scrolled to the top (Tester 1's device repro). Fix in `money_back_flow_test.dart`: `_expectLine` scrolls the line back into view before waiting for its text; also `_openTransactions` waits for the tab bar after a relaunch (the first emulator run showed a race there: the database answers after `launchOnFile` returns). No app code changed. Emulator runs: green 4 times in a row (logs `dev-final-money_back_flow-run1..3.log`, `dev-money_back_flow.log`).
PM review (Gate 4, 2026-11-23, D-101): read the test change; every expected text is unchanged, only the scroll and a tab-bar wait were added. Accepted; stays `Fixed pending Tester verification` until Tester 1 re-runs `money_back_flow_test.dart` on an idle machine (T-445) and closes it.
Tester 1 close (2026-11-24, T-445): `money_back_flow_test.dart` 3 of 3 runs green on the idle emulator (`s9-money_back_flow-1..3.log`) with every Today line of TC-016-34. Closed.
Regression test: `TC-016-34 add edit and delete money back on the device` (`integration_test/money_back_flow_test.dart`), listed in `tests/F-016-money-back-entry.md` section 3.

### B-004: Calendar grid with 500 spends is 495–525 ms in profile mode (limit 500 ms)
Task: T-325 / T-326 · Feature: F-011 (AC-18, TC-011-37) · Severity: Medium · Status: Closed 2026-11-24
Steps to reproduce: 1. From `app/`: `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/calendar_500_test.dart -d emulator-5554 --profile` (Oct + Nov seed, 500 spends). 2. Read the five "grid after" lines.
Expected: grid with final cells under 500 ms, worst of 5; each ‹ › under 500 ms.
Actual: Tester run 2026-11-21. Profile: grid 515, 525, 516, 495, 524 ms (worst 525), month change 56, 82, 53, 71, 53 ms (pass). Debug: grid 2652 / 1014 / 1472 / 1141 / 920 ms and 1851 / 797 / 808 / 687 / 713 ms on re-run (debug is not the pass rule, shown for the record). The measurement includes app start and database open (test comment), but it is stable at about 515 ms in profile on every run, so the limit is missed by about 5 %, not by noise. The limit is not loosened.
Clean re-run 2026-11-23 (emulator freshly booted, machine otherwise idle, profile): grid 548 / 498 / 494 / 517 / 497 ms (worst 548), month change 72 ms worst. Same failure.
Evidence: `step8-clean-profile-calendar_500.log`, `docs/reviews/emulator-phase-3/step8-profile-calendar_500.log`, `step8-calendar_500.log`, `step8-rerun-calendar_500.log`.
Decision needed (Project Manager): Developer reduces the grid's first-frame cost (500 spends read and summed before the first frame), or the PM rules that app start and DB open are outside AC-18 and the test measures from the Home first frame. A test change is not mine to make.
Cause & fix (Developer, 2026-11-23): see `docs/reviews/emulator-phase-3/dev-b004-probe-profile.log` and the section 11 note in plans/F-011. **No app change.** The ~500 ms is not the grid: `launchOnFile` ends with `pumpAndSettle()`, whose real-time 100 ms steps (live binding) round the measured time up to the next step after the screen is already done. The same launch pumped with 16 ms frames (profile, 10 runs): 30 final cells present after 142-234 ms, fully settled (cross-fade finished) after 170-266 ms. Compute is not the cost either: `computeMonth` plus `CalendarGrid.of` for the month take 0.1-0.3 ms on the emulator; the heaviest frame building the grid is 10-14 ms (37 ms the very first cold frame). The time is app start, DB isolate open (about 35 ms), the first query (about 70 ms), then month result, month index and browse in sequence. Measured with the unchanged test (profile, 5 launches each, worst): 524, 543, 542 ms (and 548 / 525 earlier). Not changed: the test (the limit and what it times are the PM's call). Proposal: time to final cells with 16 ms frames (what TC-011-37 and AC-18 literally say), keeping 500 ms: worst would be 234 ms.
PM ruling (Gate 4, 2026-11-23, D-094): option (a). AC-18 is about the grid with final cells being on screen within 500 ms, so the test times that: stopwatch from before `pumpWidget`, no closing `pumpAndSettle` inside the timed part, 16 ms frames until the 30 final cells with their seed sums are present, worst of 5, profile, limit 500 ms kept (method in T-490). No app change. Tester re-run T-491 closes B-004 if green.
Regression case: TC-011-37 in `tests/F-011-calendar.md` section 3 (profile run).
Tester 1 close (2026-11-24, T-491): `flutter drive --profile`, grid from launch 333 / 183 / 212 / 181 / 165 ms (worst 333), month change 184 / 96 / 52 / 54 / 66 ms (worst 184). Limit 500 ms unchanged. Debug runs (1744 ms) are not valid for speed (D-094, D-100). Evidence `s9-profile-calendar_500.log`.

### B-005: `month_setup_flow_test.dart` is stale: it waits for the Phase 2 Home text that Phase 3 removed
Task: T-305 · Feature: F-008 / F-010 (TC-008-18, TC-008-27 regression) · Severity: Medium (a red emulator regression, the app itself is fine) · Status: Closed 2026-11-24
Steps to reproduce: `flutter test integration_test/month_setup_flow_test.dart -d emulator-5554` (twice, 2026-11-21).
Expected: green, as in Phase 2.
Actual: both tests time out at "Home shows 5 Nov – 4 Dec · ₹830 a day". T-305 replaced `ThisMonthCard` by the summary card, so that line no longer exists (the same figures read `Left this month, ₹24,900. ₹830 a day, 5 November to 4 December.` on the device; see the device checks in `tests/F-010-home-summary.md`). Not an app defect; the Phase 2 integration test was not re-based when the Home was replaced.
Evidence: `docs/reviews/emulator-phase-3/step8-month-setup_flow.log`, `step8-rerun-month_setup_flow.log`.
Cause & fix (Developer, 2026-11-23): stale test. `_e2Home` is now the summary hero day line `₹830/day · 5 Nov – 4 Dec` (F-010), and the restart case opens the ⋮ menu (`More`) before `Edit this month`, which T-305 moved there. Both emulator tests green (`dev-month_setup_flow.log`, `dev-final-month_setup_flow.log`). No app code changed.
Owner: Developer updates `integration_test/month_setup_flow_test.dart` (the Tester must not change app code; the test file is left for the Developer to keep one author).
PM review (Gate 4, 2026-11-23, D-101): read the test change; it now checks the F-010 hero day line and opens More > Edit this month. Accepted; stays `Fixed pending Tester verification` until Tester 1 re-runs `month_setup_flow_test.dart` on an idle machine (T-445) and closes it.
Gate 5 note (Project Manager, 2026-11-24): the single first-run failure was a timing flake on the first install and not reproduced in 5 later runs; closed, watch it in Phase 4 (a second occurrence becomes a new bug).
Regression case: TC-008-18 / TC-008-27 (existing); F-010 section 3.
Tester 1 close (2026-11-24): runs 2 to 6 all green (`s9-month_setup_flow-2..6.log`). Run 1 failed once on the first install (TC-008-18, `tapText` found no element, `s9-month_setup_flow-1.log`); 5 later runs green, noted as a first-run timing flake, not reproduced.

### B-006: Home text breaks badly at text 2.0 on a 360 dp phone
Task: T-302 / T-305 · Feature: F-010 (TC-010-40, TC-010-41) · Severity: Low · Status: Closed 2026-11-24 (device check done; was: device check at 2.0 on 360 dp still to do)
Steps to reproduce: A13 with a 300 cover, 720x1280 at density 320, `settings put system font_scale 2.0`, Home, scroll to the Saved sub-line and the Today card.
Expected: nothing cut or split; words stay whole.
Actual: `₹300 used to cover days` breaks inside the word (`da` / `ys`); the Today card heading wraps as `Today` / `· Fri, 13` / `Nov` (separator starts a line). At the default size (411 dp wide) the heading also wraps to `Today · Fri, 13` / `Nov`. No overflow, nothing hidden, so the sweeps still pass; it is a polish defect.
Evidence: `docs/reviews/emulator-phase-3/s8-small-x2-scrolled.png`, `s8-small-collapsed-row.png`.
Cause & fix (Developer, 2026-11-23): two causes. (1) The sub-line glued every space of `in your savings pot ·` and `used to cover days` (U+00A0); at 2.0 on 360 dp one glued chunk is wider than the line, so the engine broke inside a word. New `ChunkedText` (`home_layout.dart`) keeps each chunk whole while it fits on a line and falls back to breaking between its words only when it cannot, so the designed break (after the dot) always wins and a word is never split. (2) The Today card header row had a `Flexible` heading next to a `Spacer`, so the heading got only half of the free width (the reason it wrapped `Today · Fri, 13` / `Nov` even at 411 dp). Now heading and (i) sit in an `Expanded` row beside the chevron, and the heading is two chunks, `Today ·` and the date, so a narrow line breaks only after the dot. Copy text is unchanged (`HomeCopy.todayHeaderLead` added). Not yet checked on the device.
Tester 1 close (2026-11-24): 2.0x on 720x1280 at 320 dpi: `₹300 used to cover days` unbroken and the heading breaks only after `Today ·`; default size: `Today · Fri, 13 Nov` on one line. Evidence `s9-b006-x2-top.png`, `s9-b006-x2-scroll1..3.png`, `s9-b006-default-scroll1..2.png`.
Regression test: `TC-010-60` (two tests named with it in `test/features/home/home_line_breaks_test.dart`, real fonts, 360 x 640, text 2.0; plus a unit test of `ChunkedText`). Shown to fail with the fix reverted: all-glued chunks give `line "₹1,700 in your savin" ends inside a word`; the old `Spacer` row breaks `Toda` / `y ·`.
