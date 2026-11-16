# Plan — F-009: Manual transactions

| | |
|---|---|
| **Feature doc** | [`docs/features/F-009-manual-transactions.md`](../docs/features/F-009-manual-transactions.md) (final spec, 19 ACs) |
| **Test cases** | [`tests/F-009-manual-transactions.md`](../tests/F-009-manual-transactions.md) (Approved at Gate 1; the Tester's TC IDs are used in §6) |
| **Design** | `docs/design/screens/transactions.md` (tab states, Today line, list, Add/Edit spend, dialogs): written and **approved at Gate 2** (`docs/reviews/design-phase-2.md`): full-screen editor, inline new-month card + decision sheet, decision sheets instead of dialogs |
| **Inputs** | D-002, D-034, D-036 … D-040; F-006 / F-007 / F-008 plans; `docs/reviews/phase-2-lookahead.md` #5, #12, #16 |
| **Author** | Developer |
| **Status** | Approved (Gate 1, Project Manager, 2026-11-10) |

## 1. Approach
The Transactions tab and an Add/Edit spend screen sit on the shared Phase 2 state:
- `currentMonthStateProvider` and `todayProvider` (F-008 T-213);
- `monthResultProvider` (F-007 T-209, the F-006 engine output);
- `TransactionRepository` (F-007).

1. **No money arithmetic in the UI.** Both pieces below are **pure Dart** in `domain/budget/`, unit-tested to the paisa:
   - the **Today line** model (`TodayLine.from(MonthResult, today)` → budget, spent, result kind `leftToday` / `onBudget` / `overspent`, shortfall);
   - the **day grouping** (`groupSpendsByDay(spends, today)` → newest day first, newest entry first by `createdAt`, day totals).

   Widgets only format them with `formatRupees` and `date_format.dart` (F-008 T-212).
2. **The list is lazy.** A `CustomScrollView` holds the Today line plus a `SliverList.builder` over a flattened list of day headers and rows. 500 spends build only the visible rows (AC-15: list in < 1 s). The headings `Today` / `Yesterday` / `Mon, 9 Nov` come from the injected today.
3. **One editor screen** `SpendEditorScreen(mode: add | edit(spend))`, pushed with `Navigator.push`, with a draft + controller, as in F-008:
   - **amount:** `parseAmount` (shared), range > ₹0 and ≤ ₹10 crore;
   - **date:** `showDatePicker` with `firstDate = max(month start, first budgeted day)`, `lastDate = today` (edit of a spend dated after today after a clock change: `lastDate` = that spend's date, D-048), `initialDate = today` (edit: the spend's date), so no future dates and no not-budgeted days (AC-4). Calendar dates are converted to a local `DateTime(y, m, d)` **only** for the picker;
   - **note:** `maxLength: 100` with `MaxLengthEnforcement.enforced`. Flutter counts grapheme clusters, so emoji and Hindi count as the user sees them. A counter `<n>/100` is shown from 80 characters on.
   - **Save:** `isSaving` guard (double tap = one record), `StorageException` → §5 save error, input kept.
   - **Delete:** confirmation dialog with amount and date.
   - **Back with changes:** discard dialog (`PopScope`).
4. **The D-040 note comes from the repository.** `add` / `update` / `delete` return `SpendWriteOutcome(reductions)` (F-007 T-209 runs the engine inside the write transaction and persists the reduced covers).
   - If `reductions` is not empty, the tab shows **one** cover-taken-back decision sheet with one paragraph per reduction, newest cover first (full or partial copy from §5), and **OK**.
   - With no reductions, nothing is shown (AC-19).
5. **No category picker in Phase 2** (AC-14 → N/A at Gate 1). Automatic categories arrive in Phase 4 with their own list and memory. A manual picker now would be throwaway UI and a list to keep in sync. The `category` column exists (nullable, F-007) and stays empty.
6. **New month not set up** (`MonthState.NewMonthStarted`): the FAB opens the "Set up your new month first" message with **Set up this month** (F-008). The previous month's list stays visible, read-only.
7. **Widget tests use the fake repositories** (F-007 T-209) with a fixed today. Only the integration test touches Drift.

## 2. Files / modules
| Path | Add / Change | What |
|---|---|---|
| `app/lib/domain/budget/today_line.dart` | Add | `TodayLine` + `TodayResultKind` |
| `app/lib/domain/budget/spend_groups.dart` | Add | `groupSpendsByDay`, `DayGroup(date, label kind today/yesterday/other, total, spends)` |
| `app/lib/domain/budget/spend_draft.dart` | Add | `SpendDraft` (amount text, date, note), `validate`, `isChangedFrom`, `toSpend` |
| `app/lib/features/transactions/transactions_tab.dart` | Change | `MonthState` switch: no month → `Set up your month first` + button (no FAB); current month → Today line + list or `No spends yet this month` + Add spend; new month started → previous month list + blocked FAB |
| `app/lib/features/transactions/today_line_view.dart` | Add | One `Semantics` sentence ("Today: budget ₹830, spent ₹250, ₹580 left today"), colour **plus** words (saved/overspent tokens), wraps at text scale 2.0 and never splits an amount (` ` inside amounts); shortfall line; (i) per §5 |
| `app/lib/features/transactions/spend_list.dart` | Add | Slivers, day headers with totals, rows (`<amount>, <note or No note>, <date>` as the row's semantics label) |
| `app/lib/features/transactions/spend_editor_screen.dart`, `spend_editor_controller.dart` | Add | Add/Edit, date picker limits, note counter, Save / Save changes / Delete, discard guard, snackbars `Spend added/updated/deleted` |
| `app/lib/features/transactions/widgets/delete_spend_sheet.dart`, `cover_taken_back_sheet.dart`, `discard_spend_sheet.dart`, `new_month_blocked_sheet.dart`, `new_month_card.dart` | Add | Decision sheets through the shared `showDecisionSheet` (T-212c; no `AlertDialog`) and the inline new-month card (`transactions.md` §6.4, §9) |
| `app/lib/core/copy/transactions_copy.dart` | Add | All F-009 §5 strings |
| `app/lib/core/copy/screen_copy.dart` | Change | Transactions placeholder copy removed (F-003 impact) |
| `app/test/domain/budget/today_line_test.dart`, `spend_groups_test.dart`, `spend_draft_test.dart` | Add | `TC-009-NN …` unit tests (worked example steps 1–6 to the paisa) |
| `app/test/features/transactions/*_test.dart` | Add | Widget tests on fakes: states, add/edit/delete, limits, discard, failure, note dialog, four themes, text scale 2.0, landscape |
| `app/integration_test/transactions_500_test.dart` | Add | 500 spends on the real Drift file: reopen, list shown < 1 s, scroll to the oldest day (AC-15, F-007 AC-14) |

## 3. Data model / database changes
None beyond F-007:
- **Add** inserts `transactions` (`day`, `amount_paise`, `note`, `source = 'manual'`, `category = NULL`, `created_at = edited_at = now`).
- **Edit** updates `day` / `amount_paise` / `note` / `edited_at`.
- **Delete** is a real delete (F-007 §4).

Each write runs the engine and persists the D-040 cover changes in the same transaction (F-007 T-209).

## 4. Packages (latest stable, checked on pub.dev 2026-11-10)
| Package | Version | Why |
|---|---|---|
| — | — | None new. Uses the shared formatters (no `intl`, D-070), and `integration_test` (SDK, added in T-206) |

## 5. Tasks
All F-009 tasks wait for **Phase 1 approval** (they change `transactions_tab.dart` and `screen_copy.dart`, and need T-206's packages). The pure-Dart part of T-217 could start early if the PM agrees (F-008 plan §9 Q2 applies equally).

| ID | Task | Covers AC | Depends on | Status |
|---|---|---|---|---|
| T-217 | **Pure models.** `TodayLine`, `groupSpendsByDay`, `SpendDraft` + validation; unit tests incl. the §2 worked example, shortfall month, post-change budget (₹630), the midnight move into the pot | AC-3 (rules), AC-6 (numbers), AC-9, AC-17, AC-18 | T-204, T-212a (**may start now**, D-052) | Code review |
| T-218 | **Transactions tab UI** per the Designer's spec: three states, Today line, lazy grouped list, FAB, new-month block, cover-taken-back dialog host; four themes, text scale 2.0, landscape, TalkBack labels | AC-1, AC-6 (screen), AC-9, AC-13, AC-16, AC-17, AC-19 (sheet) | T-217, T-213, T-209, T-212c | Code review |
| T-219 | **Spend editor** (full screen, `transactions.md` §8, Gate 2). Add/Edit/Delete, date limits (incl. mid-month first budgeted day), note limit/counter/emoji/Hindi, once-per-tap, save failure, discard sheets, Save in the action dock (portrait ≤ 1.3×), snackbars; edit/delete passing reductions to the tab | AC-2, AC-3, AC-4, AC-5, AC-7, AC-8, AC-10, AC-11, AC-12, AC-19 | T-218 | Code review |
| T-220 | **500-spend integration test + phase hand-over.** `integration_test/transactions_500_test.dart` on the emulator; full `check.ps1`; list for the Tester's full regression (F-001 … F-009) | AC-15 | T-219, F-007 T-211 | Code review |

## 6. Acceptance criteria coverage
TC IDs are the Tester's (`tests/F-009-manual-transactions.md` §2.4), reconciled at Gate 1.

| AC | Built in task | Proved by test cases |
|---|---|---|
| AC-1 Tab states | T-218 | TC-009-01, -02, -41, -44 |
| AC-2 Add a spend | T-219 | TC-009-03, -35, -42, -45 |
| AC-3 Amount validation | T-212a, T-217, T-219 | TC-009-04, -05, -33, -34 |
| AC-4 Date limits (incl. D-034) | T-217, T-219 | TC-009-06, -07, -30, -38 |
| AC-5 Note (100, counter, emoji/Hindi) | T-219 | TC-009-08 |
| AC-6 Today line — worked example | T-217, T-218 | TC-009-09, -10, -29, -39, -40, -45 |
| AC-7 Edit | T-219 | TC-009-11, -38 |
| AC-8 Delete with confirmation | T-219 | TC-009-12, -36, -37 |
| AC-9 List order and grouping | T-217, T-218 | TC-009-13, -32 |
| AC-10 Past-day edits reach the engine (over-covered day) | T-219 (+ F-007 T-209 repository) | TC-009-14 |
| AC-11 Once per tap; save failure | T-219 | TC-009-15, -48 |
| AC-12 Discard | T-219 | TC-009-16, -43 |
| AC-13 New month not set up | T-218 | TC-009-17 |
| AC-14 Category | **N/A in Phase 2** (Gate 1) | TC-009-18 N/A (category empty is checked in TC-009-03) |
| AC-15 Persistence and speed (500) | T-220 | TC-009-19, -31 |
| AC-16 Help, themes, large text, accessibility | T-212c, T-218, T-219 | TC-009-20, -21, -22, -33, -46 |
| AC-17 Today line after a change or shortfall | T-217, T-218 | TC-009-23, -47 |
| AC-18 Today's leftover and the pot (D-039) | T-217 | TC-009-24, -29 |
| AC-19 Cover taken back, with a note (D-040) | T-218, T-219 (+ F-007 T-209) | TC-009-25, -26, -27, -28 |

## 7. Edge cases & risks
| Case / risk | How it is handled |
|---|---|
| Midnight passes while open | `todayProvider` midnight timer + resume refresh; headings and the Today line rebuild; the editor's default date is read when it opens |
| New date is a new budget month | `MonthState.NewMonthStarted` → AC-13 block |
| Device date set back (a "future" spend) | Stays under its date heading; not in spent-so-far (engine); the add picker has `lastDate = today`; editing that spend allows up to its own date (D-048) |
| Time-zone change | Stored day numbers (F-007 AC-3) |
| 50+ spends on a day / 500 in the month | Lazy slivers; totals from the engine |
| ₹10 crore spend | Accepted; formatter keeps Indian grouping; amounts use ` ` so they never split; layout test at text scale 2.0 |
| ₹0.01 | Accepted (> ₹0), shown as **₹0** (D-038); F-009 §4 corrected at Gate 1 |
| Result less than ₹1 either way | Word from the exact paise, amount `less than ₹1` (D-050) |
| Two identical spends | Both stored (no de-duplication) |
| Spend from a previous month | Not listed; no editing outside the current month |
| Last spend of a day deleted | Group disappears (grouping recomputed) |
| Back on the Delete sheet | Same as Cancel (scrim / back = the safe choice, design system §7.8) |
| Text scale 2.0 | Today line wraps, never truncates; tested |
| Risk: Drift streams in widget tests | Fakes only (look-ahead #5) |
| Risk: the cover note fires for clamped (over-covered) days | The engine reports only pot-driven reductions (F-006 plan §1.6); AC-10 vs AC-19 tests both ways |

## 8. Impact on existing features
- **F-003 (Transactions tab):** the placeholder empty state is replaced. The TC-003 Transactions cases and `empty_tabs_test.dart` are updated with the Tester in T-218.
- **F-004:** the Transactions first-time hint is kept (its wording still fits, per the spec). Every new control uses `LabelDescription`/`InfoButton`/tooltips.
- **F-002:** tokens only; saved/overspent colours from `BudgetColors`.
- **F-008:** shares `amount_field`, `parseAmount`, `formatRupees`, `todayProvider`, `currentMonthStateProvider`. A change there re-runs the F-009 tests.
- Re-run: full suite, `check.ps1`, `tests/REGRESSION.md`, F-002/F-003/F-004 Regression-yes cases.

## 9. Open questions
1. **PM / Product Manager:** the §4 edge case "₹0.01 … shown as ₹0.01" conflicts with D-038 and F-008 AC-19 (99 paise → `₹0`). The plan follows D-038 (`₹0` in the list and Today line; the exact paise are stored). Please correct the spec line, or confirm an exception for amounts less than ₹1. Showing paise would be a money-display change, i.e. an Owner decision.
2. **PM:** confirm that AC-14 (category) is N/A for Phase 2 (§1.5).
3. **Designer:** the Add/Edit spend screen as a full screen (plan default: better with the keyboard and the date picker at text scale 2.0) or a sheet. The spec allows either.
4. **PM:** the new-month block (AC-13) shows a sheet with **Set up this month**. Is that the right component, or should it be an inline banner above the list? Designer to decide in the spec.

*Answered at Gate 1 / Gate 2 (PM, 2026-11-10):* Q1 the spec line is corrected: ₹0.01 shows as ₹0 (D-038; no exception). Q2 AC-14 is **N/A** in Phase 2. Q3 Designer: **full screen** (`transactions.md` §2). Q4 Designer: **both** — an inline card in place of the Today card plus a decision sheet when Add spend is tapped (`transactions.md` §6.4).

## 10. Project Manager review *(Gate 1 — cross-check of doc + plan + test cases)*
**Verdict:** **Approved** (Project Manager, 2026-11-10). T-217 (pure models) may start now (after T-204 and T-212a); T-218 … T-220 wait for Phase 1 approval.

Cross-check:
- [x] Every AC in the feature doc is covered by a task in this plan (AC-1 … AC-19 → T-217 … T-220; AC-14 N/A)
- [x] Every AC has at least one test case in the test file (TC-009-01 … -48; TC-009-18 N/A)
- [x] Edge cases in the doc appear in both the plan and the test cases (midnight, new budget month, device date set back, time zone, 50+ spends a day, ₹10 crore, ₹0.01, identical spends, previous month, last spend of a day, back on Delete, text scale 2.0)
- [x] Approach follows `docs/STANDARDS.md` (Today line and grouping in pure Dart, no money arithmetic in widgets, fakes in widget tests, lazy slivers)
- [x] Latest stable versions / modern APIs used (`SliverList.builder`, `MaxLengthEnforcement.enforced` with grapheme counting, `PopScope`, `showDatePicker` with `calendarOnly`)

| # | Point | Type | Resolution |
|---|---|---|---|
| 1 | **₹0.01 display.** D-038 applies with no exception: shown ₹0, stored 1 paisa, exact value in the edit field. F-009 §4 corrected. | Must fix → done by PM | F-009 §4; TC-009-34. |
| 2 | **Category picker** → AC-14 N/A for Phase 2 (throwaway UI before Phase 4's automatic categories); the nullable column stays. | Resolved | F-009 AC-14; TC-009-18 N/A. |
| 3 | **D-047 money in.** Phase 2 scope: engine (F-006 AC-25) and storage (F-007 AC-19) support it; **no manual "money in" entry** in Phase 2 (D-051). Reason: the Owner's sign-off question can be answered with spends; a second entry type adds a toggle, copy and tests to every editor state for a case SMS credits will bring in Phase 4. F-009 adds no AC; its list shows spends only. | Resolved (D-051) | F-009 §6. |
| 4 | **Under ₹1 results.** `₹0 left today` / `overspent ₹0` read as bugs. The word follows the exact paise and the amount reads `less than ₹1` (`less than ₹1 left today`, `overspent less than ₹1`). Every number shown is still whole rupees rounded down; only the sub-rupee difference gets words. | Resolved (D-050) | F-009 §2.2, §5; TC-009-40. |
| 5 | **Two covers taken back by one save.** One sheet, one paragraph per cover, newest first (the design's "one paragraph per reduction"). | Resolved (D-048) | F-009 §5; TC-009-28. |
| 6 | **Editing a future-dated spend** (after the device date moved back): the edit picker allows up to that spend's own date. | Resolved (D-048) | F-009 §4, plan §1.3; TC-009-30. |
| 7 | **Order within a day:** newest added first; edits never move a row (F-007 point 4). | Resolved (D-048) | F-009 §2.1; TC-009-13. |
| 8 | **No Material dialogs; full-screen editor; inline card + sheet for a new month** — see Gate 2. File names changed to `*_sheet.dart`; tests find sheets by text. | Must fix → done by PM | §2; tests §0. |
| 9 | **Shared widgets** (amount field, decision sheet, action dock) come from T-212c, not from F-008's screen task, so Track 2 does not wait for T-215. | Must fix → done by PM | §5 T-218 deps. |
| 10 | **Nice to have:** quick-amount chips and recent notes (F-009 Suggested additions) — CEO item for Phase 3. | Nice to have | Left with the CEO. |
| 11 | **Nice to have:** the "Numbers check" view (F-009 Suggested additions) would let the Owner check the pot and totals at sign-off; the engine side is T-221. | Nice to have | CEO to decide on the screen; T-221 for the engine dump. |

## 11. Implementation notes *(Developer, filled in during the build)*

### T-217 (Developer, 2026-11-11)
**Built (pure Dart, new files in `app/lib/domain/budget/`, each its own library exported from `budget.dart`, D-059, using the M3 `netSpent` names):** `today_line.dart` (`TodayLine`, `TodayResultKind`), `spend_groups.dart` (`groupSpendsByDay`, `DayGroup`, `DayLabel`), `spend_draft.dart` (`SpendDraft`, `spendDateLimits`, `SpendField`, `SpendProblem`, `SpendError`, `SpendFields`, `maxNoteLength`). `SpendDraft` reuses `parseAmount` and `positiveAmountProblem` from `amount_input.dart` (T-212a).

**Tests** (`test/domain/budget/today_line_test.dart`, `spend_groups_test.dart`, `spend_draft_test.dart`, named by TC ID): TC-009-03, -04, -05, -06, -07, -09, -10, -13, -16, -17, -23, -24, -30, -32, -33, -34, -38, -39, -40, -47. The worked example (steps 1 to 6) is checked to the paisa against the engine; the result words for each state and the under-₹1 edges (99 and 100 paise); a changed period (₹630); a shortfall month; the midnight move into the pot; a past day judged against its own budget. `domain_coverage.ps1`: `today_line` L 15/15 B 8/8, `spend_groups` 25/25 and 10/10, `spend_draft` 45/45 and 23/23. `tool/check.ps1` ALL CHECKS PASSED.

| # | Deviation / decision | Why |
|---|---|---|
| G1 | `TodayLine.from(MonthResult)` takes no `today`: it uses `result.today`. It throws `ArgumentError` when today is not a budgeted day (the tab shows the new-month card then). | The result already carries the `today` it was computed for; a second one could disagree. |
| G2 | `TodayResultKind` has five values: `leftToday`, `leftUnderRupee`, `onBudget`, `overspentUnderRupee`, `overspent` (D-050). The line also exposes `budget`, `netSpent`, `result`, `amount` (result without its sign), `shortfall` and `hasShortfall`. "Spent" is the net spend (D-047). | One exhaustive switch in the widget; the word follows the exact paise. |
| G3 | `groupSpendsByDay(spends, today)` returns records `DayGroup(date, label, total, spends)`. The total is spends minus money in (D-047; there is no manual money in in Phase 2, D-051, so it equals the sum of the spends today). Order: newest day first, then newest `createdAt`, then higher id. | Stable, and an edit never moves a row (D-048). |
| G4 | `SpendDraft.toFields(limits)` returns `(amount, date, note)` instead of a `Spend`. The note is trimmed, null when empty. | The engine's `Spend` has no note, and the id and times belong to the repository. |
| G5 | `spendDateLimits(month, firstBudgetedDay, today, editedSpendDate)` gives the picker's first and last day: first = first budgeted day (D-034), last = today, or the spend's own date when it is later (D-048), never after the month's end. `SpendDraft.validate(limits)` names `beforeFirstDay` / `afterLastDay`. | AC-4, TC-009-30, -38. |
| G6 | The draft does not count note characters (100). `maxNoteLength` is exported and the text field enforces it. | Same reason as F-008 S5: graphemes cannot be counted in pure Dart without `package:characters`. |

**Project Manager, Gate 3 (2026-11-11, `docs/reviews/code-phase-2.md` "Re-review"):** T-217 approved. **G1, G2, G3, G4, G5, G6 approved.** G1: T-218 checks the month state (new-month card) before `TodayLine.from`. G6: T-219 owns TC-009-08's 101st-character case as a widget test with the Hindi and emoji strings. Screen copy follows D-055 (`less than ₹1`), not the older "under ₹1" in D-050.

### T-218, T-219, T-220 (Developer C, 2026-11-13)
**Built:** the Transactions tab (all states of `transactions.md` section 6, the Today card with the counting result, the lazy day list, the new-month card and sheet, the load error), the full-screen editor with Add, Edit and Delete, the decision sheets, the cover-taken-back sheet (host: `openSpendEditor` in `spend_editor_flow.dart`), the Add spend button, the date picker theme, and the 500-spend integration test. 42 tests in `app/test/features/transactions/`, plus `integration_test/transactions_500_test.dart` (emulator, TC-009-19). Full suite: 552 pass, 2 fail (F-003 Home cases, Developer B's Home change). `flutter analyze` is clean in everything this task touched; `check.ps1` stops at analyze on B's `month_setup` test files.

| # | Deviation / decision | Why |
|---|---|---|
| C1 | The tab reads B's `currentMonthStateProvider` (it exists now) through `transactionsViewProvider`, a sealed `NoMonthView` / `NewMonthView` / `CurrentMonthView`. `TodayLine.from` is only called in `CurrentMonthView`, and only when today is a budgeted day (G1). The device date set back to before the first budgeted day gives a list with no Today card, no Add spend and read-only rows. | PM condition G1; the set-back case is not in the spec, so this is the safe reading. |
| C2 | **The Add spend button lives in the shell** (`Scaffold.floatingActionButton`, only on the Transactions tab), not inside the tab. | The Scaffold then keeps it above the bar and lifts it over snackbars, as the design asks. `app_shell.dart` has one new line and one import. The button watches the same view state and hides when nothing can be added. |
| C3 | Shared widgets touched, additive only: `TabPage.slivers` (lazy body), `NavTooltip(hint:)` (the close button has tooltip `Close` and hint `Leave without saving`), the date picker theme in `budget_theme.dart`. | Needed by the spec; no existing caller changes. |
| C4 | The list is lazy **per day** (a `SliverList.builder` of day sections), not per row. | One card per day needs its rows together. 55 rows build at once; 500 rows over 30 days open in under a second (TC-009-19). |
| C5 | No `spend_editor_controller.dart`: the form state is small and lives in the screen's `State` on top of `SpendDraft`. | A controller class would only forward calls. |
| C6 | `Set up your month` and `Set up this month` call `monthSetupLauncherProvider`, whose default does nothing until F-008's setup route replaces it. | F-008's screen is not built yet. **T-215 must override it.** |
| C7 | New small texts and behaviours: the date error `Pick a day this month, up to today.` (only reachable after a clock change while the editor is open); the save-failure snackbar is lifted above the dock; the snackbar of the last save is hidden when the next editor opens. | Not in F-009 section 5; they keep Save reachable. |
| C8 | The Today line wraps between its parts; a part such as `spent ₹250 ·` may break between the word and the amount at extreme widths, an amount never splits. The note field is its own widget (`widgets/note_field.dart`), not `BudgetTextField`. | Regular spaces are more robust at 2.0 with a ₹10 crore amount. `BudgetTextField` has no length or line options and Developer B edits it for F-008's name field. |

**Tests worth knowing:** TC-009-08 (G6) types 101 letters, 101 `चा` and 101 emoji families; the field keeps 100 of each (Flutter counts grapheme clusters) and the counter reads `100/100`. TC-009-14 runs on in-memory Drift. TC-009-20 sweeps 16 states x five theme cases x text scale 1.0 and 2.0 (contrast, tap targets, labels, overflow) and landscape in Light and Dim. TC-009-45 (the flow on the device) is not its own integration file: the same steps run on fakes in TC-009-09; the Tester may ask for the device run.

**Not done:** TC-009-22, -31, -43, -46 (Manual, Tester); TC-009-45 on the device (above).

**C6 resolved (Developer D, 2026-11-13).** The launcher is wired to F-008's setup screen (see plan F-008 section 11, U10): `(context, SetupMode)` signature, `FirstSetupMode` / `NewMonthMode(lastMonth)`, double tap opens one screen. The test harness `onSetUpMonth` now receives the mode and, when omitted, the real screen opens. TC-009-01 and TC-009-17 assert the mode; new tests of the real route are named TC-009-01, TC-009-17 and TC-008-49.

**Project Manager, Gate 3 (2026-11-13, `docs/reviews/code-phase-2.md` "Gate 3: F-008 and F-009 screens"):** T-218 and T-220 approved; G1 respected. **T-219 Must fix M1** (money arithmetic and the literal 100 in `cover_taken_back_sheet.dart` move to the engine) **and M2** (the editor close button uses `BudgetIconButton`); G6 met. C1 to C5, C7, C8 approved; **C2** (button in the shell, Transactions only) and **C3** (`TabPage.slivers`, `NavTooltip(hint:)`, date picker theme) approved as additive, no Phase 1 regression found. C6 resolved by T-240, approved. Owner sees the new date-error text (C7); T-241 adds it to the design spec.

**T-219 Gate 3 fixes M1 and M2 (Developer, 2026-11-13).** M1: `CoverReduction` is a record typedef in `domain/budget/month_result.dart`, so the two getters are an extension on it, `CoverReductionCut` (`Paise get cut`, `bool get cutIsUnderRupee`); the record, the engine and the money rules did not change (`tz_matrix.ps1` dump hash still `B30996982B3C37EB...D59E4`). `coverReductionText` now only reads `cut`, `cutIsUnderRupee` and `newAmount.isZero`; texts unchanged, the TC-009-25 to -28 widget tests unchanged. Domain tests `TC-009-25` and `TC-009-27` in `test/domain/budget/savings_pot_test.dart`; `domain_coverage.ps1` 100% lines and branches. M2: the editor close button is now `BudgetIconButton(Icons.close, closeTooltip, closeScreenHint)`; the hand-made `NavTooltip` + `InkResponse` block and the unused `nav_tooltip.dart` import are removed. New test `TC-009-16 the close button shows the focus ring when keyboard focused` in `spend_editor_screen_test.dart` (no ring in touch mode, one ring on keyboard focus); it fails on the old hand-made button (checked by putting the old code back for one run). 3 tests added (2 domain, 1 widget). `tool/check.ps1` ALL CHECKS PASSED. Back to Code review. T-242 nice-to-haves not touched.

**T-219 test-only follow-ups (Developer, 2026-11-13), from the Tester report R1.** (1) The focus-ring widget test is renamed `TC-009-49 the close button shows the focus ring when keyboard focused` (name only). (2) New `TC-009-48 failed edit keeps the input and the old record` in `spend_editor_screen_test.dart`: edit 400 to 270 with `store.failNextWrite = true`; the snackbar `Couldn't save. Please try again.` shows, the editor stays open with `270` and the note, and the stored record is still 40,000 with its note. Proved able to fail by two temporary probes (the failure path clearing the amount field; the fake repository writing the record before it throws), both reverted and checked identical to the saved copies. No app code changed, no bug. +1 test.

### T-250 part (b) and T-243 (Developer, 2026-11-16)
**T-250 (b):** above 1.3x text the first-time tip is placed under the Today card (`transactions_tab.dart`, current-month view with a Today line; same card and copy; at 1.3x and below unchanged). Tests in `test/features/transactions/transactions_tab_test.dart`: `TC-009-46` at 2.0x (Light and Dim, 360 x 640, tip showing, offset 0, bundled fonts for real glyph widths): tip below the card and the Add spend rectangle does not intersect the Today card rectangle; at 1.0x and 1.3x the tip stays above. Probes (reverted): rule switched off failed both assertions separately.
**T-243:** `integration_test/manual_transactions_flow_test.dart` `TC-009-45 add edit and delete spends on the device` (steps 1 - 5 on 9 Nov on a seeded E2 database, Today line after each step, same line after a restart). Emulator-5554: 1 / 1 passed (`docs/reviews/emulator-phase-2/integration-manual-transactions-flow.log`). A wrong expected line made it fail.
