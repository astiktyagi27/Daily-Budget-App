# Plan — F-014: Month statement

| | |
|---|---|
| **Feature doc** | [`docs/features/F-014-month-statement.md`](../docs/features/F-014-month-statement.md) (final spec, 17 ACs) |
| **Test cases** | [`tests/F-014-month-statement.md`](../tests/F-014-month-statement.md) (Tester, Step 4; the TC IDs in §6 were reconciled to the Tester's file at Gate 1) |
| **Design** | [`docs/design/screens/month-statement.md`](../docs/design/screens/month-statement.md) (draft for Phase 3 Gate 2) |
| **Inputs** | D-036, D-037, D-038, D-042, D-043, D-046 .. D-048, D-050, D-053, D-055, D-059, D-060, D-062, D-070; F-006 AC-21/22 (per-period results), F-007 AC-16 (period history) |
| **Author** | Developer 2 |
| **Status** | Plan approved (Gate 1, 2026-11-16, Project Manager B; D-081) |

## 1. Approach
The statement is a **pure function of the engine result**. `MonthResult` already carries everything the F-014 spec needs: `periods` (each `PeriodResult` with the stored `BudgetPeriod` incl. `values` and `changedAt`, `superseded`, `start`/`end`/`days`, `changes` diff, `amountToSpread`, per-day `budgets`, `shortfall`, `zeroSpendable`, `netSpent`, `moneyIn`, `saved`, `overspent`, `covered`), `firstBudgetedDay`, `today` and `totals`. No new engine output and no money rule (the engine suite and the TZ hash stay unchanged).

1. **`buildStatement(MonthResult) -> MonthStatement`** in `app/lib/domain/budget/month_statement.dart` (pure Dart, D-059 library, exported from `budget.dart`, 100 % branches). It returns typed data, never strings:
   - `header`: month range, `soFarTo` (today, when today is inside the month), `notBudgeted` range (before `firstBudgetedDay`).
   - `totals` (`Money for the month` = `totals.budgeted`, gross `spent` = `spentSoFar + moneyIn`, `refunds`, `netSpent`, `saved`, `covered`, `overspent`, `pot`, `shortfall`, `left`).
   - `changes`: one `StatementChange` per **stored period record**, oldest first (including superseded same-day ones): date, `changedAt` (for the time), kind (`started` / `startedPartway` / `later`), the typed `PeriodChange` list, `dailyAfter` (for the last record of its day), `daysLeft` (= `start.daysUntil(month.end) + 1`, the span the engine spread over), `replacedSameDay`.
   - `periods`: one `StatementPeriod` per **non-superseded** record (so AC-6's "exactly 2 period cards"): `index` / `of`, dates, `days`, typed `reasons`, values in force (salary, target, fixed-cost items; or money left and still-to-pay items for a mid-month start), a `StatementWorking`, and the totals "for these days" (`budget` = sum of the period's day budgets, `spent`, `refunds`, `netSpent`, `saved`, `overspent`, `covered`, `hasRefunds`).
   - `roundingNoteNeeded`.
2. **The working line is derived, not stored.** `spendable = values.spendable`, `alreadyBudgeted = spendable − amountToSpread` (the engine defines `amountToSpread = spendable − sum(earlier budgets)`, so this is exact), `spreadDays = start.daysUntil(month.end) + 1` (the period spreads to the month's end, which is why P1 of example M reads "over 30 days" though it lasted 12), `daily = budgets.first` (shown in whole rupees by `formatRupees`), `extraPaiseDays = amountToSpread.value % spreadDays` (for the `(i)`: `the first 4 days get 1 paisa more`; 0 → `divides evenly`). Variants: `normal` (first period or later), `shortfall` (`amountToSpread < 0`, `continuedWithShortfall`), `zero` (`zeroSpendable`, D-043), `underRupeeShortfall` (shortfall under 100 paise, D-050 / D-055 `less than ₹1 short`). The first term of the line is the spending target when one is set (that is what the engine spreads; Gate 1 D-081 (2): the line does not name it). The `, minus ₹X already budgeted` part is **left out when X is ₹0** (first period, a change on the first day, a change after ₹0 days; D-081 (3)).
3. **Reasons** come from `PeriodResult.changes` compared with the **previous non-superseded** period (so a same-day double change names the net change): salary, target, money left, `Rent changed` (same name, new amount), `Fixed cost added: Gym`, `Fixed cost removed: EMI`, and **renamed** (`Rent renamed to House rent`: one removed and one added item with the same amount and nothing else changed; the engine's diff reports it as removed + added). The first period reads `Month started` (`Month started partway` for `MidMonthStartValues`). Several reasons are joined by the screen with ` · `. If the net diff is empty (a same-day change and revert) the reason reads `Changed and changed back` (D-081 (6)). The What changed **lines** compare each stored record with the **previous stored record**, so a second change on the same day shows its own old value (`Rent ₹13,000 → ₹11,000`); added / removed / renamed fixed costs read `Fixed cost added: Gym ₹500`, `Fixed cost removed: EMI ₹5,000`, `Rent renamed to House rent` (D-081 (5)). A one-day period heading reads `30 Nov · 1 day`.
4. **The totals identity** `Budget − Net spent = Saved − Overspent − Covered` is **not printed** (spec) and is asserted only for periods whose last day is before today and for past months (D-060: a current period can include today's live overspend). The property test runs over random engine months.
5. **Rounding note (D-053, D-062).** Pure `roundingNoteNeeded(statement)`: for each figure that has both a month line and period lines (budget, spent, refunds, net spent, saved, overspent, covered) compare the **displayed** whole rupees (`value ~/ 100`, toward zero, the same rule as `formatRupees`) of the month line with the sum of the displayed period lines. Any difference → note. Example AC-12: 450,060 + 450,060 paise shows 4,500 + 4,500 but the month 9,001 → note; example M adds up → no note. To keep one rounding rule, a small `Paise.wholeRupees` extension in the domain is added and `formatRupees` is switched to use it **only as a no-behaviour-change refactor** (D-081 (7)): the existing F-008 AC-19 and money-format tests must pass **unchanged**; if any of them needs editing, drop the refactor and leave `formatRupees` as it is (D-069 / D-070 are untouched).
6. **Screen.** `MonthStatementScreen(monthId, {CalendarDate? scrollToPeriodStart})` is a pushed full screen with a back arrow (design S-1). `monthStatementProvider` (a `Provider.family<AsyncValue<MonthStatement?>, int>` built on `monthResultProvider(monthId)`) keeps it live (AC-15). Cards are built eagerly in one scroll column: at most ~10 periods (AC-17), never collapsed, and `GlobalKey`s make "scroll to this period" simple and reliable (a lazy list could not scroll to an unbuilt card). Month changes use the shared `MonthSwitcher` (design §7.14, F-011 T-325).
7. **Strings.** Visible text and the single-sentence TalkBack text are built in one place (`statement_text.dart` in `features/statement/`) from the typed data, so the working line, the `(i)` and the screen-reader sentence (`35,000 rupees minus 15,100 rupees fixed equals ...`, `formatRupeesForSpeech`) cannot drift apart. Line breaks: amounts use the existing non-breaking digits and word joiner; the visible line is a `Text.rich` whose break points are only at ` = `, `, minus ` and ` → ` (spaces elsewhere are non-breaking), tested at text scale 2.0 (AC-16).
8. **Time of a same-day change** (`20 Nov, 10:00`): `changedAt` is UTC milliseconds, shown in device local time. Local conversion is not allowed in `domain/` (`domain_layering_test` forbids `.toLocal()`), so `core/format/date_format.dart` gets `formatClockTime(int utcMillis)` (hand written 24 h `hh:mm`, no `intl`, D-070).
9. **Arrival from a day** (design S-6): `Scrollable.ensureVisible` to the period card with `alignment` so its top is `space6` below the bar, a 600 ms `accentSoft → surface` flash (`TweenSequence` on the card fill; none with Remove animations / `BudgetMotion.of(context)` zero durations), and TalkBack focus on the period heading (a `Focus` node on the heading that requests focus after the first frame). Risk: TalkBack focus follows input focus only on some versions; the widget test proves the focus node, the TalkBack walk stays manual (see §7).

**Why not store statements:** derived data would go stale (STANDARDS: nothing derived is stored); the engine recomputes in microseconds. **Why not a `DataTable`:** the working strip and wrapping rules need rich text and 2.0x layouts that a table cannot do.

## 2. Files / modules
| Path | Add / Change | What |
|---|---|---|
| `app/lib/domain/budget/month_statement.dart` | Add (T-400) | `MonthStatement`, `StatementTotals`, `StatementChange`, `StatementPeriod`, `StatementWorking` (sealed: normal / shortfall / underRupeeShortfall / zero), `PeriodReason` (sealed), `buildStatement`, `roundingNoteNeeded` |
| `app/lib/domain/budget/whole_rupees.dart`; `app/lib/core/format/money_format.dart` | Add / Change (T-400) | `Paise.wholeRupees` (`value ~/ 100`); `formatRupees` and `formatRupeesForSpeech` call it |
| `app/lib/domain/budget/budget.dart` | Change | Exports |
| `app/lib/core/format/date_format.dart` | Change (T-401) | `formatClockTime` |
| `app/lib/core/copy/statement_copy.dart` | Add (T-401) | All F-014 §5 strings; amount-bearing sentences are functions of already formatted amounts |
| `app/lib/features/statement/statement_text.dart` | Add (T-401) | Change line, working line, shortfall line, `(i)` text and screen-reader sentences from the typed data |
| `app/lib/features/statement/statement_state.dart` | Add (T-402) | `monthStatementProvider(monthId)` |
| `app/lib/features/statement/month_statement_screen.dart` | Add (T-402) | Pushed screen, states, `scrollToPeriodStart` |
| `app/lib/features/statement/widgets/totals_card.dart`, `what_changed_card.dart`, `period_card.dart`, `working_strip.dart`, `fixed_costs_expander.dart`, `rounding_note.dart`, `not_budgeted_note.dart` | Add (T-402) | Small widgets, one per design part; `LedgerRow` reused from F-013 T-383 |
| `app/lib/features/statement/open_month_statement.dart` | Add (T-405 seam, T-402 fills it) | `openMonthStatement(context, monthId, {scrollToPeriodStart})`, and a `monthStatementLauncherProvider` (no-op default until the screen exists, the `monthSetupLauncherProvider` pattern) so Home (F-010), the Dashboard (F-013) and Day details (F-012) call one function |
| `app/test/domain/budget/month_statement_test.dart`, `statement_rounding_test.dart`, `statement_property_test.dart` | Add | `TC-014-NN ...` unit and property tests |
| `app/test/features/statement/*_test.dart` | Add | Widget tests, sweeps |
| `app/test/domain/budget/fixtures.dart` | Change (T-400) | Fixtures for example M (two periods), E2 three periods, same-day changes, S, C4, F, with spends / covers / refunds from the spec |
| `app/integration_test/statement_speed_test.dart` | Add (T-404) | 10 periods and 500 spends on real Drift, shown < 1 s (AC-17) |

## 3. Data model / database changes
None. It reads the F-007 period history through `StoredMonth.periods` and the engine. `watchMonthIndex()` (F-011 T-322) lets ‹ › reach past months.

## 4. Packages (latest stable, checked on pub.dev)
| Package | Version | Why |
|---|---|---|
| none | | No `intl` (D-070), no PDF package (PDF is out of scope, D-037) |

## 5. Tasks
| ID | Task | Covers AC | Depends on | Status |
|---|---|---|---|---|
| T-400 | **Statement model in pure Dart** + fixtures. Builds every worked example of §2.6 and §2.7 through `computeMonth` and checks every shown number, the reasons (incl. renamed), the working variants, the daily-budget remainder, the same-day records, the not-budgeted range, rounding note and the identity (property test) | AC-2, AC-3, AC-5 to AC-13 (data), AC-14 (data) | F-006 (exists) | To do |
| T-401 | **Copy and text builders:** `statement_copy.dart`, `statement_text.dart`, `formatClockTime`; unit tests of visible text and TalkBack sentences, wrapping points | AC-2, AC-6, AC-13, AC-16 | T-400 | To do |
| T-402 | **Screen:** totals card, rounding note (AC-12 widget), What changed, period cards, footnote, fixed-cost expand, daily-budget (i) help sheet (AC-13 widget), switcher, states (loading, error, no month, new month not set up), live updates, `openMonthStatement` behind the T-405 seam | AC-1 (Home / Dashboard entry), AC-2, AC-4, AC-5, AC-8 to AC-15 | T-400, T-401, T-405, F-011 month browsing (T-322, T-323, T-325), `LedgerRow` (F-013 T-383) | To do |
| T-403 | **Arrival and entry points:** wire Home (F-010 T-306), Dashboard (F-013 T-384) and Day details (F-012 T-343 / T-345) to `openMonthStatement`; scroll to period, flash, heading focus | AC-1 (day entry) | T-402, T-405; F-010 / F-012 / F-013 screens | To do |
| T-404 | **Sweeps and speed:** all states x 4 themes x text 1.0 / 2.0 x small phone x landscape; TalkBack semantics tests; `statement_speed_test.dart`; list for the Tester's regression | AC-16, AC-17 | T-402 | To do |
| T-405 | **Statement launcher seam (added at Gate 1).** `open_month_statement.dart` with `openMonthStatement` and `monthStatementLauncherProvider` (no-op default, overridden by T-402), one unit test; lets F-010 T-306, F-012 and F-013 T-384 compile and wire before the screen exists | AC-1 (seam) | — | Code review |

F-014 touches no editor file. It can run beside F-013, F-015 and F-016 on separate folders (D-033).

## 6. Acceptance criteria coverage
Test case IDs are the Tester's (`tests/F-014-month-statement.md`, authoritative); the plan's earlier proposed slots are retired (Gate 1).

| AC | Built in task | Proved by test cases |
|---|---|---|
| AC-1 Entry points (Home, Dashboard, Day details scrolls to Period 2) | T-402, T-403, T-405 | TC-014-01, -02, -45, -51, -53, -54 |
| AC-2 Full month example M, exact text | T-400, T-401, T-402 | TC-014-03, -04, -44, -46, -47, -56 |
| AC-3 Totals add up; check line | T-400 | TC-014-05, -06, -48 |
| AC-4 So far on 20 Nov, Left equals Home | T-400, T-402 | TC-014-07, -08, -41, -52 |
| AC-5 What changed, `No changes this month.` | T-400, T-402 | TC-014-09, -31, -33, -57 |
| AC-6 Same-day changes (10:00 / 18:00, 2 cards) | T-400, T-401, T-402 | TC-014-10 |
| AC-7 Three periods (fixed-cost items, `₹22,900`) | T-400, T-402 | TC-014-11, -32, -35 |
| AC-8 Values per period never rewritten | T-400, T-402 | TC-014-12 |
| AC-9 Shortfall statements (S, C4, D-043 zero) | T-400, T-401, T-402 | TC-014-13, -14, -15, -34, -38, -56 |
| AC-10 Mid-month first month | T-400, T-402 | TC-014-16, -43 |
| AC-11 Refunds, per period and month (`−₹500`) | T-400, T-402 | TC-014-17, -42 |
| AC-12 Rounding note (4,50,060 x 2): rule in T-400, note widget in T-402 | T-400, T-402 | TC-014-18, -19, -20, -55 |
| AC-13 Daily-budget (i): text in T-400 / T-401, help sheet in T-402 | T-400, T-401, T-402 | TC-014-21, -22, -39 |
| AC-14 Past months, limits like F-011 | F-011 month browsing, T-402 | TC-014-23, -24, -36, -40 |
| AC-15 Read-only, live | T-402 | TC-014-25, -54 |
| AC-16 Help, themes, large text, landscape, TalkBack, wrapping | T-401, T-402, T-404 | TC-014-26, -27, -28, -29, -37, -49, -50 |
| AC-17 Speed (10 periods, 500 spends, < 1 s) | T-404 | TC-014-30 |

## 7. Edge cases & risks
| Case / risk | How it is handled |
|---|---|
| Change on the month's first day | The replaced first record is superseded (no days): in What changed as `(replaced the same day)`, no card; the card reads the whole month |
| Change on the last day | 1-day period; `over 1 day` (singular via `formatDayCount`); `daysLeft` 1 |
| Rename only | `Rent renamed to House rent`, daily unchanged; detected from the diff (§1.3) |
| Shortfall removed by a later change | Next period shows a positive working line; the month's shortfall is the current period's (engine) |
| 10+ periods | All listed (spec); eager column, measured |
| Missed months | No statement (F-008): `MonthBrowser` only lists stored months |
| Shortfall under ₹1 | `less than ₹1 short · ₹0/day` from the exact paise (D-050 / D-055) |
| Many periods with paise | Gap can exceed ₹1: note says "a few rupees" (D-062); a test with three periods of ₹100.90 (shown 100 each, month 302) |
| New month not set up | The screen opens the last month as a past month (no `so far`) |
| Same-day changes with times | `formatClockTime`; unit-tested at midnight and 12:xx; **time zone risk** minimal (`changedAt` is an instant; test builds the local `DateTime` and the expected text from the same local value) |
| Net diff empty after a same-day revert | §9 Q-4 |
| Risk: working line text drifts between visible and spoken | One builder, tests compare both |
| Risk: a wrong "already budgeted" | Equals `spendable − amountToSpread`, checked in tests against the spec numbers (₹9,960, ₹12,450, ₹17,490) |
| Risk: TalkBack focus on arrival | Widget test proves the focus node; the real TalkBack check is a manual case (D-066 style, Blocked-needs-human if the AVD has no TalkBack) |
| Risk: refunds copy | Design writes `−₹500`; AC-11 / §5 text says `₹500`: **follow the design** (flagged by the Designer, F-014 change history); PM to fix the AC wording |

Edge cases (Tester IDs): change on the first day TC-014-31; change on the last day -32; rename only -33; shortfall removed by a later change -34; 10+ periods -35; missed months -36; ₹10 crore salary -37; shortfall under ₹1 -38; leftover paise -39; new month not set up -40; three periods with paise (gap ₹2) -20; rounding -18, -19, -55; same-day revert -57; target in the working line -56.

## 8. Impact on existing features
- **F-006 / F-007:** no engine or storage change except the `Paise.wholeRupees` extension; re-run TC-006 (TZ hash, 100 % coverage, integer guard TC-006-30: the new `~/ 100` is allowed in `domain/`) and TC-007 period-history cases (AC-16).
- **F-008:** `formatRupees` now calls the extension: re-run TC-008-19 (rounding) and the money-format tests (`money_format_test.dart`, `money_format_only_test.dart`: screens still may not use `~/ 100`).
- **F-003:** none (no tab change). **F-004:** `help_rule_test.dart` (every total has its label and (i)). **F-002:** four-theme sweeps; new tokens used only through `BudgetColors`.
- **F-010, F-012, F-013:** they call `openMonthStatement` (T-403); re-run their entry-point cases when wired.
- **F-009:** no change; end-of-phase regression only.

## 9. Open questions
*All answered at Gate 1 (2026-11-16): see §10 and D-081.*
1. **PM (phase overview open item 5, other features):** none specific to F-014.
2. **PM:** AC-11 writes `Refunds ₹500`, the design and §5 write `Refunds −₹500`. Plan follows the design. Please align the AC.
3. **Designer / PM:** with a spending target set, the working line starts with the target (`₹20,000 − ₹15,100 fixed = ...`), since that is what is spread; the spec examples have no target. Confirm, and say whether the line should name it (`target ₹20,000`).
4. **Product Manager / Designer:** the reason text for a period whose same-day changes net to nothing (changed and changed back) is not in §5. Proposal: `Changed and changed back`. Also the What changed line wording for an added or removed fixed cost and for a rename is not specified (only the reasons are). Proposal: `Fixed cost added: Gym ₹500 → ₹772/day for the 7 days left`, `Fixed cost removed: EMI ₹5,000 → ...`, `Rent renamed to House rent → ...`.
5. **Owner decisions:** none (no money rule; PDF export stays out of scope).

## 10. Project Manager review *(Gate 1 — cross-check of doc + plan + test cases)*
**Verdict:** **Approved** (2026-11-16, Project Manager B). The Must fix points below were resolved in the plan, doc and test file in this pass. Owner decisions: none (no money rule, PDF stays out of scope, no permission, nothing leaves the phone).

Cross-check:
- [x] Every AC in the feature doc is covered by a task in this plan (AC-12 note and AC-13 help sheet widgets now under T-402)
- [x] Every AC has at least one test case in the test file (17 of 17; map in §6 and `tests/F-014` §2.4)
- [x] Edge cases in the doc appear in both the plan and the test cases (all 10 bullets of §4: TC-014-31 to -40, -20, -39)
- [x] Approach follows `docs/STANDARDS.md` (statement is a pure function of the engine result in `domain/`, typed data not strings, integer paise, no new money rule, engine hash unchanged; D-034 to D-062 and D-069 to D-072 untouched)
- [x] Latest stable versions / modern APIs used (no package, no `intl` per D-070; sealed classes and records; `Scrollable.ensureVisible`)

| # | Point | Type | Resolution |
|---|---|---|---|
| 1 | AC-11 says `Refunds ₹500`, design and §5 say `−₹500` | Must fix | Done: AC-11 and §2.3 now read `Refunds −₹500` (D-081 (1)); TC-014-42 follows the design |
| 2 | Plan gaps: AC-12 note and AC-13 help sheet only under T-400 / T-401; §6 used proposed slots | Must fix | Done: both listed under T-402, §6 rewritten with the Tester's IDs |
| 3 | `monthStatementLauncherProvider` / `openMonthStatement` are in T-402, but F-010, F-012 and F-013 call them earlier | Must fix | Done: seam as its own task T-405 (no-op default); F-010 T-306, F-012 T-343 and F-013 T-384 depend on it; T-402 fills it |
| 4 | Duplicate month browsing (F-013 T-381) | Must fix | Done: F-011 owns it; T-402 depends on F-011 T-322 / T-323 / T-325 |
| 5 | Working line with a spending target | Ruling | Starts with the amount the engine spreads (the target when set); the Values rows show Salary and Spending target; the line does not name it (D-081 (2)); TC-014-56 follows |
| 6 | `, minus ₹0 already budgeted` when nothing was budgeted before (TC-014-31 vs -34 disagreed) | Must fix | Done: left out when ₹0 (D-081 (3)); TC-014-31 and -34 updated |
| 7 | One-day period heading | Ruling | `30 Nov · 1 day` (no range dash, like F-015's one-day chip); TC-014-32 updated; Designer T-407 |
| 8 | Old value in a later same-day line; wording for added / removed / renamed fixed costs; reason when same-day changes net to nothing | Ruling | Per-record diff (`Rent ₹13,000 → ₹11,000`); `Fixed cost added: Gym ₹500` / `removed: EMI ₹5,000` / `Rent renamed to House rent`; `Changed and changed back` (D-081 (5), (6)); TC-014-10 updated, TC-014-33, -57 follow; doc §2.8 |
| 9 | `Paise.wholeRupees` refactor touches `formatRupees` (Phase 2 display code) | Must fix (condition) | Allowed only as a no-behaviour-change refactor: F-008 AC-19 and the money-format tests pass unchanged, otherwise dropped (D-081 (7)); written into §1.5 |
| 10 | The design example "so far on 20 Nov" (`month-statement.md` §8.1 and its Owner preview) does not add up: 13–20 Nov budget ₹4,417.80, spent ₹4,000 cannot give Saved ₹456 and Overspent ₹291 | Must fix (design) | Designer task T-407: use the Tester's M20 (Spent ₹4,000, Saved ₹715, Overspent ₹297; month Saved ₹2,115, Overspent ₹537, Pot ₹1,915, Left ₹6,900). Not a Gate 1 blocker: TC-014-07 and the doc already use M20-style numbers |
| 11 | Seeds M-full and M20 (the doc gives totals, not days) | Ruling | Confirmed as the data for AC-2 to AC-4; the Developer builds fixtures from them (`phase3_fixtures.dart`, T-389) |
| 12 | Missing edge cases | Nice to have | Tester task T-406: (a) a change made today (a period with 0 past days, `in progress`, Saved ₹0); (b) a month with no fixed costs (`Fixed costs ₹0`, no expander, working line without items); (c) the AC-1 scroll-to-period target when the statement month is a past month |
| 13 | Time zone of `formatClockTime` | Nice to have | Plan's test (local `DateTime` and expected text from the same value) is enough; no action |

## 11. Implementation notes *(Developer, filled in during the build)*
Deviations from the plan and why (each approved by the Project Manager).

**T-429 (Developer, 2026-11-23, test-only, D-100).** `statement_speed_test.dart` (TC-014-30): the 1,000 ms limit is asserted in profile mode, 3,000 ms guard in debug. Profile worst of 5: 118 ms.

**T-472 tests and probes (Developer, 2026-11-23, no app code changed).** TC-014-58 (pure `month_statement_test.dart` + screen), TC-014-59 (pure + screen), TC-014-60 (screen, real flow: day details of 20 Oct in OCT + Nov, tap the change line, statement opens on October). Engine values equal the Tester's derivation: Budget 13,26,000 paise over 22 days, 60,272 r 16 (first 16 days 60,273), shown `₹602/day`, P1 budget 6,64,000. Probes (scratch copy, reverted): period starting today not in progress, and `already = 0`, killed by TC-014-58; `if (false)` in the costs row and `fixed + 100` killed by TC-014-59; scroll target dropped, change line hidden in a past month, and monthId + 1 in day details killed by TC-014-60. The 600 ms flash and the once-only arrival are not re-asserted in TC-014-60 (TC-014-02/-51 cover them).

**T-405 (statement launcher seam), built 2026-11-16 by the foundations Developer.** `openMonthStatement(context, monthId, {scrollToPeriodStart})` reads `monthStatementLauncherProvider` through `ProviderScope.containerOf(context)` and does nothing by default. The seam test is named TC-014-01 (AC-1 entry), the closest case. T-402 must override the provider's default (replace the closure) and keep the signature.
**T-400 to T-404 built 2026-11-19 by Developer D (awaiting code review).** Deviations and notes:
1. **Month switcher** (2026-11-19): the shared `MonthSwitcher` (T-323) is used; the screen keeps its own viewed month (starts on the month it was opened for, `This month` goes to the latest) and keeps the old content while the next month loads. Past months show `Ended`; the latest month that is over shows no tag. TC-014-23, -24, -36, -40 pass. ‹ disabled copy is the shared `No earlier months`.
2. **Fixed cost added / removed reasons carry the amount** (`Fixed cost added: Gym ₹500`), as design section 7 and D-081 (5) say; TC-014-47 lists them without the amount. Tester to align the case.
3. **Working-line wrapping.** Chunks wrap only between ` = `, `, minus ` and ` → ` while every chunk fits; when a chunk is wider than the strip (the design's five-line example cannot fit in 256 dp at 2.0x) the line relaxes to wrapping at spaces, never inside an amount, and an operator stays with its amount. TC-014-27 is two tests (strict at 640 dp, relaxed at 320 dp x2.0).
4. **Wording not in the spec** (flagged for the Designer): target changes in What changed read `Spending target set to ₹25,000` / `Spending target removed` / `Spending target ₹20,000 → ₹25,000`; `(i)` of `Spent` and `Savings pot` / `Covered` are my wording (F-010 / F-012 copy is not in code yet): `Everything you spent, before any refunds.`; `the first day gets 1 paisa more` when one day gets the extra paisa.
5. **Period cards show no (i) on their rows** (design preview), only the totals card does. The totals card uses `LedgerRow` (F-013 T-383) with a new optional `status` (mark and colour for Saved and Overspent).
6. **`monthStatementLauncherProvider` default** now pushes the screen; the seam test was replaced (see T-405).
7. **Arrival** (scroll, 600 ms flash, heading focus) is built in the screen; the card sits at the top of the viewport (not `space6` below the bar). TalkBack focus follows only on devices where input focus drives it (manual TC-014-29).
8. **Speed test** `integration_test/statement_speed_test.dart` is written and analysed but not run on the emulator.

9. **Gate 3 fixes (Developer D, 2026-11-19).** T-401: `TC-014-28` unit test of `formatRupeesSpoken`; `StatementCopy.savedWord` and `overspentWord` removed; private `_compactRange` replaced by the shared `formatCompactRange`. T-402: `TC-014-06`, `TC-014-42` and `TC-014-52` (midnight) tests added, no screen bug; `LedgerRow` doc comment corrected.
