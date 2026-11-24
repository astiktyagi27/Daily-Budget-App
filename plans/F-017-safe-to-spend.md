# Plan — F-017: Safe to spend (per day)

| | |
|---|---|
| **Feature doc** | [`docs/features/F-017-safe-to-spend.md`](../docs/features/F-017-safe-to-spend.md) (final spec, 11 ACs; formula option A confirmed by the Owner, D-058) |
| **Test cases** | [`tests/F-017-safe-to-spend.md`](../tests/F-017-safe-to-spend.md) (written 2026-11-16, TC-017-01 to TC-017-36, authoritative; section 6 re-mapped at Gate 1) |
| **Design** | `docs/design/screens/home-summary.md` §4 row 6 and H-1 (the guide strip), §12 copy |
| **Inputs** | D-005, D-038, D-048 (10), D-050/D-055, D-056 (3), D-058, D-059, D-060; `docs/reviews/code-phase-2.md` (N2, and the "What Phase 3 needs" table) |
| **Author** | Developer 1 |
| **Status** | Plan approved (Gate 1, 2026-11-16, Project Manager A; see section 10) |

## 1. Approach
F-017 is **one pure function plus one small widget**. It adds a new money figure but no money rule beyond the Owner's formula, and it never touches the engine's output.

1. **Pure function in `domain/budget/` (engine addition N2).** `safeToSpendPerDay(MonthResult) → SafeToSpend`. It reads only what the engine already returns:
   - `result.totals.left` (F-006 §2.5: budgeted − net spent so far − shortfall);
   - `result.dayOn(result.today).netSpent` (today's net spend, refunds already taken off, D-047);
   - `days left including today = today.daysUntil(month.end) + 1`.

   ```
   numerator = totals.left + dayOn(today).netSpent
   perDay    = numerator ~/ daysLeft            // integer paise, rounded down (D-058)
   ```
   The result is a sealed type, so the widget is an exhaustive `switch` and no screen does money arithmetic (F-008 AC-19):
   - `SafeToSpendAmount(perDay, daysLeft)` when `perDay` is at least ₹1 (100 paise);
   - `SafeToSpendUnderRupee(daysLeft)` when `numerator` is above ₹0 but `perDay` is under 100 paise (`less than ₹1 a day`, D-050);
   - `SafeToSpendNothingLeft` when `numerator` is ₹0 or below (`Nothing left to spread over the rest of the month.`);
   - `SafeToSpendUnavailable` when today is not a budgeted day of the month (the device date was set back before the first budgeted day or the month; or today is after the month's end). The line is then hidden. **Team decision, see §9 Q1.**
   **Gate 1 (D-076): two layers.** A pure core `safeToSpendFrom({required Paise left, required Paise todayNetSpend, required int daysLeft})` treats `daysLeft` below 1 as 1 and classifies by the numerator (this is what TC-017-01, -10, -14, -17, -18 and -19 call). `safeToSpendPerDay(MonthResult)` reads the three inputs and returns `SafeToSpendUnavailable` when today is not a budgeted day, else delegates to the core. The sealed subtypes keep the plan's names (`SafeToSpendAmount`, `SafeToSpendUnderRupee`, `SafeToSpendNothingLeft`, `SafeToSpendUnavailable`); the Tester's `perDay`, `lessThanRupee`, `nothingLeft` mean the first three.
2. **Why a function over `MonthResult` and not a field on the engine.** The engine's job is the budget; Safe to spend is a guide that must never feed back into any budget, result, pot or total (AC-10). A separate file, taking the result as input, makes that visible and testable ("engine output identical before and after", AC-10). It is exported from the `budget.dart` barrel (D-059).
3. **Integer only.** `Paise` has no division on purpose (`spreadOver` is the only splitter and refuses negatives). The function uses `numerator.value ~/ daysLeft` inside its own file, with `daysLeft >= 1` guaranteed by the "budgeted day" check. The TC-006-30 guard bans `/`, `double` and `num`, not `~/`, so no guard change is needed.
4. **Classification by the numerator, not by the floored figure.** A numerator of 10 paise over 22 days floors to 0 paise but is still money left, so it reads `less than ₹1 a day`, not `Nothing left`. This is the only reading that keeps "above ₹0 but less than ₹1" (F-017 §2.1) true for every input. **PM to confirm (§9 Q2).**
5. **Widget:** `SafeToSpendStrip` in `features/home/widgets/` takes a `SafeToSpend` and draws the guide strip of the design (`sunken` fill, `radiusMd`, label `Safe to spend` + (i), value `₹899 a day · 22 days left` in `moneyMedium` ink, never green or red). F-010's summary card places it (home-summary H-2 order); F-017 owns the strip and its copy.
6. **Where it is used.** Only on the summary card (F-017 §2.3, AC-10). An architecture test asserts that `safeToSpendPerDay` and `SafeToSpendStrip` are referenced only from the Home summary files, so the Today card, calendar, collapsed row, Dashboard and statement can never show it by accident.
7. **Live behaviour comes for free.** `homeViewProvider` (F-010 T-301) calls the function from `monthResultProvider`, which already recomputes on every add, edit, delete, refund, cover and at midnight (`todayProvider`). Covers do not change `Left` or today's net spend, so the figure does not move for them (AC-3); spending today moves both `Left` and `netSpent` by the same amount, so it stays (AC-2).

## 2. Files / modules
| Path | Add / Change | What |
|---|---|---|
| `app/lib/domain/budget/safe_to_spend.dart` | Add | `safeToSpendPerDay`, sealed `SafeToSpend` (+ 4 subtypes), doc comments quoting D-058 |
| `app/lib/domain/budget/budget.dart` | Change | One more `export` line (D-059) |
| `app/lib/features/home/widgets/safe_to_spend_strip.dart` | Add | The strip: 3 visible variants, `Unavailable` renders nothing; (i) via `InfoButton`; one screen-reader sentence |
| `app/lib/core/copy/safe_to_spend_copy.dart` | Add | `Safe to spend`, `<amount> a day`, `<n> days left` / `1 day left`, `less than ₹1 a day`, `Nothing left to spread over the rest of the month.`, (i) body, speech sentence (F-017 §5, home-summary §12) |
| `app/test/domain/budget/safe_to_spend_test.dart` | Add | `TC-017-NN …` unit tests, literals from the spec (no computed expectations) |
| `app/test/features/home/safe_to_spend_strip_test.dart` | Add | Widget tests: variants, four themes, 2.0x, landscape, semantics |
| `app/test/architecture/safe_to_spend_scope_test.dart` | Add | AC-10: the figure appears only in the Home summary files |
| `app/test/architecture/domain_purity_test.dart` | Change | scan `safe_to_spend.dart` for `double`, `num`, `/`, rounding calls (TC-017-20) |

Nothing in `data/`. No new table, no stored value ("Data stored: none", F-017 §7).

## 3. Data model / database changes
None. The figure is derived on every build from `MonthResult`, never stored.

## 4. Packages (latest stable, checked on pub.dev)
| Package | Version | Why |
|---|---|---|
| — | — | None new |

## 5. Tasks
IDs confirmed by the Project Manager at Gate 1 (2026-11-16); the board is `docs/TASKS.md`.

| ID | Task | Covers AC | Depends on | Status |
|---|---|---|---|---|
| T-360 | **Pure function and unit tests.** `safe_to_spend.dart` + barrel export. Tests (literals from F-017 §2.2): example A 13 Nov → 89,954; after a ₹410 spend today → still 89,954; after the ₹300 cover → 89,954; 14 Nov → 92,238; day one of E2 → 83,000 and 30 days; example F day one → 99,600 and 25 days; example M 20 Nov (canonical M20, ₹850 spent today) → 70,454 and 11 days; example S → `NothingLeft`; `Left + today` exactly 0 and below 0 → `NothingLeft`; 50 paise on 1 day → `UnderRupee`; 99 and 100 paise per day boundary; 10 paise over 22 days → `UnderRupee`; last day (1 day left); ₹10 crore (10000000000 paise) over 22 days = the literal 454545454 paise (₹45,45,454 a day); refund today does not raise it, refund on a past day does (₹500 → 92,227); today before the month and after the month → `Unavailable`; the engine output compared with `dump()` before and after → identical. Runs `tool/domain_coverage.ps1` (100% lines and branches) and the TC-006-30 guard, and extends `domain_purity_test.dart` (TC-017-20) | AC-1 (value), AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8 (value), AC-9, AC-10 (purity) | F-006 (exists), T-308 | To do |
| T-361 | **Strip widget + copy.** `SafeToSpendStrip`, `safe_to_spend_copy.dart`, the (i) sheet, semantics (`Safe to spend, ₹899 a day, 22 days left`; nothing-left and under-rupee variants), singular `1 day left`; amounts through `formatRupees`; all four themes, text scale 2.0 (wraps at ` · `), landscape 640x360 | AC-1 (screen), AC-7 (screen), AC-11 | T-360, T-313 (Gate 2) | To do |
| T-362 | **Wire into Home and prove the live behaviour.** F-010's `HomeSummary`/`homeViewProvider` calls `safeToSpendPerDay`; the card places the strip. Widget tests on fakes with a movable clock: add a ₹410 spend today (line unchanged, Today card says `on budget`), cover 11 Nov (unchanged), midnight to 14 Nov (₹922, 21 days), refund of ₹500 on 12 Nov via the repository's `direction: moneyIn` (₹922, 22 days; F-016's screen is not needed to seed it), shortfall month (no amount). Architecture test `safe_to_spend_scope_test.dart` | AC-1, AC-2, AC-3, AC-4, AC-5, AC-8, AC-10 | T-360, T-361, F-010 T-301/T-302 | To do |

## 6. Acceptance criteria coverage
Test case IDs are the Tester's (`tests/F-017-safe-to-spend.md`, section 2.4), re-mapped by the Project Manager at Gate 1 on 2026-11-16. The earlier proposed slots are retired. Edge cases of the doc section 4: cover today TC-017-06, refunds today -32, device date back -33, no current month -34, 10 crore -19, last day -28, today not budgeted -36.

| AC | Built in task | Proved by test cases (Tester IDs) |
|---|---|---|
| AC-1 Example A shows `₹899 a day · 22 days left`, function returns 89,954 | T-360, T-361, T-362 | TC-017-01, -02, -03, -28, -29 |
| AC-2 Stable during the day | T-360, T-362 | TC-017-04, -05, -32 |
| AC-3 Covers do not change it | T-360, T-362 | TC-017-06 |
| AC-4 Next day `₹922 a day · 21 days left` | T-360, T-362 | TC-017-07, -08, -33 |
| AC-5 Equals the daily budget on day one (E2, example F, month lengths) | T-360, T-362 | TC-017-09, -10, -30 |
| AC-6 Mid-month change `₹704 a day · 11 days left` | T-360 | TC-017-11, -12 |
| AC-7 Nothing left; `less than ₹1 a day` | T-360, T-361 | TC-017-13, -14, -15, -31, -35 |
| AC-8 Refund on a past day (92,227) | T-360, T-362 | TC-017-16, -17 |
| AC-9 Integer, pure, rounds down, no divide by 0, 100% branches, 10 crore exact | T-360 | TC-017-18, -19, -20, -21 |
| AC-10 Not a budget; only on the summary card | T-360, T-362 | TC-017-22, -23, -34, -36 |
| AC-11 Help, four themes, 2.0x, landscape, TalkBack sentence | T-361 | TC-017-24, -25, -26, -27 |

## 7. Edge cases & risks
| Case / risk | How it is handled |
|---|---|
| Today has a cover | `Left` and today's net spend are both unchanged, so the figure is unchanged (F-017 §4; TC-017-03) |
| Refunds received today | Net spend today goes negative and is added back, so today's refund does not raise today's figure until tomorrow (F-017 §4). A past-day refund raises it at once (AC-8). Test with the repository fake |
| Device date set back to before the month or first budgeted day, or after the month's end | `SafeToSpendUnavailable`: the line is hidden. The spec says "uses the given today"; for a date inside the month this is exactly what happens. For a date outside it there is no "days left" to divide by, so showing nothing is safer than inventing a count. **§9 Q1** |
| Future-dated spends (clock moved back) | Ignored, as the engine ignores them (F-006 AC-13); `Left` and `dayOn` already exclude them |
| New month not set up / no month / past month | `homeViewProvider` never builds an `ActiveHome`, so there is no strip (F-017 §2.3) |
| Last day of the month | `daysLeft = 1`; the figure is all of `Left + today's net spend`; copy says `1 day left` |
| Very small positive numerator | `UnderRupee` (§1 item 4); never `₹0 a day` and never `−₹0` (D-050, D-055) |
| ₹10 crore `Left` | `perDay` up to 10,00,00,00,000 paise fits in `int`; the line wraps at 2.0x (`₹45,45,454 a day`); layout test with that amount |
| Money-rule risk: the strip is mistaken for today's budget | Design H-1: own inset, ink colour, own label and (i); not in the Today card, calendar or collapsed row; the scope architecture test enforces it |
| Money-rule risk: a later change feeds the figure back into the engine | `safeToSpendPerDay` takes a finished `MonthResult` and returns a value; AC-10's "identical before and after" test compares `dump()` of the result |
| Rounding: floor on the figure but `Left` shown rounded toward ₹0 | Both are display roundings of exact paise (D-038); the figure is computed from exact paise, never from the rounded `Left` |

## 8. Impact on existing features
- **F-006 (engine):** one new file and one export line. No existing function changes. Re-run the engine guards: TC-006-27…31 (no clock, no float, no DB), the 100% branch check in `tool/domain_coverage.ps1`, and `tool/tz_matrix.ps1` (the new test file is pure and has no time-zone dependency, but the matrix must stay green).
- **F-010:** the summary card gains the strip (home-summary §4 row 6). F-010's cases for the card layout and the order of items are written with the strip in place. See `plans/F-010-home-summary.md` T-302.
- **F-004:** the strip's (i) uses the shared `InfoButton`. The help-rule guard (TC-004-08) covers `lib/features/`; the strip must use `InfoButton` and no raw `Tooltip(` or `IconButton(`.
- **F-002:** tokens only (`sunken`, `textPrimary`, `textSecondary`, `moneyMedium`); the tokens-only architecture test must stay green.
- No other earlier feature is affected. Re-run: the F-006 suite, TC-008 Home cases only through F-010's re-runs.

## 9. Open questions
1. **Project Manager (team decision).** When today is not a budgeted day (device date set back before the first budgeted day, or after the month ended while the month is still the latest), the plan **hides** the line (`SafeToSpendUnavailable`). The alternative is to clamp today to the first budgeted day, which would show a number that was never "today". If the PM prefers to show a figure, say so: it would be a rule for a display edge case, and the PM should say if that needs the Owner.
2. **Project Manager.** The plan classifies `less than ₹1 a day` by the **numerator** being above ₹0 (§1 item 4), so 10 paise over 22 days reads `less than ₹1 a day`. F-017 §2.1 says "above ₹0 but less than ₹1" and AC-7 only tests 50 paise over 1 day. Please confirm, or ask the Product Manager to add a line to the spec.
3. **Owner decision needed?** **No.** The formula was confirmed in D-058, the figure is a guide that changes no budget, and there is no permission, network or privacy change. Both questions above are display edge cases on a figure the Owner already approved. If the PM reads Q1 or Q2 as a change to how money is "calculated or displayed" (WORKFLOW "Escalate to Owner"), escalate; the plan's default is the more conservative choice in each.
4. **Open Phase 3 items 5 and 6:** neither touches F-017.

## 10. Project Manager review *(Gate 1 — cross-check of doc + plan + test cases)*
**Verdict:** **Approved** (Project Manager A, 2026-11-16). Must fix points 1 and 2 are done by PM edits. Decisions D-073 to D-079. This is a new money figure but its formula was confirmed by the Owner (D-058); the two display edge cases below are team decisions inside D-050 and D-058 (shown to the Owner as an FYI, no action). Build track: with F-010 (strip) per the Build order; T-360 can start at once.

Cross-check:
- [x] Every AC in the feature doc is covered by a task in this plan (11 of 11, section 6)
- [x] Every AC has at least one test case in the test file (11 of 11, tests section 2.4)
- [x] Edge cases in the doc appear in both the plan and the test cases
- [x] Approach follows `docs/STANDARDS.md` (pure integer function in `domain/`, no `double`, sealed result, widget does no arithmetic)
- [x] Latest stable versions / modern APIs used (no new package; Dart 3 sealed class and exhaustive switch)

Money rules D-034 to D-062 and D-069 to D-072: untouched. The function reads a finished `MonthResult` and returns a value; AC-10 and TC-017-22 prove the engine output does not change. The PM re-derived the Tester's extra figures (TC-017-28 to -31, -15): 24,90,000 / 1 = ₹24,900; 23,07,000 / 29 = 79,551 (₹795); 24,90,000 / 28 = 88,928 (₹889) and / 29 = 85,862 (₹858); 40,00,000 / 28 = 1,42,857 (₹1,428); 1,80,000 / 27 = 6,666 (₹66): all agree with D-058.

| # | Point | Type | Resolution |
|---|---|---|---|
| 1 | The plan's function takes a `MonthResult` and guarantees `daysLeft` of at least 1, but the cases (TC-017-01, -14, -18) call it with raw numerators and days and expect `daysLeft` 0 or −3 to be treated as 1 | Must fix (Developer, done by PM) | Plan section 1 now has the two layers: pure core `safeToSpendFrom(left, todayNetSpend, daysLeft)` plus `safeToSpendPerDay(MonthResult)` (D-076). The Tester's `perDay`, `lessThanRupee`, `nothingLeft` map to the plan's `SafeToSpendAmount`, `UnderRupee`, `NothingLeft` |
| 2 | TC-017-20 needs `domain_purity_test.dart` extended; the plan did not list it | Must fix (Developer, done by PM) | Row added to section 2 and to T-360 |
| 3 | Q1: today not a budgeted day: hide or clamp | Decision (D-076) | Hide (`SafeToSpendUnavailable`); clamping would show a number that was never "today". TC-017-36 stands as written. Doc section 4 line added |
| 4 | Q2: 10 paise over 22 days | Decision (D-076) | Classify by the amount to spread: any positive amount reads `less than ₹1 a day`; `Nothing left to spread over the rest of the month.` only when Left plus today's net spend is ₹0 or below. Saying "nothing left" while money is left would be false. Doc section 2.1 clarified; TC-017-35 stands |
| 5 | AC-5 "equals the daily budget on day one" is exact only when the amount divides evenly | Decision (D-076) | The figure equals the lowest daily amount (days differ by 1 paisa, D-035). AC-5 wording extended in the doc; TC-017-30 shows it |
| 6 | Q3: Owner decision needed? | Decision | No (formula D-058; wording D-050). Reported to the Owner as an FYI |
| 7 | Q4 and the editor and delete items | Decision | Neither touches F-017 |
| 8 | TC-017-21 (100% branches) is a manual command | Nice to have | Accepted, as in F-006 (a `switch` on a sealed type may report no branch) |
| 9 | TC-017-23 gets the F-013 and F-014 screens when they are built | Nice to have | Tester adds them to the scope sweep then (B's features) |
| 10 | A refund received today does not raise today's figure (start-of-today rule) may surprise a user | Nice to have | Doc section 4 states it; TC-017-32 proves it; no change |

## 11. Implementation notes *(Developer, filled in during the build)*
Deviations from the plan and why (each approved by the Project Manager).

**Track A build (Developer A, 2026-11-19): T-360, T-361 and T-362 built, status Code review.**
- **Files.** `domain/budget/safe_to_spend.dart` (`safeToSpendFrom`, `safeToSpendPerDay`, sealed `SafeToSpend`: `SafeToSpendAmount`, `SafeToSpendUnderRupee`, `SafeToSpendNothingLeft`, `SafeToSpendUnavailable`), barrel export, `core/copy/safe_to_spend_copy.dart`, `features/home/widgets/safe_to_spend_strip.dart`, placed by `summary_card.dart`; `homeViewProvider` calls `safeToSpendPerDay`.
- **Tests.** `test/domain/budget/safe_to_spend_test.dart` (TC-017-01, -02, -05, -08, -10, -12, -14, -17, -18, -19, -22, -35, -37), `test/architecture/domain_purity_test.dart` (TC-017-20), `test/features/home/safe_to_spend_strip_test.dart` (TC-017-03, -04, -06, -07, -09, -11, -13, -15, -16, -24, -26, -28 to -34, -36), `test/architecture/safe_to_spend_scope_test.dart` (TC-017-23, a text scan of `lib` plus a widget check), `phase3_screen_sweep_test.dart` (TC-017-25). TC-017-21: `tool/domain_coverage.ps1` reports `safe_to_spend.dart` L 20/20, B 10/10. TC-017-27 is manual (TalkBack).
- **Deviation (TC-017-30 (c), Tester's number).** Salary day 29 in 2028 gives the month 29 Feb - 28 Mar (29 days; it ends the day before the next 29th), not 29 Feb - 29 Mar. The engine's figures are `₹858 a day · 29 days left` on 29 Feb and `₹889 a day · 28 days left` on 1 Mar; the test asserts those. The Tester should correct the case.
- **Safe to spend is computed from exact paise**, never from the rounded Left; the strip's value is one `Text` with non-breaking spaces so it wraps only at the dot.

