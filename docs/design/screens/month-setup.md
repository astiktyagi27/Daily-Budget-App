# Screen spec: Month setup, edit this month, and the Home month states

**Owner of this file:** Designer · **Phase:** 2 · **Feature:** F-008 (uses F-002 tokens, F-004 help pattern, F-006 engine numbers) · **Status:** Approved (Gate 2, Project Manager, 2026-11-10; PM additions §4.5, §5, §10.4–10.5)
**Read with:** `docs/features/F-008-month-setup.md` (§5 updated to match this file), `plans/F-008-month-setup.md`, `docs/design/design-system.md` (§4.3 money, §7.3 input, §7.8 sheets incl. the new decision sheet, §7.12 errors, §7.13 action dock), `app-shell.md`, `help-pattern.md`, D-034 … D-038, D-042, D-043.
Copy here matches F-008 §5. Where this file adds copy, F-008 §5 has the same rows (change history 2026-11-10).

---

## 1. Purpose
Turn "salary minus fixed costs" into one daily number the user can trust, show that number live while they type, and say honestly when the numbers don't add up.

## 2. Answers to the plan's designer questions

| # | Question (plan) | Decision | Why |
|---|---|---|---|
| Q-preview | Where does the live preview sit? (F-008 plan §9 Q1) | **Both, split by job.** (a) A pinned **action dock** at the bottom (portrait, text ≤ 1.3×) shows the daily budget in one line plus the Confirm button. (b) The **full preview card** (month, spendable line, daily budget, all with (i)) sits inline at the end of the form, above where the dock's Confirm would be. With the keyboard open the dock shrinks to just its one-line daily budget. In landscape or above 1.3× text there is no dock: preview card and Confirm are inline at the end (the plan's default). | The point of a live preview is to watch ₹830 change *while* typing Rent near the top of the form. Inline-only would hide it exactly then. The full card is too tall (~200 dp) to pin on a 640 dp phone, so only the one number is pinned. |
| Q-minus | `−` (U+2212) or `-`? (F-008 plan §9 Q4) | **U+2212 `−`**, as design system §4.3 already says. Placed before the ₹: `−₹1,000`. In arithmetic lines it has a space each side: `₹40,000 − ₹15,100 fixed`. A word joiner (U+2060) sits between `−` and `₹` so the sign never wraps away from the amount. Screen readers get "minus" spelled out in the semantics label. | The true minus is the same width as `+` and the digits in Plex, so columns line up, and it reads as maths rather than as a hyphen. TalkBack may read U+2212 inconsistently, so the label spells it. |

(The F-009 questions, Add/Edit as a full screen or sheet and the new-month block, are answered in `transactions.md` §2.)

## 3. Screen frame (all setup modes)

| # | Part | Spec |
|---|---|---|
| 1 | Top bar | 56 dp, `bg`, no title text. Leading back arrow (`arrow_back`, 24 dp, 48 dp target), tooltip `Back`, hint `Leave this screen`. Back with unsaved changes opens the discard sheet (§9). |
| 2 | Title | `headline` in the scroll body, as on the tabs (`app-shell.md` §2): `Set up your month` (first) · `Set up this month` (new month) · `Edit this month` (edit). |
| 3 | Notice line (only some modes) | Inline note: 16 dp `info` icon in `textSecondary` + `body` `textSecondary`, `space3` below the title. Pre-fill (new month): `We've filled in last month's numbers. Check them and confirm.` |
| 4 | Form sections | §4, separated by `space6`. Each field is the design system §7.3 input with label + description + optional (i). |
| 5 | Preview card | §5, `space6` above. |
| 6 | Confirm | Primary, full width. In the dock (§6) in portrait ≤ 1.3×, otherwise inline under the preview card. |
| 7 | Bottom space | `space8` + dock height, so the preview card scrolls clear of the dock. |

No bottom navigation on this screen (it is pushed full screen over the tabs).

## 4. Form fields

### 4.1 Salary day
- **First month:** a field-styled row (56 dp, `sunken`, `borderStrong` outline, `radiusMd`) showing the value or the placeholder `Choose a day` (`textSecondary`), with a trailing `expand_more`. Label `Salary day` + (i); description below the label.
  - Label: `Salary day`
  - Description: `The day your salary usually arrives. Your budget month runs from this day to the day before the next one.`
  - (i) title `Salary day`, body: `If your salary day is the 29th, 30th or 31st, short months start on their last day instead.`
  - Value: ordinal: `1st`, `2nd`, `3rd`, `4th` … `21st`, `22nd`, `23rd`, `31st`.
  - Error (Confirm with no day): `Choose your salary day`.
  - Tap opens the **salary day sheet** (§4.6).
- **Later months / edit:** read-only text, no field look: `Salary day: 5th` (`label`) with `Set in your first month.` below (`body`, `textSecondary`). Not focusable as a control; read as one item.
- **Mode switch (first month).** No day is pre-selected, and the full-month fields (§4.2–4.4) are shown on open (F-008 AC-2). When the chosen day makes today a mid-month start, the salary and target fields are replaced by the mid-month fields (§4.5) with a `motionBase` cross-fade. The draft keeps both sets, so picking the other day back restores what was typed. The preview prompt until a day is chosen: `Choose your salary day to see your budget month`.

### 4.2 Monthly salary
Amount field (design system §7.3): `₹` prefix, `moneyMedium` value, number keypad with decimal, up to 2 decimals typed. The field shows the digits **exactly as typed** (`40000`, `10000000`), with no grouping while typing (D-069). The grouped amount (`₹40,000`; `₹1,00,00,000`) shows at once in the live preview under the form: the Spendable line of the preview card (§5) and the Total fixed costs line (§4.4). A pasted `₹40,000` is accepted and shown as typed. The same applies to every amount field on this screen.
- Label `Monthly salary`
- Description `What you receive in your bank account each month, after tax.`
- Errors (one at a time, §7.12 style): `Enter your salary` · `Salary must be more than ₹0` · `That's more than ₹10 crore. Please check the amount.` · `Use numbers only, with up to 2 decimals`

### 4.3 Spend less than my salary
- List row with a trailing switch (one merged semantics node, D-032), no card around it: label `Spend less than my salary`, description `Set a smaller amount to budget and keep the rest aside.` Switch off by default.
- On: the **Spending target** amount field slides in below (`motionEmphasis`, height + fade); focus moves to it.
  - Label `Spending target`; description `The amount you want to spend this month, including fixed costs.`
  - Errors: `Enter a target` · `Target can't be more than your salary` · `Target must be more than ₹0`
- Off: the field collapses and the target is removed; the preview uses the salary again.

### 4.4 Fixed costs
Section header: `title` style `Fixed costs`, with its description below (label + description, no (i): the description already says everything): `Bills you pay every month, like rent or EMIs. They're taken out before your daily budget is worked out.`
- **Item list** inside one card (design system §7.2, padding 0). Column captions once, above the first item: `Name` (left) and `Amount` (right), `caption` `textSecondary`. Under the captions, one helper line in `caption` `textSecondary`: `Leave empty or 0 if there's nothing to pay this month.`
- **Item row** (min 72 dp, padding 12 dp × 16 dp, hairline between items):
  - Name field: flex 3, 48 dp tall, `sunken` fill, `borderStrong` outline, `radiusMd`, `bodyLarge`. Max 40 characters (enforced; no counter needed at this length).
  - Amount field: flex 2, same look, `₹` prefix, `moneyMedium`, right-aligned digits.
  - Delete: `close` icon 20 dp in `textSecondary`, 48 dp target, tooltip `Remove <name>` (`Remove item` when the name is empty).
  - Semantics: name field `Name, item 1 of 3`; amount field `Amount for Rent`; delete `Remove Rent`.
  - Errors appear under the row, full width, §7.12 style: `Give this cost a name`.
- First month starts with **Rent**, **EMI**, **Subscriptions** (names filled, amounts empty).
- **Delete:** the row collapses (`motionEmphasis`), Total updates at once, snackbar `Rent removed` with `Undo` (6 s; stays while TalkBack is on). Undo puts it back in the same position.
- **+ Add item:** Text button, full width of the card's bottom edge (48 dp), left-aligned, label `+ Add item`, hint `Add another monthly cost.` Adds an empty row at the end and focuses its Name field. At 30 items it is disabled and the line `You can add up to 30 costs.` (`caption`, `textSecondary`) appears under it.
- **Total fixed costs:** ledger line under the card: `Total fixed costs` (`body` `textSecondary`) left, amount right (`moneyMedium`, `textPrimary`), whole rupees rounded down: `₹15,100`. Empty list: `₹0`.

### 4.5 Mid-month first setup (D-034, D-042)
Shown instead of §4.2–4.4 when the chosen salary day makes today mid-month.
1. Notice line under Salary day (inline note style, §3 item 3): `You're starting partway through the month, so we'll spread the money you have left over the 25 days until your next salary.` (`<n>` updates with the salary day.)
2. **Money left now** amount field: label `Money left now`, description `How much you have to spend until your next salary.` Errors: `Enter how much you have left` · `Amount must be more than ₹0` · `That's more than ₹10 crore. Please check the amount.`
   - **Edit mode (D-048):** the field shows the stored value with the label `Money left on <first day>` (e.g. `Money left on 10 Nov`) and the description `What you had to spend when you started on <first day>. Change it if it was wrong. Days before today keep their budget.` ("now" would be wrong on a later day.)
   - **One day left** (setup on the month's last day): notice line `You're starting on the last day of this budget month, so all the money you have left is for today.`
3. **Fixed costs still to pay this month**: same section and item design as §4.4, header `Fixed costs still to pay this month`, description `Bills you haven't paid yet before your next salary, like rent due next week.` The list starts **empty**: instead of rows, the card shows only `+ Add item` and the Total line reads `₹0`.

### 4.5a Late or missed-month setup (D-057, PM addition 2026-11-11)
When "Set up this month" is opened after the month's start day, the screen is the §4.5 layout with the title `Set up this month`, the salary day read-only (`Salary day: 5th` / `Set in your first month.`), the §4.5 notice line with `<n> days`, and **no** pre-fill line; the still-to-pay list starts empty. On the start day itself it is the normal pre-filled setup (§3 item 3).

### 4.6 Salary day sheet
Bottom sheet via `showBudgetSheet` (D-031).
- Title `Salary day`; description `The day your salary usually arrives.`
- A 7-column grid of day chips 1–31 (each ≥ 48 × 48 dp, `radiusXs`, `caption` 500 digits at 1.0). Unselected: `surface` with hairline. Selected: `accent` fill, `onAccent` digit, plus a 2 dp `focus` ring (shape cue for greyscale). 29, 30, 31 carry a small `*` and the line under the grid: `* In shorter months, the month starts on its last day.`
- Tap a day: selects it at once (the form behind updates). `Done` (Secondary, full width) closes; hint `Close salary day options`. Scrim / back also close.
- Semantics: `5th, salary day, selected` / `12th`.

## 5. Preview card
A card (§7.2) titled `Your daily budget` (`title`, new copy). Three ledger lines (label left `body` `textSecondary` + (i) where listed; value right):

| Line | Label | Value | (i) |
|---|---|---|---|
| Month | `Budget month` | `5 Nov – 4 Dec · 30 days` (mid-month: `10 Nov – 4 Dec · 25 days left`; one day: `4 Dec · 1 day left`, no range) | — |
| Spendable | `Spendable this month` | Full width under the label (it is long): `₹40,000 − ₹15,100 fixed = ₹24,900`; with a target: `₹20,000 − ₹15,100 fixed = ₹4,900`; mid-month: `₹24,900 − ₹0 fixed = ₹24,900` | F-006 "Spendable" text |
| Daily | `Daily budget` | `₹830 a day` in `moneyLarge` `textPrimary` | F-006 "Daily budget" text |

All amounts whole rupees rounded down (D-038) via the shared formatter.

**Preview states**

| State | What the card shows |
|---|---|
| No salary day yet | Month line value `Choose your salary day to see your budget month`; Daily line `Enter your salary to see your daily budget` |
| Salary empty / invalid | Month line as normal; Spendable hidden; Daily line replaced by `Enter your salary to see your daily budget` (`body`, `textSecondary`) |
| Mid-month form, money left empty / invalid (§4.5) | Month line as normal; Spendable hidden; Daily line replaced by `Enter the money you have left to see your daily budget` (`body`, `textSecondary`). `Enter your salary` would be wrong above a field called Money left now (T-241, U5). |
| Valid | All three lines |
| **Shortfall** (fixed > money, D-036) | Daily line replaced by a **shortfall panel** inside the card: `overspentSoft` fill, `radiusMd`, padding `space4`. Row 1: `₹0 a day` (`moneyLarge`, `textPrimary`) · `◆ ₹1,000 short` (`label` 600, `overspent`). Row 2: `Your fixed costs are ₹1,000 more than your salary.` (`body`, `textPrimary`; or `your spending target` / `the money you have left`). Spendable line shows the negative honestly: `₹20,000 − ₹21,000 fixed = −₹1,000`. |
| **Exactly zero** (D-043) | Panel with `neutralSoft` fill: `○ ₹0 left for daily spending` (`label` 600, `neutral`) and `Your fixed costs take up all of your salary.` (or target / money left). |
| Edit mode | Daily line replaced by the edit line: `From today (20 Nov): ₹630 a day for the 15 days left. Days before today keep their budget.` (`bodyLarge`, the amount in Plex 600). One day left: `From today (4 Dec): ₹1,830 for today, the last day of this budget month. Days before today keep their budget.` In an edit shortfall: panel with `This change leaves you ₹2,550 short for the rest of the month.` |

Updates happen in the same frame as the keystroke (F-008 AC-7); the daily amount **changes at once, with no count-up** (T-241, U3). A 600 ms count while someone types would show a wrong number for most of that time, and F-008 AC-7 and TC-008-11 need the new figure in the same frame. The count-up stays on the Transactions Today line, where the result changes after a save (transactions.md §4). TalkBack gets a polite live-region update of the Daily line only after 1 s without typing, so it is not chatty.

Why the shortfall is red with ◆: after "Continue anyway" every spend counts as overspent (F-006 §2.8), so this is the overspent meaning, shown the overspent way (§7.12), not as an error. The exactly-zero case is not negative, so it uses the neutral ○.

## 6. Action dock (portrait, text ≤ 1.3×)
Design system §7.13. Pinned to the bottom, `surface` fill, top hairline (Light also no shadow), padding `space4` × `space5`, plus the system inset.
- **Keyboard closed:** line 1, `Daily budget` (`body`, `textSecondary`) left and `₹830 a day` (`moneyMedium`, `textPrimary`) right; `space3`; the Confirm Primary button. About 124 dp tall.
- **Keyboard open (T-248, decided 2026-11-13):** only line 1 (44 dp), **sitting directly above the keyboard and always visible** (the dock follows the keyboard inset; it is never covered by it). Confirm is hidden while the keyboard is open and comes back when the keyboard closes. A dock line hidden under the keyboard is a defect against this spec, not an accepted state.
- **Mechanism (T-251):** the dock is the Scaffold's bottom bar, lifted by the keyboard inset, so a snackbar (`Removed <name>`, save error) stays above the dock and never covers Confirm (TC-008-35).
- **Keyboard actions (T-248):** the keyboard's action key is **Next** on every field (salary, target, each item name, each item amount) and moves focus to the following field, scrolling it into view; on the **last field of the form** (the last item's Amount) it is **Done**, which closes the keyboard so `Start my month` / `Save changes` appears in the dock. System back with the keyboard open closes the keyboard first and does not leave the screen. No extra Done button above the keyboard.
- **Above 1.3x text / landscape:** no dock (§13), so nothing sits above the keyboard; `Start my month` is the last item of the form and is reached by **scrolling with the keyboard open**.
- Shortfall: line 1 right reads `◆ ₹1,000 short` in `overspent`. Zero: `○ ₹0 a day` in `neutral`. Empty: `—` in `textSecondary` with the left label `Enter your salary`; in the mid-month form (§4.5) the left label is `Enter how much you have left` (T-241, U5).
- Semantics: line 1 is excluded (the preview card is the readable source), the button reads as normal.
- In edit mode line 1 reads `From today` · `₹630 a day`.

## 7. Confirm and validation
- Labels: `Start my month` (first / new month; hint `Save and start this budget month`) · `Save changes` (edit; hint `Save the changes to this month`; disabled until something changed, design system disabled style).
- Tap with errors: the screen scrolls the first invalid field into view (`motionEmphasis`), focuses it, shows every error at once, and TalkBack announces the first: `Error: Enter your salary`.
- Tap with a shortfall or exactly zero: the **shortfall sheet** (§8).
- Saving: button shows the progress ring; a second tap does nothing.
- Save failure: snackbar `Couldn't save. Please try again.` (F-007 §5), neutral, no red; every value stays.
- Success: the screen closes back to Home (standard pop transition) and Home shows the This month card; no extra snackbar (the card itself is the confirmation).

## 8. Shortfall decision sheet (D-036, D-043)
Design system §7.8 **decision sheet** (it plays the role F-008 calls "dialog").

| Part | Shortfall | Exactly zero | Edit shortfall |
|---|---|---|---|
| Title | `Your numbers don't add up` | `Nothing left for daily spending` | `Your numbers don't add up` |
| Body | `Your fixed costs are ₹1,000 more than your salary.` (`spending target` / `money left`) | `Your fixed costs take up all of your salary, so there's ₹0 a day to spend.` | `This change leaves you ₹2,550 short for the rest of the month.` |
| Button 1 (Primary, first) | `Fix my numbers` + caption below: `Recommended. Change your costs or target so the month adds up.` | same | same |
| Button 2 (Secondary) | `Continue anyway` + caption below: `Start with ₹0 a day. Every spend this month will count as overspent.` | same | same |

- **Fix my numbers:** closes, saves nothing, scrolls to and focuses the first fixed-cost amount field (F-008 AC-8).
- **Continue anyway:** closes and saves (§7), then Home shows the shortfall.
- Scrim, swipe or back: close, save nothing, focus returns to the Confirm button.

## 9. Discard sheet
Decision sheet. Title `Discard changes?`, body `Your changes to this month won't be saved.` Button 1 Primary `Keep editing` (hint `Go back to your changes`); button 2 Destructive `Discard` (hint `Leave without saving`). Keep editing first because it is the safe choice. Scrim/back = Keep editing.

## 10. Home month states (F-008 §2.1)

### 10.1 No confirmed month
The Home empty state (design system §7.10) with a **Primary** button (new allowance in §7.10: an empty state may use Primary when its button is the only way forward):
- Icon `today`; title `Your daily budget lives here` (kept from F-003); description `Tell us your salary and fixed costs, and we'll work out what you can spend each day.`; button `Set up your month` (hint `Open month setup`).
- The Home first-time hint stays above it, unchanged (ID `hint.home.v1`).

### 10.2 This month card
Card (§7.2) under the title (and hint):
- Header: `This month` (`title`).
- Line 1: `5 Nov – 4 Dec · ₹830 a day` (`bodyLarge`; the amount in Plex 600 `textPrimary`). After a mid-month edit the amount is **today's** daily budget (`₹630 a day`).
- Shortfall month (after Continue anyway): a panel as in §5 (`overspentSoft`): `◆ −₹1,000 this month` (`label` 600, `overspent`) and `Every spend this month counts as overspent.` (`body`, `textPrimary`).
- Button: Secondary `Edit this month` (hint `Change this month's salary, target or fixed costs`), full width, `space4` above.
- Semantics: `This month, 5 November to 4 December, ₹830 a day.` Shortfall adds `Minus ₹1,000 this month. Every spend this month counts as overspent.`

### 10.3 New month started
Card with header `Your new month has started` (`title`), description `Check last month's numbers and confirm.` (`body`, `textSecondary`), Primary `Set up this month` (hint `Set up your new budget month`). It replaces the This month card until the new month is confirmed.

### 10.4 Home cannot read the month (F-007 §5, PM addition at Gate 2)
The Home empty state (§7.10) in place of the month content: icon `error_outline` in `neutral` inside the `neutralSoft` circle; title `Couldn't load your data`; description `Tap Try again. Nothing has been lost.`; **Primary** `Try again` (hint `Try to load your data again`). Neutral colours, never red (§7.12). It never shows `Set up your month`, so a read failure can't invite a second setup (TC-008-52).

### 10.5 Storage error screen (F-007 AC-8/AC-9, PM addition at Gate 2)
Shown by the database gate instead of the tabs, full screen, no bottom navigation, in the saved theme. Same empty-state layout (§7.10), top-aligned under `space7`: icon `error_outline` (`neutral`), title `We couldn't open your data` (`headline`), description `Your budget data is still on this phone. Try again, and if this keeps happening, restart your phone.`, **Primary** `Try again` (hint `Try to open your data again`). No file paths, error codes or SQLite text (TC-007-45). Reading order: title, description, button. Swept with the Phase 2 states (TC-008-24) in all four themes at 1.0/2.0 and landscape.

## 11. States (setup screen)

| State | What the user sees |
|---|---|
| First-time | First-month mode: no salary day, Rent/EMI/Subscriptions with empty amounts, Total `₹0`, preview prompts, dock `—`. |
| Normal | Values entered, preview live. |
| Empty | Fixed-cost list empty (all deleted, or mid-month start): card with only `+ Add item`; Total `₹0`. |
| Loading | Pre-fill / edit values are read before the screen is pushed; no spinner. Saving: progress ring in Confirm. |
| Error | Field errors (§4, §7.12 style); save failure snackbar (§7). |
| Permission denied | Not applicable. |
| Shortfall / zero | §5 panel, §6 dock line, §8 sheet. |
| Pre-filled (new month) | Notice line, all values filled, Salary day read-only. |
| Edit | Title `Edit this month`, read-only Salary day, `Save changes` disabled until changed, edit preview line. |

## 12. Themes

| Element | Light | Dark | Dim |
|---|---|---|---|
| Page / card / field fill | `#F6F3ED` / `#FFFDF8` / `#EEEAE2` | `#0E0E12` / `#17171D` / `#0A0A0D` | `#2A2825` / `#34312D` / `#24221F` |
| Field outline / focused / error | `#8A8377` / `#3A3DB0` / `#B4372F` | `#6A6876` / `#9C9FFF` / `#FF7B6F` | `#878073` / `#ABACF6` / `#FF9C8E` |
| Shortfall panel fill / ◆ text | `#F6E0DC` / `#B4372F` (4.71) | `#3A1A17` / `#FF7B6F` (6.20) | `#4A3230` / `#FF9C8E` (5.81) |
| Zero panel fill / ○ text | `#EAE6DF` / `#68646E` (4.64) | `#24242B` / `#9F9CA7` (5.72) | `#3D3A35` / `#B6AFA4` (5.21) |
| Day chip selected | `#3A3DB0` + white | `#9C9FFF` + `#14143D` | `#ABACF6` + `#1B1B3D` |
| Dock | `#FFFDF8` + `#DED8CD` rule | `#17171D` + `#2A2A33` | `#34312D` + `#48453F` |

All pairs are in design system §3. Auto follows the phone (Light or Dark).

## 13. Largest text (2.0×, 360 × 640 dp) and landscape (640 × 360)
- **No dock** above 1.3× and in landscape: preview card and Confirm are inline at the end of the form (plan default). The keyboard never hides the focused field (`Scrollable.ensureVisible` on focus). This block at the end of the page is the intended behaviour (T-248), not a fallback: with the keyboard open the user scrolls to `Start my month`, or presses Done on the last field to close the keyboard.
- **Fixed-cost rows stack** above 1.3×: Name field full width, then Amount field full width with the × to its right; the column captions are replaced by each field's own small label (`Name`, `Amount`) so nothing relies on a column header.
- **Spendable line** wraps; amounts never split (word joiner inside `−₹`, non-breaking digits).
- **Shortfall panel** rows stack: `₹0 a day` on one line, `◆ ₹1,000 short` on the next.
- **Day chips**: the grid drops to 5 columns above 1.5× so two-digit numbers fit in 48 dp chips; the sheet scrolls, Done stays pinned.
- **Title** wraps (`Set up your month` ≈ 2 lines at 52 sp).

## 14. Accessibility
- Reading order: back, title, notice, fields top to bottom, preview card, Confirm.
- Each amount field reads `<label>, <value>, edit box`, then the error if any.
- The preview card is one container; Daily line is a polite live region (§5).
- All targets ≥ 48 dp; the 20 dp × on items has a 48 dp target.

## Change history
| Date | Change | By |
|---|---|---|
| 2026-11-13 | T-248 (PM Gate 4 O3, D-071): §6 keyboard open: the dock line must stay visible above the keyboard (the build did not do this); new keyboard actions Next / Done on the last field; §13 the no-dock block at the end is intended. Expected result of TC-008-27 fixed (see `tests/F-008-month-setup.md`). Owner preview: new keyboard-open mockups. Developer follow-up T-250 | Designer |
| 2026-11-10 | First version (Phase 2, Step 6) | Designer |
| 2026-11-16 | T-251: §6 one line: the dock is the Scaffold bottom bar lifted by the keyboard inset, so snackbars stay above it. No visual change | Designer |
| 2026-11-13 | T-238 (D-069, Gate 3 T2): §4.2 amount fields show digits as typed, no grouping while typing; the grouped amount shows in the live preview (§4.4, §5); mockup fields now `₹ 40000`, `₹ 10000`. Mockup and wording only; no other change | Designer |
| 2026-11-13 | T-241 (PM Gate 3: U3, U5): §5 the daily amount changes at once while typing, no 600 ms count-up (the Transactions Today line keeps its count-up); §5 new mid-month empty row `Enter the money you have left to see your daily budget`; §6 mid-month dock label `Enter how much you have left`. Records what was approved and built; no other change | Designer |
| 2026-11-11 | §4.5a late/missed-month setup (Owner D-057); no new component | Project Manager |
| 2026-11-10 | Gate 2 (PM): §4.5 edit-mode money-left label and one-day notice (D-048); §5 one-day month and edit lines; new §10.4 Home load error and §10.5 storage error screen (F-007 §5, which no spec covered). Status → Approved | Project Manager |

---

## Owner preview

### First setup, filled in (Light, portrait, keyboard closed)
```
┌──────────────────────────────────────┐
│ ←                                    │
│ Set up your month                    │
│                                      │
│ Salary day (i)                       │
│ The day your salary usually arrives. │
│ ┌──────────────────────────────────┐ │
│ │ 5th                            ⌄ │ │
│ └──────────────────────────────────┘ │
│ Monthly salary                       │
│ What you receive in your bank        │
│ account each month, after tax.       │
│ ┌──────────────────────────────────┐ │
│ │ ₹ 40000                          │ │
│ └──────────────────────────────────┘ │
│ Spend less than my salary     ( ○ )  │
│ Set a smaller amount to budget …     │
│                                      │
│ Fixed costs                          │
│ Bills you pay every month, like rent │
│ ╭──────────────────────────────────╮ │
│ │ Name                 Amount      │ │
│ │ [Rent         ] [₹ 10000   ]  ×  │ │
│ │ [EMI          ] [₹  5000   ]  ×  │ │
│ │ [Subscriptions] [₹   100   ]  ×  │ │
│ │ + Add item                       │ │
│ ╰──────────────────────────────────╯ │
│ Total fixed costs           ₹15,100  │
│──────────────────────────────────────│
│ Daily budget              ₹830 a day │
│ ┌──────────────────────────────────┐ │
│ │          Start my month          │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### The preview card (scrolled to the end, Light)
```
┌──────────────────────────────────────┐
│ ╭──────────────────────────────────╮ │
│ │ Your daily budget                │ │
│ │ Budget month                     │ │
│ │           5 Nov – 4 Dec · 30 days│ │
│ │ Spendable this month (i)         │ │
│ │ ₹40,000 − ₹15,100 fixed = ₹24,900│ │
│ │──────────────────────────────────│ │
│ │ Daily budget (i)     ₹830 a day  │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```

### Shortfall: salary ₹20,000, rent ₹15,000, EMI ₹6,000 (Dark)
```
┌──────────────────────────────────────┐
│ ╭──────────────────────────────────╮ │
│ │ Your daily budget                │ │
│ │ Spendable this month (i)         │ │
│ │ ₹20,000 − ₹21,000 fixed = −₹1,000│ │
│ │ ╭──────────────────────────────╮ │ │
│ │ │ ₹0 a day     ◆ ₹1,000 short  │ │ │
│ │ │ Your fixed costs are ₹1,000  │ │ │
│ │ │ more than your salary.       │ │ │
│ │ ╰──────────────────────────────╯ │ │
│ ╰──────────────────────────────────╯ │
│──────────────────────────────────────│
│ Daily budget        ◆ ₹1,000 short   │
│ ┌──────────────────────────────────┐ │
│ │          Start my month          │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```
(The inner panel is a soft red tint with coral-red "◆ ₹1,000 short".)

### Tapping Start my month with the shortfall (Dark)
```
┌──────────────────────────────────────┐
│░░░░░░░░░ (setup, dimmed) ░░░░░░░░░░░░│
│╭────────────────────────────────────╮│
│               ────                   │
│  Your numbers don't add up           │
│                                      │
│  Your fixed costs are ₹1,000 more    │
│  than your salary.                   │
│                                      │
│  ┌────────────────────────────────┐  │
│  │         Fix my numbers         │  │
│  └────────────────────────────────┘  │
│  Recommended. Change your costs or   │
│  target so the month adds up.        │
│  ┌────────────────────────────────┐  │
│  │        Continue anyway         │  │
│  └────────────────────────────────┘  │
│  Start with ₹0 a day. Every spend    │
│  this month will count as overspent. │
└──────────────────────────────────────┘
```

### Mid-month first setup: salary day 5, today 10 Nov (Dim)
```
┌──────────────────────────────────────┐
│ ←                                    │
│ Set up your month                    │
│                                      │
│ Salary day (i)                       │
│ ┌──────────────────────────────────┐ │
│ │ 5th                            ⌄ │ │
│ └──────────────────────────────────┘ │
│ ⓘ You're starting partway through    │
│   the month, so we'll spread the     │
│   money you have left over the 25    │
│   days until your next salary.       │
│ Money left now                       │
│ How much you have to spend until     │
│ your next salary.                    │
│ ┌──────────────────────────────────┐ │
│ │ ₹ 24,900                         │ │
│ └──────────────────────────────────┘ │
│ Fixed costs still to pay this month  │
│ ╭──────────────────────────────────╮ │
│ │ + Add item                       │ │
│ ╰──────────────────────────────────╯ │
│ Total fixed costs                ₹0  │
│──────────────────────────────────────│
│ Daily budget              ₹996 a day │
│ ┌──────────────────────────────────┐ │
│ │          Start my month          │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```
(Preview card month line: "10 Nov – 4 Dec · 25 days left".)

Same form before the money is entered (T-241, U5):
```
│ Money left now                       │
│ ┌──────────────────────────────────┐ │
│ │ ₹                                │ │
│ └──────────────────────────────────┘ │
│ ╭──────────────────────────────────╮ │
│ │ Enter the money you have left to │ │
│ │ see your daily budget            │ │
│ ╰──────────────────────────────────╯ │
│──────────────────────────────────────│
│ Enter how much you have left       — │
```

### Edit this month on 20 Nov, rent ₹10,000 → ₹13,000 (Light)
```
┌──────────────────────────────────────┐
│ ←                                    │
│ Edit this month                      │
│ Salary day: 5th                      │
│ Set in your first month.             │
│   …                                  │
│ ╭──────────────────────────────────╮ │
│ │ Your daily budget                │ │
│ │ ₹40,000 − ₹18,100 fixed = ₹21,900│ │
│ │──────────────────────────────────│ │
│ │ From today (20 Nov): ₹630 a day  │ │
│ │ for the 15 days left. Days       │ │
│ │ before today keep their budget.  │ │
│ ╰──────────────────────────────────╯ │
│──────────────────────────────────────│
│ From today                ₹630 a day │
│ ┌──────────────────────────────────┐ │
│ │           Save changes           │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### Home: before setup, and after (Light)
```
┌──────────────────────────────────────┐
│ Daily Budget App                     │
│  ╭────╮                              │
│  │ ▦  │                              │
│  ╰────╯                              │
│ Your daily budget lives here         │
│ Tell us your salary and fixed costs, │
│ and we'll work out what you can      │
│ spend each day.                      │
│ ┌──────────────────────────────────┐ │
│ │        Set up your month         │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
┌──────────────────────────────────────┐
│ Daily Budget App                     │
│ ╭──────────────────────────────────╮ │
│ │ This month                       │ │
│ │ 5 Nov – 4 Dec · ₹830 a day       │ │
│ │ ┌──────────────────────────────┐ │ │
│ │ │       Edit this month        │ │ │
│ │ └──────────────────────────────┘ │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```

### Home after "Continue anyway" (Dim)
```
┌──────────────────────────────────────┐
│ ╭──────────────────────────────────╮ │
│ │ This month                       │ │
│ │ 5 Nov – 4 Dec · ₹0 a day         │ │
│ │ ╭──────────────────────────────╮ │ │
│ │ │ ◆ −₹1,000 this month         │ │ │
│ │ │ Every spend this month       │ │ │
│ │ │ counts as overspent.         │ │ │
│ │ ╰──────────────────────────────╯ │ │
│ │ ┌──────────────────────────────┐ │ │
│ │ │       Edit this month        │ │ │
│ │ └──────────────────────────────┘ │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```

### First setup with the keyboard open, normal text (Light, portrait) - T-248
```
┌──────────────────────────────────────┐
│ Monthly salary                       │
│ ┌──────────────────────────────────┐ │
│ │ ₹ 40000|                         │ │
│ └──────────────────────────────────┘ │
│ Spend less than my salary     ( ○ )  │
│ Fixed costs                          │
│ [Rent         ] [₹ 10000   ]  ×      │
│──────────────────────────────────────│
│ Daily budget              ₹830 a day │  <- dock line stays above keys
│──────────────────────────────────────│
│ [ 1 ][ 2 ][ 3 ]            [ Next ]  │
│ [ 4 ][ 5 ][ 6 ]                      │
│ [ 7 ][ 8 ][ 9 ]                      │
│ [ , ][ 0 ][ . ]                      │
└──────────────────────────────────────┘
 (No Start my month yet. On the last field the key says Done; Done closes
  the keyboard and the button appears.)
```

### First setup with the keyboard open, 2.0x text (Light, 360 x 640)
```
┌──────────────────────────────────────┐
│ Daily budget            ₹830 a day   │
│ ┌──────────────────────────────────┐ │
│ │          Start my month          │ │  <- last item of the page,
│ └──────────────────────────────────┘ │     reached by scrolling
│──────────────────────────────────────│
│ [ 1 ][ 2 ][ 3 ]            [ Done ]  │
│ [ 4 ][ 5 ][ 6 ]                      │
│ [ 7 ][ 8 ][ 9 ]                      │
└──────────────────────────────────────┘
 (No pinned dock at this text size. The page scrolls above the keyboard.)
```

### Why these choices
- **Keyboard open (T-248):** the daily number stays in sight above the keyboard, so the user still sees ₹830 change while typing; Confirm waits until the keyboard is closed, so a stray tap cannot save a half-typed month. Next / Done keys make closing the keyboard one natural press instead of a hunt for the back gesture.
- **The daily budget is pinned at the bottom while you type**, so you watch ₹830 change as you enter rent and EMIs; the full working-out sits at the end of the form.
- **A shortfall is shown as overspending (soft red, ◆, "₹1,000 short")**, never as an error, and "Fix my numbers" is the big first button while "Continue anyway" stays one honest tap away.
- **One form adapts to the month**: mid-month asks only for the money left now and what's still to pay; editing shows exactly what changes from today.
