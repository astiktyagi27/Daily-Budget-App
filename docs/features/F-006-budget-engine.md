# F-006: Budget engine

| | |
|---|---|
| **Phase** | 2 |
| **Status** | Plan approved (Gate 1, 2026-11-10). All Owner decisions are applied: D-034 to D-040, D-042, D-043, D-046, D-047; Gate 1 rules D-048 |
| **Plan** | [`plans/F-006-budget-engine.md`](../../plans/F-006-budget-engine.md) |
| **Test cases** | [`tests/F-006-budget-engine.md`](../../tests/F-006-budget-engine.md) |
| **Tasks** | T-201 … T-205 (+ T-221) |

## 1. What it is *(Product Manager)*
The engine works out every money number in the app. It is pure Dart in `app/lib/domain/`: no Flutter, no database, no clock, no device settings. It takes these inputs:
- the salary day;
- the budget **periods** of the month (salary, optional lower target or "money left now", fixed costs, and the date each period starts);
- the spends per day, and any **money in** (refunds, money paid back) per day (D-047);
- the "cover with savings" moves;
- **today's date**, passed in.

From these it works out:
- the budget month's dates and length;
- each day's budget, in integer paise, adding up **exactly** to the money being spread;
- each day's result: saved, on budget or overspent;
- the savings pot, and whether a "cover with savings" is allowed;
- any shortfall;
- totals **per period** and for the whole month. These feed the top summary now and a month statement later (D-037).

It has no screen. F-008 (month setup preview) and F-009 (today line) show its numbers now, and the Phase 3 Home, calendar, dashboard and statement show the rest. Because it touches money, it is 100% branch-tested (STANDARDS §3–4). It can be built at once, in parallel with Phase 1 (D-033).

**User stories:**
- As a **user**, I want my daily budget worked out from my salary, target and fixed costs so that I know exactly what I can spend today.
- As a **user who starts mid-month**, I want the money I have left spread over the days that are left so that my budget is fair from day one (D-034).
- As a **user who changes my numbers mid-month**, I want past days to stay as they were and the change to apply from today, with a record of what changed when (D-037).
- As a **user**, I want saved money kept in a pot I control so that I decide whether it covers an overspent day (D-005).
- As the **Owner**, I want the README examples to come out exactly right, to the paisa.

## 2. How it behaves *(Product Manager)*
All amounts inside the engine are **integer paise** (`int`): ₹1,333.33 = `133333` (STANDARDS §4, D-010). Rupee figures below are for reading only. All dates are **calendar dates** with no time of day.

### 2.1 The budget month
- The user has one **salary day** from 1 to 31 (set in F-008).
- A budget month **starts** on the salary day in a calendar month. If that calendar month is too short (salary day 29, 30 or 31 in a short month), it starts on **that month's last day** instead.
- It **ends** on the day before the next month's start, found by the same rule.

| Salary day | Budget month | Days | Why |
|---|---|---|---|
| 5 | 5 Oct 2026 – 4 Nov 2026 | 31 | README §2 example |
| 5 | 5 Nov 2026 – 4 Dec 2026 | 30 | |
| 1 | 1 Feb 2027 – 28 Feb 2027 | 28 | Shortest month |
| 31 | 31 Jan 2027 – 27 Feb 2027 | 28 | Feb 2027 has no 31st, so the next start is 28 Feb |
| 31 | 28 Feb 2027 – 30 Mar 2027 | 31 | Starts on Feb's last day; next start is 31 Mar |
| 31 | 31 Mar 2027 – 29 Apr 2027 | 30 | April has no 31st, so the next start is 30 Apr |
| 30 | 30 Jan 2028 – 28 Feb 2028 | 30 | 2028 is a leap year, so Feb's start is the 29th |
| 30 | 29 Feb 2028 – 29 Mar 2028 | 30 | Leap day as a start date |
| 29 | 29 Jan 2027 – 27 Feb 2027 | 30 | Feb 2027 has no 29th, so the next start is 28 Feb |
| 29 | 29 Jan 2028 – 28 Feb 2028 | 31 | Leap year: the next start is 29 Feb |
| 1 | 1 Dec 2026 – 31 Dec 2026 | 31 | Year boundary: the next start is 1 Jan 2027 |
| 25 | 25 Dec 2026 – 24 Jan 2027 | 31 | Month crosses the year |

Every budget month is 28 to 31 days long. The **budgeted days** are the days from the first budgeted day to the month's end. This is the whole month, except for a mid-month install (§2.6).

### 2.2 Spendable money and the daily budget
- **Monthly target** = the salary, or a lower target the user chose (F-008).
- **Fixed costs** = the sum of all fixed-cost items (₹0 items count as ₹0).
- **Spendable** = target − fixed costs.
- **Spreading** an amount over a range of **N** days:
  - Every day gets `amount ÷ N` paise, rounded down.
  - The leftover `amount mod N` paise go **1 paisa each to the first days of that range** (D-035).
  - So the day budgets add up **exactly** to the amount.
- The range is the whole month in a normal month, today to month end for a mid-month install (§2.6), or today to month end after a change (§2.7).

**Worked examples** (E1–E3: budget month 5 Nov 2026 – 4 Dec 2026, 30 days; E4–E5: 5 Oct 2026 – 4 Nov 2026, 31 days):

| # | Inputs | Arithmetic in paise | Daily budgets (D-035: extra paisa on the first days) | Sum check |
|---|---|---|---|---|
| E1 | Salary ₹40,000, no fixed costs | 40,00,000 ÷ 30 = 1,33,333 remainder 10 | 5–14 Nov ₹1,333.34 (10 days); 15 Nov – 4 Dec ₹1,333.33 (20 days) | 10 × 1,33,334 + 20 × 1,33,333 = 40,00,000 ✓ |
| E2 | Salary ₹40,000 − rent ₹10,000 − EMI ₹5,000 − subscription ₹100 = ₹24,900 | 24,90,000 ÷ 30 = 83,000 remainder 0 | All 30 days ₹830.00 | 30 × 83,000 = 24,90,000 ✓ |
| E3 | Salary ₹40,000, target ₹20,000, no fixed costs | 20,00,000 ÷ 30 = 66,666 remainder 20 | 5–24 Nov ₹666.67 (20 days); 25 Nov – 4 Dec ₹666.66 (10 days) | 20 × 66,667 + 10 × 66,666 = 20,00,000 ✓ |
| E4 | Salary ₹40,000, no fixed costs | 40,00,000 ÷ 31 = 1,29,032 remainder 8 | 5–12 Oct ₹1,290.33 (8 days); 13 Oct – 4 Nov ₹1,290.32 (23 days) | 8 × 1,29,033 + 23 × 1,29,032 = 40,00,000 ✓ |
| E5 | Spendable ₹24,900 (D-035 example) | 24,90,000 ÷ 31 = 80,322 remainder 18 | 5–22 Oct ₹803.23 (18 days); 23 Oct – 4 Nov ₹803.22 (13 days) | 18 × 80,323 + 13 × 80,322 = 24,90,000 ✓ |

**On screen (D-038):**
- Every amount is shown in **whole rupees, rounded down** (the paise are dropped), using the shared money formatter (F-008 AC-19). Calculations always use the exact paise.
- So E1 shows **₹1,333** on every day, E2 **₹830**, E3 **₹666**, E4 **₹1,290** and E5 **₹803**. This matches the README and the phase goal.
- A day of ₹1,333.34 and a day of ₹1,333.33 both show as ₹1,333.
- The engine never rounds. Only the formatter does.

### 2.3 Each day
- **Net spend of a day** = the spends dated that day − the money in (refunds, money paid back) dated that day (D-047). It can go below ₹0 when the money in is larger than the spends. Salary is never money in.
- **Day result** = day budget − net spend that day + money covered from savings for that day. When the net spend is below ₹0, the day is saved by **more** than its budget (₹830 budget, ₹300 spent, ₹500 refund → net −₹200 → Saved ₹1,030).
- More than 0 is **Saved**, exactly 0 is **On budget**, less than 0 is **Overspent**.
- Days after today have no result yet ("upcoming"). Today has a **live** result.
- Days of the month before the first budgeted day (mid-month install) are **not budgeted**. They have no budget and no result, and they are not counted in any total.

| Day budget | Spent | Covered | Result | Shown as |
|---|---|---|---|---|
| ₹830 | ₹500 | – | +₹330 | Saved ₹330 |
| ₹830 | ₹830 | – | ₹0 | On budget |
| ₹830 | ₹1,000 | – | −₹170 | Overspent ₹170 |
| ₹830 | ₹1,000 | ₹170 | ₹0 | On budget (covered) |
| ₹830 | ₹1,000 | ₹100 | −₹70 | Overspent ₹70 (partly covered) |
| ₹0 (shortfall month, §2.8) | ₹200 | – | −₹200 | Overspent ₹200 |

### 2.4 Savings pot and "Cover with savings" (D-005)
- Saved amounts go into the **savings pot**.
- They are **never** added to tomorrow's budget. Tomorrow's day budget is the same whatever happened today.
- **Today's saving joins the pot when the day ends, at midnight (D-039).** During the day it is not in the pot. It is shown as **"₹X left today"**, e.g. ₹830 budget − ₹620 spent = "₹210 left today". Only days before today count towards the pot.
- **Pot balance** = the sum of saved results of the counted days − all amounts covered.
- **Cover with savings** moves an amount (more than ₹0) from the pot to **one overspent budgeted day** in the current month up to today. The engine refuses the cover (and changes nothing) if:
  - the amount is more than the pot balance;
  - the amount is more than that day's uncovered overspend;
  - the day is not overspent;
  - the day is upcoming, not budgeted, or outside the month.

  The most that can be covered is the lesser of the pot balance and the day's uncovered overspend.
  - **Today's live day can be covered** when it is overspent ("up to today"); it is checked like any other day (D-048).
  - **Refusal order (D-048):** when a cover breaks more than one rule, the first matching reason is reported, in this order: amount not more than ₹0 → day outside the month → day not budgeted → day upcoming → day not overspent → more than the day's uncovered overspend → more than the pot.
- **When an edit shrinks the pot below what was covered (D-040):**
  - The **newest covers are reduced first**, then older ones, until the pot is ₹0 or more. The pot is never below ₹0.
  - The engine reports every cover it reduced: the day, the old amount and the new amount. The screen that made the edit can then show a short note (F-009 AC-18).

### 2.5 Month totals (top summary, README §2)
| Total | Rule |
|---|---|
| Salary | The current period's salary (blank for a mid-month first month; §2.6) |
| Target | The current period's target, or the salary if none |
| Fixed costs | The current period's sum of items |
| Spent so far | All spends minus all money in (D-047) on budgeted days up to and including today. The money in is also reported on its own ("Money in") for the month statement |
| Saved this month | Sum of the saved results of days **before today** (D-039) |
| Covered | Sum of all covers |
| Overspent | Sum of the **uncovered** overspend of every budgeted day up to today |
| Savings pot | Saved this month − covered (≥ 0) |
| Shortfall | The **current period's** shortfall when it was continued with one (§2.8), e.g. −₹1,000. Otherwise ₹0. An earlier period's shortfall stays in the period history (D-048). With this rule "Left" always equals the current spendable − spent so far |
| Left | Money budgeted for the month (the sum of all day budgets) − spent so far − shortfall. It can go below ₹0 |

For a month with one period and no shortfall, "Left" = target − fixed costs − spent so far, the README formula.

**Worked example** (E2 month at ₹830 a day; today is 8 Nov, day 4):
- **Spends:** 5 Nov ₹500, 6 Nov ₹1,000, 7 Nov ₹830, 8 Nov ₹200.
- **Day results:** 5 Nov saved ₹330; 6 Nov overspent ₹170; 7 Nov on budget; 8 Nov is live: "₹630 left today", which joins the pot at midnight (D-039).
- **Totals:**
  - salary ₹40,000, fixed ₹15,100;
  - spent so far ₹2,530;
  - saved ₹330, overspent ₹170, pot ₹330;
  - left = 24,900 − 2,530 = **₹22,370**.
- **Cover 6 Nov with ₹170:** the pot becomes ₹160, 6 Nov becomes On budget (covered), and overspent becomes ₹0. A ₹200 cover would be refused (more than the ₹170 overspend). After a ₹100 cover, a further ₹400 would be refused (more than the ₹230 pot).

### 2.6 Mid-month install (D-034)
- If the first month is set up on a day that is not the month's start day, the user enters **how much money is left now**. The engine spreads it over the days **from today to the day before the next salary date**, with the extra paise on the first days (D-035).
- Days of the month before today are not budgeted (§2.3).
- **Fixed costs still to pay** in this first month are subtracted from the money left before spreading: spendable = money left now − fixed costs still to pay. The list is optional and starts empty (D-042).
- **Example 1:** salary day 5, first use **10 Nov 2026**, money left ₹24,900, no fixed costs still to pay.
  - The month is 5 Nov – 4 Dec and the budgeted days are 10 Nov – 4 Dec (25 days).
  - 24,90,000 ÷ 25 = 99,600, remainder 0, so **₹996 a day**.
  - 5–9 Nov are not budgeted.
- **Example 2:** first use **11 Nov 2026**, money left ₹20,000.
  - Budgeted days are 11 Nov – 4 Dec (24 days).
  - 20,00,000 ÷ 24 = 83,333 remainder 8, so 11–18 Nov get **₹833.34** and 19 Nov – 4 Dec get **₹833.33**.
  - Sum check: 8 × 83,334 + 16 × 83,333 = 20,00,000 ✓.
- **Example 3:** first use on **5 Nov**, the month's start day. This is a normal month: salary, target and fixed costs, as in §2.2.
- From the next month on, every month is a normal full month.
- **Editing "money left" later (D-048):** the stored value always means the money the user had **on the first budgeted day**. An edit on a later day is a §2.7 change: new money left − the budgets of the budgeted days before today, spread over today to month end. Example: started 10 Nov with ₹24,900 (₹996 a day); on 20 Nov the user corrects it to ₹26,400 → 26,40,000 − 10 × 99,600 = 16,44,000 over 15 days = **₹1,096 a day** (1,09,600 paise), and 10–19 Nov keep ₹996.

### 2.7 Mid-month changes and the period history (D-037)
- Any change to salary, target, fixed costs (adding, editing or deleting an item) or "money left" creates a **new dated period** starting **today**.
- Past days keep their budgets and their results. Spends are never changed by this.
- New spendable (from the changed values) − the sum of the budgets of all budgeted days **before today** = the **amount left to spread**. It is spread over **today to month end** (D-035 extra paise on the first of those days).
- Every period is kept and is **never overwritten** (F-007). It records its start date, the values in force (salary, target, each fixed-cost item, or money left), and the resulting daily budgets.
- If several changes are made on the same day, the latest one applies from that day. All of them are kept in the history with their time.
- **Per period**, the engine reports:
  - start and end date, and number of days;
  - the values in force and what changed from the previous period;
  - the amount spread and the daily budget(s);
  - spent, saved, overspent and covered;
  - any shortfall.
- Month totals are the sum over periods. A Phase 3 **month statement** shows this list (see F-009 Suggested additions).

**Worked examples** (E2 month 5 Nov – 4 Dec, ₹830 a day; change made on **20 Nov**, so 5–19 Nov = 15 past days = 15 × ₹830 = ₹12,450 already budgeted; 20 Nov – 4 Dec = 15 days left):

| # | Change on 20 Nov | New spendable | Amount left to spread | Daily budget 20 Nov – 4 Dec | Sum check |
|---|---|---|---|---|---|
| C1 | Rent ₹10,000 → ₹13,000 | 40,000 − 18,100 = ₹21,900 | 21,900 − 12,450 = ₹9,450 | 9,45,000 ÷ 15 = 63,000, so **₹630** every day | 12,450 + 15 × 630 = 21,900 ✓ |
| C2 | Rent ₹10,000 → ₹11,000 | 40,000 − 16,100 = ₹23,900 | ₹11,450 | 11,45,000 ÷ 15 = 76,333 r 5: 20–24 Nov **₹763.34**, 25 Nov – 4 Dec **₹763.33** | 5 × 76,334 + 10 × 76,333 = 11,45,000 ✓ |
| C3 | Salary ₹40,000 → ₹35,000 | 35,000 − 15,100 = ₹19,900 | ₹7,450 | 7,45,000 ÷ 15 = 49,666 r 10: 20–29 Nov **₹496.67**, 30 Nov – 4 Dec **₹496.66** | 10 × 49,667 + 5 × 49,666 = 7,45,000 ✓ |
| C4 | Target set to ₹25,000 | 25,000 − 15,100 = ₹9,900 | 9,900 − 12,450 = **−₹2,550** | Shortfall, §2.8 | — |

After C1 there are two periods:
- **Period 1:** 5–19 Nov, salary ₹40,000, fixed ₹15,100, ₹830 a day.
- **Period 2:** 20 Nov – 4 Dec, rent changed to ₹13,000, fixed ₹18,100, ₹630 a day.

A second change on 28 Nov would add **Period 3** from 28 Nov, and Period 2 would end on 27 Nov.

*D-037's own example* (1–30 Nov month at ₹830 a day, salary changed to ₹35,000 on 13 Nov):
- ₹19,900 − 12 × ₹830 = ₹9,940, spread over 18 days.
- 9,94,000 ÷ 18 = 55,222 remainder 4, so 13–16 Nov get ₹552.23 and 17–30 Nov get ₹552.22.
- On screen this is **₹552/day** (D-038), as D-037 now says.

### 2.8 Shortfall: fixed costs bigger than the target (D-036)
- A **shortfall** exists when the amount to spread is below ₹0:
  - target − fixed costs at month start;
  - money left − fixed costs still to pay at a mid-month install;
  - amount left to spread after a change (§2.7 C4).
- The engine reports the shortfall **amount** (positive paise) and **never** produces a negative day budget.
- The user chooses (F-008):
  - **Fix my numbers** (recommended): nothing is saved, and the month or change waits.
  - **Continue anyway:** the month or period is saved, and every day budget in its range is **₹0**.
- With **Continue anyway**:
  - the shortfall shows all month as a negative figure (e.g. **−₹1,000 this month**);
  - every spend makes its day Overspent;
  - "Left" includes the shortfall (§2.5).
- **Example S1:** salary ₹20,000 (no target), fixed costs ₹21,000 (rent ₹15,000 + EMI ₹6,000). The shortfall is 20,000 − 21,000 = **₹1,000**. If continued:
  - all 30 days are ₹0;
  - a ₹200 spend on 6 Nov gives Overspent ₹200;
  - on 6 Nov, Left = 0 − 200 − 1,000 = **−₹1,200**.
- **Example C4** (above), if continued: 20 Nov – 4 Dec are ₹0 a day, and the shortfall is **₹2,550**. Past days 5–19 Nov keep ₹830.
- **Fixed costs exactly equal to the target** (spendable ₹0): there is no shortfall, but every day budget is ₹0. F-008 shows the same warning, with "₹0 left for daily spending" and the same two choices (D-043). The engine reports "zero spendable" so F-008 can tell this case from a shortfall.

### 2.9 Inputs the screens never send (D-048)
- **"Today" before the month starts:** every budgeted day is upcoming; spent so far, saved, overspent, covered and pot are ₹0; Left = the month's budgets − shortfall.
- **"Today" after the month ends:** every budgeted day is final (no live day); the last day's saving is in the pot. This is what a month statement reads.
- **Invalid input** (salary day outside 1–31, a negative or zero spend or money-in amount, a negative salary, target or fixed cost, a target above the salary, a range of 0 days): the engine throws an `ArgumentError`. It never "fixes" a value silently. The checks are always on (not `assert`).

## 3. Acceptance criteria *(Product Manager)*
All ACs are checked by unit tests on the pure-Dart engine. "Today" is always passed in, never read from the clock. All amounts in ACs are exact paise. Display rounding (D-038) is tested in F-008 AC-19.

| ID | Given / When / Then |
|---|---|
| AC-1 | **Month dates.** Given each salary day and start month in the §2.1 table, when the engine computes the budget month, then the start date, end date and number of days match the table exactly. |
| AC-2 | **Every salary day, every month.** Given each salary day 1–31 and each start month from Jan 2026 to Dec 2030 (includes leap year 2028), when consecutive budget months are computed, then each month is 28–31 days long, each month starts the day after the previous one ends, and each start is the salary day or, if the calendar month is shorter, its last day. |
| AC-3 | **Spendable money.** Given salary, optional target and fixed costs, when spendable is computed, then it equals target − sum of fixed costs, with target = salary when none is set (E1 = 40,00,000, E2 = 24,90,000, E3 = 20,00,000 paise). |
| AC-4 | **README examples exact.** Given the E1–E5 inputs of §2.2, when daily budgets are computed, then the base amounts, the number of days with the extra paisa and the totals match the table exactly (E2 gives 83,000 paise on all 30 days). |
| AC-5 | **Sum is always exact.** Given at least 10,000 generated cases with amounts from 0 to 10,00,00,00,000 paise (₹10 crore) and ranges of 1–31 days, when the amount is spread, then every day budget is ≥ 0, any two day budgets differ by at most 1 paisa, and the day budgets sum **exactly** to the amount. |
| AC-6 | **Extra paise on the first days (D-035).** Given E1, E3, E5 and mid-month Example 2, when daily budgets are computed, then the days with the extra paisa are exactly the first days of the spread range: 5–14 Nov (E1), 5–24 Nov (E3), 5–22 Oct (E5), 11–18 Nov (Example 2); and after change C2 they are 20–24 Nov, with 5–19 Nov unchanged. |
| AC-7 | **Day result.** Given the six rows of the §2.3 table, when the day result is computed, then result and status match each row; days after today are "upcoming"; days before the first budgeted day are "not budgeted" with no result. |
| AC-8 | **Never auto-carried.** Given a day with saved ₹330, when the next day's budget is computed, then it equals its own day budget (₹830 in E2), unchanged by the previous day's saving or overspend. |
| AC-9 | **Savings pot: today joins at day end (D-039).** Given the §2.5 worked example, when the pot is computed with today = 8 Nov, then it equals ₹330 and 8 Nov is reported as "₹630 left today" (not in the pot); when computed with today = 9 Nov (no new spends), then the pot is ₹960 (330 + 630) and 8 Nov is Saved ₹630. |
| AC-10 | **Cover allowed.** Given the §2.5 example, when 6 Nov is covered with ₹170, then the pot becomes ₹160, 6 Nov's result becomes ₹0 (On budget, covered) and Overspent becomes ₹0; a partial cover of ₹100 instead leaves 6 Nov at −₹70 and the pot at ₹230. |
| AC-11 | **Cover refused.** Given the §2.5 example, when the engine is asked to cover (a) 6 Nov with ₹200, (b) 6 Nov with ₹400 after a ₹100 cover, (c) 5 Nov (saved), (d) 7 Nov (on budget), (e) 9 Nov (upcoming), (f) a date outside the month, (g) ₹0 or a negative amount, or (h) a not-budgeted day of a mid-month install, then each is refused with a distinct reason and the pot and all results are unchanged. |
| AC-12 | **Pot shrinks after an edit: newest covers reduced first (D-040).** Given today 10 Nov, 5 Nov saved ₹330, 8 Nov saved ₹630, 9 Nov on budget (spent ₹830) (pot ₹960 before covers), 6 Nov covered ₹170 on 8 Nov and 7 Nov (spend raised to ₹1,000) covered ₹170 on 9 Nov (pot ₹620), when 5 Nov's spend is raised from ₹500 to ₹830 and 8 Nov's from ₹200 to ₹830 (saved falls to ₹0, so covers ₹340 > saved ₹0), then the newest cover (7 Nov, made 9 Nov) is reduced from ₹170 to ₹0 first, then 6 Nov from ₹170 to ₹0; the pot is ₹0, never negative; 6 and 7 Nov are each Overspent ₹170 again; and the engine returns both reductions (day, old ₹170, new ₹0) in newest-first order. With only 5 Nov edited (saved ₹630 left, covers ₹340), then no cover is reduced and the pot is ₹290. |
| AC-13 | **Month totals.** Given the §2.5 worked example, when totals are computed on 8 Nov, then salary ₹40,000, target ₹40,000, fixed ₹15,100, spent so far ₹2,530, saved ₹330, covered ₹0, overspent ₹170, pot ₹330, shortfall ₹0 and left ₹22,370 — exactly, in paise; spends dated after today are not counted. |
| AC-14 | **Left can go negative.** Given E2 and spends totalling ₹25,000 by 20 Nov, when totals are computed, then left = −₹100 (−10,000 paise), with no error. |
| AC-15 | **Zero amounts.** Given (a) spendable exactly ₹0, (b) a fixed cost of ₹0, (c) a past day with no spends, when the engine runs, then (a) every day budget is 0 paise, no shortfall is reported and any spend makes that day Overspent, (b) the ₹0 item changes nothing, (c) that day's result equals its full budget (Saved) — with no division-by-zero or exception. |
| AC-16 | **Shortfall at month start (D-036).** Given salary ₹20,000 and fixed costs ₹21,000 (S1), when the engine computes the month, then it reports a shortfall of exactly 1,00,000 paise (₹1,000) and no negative day budget; when computed as "continued anyway", then all 30 day budgets are 0, a ₹200 spend on 6 Nov gives Overspent ₹200, and on 6 Nov the totals show shortfall ₹1,000 and left −₹1,200. |
| AC-17 | **Huge amounts.** Given salary ₹10 crore, fixed costs ₹0, a 31-day month and 31 spends of ₹10 crore each, when the engine runs, then the daily base is 32,25,80,645 paise with the first 5 days at +1 paisa, totals are exact, and no overflow or exception occurs. |
| AC-18 | **Mid-month install (D-034).** Given salary day 5 and the first setup on 10 Nov 2026 with money left ₹24,900, when the engine computes the month, then the budgeted days are 10 Nov – 4 Dec (25 days) at 99,600 paise each, 5–9 Nov are not budgeted, and the sum is 24,90,000; given the first setup on 11 Nov with ₹20,000, then 11–18 Nov are 83,334 and 19 Nov – 4 Dec are 83,333 paise (sum 20,00,000); given money left ₹24,900 with fixed costs still to pay ₹4,900, then ₹20,000 is spread over the 25 days (80,000 paise each); given the first setup on 5 Nov, then it is a normal full month. |
| AC-19 | **Mid-month change recalculates remaining days (D-037).** Given the E2 month with spends recorded on 5–19 Nov, when each of changes C1, C2 and C3 is applied on 20 Nov, then 5–19 Nov keep 83,000 paise and their results unchanged, 20 Nov – 4 Dec get the budgets in the §2.7 table exactly, the whole month's day budgets sum to the new spendable, and no spend or cover is changed. |
| AC-20 | **Change that causes a shortfall (D-036 + D-037).** Given change C4 on 20 Nov, when the engine computes it, then it reports a shortfall of ₹2,550 and no negative budget; when continued anyway, then 20 Nov – 4 Dec are 0 paise, 5–19 Nov keep 83,000 paise, and the month totals show shortfall ₹2,550. |
| AC-21 | **Period history and per-period results (D-037).** Given the E2 month, change C1 on 20 Nov and a second change (EMI ₹5,000 → ₹4,000) on 28 Nov, when the engine reports periods, then there are exactly 3 periods (5–19 Nov, 20–27 Nov, 28 Nov – 4 Dec), each with its start/end, the values in force, what changed, its daily budget(s), spent, saved, overspent and covered; the per-period totals add up exactly to the month totals; and period 3 spreads 21,900 + 1,000 − (12,450 + 8 × 630) = ₹5,410 over 7 days (77,285 paise r 5: 28 Nov – 2 Dec 77,286, 3–4 Dec 77,285). |
| AC-22 | **Same-day changes.** Given two changes on 20 Nov (rent → ₹13,000 at 10:00, then rent → ₹11,000 at 18:00), when the engine computes the month, then the 18:00 values apply from 20 Nov (as C2), both changes are present in the history in time order, and 5–19 Nov are unchanged. |
| AC-23 | **Dates only, no clock.** Given the same inputs and the same "today", when the engine test file is run in three separate test processes with POSIX time-zone settings `TZ=UTC`, `TZ=PST8PDT` and the default (IST) (look-ahead #8: IANA names are ignored on Windows), then every output is identical; and the engine source contains no call to `DateTime.now()` or any clock. |
| AC-24 | **Pure, integer-only, guarded.** Given `app/lib/domain/`, when the Tester runs the domain guard (TC-001-06, extended per the phase overview), then no file imports `package:flutter`, `dart:ui`, any `data/` or `features/` file or a database package; no money value uses `double` or `num` (code check agreed in the plan); and branch coverage of the engine files is 100%, meaning for every file in `lib/domain/budget/` the `lcov.info` from `flutter test --branch-coverage` has branches hit = branches found (`BRH = BRF`) and lines hit = lines found (`LH = LF`) (D-048). |
| AC-25 | **Money in reduces the day's spend (D-047).** Given the E2 month and today 14 Nov, when 12 Nov has a ₹300 spend and a ₹500 refund, then 12 Nov's net spend is −20,000 paise and its result is Saved +1,03,000 (₹1,030); when 13 Nov has only a ₹500 refund, then it is Saved +1,33,000; spent so far counts the net (refunds subtract), money in is reported as 1,00,000; the pot includes both days; a refund on an overspent, covered day lowers its overspend and the cover above it returns to the pot (§4 over-covered rule); a refund dated today makes the live day "left today" larger than its budget; and in a shortfall month (₹0 a day) a ₹500 refund alone makes the day Saved ₹500. |

## 4. Edge cases *(Product Manager)*
- **Salary day 29, 30 or 31** and short months: see §2.1 (AC-1, AC-2).
- **Leap day as a spend date** (29 Feb 2028): it belongs to whichever budget month contains it.
- **Remainder of N − 1 paise:** e.g. ₹0.29 over 30 days gives the first 29 days 1 paisa and the last day 0. The sum is exact (AC-5).
- **Mid-month install on the last day of the month:** the range is 1 day. All the money left goes to today.
- **Mid-month install on the start day:** a normal month (§2.6 Example 3).
- **Change made on the month's first day:** there are no past days, so the whole month is spread again. Period 1 is replaced by the latest values but is kept in the history (AC-22 rule).
- **Change made on the last day:** the range is 1 day (today).
- **A change that lowers costs after a shortfall month was continued:** the new period's amount to spread is recalculated. If it is now positive, the remaining days get a budget again, and the shortfall figure is that of the current period.
- **Spends dated before the first budgeted day** (mid-month install): F-009 blocks them. If given anyway, the engine ignores them for totals and reports them.
- **Covering the same day twice:** allowed until the day's uncovered overspend is ₹0.
- **An edit reduces a covered day's overspend** (6 Nov spend ₹1,000 → ₹900, overspend ₹70, but ₹170 covered): the cover above the overspend (₹100) returns to the pot. This follows the D-040 rule and needs no note, because the cover only goes down to the day's new overspend.
- **A period change doesn't touch the pot:** past results are unchanged, so the pot is unchanged by the change itself.
- **Device date moves backwards or forwards:** the engine only uses the "today" it is given.
- **Time-zone change while travelling:** spends keep their stored calendar date (AC-23).
- **Refunds / money in (D-047):** supported by the engine from Phase 2 (AC-25). A refund counts on the day it arrives, not on the day of the original purchase. Manual "money in" entry is not offered in Phase 2 (F-009 §6, D-051); Phase 4 SMS credits use the same rule.
- **Missed months / a new month set up late:** the engine is given whatever first budgeted day F-008 stores; per D-057 it is **today** (a fresh start, `MidMonthStartValues`), so days before setup are not budgeted and never Saved.

## 5. Help text & copy *(Product Manager, finalised by Designer)*
No screen in this feature. Terms the engine defines, used by F-008/F-009 and Phase 3 (wording for (i) explanations):

| Term | Label | Description / tooltip |
|---|---|---|
| Daily budget | `Daily budget` | `What you can spend each day: your spendable money divided by the days left in your budget month.` |
| Spendable | `Spendable this month` | `Your monthly target minus your fixed costs.` |
| Money left now (mid-month start) | `Money left now` | `How much you have to spend until your next salary.` |
| Saved (day) | `Saved` | `You spent less than the day's budget. The difference goes to your savings pot.` |
| Left today | `<amount> left today` | `What you can still spend today. Whatever is left at midnight goes to your savings pot.` |
| On budget | `On budget` | `You spent exactly the day's budget.` |
| Overspent | `Overspent` | `You spent more than the day's budget. You can cover it from your savings pot.` |
| Savings pot | `Savings pot` | `Money you saved on earlier days. It isn't added to tomorrow's budget, you decide how to use it.` |
| Shortfall | `Short this month` | `Your fixed costs are more than your monthly money. Every spend this month counts as overspent.` |
| Left | `Left this month` | `What's budgeted for this month minus what you've spent so far.` |
| Cover with savings | `Cover with savings` | `Use money from your savings pot to cover an overspent day.` |
| Period (statement) | `Budget changed on <date>` | `You changed your numbers, so the days from then on were worked out again. Earlier days stay as they were.` |

## 6. Out of scope
- Any screen (F-008, F-009 and Phase 3 show the numbers). The "Cover with savings" UI and the month statement screen are Phase 3; PDF export comes later (D-037).
- Reading or storing data (F-007). Detecting salary from SMS (Phase 4).
- Income other than the salary (refunds are money in, D-047, not income), carrying savings into the next month.
- Changing the salary **day** after the first month (F-008 out of scope).
- Categories and category totals (Phase 3/4).

## 7. How it works — technical *(Developer, filled in when the feature is Done)*
- **What was built:** a pure-Dart budget engine, no Flutter, no database, no clock. Callers pass in the salary day, the periods (with their changes), spends, covers and "today"; `computeMonth` returns every day's status, budget, spend and result, the savings pot, per-period results and month totals. Everything is integer paise (extension type `Paise`; leftover paise go to the first days, D-035). Built in T-201 … T-205, reworked after Gate 3 (M1 to M3, T-226), Gate 4 passed 2026-11-11.
- **Main files** (`app/lib/domain/budget/`, each its own library, imported through the export barrel `budget.dart`, D-059):
  - `calendar_date.dart` (`CalendarDate`, an extension type over the day number), `budget_month.dart` (`BudgetMonth`: start clamped to short months, `containing`, `next`, `previous`), `paise.dart` (`Paise`, `spreadOver`, `Paise.sum`).
  - `fixed_cost.dart`, `budget_period.dart` (sealed `PeriodValues`: `FullMonthValues`, `MidMonthStartValues`; `diff` for "what changed"), `spread_outcome.dart` (`planPeriod` giving sealed `Spread` / `ZeroSpendable` / `Shortfall`).
  - `spend.dart` (`SpendDirection`: spend or money in, D-047), `cover.dart`, `month_input.dart`, `month_result.dart` (records `DayResult`, `PeriodResult`, `MonthTotals`, `EffectiveCover`, `CoverReduction`; `MonthResult.currentPeriod`, `dayOn`), `budget_engine.dart` (`computeMonth`, `checkCover` with the D-048 refusal order, `monthStateFor`).
  - Quality gates: `app/test/architecture/domain_layering_test.dart`, `tool/domain_coverage.ps1`, `tool/tz_matrix.ps1`.
- **Decisions applied:** D-034 / D-042 / D-057 (mid-month and late first setup), D-035 (extra paise on the first days), D-036 / D-043 (shortfall and zero spendable, "continued anyway"), D-037 (changes re-spread the remaining days, dated period history), D-038 / D-046 (on-screen rounding is the UI's job; the engine stays exact), D-039 (today joins the pot at midnight), D-040 (newest covers reduced first), D-047 (money in lowers the day's spend), D-048 (engine rules settled at Gate 1, including invalid input throwing `ArgumentError`), D-059 (one library per file), D-060 (Overspent includes today's live overspend).
- **Deviations from the plan** (plan section 11, approved at Gate 3): `CalendarDate` is an extension type, not a class (E2); results are records, `DayStatus` an enum (E3); `MonthInput` has no `salaryDay`, `BudgetMonth` carries it (E4); `Paise` has no `<`, `<=`, `>=` until needed (E5); rules the plan left open are fixed in code (E6); coverage is counted by the script from `DA` / `BRDA` lines because this Flutter writes no `BRF` / `BRH` (E7); `check.ps1` is not changed here, the two scripts join it in T-206 (E9). E1 (one library of parts) was **not** approved and was replaced by D-059.
- **How it is tested:** 60 test cases TC-006-01 … -60 in `tests/F-006-budget-engine.md`, automated in `app/test/domain/budget/` (ten test files plus `engine_hardening_test.dart` and `fixtures.dart`) and `app/test/architecture/`. Includes seeded property tests (10,217 spread cases, 2,000 months, 2,000 changes, 1,000 sequences, seed 2026, or `--dart-define=PROPERTY_SEED=<n>`) and a canonical `dump()` compared across three time zones (`tool/tz_matrix.ps1`: UTC, PST8PDT, IST, identical hashes). `tool/domain_coverage.ps1` requires 100% lines and branches per file (`LH = LF`, `BRH = BRF`, AC-24). Test report passed at Gate 4.
- **Data stored:** none. The engine is pure; F-007 stores the inputs and F-008 / F-009 / F-010 supply and show them.
- **Depends on / used by:** depends on nothing in the app. Used by F-007 (converters map to the same value types), F-008 (month start, `monthStateFor`, `planPeriod`), F-009 (`computeMonth`, `checkCover`), F-010 (Home and day results), and later F-017 (safe to spend, D-058).
- **Known limitations:** no `debugTable()` yet (T-221); `Paise` comparison operators `<`, `<=`, `>=` are added when a later feature needs them; the engine never rounds for display (whole rupees, rounded down, D-038 / D-046, is done by the UI); the safe-to-spend figure (N2, D-058) belongs to the F-017 plan, not here.

## 8. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-10 | First version of the spec, with OD-2 to OD-5 and PM questions OD-6 to OD-8 marked pending | Product Manager |
| 2026-11-10 | Owner decisions applied: D-034 (mid-month install: money left ÷ days left, §2.6, AC-18), D-035 (extra paise on the first days, §2.2, AC-6, new example E5), D-036 refined (warn with shortfall; Fix my numbers / Continue anyway at ₹0 a day with the shortfall shown all month, §2.8, AC-16, AC-20), D-037 refined (recalculate remaining days, dated period history, per-period results, §2.7, AC-19, AC-21, AC-22). ACs 21 → 24. OD-6/7/8 still pending | Product Manager |
| 2026-11-10 | Final Owner decisions applied: D-038 (on-screen whole rupees rounded down, §2.2), D-039 (today's saving joins the pot at midnight, "₹X left today", §2.4, AC-9), D-040 (newest covers reduced first, reductions reported for a note, §2.4, AC-12), D-042 (§2.6), D-043 (§2.8). AC-23 uses POSIX `TZ` names per test process (look-ahead #8). D-037 example corrected to ₹552/day. No PENDING items left. Status: final Spec, ready for the plan. 24 ACs | Product Manager |
| 2026-11-10 | Gate 1 reconciliation: D-047 money in (§1, §2.3 net spend, §2.5 spent so far, §4, §6, new AC-25); D-048 rules: cover on today's live day allowed and the refusal order (§2.4), "money left" means money on the first budgeted day (§2.6), Shortfall total = current period's (§2.5), today outside the month and invalid input (new §2.9), 100% branches defined as `BRH = BRF`, `LH = LF` (AC-24). 25 ACs. Status → Plan approved | Project Manager |
| 2026-11-11 | Step 9: section 7 (technical) filled in; status → Done after Gate 4 passed | Developer |

## Open decisions *(all closed)*
| ID | Question | Decision |
|---|---|---|
| OD-2 | Mid-month install | D-034 (§2.6) |
| OD-3 | Leftover paise | D-035 (§2.2) |
| OD-4 | Fixed costs over the target | D-036 (§2.8) |
| OD-5 | Mid-month changes | D-037 (§2.7) |
| OD-6 | How money is shown | D-038: whole rupees, rounded down (§2.2) |
| OD-7 | Today's saving and the pot | D-039: joins at midnight, shown as "₹X left today" (§2.4) |
| OD-8 | Pot shrinks below covers | D-040: newest covers reduced first, pot ≥ ₹0, note shown (§2.4) |
| Q-A | Fixed costs still to pay at a mid-month install | D-042 (§2.6) |
| Q-B | Fixed costs equal to the target | D-043 (§2.8) |
| Q-C | D-037 example figure | Corrected in DECISIONS.md to ₹552/day (§2.7) |

## Suggested additions *(for the CEO — not in scope until approved)*
- **A "what if" preview** in month setup (change the target and see the daily budget move). The engine already supports it.
- **Month-end carry-over choice** (move the unspent pot into next month's target, or keep it as "saved"). Jupiter's "Pots" and Fi's "Jars" let users carry savings. Needs a new Owner decision.
