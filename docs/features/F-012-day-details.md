# F-012: Day details & cover with savings

| | |
|---|---|
| **Phase** | 3 |
| **Status** | Spec (final, ready for the plan; planned ahead, D-033). D-034 to D-040, D-046 to D-048, D-050, D-054 to D-056 are applied (D-056: undo/remove a cover is in scope, §2.5) |
| **Plan** | [`plans/F-012-day-details.md`](../../plans/F-012-day-details.md) |
| **Test cases** | [`tests/F-012-day-details.md`](../../tests/F-012-day-details.md) |
| **Tasks** | T-3xx (assigned by the Project Manager at Step 5) |

## 1. What it is *(Product Manager)*
A screen for **one day** of the budget month (README §3.5, screen 6). It opens from a calendar cell (F-011) or from Home's Today card (F-010). It shows:
- the day's budget, what was spent (and refunded, D-047), and the result: saved, on budget or overspent;
- every spend and refund of that day.

From here the user can add, edit or delete that day's spends, reusing the F-009 editor. On an **overspent past day** they can tap **Cover with savings** to move money from the savings pot to that day (D-005). The cover follows the F-006 engine rules exactly: never more than the pot holds, and never more than the day's uncovered overspend. This feature adds **no money rule**.

**User stories:**
- As a **user**, I want to tap a day and see what I spent and why it went red.
- As a **user who overspent**, I want to use my savings to cover that day, because it's my choice (D-005).
- As a **user**, I want to fix a wrong spend from the day it belongs to.

## 2. How it behaves *(Product Manager)*
Full screen or sheet per the Designer (Step 6). Data from the F-006 engine and F-007 repositories.

### 2.1 Layout (budgeted day, current month)
1. **Header:** the date (`Wed, 11 Nov`), with a **status line** that uses words + mark + colour: `◆ Overspent ₹300` / `● Saved ₹330` / `○ On budget` / `Today · ₹410 left` / `Today · overspent ₹120`.
2. **Figures**, each with an (i):
   - `Budget` is the day's budget from the engine, in whole rupees (D-038).
   - `Spent` is the day's spends.
   - `Refunds` is shown only when the day has refunds (D-047). It is followed by `Net spent`.
   - `Covered from savings` is shown only when the day has a cover.
   - **Result** is the engine's day result: `Saved ₹x` / `On budget` / `Overspent ₹x`.
3. **Cover with savings** area, only on a past overspent day of the current month (§2.3).
4. **Entries:** the day's spends and refunds, newest first, with F-009 row style and copy (`₹250 · Lunch`, or `No note`). A refund row shows the word `Refund`, the amount as `+₹500` and its note. It is not coloured: words carry the meaning. Tap a row to open the F-009 **Edit** screen. The F-009 Delete flow is unchanged.
5. **Add spend** button. It opens the F-009 Add screen with the **date pre-set to this day**. The user can still change it, within F-009's limits.
6. **Budget changed on this day** line, only on a period's first day (D-037). It opens F-014.

### 2.2 Worked examples (₹830 a day, month 5 Nov – 4 Dec; data as in F-010 §2.4, today Fri 13 Nov, pot ₹2,000)
| Day | Header | Figures | Cover area |
|---|---|---|---|
| Thu 5 Nov | `● Saved ₹330` | Budget ₹830 · Spent ₹500 | none |
| Fri 6 Nov | `◆ Overspent ₹170` | Budget ₹830 · Spent ₹1,000 | `Cover with savings` (up to ₹170) |
| Wed 11 Nov | `◆ Overspent ₹300` | Budget ₹830 · Spent ₹1,130 | `Cover with savings` (up to ₹300) |
| Thu 12 Nov | `● Saved ₹830` | Budget ₹830 · Spent ₹0 · `Nothing spent this day` | none |
| Fri 13 Nov (today) | `Today · ₹410 left` | Budget ₹830 · Spent ₹420 | none. Today joins the pot at midnight (D-039) |
| Sat 14 Nov | `Upcoming` | Budget ₹830 · `This day hasn't happened yet.` | none. No Add spend |

**Refund example (D-047).** Mon 16 Nov, as a past day: spend ₹700 "Shoes", refund ₹500 "Amazon return".
- Spent ₹700 − refunds ₹500 = **net spent ₹200**.
- Result 830 − 200 = **Saved ₹630**.
- If the refund were ₹1,500, net spent would be −₹800 and the day **Saved ₹1,630**, more than its budget (D-047).

**Mid-month change example (example M, F-010 §2.6).** Fri 13 Nov 2026 (salary day 1 month):
- Budget ₹552 (exact ₹552.23).
- The line `Budget changed on this day: salary ₹40,000 → ₹35,000` is shown, and opens F-014.

**Shortfall example (example S).** Fri 6 Nov:
- Budget ₹0 · Spent ₹200 · `◆ Overspent ₹200`.
- The pot is ₹0, so the cover area shows `Your savings pot is empty.` and no cover button.

### 2.3 Cover with savings
- **Shown** on any budgeted, **overspent** day of the **current** budget month **up to and including today** (D-048 (2): today's live day can be covered). It is not offered on upcoming days or past months.
- **Today:** the cover area adds `Spending more today will make it overspent again.` Example: today Fri 13 Nov with ₹1,000 spent is `Today · overspent ₹170`, and covering ₹170 makes it `Today · on budget`, covered ₹170.
- The area shows `Savings pot ₹2,000` and a Primary button **Cover with savings**.
- **When the pot is ₹0:** the button is not shown. The area reads `Your savings pot is empty.` with the (i).
- **Tapping the button** opens a **cover sheet** (design system §7.8):
  - Title `Cover Wed, 11 Nov`.
  - The line `Overspent ₹300 · Savings pot ₹2,000`.
  - An **Amount** field (F-008 amount field), **pre-filled with the most that can be covered**: the lesser of the pot and the day's uncovered overspend, in exact paise. Inside the input, paise show (D-038), e.g. `47.78`.
  - The caption `This covers the whole overspend.` (or `This uses your whole savings pot.` when the pot is the limit).
  - Buttons: **Cover** (Primary, first) and **Cancel**.
- **Validation** (the engine's rules, F-006 §2.4):
  - empty or ₹0 → `Enter an amount more than ₹0`;
  - more than the pot → `That's more than your savings pot (₹2,000).`;
  - more than the uncovered overspend → `That's more than this day's overspend (₹300).`;
  - more than 2 decimals or letters → the F-008 format error.
  - The messages follow the engine's refusal order (D-048 (1)): not positive → … → not overspent → more than the day's overspend → more than the pot. So if **both** limits are exceeded, the **overspend message** is shown.
- **On Cover:**
  - The cover is saved as one unit (F-007).
  - The sheet closes, and a snackbar says `₹300 covered from your savings` with **Undo** (6 s, §2.5).
  - The header, figures, calendar (F-011) and Home summary (F-010) update.
- **Example A:**
  - **Cover 11 Nov ₹300:** the day reads `○ On budget`, `Covered from savings ₹300`, and the pot shows ₹1,700. The cover area is replaced by `Covered ₹300 from savings.`
  - **Cover 11 Nov ₹100 instead:** the day reads `◆ Overspent ₹200`, `Covered from savings ₹100`, and the pot shows ₹1,900. The button stays, now for up to ₹200.
  - **Pot as the limit:** with a pot of ₹250 and 11 Nov overspent ₹300, the field is pre-filled with `250`, the caption reads `This uses your whole savings pot.`, and after Cover the day is `◆ Overspent ₹50`, with the pot at ₹0.
  - **Covering 6 Nov after 11 Nov's ₹300:** pre-filled `170`. After the cover the pot is ₹1,530.
- **A double tap on Cover saves once.**
- **Save failure:** the F-007 save error is shown, the sheet stays open with the amount kept, and nothing changes.

### 2.4 Editing from day details (reuses F-009)
- Add, edit and delete behave exactly as in F-009. When the editor closes, the day details screen shows the updated figures.
- **The pot shrinks below the covers (D-040):** the F-009 note sheet `Savings pot updated` is shown once, naming each cover that was taken back. Newest covers are reduced first.
  - Example: 11 Nov covered ₹300 (today 13 Nov). The user raises the 12 Nov spend from ₹0 to ₹830 and 5 Nov's from ₹500 to ₹830. Saved falls from ₹2,000 to ₹840 (630 + 210). The covers of ₹300 still fit, so no note is shown.
  - The newest-first case is F-009 AC-19.
- **Editing a covered day so that its overspend falls below the cover:** the extra cover goes back to the pot with no note (F-006 §4). The day then shows the reduced `Covered from savings`. The reduction is **stored** with the edit and never comes back (D-048 (6)): raising the spend again later leaves the day overspent, and the user can cover it again.
- **Several covers cut by one edit:** one `Savings pot updated` sheet, newest cover first (D-048 (6), F-009 §5).
- **Order of entries:** within the day, the newest **added** entry comes first, and an edit never moves an entry (D-048 (8)).
- **Moving a spend to another date** in the editor: day details stays on its own day and updates. The snackbar says `Spend moved to <date>`.

### 2.5 Undo and remove a cover (D-056 (1))
- **Undo:** the `covered` snackbar has **Undo** for 6 s (with TalkBack on it stays until dismissed, design §6). Undo deletes that one cover. The day, pot, calendar and Home return to exactly their values before the cover. The snackbar then says `Cover undone`.
- **Remove cover:** on any day of the current month with `Covered from savings` above ₹0, that line has a text button **Remove**. It opens a decision sheet:
  - title `Remove this cover?`;
  - body `₹300 goes back to your savings pot, and Wed, 11 Nov is overspent ₹300 again.`;
  - buttons **Remove cover** (first, the action the user asked for) and **Keep it**.
  - On a day with several covers, Remove takes them **all** away, and the body names the total.
  - Example A after covering 11 Nov ₹300: Remove gives `◆ Overspent ₹300`, pot ₹2,000, and Home's Overspent goes back to ₹470.
- **No new money rule:** removing only deletes the user's own savings-move records (F-007). The pot can only grow, so D-040 never triggers.
- **Not offered** on past months (read-only), or for a cover already reduced to ₹0 by D-040 (there is nothing to remove; the line is hidden).
- **Removing, then a failure:** the F-007 save error is shown, and nothing changes.

### 2.6 Read-only cases
- **A past month's day:** all the figures are shown, with the line `This month has ended, so its days can't be changed.` There is no Add spend, no cover, and rows can't be tapped.
- **An upcoming day:** the budget only, and `This day hasn't happened yet.` There are no rows (future-dated spends from a moved-back device date are listed with `Dated in the future`), no Add spend and no cover.
- **New month not set up:** the previous month is read-only (F-011 AC-14).

## 3. Acceptance criteria *(Product Manager)*
Fixed "today" and engine test data (example A unless stated). Themes and accessibility per F-002 §3.

| ID | Given / When / Then |
|---|---|
| AC-1 | **Opens from both places.** Given example A, when the user taps the 11 Nov calendar cell, then day details opens for Wed 11 Nov; when the user taps the Today card on Home, then it opens for Fri 13 Nov; back returns to Home at the same scroll position. |
| AC-2 | **Figures per day.** Given example A, when day details is opened for each row of the §2.2 table, then the header status line, Budget, Spent, result and cover area match the table exactly (words, mark and colour token). |
| AC-3 | **Entry list.** Given 9 Nov with two spends (₹250 "Lunch" added first, ₹370 no note added second), when opened, then both rows are listed newest-added first as `₹370 · No note` then `₹250 · Lunch`, and Spent reads `₹620`; when the ₹250 row is edited to ₹260, then the order does not change (D-048 (8)). |
| AC-4 | **Cover offered only where allowed (D-048).** Given example A, when day details is opened for 6 and 11 Nov, then **Cover with savings** and `Savings pot ₹2,000` are shown; for 5, 7, 12 Nov (not overspent), 13 Nov (today, not overspent) and 14 Nov (upcoming), then no cover button is shown; for an overspent day of last month, then no cover button is shown. Given today 13 Nov with ₹1,000 spent (`Today · overspent ₹170`), then the button and the line `Spending more today will make it overspent again.` are shown. |
| AC-5 | **Full cover.** Given 11 Nov overspent ₹300 and pot ₹2,000, when the user taps Cover with savings, then the sheet shows `Overspent ₹300 · Savings pot ₹2,000`, the field pre-filled `300` and `This covers the whole overspend.`; when Cover is tapped, then exactly one savings move of 30,000 paise for 11 Nov is stored, the snackbar reads `₹300 covered from your savings`, the day reads `○ On budget` with `Covered from savings ₹300`, the calendar cell is ○, and Home shows Overspent `₹170` and the pot sub-line `₹1,700 in your savings pot · ₹300 used to cover days`. |
| AC-6 | **Partial cover.** Given the same day, when the user enters 100 and taps Cover, then the day reads `◆ Overspent ₹200`, `Covered from savings ₹100`, the pot is ₹1,900, and Cover with savings is still offered with the field pre-filled `200`. |
| AC-7 | **Pot is the limit.** Given 11 Nov overspent ₹300 and a pot of ₹250 (test data), when the sheet opens, then the field is pre-filled `250` with `This uses your whole savings pot.`; after Cover the day is `◆ Overspent ₹50`, the pot is ₹0, and the cover area reads `Your savings pot is empty.` |
| AC-8 | **Cover validation.** Given 11 Nov overspent ₹300 and pot ₹250, when the amount is (a) empty, (b) 0, (c) 260, (d) 300.01 with pot ₹2,000, (e) 12.345, (f) letters, then the sheet shows (a)/(b) `Enter an amount more than ₹0`, (c) `That's more than your savings pot (₹250).`, (d) `That's more than this day's overspend (₹300).`, (e)/(f) the F-008 format error; nothing is stored and the engine output is unchanged; given 400 with pot ₹250 (both limits), then the overspend message `That's more than this day's overspend (₹300).` is shown (D-048 (1) order). |
| AC-9 | **Paise maximum.** Given a day overspent by exactly 4,778 paise (example M, 18 Nov ₹600 spent on ₹552.22) and a pot of ₹2,000, when the sheet opens, then the field is pre-filled `47.78`, the line reads `Overspent ₹47`, and after Cover the day is `○ On budget` (result exactly 0 paise). |
| AC-10 | **Empty pot.** Given example S (shortfall, pot ₹0) and 6 Nov overspent ₹200, when opened, then no Cover button is shown and `Your savings pot is empty.` is shown with its (i). |
| AC-11 | **Once per tap, save failure.** Given the cover sheet, when Cover is double-tapped, then exactly one savings move is stored; given a forced write failure, when Cover is tapped, then the F-007 save error is shown, the sheet stays open with the amount, and no move is stored. |
| AC-12 | **Add from the day.** Given day details for Sun 8 Nov, when the user taps Add spend, enters ₹100 and saves, then the F-009 editor opened with date `Sun, 8 Nov`, the spend is stored for 8 Nov, and day details shows Spent `₹300` and `● Saved ₹530`. Given an upcoming day or a past month's day, then no Add spend button is shown. |
| AC-13 | **Edit and delete from the day.** Given 9 Nov's ₹370 row, when the user edits it to ₹470, then the screen shows Spent `₹720`, `● Saved ₹110`; when the user deletes the ₹250 row through F-009's confirmation, then Spent reads `₹470` and the row is gone; when the user changes a spend's date to 8 Nov, then it leaves 9 Nov's list and `Spend moved to Sun, 8 Nov` is shown. |
| AC-14 | **Cover taken back (D-040).** Given F-009 AC-19's data (5 Nov saved ₹330, 6 Nov overspent ₹170 covered ₹170, today 8 Nov), when the 5 Nov spend is edited from ₹500 to ₹830 from 5 Nov's day details, then F-009's `Savings pot updated` sheet is shown once with its exact text, and 6 Nov's day details then shows `◆ Overspent ₹170` with no `Covered from savings` line. |
| AC-15 | **Over-covered edit returns the rest silently.** Given 6 Nov spent ₹1,000, covered ₹170, when its spend is edited to ₹900, then 6 Nov shows `○ On budget`, `Covered from savings ₹70`, the pot rises by ₹100, and no note is shown. |
| AC-16 | **Refunds (D-047).** Given ₹830/day and a past day with a ₹700 spend "Shoes" and a ₹500 refund "Amazon return", when opened, then the rows read `₹700 · Shoes` and `Refund · +₹500 · Amazon return`, the figures read Spent `₹700`, Refunds `−₹500`, Net spent `₹200`, result `● Saved ₹630`; with a ₹1,500 refund instead, then Net spent `−₹800` and `● Saved ₹1,630`. A day with no refunds shows no Refunds or Net spent lines. |
| AC-17 | **Period start and shortfall.** Given example M, when 13 Nov is opened, then Budget reads `₹552` and the line `Budget changed on this day: salary ₹40,000 → ₹35,000` is shown and opens F-014; 14 Nov has no such line. Given example S, when 6 Nov is opened, then Budget `₹0`, `◆ Overspent ₹200`. |
| AC-18 | **Read-only and upcoming.** Given a day in a past month, when opened, then all figures are shown with `This month has ended, so its days can't be changed.`, rows are not tappable, and there is no Add spend or cover. Given 14 Nov (upcoming), then only `Budget ₹830` and `This day hasn't happened yet.` are shown. |
| AC-19 | **Help, themes, large text, accessibility.** Given day details (overspent, saved, refund, read-only) and the cover sheet, when shown in all four themes at text scale 1.0 and 2.0 on a small phone and in landscape (D-030), then F-002 AC-12–AC-14 pass, every figure and the cover button have their §5 label and (i) via F-004, the keyboard never hides the amount field or Cover, and TalkBack reads the header as one sentence (`Wednesday 11 November, overspent ₹300`) and each row as F-009's row sentence (refund rows: `Refund, ₹500, Amazon return`). |
| AC-20 | **Cover today (D-048 (2)).** Given today 13 Nov with ₹1,000 spent and pot ₹2,000, when the user covers ₹170, then the header reads `Today · on budget`, `Covered from savings ₹170`, the pot is ₹1,830, and the Today card on Home reads `on budget`; when a further ₹100 spend is added today, then the header reads `Today · overspent ₹100` with the cover still ₹170; when instead the ₹1,000 spend is edited to ₹900, then the cover is cut to ₹70 and stored, the pot is ₹1,930, no note is shown, and raising the spend back to ₹1,000 leaves the cover at ₹70 and the day `overspent ₹100` (D-048 (6)). |
| AC-21 | **Undo a cover (D-056).** Given 11 Nov overspent ₹300, pot ₹2,000, when the user covers ₹300 and taps **Undo** on the snackbar within 6 s, then no savings move is stored for 11 Nov, the day reads `◆ Overspent ₹300`, the pot is ₹2,000, the calendar cell is ◆, Home shows Overspent ₹470, and `Cover undone` is shown; after 6 s the Undo action is gone (cover stays). |
| AC-22 | **Remove a cover (D-056).** Given 11 Nov covered with ₹100 and then ₹200 (two moves), when the user taps **Remove** on `Covered from savings ₹300`, then the sheet `Remove this cover?` reads `₹300 goes back to your savings pot, and Wed, 11 Nov is overspent ₹300 again.` with **Remove cover** first and **Keep it**; **Keep it**, back and scrim change nothing; **Remove cover** deletes both moves, the day reads `◆ Overspent ₹300` and the pot rises by ₹300; no `Savings pot updated` note is shown; given a past month's covered day, or a cover cut to ₹0 by D-040, then no Remove button is shown; given a forced write failure, then the F-007 save error is shown and both moves stay. |

## 4. Edge cases *(Product Manager)*
- **Covering the same day twice:** allowed until it is fully covered (F-006 §4). Each cover is its own record. `Covered from savings` shows the sum.
- **The pot changes while the sheet is open** (not possible in one app session, but the field is checked again on Cover): the engine refuses an invalid cover and the sheet shows the matching message.
- **Midnight while day details for "today" is open:** when the app resumes, the header changes from `Today · …` to the date with its final status. If it is overspent, Cover is now offered.
- **A day overspent by less than ₹1** (₹830.40 spent): the header reads `◆ Overspent less than ₹1` (D-050, D-055), the sheet line reads `Overspent less than ₹1 · Savings pot ₹2,000`, and the cover field is pre-filled `0.40`.
- **₹10 crore spend:** the figures wrap at 2.0× text and are never truncated. The pre-filled cover is the pot.
- **Last spend of a day deleted:** the list shows `Nothing spent this day`. The day becomes Saved for its whole budget, and any cover on it goes back to the pot (F-006 §4).
- **Day details opened for a not-budgeted day:** not reachable (F-011 AC-13). A deep link, if one is ever added, shows the read-only text `Not budgeted: you started on <date>.`
- **Refund on a covered day** raising the result above 0: the extra cover goes back to the pot, as with any edit (F-006 §4).

## 5. Help text & copy *(Product Manager, finalised by Designer)*
| Control | Label | Description / tooltip |
|---|---|---|
| Header | `<weekday, d MMM>` | Status: `● Saved <x>` · `○ On budget` · `◆ Overspent <x>` · `Today · <x> left` · `Today · on budget` · `Today · overspent <x>` · `Upcoming`. Less than ₹1 (D-050, D-055): `● Saved less than ₹1` · `◆ Overspent less than ₹1` · `Today · less than ₹1 left` · `Today · overspent less than ₹1` |
| Budget | `Budget` | (i): `What you could spend on this day.` |
| Spent | `Spent` | (i): `Everything you spent on this day.` |
| Refunds | `Refunds` | Value written with a minus, `−<amount>`, so the column adds up (Designer; same as F-013). (i): `Money paid back to you on this day. It lowers what you spent.` |
| Day result (Designer) | `Day result` | Last line of the figures; value as the header status. (i): `The day's budget minus what you spent, after any cover from savings. Green ● saved, grey ○ on budget, red ◆ overspent.` |
| Spends heading (Designer) | `Spends` / `Spends and refunds` | — |
| Net spent | `Net spent` | (i): `What you spent minus refunds.` |
| Covered | `Covered from savings` | (i): `Money you moved from your savings pot to this day.` |
| Savings pot | `Savings pot <amount>` | (i): F-006 "Savings pot" |
| Cover button | `Cover with savings` | `Use money from your savings pot to cover this day.` Hint `Cover this day from your savings pot` |
| Empty pot | — | `Your savings pot is empty.` (i): `Your pot fills up on days you spend less than your budget.` |
| Fully covered | — | `Covered <amount> from savings.` |
| Cover sheet title | `Cover <weekday, d MMM>` | Line `Overspent <x> · Savings pot <y>` |
| Cover amount | `Amount` | Captions `This covers the whole overspend.` / `This uses your whole savings pot.` Errors: `Enter an amount more than ₹0` · `That's more than your savings pot (<pot>).` · `That's more than this day's overspend (<x>).` · F-008 format error |
| Cover / Cancel | `Cover` / `Cancel` | Hints `Move this amount from your savings pot` / `Close without covering` |
| Cover snackbar | — | `<amount> covered from your savings` · action `Undo`; after Undo: `Cover undone`; after Remove cover: `Cover removed`; save failure: `Couldn't save. Please try again.` |
| Today cover line | — | `Spending more today will make it overspent again.` |
| Remove cover | `Remove` | Hint `Remove the cover on this day` |
| Remove sheet | `Remove this cover?` | `<amount> goes back to your savings pot, and <weekday, d MMM> is overspent <amount> again.` Buttons `Remove cover` (hint `Give this money back to your savings pot`) · `Keep it` (hint `Close`) |
| Refund row | `Refund` | `+<amount> · <note>` |
| Nothing spent | — | `Nothing spent this day`; today: `Nothing spent yet today` |
| Upcoming | — | `This day hasn't happened yet.` |
| Past month | — | `This month has ended, so its days can't be changed.` |
| Change line | `Budget changed on this day` | `: <what changed>`. Hint `Open the month statement` |
| Moved snackbar | — | `Spend moved to <weekday, d MMM>` |
| Add spend | `Add spend` | Hint `Add a spend on this day` |
| Back | (icon) | Tooltip `Back` |

## 6. Out of scope
- Covering a day in a past month.
- Moving savings into the next month (F-006 suggested addition, Owner).
- Recording refunds. That is **F-016** (D-054). This doc only shows them, and its Add spend button opens the F-009 editor with F-016's Money back switch available.
- Categories on rows. These are shown in F-015's list only (F-013 shows totals).
- Any new money rule.

## 7. How it works — technical *(Developer, filled in when the feature is Done)*
**What was built.** The Day details screen (a full screen, not a sheet) opened from a calendar cell or the Home Today card: figures card, status line, spends and refunds of the day, the `Budget changed on this day` notice, and cover with savings with Undo and Remove cover. Tasks T-340 to T-346, T-475 and T-477. Gate 3 approved 2026-11-19 (D-088; T-340, T-343 and T-344 had Must fix items, fixed under D-090), Gate 4 pass 2026-11-23 (D-098).

**Main files** (`app/lib/`)
- Pure Dart in `domain/budget/`: `day_summary.dart` (`DaySummary` with `coverIds`, net `changes` and `isChangeDay`, `overspendUnderRupee`; `CoverOffer` = `CoverNone` / `CoverPotEmpty` / `CoverAvailable(max, limitedByPot)`; `DayResultKind`, shared with the calendar; `maxCover`, `coverCaption`), `cover_draft.dart` (`CoverDraft`, `validateCover`, `CoverOk` / `CoverNotOk(problem)`), `spend_groups.dart` (`spendsOnDay`).
- Data: `SavingsRepository.cover()` returns `CoverResult = ({decision, coverId})` and the new `removeCovers(monthId, ids)` deletes in one transaction (unknown ids and other months ignored), in `savings_repository.dart` and `drift_savings_repository.dart`.
- `core/providers/day_details_provider.dart` (`dayDetailsProvider` family, `DayDetailsView`); `features/day_details/` (`day_details_screen.dart` with `openDayDetails` and the launcher seam `dayDetailsLauncherProvider`, `budget_change_text.dart`, `widgets/` `figures_card`, `status_line`, `cover_card`, `cover_sheet`, `remove_cover_sheet`, `day_rows`); `core/copy/day_details_copy.dart`.
- Additive changes to F-009 files: `spend_editor_flow.dart` (`date`, `fromDay`, `Spend moved to <day>`, returns the result), `spend_editor_screen.dart` (`initialDate`, result carries `date`), `spend_list.dart` (public `SpendRow`), `BudgetButton.secondary` (optional `icon`). `statementDeltasOf` in `month_statement.dart` was made public so the change wording is one rule on both screens.

**Data stored.** Savings-pot moves through F-007 (a cover inserts a cover row; Remove cover deletes every stored cover row of the day, including rows cut to ₹0 by D-040). No new tables and no schema change.

**Decisions:** D-040, D-047, D-048 (today's live day can be covered; refusal order; over-cover cuts are stored and never come back), D-050 and D-055, D-056 (1) (Undo and Remove cover), D-077 (AC-16 `Refunds −₹500`; the Undo snackbar stays with TalkBack), D-078 (additive F-007 changes), D-079, D-088, D-089 (2) (cover-save error inside the sheet), (3) (Undo snackbar 5.75 s), (7) (count-up is a Nice to have), D-090 (1) and (2) (the under-₹1 test and the change text live in the domain layer), D-097, D-098, D-099, D-102.

**Deviations** (plan section 11; Gate 3 in `docs/reviews/code-phase-3-tracks-bc.md`)
- The savings repository tests are in a new file `cover_removal_test.dart` (TC-007-49 to -52, TC-012-09, TC-012-43; Drift and fake run the same bodies) instead of `savings_repository_test.dart`; three call sites in `months_repository_test.dart` read `.decision`.
- `Spend moved to <day>` shows only for an edit saved on another day than `fromDay`; an Add whose date was changed still says `Spend added`.
- The cover sheet shows `Couldn't save. Please try again.` inside the sheet (a live-region line under the field) because a snackbar sits under the sheet's scrim. The Undo snackbar is `persist: false` unless a screen reader is on, with a 5.75 s duration (its timer starts after the 250 ms slide-in), so Undo is gone 6 s after the cover. With the keyboard up on a short screen (under 420 dp left) only Cover stays pinned and Cancel scrolls.
- `Budget changed on this day` is written by the pure `budgetChangeText` (salary `₹40,000 → ₹35,000`, spending target, money left, the cost's name, added and removed items); a same-day double change that nets to nothing reads `changed and changed back`.
- The count-up animation of the figures (`motionCount`) is not built. Refund rows open the current spend editor (TC-012-58 checks the row and its hint only; F-016 adds the money-back editor).

**How it is tested** (`tests/F-012-day-details.md`, 74 cases, 22 ACs)
- Unit: `test/domain/budget/day_summary_test.dart` and `cover_draft_test.dart` (100 % lines and branches); the property test TC-012-56 (300 sequences on the fake repositories); `test/data/repositories/cover_removal_test.dart`.
- Widget (fakes): `test/features/day_details/` (`budget_change_text_test` with one test per branch and TC-012-27, `cover_sheet_test` with TC-012-45 and TC-012-72, `editor_seam_test`, figures, rows, Undo, Remove, read-only and upcoming states); sweeps in `test/a11y/calendar_day_sweep_test.dart` (four themes at text 1 and 2 on the small phone, landscape in Light and Dim, the cover sheet with an error).
- Integration on the emulator: `integration_test/day_details_cover_flow_test.dart` (cover, Undo, Remove, reopen; AC-5, 21, 22), exit 0 on every Step 8 run (`docs/reviews/emulator-phase-3/integration-day-details-cover-flow.log`, `step8-clean-day_details_cover_flow.log`).
- Probes: 19 Developer mutations in plan section 11, all killed except the sheet `_saving` guard (equivalent: `BudgetButton.loading` already swallows the second tap) and two that survived and got new assertions (the `coverId == null` branch and the 6 s duration); with the new tests they are killed. T-477 probe on `dayResultKind` (`< 100` made `<= 100`) killed by TC-012-72; the `cover_sheet.dart` under-₹1 line is guarded by a static check. Tester 2 re-applied the probes `maxCover`, refusal reasons and `persist`: all killed (`tests/PHASE-3-SUMMARY.md` 6.3).
- Device (A13 seed, 11 Nov): cover ₹300 with snackbar, Undo, cover again, Remove (nothing stored after Undo or Remove); Home pot ₹1,700 and Overspent ₹170 after the cover; screenshots `s8-day11-details.png`, `s8-cover300-snackbar.png`, `s8-tc012-64-after-kill.png`, `s8-tc012-64-sheet-100.png`.
- Result (2026-11-23, after T-495): 73 Pass, 1 Blocked-needs-human (TC-012-34), no Partial; no bug for F-012; `tool/check.ps1` green (1,285 tests on the 2026-11-23 re-run, 1,267 on 2026-11-21). TC-012-65 to -74 were Partial only because their tests lacked the ID; T-477 added them and T-495 re-marked them Pass.

**Known limitations and open items**
- **Still blocks Done:** T-501 (Project Manager: Gate 3 of the test-only changes, then Gate 5 and the Tester's final regression). No Tester emulator task is left for F-012. The Phase 3 commit also needs F-014's route, which is already wired (D-077).
- **TC-012-34 (TalkBack) is Blocked-needs-human**, open under D-097: the cover sheet with the keyboard at font size 2.0 (sheet title, live-region errors, an Undo snackbar that stays with TalkBack). The Owner should do it with TC-011-36 if only some can be done (`tests/PHASE-3-SUMMARY.md` 3.3).
- Nice to have, not blocking: T-466 (count-up of figures on day details and the Home hero). B-003 (F-016) touches the same refund rows in the editor but is a test-script fault.
- Depends on F-006 (`computeMonth`, `checkCover`, D-040 cuts), F-007 (savings repository), F-009 (spend editor, `SpendRow`), F-011 (`DayResultKind`, the cell tap). Used by F-010 (Today card), F-011 (cell tap), F-014 (shared change wording), F-016 (refund rows).

## 8. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-10 | First version of the spec (Phase 3 planned ahead, D-033). D-047 refunds applied for display. 19 ACs | Product Manager |
| 2026-11-11 | Owner/PM answers applied: D-048 (2) today's live day can be covered (Q-1 closed; §2.3, AC-4, new AC-20); D-048 (1) refusal order, so the overspend message wins when both limits are exceeded (AC-8 changed); D-048 (6) over-cover cuts are stored and never come back (§2.4, AC-20); D-048 (8) newest-added order (AC-3); D-056 (1) Undo and Remove cover (new §2.5, AC-21, AC-22); D-050/D-055 `under ₹1` wording (§4, §5); D-054 refunds entered via F-016. 22 ACs | Product Manager |
| 2026-11-11 | Small-amount wording switched from "under ₹1" to the Owner's literal "less than ₹1" (`overspent less than ₹1`, `saved less than ₹1`, `less than ₹1 left today`, `less than ₹1 short`, `less than ₹1 a day`), matching the Phase 2 change to D-050/D-055. Wording only, no AC added | Product Manager |
| 2026-11-11 | Status set to final Spec, ready for the plan (all Owner questions answered: D-053 to D-058). Remaining team questions go to the Project Manager at Phase 3 Gate 1 (phase overview, open items) | Product Manager |
| 2026-11-11 | §5 finalised by the Designer (`docs/design/screens/day-details.md`; full screen, not a sheet): `Day result` line + (i), `Spends` / `Spends and refunds` heading, Refunds written `−<amount>`, `Cover removed` and save-failure snackbars, `Nothing spent yet today`. AC-16 still says `Refunds ₹500`: flagged to the PM | Designer |
| 2026-11-16 | Gate 1 (Project Manager A): AC-16 aligned to the design (`Refunds −₹500`, D-077); §2.5 says the Undo snackbar stays while TalkBack is on. No other AC changed | Project Manager |
| 2026-11-23 | Step 9: section 7 (technical) filled in. Status stays Testing: Done waits for T-501 (Gate 5) | Developer |

## Impact on existing features
- **F-009:** the editor gets a "start date" input, so it opens on the chosen day. Its rules are unchanged. F-009 AC-19's note sheet is reused.
- **F-006:** covers use the engine's cover API, with the refusal reasons of AC-11 in the D-048 (1) order.
- **F-007:** the savings repository needs a **delete** of a day's savings moves (Undo / Remove, §2.5), in one transaction.

## Owner / team questions
- ~~Q-1~~ **Closed by D-048 (2):** today's live day can be covered (§2.3).

## Suggested additions *(for the CEO — not in scope until approved)*
- ~~Undo a cover~~: accepted by the Owner (D-056), now §2.5.
- **"Cover all overspent days"** in one tap, newest first. This is a new ordering rule, so it needs the Owner.
