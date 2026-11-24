# F-011: Calendar

| | |
|---|---|
| **Phase** | 3 |
| **Status** | Spec (final, ready for the plan; planned ahead, D-033). D-034 to D-040, D-046 to D-048, D-050, D-055 and D-057 are applied |
| **Plan** | [`plans/F-011-calendar.md`](../../plans/F-011-calendar.md) |
| **Test cases** | [`tests/F-011-calendar.md`](../../tests/F-011-calendar.md) |
| **Tasks** | T-3xx (assigned by the Project Manager at Step 5) |

## 1. What it is *(Product Manager)*
A month calendar on Home, under the summary and Today cards (F-010). It runs from the salary date to the day before the next salary date (README §3.5). Every day shows at a glance whether it was **saved (green ●)**, **on budget (grey ○)** or **overspent (red ◆)**, together with the amount spent. Today has a ring, and future days are shown as not yet happened. Tapping a day opens its details (F-012). Past budget months can be viewed too. Day results come from the F-006 engine. The calendar adds **no money rule**.

**User stories:**
- As a **user**, I want to see my whole budget month at a glance so that I can spot the days I overspent.
- As a **colour-blind user**, I want a shape as well as a colour on each day so that I can read the calendar without colour.
- As a **screen-reader user**, I want each day read as one full sentence.
- As a **user**, I want to look back at last month to compare.

## 2. How it behaves *(Product Manager)*
Cells per design system §7.5. The Designer writes the screen spec at Step 6.

### 2.1 The grid
- **Header:** the budget month's range, e.g. `5 Nov – 4 Dec 2026`, with **Previous month** (‹) and **Next month** (›) buttons, and a legend `● Saved ○ On budget ◆ Overspent` with an (i).
- **Weeks run Monday to Sunday.** The weekday strip reads `M T W T F S S`.
- The grid starts on the Monday of the week that holds the month's first day, and ends on the Sunday of the week that holds its last day. Days in the grid that are **outside the budget month** use the design system's "Outside month" state. They are decorative, can't be tapped, and are skipped by the screen reader.
- **A month spanning two calendar months:** the 1st of the new calendar month shows its month name, `1 Dec`, instead of `1`, so the change is visible. A budget month that starts on the 1st (for example 1–30 Nov) shows a plain `1` on its first day, because nothing changes inside the grid.
- **Example** (salary day 5, month 5 Nov – 4 Dec 2026, 30 days):
  - 5 Nov 2026 is a Thursday and 4 Dec 2026 a Friday.
  - So the grid runs Mon 2 Nov – Sun 6 Dec: 35 cells in 5 rows.
  - 2–4 Nov and 5–6 Dec are outside the month.
- **Other examples:** a 28-day month 1–28 Feb 2027 (Mon – Sun) fills exactly 4 rows. A month 31 Jan – 27 Feb 2027 (salary day 31) starts on a Sunday, so its first row has 6 outside cells. The grid has at most 6 rows.

### 2.2 Day cell states
The engine gives the status (F-006 §2.3). The cell shows:

| Engine status | Cell | Amount at the bottom |
|---|---|---|
| Saved | `savedSoft`, ● | net spent, in `saved` |
| On budget (including fully covered) | `neutralSoft`, ○ | net spent, in `neutral` |
| Overspent (including partly covered) | `overspentSoft`, ◆ | net spent, in `overspent` |
| Live (today) | the fill of today's result so far (`surface` if nothing has been spent) + 2 dp `accent` ring, day number in `accent` | spent so far, in `textPrimary` |
| Upcoming | no fill, hairline outline, day number in `textSecondary` | none |
| Not budgeted (mid-month first month, D-034) | like "Outside month" but readable: no fill, day number in `textSecondary`, no mark | none. Not tappable |

- **Amount rules:**
  - Whole rupees, rounded toward ₹0 (D-038, D-046).
  - A past day with no spends shows `₹0`.
  - Short forms so the amount fits the cell: ₹10,000–₹99,999 is written in thousands (`₹12k` for ₹12,999). ₹1,00,000–₹9,99,999 is written in lakh with one decimal, rounded down (`₹1.5L` for ₹1,59,999); ₹10,00,000–₹99,99,999 in whole lakh (`₹12L`). ₹1 crore to ₹9.99 crore is written in crore with one decimal (`₹1.5Cr`); ₹10 crore and more in whole crore (`₹10Cr`). The amount alone decides, never the screen width. A trailing `.0` is dropped (`₹1L`, `₹1Cr`) and a negative net keeps its sign (`−₹12k`). Approved by the Owner on 2026-11-16 (D-073). The full amount is in F-012 and in the screen-reader label.
- **Refunds (D-047):** the cell shows the day's **net** spend. If refunds are bigger than the day's spends, it shows the negative net (`−₹1,500`). The day is then Saved by more than its budget (●).
- **Covered days (F-012):**
  - A fully covered day turns On budget ○.
  - A partly covered day stays Overspent ◆. Its screen-reader label says how much is still uncovered.
  - The cell amount is still the net spend. Covers are not spends.
- **At text scale above 1.3×** the cell hides the amount and keeps the day number and mark (design system §4.2). The amount stays in the screen-reader label and in F-012.

### 2.3 Worked example A (₹830 a day, today Fri 13 Nov; data as in F-010 §2.4)
```
5 Nov – 4 Dec 2026                ‹  ›
  M     T     W     T     F     S     S
  2     3     4     5●    6◆    7○    8●
                    ₹500  ₹1,000 ₹830 ₹200
  9●   10○   11◆   12●  [13]   14    15
 ₹620  ₹830 ₹1,130  ₹0   ₹420
```
(This is an illustration. The real cells come from the design system. [13] is today's ring.)

| Date | Cell | Screen-reader label |
|---|---|---|
| 5 Nov | ● ₹500 | `Thursday 5 November, spent ₹500, saved ₹330` |
| 6 Nov | ◆ ₹1,000 | `Friday 6 November, spent ₹1,000, overspent ₹170` |
| 7 Nov | ○ ₹830 | `Saturday 7 November, spent ₹830, on budget` |
| 9 Nov | ● ₹620 | `Monday 9 November, spent ₹620, saved ₹210` |
| 11 Nov | ◆ ₹1,130 | `Wednesday 11 November, spent ₹1,130, overspent ₹300` |
| 12 Nov | ● ₹0 | `Thursday 12 November, nothing spent, saved ₹830` |
| 13 Nov (today) | ring, `savedSoft`, ₹420 | `Today, Friday 13 November, spent ₹420 so far, ₹410 left` |
| 14 Nov | upcoming | `Saturday 14 November, upcoming` |
| 11 Nov after a ₹300 cover | ○ ₹1,130 | `Wednesday 11 November, spent ₹1,130, on budget, ₹300 covered from savings` |
| 11 Nov after a ₹100 cover | ◆ ₹1,130 | `Wednesday 11 November, spent ₹1,130, overspent ₹200 after ₹100 from savings` |

### 2.4 Shortfall month (example S, D-036)
Every day is ₹0. Past days with no spends are **On budget ○ ₹0**. 6 Nov (₹200) is **◆ ₹200**, read as `Friday 6 November, spent ₹200, overspent ₹200`. The calendar header shows no extra shortfall panel, because it is on the summary (F-010).

### 2.5 Mid-month change (example M, D-037)
Month 1–30 Nov, with the change on 13 Nov.
- Cells before 13 Nov are measured against ₹830. Cells from 13 Nov on are measured against ₹552.
- Example: ₹600 spent on 18 Nov gives ◆, `overspent ₹47` (exact 552.22 − 600 = −47.78, shown rounded toward zero, D-046).
- **The 13 Nov cell has a small change marker** (the indigo "ink tick", 12 × 3 dp at the top centre of the cell, design system §7.5; changed from a bottom-left dot, which would collide with the amount). Its label adds `budget changed this day`. This shows where the new period starts. F-014 explains it.

### 2.6 Mid-month first month (example F, D-034)
Month 5 Nov – 4 Dec with the first use on 10 Nov. 5–9 Nov are **not budgeted**. They are not tappable and are read as `Thursday 5 November, not budgeted, before you started`. 10 Nov onwards behaves normally at ₹996.

### 2.7 Past months
- **‹** goes to the previous budget month, all the way back to the **first month the app has**. Past months are read-only in the calendar, and tapping a day opens a read-only F-012. **›** returns towards the current month, and is disabled on the current month (future months are not shown).
- **‹** is disabled on the first stored month. Its hint reads `No earlier months`.
- A past month's days all have final results (no today ring, no upcoming).
- Swiping the grid left or right does the same as › and ‹. The buttons stay for accessibility.
- **New month started, not set up (F-008):** the calendar shows last month, with the header `Last month · 5 Oct – 4 Nov`, and › disabled.

### 2.8 Tap
Tapping a budgeted day that is past or today opens **Day details (F-012)** for that day. An upcoming day opens F-012 in its upcoming form (budget only). Outside and not-budgeted days do nothing.

## 3. Acceptance criteria *(Product Manager)*
Tests use a fixed "today" and engine test data. "Small phone", themes and accessibility as in F-002 §3.

| ID | Given / When / Then |
|---|---|
| AC-1 | **Month range and grid.** Given salary day 5 and today 13 Nov 2026, when Home shows the calendar, then the header reads `5 Nov – 4 Dec 2026`, the grid runs Mon 2 Nov – Sun 6 Dec (35 cells, 5 rows), 2–4 Nov and 5–6 Dec are outside cells (not tappable, not in the screen-reader order), and the 1 Dec cell reads `1 Dec`. |
| AC-2 | **Month-length grids.** Given salary day 1 with Feb 2027 and salary day 31 with 31 Jan – 27 Feb 2027, when the calendar is shown, then the first shows 28 budget days in exactly 4 rows, and the second starts on Sunday 31 Jan (6 outside cells first) with 28 budget days; given salary day 30 in 2028, then 30 Jan – 28 Feb shows 30 budget days (no 29 Feb) and the next month 29 Feb – 29 Mar starts on 29 Feb with 30 budget days (F-006 §2.1: the leap day starts the next month). |
| AC-3 | **Cell states — example A.** Given example A (F-010 §2.4) and today 13 Nov, when the calendar is shown, then each date's mark, fill colour token, amount and screen-reader label match the §2.3 table exactly, and 14 Nov – 4 Dec are upcoming with no amount and no mark. |
| AC-4 | **Not colour alone.** Given example A rendered in grey-scale (test applies a grey-scale filter), when the Tester compares 5, 6 and 7 Nov, then the three are told apart by their ● ◆ ○ shapes, and every status is also in the screen-reader label. |
| AC-5 | **Today ring and midnight.** Given today 13 Nov, when shown, then only 13 Nov has the 2 dp accent ring and accent day number; when the test clock passes midnight and the app resumes, then the ring moves to 14 Nov and 13 Nov shows its final ● `₹420` saved ₹410. |
| AC-6 | **Covered days.** Given example A, when 11 Nov is covered with ₹300 (F-012), then its cell becomes ○ with `₹1,130` and the label in §2.3; when instead covered with ₹100, then it stays ◆ with the "overspent ₹200 after ₹100 from savings" label. |
| AC-7 | **Shortfall month.** Given example S (F-010 §2.5) and today 8 Nov, when shown, then 5 and 7 Nov are ○ `₹0` on budget, 6 Nov is ◆ `₹200` overspent ₹200, and 8 Nov has the today ring. |
| AC-8 | **Mid-month change.** Given example M and today 20 Nov, when shown, then 1–12 Nov are judged against ₹830 and 13–20 Nov against the engine's 552.23 / 552.22 budgets; an 18 Nov spend of ₹600 shows ◆ with label `…spent ₹600, overspent ₹47`; the 13 Nov cell carries the change marker and `budget changed this day` in its label; no other cell has the marker. |
| AC-9 | **Mid-month first month.** Given example F and today 12 Nov, when shown, then 5–9 Nov are not-budgeted cells (no mark, no amount, not tappable, read `<weekday> <d> November, not budgeted, before you started`), and 10–11 Nov have results against ₹996. |
| AC-10 | **Refund days (D-047).** Given ₹830/day and a past day with a ₹200 spend and a ₹1,500 refund, when shown, then the cell is ● with `−₹1,300` and the label `…net −₹1,300 after refunds, saved ₹2,130` (screen reader says "minus"); a day with a ₹700 spend and ₹500 refund shows ● `₹200`, saved ₹630. |
| AC-11 | **Amount short forms.** Given past-day net spends of ₹9,999, ₹10,000, ₹12,999, ₹1,59,999 and ₹10,00,00,000, when shown, then cells read exactly `₹9,999`, `₹10k`, `₹12k`, `₹1.5L` and `₹10Cr`; and the screen-reader labels give the full amounts. |
| AC-12 | **Past months.** Given months Oct (5 Oct – 4 Nov) and Nov stored and today 13 Nov, when the user taps ‹, then the header reads `5 Oct – 4 Nov 2026`, every day shows a final result, no cell has the ring, › is enabled and ‹ is disabled (first stored month) with hint `No earlier months`; when › is tapped, then Nov returns and › is disabled. Swipe left/right does the same. |
| AC-13 | **Tap opens details.** Given example A, when the user taps 6 Nov, 13 Nov or 20 Nov, then F-012 opens for that date (20 Nov in its upcoming form); tapping 3 Nov (outside) or a not-budgeted day does nothing; tapping a day in a past month opens F-012 read-only. |
| AC-14 | **New month not set up.** Given the Nov month ended yesterday and no Dec month is set up, when Home is shown, then the calendar header reads `Last month · 5 Nov – 4 Dec` with › disabled, and all days show final results. |
| AC-15 | **Live updates.** Given the calendar on screen, when a spend on a past day is added, edited or deleted, then that cell's mark, amount and label update without a manual refresh. |
| AC-16 | **Large text and landscape.** Given text scale 1.3×, then cells show number, mark and amount; given 2.0×, then cells show number and mark only (amount hidden) and the labels still include the amount; in landscape 640×360 the grid fits the width with 48 dp touch targets; all four themes pass F-002 AC-12–AC-14 (cell fill vs. day number and amount contrast, design system §3). |
| AC-17 | **Screen-reader order.** Given TalkBack, when the user swipes through the calendar, then focus goes header → ‹ → › → legend (i) → budget days in date order (outside cells skipped), each a button with a full sentence; upcoming and today days are included. |
| AC-18 | **Speed.** Given a month with 500 spends, when the calendar is shown or the month is changed with ‹/›, then the grid with final cells appears within 500 ms on the emulator. |
| AC-19 | **Less than ₹1 (D-050, D-055).** Given ₹830/day and past days with net spends of ₹830.50 and ₹829.50, when shown, then the cells are ◆ `₹830` and ● `₹829`, and their labels end `overspent less than ₹1` and `saved less than ₹1`; no label or cell contains `overspent ₹0`, `saved ₹0` or `−₹0`. |

## 4. Edge cases *(Product Manager)*
- **Salary day 29–31 and leap years:** the range follows F-006 §2.1 (AC-2).
- **A month crossing the year** (25 Dec – 24 Jan): the header reads `25 Dec 2026 – 24 Jan 2027` and the 1 Jan cell reads `1 Jan`.
- **6-row months:** the grid grows. Home scrolls.
- **Today is the month's last day:** › stays disabled. Tomorrow the new-month state appears.
- **Missed months** (F-008 §2.11): skipped months don't exist, so ‹ jumps from Dec straight to Sep when Oct and Nov were never set up. The header shows the real dates.
- **Device date moved back:** today's ring follows the given date. Spends dated "in the future" are not shown on upcoming cells (F-006 AC-13). F-012 still lists them.
- **50+ spends on one day:** the cell shows the total only.
- **₹0.40 spent on a day:** the cell shows `₹0` (a single amount keeps plain whole rupees, D-050), and the day is saved ₹829.60, shown as `saved ₹829` (D-038).
- **A month set up late** (D-057): days before setup are not budgeted, exactly like §2.6, with the label `<weekday d month>, not budgeted, before this month's setup`.
- **Overspent by less than ₹1** (₹830.50 spent): the cell is ◆ `₹830` and the label says `overspent less than ₹1` (D-050, D-055). Saved by less than ₹1 (₹829.50 spent) reads `saved less than ₹1` with ●.

## 5. Help text & copy *(Product Manager, finalised by Designer)*
| Control | Label | Description / tooltip |
|---|---|---|
| Header | `<start> – <end> <year>` | Past: same, plus the tag `Ended`. New month not set up: `Last month · <start> – <end>` |
| This month (past months only) | `This month` | Hint `Go back to the current month` |
| Previous month | (icon ‹) | Tooltip / hint `Previous month`; disabled hint `No earlier months` |
| Next month | (icon ›) | Tooltip / hint `Next month`; disabled hint `This is the current month` (new month not set up: `This is the latest month`) |
| Legend | `● Saved ○ On budget ◆ Overspent` (+ `▬ Budget changed` in a month with a change) | (i) title `Calendar`: `Each day shows what you spent. Green ● means you spent less than the day's budget, grey ○ exactly the budget, red ◆ more. A small indigo line at the top of a day means your budget changed that day. Tap a day to see its spends.` |
| Not-budgeted caption | — | Under the grid: `Days before <d MMM> aren't budgeted. You started on <d MMM>.` / late setup: `Days before <d MMM> aren't budgeted. This month was set up on <d MMM>.` |
| Loading / error | — | Screen reader `Loading your calendar`; past-month load error `Couldn't load this month.` + `Try again` (hint `Try to load this month again`) |
| Day cell (screen reader) | — | Saved: `<weekday d month>, spent <x>, saved <y>`. On budget: `…, on budget`. Overspent: `…, overspent <y>`. Nothing spent: `…, nothing spent, saved <budget>`. Less than ₹1: `…, saved less than ₹1` / `…, overspent less than ₹1` (D-050, D-055). Covered: `…, on budget, <c> covered from savings` / `…, overspent <y> after <c> from savings`. Refunds: `…, net <x> after refunds, …`. Today: `Today, <weekday d month>, spent <x> so far, <y> left` / `…, overspent <y>`. Upcoming: `<weekday d month>, upcoming`. Not budgeted: `<weekday d month>, not budgeted, before you started` (late setup: `…, before this month's setup`). Change day adds `budget changed this day`. Tap hint `See this day` |
| First-time hint (Home) | — | Existing `hint.home.v1` stays. New hint `hint.calendar.v1`: `Tap a day to see its spends.`, shown above the calendar only after `hint.home.v1` is dismissed (Designer, `screens/home-summary.md` H-7) |

## 6. Out of scope
- Week view, year view, heat maps.
- Spends and covers in past months: past months are read-only (see Suggested additions).
- Showing future months, or planning future spends.
- Month-transition animations beyond `motionBase` (Phase 6).
- Any new money rule.

## 7. How it works — technical *(Developer, filled in when the feature is Done)*
**What was built.** The month calendar on Home: grid from the salary date to the day before the next one, day cells with mark, amount and today ring, legend with (i), month switcher and swipe, past months, and the shared month browsing that F-013, F-014 and F-015 reuse. Tasks T-320 to T-326, T-454 (partly), T-475, T-477, T-490 and T-494. Gate 3 approved 2026-11-19 (D-088, conditional on a green check run). Gate 4 not yet passed: TC-011-37 (B-004) waits for the Tester's profile re-run (D-094, D-098).

**Main files** (`app/lib/`)
- Pure Dart in `domain/budget/`: `calendar_grid.dart` (`CalendarGrid.of(MonthResult)`, `CalendarCell`, `CellKind`, `TodayFill`), `calendar_date.dart` (public `weekdayIndex`, Monday = 0). The result words are the shared `DayResultKind` from `day_summary.dart`, not a separate type.
- Data: `watchMonthIndex()` and `MonthRef` on `data/repositories/month_repository.dart` and `drift_month_repository.dart` (reads `budget_months` only, newest first).
- `core/providers/month_browser.dart` (`monthIndexProvider`, the pure `MonthBrowse`, `monthBrowserProvider` family keyed by consumer and reset at midnight, `kCalendarBrowserKey`) and `calendar_providers.dart` (`calendarViewProvider`, `CalendarHeader`); `core/widgets/month_switcher.dart` (shared switcher, design system 7.14).
- `features/home/calendar/`: `calendar_section.dart`, `day_cell.dart`, `calendar_grid_view.dart`, `calendar_legend.dart`, `calendar_labels.dart`, `calendar_marks.dart`; `core/copy/calendar_copy.dart`.
- Formatting and hints: `formatRupeesShort` in `core/format/money_format.dart`; `HintId.calendar` (`hint.calendar.v1`), `HelpCopy.hintCalendar`, `FirstTimeHint.textFor`. `home_tab.dart` hosts `CalendarSection` (active and new-month-due states).

**Data stored.** None new, no schema change. `watchMonthIndex()` is a read-only addition to the month repository (D-078 (1)); the calendar writes nothing.

**Decisions:** D-073 (short money forms `₹12k`, `₹1.5L`, `₹12L`, `₹1.5Cr`, `₹10Cr` only inside day cells, cut not rounded, full amounts in every spoken label), D-074 (F-011 owns shared month browsing), D-075 (AC-2 corrected for the leap day; a month starting on the 1st shows a plain `1`; not-budgeted cells read with the weekday; 48 dp pitch, gutters at most 14 dp), D-077, D-078 (F-007 and F-004 additive changes), D-079, D-088, D-089 (1) (rubber band dropped, range text changes at once), D-094 (B-004: the test re-measures, limit stays 500 ms), D-095 (past-month reader order follows the app), D-096 (grey-scale accepted on shape assertions), D-097, D-098, D-099, D-102 (survivors G4, G7a, G7b, S2, S2b closed by tests).

**Deviations** (plan section 11, Gate 3 in `docs/reviews/code-phase-3-tracks-bc.md`)
- `MonthRef` is a small class, not a record (`BudgetMonth` has no `==`). The fake month store re-emits the same list on every store change (allowed by TC-011-62). `isMonthFirstDay` is false on outside cells.
- The 16 dp rubber band at a swipe limit is not built (a swipe at a limit does nothing); the old grid stays while the next month loads and only the range text changes at once (no cross-fade of the range). Accepted in D-089 (1).
- The amount in a cell is hidden when fitting would go under 9 sp (measured with the real font through `TextPainter`) and above 1.3x text.
- T-454 (measure `₹9,999`, `−₹9,999`, `₹99k`, `₹9.9L`, `−₹100Cr` on 360 dp) is only partly measured: `₹9,999` at 1.0x (TC-011-23) and `₹1,130` at 1.3x (TC-011-31) with the real font; the other four were not. Paper values are in `calendar.md` 10.
- Past-month screen-reader order (D-095): the app reads `Ended, 5 Oct – 4 Nov 2026` (one heading node), `Previous month`, `Next month`, `This month`; the case text changed, not the app.
- AC-2 already carries the corrected wording (29 Feb starts the next month, D-075), so there was nothing left to change for T-498.

**How it is tested** (`tests/F-011-calendar.md`, 66 cases, 19 ACs)
- Unit: `test/domain/budget/calendar_grid_test.dart` (grids from the spec; the model test named `TC-011-02 the F-006 months, also TC-011-03 ... TC-011-07 and TC-011-40`; TC-011-19 day-one change gives no tick; TC-011-38 boundary at 99, 100, 101 paise), `test/core/format/money_format_short_test.dart` (AC-11 forms and boundaries), `test/data/repositories/month_index_test.dart` (TC-011-59 to -62 on the fake and Drift).
- Widget: `test/features/home/` (`calendar_labels_test`, `calendar_gap_cases_test` with TC-011-11, -15, -35, -42, -43, -47, -48, `calendar_day_number_contrast_test` = TC-011-34 in five theme cases), `test/a11y/calendar_day_sweep_test.dart` (four themes at 1.0, 1.3 and 2.0x, small phone, 640 x 360).
- Integration on the emulator: `integration_test/calendar_500_test.dart` (TC-011-37, 500 spends, limit 500 ms for the grid and for a month change). The unchanged test ended `launchOnFile` with `pumpAndSettle()` (100 ms real-time steps) and read 525 and 548 ms, then 524, 543 and 542 ms in profile (B-004). The Developer's probe with 16 ms frames showed the 30 final cells on screen after 142-234 ms (`dev-b004-probe-profile.log`). Under D-094 T-490 changed the measurement (stopwatch before `pumpWidget`, 16 ms frames until the 30 final cells show their seed sums, `launchOnFile(settle: false)`): profile grid 167-250 ms, worst 250 ms; month change worst 88 ms (`docs/reviews/emulator-phase-3/dev-t490-profile-calendar_500.log`). Limit kept at 500 ms. The Tester's re-run (T-491) is still to do.
- Mutation pass (`tests/PHASE-3-SUMMARY.md` 6.1, 6.4): the grid and label mutants of section 6.1 were run; survivors G4, G7a, G7b, S2, S2b were closed by T-475 tests with recorded probes (D-102). Developer probes of T-477 (marks, cover reduction, not-budgeted semantics, latest-month copy, previous month, whole-rupee rounding) were all killed.
- Device (A13 seed): labels per day, Home tip then Calendar tip, a day tap opens the real Day details route, four themes at x2.0 (`s8-tc011-56-*.png`), grey-scale screenshot `s8-tc011-12-greyscale.png` read by the Project Manager.
- Result (2026-11-23, after T-495): 61 Pass, 3 Partial (TC-011-32, -33, -58, accepted under D-099), 1 Blocked-needs-human (TC-011-36), 1 Fail (TC-011-37, B-004); `tool/check.ps1` green (1,285 tests on the 2026-11-23 re-run, 1,267 on 2026-11-21).

**Known limitations and open items**
- **Still blocks Done:** T-491 (Tester 1: re-run `calendar_500` in profile on an idle machine; grid and month change under 500 ms passes TC-011-37 and closes B-004, no second PM review, D-094), T-501 (Project Manager: Gate 3 of the test-only changes, then Gate 5). Gate 4 is not yet passed for this feature.
- **TC-011-36 (TalkBack) is Blocked-needs-human**, open under D-097; it is the case the Owner should do if only one or two are possible (swipe through the 30 day buttons; steps in `tests/PHASE-3-SUMMARY.md` 3.3).
- **TC-011-12 (grey-scale):** Pass on shape assertions (D-096); an optional one-minute look by the Owner (Settings > Accessibility > Colour correction > Grayscale) is open, not a blocker.
- TC-011-32, -33 and -58 stay Partial and accepted (D-099).
- Nice to have, not blocking: T-454 (finish the amount-fit measurement).
- Depends on F-006 (engine, `computeMonth`), F-007 (month index), F-010 (Home hosts the section), F-012 (a day tap opens day details), F-004 (hint). Used by F-013, F-014 and F-015 (`monthBrowserProvider` and `MonthSwitcher`), F-012 (shares `DayResultKind`).

## 8. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-10 | First version of the spec (Phase 3 planned ahead, D-033). Team question "how far back" decided: back to the first stored month. 18 ACs | Product Manager |
| 2026-11-11 | Q-1 closed by D-055 with D-050's wording: `overspent under ₹1` / `saved under ₹1` (§4, §5, new AC-19); D-057 late-start month uses the not-budgeted state (§4). 19 ACs | Product Manager |
| 2026-11-11 | Small-amount wording switched from "under ₹1" to the Owner's literal "less than ₹1" (`overspent less than ₹1`, `saved less than ₹1`, `less than ₹1 left today`, `less than ₹1 short`, `less than ₹1 a day`), matching the Phase 2 change to D-050/D-055. Wording only, no AC added | Product Manager |
| 2026-11-11 | Status set to final Spec, ready for the plan (all Owner questions answered: D-053 to D-058). Remaining team questions go to the Project Manager at Phase 3 Gate 1 (phase overview, open items) | Product Manager |
| 2026-11-16 | §2.2 short forms use no decimal from ₹10 L and ₹10 Cr (`₹12L`, `₹12Cr`), so they fit; AC-11's five values are unchanged (`₹9,999`, `₹10k`, `₹12k`, `₹1.5L`, `₹10Cr`); no AC changed. | Designer |
| 2026-11-11 | Designer (`docs/design/screens/calendar.md`, design system §7.5): change marker is the top-centre ink tick (§2.5); §5 adds `Ended` tag, `This month` button, `▬ Budget changed` legend item and (i) sentence, not-budgeted caption, `hint.calendar.v1`, loading/error copy. No AC changed | Designer |
| 2026-11-16 | Gate 1 (Project Manager A): AC-2 corrected (the leap day starts the next month, F-006 §2.1; D-075); §2.1 says a month that starts on the 1st shows a plain `1`; not-budgeted labels now include the weekday (AC-9, §2.6, §4, §5); short-form edge cases and the Owner's approval noted in §2.2 (D-073). Product Manager changes | Project Manager |
| 2026-11-23 | Step 9: section 7 (technical) filled in. Status stays Testing: Done waits for T-491 (B-004 profile re-run), T-501 (Gate 5) | Developer |

## Impact on existing features
- **F-010:** the calendar sits under the Today card on Home.
- **Design system §7.5:** needs a **Not budgeted** state, a **change-day marker** and the **short-form amount** rule for lakh and crore. These go to the Designer.

## Owner / team questions
- ~~Q-1~~ **Closed by D-055:** the Owner chose "less than ₹1"; the one phrase used everywhere, in Phase 2 and Phase 3, is the Owner's literal **`overspent less than ₹1`** (and `less than ₹1 left today`, `saved less than ₹1`, `less than ₹1 short`), as amended on the D-050 row.

## Suggested additions *(for the CEO — not in scope until approved)*
- **Editing spends of past months.** It recomputes a closed month, which raises a money-rule question (does the closed month's pot change?), so it needs the Owner.
- **A "this week" strip** above the calendar for one-handed use.
