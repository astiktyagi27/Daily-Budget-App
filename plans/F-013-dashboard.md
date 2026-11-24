# Plan — F-013: Dashboard

| | |
|---|---|
| **Feature doc** | [`docs/features/F-013-dashboard.md`](../docs/features/F-013-dashboard.md) (final spec, 17 ACs) |
| **Test cases** | [`tests/F-013-dashboard.md`](../tests/F-013-dashboard.md) (Tester writes it at Step 4; the TC IDs in §6 were reconciled to the Tester's file at Gate 1) |
| **Design** | [`docs/design/screens/dashboard.md`](../docs/design/screens/dashboard.md) (draft for Phase 3 Gate 2), design system §7.14 month switcher, §7.15 segmented control, §7.16 share bar row |
| **Inputs** | D-034 .. D-040, D-042, D-046 .. D-048, D-050, D-054 .. D-057, D-059, D-060, D-062, D-069 .. D-072; F-006 / F-007 / F-009 plans; phase 3 overview open items 2, 4, 5 |
| **Author** | Developer 2 |
| **Status** | Plan approved (Gate 1, 2026-11-16, Project Manager B; D-080) |

## 1. Approach
The Dashboard is a read-only view over two things that already exist: the engine's `MonthResult` (`monthResultProvider(monthId)`: day statuses, net spent per day, covers, month totals) and the stored spends (`monthSpendsProvider(monthId)`). Nothing is written and no money rule changes (Phase 3 overview: "Phase 3 only displays engine numbers").

1. **Two pure-Dart statistics, no money arithmetic in widgets** (STANDARDS §3, §4), new files in `app/lib/domain/budget/`, each its own library exported from `budget.dart` (D-059):
   - `category_breakdown.dart`: `categoryBreakdown(spends, from, to)` returns the ranked rows (`category`, `amount`, `percent` as whole percent rounded down, `underOnePercent`, `barPermille`), the gross `spent`, the `refunds`, the `netSpent`, whether the shown percents add up to 100, and a `kind` (`empty` / `single(category)` / `several`). The `kind` is what makes the screen read well when almost everything is Other (AC-2, AC-3).
   - `month_figures.dart`: `monthFigures(MonthResult)` returns the figures of "This month in numbers" over the **ended days** (budgeted days with status `saved`, `onBudget` or `overspent`; the engine already leaves out `live` today, `upcoming` and `notBudgeted`): highest day (earliest wins a tie, plus `moreDays`), average (integer, rounded toward zero) and the day counts with the covered count.
   - Integer paise only. Share = `amount.value * 100 ~/ total.value`; bar = `amount.value * 1000 ~/ total.value`; average = `sum.value ~/ endedDays`. `~/` truncates toward zero, which is the D-046 rule (a negative average `−₹37` works). Largest case ₹10 crore x 31 days = 3.1 x 10^11 paise; x 100 stays far below 2^53, so it is exact on every platform (AC-14). No `double`, `num`, `.round()`, `.floor()` or `/` in these files (the TC-006-30 guard and `domain_layering_test`).
2. **Net spent always equals the engine.** `categoryBreakdown` is given only the spends the engine counts (dated from the first budgeted day to `min(today, month end)`). A property test checks `sum(rows) − refunds == MonthResult.totals.spentSoFar` for random months (AC-7). For **One day** the day's `netSpent` is the engine's `DayResult.netSpent`.
3. **Categories (decision for AC-14 / phase overview item 2).** The Dashboard reads a **category on every spend**, so the model comes first (task T-380, shared with F-015): `SpendCategory` (the README §3.4 nine) and a nullable `Spend.category` (the engine ignores it, so no money rule and no engine change; the engine determinism hash `tool/tz_matrix.ps1` must stay the same). A spend with no category stored, or a key this version does not know, counts as Other. With Phase 2 data, everything is Other and the **single-category state** is the normal first view.
4. **Month browsing is shared.** F-011, F-013, F-014 and F-015 all need the stored months in order, ‹ › limits and the §7.14 switcher. **F-011 owns it** (F-011 T-322 month index, T-323 limits and provider, T-325 `MonthSwitcher`; Gate 1 ruling, the duplicate T-381 here is removed). The Dashboard keeps its own `dashboardMonthProvider` (selected month id, default = the month of `currentMonthStateProvider`; a not-set-up new month shows the last month as a past month).
5. **Range and day are screen state.** `dashboardRangeProvider` (This month | One day) and `dashboardDayProvider` live in a Riverpod `Notifier` that resets when the month changes (day default = today, or the month's last day for a past month). The picker limits come from the existing `spendDateLimits(month, firstBudgetedDay, today)` (first budgeted day to today, never past the month's end), so there is one rule for "days you can pick".
6. **Provider chain, so updates are live (AC-15):** `monthSpendsProvider` + `monthResultProvider` (both streams) → `dashboardViewProvider` (a sealed `DashboardView`: `NoMonthView`-style states reuse the Phase 2 `AppMonthState`) → widgets. A category change in F-015, or a spend, refund or cover anywhere, re-emits the stream and the view recomputes (an O(n) pass over at most a few hundred spends, well under 1 ms).
7. **Reuse before adding:** `TabPage`, `BudgetCard`, `EmptyState`, `InfoButton` / `LabelDescription` (F-004), `FirstTimeHint(id: HintId.dashboard)` (text and ID unchanged, design B-6), `showBudgetSheet`, `formatRupees` / `formatRupeesForSpeech`, `formatWeekdayDayMonth`, `formatRange`, `BudgetTag`, the StorageCopy error pair used by the Transactions tab. New shared widgets: `SegmentedControl` (§7.15), `ShareBarRow` (§7.16), `LedgerRow` (label + (i) left, amount right; F-014 reuses it).
8. **"Go to Transactions" and the links.** The tab switch needs the selected tab to be readable by a child: today `AppShell` keeps it in local state (`_tab`). T-386 moves it to a tiny `selectedTabProvider` (a `Notifier<AppTab>`), a one-line change to `app_shell.dart` that also helps F-010's links. The highest-day row opens F-012 through the F-012 plan's launcher (`openDayDetails(context, date)`; if none exists when this is built, T-384 adds the provider with a no-op default, as F-009 C6 did for month setup). The `Month statement` row calls `openMonthStatement(context, monthId)` from F-014 (seam T-405, screen T-402).

**Why this over the alternatives:** a charting package or a custom-painted pie was rejected (design B-1: no pie, no axes; a ranked list of bars is a `Container` with a width, readable as text, no package, all four themes from tokens). Computing the statistics in the widget was rejected (STANDARDS §4, and 100 % branch coverage is only practical in `domain/`). Storing per-category totals was rejected (derived data, would go stale; STANDARDS "nothing derived is stored").

## 2. Files / modules
| Path | Add / Change | What |
|---|---|---|
| `app/lib/domain/budget/spend_category.dart` | Add (T-380) | `enum SpendCategory` with the README §3.4 order and storage keys `food, groceries, shopping, travel, bills_recharge, entertainment, health, friends_people, other`; `SpendCategory.fromKey(String?)` (null or unknown key → `other`); `bool get isOther` |
| `app/lib/domain/budget/spend.dart` | Change (T-380) | `Spend` gets `final SpendCategory? category` (optional named constructor parameter, default null). Engine code does not read it |
| `app/lib/domain/budget/budget.dart` | Change | Export the new files |
| `app/lib/data/repositories/drift_mappers.dart` | Change (T-380) | `storedSpendOf` fills `category` from the column (`SpendCategory.fromKey`). The column and schema are unchanged |
| `app/lib/domain/budget/category_breakdown.dart` | Add (T-382) | `categoryBreakdown`, `CategoryBreakdown`, `CategoryRow`, `BreakdownKind` |
| `app/lib/domain/budget/month_figures.dart` | Add (T-382) | `monthFigures(MonthResult)`, `MonthFigures` (highest day + `moreDays`, average, `DayCounts(saved, onBudget, overspent, covered)`, `endedDays`, `strip` = the ended days' statuses in date order) |
| `app/lib/core/copy/category_copy.dart` | Add (T-380) | The nine display names (README §3.4 spelling), shared with F-015 |
| `app/lib/core/widgets/category_icon.dart` | Add (T-380) | The nine Material outlined icons of `transactions-search.md` §5.4 in a 40 dp `neutralSoft` circle, decorative, shared with F-015 |
| *(month index, `MonthBrowser`, `MonthSwitcher`)* | Not built here | F-011 owns them (T-322 / T-323 / T-325); F-013 only consumes them (Gate 1) |
| `app/lib/core/widgets/segmented_control.dart`, `share_bar_row.dart`, `ledger_row.dart` | Add (T-383) | §7.15, §7.16 and the label/(i)/amount row of Refunds and Net spent |
| `app/lib/core/copy/dashboard_copy.dart` | Add (T-384) | All F-013 §5 strings; sentences that carry an amount are functions of the already formatted amount |
| `app/lib/core/copy/screen_copy.dart` | Change (T-384) | Dashboard placeholder strings removed (F-003 impact, §8) |
| `app/lib/features/shell/app_shell.dart`, `app_tab.dart`; new `selected_tab_provider.dart` | Change / Add (T-386) | Selected tab as a provider so `Go to Transactions` can switch tabs (no new route) |
| `app/lib/features/dashboard/dashboard_state.dart` | Add (T-384) | `dashboardMonthProvider`, `dashboardRangeProvider`, `dashboardDayProvider`, `dashboardViewProvider` |
| `app/lib/features/dashboard/dashboard_tab.dart` | Change (T-384) | Replaces the placeholder: switch over the view states |
| `app/lib/features/dashboard/widgets/where_money_went_card.dart`, `category_rows.dart`, `single_category_view.dart`, `other_hint_card.dart`, `refund_lines.dart`, `numbers_card.dart`, `day_strip.dart`, `statement_link_row.dart`, `day_chip.dart` | Add (T-384) | One small widget each (STANDARDS "small widgets") |
| `app/test/domain/budget/category_breakdown_test.dart`, `month_figures_test.dart`, `spend_category_test.dart`, `month_browser_test.dart` | Add | `TC-013-NN ...` unit tests, 100 % lines and branches (`tool/domain_coverage.ps1`) |
| `app/test/features/dashboard/*_test.dart` | Add | Widget tests on the fake repositories and the E2 harness (`test/helpers/transactions_harness.dart`, `e2Store`), sweeps with `theme_cases.dart` |
| `app/integration_test/dashboard_500_test.dart` | Add (T-385) | 500 spends in 9 categories on the real Drift file, final figures < 500 ms (AC-17) |
| `app/test/features/tabs/empty_tabs_test.dart`, `test/copy/copy_tables_test.dart`, `test/features/screens/p1_screen_sweeps_test.dart` | Change (T-384) | Dashboard placeholder cases updated (§8) |

## 3. Data model / database changes
**None to the schema.** The nullable `transactions.category` column (F-007) is read. Stored keys (decision, "agreed in the plan" per F-015 §7): `food, groceries, shopping, travel, bills_recharge, entertainment, health, friends_people, other`, lower-case with underscores, chosen so Phase 4's categoriser can write the same strings. A `null` or unknown value reads as Other and is never an error (no crash on data from a later version). `MonthRepository.watchAllMonths()` is a new read query (T-381).

## 4. Packages (latest stable, checked on pub.dev)
| Package | Version | Why |
|---|---|---|
| none | | No chart package (design B-1). No `intl` (D-070). Date labels use `date_format.dart` |

## 5. Tasks
| ID | Task | Covers AC | Depends on | Status |
|---|---|---|---|---|
| T-380 | **Category read foundation (shared with F-015, F-016).** `SpendCategory`, `Spend.category`, mapper reads the column, `category_copy.dart`, `category_icon.dart`. Unit tests: key round trip, unknown key → Other, order = README §3.4. Engine unchanged: re-run the F-006 suite, the TZ matrix hash and domain coverage | AC-14 (model), supports AC-2 to AC-5 | F-007 (exists) | Code review |
| T-381 | ~~Shared month browsing~~ **Removed at Gate 1:** F-011 owns it (T-322 month index, T-323 limits and provider, T-325 `MonthSwitcher`; the pure `MonthBrowser` is part of F-011's plan). F-013 only depends on it | — | — | — | Removed |
| T-382 | **Statistics in pure Dart.** `categoryBreakdown`, `monthFigures` with unit tests for every worked example (A, B, refund §2.6, shortfall S, mid-month F, covers, ties, all ₹0, negative net, paise-only, ₹10 crore x 31 days, no ended days) and a property test against `computeMonth` | AC-2 to AC-12, AC-14 | T-380 | Code review |
| T-383 | **Shared widgets** `SegmentedControl`, `ShareBarRow`, `LedgerRow`: four themes, text scale 2.0, TalkBack labels, bar excluded from semantics, help via F-004 | AC-16 (parts) | T-380 | Code review |
| T-384 | **Dashboard screen.** Providers, all states of the design (§8 of the screen spec: loading, error, no month, empty, single category, several, refunds, no ended days, past month, new month not set up, a One day with only refunds), One day picker and chip, links (`Go to Transactions` via `selectedTabProvider`, highest day → F-012, `Month statement` → F-014), live updates; the display of AC-5 (`<1%`, ties), AC-9 (covers) and AC-11 (first day) is built here | AC-1 to AC-13, AC-15 | F-011 month browsing (T-322, T-323, T-325), T-382, T-383, T-386; F-014 T-405 (launcher seam) for the statement link; F-012 T-343 / T-345 (`openDayDetails`) for the day link | Code review |
| T-385 | **Sweeps, speed, hand-over.** AC-16 sweep (each state x 4 themes x text 1.0 / 2.0 x small phone x landscape, TalkBack sentences), `dashboard_500_test.dart` (AC-17), F-003 / F-004 case updates, list for the Tester's regression | AC-16, AC-17 | T-384 | In progress |
| T-386 | **Selected tab as a provider (seam, added at Gate 1).** `selectedTabProvider` (`Notifier<AppTab>`), `app_shell.dart` reads and writes it instead of local `_tab`; no behaviour change. F-010's links may use it too. Re-run TC-003-04, -10, -19, -20, -30 | AC-2 (Go to Transactions) | — (F-003 exists) | Code review |

Build order inside the phase: T-380 first (it unblocks F-015's read side), then T-382 / T-383 / T-386 in parallel (separate files), then T-384 (after F-011's month browsing) and T-385. F-013 does not touch the F-009 editor files, so it never conflicts with F-015 T-424 or F-016 T-442.

## 6. Acceptance criteria coverage
Test case IDs are the Tester's (`tests/F-013-dashboard.md`, authoritative); the plan's earlier proposed slots are retired (Gate 1).

| AC | Built in task | Proved by test cases |
|---|---|---|
| AC-1 Replaces the placeholder; layout; no month state | T-384 | TC-013-01, -02, -39, -43, -44, -47 |
| AC-2 Single category, all Other: sentence, no bar / % / chart, hint card, `Go to Transactions` | T-382, T-384, T-386 | TC-013-03, -04, -49, -52 |
| AC-3 Single category that is not Other: no hint | T-382, T-384 | TC-013-05 |
| AC-4 Several categories: order, amounts, %, bar lengths within 1 dp, no ₹0 rows, rounding note only when shares are below 100 | T-382, T-383, T-384 | TC-013-06, -07, -35, -36 |
| AC-5 `<1%` and README-order ties | T-382, T-384 | TC-013-07, -08, -37 |
| AC-6 One day: chip, sentences, empty day, picker limits | T-384 | TC-013-09, -42, -48 |
| AC-7 Refunds lines; net spent equals the engine; day with refunds above spends | T-382, T-384 | TC-013-10, -11, -45 |
| AC-8 Numbers, example A (and edge cases of the figures) | T-382, T-384 | TC-013-12, -13, -14, -33, -34, -40, -41, -46 |
| AC-9 Covers in the numbers | T-382, T-384 | TC-013-15 |
| AC-10 Highest-day tie `+1 more day` | T-382, T-384 | TC-013-16 |
| AC-11 No ended days | T-382, T-384 | TC-013-17, -18 |
| AC-12 Shortfall month and mid-month first month | T-382, T-384 | TC-013-19, -20 |
| AC-13 Past months, limits like F-011 | F-011 month browsing, T-384 | TC-013-21, -22, -47, -48 |
| AC-14 Integer statistics, 100 % branches, ₹10 crore x 31 days | T-380, T-382 | TC-013-23, -24, -25 (also `domain_layering_test`, `tool/domain_coverage.ps1`); TC-013-53 added by T-387 |
| AC-15 Live updates | T-384 (proof with the F-015 flow in T-385) | TC-013-26, -27, -36, -52 |
| AC-16 Help, themes, large text, landscape, TalkBack | T-383, T-384, T-385 | TC-013-28, -29, -30, -31, -50, -51 |
| AC-17 Speed (500 spends, 9 categories, < 500 ms) | T-385 | TC-013-32 |

## 7. Edge cases & risks
| Case / risk | How it is handled |
|---|---|
| **Almost everything is Other (the main risk)** | `BreakdownKind.single` is a first-class state with its own sentence and hint card; the hint disappears by itself when a second category exists (it is derived, not dismissed, so no storage and no new hint ID). Tested with Phase 2 data (all null categories) and with all-Food |
| One category is Other plus a refund | The sentence and hint show, then `Refunds` and `Net spent` lines (AC-7) |
| All 9 categories used | 9 rows, never truncated; a long row at 2.0x stacks name / amount (design §11) |
| A category's only spend deleted | Recomputed from stored spends, the row disappears |
| Net negative for the month | `Net spent −₹300`; average `−₹37 a day`; `~/` truncates toward zero (D-046) |
| Highest day when every ended day is ₹0 | `No spends yet` (spec). **Plan also uses it when every ended day's net is ≤ 0** (all refunds): see §9 Q-3 |
| Tie on the highest day | Earliest date; `moreDays = ties − 1`; `+1 more day` / `+<n> more days` |
| Partly covered day in "incl. n covered" | The engine already counts a fully covered day as `onBudget` and a partly covered one as `overspent`; `covered` counts every ended day with a cover above ₹0 (see §9 Q-4) |
| Paise-only category (₹0.40 Health) | Row shows `₹0` (D-038) and `<1%` |
| `<1%` and the rounding note | Share > 0 and < 1 % → `underOnePercent`; the note appears when the **shown** whole percents sum below 100 (`<1%` counts as 0) |
| Today leaves the figures (D-039, Q-1) | Only ended days count; the caption says so. Today's spends **do** count in the category section (month "so far") |
| Midnight while open | `todayProvider` refreshes; the provider chain recomputes; new month not set up shows last month as past |
| Device date set back | The engine ignores future-dated spends; `categoryBreakdown` is given only the engine's counted range |
| Spends outside budgeted days | Not passed in (mid-month first month: 5 to 9 Nov are ignored) |
| Large text | Rows stack above 1.3x; amounts use non-breaking digits and the word joiner (existing formatter) |
| Risk: `Spend` gains a field | Additive and optional. Compile-time check only; the engine's 100 % branch coverage and the TZ dump hash prove no behaviour change |
| Risk: a one-bar chart looks broken | No bar when there is one category (spec) |
| Risk: share bar width is a `double` | Layout-only (a fraction of the available width from the integer permille); never shown as money. The architecture tests only scan money text |
| Risk: speed | O(n) with n <= a few hundred; engine result and spends are cached by providers; measured on the emulator (T-385) |

Edge cases (Tester IDs): all 9 categories TC-013-35; negative net (`−₹37 a day`) -33; paise-only -37; all ₹0 -34; midnight and new month not set up -39, -47; device date back -38; a category's only spend deleted -36; today left out until midnight -40; two-period month -41; refund-only day -45 and -46.

## 8. Impact on existing features
- **F-003:** the Dashboard placeholder (`ScreenCopy.dashboardEmpty*`, TC-003-05's Dashboard part in `empty_tabs_test.dart`) is replaced; update those cases (as T-216 / T-218 did). Re-run TC-003-04, -10, -19, -20, -30 (the `selectedTabProvider` change in `app_shell.dart`).
- **F-004:** `hint.dashboard.v1` text and ID are unchanged (design B-6): re-run TC-004 hint cases and `hints_test.dart`. Every new control uses `LabelDescription` / `InfoButton` / tooltips: `help_rule_test.dart` must stay green.
- **F-002:** tokens only (`tokens_only_test.dart`, `shared_components_test.dart`); new components added to the design system's component list (Designer).
- **F-006:** engine logic untouched. `Spend.category` is additive: re-run the whole F-006 suite, `tool/tz_matrix.ps1` (three identical hashes) and `tool/domain_coverage.ps1` (100 %, now also the new files).
- **F-007:** `storedSpendOf` and the new `watchAllMonths` query: re-run TC-007 repository cases and the 500-spend case TC-007-14.
- **F-009:** list, editor and Today card untouched by this feature; re-run its Regression-yes cases once at the end of the phase (the category foundation changes `Spend`).
- **F-011, F-014, F-015:** F-013 uses F-011's month index, `MonthBrowser` and month switcher; F-015 reads the categories this feature displays (AC-15 live update is proved by changing a category through the F-015 flow in an integration test, T-385).

## 9. Open questions
*All answered at Gate 1 (2026-11-16): see §10 and D-080 (Q-1 to Q-5), D-085 (T-381).*
1. **PM, phase overview item 2 / F-013 Q-1:** the average and the highest day leave **today** out until midnight (the spec's choice, kept stable during the day). **Developer recommendation: confirm as specified.** Including today "so far" would make the numbers jump with every spend and conflicts with D-039's "today is not final". Needs no Owner decision (display only, no money rule).
2. **PM:** who builds the shared month browsing (T-381: `watchAllMonths`, `MonthBrowser`, `MonthSwitcher`)? Four plans need it. Proposal: F-011 owns it (it is the first screen with ‹ ›) and this plan only depends on it; if the F-011 plan does not include it, T-381 here does. Please assign one owner and delete the other task.
3. **Product Manager:** "Highest-spending day" when no ended day has a positive net spend (all ₹0 is in the spec; all refunds, or refunds cancelling every spend, is not). Plan: `No spends yet` whenever the largest net is ≤ ₹0.
4. **Product Manager:** `incl. <n> covered from savings` counts ended days with any cover above ₹0 (full or partial). The spec example only has a full cover.
5. **Designer:** `Go to Transactions` only switches the tab. It does not pre-set a filter or open an editor; confirm. Also the day-strip (design note 15) is built unless the PM drops it.
6. **Owner decisions:** none. No money rule, permission or privacy change (display statistics only, nothing leaves the phone).

## 10. Project Manager review *(Gate 1 — cross-check of doc + plan + test cases)*
**Verdict:** **Approved** (2026-11-16, Project Manager B). The Must fix points below were resolved in the plan, doc and test file in this pass; nothing is left open for the Developer before T-380 starts. Owner decisions: none (display statistics only, no money rule, no permission, nothing leaves the phone).

Cross-check:
- [x] Every AC in the feature doc is covered by a task in this plan (AC-5, AC-9 display now listed under T-384)
- [x] Every AC has at least one test case in the test file (17 of 17; map in §6 and `tests/F-013` §2.4)
- [x] Edge cases in the doc appear in both the plan and the test cases (§4 of the doc: nine bullets, all in §7 and TC-013-33 to -40)
- [x] Approach follows `docs/STANDARDS.md` (statistics in pure `domain/`, integer paise, `~/` toward zero as D-046, no `double` for money, no package, widgets small; money rules D-034 to D-062 and D-069 to D-072 untouched, the figures only display engine numbers)
- [x] Latest stable versions / modern APIs used (no new package; Dart 3 sealed classes and records)

| # | Point | Type | Resolution |
|---|---|---|---|
| 1 | Task T-381 (shared month browsing) duplicates F-011's month index and switcher | Must fix | Done: T-381 removed, F-011 owns `watchMonthIndex`, `MonthBrowser` and `MonthSwitcher` (T-322 / T-323 / T-325); T-384 depends on them (§1, §2, §5, §8 updated) |
| 2 | §6 used proposed TC slots; AC-5 and AC-9 display had no task beyond T-382 | Must fix | Done: §6 rewritten with the Tester's IDs; T-384 lists AC-5, AC-9, AC-11 display |
| 3 | `selectedTabProvider` hidden inside the screen task, but F-010 can use it too and it touches `app_shell.dart` | Must fix | Done: own task T-386 (seam), T-384 and A's F-010 links depend on it; F-003 cases re-run |
| 4 | Q-1: today left out of the average and highest day until midnight | Ruling | Confirmed as recommended (D-080 (1)). Today's spends still count in the category section |
| 5 | Highest day when no ended day has net above ₹0 (all ₹0, or only refund days) | Ruling | `No spends yet`, not tappable; the average is still shown (D-080 (2)); TC-013-34, -46 match; doc clarified |
| 6 | Does `incl. n covered` count partly covered days | Ruling | Yes, any ended day with a cover above ₹0 (D-080 (3)); M20 reads `incl. 1 covered from savings` (TC-013-41) |
| 7 | Bar length basis | Ruling | The category's exact share of the range total (design system §7.16, integer permille, at least 2 dp), not relative to the biggest row (D-080 (4)); TC-013-06 checks the ratio |
| 8 | One day with only refunds | Ruling | `Nothing spent on <date>.` then `Refunds` and `Net spent` lines (D-080 (5)); TC-013-45 matches |
| 9 | Range choice across restarts | Ruling | Kept while the app is open, This month again after a restart; a month change resets the day (D-080 (6)); TC-013-42, -52 match |
| 10 | The design example "so far on 20 Nov" (`month-statement.md` §8.1, Owner preview) does not add up | Must fix (design, before Gate 2 of this screen's design set) | Designer task T-407 (F-014) with the Tester's seed M20; not a blocker for Gate 1 because no AC reads those numbers |
| 11 | Dashboard design: add the refund-only day state and say the bar basis | Nice to have | Designer task T-388 |
| 12 | No test case for a stored category key this version does not know (plan T-380 has the unit test, the Tester's file has no row) | Nice to have | Tester task T-387 adds `TC-013-53 unknown category key reads as Other` |
| 13 | `Spend.category` touches approved F-006 / F-007 code (additive, engine does not read it) | Ruling | Accepted on the plan's own condition: T-380 re-runs the F-006 suite, the TZ matrix hash (three identical) and domain coverage (100 %); any change to either blocks T-380 |
| 14 | `Go to Transactions` only switches the tab (no filter pre-set); the day strip stays as designed | Ruling | Confirmed (plan Q-5) |

## 11. Implementation notes *(Developer, filled in during the build)*
Deviations from the plan and why (each approved by the Project Manager).

**T-390 (Developer, 2026-11-23, test-only, D-100).** `dashboard_500_test.dart` asserts the 500 ms limit in profile mode (`speedLimitMs` in `integration_test/real_app.dart`) and a 3,000 ms guard in debug. Profile worst of 5: 98 ms; debug worst 833 ms (run 0). Command: `flutter drive --profile -d emulator-5554 --driver=test_driver/integration_test.dart --target=integration_test/dashboard_500_test.dart`.

**T-471 tests and probes (Developer, 2026-11-23, no app code changed).** Added TC-013-49, -57, -58, -59, -60, split TC-013-48 out of TC-013-21, renamed the old-month-stays test to TC-013-55. Probes run in a scratch copy of `app/` (project untouched), each reverted: C15 (hint hidden in One day) killed by TC-013-49; C2b (bar `saved`) and C2c (bar `accent`) by TC-013-58; C4b (no-status amount `textSecondary`, also `overspent`, also status ignored) by TC-013-59; C6a (`<= 1`) and C6b (`< 2`) by TC-013-60; C1 (minHeight 44) and C1b (minHeight 0) by TC-013-57 (not equivalent after all: at 1.0x the constant sets the height); C5 (`_shown = null`) by TC-013-55; day picker `lastDate + 1` by TC-013-48 and TC-013-09.

**T-386 (selected tab provider), built 2026-11-16 by the foundations Developer.** `AppShell` became a `ConsumerStatefulWidget`; the tab fade starts from a `ref.listen` so a change made by another screen fades like a bar tap. `SelectedTabNotifier.select` carries an `ignore` for `use_setters_to_change_properties` (a Notifier method must not be a setter). No behaviour change: TC-003-04, -10, -19, -20, -30 pass unchanged. Own tests are named TC-013-04 (Go to Transactions seam).

**Track C build, 2026-11-19 (T-380, T-382, T-383, T-384, T-385 in part).** Files: `domain/budget/spend_category.dart`, `category_breakdown.dart`, `month_figures.dart` (+ export lines, `Spend.category`); `data/repositories/drift_mappers.dart` (reads the column); `core/copy/category_copy.dart`, `dashboard_copy.dart`; `core/widgets/category_icon.dart`, `segmented_control.dart`, `share_bar_row.dart`, `ledger_row.dart`; `features/dashboard/` (`dashboard_state.dart`, `dashboard_tab.dart`, `widgets/*`); `features/day_details/open_day_details.dart`. Tests: 4 domain/data files, `test/core/widgets/dashboard_widgets_test.dart`, `test/features/dashboard/` (tab, numbers, sweep), `integration_test/dashboard_500_test.dart`, helper `test/helpers/dashboard_harness.dart`.

Deviations and open points (for the Project Manager):
1. **Month switcher (built).** The Dashboard header uses F-011's shared `MonthSwitcher`, `monthIndexProvider` and `MonthBrowse` (`Ended` tag, `This month`, disabled-arrow hints; the latest month follows new months via `followCurrentMonth`). TC-013-21 and TC-013-22 go through the arrows. While another month loads, `DashboardTab` (a `ConsumerStatefulWidget`) keeps the last `MonthDashboard` on screen, like `CalendarSection._shown`; the placeholders are only for the very first load (test `TC-013-22 the old month stays on screen while the next one loads`). Deviation: the header range text also stays on the old month until the new one is ready (it is part of the kept view), where the review asked for the new range at once.
2. **Day details (built).** `openDayDetails` / `dayDetailsLauncherProvider` in `features/day_details/open_day_details.dart` is wired by F-012 T-345: the default pushes the real `DayDetailsScreen`, read-only for a past month. TC-013-14 asserts through the launcher.
3. **Providers:** one `dashboardSelectionProvider` (range, day, month) instead of the three the plan named; one record, one reset rule.
4. **Segmented control** 48 dp tall (design 44 dp) so the node passes the tap-target guideline.
5. **Header text** inside one month is `1 – 30 Nov 2026` (calendar design form), otherwise `5 Nov – 4 Dec 2026`.
6. **Sweep** lives in `test/features/dashboard/dashboard_sweep_test.dart`, not the shared a11y file, and includes M20 again (the Home calendar legend is a `Wrap` now, so the earlier overflow at 2.0x is gone).
7. **Not run:** `dashboard_500_test.dart` (emulator), TC-013-31, -50 (by hand), -51, -52; AC-15 proof through the F-015 flow.
8. Live updates need up to three frame pumps in a widget test (stream event, provider chain, frame); each change shows without a refresh gesture.
