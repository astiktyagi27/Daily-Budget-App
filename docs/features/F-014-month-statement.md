# F-014: Month statement

| | |
|---|---|
| **Phase** | 3 |
| **Status** | Spec (final, ready for the plan; planned ahead, D-033). D-034 to D-040, D-042, D-043, D-046 to D-048, D-050, D-053 (note wording per D-062) and D-060 are applied |
| **Plan** | [`plans/F-014-month-statement.md`](../../plans/F-014-month-statement.md) |
| **Test cases** | [`tests/F-014-month-statement.md`](../../tests/F-014-month-statement.md) |
| **Tasks** | T-400 to T-407 in `docs/TASKS.md` (Gate 1, 2026-11-16) |

## 1. What it is *(Product Manager)*
A plain, read-only statement of one budget month (D-037). It shows:
- every **budget period** of the month: its dates, the values in force (salary, target, fixed costs, or money left), the money spread and the daily budget, and its totals;
- a list of **what changed and when**;
- the **whole-month totals**.

The user is never left wondering why the budget changed. It is available for the current month (labelled **so far**) and for every past month. It reads the period history kept since Phase 2 (F-007 AC-16) and the engine's per-period results (F-006 AC-21). This feature adds **no money rule**. PDF export is not in this phase (D-037).

**User stories:**
- As a **user who changed my salary mid-month**, I want to see why my daily budget went from ₹830 to ₹552.
- As the **Owner**, I want to check that every number in a month adds up.
- As a **user**, I want to look back at last month's statement.

## 2. How it behaves *(Product Manager)*
Full screen, scrolling. The Designer writes the screen spec at Step 6.

### 2.1 Getting there
- **Home:** `Month statement`, or `Budget changed on … · See month statement` (F-010).
- **Dashboard:** the `Month statement` link (F-013).
- **Day details:** the `Budget changed on this day` line on a period's first day (F-012). The statement scrolls to that period.
- ‹ › change month, with the same months and limits as F-011 §2.7.

### 2.2 Layout
1. **Title** `Month statement`, and the month `1 – 30 Nov 2026`. The current month adds `· so far (to Fri, 20 Nov)`.
2. **Month totals card** (§2.4).
3. **What changed** (§2.5).
4. **Periods**, oldest first. Each is a card (§2.3).
5. A footnote: `Amounts are in whole rupees. Calculations use exact amounts.`

### 2.3 Period card
| Part | Content |
|---|---|
| Heading | `<start> – <end>` and `· <n> days`. The current period reads `13 Nov – 30 Nov · 18 days · in progress` |
| Why it started | `Month started` (first period), `Salary changed` / `Target changed` / `Rent changed` / `Fixed cost added: Gym` / `Fixed cost removed: EMI` / `Money left changed`, or several of these, joined with `·` |
| Values in force | `Salary ₹35,000` · `Spending target ₹20,000` (only if set) · `Fixed costs ₹15,100` (tap to expand the items, `Rent ₹10,000`, `EMI ₹5,000`, `Subscriptions ₹100`). In a mid-month first month: `Money left ₹24,900` · `Still to pay ₹0` (D-034, D-042) |
| Working | First period of a normal month: `₹40,000 − ₹15,100 fixed = ₹24,900 over 30 days → ₹830/day`. A later period: `₹35,000 − ₹15,100 fixed = ₹19,900, minus ₹9,960 already budgeted = ₹9,940 over 18 days → ₹552/day` |
| Shortfall | When continued anyway (D-036): `₹1,000 short · ₹0/day (continued anyway)`. Equal case (D-043): `₹0 left for daily spending · ₹0/day` |
| Totals for these days | `Budget ₹9,960` · `Spent ₹10,000` (+ `Refunds −₹500` · `Net spent ₹9,500` when there are refunds, D-047; without refunds the line is just `Spent ₹9,000`) · `Saved ● ₹1,400` · `Overspent ◆ ₹240` · `Covered from savings ₹200` |

- **Saved, Overspent and Covered** follow the engine:
  - **Saved counts ended days only** (D-039). **Overspent counts every budgeted day up to and including today** (D-060), so a current period (and the "So far" month) includes today's live overspend; a past period has no live day, so the two rules give the same result there.
  - Overspent is the **uncovered** overspend.
  - Covered is the covers made **for days in this period**.
- **The check line.** Every period and the month satisfy: **Budget − Net spent = Saved − Overspent − Covered** (asserted on **ended periods and past months only**, where every day has ended; a current period can include today's live overspend, D-060). This is the identity the Owner can check by eye. The statement does not print the formula, but the AC tests it.
- The working line always uses **whole rupees** (D-038). The (i) next to the daily budget explains the extra paise: `₹9,940 doesn't divide evenly by 18 days, so the first 4 days get 1 paisa more. That's why you see ₹552 every day.`

### 2.4 Month totals card
| Row | Value (engine month totals, F-006 §2.5) |
|---|---|
| `Money for the month` | The sum of all day budgets. Normally the spendable amount |
| `Spent` | Spends of budgeted days up to today. With refunds: `Spent`, `Refunds`, `Net spent` |
| `Saved` ● | Saved on ended days |
| `Covered from savings` | All covers |
| `Overspent` ◆ | Uncovered overspend, up to and including today (D-060) |
| `Savings pot` | Saved − covered |
| `Short this month` | Only when there is a shortfall: `−₹1,000` |
| `Left` | Money for the month − net spent − shortfall (the Home figure) |

The current month's card is headed `So far`, and a past month's `Month total`.

### 2.5 What changed
A dated list, one line per stored change (every period record, including same-day changes, with the time), oldest first:
- `1 Nov · Month started: salary ₹40,000, fixed costs ₹15,100 → ₹830/day`
- `13 Nov · Salary ₹40,000 → ₹35,000 → ₹552/day for the 18 days left`

A month with a single period shows `No changes this month.` under the first line. Same-day changes are listed with their times. Only the last one has `→ <daily>/day`, and the earlier ones are marked `(replaced the same day)`.

### 2.6 Worked example M, full month (D-037; salary day 1; viewed on 1 Dec)
**Period 1 · 1 – 12 Nov · 12 days · Month started**
- Salary ₹40,000 · Fixed costs ₹15,100 (Rent ₹10,000, EMI ₹5,000, Subscriptions ₹100).
- `₹40,000 − ₹15,100 fixed = ₹24,900 over 30 days → ₹830/day`.
- Budget 12 × ₹830 = **₹9,960** · Spent **₹9,000** · Saved **₹1,400** · Overspent **₹240** · Covered **₹200**.
- Check: 9,960 − 9,000 = 960 = 1,400 − 240 − 200 ✓.

**Period 2 · 13 – 30 Nov · 18 days · Salary changed**
- Salary ₹35,000 · Fixed costs ₹15,100.
- `₹35,000 − ₹15,100 fixed = ₹19,900, minus ₹9,960 already budgeted = ₹9,940 over 18 days → ₹552/day`.
- Exact: 9,94,000 ÷ 18 = 55,222 remainder 4, so 13–16 Nov get ₹552.23 and 17–30 Nov get ₹552.22. Sum: 4 × 55,223 + 14 × 55,222 = 2,20,892 + 7,73,108 = 9,94,000 ✓.
- Budget **₹9,940** · Spent ₹10,000 · Refunds ₹500 · Net spent **₹9,500** · Saved **₹740** · Overspent **₹300** · Covered ₹0.
- Check: 9,940 − 9,500 = 440 = 740 − 300 − 0 ✓.

**Month total**
- Money for the month **₹19,900** (9,960 + 9,940 = 35,000 − 15,100 ✓).
- Spent ₹19,000 · Refunds ₹500 · Net spent **₹18,500**.
- Saved **₹2,140** · Covered **₹200** · Overspent **₹540** · Savings pot **₹1,940**.
- Left **₹1,400**.
- Check: 19,900 − 18,500 = 1,400 = 2,140 − 200 − 540 ✓. The period lines add up to the month lines exactly.

**What changed**
- `1 Nov · Month started: salary ₹40,000, fixed costs ₹15,100 → ₹830/day`
- `13 Nov · Salary ₹40,000 → ₹35,000 → ₹552/day for the 18 days left`

**The same month "so far" on Fri 20 Nov:**
- The heading reads `So far` and the second period `13 Nov – 30 Nov · 18 days · in progress`.
- Its Budget still shows the period's ₹9,940. Spent covers 13–20 Nov and Overspent covers 13–20 Nov (D-060: it includes today's live overspend), while Saved covers 13–19 Nov (ended days only).
- Left matches Home (F-010 §2.6, ₹6,900, when spent so far is ₹13,000).
- Figures (seed M20, `month-statement.md` §8.1): month Money for the month ₹19,900 · Spent ₹13,000 · Saved ₹2,115 (₹1,400 + ₹715) · Covered ₹200 · Overspent ₹537 (₹240 + ₹297) · Savings pot ₹1,915 · Left ₹6,900. Period 2: Spent ₹4,000 (13–20 Nov) · Saved ₹715 (13–19 Nov) · Overspent ₹297 (20 Nov, today) · Covered ₹0. Those 8 days were budgeted ₹4,417.80 and ₹4,000 was spent, so ₹417.80 is left over, which is ₹715.58 − ₹297.78 (shown whole rupees).

### 2.7 Other worked examples
- **Three periods** (F-006 AC-21; E2 month 5 Nov – 4 Dec, salary day 5):
  - P1 5–19 Nov `₹830/day`.
  - P2 20–27 Nov `Rent changed` `₹40,000 − ₹18,100 fixed = ₹21,900, minus ₹12,450 already budgeted = ₹9,450 over 15 days → ₹630/day`.
  - P3 28 Nov – 4 Dec `EMI changed` `₹40,000 − ₹17,100 fixed = ₹22,900, minus ₹17,490 already budgeted = ₹5,410 over 7 days → ₹772/day` (exact 77,286 / 77,285 paise).
  - Money for the month: 12,450 + 8 × 630 + 5,410 = 12,450 + 5,040 + 5,410 = **₹22,900** ✓.
- **Shortfall month** (example S):
  - One period, 5 Nov – 4 Dec · `Month started`, Salary ₹20,000, Fixed costs ₹21,000 (Rent ₹15,000, EMI ₹6,000).
  - `₹20,000 − ₹21,000 fixed = −₹1,000 → ₹1,000 short · ₹0/day (continued anyway)`.
  - Totals on 8 Nov: Money for the month ₹0 · Spent ₹200 · Overspent ₹200 · Short this month −₹1,000 · Left −₹1,200.
- **Change that causes a shortfall** (F-006 C4, a target of ₹25,000 on 20 Nov):
  - Period 2 shows `₹25,000 − ₹15,100 fixed = ₹9,900, minus ₹12,450 already budgeted = −₹2,550 → ₹2,550 short · ₹0/day (continued anyway)`.
  - The month card shows `Short this month −₹2,550`.
- **Mid-month first month** (example F):
  - One period, 10 Nov – 4 Dec · 25 days · `Month started partway`, `Money left ₹24,900 · Still to pay ₹0`.
  - `₹24,900 − ₹0 still to pay = ₹24,900 over 25 days → ₹996/day`.
  - A line above the periods: `5 – 9 Nov: not budgeted (before you started).`

### 2.8 Gate 1 clarifications *(Project Manager, 2026-11-16; D-081)*
- **Refunds** are written `Refunds −₹500` everywhere (AC-11 updated to match the design).
- **Working line, first term:** the amount the engine spreads, which is the spending target when one is set, otherwise the salary. The values list shows both `Salary` and `Spending target`; the working line does not name the target.
- **`, minus ₹X already budgeted`** is left out when X is ₹0 (the first period, a change on the first day, a change after days budgeted at ₹0): `₹35,000 − ₹15,100 fixed = ₹19,900 over 30 days → ₹663/day`.
- **A one-day period** heading reads `30 Nov · 1 day` (no range dash).
- **What changed** has one line per stored record. Each line's old → new compares that record with the **previous stored record**, so a second change on the same day shows its own old value: `20 Nov, 18:00 · Rent ₹13,000 → ₹11,000 → ₹763/day for the 15 days left`. Fixed-cost wording: `Fixed cost added: Gym ₹500`, `Fixed cost removed: EMI ₹5,000`, `Rent renamed to House rent`.
- **A period's reason** compares it with the previous *period card* (same-day changes netted). If they net to nothing the reason reads `Changed and changed back`.
- The "so far on 20 Nov" example in `docs/design/screens/month-statement.md` §8.1 did not add up and is corrected by the Designer (T-407) with the data of seed M20 (`tests/F-013`: 13–20 Nov spent ₹4,000, saved ₹715, overspent ₹297).

## 3. Acceptance criteria *(Product Manager)*
Fixed "today", engine and history test data from F-006 / F-007. Themes and accessibility per F-002 §3.

| ID | Given / When / Then |
|---|---|
| AC-1 | **Entry points.** Given example M on 20 Nov, when the user taps `Month statement` or `See month statement` on Home, or `Month statement` on the Dashboard, then the statement for 1–30 Nov opens at the top; when the user taps `Budget changed on this day` in 13 Nov's day details, then it opens scrolled to Period 2. |
| AC-2 | **Full-month example M.** Given the §2.6 data and today 1 Dec, when November's statement is shown, then every period heading, reason, value, working line, total and change line in §2.6 is shown exactly (whole rupees), the totals card is headed `Month total`, and there is no "so far" or "in progress". |
| AC-3 | **Totals add up (whole-rupee data).** Given the §2.6 data, when the Tester sums the shown period lines, then Budget (9,960 + 9,940 = 19,900), Net spent (9,000 + 9,500 = 18,500), Saved (1,400 + 740 = 2,140), Overspent (240 + 300 = 540) and Covered (200 + 0) equal the shown month lines; and for each period and the month, Budget − Net spent = Saved − Overspent − Covered. |
| AC-4 | **"So far".** Given example M and today 20 Nov, when shown, then the header reads `1 – 30 Nov 2026 · so far (to Fri, 20 Nov)`, the totals card is headed `So far`, Period 2 reads `13 Nov – 30 Nov · 18 days · in progress` with Budget `₹9,940`, and the card's Left equals Home's Left (F-010 AC-8). |
| AC-5 | **What changed.** Given example M, when shown, then What changed has exactly the two §2.5 lines in date order; given a month with one period, then it has the `Month started` line and `No changes this month.` |
| AC-6 | **Same-day changes (F-006 AC-22).** Given the E2 month with rent → ₹13,000 at 10:00 and rent → ₹11,000 at 18:00 on 20 Nov, when shown, then What changed lists both with their times, the 10:00 line ends `(replaced the same day)`, the 18:00 line ends `→ ₹763/day for the 15 days left`, and there are exactly 2 period cards (5–19 Nov, 20 Nov – 4 Dec). |
| AC-7 | **Three periods.** Given F-006 AC-21's data, when shown, then there are 3 period cards with the §2.7 dates, reasons, working lines (`→ ₹830/day`, `→ ₹630/day`, `→ ₹772/day`) and fixed-cost items (P1 Rent ₹10,000; P2 Rent ₹13,000; P3 EMI ₹4,000), and Money for the month reads `₹22,900`. |
| AC-8 | **Values per period are never rewritten.** Given example M, when Period 1's fixed costs are expanded, then they read Rent ₹10,000, EMI ₹5,000, Subscriptions ₹100, and its salary reads `₹40,000`, even though the current salary is ₹35,000. |
| AC-9 | **Shortfall statements.** Given example S and today 8 Nov, then the period shows `₹20,000 − ₹21,000 fixed = −₹1,000 → ₹1,000 short · ₹0/day (continued anyway)` and the totals show `Short this month −₹1,000` and Left `−₹1,200`. Given change C4 continued anyway, then Period 2 shows the `−₹2,550 → ₹2,550 short` line and the month shows `Short this month −₹2,550`. Given the D-043 equal case, then `₹0 left for daily spending · ₹0/day`. |
| AC-10 | **Mid-month first month.** Given example F, when shown, then the period reads `10 Nov – 4 Dec · 25 days · Month started partway`, `Money left ₹24,900 · Still to pay ₹0`, `… over 25 days → ₹996/day`, the line `5 – 9 Nov: not budgeted (before you started).` is shown, and there is no Salary row. |
| AC-11 | **Refunds (D-047).** Given Period 2 of §2.6 (spends ₹10,000, refunds ₹500), when shown, then the period shows `Spent ₹10,000 · Refunds −₹500 · Net spent ₹9,500`, and Period 1 (no refunds) shows only `Spent ₹9,000`; the month shows `Refunds −₹500` and `Net spent ₹18,500`. |
| AC-12 | **Rounding (D-038, D-046, D-053).** Given two periods whose net spends are 4,50,060 and 4,50,060 paise (₹4,500.60 each), when shown, then each period line reads `₹4,500`, the month line reads `₹9,001` (the exact total, rounded down), and the note `Totals use exact amounts, so they can differ by a few rupees from the parts.` is shown under the totals card because the shown lines don't add up; given the §2.6 data (lines add up, AC-3), then the note is absent. |
| AC-13 | **Daily-budget (i).** Given Period 2 of §2.6, when the user taps the (i) next to `₹552/day`, then the help sheet reads `₹9,940 doesn't divide evenly by 18 days, so the first 4 days get 1 paisa more. That's why you see ₹552 every day.`; for an exact period (₹830/day), then the (i) reads `₹24,900 divides evenly over 30 days.` |
| AC-14 | **Past months.** Given October and November stored, when ‹ is tapped, then October's statement is shown with `Month total` and its own periods; ‹/› limits match F-011 AC-12; a statement is shown for every stored month, back to the first. |
| AC-15 | **Read-only, live.** Given the statement, then nothing on it can be edited; when a spend or cover is added elsewhere and the user returns, then the figures are updated. |
| AC-16 | **Help, themes, large text, accessibility.** Given the §2.6 statement, when shown in all four themes at text scale 1.0 and 2.0 on a small phone and in landscape (D-030), then F-002 AC-12–AC-14 pass; working lines wrap at the ` = `, `, minus ` and ` → ` points and never split an amount; every total has its §5 label and (i); TalkBack reads each period heading as a heading and the working line as one sentence (`40,000 rupees minus 15,100 rupees fixed equals 24,900 rupees, over 30 days, 830 rupees a day`). |
| AC-17 | **Speed.** Given a month with 10 periods and 500 spends, when the statement opens, then it is fully shown within 1 second on the emulator. |

## 4. Edge cases *(Product Manager)*
- **A change on the month's first day:** that period has 0 past days. Its card reads `1 Nov – 30 Nov`, and the replaced first period shows in What changed as `(replaced the same day)` (F-006 §4).
- **A change on the last day:** a 1-day period. `over 1 day → ₹<x>/day`.
- **A fixed cost renamed only** (same amount): a new period with the reason `Rent renamed to House rent`, and the daily budget unchanged.
- **A change that removes a shortfall:** the next period shows a positive working line. The month's shortfall is the current period's (F-006 §4).
- **10+ periods:** all are listed. The list is never collapsed or truncated.
- **Missed months:** they don't exist, so they have no statement (F-008 §2.11).
- **A ₹10 crore salary:** the working lines wrap at 2.0× text.
- **A shortfall less than ₹1** (fixed costs ₹0.50 more than the money): `less than ₹1 short · ₹0/day` (D-050).
- **Many periods with paise:** the gap between the shown parts and the true total can exceed ₹1 (up to ₹1 per line). The note therefore says "a few rupees" (D-062).
- **Leftover paise in the first period of a normal month** (E1, ₹1,333.34 / ₹1,333.33): the (i) explains `the first 10 days get 1 paisa more`.
- **New month not set up:** the statement shows last month.

## 5. Help text & copy *(Product Manager, finalised by Designer)*
| Control | Label | Description / tooltip |
|---|---|---|
| Title | `Month statement` | Month line `<start> – <end> <year>` (+ ` · so far (to <weekday, d MMM>)`) |
| Totals card | `So far` / `Month total` | — |
| Money for the month | `Money for the month` | (i): `All the daily budgets of this month added together.` |
| Spent / Refunds / Net spent | `Spent` / `Refunds` / `Net spent` | Refunds value written `−<amount>` (Designer; as F-013, F-012). (i) as F-013 |
| Saved / Covered / Overspent / Savings pot | as F-010 | (i) as F-010 / F-012 |
| Short this month | `Short this month` | (i): F-006 "Shortfall" |
| Left | `Left` | (i): F-006 "Left" |
| What changed | `What changed` | (i): `Every time you changed your salary, target or fixed costs. Days before a change keep their budget.` |
| Change line | — | `<d MMM> · <what changed> → <daily>/day for the <n> days left`; first: `<d MMM> · Month started: salary <x>, fixed costs <y> → <daily>/day`; same day: `<d MMM>, <hh:mm> · … (replaced the same day)` |
| No changes | — | `No changes this month.` |
| Period overline (Designer) | `Period <i> of <n>` | — |
| Period heading | `<start> – <end> · <n> days` (+ ` · in progress`) | Reasons as §2.3 (+ `Month started partway`) |
| Period totals sub-heading (Designer) | `For these days` | — |
| Mid-month first change line (Designer) | — | `<d MMM> · Month started partway: money left <x>, still to pay <y> → <daily>/day` |
| Loading (Designer) | — | Screen reader `Loading the statement` |
| Working line | — | As §2.3 / §2.7 |
| Shortfall line | — | `<amount> short · ₹0/day (continued anyway)` / `₹0 left for daily spending · ₹0/day` |
| Not budgeted line | — | `<start> – <end>: not budgeted (before you started).` |
| Daily budget (i) | — | `<amount> doesn't divide evenly by <n> days, so the first <r> days get 1 paisa more. That's why you see <daily> every day.` / `<amount> divides evenly over <n> days.` |
| Footnote | — | `Amounts are in whole rupees. Calculations use exact amounts.` |
| Rounding note (D-053) | — | `Totals use exact amounts, so they can differ by a few rupees from the parts.` Shown only when the shown parts don't add up to the shown total |
| Fixed costs expand | `Fixed costs <total>` | Hint `Show the fixed costs in this period`; expanded: `Hide the fixed costs` |

## 6. Out of scope
- PDF, Excel or share export (later, D-037).
- Editing anything from the statement.
- Statements across several months, or a yearly summary.
- Any new money rule.

## 7. How it works — technical *(Developer, filled in when the feature is Done)*
**What was built.** The Month statement screen: for a month, the totals card, the rounding note, a What changed list (one line per stored change), and one card per budget period with its dates, the values in force, the working line that gets the daily budget, and spent / saved / overspent / covered. Past months are reached with the shared month switcher. It opens from Home, the Dashboard and Day details (and scrolls to and flashes the period of the day it came from). It is read-only and shows only numbers the engine already computes. Tasks T-400 to T-405, T-472 (tests), T-429 (speed test, profile aware); Gate 1 D-081 and D-085, Gate 3 D-088, Gate 4 D-100 to D-105.

**Main files** (`app/lib/`)
- Pure Dart in `domain/budget/month_statement.dart`: `buildStatement(MonthResult)` returning `MonthStatement` (`StatementPeriod`, `StatementPeriodTotals`, `StatementTotals`, `StatementChange` with sealed `StatementDelta` / `StatementReason`, sealed `StatementWorking` = `SpreadWorking` / `ShortfallWorking` / `ZeroWorking`), `statementDeltasOf`, `roundingNoteNeeded`, `fixedCostsOf`. No money arithmetic in widgets (STANDARDS section 3, 4); every figure is read from the engine's result.
- `features/statement/`: `month_statement_screen.dart` (switcher, states, live updates, arrival: scroll, 600 ms flash, heading focus), `statement_state.dart`, `statement_text.dart` (visible text and spoken sentences, the wrapping points of the working line), `open_month_statement.dart` (`openMonthStatement(context, monthId, {scrollToPeriodStart})` and `monthStatementLauncherProvider`, a no-op seam first, T-405, now pushing the screen), `widgets/` (`totals_card`, `what_changed_card`, `period_card`, `working_strip`, `rich_money`); copy in `core/copy/statement_copy.dart`.
- Shared: `LedgerRow` (F-013 T-383) gained an optional `status` (mark and colour for Saved and Overspent); `formatRupeesSpoken` in `core/format/money_format.dart` and the shared `formatCompactRange` in `date_format.dart` (`formatClockTime` for the change time); `MonthSwitcher` and `MonthBrowser` belong to F-011.
- Wired from other features: Home (F-010 T-306), the Dashboard link row (F-013), and Day details change line (F-012) call `openMonthStatement`.

**Data stored.** None. No schema change and no migration. It reads the F-007 period history (each period's values, fixed costs and `created at`) through the engine's `MonthResult`; the only F-007 addition it uses is F-011's `watchMonthIndex` to browse months. The viewed month lives in memory: it starts on the month the screen was opened for and `This month` goes to the latest.

**Decisions:** D-081 (1) refunds written `Refunds −₹500`; (2) the working line starts with the amount the engine spreads (target when set, else salary) and does not name the target; (3) `, minus ₹X already budgeted` left out when X is ₹0; (4) a one-day period reads `30 Nov · 1 day`; (5) What changed has one line per stored record, compared with the previous record; (6) same-day changes that net to nothing read `Changed and changed back`; (7) `Paise.wholeRupees` only as a no-behaviour refactor; (8) the design example `so far on 20 Nov` corrected with seed M20 (T-407); (9) the launcher is its own seam (T-405). Also D-053 and D-062 (rounding note: the true total plus `a few rupees`), D-060 (Saved counts ended days, Overspent counts up to today), D-050 and D-055 (`less than ₹1`), D-085, D-086, D-088, D-100, D-102 to D-105.

**Deviations** (plan section 11)
- The screen keeps its own viewed month and the old content while the next month loads; past months show `Ended`, the latest month that is over shows no tag; `‹` disabled copy is the shared `No earlier months`.
- Fixed cost added and removed reasons carry the amount (`Fixed cost added: Gym ₹500`) as design section 7 and D-081 (5) say; TC-014-47 lists them without the amount and the Tester was to align the case.
- The working line wraps only between ` = `, `, minus ` and ` → ` while every chunk fits; when a chunk is wider than the strip (the design's five-line example cannot fit in 256 dp at 2.0x) it relaxes to wrapping at spaces, never inside an amount. TC-014-27 is two tests (strict at 640 dp, relaxed at 320 dp x 2.0).
- Wording not in the spec, flagged for the Designer: target changes read `Spending target set to ₹25,000`, `Spending target removed`, `Spending target ₹20,000 → ₹25,000`; the (i) texts of `Spent`, `Savings pot`, `Covered`; `the first day gets 1 paisa more`.
- Period cards have no (i) on their rows (design preview), only the totals card does. The arrival card sits at the top of the viewport. TalkBack focus follows the arrival only on devices where input focus drives it (manual TC-014-29).
- Gate 3 fixes: `TC-014-28` unit test of `formatRupeesSpoken`, unused `savedWord` / `overspentWord` removed, private `_compactRange` replaced by the shared function; `TC-014-06`, `-42`, `-52` (midnight) added, no screen bug.

**How it is tested** (`tests/F-014-month-statement.md`, 60 cases, 17 / 17 ACs)
- Unit: `test/domain/budget/month_statement_test.dart`, `statement_property_test.dart`, `statement_rounding_test.dart`, `test/core/format/money_format_test.dart` (spoken rupees); every worked example of spec 2.6 and 2.7 through `computeMonth`, checked to the paisa.
- Widget (fake repositories; five theme cases, text scale 2.0, small phone, landscape): `test/features/statement/` (`month_statement_screen_test`, `statement_months_test`, `open_month_statement_test`, `statement_sweep_test`), helper `test/helpers/statement_harness.dart`, shared fixtures `phase3_fixtures.dart` (seed M20). T-472 added TC-014-58 (a change made today: period in progress, Saved ₹0; the engine gives 13,26,000 paise over 22 days, `₹602/day`), TC-014-59 (no fixed costs, no expander) and TC-014-60 (day details of 20 Oct, tap the change line, the statement opens on October at the right period).
- Integration on the emulator: `integration_test/statement_speed_test.dart` (TC-014-30: 10 periods, 500 spends, limit 1,000 ms). Profile mode (D-100), `flutter drive --profile -d emulator-5554 --driver=test_driver/integration_test.dart --target=integration_test/statement_speed_test.dart`: worst of 5 is 110 ms in the clean run (`step8-clean-profile-statement_speed.log`), 118 ms in the Developer's T-429 run. Debug runs were 702 and 745 ms (`integration-statement-speed.log`); debug does not decide (D-100).
- Mutation pass (this file's mutants, the shared `LedgerRow` and the sweeps): 5 run. 2 killed on 2026-11-21 (amount dropped from the `LedgerRow` semantics; a fixed 600 dp amount in the statement sweep) and C4b (ledger colour without status) killed on the re-run by TC-013-59; the 30 dp and 0 dp row-height constants stay equivalent (the (i) button already gives 48 dp). T-472 probes, reverted: a period starting today not counted in progress and `already = 0` killed by TC-014-58; `if (false)` in the costs row and `fixed + 100` by TC-014-59; scroll target dropped, change line hidden in a past month and `monthId + 1` in day details by TC-014-60. The 600 ms flash and the once-only arrival are covered by TC-014-02 and -51, not re-asserted in TC-014-60. No money-calculation bug was found.
- Result (Tester 2, 2026-11-23): Pass 55, Partial 2, Fail 0, Blocked 1 (TC-014-29), Pending 2. No bug logged. `tool/check.ps1` last run: 1,285 tests green, domain coverage 100 %, TZ matrix passed. Gate 4: conditional pass (D-103).

**Known limitations and open items**
- **Not Done yet.** Open before Done (D-103, D-104): Tester 1's emulator session T-409: TC-014-49 (font 2.0 and landscape), TC-014-50 (four themes by eye), TC-014-51 (arrival flash with animations on and off) and TC-014-54 (kill on the statement). Also a green `tool/check.ps1` on the final code (Orchestrator), and Gate 5 with the Tester's final session.
- **TC-014-29 (TalkBack) is Blocked-needs-human**, accepted as open (D-104). Proofs in place: the spoken sentences (TC-014-28) and the sweeps are green. A real-phone walk is recommended, not required.
- The working line can wrap at spaces (never inside an amount) when a chunk is wider than the strip at large text. The rounding note says `a few rupees` (D-062); the totals show the true sum. PDF export is not built (later).
- Nice to have: none new from the Gate 4 review. The wording flagged for the Designer above is still to be recorded in the screen spec.
- Depends on F-006 (per-period results), F-007 (period history), F-011 (`MonthSwitcher`, month index), F-013 (`LedgerRow`). Used by F-010 (Home links), F-012 (Day details change line, scroll to the period), F-013 (`Month statement` link).

## 8. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-10 | First version of the spec (Phase 3 planned ahead, D-033). Team questions decided: the current month is labelled "so far"; every stored month can be viewed. D-047 refunds applied for display. Q-1 (totals rounding) raised to the Owner. 17 ACs | Product Manager |
| 2026-11-11 | Q-1 closed by D-053 (true total + note, the Owner's exact wording; AC-12, §5). D-048 (4): the month's shortfall is the current period's (§2.7 C4 already so). D-050: a sub-rupee shortfall reads `under ₹1 short` (§4). 17 ACs | Product Manager |
| 2026-11-11 | Small-amount wording switched from "under ₹1" to the Owner's literal "less than ₹1" (`overspent less than ₹1`, `saved less than ₹1`, `less than ₹1 left today`, `less than ₹1 short`, `less than ₹1 a day`), matching the Phase 2 change to D-050/D-055. Wording only, no AC added | Product Manager |
| 2026-11-11 | Status set to final Spec, ready for the plan (all Owner questions answered: D-053 to D-058). Remaining team questions go to the Project Manager at Phase 3 Gate 1 (phase overview, open items) | Product Manager |
| 2026-11-11 | §5 finalised by the Designer (`docs/design/screens/month-statement.md`): `Period <i> of <n>` overline, `For these days`, mid-month first change line, `Hide the fixed costs`, loading label, Refunds written `−<amount>` (AC-11 still says `Refunds ₹500`: flagged to the PM). D-053 note wording unchanged | Designer |
| 2026-11-11 | D-060 applied (T-225): Saved counts ended days, Overspent counts days up to and including today; the check line is asserted on ended periods and past months only (§2.3, §2.4, §2.6). Fixed the §2.3 example (`Spent ₹10,000` with `Refunds ₹500` gives `Net spent ₹9,500`, matching §2.6 Period 2 and AC-11) and the §2.6 "So far" ranges. D-062 (Owner): rounding note now says "a few rupees" (§5, AC-12, edge cases, Q-1 note). No AC added | Product Manager |
| 2026-11-16 | §2.6 "so far" paragraph aligned to the corrected seed M20 (T-407, D-081 note 1): figures added (Saved ₹2,115, Overspent ₹537, Pot ₹1,915, Left ₹6,900; Period 2 Spent ₹4,000, Saved ₹715, Overspent ₹297). The old ₹1,856 / ₹531 figures were only in the design, not here. No AC rule change | Product Manager |
| 2026-11-16 | Gate 1 (Project Manager B, D-081): AC-11 and §2.3 aligned to `Refunds −₹500`; new §2.8 (working line with a target, no `minus ₹0 already budgeted`, one-day heading, What changed per-record lines and wording, `Changed and changed back`). No AC added. 17 ACs | Project Manager |
| 2026-11-23 | Section 7 filled in (Step 9, T-410): built files, stored data (none), decisions D-081 to D-105, deviations, tests (profile-mode speed run, mutation pass), open items (T-409 emulator cases, TC-014-29 TalkBack). Status stays Testing until those are closed (D-103, D-105) | Developer |

## Impact on existing features
- **F-006:** needs per-period totals with **covered per period**, and the reason or diff of each period (F-006 §2.7 already lists these). It also needs refunds (D-047) in per-period spent.
- **F-007:** the period history must keep the **time** of each change (already in F-007 §2.1) and enough detail to name the change (old value → new value).

## Owner / team questions
- ~~Q-1~~ **Closed by D-053:** the true total is shown, with the note `Totals use exact amounts, so they can differ by a few rupees from the parts.` when the shown parts don't add up.
- ~~Team note (₹(n−1) gap)~~ **Closed by D-062:** the Owner chose "a few rupees"; the note reads `Totals use exact amounts, so they can differ by a few rupees from the parts.` (with *n* lines the gap can reach ₹(n−1), e.g. three periods of ₹100.90 show ₹100 each against a total of ₹302).

## Suggested additions *(for the CEO — not in scope until approved)*
- **PDF / share statement** (already planned "later", D-037).
- **A "why did my budget change?" banner** on Home for 1 day after a change, linking here.
