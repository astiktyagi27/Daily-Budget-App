# Screen spec: Day details, Cover with savings, Undo and Remove cover

**Owner of this file:** Designer · **Phase:** 3 (planned ahead, D-033; docs only) · **Feature:** F-012 Day details & cover with savings (reuses the F-009 editor and sheets, F-008 amount field; F-004 help pattern; F-006 engine) · **Status:** Draft for Phase 3 Gate 2
**Read with:** `docs/features/F-012-day-details.md` (§5 updated to match this file), `calendar.md`, `home-summary.md`, `transactions.md` (editor, row style, §9 sheets), `transactions-search.md` (Money back rows), `month-setup.md` §4.2 (amount field), `docs/design/design-system.md` §7.4, §7.8, §7.9, §7.12. Decisions D-005, D-037, D-038, D-039, D-040, D-046, D-047, D-048, D-050, D-055, D-056.

---

## 1. Purpose
Explain one day in full (its budget, what was spent, the result) and let the user fix it: add or edit a spend, or cover an overspent day from savings, and take that cover back.

## 2. Design decisions

| # | Question (F-012 "full screen or sheet") | Decision | Why |
|---|---|---|---|
| D-1 | Full screen or sheet? | **Full screen**, pushed over Home (standard page transition), back arrow top-left. | From here the user opens the F-009 editor (full screen) and the cover sheet. A sheet under a full-screen editor under another sheet is a stack the user loses track of. A route also gives a clean back and keeps Home's scroll position (AC-1). |
| D-2 | Status twice? | The **status line** under the title answers "how did the day go" at a glance; the **Day result** line closes the ledger (Budget − Net spent ± cover) so the sum can be checked, khata style. Same words, same mark. | The ledger reads top to bottom like a bill; ending without its total feels unfinished. |
| D-3 | How refunds read in the ledger | `Refunds  −₹500` (minus sign), then `Net spent  ₹200`. Same as the Dashboard (F-013 §2.2) and the statement. | The column then adds up by eye (₹700 − ₹500 = ₹200). F-012 AC-16 and F-014 AC-11 write `Refunds ₹500`; see §14. |
| D-4 | Where does Cover live? | A **Cover card** between the figures and the spends, with the pot amount, one sentence and the **Primary** `Cover with savings`. `Add spend` is a **Secondary** button at the end. | One Primary per screen (§7.1): on an overspent day, covering is the action this screen is for. |
| D-5 | Cover sheet: focus the field? | **No.** The field is pre-filled with the most that can be covered, so the common path is two taps: `Cover with savings` → `Cover`. Tapping the field opens the keyboard. | Fewer taps; the keyboard would hide the buttons for the 90 % case that takes the full amount. |
| D-6 | Remove cover | A `Remove` Text button on the `Covered from savings` line → decision sheet whose button 1 is **Destructive** `Remove cover` (it deletes records, §7.8), button 2 Secondary `Keep it`. | The user asked for it with a deliberate tap, so it goes first; red text marks that it undoes something. |

## 3. Layout (budgeted day, current month)
Top to bottom, `space5` gutters, scrolling:

| # | Part | Spec |
|---|---|---|
| 1 | Top bar | 56 dp, `bg`, leading back arrow (`arrow_back`, 48 dp target), tooltip `Back`. No title in the bar. |
| 2 | Title | `headline`: `Wed, 11 Nov` (always the weekday form; today too). |
| 3 | Status line | `space2` below. 8 dp mark + words in Plex 600 18/24, in the status colour: `◆ Overspent ₹300` (`overspent`) · `● Saved ₹330` (`saved`) · `○ On budget` (`neutral`) · `● Today · ₹410 left` (`saved`) · `○ Today · on budget` · `◆ Today · overspent ₹170` · `Upcoming` (`textSecondary`, no mark). Less than ₹1: `◆ Overspent less than ₹1`, `● Saved less than ₹1`, `● Today · less than ₹1 left`, `◆ Today · overspent less than ₹1`. Changes with a cross-fade; the count-up (`motionCount`) is a **Nice to have** (T-466), not required: the figures are correct without it (Gate 3, D-089). |
| 4 | Notices | Inline notes (16 dp icon + `body` `textSecondary`), `space3` below the status line, only when they apply: **Budget changed** (period's first day): `history` icon + `Budget changed on this day: salary ₹40,000 → ₹35,000` + trailing `chevron_right`; the whole line is a 48 dp button → F-014 scrolled to that period. The text after the colon follows the month statement's wording for every kind of change (exact table in §3.1). **Past month:** `lock` icon + `This month has ended, so its days can't be changed.` |
| 5 | Figures card | `space6` below. Card, padding 16 dp. Ledger rows (label + (i) left, `body` `textSecondary`; amount right, `moneyMedium` `textPrimary`): `Budget` · `Spent` · `Refunds` (only with refunds; `−₹500`) · `Net spent` (only with refunds) · `Covered from savings` (only with a cover; amount `textPrimary`, then a right-aligned Text button `Remove` on the line below, 48 dp target). Then a hairline and the **Day result** row: label `Day result` + (i) in `label` 600 `textPrimary`; value = the status words with mark in Plex 600, status colour (`◆ Overspent ₹300`). Upcoming: only `Budget` and the line `This day hasn't happened yet.` (`body`, `textSecondary`), no Day result. |
| 6 | Cover card | Only on an overspent budgeted day of the current month up to today (D-048 (2)), `space4` below. §5. |
| 7 | Spends | Section label `Spends` (or `Spends and refunds` when the day has a refund), `caption` 500 `textSecondary`, heading, `space6` above. Then one card (padding 0) of rows, newest added first (D-048 (8)): F-009 row style (`transactions.md` §5). Spend: note (or `No note`) + amount. Refund: note + second line `Refund` (`body`, `textSecondary`) + amount `+₹500` in `textPrimary` (not coloured). Tap → F-009 Edit (refunds: `Edit money back`). No category chips here (F-012 §6). Empty past day: the card holds one line `Nothing spent this day` (`body`, `textSecondary`), not tappable. |
| 8 | Add spend | Secondary button, full width, leading `add` icon, `space4` below the list: `Add spend` (hint `Add a spend on this day`). Opens the F-009 Add screen with this date set (F-016's Money back switch available). Not on upcoming days or past months. |
| 9 | Bottom space | `space8` + system inset. |

### 3.1 The `Budget changed on this day` line, exact wording (Gate 3, D-089)
The line is `Budget changed on this day: ` + one phrase per difference, joined with ` · ` (the statement's separator, `month-statement.md` §6). Each phrase is **the month statement's phrase for the same event** (`month-statement.md` §6, §13, D-081 (5)), with only the fixed words in lower case because they follow a colon; a fixed cost's name is shown as the user typed it. Amounts use `formatRupees` (whole rupees, `→` as in the statement). The text is built by one pure function with its strings in `DayDetailsCopy`; the screen only shows it.

| What changed | Phrase after the colon | Statement wording it reuses |
|---|---|---|
| Salary | `salary ₹40,000 → ₹35,000` | `Salary ₹40,000 → ₹35,000` |
| Spending target changed | `spending target ₹20,000 → ₹25,000` | `Spending target ₹20,000 → ₹25,000` |
| Spending target set | `spending target set to ₹25,000` | `Spending target set to ₹25,000` |
| Spending target removed | `spending target removed` | `Spending target removed` |
| Money left (mid-month start) | `money left ₹24,900 → ₹20,000` | `Money left ₹24,900 → ₹20,000` |
| Fixed cost changed | `Rent ₹10,000 → ₹13,000` | `Rent ₹10,000 → ₹13,000` |
| Still to pay of a mid-month cost | `Rent ₹3,000 → ₹2,000` (same words as a fixed cost change; the name tells which) | `Rent ₹3,000 → ₹2,000` |
| Fixed cost added | `fixed cost added: Gym ₹500` | `Fixed cost added: Gym ₹500` |
| Fixed cost removed | `fixed cost removed: EMI ₹5,000` | `Fixed cost removed: EMI ₹5,000` |
| Fixed cost renamed (one removed and one added with the same amount, nothing else changed) | `Rent renamed to House rent` | `Rent renamed to House rent` |
| Several in one save | `salary ₹40,000 → ₹35,000 · Rent ₹10,000 → ₹13,000` | joined with ` · ` |

Wraps only at ` → ` and ` · `; amounts never split. Screen reader: `Budget changed on this day: salary 40,000 rupees to 35,000 rupees`, button, hint `Open the month statement`; added, removed and renamed are read as written. Same-day double changes name the net change (as the statement's period reason does); a day whose changes net to nothing reads `Budget changed on this day: changed and changed back` (the statement's reason, lower-cased), so the line never ends empty.

## 4. Worked examples (example A, today Fri 13 Nov, pot ₹2,000)

| Day | Status line | Figures | Cover card |
|---|---|---|---|
| Thu 5 Nov | `● Saved ₹330` | Budget ₹830 · Spent ₹500 · Day result `● Saved ₹330` | — |
| Fri 6 Nov | `◆ Overspent ₹170` | Budget ₹830 · Spent ₹1,000 · `◆ Overspent ₹170` | Pot ₹2,000, `Cover with savings` (pre-fill 170) |
| Wed 11 Nov | `◆ Overspent ₹300` | Budget ₹830 · Spent ₹1,130 · `◆ Overspent ₹300` | Pot ₹2,000, `Cover with savings` (pre-fill 300) |
| Thu 12 Nov | `● Saved ₹830` | Budget ₹830 · Spent ₹0 · `● Saved ₹830`; list `Nothing spent this day` | — |
| Fri 13 Nov | `● Today · ₹410 left` | Budget ₹830 · Spent ₹420 · `● ₹410 left` | — (joins the pot at midnight) |
| Sat 14 Nov | `Upcoming` | Budget ₹830 · `This day hasn't happened yet.` | — |

**Refund day** (viewed as a past day): ₹700 `Shoes` + ₹500 refund `Amazon return` → Spent ₹700 · Refunds −₹500 · Net spent ₹200 · `● Saved ₹630`. With a ₹1,500 refund: Net spent `−₹800`, `● Saved ₹1,630`.
**Two-period month** (example M, Fri 13 Nov): Budget `₹552` · notice `Budget changed on this day: salary ₹40,000 → ₹35,000`.
**Shortfall** (example S, Fri 6 Nov): Budget ₹0 · Spent ₹200 · `◆ Overspent ₹200`; Cover card shows the empty-pot form.

## 5. Cover card
Card, padding 16 dp:
- Line 1: `Savings pot` + (i) (`label` 500, `textSecondary`) left; `₹2,000` (`moneyMedium`, `textPrimary`) right.
- Line 2: `Use money from your savings pot to cover this day.` (`body`, `textSecondary`).
- **Today only:** line 3 `Spending more today will make it overspent again.` (`body`, `textSecondary`).
- Primary `Cover with savings` (full width, hint `Cover this day from your savings pot`), `space4` above.

Variants:
- **Pot ₹0:** line 2 becomes `Your savings pot is empty.` (`body`, `textPrimary`) with an (i) (`Your pot fills up on days you spend less than your budget.`); no button.
- **Fully covered** (day now on budget): the card is replaced by an inline note: `savings` icon + `Covered ₹300 from savings.` (`body`, `textSecondary`). The `Covered from savings ₹300` row and `Remove` stay in the figures card.
- **Partly covered:** card stays; pot shows the new amount; the next sheet pre-fills the rest.

## 6. Cover sheet
Decision-style bottom sheet (§7.8) with one field, via `showBudgetSheet`:

| Part | Spec |
|---|---|
| Title | `Cover Wed, 11 Nov` (`title`) |
| Line | `Overspent ₹300 · Savings pot ₹2,000` (`body`, `textSecondary`, amounts Plex 600 `textPrimary`); less than ₹1: `Overspent less than ₹1 · Savings pot ₹2,000` |
| Amount | Shared amount field (`month-setup.md` §4.2), medium size: label `Amount`, ₹ prefix, **pre-filled with the most that can be covered, in exact paise** (`300`, `47.78`, `0.40`). Not focused on open (D-5). Number keypad with decimal. |
| Caption | Under the field, `body` `textSecondary`: `This covers the whole overspend.` when the value equals the day's overspend; `This uses your whole savings pot.` when it equals the pot (and is less than the overspend); no caption for a smaller custom amount. Updates as the user types. |
| Errors | Field error style (§7.12), one at a time, in the engine's order (D-048 (1)): `Enter an amount more than ₹0` · `That's more than this day's overspend (₹300).` · `That's more than your savings pot (₹2,000).` · F-008 format error `Use numbers only, with up to 2 decimals`. Shown on Cover; once shown, re-checked as the user types. |
| Buttons | Stacked, pinned at the sheet bottom: Primary `Cover` (hint `Move this amount from your savings pot`; progress ring while saving; a second tap does nothing) · Secondary `Cancel` (hint `Close without covering`). Scrim / swipe / back = Cancel. |
| Keyboard | When the field is focused the sheet rises above the keyboard. On a short screen only **Cover** stays pinned above the keyboard (the field and Cover are never hidden, F-012 AC-19); **Cancel** scrolls with the sheet and is still reachable by scrolling, by the scrim and by Back (all three = Cancel). Gate 3, D-089. |
| Save error | A line **inside the sheet**, under the field and its caption and above the buttons (a snackbar of the page sits under the sheet's scrim and would not be seen): `Couldn't save. Please try again.` in `body`, `overspent` colour, with a 16 dp `error` icon (field error style, §7.12; read as a live region). The sheet stays open, the amount stays, **Cover** is enabled again; the line goes when the amount is edited or Cover is tapped again. Gate 3, D-089. |

**After Cover:** the sheet closes (`motionEmphasis` exit); the status line, figures and Cover card update (cross-fade; the count-up is a Nice to have, T-466); the snackbar (§7.9) `₹300 covered from your savings` with action `Undo` (6 s; stays while TalkBack is on). Built as 5.75 s, because the timer starts after the 250 ms entrance, so the snackbar is gone 6 s after the cover; with a screen reader on it stays until dismissed (D-077 (5)).
**Save failure:** shown inside the sheet (row `Save error` above), never as a snackbar; nothing changes.

## 7. Undo and Remove
- **Undo** (snackbar, 6 s): deletes that one cover; everything returns to before; snackbar `Cover undone` (4 s).
- **Remove** on `Covered from savings` (current month only; hidden when the cover is ₹0 after D-040 cuts, and on past months) opens a decision sheet:
  - Title `Remove this cover?`
  - Body `₹300 goes back to your savings pot, and Wed, 11 Nov is overspent ₹300 again.` (several covers: the total).
  - Button 1 **Destructive** `Remove cover` (hint `Give this money back to your savings pot`) · Button 2 Secondary `Keep it` (hint `Close`). Scrim / swipe / back = Keep it.
  - After Remove: sheet closes; figures count back; snackbar `Cover removed` (4 s, no action; the sheet was the confirmation).
  - Failure: snackbar `Couldn't save. Please try again.`; nothing changes. (Here the sheet has already closed, so a snackbar is seen; only the cover sheet's own save error is inside the sheet, §6.)

## 8. Editing from the day (F-009 reuse)
- Tap a row → F-009 Edit (or Edit money back); `Add spend` → F-009 Add with this date. On return the figures update in place.
- If the save cut covers (D-040), F-009's `Savings pot updated` sheet (`transactions.md` §9.2) shows once, then the snackbar.
- An edit that lowers an overspend below its cover silently returns the extra (the `Covered from savings` amount drops, no sheet).
- **Date moved away:** the row leaves this day with a `motionEmphasis` collapse; snackbar `Spend moved to Sun, 8 Nov`.
- Last spend deleted: the list shows `Nothing spent this day`; the day turns ● Saved for its whole budget.

## 9. Read-only and upcoming
- **Past month day:** lock notice (§3 item 4); figures and rows shown; rows have no press effect and no tap hint; no Cover card, no `Remove`, no Add spend.
- **Upcoming day:** title, `Upcoming`, figures card with `Budget ₹830` and `This day hasn't happened yet.`; no list section unless a future-dated spend exists (device date moved back): then the list shows it with a second line `Dated in the future` (`body`, `textSecondary`).
- **Not budgeted:** not reachable from the calendar. Any other way in shows only the title and `Not budgeted: you started on 10 Nov.` (`body`, `textSecondary`).

## 10. States

| State | What the user sees |
|---|---|
| First-time | Normal; no hint on this screen (the calendar hint led here). |
| Normal | §3. |
| Empty | Past day with no spends: `Nothing spent this day`, `● Saved ₹830`. Today with none: `● Today · ₹830 left`, `Nothing spent yet today` in the list card. |
| Loading | None visible: the day's data is read before the screen is pushed (under 1 frame for 500 spends). If a read is slow, figures show the static placeholder bars of `home-summary.md` §7 (never `₹0`). |
| Error | Load failure: the body is the `Couldn't load your data` empty state with Primary `Try again` (`month-setup.md` §10.4). Save failures: a line inside the cover sheet (§6); a snackbar for Remove and Undo (§7). Cover field errors (§6). |
| Shortfall month | Budget `₹0`; spends are overspent; Cover card shows `Your savings pot is empty.` unless the pot has money (refunds can make saved days, F-016). |
| Two-period month | Budget is the day's own period budget (`₹830` before 13 Nov, `₹552` from it); the period's first day has the Budget-changed notice. |
| Midnight while open on today | On resume the title stays, the status line changes from `Today · …` to the final result (cross-fade `motionBase`); if overspent, the Cover card appears. |
| Permission denied | Not applicable. |

## 11. Themes

| Element | Light | Dark | Dim |
|---|---|---|---|
| Status / Day result: saved | `#1A7044` on `#F6F3ED` (5.50) / on card (6.00) | `#52C98B` (9.25 / 8.57) | `#80D3A1` (8.22 / 7.24) |
| overspent | `#B4372F` (5.37 / 5.86) | `#FF7B6F` (7.63 / 7.07) | `#FF9C8E` (7.28 / 6.41) |
| on budget | `#68646E` (5.21 / 5.68) | `#9F9CA7` (7.14 / 6.62) | `#B6AFA4` (6.76 / 5.95) |
| Cover with savings (Primary) | `#3A3DB0` + white (8.49) | `#9C9FFF` + `#14143D` (7.36) | `#ABACF6` + `#1B1B3D` (7.84) |
| Remove cover (Destructive) | `#B4372F` on `#FFFDF8` | `#FF7B6F` on `#17171D` | `#FF9C8E` on `#34312D` |
| `Remove` text button | `#3A3DB0` (8.35) | `#9C9FFF` (7.49) | `#ABACF6` (6.14) |
| Snackbar + Undo | `#1C1B22` / `#F2F0EA` / `#ABACF6` | `#EEE9E0` / `#1C1B22` / `#3A3DB0` | same as Dark |

All pairs in design system §3. `Remove` is an indigo text button (not red): it opens a confirmation, and only the confirming button is red.

## 12. Largest text (2.0×, 360 × 640 dp) and landscape (640 × 360)
- **Title** and **status line** wrap; the mark stays before the first word.
- **Figures:** above 1.3× each row stacks label + (i) over the amount; `Remove` sits under the amount, left-aligned.
- **Rows:** as `transactions.md` §12 (amount moves under the note when the text column would be under 120 dp).
- **Cover sheet:** grows to 90 % and scrolls; buttons pinned. At 2.0× with the keyboard open, the field and `Cover` are both visible on a 640 dp phone (sheet content scrolls between them); F-012 AC-19 "keyboard never hides the amount field or Cover".
- **Landscape:** content column max 600 dp centred. Cover sheet max width 600 dp, centred.

## 13. Accessibility
- Order: back → title + status as one heading node (`Wednesday 11 November, overspent ₹300`; today: `Today, Friday 13 November, ₹410 left`) → notices → each figure (`Budget, ₹830`; refunds `Refunds, minus ₹500`) then its (i) → `Remove` → Day result → Cover card (`Savings pot, ₹2,000`, its (i), the sentence, the button) → `Spends` heading → rows (`₹1,130, Phone bill, Wednesday 11 November`, hint `Edit`; refund `Refund, ₹500, Amazon return`) → Add spend.
- Cover sheet: title is announced on open; the field reads `Amount, 300, edit box`; caption is read after it; errors are live regions (`Error: That's more than your savings pot (₹250).`).
- All targets ≥ 48 dp. Marks are decorative.

## 14. Copy (final; F-012 §5 matches)

| Control | Label | Description / tooltip / hint |
|---|---|---|
| Back | (icon) | Tooltip `Back` |
| Title | `<Wkd, d MMM>` | — |
| Status line | — | `● Saved <x>` · `○ On budget` · `◆ Overspent <x>` · `● Today · <x> left` · `○ Today · on budget` · `◆ Today · overspent <x>` · `Upcoming`; less than ₹1: `● Saved less than ₹1` · `◆ Overspent less than ₹1` · `● Today · less than ₹1 left` · `◆ Today · overspent less than ₹1` |
| Budget | `Budget` | (i): `What you could spend on this day.` |
| Spent | `Spent` | (i): `Everything you spent on this day.` |
| Refunds | `Refunds` | Value `−<amount>`. (i): `Money paid back to you on this day. It lowers what you spent.` |
| Net spent | `Net spent` | (i): `What you spent minus refunds.` |
| Covered | `Covered from savings` | (i): `Money you moved from your savings pot to this day.` |
| Day result | `Day result` | Value as the status line. (i): `The day's budget minus what you spent, after any cover from savings. Green ● saved, grey ○ on budget, red ◆ overspent.` |
| Savings pot | `Savings pot` | (i): F-006 "Savings pot" text |
| Cover sentence | — | `Use money from your savings pot to cover this day.` |
| Cover button | `Cover with savings` | Hint `Cover this day from your savings pot` |
| Today cover line | — | `Spending more today will make it overspent again.` |
| Empty pot | — | `Your savings pot is empty.` (i): `Your pot fills up on days you spend less than your budget.` |
| Fully covered | — | `Covered <amount> from savings.` |
| Cover sheet | `Cover <Wkd, d MMM>` | Line `Overspent <x> · Savings pot <y>` |
| Cover amount | `Amount` | Captions `This covers the whole overspend.` / `This uses your whole savings pot.` Errors `Enter an amount more than ₹0` · `That's more than this day's overspend (<x>).` · `That's more than your savings pot (<pot>).` · `Use numbers only, with up to 2 decimals` |
| Cover / Cancel | `Cover` / `Cancel` | Hints `Move this amount from your savings pot` / `Close without covering` |
| Snackbars | — | `<amount> covered from your savings` + `Undo`; `Cover undone`; `Cover removed`; `Spend moved to <Wkd, d MMM>`; failure on Remove or Undo `Couldn't save. Please try again.` (the cover sheet's own failure is inside the sheet) |
| Remove | `Remove` | Hint `Remove the cover on this day` |
| Remove sheet | `Remove this cover?` | `<amount> goes back to your savings pot, and <Wkd, d MMM> is overspent <amount> again.` · `Remove cover` (hint `Give this money back to your savings pot`) · `Keep it` (hint `Close`) |
| Budget-changed notice | `Budget changed on this day` | `: <what changed>` exactly as §3.1; hint `Open the month statement` |
| Cover save error | — | `Couldn't save. Please try again.` as a line inside the sheet (not a snackbar) |
| Past month notice | — | `This month has ended, so its days can't be changed.` |
| Spends heading | `Spends` / `Spends and refunds` | — |
| Refund row | `Refund` | `+<amount>` · note |
| Nothing spent | — | `Nothing spent this day` / today `Nothing spent yet today` |
| Upcoming | — | `This day hasn't happened yet.`; future-dated row line `Dated in the future` |
| Not budgeted | — | `Not budgeted: you started on <d MMM>.` |
| Add spend | `Add spend` | Hint `Add a spend on this day` |

## 15. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-11 | First version (Phase 3 planned ahead, D-033). Decisions D-1 … D-6 | Designer |
| 2026-11-16 | T-310 consistency check (D-075, D-077): no change needed. The not-budgeted line (§9) stays; Undo snackbar already stays while TalkBack is on (§6); weekday in the calendar's not-budgeted label does not affect this screen | Designer |
| 2026-11-16 | T-451 (Gate 2 Nice to have 4): stale §16 note 1 (refund wording) removed, already aligned by D-077 (3), D-081 (1). No design change | Designer |
| 2026-11-19 | T-465 (Gate 3, D-089): new §3.1 exact wording of the `Budget changed on this day` line for every kind of change (the statement's words); §6 the cover-save error is a line inside the sheet, only Cover stays pinned with the keyboard up on a short screen, Undo snackbar built as 5.75 s (persist only with a screen reader); the count-up is a Nice to have (T-466) | Designer |

## 16. Notes for the Project Manager
1. (Removed, T-451: F-012 AC-16 and F-014 AC-11 were aligned to `Refunds −₹500` by D-077 (3) and D-081 (1).)
2. New copy: `Day result` + (i), `Spends` / `Spends and refunds`, `Cover removed`, `Nothing spent yet today`, the lock notice icon. F-012 §5 updated.
3. Error order in §6 follows D-048 (1) (overspend before pot), which is what F-012 AC-8 tests.

---

## Owner preview

### Wed 11 Nov, overspent (Light)
```
┌──────────────────────────────────────┐
│ ←                                    │
│ Wed, 11 Nov                          │
│ ◆ Overspent ₹300                     │
│ ╭──────────────────────────────────╮ │
│ │ Budget (i)                  ₹830 │ │
│ │ Spent (i)                 ₹1,130 │ │
│ │──────────────────────────────────│ │
│ │ Day result (i) ◆ Overspent ₹300  │ │
│ ╰──────────────────────────────────╯ │
│ ╭──────────────────────────────────╮ │
│ │ Savings pot (i)           ₹2,000 │ │
│ │ Use money from your savings pot  │ │
│ │ to cover this day.               │ │
│ │ ┌──────────────────────────────┐ │ │
│ │ │      Cover with savings      │ │ │
│ │ └──────────────────────────────┘ │ │
│ ╰──────────────────────────────────╯ │
│ Spends                               │
│ ╭──────────────────────────────────╮ │
│ │ Phone bill                ₹1,130 │ │
│ ╰──────────────────────────────────╯ │
│ ┌──────────────────────────────────┐ │
│ │ + Add spend                      │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### Tap "Cover with savings" (Light)
```
┌──────────────────────────────────────┐
│░░░░░░░ (day details, dimmed) ░░░░░░░░│
│╭────────────────────────────────────╮│
│               ────                   │
│  Cover Wed, 11 Nov                   │
│  Overspent ₹300 · Savings pot ₹2,000 │
│  Amount                              │
│  ┌────────────────────────────────┐  │
│  │ ₹ 300                          │  │
│  └────────────────────────────────┘  │
│  This covers the whole overspend.    │
│  ┌────────────────────────────────┐  │
│  │             Cover              │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │             Cancel             │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

### After Cover (Light)
```
┌──────────────────────────────────────┐
│ ←                                    │
│ Wed, 11 Nov                          │
│ ○ On budget                          │
│ ╭──────────────────────────────────╮ │
│ │ Budget (i)                  ₹830 │ │
│ │ Spent (i)                 ₹1,130 │ │
│ │ Covered from savings (i)    ₹300 │ │
│ │                           Remove │ │
│ │──────────────────────────────────│ │
│ │ Day result (i)       ○ On budget │ │
│ ╰──────────────────────────────────╯ │
│ ✓ Covered ₹300 from savings.         │
│ Spends                               │
│ ╭──────────────────────────────────╮ │
│ │ Phone bill                ₹1,130 │ │
│ ╰──────────────────────────────────╯ │
│ ╭──────────────────────────────────╮ │
│ │ ₹300 covered from your     Undo  │ │
│ │ savings                          │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```
(Pot is now ₹1,700; Home shows Overspent ₹170. "Undo" stays for 6 seconds.)

### Tap "Remove" (Dark)
```
┌──────────────────────────────────────┐
│╭────────────────────────────────────╮│
│               ────                   │
│  Remove this cover?                  │
│  ₹300 goes back to your savings pot, │
│  and Wed, 11 Nov is overspent ₹300   │
│  again.                              │
│  ┌────────────────────────────────┐  │
│  │ Remove cover                   │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │            Keep it             │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```
("Remove cover" is coral-red text on an outlined button; "Keep it" plain.)

### Today, Fri 13 Nov (Dark)
```
┌──────────────────────────────────────┐
│ ←                                    │
│ Fri, 13 Nov                          │
│ ● Today · ₹410 left                  │
│ ╭──────────────────────────────────╮ │
│ │ Budget (i)                  ₹830 │ │
│ │ Spent (i)                   ₹420 │ │
│ │──────────────────────────────────│ │
│ │ Day result (i)       ● ₹410 left │ │
│ ╰──────────────────────────────────╯ │
│ Spends                               │
│ ╭──────────────────────────────────╮ │
│ │ Lunch                       ₹420 │ │
│ ╰──────────────────────────────────╯ │
│ ┌──────────────────────────────────┐ │
│ │ + Add spend                      │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### Shortfall month, Fri 6 Nov, empty pot (Dim)
```
┌──────────────────────────────────────┐
│ Fri, 6 Nov                           │
│ ◆ Overspent ₹200                     │
│ ╭──────────────────────────────────╮ │
│ │ Budget (i)                    ₹0 │ │
│ │ Spent (i)                   ₹200 │ │
│ │ Day result (i) ◆ Overspent ₹200  │ │
│ ╰──────────────────────────────────╯ │
│ ╭──────────────────────────────────╮ │
│ │ Savings pot (i)               ₹0 │ │
│ │ Your savings pot is empty. (i)   │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```

### Two-period month: Fri 13 Nov, the day the budget changed (Dark)
```
┌──────────────────────────────────────┐
│ Fri, 13 Nov                          │
│ ● Saved ₹52                          │
│ ⟲ Budget changed on this day:        │
│   salary ₹40,000 → ₹35,000         › │
│ ╭──────────────────────────────────╮ │
│ │ Budget (i)                  ₹552 │ │
│ │ Spent (i)                   ₹500 │ │
│ │ Day result (i)       ● Saved ₹52 │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```
(Exact budget ₹552.23; shown in whole rupees. The notice opens the month statement at Period 2.)

### A past day with a refund (Light)
```
┌──────────────────────────────────────┐
│ Mon, 16 Nov                          │
│ ● Saved ₹630                         │
│ ╭──────────────────────────────────╮ │
│ │ Budget (i)                  ₹830 │ │
│ │ Spent (i)                   ₹700 │ │
│ │ Refunds (i)                −₹500 │ │
│ │ Net spent (i)               ₹200 │ │
│ │ Day result (i)      ● Saved ₹630 │ │
│ ╰──────────────────────────────────╯ │
│ Spends and refunds                   │
│ ╭──────────────────────────────────╮ │
│ │ Amazon return              +₹500 │ │
│ │ Refund                           │ │
│ │──────────────────────────────────│ │
│ │ Shoes                       ₹700 │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```

### Why these choices
- **The day reads like a receipt:** budget, spent, any refund or cover, then the result as the last line, so you can check the sum yourself.
- **Covering is two taps** (Cover with savings → Cover), pre-filled with exactly what's needed, and it can be undone for 6 seconds or removed later.
- **Nothing is red unless money was overspent:** "Remove" is a quiet link; only the button that actually takes the cover away is red.
