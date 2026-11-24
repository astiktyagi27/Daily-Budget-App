# Plan — F-011: Calendar

| | |
|---|---|
| **Feature doc** | [`docs/features/F-011-calendar.md`](../docs/features/F-011-calendar.md) (final spec, 19 ACs) |
| **Test cases** | [`tests/F-011-calendar.md`](../tests/F-011-calendar.md) (written 2026-11-16, TC-011-01 to TC-011-58, authoritative; section 6 re-mapped at Gate 1) |
| **Design** | `docs/design/screens/calendar.md`, design system §7.5 (day cell), §7.14 (month switcher), §4.3 |
| **Inputs** | D-034, D-036, D-037, D-038, D-039, D-046, D-047, D-048, D-050, D-055, D-057, D-059; F-006/F-007/F-008 as built; sibling plans F-010, F-012 |
| **Author** | Developer 1 |
| **Status** | Plan approved (Gate 1, 2026-11-16, Project Manager A; see section 10) |

## 1. Approach
The calendar is a view over `MonthResult` (`days`, `periods`, `totals`), so it adds **no money rule**. Three layers:

1. **Pure model, `domain/budget/calendar_grid.dart`.** `CalendarGrid.of(MonthResult)` returns weeks (Monday to Sunday) of `CalendarCell`s:
   - `kind`: `outside`, `notBudgeted`, `upcoming`, `today`, `saved`, `onBudget`, `overspent`, from the engine's `DayStatus` (`live` is `today`; its fill comes from the sign of `result`, and "nothing spent yet" gives a plain `surface` fill: `todayFill` enum);
   - `date`, `isMonthFirstDay` (the number reads `1 Dec` when the 1st of a calendar month is not the budget month's first day), `netSpent`, `result`, `covered`, `resultKind` (saved, saved under ₹1, on budget, overspent, overspent under ₹1: same five words as `TodayResultKind`, D-050/D-055), `isChangeDay`;
   - `isChangeDay` = the start of a non-superseded period other than the first non-superseded one (a same-day replaced change gives no second tick, AC-8);
   - leading and trailing `outside` cells so the grid starts on the Monday of the first day's week and ends on the Sunday of the last day's week (4 to 6 rows), pure integer weekday maths from `CalendarDate` (the weekday formula in `date_format.dart` is reused by moving `_weekdayIndex` to a public `CalendarDate.weekdayIndex`; it is already pure).
   A covered day needs no special case: the engine's `result` already includes covers, so fully covered is `onBudget` and partly covered stays `overspent`, and `covered` feeds the label (AC-6).
2. **Labels and short forms in the UI layer, never in the model.**
   - `formatRupeesShort(Paise)` is added to `core/format/money_format.dart` (design system §7.5: below ₹10,000 full; ₹10,000 to ₹99,999 `₹12k`; ₹1,00,000 to ₹99,99,999 `₹1.5L` with one decimal and a dropped `.0`; ₹1 crore and above `₹10Cr`; all rounded toward zero, integers and `~/` only; sign and no-`−₹0` rules reused from `formatRupees`). The money-format architecture test already bans `/`, `double` and `num` in that file.
   - `calendar_labels.dart` (in `features/home/calendar/`) builds the screen-reader sentence per cell from the cell and `formatRupeesForSpeech`, with all words in `core/copy/calendar_copy.dart` (F-011 §5). It is a pure function, unit-tested against the §2.3 table.
3. **Providers and widgets.**
   - **A month index.** The calendar must know which months exist (missed months leave gaps, `‹` jumps from Dec to Sep). `MonthRepository` has no list of months, so one small read is added: `Stream<List<MonthRef>> watchMonthIndex()` returning `({int id, BudgetMonth month, CalendarDate firstBudgetedDay})`, newest first, from `budget_months` only (no periods, no fixed costs). Drift implementation and the in-memory fake both added (F-007 stays "Done", this is an additive read; see §8).
   - `calendarMonthProvider`: a `Notifier<int?>` holding the viewed month id (null = the current/latest month). It resets to null when `todayProvider` changes day (calendar "always reopens on the current month after midnight", design §6.5) and keeps the choice across tab switches (the provider lives in the `ProviderScope`).
   - `calendarViewProvider`: `AsyncValue<CalendarView>` = `{result, grid, isLatest, isEnded, canGoBack, canGoForward, headerKind (current | ended | lastMonth), hasNotBudgeted}`, built from the index and `monthResultProvider(id)`. For the new-month-due state it targets `lastMonth.id` and `headerKind = lastMonth`.
   - `MonthSwitcher` is a **core** widget (`core/widgets/month_switcher.dart`, design system §7.14), because F-013 and F-014 reuse it. It takes the range text, tag, `This month` action, previous/next callbacks and their disabled hints; its ‹ › use `BudgetIconButton`.
   - `CalendarSection` (`features/home/calendar/`) = switcher + hint host + legend with (i) + weekday strip + grid + caption, with swipe (`GestureDetector.onHorizontalDragEnd`, velocity threshold; a 16 dp rubber band at the limits) and a `motionBase` cross-fade with a 16 dp slide (`AnimatedSwitcher`, instant with Remove animations). While the next month loads the old grid stays (no empty frame, AC-18).
   - `DayCell`: square (`AspectRatio`), width from the Home content width, capped at 56 dp and centred in landscape, 48 dp minimum touch target, `FittedBox(scaleDown)` for the amount (never an ellipsis), the number capped at 1.3x through `MediaQuery.withClampedTextScaling`, the amount hidden above 1.3x while the label keeps it (AC-16), marks drawn with `CustomPaint` (● ○ ◆) and the change tick (12 x 3 dp, `accent`, top centre). Cells are rows of `Expanded` in a `Column` (at most 42 cells), not a lazy grid.
   - Tapping a cell calls `openDayDetails(context, monthId, date)` (F-012). `outside` and `notBudgeted` cells have no `InkWell` and are excluded from semantics; `upcoming` cells are buttons that open the upcoming form (AC-13).
4. **First-time hint.** New `HintId.calendar('calendar.v1')` and `HelpCopy.hintCalendar` (`Tap a day to see its spends.`), shown above the calendar only when `hint.home.v1` has been dismissed (design H-7, so a screen never shows two tips). `FirstTimeHint.textFor` gets the new case. This is the one change outside Home; it touches F-004 (§8, §9 Q4).
5. **No new money rule.** The only "display" additions are the short forms (§9 Q2, flagged for the PM and possibly the Owner).

## 2. Files / modules
| Path | Add / Change | What |
|---|---|---|
| `app/lib/domain/budget/calendar_grid.dart` | Add | `CalendarGrid`, `CalendarCell`, `CellKind`, `ResultKind`, `TodayFill` |
| `app/lib/domain/budget/calendar_date.dart` | Change | public `weekdayIndex` (Monday = 0), moved from `date_format.dart`'s private helper |
| `app/lib/domain/budget/budget.dart` | Change | export `calendar_grid.dart` |
| `app/lib/core/format/money_format.dart` | Change | `formatRupeesShort` |
| `app/lib/core/format/date_format.dart` | Change | use `CalendarDate.weekdayIndex` |
| `app/lib/data/repositories/month_repository.dart`, `drift_month_repository.dart` | Change | `watchMonthIndex()` + `MonthRef` |
| `app/test/helpers/fake_month_repository.dart` | Change | `watchMonthIndex()` on the fake store |
| `app/lib/core/providers/calendar_providers.dart` | Add | `calendarMonthProvider`, `calendarViewProvider`, `monthIndexProvider` |
| `app/lib/core/widgets/month_switcher.dart` | Add | shared switcher (design system §7.14) |
| `app/lib/features/home/calendar/calendar_section.dart`, `day_cell.dart`, `calendar_grid_view.dart`, `calendar_legend.dart`, `calendar_labels.dart`, `calendar_marks.dart` | Add | UI |
| `app/lib/core/copy/calendar_copy.dart` | Add | F-011 §5 / calendar.md copy and speech sentences |
| `app/lib/domain/preferences/hint_id.dart`, `core/help/first_time_hint.dart`, `core/copy/help_copy.dart` | Change | `calendar.v1` hint |
| `app/lib/features/home/home_tab.dart` | Change | hosts `CalendarSection` (F-010 T-305 owns the file) |
| `app/test/domain/budget/calendar_grid_test.dart` | Add | `TC-011-NN` grids (§2 examples), states, change tick, not-budgeted |
| `app/test/core/format/money_format_short_test.dart` | Add | AC-11 forms and boundaries |
| `app/test/features/home/calendar_*_test.dart` | Add | widget tests: cells, labels, navigation, swipe, sweeps, grey-scale |
| `app/test/data/repositories/month_index_test.dart` | Add | `watchMonthIndex` on memory Drift and the fake |
| `app/integration_test/calendar_500_test.dart` | Add | 500 spends: grid and month change within 500 ms (AC-18) |

## 3. Data model / database changes
No schema change. One new **read** query on `budget_months` ordered by `start_day` descending, selecting `id`, `start_day`, `end_day`, `salary_day`, `first_budgeted_day`. It watches that table only. Past months' details come from the existing `monthResultProvider(id)` family.

## 4. Packages (latest stable, checked on pub.dev)
| Package | Version | Why |
|---|---|---|
| — | — | None new. No calendar package: the grid is 42 simple cells and the design is custom |

## 5. Tasks
IDs confirmed by the Project Manager at Gate 1 (2026-11-16); the board is `docs/TASKS.md`.

| ID | Task | Covers AC | Depends on | Status |
|---|---|---|---|---|
| T-320 | **Pure grid model.** `CalendarGrid`, `CalendarDate.weekdayIndex`; tests for all grids: salary day 5 (35 cells, 2 to 4 Nov and 5 to 6 Dec outside), Feb 2027 (4 rows), 31 Jan to 27 Feb 2027 (6 outside first), 30 Jan to 28 Feb 2028 (30 days, no 29 Feb) and 29 Feb to 29 Mar 2028 (the leap day is the first budget cell, D-075), 25 Dec to 24 Jan, 6-row months; cell kinds for examples A, S, M, F; covered and partly covered; refund days; under-₹1 kinds (₹830.50, ₹829.50, ₹0.40); change tick only on 13 Nov; upcoming and live; clock moved back; 100% branches | AC-1 to 3, 5 (model), 6, 7, 8, 9, 10, 19 (model) | F-006 | To do |
| T-321 | **`formatRupeesShort`** with the boundary table (9,999 / 10,000 / 12,999 / 99,999 / 1,00,000 / 1,59,999 / 99,99,999 / 1,00,00,000 / 10,00,00,000, negatives, `.0` dropped, no `−₹0`; expected values are the design system section 7.5 table: `₹99L`, `₹12Cr`, `₹1L`, `₹1Cr`, `₹99k`, `−₹12k`, D-073) | AC-11 | T-309 | To do |
| T-322 | **Month index.** `MonthRef`, `watchMonthIndex` (Drift + fake), memory-Drift test and fake test, read-failure path | AC-12 (data), AC-14 | F-007, T-309 (new `watchMonthIndex` cases) | Code review |
| T-323 | **Providers and shared month browsing (D-074).** `MonthBrowser` (core provider family keyed by consumer, the generalised `calendarMonthProvider`, reset at midnight; F-013, F-014 and F-015 use it), the core `MonthSwitcher` widget (design system section 7.14; moved here from T-325 so the other features can start), `calendarViewProvider` (current, ended, last-month states; `canGoBack` false on the first stored month), keep-old-while-loading | AC-12, AC-14, AC-18 | T-320, T-322, F-010 T-301, T-308 | To do |
| T-324 | **Cells and labels.** `DayCell`, marks, change tick, ring, fills per theme, `calendar_labels.dart` against the §2.3 table including the covered, refund, today, upcoming, not-budgeted and under-₹1 sentences (`minus` for negatives), amount hidden above 1.3x, press scale | AC-3, 4, 5, 6, 7, 8, 9, 10, 11, 16, 17, 19 | T-320, T-321, T-310 (weekday label and gutters), T-313 (Gate 2) | To do |
| T-325 | **Section.** legend with (i) (and `▬ Budget changed` when the month has a change), weekday strip, not-budgeted caption, swipe and rubber band, transition, loading grid (hairline boxes, never `₹0`), past-month error with **Try again**, `hint.calendar.v1` (HintId, copy, `FirstTimeHint.textFor`), tap to `openDayDetails` | AC-1, 12, 13, 14, 15, 17 | T-323, T-324, F-012 T-345 | To do |
| T-326 | **Home integration and sweeps.** Placed in `HomeTab` (F-010 T-305); live-update test (a past-day edit updates its cell, AC-15); four themes x 1.0, 1.3 and 2.0 x small phone and landscape 640x360 (48 dp targets, cell cap 56 dp), grey-scale compare, TalkBack order (header, ‹, ›, legend (i), days); `integration_test/calendar_500_test.dart` | AC-4, 15, 16, 17, 18 | T-325, F-010 T-305 | To do |

## 6. Acceptance criteria coverage
Test case IDs are the Tester's (`tests/F-011-calendar.md`, section 2.4), re-mapped by the Project Manager at Gate 1 on 2026-11-16. The earlier proposed slots are retired. Edge cases of the doc section 4: year crossing TC-011-40, 6-row months TC-011-02 and -41, today the last day -42, missed months -43, device date back -44, 50+ spends -47, 40 paise -48, late setup -21, less than 1 rupee -38. The `watchMonthIndex` read has no AC; its cases are added by the Tester (T-309, TC-011-59 and up).

| AC | Built in task | Proved by test cases (Tester IDs) |
|---|---|---|
| AC-1 Month range and grid | T-320, T-325 | TC-011-01, -02, -39, -40, -41, -53 |
| AC-2 Month-length grids (Feb, 31 Jan, leap day) | T-320 | TC-011-03, -04, -05, -06, -07, -39 |
| AC-3 Cell states, example A, labels | T-320, T-324 | TC-011-08, -09, -10, -45, -46, -47, -48, -49, -54, -55 |
| AC-4 Not colour alone (grey-scale) | T-324, T-326 | TC-011-11, -12 |
| AC-5 Today ring and midnight | T-320, T-324, T-326 | TC-011-13, -44, -57 |
| AC-6 Covered days | T-320, T-324 (cover through the UI needs F-012; also seeded through the fake) | TC-011-14, -15 |
| AC-7 Shortfall month | T-320, T-324 | TC-011-16 |
| AC-8 Mid-month change and tick | T-320, T-324 | TC-011-17, -18, -19 |
| AC-9 Mid-month first month | T-320, T-324 | TC-011-20, -21 |
| AC-10 Refund days | T-320, T-324 | TC-011-22 |
| AC-11 Short forms | T-321, T-324 | TC-011-23, -24 |
| AC-12 Past months, previous and next, swipe | T-322, T-323, T-325 | TC-011-25, -26, -27, -42, -43, -50, -51 (+ T-309 index cases) |
| AC-13 Tap opens details | T-325 | TC-011-28, -52 |
| AC-14 New month not set up | T-322, T-323, T-325 | TC-011-29 |
| AC-15 Live updates | T-326 | TC-011-30, -58 |
| AC-16 Large text and landscape | T-324, T-326 | TC-011-31, -32, -33, -34, -56 |
| AC-17 Screen-reader order | T-324, T-325, T-326 | TC-011-35, -36 |
| AC-18 Speed (500 spends, 500 ms) | T-323, T-326 | TC-011-37 |
| AC-19 Less than 1 rupee | T-320, T-324 | TC-011-38 |

## 7. Edge cases & risks
| Case / risk | How it is handled |
|---|---|
| Salary day 29 to 31, leap years, year crossing | `BudgetMonth` (F-006) gives the range; the grid test covers 29 Feb and 25 Dec to 24 Jan (`1 Jan` cell) |
| 6-row months | Grid grows; Home scrolls; nothing clipped |
| Missed months | The index only holds real months, so ‹ jumps Dec to Sep, header shows real dates |
| First stored month | ‹ disabled, hint `No earlier months` |
| New month not set up | Calendar targets `lastMonth.id`, header `Last month · …`, › disabled with hint `This is the latest month`, no `Ended` tag |
| Day with 50+ spends | Cell shows the total only |
| Future-dated spends (clock set back) | Engine ignores them; upcoming cells show no amount (F-006 AC-13); F-012 lists them |
| ₹0.40 spent | Cell `₹0`, label `saved ₹829` (D-038); under-₹1 labels per D-050/D-055 and never `overspent ₹0`, `saved ₹0` or `−₹0` |
| Amounts up to ₹10 crore | `₹10Cr` short form; full amount in the label and F-012 |
| Text 2.0x | Number and mark only; amount in the label (the one thing on Home that does not scale, design §10) |
| Risk: month change slower than 500 ms | Keep-old-grid-until-ready hides the wait; `monthInputProvider` opens three streams per month. If measured over 500 ms, the previous month is warmed with `ref.listen` after the grid shows. The provider families are not auto-disposed (existing F-009 behaviour), so visited months stay in memory: tiny, but note it |
| Risk: swipe fights vertical scroll | Horizontal drag only with a velocity threshold; the buttons stay for accessibility |
| Risk: cell colours fail contrast in a theme | Design pairs are in design system §3; the F-002 AC-12 to AC-14 contrast sweep runs on the cell fills x number and amount colours |
| Risk: `home_tab.dart` conflicts with F-010 | F-010 T-305 owns the file; T-326 lands after it |

## 8. Impact on existing features
- **F-007:** additive read `watchMonthIndex` on `MonthRepository` (+ fake). Re-run **TC-007-11, -12** (live updates), the repository suites and the fake-parity tests. F-007 is Done, so this needs the PM's approval as a follow-up task, not a redesign.
- **F-004:** a fifth `HintId`. `test/core/help/hints_test.dart` asserts exactly 4 ids and their storage keys (TC-004-09, -10, and the id/keys test): update with the Tester. The preference allow-list is built from `PreferenceKeys.hintSeen`, so the new key is covered; re-run **TC-004-09, -10, -11, -12, -14, -15** and the storage allow-list test. F-004 doc §5 and `help-pattern.md` §4.2 need the new tip row (design note 14.1, PM to ask the Designer/Product Manager).
- **F-006:** `CalendarDate.weekdayIndex` public, no behaviour change. Re-run TC-006 calendar-date cases and the time-zone matrix; the new pure file must keep `tool/domain_coverage.ps1` at 100%.
- **F-008 / F-009:** none directly. `date_format.dart` helper moved: re-run the date label tests (TC-008 date formatting, TC-009 headings).
- **F-010:** hosts the section. **F-012:** receives taps. **F-013/F-014:** reuse `MonthSwitcher`.
- **F-002:** day-cell states and the tick are design-system §7.5 additions (Designer's Gate 2). Re-run the token and contrast guards.
- Re-run: full suite, `tool/check.ps1`, `tests/REGRESSION.md`, F-001…F-009 Regression-yes cases.

## 9. Open questions
1. **Project Manager (open item 7, Designer):** design-system §7.5 additions (not-budgeted cell, change marker, short forms) are written in the design system and `calendar.md`; confirm Gate 2 covers them before T-324.
2. **Project Manager / possible Owner decision:** the **short money forms** `₹12k`, `₹1.5L`, `₹10Cr` change how an amount is *displayed* (D-038 says whole rupees, full grouping). There is no D-number for them. WORKFLOW lists "any change to how money is calculated or displayed" under Escalate to Owner. Marked **Owner decision?** The plan keeps it in one function, `formatRupeesShort`, so dropping it (for example hiding amounts over ₹9,999 in cells) is a one-file change. Please decide before T-321.
3. **Project Manager (open item 5, editor sequencing):** the calendar does not edit spends; see `plans/F-012-day-details.md` §9.
4. **Project Manager:** the new `hint.calendar.v1` and the F-004 test updates (§8). OK to include in T-325, with the Tester updating TC-004-09/-10?
5. **Project Manager:** `watchMonthIndex` is an additive change to the Done F-007 repository (§1.3, §8). Approve as part of T-322, or have it assigned to a F-007 follow-up task.
6. **Project Manager:** "how far back" is already decided (back to the first stored month). Past months are read-only (F-011 §6); editing past months is a suggested addition that raises a money-rule question and goes to the Owner later, not in this plan.
7. **Owner decision needed otherwise?** No: no permission, no network, no new money calculation.
8. **Open item 6 (savings repository delete):** not used by the calendar.

## 10. Project Manager review *(Gate 1 — cross-check of doc + plan + test cases)*
**Verdict:** **Approved** (Project Manager A, 2026-11-16). Must fix points 1 to 6 are done by PM edits or assigned (T-309, T-310, T-313); T-321 and T-322 start after T-309, T-324 after T-310 and T-313. Decisions D-073 to D-079. The Owner has already approved the short money forms (D-073); nothing else needs the Owner. Build track: F-011 and F-012 together (D-033).

Cross-check:
- [x] Every AC in the feature doc is covered by a task in this plan (19 of 19, section 6)
- [x] Every AC has at least one test case in the test file (19 of 19, tests section 2.4)
- [x] Edge cases in the doc appear in both the plan and the test cases
- [x] Approach follows `docs/STANDARDS.md` (pure grid model in `domain/`, integer paise, short forms in one function, UI through providers, no calendar package)
- [x] Latest stable versions / modern APIs used (no new package; Dart 3 sealed types)

Money rules D-034 to D-062 and D-069 to D-072: untouched. Cells show the engine's day results; the short forms are display only and are Owner-approved (D-073).

**Shared month browsing (D-074).** F-011 owns it for F-011, F-013, F-014 and F-015: `MonthRepository.watchMonthIndex` (T-322), the core `MonthSwitcher` widget and `MonthBrowser` (T-323; the plan's `calendarMonthProvider` and `monthIndexProvider` become this shared pair, one instance per consumer so each screen remembers its own viewed month and resets at midnight). The F-013, F-014 and F-015 plans must use them and not write their own month index or switcher. T-322 and T-323 are the first F-011 tasks to land.

| # | Point | Type | Resolution |
|---|---|---|---|
| 1 | AC-2 and T-320 said the month 30 Jan to 28 Feb 2028 includes 29 Feb. F-006 section 2.1 makes 29 Feb the first day of the next month (29 Feb to 29 Mar 2028) | Must fix (Product Manager change, done by PM) | Doc AC-2 and plan T-320 corrected (D-075). TC-011-05 and -06 already test the F-006 truth |
| 2 | TC-011-24 expects `₹99.9L` for ₹99,99,999 and `₹12.3Cr` for ₹12,34,56,789. The design system section 7.5 table (and doc section 2.2) say whole lakh from ₹10 L and whole crore from ₹10 Cr: `₹99L` and `₹12Cr` | Must fix (Tester) | T-309: correct both values. The other rows stand (`₹1L`, `₹1Cr`, `₹99k`, `−₹12k`, `.0` dropped) and answer tests note 2 (D-073) |
| 3 | Month browsing is needed by four features | Must fix (Developer, noted here) | D-074 as above; T-323 text edited in section 5 |
| 4 | `watchMonthIndex` (T-322) has a test file in the plan but no test case | Must fix (Tester) | T-309: add TC-011-59 and up (memory Drift and fake parity, newest first, gaps for missed months, empty table, read failure) |
| 5 | AC-9 and the not-budgeted caption label had no weekday while every other cell has one; the Designer asked | Decision (D-075) | The label includes the weekday: `Thursday 5 November, not budgeted, before you started` (late setup: `…, before this month's setup`). Doc edited; Designer T-310; Tester T-309 (TC-011-20, -21); blocks T-324 |
| 6 | Grid gutters of 16 dp give a 47.4 dp touch pitch on 360 dp, 0.6 dp under the 48 dp rule | Decision (D-075, Gate 2) | Designer T-310 sets the grid gutters to at most 14 dp (pitch 48.0 dp at 360 dp); below 336 dp content width seven columns cannot reach 48 dp, a documented exception (the 320 dp test phone); height is always at least 48 dp. Reviewed at T-313 |
| 7 | Q2: short money forms need an Owner decision? | Decision | Yes, and it is given: approved by the Owner on 2026-11-16 (D-073). Proceed with `formatRupeesShort` |
| 8 | Q1: does Gate 2 cover the design system section 7.5 additions? | Decision | Yes: T-313 reviews not-budgeted cell, change tick and short forms before T-324 |
| 9 | Q4 and F-004: `hint.calendar.v1`, `HintId.calendar`, the hints test that asserts four ids | Decision (D-078) | Approved, built in T-325. Tester T-312 updates TC-004-09 and -10 and the id and key list. Product Manager T-311 adds the F-004 section 5 row; Designer T-310 adds the help-pattern section 4.2 row |
| 10 | Q5: `watchMonthIndex` is an additive read on the Done F-007 repository | Decision (D-078) | Approved inside T-322. TC-007-11, -12 and the repository suites are re-run; F-007 stays Done |
| 11 | Tests note 3: a month that starts on the 1st (M20) shows a plain `1` or `1 Nov`? | Decision (D-075) | Plain `1` on the budget month's first day; `1 Dec` only for the 1st of a calendar month that starts inside the month. Doc section 2.1 clarified; TC-011-41 stands |
| 12 | Q3, Q6 and the editor and delete items | Decision | The calendar edits nothing. Editing past months stays a later Owner question |
| 13 | AC-4 grey-scale is shown by shapes in the widget test; "told apart in grey by eye" is manual (TC-011-12) | Nice to have | Accepted |
| 14 | AC-18 timing counts only on the emulator (TC-011-37, worst of 5) | Nice to have | Accepted |
| 15 | `readFailsFor(monthId)` on `FakeMoneyStore` for TC-011-50 | Nice to have | In T-308 |
| 16 | Provider families are not auto-disposed, so visited months stay in memory | Nice to have | Accepted (small); measure in T-326 |

## 11. Implementation notes *(Developer, filled in during the build)*
Deviations from the plan and why (each approved by the Project Manager).

**T-490 and T-494 (Developer, 2026-11-23, test-only, no app code changed).** TC-011-37 follows D-094: `launchOnFile(..., settle: false)` (new option in `integration_test/real_app.dart`), stopwatch before `pumpWidget`, 16 ms frames until the 30 non-outside cells exist and the 9 cells of 5-13 Nov show the seed sums, no closing `pumpAndSettle` inside the timed part, worst of 5, limit 500 ms. Profile: `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/calendar_500_test.dart -d emulator-5554 --profile`: grid 167-250 ms (worst 250), month change worst 88 ms (`dev-t490-profile-calendar_500.log`). TC-011-35 past month: the heading is one node `Ended, 5 Oct – 4 Nov 2026`, then `Previous month`, `Next month`, `This month` (D-095), skip removed. The model test for TC-011-03..-07 and -40 now carries those IDs in its name.

**B-004 investigation (Developer 1, 2026-11-23, no app code changed).** TC-011-37 times `launchOnFile`, which ends in `pumpAndSettle()` with real-time 100 ms steps, so the figure is rounded up to the next step: unchanged test, profile, worst of 5: 524, 543, 542 ms (earlier 525, 548). With 16 ms frames the 30 final cells are on screen after 142-234 ms and the screen is settled after 170-266 ms (10 launches, `docs/reviews/emulator-phase-3/dev-b004-probe-profile.log`). `computeMonth` + `CalendarGrid.of` = 0.1-0.3 ms; the grid frame costs 10-14 ms to build (37 ms for the first cold frame); the rest is app start, DB open and the provider chain (database, latest month, month index, browse, calendar view). Nothing to optimise in the grid; the test was left unchanged. For the Project Manager: either time to final cells at 16 ms frames (limit stays 500 ms, worst seen 234 ms) or rule the current number. B-004 stays Open.

**T-475 tests and probes (Developer, 2026-11-23, no app code changed).** `calendar_grid_test.dart`: TC-011-19 day-one change gives no tick (G4 killed) and TC-011-38 boundary at 99, 100, 101 paise for `dayResultKind` and the grid (G7a, G7b killed); `calendar_labels_test.dart`: TC-011-38 labels at the same boundary (G7a, G7b killed); new `test/features/home/calendar_day_number_contrast_test.dart` (TC-011-34): reads the day number colour and the cell fill from the widget in five theme cases and every cell kind, 4.5:1 and the design colour (S2b border colour killed by contrast; S2 `textSecondary` passes 4.5:1 so it is killed only by the exact design-colour assertion). No `tests/F-011` rows were added (Tester 1's file); IDs reuse TC-011-19, -34, -38.

**T-322 (month index), built 2026-11-16 by the foundations Developer.** `MonthRef` is a small class (`BudgetMonth` has no `==`), not a record; tests compare its fields. Drift reads `budget_months` only (`select ... orderBy startDay desc`), so period, fixed-cost and spend writes do not re-emit. The Drift read-failure case drops `budget_months` in a memory database (a closed database throws a `StateError`, not a storage error). The fake re-emits the same list on every store change (allowed by TC-011-62). Fake and Drift share the TC-011-59 to -62 bodies; TC-011-65 and -66 belong to T-323.

**T-320 to T-326 built 2026-11-16 to 2026-11-19 by Developer Track B.** Notes and deviations:
1. **T-320.** `CalendarGrid.of(MonthResult)`, `CalendarCell`, `CellKind`, `TodayFill`; `CalendarDate.weekdayIndex` is public (`date_format.dart` uses it). The result words are the shared `DayResultKind` (`day_summary.dart`), not a separate `ResultKind`. `isMonthFirstDay` is false on outside cells. 100 % lines and branches.
2. **T-321.** `formatRupeesShort` in `core/format/money_format.dart`, table of design system §7.5; `money_format_short_test.dart`.
3. **T-323.** `core/providers/month_browser.dart`: `monthIndexProvider`, the pure `MonthBrowse` (limits and neighbours), `monthBrowserProvider` (family keyed by consumer, reset by `todayProvider`), `monthBrowseProvider`; `core/widgets/month_switcher.dart`; `calendar_providers.dart` (`calendarViewProvider`, `CalendarHeader`). F-013, F-014 and F-015 use `monthBrowserProvider(<their own key>)`; the calendar's key is `kCalendarBrowserKey`.
4. **T-324, T-325.** `DayCell`, marks, `calendar_labels.dart`, `CalendarSection`, legend with (i), weekday strip, caption, `hint.calendar.v1` (`HintId.calendar`, `HelpCopy.hintCalendar`, `FirstTimeHint.textFor`; the hints test expects five ids and the Phase 2 Home test TC-008-51 now checks that the home tip is gone instead of "no tip"). Deviations: (a) the 16 dp **rubber band** at the limits of a swipe is not built (a swipe at a limit does nothing); (b) while a month loads the old grid stays and only the range text changes at once (no cross-fade of the range); (c) the amount is hidden when fitting would go under 9 sp by measuring the text with the real font (`TextPainter`), and above 1.3x text.
5. **T-326.** `CalendarSection` is placed in `home_tab.dart` (active month and new-month-due states) after Track A's assembly; the sweeps are in `test/a11y/calendar_day_sweep_test.dart`. `integration_test/calendar_500_test.dart` is written and analyses clean but was **not run on the emulator**. T-454 (measure `₹9,999`, `−₹9,999`, `₹99k`, `₹9.9L`, `−₹100Cr` at 360 dp): the 9 sp rule is built; `₹9,999` is shown at 1.0x (TC-011-23) and `₹1,130` at 1.3x (TC-011-31) with the real font; the other four amounts were not measured yet.

**T-477 tests and probes (Developer 2, 2026-11-23, no app code changed).** Probes ran on a scratch copy of `app/` outside the project (one change each, test run, change reverted): TC-011-11 `onBudget` mark painted filled instead of stroked: killed. TC-011-15 `_reduceNewestFirst` no longer lowers the cover (`cover.amount -= cut` removed): killed. TC-011-35 not budgeted cells given button semantics (`if (!cell.isTappable) return padded` made `if (false)`): killed. TC-011-42 `thisIsTheLatestMonth` copy changed: killed. TC-011-43 `MonthBrowse.previousId` stays on the same month: killed. TC-011-47 `_wholeRupees` rounds to nearest (₹56): killed. TC-011-48 `_wholeRupees` rounds up (₹1): killed. TC-012-72 `dayResultKind` `< 100` made `<= 100`: killed; `cover_sheet.dart` `day.overspendUnderRupee` replaced by `day.overspend.value < 100`: killed by the static check (the behaviour at 99 and 100 paise is the same, so only the source check guards it). Re-ID only, no new assertions: TC-012-65 to -71, -73, -74 in `budget_change_text_test.dart` and `day_summary_test.dart`. Finding: TC-011-35 past-month reader order differs from the case (see TASKS T-477).
