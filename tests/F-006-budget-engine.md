# Test Cases — F-006: Budget engine

| | |
|---|---|
| **Feature doc** | [`docs/features/F-006-budget-engine.md`](../docs/features/F-006-budget-engine.md) (final Spec, 24 ACs) |
| **Plan** | [`plans/F-006-budget-engine.md`](../plans/F-006-budget-engine.md) (Draft, read 2026-11-10 after these cases were written; its file and API names win over the proposals in §0. Its §6 proposed one TC per AC (TC-006-01 … -24); **this file is authoritative** (plan §6) and the AC → TC map is §2.4) |
| **Author** | Tester (written **before** development, approved by Project Manager at Gate 1) |
| **Status** | Passed (Step 8, Tester, 2026-11-11: TC-006-01 … -60, 60 / 60; Gate 4 passed by the Project Manager, 2026-11-11) |
| **Change history** | 2026-11-10 (Tester, Step 4): first version, TC-006-01 … TC-006-58. Same day: aligned with the Developer's draft plan (file names, impact §2.1, open questions in §2.3) and AC → TC map added (§2.4); no ID changed. 2026-11-10 (PM, Gate 1): rows TC-006-13, -42, -50, -57 set to the D-048 rules; new TC-006-59 (money-left edit) and TC-006-60 (D-047 money in); notes §2.3 answered; status Approved. 2026-11-11 (Tester, T-224 after PM Gate 3): TC-006-30 command skips `import`/`export`/`part`/`library` lines (D-059) and whole-line comments; TC-006-31 command counts `DA`/`BRDA` records (E7); real test file names recorded (plan §11 E10; T-226 adds `engine_hardening_test.dart` to TC-006-21, -43, -56, -60); TC-006-18 Expected states that Overspent includes today's live overspend (D-060); sections 3, 4 and 5 added with the Step 8 run. No ID changed |

## 0. How to run these cases

**Environment:** as F-002 §0 (Windows 11, PowerShell 5.1, Flutter 3.47.9 / Dart 3.13.7 at `C:\src\flutter`; setup S1 from F-001 §0). Commands run from `app/`. **Nothing in this file needs the emulator or a database**: the engine is pure Dart and every case except the command checks is a plain `flutter test` unit test.

**Rules every engine test follows**
- **Paise only.** Every expected value is written as an integer paise literal in the test (₹1,333.33 → `133333`), copied from the feature doc, never computed with the code under test. Rupee figures in this file are for reading.
- **"Today" is passed in**, never read from a clock. Tests never call `DateTime.now()`.
- **Dates are calendar dates** (the plan's `CalendarDate` value type in `domain/`, look-ahead #7). Tests build them from year/month/day.
- **Copy-free.** The engine has no screen. Words such as "Saved" or "₹630 left today" are checked in F-008/F-009; here the test checks the **status value** (saved / onBudget / overspent / upcoming / notBudgeted / live) and the paise.

**Fixtures** (shared helpers in `test/domain/budget/fixtures.dart`; names proposed)

| Name | Meaning |
|---|---|
| **E2** | Salary day 5; month 5 Nov 2026 – 4 Dec 2026 (30 days); salary 40,00,000; no target; fixed costs Rent 10,00,000 · EMI 5,00,000 · Subscriptions 10,000 (sum 15,10,000); spendable 24,90,000; 83,000 a day |
| **W1** | E2 + the F-006 §2.5 worked spends: 5 Nov 50,000 · 6 Nov 1,00,000 · 7 Nov 83,000 · 8 Nov 20,000; today 8 Nov |
| **W2** | AC-12 data: E2; today 10 Nov; spends 5 Nov 50,000 · 6 Nov 1,00,000 · 7 Nov 1,00,000 · 8 Nov 20,000 · 9 Nov 83,000; covers 6 Nov 17,000 (made 8 Nov 21:00) and 7 Nov 17,000 (made 9 Nov 21:00) |
| **S1** | Salary day 5; month 5 Nov – 4 Dec 2026; salary 20,00,000; no target; Rent 15,00,000 + EMI 6,00,000 (21,00,000) |
| **C1…C4** | The §2.7 changes on 20 Nov 2026 on top of E2 (C1 rent → 13,00,000 · C2 rent → 11,00,000 · C3 salary → 35,00,000 · C4 target 25,00,000) |
| **Seed** | Property tests use `Random(2026)` (fixed seed, as plan F-006 §2) and print the seed and the failing input in `reason:` so a failure can be replayed. A second run with `--dart-define=PROPERTY_SEED=<n>` may use another seed; the fixed seed is the one recorded in §4 |

**Property-style cases.** There is no property-testing package in the project; the Developer writes plain loops over generated inputs (fixed seed above). Each property test is **one** test per TC ID. They must still run in under 10 s each on this machine.

**Test files** (plan F-006 §2): `test/domain/budget/*_test.dart` (one file per area; the file names in the "Automated test" column are the Tester's proposal, the plan's names win), `test/domain/budget/spread_property_test.dart` (property cases TC-006-02, -03, -06, -07, -23, -47), `test/architecture/domain_layering_test.dart` (extends TC-001-06 without touching the Phase 0 test file; TC-006-28, -29, -30). Scripts: `tool/tz_matrix.ps1` (TC-006-27) and `tool/domain_coverage.ps1` (TC-006-31), both called by `tool/check.ps1`.

**[TZ]** marks the case that must also be run three times with a POSIX `TZ` value per process (§1.1 → TC-006-27; plan script `tool/tz_matrix.ps1`). IANA names are ignored on Windows (look-ahead #8), so only `TZ=UTC`, `TZ=PST8PDT` and the default (IST) are used.

## 1. Test cases
Types: **Auto-unit** · **Auto-widget** · **Auto-integration** · **Manual** (incl. **Manual (command)**).
Automated tests include the TC ID in their name, e.g. `test('TC-006-05 readme examples are exact to the paisa', …)`.
**Regression = yes** means the case is re-run in every full regression (automated cases always are; mark important manual cases yes).

| ID | AC | Scenario | Test data | Steps | Expected | Type | Automated test | Regression |
|---|---|---|---|---|---|---|---|---|
| TC-006-01 | AC-1 | Budget month dates for the §2.1 table | The 12 rows of F-006 §2.1 as (salary day, a date inside the month) | For each row compute the budget month containing the row's start date, and also the one containing its end date | Start, end and day count equal the table exactly for all 12 rows: 5 → 5 Oct–4 Nov 2026 (31); 5 → 5 Nov–4 Dec 2026 (30); 1 → 1–28 Feb 2027 (28); 31 → 31 Jan–27 Feb 2027 (28); 31 → 28 Feb–30 Mar 2027 (31); 31 → 31 Mar–29 Apr 2027 (30); 30 → 30 Jan–28 Feb 2028 (30); 30 → 29 Feb–29 Mar 2028 (30); 29 → 29 Jan–27 Feb 2027 (30); 29 → 29 Jan–28 Feb 2028 (31); 1 → 1–31 Dec 2026 (31); 25 → 25 Dec 2026–24 Jan 2027 (31). Start date and end date give the **same** month | Auto-unit | `TC-006-01 budget month dates match the spec table` (`budget_month_test.dart`) | yes |
| TC-006-02 | AC-2 | **Property:** every salary day 1–31, every start month Jan 2026 – Dec 2030 | 31 salary days × 60 consecutive months = 1,860 months | For each salary day: compute the month starting in Jan 2026, then the next one 59 times | For every month: 28 ≤ days ≤ 31; start = the salary day, or the calendar month's last day when the month is shorter (`min(day, lastDay)`); start of month k+1 = end of month k + 1 day (no gap, no overlap); the 60 months of each salary day cover exactly 1,826 days (start of Jan 2026 to the day before the start of Jan 2031). Leap year: salary day 29/30/31 starts on **29 Feb 2028**, and day 29 never "sticks" to the 28th after Feb 2027 (Mar 2027 starts on 29 Mar) | Auto-unit | `TC-006-02 every salary day gives valid consecutive months 2026 to 2030` (`spread_property_test.dart`) | yes |
| TC-006-03 | AC-1, AC-2 | **Property:** every date belongs to exactly one budget month | Every calendar date 1 Jan 2026 – 31 Dec 2030 (1,826 dates) × salary days 1–31 | Compute the month containing each date | `start ≤ date ≤ end` every time; the month found for `end + 1` starts on `end + 1`. 29 Feb 2028 belongs to: day 1 → 1–29 Feb 2028; day 15 → 15 Feb–14 Mar 2028; day 29 → 29 Feb–28 Mar 2028 (start); day 30 → 29 Feb–29 Mar 2028 (start); day 31 → 29 Feb–30 Mar 2028 (start) | Auto-unit | `TC-006-03 every date belongs to exactly one budget month` (`spread_property_test.dart`) | yes |
| TC-006-04 | AC-3 | Spendable money | (a) E1: salary 40,00,000, no target, no costs. (b) E2. (c) E3: salary 40,00,000, target 20,00,000. (d) target = salary 40,00,000 + E2 costs. (e) target 20,00,000 + E2 costs | Compute spendable | (a) 40,00,000 (b) 24,90,000 (c) 20,00,000 (d) 24,90,000 (same as no target) (e) 4,90,000 | Auto-unit | `TC-006-04 spendable is target minus fixed costs` (`spread_test.dart`) | yes |
| TC-006-05 | AC-4 | README / D-035 worked examples E1–E5, exact | E1–E3 on 5 Nov–4 Dec 2026 (30 days); E4–E5 on 5 Oct–4 Nov 2026 (31 days); E5 = spendable 24,90,000 (e.g. salary 40,00,000 − costs 15,10,000) | Compute the month's day budgets | **E1:** 5–14 Nov = 1,33,334 (10 days), 15 Nov–4 Dec = 1,33,333 (20). **E2:** all 30 days = 83,000. **E3:** 5–24 Nov = 66,667 (20), 25 Nov–4 Dec = 66,666 (10). **E4:** 5–12 Oct = 1,29,033 (8), 13 Oct–4 Nov = 1,29,032 (23). **E5 (D-035):** 5–22 Oct = 80,323 (18), 23 Oct–4 Nov = 80,322 (13). Each list has exactly the month's day count and sums to 40,00,000 / 24,90,000 / 20,00,000 / 40,00,000 / 24,90,000 | Auto-unit | `TC-006-05 readme examples are exact to the paisa` (`spread_test.dart`) | yes |
| TC-006-06 | AC-5, AC-6 | **Property:** spread is exact, fair and front-loaded | ≥ 10,000 generated (amount, N): amount uniform in 0 … 10,00,00,00,000 (₹10 crore), plus a log-uniform half so small amounts (0–100 paise) appear often; N in 1–31. **Plus fixed boundary rows for every N 1–31:** amount 0, 1, N−1, N, N+1, 2N−1, 10,00,00,00,000 | Spread amount over N days | For every case: N values; each ≥ 0; max − min ≤ 1; sum == amount exactly; with `q = amount ~/ N`, `r = amount % N`: the first r values are q+1 and the rest q (D-035, so the extra paise are always the **first** days); no exception | Auto-unit | `TC-006-06 spreading always sums exactly and puts extra paise first` (`spread_property_test.dart`) | yes |
| TC-006-07 | AC-5 | **Property:** a whole computed month sums to its spendable | ≥ 2,000 generated months: salary day 1–31, start month Jan 2026–Dec 2030, salary 1 … 10,00,00,00,000, target none or 1 … salary, 0–30 fixed costs each 0 … 10,00,00,00,000 | Compute the month | If target − costs ≥ 0: day count = month length, sum of day budgets == target − costs exactly, every value ≥ 0. If < 0: shortfall == costs − target exactly, every day budget is 0 (when continued) and none is negative | Auto-unit | `TC-006-07 every generated month sums exactly to its spendable` (`spread_property_test.dart`) | yes |
| TC-006-08 | AC-6 | Extra paisa on the first days, named dates | E1, E3, E5, mid-month Example 2 (first setup 11 Nov 2026, money left 20,00,000), C2 | Compute; list the dates whose budget is the higher value | Exactly: 5–14 Nov (E1); 5–24 Nov (E3); 5–22 Oct (E5); 11–18 Nov (Example 2); after C2: 20–24 Nov at 76,334 and 25 Nov–4 Dec at 76,333, while 5–19 Nov stay 83,000 | Auto-unit | `TC-006-08 extra paise go to the first days of the spread range` (`spread_test.dart`) | yes |
| TC-006-09 | AC-7 | Day result for the six §2.3 rows, plus upcoming and not budgeted | Rows (budget / spent / covered): 83,000/50,000/0 · 83,000/83,000/0 · 83,000/1,00,000/0 · 83,000/1,00,000/17,000 · 83,000/1,00,000/10,000 · 0 (S1 continued)/20,000/0. Day is before today. Plus W1 with 9 Nov (after today) and a mid-month install on 10 Nov (5 Nov not budgeted) | Compute each day result | Results +33,000 saved · 0 onBudget · −17,000 overspent · 0 onBudget (covered flag true) · −7,000 overspent (partly covered) · −20,000 overspent. 9 Nov: status upcoming, no result value. 8 Nov in W1 (today): status live, remaining 63,000. Mid-month 5 Nov: notBudgeted, no budget, no result, excluded from every total | Auto-unit | `TC-006-09 day result status for every case` (`day_result_test.dart`) | yes |
| TC-006-10 | AC-8 | Savings are never carried to the next day | E2; (a) 5 Nov spent 50,000 (saved 33,000); (b) 5 Nov spent 1,00,000 (overspent 17,000); (c) no spends; today 7 Nov | Compute 6 Nov's day budget in each | 6 Nov budget = 83,000 in (a), (b) and (c); identical day-budget lists in all three | Auto-unit | `TC-006-10 a saving or overspend never changes the next day budget` (`day_result_test.dart`) | yes |
| TC-006-11 | AC-9 | Today's leftover joins the pot only at day end (D-039) | W1 | 1. Compute with today = 8 Nov. 2. Same spends, today = 9 Nov | 1. Pot = 33,000; 8 Nov status live with 63,000 left; Saved this month = 33,000. 2. Pot = 96,000 (33,000 + 63,000); 8 Nov status saved +63,000; 6 Nov's −17,000 does **not** reduce the pot (pot = saved − covered, overspend is separate) | Auto-unit | `TC-006-11 todays leftover joins the pot at midnight` (`savings_pot_test.dart`) | yes |
| TC-006-12 | AC-10 | Cover allowed: full and partial | W1 (pot 33,000) | (a) Cover 6 Nov with 17,000. (b) Fresh W1: cover 6 Nov with 10,000 | (a) Accepted; pot 16,000; 6 Nov result 0, onBudget, covered; month Overspent total 0; Covered total 17,000. (b) Accepted; 6 Nov −7,000 overspent (partly covered); pot 23,000; Overspent total 7,000 | Auto-unit | `TC-006-12 cover with savings moves pot money to an overspent day` (`savings_pot_test.dart`) | yes |
| TC-006-13 | AC-11 | Cover refused, with a distinct reason, nothing changed | W1; and a mid-month install on 10 Nov (today 12 Nov, pot > 0 from 10–11 Nov savings) for (h) | Ask to cover: (a) 6 Nov 20,000; (b) after a 10,000 cover, 6 Nov 40,000; (c) 5 Nov (saved); (d) 7 Nov (on budget); (e) 9 Nov (upcoming); (f) 5 Dec 2026 and 4 Nov 2026 (outside the month); (g) 0 and −100; (h) 5 Nov of the mid-month month (not budgeted); (j) pot-only case: W1 with 5 Nov spend 80,000 (pot 3,000), cover 6 Nov 5,000 | (a) refused: more than the day's overspend; (b) refused: more than the day's overspend (40,000 > 7,000; it is also more than the 23,000 pot, and the D-048 order puts the overspend check first); (c)/(d) refused: day not overspent (same reason); (e) refused: upcoming; (f) refused: outside the month; (g) refused: amount not positive; (h) refused: not budgeted; (j) refused: more than the pot (5,000 ≤ 17,000 overspend, > 3,000 pot). Seven **different** reason values in total. After every refusal the full engine output (all day results, pot, totals) equals the output before (deep equality) | Auto-unit | `TC-006-13 invalid covers are refused with distinct reasons and change nothing` (`savings_pot_test.dart`) | yes |
| TC-006-14 | AC-12 | Pot shrinks after an edit: newest covers reduced first (D-040) | W2 (pot 96,000 before covers, 62,000 after) | 1. Edit 5 Nov spend 50,000 → 83,000 and 8 Nov 20,000 → 83,000; recompute. 2. Fresh W2: edit only 5 Nov 50,000 → 83,000 | 1. Saved = 0; 7 Nov cover (made 9 Nov) 17,000 → 0 first, then 6 Nov (made 8 Nov) 17,000 → 0; pot 0 (never negative); 6 and 7 Nov each overspent −17,000 again; reductions list = [(7 Nov, 17,000, 0), (6 Nov, 17,000, 0)] in that order (newest first). 2. Saved 63,000, covers 34,000, pot 29,000; reductions list empty | Auto-unit | `TC-006-14 shrinking pot reduces newest covers first` (`savings_pot_test.dart`) | yes |
| TC-006-15 | AC-13 | Month totals on 8 Nov | W1, plus a spend of 40,000 dated 10 Nov (future, must be ignored) | Compute totals, today 8 Nov | Salary 40,00,000; target 40,00,000; fixed 15,10,000; spent so far 2,53,000; saved 33,000; covered 0; overspent 17,000; pot 33,000; shortfall 0; left 22,37,000. The 10 Nov spend is not in spent so far or left | Auto-unit | `TC-006-15 month totals match the worked example` (`month_totals_test.dart`) | yes |
| TC-006-16 | AC-14 | Left can go below ₹0 | E2; spends totalling 25,00,000 on 5–20 Nov (e.g. 16 × 1,56,250); today 20 Nov | Compute totals | Left = −10,000; no exception; overspent and pot computed normally | Auto-unit | `TC-006-16 left can go negative without error` (`month_totals_test.dart`) | yes |
| TC-006-17 | AC-15 | Zero amounts | (a) salary 15,10,000, E2 costs (spendable 0); 6 Nov spend 100. (b) E2 + item "Gym" 0. (c) E2, no spends, today 8 Nov | Compute | (a) all 30 day budgets 0; shortfall 0; the "zero spendable" flag is true (distinct from shortfall, D-043); 6 Nov overspent −100. (b) day budgets identical to E2 (83,000 ×30); fixed 15,10,000. (c) 5–7 Nov each saved +83,000; pot 2,49,000. No exception, no division by zero anywhere | Auto-unit | `TC-006-17 zero amounts never divide by zero` (`shortfall_test.dart`) | yes |
| TC-006-18 | AC-16 | Shortfall at month start, then continued (D-036) | S1; continued-anyway flag; 6 Nov spend 20,000; today 6 Nov | 1. Compute without continuing. 2. Compute as continued | 1. Shortfall = 1,00,000; no day budget below 0; result says "needs a choice" (not saved). 2. 30 day budgets = 0; 6 Nov (today, still live) overspent −20,000; totals on 6 Nov: **Overspent 20,000 (today's live overspend counts in Overspent, D-060, AC-13)**, shortfall 1,00,000, left −1,20,000; on 7 Nov the same day is status overspent | Auto-unit | `TC-006-18 shortfall at month start is reported and can be continued at zero` (`shortfall_test.dart`) | yes |
| TC-006-19 | AC-17 | Huge amounts, no overflow | Salary 10,00,00,00,000 (₹10 crore), no costs, 31-day month 5 Oct–4 Nov 2026; 31 spends of 10,00,00,00,000 (one per day); today 4 Nov | Compute | Day base 32,25,80,645; 5–9 Oct = 32,25,80,646 (5 days); sum 10,00,00,00,000; spent so far 3,10,00,00,00,000; overspent and left exact (left = 10,00,00,00,000 − 3,10,00,00,00,000 = −3,00,00,00,00,000); no exception. (Dart `int` is 64-bit on the VM and on Android; the test also asserts no intermediate value is a `double`) | Auto-unit | `TC-006-19 ten crore amounts stay exact` (`month_totals_test.dart`) | yes |
| TC-006-20 | AC-18 | Mid-month install (D-034, D-042) | Salary day 5; (a) first setup 10 Nov 2026, money left 24,90,000; (b) 11 Nov, 20,00,000; (c) 10 Nov, 24,90,000, still to pay 4,90,000; (d) 5 Nov with salary 40,00,000 + E2 costs | Compute the first month | (a) budgeted 10 Nov–4 Dec (25 days) at 99,600 each, sum 24,90,000; 5–9 Nov notBudgeted. (b) 11–18 Nov 83,334 (8), 19 Nov–4 Dec 83,333 (16), sum 20,00,000. (c) 20,00,000 spread over 25 days = 80,000 each. (d) normal full month = E2 (83,000 ×30), first budgeted day 5 Nov. Totals: Salary blank (none) for (a)–(c) | Auto-unit | `TC-006-20 mid month install spreads money left over the days left` (`mid_month_test.dart`) | yes |
| TC-006-21 | AC-19 | Mid-month changes C1–C3 keep the past | E2 with one spend per day 5–19 Nov (varied: 50,000 / 83,000 / 1,00,000 rotating) and the W1 6 Nov cover; snapshot results of 5–19 Nov | Apply C1, C2, C3 (each on a fresh copy) on 20 Nov | 5–19 Nov: budget 83,000 and results identical to the snapshot. **C1:** 20 Nov–4 Dec 63,000 ×15. **C2:** 20–24 Nov 76,334, 25 Nov–4 Dec 76,333. **C3:** 20–29 Nov 49,667, 30 Nov–4 Dec 49,666. Whole-month sum = new spendable (21,90,000 / 23,90,000 / 19,90,000). Spends and covers unchanged (deep equality) | Auto-unit | `TC-006-21 mid month change recalculates only the remaining days` (`periods_test.dart`) Also T-226 hardening: `TC-006-21 currentPeriod is the period in force today` (`engine_hardening_test.dart`). | yes |
| TC-006-22 | AC-19 | D-037's own example: ₹552 a day | Salary day 1; month 1–30 Nov 2026; salary 40,00,000; costs 15,10,000 (83,000 a day); on 13 Nov salary → 35,00,000 | Compute | 1–12 Nov 83,000; amount left 9,94,000; 13–16 Nov 55,223, 17–30 Nov 55,222; sum of month 19,90,000 | Auto-unit | `TC-006-22 decision d037 example gives 552 a day` (`periods_test.dart`) | yes |
| TC-006-23 | AC-19 | **Property:** any change on any day keeps the past and sums exactly | ≥ 2,000 generated: random month (as TC-006-07), random change day inside it, random new salary/target/costs that still leave ≥ 0 to spread | Snapshot before; apply change; recompute | Every day before the change day keeps its budget; days from the change day on match `spread(newSpendable − pastBudgets, daysLeft)` (TC-006-06 rule); whole-month sum == new spendable | Auto-unit | `TC-006-23 any change keeps past days and sums to the new spendable` (`spread_property_test.dart`) | yes |
| TC-006-24 | AC-20 | Change that causes a shortfall (C4) | E2; C4 on 20 Nov | 1. Compute. 2. Compute as continued | 1. Shortfall 2,55,000; no negative budget; change "needs a choice". 2. 20 Nov–4 Dec = 0; 5–19 Nov = 83,000; month totals shortfall 2,55,000; left = 12,45,000 − spent − 2,55,000 | Auto-unit | `TC-006-24 change causing a shortfall reports it and continues at zero` (`shortfall_test.dart`) | yes |
| TC-006-25 | AC-21 | Period history with per-period results | E2; C1 on 20 Nov; EMI 5,00,000 → 4,00,000 on 28 Nov; spends on several days in each period; one cover in period 1 | Ask the engine for periods | Exactly 3 periods: P1 5–19 Nov (15 days, salary 40,00,000, fixed 15,10,000, 83,000/day, change = none/initial); P2 20–27 Nov (8 days, rent 10,00,000 → 13,00,000, fixed 18,10,000, 63,000/day); P3 28 Nov–4 Dec (7 days, EMI 5,00,000 → 4,00,000, fixed 17,10,000, amount spread 5,41,000: 28 Nov–2 Dec 77,286, 3–4 Dec 77,285). Each has spent, saved, overspent, covered, shortfall; Σ period values == month totals exactly | Auto-unit | `TC-006-25 period history reports three periods with exact results` (`periods_test.dart`) | yes |
| TC-006-26 | AC-22 | Same-day changes: latest wins, all kept | E2; on 20 Nov rent → 13,00,000 at 10:00 and rent → 11,00,000 at 18:00; also the same two given in reverse list order | Compute | 20 Nov–4 Dec = C2 budgets (76,334 ×5, 76,333 ×10); history holds both changes in time order (10:00 then 18:00) regardless of input order; the effective period from 20 Nov uses the 18:00 values; 5–19 Nov unchanged | Auto-unit | `TC-006-26 same day changes apply the latest and keep both` (`periods_test.dart`) | yes |
| TC-006-27 | AC-23 | Same output in three time zones **[TZ]** | The whole engine test folder; plus a sentinel test in `engine_time_zone_test.dart` | See §1.1 → TC-006-27: run `test/domain/` three times (`TZ=UTC`, `TZ=PST8PDT`, default). The sentinel test asserts the process really is in the expected zone (`DateTime(2026, 11, 9).timeZoneOffset` = 0 h / −8 h / +5:30 h, read from `--dart-define=EXPECT_TZ_OFFSET_MIN`) and writes a canonical dump of the W2 + C1 + C4 outputs to `build/tz/<zone>.txt` | All three runs pass; the three dumps are byte-identical; the sentinel passes in each run (so the zone change was real, not silently ignored) | Manual (command) + Auto-unit | `TC-006-27 engine output does not depend on the time zone` (`engine_time_zone_test.dart`) | yes |
| TC-006-28 | AC-23 | No clock in the engine | `lib/domain/**.dart` | See §1.1 → TC-006-28; automated guard scans the same files | 0 matches for `DateTime.now`, `Clock`, `clock.`, `Stopwatch`, `DateTime.timestamp`, `.toLocal(`, `timeZoneOffset` in `lib/domain/` | Manual (command) + Auto-unit | `TC-006-28 domain code never reads the clock` (`test/architecture/domain_layering_test.dart`) | yes |
| TC-006-29 | AC-24 | Domain guard extended (layer direction) | `lib/domain/**.dart` | TC-001-06 guard, extended | 0 imports of `package:flutter`, `dart:ui`, `package:daily_budget/data/`, `package:daily_budget/features/`, relative `../data/` / `../features/`, `package:drift`, `package:sqlite3`, `package:shared_preferences`, `dart:io`. A deliberately bad fixture string in the test proves the guard can fail | Auto-unit | `TC-001-06 domain contains no Flutter or dart:ui imports` (existing) + `TC-006-29 domain does not import data features or database packages` (`test/architecture/domain_layering_test.dart`) | yes |
| TC-006-30 | AC-24 | No floating point for money | `lib/domain/budget/**.dart` (folder per plan) | See §1.1 → TC-006-30; automated guard scans the same files (pattern agreed in the plan) | 0 matches for `double`, `num `, `num>`, `num?`, `.toDouble(`, `toStringAsFixed`, `.round(`, `.floor(`, `.ceil(`, and the `/` division operator (only `~/` and `%`) in engine files | Manual (command) + Auto-unit | `TC-006-30 engine uses integers only for money` (`test/architecture/domain_layering_test.dart`) | yes |
| TC-006-31 | AC-24 | 100% branch coverage of the engine files | `flutter test --branch-coverage test/domain/` | See §1.1 → TC-006-31 | For every engine file in `lib/domain/budget/`: `BRH == BRF` and `LH == LF`, counted from the `DA`/`BRDA` records in `coverage/lcov.info` (§1.1; Flutter 3.47.9 writes no summary lines); record the numbers. Any uncovered branch is a Fail (not a note) | Manual (command) | script `tool/domain_coverage.ps1` (same count, PASS/FAIL per file) | yes |

### 1.1 Commands

**TC-006-27** (from `app/`; the three runs must be separate processes. `tool/tz_matrix.ps1` from plan F-006 T-205 does the same; this command is the independent check, and it adds the sentinel and the dump comparison)
```powershell
$runs = @(@{tz='UTC'; off=0}, @{tz='PST8PDT'; off=-480}, @{tz=$null; off=330})
foreach ($r in $runs) {
  if ($r.tz) { $env:TZ = $r.tz } else { Remove-Item Env:TZ -ErrorAction SilentlyContinue }
  flutter test test/domain/ --dart-define=EXPECT_TZ_OFFSET_MIN=$($r.off) --dart-define=TZ_NAME=$(if ($r.tz) {$r.tz} else {'IST'}); "exit $LASTEXITCODE"
}
Remove-Item Env:TZ -ErrorAction SilentlyContinue
Get-FileHash build\tz\*.txt | Format-Table Hash, Path
```
Expected: three `exit 0`; three dump files with one identical hash. (November is outside US daylight saving, so `PST8PDT` is −8 h on 9 Nov 2026.) If `check.ps1` gains this step in the plan, this command is its proof.

**TC-006-28** (from `app/`)
```powershell
Get-ChildItem lib\domain -Recurse -Filter *.dart | Select-String -Pattern 'DateTime\.now','DateTime\.timestamp','\bClock\b','\bclock\.','Stopwatch','\.toLocal\(','timeZoneOffset'
```
Expected: no output.

**TC-006-30** (from `app/`; folder per plan)
```powershell
Get-ChildItem lib\domain\budget -Recurse -Filter *.dart | Select-String -Pattern '\bdouble\b','\bnum\b','toDouble\(','toStringAsFixed','\.round\(','\.floor\(','\.ceil\(','[^~/]/[^/=*]' | Where-Object { $_.Line -notmatch '^\s*(import|export|part|library)\b' -and $_.Line -notmatch '^\s*//' }
```
Expected: no output. Since D-059 every file starts with `package:` imports and `budget.dart` is an export barrel, and the `/` pattern also matches the `/` in a URI, so directive lines are skipped (PM, Gate 3 M1). The second filter skips whole-line `//` and `///` comments: the plain pattern also hits a doc comment such as `Add/Edit` (`spend_draft.dart:60`), which is not division. The automated guard also blanks string literals and cuts trailing `// ...` comments; this command does not, so a trailing comment or string containing `/` would show as a hit and is judged by hand (Developer informed, not waved through). Run 2026-11-11: no output.

**TC-006-31** (from `app/`; `tool/domain_coverage.ps1` from plan F-006 T-205 automates the same check, this is the independent cross-check)
```powershell
flutter test --branch-coverage test/domain/
$cur = $null; $s = @{}
foreach ($l in Get-Content coverage\lcov.info) {
  if ($l -like 'SF:*') { $cur = $l.Substring(3); $s[$cur] = @{LF=0;LH=0;BRF=0;BRH=0} }
  elseif ($l -match '^DA:\d+,(\d+)') { $s[$cur].LF++; if ([int64]$Matches[1] -gt 0) { $s[$cur].LH++ } }
  elseif ($l -match '^BRDA:\d+,\d+,\d+,(-|\d+)$') { $s[$cur].BRF++; if ($Matches[1] -ne '-' -and [int64]$Matches[1] -gt 0) { $s[$cur].BRH++ } }
}
$s.Keys | Where-Object { $_ -match 'lib[\\/]domain[\\/]budget' } | Sort-Object | ForEach-Object { '{0} L {1}/{2} B {3}/{4}' -f $_, $s[$_].LH, $s[$_].LF, $s[$_].BRH, $s[$_].BRF }
```
Expected: every engine file shows equal numbers (L x/x, B y/y), and B > 0 for files with branches. `budget.dart` (exports only) does not appear. Flutter 3.47.9 writes no `LF`/`LH`/`BRF`/`BRH` summary lines (plan F-006 §11 E7), so the command counts the `DA` (line) and `BRDA` (branch) records itself (PM, Gate 3). `--branch-coverage` exists in Flutter 3.47.9.

## 2. Edge cases
Same columns.

| ID | AC | Scenario | Test data | Steps | Expected | Type | Automated test | Regression |
|---|---|---|---|---|---|---|---|---|
| TC-006-32 | AC-2, AC-5 | 28-day month at ₹40,000 | Salary day 1; 1–28 Feb 2027; salary 40,00,000 | Compute | 1–4 Feb 1,42,858; 5–28 Feb 1,42,857; sum 40,00,000 | Auto-unit | `TC-006-32 twenty eight day month spreads exactly` (`spread_test.dart`) | yes |
| TC-006-33 | AC-2, AC-5 | 29-day leap February | Salary day 1; 1–29 Feb 2028; salary 40,00,000 | Compute | 1 Feb 1,37,932; 2–29 Feb 1,37,931; 29 days; sum 40,00,000 | Auto-unit | `TC-006-33 leap february has twenty nine days and sums exactly` (`spread_test.dart`) | yes |
| TC-006-34 | AC-1, AC-2 | Salary day 31 through the leap year | Salary day 31; months starting 31 Jan 2028, 29 Feb 2028, 31 Mar 2028, 30 Apr 2028 | Compute each | 31 Jan–28 Feb 2028 (29 days); 29 Feb–30 Mar 2028 (31); 31 Mar–29 Apr 2028 (30); 30 Apr–30 May 2028 (31). The stored salary day stays 31 (not 29 or 30) after each short month | Auto-unit | `TC-006-34 salary day 31 survives short and leap months` (`budget_month_test.dart`) | yes |
| TC-006-35 | AC-7 | Leap day as a spend date | Salary day 15, month 15 Feb–14 Mar 2028, 83,000 a day; spend 1,00,000 on 29 Feb 2028; today 1 Mar 2028 | Compute | 29 Feb is a budgeted day of that month, overspent −17,000; counted in spent so far | Auto-unit | `TC-006-35 leap day spend belongs to its budget month` (`day_result_test.dart`) | yes |
| TC-006-36 | AC-5, AC-6 | Remainder N−1 and tiny amounts | (a) 29 paise over 30 days. (b) 1 paisa over 31 days. (c) 30 paise over 30 days. (d) 0 over 1 day | Spread | (a) first 29 days 1, last day 0; sum 29. (b) day 1 = 1, others 0. (c) all 1. (d) [0]. No negative values | Auto-unit | `TC-006-36 tiny amounts and remainder n minus one spread exactly` (`spread_test.dart`) | yes |
| TC-006-37 | AC-6 | Month that crosses the year | Salary day 25; 25 Dec 2026–24 Jan 2027; salary 40,00,000 | Compute | 25 Dec–1 Jan = 1,29,033 (8 days), 2–24 Jan = 1,29,032 (23); sum 40,00,000 | Auto-unit | `TC-006-37 year crossing month spreads exactly` (`spread_test.dart`) | yes |
| TC-006-38 | AC-18 | Mid-month install on the month's last day | Salary day 5; first setup 4 Dec 2026; money left 50,000 | Compute | Budgeted days = [4 Dec] (1 day) = 50,000; 5 Nov–3 Dec not budgeted | Auto-unit | `TC-006-38 mid month install on the last day budgets one day` (`mid_month_test.dart`) | yes |
| TC-006-39 | AC-18, AC-16, AC-15 | Mid-month install with too much still to pay | Salary day 5; 10 Nov 2026; (a) money left 10,00,000, still to pay 12,00,000; (b) money left 10,00,000, still to pay 10,00,000 | Compute; then as continued | (a) shortfall 2,00,000; continued → 10 Nov–4 Dec all 0. (b) no shortfall, zero-spendable flag true, all 0 | Auto-unit | `TC-006-39 mid month install with costs above money left is a shortfall` (`mid_month_test.dart`) | yes |
| TC-006-40 | AC-19, AC-22 | Change on the month's first day | E2; on 5 Nov at 12:00 rent → 13,00,000 | Compute | No past days; all 30 days 73,000 (21,90,000 ÷ 30); history keeps the original period and the 5 Nov 12:00 change; the effective period from 5 Nov uses the new values | Auto-unit | `TC-006-40 change on the first day respreads the whole month` (`periods_test.dart`) | yes |
| TC-006-41 | AC-19 | Change on the month's last day | E2; on 4 Dec rent → 9,00,000 | Compute | 5 Nov–3 Dec 83,000 (29 days = 24,07,000); 4 Dec = 25,90,000 − 24,07,000 = 1,83,000; sum 25,90,000 | Auto-unit | `TC-006-41 change on the last day budgets only today` (`periods_test.dart`) | yes |
| TC-006-42 | AC-20 | Costs lowered after a continued shortfall | S1 continued (all 0); on 20 Nov EMI 6,00,000 → 0 | Compute | 5–19 Nov stay 0; amount left 5,00,000 over 15 days: 20–24 Nov 33,334, 25 Nov–4 Dec 33,333; the current period's shortfall is 0; the month total Shortfall = 0 (D-048: current period's); Left = 5,00,000 − spent (= current spendable − spent); P1 in the period history still shows shortfall 1,00,000 | Auto-unit | `TC-006-42 lowering costs after a shortfall gives days a budget again` (`shortfall_test.dart`) | yes |
| TC-006-43 | AC-7, AC-13 | Spends before the first budgeted day are ignored and reported | Mid-month install 10 Nov; spend 30,000 dated 7 Nov; today 12 Nov | Compute | 7 Nov stays notBudgeted; the 30,000 is not in spent so far, overspent or left; the engine output lists it as an ignored spend | Auto-unit | `TC-006-43 spends before the first budgeted day are ignored and reported` (`mid_month_test.dart`) Also T-226 hardening: `TC-006-43 currentPeriod carries the zero-spendable flag` (`engine_hardening_test.dart`). | yes |
| TC-006-44 | AC-10, AC-11 | Covering the same day twice | W1 | Cover 6 Nov 10,000, then 7,000, then 1 | First two accepted (6 Nov → 0, pot 16,000); third refused "day not overspent" | Auto-unit | `TC-006-44 a day can be covered twice until its overspend is zero` (`savings_pot_test.dart`) | yes |
| TC-006-45 | AC-12 | Edit reduces a covered day's overspend (over-covered) | W1 + cover 6 Nov 17,000 (pot 16,000) | Edit 6 Nov spend 1,00,000 → 90,000 | 6 Nov overspend 7,000; effective cover 7,000; 10,000 returns to the pot → pot 26,000; 6 Nov onBudget (covered). The F-009 "taken back" note must **not** be triggered (spec §4: needs no note) — see §2.3 note 2 for how the engine marks it | Auto-unit | `TC-006-45 cover above a reduced overspend returns to the pot` (`savings_pot_test.dart`) | yes |
| TC-006-46 | AC-12 | Partial cover reduction | W2 | Edit only 8 Nov 20,000 → 83,000 (saved becomes 33,000; covers 34,000) | 7 Nov cover (newest) 17,000 → 16,000; 6 Nov unchanged 17,000; pot 0; 7 Nov overspent −1,000; reductions = [(7 Nov, 17,000, 16,000)] | Auto-unit | `TC-006-46 pot shortfall of ten rupees cuts only the newest cover` (`savings_pot_test.dart`) | yes |
| TC-006-47 | AC-12 | **Property:** pot never negative, covers never exceed overspend | ≥ 1,000 generated sequences on E2: 1–60 random spends (0 … 3,00,000) on random days up to a random today, random covers (only accepted ones kept), then random edits/deletes | After every step recompute | Pot ≥ 0; for each day effective cover ≤ that day's overspend; Σ covers ≤ Σ saved; Σ day budgets == spendable; reductions are always newest-first by cover time | Auto-unit | `TC-006-47 pot never goes negative under random spends covers and edits` (`spread_property_test.dart`) | yes |
| TC-006-48 | AC-19 | A period change does not touch the pot | W1 + cover 6 Nov 10,000; today 8 Nov | Apply C1 on 8 Nov | Pot before = pot after (23,000); 5–7 Nov results unchanged | Auto-unit | `TC-006-48 a budget change leaves the pot unchanged` (`periods_test.dart`) | yes |
| TC-006-49 | AC-13, AC-23 | "Today" moved backwards or forwards | W1 with extra spends dated 9–20 Nov | Compute with today = 20 Nov, then 8 Nov, then 20 Nov again | Each result depends only on the given today: on 8 Nov, spends dated 9–20 Nov are not counted (upcoming days, no result); results for 20 Nov are identical in run 1 and 3; no exception | Auto-unit | `TC-006-49 engine uses only the today it is given` (`month_totals_test.dart`) | yes |
| TC-006-50 | AC-13 | "Today" outside the month | E2 with today = 4 Nov 2026 and 5 Dec 2026 | Compute | Does not throw (F-006 §2.9, D-048). 4 Nov: every day upcoming; spent so far, saved, overspent, covered, pot 0; Left 24,90,000. 5 Dec: no live day, every day final; 4 Dec's leftover is in the pot | Auto-unit | `TC-006-50 today outside the month does not throw` (`month_totals_test.dart`) | yes |
| TC-006-51 | AC-5, AC-17 | 30 fixed costs of ₹10 crore | Salary 10,00,00,00,000; 30 items × 10,00,00,00,000 | Compute | Fixed 3,00,00,00,00,000; shortfall 2,90,00,00,00,000 exactly; no overflow | Auto-unit | `TC-006-51 thirty ten crore costs give an exact shortfall` (`shortfall_test.dart`) | yes |
| TC-006-52 | AC-13 | Many spends on one day | E2; 60 spends of 1,001 paise on 9 Nov; today 9 Nov | Compute | 9 Nov spent 60,060; live remaining 22,940; totals exact | Auto-unit | `TC-006-52 many spends on one day add up exactly` (`month_totals_test.dart`) | yes |
| TC-006-53 | AC-7, AC-12 | Input order does not matter, cover time does | W2 with the spends list shuffled (5 shuffles) and covers given in reverse list order | Compute; apply the TC-006-14 edit | Every output identical to TC-006-14; reduction order still by cover time (7 Nov first) | Auto-unit | `TC-006-53 engine output ignores input order but respects cover time` (`savings_pot_test.dart`) | yes |
| TC-006-54 | AC-21 | Period totals with a shortfall period | E2, C4 on 20 Nov continued; spends on 10 Nov and 22 Nov | Report periods | 2 periods; P2 shortfall 2,55,000, budgets 0, the 22 Nov spend overspent; Σ periods == month totals | Auto-unit | `TC-006-54 shortfall period appears in the period history` (`periods_test.dart`) | yes |
| TC-006-55 | AC-22 | Three same-day changes | E2; 20 Nov: rent → 13,00,000 (09:00), salary → 35,00,000 (12:00), rent back → 10,00,000 (17:00) | Compute | Effective 20 Nov values: salary 35,00,000, rent 10,00,000 → C3 budgets (49,667 ×10, 49,666 ×5); history has all three in time order | Auto-unit | `TC-006-55 three same day changes keep the latest values` (`periods_test.dart`) | yes |
| TC-006-56 | AC-3, AC-24 | Engine rejects invalid input instead of guessing | Salary day 0 and 32; negative salary, target, fixed cost or spend; target > salary | Call the engine | Each returns/throws the plan's validation error (an `ArgumentError` or typed failure); never a silently "fixed" value | Auto-unit | `TC-006-56 invalid engine inputs are rejected` (`spread_test.dart`) Also T-226 hardening: `TC-006-56 duplicate cover ids are rejected`; `TC-006-56 dayOn rejects a date outside the month` (`engine_hardening_test.dart`). | yes |
| TC-006-57 | AC-9, AC-11 | Cover on today's live day | W1; today 8 Nov; 8 Nov spend raised to 1,00,000 (overspent −17,000 live); pot 33,000 | Cover 8 Nov with 17,000 | Allowed (F-006 §2.4, D-048): accepted, pot 16,000, 8 Nov result 0 and still status live | Auto-unit | `TC-006-57 todays overspend can be covered` (`savings_pot_test.dart`) | yes |
| TC-006-59 | AC-18, AC-19 | "Money left" corrected on a later day (D-048) | Salary day 5; first setup 10 Nov 2026, money left 24,90,000 (99,600 a day); on 20 Nov money left → 26,40,000 | Compute | 10–19 Nov keep 99,600 (10 days = 9,96,000); amount left 16,44,000 over 20 Nov–4 Dec (15 days) = 1,09,600 each; month sum 26,40,000; two periods in the history (both `MidMonthStartValues`) | Auto-unit | `TC-006-59 correcting money left later keeps past days` (`mid_month_test.dart`) | yes |
| TC-006-60 | AC-25 | Money in reduces the day's spend (D-047) | E2; today 14 Nov; (a) 12 Nov spend 30,000 + money in 50,000; (b) 13 Nov money in 50,000 only; (c) W1 + cover 6 Nov 17,000, then money in 10,000 on 6 Nov; (d) today 14 Nov with money in 50,000 dated 14 Nov; (e) S1 continued, 6 Nov money in 50,000 | Compute | (a) 12 Nov net −20,000, Saved +1,03,000. (b) 13 Nov Saved +1,33,000. Totals (a)+(b): spent so far = Σ spends − Σ money in; money in total 1,00,000; pot includes both days. (c) 6 Nov overspend 7,000, effective cover 7,000, 10,000 back to the pot, no reduction reported. (d) 14 Nov live, left today 1,33,000 (more than the 83,000 budget). (e) 6 Nov Saved +50,000 on a 0 budget. A money-in amount of 0 or less → `ArgumentError` | Auto-unit | `TC-006-60 money in lowers the day spend and can make it negative` (`day_result_test.dart`) Also T-226 hardening: `TC-006-60 day netSpent is spends minus money in` (`engine_hardening_test.dart`). | yes |
| TC-006-58 | AC-23 | Day counts never use local time arithmetic | Salary day 5; months spanning US DST changes (Mar 2027, Nov 2026) **[TZ]** | Run TC-006-02 under `TZ=PST8PDT` (part of §1.1 → TC-006-27) | Same day counts as under IST (no 23- or 25-hour day effect; look-ahead #13c) | Auto-unit | covered by `TC-006-02 every salary day gives valid consecutive months 2026 to 2030` under TC-006-27's runs | yes |

Not applicable to F-006 (no screen, no storage, no SMS): permission denied, unknown/duplicate SMS, all 4 themes, largest system font, app killed in background, empty inbox. "Empty data" = TC-006-17 (c) and TC-006-50.

### 2.1 Impact on existing features
Aligned with plan F-006 §8 (no existing file changes).
- **F-001:** TC-001-06 (domain purity, `domain_purity_test.dart`) must stay green and is **extended** by TC-006-28/-29/-30 in the new `domain_layering_test.dart` (D-033: F-006 is built while Phase 1 is open). The Tester adds a pointer note to the F-001 file (TC-001-06 → "extended by TC-006-29"); TC-001-06 itself is not changed. TC-001-12 (every test name starts with a TC ID) covers the new `TC-006-NN ` tests. TC-001-24/-25 unaffected: the plan adds no package (plan §4; it avoids `package:meta`). TC-001-44 (the `check.ps1` step list) and `tests/REGRESSION.md` check 1 change when `tool/tz_matrix.ps1` and `tool/domain_coverage.ps1` join `check.ps1` (plan F-007 §2) — the Tester updates both in that task.
- **F-002 … F-005:** no file is shared. All Regression-yes cases stay green (run as part of `flutter test`).
- **F-003 (later, not F-006 itself):** the Home and Transactions placeholders change when F-008/F-009 wire the engine in, after Phase 1 approval. See F-008 §2.3 and F-009 §2.3.

### 2.2 Regression
All F-001 to F-005 Regression-yes cases and `tests/REGRESSION.md` checks 1–9. New for REGRESSION.md after Step 8: "engine 3-zone run (TC-006-27)" and "engine branch coverage 100% (TC-006-31)".

### 2.3 Notes for the Project Manager / Product Manager
1. **AC-24 "100% branch coverage"** is measurable with `flutter test --branch-coverage` (TC-006-31). Dart's coverage counts branches the VM instruments; a `switch` expression on a sealed type may report no branch. The PM should accept "BRH = BRF and LH = LF" as the definition.
2. ~~**Over-covered day after an edit (TC-006-45)** vs. D-040 reductions.~~ *Answered by plan F-006 §1.6/§7:* the over-cover is clamped and **not** listed as a reduction; only pot-driven cuts are. TC-006-45 expects exactly that.
3. **Month Shortfall total after costs are lowered (TC-006-42):** §2.5 defines "Left = budgeted − spent − shortfall". If the month total Shortfall becomes 0 once the current period has none, the earlier shortfall disappears from Left. The PM should confirm that is intended (the period history still holds it).
4. **"Today" outside the budget month (TC-006-50)** is not specified. F-008/F-009 never pass it (a new month means a new setup), but the engine must not throw. The plan should state the rule; the row is updated at Gate 1.
5. **Cover on today (TC-006-57):** AC-11 lists "upcoming" as refused but says nothing about today's live day. §2.4 says "up to today", so the case expects it allowed. The cover UI is Phase 3, so this only affects the engine API now.
6. **AC-5 generator:** "amounts from 0 to ₹10 crore" uniformly would almost never produce small amounts, so TC-006-06 adds a log-uniform half and fixed boundary rows. Same seed every run.
7. **Cover refusal precedence (TC-006-13 b):** AC-11 (b) breaks two rules at once (more than the pot and more than the overspend). The plan should fix the order of checks so the reason is predictable; TC-006-13 (j) isolates the pot rule.

8. **Persisted reductions (plan F-006 §9 Q2):** accepted (D-048). Persistence is the repository's job, so the case is **TC-007-46**; the engine only reports. TC-006-47 already checks the pot never goes negative either way.
9. **Money-left edits in a mid-month first month (plan F-006 §9 Q1):** answered (D-048): money on the first budgeted day; TC-006-59.
10. **Gate 1 answers (PM, 2026-11-10):** note 1 accepted (`BRH = BRF`, `LH = LF` per file, F-006 AC-24); note 3: current period's shortfall (TC-006-42); note 4: F-006 §2.9 (TC-006-50); note 5: allowed (TC-006-57); note 7: D-048 order (TC-006-13).

### 2.4 AC → test case map
| AC | Test cases |
|---|---|
| AC-1 | TC-006-01, -03, -34 |
| AC-2 | TC-006-02, -03, -32, -33, -34, -58 |
| AC-3 | TC-006-04, -56 |
| AC-4 | TC-006-05 |
| AC-5 | TC-006-06, -07, -32, -33, -36, -51 |
| AC-6 | TC-006-06, -08, -36, -37 |
| AC-7 | TC-006-09, -35, -43, -53 |
| AC-8 | TC-006-10 |
| AC-9 | TC-006-11, -57 |
| AC-10 | TC-006-12, -44 |
| AC-11 | TC-006-13, -44, -57 |
| AC-12 | TC-006-14, -45, -46, -47, -53 |
| AC-13 | TC-006-15, -43, -49, -50, -52 |
| AC-14 | TC-006-16 |
| AC-15 | TC-006-17, -39 |
| AC-16 | TC-006-18, -39 |
| AC-17 | TC-006-19, -51 |
| AC-18 | TC-006-20, -38, -39, -59 |
| AC-19 | TC-006-21, -22, -23, -40, -41, -48, -59 |
| AC-20 | TC-006-24, -42 |
| AC-21 | TC-006-25, -54 |
| AC-22 | TC-006-26, -40, -55 |
| AC-23 | TC-006-27, -28, -49, -58 |
| AC-24 | TC-006-29, -30, -31, -56 |
| AC-25 | TC-006-60 |

## 3. Regression cases from bugs
Every bug found in this feature adds a case here. It is never deleted.

| ID | Bug | Scenario | Expected | Automated test |
|---|---|---|---|---|
| — | No bugs found in F-006 Step 8 (2026-11-11) | | | |

## 4. Test runs *(Tester)*
| Run | Date | Build / task | Passed | Failed | Notes |
|---|---|---|---|---|---|
| R1 | 2026-11-11 | T-201 … T-205 and T-226 after PM Gate 3 re-review (M1, M2, M3 fixed), Flutter 3.47.9 / Dart 3.13.7; Step 8 via T-224 | 60 / 60 cases (58 by named automated test, TC-006-31 by command, TC-006-58 inside TC-006-02 under the three zones) | 0 | `tool/check.ps1` ALL CHECKS PASSED (328 tests in 62 files, full tree incl. Phase 1 work in progress); `tool/domain_coverage.ps1` 100%; `tool/tz_matrix.ps1` PASSED; independent TC-006-27/-28/-30/-31 commands all as expected. No bug |

### Latest run — detailed results (R1, 2026-11-11)
Commands (all from the project root or `app/`, PowerShell 5.1):

| Command | Result |
|---|---|
| `.\tool\check.ps1` | PASS in every step (pub get, format, `flutter analyze`, `dart analyze --fatal-infos`, test names on 62 files, `flutter test` 328 tests), `ALL CHECKS PASSED`, exit 0 |
| `.\tool\domain_coverage.ps1` | PASS, **100% lines and branches** in all 17 files of `lib/domain/budget/` (`budget.dart` has directives only). `flutter test --branch-coverage test/domain/budget`: 135 tests passed |
| `.\tool\tz_matrix.ps1` | PASS in UTC, PST8PDT and IST; the three dumps are identical. **Dump SHA-256 `B30996982B3C37EBDA2355BAFC8B6D1AD17879A94A7B0E44CD33282F6D7D59E4`** (new value since `netSpent`, as the PM's re-review recorded) |
| §1.1 TC-006-27 command (independent, `--dart-define=EXPECT_TZ_OFFSET_MIN`) | `exit 0` three times (`test/domain/`, 138 tests each); `build\tz\UTC.txt`, `PST8PDT.txt`, `IST.txt` all hash `B30996982B3C37EB…D59E4`; the sentinel passed in each zone |
| §1.1 TC-006-28 command | no output |
| §1.1 TC-006-30 command (new form) | no output. The old form (without the directive and comment filters) gives 67 hits: 66 `package:` import/export lines plus `spend_draft.dart:60`, the doc comment `Add/Edit`, none of them division |
| §1.1 TC-006-31 command (new form) | every file equal: `amount_input` L 42/42 B 26/26 · `budget_engine` 210/210 and 70/70 · `budget_month` 31/31, 11/11 · `budget_period` 63/63, 30/30 · `calendar_date` 27/27, 16/16 · `cover` 1/1, 1/1 · `fixed_cost` 1/1, 1/1 · `month_input` 1/1, 1/1 · `month_result` 6/6, 4/4 · `paise` 23/23, 16/16 · `setup_draft` 198/198, 95/95 · `spend` 1/1, 1/1 · `spend_draft` 45/45, 23/23 · `spend_groups` 25/25, 10/10 · `spread_outcome` 22/22, 10/10 · `today_line` 15/15, 8/8. The same numbers as `domain_coverage.ps1` |
| Name check (script over `app/test`) | a test named `TC-006-NN …` exists for every case except TC-006-31 (command) and TC-006-58 (inside TC-006-02 under the zone runs, by design); the titles written in the rows match the real titles |

| ID | Result | Evidence |
|---|---|---|
| TC-006-01 … -26 | Pass | Named tests in `budget_month_test`, `spread_test`, `spread_property_test`, `day_result_test`, `savings_pot_test`, `month_totals_test`, `shortfall_test`, `mid_month_test`, `periods_test` (+ `engine_hardening_test` for -21), inside the green `flutter test` of `check.ps1` and `domain_coverage.ps1`. Property cases: -02 (1,860 months), -03 (1,826 dates × 31 salary days), -06 (10,217 cases, seed 2026), -07 (2,000 months), -23 (2,000 changes) |
| TC-006-27 | Pass | `tool/tz_matrix.ps1` and the independent command (three zones, identical dumps, sentinel real) |
| TC-006-28, -29, -30 | Pass | `domain_layering_test.dart` (each guard also proves it can fail) and the independent commands (no output) |
| TC-006-31 | Pass | Command and `domain_coverage.ps1`, 100% in every file |
| TC-006-32 … -57, -59, -60 | Pass | Named tests (`spread_test`, `budget_month_test`, `day_result_test`, `mid_month_test`, `periods_test`, `shortfall_test`, `savings_pot_test`, `month_totals_test`, `spread_property_test` for -47, `engine_hardening_test` for -43, -56, -60) |
| TC-006-18 | Pass | The test asserts Overspent 20,000 while 6 Nov is still live (D-060) and status overspent on 7 Nov, as the Expected column now says |
| TC-006-58 | Pass | `TC-006-02` under `TZ=PST8PDT` (and UTC, IST) in both the script and the independent command |

**F-008 / F-009 pure halves (T-212a, T-214a, T-217) — the same run.** Their test files are `amount_input_test`, `setup_draft_test`, `today_line_test`, `spend_groups_test` and `spend_draft_test` in `test/domain/budget/`; all pass inside the 328 tests and the 135 in `test/domain/budget`. They are recorded in the "Automated test" column of the cases they cover in `tests/F-008-month-setup.md` (31 cases) and `tests/F-009-manual-transactions.md` (20 cases). The widget halves of the same IDs are not run yet (T-215, T-218, T-219); their cases stay "not yet executed" there.

## 5. Test report to Project Manager *(Gate 4)*
- **Verdict: Pass.** F-006 Step 8 for T-201 … T-205 and T-226: 60 of 60 cases pass, no failures, no bug.
- **ACs covered: 25 / 25** (AC-1 … AC-25 by the map in 2.4). AC-23 and AC-24: three-zone run with identical dumps and a real zone change; no clock read, no `double`, no database or Flutter import in the engine; 100% line and branch coverage in each of the 17 files.
- **Bugs logged: none.**
- **Full regression:** automated suite green (`check.ps1`, 328 tests in 62 files, including the F-001 … F-005 cases, TC-001-06 still green and extended by TC-006-29). Not re-run in this pass: `REGRESSION.md` checks that need the emulator (check 9) and the manual cases of F-001 … F-005. F-006 changes no screen, and the Phase 1 UI is being built by another Developer at the same time, so the emulator regression waits for the phase-end run.
- **Notes for the PM**
  1. TC-006-30's manual command needed one more filter than the review gave: besides directive lines it must skip whole-line `//` and `///` comments, or the doc comment `Add/Edit` in `spend_draft.dart:60` is a false hit. The automated guard already handles this (it cuts comments). Recorded in 1.1.
  2. The dump hash to quote from now on is `B30996982B3C37EB…D59E4` (since `netSpent`).
  3. `check.ps1` still does not call `domain_coverage.ps1` and `tz_matrix.ps1` (they join in T-206); until then both are run by hand, as in this report. TC-001-44's step list and `REGRESSION.md` check 1 change with T-206.
  4. Nice to have (review N5, N6) stay open: block comments in the guard, and the `groupSpendsByDay` tie-break once F-007 fixes the id type.
  5. Edge-case coverage (28/29/30/31-day months, leap year, salary 29th–31st, mid-month install, ₹0, ₹10 crore, paise rounding, empty data, today outside the month) is in the cases above, all passing.

## 6. Project Manager verdict *(Gate 4, 2026-11-11)*
**Verdict: Pass.** No Must fix items.
- **Cases:** all 60 cases (TC-006-01 … -60) have a result; 58 by named test, TC-006-31 by command, TC-006-58 inside TC-006-02 under the three zones. No bug, so section 3 stays empty.
- **ACs:** cross-checked AC-1 … AC-25 in the feature doc against plan section 6 (task per AC) and the map in 2.4 (test cases per AC). Every AC has a task, at least one case and a Pass result. No AC or case is missing.
- **PM spot-check (own run, same day):** `tool/check.ps1` ALL CHECKS PASSED (63 test files, 335 tests; the Phase 1 UI Developer added tests since the Tester's 328); `tool/domain_coverage.ps1` 100% lines and branches in all 17 files, identical to the Tester's numbers; `tool/tz_matrix.ps1` PASSED in UTC, PST8PDT and IST, dump SHA-256 `B30996982B3C37EB…D59E4` in all three.
- **Regression:** automated suite green. The emulator and manual F-001 … F-005 checks wait for the phase-end run (F-006 changes no screen); accepted.
- **Decisions:** (1) `check.ps1` will call `domain_coverage.ps1` and `tz_matrix.ps1` in T-206, as two extra steps; the Tester then updates TC-001-44 and `REGRESSION.md` check 1. (2) Tester notes 1 to 5 accepted; note 4 (N5, N6) stay Nice to have. (3) Small Developer task T-228: rename the `TC-005-18` test in `app_gate_test.dart` to `TC-005-32`.
- **Next:** Developer's step 9 (T-228): fill section 7 of the feature doc, then INDEX F-006 → Done. INDEX shows Testing until then.

