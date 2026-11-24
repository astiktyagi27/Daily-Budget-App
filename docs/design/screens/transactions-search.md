# Screen spec: Transactions — search, filters, categories, and Money back

**Owner of this file:** Designer · **Phase:** 3 (planned ahead, D-033; docs only) · **Features:** F-015 Transactions list (search & filter, category chip, Category on Add/Edit spend) and F-016 Money back (manual refund entry) · **Status:** Draft for Phase 3 Gate 2
**Extends:** `transactions.md` (Phase 2, F-009). Everything there stays unless this file says otherwise: Today card (§4), day grouping and row style (§5), states (§6), Add spend button (§7), editor (§8), sheets (§9). `transactions.md` itself is not edited (Phase 2 doc).
**Read with:** `docs/features/F-015-transactions-list.md`, `docs/features/F-016-money-back-entry.md` (§5 of both updated to match this file), `day-details.md`, `dashboard.md`, `docs/design/design-system.md` §7.3, §7.4, §7.8, §7.9, §7.10, §7.15. Decisions D-038, D-047, D-048, D-050, D-051, D-054, D-056.

---

## 1. Purpose
Find any spend in a few keystrokes, narrow the list by date, category or type, put a spend in the right category with one tap, and record money paid back.

## 2. Design decisions

| # | Question | Decision | Why |
|---|---|---|---|
| T-1 | Where is `Clear all`? | On the **results line** (right side), which only exists while searching or filtering. Not at the end of the chip row. | The chip row scrolls sideways, so a button at its end can be off-screen. The results line is exactly where the user looks after filtering. |
| T-2 | Type chip (i) | No (i) inside a chip. The explanation is the **Type sheet's description**: `Refunds are money paid back to you. They lower what you spent that day.` | A chip is one control; an (i) inside it would be a second tiny target. The sheet is where the choice is made. |
| T-3 | Day total while filtering | The header total reads `₹250 shown` (visible word `shown`), not just `₹250`. | Otherwise the day looks like it cost ₹250 when it cost ₹620. F-015 put `shown` only in the screen-reader label; it should be visible too. |
| T-4 | Category chip look | Small `neutralSoft` chip with text only (§7.15), at the start of the row's second line. No icons in the list. | Icons on every row make the list busy. Icons appear in the category sheet, where the choice is made. |
| T-5 | Refund rows | Second line shows `Refund` (`body`, `textSecondary`) instead of a category chip; amount `+₹500` in `textPrimary`. Not green. | Refunds have no category (F-016). Words carry the meaning; a green `+` would read as a "saved" result. |
| T-6 | Money back cue in the editor | When the switch is on, the amount prefix becomes `+₹` and the title `Add money back`. | Two non-colour cues that this entry lowers spending. |
| T-7 | Transactions first-time hint | Same ID `hint.transactions.v1`, new text: `Tap a spend to fix it, or tap its category to change it.` | The Phase 1 text promised "You'll be able to fix it right here"; in Phase 3 it is possible. Same ID, so users who dismissed it don't see it again. Needs F-004 §5 / `help-pattern.md` §4.2 (§15). |

## 3. Tab layout (month confirmed)
Top to bottom (changes from `transactions.md` §3 in bold):
1. Title `Transactions`.
2. Hint `hint.transactions.v1` (T-7 text).
3. Today card (unchanged, `transactions.md` §4).
4. **Search field** (§4), `space4` below.
5. **Filter chip row** (§5), `space3` below; scrolls sideways, edge-to-edge with `space5` start/end padding.
6. **Results line** (§6), only while searching or filtering.
7. The day list (`transactions.md` §5) with **category chips**, **refund rows**, **month separators** and **filtered day totals** (§7).
8. Add spend button (unchanged).

Search field and chips are shown whenever at least one entry exists in any stored month. With no entries anywhere, the tab is the `transactions.md` §6.2 empty state as before.

## 4. Search field
- 48 dp tall, `sunken` fill, 1 dp `borderStrong`, `radiusMd`; focused: 2 dp `accent`. Leading 20 dp `search` icon (`textSecondary`). Placeholder `Search notes or amounts` (`bodyLarge`, `textSecondary`). Text `bodyLarge` `textPrimary`. Keyboard: text with the number row; action key `Search` closes the keyboard.
- Trailing × (`close`, 20 dp, 48 dp target) when there is text; tooltip / hint `Clear search`.
- **What is searched:** the note text and the amount (digits, with or without correctly placed grouping commas). Misplaced grouping such as `99,50` is not a number (same rule as F-008): it is searched as text and finds only a note that contains `99,50`. The grey placeholder `No note` that rows without a note show is display text, **not** a note: searching `no note` finds only entries whose note really contains those words, never the empty-note entries (D-082 (7)); if none, `No spends match "no note".`
- Results update 250 ms after the last keystroke (within F-015 AC-16's 300 ms); no spinner. The list keeps the previous results until the new ones are ready.
- Screen reader: `Search notes or amounts, edit box`, hint `Type a note or an amount, like lunch or 250`.

## 5. Filter chips
Three filter chips (`BudgetFilterChip`, §7.15): `Dates: This month` · `Category: All` · `Type: All`. A chip is **active** (filled `accentSoft`, leading ✓) when it is not at its default. Each opens a sheet (`showBudgetSheet`, D-031).

### 5.1 Dates sheet
Title `Show spends from`. Radio rows (§7.4, 56 dp, label + description):
- `This month` · `5 Nov – 4 Dec`
- `Last month` · `5 Oct – 4 Nov` (disabled with `No earlier month yet` when none is stored)
- `Custom range` · `Pick the first and last day`
The current choice is selected (radio on). Picking This month / Last month applies and closes. Custom range closes the sheet and opens the Material date-range picker (`showDateRangePicker`, themed like `transactions.md` §8.2; help text `Pick the first and last day`; first = first stored month's start, last = today). Chip text: `Dates: This month` / `Dates: Last month` / `Dates: 1 Nov – 13 Nov` (same day: `Dates: 13 Nov`). **New month not set up (D-083 (3)):** the default is `Last month`, which then means the latest stored month, so the chip reads `Dates: Last month` (not active-styled: it is the default then). In the sheet `Last month` is the selected row with its real range (`5 Oct – 4 Nov`), and the **`This month` row is disabled**: its description is replaced by `Set up your month first` (`body`, `textSecondary`), its label stays `This month`, and the radio is drawn disabled (`neutralSoft` fill, no outline, design system §7.4); tapping it does nothing and does not close the sheet. The row is not hidden, so the list of choices never changes shape. Semantics: `This month, not available, Set up your month first, radio button`; the selected row `Last month, 5 October to 4 November, selected, radio button`. `Custom range` works as usual (last day = today). When the new month is set up the row becomes active at once and the default returns to `This month`.

### 5.2 Category sheet (filter)
Title `Show categories`, description `Spends without a category count as Other.` Nine checkbox rows (40 dp icon circle §5.4 + name + trailing checkbox, `borderStrong` outline, checked `accent` fill + `onAccent` tick). Pinned buttons: Primary `Show` (hint `Show these categories`) · Secondary `Clear` (hint `Show all categories`). Scrim / back = no change. A Category filter leaves **refunds out** (a refund has no category, F-016); `Type: Refunds` still lists them. Chip text: `Category: All` / `Category: Food` / `Category: 2 categories`.

### 5.3 Type sheet
Title `Show`, description `Refunds are money paid back to you. They lower what you spent that day.` Radio rows `All` · `Spends` · `Refunds`; picking applies and closes. Chip text `Type: All` / `Type: Spends` / `Type: Refunds`.

### 5.4 Category names and icons (all category UIs)
| Category | Icon (Material outlined) |
|---|---|
| Food | `restaurant` |
| Groceries | `local_grocery_store` |
| Shopping | `shopping_bag` |
| Travel | `commute` |
| Bills & Recharge | `request_quote` |
| Entertainment | `movie` |
| Health | `medical_services` |
| Friends & People | `group` |
| Other | `more_horiz` |
Icons are `neutral` inside a 40 dp `neutralSoft` circle, decorative. Order is README §3.4 order everywhere.

## 6. Results line
Only while searching or filtering, `space3` above the list: left `2 results · spent ₹670` (`body` `textSecondary`, amounts Plex 600 `textPrimary`; `1 result`); right a Text button `Clear all` (hint `Clear the search and all filters`). Polite live region, announced 1 s after typing stops: `2 results, spent ₹670`.
**Which parts show (D-082 (8)):** `spent <x>` is the **gross of the matching spends** (refunds are not taken off it) and is **left out when no spend matches**; ` · refunds <y>` is shown only when a refund matches. So: spends only `2 results · spent ₹670`; both `2 results · spent ₹200 · refunds ₹500`; **refunds only** (for example Type: Refunds, or a search that finds only the Amazon return) `1 result · refunds ₹500`, with no `spent ₹0`; no match `0 results`. Spoken: `1 result, refunds ₹500`.

## 7. The list (changes to `transactions.md` §5)
- **Row** (min 72 dp): line 1 note (or `No note`) left, amount right (unchanged). Line 2: the **category chip** (§7.15; `Other` when none stored). Tapping the chip opens the category sheet (§8); tapping anywhere else on the row opens the editor (current month only; past-month rows have no row action, but their chip still works, F-015 AC-14).
- **Refund row** (T-5): line 1 note + `+₹500`; line 2 `Refund`. Opens `Edit money back`.
- **Day header while filtering** (T-3): `Mon, 9 Nov` · `₹250 shown`; semantics `Monday 9 November, total shown ₹250`. Unfiltered it is the day's net total (refunds included: `−₹80` for 13 Nov with a ₹500 refund).
- **Month separator** when the shown range spans budget months: a full-width hairline, `space6` above, then `October · 5 Oct – 4 Nov` (`label` 600, `textPrimary`, heading) `space3` above the first day header of that month.
- **Edits while filtered (D-082 (4)):** a row that stops matching leaves the list **at once**: it **leaves at once, no motion** (no collapse; accepted at Gate 3, D-091) as soon as the change is saved, not after the snackbar; an emptied day group goes with it; the results line and the day totals update in the same moment. **Undo** (6 s, in the snackbar `Moved to Food` / `Moved to Travel`) puts the row back into its old place at once, and the results line returns to its old numbers (`1 result · spent ₹420` → `2 results · spent ₹670`). A row changed in the editor leaves the same way with the snackbar `Spend updated`; there is no Undo there, and `Clear all` / `Clear search` shows it again in its place. The list holds the row's id, so Undo still works after the row has left. TalkBack: the results line is announced (polite) and focus moves to the next row.
- **Order** within a day: newest added first, never moved by an edit (D-048 (8)).
- Bottom padding unchanged (nav + 88 dp).

## 8. Category sheet (from a row)
`showBudgetSheet`:
- Title `Category for ₹250 · Lunch` (`title`; `… · No note` when empty).
- Line `Only this spend changes. Automatic categories come later.` (`body`, `textSecondary`).
- Nine rows (56 dp): icon circle · name (`label`) · the current one has a trailing `check` (`accent`) and its name in weight 600. Semantics `Food, category, selected` / `Shopping, category`.
- Tap a row: saves at once, closes (`motionEmphasis`), snackbar `Moved to Food` + `Undo` (6 s). Tapping the ticked row: closes, no write, no snackbar.
- Pinned Secondary `Done` (hint `Close`). Scrim / back = Done.
- Save failure: snackbar `Couldn't save. Please try again.`; the chip keeps its old value.

## 9. Add / Edit spend additions (F-015 §2.4a, F-016)
Order of the editor (`transactions.md` §8.1) becomes:

| # | Part | Spend (switch off) | Money back (switch on) |
|---|---|---|---|
| 1 | Top bar | × (unchanged) | same |
| 2 | Title | `Add spend` / `Edit spend` | `Add money back` / `Edit money back` (cross-fade `motionBase`) |
| 3 | Amount | Label `Amount`, description `How much you spent.`, prefix `₹` | Label `Amount back`, description `How much you got back.`, prefix `+₹` (T-6). Value kept when switching. Errors as F-009. |
| 4 | **Money back switch** | List row with trailing switch, one semantics node: label `Money back / refund`, description `Turn on for money paid back to you, like a refund or a friend paying you back. It lowers what you spent that day. Not for your salary.` Off by default on Add. | On. |
| 5 | Date | unchanged | unchanged (same limits) |
| 6 | Note | Label `Note (optional)`, description `For example, "Lunch with Riya" or "Petrol".` | Description `For example, "Amazon return" or "Riya paid me back".` |
| 7 | **Category** | Label `Category`, description `What kind of spend this is. Automatic categories come later.` Field-styled row (56 dp, `sunken`, `borderStrong`, `radiusMd`): leading 20 dp category icon in `neutral`, value `Other` / `Food` (`bodyLarge`), trailing `expand_more`. Tap → category sheet titled `Category` (same rows and line; picking updates the field and closes, nothing saved until Save). Hint `Choose a category`. | Hidden: collapses with `motionEmphasis` (height + fade). The chosen category is kept in the draft and comes back if the switch is turned off again; it is not stored with a refund. |
| 8 | Save (dock) | `Save` / `Save changes` (hints as F-009) | `Save` (hint `Save this money back`) / `Save changes` (hint `Save your changes`) |
| 9 | Delete (edit) | `Delete` → `Delete this spend?` (unchanged) | `Delete` (hint `Delete this money back`) → `Delete this money back?` / `₹500 back on Fri, 13 Nov. This can't be undone.` · Destructive `Delete` · Secondary `Cancel` |

- **Add:** if Category is never touched, nothing is stored (shows `Other`). Picking `Other` after another category stores `other` (no category and `other` both read as Other everywhere, D-082 (5)). **A category picked on an otherwise empty Add counts as input** (D-082 (6)): back, ×, or the system back then asks `Discard this spend?` (sheet §9.3 of `transactions.md`); with nothing typed **and** no category picked, back leaves at once as before. **On Add, the Money back switch alone is not input** (accepted at Gate 3, D-091; F-016 AC-11): back with only the switch turned on leaves at once; once an amount or note is typed, back asks `Discard this money back?`. On Edit the switch stays a change. Edit: changing the category (to a different effective category: no category and `Other` are the same) or the switch enables `Save changes` and makes back ask `Discard changes?`.
- **Discard sheet (money back, add):** title `Discard this money back?`, body `What you've typed won't be saved.`, buttons as `transactions.md` §9.3.
- **Snackbars:** `Spend added` / `Spend updated` / `Spend deleted` (unchanged); `Money back added` / `Money back updated` / `Money back deleted`.
- **Converting an existing entry (T-450, D-084 (3), F-016 §2, TC-016-11):** on Edit, turning the switch on or off is an ordinary edit saved with `Save changes`. **Spend to money back:** the category is cleared in the same write as the direction change (nothing is stored; the draft category the person picked earlier is dropped when they save). **Money back to spend:** the entry gets no category and reads `Other` until the person picks one (the Category row comes back showing `Other`, or the draft category if one was picked before switching in the same session). The snackbar follows the **result**, never the starting type: `Money back updated` after a spend became money back, `Spend updated` after money back became a spend. Cover rules apply as for any edit (`Savings pot updated` may show first, as above). The title cross-fades while editing, but the saved snackbar is the only place the result is named.
- **Cover cuts (D-040):** saving or deleting a money back can show `Savings pot updated` (`transactions.md` §9.2) before the snackbar.
- With the keyboard open (amount focused) the switch row sits right under the amount, so it is reachable without closing the keyboard.

## 10. No results and empty states
Left-aligned empty state (§7.10) under the results line, icon `search_off`:
| Case | Title | Button |
|---|---|---|
| Search only | `No spends match "taxi".` | Secondary `Clear search` (hint `Clear the search`) |
| Search + filters | `No spends match your search and filters.` | Secondary `Clear all` |
| Filters only | `No spends match your filters.` | Secondary `Clear all` |
No description line (the title says it all). The results line shows `0 results`.

## 11. States

| State | What the user sees |
|---|---|
| First-time | Hint (T-7), Today card, search, chips, list. |
| Normal | §3. |
| No confirmed month | `transactions.md` §6.1 (no search, no chips). |
| Month with no spends, older months exist | Today card, search, chips, then `No spends yet this month` (`transactions.md` §6.2). Searching or `Dates: Last month` finds older entries. |
| Loading | No skeleton (`transactions.md` §10): the list builds lazily from the repository stream; 1,000 entries appear within 1 s (AC-16). Search/filter keeps the old results until the new ones arrive. |
| Error | Load: `transactions.md` §6.5. Category save or Money back save: snackbar `Couldn't save. Please try again.`. Field errors per F-009. |
| New month not set up | `transactions.md` §6.4; chips default `Dates: Last month`; in the Dates sheet `This month` is disabled with `Set up your month first` (§5.1); category chips on those rows still work. |
| Only refunds match | Results line `1 result · refunds ₹500` (no `spent`), §6. |
| A row leaves a filtered list | Collapses at once, Undo restores it (§7). |
| Shortfall month | Unchanged list; Today card per F-009. Refunds listed like any other. |
| Two-period month | Nothing special: one month, one list. |
| Permission denied | Not applicable. |

## 12. Themes

| Element | Light | Dark | Dim |
|---|---|---|---|
| Search field fill / outline / focus | `#EEEAE2` / `#8A8377` / `#3A3DB0` | `#0A0A0D` / `#6A6876` / `#9C9FFF` | `#24221F` / `#878073` / `#ABACF6` |
| Filter chip idle | `#FFFDF8` + `#8A8377` (3.69) | `#17171D` + `#6A6876` (3.28) | `#34312D` + `#878073` (3.31) |
| Filter chip active | `#E7E6F6`, text `#1C1B22` (13.87), ✓ `#3A3DB0` (6.89) | `#25264A`, `#F2F0EA` (12.67), `#9C9FFF` (6.06) | `#3E3D55`, `#EEE9E0` (8.67), `#ABACF6` (4.97) |
| Category chip | `#5C5864` on `#EAE6DF` (5.56) | `#A8A5B1` on `#24242B` (6.37) | `#BEB7AB` on `#3D3A35` (5.69) |
| Refund row `+₹500` / `Refund` | `#1C1B22` / `#5C5864` | `#F2F0EA` / `#A8A5B1` | `#EEE9E0` / `#BEB7AB` |
| Switch on (track / thumb) | `#3A3DB0` / `#FFFFFF` | `#9C9FFF` / `#14143D` | `#ABACF6` / `#1B1B3D` |
| Checkbox checked | `#3A3DB0` + white tick | `#9C9FFF` + `#14143D` | `#ABACF6` + `#1B1B3D` |

All pairs in design system §3. Switch and checkbox off: `borderStrong` outline (≥ 3.28 : 1).

## 13. Largest text (2.0×, 360 × 640 dp) and landscape (640 × 360)
- **Search field** grows with its text; placeholder wraps to two lines if needed.
- **Chips** grow but stay one row; the row scrolls (never wraps, never clips, AC-19). Chip labels are not capped.
- **Results line:** `Clear all` moves under the count above 1.3×; the count wraps at ` · ` (`1 result` / `refunds ₹500`), amounts never split.
- **Dates sheet:** rows grow with their text; the disabled `This month` row keeps both lines (`Set up your month first` wraps, never cut) and stays 56 dp minimum; sheet scrolls, buttons (none here) stay reachable.
- **Row exit:** the row leaves at once, no motion, so large text changes nothing here; the snackbar sits above the nav with `Undo` wrapping under the text if needed.
- **Rows:** amount moves under the note (as `transactions.md` §12); the category chip stays on its own line.
- **Sheets:** grow to 90 % and scroll; buttons pinned.
- **Editor:** no dock above 1.3× / landscape (unchanged rule); the switch row stacks label, description, then the switch right-aligned.
- **Landscape:** list column max 600 dp, centred.

## 14. Accessibility
- Order: title → hint → Today card → search → chips (`Dates, This month, filter, button`; active: `Category, Food, filter on, button`) → results line + `Clear all` → day headers and rows (`₹250, Lunch, Food, Monday 9 November`, hint `Edit`; then the chip as its own stop `Category Food, change`, tooltip `Change category`) → Add spend.
- Refund row: `Refund, ₹500, Amazon return, Friday 13 November` (no category: refunds have none; see §16).
- Dates sheet: title `Show spends from`; rows `This month, 5 November to 4 December, radio button`; disabled `This month, not available, Set up your month first, radio button`; selected `Last month, 5 October to 4 November, selected, radio button`.
- Results line (live, polite): `2 results, spent ₹670` / `1 result, refunds ₹500` / `2 results, spent ₹200, refunds ₹500` / `0 results`. When a row leaves, the line is announced again and the snackbar `Moved to Food, Undo` follows.
- Editor: close → title → Amount → `Money back / refund, switch, off` + description → Date → Note → Category (`Category, Other, button`, hint `Choose a category`) → Save → Delete.
- Every target ≥ 48 dp (the 24 dp category chip extends its target vertically into the row's second line).

## 15. Copy (final; F-015 §5 and F-016 §5 match)

| Control | Label | Description / tooltip / hint |
|---|---|---|
| Hint (`hint.transactions.v1`) | `Tip` | `Tap a spend to fix it, or tap its category to change it.` |
| Search | Placeholder `Search notes or amounts` | Hint `Type a note or an amount, like lunch or 250`; clear tooltip `Clear search` |
| Dates chip | `Dates: <This month / Last month / d MMM – d MMM / d MMM>` | Sheet `Show spends from`; options `This month` (`Set up your month first` when the new month is not set up; the row is then disabled and `Last month` is the default) · `Last month` (`No earlier month yet`) · `Custom range` (`Pick the first and last day`) |
| Category chip (filter) | `Category: <All / Food / n categories>` | Sheet `Show categories`, description `Spends without a category count as Other.`, buttons `Show` (hint `Show these categories`) · `Clear` (hint `Show all categories`) |
| Type chip | `Type: <All / Spends / Refunds>` | Sheet `Show`, description `Refunds are money paid back to you. They lower what you spent that day.` |
| Results line | — | `<n> result(s)` + ` · spent <x>` (gross of matching spends; left out when none match) + ` · refunds <y>` (left out when none match); `0 results` |
| Clear all | `Clear all` | Hint `Clear the search and all filters` |
| No results | — | `No spends match "<query>".` + `Clear search` (hint `Clear the search`) / `No spends match your search and filters.` + `Clear all` / `No spends match your filters.` + `Clear all` |
| Day header (filtered) | `<heading>` + `<amount> shown` | Screen reader `<heading>, total shown <amount>` |
| Month separator | — | `<Month> · <start> – <end>` |
| Row category chip | `<Category>` | Screen reader `Category <name>, change`; tooltip `Change category` |
| Category sheet (row) | `Category for <amount> · <note or No note>` | `Only this spend changes. Automatic categories come later.` · `Done` (hint `Close`) |
| Category sheet (editor) | `Category` | same line and rows |
| Category snackbar | — | `Moved to <category>` · `Undo` |
| Editor Category row | `Category` | `What kind of spend this is. Automatic categories come later.` Value `<category>` (`Other` when none). Hint `Choose a category` |
| Money back switch | `Money back / refund` | `Turn on for money paid back to you, like a refund or a friend paying you back. It lowers what you spent that day. Not for your salary.` |
| Titles | `Add money back` / `Edit money back` | — |
| Amount back | `Amount back` | `How much you got back.` |
| Note (money back) | `Note (optional)` | `For example, "Amazon return" or "Riya paid me back".` |
| Save | `Save` / `Save changes` | `Save this money back` / `Save your changes` |
| Snackbars | — | `Money back added` · `Money back updated` · `Money back deleted` |
| Delete sheet | `Delete this money back?` | `<amount> back on <Wkd, d MMM>. This can't be undone.` · `Delete` (hint `Delete this money back`) · `Cancel` (hint `Keep this money back`) |
| Discard sheet | `Discard this money back?` | `What you've typed won't be saved.` · `Keep editing` · `Discard` |
| Refund row | `Refund` | `+<amount>` · note |

## 16. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-11 | First version (Phase 3 planned ahead, D-033). Decisions T-1 … T-7 | Designer |
| 2026-11-16 | T-427 (D-082, D-083, D-086): Dates sheet when the new month is not set up (default `Last month`, `This month` row disabled with `Set up your month first`, §5.1); a row that stops matching leaves **at once** with Undo instead of after the snackbar (§7); results line with only refunds (`1 result · refunds ₹500`, `spent` = gross of matching spends, left out when none match, §6); a category alone counts as input for Discard and Other after a category stores `other` (§9); `no note` is not searchable (§4). Themes, 2.0×, landscape, accessibility sentences, states and copy rows updated; new previews | Designer |
| 2026-11-16 | T-450 (Gate 2 Must fix 2): §9 says what happens when an existing entry is converted between spend and money back: category cleared in the same write when it becomes money back, snackbar follows the result (`Money back updated` / `Spend updated`). Hint text row now also in `help-pattern.md` | Designer |
| 2026-11-21 | Gate 3 Track E (D-091): `BudgetFilterChip` name; a row that stops matching leaves at once, no motion (§4 edit rule, §13, preview); `99,50` is text; a Category filter leaves refunds out (§5.2); on Add the Money back switch alone is not input (§9) | Designer |

## 17. Notes for the Project Manager
1. **T-7** changes `hint.transactions.v1` text: `help-pattern.md` §4.2 and §4.3 now hold the same line (T-450, 2026-11-16); F-004 §5 and TC-004-09 follow (T-452, T-453).
2. **F-015 AC-19** reads a refund row as `Refund, ₹500, Amazon return, Other, Friday 13 November`. Refunds have no category (F-016 §1, F-015 §2.4a), so the design reads it without `Other`. Please drop `Other` from that AC.
3. **F-015 AC-10**: the day header now also shows the visible word `shown` (T-3); the AC's screen-reader text is unchanged.
4. **Editor sequencing** (phase-3 overview open item 5): this file is the single layout for both F-015 §2.4a and F-016, so whichever is built first follows §9 and the second only adds its row.
5. T-427: F-015 doc section 5 copy should carry `Set up your month first` (Dates sheet) and the refunds-only results line; the Tester's TC-015-63, -45, -46, -52, -57, -61 already match this file.
6. New copy: `No spends match your filters.`, `No earlier month yet`, `Show these categories` / `Show all categories` hints, `Keep this money back`, `Delete this money back` hint, `+₹` prefix.

---

## Owner preview

### Transactions with categories, today Fri 13 Nov (Light)
```
┌──────────────────────────────────────┐
│ Transactions                         │
│ ╭──────────────────────────────────╮ │
│ │ Today (i)                        │ │
│ │ budget ₹830 · spent ₹420 ·       │ │
│ │ ● ₹410 left today                │ │
│ ╰──────────────────────────────────╯ │
│ ┌──────────────────────────────────┐ │
│ │ ⌕ Search notes or amounts        │ │
│ └──────────────────────────────────┘ │
│ (Dates: This month ⌄) (Category: All │
│ ⌄) (Type: All ⌄)  → scrolls sideways │
│ Today                         ₹420   │
│ ╭──────────────────────────────────╮ │
│ │ Lunch                       ₹420 │ │
│ │ [Other]                          │ │
│ ╰──────────────────────────────────╯ │
│ Wed, 11 Nov                 ₹1,130   │
│ ╭──────────────────────────────────╮ │
│ │ Phone bill                ₹1,130 │ │
│ │ [Other]                          │ │
│ ╰──────────────────────────────────╯ │
│ Mon, 9 Nov                    ₹620   │
│ ╭──────────────────────────────────╮ │
│ │ No note                     ₹370 │ │
│ │ [Other]                          │ │
│ │──────────────────────────────────│ │
│ │ Lunch                       ₹250 │ │
│ │ [Other]                          │ │
│ ╰──────────────────────────────────╯ │
│                     ╭──────────────╮ │
│                     │ + Add spend  │ │
│                     ╰──────────────╯ │
└──────────────────────────────────────┘
```
(On the phone the three chips sit on one line that scrolls sideways. [Other] is a small grey tag you can tap. 12 Nov had no spends, so it has no group.)

### Search "lunch" (Dark)
```
┌──────────────────────────────────────┐
│ ┌──────────────────────────────────┐ │
│ │ ⌕ lunch                        × │ │
│ └──────────────────────────────────┘ │
│ (Dates: This month ⌄) (Category: …   │
│ 2 results · spent ₹670     Clear all │
│ Today                    ₹420 shown  │
│ ╭──────────────────────────────────╮ │
│ │ Lunch                       ₹420 │ │
│ │ [Other]                          │ │
│ ╰──────────────────────────────────╯ │
│ Mon, 9 Nov               ₹250 shown  │
│ ╭──────────────────────────────────╮ │
│ │ Lunch                       ₹250 │ │
│ │ [Other]                          │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```
("₹250 shown": 9 Nov really cost ₹620, only the matching lunch is listed.)

### Tap a category tag (Light)
```
┌──────────────────────────────────────┐
│╭────────────────────────────────────╮│
│               ────                   │
│  Category for ₹250 · Lunch           │
│  Only this spend changes. Automatic  │
│  categories come later.              │
│  (F) Food                            │
│  (G) Groceries                       │
│  (S) Shopping                        │
│  (T) Travel                          │
│  (B) Bills & Recharge                │
│  (E) Entertainment                   │
│  (H) Health                          │
│  (P) Friends & People                │
│  (⋯) Other                       ✓   │
│  ┌────────────────────────────────┐  │
│  │              Done              │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```
((F), (G) … stand in for thin grey line icons in grey circles: a fork and knife, a basket, a bag and so on; the app uses no emoji. Tap Food → the sheet closes and "Moved to Food · Undo" appears.)

### Filtered by Food (Dim)
```
┌──────────────────────────────────────┐
│ (Dates: This month ⌄) (✓ Category:   │
│ Food ⌄) (Type: All ⌄)                │
│ 2 results · spent ₹670     Clear all │
│ Today                    ₹420 shown  │
│ │ Lunch                       ₹420 │ │
│ │ [Food]                           │ │
│ Mon, 9 Nov               ₹250 shown  │
│ │ Lunch                       ₹250 │ │
│ │ [Food]                           │ │
└──────────────────────────────────────┘
```
(The active chip is filled soft indigo with a ✓.)

### No results (Light)
```
┌──────────────────────────────────────┐
│ │ ⌕ taxi                         × │ │
│ 0 results                  Clear all │
│                                      │
│  ╭────╮                              │
│  │ ⌕̸  │                              │
│  ╰────╯                              │
│ No spends match "taxi".              │
│ ┌──────────────────────────────────┐ │
│ │           Clear search           │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### Add spend with a category (Light)
```
┌──────────────────────────────────────┐
│ ×                                    │
│ Add spend                            │
│ Amount                               │
│ How much you spent.                  │
│ ┌──────────────────────────────────┐ │
│ │ ₹ 250                            │ │
│ └──────────────────────────────────┘ │
│ Money back / refund          ( ○  )  │
│ Turn on for money paid back to you,  │
│ like a refund or a friend paying you │
│ back. It lowers what you spent that  │
│ day. Not for your salary.            │
│ Date                                 │
│ ┌──────────────────────────────────┐ │
│ │ Today · Fri, 13 Nov            ▦ │ │
│ └──────────────────────────────────┘ │
│ Note (optional)                      │
│ ┌──────────────────────────────────┐ │
│ │ Lunch                            │ │
│ └──────────────────────────────────┘ │
│ Category                             │
│ What kind of spend this is.          │
│ Automatic categories come later.     │
│ ┌──────────────────────────────────┐ │
│ │ (F) Food                       ⌄ │ │
│ └──────────────────────────────────┘ │
│──────────────────────────────────────│
│ ┌──────────────────────────────────┐ │
│ │               Save               │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### Same screen with Money back on (Dark)
```
┌──────────────────────────────────────┐
│ ×                                    │
│ Add money back                       │
│ Amount back                          │
│ How much you got back.               │
│ ┌──────────────────────────────────┐ │
│ │ +₹ 500                           │ │
│ └──────────────────────────────────┘ │
│ Money back / refund          (  ● )  │
│ Turn on for money paid back to you,  │
│ … Not for your salary.               │
│ Date                                 │
│ ┌──────────────────────────────────┐ │
│ │ Today · Fri, 13 Nov            ▦ │ │
│ └──────────────────────────────────┘ │
│ Note (optional)                      │
│ For example, "Amazon return" or      │
│ "Riya paid me back".                 │
│ ┌──────────────────────────────────┐ │
│ │ Amazon return                    │ │
│ └──────────────────────────────────┘ │
│──────────────────────────────────────│
│ ┌──────────────────────────────────┐ │
│ │               Save               │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```
(No Category row: refunds don't have one. After Save: "Money back added", and Home's Today card reads "budget ₹830 · spent −₹80 · ₹910 left today" with "Includes ₹500 back from refunds".)

### The refund in the list, Type: Refunds (Light)
```
┌──────────────────────────────────────┐
│ (Dates: This month ⌄) (Category: All │
│ ⌄) (✓ Type: Refunds ⌄)               │
│ 1 result · refunds ₹500    Clear all │
│ Today                   −₹500 shown  │
│ ╭──────────────────────────────────╮ │
│ │ Amazon return              +₹500 │ │
│ │ Refund                           │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```

### Custom range across two months (Light)
```
┌──────────────────────────────────────┐
│ (✓ Dates: 1 Nov – 13 Nov ⌄) …        │
│ 10 results · spent ₹6,050  Clear all │
│ November · 5 Nov – 4 Dec             │
│ Today                    ₹420 shown  │
│ …                                    │
│──────────────────────────────────────│
│ October · 5 Oct – 4 Nov              │
│ Wed, 4 Nov               ₹520 shown  │
│ │ Groceries                   ₹520 │ │
│ │ [Groceries]                      │ │
└──────────────────────────────────────┘
```
(November's 9 spends total ₹5,530; this illustration adds one October spend of ₹520 on 4 Nov. 1–4 Nov belong to the October budget month, 5 Oct – 4 Nov.)

### Dates sheet when the new month is not set up, today Sat 5 Dec (Light)
```
┌──────────────────────────────────────┐
│ (Dates: Last month ⌄) (Category: All │
│ ⌄) (Type: All ⌄)                     │
│╭────────────────────────────────────╮│
│               ────                   │
│  Show spends from                    │
│  ○ This month                        │
│    Set up your month first           │
│    (greyed out, cannot be picked)    │
│  ● Last month                        │
│    5 Nov – 4 Dec                     │
│  ○ Custom range                      │
│    Pick the first and last day       │
└──────────────────────────────────────┘
```
(The new month has begun but is not set up yet, so there is nothing to show for "this month". The list opens on the last month; the greyed row says what to do. Once the month is set up the row switches on by itself.)

### Results line with only refunds (Light)
```
┌──────────────────────────────────────┐
│ ┌──────────────────────────────────┐ │
│ │ ⌕ return                       × │ │
│ └──────────────────────────────────┘ │
│ 1 result · refunds ₹500    Clear all │
│ Today                   −₹500 shown  │
│ ╭──────────────────────────────────╮ │
│ │ Amazon return              +₹500 │ │
│ │ Refund                           │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```
(Nothing matching is a spend, so there is no "spent" part, not even "spent ₹0". With Lunch ₹200 and the refund both matching it would read "2 results · spent ₹200 · refunds ₹500".)

### A row leaves a filtered list, with Undo (Dark; Category: Food filter)
```
┌──────────────────────────────────────┐
│ (✓ Category: Food ⌄)                 │
│ 2 results · spent ₹670     Clear all │
│ Today                    ₹420 shown  │
│ │ Lunch                       ₹420 │ │
│ │ [Food]                           │ │
│ Mon, 9 Nov               ₹250 shown  │
│ │ Lunch                       ₹250 │ │
│ │ [Food]  ← tap, pick Travel       │ │
└──────────────────────────────────────┘
        ↓ at once (the row leaves, no motion)
┌──────────────────────────────────────┐
│ 1 result · spent ₹420      Clear all │
│ Today                    ₹420 shown  │
│ │ Lunch                       ₹420 │ │
│ │ [Food]                           │ │
│ ╭──────────────────────────────────╮ │
│ │ Moved to Travel          [Undo]  │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```
(The 9 Nov row no longer matches "Food", so it leaves straight away instead of waiting for the message to go. Undo, for 6 seconds, brings it back and the line returns to "2 results · spent ₹670".)

### Why these choices
- **Search, then three chips:** typing "lunch" or "250" finds a spend in a second; dates, category and type narrow the list without a busy filter screen.
- **One tap on the grey tag sets a category**, with Undo, and it's clear that only that one spend changes until automatic sorting arrives.
- **A greyed-out "This month" with a reason, not a vanished row:** when the new month isn't set up the sheet keeps its shape and says "Set up your month first", and the list simply opens on last month.
- **The results line only counts what really matched:** a refunds-only search says "refunds ₹500" and never "spent ₹0"; a row you recategorise out of a filter leaves at once, with Undo.
- **Money back is a switch on the same form**, with "+₹", its own title and no category, so a refund can't be mistaken for a spend.
