# Plan — F-012: Day details & cover with savings

| | |
|---|---|
| **Feature doc** | [`docs/features/F-012-day-details.md`](../docs/features/F-012-day-details.md) (final spec, 22 ACs) |
| **Test cases** | [`tests/F-012-day-details.md`](../tests/F-012-day-details.md) (written 2026-11-16, TC-012-01 to TC-012-64, authoritative; section 6 re-mapped at Gate 1) |
| **Design** | `docs/design/screens/day-details.md` (full screen, cover card and sheet, Undo and Remove), `transactions.md` (F-009 rows, editor, §9 sheets), design system §7.8 |
| **Inputs** | D-005, D-037, D-038, D-039, D-040, D-046, D-047, D-048 (1), (2), (6), (8), D-050, D-055, D-056 (1), D-059; F-006/F-007/F-009 as built; sibling plans F-010, F-011 |
| **Author** | Developer 1 |
| **Status** | Plan approved (Gate 1, 2026-11-16, Project Manager A; see section 10) |

## 1. Approach
Day details is a full-screen route (`DayDetailsScreen(monthId, date)`) over `monthResultProvider(monthId)`, `monthSpendsProvider(monthId)` and `monthCoversProvider(monthId)`. It is opened from a calendar cell (any month) and from Home's Today card. It adds **no money rule**: the cover uses the engine's `checkCover` and the repository's existing `cover()`.

1. **Pure model, `domain/budget/day_summary.dart`.** `DaySummary.of(MonthResult, CalendarDate)` returns everything the screen shows as exact paise and flags, so no widget does money arithmetic:
   - `status` (engine `DayStatus`), `resultKind` (saved, saved under ₹1, on budget, overspent, overspent under ₹1, plus the live words `left today`, `left under ₹1`), `budget`, `spent` (gross), `moneyIn`, `netSpent`, `covered`, `result`;
   - `isEnded = result.today.isAfter(result.month.end)` (past months and the new-month-due state are read-only, F-012 §2.6);
   - `coverOffer`: `none`, `potEmpty`, or `available(max)`, where `max = min(pot, uncovered overspend)` and `limitedByPot` says which limit applied. Offered only on a budgeted, overspent day (past, or today when `result` is negative, D-048 (2)) of a month that is not over; `potEmpty` when the pot is ₹0 (AC-10);
   - `canRemoveCover` and `coverIds`: the engine's `effectiveCovers` for that day with amount above ₹0, month not over (AC-22: hidden when D-040 cut it to ₹0). Remove acts on **all** the day's stored cover rows (the screen passes every stored cover id of the day, including ₹0 rows, from `monthCoversProvider`);
   - `changeOnThisDay`: the period starting that day (non-superseded, not the first) with its `PeriodChange` list for the `Budget changed on this day: salary ₹40,000 → ₹35,000` line;
   - `isFutureDated` rows (clock set back).
2. **Pure cover form check, `domain/budget/cover_draft.dart`.** `CoverDraft(amountText)` + `validateCover(MonthResult, day, draft)` parses with `parseAmount`, then asks the engine's `checkCover`, and returns `CoverOk(Paise)` or a `CoverProblem` (`missing`, `notPositive`, `badFormat`, `tooLarge`, `exceedsOverspend`, `exceedsPot`, `notOffered`). Because `checkCover` refuses in the D-048 (1) order, "both limits exceeded" gives the **overspend** message automatically (AC-8). The sheet pre-fill is `amountInputText(max)` (`300`, `47.78`, `0.40`); the caption is chosen from `max` versus the typed amount. Pure, unit-tested.
3. **Rows.** `spendsOnDay(spends, date)` is added to `domain/budget/spend_groups.dart`: newest **added** first (`createdAt`, then id; an edit never moves a row, D-048 (8)). It reuses the ordering already used by `groupSpendsByDay`. Rows reuse F-009's row look; the existing `SpendListSliver` row widget is made public as `SpendRow` (refund rows add the `Refund` second line and `+₹500`, F-016's switch decides the direction; rows have no category chip here).
4. **F-009 flows are reused, not copied.**
   - `openSpendEditor` (in `spend_editor_flow.dart`) gets two optional parameters: `date` (the editor opens on that day, AC-12) and `fromDay` (the day screen that opened it). The editor screen gets `initialDate` and its result gets the saved `date`. When `result.date != fromDay` the snackbar reads `Spend moved to <weekday, d MMM>` (AC-13). The D-040 `Savings pot updated` sheet is the same `showCoverTakenBackSheet` (AC-14).
   - Day details only edits **the current month**, where `transactionsViewProvider` already resolves the same stored month, so `openSpendEditor` keeps resolving the month from it. Read-only days never open the editor.
5. **Cover sheet** via `showBudgetSheet` (D-031): title `Cover Wed, 11 Nov`, the line `Overspent ₹300 · Savings pot ₹2,000` (`less than ₹1` variants), the shared `AmountField` (medium, pre-filled, not focused on open), the caption, errors shown on Cover and re-checked as the user types, **Cover** (Primary, with a progress state, a second tap does nothing: `_saving` guard as in the F-009 editor) and **Cancel**. A save failure shows `Couldn't save. Please try again.` over the sheet and keeps the amount (AC-11).
6. **Undo and Remove (D-056 (1)).** After a cover the snackbar `₹300 covered from your savings` has **Undo** (6 s, stays while TalkBack is on). Undo calls `removeCovers({coverId})`; `Remove` opens a `showDecisionSheet` (`Remove cover` destructive first, `Keep it`) and calls `removeCovers(allIdsOfTheDay)`. See open item 6 below for the repository change. No new money rule: only the user's own savings-move records are deleted, the pot can only grow, so D-040 never fires and no `Savings pot updated` sheet is shown.
7. **Open item 6 (savings repository delete), concrete design.** `SavingsRepository` today has `watchCovers` and `cover()` which returns only a `CoverDecision` (no stored id), and the `savings_moves` table has no delete path. The plan changes the interface to:
   - `Future<CoverResult> cover(...)` where `CoverResult = ({CoverDecision decision, int? coverId})` (id only when stored);
   - `Future<void> removeCovers(int monthId, Set<int> coverIds)`: in one transaction, deletes those rows of that month; unknown ids are ignored (so a late Undo after a Remove is harmless); a write failure throws `StorageException(write)` and deletes nothing. No trigger blocks deletes on `savings_moves` (only the period and fixed-cost tables are append-only), so no schema change and no migration.
   - Drift implementation, `FakeSavingsRepository`, and F-007's cover tests (TC-007-10, -12 and the repository cover tests) are updated. This is a change to a Done feature (F-007): PM approval needed (§9 Q2).
8. **Providers.** `dayDetailsProvider` is a `Provider.family<AsyncValue<DayDetailsView>, (int monthId, CalendarDate date)>` built from the three existing providers; `DayDetailsView = {result, summary, rows, covers, stored month}`. Loading shows the static placeholder bars (never `₹0`), error shows `Couldn't load your data` with **Try again**. Midnight needs nothing new: `todayProvider` changes the result and the status line changes from `Today · …` to its final word (cross-fade `motionBase`), and the Cover card appears if the day is overspent (F-012 §4).
9. **Today card and calendar both call one function:** `openDayDetails(BuildContext, {required int monthId, required CalendarDate date})` in `features/day_details/day_details_screen.dart`, a `MaterialPageRoute` push, so back returns to Home at the same scroll position (the shell keeps the tab's `ScrollController`, AC-1).
10. **Formatting.** All money through `formatRupees` / `formatRupeesForSpeech`; the `Refunds` row is written `−₹500` (design D-3; F-012 AC-16 still says `Refunds ₹500`, see §9 Q4); paise appear only inside the cover field (D-038).

## 2. Files / modules
| Path | Add / Change | What |
|---|---|---|
| `app/lib/domain/budget/day_summary.dart` | Add | `DaySummary`, `CoverOffer`, `DayResultKind` (shared with F-011's labels where the words match) |
| `app/lib/domain/budget/cover_draft.dart` | Add | `CoverDraft`, `validateCover`, `CoverProblem` |
| `app/lib/domain/budget/spend_groups.dart` | Change | `spendsOnDay` |
| `app/lib/domain/budget/budget.dart` | Change | exports |
| `app/lib/data/repositories/savings_repository.dart`, `drift_savings_repository.dart` | Change | `CoverResult`, `removeCovers` |
| `app/test/helpers/fake_savings_repository.dart`, `fake_money_store.dart` | Change | same, all-or-nothing, `failNextWrite` |
| `app/lib/core/providers/day_details_provider.dart` | Add | `dayDetailsProvider` family, `DayDetailsView` |
| `app/lib/features/day_details/day_details_screen.dart`, `openDayDetails` | Add | Route, header, status line, notices, loading and error |
| `app/lib/features/day_details/widgets/figures_card.dart`, `status_line.dart`, `cover_card.dart`, `cover_sheet.dart`, `remove_cover_sheet.dart`, `day_rows.dart` | Add | Small widgets per the design |
| `app/lib/features/transactions/spend_editor_flow.dart` | Change | `date`, `fromDay`, moved-snackbar, returns the result |
| `app/lib/features/transactions/spend_editor_screen.dart` | Change | `initialDate`, result carries `date` |
| `app/lib/features/transactions/spend_list.dart` | Change | public `SpendRow` |
| `app/lib/core/copy/day_details_copy.dart` | Add | F-012 §5 strings, speech sentences, cover errors |
| `app/test/domain/budget/day_summary_test.dart`, `cover_draft_test.dart` | Add | `TC-012-NN` units, literals from §2.2 and §2.3 |
| `app/test/data/repositories/savings_repository_test.dart` | Change | `removeCovers`, id returned, all-or-nothing, unknown ids |
| `app/test/features/day_details/*_test.dart` | Add | widget tests on fakes: figures, rows, cover sheet, Undo, Remove, read-only, upcoming, sweeps |
| `app/integration_test/day_details_cover_flow_test.dart` | Add | on the real Drift file: cover, Undo, Remove, reopen (AC-5, 21, 22) |

## 3. Data model / database changes
No schema change. New repository method `removeCovers` (DELETE by id and month, in a transaction). `cover()` returns the inserted row id. No new table; "Data stored: savings-pot moves (F-007), no new tables" stays true.

## 4. Packages (latest stable, checked on pub.dev)
| Package | Version | Why |
|---|---|---|
| — | — | None new |

## 5. Tasks
IDs confirmed by the Project Manager at Gate 1 (2026-11-16); the board is `docs/TASKS.md`.

| ID | Task | Covers AC | Depends on | Status |
|---|---|---|---|---|
| T-340 | **Pure models.** `DaySummary`, `CoverOffer`, `validateCover`, `spendsOnDay`; unit tests for every row of §2.2 (5, 6, 11, 12, 13, 14 Nov), the refund day (₹700 and ₹500 → saved ₹630; ₹1,500 → net −₹800, saved ₹1,630), partly and fully covered, pot as the limit (₹250), pot empty (S), 47.78 pre-fill (M), 0.40 pre-fill, today overspent, validation (a to f and both-limits order), period-start line (M), D-040 ₹0 cover has no Remove, past month and new-month-due read-only; 100% branches; also the property test `cover_property_test.dart` (TC-012-56) and `maxCover` (TC-012-57) | AC-2, 4, 5 (values), 6, 7, 8, 9, 10, 14 (values), 15, 16, 17, 18, 20 (values) | F-006, T-308 | To do |
| T-341 | **Savings repository:** `CoverResult` with id, `removeCovers`; Drift, fake and tests (all-or-nothing, unknown id, write failure, live emit) | AC-11 (failure), 21, 22 | F-007 | To do |
| T-342 | **Editor seam.** `initialDate` on `SpendEditorScreen`, `date` and `fromDay` on `openSpendEditor`, result carries the saved date, `SpendRow` made public; F-009 tests stay green. **Editor order (D-074): F-012 T-342, then F-015 T-420, then F-015 T-424, then F-016 T-442; one owner at a time, each green before the next starts** | AC-12, 13 | F-009 | To do |
| T-343 | **Screen.** `DayDetailsScreen`, provider, status line with words, mark and colour, figures card, notices (period change opens F-014 via its launcher; past-month lock), entries card, Add spend, upcoming and read-only forms, loading, error, midnight cross-fade, count-up, `Dated in the future` row (TC-012-51) | AC-1 (screen), 2, 3, 12, 13, 16, 17, 18, 19 | T-340, T-342, F-010 T-301, T-313 (Gate 2) | To do |
| T-344 | **Cover card, cover sheet, Undo, Remove.** Cover card variants (available, today line, empty pot with (i), fully covered note), the sheet with pre-fill, caption and errors, double-tap guard, failure path, snackbar with Undo (6 s), Remove decision sheet (`Remove this cover?`), `Cover removed` snackbar, stale-amount refusal (TC-012-45) | AC-4, 5, 6, 7, 8, 9, 10, 11, 14, 15, 20, 21, 22 | T-340, T-341, T-343 | To do |
| T-345 | **Navigation and integration.** `openDayDetails` from F-011 cells and F-010's Today card; Home figures and calendar cell update after a cover (AC-5 and F-010 AC-3, F-011 AC-6 end to end); back keeps Home's scroll position | AC-1, 5 | T-343, T-344, F-010 T-303, F-011 T-324 | To do |
| T-346 | **Sweeps and emulator flow.** Four themes x text 1.0 and 2.0 x small phone and landscape for overspent, saved, refund, read-only and the cover sheet with the keyboard open; TalkBack sentences; `integration_test/day_details_cover_flow_test.dart` | AC-19, 5, 21, 22 | T-344, T-345 | To do |

## 6. Acceptance criteria coverage
Test case IDs are the Tester's (`tests/F-012-day-details.md`, section 2.4), re-mapped by the Project Manager at Gate 1 on 2026-11-16. The earlier proposed slots are retired. Edge cases of the doc section 4: same day twice TC-012-44, pot changes -45, midnight -46, under 1 rupee -47, 10 crore -48, last spend deleted -49, refund on a covered day -50, not-budgeted day -62.

| AC | Built in task | Proved by test cases (Tester IDs) |
|---|---|---|
| AC-1 Opens from both places, back keeps scroll | T-343, T-345 | TC-012-01, -02, -52, -62, -63 |
| AC-2 Figures per day (table 2.2) | T-340, T-343 | TC-012-03, -04 |
| AC-3 Entry list order | T-340, T-343 | TC-012-05, -53 |
| AC-4 Cover offered only where allowed (incl. today) | T-340, T-344 | TC-012-06, -07, -46 |
| AC-5 Full cover, one move of 30,000 paise, Home and calendar update | T-340, T-344, T-345 | TC-012-08, -09, -54, -56, -57, -64 |
| AC-6 Partial cover | T-340, T-344 | TC-012-10, -44 |
| AC-7 Pot is the limit | T-340, T-344 | TC-012-11, -56 |
| AC-8 Cover validation (a to f, both limits) | T-340, T-344 | TC-012-12, -13, -56 |
| AC-9 Paise maximum 47.78 | T-340, T-344 | TC-012-14, -47 |
| AC-10 Empty pot | T-340, T-344 | TC-012-15 |
| AC-11 Once per tap; save failure; stale amount | T-341, T-344 | TC-012-16, -17, -45 |
| AC-12 Add from the day | T-342, T-343 | TC-012-18, -19, -61 |
| AC-13 Edit and delete from the day; moved snackbar | T-342, T-343 | TC-012-20, -21, -22, -49 |
| AC-14 Cover taken back (D-040) | T-340, T-344 (F-007 reconciliation already built) | TC-012-23, -60 |
| AC-15 Over-covered edit returns the rest silently | T-340, T-344 | TC-012-24, -59 |
| AC-16 Refunds | T-340, T-343 | TC-012-25, -26, -50, -58 (-58 runs when F-016 is built) |
| AC-17 Period start line and shortfall | T-340, T-343 | TC-012-27 |
| AC-18 Read-only and upcoming | T-340, T-343 | TC-012-28, -29, -51 |
| AC-19 Help, themes, large text, accessibility, keyboard | T-343, T-344, T-346 | TC-012-30, -31, -32, -33, -34, -48 |
| AC-20 Cover today and later edits | T-340, T-344 | TC-012-35, -36 |
| AC-21 Undo | T-341, T-344 | TC-012-37, -38, -55 |
| AC-22 Remove | T-341, T-344 | TC-012-39, -40, -41, -42, -43 |

## 7. Edge cases & risks
| Case / risk | How it is handled |
|---|---|
| Double tap on Cover or Undo | `_saving` guard; one stored move (AC-11); `removeCovers` is idempotent |
| Both limits exceeded | The overspend message wins: `checkCover` order (D-048 (1)) |
| Pot changes while the sheet is open | The amount is re-checked with `validateCover` on Cover; the engine refuses an invalid cover and the matching message shows |
| Midnight with day details on today | `todayProvider` rebuild; header switches to the final status; Cover card appears when overspent |
| Last spend of the day deleted | List shows `Nothing spent this day`; the engine's result gives the cover back to the pot (F-006 §4) |
| Edit lowers an overspend below its cover | Engine clamps and the repository stores the lowered amount (existing `reconcileCovers`); the `Covered from savings` line shows the reduced amount, no note (AC-15) |
| Cover cut to ₹0 by D-040 | Remove hidden, line hidden (AC-22) |
| Undo after the cover was already removed or the day changed | `removeCovers` ignores unknown ids; the snackbar then does nothing visible |
| Undo/Remove and the stored reductions | Reductions are only stored for edits; Undo and Remove delete whole rows, the pot only grows, so D-040 cannot trigger |
| Covers on a day cut by two edits | One `Savings pot updated` sheet, newest first (existing F-009 behaviour, F-012 §2.4) |
| Moved spend (date changed in the editor) | Day screen stays on its own day, row leaves, snackbar `Spend moved to <date>` |
| Future-dated spends (clock set back) | Listed with `Dated in the future` on the upcoming form; not counted by the engine |
| Not-budgeted day reached some other way | Only `Not budgeted: you started on <date>.`; unreachable from the calendar |
| Deep stack: day screen, editor, then sheets | One route per layer; the cover sheet and the editor are never open together (the editor is a separate pushed route) |
| ₹10 crore spend | Figures wrap at 2.0x; the cover pre-fill is the pot |
| Risk: changing the savings repository interface breaks F-007 tests | T-341 updates the Drift and fake implementations together and re-runs the repository suites; the PM approves the F-007 follow-up (§9 Q2) |
| Risk: keyboard hides the field or Cover at 2.0x | Sheet scrolls inside (max 90 %); widget test with `viewInsets` at 2.0x on 360 x 640 and landscape |
| Risk: money-rule drift | The cover amount is bounded only by `checkCover`; nothing is rounded except for display; `less than ₹1` words come from the exact paise (D-050) |

## 8. Impact on existing features
- **F-009 (editor):** new optional parameters and one extra result field; the Transactions tab's own calls are unchanged. Re-run **TC-009-03, -07, -11, -12, -14, -15, -16, -25 to -28, -42, -43, -45, -48, -49**, `spend_editor_screen_test.dart`, `cover_note_test.dart`, `delete_spend_test.dart`, `transactions_sweep_test.dart` and the manual-transactions integration flow (TC-009-45). `SpendRow` becomes public.
- **F-007 (Done):** `cover()` return type and the new `removeCovers`. Re-run **TC-007-10, -11, -12, -18** and the repository suites (Drift and fake parity). No schema or migration change, so the schema snapshot test (TC-007-14) stays green.
- **F-006:** none changed; `checkCover` and `effectiveCovers` are used as built. Re-run the cover cases TC-006-13, -44, -45, -57 only through F-006's own suite (unchanged).
- **F-010 / F-011:** receive the cover's live effects: F-010 AC-3, F-011 AC-6.
- **F-016 / F-015:** both change the same editor (see §9 Q1).
- **F-014:** the period-start notice opens the statement through the launcher seam.
- **F-004:** every figure, the cover button and the Remove button get label and (i) through the shared help widgets; the help-rule guard covers `lib/features/`.
- Re-run: full suite, `tool/check.ps1`, `tests/REGRESSION.md`, F-001…F-009 Regression-yes cases.

## 9. Open questions
1. **Project Manager (open item 5, editor sequencing).** F-012 (start date, result date), F-016 (Money back switch) and F-015 §2.4a (Category row) all edit `spend_editor_screen.dart` and `spend_editor_flow.dart`. Proposal: **one Developer owns the editor files at a time, in this order: F-012 T-342, then F-016, then F-015.** Reasons: F-012's change is the smallest and purely additive (two optional parameters and one result field), the calendar tap path needs it, and F-016 and F-015 can then build on the same seam. The seam is landed and green before the next branch starts, so no three-way merge.
2. **Project Manager (open item 6, savings repository delete).** Approve the F-007 change in §1.7: `cover()` returns `({decision, coverId})` and a new `removeCovers(monthId, ids)` deletes rows in one transaction. Alternative with the same behaviour: keep `cover()` and add `deleteCoversOn(monthId, day)` only; rejected because Undo must remove exactly the one cover just made (F-012 AC-21).
3. **Project Manager / Designer:** day details shows `Remove` for a day whose stored cover rows are all ₹0 only if the engine amount is above ₹0, so no button for a fully reduced cover (AC-22). Confirm that the `Covered from savings` line is hidden then, as the spec says.
4. **Product Manager:** F-012 AC-16 still says `Refunds ₹500`; the design (D-3) and §5 say `−₹500`. The plan builds `−₹500`; please align AC-16 (the Designer already flagged it).
5. **Project Manager:** F-012 §2.2 says a day with `Nothing spent yet today` for today; only the design has this line in the list card; plan follows the design.
6. **Owner decision needed?** **No new one.** Cover, Undo and Remove are already approved (D-005, D-056 (1)); nothing is moved automatically (D-005), no network, no permission. The only data-affecting change is that the user can delete their own savings-move records, which D-056 (1) approved; no money rule changes.

## 10. Project Manager review *(Gate 1 — cross-check of doc + plan + test cases)*
**Verdict:** **Approved** (Project Manager A, 2026-11-16). Must fix points 1 and 2 are done by PM edits. Decisions D-073 to D-079. No Owner decision is needed (cover, Undo and Remove are D-005 and D-056 (1)). Build track: F-011 and F-012 together (D-033).

Cross-check:
- [x] Every AC in the feature doc is covered by a task in this plan (22 of 22, section 6)
- [x] Every AC has at least one test case in the test file (22 of 22, tests section 2.4)
- [x] Edge cases in the doc appear in both the plan and the test cases (all section 4 cases have a TC)
- [x] Approach follows `docs/STANDARDS.md` (pure `DaySummary` and `cover_draft` in `domain/`, integer paise, the engine's `checkCover` is the only bound, repositories behind the interface)
- [x] Latest stable versions / modern APIs used (no new package)

Money rules D-034 to D-062 and D-069 to D-072: untouched. The cover amount is bounded only by the engine's `checkCover` (D-048 (1) order); the only data change is that the user can delete their own savings-move records (D-056 (1)); the pot can only grow, so D-040 never fires.

| # | Point | Type | Resolution |
|---|---|---|---|
| 1 | AC-16 said `Refunds ₹500`; the design and doc section 5 say `−₹500` so the column adds up | Must fix (Product Manager change, done by PM) | Doc AC-16 now reads `Refunds −₹500` (D-077). F-014 AC-11 has the same wording: Project Manager B / Product Manager to align (not touched here) |
| 2 | The Tester's property test TC-012-56, `maxCover` TC-012-57, stale amount TC-012-45 and the `Dated in the future` row TC-012-51 had no plan task (tests note 7) | Must fix (Developer, done by PM) | Added to T-340 (-56, -57), T-343 (-51), T-344 (-45) in section 5; section 6 re-mapped |
| 3 | Q1: editor sequencing | Decision (D-074) | T-342 (additive: two optional parameters and a result field) first, then F-015 T-420, F-015 T-424, F-016 T-442. One owner of `spend_editor_screen.dart` and `spend_editor_flow.dart` at a time; each lands green (analyze and the full suite) before the next starts. F-009 re-run list in section 8 stands |
| 4 | Q2: `cover()` returns `({decision, coverId})` and new `removeCovers(monthId, ids)` | Decision (D-078) | Approved as an additive change to the Done F-007 repository (Drift, fake and tests together in T-341). The alternative `deleteCoversOn` is rejected: Undo must delete exactly the cover just made. Tester T-312 updates the F-007 cover cases; TC-012-43 covers atomicity |
| 5 | Q3: Remove is hidden and the `Covered from savings` line hidden when D-040 cut the cover to 0 | Decision | Confirmed |
| 6 | Q4: AC-16 wording | Decision | Done, point 1 |
| 7 | Q5: `Nothing spent yet today` | Decision | Confirmed as in the design |
| 8 | Q6: Owner decision needed? | Decision | No new one. Agreed |
| 9 | Tests note 4: Undo stays while TalkBack is on | Decision (D-077) | Wanted. Doc section 2.5 now says so; TC-012-38 checks it |
| 10 | The `Budget changed on this day` notice opens F-014 | Decision (D-077) | Same rule as F-010 T-306: built against the launcher seam, wired when F-014's route exists, blocks the Phase 3 commit until wired |
| 11 | TC-012-58 (refund rows open `Edit money back`) needs F-016 (B's T-442 and later) | Nice to have | Until F-016 is built the case only checks the row is tappable with hint `Edit` (as the case says) |
| 12 | TC-012-45 simulates a changed pot by swapping the fake store | Nice to have | Accepted; cannot happen in one real session |

## 11. Implementation notes *(Developer, filled in during the build)*
Deviations from the plan and why (each approved by the Project Manager).

**Built 2026-11-16 to 2026-11-19 by Developer Track B.** Order: T-342, T-341, T-340, then T-343 to T-345 and the sweeps (T-346). Notes and deviations:
1. **T-342 (editor seam).** `SpendEditorScreen.initialDate`, `openSpendEditor(date:, fromDay:)`, `SpendEditorResult.date`, `TransactionsCopy.spendMoved`. `Spend moved to <day>` is shown for an **edit** saved on another day than `fromDay` only; an Add whose date was changed in the editor still says `Spend added`. Tests: `editor_seam_test.dart` (4 seam tests; they do not close TC-012-18 / -22, the day-details tests do). Also: `SpendRow` is public with two optional parameters (`subtitle`, `isRefund`), and `BudgetButton.secondary` gained an optional `icon` (Add spend). Both additive.
2. **T-341 (savings repository).** As planned (D-078): `CoverResult = ({decision, coverId})`, `removeCovers(monthId, ids)` in one transaction, unknown ids and other months ignored. Tests are in a new file `test/data/repositories/cover_removal_test.dart` (TC-007-49 to -52, TC-012-09, TC-012-43; Drift and fake run the same bodies) instead of `savings_repository_test.dart`, to keep the old file untouched; three call sites in `months_repository_test.dart` read `.decision` now.
3. **T-340 (pure models).** `DaySummary` (also holds `coverIds`, taken from the engine's `effectiveCovers`, so the screen needs no `monthCoversProvider` for Remove: it deletes every stored cover row of the day, including the rows cut to ₹0), `CoverOffer` (`CoverNone`, `CoverPotEmpty`, `CoverAvailable(max, limitedByPot)`), `DayResultKind` (shared with the calendar), `maxCover`, `coverCaption`, `CoverDraft`/`validateCover` (`CoverOk`, `CoverNotOk(problem)`), `spendsOnDay`. 100 % lines and branches (`tool/domain_coverage.ps1`). Property test TC-012-56 runs on the fake repositories (same reconciliation as Drift), 300 sequences.
4. **T-343 to T-345 (screen).** `DayDetailsScreen`, `dayDetailsProvider`, `FiguresCard`, `CoverCard`, `CoveredNote`, `CoverSheet`, copy in `day_details_copy.dart`. The launcher seam `dayDetailsLauncherProvider` (made by Track D, F-013) now pushes the real screen by default (T-345). Deviations: (a) the cover sheet shows `Couldn't save. Please try again.` **inside the sheet** (a live-region line under the field) instead of a snackbar, because a snackbar sits under the sheet's scrim and cannot be seen; the text and the kept amount are as specified. (b) The Undo snackbar is built with `persist: false` unless a screen reader is on (Flutter keeps a snackbar with an action by default), `duration` 5.75 s because its timer starts after the 250 ms slide-in, so Undo is gone 6 s after the cover. (c) With the keyboard up on a short screen (under 420 dp left) only **Cover** stays pinned and **Cancel** scrolls with the form; focusing the field scrolls it into view. (d) Count-up animation of the figures (`motionCount`) is not built (nice to have, not an AC). (e) The `Budget changed on this day` text is written by the screen: `salary ₹40,000 → ₹35,000`, other fields `spending target`, `money left`, the cost's name; added and removed items read `<name> ₹x added` / `<name> removed` (the Designer only specified the salary case). (f) Refund rows open the current spend editor until F-016 lands (TC-012-58 checks the row and its hint only).
5. **T-346.** Sweeps in `test/a11y/calendar_day_sweep_test.dart` (calendar and day details states, 4 themes x text 1 and 2 on the small phone, landscape in Light and Dim, the cover sheet with an error). `integration_test/day_details_cover_flow_test.dart` is written and analyses clean but **was not run on the emulator** in this session.
6. Not covered by an automated test: TC-012-34, -64 (manual on the emulator), the count-up (not built).
7. **Gate 3 fixes (2026-11-19, Developer fixes B/C).** (a) The under-₹1 test is `DaySummary.overspendUnderRupee` (the domain's `dayResultKind`, tests `TC-012-47 overspend under a rupee is under 100 paise` at 99 and 100 paise); `cover_sheet.dart` no longer compares paise (D-090 (1)). (b) `Budget changed on this day` is built by the pure `budgetChangeText` (`features/day_details/budget_change_text.dart`, strings in `DayDetailsCopy`, wording and ` · ` joiner from design §3.1, D-090 (2)); it reuses the statement's `statementDeltasOf` (made public in `month_statement.dart`, so a rename is the same rule on both screens). `DaySummary.changes` is now the **net** difference from the previous kept period and `isChangeDay` a flag, so a same-day double change that nets to nothing reads `changed and changed back`. One test per branch in `budget_change_text_test.dart` (salary, target changed / set / removed, money left, fixed cost changed, still to pay, added, removed, renamed, two joined, netted to nothing) and `TC-012-27 same day changes net out`. (c) The cover-sheet save error is a line under the field and caption with an error icon in the overspent colour, above the buttons (design).
8. **Probes (reverted mutations, 2026-11-19).** Each mutation was applied, the named tests run, and the file restored.

| Mutation | Result | Failing test(s) |
|---|---|---|
| `limitedByPot` flipped (`pot > overspend`) | killed | TC-012-10, -11, -14 (`day_summary_test.dart`) |
| `offerable` without `!isEnded` | killed | TC-012-06, -28 |
| `offerable` without the live-day branch | killed | TC-012-07 |
| `canRemoveCover` without `!isEnded` | killed | TC-012-28 |
| `isFullyCovered` without `result == zero` | killed | TC-012-10 |
| `coverIds` skipping cut rows | killed | TC-012-41 |
| `overspendUnderRupee` never true | killed | TC-012-47 |
| `maxCover` returns the pot | killed | TC-012-04, -07, -10, cover_draft TC-012-57 |
| refusal mapping swapped in `validateCover` | killed | TC-012-12, -13 (domain and sheet) |
| `> maxAmount` dropped | killed | TC-012-12 |
| pot check dropped in the engine (property test) | killed | TC-012-56 (also -12, -13) |
| sheet: overspend and pot messages swapped | killed | TC-012-12, -13, -45 (`cover_sheet_test.dart`) |
| sheet: `_saving` guard removed | **survived: equivalent** | `BudgetButton.loading` already swallows the second tap; with the guard **and** `loading: _saving` both removed TC-012-16 fails, so the test measures the double tap. The guard is kept as the second layer |
| sheet: `coverId == null` branch removed | **survived, test added** | new `TC-012-45 a cover the engine refuses after all keeps the sheet open` (a refusing repository wrapper); with the new test the mutant is killed |
| `persist` always true | killed | TC-012-38 (expires after six seconds) |
| duration 6 s instead of 5.75 s | **survived, test added** | `TC-012-38 undo expires` now also asserts the `SnackBar.duration` is 5750 ms; the mutant is killed |
| Remove deletes only the first id | killed | TC-012-39 |
| Keep it deletes | killed | TC-012-40 |
| sheet under-₹1 line off | killed | TC-012-47 (`cover_sheet_test.dart`) |

Note: a Flutter upgrade can change the 250 ms snackbar entrance; TC-012-38 will show it.


**T-477 (Developer 2, 2026-11-23).** TC-012-65 to -71, -73 and -74 now name the existing wording tests in `budget_change_text_test.dart` and `day_summary_test.dart`; TC-012-72 is new (`day_summary_test.dart` flag at 99, 1, 100, 0 and 1,00,000 paise; `cover_sheet_test.dart` sheet line plus static check of `cover_sheet.dart`). Probes in plan F-011 section 11.
