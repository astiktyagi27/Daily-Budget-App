# Plan — F-015: Transactions list (search & filter)

| | |
|---|---|
| **Feature doc** | [`docs/features/F-015-transactions-list.md`](../docs/features/F-015-transactions-list.md) (final spec, 19 ACs) |
| **Test cases** | [`tests/F-015-transactions-list.md`](../tests/F-015-transactions-list.md) (Tester, Step 4; the TC IDs in §6 were reconciled to the Tester's file at Gate 1) |
| **Design** | [`docs/design/screens/transactions-search.md`](../docs/design/screens/transactions-search.md) (extends `transactions.md`), design system §7.15 |
| **Inputs** | D-038, D-039, D-046 .. D-048 (8), D-050, D-054, D-056 (2), D-059, D-069, D-070; F-009 plan §11 (C1 to C8), F-007 plan; phase overview open items 4 and 5 |
| **Author** | Developer 2 |
| **Status** | Plan approved (Gate 1, 2026-11-16, Project Manager B; D-082, D-083) |

## 1. Approach
The Transactions tab keeps everything F-009 built (Today card, Add spend button in the shell, `openSpendEditor`, delete / discard / cover-taken-back sheets, new-month card). F-015 replaces only the **list part** and adds search, filters and category.

1. **Filtering is pure Dart, in memory.** New `app/lib/domain/budget/transaction_search.dart` (D-059 library, 100 % branches):
   - `typedef NotedSpend = ({Spend spend, String? note})` (domain cannot import `StoredSpend`, which lives in `data/`; `StoredSpend` gets a `noted` getter).
   - `EntryFilter` (query, `DatesFilter`, `Set<SpendCategory>`, `TypeFilter`), `filterEntries`, `parseSearchQuery`, `resultsSummary` (count, gross spent, refunds).
   - **Text:** trimmed, empty → no query; note contains the query, case-insensitive (`toLowerCase`, Unicode aware, so Hindi and emoji work).
   - **Number:** the typed text is a number query when `parseAmount` returns an `AmountValue` (so `₹250`, `1,130`, `300.50`; letters make it text, a decimal comma `99,50` is Indian grouping and matches nothing numerically). No decimal point → equals the **shown whole rupees** (`amount.value ~/ 100`, D-038), so `300` finds ₹300.50. With a decimal point → equals the **exact paise**. A number query also matches notes containing the typed digits (`250` finds `250g paneer`). `0` matches ₹0.01 to ₹0.99 and notes containing "0".
   - **Category:** OR inside the set; `Other` includes `null`. **Type:** all / spends / refunds. All parts AND.
2. **Why in memory and no new SQL index:** F-007 says queries "need indexes for AC-16 (a plan decision)". The data is small (AC-16: 1,000 entries over 3 months; a user adds a few spends a day), the existing `monthSpendsProvider(monthId)` streams are already live and per month, and a filter pass over 1,000 entries is about a millisecond. SQL `LIKE` would not do case-insensitive Hindi / emoji matching reliably and would need a schema migration. **Decision: no schema change, no index; revisit only if the emulator measurement (T-425) misses AC-16.**
3. **List model (pure).** `groupEntries(...)` returns month sections, newest first; each section holds the stored month, its day groups (reusing `groupSpendsByDay`, so order, "newest added first" and net day totals are unchanged) and the **shown** day totals (only matching entries, AC-10). A month separator is drawn only when more than one section is shown. `Today` / `Yesterday` headings come from the existing `DayLabel`.
4. **State.** `transactionsFilterProvider` is a plain `NotifierProvider<TransactionsFilterNotifier, EntryFilter>` (not auto-disposed, so it survives tab switches like the rest of the shell's `IndexedStack`, and is gone on restart: AC-15). Search typing goes through a 250 ms debounce in the notifier (`Timer`, cancelled on dispose); the field itself stays instant. `transactionsListProvider` (`Provider<AsyncValue<TransactionsListModel>>`) resolves the date range with F-011's month index and `MonthBrowser` (F-011 T-322 / T-323), watches `monthSpendsProvider(id)` for every stored month the range touches, concatenates, filters and groups. An empty-for-now stream gives loading, a failed one the existing load error with **Try again**.
5. **Categories.** `SpendCategory` and `Spend.category` come from F-013 T-380. F-015 adds the write side (T-420): `SpendFields` gets `category` (and `direction`, used by F-016, so the record changes once), `TransactionRepository.add` / `update` store both, and a new `updateCategory(int id, SpendCategory? category, {required int now})` changes only the category column and `edited_at`. It does **not** run the engine or `reconcileStoredCovers`: a category is not money (AC-13). It throws `ArgumentError` for a money-in row (refunds have no category, F-016) and works on **any month's** row (AC-14, open item 4: built as specified, amount and date stay read-only in past months; a category write needs no month check). Undo calls `updateCategory` with the previous value (null restores "no category").
6. **Stored value rules (decision).** Picking a category stores its key. **Picking Other stores `other` explicitly** when the spend had another category; picking the already-ticked one is a no-op, and **null and `other` both mean the ticked row is Other**. In the editor, "changed" compares the effective category (null ≡ other), so reopening Other on an untouched spend does not enable `Save changes`, and an untouched Add stores `null` (AC-17).
7. **UI pieces** (all reuse existing shell, `BudgetCard`, `showBudgetSheet`, `BudgetTag` look, `EmptyState`, `LabelDescription`):
   - `FilterChip` (design §7.15: idle / active with ✓) in `core/widgets/`, `CategoryChip` (a `BudgetTag`-styled tappable chip whose 48 dp target extends into the row, design §7), `SearchField`.
   - Sheets through `showBudgetSheet`: `DatesSheet` (radio rows; Custom opens `showDateRangePicker` themed like the date picker, first = first stored month's start, last = today), `CategoryFilterSheet` (nine checkboxes, `Show` / `Clear`), `TypeSheet`, and one `CategorySheet` with two modes: **row** (saves at once, snackbar `Moved to Food` + `Undo` 6 s) and **editor** (only changes the draft).
   - `spend_list.dart` is generalised: `SpendListSliver` takes sections, builds a lazy `SliverList.builder` **per day** (as F-009 C4; 1,000 entries open at once), rows with the chip line or the `Refund` line (`+₹500`, not coloured), the day header with `shown` while filtering, month separators. Past-month rows have the chip but no row tap (AC-14).
8. **Editor Category row (§2.4a).** `SpendEditorScreen` gets a `Category` field row (design §9 row 7) under Note. `SpendDraft` gains `category`; `SpendDraft.forEdit` reads `spend.category`; `isChangedFrom` uses the effective category. See §1.9 for sequencing with F-016.
9. **Editor sequencing (phase overview open item 5, recommendation).** One Developer owns the editor files (`spend_editor_screen.dart`, `spend_draft.dart`, `spend_editor_flow.dart`, `widgets/delete_spend_sheet.dart`, `discard_spend_sheet.dart`, `note_field.dart`, `core/widgets/amount_field.dart`) for both features, in this order: **F-012 T-342** (editor seam, first of all), **T-420** (shared plumbing: `SpendFields`, repository, `SpendDraft.category`, `SpendDraft.moneyBack`, fakes) → **T-424** (F-015 Category row) → **F-016 T-442** (Money back switch, which hides the Category row). No parallel edits to those files. The design file `transactions-search.md` §9 is already the single layout for both, so the second feature only adds its row. New strings go in new copy files (`search_copy.dart`, F-016's `money_back_copy.dart`), not in `transactions_copy.dart`, so nothing else collides. F-015 AC-17's third clause (switch on hides Category) is proved in T-442. F-016's repository and domain tests (T-441) need only T-420.
10. **First-time hint.** `hint.transactions.v1` keeps its ID and gets the new text `Tap a spend to fix it, or tap its category to change it.` (`HelpCopy.hintTransactions`; F-004 §5 and `help-pattern.md` §4.2 to be aligned by the PM).

**Alternatives rejected:** SQL search (migration, Unicode case, §1.2); a separate Search screen (the spec puts search on the tab); a `Drift` view for all months (a second code path to keep in step with the fakes).

## 2. Files / modules
| Path | Add / Change | What |
|---|---|---|
| `app/lib/domain/budget/transaction_search.dart` | Add (T-421) | `NotedSpend`, `EntryFilter`, `DatesFilter` (sealed: thisMonth, lastMonth, custom), `TypeFilter`, `parseSearchQuery`, `filterEntries`, `resolveRange`, `groupEntries`, `ResultsSummary` |
| `app/lib/domain/budget/spend_draft.dart` | Change (T-420) | `category`, `moneyBack` (used by F-016), effective-category compare, `toFields` returns them (a money back stores no category) |
| `app/lib/data/repositories/transaction_repository.dart`, `drift_transaction_repository.dart`, `drift_mappers.dart` | Change (T-420) | `SpendFields` (+ `category`, `direction`), `add` / `update` write both, `updateCategory`, `StoredSpend.noted`; the `direction` parameter of `add` moves into `SpendFields` |
| `app/test/helpers/fake_transaction_repository.dart`, `repository_setup.dart`, and the tests that build `SpendFields` | Change (T-420) | Mechanical: 12 uses in 8 files today (`SpendFields` record literals); the fake `update` uses `fields.direction` and `fields.category` instead of the old record's values |
| `app/lib/core/widgets/filter_chip.dart`, `category_chip.dart`, `search_field.dart` | Add (T-422) | §7.15 chips, search field with × |
| `app/lib/core/copy/search_copy.dart` | Add (T-422) | F-015 §5 copy (sheet titles, results line, no-results, snackbar, month separator) |
| `app/lib/features/transactions/sheets/dates_sheet.dart`, `category_filter_sheet.dart`, `type_sheet.dart`, `category_sheet.dart` | Add (T-422) | The four sheets |
| `app/lib/features/transactions/transactions_filter_state.dart` | Add (T-423) | `transactionsFilterProvider` (debounce), `transactionsListProvider` |
| `app/lib/features/transactions/spend_list.dart` | Change (T-423) | Sections, chip line, refund rows, month separators, shown totals, per-row editability |
| `app/lib/features/transactions/transactions_tab.dart` | Change (T-423) | Search, chips, results line, no-results states under the Today card; the list for both current and new-month views; tip rule (`_tipBelowTodayAbove`) kept |
| `app/lib/features/transactions/widgets/results_line.dart`, `search_empty_state.dart` | Add (T-423) | Results line with `Clear all`; the three no-results variants |
| `app/lib/features/transactions/category_change_flow.dart` | Add (T-423) | Opens the row sheet, writes, snackbar with Undo (holds ids and the repository, so it works after the row leaves a filtered list) |
| `app/lib/core/copy/help_copy.dart` | Change (T-423) | New `hintTransactions` text |
| `app/lib/features/transactions/spend_editor_screen.dart`, `widgets/category_field.dart` | Change / Add (T-424) | Category row and its sheet in editor mode |
| `app/test/domain/budget/transaction_search_test.dart` | Add | `TC-015-NN ...` unit tests |
| `app/test/features/transactions/*_test.dart` | Add / Change | Widget tests; existing `transactions_tab_test.dart`, `transactions_sweep_test.dart`, `delete_spend_test.dart`, `spend_editor_screen_test.dart` re-run, edited only where the list rows changed |
| `app/integration_test/transactions_search_test.dart` | Add (T-425) | 1,000 entries over 3 months: open < 1 s, search / filter < 300 ms, per-frame timings of the scroll |

## 3. Data model / database changes
**No schema change.** Column `transactions.category` (nullable text, F-007) is written with the keys of F-013 §3 (`food, groceries, shopping, travel, bills_recharge, entertainment, health, friends_people, other`); they must match Phase 4's categoriser. No index (§1.2). `edited_at` is updated by `updateCategory`; the list order uses `created_at` and id, so an edit never moves a row (D-048 (8)).

## 4. Packages (latest stable, checked on pub.dev)
| Package | Version | Why |
|---|---|---|
| none | | No search package, no `intl` (D-070) |

## 5. Tasks
| ID | Task | Covers AC | Depends on | Status |
|---|---|---|---|---|
| T-420 | **Write-side plumbing for the editor (both F-015 and F-016).** `SpendFields` (+ category, direction), `SpendDraft.category` / `moneyBack`, repository `add` / `update` / `updateCategory`, `StoredSpend.noted`, fake and Drift tests (covers untouched, covers not re-run by a category change, past-month category write, money-in row refused) | AC-13 (data), AC-17, AC-18 (data) | F-013 T-380; **F-012 T-342** (editor seam first) | Code review |
| T-421 | **Search and filter in pure Dart** with unit tests for every row of §2.5 and AC-3 to AC-10 and the spec edge cases (spaces only, `0`, 100+ characters, `250rs`, `99,50`, same-day range, Hindi, emoji); 100 % branches | AC-3 to AC-10 (logic) | T-420, F-011 month browsing (T-322 / T-323) | Code review |
| T-422 | **Components and sheets:** `FilterChip`, `CategoryChip`, `SearchField`, the four sheets, copy; four themes, 2.0x, TalkBack labels, (i) / hints per F-004 | AC-5 (UI), AC-11 (sheet), AC-19 (parts) | T-421 | Code review |
| T-423 | **The list:** filter state, list model, results line, no-results states, rows (chip, refund, shown totals, separators), category change with Undo, past-month rows, filters kept while the app runs, new hint text; F-009 flows kept | AC-1 to AC-16, AC-19 | T-422, F-011 month browsing (T-322 / T-323) | Code review |
| T-424 | **Category row in the Add / Edit editor** (§2.4a): field, sheet (editor mode), `Save changes` and discard behaviour, one stored key on Save | AC-17, AC-18 | T-420, T-422, F-012 T-342; **editor owner**, before F-016 T-442 | Code review |
| T-425 | **Speed, sweeps, hand-over:** 1,000-entry integration test and the agreed profile run (§7), all-state sweeps (4 themes x 1.0 / 2.0 x small phone x landscape), the F-009 Regression-yes re-run (AC-2), list for the Tester's regression | AC-2, AC-16, AC-19 | T-423, T-424 | Code review |

T-423 and T-424 touch different files and may run in parallel after T-422; T-424 must finish before F-016 T-442 starts.

## 6. Acceptance criteria coverage
Test case IDs are the Tester's (`tests/F-015-transactions-list.md`, authoritative); the plan's earlier proposed slots are retired (Gate 1).

| AC | Built in task | Proved by test cases |
|---|---|---|
| AC-1 Layout; no results line and no `Clear all` when idle | T-423 | TC-015-01, -49, -50, -58 |
| AC-2 F-009 behaviour kept | T-423, T-425 | TC-015-02, -62 |
| AC-3 Text search (case, partial, Hindi, emoji) | T-421, T-423 | TC-015-03, -04, -08, -40, -42, -61 |
| AC-4 Amount search (a to f) | T-421 (UI in T-423) | TC-015-05, -06, -07, -41, -43 |
| AC-5 No results; `Clear search`; `Clear all` | T-422, T-423 | TC-015-09, -10, -47 |
| AC-6 Date filter; separators; picker limits | T-421, T-422, T-423 | TC-015-11, -12, -13, -44, -63 |
| AC-7 Category filter incl. Other with null | T-421, T-423 | TC-015-14, -15 |
| AC-8 Type filter and refunds; day header `−₹80` | T-421, T-423 | TC-015-16, -17, -51, -52 |
| AC-9 Filters combine; `Clear all` | T-421, T-423 | TC-015-18, -45 |
| AC-10 Day totals while filtering (`shown`) | T-421, T-423 | TC-015-19 |
| AC-11 Change a category; one record only | T-420, T-422, T-423 | TC-015-20, -53, -54, -55, -56 |
| AC-12 Undo and no-op | T-420, T-423 | TC-015-21, -46 |
| AC-13 Category is not money (deep equality of engine output; Dashboard updates) | T-420, T-423 | TC-015-22, -23 |
| AC-14 Past-month rows: chip works, row tap does nothing | T-420, T-423 | TC-015-24 |
| AC-15 Filters kept while open, reset on restart | T-423 | TC-015-25, -26, -48 |
| AC-16 Hundreds of entries (open < 1 s, update < 300 ms, no frame > 32 ms; method D-083) | T-423, T-425 | TC-015-27, -28, -29, -38 |
| AC-17 Category on Add spend (and hidden with Money back) | T-424; third clause in F-016 T-442 | TC-015-30, -31, -32 |
| AC-18 Category on Edit spend | T-424 | TC-015-33, -34, -57, -64 |
| AC-19 Help, themes, large text, landscape, TalkBack | T-422, T-423, T-425 | TC-015-35, -36, -37, -39, -59, -60 |

## 7. Edge cases & risks
| Case / risk | How it is handled |
|---|---|
| Spaces only / `0` / 100+ characters / `250rs` / `99,50` | Spec §4; each has a case (TC-015-40, -41, -42, -43, -06) |
| Same-day custom range | One day, inclusive both ends |
| Spend edited so it no longer matches | Leaves after Save; results line recomputes (provider chain) |
| **Category changed while filtered out** | Spec says the row leaves "after the snackbar" and Undo brings it back. **Plan default: the row leaves at once with the `motionEmphasis` collapse, Undo restores it.** Holding it until the snackbar closes needs a "pinned ids" set in the filter state. **Confirmed at Gate 1 (D-082 (4)): the row leaves at once; the doc and TC-015-45 / -46 follow.** |
| Missed month inside a custom range | No entries, no separator (sections only for stored months with entries) |
| Midnight | `todayProvider` and the resolved range recompute on resume |
| New month not set up | `This month` has no month; default chip reads `Dates: Last month` (not active styled). **Confirmed at Gate 1 (D-083 (3)): `This month` row disabled with `Set up your month first`; Designer T-427 writes the copy.** |
| Debounce vs AC-16 | Spec 250 ms plus the build leaves about 50 ms of the 300 ms. Plan keeps 250 ms and measures; fallback 200 ms (pre-approved at Gate 1, D-083 (2); the Tester then updates TC-015-29) |
| **AC-16 "no frame over 32 ms in the profile run agreed in the plan"** | Agreed measure: an integration test scrolls the 1,000-entry list from newest to oldest day, collecting `FrameTiming` through `addTimingsCallback`; threshold build time <= 32 ms per frame on emulator-5554 in a **profile-mode** run. The exact command (`flutter drive --profile` with the standard `integration_test` driver) is confirmed by the Developer in T-425 and written into the test case; debug-mode numbers are not used. **Method and re-run rule fixed at Gate 1 (D-083 (1)): profile mode on emulator-5554, one warm-up and 3 timed scrolls, UI-thread build time of every frame ≤ 32 ms, rasterizer time recorded not gated** |
| Lazy list and 1,000 entries | Per-day `SliverList.builder`; day groups computed once per filter change (not per frame) |
| Filtering recomputes on every stream tick | Provider chain is cached; only changes in query, filter or data recompute |
| Search field keeps focus and the keyboard when the list rebuilds | The field lives outside the list; the list keeps the old results until the new ones are ready |
| Past-month row: a category write failing | Snackbar `Couldn't save. Please try again.`, the chip keeps its old value (`StorageException`) |
| Double tap on a category in the sheet | The sheet closes on the first pick; the flow ignores a second call while writing |
| Refund row has no category | No chip, `Refund` line; `updateCategory` refuses money-in rows; the TalkBack label has no `Other` (Designer note 2, AC-19 wording to be fixed by the PM) |
| Unknown category key from a later version | Reads as Other (`SpendCategory.fromKey`) |
| Risk: the `direction` parameter moves into `SpendFields` | Mechanical test edits, no behaviour change; the whole suite runs after T-420 |

## 8. Impact on existing features
- **F-009 (most affected):** list rows, the Today card position and the tip rule are in the same files. Re-run **all** F-009 Regression-yes cases (add, edit, delete, grouping, Today card, discard, cover-taken-back sheet, new-month block, 500-spend case TC-009-19, sweep TC-009-20, tip rule TC-009-46) and the existing widget tests under `test/features/transactions/`. `SpendFields` and `add` change shape (T-420): `transactions_repository_test.dart`, `savings_repository_test.dart`, `database_providers_test.dart`, `repository_setup.dart`.
- **F-007:** the repository interface gains `updateCategory`; `add`'s signature loses `direction`. Re-run TC-007 repository, cover reconciliation (AC-18) and speed (AC-14) cases.
- **F-004:** the hint text changes under the same ID (`hints_test.dart`, `copy_tables_test.dart`, TC-004 hint cases). Every new control must pass `help_rule_test.dart`.
- **F-003:** the Transactions tab keeps its label and nav tooltip; re-run TC-003-04, -19, -20.
- **F-002:** four themes; `tokens_only_test.dart`, `shared_components_test.dart` for the new `FilterChip` / `CategoryChip`.
- **F-006:** untouched (the category does not reach the engine). A test asserts equal `MonthResult` before and after a category change.
- **F-013:** reads the categories set here (live update, F-013 AC-15). **F-016:** builds on T-420 and T-424. **F-010, F-011, F-012:** their "add / edit a spend" flows call `openSpendEditor`, so the new editor row appears there too; re-run their editor cases.

## 9. Open questions
*All answered at Gate 1 (2026-11-16): see §10 and D-082, D-083, D-084.*
1. **PM (open item 4):** a past month's spend may have its category changed while amount and date stay read-only. Built as specified (§1.5); please confirm. **Not an Owner decision** (a category is not money, no permission, nothing leaves the phone).
2. **Designer / PM:** when a category change makes the row leave a filtered list: at once (plan default) or after its snackbar closes (the spec wording)?
3. **Designer:** the Dates sheet when the new month is not set up. Plan: default `Last month` = the latest stored month, and the `This month` row disabled with a short line (new copy, for example `Set up your month first`).
4. **PM (open item 5):** confirm the sequencing of §1.9 (one editor owner; T-420 then T-424 then F-016 T-442).
5. **PM:** AC-19's refund TalkBack sentence still contains `Other` (Designer note 2): drop it.
6. **PM:** the `SpendFields` shape (a record with category and direction added, `add` loses its `direction` parameter) is a small interface change to approved F-007 code.
7. **Owner decisions:** none.

## 10. Project Manager review *(Gate 1 — cross-check of doc + plan + test cases)*
**Verdict:** **Approved** (2026-11-16, Project Manager B). The Must fix points below were resolved in the plan, doc and test file in this pass. Owner decisions: none (a category is not money, no new permission, nothing leaves the phone; the `SpendFields` change is internal code).

Cross-check:
- [x] Every AC in the feature doc is covered by a task in this plan (19 of 19)
- [x] Every AC has at least one test case in the test file (19 of 19; map in §6 and `tests/F-015` §2.4, 64 cases)
- [x] Edge cases in the doc appear in both the plan and the test cases (§4: 11 bullets, TC-015-40 to -48, -51, -06, -41, -43)
- [x] Approach follows `docs/STANDARDS.md` (pure-Dart search and grouping in `domain/`, integer paise, UI through repositories and providers, no schema change, no package; the category is never read by the engine so D-034 to D-062 and D-069 to D-072 are untouched; AC-13 proves it by deep equality)
- [x] Latest stable versions / modern APIs used (no package, no `intl` per D-070; Dart 3 sealed `DatesFilter`, records, `SliverList.builder`)

| # | Point | Type | Resolution |
|---|---|---|---|
| 1 | §6 used proposed slots; month browsing depended on the removed F-013 T-381 | Must fix | Done: §6 rewritten with the Tester's IDs; T-421 / T-423 depend on F-011's month index and `MonthBrowser` (T-322 / T-323) |
| 2 | Editor files are changed by three features | Must fix | Done: one owner at a time, order **F-012 T-342 → T-420 (plumbing) → T-424 (Category row) → F-016 T-442 (switch)**; F-016 T-440 / T-441 may start after T-420; dependencies written into T-420, T-424 and §1.9 |
| 3 | `SpendFields` shape (category and direction added, `add` loses its `direction` parameter) changes approved F-007 code | Ruling | Approved (D-082 (2)): mechanical, no behaviour change; the whole suite and the 12 `SpendFields` uses in 8 files re-run after T-420 |
| 4 | Search and filters in memory, not SQL; no index, no schema change | Ruling | Approved (D-082 (1)); revisit only if the T-425 measurement misses AC-16 |
| 5 | Past-month rows: category may change, amount and date stay read-only (open item 4) | Ruling | Confirmed (D-082 (3)) |
| 6 | A row that stops matching a filtered list: at once or after the snackbar | Must fix (doc vs plan) | At once with the `motionEmphasis` collapse; Undo (6 s) puts it back (D-082 (4)); doc §4 and TC-015-45, -46 updated; the flow holds ids so Undo works after the row has left |
| 7 | Dates sheet when the new month is not set up | Ruling | Default `Last month` = the latest stored month; the `This month` row is disabled with `Set up your month first` (D-083 (3)); Designer T-427 writes the copy; TC-015-63 updated |
| 8 | AC-16 frame times "in the profile run agreed in the plan" had no method | Must fix | Method defined (D-083 (1)): profile mode on emulator-5554, one warm-up and 3 timed scrolls newest to oldest day on L1000, `FrameTiming` through the integration binding, UI-thread build time of every frame ≤ 32 ms, raster time recorded not gated (software GPU), first frame after navigation excluded, one re-run only if a system event is logged. T-425 writes the exact `flutter drive --profile` command into TC-015-27. The debounce fallback 200 ms is pre-approved |
| 9 | Spec silent on Other after a category, Discard with only a category, `no note`, results line with only refunds | Ruling | Other stores `other` (null and `other` both read as Other, an untouched Add stores null); a category alone counts as input (Discard asked); `no note` is not searchable; `spent` is the gross of matching spends and is left out when none match (D-082 (5) to (8)); doc §2.6 |
| 10 | AC-19 refund sentence contains `Other` | Must fix | Done: removed from AC-19 (D-082 (9)); TC-015-37 already follows the design |
| 11 | First-time hint text change under the same ID | Ruling | Approved; `help-pattern.md` §4.2 and F-004 §5 to be aligned by the Developer in T-423 (copy-table test TC-015-58) |
| 12 | Missing cases | Nice to have | Tester task T-426: a number query finds a refund row by its amount; Type: Refunds combined with a search; the frame-method wording in TC-015-27; the debounce fallback if used |
| 13 | Dates / Type / Category sheet and exit-motion design details | Nice to have | Designer task T-427 (Dates sheet line, row exit at once, results line with only refunds) |

## 11. Implementation notes *(Developer, filled in during the build)*
Deviations from the plan and why (each approved by the Project Manager).

**T-429 (Developer, 2026-11-23, test-only, D-100).** `transactions_search_test.dart`: 1,000 ms open and 300 ms search, category and dates limits asserted in profile mode through `speedLimitMs`, 3,000 ms guard in debug; the 32 ms UI build is asserted in profile and logged in debug. Profile worst of 5: open 83 ms, scroll build 8.9 ms, search 275 ms, category 46 ms, dates 32 ms.

**T-473 tests and probes (Developer, 2026-11-23, no app code changed).** TC-015-65 and -66 in `transactions_search_queries_test.dart`; TC-015-67 in `transactions_filters_test.dart` on the bare `TransactionsTab` under a test-owned `ProviderContainer` (the shell's IndexedStack never rebuilds the tab, so only a bare tab can prove it). Probes (scratch copy, reverted): number query ignoring refund rows killed by TC-015-65; `TypeFilter.refunds => true` by TC-015-66; T25b (`TextEditingController()` without the stored query) by TC-015-67 (and TC-015-48).

2026-11-20 (Developer, Track E): built T-420 to T-424 (T-425 not started). Deviations: `FilterChip` is `BudgetFilterChip` (Material clash); `99,50` reads as text through `parseAmount`, same result (no match); a Category filter leaves refunds out (they have no category); the collapse animation of a row leaving a filtered list is not built (the row leaves at once, no motion); on Add the Money back switch alone is not "input" for the Discard question; a placeholder wraps up to 3 lines (square test font). Existing F-009 tests changed only to scroll to rows, to expect the category in a row sentence and the new hint text. Open: tests TC-015-26..-29, -31..-39, -42..-48, -50..-64 mostly, sweeps, `integration_test` and profile run (not run, emulator).

2026-11-20 / 21 (Developer E2, Track E, T-425 and the F-015 test work). Code was inspected, not rewritten. **One bug found by a test and fixed:** the `Moved to Food` snackbar with `Undo` never closed after 6 s (TC-015-21 failed first). Since Flutter 3.29 a `SnackBar` with an action stays until dismissed unless `persist: false`; `category_change_flow.dart` now sets it. (The same default may affect the other snackbars with an action: `day_details_screen.dart` and `month_setup_screen.dart`, not touched here, for their owners to check.)

**Tests added (53 unit / widget, 2 integration):** `transactions_filters_test.dart` 17 (TC-015-10 to -18, -25, -44, -47 to -49, -51, -52, -63), `category_sheet_test.dart` 8 (-20, -21, -23, -24, -46, -53, -55, -56), `spend_editor_category_test.dart` 6 (-31 to -34, -57, -64), `transactions_search_queries_test.dart` 15 (-04, -05, -08, -29, -36 to -38, -41 to -43, -45, -50, -58, -61, -62 and the refund sentence without `Other`), `transactions_search_sweep_test.dart` 3 (TC-015-35 and -59: 17 states x Light / Dark / Dim / Auto light / Auto dark x 1.0 / 2.0 on the small phone, landscape in Light and Dim, and the 48 dp chip heights), `transactions_list_f009_regression_test.dart` 1 (-02), `test/copy/search_copy_test.dart` 3 (copy table, category names, hint; the Money back copy table is `test/copy/money_back_copy_test.dart`, F-016). Integration: `integration_test/transactions_search_test.dart` (-27, -28) with `test_driver/integration_test.dart`. Pure logic: `tool/domain_coverage.ps1` 100 % lines and branches, `transaction_search.dart` 108/108 lines, 53/53 branches (unchanged, the earlier unit tests already covered it). Map of cases to files: `tests/F-015` section 2.5.

**Reverted probes (each change was made in the code, the named test run and seen to fail, then the code restored byte for byte):** TC-015-29 debounce 250 to 100 ms; -12 month separator only above five sections; -63 `This month` row never disabled; -64 changed compares the raw category and the ticked row counts as a pick (the second half alone is not caught, by design: the effective-category rule is checked in two places); -32 Category row not hidden for money back; -24 past-month rows open the editor; -55 picking Other stores nothing; -21 snackbar persists (this one was also the real bug); -18 Clear all keeps the search; -52 results line drops the refunds part; -37 refund sentence gains `Other`; -36 copy wording (widget and copy table); -58 hint wording; -42 placeholder limited to one line; -35 filter chip 10 dp tall (new 48 dp test) and category chip 10 dp tall (sweep); -04 note match equality; -61 `No note` searchable; -05 / -41 exact-paise compare; -43 text query empty; -45 and -38 query ignored; -14 Other without null; -11 and -08 last month = this month; -13 picker starts at newest month; -44 range end exclusive; -47 range touches no month; -51 and -16 refunds / spends type swapped; -10 no-results kind; -15 `Clear` applies ticked rows; -17 refund without `+`; -48 filters reset at midnight; -49 date chip always `This month`; -50 only newest month counts; -56 failed save message; -46 undo writes another category; -23 pick writes Travel; -53 day order reversed; -57 category not a change; -31 untouched add stores Other; -33 and -34 editor pick does not change the field. **Not probed:** TC-015-02 (composite re-run of the F-009 flows), -25 (tab switch), -62 (Today card), -48 beyond the reset above, and the two integration tests on the device (their first runs failed correctly on a wrong day-total text and on keyboard text that never arrived, see below).

**Emulator (emulator-5554, Medium_Phone_API_37.0, left running).** Command (also in TC-015-27): `flutter drive --profile -d emulator-5554 --driver=test_driver/integration_test.dart --target=integration_test/transactions_search_test.dart` from `app/`. Log `docs/reviews/emulator-phase-3/integration-transactions-search-profile.log` (the first attempt that hung is kept as `...-attempt1-hung.log`: `position.animateTo` never completes under the integration binding, the scroll now steps the position with one real frame per step, 100 px a frame). Result, all passed: open worst of 5 restarts 89 ms (limit 1,000); one warm-up and three timed scrolls of 1,100 frames each, worst UI build 8.0 / 9.9 / 10.5 ms (limit 32 ms), worst raster 9.3 / 8.7 / 11.5 ms (recorded, not gated); oldest day `Sat, 5 Sep` reached and its total `₹489 shown` equals the seed's sum; search `lunch` after the last keystroke worst of 5 **275 ms** (250 ms debounce plus about 25 ms; the limit is 300 ms, so the margin is 25 ms and the 200 ms fallback of D-083 (2) stays available but is not needed), Category 48 ms, Dates 51 ms. Two things about the method: the search text is handed to the field through its `onChanged` callback (`tester.enterText` does not reach the field through the emulator's real keyboard connection: the field stayed empty); a custom range over all three months is set through the provider container, so the list holds the full 1,000 entries (the default `This month` holds 500). A date range counts as a filter, so day headers say `₹489 shown` there (AC-10).

**Other emulator runs (debug mode through `flutter test integration_test/<file> -d emulator-5554`, logs `docs/reviews/emulator-phase-3/integration-<name>.log`):** `day_details_cover_flow_test` passed; `statement_speed_test` passed (worst of 5 702 ms, limit 1,000); `home_500_test` passed (worst 13 ms, limit 1,000); `dashboard_500_test` **failed** its 500 ms limit on the first, cold run only (576 ms; runs 2 to 5 were 162 to 282 ms; debug mode); `calendar_500_test` **failed**: the grid appeared after 719 to 2,571 ms and the `5 Oct` text never showed after `Previous month` within 5 s in any run, so either the test looks for text the month switcher no longer shows or the month change is broken. Neither belongs to F-015; reported to the Orchestrator for the owners of F-013 and F-011.

**Not automated (manual or emulator, left to the Tester):** TC-015-26 (force-stop), -39 (TalkBack), -60 (kill with the sheet open). Deviations from the Tester's file names: the new cases live in `transactions_filters_test.dart`, `transactions_search_queries_test.dart` and `transactions_search_sweep_test.dart` instead of the shared `transactions_search_test.dart` and `phase3_screen_sweep_test.dart` (other tracks edit those at the same time); the sweep uses the bundled Plex font (`loadBundledFonts`), because with the square test font the placeholder needs more than three lines at 2.0x on a 360 dp phone.
