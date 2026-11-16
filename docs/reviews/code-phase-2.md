# Code review (Gate 3): Phase 2

One file for the phase, with a section for each batch of tasks. Reviewer: Project Manager.

---

## T-201 … T-205: F-006 budget engine (2026-11-11)

**Verdict: Changes requested.** The money logic is correct: every Owner rule I spot-checked holds. Three Must-fix items are about structure and naming, not numbers:
- **M1:** the integer-only guard (TC-006-30) also matches import paths. That bug is the only reason the engine is built as one library made of parts (E1).
- **M2:** go back to one library per file, with `budget.dart` as the single import.
- **M3:** "spent" means gross spends in one result and net spend in the others.

| Task | Verdict | Status |
|---|---|---|
| T-201 `CalendarDate`, `BudgetMonth`, layering guard | Changes requested (M1, M2) | In progress |
| T-202 `Paise`, `spreadOver`, property test | Approved | Ready for test |
| T-203 Periods, `planPeriod`, shortfall, `diff` | Approved | Ready for test |
| T-204 `computeMonth`, `checkCover`, reductions, totals | Changes requested (M3) | In progress |
| T-205 Coverage and TZ scripts | Approved | Ready for test |

M2 only changes the top of each file (`part of` becomes imports), so T-202, T-203 and T-205 keep their approval. The Tester runs Step 8 for all five tasks **after** the M1–M3 re-review, so one run covers the final files (T-224).

**Files:** `app/lib/domain/budget/` (12 files), `app/test/domain/budget/` (10 test files + `fixtures.dart`), `app/test/architecture/domain_layering_test.dart`, `tool/domain_coverage.ps1`, `tool/tz_matrix.ps1`. No existing file changed. No package added.

### What I ran (2026-11-11, Flutter 3.47.9)
| Command | Result |
|---|---|
| `tool/check.ps1` | **ALL CHECKS PASSED**, exit 0, **248 tests** (full tree, including the Phase 1 work in progress) |
| `tool/domain_coverage.ps1` | **100%**, exit 0. `budget_engine` L 205/205 B 68/68 · `budget_month` 31/31, 11/11 · `budget_period` 63/63, 30/30 · `calendar_date` 27/27, 16/16 · `paise` 23/23, 16/16 · `spread_outcome` 22/22, 10/10 · `month_result` 2/2, 2/2 · `cover`, `fixed_cost`, `month_input`, `spend` 1/1, 1/1 · `budget.dart` has directives only |
| `tool/tz_matrix.ps1` | **PASSED**, exit 0. 55/55 tests in UTC, PST8PDT and IST. The sentinel offsets were real. All three dumps have SHA-256 `EA0839D8…5044CE` |
| Independent re-count of `lcov.info` (my own `DA`/`BRDA` counter, the corrected TC-006-31 command below) | Same numbers as the script, file by file |
| Tester's TC-006-28 / TC-006-30 commands | No output (pass), but only because of E1 (see M1) |

### Checklist
| Check | Result |
|---|---|
| **Correct** | Matches plan §3 and the Owner rules. See the spot-check table below. Invalid input always throws `ArgumentError` (D-048 (9)). Nothing is silently fixed. |
| **Clean** | Small pure functions with no clock and no I/O. A sealed `SpreadOutcome` and an exhaustive `switch`. The newest-first cut is one short loop. The 2 private mutable helpers (`_Effective`, `_Sums`) stay inside one function's work. Issues: M2 (parts) and M3 (naming). |
| **Modern** | Dart 3.13 extension types (`Paise`, `CalendarDate`), records for the results, sealed classes, `const new` constructors (D-024), and patterns in `switch` and `for`. Nothing is deprecated. |
| **Tested** | 58 new tests, named by TC ID. Property tests use a fixed seed, which is printed in every failure reason. The guards prove they can fail. Coverage is 100% per file. TZ matrix runs in 3 zones and checks the dump hashes. Minor point: N4. |
| **UX** | No UI. The API is ready for Phase 3, with gaps N1 and N2 (see "What Phase 3 needs"). |
| **Safe** | No logging, no I/O, no network. `dart:io` and DB packages are banned from `domain/` by TC-006-29. |

### Money correctness spot-check (against the Owner decisions)
| Rule | Where in code | Verdict |
|---|---|---|
| **D-035** spread, extra paise first | `Paise.spreadOver`: `base = v ~/ n`, the first `v % n` days get +1. `List.unmodifiable`. Throws on `n < 1` or `v < 0` | ✓ TC-006-05/-06 (10,217 cases)/-08/-36 |
| **D-036 / D-043** shortfall and ₹0 spendable | `planPeriod`: `> 0` → `Spread`, `= 0` → `ZeroSpendable`, `< 0` → `Shortfall(−amount)`, budgets ₹0, never negative. An effective non-`Spread` period without `continuedWithShortfall` throws (E6a, the "needs a choice" case). Month Shortfall = the **current** period's (D-048 (4)), so `left = budgeted − spentSoFar − shortfall` | ✓ TC-006-17/-18/-24/-39/-42/-51 |
| **D-037** periods | Sorted by (start, `changedAt`, input index). A same-start earlier change is `superseded` (0 days, kept). Each effective period spreads `spendable − Σ earlier budgets` from its start (the change day, inclusive) to month end. Past budgets are untouched | ✓ TC-006-21/-22 (₹552.23/₹552.22)/-23/-25/-26/-40/-41 |
| **D-039** pot at day end | `savedBeforeCovers` and `_Sums.saved` count only `i < todayIndex`. Today is `live`. After the month, `todayIndex ≥ dayCount`, so the last day is in the pot | ✓ TC-006-11/-50 |
| **D-040** newest-first reductions | Clamp first: each cover is limited to its day's remaining overspend, oldest first (not reported). Then `excess = Σ counted covers − saved` is cut from the newest `madeAt` (ties broken by id). Each cut is reported with `oldAmount` = the amount after the clamp. Stored ₹0 covers are skipped. I checked that the pot can't go negative: covered days have results ≤ ₹0 after the clamp, so `saved` equals `savedBeforeCovers` | ✓ TC-006-14/-45/-46/-47 (property) |
| **D-047** money in | The day result is `budget − spends + moneyIn + covered`, and it may be above the budget. `spentSoFar` is net and `moneyIn` is reported separately | ✓ TC-006-60. Naming issue: M3 |
| **D-057** late / missed-month start | `firstBudgetedDay` = the setup day with `MidMonthStartValues`. Earlier days are `notBudgeted`, have no budget or result, and are in no total, so they can never count as saved. `monthStateFor` returns `NewMonthStarted(containing, missedMonths)` and never creates the skipped months | ✓ TC-006-03/-20/-38/-43 |
| D-034 / D-042 / D-048 (5) mid-month, money left | `spendable = moneyLeft − stillToPay`. A later edit is an ordinary period | ✓ TC-006-20/-59 |
| D-048 (1)/(2) cover order, today coverable | `_refusalFor` checks in the D-048 order. Only `day.isAfter(today)` is upcoming, so today can be covered | ✓ TC-006-13 (7 distinct reasons, deep equality)/-44/-57 |
| D-038 / D-046 / D-050 / D-055 display rounding | Not the engine's job: it returns exact paise. ✓ No `/`, `double` or rounding in `domain/budget/` | ✓ TC-006-30 |
| AC-23 no clock | No `DateTime.now`. `CalendarDate` is a day number built through `DateTime.utc`. `fromDateTime` uses only y/m/d | ✓ TC-006-27/-28, TZ matrix |

### What Phase 3 needs: can the engine answer it?
| Need | Answer |
|---|---|
| **D-058 Safe to spend** = (Left + today's net spend) ÷ days left including today | **Yes, from data already in the result:** `totals.left`, `dayOn(today).spent − dayOn(today).moneyIn` (after M3: `netSpent`), and `today.daysUntil(month.end) + 1`. The division must live in `domain/budget/` (no money arithmetic in screens, F-008 AC-19). `Paise` has no division, and `spreadOver` rejects negatives. **N2:** F-017's plan adds `safeToSpendPerDay(MonthResult)` with its own tests: floor division, the "Nothing left" case at ≤ ₹0, and the "less than ₹1" case |
| **F-014 per-period results** | **Yes.** `PeriodResult` has: start, end, days, superseded, the values in force (`period.values`), `changes` (derived `diff`, D-048 (7)), `amountToSpread`, `budgets`, `shortfall`, `zeroSpendable`, `spent` (net) and `moneyIn`, `saved`, `overspent`, `covered`. Superseded same-day changes are kept with `changedAt` for the "What changed" list. The F-014 check line (Budget − Net spent = Saved − Overspent − Covered) holds for every ended period |
| **Calendar day status (F-011 / F-012 / F-013)** | **Yes.** `DayStatus` has `notBudgeted / upcoming / live / saved / onBudget / overspent`. `covered > 0` marks "covered" and "partly covered". The live day's fill comes from the sign of `result`. Period starts give the "budget changed" marker |
| Current period for Home (salary, fixed costs, the D-043 "₹0 left" panel) | Totals carry the current salary, target, fixed costs and shortfall, but **not** the zero-spendable flag. **N1:** expose `MonthResult.currentPeriod`. The engine already computes it in `_currentPlan` |

### Decision on F-010 Q-1: does Overspent include today's live overspend? **Yes** (D-060)
The engine already counts it (`_Sums`: `i <= todayIndex`), and TC-006-18 pins it: with S1, today 6 Nov and ₹200 spent today, `totals.overspent = 20000`. I keep this behaviour because:
1. F-006 §2.5 says "every budgeted day **up to today**", and Spent so far and Left already include today.
2. D-048 (2) lets the user cover today. If Overspent left out today, covering today would lower the pot while Overspent stayed the same until midnight, which looks like a bug.
3. An overspend is money already gone. A saving today can still be spent, so it is not final, and D-039 keeps it out of the pot. The asymmetry is deliberate: the app never makes the user look better off than they are (in the spirit of D-038).

What follows from it:
- F-010 AC-6 stays at ₹350.
- **F-014 §2.3** ("Saved and Overspent count **ended** days only") must say: Saved counts ended days; Overspent counts days up to today, so a current period includes today's live overspend. The check line is asserted on ended periods only, as F-014 already says.
- Period totals behave the same way as month totals.
- F-013's day counts use statuses of ended days, so they are unaffected.

This goes to the Product Manager as T-225, together with an F-014 example error I found: `Spent ₹9,000` + `Refunds ₹500` · `Net spent ₹9,500` should be net ₹8,500, or gross ₹10,000.

### Must fix
**M1 (T-201): the TC-006-30 guard must ignore directive lines and comments.** The pattern `[^~/]/[^/=*]` matches every `import 'package:daily_budget/domain/…'` line (I confirmed this). It also matches words like "and/or" in a `//` comment. So any engine file that imports something fails the guard. That includes the early F-008/F-009 files and any file after M2.
- *Why:* a guard that blocks ordinary imports pushes code into odd shapes (E1). The fix belongs in the guard, not the code.
- *How:* in `domain_layering_test.dart`, before matching `_floatPatterns`, drop lines matching `^\s*(import|export|part|library)\b` and cut everything from `//` to the end of the line. Better still, strip string literals too. Add self-proofs: `import 'package:daily_budget/domain/budget/paise.dart';` and `// spends and/or refunds` give **no** match, while `final c = a / b; // x` still matches. Apply the same exclusion to the Tester's manual TC-006-30 command (T-224).

**M2 (T-201, touches all 12 files): one library per file, with `budget.dart` as an export barrel.** E1 is **not** accepted as the long-term style:
- *Why:*
  - Its only reason was the M1 bug.
  - Parts share one private scope, so every `_` helper (for example the mutable `_Effective.amount`, `_EntryKey` and `PeriodValues._sumOf`) can be reached from all 12 files and from every later file that joins the library.
  - dart.dev recommends small libraries over `part` outside generated code.
  - The library would keep growing: T-212a, T-214a and T-217 would have to join as parts.
- *Cost:* I checked that no private name is used across files today, so the change is mechanical.
- *How:*
  - Each file imports what it uses with `package:daily_budget/domain/budget/<file>.dart` (`always_use_package_imports`).
  - `budget.dart` becomes `library;` plus one `export` per file, so callers still import `budget.dart` only and no test changes its imports.
  - `domain_coverage.ps1` already accepts an export-only file. Re-run `check.ps1`, `domain_coverage.ps1` and `tz_matrix.ps1`.
  - The early F-008/F-009 files follow the same pattern: their own library, exported from `budget.dart`.
  - Recorded as **D-059**.

**M3 (T-204): one meaning for "spent".**
- *The problem:*
  - `DayResult.spent` is **gross** spends, with money in separate.
  - `PeriodResult.spent` and `MonthTotals.spentSoFar` are **net** of money in.
  - F-011 cells, F-012 and F-013 show the day's **net** spend, and D-058 needs today's **net** spend. A caller reading `day.spent` would show the wrong figure as soon as refunds exist (D-054 brings manual refunds in Phase 3).
- *Why now:* T-217 (`TodayLine`) and later F-010/F-011 bind to these names. Renaming is a 10-minute change today and a multi-feature change later.
- *How:*
  - Rename `PeriodResult.spent` to `netSpent`.
  - Add a net figure for the day, either a `netSpent` field in `DayResult` (= `spent − moneyIn`) or an extension getter in `month_result.dart`.
  - Keep `DayResult.spent` as gross spends, with a doc comment saying so.
  - `MonthTotals.spentSoFar` keeps its name (the spec's term); its doc comment already says "net".
  - Update `dump()` and the affected tests. No expected value changes.

### Nice to have (follow-up task T-226, Developer)
- **N1:** `MonthResult.currentPeriod` (the `PeriodResult` in force today: the first period before the month, the last after it), from the existing `_currentPlan`. Home needs it for the D-043 panel and the current values.
- **N2:** (F-017 plan, Phase 3, recorded here so it is not lost) `safeToSpendPerDay` in `domain/budget/` as described above.
- **N3:** reject duplicate cover ids with `ArgumentError`, or key `amountOf` by input index.
  - *Why:* two identical `const Cover(...)` values are one object, so the identity map gives both entries the second amount.
  - Also make `MonthResult.dayOn` throw `ArgumentError` for a date outside the month, instead of a `RangeError` or a wrong day.
- **N4:** `engine_time_zone_test.dart` expects `p(2190000 - 5 * 83000)`. Write the literal `p(1775000)` (tests/F-006 §0: expected values are literals copied from the spec).

### Deviations E1–E11 (plan §11), decided
| # | Decision |
|---|---|
| E1 | **Not accepted.** Fix the guard (M1) and return to separate libraries with an export barrel (M2, D-059) |
| E2 | Accepted. Free `==` and zero cost, and the F-007 converter is the identity. Use `.iso` for text (`toString()` is the day number) |
| E3 | Accepted. Records give structural equality without `meta`. Note that a record holding a `List` compares that list by identity, which is why whole-output equality goes through `dump()`. That is the right approach |
| E4 | Accepted. One source for the salary day. `monthStateFor` is covered inside TC-006-03/-56 |
| E5 | Accepted. Add `<`, `<=` and `>=` back with a test when someone needs them |
| E6 | Accepted, (a)–(h). Each keeps "never silently fix" and "a reduced cover stays reduced" |
| E7 | Accepted. The script counts `DA`/`BRDA` itself. The Tester's command is replaced (T-224) |
| E8 | Accepted. The sentinel plus the hash comparison is stronger than the plan asked for |
| E9 | Accepted. The scripts join `check.ps1` in T-206 |
| E10 | Accepted. The Tester adds the file names (T-224) |
| E11 | Accepted. T-221 stays open. Moving `dump()` into `lib/` is a good start for it |

### For the Tester (T-224, after the M1–M3 re-review)
1. **TC-006-31 command** (E7): Flutter 3.47.9 writes no `BRF`/`BRH`, so count the per-branch lines:
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
   Expected: every engine file shows equal numbers, and B > 0 for files with branches. `budget.dart` (exports only) does not appear. (I ran this on 2026-11-11 and it matches the script.)
2. **TC-006-30 command:** after M2, add `| Where-Object { $_.Line -notmatch '^\s*(import|export|part|library)\b' }` before the end of the pipe. Still expect no output.
3. Add the test file names from plan §11 E10 to the "Automated test" column.
4. **TC-006-18 / AC-13 note:** Overspent includes today's live overspend (D-060). TC-006-18 already asserts it (₹200 on 6 Nov while today is live). Say so in its Expected column.
5. Run Step 8 for T-201 … T-205 after the re-review: `check.ps1`, `domain_coverage.ps1`, `tz_matrix.ps1` and the independent TC-006-27/-28/-30/-31 commands.

### Early-start tasks (D-052)
**T-212a, T-214a and T-217 may begin as soon as the Developer reports M1–M3 done.** They do not need to wait for my re-review or the Tester. They must not run in parallel with the rework, for three reasons:
- They would fail the current TC-006-30 guard as soon as they import anything (M1).
- They must be built as their own libraries, exported from `budget.dart` (M2, D-059).
- T-214a and T-217 read `DayResult` and `PeriodResult` and must use the M3 names.

They stay new files in `lib/domain/budget/` (plus `budget.dart`'s export list) and `test/domain/budget/` only.

---

## Re-review T-201, T-204, T-226 and early-start T-212a, T-214a, T-217 (2026-11-11)

**Verdict: Approved. No Must fix.** Every task in this batch goes to Ready for test. The M1, M2 and M3 fixes are in and do what the first review asked. The three early-start tasks follow D-059 and the M3 names.

| Task | Verdict | Status |
|---|---|---|
| T-201 `CalendarDate`, `BudgetMonth`, layering guard (M1, M2) | Approved | Ready for test |
| T-204 `computeMonth`, `checkCover`, totals (M3) | Approved | Ready for test |
| T-226 hardening N1, N3, N4 | Approved | Ready for test |
| T-212a `parseAmount`, `AmountParse` | Approved | Ready for test |
| T-214a `SetupDraft` | Approved | Ready for test |
| T-217 `TodayLine`, `groupSpendsByDay`, `SpendDraft` | Approved | Ready for test |
| T-202, T-203, T-205 | Notes confirmed, approval stands | Ready for test |

### What I ran (2026-11-11, Flutter 3.47.9)
| Command | Result |
|---|---|
| `tool/check.ps1` | **ALL CHECKS PASSED**, exit 0: format, `flutter analyze`, `dart analyze --fatal-infos`, test-name check on 62 files, 328 tests (full tree, including Phase 1 work in progress) |
| `tool/domain_coverage.ps1` | **100% lines and branches** in all 17 files of `lib/domain/budget/` (engine 210/210 and 70/70, `setup_draft` 198/198 and 95/95, `amount_input` 42/42 and 26/26, `spend_draft` 45/45 and 23/23, `spend_groups` 25/25 and 10/10, `today_line` 15/15 and 8/8). `budget.dart` has directives only |
| `tool/tz_matrix.ps1` | **PASSED** in UTC, PST8PDT and IST. All three dumps have the same SHA-256 (`B3099698…D59E4`; the hash differs from the first review because `dump()` now prints `netSpent`) |
| My own read of the code | No `part` / `part of` in `lib/domain/`. No `double`, no rounding, no `DateTime.now`. No money arithmetic outside `domain/budget/` |

### M1, M2, M3: verified
| # | Check | Result |
|---|---|---|
| **M1** | `domain_layering_test.dart` `codeOnly` drops `import`/`export`/`part`/`library` lines, blanks string literals and cuts `//` comments before matching | **Fixed.** Self-proofs: an import line, an export line, `// spends and/or refunds` and `'a / b'` give no match; `a / b; // x` and all 8 bad lines still match. The guard now scans all 17 files, imports included |
| **M2** | Each file in `lib/domain/budget/` is its own library with `package:` imports. `budget.dart` is `library;` plus 16 `export` lines | **Fixed.** No `part`. Callers and every test still import `budget.dart` only. Coverage and TZ results are unchanged, so no behaviour moved. D-059 holds for the three new files too |
| **M3** | `DayResult.spent` (gross, now documented) plus a new `DayResult.netSpent` = `spent - moneyIn`. `PeriodResult.spent` is now `netSpent`. `MonthTotals.spentSoFar` unchanged | **Fixed.** `netSpent` is the figure screens show (D-047, D-058). `TodayLine` and `groupSpendsByDay` use it. No expected money value changed |

### T-226 Nice to have: verified
- **N1** `MonthResult.currentPeriod` and `currentPeriodIndex`: first period before the month, last effective one after it, never a superseded one. TC-006-21 and TC-006-43 prove it, and the D-043 zero-spendable flag is reachable from it. Phase 3's Home can use it.
- **N3** duplicate cover ids and a `dayOn` date outside the month throw `ArgumentError`; TC-006-56 covers both.
- **N4** literal `p(1775000)`.
- N2 (`safeToSpendPerDay`, D-058) stays in the F-017 plan, as agreed.

### T-212a, T-214a, T-217: review against the plan and feature docs
| Check | Result |
|---|---|
| **Correct** | `parseAmount` is integer-only: Indian and Western grouping, `.5`, `40000.`, at most 2 decimals, `₹` and spaces skipped, and a text with more than 12 whole digits is never turned into an `int`. `SetupDraft` validates in screen order, keeps both value sets when the salary day changes the kind (D-034), pre-fills a new month from the last period (full: everything; mid-month start: items still to pay, F-008 §2.6), and its preview goes through the engine's `planPeriod`, so no money arithmetic lives in a screen (F-008 AC-19). `TodayLine` follows D-039 (today is not in the pot until midnight), D-047 (net spend) and D-050/D-055 (the word follows the exact paise). `groupSpendsByDay` is newest day first, then newest added, ties by id (D-048). `spendDateLimits` covers a future-dated edit (D-048) and never goes past the month end |
| **Clean** | Immutable drafts, sealed result types with exhaustive `switch`, records for `DayGroup`, `SpendFields`, `SpendError`. Small files, one job each. No dead code. The only `dart:convert` use is a signature string for "changed?", which is pure Dart and allowed |
| **Modern** | Dart 3.13 `const new`, extension types, patterns with `when`, `.indexed`, sealed classes. Nothing deprecated |
| **Tested** | Test names carry TC IDs (the check passes on all 62 files). TC lists are in the task rows. The worked example in TC-009-10 is checked to the paisa against the engine. 100% coverage per file |
| **UX** | No UI yet. The pure layer hands the screens everything they need: problem enums for the §5 error texts, `PreviewReady` figures, `TodayResultKind` for the Today word |
| **Safe** | No I/O, no logging, no clock. Nothing is silently fixed: `toPeriodValues`, `toFields` and `addItem` throw `StateError` on bad use |

### Plan §11 deviations, decided
| # | Decision |
|---|---|
| **S1** `AmountParse` variants prefixed `Amount…` | **Approved.** One barrel exports everything, so `Empty` and `Value` would be too generic |
| **S2** extra variant `AmountTooLarge` (more than 12 whole-rupee digits) | **Approved.** It is how "never turn a huge text into an `int`" is made true. It maps to the same §5 text ("more than ₹10 crore"), so the screen needs no extra copy |
| S3 `.5` and `40000.` accepted; commas only as Indian or Western grouping | Approved (TC-008-32 allows both). Devanagari digits are rejected as bad format, which is right for a number field with a number keypad |
| **S4** `preview({today, earlierBudgets})` has no `month` parameter | **Approved.** The month always follows from the salary day and today, so a screen cannot pass a month that disagrees. **Condition for T-214b/T-215:** an edit passes the engine's budgets of the budgeted days before today (never the not-budgeted days), and the controller and the preview use the same `todayProvider` value (F-008 edge case "midnight passes") |
| **S5** no character counting of item names (40) in the draft | **Approved, with a condition.** Pure Dart cannot count graphemes without `package:characters`, and a code-point count would wrongly reject valid Hindi or emoji names. The limit is a **field** rule, so **T-215 must own TC-008-34's 41st-character case as a widget test, using `maxLength` with Flutter's default grapheme counting, and include a Hindi or emoji name.** Added to the T-215 row |
| S6 problems are `FieldId` + `FieldProblem` + item key; a bad or empty item amount counts as ₹0 in the preview and in Total | Approved. No strings in `domain/` |
| S7 constructors `firstSetup`, `lateStart`, `newMonth`, `forEdit`; `isChangedFrom` compares normalised values | Approved. `10000.00` equals `10000`, an empty item amount equals `0` (TC-008-55 and the Save-disabled rule) |
| S8 `toPeriodValues`, `addItem`, `insertItem` throw `StateError` | Approved (never silently fix) |
| S9 edit-mode money-left meaning passes earlier budgets to `planPeriod` | Approved (D-048 (5), matches F-006) |
| **G1** `TodayLine.from(result)` uses `result.today` and throws when today is not budgeted | **Approved.** One "today", so the line and the result cannot disagree. The tab shows the new-month card in that case, so T-218 must check the month state first |
| **G2** five `TodayResultKind`s plus `budget`, `netSpent`, `result`, `amount`, `shortfall`, `hasShortfall` | **Approved.** One exhaustive `switch` in the widget. D-055 changed the words to `less than ₹1`; the enum names are internal and the screen copy follows D-055, not the old "under ₹1" |
| G3 `groupSpendsByDay` returns records; the total is net | Approved (D-047) |
| **G4** `SpendDraft.toFields` returns `(amount, date, note)` instead of a `Spend` | **Approved.** The engine's `Spend` has no note, and the id and times belong to the repository (T-209) |
| G5 `spendDateLimits` | Approved (AC-4, TC-009-30, -38) |
| **G6** no note character counting (100) | **Approved, same condition as S5:** **T-219 must own TC-009-08's 101st-character case, with the Hindi and emoji strings, as a widget test.** Added to the T-219 row |

### Confirmed notes: T-202, T-203, T-205
The Developer's "M2 re-header applied, no code change" notes are correct: I compared the file heads (own library, `package:` imports) and re-ran coverage and the TZ matrix. The scripts were not touched. Approval stands.

### Nice to have (none blocks; no task unless the Developer wants one)
- **N5:** the TC-006-30 guard handles `//` comments but not the middle lines of a `/* … */` block. No file uses block comments today. Add one self-proof line if that ever changes.
- **N6:** `groupSpendsByDay` breaks ties by id. When F-007 fixes the id type (T-209), check that the tie-break still means "newest added".

### For the Tester
- **T-224 item 5 can start now:** Step 8 for T-201 … T-205 and T-226: `check.ps1`, `domain_coverage.ps1`, `tz_matrix.ps1` and the independent TC-006-27/-28/-30/-31 commands. Any record of the dump hash must use the new value (it changed with `netSpent`).
- **New:** Step 8 for the pure halves of F-008 and F-009 (T-212a, T-214a, T-217): test files and TC lists are in the task rows. Record the file names in `tests/F-008-month-setup.md` and `tests/F-009-manual-transactions.md`. The widget halves of the same IDs stay open for T-215, T-218 and T-219.
- TC-008-34 and TC-009-08: mark the 41st and 101st character cases as widget tests (T-215, T-219), not domain tests.

## T-212b, T-212c, T-213 first half (Developer B), Gate 3 (2026-11-13)

**Verdict: Approved. No Must fix.** T-212b and T-212c go to **Ready for test**. T-213 first half (`clockProvider`, `todayProvider`) is approved and goes to Ready for test; the task stays In progress until `currentMonthStateProvider` is built (needs T-209).

**How I reviewed:** by reading files only (Developer A was running Flutter builds on the same database, so I did not run `flutter`, `dart` or `tool/check.ps1`). Read: `core/format/*`, `core/widgets/{amount_field,decision_sheet,action_dock,empty_state,budget_text_field}.dart`, `core/providers/today_provider.dart`, `test/architecture/money_format_only_test.dart`, the test names in `test/core/{format,widgets,providers}`. The Developer reports 406 tests passing and clean format and analyze for B's files; the Tester's Step 8 re-runs them. **I did not verify the green run myself.**

| Check | Result |
|---|---|
| **Correct** | `formatRupees` is integer-only: `abs ~/ 100` (toward zero), last three digits then pairs, U+2212 plus U+2060 for a negative, no sign when the whole rupees are 0 (D-050), a separate speech form with no invisible characters. Weekday is `(dayNumber + 3) % 7` (day 0 was a Thursday); Dart `%` is never negative, so dates before 1970 work, and TC-008-29 tests leap years and pre-1970. `todayProvider` reads the clock once, refreshes on resume and at the next local midnight, re-arms the timer each time (including after an early fire or a date set back) and cancels on dispose. |
| **Clean** | Small files, one job each. Sealed/record-free simple code, no dead code, doc comments explain why. `AmountField` is a thin wrapper over `BudgetTextField`, which is what the plan asked for (one place for the money style). |
| **Modern** | Dart 3.13 `const new`, named `const new primary`, null-aware element `?action`, `.indexed`, switch expressions, `AppLifecycleListener`, `NotifierProvider`. Nothing deprecated seen. |
| **Tested** | Tests carry TC IDs; the architecture guard skips `import`, `export` and comment lines and has one probe per pattern. |
| **UX** | Decision sheet: the safe choice is returned for scrim, swipe and back, the buttons scroll on their own only above 60 % of the sheet (2.0 text), a double tap is ignored. Dock: the line stays and Confirm hides while the keyboard is open, inline form above text 1.3 and in landscape. The (i) stays its own item beside the label. Errors use icon plus text plus outline, announced as a live region. |
| **Safe** | No logging, no I/O, clock only through `clockProvider`. |

### Deviations T1 to T7, decided
| # | Decision |
|---|---|
| **T1** no `intl` in formatting | **Approved (D-070).** The result matches `NumberFormat.decimalPattern('en_IN')` on whole rupees, there is no locale start-up, and TC-008-30 stays trivially true. `intl` is now unused (no `package:intl` import in `app/lib` or `app/test`), and STANDARDS section 2 asks for a reason for every package, so **remove `intl` from the pubspec**. I did not edit the pubspec (Developer A owns it): the instruction is a note on the **T-206** row. Also update D-067, the T-206 row text and TC-001-24/-25 if they list `intl`. Plan F-008 sections 1.4 and 4 and plan F-009 section 4 still say `intl`; Developer to correct. Design system 4.3 names `NumberFormat.decimalPattern`; Designer to correct (T-238). |
| **T2** no digit grouping while typing | **Approved: keep the text as typed and change the spec (D-069).** UX: a field that rewrites the digits on every key must move the cursor, and Indian grouping (3 then 2s) makes deleting or inserting in the middle jump, plus a decimal part and pasted text; TalkBack re-reads the field after each rewrite, which hurts the accessibility goal (TC-008-26 reads `edit box, 40000`). The user still sees the grouped amount at once in the preview line under the form (`₹40,000 - ...`). `parseAmount` accepts Indian and Western commas, so paste works. Effort: change two spec lines, versus four approved cases (TC-008-19, -26, -31, -32), a formatter and cursor tests. **This is a design change**: recorded, shown to the Owner, kept for their feedback at phase end; if they want grouping it is one `TextInputFormatter` in `AmountField` plus Tester edits. Task **T-238** (Designer) updates design system 7.3 and 4.3, month-setup 4.2 and the mockup field. |
| **T3** decision sheet API (`paragraphs`, required `dismissValue`, `DecisionOption` variants) | Approved. The caller cannot forget the safe dismiss choice (design system 7.8). |
| **T4** `ActionDock({line, action})` and `ActionDock.fits` | Approved. Matches 7.13; the screen decides dock or inline. |
| **T5** `EmptyState` action as wide as the text, at most 320 dp | Approved. Identical on a 360 dp phone. |
| **T6** `BudgetTextField` gained `info`, `large`, `textInputAction`, `onSubmitted`; `LabelDescription` used for the label block | Approved. Phase 1 tests still pass unchanged (Developer's report; the Tester's regression confirms). |
| **T7** `todayProvider` tests dispose the container inside the test | Approved. A pending timer would fail a finished test. |

### Must fix
None.

### Nice to have
- **N1 (Developer, no task):** correct the `intl` mentions in plan F-008 sections 1.4 and 4 and plan F-009 section 4 with the other T-206 doc edits.
- **N2 (Developer, when T-214b/T-215 are built):** the dock's summary line is decorative for screen readers, so the month-setup preview text must be reachable as its own readable item (already stated in the `ActionDock` doc comment; check it in the T-215 TalkBack case TC-008-26).

### For the Tester
- **T-239:** the manual TC-008-30 command must skip `import`, `export` and comment lines (`//`, `///`), like the automated guard; otherwise `[^~/]/[^/=*]` matches the `package:` imports. Record the new test files and run Step 8 for T-212b, T-212c and T-213 first half. TC-008-19, -26, -31, -32 stay as approved (text unchanged while typing).

### For the Owner (soft, not blocking)
Amount fields will show the digits as you type them (`40000`), and the grouped amount (`₹40,000`) shows right below in the summary line. The design had said the field itself would group the digits as you type. I chose the simpler, steadier field (no jumping cursor, cleaner for TalkBack). Say so at phase-end feedback if you want grouping in the field itself.


## F-007 Local database, T-206 to T-211 (Developer A), Gate 3 (2026-11-13)

**Verdict: Approved. No Must fix.** T-206, T-207, T-208, T-209, T-210 and T-211 go to **Ready for test**.

**How I reviewed:** by reading files only (two Developers were running Flutter builds, so I did not run `flutter`, `dart` or `tool/check.ps1`). Read: `data/database/{app_database,tables,triggers.drift,converters,database_connection}.dart`, `data/repositories/{storage_exception,cover_reconciliation,drift_month_repository,drift_transaction_repository}.dart`, `core/providers/database_providers.dart`, `core/logging/app_logging.dart`, `features/storage_error/{database_gate,storage_error_screen}.dart`, `pubspec.yaml`, `build.yaml`, manifest, both `res/xml` files, `integration_test/persistence_test.dart`, the `TC-007-*` names in `app/test`, the `check.ps1` codegen step. **I did not verify the reported green run (452 tests, check.ps1 ALL CHECKS PASSED, emulator 2/2); the Tester's Step 8 re-runs it.**

### Gate 1 conditions (plan section 10) and standards
| Condition | Result |
|---|---|
| D-045 device transfer included, cloud off | `allowBackup="false"`; `data_extraction_rules.xml` excludes every domain in `<cloud-backup>` and includes `database` and `sharedpref` in `<device-transfer>`; `backup_rules.xml` excludes everything for API 30 and lower. Pass. |
| Android doc source recorded (PM condition 1) | Not fetched by A. **I fetched the Android "Auto Backup for Apps" page myself (2026-11-13).** It confirms `dataExtractionRules` for API 31+, `fullBackupContent` for 30 and lower, separate `<cloud-backup>` and `<device-transfer>` sections, and that with `allowBackup="false"` on API 31+ some manufacturers still do device-to-device transfer. Matches the plan. Condition met. |
| D-047 `direction` column, D-048 covers stored with the edit | Schema has `direction` with CHECK; `reconcileCovers` is one shared function for Drift and fakes, run in the same transaction as each spend write. Pass. |
| Append-only in the database | 4 triggers (update and delete on `budget_periods`, `period_fixed_costs`), `RAISE(ABORT)`. Pass. |
| Money paise, dates day numbers | `PaiseConverter`, `CalendarDateConverter`; no `dateTime()` or `real` column. Pass. |
| Open guard, bytes unchanged | `setup` callback reads `PRAGMA user_version` only and throws `DatabaseTooNewException` before Drift migrates; `onUpgrade` throws if `from > to` and for any unwritten step. The file is never deleted or recreated. Pass. |
| Failures typed, no data in errors | `StorageException` carries only the kind; the provider logs only `kind.name`; `listenToLogs` prints level, logger and message, never the error or stack. Pass. |
| Layers | UI goes through repository interfaces and providers; `repositories_only_test` guards `features/` and `domain/`. Pass. |
| One transaction per write | `add`, `update`, `delete`, `confirmMonth`, `addPeriod` all run in `_db.transaction`. Pass. |
| Modern idioms | Dart 3 records, switch expressions, `const new`, `.indexed`, Riverpod `retry: _noRetry` so a read failure goes to the error state. Pass. |

### Privacy and Owner-escalation list
- **Permissions:** none added. The main manifest has no `uses-permission`; debug and profile manifests carry only Flutter's standard INTERNET (not in release). No network code in `lib/data`.
- **Nothing leaves the phone:** cloud backup excluded for all domains. Phone-to-phone transfer is the Owner's decision D-045/D-049, built as decided. No new escalation item is triggered by the code.
- **Packages:** `intl` is removed (D-070). `sqlite3` is now a direct dependency (the plan said transitive): `database_connection.dart` imports `package:sqlite3/common.dart`, so the `depend_on_referenced_packages` lint needs it. Same package, no cost, no encryption package. Accepted.
- **Money display/calculation:** no change.
- D-067, D-068, D-070 are followed (versions match D-067; `check.ps1` has the codegen, coverage and TZ steps; `intl` gone).

### Deviations and gaps A listed, decided
| Item | Decision |
|---|---|
| Interface names differ from plan section 2 (`watchLatestMonth`, `watchMonth`, shared `FakeMoneyStore`) | **Approved.** Simpler than the plan; T-214b uses the real names. |
| Logging hook in `core/logging/app_logging.dart`, not `main.dart` | **Approved** (small and testable). |
| `sqlite3` upgrade command needs `hooks meta record_use` | **Approved**, recorded in D-067. |
| **TC-007-33 debug delay hook not built** (PM Nice to have 9) | **Approved, not built.** The all-or-nothing guarantee is proved by TC-007-09/-10 (test-only SQLite trigger aborts the 3rd cost insert) and SQLite's journal; app code stays free of test hooks. The Tester runs TC-007-33 as a best-effort manual kill during a save of a large month, or records "not repeatable, covered by -09/-10". |
| **Manual-only cases** TC-007-02, -17, -20, -23, -25, -33, -36, -37, -38, -41, -48 | **Approved as manual/device cases for the Tester (Step 8).** -25 and -38 are run by `check.ps1`; -23 is the lock-file check plus a debug build; -17 and -41 need the emulator with a damaged or newer file; -20 and -48 are the backup and device-transfer checks; -02, -33, -36, -37 are restart, kill, clear data and time-zone steps (-37 also has the automated 3-zone `database_time_zone_test`). |
| **Backup docs not re-fetched** | **Done by me (see above).** Line added to plan section 11. |

### Nice to have (none blocks)
- **N1 (Developer, with the next edit of `database_providers.dart`, T-214b):** the doc comment "UTC milliseconds since 1970 from the app clock ... for `created_at`..." sits above `_noRetry`, and the `_noRetry` text (read failures) sits where `nowMillisProvider` should be documented: the two comments are swapped. `nowMillisProvider` has no user yet; T-215/T-219 need it for the repositories' `now:`, so keep it, but if they do not use it, remove it (dead-code rule).
- **N2 (Tester for TC-007-20/-48; Owner awareness):** the Android page says that when a section is missing from `data-extraction-rules`, that mode is fully enabled, and it lists a third section `<cross-platform-transfer platform="ios">` (Android 16 QPR2, move to an iPhone). Our file has no such section, so on those Android versions the data might be offered for a user-started move to iOS. It is phone-to-phone like D-045, never to a server, and only on the newest Android. Adding the section needs iOS bundle and team ids we do not have. The Tester notes what an Android 16 QPR2 image does; the Owner is told below.
- **N3 (Developer, with T-222):** `knownSchemaVersion` is separate from `schemaVersion`; a test checks they match. Keep that test when the first v2 migration lands.

### For the Tester
- Step 8 for T-206 to T-211: `check.ps1`, the emulator integration test and the manual cases above; record results in `tests/F-007-local-database.md`.
- TC-007-23: confirm in `pubspec.lock` that `sqlite3_flutter_libs` and `sqlcipher_flutter_libs` are only the `+eol` stubs and not direct dependencies.
- TC-007-20/-48: on an Android 12+ emulator confirm no cloud backup is produced for the app (`adb shell dumpsys backup`) and that device transfer includes the database; note the Android 16 QPR2 behaviour if an image is available.

### For the Owner
Nothing needs a decision now. One awareness item (N2): Android 16's newest phone-to-iPhone transfer is not covered by the backup rules written for Android-to-Android moves. Data would move only if you start a transfer yourself, and never to a server. Tell the team if you want it blocked; it needs a small extra setting.


## Gate 3: F-008 and F-009 screens, T-213 (second half), T-214b, T-215, T-216, T-218, T-219, T-220, T-240 (2026-11-13)

**Verdict: Approved for T-213, T-214b, T-215, T-216, T-218, T-220 and T-240. T-219 has two small Must fix points (M1, M2).** Developer B's F-008 work and Developer C's Transactions tab and 500-spend test are sound. Only the spend editor goes back.

| Task | Verdict | Status |
|---|---|---|
| T-213 second half (`currentMonthStateProvider`, `AppMonthState`) | Approved | Ready for test |
| T-214b `MonthSetupController` | Approved (S4 met) | Ready for test |
| T-215 setup screen | Approved (S5 met; U3, U5 approved as design changes) | Ready for test |
| T-216 Home wiring | Approved | Ready for test |
| T-218 Transactions tab | Approved (G1 respected) | Ready for test |
| **T-219 spend editor** | **Must fix M1, M2** (G6 met) | **In progress** |
| T-220 500-spend integration test | Approved | Ready for test |
| T-240 launcher wiring | Approved | Ready for test |

**How I reviewed:** by reading files only (the Orchestrator was running `tool/check.ps1`; I did not run `flutter`, `dart` or the script). Read: `core/providers/month_state_provider.dart`, `features/month_setup/{month_setup_controller,month_setup_screen}.dart` and `widgets/{setup_preview_card,setup_action_dock,shortfall_sheet,discard_sheet,salary_day_field}`, `fixed_costs_section` (the remove button and name field), `features/home/{home_tab,this_month_card}.dart`, `features/transactions/*` (tab, state, list, Today view, editor, flow, launcher, add button, sheets, note field), `features/shell/{app_shell,tab_page}.dart`, `core/help/nav_tooltip.dart`, `core/widgets/budget_icon_button.dart`, the date-picker part of `budget_theme.dart`, the copy files, the tests named for S5 and G6, `help_rule_test.dart`, `shared_components_test.dart`, `money_format_only_test.dart`. **I did not verify the reported green runs (588 tests, the emulator timings of the 500-spend test); the Tester's Step 8 re-runs them.**

### Gate 3 conditions
| Condition | Result |
|---|---|
| **S4** edit passes the engine's budgets of the budgeted days before today; controller and preview share one `todayProvider` value | **Met.** `_earlierBudgets` takes the `computeMonth` days whose status is not `notBudgeted` and whose date is before today. `setupPreviewProvider`, `previewFor` and `submit` all read `todayProvider`, and `submit` re-reads it (D-048). The preview is `PreviewNeedsAmount` when today is outside the edited month |
| **S5** TC-008-34's 41st-character case is a widget test with grapheme counting and a Hindi or emoji name | **Met.** `month_setup_screen_test.dart` TC-008-34 types 40, then 41, of `a`, `कि`, an emoji and a ZWJ family: the 41st is dropped. The field uses `maxLength: maxItemNameLength` with `MaxLengthEnforcement.enforced` |
| **G1** month state is checked before `TodayLine.from` | **Met.** `transactionsViewProvider` builds `TodayLine.from(result)` only when today is on or after the first budgeted day and inside the month; otherwise `line` is null (no Today card, no Add spend, rows read-only) |
| **G6** TC-009-08's 101st-character case is a widget test with Hindi and emoji | **Met.** `spend_editor_screen_test.dart` types 101 letters, `चा` and a family emoji; 100 are kept and the counter reads `100/100`. Hindi and emoji notes are stored equal to what was typed |

### Checklist
| Check | Result |
|---|---|
| **Correct** | State is one sealed `AppMonthState`; a read failure is an `AsyncError` and never "no month" (AC-11). Confirm saves once (`isSaving` plus the screen's `_busy`), keeps the draft on a storage failure, re-reads today, and treats a late or missed-month start as a fresh start (D-057). Shortfall and zero need a choice and nothing is saved until **Continue anyway**; scrim, swipe and back are the safe choice. Editor: `_saving` is set before the first `await`; date limits and the note limit come from the pure layer; a save returns the cover reductions to the tab. Money on screen goes through `formatRupees`, and the Today numbers come from `TodayLine`. One exception: M1 |
| **Clean** | Small widgets, one job each, no dead code, no TODO. Points: M2 (duplicate icon button), N1 to N7 |
| **Modern** | Sealed classes with exhaustive `switch`, records, `const new`, null-aware elements, `.indexed`, `PopScope`, `SliverList.builder`. Nothing deprecated seen |
| **Tested** | TC IDs in the names; 91 new tests for F-008, 42 for F-009 plus the integration test; the sweeps cover 16 states x 5 themes x text 1.0 and 2.0, plus landscape |
| **UX** | Fewer taps than planned (Save in the dock, focus to the first error, Undo for a deleted item). Gap: N7 |
| **Safe** | No new permission. No network code in `features/` (I searched for `http`, `Uri.`, share and permission calls). The only logging in the providers I read is `database_providers.dart`, which logs the failure kind only. No amounts in logs |

### Escalation list (WORKFLOW.md)
- **Money calculation or display:** no change to the rules. Formatting is the Phase 2 `formatRupees` (D-038, D-050, D-055) and the engine does the sums. Not escalated. (The one place a screen does money arithmetic is M1.)
- **Permissions, privacy, data off the phone:** nothing added.
- **Package or paid service:** none.
- **Scope:** unchanged.
- **Design and copy changes** (U3, U5, C7): shown to the Owner, not escalated (below).

### Must fix (T-219 only)
**M1 (T-219): `coverReductionText` does money arithmetic in a screen file.** `features/transactions/widgets/cover_taken_back_sheet.dart` computes `reduction.oldAmount - reduction.newAmount` and compares `cut.value >= 100` and `cut.value < 100` to pick the "less than ₹1" wording.
- *Why:* STANDARDS sections 3 and 4 keep all money logic in `domain/budget/`, where it is unit-tested to 100%, and F-008 AC-19 says screens do no money arithmetic. A literal `100` (paise per rupee) in a widget is exactly what that rule exists to catch, and D-055's "less than ₹1" is a display rule that `TodayLine` already owns in the domain (`leftUnderRupee`). `money_format_only_test.dart` only bans `~/ 100`, so nothing flags this.
- *How:* in `domain/budget/budget_engine.dart` (where `CoverReduction` lives) add `Paise get cut => oldAmount - newAmount;` and `bool get cutIsUnderRupee => cut.value < 100;` (or one small sealed result), with tests in `test/domain/budget/` named for TC-009-25 and TC-009-27 so coverage stays 100%. The screen then only reads `reduction.cut`, `reduction.newAmount.isZero` and `reduction.cutIsUnderRupee`, with the same two texts as today. No expected text changes. Keep the TC-009-25 to -28 widget tests unchanged.

**M2 (T-219): the editor's close button is a hand-made copy of `BudgetIconButton` and has no focus ring.** `spend_editor_screen.dart` lines 247 to 271 build `NavTooltip` + `Semantics` + `InkResponse` + a 48 dp box by hand.
- *Why:* B's `BudgetIconButton` (U6) is the same control and also has the keyboard focus ring (F-004 AC-4, TC-004-04: a focus ring on every focusable control). The copy is duplicate code and a focus gap for keyboard and switch users.
- *How:* replace the block with `BudgetIconButton(icon: Icons.close, tooltip: TransactionsCopy.closeTooltip, hint: TransactionsCopy.closeScreenHint, onPressed: () => Navigator.of(context).maybePop())`. The label (`Close`) and hint (`Leave without saving`) stay as the tests expect. Remove the `NavTooltip` import if nothing else in the file uses it (`FocusRing` stays: the date field uses it).

### Deviations, decided

**F-008, plan section 11 (U1 to U10)**
| # | Decision |
|---|---|
| U1 `AppMonthState` names | Approved. The engine already owns `MonthState`; F-009 uses the new names |
| U2 three modes, kind inside the draft | Approved. D-034 lets the salary day change the kind live |
| **U3** no count-up of the daily amount while typing | **Approved as a design change, with a Designer task (T-241) to bring the spec in line.** AC-7 and TC-008-11 need the new figure in the same pump. A 600 ms count while someone types would show a wrong number for most of that time and would fight the polite live region (which already waits one second). The count-up stays where it belongs: the Today result in Transactions after a save (built and tested). With Remove animations on it would have been instant anyway. The cost is a little polish; nothing is lost in meaning |
| U4 deleted row disappears at once | Approved. Total, preview and Undo are immediate; a collapse is polish, optional later |
| **U5** new copy: `Enter the money you have left to see your daily budget` (preview line) and the dock label `Enter how much you have left` | **Approved as built; T-241 records them in the spec.** The first mirrors the approved `Enter your salary to see your daily budget`; `Enter your salary` above a field called Money left now would be wrong. The second is the approved error text of the same field, so the words match what the field says elsewhere. Plain, same voice. N1 (its own constant for the dock label) is a Nice to have |
| **U6** `BudgetIconButton` | **Approved, fits the help-rule guard.** `shared_components_test.dart` (TC-004-08) bans `Tooltip(` and `IconButton(` in `lib/features/` only, and its own message says "use InfoButton or a core control": this is that core control. It has a 48 dp target, a long-press tooltip, the tooltip text as the screen-reader label, an optional hint and a focus ring. The back arrow has tooltip `Back` plus a hint; the item remove x has tooltip `Remove <name>` (a tooltip meets the rule). `help_rule_test.dart` (TC-004-06) walks the Phase 1 screens only, so it neither sees nor breaks on it. N2: wrap `NavTooltip` instead of a second `Tooltip(`. The widget has no unit test of its own beyond the screen tests and the sweep (tap size, label); the Tester may add one small TC-004-05-style case in Step 8 |
| U7 extra edge cases (edit hidden when the date is outside the month; edit left open past month end; pre-filled month past its start day) | Approved. Each avoids a throw in `planPeriod` or breaks D-057; all tested |
| U8 no month line in the edit preview; `LabelDescription` for the labels | Approved |
| U9 TC-008-24 in the F-008 sweep file | Approved |
| U10 launcher not wired | Resolved by T-240 |

**F-009, plan section 11 (C1 to C8)**
| # | Decision |
|---|---|
| C1 `transactionsViewProvider` with a sealed view | Approved. G1 is respected; the date-set-back case is the safe reading (list shown, nothing can be added) |
| **C2** Add spend lives in the shell, only on Transactions | **Approved, no Phase 1 regression found.** `Scaffold.floatingActionButton` is `AddSpendButton` only when the tab is Transactions, and the button returns `SizedBox.shrink()` when there is no month or nothing can be added, so the Phase 1 Transactions screen (no month) shows only what its F-003 cases expect, plus the new empty state. The Scaffold keeps the button above the bar and lifts it over snackbars, which is why this is better than a button inside the tab. Re-tap to top, Back goes Home, the tab fade and the other three tabs do not touch it. Its semantics are the extended FAB merged with `NavTooltip` (label `Add spend`, hint = tooltip), one node. N7: it shows at once while the page fades in |
| **C3** shared files: `TabPage.slivers`, `NavTooltip(hint:)`, date picker theme | **Approved, additive.** `TabPage`'s default constructor and fields are unchanged, and `slivers` is a second constructor with the same header, hint and bottom space. `NavTooltip.hint` is optional and defaults to the message, so every existing call reads as before. The date picker theme applies to date pickers only (Phase 1 has none) and uses tokens only (`surface`, `accent`, `onAccent`, `textPrimary`, `textSecondary`); disabled days at 50 % `textSecondary` are exempt from the contrast rule. The F-003 cases edited in `empty_tabs_test`, `app_name_test`, `help_rule_test`, `p1_screen_sweeps_test`, `onboarding_routing_test` and `copy_tables_test` follow the intended change of the Transactions body (placeholder to the F-009 empty state, F-009 AC-1); I found no weakened expectation |
| C4 list lazy per day | Approved. 55 rows build at once; the 500-spend run is the proof |
| C5 no editor controller class | Approved. The form state is small and sits on `SpendDraft` |
| C6 launcher default did nothing | Resolved by T-240 |
| C7 new small texts (`Pick a day this month, up to today.`; save-failure snackbar above the dock; hide the last snackbar when an editor opens) | Approved. The date error is only reachable after a clock change while the editor is open. **Owner sees the new line**; T-241 adds it to `transactions.md` |
| C8 Today line wraps between its parts; own note field | Approved. `BudgetTextField` has no length options and B edits it |

### T-240 (Developer D)
`monthSetupLauncherProvider` now takes `(context, SetupMode)`, opens `MonthSetupScreen.open` and ignores a second tap until the screen is closed (TC-008-49). The Transactions tab passes `FirstSetupMode()` for no month and `NewMonthMode(lastMonth)` for the new-month card and the Add spend sheet. Home keeps its own once-per-open guard. **Approved.** Small and correct. N4: the provider sits in `features/transactions/` but belongs to month setup, and Home repeats the guard.

### Nice to have (task T-242, none blocks)
- **N1:** own constant for the dock label (not the error string `moneyLeftMissing`).
- **N2:** `BudgetIconButton` wraps `NavTooltip`.
- **N3:** the `_Busy` notifier in `spend_editor_flow.dart` needs an `ignore: use_setters_to_change_properties`; a plain provider avoids the lint ignore.
- **N4:** move the launcher to `features/month_setup/` and let Home use it.
- **N5:** `_spokenDate` in `this_month_card.dart` splits a formatted string; add a long day-month formatter.
- **N6:** Delete in the editor opens its sheet before setting the busy flag; a double tap inside one frame could open two sheets.
- **N7:** the Add spend button shows at once while the new tab fades in.
- Remark (no task): `setup_preview_card.dart` line 261 has a `.replaceAll` whose two arguments look identical; I take it to be a non-breaking space turned into a normal one for the screen reader. A ` ` escape would make that visible to the next reader.

### For the Tester
1. Step 8 for T-213 (second half), T-214b, T-215, T-216, T-218, T-220 and T-240 once `tool/check.ps1` is green. Record the test file names in the TC rows (they are already named in the task rows).
2. T-219 waits for M1 and M2; after the re-review, run it with the rest of F-009.
3. TC-003-05, TC-003-17 and TC-003-31 need the new Home wording (T-216). The F-003 Transactions placeholder cases changed with F-009 AC-1.
4. Manual: TC-008-26, -27, -38, -50, TC-009-22, -31, -43, -46 (TalkBack, emulator, rotation); TC-009-45 on the device if wanted. Include the setup back arrow and an item remove x in the TalkBack walk (`Back` with its hint, `Remove <name>`) and the one-second polite read of the daily line.
5. Keyboard focus ring check on the setup back arrow, the item remove x and, after M2, the editor close button.

### For the Owner (shown, not escalated)
- **The daily amount does not count up while you type your salary (U3).** The design said the number would roll to its new value over about half a second. It now changes at once, because the preview must be right on every keystroke and a rolling number would show wrong figures while you type. The roll still happens on the Transactions Today line after you save a spend.
- **Three new lines of wording (U5, C7):** for a first setup that starts partway through the month, the preview says `Enter the money you have left to see your daily budget` and the pinned bar says `Enter how much you have left`. The spend editor can say `Pick a day this month, up to today.` if the phone clock moves while you are adding a spend. Tell the team if you want different words.
- Nothing needs a decision: no money rule, permission or data change.

## Gate 3 re-review: T-219 spend editor, Must fix M1 and M2 (2026-11-13)

**Verdict: Approved. No Must fix. T-219 goes to Ready for test.** Both items are fixed as asked. Read-only review; flutter was not run (the Tester has it running).

| Item | What I checked | Result |
|---|---|---|
| **M1** | `month_result.dart` has `extension CoverReductionCut on CoverReduction` with `Paise get cut => oldAmount - newAmount` and `bool get cutIsUnderRupee => cut.value < 100`. `cover_taken_back_sheet.dart` has no subtraction and no literal `100`; it reads `reduction.cut`, `newAmount.isZero` and `cutIsUnderRupee`. Same two texts and same branch logic as before (whole cover and not under ₹1 = taken back; else partly, with `less than ₹1` when under) | **Fixed** |
| **M1 form** | A record typedef cannot hold getters, so an extension on the typedef is the right tool. It sits next to `CoverReduction` in the domain, is exported through `budget.dart`, and uses the Dart 3 extension syntax. Better than turning the record into a class, which would touch the repository and every test that builds the record | **Accepted** |
| **M1 tests** | `savings_pot_test.dart` `_cutTests`: TC-009-25 (whole cover: cut = old; exactly ₹1 is not under ₹1) and TC-009-27 (partial cut 1000 paise; 50 paise under; 99 paise under) | **Can fail:** a cut of `newAmount - oldAmount`, a `<= 100` boundary or a `< 99` boundary each break at least one `expect` (exactly 100 vs 99 paise are both pinned). Good |
| **M2** | `spend_editor_screen.dart` uses `BudgetIconButton(icon: Icons.close, tooltip: closeTooltip, hint: closeScreenHint, onPressed: maybePop)`. Import added; the hand-made `InkResponse` block is gone. `FocusRing` import stays for the date field | **Fixed** |
| **M2 test** | `spend_editor_screen_test.dart` "TC-009-16 the close button shows the focus ring when keyboard focused": asserts no ring in touch mode, then a Tab key switches `highlightMode` to traditional, focuses the button, and asserts exactly one `FocusRingPainter` under the button's Tooltip | **Can fail:** it needs both the ring and the highlight-mode switch, so a button without `FocusRing` (the old hand-made copy) fails the last `expect`, and a ring that always paints fails the touch-mode one. Good |

**ID question (TC-009-16).** That test is not a Discard case, and a second test with the same ID blurs the traceability chain. It deserves its own ID: **TC-009-49** (F-004 AC-4 / TC-004-04 applied to the editor close button). It is a Nice to have, so it does not block approval. Handled as a note in the T-219 row of `TASKS.md`.

### For the Tester
- Step 8 for T-219 with the rest of F-009. Add TC-009-49 to `tests/F-009-manual-transactions.md` (Auto-widget, the test above); add `test/domain/budget/savings_pot_test.dart` to the Automated test cells of TC-009-25 and -27.
- After you add the row, a Developer renames the test to `TC-009-49 ...` (name only).
- Keyboard focus-ring walk (manual) now includes the editor close button, as already listed.

## Gate 3: T-250 keyboard behaviour (month setup, Transactions tip) and T-243 integration tests (2026-11-16)

**Verdict: Approved. No Must fix. T-250 and T-243 go to Ready for test.** Read-only review (the Orchestrator was running `tool/check.ps1`; I did not run flutter, dart or the script). Read: `month_setup_screen.dart`, the key and Next helpers in `widgets/fixed_costs_section.dart`, `core/widgets/{action_dock,amount_field,budget_text_field}.dart`, `transactions_tab.dart`, `month_setup_keyboard_test.dart`, the TC-009-46 tests in `transactions_tab_test.dart`, `integration_test/{real_app,month_setup_flow_test,manual_transactions_flow_test}.dart` and the two emulator logs, against month-setup 6 and 13, design-system 7.13, transactions 3.1 and 12, plans F-008 and F-009 section 11 and STANDARDS.

| Check | Result |
|---|---|
| Dock line directly above the keyboard (month-setup 6, DS 7.13) | **Met.** `bottomNavigationBar` padded by the keyboard inset, `resizeToAvoidBottomInset: !docked`; `ActionDock` drops Confirm while the keyboard is open and keeps the line. Test: dock bottom = 640 minus keyboard (within 0.5 dp), line hit-testable, Confirm absent, for first setup, new month and edit |
| Next on every field, Done on the last | **Met.** `_keyFor` / `_nextFor` share one `_fieldOrder`; Next skips the remove buttons (tested); Done closes the keyboard and Confirm returns (tested, also `Save changes` in edit) |
| Back (system and arrow) closes the keyboard first | **Met.** `_onBack` checks the keyboard inset before the discard logic; the test covers both routes, then shows the next Back asks to discard |
| No dock above 1.3x and in landscape | **Met.** `ActionDock.fits` unchanged; tests at 2.0x and landscape assert no dock and Start my month hit-testable above the keyboard |
| Transactions tip below the Today card above 1.3x (transactions 3.1) | **Met.** Only when a Today line exists and scale is above 1.3; same card and copy, only the position moves. Tests: 2.0x Light and Dim (tip below card, Add spend rectangle does not overlap the card), 1.0x and 1.3x tip above |
| Tests named by TC ID and able to fail | **Yes.** The Developer's probes (Back check removed, default Next traversal, dock not lifted, tip rule off) each failed tests; the assertions I read are tight enough for that |
| STANDARDS | Met: no new strings, logging, permission or money logic; `const new`; no dead code |

### The three judgements
1. **Dock stays the Scaffold `bottomNavigationBar`, lifted by the keyboard inset: Approved.** The designed result (the line sits on the keyboard) is met exactly. The first try, the dock inside the body, let the `Removed X` snackbar cover Start my month (TC-008-35), which is a worse defect. A bottom bar keeps snackbars above the dock. The spec does not say how the dock is built, so no spec is wrong; the Designer gets a one-line note (T-251). Plan section 11 already records the deviation.
2. **Card 404 dp vs "about 300 dp" in `transactions.md` 3.1: the number in the design note is wrong, the rule holds.** The rule (Add spend never covers the Today card at offset 0) is what TC-009-46 asserts with real fonts, and it passes; the button is near 550 dp of 640, the card ends near 404 dp. The figure needs updating: **T-251** (Designer, Nice to have, shown to the Owner, not escalated).
3. **New optional `onEditingComplete` on `AmountField` and `BudgetTextField`: Approved, Phase 1 unaffected.** It defaults to null and goes straight to `TextField.onEditingComplete`; null keeps Flutter's default behaviour (Next by traversal, Done closes). Only month-setup fields pass it (the last field passes null on purpose); no Phase 1 screen does. The full suite in the Tester's `check.ps1` run confirms the Phase 1 widget tests.

### T-243 integration tests
- `month_setup_flow_test.dart`: TC-008-54 (fresh install through onboarding on the real preferences plugin, E2 entered, Home `5 Nov – 4 Dec · ₹830 a day`) and TC-008-18 (new app tree on the same database file; Home line; Edit this month shows 40000, Rent 10000, EMI 5000, Subscriptions 100). Names carry the TC IDs, as Gate 4 asked.
- `manual_transactions_flow_test.dart`: TC-009-45 steps 1 to 5. I checked the sums: 250, 650, 950.50 gives `overspent ₹120` (rounded down, D-038); edit 400 to 270 gives `₹9 left today` (9.50 left); delete 300.50 gives `₹310`; same line after a restart. Waits poll real frames (`pumpUntil`), no fixed sleeps.
- `real_app.dart` is small and shared; no app code changed. Logs show all passing (3 of 3) in `docs/reviews/emulator-phase-2/`; a wrong expected value made each test fail (Developer probe).
- Remark, not blocking: the flow test closes the keyboard with `unfocus()` rather than the Done key (the real emulator keyboard); the Done key itself is covered by the widget test.

### Nice to have
- **N1 (T-251, Designer):** the two spec notes above.
- **N2 (Tester, with T-244):** add `month_setup_keyboard_test.dart` to the Automated cell of TC-008-27 (b), the TC-009-46 widget tests to that row, and the integration files to TC-008-18, -54 and TC-009-45. The T-242 tidy-ups were not done and stay open.

### For the Owner (shown, not escalated)
- With the keyboard open, the line "Daily budget ₹830 a day" now stays above the keyboard while you type. The keyboard key reads Next (Done on the last field) and Back closes the keyboard before leaving the screen. At large text sizes there is still no pinned bar; Start my month is at the end of the page.
- At large text sizes the first-time tip on Transactions moves below the Today card, so Add spend no longer covers it. Nothing needs a decision.
