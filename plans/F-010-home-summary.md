# Plan — F-010: Home summary

| | |
|---|---|
| **Feature doc** | [`docs/features/F-010-home-summary.md`](../docs/features/F-010-home-summary.md) (final spec, 19 ACs) |
| **Test cases** | [`tests/F-010-home-summary.md`](../tests/F-010-home-summary.md) (written 2026-11-16, TC-010-01 to TC-010-58, authoritative; section 6 re-mapped at Gate 1) |
| **Design** | `docs/design/screens/home-summary.md` (summary card, Today card, collapsed row, states), design system §7.2, §7.6 |
| **Inputs** | D-034…D-043, D-046, D-047, D-050, D-055, D-057, D-059, D-060; F-006/F-007/F-008/F-009 as built (see §1); plans F-011, F-012, F-017 (sibling plans) |
| **Author** | Developer 1 |
| **Status** | Plan approved (Gate 1, 2026-11-16, Project Manager A; see section 10) |

## 1. Approach
Phase 3 only **displays** engine numbers. Home becomes a thin view over `currentMonthStateProvider` (F-008) and `monthResultProvider` (F-007), the same pattern as the Transactions tab (`transactions_state.dart`).

1. **A pure view model, no money arithmetic in widgets.** `HomeSummary.from(MonthResult)` in `domain/budget/` returns the facts the card needs, as exact paise and flags:
   - `left` and its sign; `dailyBudget` (today's budget, or the current period's first budget when today is outside the budgeted days: the rule `ThisMonthCard._dailyBudget` has today); `rangeStart = firstBudgetedDay`, `rangeEnd = month.end`;
   - ledger values: `salary`, `target` (shown only when below the salary: the engine's `totals.target` is `salary` when none is set), `moneyLeftAtStart` (read from `MidMonthStartValues` of `currentPeriod`; shown instead of Salary when `totals.salary == null`), `fixedCosts`, `spentSoFar`, `saved`, `overspent`;
   - `pot` and `covered` (sub-line only when `covered` is above ₹0 on any cover, so with no covers it is hidden, F-010 §2.2);
   - `progressPermille`: `spentSoFar * 1000 ~/ budgeted` clamped to 0…1000; 1000 when `budgeted` is ₹0 or less or spent is at least budgeted; 0 when spent is ₹0 or less (an integer, so the rule never needs floating point; ₹10 crore x 1000 fits in `int`);
   - `shortfall` and `zeroSpendable` (from `currentPeriod`, engine addition N1 is already built as `MonthResult.currentPeriod`), `startedLate = firstBudgetedDay != month.start` (D-034, D-057 caption);
   - `latestChangeDay`: the start of the last non-superseded period when the month has more than one non-superseded period, else null (`Budget changed on 13 Nov`, F-010 §4 "latest change date").
2. **`TodayLine` gains `moneyIn`** (optional named parameter, default ₹0, filled by `TodayLine.from`) for the `Includes ₹500 back from refunds` line (AC-11). Existing F-009 constructor calls and tests keep compiling.
3. **A `HomeView` sealed type**, exhaustive in the widget, built by `homeViewProvider` (new `features/home/home_state.dart`):
   - `NoMonthHome`, `NewMonthHome(lastMonth)`, `ActiveHome(stored, summary, line?, safeToSpend, canEdit)`.
   - `line` is null when today is not a budgeted day (device date set back): the Today card is left out, as the Transactions tab does (`TodayLine.from` throws there).
   - Loading and error stay `AsyncValue` states, handled in the widget.
4. **Reuse, do not copy.** The Today result line (words, marks, colours, count-up, one-sentence semantics) lives today as the private `_Line` inside `features/transactions/today_line_view.dart`. It moves to `core/widgets/today_result_line.dart` and both the Transactions Today card and Home's Today card use it. F-009's own widget tests are the proof that nothing changed. Features must not import each other's widgets.
5. **Home layout** switches from `TabPage(body:)` to `TabPage.slivers(bodySlivers:)`: summary card, Today card, `SliverToBoxAdapter` for the calendar section (F-011 supplies `CalendarSection`; until it exists a placeholder is not shipped, see §9 Q3). The big card stays a normal box, not lazy, because it is short.
6. **Collapsed row.** A `Stack` in `HomeTab` puts a `CollapsedSummaryRow` over the page. A listener on the shell's per-tab `ScrollController` (`widget.controller`) tests whether the summary card's bottom edge (a `GlobalKey` on it) is above the top of the body, and sets a `ValueNotifier<bool>`; only the small row rebuilds on scroll. It is not built at text scale above 1.3x or in landscape (design §6). Tap scrolls to the top with `animateTo` over `motionEmphasis`. No change to `TabPage`.
7. **Navigation seams.** Today card, `Month statement` and `See month statement` go through two functions: `openDayDetails(context, monthId, date)` (F-012 T-345) and a `monthStatementLauncherProvider` (F-014; same shape as `monthSetupLauncherProvider`). `Edit this month` keeps the existing `_open(EditMonthMode(stored))` guard in `home_tab.dart` (double tap opens one screen, TC-008-49).
8. **`Edit this month` in a ⋮ menu.** Built from the core `BudgetIconButton` (tooltip `More`, 48 dp) and a themed `showMenu`, so the help-rule guard (TC-004-08 bans raw `Tooltip(`/`IconButton(` in `features/`) stays green. If `showMenu` is flagged by the guard, a core `BudgetMenuButton` is added.
9. **Live updates (AC-13) and midnight (AC-4)** need no new mechanism: `monthResultProvider` recomputes on every write and `todayProvider` moves at midnight and on resume. Amounts count up with `TweenAnimationBuilder<int>` and `BudgetMotion.of(context).count`, as the Today line does today. The Today card cross-fades (`motionBase`) when the date changes.
10. **Ledger row widget** `LedgerRow` (label + (i) left, amount right; one `Semantics(container: true)` node reading `Overspent, ₹470` with the (i) as its own node, D-032; stacks label over amount above 1.3x). ₹0 Saved or Overspent has no mark and `neutral` colour (design H-3).
11. **Formatting.** Every amount goes through `formatRupees` / `formatRupeesForSpeech` (AC-12; the TC-008-30 architecture test scans `lib/features`). No `~/ 100`, no `'₹…'` literals in features.

## 2. Files / modules
| Path | Add / Change | What |
|---|---|---|
| `app/lib/domain/budget/home_summary.dart` | Add | `HomeSummary` + `from`, ledger flags, `progressPermille`, `latestChangeDay` |
| `app/lib/domain/budget/today_line.dart` | Change | optional `moneyIn`, `hasRefunds` |
| `app/lib/domain/budget/budget.dart` | Change | export `home_summary.dart` |
| `app/lib/features/home/home_state.dart` | Add | `HomeView`, `homeViewProvider` |
| `app/lib/features/home/home_tab.dart` | Change | `HomeView` switch, slivers, collapsed-row stack, error/loading/empty states, `Edit this month` opener kept |
| `app/lib/features/home/this_month_card.dart` | Delete | replaced; `NewMonthCard` moves to `widgets/new_month_card.dart` (same widget) |
| `app/lib/features/home/widgets/summary_card.dart`, `summary_hero.dart`, `ledger_row.dart`, `summary_ledger.dart`, `shortfall_panel.dart`, `budget_changed_line.dart`, `home_today_card.dart`, `collapsed_summary_row.dart`, `home_loading.dart`, `new_month_card.dart` | Add | Small widgets per the design; `SafeToSpendStrip` comes from F-017 |
| `app/lib/core/widgets/today_result_line.dart` | Add | extracted `_Line` + semantics sentence, shared |
| `app/lib/features/transactions/today_line_view.dart` | Change | uses `TodayResultLine` |
| `app/lib/core/copy/home_copy.dart` | Add | F-010 §5 / home-summary §12 strings, speech sentences |
| `app/lib/core/copy/month_setup_copy.dart` | Change | remove home strings no screen uses any more (`homeThisMonth`, `homeCardSpeech`, `homeShortfallSpeech`); keep the ones the new card reuses |
| `app/test/domain/budget/home_summary_test.dart`, `today_line_test.dart` | Add / Change | `TC-010-NN …` unit tests (examples A, S, M, F) |
| `app/test/features/home/home_summary_*_test.dart` | Add | widget tests on fakes: layout, states, live updates, themes, 2.0x, landscape, collapse |
| `app/test/features/home/home_month_states_test.dart` | Change | F-008 Home cases move to the new card (TC-008-02, -03, -49, -50) |
| `app/integration_test/home_500_test.dart` | Add | 500 spends on the real Drift file: Home figures within 1 s from cold start (AC-19) |

## 3. Data model / database changes
None. No new query: Home reads `monthResultProvider(stored.id)`.

## 4. Packages (latest stable, checked on pub.dev)
| Package | Version | Why |
|---|---|---|
| — | — | None new |

## 5. Tasks
IDs confirmed by the Project Manager at Gate 1 (2026-11-16); the board is `docs/TASKS.md`.

| ID | Task | Covers AC | Depends on | Status |
|---|---|---|---|---|
| T-300 | **Pure model.** `HomeSummary`, `TodayLine.moneyIn`; unit tests with literals from examples A (19,37,000 left, 2,00,000 saved...), S (−1,20,000; panel; ₹350 overspent after ₹150), M (₹6,900; latest change 13 Nov), F (money left, `startedLate`), target row, zero spendable, refunds (net negative), rounding toward zero (19,37,050 → `₹19,370`, −1,20,050 → `−₹1,200`), progress rule edges, cover sub-line; 100% branch coverage | AC-2, 3, 5 (kinds), 6, 7, 8, 9, 10, 11, 12 (values) | F-006, T-308, T-309 | To do |
| T-301 | **`homeViewProvider` and states.** `HomeView`, the `line == null` rule, loading placeholder state (never a false ₹0), load error with **Try again** (invalidates the same four providers as today) | AC-1 (states), AC-16 | T-300, F-008 T-213 | To do |
| T-302 | **Summary card.** Hero (negative: ◆ and caption), progress rule, day line, late-start caption, **F-017 strip slot**, shortfall / zero panel, budget-changed line, ledger with `LedgerRow`, savings-pot sub-line, `Month statement` row, ⋮ menu with `Edit this month`; count-up; help (i) on every figure from home-summary §12; stacked ledger above 1.3x | AC-1, 2, 3, 6, 7, 8 (screen), 9, 10, 12, 17, 18 | T-300, T-301, F-017 T-361, T-313 (Gate 2) | To do |
| T-303 | **Today card.** Extract `TodayResultLine` (F-009 regression first), build `HomeTodayCard` (header `Today · Fri, 13 Nov`, chevron, whole-card press, refunds line, one-sentence semantics, cross-fade at midnight) | AC-4, 5, 11, 14 (today), 17, 18 | T-300, T-301 | To do |
| T-304 | **Collapsed row.** Scroll listener, 56 dp pinned row, negative variant, tap to top, hidden above 1.3x and in landscape, semantics `₹19,370 left this month, ₹830 a day` | AC-15 | T-302 | To do |
| T-305 | **Home assembly.** Replace `ThisMonthCard`, slivers, `NewMonthCard` move, calendar slot, F-008 test updates (`home_month_states_test.dart`), delete dead strings and file; `hint.calendar.v1` is hosted by F-011 | AC-1, AC-13, AC-16 | T-301…T-304 | To do |
| T-306 | **Navigation wiring.** `openDayDetails` for the Today card (needs F-012 T-343/T-345), `monthStatementLauncherProvider` for `Month statement` and `See month statement` (needs F-014's route) | AC-8 (opens F-014), AC-14 | T-302, T-303, F-012 T-345, F-014's statement route (D-077: built against the seam, wired when F-014 exists; blocks the Phase 3 commit) | To do |
| T-307 | **Sweeps and speed.** Four themes x text 1.0 and 2.0 x small phone and landscape 640x360 for examples A and S; TalkBack semantics order (home-summary §11); `integration_test/home_500_test.dart` | AC-18, AC-19 | T-305 | To do |

## 6. Acceptance criteria coverage
Test case IDs are the Tester's (`tests/F-010-home-summary.md`, section 2.4), re-mapped by the Project Manager at Gate 1 on 2026-11-16. The earlier proposed slots (`TC-010-nn` = AC-nn) are retired. Edge cases of the doc section 4 are TC-010-44 (10 crore), -45 (first day), -46 (last day), -47 (left exactly 0), -19b (several changes), -48 (paise only), -49 (change removes shortfall), -50 (device date back) and -51 (refund bigger than all spends).

| AC | Built in task | Proved by test cases (Tester IDs) |
|---|---|---|
| AC-1 Layout replaces This month card; `Edit this month` in the menu | T-302, T-305 | TC-010-01, -02, -58 |
| AC-2 Example A figures | T-300, T-302, T-303 | TC-010-03, -04, -05, -45, -47, -48, -52 |
| AC-3 Cover updates the summary live | T-300, T-302 (needs F-012) | TC-010-06, -07 |
| AC-4 Midnight (D-039) | T-303 (ring check needs F-011 T-326) | TC-010-08, -54, -56 |
| AC-5 Today card results a to e | T-300, T-303 | TC-010-09, -10 |
| AC-6 Shortfall month (S), panel on 5 Nov, 20 Nov, 4 Dec; 350 after 150 | T-300, T-302 | TC-010-11, -12, -13, -14, -47 |
| AC-7 Zero spendable | T-300, T-302 | TC-010-15 |
| AC-8 Mid-month change (M), statement link | T-300, T-302, T-306 | TC-010-16, -17, -18, -19, -49 |
| AC-9 Mid-month first month, late setup, still to pay | T-300, T-302 | TC-010-20, -21, -22 |
| AC-10 Target row | T-300, T-302 | TC-010-23, -24 |
| AC-11 Refunds | T-300, T-303 | TC-010-25, -26, -27, -51 |
| AC-12 Rounding toward zero; all amounts via the formatter | T-300, T-302 | TC-010-28, -29, -30 |
| AC-13 Live updates | T-305 | TC-010-31, -50 |
| AC-14 Navigation | T-303, T-306 | TC-010-32, -53 |
| AC-15 Collapse on scroll (up to 1.3x, portrait) | T-304 | TC-010-33, -34 |
| AC-16 States (a to d), last day, today not budgeted | T-301, T-305 | TC-010-35, -36, -37, -38, -46, -55, -57, -59 (new, T-309) |
| AC-17 Help on every figure | T-302, T-303 | TC-010-39 |
| AC-18 Themes, 2.0x, landscape, TalkBack | T-302, T-303, T-307 | TC-010-40, -41, -42, -44 |
| AC-19 Speed (500 spends, 1 s) | T-307 | TC-010-43 |

## 7. Edge cases & risks
| Case / risk | How it is handled |
|---|---|
| Today outside the budgeted days (clock set back) | `line == null`: Today card and strip left out; summary still shows (`dailyBudget` falls back to the period's first budget); nothing added to totals (F-006 AC-13) |
| Left exactly ₹0 | `₹0`, neutral colour, no ◆ (F-010 §4) |
| Left negative | ◆, `−₹1,200` (U+2212 + U+2060 via formatter), caption; screen reader says `minus` |
| ₹10 crore figures / 2.0x text | Hero and ledger wrap, never truncate; `FittedBox` is not used for amounts; tested with `₹10,00,00,000` |
| Refunds bigger than all spends | `Spent so far` negative, `progressPermille` 0; Left above spendable |
| Two spends of paise only | `Spent so far` shows `₹0` (D-038), accepted |
| Several changes in one month | `latestChangeDay` is the last non-superseded period's start |
| Same-day replaced change | Superseded periods are not counted (engine keeps them with 0 days) |
| Window of the collapse listener | Uses the shell's controller; listener removed in `dispose`; no setState on scroll, only a `ValueNotifier` |
| Rebuild cost | One `monthResultProvider` watched by Home, calendar and Today card; the engine is O(spends). 500 spends are measured (AC-19) |
| Risk: a dead `Month statement` button if F-014 is not built | T-306 is its own task and depends on F-014; the seam defaults to no action only in tests (§9 Q3) |
| Risk: shared `TodayResultLine` extraction breaks F-009 | Extraction is the first commit of T-303; F-009's widget tests (TC-009-09, -10, -39, -40) run before and after |
| Risk: money rule drift | No money rule: values come straight from `totals`, `currentPeriod` and `TodayLine`; `progressPermille` is display only |
| D-060 | Overspent shows `totals.overspent`, which includes today's live overspend; Saved counts days before today (AC-6 pins ₹350) |

## 8. Impact on existing features
- **F-008:** `ThisMonthCard` is replaced (F-008 AC-1). Re-run and update **TC-008-02, -03, -49, -50** and the Home cases of `home_month_states_test.dart`; the shortfall copy moves with it (F-008 AC-8 stays true, TC-008-20 reads Home). `Edit this month` still opens F-008 edit mode (TC-008-20).
- **F-009:** the Today line widget is extracted and shared. Re-run **TC-009-09, -10, -23, -29, -39, -40, -45, -47** and the Transactions sweep. `TodayLine` gains an optional field only.
- **F-003 / F-004:** Home's body changes shape (slivers, stack). Re-run the F-003 shell and tab cases (scroll controller per tab, Home first-time hint TC-004-09, -10) and the help-rule guard TC-004-06/-08.
- **F-002:** tokens only; re-run TC-002 token guard and theme contrast checks if a new token pair is added (none planned).
- **F-006 / F-007:** read-only. Re-run F-007 live-update cases TC-007-11, -12 for the Home consumers.
- **Siblings:** F-017 (strip slot), F-011 (calendar slot, `hint.calendar.v1`), F-012 (Today card and cover live updates), F-014 (statement links), F-016 (refunds line shows what F-016 records).
- Re-run: full suite, `tool/check.ps1`, `tests/REGRESSION.md`, F-001…F-009 Regression-yes cases.

## 9. Open questions
1. **Project Manager:** shell sequencing of `home_tab.dart`, `today_line_view.dart` and `transactions_tab.dart`: F-010, F-011 and F-012 all touch Home or the Today line. Suggested order: T-303 extraction first, then T-300/T-301, then the three feature branches. One Developer owns `home_tab.dart` at a time.
2. **Project Manager (open item 5, F-009 editor):** F-010 does not touch the editor. The Today card only opens F-012. The editor order is in `plans/F-012-day-details.md` §9.
3. **Project Manager:** F-010 T-306 needs F-012 and F-014 screens. If F-014 is planned later, ship the link only when F-014 exists (one Phase 3 commit, so no user sees a dead button), or hide `Month statement` until then. Please sequence.
4. **Designer / PM:** design-system §7.6 collapsed row is hidden above 1.3x and in landscape (home-summary §14 note 3); AC-15 tests 1.0x only. Confirm no AC change.
5. **Owner decision needed?** **No.** No money rule changes, no permission, no network. Overspent including today (D-060) is already decided. Display of the progress rule and ₹0 without marks are design choices.
6. **Open item 6 (savings repository delete):** not used by F-010; F-012 owns it.

## 10. Project Manager review *(Gate 1 — cross-check of doc + plan + test cases)*
**Verdict:** **Approved** (Project Manager A, 2026-11-16). The Must fix points 1 to 4 are done by PM edits or assigned (T-308, T-309); T-300 starts after T-308 and T-309. Decisions D-073 to D-079 (`docs/DECISIONS.md`). No Owner decision is needed for this feature. Build tracks: this is the F-010 track (with F-017's strip); see `plans/phase-3-overview.md` Build order.

Cross-check:
- [x] Every AC in the feature doc is covered by a task in this plan (19 of 19, section 6)
- [x] Every AC has at least one test case in the test file (19 of 19, tests section 2.4; AC-16 gains TC-010-59)
- [x] Edge cases in the doc appear in both the plan and the test cases (the doc's "device date moved back" had no plan or test line for the Today card: points 2 and 3)
- [x] Approach follows `docs/STANDARDS.md` (pure view model in `domain/`, integer paise, UI only through the formatter, no new package, shared widget extracted instead of copied)
- [x] Latest stable versions / modern APIs used (no new package; Dart 3 sealed `HomeView`, exhaustive switch)

Money rules D-034 to D-062 and D-069 to D-072: untouched. Every figure comes from `totals`, `currentPeriod` and `TodayLine`; `progressPermille` is display only. Phase 3 changes no calculation here.

| # | Point | Type | Resolution |
|---|---|---|---|
| 1 | TC-010-05 and -52 assert a progress fraction of 0.2221 (and 0.0 / 1.0), but the plan models the rule as an integer `progressPermille` (5,53,000 x 1000 ~/ 24,90,000 = 222). The cases cannot pass as written | Must fix (Tester) | T-309: assert `progressPermille` 222, 1000 (spent at least spendable), 1000 (spendable 0 or less), 0 (spent 0 or less) |
| 2 | Doc section 4 says "Home uses today's date as given" but the plan leaves the Today card out when today is not a budgeted day (`line == null`), and no test covers it | Must fix (PM doc, Tester) | Doc section 4 line added (Today card and Safe to spend hidden, summary as the engine gives it, D-077). T-309: new TC-010-59 (F12 with the device date set back to 8 Nov, and A13 set back to 2 Nov: no Today card, no strip, no exception) |
| 3 | The plan's section 6 used proposed TC slots | Must fix (Developer, done by PM) | Section 6 above is re-mapped to the Tester's IDs |
| 4 | The plan has no task for the test helpers the cases need (`seedExampleA/M/F`, `addMoneyInTo`, `FakeMoneyStore.readDelay`, `P3Screen` driver, `phase3_screen_sweep_test.dart`) (tests section 0 and note 6) | Must fix (Developer) | New T-308 (shared by F-010, F-011, F-012, F-017); T-300 depends on it |
| 5 | Q3: F-010 T-306 sequencing with F-014; `Month statement` must not ship dead | Decision (D-077) | T-306 waits for F-014's statement route. T-302 builds the `Month statement` row and the `See month statement` line against `monthStatementLauncherProvider`; they are not hidden (TC-010-32 stays); tests use a route stub. F-010 is not Done and the Phase 3 commit and Gate 5 are blocked until T-306 is wired. The same rule applies to F-012's `Budget changed on this day` notice |
| 6 | Q4: pinned row hidden above 1.3x and in landscape; AC-15 tests 1.0x only | Decision (D-077) | Accepted. AC-15 amended in the doc; TC-010-34 proves the absence at 2.0x and in landscape |
| 7 | Q1: three features touch Home and the Today line | Decision | Order: T-303 extraction first (F-009 cases TC-009-09, -10, -39, -40 before and after), then T-300 and T-301, then T-302 to T-305. F-010 T-305 owns `home_tab.dart`; F-011 T-326 and F-012 T-345 edit it only after T-305 is merged. One Developer owns the file at a time |
| 8 | Q2 and Q6: the F-009 editor and the savings delete | Decision | F-010 does not touch either. Editor order is D-074; the delete is F-012 T-341 (D-078) |
| 9 | Q5: Owner decision needed? | Decision | No. Agreed: no money rule, no permission, no network. Overspent including today is D-060 |
| 10 | F-008 Home cases (TC-008-02, -03, -12, -20, -21, -24, -28) change when T-305 lands (tests section 2.1) | Must fix (Tester, at T-305) | T-312: retire with a note and add new IDs, never reuse an ID; TC-008-01 and -49 unchanged |
| 11 | TC-010-08 also checks the calendar's today ring (F-011) | Nice to have | Runs fully after F-011 T-326; until then the ring check uses the calendar stub |
| 12 | F-010 section 2.5 ASCII drew `Saved this month ● ₹0` but section 5 and design H-3 say no mark on a zero | Nice to have | Fixed in the doc by the PM |
| 13 | TC-010-48 reads `spent ₹0 · ₹829 left today` (both round down, D-038) | Nice to have | Accepted as correct by the rules; no Designer change |
| 14 | If the help-rule guard (TC-004-08) flags `showMenu`, add a core `BudgetMenuButton` | Nice to have | Developer's call inside T-302 |
| 15 | TC-010-49 values are the Tester's hand derivation | Nice to have | Confirmed at the first run: the engine wins and the case is corrected (tests section 2.3 note 1) |

## 11. Implementation notes *(Developer, filled in during the build)*
Deviations from the plan and why (each approved by the Project Manager).

**T-492 (Developer, 2026-11-23, test-only).** `home_500_test.dart` measures from before `pumpWidget` in 16 ms frames until `₹18,652` and `₹6,247` show (it printed 0 ms before). Profile worst of 5: 190 ms (97-190), limit 1000 ms kept (`dev-t492-profile-home_500.log`).

**B-006 (Developer 1, 2026-11-23).** `ChunkedText` (`home_layout.dart`): a line made of chunks; a chunk is kept whole (non-breaking spaces) while it fits one line, else it breaks between its words, so a word or amount is never split and the designed break (after `·`) wins. Used by the savings-pot sub-line and the Today card heading (`Today ·` + date). The heading row also lost a `Spacer` that halved the heading's width. New tests carry the existing ID `TC-010-60` (`test/features/home/home_line_breaks_test.dart`, real fonts); both shown to fail with the fix reverted.

**T-308 (shared harness) and T-389 (shared fixtures), built 2026-11-16 by the foundations Developer; no app code.**
- `FakeMoneyStore.watch` is no longer an `async*` generator: a cancel of such a stream waits for the next change, which hung `addTearDown(sub.cancel)`. Behaviour of the existing cases is unchanged (full suite green).
- `readDelay`, `readFailsFor(monthId)` and `delayReadsOf(monthId)` hold or fail the reads of one month (TC-010-37, TC-011-49, -50). `addMoneyInTo` sits in `transactions_harness.dart` beside `addSpendTo`.
- The named data sets (A13, A13c300, S8, F12, OCT-NOV, P250, W3, R16, ...) are defined once in `test/helpers/phase3_fixtures.dart`; `phase3_data.dart` only seeds them into a store (`storeFor`, `seedFixture`, `seedExampleA/M/F`).
- **M20 (orchestrator ruling):** `m20` and `m20c` are the F-013 / F-014 seed (Saved 2,11,558, Overspent 53,778, pot 1,91,558, Left 6,90,000, cover 20,000 on 6 Nov: the only day of that seed a cover fits, 8 Nov is on budget). The F-010 file's own M20 (Saved 1,85,668) is kept as `m20F010` / `m20cF010` only so the Tester can re-base TC-010-16, -17, -18. T-300's `m20` literals must be the canonical ones.
- `f12` (F-010) and `fixtureF` (F-013 / F-016) are different spends on the same month; `octNov` (F-011) and `fixtureO1` (F-013) are different Octobers.
- `P3Screen` has the 16 Home states that exist without new screens; `HintId.calendar` state, the other tracks' states and the F-010 sweep body are added with their screens.

**Track A build (Developer A, 2026-11-19): T-300 to T-305 and T-307 built, status Code review; T-306 open (see its row).**
- **Files.** Domain: `home_summary.dart` (`HomeSummary.from`), `today_line.dart` (`moneyIn`, `hasRefunds`). App: `core/widgets/today_result_line.dart` (extracted `_Line`, shared by `TodayLineView` and Home; F-009 cases TC-009-09, -10, -39, -40 and the Transactions sweep run green before and after), `core/copy/home_copy.dart`, `core/format/date_format.dart` (`formatCompactRange`, `1 – 30 Nov`), `features/home/home_state.dart` (`HomeView`, `homeViewProvider`), `features/home/home_tab.dart`, `features/home/widgets/` (`summary_card`, `summary_hero`, `summary_ledger`, `home_ledger_row`, `notice_panel`, `budget_changed_line`, `home_today_card`, `collapsed_summary_row`, `home_loading`, `new_month_card`, `counting_amount`, `home_layout`). `this_month_card.dart` is deleted; `MonthSetupCopy` lost the six strings no screen uses.
- **Tests.** `home_summary_test.dart` (18), `home_summary_card_test.dart`, `home_today_card_test.dart`, `home_collapsed_row_test.dart`, `home_states_test.dart`, `home_month_states_test.dart` (TC-008-57 to -61 replace the retired F-008 Home cases; TC-008-62 is in the sweep), `test/copy/home_copy_test.dart`, `phase3_screen_sweep_test.dart` (TC-010-40, -41 by card test, TC-008-62), `money_format_only_test.dart` (TC-010-30), `integration_test/home_500_test.dart` (TC-010-43, written and analysed, **not run**: no emulator was running).
- **Deviation 1 (hero fit).** The hero amount sits in a `FittedBox(scaleDown)` so `₹10,00,00,000` and 2.0x text never truncate, split or overflow on a 360 dp phone (plan §1 said no FittedBox for amounts; a one-line figure at 80 sp cannot otherwise fit 280 dp). Every other amount is plain `Text`.
- **Deviation 2 (pinned row layout).** The pinned row is not an overlay: it takes its own space above the page (and covers the status bar), so a row scrolled into view by a screen reader is never hidden under it. It is measured in scroll offsets after the frame (a listener fires before layout). Plan §1 item 6 said a `Stack`.
- **Deviation 3 (display rules inside `HomeSummary`).** `isOver` is Left of at most −₹1 (a Left of −99 paise reads `₹0`, never `−₹0`, D-050); a ₹0 Saved or Overspent has no mark; progress is full when nothing is budgeted or spent is at least the budget, checked before the empty case.
- **Deviation 4 (Tester's numbers corrected to the engine, no money rule changed).** TC-010-48: on Today(9 Nov) Saved is `₹3,320` (four ended days), not `₹0`. TC-010-59 (a), (b): spends dated after the device date are in no total (F-006 AC-13), so Spent so far is `₹0` and Left `₹24,900`, not `₹1,900` / `₹5,530`. TC-010-59 (c) and TC-017-36 (c): Today(5 Dec) with December not set up is the new-month card (TC-010-36), not an unbudgeted day. The Tester should correct the case text.
- **Deviation 5 (day line for example M).** The day line uses `1 – 30 Nov` inside one month (design system §7.6, TC-010-16); `formatRange` is kept for two-month ranges. The statement track keeps its own private copy of the same rule.
- **Deviation 6 (ledger row).** One-line rows use a `Wrap` so a very large amount drops under its label instead of overflowing.
- **T-306 state.** `Month statement` and `See month statement` go through `openMonthStatement` (the T-405 seam) and are never hidden; the Today card opens `openDayDetails` (the seam in `features/day_details/open_day_details.dart`). Both are tested through launcher stubs (TC-010-19, -32, -53). Open until F-014's route and F-012's route replace the seam defaults and TC-010-19/-32 are re-run against them.
- **Open for others.** `home_tab.dart` now also hosts F-011's `CalendarSection` (added by Track B); the calendar hint state (TC-010-57) waits for `HintId.calendar`. TC-010-42 (TalkBack) is manual on the emulator.

**Gate 3 fixes (Developer A, 2026-11-19).**
- **T-302.** Day line: the only break is after the dot (` · ` becomes ` · `) and a word joiner follows the en dash (Flutter breaks after an en dash even before a non-breaking space). Test `TC-010-41 day line breaks only at the dot at 2.0x` in `home_day_line_test.dart`, shown to fail on the reverted code. Deviation from the review text: its literal `' · '` replacement lets the line also break before the dot.
- **T-306.** `TC-010-19` and `TC-010-32` each have one test without a launcher override (real `MonthStatementScreen` and `DayDetailsScreen`, Back keeps the scroll offset).
- **T-307.** 60 of 60 clean runs of `homeCollapsedRow` (four themes, x1.0 and x2.0), no code change; Ready for test.
