# Code review, Phase 3 Tracks B and C (Gate 3)

Reviewer: Project Manager (reviewer 2), 2026-11-19. Scope: Track B = F-011 Calendar (T-320 to T-326) and F-012 Day details and cover with savings (T-340 to T-346); Track C = F-013 Dashboard (T-380, T-382 to T-385). Tracks A and D are reviewed by reviewer 1 in their own file.

Method: files read only. The orchestrator was running `tool/check.ps1` and a Developer was editing app code, so the reviewer ran no flutter, dart or check script. **Every approval below is conditional on that check run being green** (analyzer and `dart analyze --fatal-infos` clean, full suite, `tool/domain_coverage.ps1` 100 %, TZ matrix, and the F-003, F-004, F-007, F-009 re-run cases named in the plans). Reading cannot prove a test can fail; where the Developer gave no probe, that is said.

| Task | Verdict |
|---|---|
| T-320 calendar grid model | **Approved**, Ready for test |
| T-321 `formatRupeesShort` | **Approved**, Ready for test |
| T-322 month index | already Ready for test (Gate 3 2026-11-16), unchanged |
| T-323 `MonthBrowser`, `MonthSwitcher` | **Approved**, Ready for test (one stale note to fix, Nice to have) |
| T-324 cells and labels | **Approved**, Ready for test |
| T-325 calendar section | **Approved**, Ready for test (rubber band, range cross-fade: deviations accepted) |
| T-326 Home integration, sweeps | **Approved**, Ready for test (emulator test and T-454 stay open, see below) |
| T-340 pure day models | **Must fix** (probes, one money threshold in a screen), In progress |
| T-341 savings repository `cover()` / `removeCovers` | **Approved**, Ready for test |
| T-342 editor seam | **Approved**, Ready for test |
| T-343 day details screen | **Must fix** (change line wording and untested branches), In progress |
| T-344 cover card, sheet, Undo, Remove | **Must fix** (money threshold in the sheet, probes), In progress |
| T-345 navigation and Home integration | **Approved**, Ready for test |
| T-346 sweeps and emulator flow | **Approved**, Ready for test (emulator test not run, see below) |
| T-380 category read foundation | **Approved**, Ready for test |
| T-382 dashboard statistics (pure) | **Approved**, Ready for test |
| T-383 shared widgets | **Approved**, Ready for test |
| T-384 dashboard screen | **Must fix** (keep old content while loading), In progress |
| T-385 sweeps, speed, hand-over | stays **In progress** (list below) |

**Feature verdicts.** F-011 Calendar: **approved** (all of T-320 to T-326 Ready for test). F-012 Day details: **Must fix** on three small items (T-340, T-343, T-344), the rest approved. F-013 Dashboard: **Must fix** on T-384 (one item) and T-385 is not finished.

---

## Track B, F-011 Calendar

**Correct.**
- `CalendarGrid.of` builds Monday to Sunday weeks from `month.start` and `month.end`, outside cells are decorative, `isMonthFirstDay` is `date.day == 1 && date != monthStart` (D-075 (2): a month starting on the 1st shows plain `1`). Change days are the starts of non-superseded later periods, the same rule `DaySummary.of` uses, so a cell tick and the day-details line cannot disagree. Today's fill is the sign of the live result, plain `surface` when nothing is spent and no refund. Every money figure is the engine's (`result.dayOn`); the result words are the shared `DayResultKind` from the exact paise (D-050, D-055).
- `formatRupeesShort` follows D-073: under ₹10,000 it is `formatRupees`, then `k`, `L` with one decimal, whole `L`, `Cr` with one decimal, whole `Cr`; cut, never rounded; a trailing `.0` dropped; the sign kept with a word joiner; `₹99k`, `₹99L`, `₹12Cr` edge values fall out of the switch. Integer only.
- `calendarCellLabel` is pure and builds the full sentence with full amounts (`formatRupeesForSpeech`), never a short form. It covers upcoming, not budgeted (first month and late setup), today, refunds (`net ... after refunds`), covered (`covered from savings` when on budget, `after ... from savings` when still overspent), under-rupee words, and the change-day phrase.
- `DayCell`: 2 dp accent ring on today, hairline on upcoming, fills from tokens, mark and amount, tick for a change day, the amount is hidden above 1.3x text or when fitting it would go under the 9 sp floor (measured with `TextPainter` and the real font), the touch target is the cell plus its gap, and the not-budgeted cell is plain text for a screen reader with no press effect. Outside cells are excluded from semantics, so the order is header, arrows, legend, days (AC-17).
- Gutters 14 dp, pitch `(width - 24) / 7`, capped at 60 for landscape, rows `IntrinsicHeight` so large text grows cells (D-075 (4)).
- `CalendarSection`: the last loaded month stays on screen while the next loads (`_shown`), a missing month index gives `SizedBox.shrink`, the error is a neutral line with **Try again**, swipe and buttons share `_previous` and `_next`, the latest month follows new months (`view(null)`), and tapping uses a cooldown so a double tap opens one screen (TC-011-52). The range and the `Ended` tag come from the month index, so they do not wait for the grid.
- `MonthBrowser` (D-074): a `NotifierProvider.family` keyed by consumer, reset by `todayProvider`; `MonthBrowse` is pure (limits, gap jump); `monthBrowseProvider` joins it with the index. TC-011-65 and -66 exist in `month_browser_test.dart` (the T-323 note "TC-011-66 not written" is stale, fix the note).
- `MonthSwitcher` (design system 7.14) only draws and calls back; disabled arrows carry the reason as hint; **This month** appears on a past month.

**Deviations.**

| Deviation | Ruling |
|---|---|
| 16 dp rubber band at a swipe limit not built | **Accepted, not an AC.** AC-12 says swipe does the same as the buttons; the rubber band appears only in the design text (`calendar.md` swipe paragraph), plan T-325 and the expected result of TC-011-27. It also contradicts the design system motion rule "nothing bounces". Designer note (design change, shown to the Owner, not escalated): drop the rubber band, "a swipe at a limit does nothing"; Tester: reword TC-011-27 (the third swipe does not move, no month change; nothing to assert on a bounce). No code task. |
| Range text changes at once, no cross-fade of the range while a month loads | **Accepted, not an AC.** The grid does cross-fade with the 16 dp slide (`AnimatedSwitcher`, instant with Remove animations) and the old grid stays while loading, which is what AC-18 needs (no empty frame, speed). The range comes from the index immediately, which is also correct for a screen reader. Designer note: `calendar.md` line "the switcher range swaps text in the same fade" becomes "the range changes at once". |
| Amount hidden by a measured 9 sp floor | **Accepted** (the design system §7.5 asks for it; T-454 is the measurement). |
| Legend, hints test now five ids, TC-008-51 now checks "home tip gone" | Accepted (D-078 (2)). |

**Home calendar legend at 2.0x (83 px overflow on M20): resolved by reading, to be proved by the check run.** `calendar_legend.dart` was changed after Track C wrote its note (the file is newer than the Dashboard sweep): the items are a `Wrap` (spacing, run spacing) of `Row(min)` with a `Flexible` text, inside `Expanded`, and the (i) sits after the last item. A `Wrap` of flexible items cannot overflow horizontally. The calendar sweep `TC-011-34` includes `M20 six rows and a change day` (legend with the change item) at x2.0 in all four themes and in landscape, so the check run is the proof. The stale comment and the missing M20 state in the Dashboard sweep are a Track C Must fix (T-385, below).

**Tests.** Names carry TC IDs and match the Tester's case table (`calendar_grid_test.dart`, `money_format_short_test.dart`, `calendar_labels_test.dart`, `calendar_section_test.dart`, `month_browser_test.dart`). Swipe, tap, double tap, ring at midnight, live past-day edit, large text hiding amounts, the 9 sp floor, loading boxes without a rupee, the failing past month and the hint order each have a test. TC-011-27's file name in the Tester's table (`calendar_navigation_test.dart`) is not the real one; the Tester updates the file column. No probes are recorded for T-320 to T-326; the Tester's mutation pass covers `calendar_grid.dart` and `calendar_labels.dart` (Step 8).

**Not run, not blocking Gate 3.**
- `integration_test/calendar_500_test.dart` (TC-011-37) was written and analyses clean but never ran. A never-run emulator test can be wrong. The Tester runs it at Step 8 with the 500-spend seed; a failure is a bug. F-011 cannot be Done without a green log in `docs/reviews/emulator-phase-3/`.
- **T-454 stays To do (Nice to have, non-blocking).** The 9 sp rule is built and two amounts are proved (`₹9,999` at 1.0x, `₹1,130` at 1.3x). Still to measure at 360 dp, text 1.0 to 1.3x: `−₹9,999`, `₹99k`, `₹9.9L`, `−₹100Cr`. Either result is allowed by the design (hide the amount and tell the Designer), so no money display can be wrong; do it with the sweep and put the five numbers in plan F-011 section 11.

**Nice to have (follow-up task, one line each).**
- The header logic (`current`, `lastMonth`, `ended`) is written twice (`calendarViewProvider` and `CalendarSection.build`). The section needs it before the grid arrives, so it is acceptable; add one shared pure function when the Dashboard and the statement need it too.
- `calendar_labels.dart` flips the sign of the result (`result.value < 0 ? -result : result`); see the shared Nice to have under F-012.
- Fix the stale T-323 note (TC-011-66 exists).

---

## Track B, F-012 Day details and cover with savings

**Correct.**
- `DaySummary.of` holds every figure as exact paise and flags, and adds no money rule: the cover limit is `maxCover(pot, overspend)`, `limitedByPot` is `overspend > pot`, "offerable" is an overspent budgeted day, or today's live day with an overspend, in a month that has not ended (AC-4, AC-20). A past month, an upcoming day and a not-budgeted day get `CoverNone`. `canAddSpend`, `canRemoveCover` (not for a cover cut to ₹0, AC-22), `isFullyCovered` and `coverIds` (every stored row of the day, including ones cut to ₹0, so Remove deletes both moves) are right against AC-12, AC-21, AC-22.
- `validateCover` parses with the F-008 amount parser, and then asks the engine's `checkCover`, so the refusal order is the engine's (not positive, then overspend, then pot): AC-8 (d) and the "400 with pot ₹250 gets the overspend message" case follow without a second copy of the order. `tooLarge` is handled before the engine.
- Repository (T-341, D-078): `cover()` returns `({decision, coverId})` with the id only for `CoverAllowed`; `removeCovers(monthId, ids)` deletes inside one transaction, ignores unknown ids and ids of another month (a late Undo after Remove does nothing), and a write failure deletes nothing (`guarded`). The fake matches (`checkWrite`, `notify` only when something was removed). No schema change; F-007 stays Done. `cover_removal_test.dart` runs the same bodies on memory Drift and the fake (TC-007-49 to -52, TC-012-09, -43).
- Screen: the `DayDetailsView` is built from the engine's result and the spends; loading shows grey bars, never `₹0`; error has **Try again**; the back button returns to Home with the scroll kept (a pushed route). Refund rows read `Refund` as a subtitle; `Dated in the future` row; the period-start line opens `openMonthStatement(scrollToPeriodStart:)` through the launcher (D-077 (2)).
- Cover sheet: pre-filled with `amountInputText(offer.max)`, caption from `coverCaption` (overspend wins when equal), `_saving` is set before the first await so a double tap stores one move (AC-11), the engine decides again when Cover is tapped (stale amount refused with the matching message, TC-012-45), `coverId == null` (refused after all) keeps the sheet open.
- Undo removes exactly the cover just made (`removeCovers(month, {id})`), Remove deletes `day.coverIds`, `_writing` blocks a second run, failures show `StorageCopy.saveError`.
- Editor seam (T-342): `initialDate`, `openSpendEditor(date:, fromDay:)`, `SpendEditorResult.date`, `Spend moved to <day>` for an edit saved on another day only, an Add whose date was changed says `Spend added`. The discard check compares with the initial draft, so a preset date is not "input". Four seam tests; they do not close TC-012-18 or -22 (rule from `code-phase-3.md` T-389 item 4). The editor files are free for F-015 T-420.

**Deviations the Developer asked about.**

| Deviation | Ruling |
|---|---|
| Cover-save error shown inside the sheet, not as a snackbar | **Accepted.** A snackbar of the page's Scaffold sits under the sheet's scrim, so the user would not see it. AC-11 only asks that the F-007 save error is shown, the sheet stays open and the amount stays; the text is the same and it is a live region. Designer note (design change, shown to the Owner): `day-details.md` lines 78 and 87 say snackbar for the **sheet**; amend to "line under the field". Tester: reword TC-012-17 (the Remove failure TC-012-42 stays a snackbar because the Remove sheet has closed). |
| Undo snackbar `duration` 5.75 s, `persist` only when a screen reader is on | **Accepted, correct.** Flutter starts a snackbar's timer after its 250 ms entrance, so 5.75 s is gone 6 s after the cover (AC-21: "within 6 s"); a snackbar with an action persists by default, so `persist: false` is needed, and D-077 (5) keeps it for TalkBack. TC-012-38 proves both. Note in plan section 11 that a Flutter upgrade can change the 250 ms; the test will show it. |
| With the keyboard up on a short screen only **Cover** stays pinned, **Cancel** scrolls | **Accepted.** AC-19 says the keyboard never hides the amount field or **Cover**; Cancel is still reachable by scrolling and by the scrim and back (TC-012-54). TC-012-33 proves it. Designer note: `day-details.md` §6 "the buttons stay visible" becomes "Cover stays visible". |
| Count-up of the figures not built | **Accepted, not an AC** (day-details.md and design system 7.x describe it as polish; AC-2 to AC-6 name figures, not motion). Nice to have task: `motionCount` in the figures and the status line; the status line already cross-fades. If the Designer prefers, the line can be dropped from the design. |
| `Budget changed on this day` text written by the screen | **Money formatting, no arithmetic, so the layer is right in principle** (STANDARDS section 4: format at the UI layer; same pattern as `statement_text.dart`). But **Must fix**, see T-343 item 1: only the salary form is specified and tested; the other branches use wording that differs from the statement's for the same event. |
| Refund rows open the current spend editor until F-016 | **Accepted.** TC-012-58 says "after F-016". F-012 cannot be Done until F-016 T-442 lands and TC-012-58 is run; add that to the F-012 Done checklist (with D-077's F-014 wiring). |
| Repository tests in a new file `cover_removal_test.dart` | **Accepted** (the old file stays untouched and both repositories share one body). The Tester updates the two table cells (TC-012-09, -43) that name `savings_repository_test.dart`. |
| Integration test `day_details_cover_flow_test.dart` not run | **Not blocking Gate 3**; the Tester runs it at Step 8; no Done without a green log. TC-012-34 and -64 stay manual. |
| Probes missing for the day-summary and cover-draft unit tests, the cover-sheet validation, the property test and the sweeps | **Must fix for the money rules, Tester's pass for the sweeps.** These files hold the savings and cover limits (a wrong `maxCover` or a swapped refusal order moves real money in the pot). Coverage at 100 % is not proof that a test can fail. See T-340 item 2 and T-344 item 2. The sweeps (T-346) are checked by the Tester's mutation pass at Step 8. |

### T-340 Pure models: Must fix
1. **Must fix, small: the "under ₹1" threshold must not live in a screen.** `cover_sheet.dart` line 156 does `day.overspend.value < 100` to choose `coverLineUnderRupee`. That is a money rule (D-050, D-055: under ₹1 is under 100 paise) in a widget, and `dayResultKind` already holds it. Add `bool get overspendUnderRupee` to `DaySummary` (`overspend.isPositive && overspend.value < 100`, or reuse `dayResultKind(-overspend)`), unit test it in `day_summary_test.dart` (99, 100 paise), and use it in the sheet. Why: STANDARDS section 4 and plan F-012 section 1.1 ("no widget does money arithmetic"); a second copy of the 100-paise constant drifts.
2. **Must fix: probes.** Run and record in plan F-012 section 11 (as Track C did for T-382) reverted mutations that each make a test fail: `limitedByPot` flipped, `offerable` without `!isEnded`, `offerable` without the live-day branch, `canRemoveCover` without `!isEnded`, `isFullyCovered` without `result == zero`, `coverIds` skipping cut rows, `maxCover` returning the pot, the order of the refusals in `validateCover`, `> maxAmount` dropped, and, in `cover_property_test.dart`, a mutant that lets a cover exceed the pot. A mutant that survives is a missing test: add it.
3. Nice to have: `Paise.abs` or `DaySummary.resultMagnitude` for the three copies of "absolute value of the result" (`day_status.dart` twice, `calendar_labels.dart` once) and `DaySummary.refundsShown` for `-day.moneyIn`. Sign flips for display are used in Phase 2 screens too, so this is cleanup, not a blocker.

### T-343 Screen: Must fix
1. **Must fix: the `Budget changed on this day` line outside the salary case.** `_changeText` in `day_details_screen.dart` writes `salary ₹40,000 → ₹35,000` (the specified, tested case, AC-17) and invents wording for the rest: `spending target`, `money left`, `<cost name> ₹x → ₹y` (the same text for a fixed cost and for the amount still to pay of a mid-month cost), `<name> ₹x added`, `<name> removed`. The statement (F-014, D-081 (5)) already words the same events differently (`Gym ₹500 added` is `Fixed cost added: Gym ₹500`, `<name> changed`), so the Owner would read two wordings of one change. Fix: (a) move the text out of the screen into a small pure function next to `day_status.dart` with its strings in `DayDetailsCopy` (no literals in the widget); (b) reuse the statement's names and wording for the cases the Designer did not specify (`StatementCopy`: `Spending target`, `Money left`, `costChanged`, `fixedCostAdded`, `fixedCostRemoved`), lower-cased only where the sentence needs it, and ask the Designer to add the exact copy (Designer note below); (c) one unit test per branch (salary, target, money left, fixed cost changed, still to pay, added, removed, two changes joined with a comma), because today only the salary branch has a test. Why: untested branches in a screen, and a user-visible copy mismatch between two screens.
2. Nice to have: the figures `AnimatedSwitcher` and the count-up (see deviations).

### T-344 Cover card, sheet, Undo, Remove: Must fix
1. **Must fix, small:** the `value < 100` threshold (see T-340 item 1).
2. **Must fix: probes for the sheet.** Record reverted mutations that fail a test: the overspend and pot messages swapped, `_saving` guard removed (TC-012-16 must fail), `coverId == null` branch removed (TC-012-45), `persist` always true (TC-012-38), duration 6 s instead of 5.75 s (TC-012-38 must fail, proving the test measures the 6 s), `Remove` deleting only the first id (TC-012-39), `Keep it` deleting (TC-012-40). Put the list in plan F-012 section 11.
3. Nice to have: `_cover()` in the sheet validates twice and casts (`as CoverOk`). Use one `switch (validateCover(...)) { CoverNotOk(:problem) => ..., CoverOk(:amount) => ... }`; no cast, no second parse.

### T-341 Savings repository: Approved
As above. Interface change is additive, existing call sites use `.decision`, atomic delete is tested (TC-007-50 fails the second write and checks nothing changed). **Nice to have:** none.

### T-342 Editor seam: Approved
As above. Re-run list in plan F-012 section 8 must stay in the check run (F-009 cases TC-009-*). **Nice to have:** none.

### T-345 and T-346: Approved
`dayDetailsLauncherProvider` now pushes the real screen (the F-013 seam is closed); calendar cells and the Today card use it; back keeps the scroll (TC-012-02). Sweeps in `calendar_day_sweep_test.dart` cover calendar and day states, the cover sheet and its error, four themes x text 1 and 2 on the small phone, landscape in Light and Dim. The shared skeleton `phase3_screen_sweep_test.dart` is where the Tester's table points; the Developer's own file is acceptable (same helper, same checks), the Tester updates the file column.

---

## Track C, F-013 Dashboard

**Correct.**
- `SpendCategory` has the README order (ties, picker), keys, `fromKey` (null and an unknown key read as Other, never an error); `Spend.category` is nullable and the engine never reads it, so no money rule depends on it (engine untouched; the F-006 suite, domain coverage and the TZ matrix are in `tool/check.ps1`). The mapper keeps null as null and maps an unknown key to Other (TC-013-53, `spend_category_read_test.dart`).
- `categoryBreakdown`: integer only (`amount * 100 ~/ gross`, `amount * 1000 ~/ gross`; ₹10 crore x 31 days is 3.1 x 10^11 paise times 1000, exact), ranked by amount then README order, `<1%` flag, bar permille is the exact share (D-080 (4)), rounding note only for several categories whose shown percents do not sum to 100, refunds and net as separate fields (AC-7). The shown 70, 18, 11 of example B sum to 99, so the note shows; 500 Food and 500 Travel give 50 and 50, no note.
- `monthFigures`: only ended days (saved, on budget, overspent), today leaves until midnight (D-080 (1)), the earliest date wins a tie and `moreDays` counts the rest, the highest day is null when no ended day has a net above ₹0 (D-080 (2)), the average is `sum ~/ ended` (toward zero, D-046; ₹638 of 63,875 paise, ₹66 of 6,666), covers count ended days with any cover above ₹0 (D-080 (3)). The tie counter only matters when a highest day exists, as its comment says.
- `dashboardViewProvider` is a sealed view (`NoMonthDashboard`, `MonthDashboard`), built on the existing providers, with a `NewMonthDue` month shown as `Last month`, the picker limits from `spendDateLimits` (one rule), the day clamped into the limits, a past month defaulting to its last day, and the header starting at the first budgeted day (`10 Nov – 4 Dec 2026` for a mid-month start, AC-12). The screen is an exhaustive `switch`; no figure is computed in a widget except layout fractions of integer permille.
- `SegmentedControl`, `ShareBarRow`, `LedgerRow`: tokens, check mark plus weight as the non-colour cue, bar excluded from semantics and the row read as one sentence (`Shopping, ₹1,000, 18 percent`), rows stack above 1.3x text, the bar grows over `motionBase` (instant with Remove animations) and is never green, red or accent. Help via the shared `InfoButton` and `LabelDescription`.
- Links: `Go to Transactions` only switches the tab through `selectedTabProvider` (D-080 (7)); the highest day opens Day details for that day (read-only for a past month); the statement row opens `openMonthStatement`.

**Deviations.**

| Deviation | Ruling |
|---|---|
| One `dashboardSelectionProvider` (range, month, day) instead of three | **Accepted.** One record, one reset rule (`selectMonth` resets only the day; `One day` stays, D-080 (6) and design B-9), fewer providers to keep in step. Plan section 5 and the files table name three; the Developer's note in section 11 is the record. Nice to have: F-013 uses its own `monthId` instead of `monthBrowserProvider('dashboard')` (D-074), so the viewed month is not reset at midnight like the calendar's. The plan itself (point 4) kept a Dashboard month provider, so this is not a deviation from the approved plan; align it when F-014 and F-015 adopt `monthBrowserProvider`, and record one rule. |
| Segmented control 48 dp tall (design 44 dp track with a 48 dp target) | **Accepted.** STANDARDS section 7 says touch targets at least 48 dp; the accessibility guideline measures the semantic node, so a 44 dp node fails it. Designer note (design change, shown to the Owner): `design-system.md` 7.15 and `dashboard.md` become 48 dp. |
| Sweep in `test/features/dashboard/dashboard_sweep_test.dart`, not the shared a11y file | **Accepted** (the 16 states x 5 theme cases x 1.0 and 2.0 loop is long and has its own timeout). The Tester updates the TC-013-28 file column; the test name `TC-013-28 ...` is right. |
| Header text inside one month `1 – 30 Nov 2026` | Accepted (the calendar's form). |
| AC-15 live proof through the F-015 flow waits for F-015 T-423 | **Accepted, stays open in T-385.** The widget proofs TC-013-26 and -27 change data through the fake store and show the update without a refresh; the cross-feature proof needs F-015. F-013 cannot be Done before it. |
| TC-013-32 (500 spends in 9 categories, under 500 ms) not run | **Not blocking Gate 3**; the Tester runs `integration_test/dashboard_500_test.dart` at Step 8; no Done without a green log. |
| AC-17 keep old content while a month changes: "still open" | **Must fix.** Read below. (Note: the doc's AC-17 is only the 500 ms speed; the keep-old-content rule is in the approved design, `dashboard.md` section 8, "Month change keeps the old content until the new month is ready", confirmed at Gate 2, D-087.) |

### T-380, T-382, T-383: Approved
- T-380: no engine change, mapper reads the column, copy and icons separate from logic. **Nice to have:** none.
- T-382: the strongest of the three. The Developer recorded 9 reverted mutations that failed tests and simplified the tenth (an equivalent mutant), 100 % lines and branches, integer-only check in `domain_layering_test.dart` (TC-013-24), a property test against `computeMonth`, ten crore x 31 days. **Nice to have:** `categoryBreakdown` divides by `gross`, which is positive whenever a row exists because a stored spend is always above ₹0 (F-009 validation); a one-line comment saying so removes the next reader's doubt.
- T-383: widgets are tokens-only, labelled, and tested in four themes at 2.0x. No probes were recorded for the widgets; the Tester's mutation pass covers them. **Nice to have:** the day words `saved`, `on budget`, `overspent` in `numbers_card.dart` are literals in the widget; move them to `DashboardCopy` (the copy table test then sees them).

### T-384 Dashboard screen: Must fix
1. **Must fix: keep the old content while the next month loads** (approved design section 8, Developer's own "still open" item 1). Today `dashboardViewProvider` returns `AsyncLoading` while `storedMonthProvider(chosen)`, the month's spends or its result are loading, and `DashboardTab` then draws the placeholder bars in place of the whole page, so every first visit to a month flashes the skeleton and the header. The calendar already does this right (`_shown`). Fix: keep the last `MonthDashboard` in the tab (a field in a small `ConsumerStatefulWidget`, as `CalendarSection` does) or in the provider, and show it, with the header already on the new range, until the new view arrives; the skeleton is only for the very first load. Add one test (hold the new month's read with `delayReadsOf`, expect the old category rows still on screen, no `₹0`, no placeholder, then the new rows after release). Why: AC-17 speed is measured to "final figures", and a flash of placeholders during a 50 ms read is jarring; the design promised no empty frame.
2. **Nice to have:** the plan's `dashboardMonthProvider` vs `monthBrowserProvider('dashboard')` (see deviations).
3. Plan F-013 section 11 deviations 1 and 2 are out of date ("seam still open", "no-op default"); rewrite them to what is built (the switcher is wired, the launcher pushes the real screen), so the Done checklist is true.

### T-385 Sweeps, speed, hand-over: stays In progress
Done: the 16-state sweep (1.0 and 2.0, scrolled to the end, landscape in Light and Dim) and TC-013-50 row stacking. What remains, exact:
1. **Must fix: put M20 back into the Dashboard sweep and delete the stale comment** (lines 102 to 104 of `dashboard_sweep_test.dart`: "M20 is left out ... overflows its calendar legend"). The legend is a `Wrap` now; if M20 at 2.0x still overflows the Home tab behind the Dashboard, that is a Track B bug to report, not a reason to skip the state. This is also the proof for the legend question above.
2. Run `dashboard_500_test.dart` (TC-013-32) on the emulator, log in `docs/reviews/emulator-phase-3/` (or hand to the Tester with the instruction above).
3. AC-15 live proof through the F-015 flow, after F-015 T-423.
4. The F-003 and F-004 case list for the Tester's regression (the Dashboard replaced the placeholder tab; TC-003-*, TC-004-* that read the Dashboard tab).
5. Record the probes of T-383 only if the Developer wants them early; otherwise the Tester's pass.

TC-013-31 (TalkBack on the emulator) and TC-013-50, -51, -52 stay manual (Tester, Step 8).

---

## Must fix list (exact text for the Developer)

**Track B (back to In progress: T-340, T-343, T-344)**
1. `DaySummary.overspendUnderRupee` (unit tested at 99 and 100 paise) replaces `day.overspend.value < 100` in `cover_sheet.dart` (T-340, T-344).
2. Record the probe mutations listed in T-340 item 2 and T-344 item 2 in plan F-012 section 11; add a test for any mutant that survives.
3. Move `_changeText` out of `day_details_screen.dart` into a pure function with its strings in `DayDetailsCopy`; reuse the statement's wording for target, money left, fixed cost changed, still to pay, added and removed; one unit test per branch (T-343 item 1).

**Track C (T-384 back to In progress; T-385 stays In progress)**
4. T-384: keep the old content while the next month loads, with one test.
5. T-385: re-add M20 to the Dashboard sweep and delete the stale comment.
6. Plan F-013 section 11 deviations 1 and 2 rewritten to the built state.

## Nice to have (follow-up tasks, none blocks)
- T-454: measure the four remaining amounts (non-blocking).
- Count-up of the figures (`motionCount`) in day details, or the Designer drops it.
- Shared `Paise.abs` / `refundsShown` for sign flips in screens; day words in `DashboardCopy`.
- `calendarViewProvider` and the section share one header function; `monthBrowserProvider('dashboard')` for F-013 (and F-014, F-015) with one midnight rule.
- Stale notes: T-323 (TC-011-66 exists).

## For the Designer (design changes, shown to the Owner as previews, not escalated)
1. `calendar.md` swipe paragraph: no rubber band, a swipe at a limit does nothing; the range changes at once (the grid still cross-fades). Aligns with "nothing bounces".
2. `day-details.md` (cover sheet): save failure is a line under the field inside the sheet (a snackbar would be hidden by the scrim); with the keyboard up on a short screen only **Cover** stays pinned.
3. `day-details.md`: exact wording of the `Budget changed on this day` line for target, money left, a fixed cost changed, the still-to-pay amount, added and removed (today only salary is specified); same wording family as the statement.
4. `design-system.md` 7.15 and `dashboard.md`: segmented control is 48 dp tall.
5. Day details count-up: keep as a Nice to have or drop.

## For the Tester
- Reword TC-011-27 (no rubber band) and TC-012-17 (error inside the sheet); fix the file columns (TC-011-27, TC-012-09, -43, TC-013-28, TC-012-30 and TC-011-34 sweep locations); mutation pass at Step 8 for `calendar_grid.dart`, `calendar_labels.dart`, the sweeps and the Track C widgets.
- Run at Step 8: `calendar_500_test.dart`, `day_details_cover_flow_test.dart`, `dashboard_500_test.dart`; none of the three has run. F-011, F-012 and F-013 are not Done without green logs. F-012 also waits for TC-012-58 (after F-016) and the F-014 wiring (D-077).

## For the Owner
Nothing needs a decision. No money rule, calculation or displayed figure changes in any ruling above: the Dashboard and day details only show the engine's numbers, and the one rule at issue (the under-₹1 words) is the Owner's own D-050 and D-055, only moved to the domain layer. The design changes in the list above are shown as previews, not escalated.
