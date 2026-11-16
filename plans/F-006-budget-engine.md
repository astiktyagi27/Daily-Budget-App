# Plan — F-006: Budget engine

| | |
|---|---|
| **Feature doc** | [`docs/features/F-006-budget-engine.md`](../docs/features/F-006-budget-engine.md) (final spec, 24 ACs) |
| **Test cases** | [`tests/F-006-budget-engine.md`](../tests/F-006-budget-engine.md) (Approved at Gate 1; the Tester's TC IDs are used in §6) |
| **Design** | None (no screen) |
| **Inputs** | Owner decisions D-034 … D-040, D-042, D-043; `docs/reviews/phase-2-lookahead.md` #7, #8, #13 |
| **Author** | Developer |
| **Status** | Approved (Gate 1, Project Manager, 2026-11-10) |

## 1. Approach
The engine is a set of **pure functions over immutable values** in a new folder `app/lib/domain/budget/`. It has no Flutter, no database, no clock and no I/O. The one input it is handed is "today". It is built first and on its own, **in parallel with Phase 1** (D-033), because it only adds new files under `lib/domain/budget/` and new test files under `test/domain/budget/` and `test/architecture/`. It needs no package.

**Main design choices:**

1. **Calendar dates are a value type, not `DateTime`.** `CalendarDate` holds a **day number** (days since 1970-01-01), built only through `DateTime.utc(y, m, d)`.
   - Arithmetic (`addDays`, `daysUntil`, compare) is integer arithmetic on the day number. It never involves local time or `Duration`, so DST and time zones cannot shift a day (look-ahead #7, #13c).
   - The same day number is what F-007 stores in its `INTEGER` columns, so the storage converter is a one-liner.
   - *Alternative rejected:* `DateTime` with time zeroed. Local `DateTime` moves across zones (look-ahead #7), and UTC `DateTime` still allows hours and minutes to creep in.
2. **Money is an extension type `Paise` over `int`** (Dart 3.3+ extension types).
   - At runtime it is a plain `int`, so it costs nothing and F-007 stores it as `INTEGER`. The type system still stops a raw `int` (a day count, say) being passed as money.
   - It has operators `+`, `-`, unary `-`, comparison, `isNegative`/`isZero`, and `spreadOver(int days)`.
   - There is **no `/` and no `double`** anywhere.
   - *Alternative rejected:* a plain `int` typedef, which gives no type safety. A `final class Money` wrapper would allocate an object per value; with 500 spends × several recomputes per frame that is wasted.
3. **One entry point, `computeMonth(MonthInput) → MonthResult`.** It recomputes the whole month (≤ 31 days, ≤ a few hundred spends) from the stored facts every time:
   - the facts are periods, spends and covers;
   - nothing derived (day budgets, results, pot) is stored, so there is no cache to go stale;
   - this matches F-007's choice to recompute day budgets from the append-only period history (D-037).

   Cost: O(days × periods + spends + covers), well under 1 ms (look-ahead #16).
4. **Preview and validation use the same rules as storage.** `planPeriod(...)` returns a sealed `SpreadOutcome`: `Spread(budgets)`, `ZeroSpendable(budgets of ₹0)` or `Shortfall(amount)`. F-008's live preview, the shortfall dialog and the saved month therefore can never disagree.
5. **Sealed classes plus exhaustive `switch` for every state:**
   - `DayStatus`: `notBudgeted`, `upcoming`, `live`, `saved`, `onBudget`, `overspent`;
   - `PeriodValues`: `FullMonthValues`, `MidMonthStartValues`;
   - `SpreadOutcome`;
   - `CoverDecision`: `CoverAllowed`, `CoverRefused(reason)`.

   Results are records or `final` classes with `==`, so tests compare whole values.
6. **D-040 cover reductions are reported, not silently applied.** `computeMonth` returns the effective cover amounts plus a list of `CoverReduction(day, coverId, oldAmount, newAmount)`, newest first.
   - The **repository (F-007) persists** the reduced amounts in the same transaction as the edit that caused them.
   - The screen (F-009) shows the note.
   - Reason: a reduced cover must stay reduced even if the pot later grows again. A purely derived reduction would "come back" by itself, contradicting the note "was taken back".
   - The over-covered case (an edit lowers a covered day's overspend, F-006 §4) is clamped the same way, but it is *not* listed as a reduction, because the spec says it needs no note.

## 2. Files / modules
All new. No existing file changes in this feature.

| Path | Add / Change | What |
|---|---|---|
| `app/lib/domain/budget/calendar_date.dart` | Add | `CalendarDate` (day number, `y/m/d`, `addDays`, `daysUntil`, `compareTo`, `isBefore/isAfter`, `daysInMonth(y, m)`, `toString` ISO). `CalendarDate.fromDateTime(DateTime local)` takes **only** y/m/d of a value the caller already has; the engine itself never creates a `DateTime.now()` |
| `app/lib/domain/budget/paise.dart` | Add | `extension type const Paise(int value)`: operators, `Paise.zero`, `spreadOver(days) → List<Paise>` (D-035: base = `value ~/ days`, the first `value % days` days +1). `ArgumentError` (always on, not `assert`) for `days < 1` or `value < 0` (D-048, TC-006-56) |
| `app/lib/domain/budget/budget_month.dart` | Add | `BudgetMonth(start, end)`: `startIn(salaryDay, year, month)` (clamp to the last day), `containing(salaryDay, today)`, `next`, `previous`, `length`, `contains`, `days` |
| `app/lib/domain/budget/fixed_cost.dart` | Add | `FixedCost(name, amount)`. The engine only sums amounts; names are kept for "what changed" |
| `app/lib/domain/budget/budget_period.dart` | Add | `BudgetPeriod(start, changedAt, values, continuedWithShortfall)`. `changedAt` is an ordering key (UTC epoch ms, supplied by the caller), used **only** to order same-day changes. Sealed `PeriodValues`: `FullMonthValues(salary, target?, fixedCosts)` and `MidMonthStartValues(moneyLeft, fixedCostsStillToPay)`; `spendable` getter; `diff(previous) → List<PeriodChange>` |
| `app/lib/domain/budget/spread_outcome.dart` | Add | sealed `SpreadOutcome` + `planPeriod(month, firstBudgetedDay, earlierBudgets, values, from)` |
| `app/lib/domain/budget/spend.dart` / `cover.dart` | Add | `Spend(id, date, amount, direction, createdAt)` with `enum SpendDirection { spend, moneyIn }` (D-047; amount always > 0, the direction gives the sign), `Cover(id, day, amount, madeAt)` |
| `app/lib/domain/budget/month_input.dart` | Add | `MonthInput(salaryDay, month, firstBudgetedDay, periods, spends, covers, today)` |
| `app/lib/domain/budget/month_result.dart` | Add | `DayResult(date, status, budget, spent, covered, result)`, `PeriodResult(...)`, `MonthTotals(...)`, `CoverReduction(...)`, `MonthResult(days, periods, totals, effectiveCovers, reductions, ignoredSpends)` |
| `app/lib/domain/budget/budget_engine.dart` | Add | `computeMonth(MonthInput)`, `checkCover(MonthResult, day, amount) → CoverDecision`, `monthStateFor(salaryDay, lastMonth, today)` (current / new month started / missed months, F-008 §2.11) |
| `app/test/domain/budget/*_test.dart` | Add | One test file per source file, tests named `TC-006-NN …` |
| `app/test/domain/budget/spread_property_test.dart` | Add | AC-5: 10,000 seeded random cases (`Random(2026)`, fixed seed, so reproducible) |
| `app/test/architecture/domain_layering_test.dart` | Add | Phase-overview carry-over: `domain/` imports no `data/`, `features/`, `package:drift`, `package:sqlite3`; `domain/budget/` contains no `double`, `num`, `toDouble(`, `DateTime.now`, `clock` and no spaced ` / ` operator (AC-23, AC-24). A **new file**, so `domain_purity_test.dart` (TC-001-06, Phase 0) is not edited while Phase 1 is open |
| `tool/domain_coverage.ps1` | Add | Runs `flutter test --branch-coverage test/domain/budget` and fails unless every `BRDA` and `DA` line for `lib/domain/budget/` in `coverage/lcov.info` is hit (AC-24, 100% branches). Plain PowerShell 5.1, like `check.ps1` |
| `tool/tz_matrix.ps1` | Add | Runs the given test files three times: `TZ=UTC`, `TZ=PST8PDT`, unset (IST). Fails on any failure (AC-23; F-007 AC-3 reuses it). POSIX names only (look-ahead #8) |

`check.ps1` gets these two scripts as steps in **T-206** (F-007) (after Phase 1 approval), because `tool/check.ps1` belongs to the Phase 1 commit. Until then the scripts are run by hand and by the Tester.

## 3. Data model / database changes
None in this feature. These engine types are the model F-007 maps rows to and from:
- `CalendarDate` ↔ `INTEGER` day number.
- `Paise` ↔ `INTEGER`.
- `BudgetPeriod` ↔ a period row plus its fixed-cost rows.
- `Cover` ↔ a savings-move row.

**Rules the engine applies (from the spec, one place in code):**

| Rule | Implementation |
|---|---|
| Month start (§2.1) | `min(salaryDay, daysInMonth(y, m))` |
| Spread (D-035) | `base = a ~/ n`, first `a % n` days `base + 1` |
| Amount to spread for a period starting `s` (§2.7) | `values.spendable − Σ budgets of budgeted days < s` |
| Same-day changes (AC-22) | Periods sorted by `(start, changedAt)`. For each start date only the last one is **effective**; earlier ones are kept in `periods` with `superseded: true` and zero days |
| Shortfall (§2.8, D-036) | amount < 0 → `Shortfall(−amount)`, day budgets `Paise.zero`. Exactly 0 → `ZeroSpendable` (D-043). Totals' `shortfall` = the **current** period's shortfall (§4 edge case "lowers costs after a shortfall") |
| Day result (§2.3) | `budget − netSpent + coveredEffective`, `netSpent = Σ spend − Σ moneyIn` of that day (D-047, may be < 0). Statuses: `upcoming` after today; `live` for today; `notBudgeted` before the first budgeted day |
| Cover checks (§2.4, D-048) | Refusal reasons checked in this order: `notPositive`, `outsideMonth`, `notBudgeted`, `upcoming`, `notOverspent`, `exceedsOverspend`, `exceedsPot`. Today's live day may be covered |
| Today outside the month (§2.9) | Before start: all upcoming, totals 0; after end: all final, last day in the pot. Never throws |
| Invalid input (§2.9) | `ArgumentError` from `computeMonth`/`planPeriod`/`spreadOver`, never a silent fix |
| Pot (D-039) | `Σ max(result, 0)` over budgeted days **before today** − Σ effective covers |
| Cover clamp | Each cover is first limited to its day's overspend (no note). Then, if pot < 0, covers are reduced newest `madeAt` first until pot ≥ 0, and each one is reported (D-040) |
| Left (§2.5) | `Σ all day budgets − spent so far − shortfall` |
| Spends ignored | Outside the month or before the first budgeted day: excluded from every total and returned in `ignoredSpends` (§4) |
| Future spends | Spends dated after today: stay in their `DayResult.spent`, but are not in `spentSoFar` (F-009 §4) |

## 4. Packages (latest stable, checked on pub.dev)
| Package | Version | Why |
|---|---|---|
| — | — | None. Pure Dart SDK only (`dart:math` `Random` for the seeded property test). `test`/`flutter_test` already exist |

**Riverpod code generation (D-027 revisit):** not used. The engine has no providers. The few Phase 2 providers stay manual (see F-007 §4).

## 5. Tasks
All F-006 tasks are **buildable now**, in parallel with Phase 1 (D-033): new files only, under `lib/domain/budget/`, `test/domain/budget/`, `test/architecture/` (new file) and `tool/` (new scripts).

| ID | Task | Covers AC | Depends on | Status |
|---|---|---|---|---|
| T-201 | `CalendarDate`, `BudgetMonth` (start clamp, next/previous, containing today, missed months), plus `domain_layering_test.dart` (imports, no `DateTime.now`/clock, no `double`/`num`/` / `) | AC-1, AC-2, AC-23 (source check), AC-24 (imports, no double) | — | Code review (M1, M2 done) |
| T-202 | `Paise` extension type and `spreadOver` (D-035), seeded 10,000-case property test, huge-amount checks | AC-4, AC-5, AC-6 (E1, E3, E5), AC-17 (spread part) | T-201 | Ready for test |
| T-203 | Periods and `planPeriod`: `FullMonthValues`/`MidMonthStartValues`, spendable, mid-month install (D-034, D-042), changes recalculating the remaining days (D-037), same-day ordering, shortfall / zero spendable (D-036, D-043), `diff` for "what changed", per-period results | AC-3, AC-6 (Example 2, C2), AC-15 (a, b), AC-16, AC-18, AC-19, AC-20, AC-21, AC-22 | T-202 | Ready for test |
| T-204 | `computeMonth`: day results and statuses, money in / net spend (D-047), never auto-carried, pot with today joining at midnight (D-039), `checkCover` with distinct refusal reasons, cover clamp + newest-first reductions (D-040), month totals, left/negative left, ignored and future spends | AC-7, AC-8, AC-9, AC-10, AC-11, AC-12, AC-13, AC-14, AC-15 (c), AC-17 (totals), AC-25 | T-203 | Code review (M3, T-226 done) |
| T-205 | Quality gates: `tool/domain_coverage.ps1` (100% branch + line for `lib/domain/budget/`), `tool/tz_matrix.ps1` (3 POSIX `TZ` runs), add any missing branch tests; `dart format`, `flutter analyze`, `dart analyze --fatal-infos`, full `flutter test` | AC-23, AC-24 | T-204 | Ready for test |

## 6. Acceptance criteria coverage
TC IDs are the Tester's (`tests/F-006-budget-engine.md` §2.4), reconciled at Gate 1.

| AC | Built in task | Proved by test cases |
|---|---|---|
| AC-1 Month dates (§2.1 table, 12 rows) | T-201 | TC-006-01, -03, -34 |
| AC-2 Every salary day 1–31, Jan 2026 – Dec 2030 | T-201 | TC-006-02, -03, -32, -33, -34, -58 |
| AC-3 Spendable | T-203 | TC-006-04, -56 |
| AC-4 README E1–E5 exact | T-202 | TC-006-05 |
| AC-5 Sum exact, 10,000 cases | T-202 | TC-006-06, -07, -32, -33, -36, -51 |
| AC-6 Extra paise on the first days | T-202, T-203 | TC-006-06, -08, -36, -37 |
| AC-7 Day result and statuses | T-204 | TC-006-09, -35, -43, -53 |
| AC-8 Never auto-carried | T-204 | TC-006-10 |
| AC-9 Pot, today joins at midnight | T-204 | TC-006-11, -57 |
| AC-10 Cover allowed | T-204 | TC-006-12, -44 |
| AC-11 Cover refused (a–h, distinct reasons, D-048 order) | T-204 | TC-006-13, -44, -57 |
| AC-12 Newest covers reduced first | T-204 | TC-006-14, -45, -46, -47, -53 |
| AC-13 Month totals | T-204 | TC-006-15, -43, -49, -50, -52 |
| AC-14 Left negative | T-204 | TC-006-16 |
| AC-15 Zero amounts | T-203 (a, b), T-204 (c) | TC-006-17, -39 |
| AC-16 Shortfall at month start | T-203 | TC-006-18, -39 |
| AC-17 Huge amounts | T-202, T-204 | TC-006-19, -51 |
| AC-18 Mid-month install | T-203 | TC-006-20, -38, -39, -59 |
| AC-19 Mid-month change C1–C3 | T-203 | TC-006-21, -22, -23, -40, -41, -48, -59 |
| AC-20 Change causing a shortfall (C4) | T-203 | TC-006-24, -42 |
| AC-21 Period history, 3 periods | T-203 | TC-006-25, -54 |
| AC-22 Same-day changes | T-203 | TC-006-26, -40, -55 |
| AC-23 Dates only, no clock (3 `TZ` runs) | T-201 (source check), T-205 (`tz_matrix.ps1`) | TC-006-27, -28, -49, -58 |
| AC-24 Pure, integer-only, 100% branches | T-201 (guard), T-205 (coverage) | TC-006-29, -30, -31, -56 |
| AC-25 Money in (D-047) | T-204 | TC-006-60 |

## 7. Edge cases & risks
| Case / risk | How it is handled |
|---|---|
| Salary day 29–31, leap years (§2.1, §4) | Clamp rule in `BudgetMonth.startIn`; AC-1 table + AC-2 sweep over 5 years × 31 days |
| Leap day as a spend date | `CalendarDate` day numbers; belongs to the month that `contains` it (test in T-201) |
| Remainder `N − 1` paise (₹0.29 over 30 days) | Property test plus an explicit case: 29 days at 1 paisa, the last day at 0 |
| Mid-month install on the last day (range 1 day) / on the start day | `planPeriod` with `n = 1`; a start-day install is treated as `FullMonthValues` (F-008 chooses the values type) |
| Change on the first / last day of the month | First day: the new period has the same start as period 1, so period 1 becomes `superseded` (kept). Last day: range 1 day |
| Lower costs after a continued shortfall | The new period's amount is recomputed; the totals' shortfall is the current period's |
| Spends before the first budgeted day, or outside the month | Excluded and reported in `ignoredSpends` |
| Covering the same day twice | Allowed while uncovered overspend > 0 (AC-11 a/b use the remaining overspend) |
| Over-covered day after an edit | Clamped to the new overspend, the rest returns to the pot, no reduction reported |
| Device date moves | Only the `today` passed in is used. The guard test forbids `DateTime.now`/clock in `domain/budget/` |
| `int` overflow | Max: 31 days × ₹10 crore spends = 3.1 × 10¹¹ paise, far below 2⁶³. App is Android-only (64-bit `int`); no web build (D-020) |
| `changedAt` ordering across time zones | Stored and compared as UTC epoch ms; only its order matters, never its calendar date |
| Risk: 100% branch coverage hard to keep | Small pure functions. Coverage is checked by script in T-205 and later by `check.ps1` (T-206) |
| Risk: spec rules interpreted differently by F-008/F-009 | Both call only `planPeriod`/`computeMonth`/`checkCover`; neither has its own money arithmetic (F-008 AC-19 code check) |

## 8. Impact on existing features
- **No existing file changes.** F-001 TC-001-06 (domain purity) must stay green: the new files import only `dart:core`/`dart:math` and `package:meta` if needed (`meta` is already resolved through Flutter, but `depend_on_referenced_packages` would require listing it, so the plan **avoids `package:meta`**).
- The new `domain_layering_test.dart` extends the guard without touching the Phase 0 test file. The F-001 test file gets a note from the Tester (new TC in F-006).
- Re-run: full `flutter test`, `tool/check.ps1`, `tests/REGRESSION.md`.

## 9. Open questions
1. **Money-left edits in a mid-month first month.** If the user edits "Money left now" on a later day, the plan applies §2.7 literally: the new value is the month's base, minus the budgets already used before today. This means "money left" keeps meaning "money left on the first budgeted day". Product Manager to confirm, or say it should mean "money left as of today" (then the earlier budgets are not subtracted).
2. **Persisting D-040 reductions.** The plan stores the reduced cover amounts (repository, F-007 T-209), so a cover taken back never reappears. Project Manager to confirm. The alternative (derive each time) would make a taken-back cover come back if the pot later grows.
3. **"What changed" is derived, not stored.** `BudgetPeriod.diff(previous)` computes it from the stored values. F-007 §2.1 lists it as stored; deriving it gives the same result with no risk of the two disagreeing. PM to accept at Gate 1.
4. **TC numbering.** Proposed TC-006-01 … -24 mirror the ACs; the Tester may split (e.g. one TC per §2.1 row). PM reconciles.

*Answered at Gate 1 (PM, 2026-11-10):* Q1 accepted as planned: "money left" means the money on the first budgeted day (F-006 §2.6, D-048, TC-006-59). Q2 accepted: the repository persists D-040 reductions **and** over-cover clamps in the same transaction as the edit (D-048, TC-007-46). Q3 accepted: "what changed" is derived by `diff`, not stored (F-007 §2.1 reworded). Q4: the Tester's IDs win; §6 now uses them.

## 10. Project Manager review *(Gate 1 — cross-check of doc + plan + test cases)*
**Verdict:** **Approved** (Project Manager, 2026-11-10). T-201 … T-205 may start now, in parallel with Phase 1 (D-033): new files only under `lib/domain/budget/`, `test/domain/budget/`, `test/architecture/` and `tool/`. No Phase 1 file is touched.

Cross-check:
- [x] Every AC in the feature doc is covered by a task in this plan (AC-1 … AC-25 → T-201 … T-205, §6)
- [x] Every AC has at least one test case in the test file (TC-006-01 … -60, §6 and the test file §2.4)
- [x] Edge cases in the doc appear in both the plan and the test cases (salary day 29–31, leap day, remainder N−1, install on the last/first day, change on the first/last day, lowered costs after a shortfall, spends before the first budgeted day, covering twice, over-covered day, device date moves, time zones, money in)
- [x] Approach follows `docs/STANDARDS.md` (pure Dart in `domain/`, integer paise via an extension type, no clock, 100% branches, layer guard extended in a new file)
- [x] Latest stable versions / modern APIs used (Dart 3.13 extension types, sealed classes with exhaustive `switch`, records; no package needed)

| # | Point | Type | Resolution |
|---|---|---|---|
| 1 | **D-047 money in (new Owner decision).** The engine accepts money in from Phase 2: `Spend.direction` (`spend` / `moneyIn`), net spend per day may be < 0, so the day is saved by more than its budget; spent so far is net and money in is reported separately. Manual "money in" entry is **not** in Phase 2 (D-051): F-009 adds no UI; F-007 stores the direction from schema v1 so Phase 4 needs no migration for it. | Must fix → done by PM | F-006 §1, §2.3, §2.5, §4, §6, new AC-25; this plan §2, §3, T-204; TC-006-60 added. |
| 2 | **Cover refusal order** (test notes 7). Fixed order: not positive → outside month → not budgeted → upcoming → not overspent → more than the uncovered overspend → more than the pot. Reason: day-level facts first, so the message names the day's problem before the pot's; TC-006-13 (j) isolates the pot rule. TC-006-13 (b) therefore expects `exceedsOverspend`. | Resolved (D-048) | F-006 §2.4, plan §3, TC-006-13. |
| 3 | **Covering today's live day** (test note 5). Allowed, as §2.4 "up to today" says; it is checked like any overspent day. The cover UI is Phase 3. | Resolved (D-048) | F-006 §2.4, TC-006-57. |
| 4 | **"Today" outside the month** (test note 4). Before the month: all days upcoming, every running total ₹0, Left = budgets − shortfall. After it: every day final, the last day's saving in the pot (this is the month-statement view). Never throws. | Resolved (D-048) | F-006 §2.9, plan §3, TC-006-50. |
| 5 | **Shortfall total after costs are lowered** (test note 3). The month Shortfall is the **current** period's. This is not a loss of information: with it, Left = current spendable − spent so far in every case (proof: if the amount to spread is ≥ 0, Σ budgets = spendable; if < 0, Σ budgets = past budgets and shortfall = past − spendable). The earlier shortfall stays in the period history. | Resolved (D-048) | F-006 §2.5, TC-006-42. |
| 6 | **"Money left now" edited later** (plan Q1, test note 9). Means the money on the first budgeted day; an edit is a §2.7 change. F-008 shows it as `Money left on <first day>` in edit mode so the label is not misleading (F-008 §5, `month-setup.md` §4.5). | Resolved (D-048) | F-006 §2.6; TC-006-59 added (₹24,900 → ₹26,400 on 20 Nov → 1,09,600 paise a day). |
| 7 | **Persisted D-040 reductions and clamps** (plan Q2). Accepted: a taken-back cover stays taken back, and a cover clamped by an edit that lowered the overspend stays clamped (covering is the user's decision, D-005; returned money is not silently re-used). The engine reports, the repository persists in the same transaction. | Resolved (D-048) | TC-007-46 (repository). Engine test note 8 closed. |
| 8 | **"What changed" derived** (plan Q3). Accepted: `BudgetPeriod.diff(previous)`; nothing stored that could disagree. | Resolved | F-007 §2.1 reworded. |
| 9 | **Invalid input.** §1.2 said "asserts"; asserts vanish in release builds and TC-006-56 expects an error. Public entry points throw `ArgumentError`, always on. | Must fix → done by PM | Plan §2/§3, F-006 §2.9. |
| 10 | **100% branch coverage definition** (test note 1). Per engine file in `lcov.info` from `flutter test --branch-coverage`: `BRH = BRF` and `LH = LF`. `tool/domain_coverage.ps1` checks exactly this; it covers every file under `lib/domain/budget/`, including the early pure files of F-008/F-009 (point 12). | Resolved (D-048) | F-006 AC-24, TC-006-31. |
| 11 | **TC reconciliation.** The Tester's 58 (now 60) IDs win; §6 rewritten with the Tester's map. Plan §7 overflow figure corrected (3.1 × 10¹¹ paise). | Resolved | §6, §7. |
| 12 | **Early pure-Dart parts of F-008/F-009** (F-008 plan Q2). Approved to start after T-204, by the same or a second Developer, new files in `lib/domain/budget/` only: **T-212a** `parseAmount`, **T-214a** `SetupDraft` (without the controller), **T-217** `TodayLine`, `groupSpendsByDay`, `SpendDraft`. They need no package and touch no Phase 1 file. | Resolved (D-052) | `docs/TASKS.md`. |
| 13 | **Riverpod codegen (D-027 revisit).** Not needed here; F-007 keeps manual providers. Agreed. | Resolved | — |
| 14 | **Nice to have:** a `MonthResult.debugTable()` (pure string) for the F-009 suggested "Numbers check", so the Owner can compare every day at sign-off. Small, no UI. | Nice to have | Follow-up task T-221. |

## 11. Implementation notes *(Developer, filled in during the build)*
Deviations from the plan and why (each to be approved by the Project Manager at code review).

### T-201 … T-205 (Engine Developer, 2026-11-11)
**Built:** `app/lib/domain/budget/` (12 files), `app/test/domain/budget/` (10 test files + `fixtures.dart`), `app/test/architecture/domain_layering_test.dart`, `tool/domain_coverage.ps1`, `tool/tz_matrix.ps1`. 58 new tests (55 engine + 3 guard), named by TC ID; full suite 248 tests green; `tool/check.ps1` PASS after each task. No existing file changed except this plan and the T-201 … T-205 rows of `docs/TASKS.md`; no package added.

| # | Deviation / decision | Why |
|---|---|---|
| E1 | **One library made of parts.** `budget.dart` is the only library (`library;` + `part` lines); the other 11 files are `part of 'budget.dart'`. Callers import `package:daily_budget/domain/budget/budget.dart` only. | `always_use_package_imports` would put `package:daily_budget/domain/...` paths in every engine file, and the TC-006-30 `/` pattern (`[^~/]/[^/=*]`) hits those import lines. With parts, the Tester's manual TC-006-28/-30 commands give **no output**. The early F-008/F-009 files (T-212a, T-214a, T-217) should join as parts too, or the TC-006-30 check needs an import-line exception. |
| E2 | **`CalendarDate` is an extension type** over the day number (`CalendarDate.fromDayNumber(int)`, unnamed factory from y/m/d, `fromDateTime`), not a class. | Free `==`/`hashCode` (map keys, record equality) without `package:meta`'s `@immutable`, which `avoid_equals_and_hash_code_on_mutable_classes` would require (plan §8 avoids `meta`). Zero cost, and F-007's converter is the identity. Cost: `toString()` is the day number; use `.iso` for text. |
| E3 | **Results are records**, not classes with `==`: `DayResult`, `PeriodResult`, `MonthTotals`, `EffectiveCover`, `CoverReduction`, `PeriodChange` (typedefs). `DayStatus` is an **enum** (no payload, still exhaustive). `MonthResult` is a `final class` holding lists of those records. | Structural equality for tests without `@immutable` (same lint as E2). Whole-output equality (TC-006-13, -49) compares a canonical `dump()` from `test/domain/budget/fixtures.dart`. |
| E4 | `MonthInput` has **no `salaryDay`**: `BudgetMonth` carries it. `planPeriod` takes **named** parameters. `monthStateFor({salaryDay, lastMonth, today})` returns a sealed `MonthState`: `NoMonthYet`, `CurrentMonth`, `NewMonthStarted(missedMonths)`; today before the last month (date moved back) → `CurrentMonth`; a salary day different from `lastMonth.salaryDay` throws. | One source of truth for the salary day. `monthStateFor` has no TC of its own; its checks are inside TC-006-03 (month containing today, 0/1/2 missed months) and TC-006-56 (mismatch). |
| E5 | `Paise` keeps `+`, `-`, unary `-`, `>`, `isNegative`/`isZero`/`isPositive`, `orZero`, `atMost`, `Paise.sum` and `spreadOver`. `<`, `<=`, `>=` were **dropped**. | Unused by the engine, so they broke `LH = LF` (AC-24). Add them back with a test when F-008/F-009 need them. |
| E6 | **Rules the plan left open, now fixed in code:** (a) an effective period whose outcome is `Shortfall` **or** `ZeroSpendable` must have `continuedWithShortfall: true`, else `ArgumentError` (the "needs a choice" case; the flag also covers D-043). (b) The first period must start on `firstBudgetedDay`; any period outside `firstBudgetedDay … month end` throws. (c) Same start **and** same `changedAt`: the later one in the input list wins. (d) Superseded periods: `days 0`, `end = start − 1`, no budgets; `amountToSpread`/`shortfall`/`zeroSpendable` come from their own plan, for the history. (e) Covers: amount ≥ ₹0 (₹0 = a stored D-040 reduction); a cover on a day outside the budgeted days throws. (f) The over-cover clamp uses the day's own overspend (budget − net spend), so it does not depend on "today"; covers of days after today (only possible if the device date moved back) are not in Covered/pot and are never reduced. (g) A reduction's `oldAmount` is the amount after the clamp. (h) Spends after the month end are ignored and reported like spends before the first budgeted day. | Each keeps "never silently fix" (D-048 (9)) and "a reduced cover stays reduced" (D-048 (6)). |
| E7 | **Coverage numbers:** Flutter 3.47.9's `lcov.info` has `BRDA` lines but **no `BRF`/`BRH` totals**, so `tool/domain_coverage.ps1` counts both from the `DA`/`BRDA` lines, and fails on any missed line or branch and on any engine file no test loads (a file of only comments and directives, i.e. `budget.dart`, is accepted). Result, every file `LH = LF` and `BRH = BRF`: `budget_engine` L 205/205 B 68/68 · `budget_month` 31/31, 11/11 · `budget_period` 63/63, 30/30 · `calendar_date` 27/27, 16/16 · `paise` 23/23, 16/16 · `spread_outcome` 22/22, 10/10 · `month_result` 2/2, 2/2 · `cover`, `fixed_cost`, `month_input`, `spend` 1/1, 1/1. The script was also seen to fail (only `budget_month_test.dart` run → 10 files FAIL). | **Tester:** the TC-006-31 command in `tests/F-006` §1.1 reads `BRF`/`BRH` lines, so it prints empty branch numbers; it should count `BRDA` lines (hit = last field not `-` and > 0). |
| E8 | **`tool/tz_matrix.ps1`** runs the tests three times (`TZ=UTC`, `TZ=PST8PDT`, default = IST), passing `EXPECT_TZ_OFFSET_MIN` and `TZ_NAME`; the TC-006-27 sentinel checks the real offset (0 / −480 / +330) and writes `build/tz/<zone>.txt`; the script then requires the three SHA-256 hashes to match (it skips the comparison with a note when the given tests write no dumps, for F-007 reuse). Result: 3 × 55 passed, one hash. `-Tests` and `-DefaultOffsetMinutes` parameters. | AC-23, TC-006-27, TC-006-58 (DST checks inside TC-006-02 and a Mar 2027 month in the dump). |
| E9 | **`tool/check.ps1` not changed**: the two scripts join it in T-206 (plan §2), after Phase 1 approval. | `check.ps1` belongs to the Phase 1 commit. |
| E10 | **Test files** use the Tester's names (`budget_month_test`, `spread_test`, `spread_property_test`, `day_result_test`, `savings_pot_test`, `month_totals_test`, `shortfall_test`, `mid_month_test`, `periods_test`, `engine_time_zone_test`). `tests/F-006…` was not edited (instruction); the Tester adds the file names to the rows. Property tests: TC-006-06 10,217 cases, -07 2,000 months, -23 2,000 changes, -47 1,000 sequences; seed `Random(2026)` or `--dart-define=PROPERTY_SEED=<n>`, printed in every failure reason. | — |
| E11 | Nice to have **T-221** (`MonthResult.debugTable()`) not built. The test-side `dump()` in `fixtures.dart` already prints every day, period, total, cover and reduction and could be moved into `lib/` for it. | Out of T-201 … T-205 scope. |

**Project Manager, Gate 3 (2026-11-11, `docs/reviews/code-phase-2.md`):**
- E2–E11 approved.
- **E1 not approved:** the engine goes back to one library per file, with `budget.dart` as an export barrel, and the TC-006-30 guard skips directive lines and comments (M1, M2, D-059).
- Must fix M3: `PeriodResult.spent` becomes `netSpent`, and a day gets a `netSpent` figure next to the gross `spent`.
- F-010 Q-1 decided: Overspent includes today's live overspend (D-060), as the engine already does (TC-006-18).
- Verdicts:
  - T-202, T-203, T-205: Ready for test.
  - T-201, T-204: In progress for M1–M3.
- Nice to have: T-226.
- Tester follow-ups: T-224.

### Gate 3 rework: M1, M2, M3 and T-226 (Developer, 2026-11-11)
**Result:** `tool/check.ps1` ALL CHECKS PASSED (253 tests at this point: 248 + 5 new), `tool/domain_coverage.ps1` 100% lines and branches per file, `tool/tz_matrix.ps1` PASSED (3 zones, identical dump hashes). No money number changed: every expected value in the existing tests is untouched.

| # | What was done |
|---|---|
| M1 | `test/architecture/domain_layering_test.dart`: the TC-006-30 guard now looks at code only (`codeOnly`): lines starting with `import`, `export`, `part` or `library` are skipped, string literals are blanked and everything from `//` to the end of the line is cut. Self-proofs added: an `import` line, an `export` line, `// spends and/or refunds` and `final s = 'a / b';` give no match; `final c = a / b; // x` still matches; all 8 bad lines still match. The clock and import guards are unchanged. The Tester's manual TC-006-30 command (T-224) must skip the same directive lines. |
| M2 | E1 is gone. Every file in `lib/domain/budget/` is its own library and imports what it uses by `package:daily_budget/domain/budget/<file>.dart`. `budget.dart` is `library;` plus one `export` per file (D-059). No private name was shared across files, so only the first lines of the files changed. No test changed its imports. |
| M3 | `PeriodResult.spent` is now `netSpent` (net of money in). `DayResult` gets `netSpent` (= `spent - moneyIn`) next to the gross `spent`, whose doc comment now says "gross". `MonthTotals.spentSoFar` keeps its name. The private `_Sums.spent` became `netSpent`. `dump()` and the tests that read the old names were updated (`day12.netSpent` replaces `spent - moneyIn`, and so on). |
| N1 (T-226) | `MonthResult.currentPeriod` (and `currentPeriodIndex`): the first period before the month, the last effective one after it, never a superseded one. It uses the existing `_currentPlan`. Tests: TC-006-21 (index before, on and after a same-day change) and TC-006-43 (the zero-spendable flag is reachable). |
| N3 (T-226) | `computeMonth` throws `ArgumentError` for two covers with the same id (checked first, so the identity map can no longer hold two entries for one value). `MonthResult.dayOn` throws `ArgumentError` for a date outside the month. Tests: TC-006-56. |
| N4 (T-226) | `engine_time_zone_test.dart` uses the literal `p(1775000)`. |

**Tests added** (`test/domain/budget/engine_hardening_test.dart`, 5 tests): TC-006-21, TC-006-43, TC-006-56 (two), TC-006-60 (day `netSpent`). The guard test TC-006-30 got its new self-proofs.
**Files changed:** all 12 files in `lib/domain/budget/` (headers; M3 and N1/N3 in `month_result.dart` and `budget_engine.dart`), `fixtures.dart`, `day_result_test.dart`, `periods_test.dart`, `spread_property_test.dart`, `engine_time_zone_test.dart`, `domain_layering_test.dart`.
**Not changed:** `tool/` scripts, `check.ps1`, anything outside `lib/domain/budget/` and `test/`. Coverage for the changed files is still 100% (`budget_engine` L 210/210, B 70/70).
**For the Tester (T-224):** the TC-006-30 command must skip directive lines (see the review); the new tests carry TC-006-21, -43, -56, -60 in `engine_hardening_test.dart`.
**For the Project Manager:** T-201 and T-204 are back in Code review for the re-review of M1 to M3. N2 stays with the F-017 plan.

**Project Manager, Gate 3 re-review (2026-11-11, `docs/reviews/code-phase-2.md` "Re-review"):** M1, M2, M3 and T-226 (N1, N3, N4) verified; E1 is gone. T-201, T-204 and T-226 are Ready for test, with T-202, T-203 and T-205 (notes confirmed). `check.ps1`, `domain_coverage.ps1` (100%, 17 files) and `tz_matrix.ps1` (3 zones, identical dumps) green.
