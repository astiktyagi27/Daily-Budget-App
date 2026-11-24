# F-015: Transactions list (search & filter)

| | |
|---|---|
| **Phase** | 3 |
| **Status** | Spec (final, ready for the plan; planned ahead, D-033). D-038, D-039, D-046 to D-048, D-050, D-054 and D-056 (2) are applied |
| **Plan** | [`plans/F-015-transactions-list.md`](../../plans/F-015-transactions-list.md) |
| **Test cases** | [`tests/F-015-transactions-list.md`](../../tests/F-015-transactions-list.md) |
| **Tasks** | T-420 to T-427 in `docs/TASKS.md` (Gate 1, 2026-11-16) |

## 1. What it is *(Product Manager)*
The full Transactions tab (README §4 screen 8, F-009 §6 out of scope). It replaces F-009's simple list. It adds:
- **search** by note or amount;
- **filters** by date range, category and type (spends or refunds, D-047);
- a **category chip** on every row, so the user can set or change a spend's category from the list;
- a **Category** field on the F-009 **Add / Edit spend** screen (D-056 (2)), using the same category sheet.

Categories are the README §3.4 list. A spend without a category shows as **Other** (Phase 2 stores none, F-009 AC-14 N/A). A change applies to **that one entry only**. Remembering the choice for a merchant comes in Phase 4. The list stays fast with hundreds of entries. F-009's Today card, Add spend button, editor and delete flow are kept unchanged. Changing a category never changes any money figure, so this feature adds **no money rule**.

**User stories:**
- As a **user**, I want to find "that lunch last week" by typing "lunch" or "250".
- As a **user**, I want to see only one category, or only one date range, so that I can check where money went.
- As a **user**, I want to put a spend in the right category with one tap, so that the Dashboard (F-013) means something.

## 2. How it behaves *(Product Manager)*
Layout per design system and `docs/design/screens/transactions.md`. The Designer extends that spec at Step 6.

### 2.1 Layout (top to bottom)
1. Title, the first-time hint (unchanged), and the F-009 **Today card** (unchanged).
2. **Search field** `Search notes or amounts`, with a clear (×) button when it has text.
3. **Filter chips row** (`BudgetFilterChip`; scrolls sideways): `Dates: This month` · `Category: All` · `Type: All`. An active filter chip is filled (`accentSoft`). `Clear all` appears when anything is filtered or searched.
4. **Results line** (only while searching or filtering): `2 results · spent ₹670` (+ `· refunds ₹500` when refunds match).
5. **The list**, grouped by day, newest first, using F-009's grouping, headings and row style, plus:
   - a **category chip** at the start of the row's second line: `Other`, `Food`…;
   - **refund rows** (D-047), with the word `Refund` and `+₹500`, not coloured;
   - **month separators** when a range spans budget months: `October · 5 Oct – 4 Nov`.
   - While filtering, the day header total adds up **only the shown entries**, and its screen-reader label says `shown`.
6. The floating **Add spend** button (F-009, unchanged).

### 2.2 Search
- **Where it looks:** the note (any case, any language, emoji included) and the amount.
- **Text query:** matches entries whose note **contains** it (`lun` matches "Lunch"), ignoring case.
- **Number query:** `250`, `₹250`, `1,130`, `300.50`.
  - It matches entries whose **shown amount** (whole rupees, D-038) **equals** it. A query with decimals must equal the **exact** amount (`300.50` matches only ₹300.50).
  - It **also** matches notes containing those digits (`250` matches "250g paneer").
  - `₹`, spaces and correctly placed grouping commas (`1,130`) are ignored; misplaced grouping (`99,50`) is text, see Edge cases.
- **Scope:** results respect the active filters (the date range defaults to this month).
- The list updates as the user types (within 300 ms of the last keystroke, AC-16).
- **No results:** `No spends match "<query>".` with a `Clear search` button. If filters are also active, it reads `No spends match your search and filters.` with `Clear all`.

### 2.3 Filters
| Filter | Options | Default |
|---|---|---|
| **Dates** | `This month` (current budget month) · `Last month` · `Custom range` (a date-range picker from the first stored month's start to today) | This month |
| **Category** | Multi-select of the 9 categories. `Other` includes entries with no category. **Refunds are left out** while a category is ticked, because a refund has no category (F-016 AC-2); `Type: Refunds` still lists them | All |
| **Type** | `All` · `Spends` · `Refunds` (D-047) | All |

- Filters combine with AND. Categories within the filter combine with OR.
- Filters and the search text stay while the app is open (switching tabs keeps them). They reset to the defaults when the app restarts.
- **New month not set up** (F-009 AC-13): `This month` means last month, and the chip reads `Dates: Last month`.

### 2.4 Changing a category
- Tap the **category chip** on a row. A sheet opens: `Category for ₹250 · Lunch`, with the 9 categories (current one ticked) and **Done**.
- Picking a category saves it at once to that entry only (F-007 `category` column, the README §3.4 keys) and closes the sheet. A snackbar says `Moved to Food`, with `Undo` (6 s). Undo restores the previous value, including "no category".
- Nothing else changes: amounts, budgets, the pot and covers are untouched. The Dashboard (F-013) updates.
- Category chips also work on **past months' rows**. The amount and date there stay read-only (F-009), but the category is not money.
- Picking the category that is already ticked closes the sheet with no change and no snackbar.
- **Not remembered:** another "Lunch" spend stays Other. A line in the sheet says so: `Only this spend changes. Automatic categories come later.`
- Tapping the rest of the row opens the F-009 editor as before (current month only).
- **Order:** within a day, the newest **added** entry comes first; editing (amount or category) never moves a row (D-048 (8)).

### 2.4a Category on Add / Edit spend (D-056 (2))
- The F-009 editor gets a **Category** row under Note: `Category · Other`. Tapping it opens the §2.4 category sheet (title `Category`, the 9 categories, current one ticked, the not-remembered line).
- **Add spend:** the row starts as `Other`. If the user never touches it, **no category is stored** (the same as Phase 2 entries). Picking one stores its key on Save, not before.
- **Edit spend:** the row shows the stored category (`Other` when empty). A change counts as an unsaved change, so `Save changes` is enabled and back asks `Discard changes?` (F-009 AC-12).
- **Money back (F-016):** the Category row is hidden while the Money back switch is on. Refunds store no category (F-013 shows refunds as one line).
- Example: Add ₹250, note `Lunch`, Category Food, Save. Exactly one spend is stored with category `food`, and the list row's chip reads `Food`. The Dashboard (F-013) shows Food ₹250.

### 2.5 Worked example (data as in F-010 §2.4, with notes; today Fri 13 Nov)
| Day | Entries |
|---|---|
| Fri 13 Nov | ₹420 `Lunch` |
| Thu 12 Nov | — |
| Wed 11 Nov | ₹1,130 `Phone bill` |
| Tue 10 Nov | ₹830 `Petrol` |
| Mon 9 Nov | ₹370 `No note` (20:00) · ₹250 `Lunch` (13:00) |
| Sun 8 Nov | ₹200 `Chai and snacks` |
| Sat 7 Nov | ₹830 `Dinner out` |
| Fri 6 Nov | ₹1,000 `Shoes` |
| Thu 5 Nov | ₹500 `Groceries` |

Every entry is Other, and the total is ₹5,530 (500 + 1,000 + 830 + 200 + 250 + 370 + 830 + 1,130 + 420).

| Action | Result |
|---|---|
| Search `lunch` | `2 results · spent ₹670`: 13 Nov ₹420, 9 Nov ₹250 |
| Search `830` | `2 results · spent ₹1,660`: 10 Nov ₹830, 7 Nov ₹830 |
| Search `250` | `1 result · spent ₹250`: 9 Nov ₹250 |
| Search `1,130` | `1 result · spent ₹1,130` |
| Search `taxi` | `No spends match "taxi".` |
| Set both Lunch entries to Food, then Category: Food | `2 results · spent ₹670` |
| Category: Other (after that) | `7 results · spent ₹4,860` (5,530 − 670) |
| Add a ₹500 refund `Amazon return` on 13 Nov; Type: Refunds | `1 result · refunds ₹500` |
| Type: All, search `amazon` | `1 result · refunds ₹500` |
| Dates: Custom 1 – 13 Nov (Oct month 5 Oct – 4 Nov stored) | October's 1–4 Nov entries under `October · 5 Oct – 4 Nov`, then November's |

### 2.6 Gate 1 clarifications *(Project Manager, 2026-11-16; D-082, D-083)*
- **Choosing `Other`** after another category stores `other`. No category and `other` both mean Other (chip, Category filter, Dashboard). An untouched Add stores nothing. Picking the ticked `Other` on an untouched spend is no change (no `Save changes`, no Discard question).
- **Add spend:** a category picked with nothing else typed counts as input, so Back asks `Discard this spend?`.
- **Search:** `no note` does not find entries with no note (`No note` is display text). A number query also finds refund rows by their amount.
- **Results line:** `spent` is the gross of the matching spends and is left out when no spend matches; `refunds` is left out when no refund matches (`1 result · refunds ₹500`).
- **A row that stops matching** a filtered list (note edited, category changed) leaves at once, no motion (no collapse; accepted at Gate 3, D-091); Undo (6 s) puts it back.
- **Dates sheet when the new month is not set up:** the default is `Last month` (the latest stored month); the `This month` row is disabled with `Set up your month first`.
- **Past-month rows** may have their category changed; amount and date stay read-only.
- **AC-16 frame times:** measured in profile mode on the emulator: UI-thread build time of every frame ≤ 32 ms over 3 timed scrolls (D-083).

## 3. Acceptance criteria *(Product Manager)*
Fixed "today", seeded data (the §2.5 table unless stated). Themes and accessibility per F-002 §3.

| ID | Given / When / Then |
|---|---|
| AC-1 | **Layout.** Given a confirmed month with spends, when Transactions opens, then it shows title, hint, the F-009 Today card, the search field, the chips `Dates: This month` · `Category: All` · `Type: All`, the list grouped by day with a category chip on every row, and Add spend; no results line and no `Clear all` while nothing is searched or filtered. |
| AC-2 | **F-009 behaviour kept.** Given the new list, when the Tester re-runs the F-009 Regression-yes cases (add, edit, delete, grouping, Today card, discard, new-month block), then all pass unchanged. |
| AC-3 | **Text search.** Given §2.5, when the user types `lunch`, `LUNCH` and `lun`, then each shows `2 results · spent ₹670` with 13 Nov ₹420 and 9 Nov ₹250 under their day headers; given a note `चाय` (Hindi) or `☕ chai`, then searching `चाय` / `☕` finds it. |
| AC-4 | **Amount search.** Given §2.5 plus a ₹300.50 spend and a "250g paneer" note on ₹90, when the user searches (a) `830`, (b) `₹1,130`, (c) `250`, (d) `300`, (e) `300.50`, (f) `300.5`, then results are (a) 7 and 10 Nov, (b) 11 Nov, (c) 9 Nov ₹250 and the ₹90 "250g paneer", (d) the ₹300.50 spend (shown `₹300`), (e) and (f) the ₹300.50 spend only. |
| AC-5 | **No results.** Given §2.5, when the user searches `taxi`, then `No spends match "taxi".` and `Clear search` are shown; tapping it restores the full list; with a filter also active, then `No spends match your search and filters.` and `Clear all` are shown. |
| AC-6 | **Date filter.** Given October (5 Oct – 4 Nov) and November stored, when Dates is set to (a) Last month, then only October's entries show with the chip `Dates: Last month`; (b) Custom 1 – 13 Nov, then entries from both months show, with the separators `November · 5 Nov – 4 Dec` and `October · 5 Oct – 4 Nov`, newest first; the custom picker allows nothing before 5 Oct and nothing after today. |
| AC-7 | **Category filter.** Given both Lunch entries set to Food, when Category is Food, then `2 results · spent ₹670`; when Category is Other, then `7 results · spent ₹4,860` and the entries with no stored category are included; when Food + Other, then all 9 entries. |
| AC-8 | **Type filter and refunds (D-047).** Given §2.5 plus a ₹500 refund "Amazon return" on 13 Nov, when Type is Refunds, then only the refund shows, as `Refund · +₹500 · Amazon return`, with `1 result · refunds ₹500`; when Type is Spends, then the 9 spends show and the results line has no refunds part; when Type is All and the search is `amazon`, then the refund is found. The 13 Nov day header total while unfiltered shows the day's net spend `−₹80` (₹420 − ₹500). When Category Food is ticked, the refund is not listed (a refund has no category); when the search is `99,50` (misplaced grouping, read as text), then `No spends match "99,50"` shows and no ₹9,950 spend is found. |
| AC-9 | **Filters combine, clear all.** Given Category Food and search `lunch` and Dates Last month (no Food lunches in October), then the no-results state for search and filters is shown; tapping `Clear all` resets search and all three filters to their defaults and shows the full current month. |
| AC-10 | **Day totals while filtering.** Given search `lunch`, when shown, then the 9 Nov header total reads `₹250 shown` (the word `shown` is visible; only the shown entry is counted) and TalkBack reads `Monday 9 November, total shown ₹250`; without a search the header reads `₹620`. |
| AC-11 | **Change a category.** Given the 9 Nov ₹250 Lunch row (Other), when the user taps its chip, then the sheet `Category for ₹250 · Lunch` lists the 9 categories with Other ticked and the not-remembered line; when Food is picked, then the sheet closes, `Moved to Food` with `Undo` is shown, the chip reads `Food`, exactly that one record's category is `food` in the database, and the 13 Nov Lunch stays Other. |
| AC-12 | **Undo and no-op.** Given the change in AC-11, when Undo is tapped, then the record's category is empty again (as before) and the chip reads `Other`; when the user picks the already-ticked category, then the sheet closes with no snackbar and no write. |
| AC-13 | **Category is not money.** Given example A, when every spend's category is changed, then the engine's day budgets, results, pot, totals and Home figures are identical (deep equality) before and after, and the Dashboard (F-013) breakdown updates without a manual refresh. |
| AC-14 | **Past-month rows.** Given an October row, when its chip is tapped, then the category can be changed (as AC-11); when the rest of the row is tapped, then nothing opens (read-only per F-009). |
| AC-15 | **Filters kept, then reset.** Given Category Food active, when the user switches to Home and back, then the filter is still active; when the app is force-stopped and reopened, then all filters and the search are at their defaults. |
| AC-16 | **Hundreds of entries.** Given 1,000 entries over 3 months (500 in the current month), when Transactions opens, then the list appears within 1 second; scrolling to the oldest day stays smooth (no frame over 32 ms in the profile run agreed in the plan); typing a search or changing a filter updates the results within 300 ms of the last keystroke/tap on the emulator. |
| AC-17 | **Category on Add spend (D-056 (2)).** Given the Add spend screen, when the user enters ₹250, note `Lunch`, opens Category, picks Food and saves, then exactly one spend is stored with category `food` and its row chip reads `Food`; given a spend saved without touching Category, then its stored category is empty and the chip reads `Other`; given the Money back switch on (F-016), then the Category row is not shown. |
| AC-18 | **Category on Edit spend.** Given a stored ₹250 Lunch spend in Food, when Edit opens, then the Category row reads `Food`; when Shopping is picked, then `Save changes` becomes enabled and back asks `Discard changes?`; when saved, then the record's category is `shopping`, the amount and date are unchanged, the row stays in its place in the day, and no money figure changes (as AC-13). |
| AC-19 | **Help, themes, large text, accessibility.** Given the list with an active search and filters, the category sheet and the no-results state, when shown in all four themes at text scale 1.0 and 2.0 on a small phone and in landscape (D-030), then F-002 AC-12–AC-14 pass; the chips row scrolls instead of clipping; every control has its §5 label and description/hint via F-004; TalkBack reads a row as `₹250, Lunch, Food, Monday 9 November` (refund: `Refund, ₹500, Amazon return, Friday 13 November`) with the chip as its own stop `Category Food, change`. |

## 4. Edge cases *(Product Manager)*
- **A search with only spaces:** treated as empty.
- **A search of `0` or `₹0`:** matches entries shown as `₹0` (₹0.01–₹0.99, D-038) and notes containing "0".
- **A very long query** (100+ characters): accepted. It usually gives no results.
- **A number with letters** (`250rs`): treated as text, so it matches notes containing "250rs".
- **A decimal comma** (`99,50`): misplaced grouping is not a number (the same rule as F-008, `parseAmount` rejects it), so it is searched as text and finds only a note containing `99,50`. It does not find a ₹9,950 spend. Result: `No spends match "99,50"` when no note contains it.
- **Custom range with the same start and end:** one day.
- **A spend edited while filtered so that it no longer matches** (amount changed): it leaves the results after saving, and the results line updates.
- **A category changed while that category is filtered out:** the row leaves the results at once (D-082), and Undo (6 s) brings it back.
- **The date range covers a missed month:** there are no entries and no separator for it.
- **Midnight passes:** `This month` follows the new month on resume (F-009 §4).
- **Refunds in a shortfall month:** they are listed like any other refund. Money effects are F-006's.

## 5. Help text & copy *(Product Manager, finalised by Designer)*
| Control | Label | Description / tooltip |
|---|---|---|
| First-time hint (`hint.transactions.v1`, Designer) | `Tip` | New text, same ID: `Tap a spend to fix it, or tap its category to change it.` (F-004 §5 to be aligned by the PM) |
| Search field | Placeholder `Search notes or amounts` | Hint `Type a note or an amount, like lunch or 250`. Clear button tooltip `Clear search` |
| Dates chip | `Dates: <This month / Last month / d MMM – d MMM / d MMM>` | Sheet title `Show spends from`. Options `This month` · `Last month` (disabled: `No earlier month yet`) · `Custom range` (`Pick the first and last day`). Custom: picker help `Pick the first and last day` |
| Category chip (filter) | `Category: <All / Food / 2 categories>` | Sheet title `Show categories`, multi-select, buttons `Show` (hint `Show these categories`) · `Clear` (hint `Show all categories`). Description `Spends without a category count as Other.` |
| Type chip | `Type: <All / Spends / Refunds>` | Sheet title `Show`; the explanation is the sheet's description (no (i) inside a chip): `Refunds are money paid back to you. They lower what you spent that day.` |
| Clear all | `Clear all` | On the right of the results line. Hint `Clear the search and all filters` |
| Results line | — | `<n> result(s) · spent <x>` (+ ` · refunds <y>`) |
| No results | — | `No spends match "<query>".` + `Clear search` (hint `Clear the search`) / `No spends match your search and filters.` + `Clear all` / filters only: `No spends match your filters.` + `Clear all` |
| Month separator | — | `<Month> · <start> – <end>` |
| Row category chip | `<Category>` | Screen reader `Category <name>, change`. Tooltip `Change category`. Refund rows show `Refund` instead (no category) |
| Category sheet | `Category for <amount> · <note or No note>` | Line `Only this spend changes. Automatic categories come later.` Button `Done` (hint `Close`) |
| Category names | `Food` · `Groceries` · `Shopping` · `Travel` · `Bills & Recharge` · `Entertainment` · `Health` · `Friends & People` · `Other` | — |
| Category snackbar | — | `Moved to <category>` · action `Undo` |
| Editor Category row (D-056) | `Category` | Value `<category>` (`Other` when none). Description: `What kind of spend this is. Automatic categories come later.` (F-009 §5 copy). Hint `Choose a category` |
| Refund row | `Refund` | `+<amount> · <note>` |
| Day header (filtered) | `<heading>` + `<amount> shown` (the word `shown` is visible, Designer) | Screen reader `<heading>, total shown <amount>` |
| Category sheet (editor) | `Category` | Same rows and line as the row sheet; picking only changes the field until Save |

## 6. Out of scope
- Remembering a category per merchant, and automatic categories (Phase 4).
- Bulk select and bulk re-categorise. Custom categories.
- Searching by category name in the search field (use the filter).
- Export of the list.
- Recording refunds: that is **F-016** (D-054). This doc lists and filters them.
- Any money rule.

## 7. How it works — technical *(Developer, filled in when the feature is Done)*
**What was built.** Search and filters on the Transactions tab (search field, Type, Category and Dates chips with their sheets, a results line with `Clear all`, day totals that read `shown` while a filter is on, the search and filter empty states), a Category row on the Add / Edit spend screen, and a category chip on each row that changes the category from the list with an Undo snackbar. Past months can be browsed and their categories changed (amount and date stay read-only). Search and filters run in memory in pure Dart (D-082 (1)). Tasks T-420 to T-425, T-429 (speed test, profile aware), T-473 (tests); Gate 1 D-082, D-083, D-085, Gate 3 D-091, D-092, Gate 4 D-100 to D-105.

**Main files** (`app/lib/`)
- Pure Dart in `domain/budget/transaction_search.dart` (query, Type, Category and date-range filtering, the results line figures, 108 of 108 lines and 53 of 53 branches covered); shared `spend_category.dart` (F-013 T-380); `spend_draft.dart` carries `category` and `direction` and `toFields` returns `SpendFields`.
- `features/transactions/`: `transactions_filter_state.dart` (filters kept while the app is open, reset at midnight and by `Clear all`), `transactions_tab.dart` and `spend_list.dart` (search header, results line, rows with the category chip), `category_change_flow.dart` (change from a row, `Moved to Food` snackbar with Undo for 6 s), `spend_editor_screen.dart` and `spend_editor_flow.dart` (Category row), `sheets/` (`type_sheet`, `category_filter_sheet`, `category_sheet`, `dates_sheet`, `sheet_parts`), `widgets/` (`search_header`, `results_line`, `search_empty_state`, `category_field`); `SpendRow` gained optional `category`, `onCategoryTap`, `spokenDate` (default null, Day details unchanged).
- Shared widgets: `core/widgets/search_field.dart`, `filter_chip.dart` (`BudgetFilterChip`), `category_chip.dart`, `category_icon.dart`; copy in `core/copy/search_copy.dart` and `category_copy.dart`.
- Additive changes to F-007 code that belong to this feature: **`SpendFields`** (adds `category` and `direction`; `TransactionRepository.add` loses its direction parameter, D-082 (2)) and **`updateCategory(id, category, {now})`**, which changes only the category and `edited_at`, never touches the engine or the covers, works for a row of any month and throws for money in (a refund has no category). `update` also writes the category; `update` writing `direction` is F-016's part of the same change (D-084).

**Data stored.** The `transactions.category` column that F-007 already had, as a key (`SpendCategory` keys; a missing key and `other` both read as Other, an unknown key reads as Other). Nothing else: no schema change, no migration, no trigger touched. Picking a category writes only `category` and `edited_at` (`updateCategory`); an untouched Add stores nothing; picking Other after another category stores `other` (D-082 (5)). Filters, the search text and the date range are in memory only.

**Decisions:** D-082 (1) in-memory search, no SQL or index; (2) `SpendFields` change approved; (3) past-month rows can change category; (4) a row that stops matching leaves at once and Undo puts it back (D-092 (4): no collapse motion); (5) the Other rule; (6) a category picked on an otherwise empty Add counts as input; (7) `no note` does not find empty notes; (8) results line `spent` is the gross of matches, left out when none match; (9) the refund sentence has no category. D-083 (1) frame-time method in profile mode, (2) 250 ms debounce with the pre-approved 200 ms fallback (T-469), (3) Dates default `Last month` with `This month` disabled when the new month is not set up. D-091, D-092 (1 to 6), D-100, D-102 to D-105; and the F-009 rules it builds on (D-048 day order).

**Deviations** (plan section 11)
- `FilterChip` is `BudgetFilterChip` (Material has a `FilterChip`). `99,50` as a query is text (F-008 grouping rule), same result (no match). A Category filter leaves refunds out (they have no category); `Type: Refunds` lists them. A row leaving a filtered list goes at once with no collapse motion. On Add the Money back switch alone is not input. A placeholder wraps up to 3 lines at large text. Existing F-009 tests changed only to scroll to rows, to expect the category in a row sentence and the new hint text.
- **One bug found by a test and fixed:** the `Moved to Food` snackbar with Undo never closed after 6 s (TC-015-21 failed first): since Flutter 3.29 a snackbar with an action stays until dismissed unless `persist: false`; `category_change_flow.dart` sets it (with the screen-reader refinement of D-091). The same default may affect the snackbars with an action in `day_details_screen.dart` and `month_setup_screen.dart`, left to their owners.
- The new cases live in `transactions_filters_test.dart`, `transactions_search_queries_test.dart` and `transactions_search_sweep_test.dart` instead of the shared files the Tester named (other tracks edited those at the same time); the sweep uses the bundled Plex font because the square test font wraps the placeholder to more than three lines at 2.0x.
- T-429 (test only): `transactions_search_test.dart` applies the 1,000 ms open and 300 ms search, category and dates limits and the 32 ms frame build in profile mode (`speedLimitMs`), a 3,000 ms guard in debug.

**How it is tested** (`tests/F-015-transactions-list.md`, 67 cases, 19 / 19 ACs)
- Unit: `test/domain/budget/transaction_search_test.dart`, `spend_draft_test.dart`, `spend_category_test.dart`; `test/data/repositories/category_write_test.dart` (`updateCategory`), `spend_category_read_test.dart`, `transactions_repository_test.dart`; domain coverage 100 %.
- Widget (fake repositories; five theme cases, text scale 2.0, small phone, landscape): `test/features/transactions/transactions_filters_test.dart`, `category_sheet_test.dart`, `spend_editor_category_test.dart`, `transactions_search_queries_test.dart`, `transactions_search_sweep_test.dart` (17 states x themes x 1.0 / 2.0, 48 dp chips), `transactions_list_f009_regression_test.dart` (TC-015-02), `test/copy/search_copy_test.dart`. T-473 added TC-015-65, -66 (queries) and TC-015-67 (filters kept across a tab switch, on a bare `TransactionsTab` under a test-owned container because the shell's IndexedStack never rebuilds the tab).
- Integration on the emulator: `integration_test/transactions_search_test.dart` with `test_driver/integration_test.dart` (TC-015-27, -28), profile mode (D-083, D-100): `flutter drive --profile -d emulator-5554 --driver=test_driver/integration_test.dart --target=integration_test/transactions_search_test.dart`. Clean run of 2026-11-23, the decisive one (`step8-clean-profile-transactions_search.log`): open worst of 5 90 ms of 1,000; scroll worst UI build 8.1 ms of 32 (three timed scrolls of 1,100 frames); search 273 ms of 300; category 31 ms; dates 49 ms. The Developer's own runs gave open 83 to 89 ms, scroll build 8.0 to 10.5 ms, search 275 ms (`dev-t429-profile-transactions_search.log`, `integration-transactions-search-profile.log`). The first attempt hung (`position.animateTo` never completes under the integration binding) and is kept as `...-attempt1-hung.log`; the scroll now steps the position one real frame at a time. The search text reaches the field through `onChanged`, because `tester.enterText` does not reach it through the emulator's keyboard connection. Debug failures were taken on a loaded machine or the cold first open and do not decide.
- Mutation pass and probes: Developer probes (reverted each time) cover about 50 cases, among them TC-015-29 debounce 250 to 100 ms, -63, -64, -32, -24, -55, -21 (the real snackbar bug), -18, -52, -37, -36, -58, -42, -35. T-470 items: 4 run, 3 killed on 2026-11-21 (composite via editable rows, Today card ignoring the search, the `persist` probe), the survivor T25b (`TextEditingController()` without the stored query) was equivalent in the shell and is **killed** on the final code by TC-015-67 (re-applied by Tester 2): all 4 killed. Part of the 10 of 10 re-run of D-102. Not probed: TC-015-02, -25, -62.
- Result (Tester 2, 2026-11-23): Pass 63, Partial 1, Fail 0, Blocked 1 (TC-015-39), Pending 2. No bug logged. `tool/check.ps1` last run: 1,285 tests green, domain coverage 100 %, TZ matrix passed. Gate 4: conditional pass (D-103).

**Known limitations and open items**
- **Not Done yet.** Open before Done (D-103, D-104): Tester 1's emulator session T-430: TC-015-26 (force-stop), TC-015-59 (by hand, device half) and TC-015-60 (kill with the sheet open). Also a green `tool/check.ps1` on the final code (Orchestrator), and Gate 5 with the Tester's final session.
- **TC-015-39 (TalkBack) is Blocked-needs-human**, accepted as open (D-104). Proofs in place: the semantics sentences (TC-015-37) and the sweeps are green. A real-phone walk is recommended, not required.
- **Search margin is thin: 25 to 27 ms.** The 250 ms debounce plus the work gives 273 to 275 ms against 300 ms. The 200 ms debounce fallback (D-083 (2), T-469) is not triggered (273 ms is under the 285 ms trigger) but stays armed: if a later run misses 300 ms, change the debounce to 200 ms.
- Search runs over the month's rows in memory (fine at 1,000 entries, D-082 (1)); revisit only if the measurement fails. A row leaving a filtered list has no motion (Nice to have). The snackbar-with-action default may affect two other screens (see Deviations).
- Nice to have: none new from the Gate 4 review.
- Depends on F-007 (`SpendFields`, `updateCategory`), F-009 (list, editor, Today card), F-011 (month index, switcher), F-013 (`SpendCategory`, category widgets). Used by F-013 (reads the categories it writes; AC-15 live update), F-016 (same editor and list), F-012 (rows shared through `SpendRow`).

## 8. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-11 | First version of the spec (Phase 3 planned ahead, D-033). D-047 refunds applied (Type filter, refund rows). 17 ACs | Product Manager |
| 2026-11-11 | Owner answers applied: D-056 (2) Category field on Add/Edit spend (new §2.4a, AC-17, AC-18; help/accessibility AC moved to AC-19; removed from Out of scope and Suggested additions); D-048 (8) newest-added order kept on edits; D-054 refunds entered via F-016. 19 ACs | Product Manager |
| 2026-11-11 | Status set to final Spec, ready for the plan (all Owner questions answered: D-053 to D-058). Remaining team questions go to the Project Manager at Phase 3 Gate 1 (phase overview, open items) | Product Manager |
| 2026-11-11 | §5 finalised by the Designer (`docs/design/screens/transactions-search.md`): new `hint.transactions.v1` text, Type explanation moved from an (i) to the Type sheet description, `Clear all` on the results line, visible `shown` on filtered day totals, filters-only no-results line, `No earlier month yet`, sheet button hints, editor Category sheet. AC-19's refund sentence includes `Other`, which refunds don't have: flagged to the PM | Designer |
| 2026-11-16 | Gate 1 (Project Manager B, D-082, D-083): AC-19 refund sentence loses `Other`; §4 row leaves a filtered list at once; new §2.6 clarifications (Other rule, Discard with a category, `no note`, results line, Dates sheet, frame-time method). No AC added. 19 ACs | Project Manager |
| 2026-11-16 | T-452 (Gate 2, review point 7): AC-10 wording aligned to the design (T-3) and TC-015-19: while a search or filter is on, the day header reads `₹250 shown` (visible word `shown`), not a bare `₹250`. TalkBack sentence and the no-search `₹620` unchanged. No rule changed, AC numbers unchanged | Product Manager |
| 2026-11-21 | Gate 3 Track E (D-091): doc matches the build. Filter chip is `BudgetFilterChip`; `99,50` is text (F-008 grouping rule); a Category filter leaves refunds out; a row leaving a filtered list goes at once with no motion. No AC meaning changed | Product Manager |
| 2026-11-23 | Section 7 filled in (Step 9, T-431): built files, stored data (category only), `SpendFields` and `updateCategory`, decisions D-082 to D-105, deviations, tests (profile-mode runs, mutation pass), open items (T-430 emulator cases, TC-015-39 TalkBack, thin search margin and armed T-469). Status stays Testing until those are closed (D-103, D-105) | Developer |

## Impact on existing features
- **F-009:** the list part is replaced. The Today card, editor, delete and discard flows are unchanged (AC-2). Past months become visible through the Dates filter (F-009 §6 "Previous months' transactions view" now comes in here).
- **F-007:** queries by text, date range, category and type need indexes for AC-16 (a plan decision). The category keys must match Phase 4's categoriser.
- **F-013:** reads the categories set here.

## Owner / team questions
- None for the Owner. **Team (PM):** confirm that past-month rows may have their **category** changed while amount and date stay read-only (§2.4). **Closed by D-082 (3) (Gate 1): confirmed.**

## Suggested additions *(for the CEO — not in scope until approved)*
- ~~Category field in Add/Edit spend~~: accepted by the Owner (D-056), now §2.4a.
- **"Apply to all spends with this note"** in the category sheet: a one-off bulk change, not a remembered rule.
- **Recent searches** and **amount range** filters (₹500+), as in Walnut and Axio.
