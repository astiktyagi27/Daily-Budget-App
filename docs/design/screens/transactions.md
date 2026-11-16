# Screen spec: Transactions tab, Add / Edit spend, and its sheets

**Owner of this file:** Designer · **Phase:** 2 · **Feature:** F-009 (uses F-002 tokens, F-004 help pattern, F-006 engine numbers, F-008 shared amount field) · **Status:** Approved (Gate 2, Project Manager, 2026-11-10; PM additions §4, §5, §6.5, §9.2)
**Read with:** `docs/features/F-009-manual-transactions.md` (§5 updated to match this file), `plans/F-009-manual-transactions.md`, `month-setup.md` (shared amount field, decision sheet, action dock, minus sign), `docs/design/design-system.md` (§4.3, §7.8, §7.12, §7.13), `app-shell.md`, `help-pattern.md`, D-036 … D-040.
Copy here matches F-009 §5. Where this file adds copy, F-009 §5 has the same rows (change history 2026-11-10).

---

## 1. Purpose
Show what today still allows ("₹580 left today"), list this month's spends by day, and make adding, fixing or removing a spend take a few taps.

## 2. Answers to the plan's designer questions

| # | Question (plan) | Decision | Why |
|---|---|---|---|
| Q-editor | Add/Edit spend as a full screen or a sheet? (F-009 plan §9 Q3) | **Full screen** (the plan's default), pushed over the tabs, with a × close at the top left and Save pinned above the keyboard. | The keyboard opens at once (amount is focused) and takes about half the screen; a sheet would be squeezed into what is left, and at 2.0× text the three fields plus Save would not fit. The date picker opens as its own dialog on top, which is clumsy from inside a sheet. Back/discard behaviour is also simpler on a route (`PopScope`). It matches the month setup screen, so both money forms feel the same. |
| Q-block | The "new month not set up" block: sheet on tapping Add spend, or an inline banner? (F-009 plan §9 Q4) | **Both, each with one job.** An **inline card** takes the Today line's place at the top of the tab (there is no budget for today yet, so there is nothing else to show there) with **Set up this month**. The **Add spend** button stays where it always is; tapping it opens a **decision sheet** with the same message. | The banner tells the user the state before they try anything; the sheet answers the tap they made (F-009 AC-13) instead of a button that silently does nothing or disappears. Keeping Add spend in place keeps muscle memory. |
| Q-paise | (plan §9 Q1, PM question, noted here) | The design follows **D-038**: a ₹0.01 spend shows as **₹0** in the list and Today line; the editor field shows the exact typed value (`0.01`). | Only the Owner can make an exception to D-038. |

## 3. Tab layout (month confirmed)
Top to bottom, inside the shared frame (`app-shell.md` §2):
1. Title `Transactions`.
2. First-time hint card (unchanged copy, `hint.transactions.v1`: `Spotted a wrong amount or category later? You'll be able to fix it right here.`). **Text up to 1.3x: here, above the Today card. Above 1.3x (T-247): it moves below the Today card**, see §3.1.
3. **Today card** (§4).
4. The **day list** (§5), or the no-spends empty state (§6.2).
5. **Add spend** button floating at the bottom right (§7).
List bottom padding: nav height + 88 dp, so the last row scrolls clear of the button.

### 3.1 First-time tip and the Add spend button at large text (T-247, decided 2026-11-13)
Problem seen at 2.0x on 360 x 640 dp: the tip card grows to about 250 dp, pushes the Today card down, and the floating Add spend button lands on the Today line until the user scrolls or dismisses the tip.
- **Rule:** at the top of the page (scroll offset 0), at any text size, the Add spend button **never covers the Today card**. The Today line is the main information of this tab and is never hidden by a control.
- **Fix:** above 1.3x text the first-time tip is placed **under the Today card** (between the Today card and the day list) instead of above it. Same card, same copy, same Got it / × behaviour (design system §7.11c); only its position changes. At 1.3x and below nothing changes (tip above the Today card).
- With the tip below the Today card at 2.0x, the Today card ends about 404 dp from the top (measured with the real bundled fonts; the earlier "about 300 dp" was wrong) and the Add spend button starts about 499-550 dp down, so they clear. The rule is the non-overlap, unchanged. The tip and the first rows may pass under the button, which is fine: the page scrolls and the list has bottom padding.
- Not chosen: shrinking the button to an icon (the label is the explanation), a compact tip (its text must stay fully readable at 2.0x), moving the button (keeps muscle memory, see Q-block).
- **Test (for T-250):** 360 x 640, text 2.0x, first-time tip showing, scroll offset 0, Light and Dim: the Add spend button's rectangle does not intersect the Today card's rectangle and the tip is below the card; at 1.0x the tip is still above the card.

## 4. Today card
A card (design system §7.2):
- Header row: `Today` (`title`) + (i). (i) title `Today`, body `Today's budget minus what you've spent today. Whatever is left at midnight goes to your savings pot.`
- **The line**, `bodyLarge` (16/24) with every amount in Plex 600 tabular:

  `budget ₹830 · spent ₹250 · ₹580 left today`

  - The first two parts are `textPrimary`.
  - The **result** part is coloured **and** marked, and the words carry the meaning on their own:

    | Result | Text | Colour | Mark (decorative, before the result) |
    |---|---|---|---|
    | Under budget | `₹580 left today` | `saved` | ● |
    | Exactly ₹0 | `on budget` | `neutral` | ○ |
    | Over | `overspent ₹120` | `overspent` | ◆ |
    | Under ₹1 either way (D-050) | `less than ₹1 left today` / `overspent less than ₹1` | `saved` / `overspent` | ● / ◆ |

  - The mark is a separate decorative widget, not part of the text, so the text matches F-009 exactly.
  - Each "part" is one no-break unit (non-breaking spaces inside `spent ₹250`, word joiner inside `₹`), so at large text the line wraps only at the ` · ` separators.
- **Shortfall month** (D-036, Continue anyway): a panel under the line, `overspentSoft` fill, `radiusMd`: `◆ −₹1,000 this month` (`label` 600, `overspent`). The line itself reads `budget ₹0 · spent ₹200 · overspent ₹200`.
- **After a mid-month change** (D-037) the line simply uses today's budget (`budget ₹630 · …`); nothing else changes.
- **Semantics:** one sentence: `Today: budget ₹830, spent ₹250, ₹580 left today.` (shortfall: `… overspent ₹200. Minus ₹1,000 this month.`) The (i) is its own stop: `More about Today`.
- Updates immediately after any add, edit or delete; the result amount counts to its new value over `motionCount` (instant with Remove animations). This count-up is kept here because the result changes after a save; the month setup preview does not count up while typing (month-setup.md §5, T-241).

Why "left today" is green although the money is not in the pot yet (D-039): F-009 asks for the saved colour, and the words "left today" say it is still today's money. At midnight it becomes that day's "Saved".

## 5. Day list
- **Grouping:** this budget month, newest day first; inside a day, newest **added** entry first. An edit (even of the date) never moves a row to the top of its day (D-048).
- **Day header** (outside the card, `space6` above, `space2` below, `space5` gutters): heading left in `label` 600 `textPrimary`: `Today` · `Yesterday` · `Sat, 7 Nov`; that day's total right in `moneyMedium` `textSecondary`: `₹650`. Semantics: `Today, total ₹650`, marked as a heading.
- **Day card:** one card per day (padding 0), rows separated by inset hairlines.
- **Row** (design system §7.4, min 56 dp, padding 12 × 20 dp):
  - Title: the note in `bodyLarge` `textPrimary`, wraps, never truncated; or `No note` in `textSecondary`.
  - Trailing: amount in `moneyMedium` `textPrimary`, whole rupees rounded down (`₹300` for ₹300.50). Spends are not coloured: a single spend is neither saved nor overspent.
  - No leading icon (no categories in Phase 2), no chevron. The whole row is pressable (`sunken` fill on press) and opens **Edit spend**.
  - Semantics: `₹250, Lunch, Monday 9 November` (or `₹300, No note, Monday 9 November`); tap hint `Edit`.
- Deleting the last spend of a day removes its header and card (`motionEmphasis` collapse).
- A row whose date was changed moves to its new day; the list does not animate the move (it rebuilds), the snackbar confirms.

## 6. Tab states

### 6.1 No confirmed month
Empty state (design system §7.10) under the title and hint, **no** Today card and **no** Add spend button:
- Icon `event`; title `Set up your month first`; description `Your spends need a budget month. It takes a minute.`; **Primary** button `Set up your month` (hint `Open month setup`) → F-008.

### 6.2 Month confirmed, no spends
Today card (`budget ₹830 · spent ₹0 · ₹830 left today`), then the empty state:
- Icon `receipt_long`; title `No spends yet this month`; description `Add what you spend and we'll keep your daily budget up to date.`
- **No button inside the empty state.** The floating **Add spend** button (§7) is the button for this state, as it is for every month-confirmed state. Two identical "Add spend" buttons on one screen would make the user wonder whether they differ. F-009 §5 is updated to say this.

### 6.3 With spends
§4 + §5.

### 6.5 Can't load (F-007 §5, PM addition at Gate 2)
In place of the Today card and list: empty state (§7.10) with icon `error_outline` (`neutral`), title `Couldn't load your data`, description `Tap Try again. Nothing has been lost.`, **Primary** `Try again` (hint `Try to load your data again`). No Add spend button while nothing is loaded. Neutral, never red. (Section number follows 6.4 below.)

### 6.4 New month started, not set up (AC-13)
- **Top card** in place of the Today card: header `Set up your new month first` (`title`), description `Your last budget month has ended. Confirm this month's numbers to keep adding spends.` (`body`, `textSecondary`), Primary `Set up this month` (hint `Set up your new budget month`) → F-008.
- Below it a section label (`caption` 500, `textSecondary`, heading): `Last month · 5 Oct – 4 Nov`, then last month's day list, **read-only**: rows are not pressable (no ripple, no tap hint), semantics drop the `Edit` hint.
- **Add spend** stays visible. Tapping it opens the **new-month decision sheet**: title `Set up your new month first`, body `Your last budget month has ended. Confirm this month's numbers to keep adding spends.`, Primary `Set up this month`, Secondary `Not now` (hint `Close`). Scrim/back = Not now.

## 7. Add spend button
- Extended floating button: `add` icon + `Add spend`, `button` style, 56 dp tall, `radiusMd`, `accent` fill, `onAccent` content. Light: `float` shadow; Dark/Dim: no shadow (the accent fill stands out on its own).
- Placed `space5` from the right edge and 16 dp above the bottom nav. It does not hide on scroll. Snackbars push it up (standard `Scaffold` behaviour).
- Tooltip and hint: `Add a spend by hand`.
- At 2.0× text its label scales fully; it is about 180 dp wide at 2.0×, still well clear of the left edge on a 360 dp screen.

## 8. Add / Edit spend screen (full screen)

### 8.1 Layout
| # | Part | Spec |
|---|---|---|
| 1 | Top bar | 56 dp, `bg`. Leading × (`close`, 48 dp target), tooltip `Close`, hint `Leave without saving`. With changes, opens the discard sheet (§9.3). |
| 2 | Title | `Add spend` / `Edit spend` (`headline`, in the scroll body). |
| 3 | Amount | Shared amount field (month-setup §4.2) in its **large** size: 64 dp tall, value in `moneyLarge` (28/34). Label `Amount`; description `How much you spent.` Add: focused on open, keyboard up. Edit: pre-filled with the exact amount (`300.50`), not focused. Errors: `Enter an amount` · `Amount must be more than ₹0` · `That's more than ₹10 crore. Please check the amount.` · `Use numbers only, with up to 2 decimals` |
| 4 | Date | Label `Date`; description `When you spent it. You can pick any day this month up to today.` Field-styled row with the value and a trailing `calendar_today` icon: `Today · Mon, 9 Nov` / `Yesterday · Sun, 8 Nov` / `Sat, 7 Nov`. Tap opens the date picker (§8.2). Semantics: `Date, today, Monday 9 November, button`. |
| 5 | Note | Label `Note (optional)`; description `For example, "Lunch with Riya" or "Petrol".` Text field 56 dp, grows to 3 lines, then scrolls inside. Counter `<n>/100` (`caption`, `textSecondary`, right-aligned under the field) from 80 characters on. At 100 the counter stays `textSecondary` (input is simply blocked; it is not an error). |
| 6 | Save | **Action dock** (§7.13): Primary `Save` (hint `Save this spend`) / `Save changes` (hint `Save your changes`), pinned above the keyboard or the bottom inset. `Save changes` is disabled until something changed (same rule as F-008 edit). |
| 7 | Delete (edit only) | Destructive button `Delete` with leading `delete` icon, full width, at the end of the form content, `space8` above. Hint `Delete this spend`. Opens §9.1. |

### 8.2 Date picker
Material date picker (`showDatePicker`, `DatePickerEntryMode.calendarOnly`), themed from tokens via `datePickerTheme`:
- Surface `surface`, header title in `title` (Bricolage), help text `Pick the day you spent it` (`label`, `textSecondary`).
- Selected day: `accent` fill, `onAccent` digit. Today: 1 dp `accent` ring. Selectable days `textPrimary`; blocked days (future, before the month start, or before the first budgeted day after a mid-month setup) `textSecondary` at 50 % (disabled; exempt from contrast as disabled controls, but still distinguishable).
- Buttons: `Cancel` and `OK` as Text buttons in `accent`.
- Range: first = later of month start and first budgeted day; last = today; initial = the current value.

### 8.3 After Save
- The screen closes (standard pop). On the tab: snackbar `Spend added` / `Spend updated` (4 s). The list and Today card are already updated.
- If the save reduced a cover (D-040): the **cover-taken-back sheet** (§9.2) opens first; the snackbar shows after it closes.
- Save failure: snackbar `Couldn't save. Please try again.` (F-007 §5) on the editor, **lifted above the Save dock** so it never covers Save; input stays; nothing stored.
- **Opening the editor hides the previous snackbar** (for example `Spend added` from the last save), so an old message never sits over the form.
- **Date error** (T-241, C7): `Pick a day this month, up to today.` shown under the Date row in the field-error style (§7.12) when the saved date is no longer allowed, which can only happen after a clock change while the editor is open. Save stays blocked until a valid day is picked.
- Double tap: one save (progress ring in the button while saving).

## 9. Sheets
All are design system §7.8 **decision sheets** via `showBudgetSheet` (D-031): title, body, then full-width stacked buttons, button 1 first; each sheet has its own visible close choice.

### 9.1 Delete confirmation
- Title `Delete this spend?`
- Body `₹250 on Mon, 9 Nov. This can't be undone.` (amount rounded down like everywhere; the date is always the weekday form, never "Today", so it is exact).
- Button 1 **Destructive** `Delete` (hint `Delete this spend`); button 2 Secondary `Cancel` (hint `Keep this spend`).
- Delete is first because the user asked for it with a deliberate tap; the sheet only confirms it. Scrim / back = Cancel.
- Delete: sheet and editor close, snackbar `Spend deleted`.

### 9.2 Cover taken back (D-040)
- Title `Savings pot updated`
- Body, one paragraph per reduction:
  - Full: `Your savings pot went down, so the ₹170 that covered Fri, 6 Nov was taken back. 6 Nov is overspent again.`
  - Partial: `Your savings pot went down, so ₹70 of the cover on Fri, 6 Nov was taken back.`
- Button: Primary `OK` (hint `Close`). Scrim / back = OK.
- Several covers cut by one save: one sheet, one paragraph per cover, newest cover first (D-048). A cut less than ₹1 reads `less than ₹1 of the cover on <day>`.
- Shown once, only when the save caused a reduction (F-009 AC-19). No red in the sheet: it explains a change, it is not a warning; the affected day's ◆ will show in the Phase 3 calendar.

### 9.3 Discard
| | Add | Edit |
|---|---|---|
| Title | `Discard this spend?` | `Discard changes?` |
| Body | `What you've typed won't be saved.` | `Your changes to this spend won't be saved.` |
| Button 1 | Primary `Keep editing` (hint `Go back to your spend`) | same |
| Button 2 | Destructive `Discard` (hint `Leave without saving`) | same |

Keep editing is first: a back press is often accidental, so the safe choice is the big one. Scrim / back = Keep editing. With no input / no changes, back leaves directly.

## 10. States

| State | Tab | Editor |
|---|---|---|
| First-time | Hint card + the state below | — |
| Normal | Today card + list | Fields, Save |
| Empty | §6.1 (no month) or §6.2 (no spends) | Add: empty amount, today, empty note |
| Loading | None visible: the list is built lazily from the repository stream; the first frame shows the last known data, and 500 spends appear in under 1 s (AC-15). No skeletons, no spinner. | Saving: progress ring in Save |
| Error | Save failure snackbar (on the editor, above the dock); amount field errors (§7.12) | Date error `Pick a day this month, up to today.` (§8.3) |
| Permission denied | Not applicable (manual entry needs no permission) | |
| New month not set up | §6.4 | Not reachable (blocked) |
| Shortfall month | Today line with ₹0 budget + `−₹1,000 this month` panel | Unchanged |

## 11. Themes

| Element | Light | Dark | Dim |
|---|---|---|---|
| Today result: left / on budget / over | `#1A7044` / `#68646E` / `#B4372F` on `#FFFDF8` (6.00 / 5.68 / 5.86) | `#52C98B` / `#9F9CA7` / `#FF7B6F` on `#17171D` | `#80D3A1` / `#B6AFA4` / `#FF9C8E` on `#34312D` |
| Day header total | `#5C5864` on `#F6F3ED` | `#A8A5B1` on `#0E0E12` | `#BEB7AB` on `#2A2825` |
| Row amount / note / `No note` | `#1C1B22` / `#1C1B22` / `#5C5864` | `#F2F0EA` / … / `#A8A5B1` | `#EEE9E0` / … / `#BEB7AB` |
| Add spend button | `#3A3DB0` + white, shadow | `#9C9FFF` + `#14143D` | `#ABACF6` + `#1B1B3D` |
| Delete (Destructive) text/icon | `#B4372F` on `#FFFDF8` | `#FF7B6F` on `#17171D` | `#FF9C8E` on `#34312D` |
| Shortfall panel | `#F6E0DC` / `#B4372F` | `#3A1A17` / `#FF7B6F` | `#4A3230` / `#FF9C8E` |

All pairs are in design system §3. Auto follows the phone.

## 12. Largest text (2.0×, 360 × 640 dp) and landscape (640 × 360)
- **Today line** wraps at the ` · ` separators only, so `budget ₹830` / `spent ₹250` / `₹580 left today` can each take a line; an amount never splits. A ₹10 crore overspend (`overspent ₹9,99,99,170`) fits on its own line at 2.0×.
- **First-time tip** sits below the Today card above 1.3x (§3.1), so the Add spend button never covers the Today line.
- **Day header:** if heading and total don't fit on one line, the total moves under the heading (left-aligned).
- **Row:** the amount moves under the note when the text column would be narrower than 120 dp; notes wrap fully.
- **Editor:** no dock above 1.3× or in landscape: Save sits at the end of the form (after Note), Delete after it. The focused field always scrolls into view above the keyboard.
- **Date picker:** Material's picker handles large text by scaling its grid; in landscape it uses its side-by-side layout.
- **Sheets:** grow up to 90 % and scroll; buttons stay pinned at the bottom of the sheet.

## 13. Accessibility
- Tab reading order: title, hint, Today card (one sentence, then its (i)), each day header then its rows, Add spend button, bottom nav.
- Editor reading order: close, title, Amount, Date, Note, Save, Delete.
- Every target ≥ 48 dp. The Today sentence and row labels are as in §4 and §5 (AC-16).

## Change history
| Date | Change | By |
|---|---|---|
| 2026-11-13 | T-247 (PM Gate 4 O2, D-071): new §3.1 and a §12 line: above 1.3x the first-time tip moves below the Today card so the Add spend button never covers the Today line at the top of the page. Owner preview: new 2.0x mockup. Developer follow-up T-250 | Designer |
| 2026-11-10 | First version (Phase 2, Step 6) | Designer |
| 2026-11-16 | T-251 (PM Gate 3 of T-250): §3.1 Today card height corrected to about 404 dp at 2.0x on 360 x 640 (not about 300); button starts about 499-550 dp; rule unchanged | Designer |
| 2026-11-13 | T-241 (PM Gate 3: C7): §8.3 date error `Pick a day this month, up to today.`, save-failure snackbar lifted above the dock, previous snackbar hidden when the editor opens; §4 notes the Today count-up stays (month setup no longer counts up). Records what was approved and built | Designer |
| 2026-11-10 | Gate 2 (PM): §4 under-₹1 row (D-050); §5 order within a day (D-048); new §6.5 load error; §9.2 several covers in one sheet; mockup weekday corrected (4 Nov 2026 is a Wednesday). Status → Approved | Project Manager |

---

## Owner preview

### Transactions with spends, today Mon 9 Nov (Light)
```
┌──────────────────────────────────────┐
│ Transactions                         │
│ ╭──────────────────────────────────╮ │
│ │ Today (i)                        │ │
│ │ budget ₹830 · spent ₹650 ·       │ │
│ │ ● ₹180 left today                │ │
│ ╰──────────────────────────────────╯ │
│ Today                         ₹650   │
│ ╭──────────────────────────────────╮ │
│ │ Groceries                   ₹400 │ │
│ │──────────────────────────────────│ │
│ │ Lunch                       ₹250 │ │
│ ╰──────────────────────────────────╯ │
│ Yesterday                     ₹310   │
│ ╭──────────────────────────────────╮ │
│ │ Petrol                      ₹310 │ │
│ ╰──────────────────────────────────╯ │
│ Sat, 7 Nov                    ₹820   │
│ ╭──────────────────────────────────╮ │
│ │ Dinner with Riya            ₹780 │ │
│ │──────────────────────────────────│ │
│ │ No note                      ₹40 │ │
│ ╰──────────────────────────────────╯ │
│                     ╭──────────────╮ │
│                     │ + Add spend  │ │
│                     ╰──────────────╯ │
│──────────────────────────────────────│
│                     ▬                │
│   ⌂       ▥        ≣         ⫶       │
│ Home Dashboard Transactions Settings │
└──────────────────────────────────────┘
```
("● ₹180 left today" is green; everything else is ink.)

### Today card after a ₹300.50 spend (Dark)
```
┌──────────────────────────────────────┐
│ ╭──────────────────────────────────╮ │
│ │ Today (i)                        │ │
│ │ budget ₹830 · spent ₹950 ·       │ │
│ │ ◆ overspent ₹120                 │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```
(Coral red with the ◆ diamond. Exact figures are ₹950.50 and ₹120.50; the screen rounds down.)

### Shortfall month: ₹200 spent today (Dim)
```
┌──────────────────────────────────────┐
│ ╭──────────────────────────────────╮ │
│ │ Today (i)                        │ │
│ │ budget ₹0 · spent ₹200 ·         │ │
│ │ ◆ overspent ₹200                 │ │
│ │ ╭──────────────────────────────╮ │ │
│ │ │ ◆ −₹1,000 this month         │ │ │
│ │ ╰──────────────────────────────╯ │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```

### Add spend, keyboard open (Light)
```
┌──────────────────────────────────────┐
│ ×                                    │
│ Add spend                            │
│ Amount                               │
│ How much you spent.                  │
│ ┌──────────────────────────────────┐ │
│ │ ₹ 250|                           │ │
│ └──────────────────────────────────┘ │
│ Date                                 │
│ ┌──────────────────────────────────┐ │
│ │ Today · Mon, 9 Nov             ▦ │ │
│ └──────────────────────────────────┘ │
│ Note (optional)                      │
│ ┌──────────────────────────────────┐ │
│ │ Lunch                            │ │
│ └──────────────────────────────────┘ │
│ ┌──────────────────────────────────┐ │
│ │               Save               │ │
│ └──────────────────────────────────┘ │
│┌────────────────────────────────────┐│
││  1     2     3     ⌫               ││
││  4     5     6     .               ││
││  7     8     9     0      ✓        ││
│└────────────────────────────────────┘│
└──────────────────────────────────────┘
```

### Edit spend with Delete, then the confirmation (Dim)
```
┌──────────────────────────────────────┐
│ ×                                    │
│ Edit spend                           │
│ Amount                               │
│ ┌──────────────────────────────────┐ │
│ │ ₹ 250                            │ │
│ └──────────────────────────────────┘ │
│ Date      Today · Mon, 9 Nov       ▦ │
│ Note      Lunch                      │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ ⌫ Delete                         │ │
│ └──────────────────────────────────┘ │
│──────────────────────────────────────│
│ ┌──────────────────────────────────┐ │
│ │      Save changes (disabled)     │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
┌──────────────────────────────────────┐
│░░░░░░░░░ (editor, dimmed) ░░░░░░░░░░░│
│╭────────────────────────────────────╮│
│               ────                   │
│  Delete this spend?                  │
│  ₹250 on Mon, 9 Nov. This can't be   │
│  undone.                             │
│  ┌────────────────────────────────┐  │
│  │ ⌫ Delete                       │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │             Cancel             │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```
Date error after a clock change (T-241, C7):
```
│ Date                                 │
│ ┌──────────────────────────────────┐ │
│ │ Wed, 11 Nov                    ▦ │ │
│ └──────────────────────────────────┘ │
│ Pick a day this month, up to today.  │
```

(The Edit mockup abbreviates Date and Note; on the real screen they keep their labels and descriptions as in Add.)

### Cover taken back after an edit (Light)
```
┌──────────────────────────────────────┐
│░░░░░░░░ (Transactions, dimmed) ░░░░░░│
│╭────────────────────────────────────╮│
│               ────                   │
│  Savings pot updated                 │
│                                      │
│  Your savings pot went down, so the  │
│  ₹170 that covered Fri, 6 Nov was    │
│  taken back. 6 Nov is overspent      │
│  again.                              │
│  ┌────────────────────────────────┐  │
│  │               OK               │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

### No month yet (Dark)
```
┌──────────────────────────────────────┐
│ Transactions                         │
│                                      │
│  ╭────╮                              │
│  │ ▦  │                              │
│  ╰────╯                              │
│ Set up your month first              │
│ Your spends need a budget month. It  │
│ takes a minute.                      │
│ ┌──────────────────────────────────┐ │
│ │        Set up your month         │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### New month started, not set up (Light), and tapping Add spend
```
┌──────────────────────────────────────┐
│ Transactions                         │
│ ╭──────────────────────────────────╮ │
│ │ Set up your new month first      │ │
│ │ Your last budget month has       │ │
│ │ ended. Confirm this month's      │ │
│ │ numbers to keep adding spends.   │ │
│ │ ┌──────────────────────────────┐ │ │
│ │ │      Set up this month       │ │ │
│ │ └──────────────────────────────┘ │ │
│ ╰──────────────────────────────────╯ │
│ Last month · 5 Oct – 4 Nov           │
│ Wed, 4 Nov                    ₹520   │
│ ╭──────────────────────────────────╮ │
│ │ Groceries                   ₹520 │ │
│ ╰──────────────────────────────────╯ │
│                     ╭──────────────╮ │
│                     │ + Add spend  │ │
│                     ╰──────────────╯ │
└──────────────────────────────────────┘
┌──────────────────────────────────────┐
│╭────────────────────────────────────╮│
│               ────                   │
│  Set up your new month first         │
│  Your last budget month has ended.   │
│  Confirm this month's numbers to     │
│  keep adding spends.                 │
│  ┌────────────────────────────────┐  │
│  │       Set up this month        │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │            Not now             │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

### Large text 2.0x, first-time tip showing (Light, 360 x 640) - T-247
```
Before (problem)                After (decided)
┌─────────────────────┐        ┌─────────────────────┐
│ Transactions        │        │ Transactions        │
│ Tip                 │        │ ╭─────────────────╮ │
│ Spotted a wrong     │        │ │ Today (i)       │ │
│ amount or category  │        │ │ budget ₹830 ·   │ │
│ later? You'll be    │        │ │ spent ₹650 ·    │ │
│ able to fix it      │        │ │ ● ₹180 left     │ │
│ right here.         │        │ │ today           │ │
│ [Got it]            │        │ ╰─────────────────╯ │
│ ╭───────────╮       │        │ Tip                 │
│ │ Today (i) │ ╭───╮ │        │ Spotted a wrong     │
│ │ budget ₹8 │ │+ A│ │ covers │ amount or ...       │
│ ╰───────────╯ ╰───╯ │ Today  │ [Got it]  ╭───────╮ │
│ Today        ₹650   │        │ Today     │+ Add  │ │
│─────────────────────│        │───────────╰───────╯─│
│  Home  ...          │        │  Home  ...          │
└─────────────────────┘        └─────────────────────┘
```

### Why these choices
- **"₹180 left today" leads with words plus a green ●**, so the one thing that matters today reads without colour, and the list below stays calm ink with no colours on single spends.
- **Add/Edit is a full screen with Save above the keyboard**: type the amount, add a note, tap Save; three taps for a typical spend, and it still fits at 2.0× text.
- **Every confirmation is a bottom sheet with honest words**: what will happen, the amount and date, and the safe choice where a tap might be accidental.
