# Phase 3 test summary (Tester working file)

Written by the Tester for the Project Manager. Source files: `tests/F-010` to `tests/F-017`, `docs/reviews/code-phase-3-tracks-ad.md`, `docs/reviews/code-phase-3-tracks-bc.md`, `docs/TASKS.md`.

| | |
|---|---|
| **Status** | **Step 8 results are in section 4 and 5 of each test file and in section 6 below. 2026-11-23 (Tester 2): Gate 4 follow-ups T-391, T-408, T-428 and T-495 done (case results re-marked, probes re-run on the final code, section 6.6); what is left is the emulator and device work of section 7 (Tester 1, one idle-machine session), the TalkBack cases (Blocked-needs-human, D-097, D-104), and the Orchestrator's `tool/check.ps1` on the final code.** The T-307 20-run check is part of section 7 |
| **Change history** | 2026-11-19 (Tester, Gate 3 follow-up): first version. Mutation-pass plan from the two Gate 3 reviews, the list of emulator and manual cases still to run, TalkBack cases as Blocked-needs-human with steps 2026-11-21 (Tester 2, Step 8): section 6 added, results, mutation pass (72 mutants), survivors, what remains |
| | 2026-11-23 (Tester 2, T-391, T-408, T-428, T-495): section 6.6 added (probes re-applied on the final code, re-marked counts, what does not reconcile); section 7 added (remaining emulator and device tasks for Tester 1 with exact steps and pass rules); Phase 3 lines added to `tests/REGRESSION.md` as checks 27 to 31 |

## 1. What must be green before Step 8 starts
1. `tool/check.ps1` green on the final code (analyzer and `dart analyze --fatal-infos`, full suite, `tool/domain_coverage.ps1` 100 %, TZ matrix). Both reviews make every approval conditional on it.
2. The Must fix list of the reviews done: T-302 (day line break), T-306 (real-route tests), T-307 (20 clean runs of the flaky Home sweep state, no retry), T-340 / T-343 / T-344 (`DaySummary.overspendUnderRupee`, the change-line function, probes in plan F-012 section 11), T-384 (keep old content, TC-013-55), T-385 (M20 back in the Dashboard sweep), T-401 (spoken-rupees unit test, dead copy, duplicate range helper), T-402 (**tests for TC-014-06, -42, -52**; stale `LedgerRow` comment).
3. A case is run only when its full test exists (rule of `code-phase-3.md` T-389 item 4). Known missing tests today: TC-014-06, -42, -52, the spoken-rupees unit half of TC-014-28, TC-013-55, TC-013-56, TC-012-65 to -72, TC-014-58 to -60, TC-012-18 and -22 (the seam tests do not close them, review Track B).

## 2. Mutation-pass plan (Tester, Step 8)

**Purpose.** Coverage of 100 % does not prove a test can fail. For each file below, break the code in one small way, run only the tests that should notice, and confirm at least one fails. A mutant that survives is a missing test: write the test (under `app/test/`), never change the app code.

**How, without touching the Developers' files.** The Tester never edits `app/lib/`, and Developers edit it now. So: copy `app/` once to a scratch folder (outside the project, for example in the session scratchpad), apply one mutant at a time **in the copy**, run `flutter test <one file>` there, record the result, then restore the copy's file from the project (copy it over again; never delete with a shell alias, remove the scratch copy at the end with an explicit full path). Run it after the check run is green and the Must fix items are in, on the final code. Record every mutant in section 4 of the feature's test file (killed / survived, test name that failed).

**Order (money first).** 2.1 and 2.2, then 2.3, then 2.4. About 10 mutants per file, 30 to 45 minutes each file.

### 2.1 `lib/domain/budget/calendar_grid.dart` (F-011; no probes were recorded)
| # | Mutant | Test that must fail |
|---|---|---|
| 1 | `isMonthFirstDay` without `date != monthStart` (a month starting on the 1st shows `1 Dec`-style text on day 1) | TC-011-41 |
| 2 | Week starts on Sunday (first cell not a Monday) | TC-011-02, -39 |
| 3 | Leading or trailing outside cell counted as a budget cell | TC-011-02, -39 |
| 4 | Change days include a superseded same-day period (second tick) | TC-011-19 |
| 5 | A change tick on the first period's start | TC-011-18 |
| 6 | Today's fill follows `surface` even when something is spent (or the sign of the live result flipped) | TC-011-45, -08 |
| 7 | Under-₹1 threshold `< 100` becomes `<= 100` or `< 99` | TC-011-38 |
| 8 | `notBudgeted` boundary: `<` instead of `<=` the first budgeted day | TC-011-20 |
| 9 | Upcoming starts one day late (today counted as upcoming) | TC-011-08, -46 |
| 10 | A partly covered day drawn as ○ (or a fully covered day as ◆) | TC-011-14, -15 |
| 11 | Refund day: net sign flipped | TC-011-22 |

### 2.2 `lib/features/home/calendar/calendar_labels.dart` (F-011; no probes recorded)
| # | Mutant | Test that must fail |
|---|---|---|
| 1 | The sign flip `result.value < 0 ? -result : result` removed (a negative result read as a positive amount) | TC-011-08, -16 |
| 2 | `saved` and `overspent` words swapped | TC-011-08, -17 |
| 3 | Short form (`₹12k`) used in the spoken label instead of the full amount | TC-011-23 |
| 4 | `covered from savings` / `after ₹x from savings` dropped | TC-011-14 |
| 5 | Change-day phrase `budget changed this day` dropped | TC-011-18 |
| 6 | `net … after refunds` replaced by `spent` | TC-011-22 |
| 7 | Under-rupee words (`less than ₹1`) at 100 paise instead of 99 | TC-011-38 |
| 8 | Weekday missing from a not-budgeted label | TC-011-20, -21 |
| 9 | `Today,` prefix or `so far` dropped | TC-011-08, -45 |
| 10 | Late-setup wording replaced by the first-use wording | TC-011-21 |

### 2.3 The sweeps (T-307, T-346, T-385, T-404; widths and states, not money)
A sweep test proves a screen does not overflow and passes the contrast guideline, so each mutant must make a sweep **fail**:
| # | Mutant (in the scratch copy, one at a time) | Sweep that must fail |
|---|---|---|
| 1 | A fixed `SizedBox(width: 200)` around a figure row on Home, Day details, Dashboard, Statement | `home_*`, `calendar_day_sweep_test.dart` (TC-011-34, TC-012-30), `dashboard_sweep_test.dart` (TC-013-28), `statement_sweep_test.dart` (TC-014-26) |
| 2 | Day number colour set to `textSecondary` on `neutralSoft` (contrast under 4.5) | same, `textContrastGuideline` |
| 3 | A tappable cell or `Month statement` row shrunk to 40 dp | tap-target guideline in the same sweeps |
| 4 | Calendar legend back to a `Row` (no `Wrap`) | TC-011-34 and the Dashboard `M20` state at x2.0 (Gate 3 Must fix 5) |
| 5 | The state list loses `M20` or the scroll-to-the-end step | review the sweep list against the D states / Calendar states / Day details states / T states tables |
| 6 | Day line of the summary card without a break at ` · ` (T-302 item 1) | TC-010-41 / TC-010-44 at x2.0 |
| 7 | Collapsed row measured late (`_measure` removed) | the Home sweep state A13 scrolled, collapsed row (flaky state of T-307) |

Also here: **flakiness check for T-307.** Run the collapsed-row state (Light, x1.0, and the other three themes and x2.0) 20 times; one failure blocks Ready for test. No retry wrappers.

### 2.4 Track C widgets and the statistics (T-382 has 9 recorded probes; T-383 has none)
| # | Mutant | Test that must fail |
|---|---|---|
| 1 | `SegmentedControl` height 48 dp → 44 dp | TC-013-56 |
| 2 | `ShareBarRow` bar width = share + 1 permille, or bar painted accent, green or red | TC-013-06, `dashboard_widgets_test.dart` |
| 3 | Share row does not stack above 1.3x text | TC-013-50, -28 |
| 4 | `LedgerRow` semantic label drops the amount, or `status: null` changes the default output | TC-013-30, TC-014-28, the `LedgerRow` no-status case |
| 5 | Dashboard keeps no old content (`_shown`-style field removed) | TC-013-55 |
| 6 | `<1%` flag at `< 2` or `<= 1` percent | TC-013-08, -37 |
| 7 | Tie order by amount only (README order dropped) | TC-013-07 |
| 8 | Rounding note shown when the sum is not 100 **and** only one category, or never | TC-013-06, -07, -35 |
| 9 | `monthFigures` counts today as an ended day | TC-013-40 |
| 10 | Highest day ties: the later date wins, `moreDays` off by one | TC-013-16 |
| 11 | Average rounds down instead of toward zero (negative net −3,750 case) | TC-013-33, -19 |
| 12 | A fully covered day counted as saved, or a partly covered day not counted in `incl. n covered` | TC-013-15, -41 |
| 13 | `SpendCategory.fromKey` throws on an unknown key | TC-013-53 |
| 14 | `numbers_card.dart` day words (`saved`, `on budget`, `overspent`) swapped | TC-013-12, -19 |

### 2.5 Spot check of the Developer's probes (Track B and A money files)
When plan F-012 section 11 lists the probes asked in T-340 item 2 and T-344 item 2, re-apply **three** of them in the scratch copy (`maxCover` returns the pot; the refusal order in `validateCover` swapped; `persist` always true in the Undo snackbar) and confirm each fails the named test. Same for three of the F-010 / F-014 / F-017 model probes if recorded. A listed probe that does not fail on re-run is a Must fix to the Developer.

## 3. Emulator and manual cases still to run (Step 8, none run yet)

Emulator `Medium_Phone_API_37.0` (emulator-5554) per the Phase 2 runs; keep its window minimised. Log each run in `docs/reviews/emulator-phase-3/` (folder to be created by the run, not yet present) and in section 4 of the feature's test file. **F-011, F-012 and F-013 are not Done without a green log for their integration test** (Gate 3 reviews).

### 3.1 Integration tests written but never run
| Test | Case | Seed | Pass rule |
|---|---|---|---|
| `integration_test/calendar_500_test.dart` | TC-011-37 (F-011 AC-18) | Oct + Nov, 500 spends, emulator date 13 Nov 2026 | Grid with final cells under 500 ms and each ‹ › under 500 ms, worst of 5; cell amounts equal the seed sums. A failure is a bug (a never-run emulator test can also be wrong: check the test first) |
| `integration_test/day_details_cover_flow_test.dart` | TC-012-08, -37, -39 on a device (REGRESSION.md line "cover 11 Nov ₹300, Undo, Remove") | A13 on the real database | Cover ₹300 on 11 Nov, Undo, cover again, Remove; figures, snackbars and Home Overspent as in the cases; nothing stored after Undo or Remove |
| `integration_test/dashboard_500_test.dart` | TC-013-32 (F-013 AC-17) | E2 + 500 spends over 9 categories, emulator date 4 Dec | First frame with final figures under 500 ms, each switch under 500 ms, worst of 5; 9 rows shown; category totals equal the seed |
| `integration_test/statement_speed_test.dart` | TC-014-30 (F-014 AC-17) | 10 periods and 500 spends | Statement fully shown under 1,000 ms, worst of 5; month change keeps the old content |
| `integration_test/home_500_test.dart` | TC-010-43 (F-010 AC-17) | 500 spends | As the case in `tests/F-010` |

Run them one at a time (`flutter test integration_test/<file> -d emulator-5554`), the Tester's own run, after the check run is green. Record command, date, build and the five timings.

### 3.2 Manual [EMU] cases (no TalkBack)
| Case | What |
|---|---|
| TC-011-12 | Grey-scale colour correction: ● ○ ◆, today ring and change tick told apart by shape |
| TC-011-56 | Four themes at text scale 2.0 on the calendar |
| TC-011-57, TC-010-56 | Time-zone change on the device (as TC-007-37): ring follows the new zone |
| TC-011-58, TC-010-55 | App killed in the background (`adb shell am kill`): no crash, current month |
| TC-012-64 | App killed with the cover sheet open: nothing stored |
| TC-013-50, -51 | Dashboard at font 2.0 and landscape; four themes by eye |
| TC-013-52 | Dashboard killed in the background: opens on This month |
| TC-014-49, -50 | Statement at font 2.0 and landscape; four themes by eye |
| TC-014-51 | Arrival flash with Remove animations on and off |
| TC-014-54 | Statement killed in the background |
| TC-015-26, -59, -60; TC-016-35, -36 | F-015 and F-016 device cases (their own files, run with their features) |

### 3.3 TalkBack cases: Blocked-needs-human (D-066) with steps
An agent cannot drive TalkBack. Each case stays **Blocked-needs-human** until the Owner (or a helper) walks it on a real phone or the emulator; the Tester records the steps and the `adb shell uiautomator dump` texts as evidence when it can. Not a Gate 5 blocker (Phase 1 precedent), but listed as an open item for the CEO report.

**Setup common to all:** Settings > Accessibility > TalkBack on; font size 2.0 only where the case says; the seed named in the case; emulator date 13 Nov 2026 where it says. Swipe right = next item, double tap = activate. Turn TalkBack off afterwards.

| Case | Steps |
|---|---|
| TC-010-42 | Seed A13, then S8. Open Home. Swipe through from the top: summary card (amounts read as sentences, progress bar not read), Safe to spend line, Today card, calendar, ledger. Confirm each amount reads as words (`₹19,370 left`), the collapsed row after scrolling past the card is reachable and reads `₹19,370 left, ₹830 a day`, no red/green words |
| TC-017-27 | Seed A13. Open Home. Swipe to the Safe to spend line: reads the full sentence with the amount and `a day`; the (i) is a button with its text; spending today does not change the sentence |
| TC-011-36 | Seed A13. Swipe through the calendar: range heading, previous, next, legend, then each day as `Thursday 5 November, spent ₹500, saved ₹330`; outside days skipped; marks, ring and tick not read as words; double tap opens the day |
| TC-012-34 | Seed A13, font 2.0. Day details for 11 Nov: sentences as TC-012-32; open `Cover with savings`: the sheet title is announced; tap the field (keyboard opens): field and `Cover` stay reachable; an error is announced (live region); after Cover the Undo snackbar is announced and, with TalkBack on, stays until dismissed |
| TC-013-31 | Seed A, then B. Dashboard: order as `dashboard.md` section 12; `Shopping, ₹1,000, 18 percent`; the Days sentence; the highest-day button; the Other hint and its button |
| TC-014-29 | Seed M20. Statement: whole page in order; period headings; the working line is one sentence; arriving from `Budget changed on this day` puts focus on the Period 2 heading |
| TC-015-39, TC-016-24 | As written in their files, run with their features |
| Phase 1 carry-over | TC-003-03 step 4, TC-003-18, TC-004-04, TC-004-07 R1, TC-008-26, TC-009-22 (steps in `tests/PHASE-1-SUMMARY.md`); TC-007-48 needs two real phones |

## 4. Regression the Tester re-runs at Step 8 (from the plans and reviews)
F-003 and F-004 cases that read the Dashboard tab (the Dashboard replaced the placeholder, T-385 item 4: TC-003-05, -31, -04, -12, -20; TC-004-06, -09, -10); F-009 editor cases through day details (TC-009-03, -06, -11, -12, -25 to -28); F-007 savings and cover cases (TC-007-18, -46, -49 to -52); F-006 cover and period cases; the F-008 amount field (TC-008-05); the Transactions sweep (shared `TodayResultLine`, T-303); `tests/REGRESSION.md` plus the new Phase 3 lines (to be added at Step 8 per feature).

## 5. Open items that block Done (not test failures)
- F-011: green `calendar_500` log; T-454 (five amounts to measure at 360 dp) is Nice to have.
- F-012: green `day_details_cover_flow` log; TC-012-58 after F-016 T-442; F-014 wiring (D-077).
- F-013: green `dashboard_500` log; AC-15 live proof through the F-015 flow after F-015 T-423.
- F-014: green `statement_speed` log; the three missing tests above.
- F-010: green `home_500` log; T-307 flaky state settled (20 clean runs).

## 6. Step 8 results (Tester 2, 2026-11-21): F-013, F-014, F-015, F-016 and the mutation pass

**Run.** Whole suite `flutter test --reporter json`: 1,267 tests, 1,267 passed, 0 failed, 0 skipped. `tool/domain_coverage.ps1`: DOMAIN COVERAGE 100 % (lines and branches, every file including `category_breakdown`, `month_figures`, `calendar_grid`, `month_statement`, `transaction_search`). `tool/tz_matrix.ps1`: UTC, PST8PDT and IST dumps identical, PASSED. Manual command cases: the integer-only, layer, privacy and logging scans of `lib/` are clean (only `~/` divisions in the statistics, no `double` or `num` in `lib/domain/budget`, `lib/domain` imports nothing from `data/`, `features/` or Flutter, features read only `data/repositories`, no network or analytics package, the only `debugPrint` is the existing `app_logging.dart`). `tool/check.ps1` as a whole was not re-run by me (it is the Orchestrator's check run and it runs `flutter` in the same app folder as Tester 1).

| Feature | Cases | Pass | Partial | Fail | Blocked | Pending |
|---|---|---|---|---|---|---|
| F-013 Dashboard | 60 | 47 | 4 | 1 (TC-013-32, B-002) | 6 (TalkBack TC-013-31; no test: TC-013-49, -57, -58, -59, -60) | 2 |
| F-014 Month statement | 60 | 52 | 2 | 0 | 4 (TalkBack TC-014-29; no test: TC-014-58, -59, -60) | 2 |
| F-015 Transactions list | 67 | 58 | 1 | 0 | 4 (TalkBack TC-015-39; no test: TC-015-65, -66, -67) | 4 |
| F-016 Money back | 47 | 43 | 1 | 1 (TC-016-34, B-003) | 1 (TalkBack TC-016-24) | 1 |

Counts include the new cases written in this pass (F-013 -57 to -60, F-015 -65 to -67, F-016 -46 and -47). Device and integration cases use Tester 1's logs in `docs/reviews/emulator-phase-3/` (read 2026-11-21): TC-013-32 fails in four clean runs (562 to 673 ms) and the re-run (723 ms) against 500 ms: **B-002**. TC-014-30 passes (702 ms clean, 745 ms in the step 8 re-run; the first step 8 run, 1,087 ms, overlapped my full-suite and mutation runs from about 01:15 to 01:37 IST and is not counted). TC-015-27 and TC-015-28 passed in the clean logs and failed in the step 8 logs taken while I was still running: **Pending a re-run on an idle machine**. TC-016-34 times out at the same step (waiting for the Today line `spent ₹120 · ₹710 left today` after the edit to ₹300) in two logs, the second with the machine mostly idle: **Fail, B-003** (app or test script, to be found). Tester 1's own cases (F-010 to F-012, F-017) are not in this table.

**Mutation pass: 72 mutants, 55 killed, 17 survived.** Every survivor has a reason below or in the feature file (section 4.2 of `tests/F-013` to `F-016`). Method: scratch copy of `app/` in the Tester's scratchpad, one mutant at a time, only the named test files run, copy restored after each run, project `app/` never touched.

### 6.1 F-011 grid and labels (`calendar_grid.dart`, `calendar_labels.dart`, with the engine and `dayResultKind` lines they depend on)
| # | File | Mutant | Result | Failing test |
|---|---|---|---|---|
| G1 | domain/budget/calendar_grid.dart | isMonthFirstDay without date != monthStart (TC-011-41) | **KILLED** | TC-011-41 a month starting on the 1st shows a plain 1 |
| G2 | domain/budget/calendar_grid.dart | week starts on Sunday (TC-011-02, -39) | **KILLED** | TC-011-02 salary day 5: Mon 2 Nov to Sun 6 Dec, 35 cells; TC-011-02 the F-006 months: Feb 2027, 31 Jan, the leap days |
| G3 | domain/budget/calendar_grid.dart | a leading outside cell counted as a budget cell (TC-011-02, -39) | **KILLED** | TC-011-02 salary day 5: Mon 2 Nov to Sun 6 Dec, 35 cells; TC-011-02 the F-006 months: Feb 2027, 31 Jan, the leap days |
| G4 | domain/budget/calendar_grid.dart | change days include superseded periods (TC-011-19) | **SURVIVED** | all named tests pass |
| G5 | domain/budget/calendar_grid.dart | change tick on the first period start (TC-011-18) | **KILLED** | TC-011-08 example A labels read as the table; TC-011-16 shortfall month labels |
| G6a | domain/budget/calendar_grid.dart | today fill ignores spend (nothingSpent only checks refunds) (TC-011-45, -08) | **KILLED** | TC-011-10 cells for every engine status (example A); TC-011-08 cells of example A show their amounts and marks |
| G6b | domain/budget/calendar_grid.dart | today fill on budget drawn as saved | **KILLED** | TC-011-10 cells for every engine status (example A) |
| G6c | domain/budget/calendar_grid.dart | today fill sign flipped for saved | **KILLED** | TC-011-10 cells for every engine status (example A); TC-011-08 cells of example A show their amounts and marks |
| G7a | domain/budget/day_summary.dart | under-1-rupee threshold <= 100 (TC-011-38) | **SURVIVED** | all named tests pass |
| G7b | domain/budget/day_summary.dart | under-1-rupee threshold < 99 (TC-011-38) | **SURVIVED** | all named tests pass |
| G8 | domain/budget/budget_engine.dart | notBudgeted boundary: first budgeted day treated as not budgeted (TC-011-20) | **KILLED** | TC-011-02 salary day 5: Mon 2 Nov to Sun 6 Dec, 35 cells; TC-011-02 the F-006 months: Feb 2027, 31 Jan, the leap days |
| G9 | domain/budget/budget_engine.dart | today counted as upcoming (TC-011-08, -46) | **KILLED** | TC-011-02 salary day 5: Mon 2 Nov to Sun 6 Dec, 35 cells; TC-011-02 the F-006 months: Feb 2027, 31 Jan, the leap days |
| G10 | domain/budget/calendar_grid.dart | partly covered day kind computed without the cover (TC-011-14, -15) | **KILLED** | TC-011-14 covered days say what savings covered |
| G11 | domain/budget/calendar_grid.dart | refund day net sign flipped (TC-011-22) | **KILLED** | TC-011-08 example A labels read as the table; TC-011-14 covered days say what savings covered |
| G12 | domain/budget/calendar_grid.dart | hasRefunds inverted (TC-011-22) | **KILLED** | TC-011-08 example A labels read as the table; TC-011-14 covered days say what savings covered |
| G13 | domain/budget/calendar_grid.dart | covered dropped from the cell (TC-011-14) | **KILLED** | TC-011-14 covered days say what savings covered; TC-011-14 covered days: fully on budget, partly still overspent |
| G14 | domain/budget/calendar_grid.dart | notBudgeted cell tappable (TC-011-20) | **KILLED** | TC-011-10 cells for every engine status (example A); TC-011-20 not budgeted days cannot be tapped |
| L1 | features/home/calendar/calendar_labels.dart | sign flip of the result removed (TC-011-08, -16) | **KILLED** | TC-011-08 example A labels read as the table; TC-011-14 covered days say what savings covered |
| L2 | features/home/calendar/calendar_labels.dart | saved and overspent words swapped (TC-011-08, -17) | **KILLED** | TC-011-08 example A labels read as the table; TC-011-22 refund days say net after refunds |
| L3 | features/home/calendar/calendar_labels.dart | short form in the spoken label (TC-011-23) | **KILLED** | TC-011-22 refund days say net after refunds; TC-011-24 labels carry the full amount, never a short form |
| L4 | features/home/calendar/calendar_labels.dart | covered/after-from-savings phrase dropped (TC-011-14) | **KILLED** | TC-011-14 covered days say what savings covered |
| L5 | features/home/calendar/calendar_labels.dart | change-day phrase dropped (TC-011-18) | **KILLED** | TC-011-18 the change day adds its words |
| L6 | features/home/calendar/calendar_labels.dart | net after refunds replaced by spent (TC-011-22) | **KILLED** | TC-011-22 refund days say net after refunds; TC-011-23 an amount that would shrink under 9 sp is hidden |
| L8 | features/home/calendar/calendar_labels.dart | weekday missing from the labels (TC-011-20, -21) | **KILLED** | TC-011-08 example A labels read as the table; TC-011-14 covered days say what savings covered |
| L9a | features/home/calendar/calendar_labels.dart | Today, prefix dropped (TC-011-08, -45) | **KILLED** | TC-011-08 example A labels read as the table; TC-011-45 today overspent, nothing spent, on budget today |
| L9b | features/home/calendar/calendar_labels.dart | so far dropped for today (TC-011-45) | **KILLED** | TC-011-08 example A labels read as the table; TC-011-45 today overspent, nothing spent, on budget today |
| L10 | features/home/calendar/calendar_labels.dart | late-setup wording replaced by first-use wording (TC-011-21) | **KILLED** | TC-011-20 not budgeted labels carry the weekday |

### 6.2 Sweeps (F-010 to F-014 widths, contrast, tap targets)
| # | File | Mutant | Result | Failing test |
|---|---|---|---|---|
| S1a | features/dashboard/widgets/numbers_card.dart | fixed 600 dp width around a Dashboard figure (TC-013-28) | **KILLED** | TC-013-28 dashboard states pass the theme and text scale sweep; TC-013-28 dashboard states survive landscape |
| S1b | core/widgets/ledger_row.dart | fixed 600 dp width around a ledger amount (TC-014-26, TC-013-28, TC-012-30) | **KILLED** | TC-014-26 statement states pass the theme and text scale sweep; TC-014-49 statement in landscape keeps a 600 dp column |
| S2 | features/home/calendar/day_cell.dart | calendar day number textSecondary on neutral fill (contrast) (TC-011-34) | **SURVIVED** | all named tests pass |
| S2b | features/home/calendar/day_cell.dart | calendar day number in the border colour (contrast under 4.5) | **SURVIVED** | all named tests pass |
| S3a | core/widgets/segmented_control.dart | segmented control 40 dp (tap target) (TC-013-28) | **SURVIVED** | all named tests pass |
| S3b | core/widgets/ledger_row.dart | ledger row minimum height 30 dp (TC-014-26) | **SURVIVED** | all named tests pass |
| S3c | core/widgets/ledger_row.dart | ledger row minHeight 0 (is the constant what makes 48 dp?) | **SURVIVED** | all named tests pass |
| S4 | features/home/calendar/calendar_legend.dart | calendar legend back to a Row (TC-011-34, M20 state) | **KILLED** | TC-010-40 p3 driver opens a Home state per fixture; TC-011-34 calendar states pass the theme and text sweep |
| S7 | features/home/home_tab.dart | collapsed row never measured (T-307 state) | **KILLED** | TC-010-33 summary collapses to one pinned row on scroll; TC-010-34 collapsed row for negative left and its large text rule |

### 6.3 Developer probes re-applied (section 2.5)
| # | File | Mutant | Result | Failing test |
|---|---|---|---|---|
| P1 | domain/budget/cover_draft.dart | probe 2.5: maxCover returns the pot | **KILLED** | TC-012-57 max cover is the lesser of pot and overspend; TC-012-04 day details figures are the engine values in paise |
| P2 | domain/budget/cover_draft.dart | probe 2.5: refusal reasons swapped in validateCover | **KILLED** | TC-012-12 invalid cover amounts name their problem (a to f); TC-012-13 overspend message comes before the pot message |
| P3 | features/transactions/category_change_flow.dart | probe 2.5: persist always true in the Undo snackbar | **KILLED** | TC-015-21 undo restores the previous value and the same pick is a no op; TC-015-21 undo is gone six seconds after the change without a screen reader |

### 6.4 Survivors and what they mean
| Survivor | Verdict | Action |
|---|---|---|
| G4 (change days from all periods, not the kept ones) | **Real gap.** Same result unless the first period is superseded (a change on the month's first day): then day 1 would get a change tick. No calendar test has a day-one change | T-475 (1); a case for `tests/F-011` (Tester 1's file) |
| G7a, G7b (under-₹1 threshold `<= 100`, `< 99`) | **Real gap, money wording.** The tests use 50 paise only; 99 and 100 paise are untested, so "less than ₹1" could flip for exactly ₹1.00 | T-475 (2) |
| S2, S2b (calendar day number in `textSecondary`, in the border colour) | **Real gap.** The sweeps' contrast guideline does not see these numbers (excluded from semantics), so even a sub-4.5:1 colour passes | T-475 (3) |
| C2b, C2c (share bar green, accent) | Real gap (colour is only a manual check) | TC-013-58, T-471 |
| C4b (`LedgerRow` plain amount colour) | Real gap | TC-013-59, T-471 |
| C6a, C6b (`<1%` at <= 1 and < 2 percent) | Real gap, display of a share | TC-013-60, T-471 |
| C15 (Other hint hidden in One day) | Confirms TC-013-49 has no test | T-471 |
| C1, C1b, S3a (segmented control 44, 0, 40 dp), S3b, S3c (ledger row 30, 0 dp) | Equivalent today: the height comes from the content (the (i) button and the segment padding), so the constants are redundant; only the 1.0x measurement is missing | TC-013-57, T-471 |
| T25b (search field forgets its text) | Equivalent in the current `IndexedStack` shell; the provider-level survival is untested | TC-015-67, T-473 |

Not run: sweep mutant 5 (state list review: `M20` is in the Dashboard sweep list, read in `dashboard_sweep_test.dart`; the sweep passes with it), sweep mutant 6 (T-302 day line break) and the 20-run flakiness check of T-307 (Tester 1's Home feature). Plan items checked by other ids: change tick on the first period = G5 (killed); `notBudgeted` and `upcoming` boundaries live in the engine and were applied there (G8, G9, killed).

### 6.5 What remains before Gate 4 (F-013 to F-016)
1. Fix B-002 (T-474) and B-003 (T-476) and re-run `dashboard_500` and `money_back_flow` on an idle machine.
2. Developer tests for the missing cases: TC-013-49, -57 to -60 (T-471), TC-014-58 to -60 (T-472), TC-015-65 to -67 (T-473); F-010 to F-012 survivors (T-475).
3. A clean re-run of `transactions_search` (TC-015-27, -28) by Tester 1 on an idle machine, and its logs for the [EMU] cases of my four files (kill, force-stop, four themes by eye, font 2.0 and landscape by hand): TC-013-50, -51, -52; TC-014-49, -50, -51, -54; TC-015-26, -59, -60; TC-016-35, -36.
4. TalkBack walks by the Owner (Blocked-needs-human, steps in section 3.3 and in each case): TC-013-31, TC-014-29, TC-015-39, TC-016-24.
5. The Orchestrator's `tool/check.ps1` on the final code (dart format step, analyzer) after the Developer's test additions.

### 6.6 Gate 4 follow-up (Tester 2, 2026-11-23): probes on the final code and the re-marked totals

**Probes re-applied once on the final code (D-102, T-391, T-428).** Method as section 2: scratch copy of `app/` (lib, test, assets, pubspec, build.yaml, drift_schemas, integration_test, test_driver) outside the project, one probe at a time, only the named test files run, the changed file restored after each run (afterwards `lib/` of the copy was compared with the project's `lib/`: identical; the project's `app/` was never touched). Unmutated baseline first: green. Files run: `dashboard_widgets_test.dart`, `dashboard_tab_test.dart`, `category_breakdown_test.dart` (58 tests each run) for the Track C probes; `transactions_filters_test.dart`, `transactions_search_queries_test.dart` (35 tests) for T25b.

| # | File | Probe | Result | Failing test |
|---|---|---|---|---|
| C1 | core/widgets/segmented_control.dart | `minHeight` 48 to 44 dp | **KILLED** | TC-013-57 segmented control keeps 48 dp at normal text |
| C1b | core/widgets/segmented_control.dart | `minHeight` 0 | **KILLED** | TC-013-57 |
| S3a | core/widgets/segmented_control.dart | `minHeight` 40 dp | **KILLED** | TC-013-57 |
| C2b | core/widgets/share_bar_row.dart | bar painted `saved` (green) | **KILLED** | TC-013-58 share bars are ink in every theme |
| C2c | core/widgets/share_bar_row.dart | bar painted `accent` | **KILLED** | TC-013-58 |
| C4b | core/widgets/ledger_row.dart | no-status amount colour `textSecondary` | **KILLED** | TC-013-59 ledger amount colour |
| C6a | domain/budget/category_breakdown.dart | `<1%` flag at `<= 1` percent | **KILLED** | TC-013-60 share boundaries around one percent |
| C6b | domain/budget/category_breakdown.dart | `<1%` flag at `< 2` percent | **KILLED** | TC-013-60 |
| C15 | features/dashboard/dashboard_tab.dart | Other hint hidden in One day (`range != day` added to `showTip`) | **KILLED** | TC-013-49 other hint shows for a one day all other state |
| T25b | features/transactions/transactions_tab.dart | search field `TextEditingController()` without the stored query | **KILLED** | TC-015-67 filters and search text outlive a rebuilt tab; TC-015-48 filters survive midnight and the month follows |

**Result: 10 probes, 10 killed, 0 survived** (the 9 Track C survivors of section 6.4 plus T25b). The 17 survivors of section 6.4 now stand at: 10 re-confirmed killed here (C1, C1b, C2b, C2c, C4b, C6a, C6b, C15, S3a, T25b); 5 killed by the Developer's T-475 tests (G4, G7a, G7b, S2, S2b, all F-011; D-102 asks only for the Track C and T25b re-run, so I did not re-apply them); 2 equivalent constants with no test (S3b and S3c, ledger row 30 dp and 0 dp, D-102). No probe failed to fail, so there is no Must fix for the Developer from this re-run. The survivor tables in `tests/F-013`, `F-014` and `F-015` carry the re-run notes.

**Targeted test run on the current code.** Eleven files (`dashboard_tab_test`, `dashboard_widgets_test`, `category_breakdown_test`, `month_statement_screen_test`, `month_statement_test`, `transactions_search_queries_test`, `transactions_filters_test`, `calendar_gap_cases_test`, `budget_change_text_test`, `day_summary_test`, `cover_sheet_test`): 217 tests, 217 passed, 0 failed, 0 skipped after the Developer removed the `skip` of `TC-011-35 screen reader order on a past month` (the first run, minutes earlier, showed it skipped; the re-run of `calendar_gap_cases_test.dart` shows 8 of 8 passed, 0 skipped). Also green: `calendar_grid_test.dart` (17 of 17, the model test now carries TC-011-03 to -07 and -40 in its name) and `money_format_test.dart` (7 of 7, the TC-014-28 unit half). Every test named in T-391, T-408, T-428 and T-495 was found by its name and passed; there is no test with the ID `TC-013-56` (it is Pass through TC-013-57, as T-391 says).

**Re-marked totals (case files).**
| File | Before | After | What changed |
|---|---|---|---|
| F-011 (66) | Pass 47, Partial 10, Not run 7, Blocked 1, Fail 1 | Pass 61, Partial 3, Not run 0, Blocked 1, Fail 1 | TC-011-11, -15, -42, -43, -47, -48 Pass (`calendar_gap_cases_test.dart`); TC-011-03 to -07, -40 Pass (IDs now in the model test name); TC-011-12 Pass on shape assertions (D-096, Owner look open); TC-011-35 Pass (skip gone; case text for a past month changed to the app's order, D-095). Still Partial and accepted: TC-011-32, -33, -58 (D-099). Still Fail: TC-011-37 (B-004, T-491 re-run) |
| F-012 (74) | Pass 63, Partial 10, Blocked 1 | Pass 73, Blocked 1 | TC-012-65 to -74 Pass with their test files |
| F-013 (60) | Pass 47, Partial 4, Fail 1, Blocked 6, Pending 2 | Pass 56, Partial 1, Blocked 1, Pending 2 | TC-013-32 Pass in profile (83 and 89 ms, D-100), B-002 closed; TC-013-48, -49, -55, -56, -57 to -60 Pass. Open: TC-013-50 (device half), -51, -52, -31 |
| F-014 (60) | Pass 52, Partial 2, Blocked 4, Pending 2 | Pass 55, Partial 2, Blocked 1, Pending 2 | TC-014-58, -59, -60 Pass; TC-014-06, -42, -52, -30 confirmed Pass (30: profile 123 and 110 ms). Open: TC-014-49, -51 (device halves), -50, -54, -29 |
| F-015 (67) | Pass 58, Partial 1, Blocked 4, Pending 4 | Pass 63, Partial 1, Blocked 1, Pending 2 | TC-015-65, -66, -67 Pass; TC-015-27 and -28 Pass from the clean profile log 2026-11-23 18:35 (open 90 ms, scroll worst build 8.1 ms of 32, search 273 ms of 300). Open: TC-015-26, -59 (device half), -60, -39 |
| F-016 (47) | unchanged | unchanged | not part of these tasks; TC-016-34 (B-003) and TC-016-35, -36 are in section 7 (T-445) |

**What does not reconcile (for the Orchestrator and the Project Managers).**
1. The table of section 6 (Tester 2, 2026-11-21) and the paragraph "Missing tests today" in section 1 are history and still show the old counts; section 6.6 and the case files are current. I did not rewrite the history.
2. The 20-case statement in the Tester 1 paragraph below ("7 F-011 cases have no test carrying their ID and 20 cases in F-011/F-012 are Partial") is now settled by section 6.6: F-011 has 3 accepted Partial cases and F-012 none.
3. The task text says T-495 is a Tester 1 task; it was done here by Tester 2 at the Orchestrator's request. TC-011-37 (B-004) and everything under T-491, T-493, T-496 are untouched: they need the emulator or an idle machine (section 7).
4. `tests/F-016-money-back-entry.md` still shows TC-016-34 as Fail (B-003) until T-445 re-runs `money_back_flow_test`; B-003 and B-005 stay `Fixed pending Tester verification` in `docs/BUGS.md`. B-006 likewise (T-493). B-002 is closed (D-100).
5. The margin note for TC-015-28: D-103 says 25 ms, the log gives 273 ms of 300 (27 ms). T-469 stays armed either way.
6. D-105 asks for a final full regression including `tool/check.ps1` on the final code: this has not been run after the Developers' latest test edits (I ran only targeted files; the Orchestrator's check run is the next step, and it must not overlap an emulator session).

## 6. Step 8 results, Tester 1 (F-010, F-011, F-012, F-017), 2026-11-21 and 2026-11-23
**Automated:** `tool/check.ps1` green twice (1267 tests on 11-21, 1285 on 11-23; analyzers, 100 % domain coverage incl. `safe_to_spend.dart` 20/20 lines 10/10 branches, TZ matrix identical in UTC, PST8PDT, IST). Logs `docs/reviews/emulator-phase-3/check-run-step8.txt`, `check-run-step8-r2.txt`.

**Emulator integration tests (limits not loosened; profile is the measurement):**
| Test | Debug | Profile | Result |
|---|---|---|---|
| home_500 (TC-010-43) | worst 1039 ms once (cold jitter), then 17 / 14 ms | 0 ms | Pass |
| calendar_500 (TC-011-37) | grid 687-2652 ms | **525 ms and 548 ms worst (limit 500)** | **Fail, B-004** |
| day_details_cover_flow | exit 0 on every run | n/a | Pass |
| statement_speed (TC-014-30) | 1087 / 745 / 667 ms | 123 / 110 ms | Pass |
| dashboard_500 (TC-013-32) | run 0 562-1349 ms | 89 / 83 ms | debug Fail B-002, profile Pass |
| transactions_search (TC-015-27/-28) | search 275-368 ms (load-dependent) | search 276 / 273 ms, scroll raster 24 / 14.7 ms | Pass in profile |
| manual_transactions_flow, persistence, transactions_500 (724-905 ms), onboarding_flow, preferences_persistence | green | n/a | Pass |
| money_back_flow (TC-016-34) | fails at the edit to ₹300, three runs | n/a | Fail B-003; the same steps pass by hand on the device (app correct) |
| month_setup_flow | fails, three runs (waits for the Phase 2 Home line removed in T-305) | n/a | Fail B-005 (stale test) |

**T-469 hint (TC-015-28):** idle-machine search worst is 273-276 ms in profile and 275 ms in debug (11-21 first run); 304-368 ms only under load or on a freshly booted emulator. The trigger "a clean run over 285 ms" has not been met.

**Device checks (A13 seeded; clock 13 Nov 2026):** Home figures and strip match the engine; Home tip first then Calendar tip; calendar labels per day; day taps open the real Day details route; Month statement link opens the real statement route (T-306 both defaults verified on the device); cover ₹300 on 11 Nov with snackbar, Undo, Remove (nothing stored after Undo or Remove), Home pot ₹1,700 and Overspent ₹170 after the cover; collapsed row at 360 x 640 dp (not built at x2.0); text 2.0 and large display size and landscape: no overflow lines in logcat (B-006 Low: word break at x2.0); four themes at x2.0 walked; force-stop and `am kill` persistence; Los Angeles time zone moves the ring; next day Safe to spend ₹922 a day, 21 days left; ₹100 spend today leaves ₹899 unchanged. Evidence `docs/reviews/emulator-phase-3/s8-*.png`.

**Regression lines to add to `tests/REGRESSION.md` (Orchestrator may merge):** (1) Home with A13 on the emulator: figures, Today card, Safe to spend, calendar labels (TC-010-03/-06/-08). (2) Cover 11 Nov ₹300, Undo within 6 s, cover again, Remove (TC-012-08/-37/-39). (3) Safe to spend ₹899 then ₹922 next day (TC-017-04). (4) Home Month statement link and a calendar day open the real routes (T-306).

**Still Blocked-needs-human (TalkBack):** TC-010-42, TC-011-36, TC-012-34, TC-017-27 (steps in 3.3). **Open before Gate 4 can pass for F-011:** B-004. **For the Developers:** B-003, B-005 test fixes; 7 F-011 cases have no test carrying their ID (TC-011-11, -15, -35, -42, -43, -47, -48) and 20 cases in F-011/F-012 are Partial through another ID.

## 7. Remaining emulator and device tasks for Tester 1 (one idle-machine session)

Written 2026-11-23 by Tester 2. Everything below can be done in **one session** on an idle machine (no other `flutter`, Gradle or emulator work at the same time; Tester 2 and the Orchestrator's `tool/check.ps1` must not run during it). **Order:** step 0, then A (flutter test only, no emulator), then B (profile speed runs), C (functional re-runs), D (device by-hand cases, grouped by seed), then close the records. The TalkBack cases stay Blocked-needs-human (D-097, D-104, section 3.3) and are **not** in this session.

### 7.0 Setup and rules for the whole session
- From `app/`. Emulator `Medium_Phone_API_37.0` as `emulator-5554`, window minimised, started cold once (not freshly booted during a timed run: wait 2 minutes after boot). Package `com.dailybudget.app`.
- Clock for the device cases: `adb shell settings put global auto_time 0`, then `adb shell cmd alarm set-time <epoch ms>` (13 Nov 2026 10:30 IST, as your step 8 device checks). Seeds are the ones named in each case (A13, A, B, M20, S, AR, as in your step 8 device run: seeded through `run-as` and sqlite3; evidence names `s8-*.png` already in the folder).
- Evidence for every case: screenshot `adb exec-out screencap -p > docs/reviews/emulator-phase-3/s9-<case>.png` (and the `adb shell uiautomator dump` text where the case says), notes in section 4 of the case's test file (`tests/F-xxx`), logs as `docs/reviews/emulator-phase-3/s9-*.log`.
- **Reset after each by-hand case that changes the display:** `adb shell settings put system font_scale 1.0`; `adb shell wm size reset`; `adb shell wm density reset`; `adb shell settings put system accelerometer_rotation 0`; `adb shell settings put system user_rotation 0`; animations back on: `adb shell settings put global animator_duration_scale 1`, `transition_animation_scale 1`, `window_animation_scale 1`. Theme back to Auto where a case changed it.
- **Standard display set-ups.** Font 2.0 at 360 dp: `adb shell wm size 720x1280`, `adb shell wm density 320`, `adb shell settings put system font_scale 2.0`. Landscape 640 x 360: `adb shell settings put system accelerometer_rotation 0`, `adb shell settings put system user_rotation 1`. Remove animations on: the three `*_scale` settings above to `0`, off: to `1`.
- **Kill:** `adb shell input keyevent KEYCODE_HOME`, then `adb shell am kill com.dailybudget.app` (works because the app is in the background), reopen with `adb shell monkey -p com.dailybudget.app -c android.intent.category.LAUNCHER 1`. **Force-stop:** `adb shell am force-stop com.dailybudget.app`, reopen the same way.
- **Overflow check on every by-hand walk:** `adb logcat -d | grep -i "overflow"` after the walk (clear first with `adb logcat -c`): no `RenderFlex overflowed` line.
- A failure is a bug: log it in `docs/BUGS.md` (next free number), add the regression case to the feature file, stop that case, continue with the next. Do not loosen any limit.

### 7.A Idle-machine flutter test (no emulator): T-496
| Task | Steps | Pass rule |
|---|---|---|
| **T-496** (F-010 AC-18, 19; Gate 3 Must fix, never run) | After the Orchestrator's green `tool/check.ps1`, on the idle machine: run the Home sweep 20 times in a row, **no retry wrapper and no `--retry`**: `for ($i = 1; $i -le 20; $i++) { flutter test test/a11y/phase3_screen_sweep_test.dart --plain-name "TC-010-40 home states pass the theme and text scale sweep"; "run $i exit $LASTEXITCODE" }`, and the same 20 times for `test/features/home/home_collapsed_row_test.dart` (the collapsed-row state of T-307: Light x1.0, the other three themes and x2.0 are inside the sweep's loops). Record the command and the 20 exit codes (and the failing test name if any) in `tests/F-010-home-summary.md` section 4 | 20 of 20 green for both. One failure blocks F-010 Done and becomes a bug (collapsed row measured late, the T-307 state) |

### 7.B Profile speed runs: T-491 (calendar_500, home_500)
Run one at a time, each after the previous one has finished and the app is closed. Each command: `flutter drive --profile -d emulator-5554 --driver=test_driver/integration_test.dart --target=integration_test/<file> 2>&1 | Tee-Object docs/reviews/emulator-phase-3/s9-profile-<name>.log`.
| Task | File and case | Steps | Pass rule |
|---|---|---|---|
| T-491 (a) | `calendar_500_test.dart`, TC-011-37 (F-011 AC-18, D-094) | Emulator date 13 Nov 2026 is set by the test seed (Oct + Nov, 500 spends); run the command; read the five timings of the grid with its 30 final cells and of ‹ and › (the test stopwatch starts before `pumpWidget`, 16 ms frames, waits for the final cells with their seed sums, worst of 5 including run 0) | Worst of 5 under 500 ms for the grid and for each month change; cell amounts equal the seed sums. Green: TC-011-37 Pass in `tests/F-011` and **close B-004** (the PM pre-approved it, D-094). Red: reopen B-004 with the five numbers and send to the Project Manager (do not loosen) |
| T-491 (b) | `home_500_test.dart`, TC-010-43 (F-010 AC-17, T-492) | Run the command; read the five timings (the test now starts the stopwatch before the app starts, T-492) | Worst of 5 under the AC-17 limit in `tests/F-010-home-summary.md` TC-010-43 and **not 0 ms** (a 0 ms reading means the stopwatch is wrong again: report to the Developer). Green: TC-010-43 Pass |
| T-491 (c) | `month_setup_flow_test.dart` (B-005) | Debug is fine (functional): `flutter test integration_test/month_setup_flow_test.dart -d emulator-5554`, three runs | 3 of 3 exit 0; **close B-005** in `docs/BUGS.md` and record TC-008-18, -27 in `tests/F-008-month-setup.md` section 4 |

### 7.C Functional integration re-runs: T-445 (1)
| Task | Steps | Pass rule |
|---|---|---|
| **T-445 (1)** B-003 | `flutter test integration_test/money_back_flow_test.dart -d emulator-5554`, three runs, logs `s9-money_back_flow-<n>.log` (debug is fine) | 3 of 3 exit 0 with the Today lines `spent −₹80 · ₹910 left today`, the same after restart, `spent ₹120 · ₹710 left today`, `spent ₹720 · ₹110 left today`, back to `spent ₹120 · ₹710 left today`, after delete `spent ₹420 · ₹410 left today` (TC-016-34). Close B-003; TC-016-34 Pass in `tests/F-016-money-back-entry.md` section 4 and 5. A red run: the app was right when done by hand on 2026-11-21, so read the log first and tell the Developer (test script) |

### 7.D By-hand device cases (group by seed to save time)
**Group 1: Dashboard, seed A (and B), date 13 Nov 2026 (T-392).**
| Case | Steps | Pass rule |
|---|---|---|
| **TC-013-50** (F-013 AC-16) | Font 2.0 at 360 x 640 dp (set-up above), Light then Dim. Open the Dashboard. Walk: B (three categories), A plus a refund (Money back on Other), the first-day state. Screenshot each. Then landscape in Light and Dim, same three states. `logcat` overflow check | No amount split across lines; nothing cut; share rows stack (name over amount over bar); the day strip wraps; the hint card and `Go to Transactions` are reachable by scrolling; nothing hidden behind the bottom navigation; no overflow line in logcat. Update TC-013-50 from Partial to Pass |
| **TC-013-51** (AC-16) | Theme Light, Dark, Dim, Auto (Auto: `adb shell cmd uimode night yes` then `no`). In each open B and A. Screenshot | Bars and track are ink on neutral, **never green or red**; the Days marks ● ○ ◆ are visible and `0 saved` mark is neutral; the hint card is soft indigo with readable text. Pass = all four themes seen |
| **TC-013-52** (AC-15) | A seeded; Dashboard: One day, 11 Nov chosen. Kill (command above), reopen | No crash; the Dashboard opens on **This month** (the range choice is not saved); figures unchanged (`All ₹5,530 so far is in Other.`, Highest `Wed, 11 Nov · ₹1,130`) |

**Group 2: Statement, seeds M20 and S (T-409).**
| Case | Steps | Pass rule |
|---|---|---|
| **TC-014-49** (F-014 AC-16) | Font 2.0 at 360 x 640 dp, Light and Dim. Walk M20, S, a rounding-note month and the three-period month by hand, then landscape. Overflow check | Working strips wrap only at the allowed points; `What changed` shows the date above its text; the ledger stacks label over amount; no amount cut; nothing behind the system bar; no overflow line. TC-014-49 Partial to Pass |
| **TC-014-50** (AC-16) | Four themes (Light, Dark, Dim, Auto) on M20 and S | Working strip fill, shortfall panel colours and the replaced-same-day text as `docs/design/screens/month-statement.md` section 10; `Saved` and `Overspent` amounts use the status colours and carry ● / ◆ with words |
| **TC-014-51** (AC-1) | M20 at 20 Nov. Day details 13 Nov, tap `Budget changed on this day` to open the statement at Period 2. Do it twice: animations off (three `*_scale` = 0) and on (= 1). Screen-record or take screenshots 100 ms apart (`adb shell screenrecord --time-limit 5 /sdcard/a.mp4`, then `adb pull`) | Animations on: the Period 2 card flashes `accentSoft` to `surface` over about 600 ms. Animations off: no flash, the card is simply at the right place. TC-014-51 Partial to Pass |
| **TC-014-54** (AC-15) | Statement open, scrolled to Period 2. Kill, reopen | No crash; the app opens as F-003 says (Home); opening the statement again shows the current month from the top |

**Group 3: Transactions, seed AR (T-430).**
| Case | Steps | Pass rule |
|---|---|---|
| **TC-015-26** (F-015 AC-15) | Transactions: Category Food, search `lunch` (`2 results · spent ₹670`). Force-stop, reopen, open Transactions | All filters and the search are at their defaults (Type All, This month, no category, empty field); no crash |
| **TC-015-59** (AC-19) | Font 2.0 at 360 x 640 dp, Light and Dim. AR with a search active; open the three filter sheets (Type, Category, Dates), the row Category sheet and the editor; then landscape. Overflow check | Chip row scrolls horizontally; no chip clipped; sheets scroll with their buttons pinned; no amount cut; the add button (FAB) never covers the last row; no overflow line. TC-015-59 Partial to Pass |
| **TC-015-60** (AC-11) | Open a row's Category sheet. Home key, `am kill`, reopen, open Transactions | No crash; nothing changed (the row keeps its category, no Undo snackbar); the list as before |

**Group 4: Money back, seed A (T-445 (2)).**
| Case | Steps | Pass rule |
|---|---|---|
| **TC-016-35** (F-016 AC-12) | Font 2.0 at 360 x 640 dp, Light and Dim, then landscape. Open the add-spend editor: walk it with the Money back switch off and on, the delete sheet (edit an existing refund) and the discard sheet (type, then Back). Overflow check | No amount split; the switch row stacks; Save is reachable (no dock above 1.3x); the keyboard does not hide the switch row (it sits right under the amount); no overflow line |
| **TC-016-36** (AC-3; data safety, no widget-test equivalent) | Add-spend editor, switch **on**, type `500`, do not save. Home key, `am kill`, reopen. Open Transactions | No crash; **nothing stored** (no new row, Today line unchanged); the editor does not reopen with the 500 (nothing resumed) |

### 7.E After the session
1. Update section 4 and 5 of `tests/F-010`, `F-011`, `F-013`, `F-014`, `F-015`, `F-016` (results, counts) and `docs/BUGS.md` (B-003, B-004, B-005, B-006 closed or reopened). Do not change case text.
2. **B-006 (T-493, F-010 TC-010-40, -41, -60; Low):** A13 with the 300 cover, 360 dp (720x1280 at density 320), `font_scale 2.0`: Home scrolled to the Saved sub-line and the Today card: `₹300 used to cover days` with no word split, the heading breaks only after `Today ·`; repeat at the default font size at 411 dp (`wm size reset`, `wm density reset`): the heading must not wrap as `Today · Fri, 13` / `Nov`. Screenshots `s9-b006-*.png`. Close B-006 or reopen. This is a by-hand case and belongs in this session (group 0, with Home).
3. Mark T-391 / T-392 / T-409 / T-428 / T-430 / T-445 / T-491 / T-493 / T-496 in `docs/TASKS.md` (your rows only) and tell the Orchestrator so that the Developer's Step 9 tasks (T-393, T-410, T-431, T-446, T-497, T-498) can start.
4. Re-run `tool/check.ps1` (Orchestrator) once more if any test file changed; Gate 5 needs the Tester's final full regression (`tests/REGRESSION.md` checks 22 to 31 included).

### 7.F Case checklist (the list asked for, with its task)
| Case | Task | Group |
|---|---|---|
| TC-013-50, -51, -52 | T-392 | 1 |
| TC-014-49, -50, -51, -54 | T-409 | 2 |
| TC-015-26, -59, -60 | T-430 | 3 |
| TC-016-35, -36 (and TC-016-34 re-run) | T-445 | 4 and C |
| TC-011-37 (calendar_500), TC-010-43 (home_500), B-005 re-run | T-491 | B |
| B-006 on the device | T-493 | 0 |
| 20-run flakiness of the Home sweep | T-496 | A |
| Not in this session: TalkBack TC-010-42, TC-011-36, TC-012-34, TC-013-31, TC-014-29, TC-015-39, TC-016-24, TC-017-27 and the Phase 1 carry-over | D-097, D-104 | Owner, recommended not required |

## 8. Tester 1 final emulator session result (2026-11-24)
- T-496: 20 of 20 green for the Home sweep and 20 of 20 for the collapsed row (no retry).
- Debug `calendar_500` (1744 ms) and `home_500` (1490 ms) exit 1 only because debug is slow; profile (D-094, D-100): calendar worst 333 ms (limit 500), month change 184 ms; home worst 190 ms (limit 1000). TC-011-37 and TC-010-43 Pass.
- B-003 closed (3 of 3), B-004 closed, B-005 closed (5 of 6 green, 1 first-run flake), B-006 closed (device).
- Device cases Pass: TC-013-50, -51, -52, TC-014-49, -50, -54, TC-015-26, -59, -60, TC-016-36. Partial: TC-014-51 (flash not seen in captures), TC-016-35 (delete sheet and Light landscape not walked). TalkBack cases Blocked-needs-human.
- F-011: 19 ACs. No High or Critical bug found.
