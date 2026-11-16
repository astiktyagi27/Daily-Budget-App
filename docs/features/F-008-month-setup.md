# F-008: Month setup screen

| | |
|---|---|
| **Phase** | 2 |
| **Status** | Plan approved (Gate 1, 2026-11-10; OD-9 closed by D-057 on 2026-11-11). D-034 to D-038, D-042, D-043, D-046, D-048, D-050, D-057 are applied |
| **Plan** | [`plans/F-008-month-setup.md`](../../plans/F-008-month-setup.md) |
| **Test cases** | [`tests/F-008-month-setup.md`](../../tests/F-008-month-setup.md) |
| **Tasks** | T-212a/b/c, T-213, T-214a/b, T-215, T-216 |

## 1. What it is *(Product Manager)*
The screen where the user sets up a budget month (README §3.2):
- the salary day (first month only);
- the salary amount, entered by hand (SMS detection is Phase 4);
- an optional lower spending target;
- the fixed costs: Rent, EMIs, Subscriptions, plus **+ Add item**, each editable and deletable.

A **live preview** shows the budget month dates and the daily budget, worked out by the F-006 engine, before the user confirms. From the second month on, last month's values are pre-filled so the user only checks and confirms. After confirming, the user can come back and edit this month. Every field uses the F-004 label + description + (i) pattern, and the screen works in all four themes.

**User stories:**
- As a **user**, I want to enter my salary, an optional lower target and my fixed costs, and see my daily budget before confirming, so that I know the number is right.
- As a **user**, I want last month's fixed costs pre-filled so that a new month takes seconds.
- As a **user who saves**, I want to set a target lower than my salary so that the app budgets only what I want to spend.

## 2. How it behaves *(Product Manager)*
Layout and components are **per design system**. The Designer writes the screen spec (`docs/design/screens/…`) at Step 6.

1. **Getting there.**
   - With no confirmed month, the Home tab's empty state gets a **Set up your month** button. This replaces the F-003 Phase 1 placeholder copy for Home; see Impact.
   - When a new budget month has started (today is on or after the next start date, F-006 §2.1), Home shows **Your new month has started** with a **Set up this month** button.
   - After confirming, Home shows a plain **This month** card: dates, daily budget and an **Edit this month** button. The full Home summary is Phase 3.
2. **Fields, top to bottom:**
   1. **Salary day.** A picker for day 1–31, **first month only**. Later months show it read-only ("Salary day: 5th").
   2. **Monthly salary (₹).** Required. More than ₹0 and at most ₹10,00,00,000 (₹10 crore). Up to 2 decimal places can be typed, and they are stored exactly in paise. Numeric keyboard. Everywhere outside the input field, the amount is shown in whole rupees, rounded down, with Indian grouping (₹40,000; ₹1,00,00,000) (D-038).
   3. **"Spend less than my salary" switch.** Off by default. When on, a **Spending target (₹)** field appears. It is required, more than ₹0, and no more than the salary. Turning the switch off removes the target.
   4. **Fixed costs.**
      - On the first month the list starts with three suggested items, **Rent, EMI, Subscriptions**, with empty amounts. An empty amount counts as ₹0.
      - Each item has a name (1–40 characters, required) and an amount (₹0 to ₹10 crore, 2 decimals).
      - Tap an item to edit its name or amount. A delete control on each item removes it, with **Undo** for a few seconds.
      - **+ Add item** adds a new empty item and focuses its name.
      - At most 30 items.
      - A running **Total fixed costs** line is shown.
3. **Live preview** (always visible near the Confirm button). It updates on every change:
   - **Budget month:** e.g. `5 Nov – 4 Dec · 30 days`.
   - **Spendable:** `₹40,000 − ₹15,100 fixed = ₹24,900`. When a target is set, the target replaces the salary in this line.
   - **Daily budget:** `₹830 a day`, in whole rupees rounded down (D-038). The exact paise are used in every calculation. Only the display drops them.

   While the salary is empty or invalid, the preview shows `Enter your salary to see your daily budget`.
4. **Worked examples** (salary day 5, set up on 5 Nov 2026, 30-day month 5 Nov – 4 Dec):

   | Salary | Target | Fixed costs | Preview |
   |---|---|---|---|
   | ₹40,000 | – | none | Spendable ₹40,000 · **₹1,333 a day** (exact: 5–14 Nov ₹1,333.34, the rest ₹1,333.33, D-035) |
   | ₹40,000 | – | Rent ₹10,000, EMI ₹5,000, Subscriptions ₹100 | ₹40,000 − ₹15,100 = ₹24,900 · ₹830 a day |
   | ₹40,000 | ₹20,000 | none | Spendable ₹20,000 · **₹666 a day** (exact: ₹666.67 / ₹666.66) |
   | ₹40,000 | ₹20,000 | Rent ₹10,000, EMI ₹5,000, Subscriptions ₹100 | ₹20,000 − ₹15,100 = ₹4,900 · **₹163 a day** (exact: 4,90,000 ÷ 30 = 16,333 remainder 10, so the first 10 days are ₹163.34 and the rest ₹163.33) |

5. **Shortfall: fixed costs bigger than the money (D-036).**
   - When fixed costs are more than the target (or salary), the preview shows a warning card instead of a daily budget. The same applies to fixed costs still to pay being more than the money left (mid-month), or to an edit that leaves less than ₹0 for the remaining days (F-006 §2.7 C4). Example card: `₹0 a day · ₹1,000 short`, with `Your fixed costs are ₹1,000 more than your salary.`
   - Tapping **Start my month** / **Save changes** while there is a shortfall opens a dialog with the shortfall and two buttons:
     1. **Fix my numbers** (recommended, shown first and styled as the primary button). It closes the dialog, saves nothing and moves focus to the fixed-costs list.
     2. **Continue anyway** (secondary). It saves the month or change with a **₹0 daily budget** for its days, and records the shortfall.
   - After **Continue anyway**, Home's This month card shows the shortfall **all month**, e.g. `−₹1,000 this month` and `Every spend this month counts as overspent.` Every spend is then Overspent (F-006 §2.8).
   - **Worked example (S1):** salary ₹20,000, rent ₹15,000, EMI ₹6,000, giving fixed ₹21,000 and a shortfall of ₹1,000. The dialog says `Your fixed costs are ₹1,000 more than your salary.` With a ₹19,000 target the dialog would name the target instead.
   - Fixed costs **exactly equal** to the money (₹0 a day, no shortfall) show the same warning card with `₹0 left for daily spending` and the same two choices. This follows D-043.
6. **Mid-month first setup (D-034).**
   - If the first-ever setup happens on a day that is not the budget month's start day, the screen asks for **Money left now** instead of the salary and target. That money is spread over **today to the day before the next salary date**.
   - The fields are:
     - **Salary day**;
     - **Money left now (₹):** required, more than ₹0, at most ₹10 crore;
     - **Fixed costs still to pay this month:** the list starts empty, with + Add item. It is optional and is subtracted from the money left (D-042).
   - A line explains it: `You're starting partway through the month, so we'll spread the money you have left over the <n> days until your next salary.`
   - **Worked example:** salary day 5, today 10 Nov 2026, money left ₹24,900, nothing still to pay. The preview shows `10 Nov – 4 Dec · 25 days left` and `₹996 a day` (24,90,000 ÷ 25 = 99,600 paise).
   - On 11 Nov with ₹20,000 left, it shows `11 Nov – 4 Dec · 24 days left` and `₹833 a day` (D-038). Exact: 20,00,000 ÷ 24 = 83,333 remainder 8, so 11–18 Nov are ₹833.34 and the rest ₹833.33 (D-035).
   - The next month is a normal full setup. Salary is empty and required; fixed costs are pre-filled from this month's list.
7. **Confirm.**
   - **Start my month** (first setup or a new month) or **Save changes** (when editing) validates every field. The first invalid field gets focus with its error message under it.
   - It saves everything in one unit (F-007 AC-4), then returns to Home, which shows the This month card.
   - A double tap saves once.
8. **Pre-fill (second month onwards).** The new month's setup opens with last month's salary, target (and switch state) and all fixed-cost items with their names and amounts, in the same order. A line at the top says `We've filled in last month's numbers. Check them and confirm.` Nothing is saved until Confirm.
9. **Editing the current month** (Edit this month).
   - It opens the same screen with the saved values.
   - The salary day is read-only.
   - **Save changes** is disabled until something has changed.
   - **Recalculate the remaining days (D-037):** past days keep their budgets and results, and the new money left is spread over **today and the remaining days**.
   - The preview states the effect before saving: `From today (20 Nov): ₹630 a day for the 15 days left. Days before today keep their budget.`
   - Saving adds a new dated **period** to the month's history and never overwrites the old one (F-007 AC-16).
   - **Worked examples** (E2 month 5 Nov – 4 Dec, ₹830 a day, edit on 20 Nov; 5–19 Nov already budgeted 15 × ₹830 = ₹12,450; 15 days left):
     - Rent ₹10,000 → ₹13,000: ₹21,900 − ₹12,450 = ₹9,450 ÷ 15 = **₹630 a day**.
     - Salary ₹40,000 → ₹35,000: ₹19,900 − ₹12,450 = ₹7,450 ÷ 15 gives `From today (20 Nov): ₹496 a day for the 15 days left` (D-038). Exact: 7,45,000 ÷ 15 = 49,666 remainder 10, so 20–29 Nov are ₹496.67 and 30 Nov – 4 Dec ₹496.66.
     - Target set to ₹25,000: ₹9,900 − ₹12,450 = −₹2,550, so the shortfall dialog shows `This change leaves you ₹2,550 short for the rest of the month.` (step 5).
10. **Leaving without saving.**
    - Back, or the close button, with unsaved changes asks `Discard changes?` with the buttons **Discard** and **Keep editing**.
    - With no changes, it simply leaves.
    - An unsaved first setup leaves Home in the "Set up your month" state.
11. **Missed months.** If the app wasn't opened for one or more whole budget months, setup is for the month that contains today. Skipped months are not created.
12. **A new month set up after its start day (D-057).** This covers missed months and any late "Set up this month" (e.g. the month started 5 Dec and the user confirms on 12 Dec). It is treated like a fresh start (D-034): the screen (title `Set up this month`, salary day read-only) asks **Money left now** and spreads it over **today to the day before the next salary date**; "Fixed costs still to pay this month" starts **empty** (D-042); the mid-month line explains it; there is no pre-fill line. Days of the month before today are **not budgeted** and never count as saved. If today is exactly the month's start day, it is the normal pre-filled setup (step 8). The month after a late start is a normal full setup; its salary, target and items are pre-filled from the last period that had them, otherwise salary is empty (as step 6).

## 3. Acceptance criteria *(Product Manager)*
"Small phone", "all four themes" and accessibility checks are as defined in F-002 section 3. Dates in tests are set by a fixed "today", not the real clock.

| ID | Given / When / Then |
|---|---|
| AC-1 | **Entry points.** Given no confirmed month, when Home is shown, then it shows the empty state with **Set up your month**, which opens the setup screen. Given a confirmed month, then Home shows the This month card (dates, daily budget, **Edit this month**). Given today is on/after the next month's start, then Home shows **Your new month has started** with **Set up this month**. |
| AC-2 | **First-month fields.** Given the first setup, when the screen opens, then it shows Salary day, Monthly salary, the "Spend less than my salary" switch (off, no target field), and fixed costs Rent, EMI, Subscriptions with empty amounts, **+ Add item**, and Total fixed costs ₹0 — each labelled with the section 5 label and description/(i). |
| AC-3 | **Salary validation.** Given the salary field, when the user enters (a) nothing, (b) 0, (c) 10,00,00,001, (d) 12.345, (e) letters, then Confirm shows the section 5 error for each and nothing is saved; when the user enters 40000, 10,00,00,000 or 99.50, then it is accepted and stored exactly (40,00,000 / 10,00,00,00,000 / 9,950 paise) and shown outside the field as ₹40,000, ₹10,00,00,000 and ₹99 (D-038). |
| AC-4 | **Target.** Given salary ₹40,000, when the switch is turned on, then the target field appears and is required; ₹20,000 is accepted; ₹40,000.01 and ₹0 are rejected with the section 5 error; when the switch is turned off, then the target is removed and the preview uses the salary again. |
| AC-5 | **Fixed costs add, edit, delete.** Given the fixed-costs list, when the user taps **+ Add item**, then a new item appears with its name focused; when an item's name or amount is changed, then Total fixed costs updates; when an item is deleted, then it disappears with **Undo**, and Undo restores it in the same position; an item with an empty name is rejected on Confirm; the 31st item cannot be added (button disabled with the section 5 hint). |
| AC-6 | **Live preview — README examples.** Given salary day 5 and today 5 Nov 2026, when the four rows of the §2.4 table are entered, then the preview shows the month `5 Nov – 4 Dec · 30 days`, the spendable line, and exactly `₹1,333 a day`, `₹830 a day`, `₹666 a day` and `₹163 a day` (D-038), while the saved day budgets match the engine's exact paise (F-006 AC-4). |
| AC-7 | **Preview updates instantly.** Given a valid setup, when any amount, the target switch or an item is changed, deleted or undone, then the preview and Total fixed costs update before the next frame settles (in the same widget-test pump), without tapping anything else. |
| AC-8 | **Shortfall warning and choices (D-036).** Given salary ₹20,000 and fixed costs ₹21,000 (S1), when the preview updates, then it shows `₹0 a day · ₹1,000 short` and the shortfall text; when the user taps **Start my month**, then a dialog shows the ₹1,000 shortfall with **Fix my numbers** first (primary) and **Continue anyway** second; **Fix my numbers** saves nothing and focuses the fixed costs; **Continue anyway** saves the month with 0-paise day budgets and the shortfall, and Home shows `−₹1,000 this month` on every day of the month (checked on 5 Nov, 20 Nov and 4 Dec). With a target set, the text names the target. The equal case (fixed ₹20,000) shows `₹0 left for daily spending` with the same two choices (D-043). |
| AC-9 | **Mid-month first setup (D-034).** Given no month yet, salary day 5 and today 10 Nov 2026, when the setup screen opens, then it shows Salary day, **Money left now** and **Fixed costs still to pay this month** (empty) instead of salary and target, plus the explanation line; when ₹24,900 is entered, then the preview shows `10 Nov – 4 Dec · 25 days left` and `₹996 a day`; when confirmed, then the saved month's first budgeted day is 10 Nov. Given today 11 Nov and ₹20,000, then the preview shows 24 days and the D-035 split (shown `₹833 a day`; stored 8 days at 83,334 and 16 days at 83,333 paise). Given today 5 Nov (the start day), then the normal salary/target screen is shown. |
| AC-10 | **Confirm saves atomically, once.** Given a valid setup, when the user double-taps **Start my month**, then exactly one month with its fixed costs is stored (F-007), Home shows the This month card with the same daily budget as the preview, and after force-stop and reopen the same values are shown. |
| AC-11 | **Save failure.** Given a database write failure is forced, when the user confirms, then the F-007 save-error message appears, every entered value stays on screen, and Home still shows "Set up your month". |
| AC-12 | **Pre-fill next month.** Given a confirmed month 5 Nov – 4 Dec with salary ₹40,000, target ₹20,000 and fixed costs Rent ₹10,000, EMI ₹5,000, Subscriptions ₹100, when today becomes 5 Dec and the user opens **Set up this month**, then the screen shows month `5 Dec – 4 Jan · 31 days`, salary day read-only "5th", and all those values pre-filled in the same order with the pre-fill line; nothing is saved until Confirm. |
| AC-13 | **Edit this month: remaining days recalculated (D-037).** Given the E2 month and today 20 Nov, when the user opens **Edit this month**, then Save changes is disabled until a value changes and the salary day cannot be changed; when Rent is raised to ₹13,000, then the preview shows `From today (20 Nov): ₹630 a day for the 15 days left`; when saved, then 20 Nov – 4 Dec are ₹630, 5–19 Nov keep ₹830 and their results, recorded spends are untouched, and a new period dated 20 Nov is stored with the old one intact (F-007 AC-16). The salary ₹35,000 example shows `₹496 a day` and stores 49,667 / 49,666 paise as in §2 step 9. |
| AC-14 | **Discard changes.** Given unsaved changes, when the user presses back, then the `Discard changes?` dialog appears; **Keep editing** stays on the screen with all input; **Discard** leaves without saving. Given no changes, then back leaves immediately with no dialog. |
| AC-15 | **Month-length cases on screen.** Given salary day 31 and today 31 Jan 2027, when the first setup is previewed, then it shows `31 Jan – 27 Feb · 28 days`; given salary day 30 and today 30 Jan 2028, then `30 Jan – 28 Feb · 30 days`. |
| AC-16 | **Help on every field.** Given the setup screen, when the Tester checks every control against section 5, then each has its label and description or (i) using the F-004 component (F-004 AC-5, AC-6), and each (i) opens its explanation. |
| AC-17 | **Themes, large text, accessibility.** Given the setup screen with 10 fixed costs, an error showing and the preview visible, when shown in all four themes at text scale 1.0 and 2.0 on a small phone (and landscape 640×360, D-030), then F-002 AC-12–AC-14 pass, all fields and Confirm can be scrolled to, the keyboard never hides the focused field, and TalkBack reads each field's label, value and error. |
| AC-18 | **Edit causing a shortfall.** Given the E2 month and today 20 Nov, when the user sets a target of ₹25,000 and taps Save changes, then the dialog says `This change leaves you ₹2,550 short for the rest of the month.` with **Fix my numbers** first and **Continue anyway**; Fix my numbers saves nothing; Continue anyway stores the new period with 20 Nov – 4 Dec at ₹0, keeps 5–19 Nov at ₹830, and Home shows `−₹2,550 this month`. |
| AC-19 | **Shared money formatter rounds down (D-038).** Given the one money formatter in `app/lib/core/` (used by F-008, F-009 and every later screen), when it formats these paise values, then the output is exactly: 66,667 → `₹666`; 1,33,334 → `₹1,333`; 83,000 → `₹830`; 99 → `₹0`; 0 → `₹0`; 10,00,00,00,000 → `₹10,00,00,000`; 1,23,45,67,899 → `₹1,23,45,678`; −1,00,000 → `−₹1,000`; −12,050 → `−₹120` (the size is rounded down, toward ₹0; the minus sign is per design system); it uses integer arithmetic only (no `double` or `num` division, look-ahead #12); and no screen in F-008/F-009 formats money any other way (code check agreed in the plan). |
| AC-20 | **Late or missed-month setup is a fresh start (D-057).** Given a confirmed month 5 Nov – 4 Dec (salary ₹40,000, E2 costs) and today 12 Dec 2026, when the user opens **Set up this month**, then the screen shows `Salary day: 5th` (read-only), **Money left now** (empty) and **Fixed costs still to pay this month** (empty), the mid-month line with `24 days`, no salary/target fields and no pre-fill line; when ₹24,000 is entered, then the preview shows `12 Dec – 4 Jan · 24 days left` and `₹1,000 a day`; when confirmed, then the month 5 Dec – 4 Jan is stored with first budgeted day 12 Dec and 5–11 Dec are not budgeted (never Saved). Given the last confirmed month was 5 Oct – 4 Nov and today 20 Dec (missed months), then the same applies to 5 Dec – 4 Jan with 16 days left and no Nov month is created. Given today 5 Dec (the start day), then the normal pre-filled setup is shown (AC-12). |

## 4. Edge cases *(Product Manager)*
- **Salary day 29–31** in a short month: the preview shows the clamped dates (AC-15, F-006 §2.1).
- **Leap year:** the Feb 2028 months (AC-15).
- **Missed months / late setup:** setup is for the month containing today (§2.11) and is a fresh start from today (§2.12, D-057).
- **Pasting** "₹40,000" or "40,000.00" into an amount field: accepted and normalised. Pasting text with letters is rejected.
- **Leading zeros** ("040000"): accepted as ₹40,000.
- **Decimal comma** ("99,50"): not accepted as a decimal. It shows the format error, because Indian grouping uses commas for thousands.
- **Total fixed costs above ₹10 crore** (30 items × ₹10 crore): no overflow (F-006 AC-17). This is a shortfall case (D-036).
- **Two items with the same name** (two EMIs): allowed.
- **Deleting all fixed-cost items:** allowed. Fixed costs are ₹0.
- **Target equal to salary:** allowed, the same as no target.
- **Rotation / app backgrounded mid-entry:** typed values are kept while the app is alive. If the system kills the app, unsaved input may be lost, which is acceptable for a first version.
- **Date changes while the screen is open** (midnight passes): the preview follows the new date at once (the app's "today" updates at midnight and on resume), so the numbers shown are always the ones Confirm saves. Confirming saves the month that contains "today" at the moment of Confirm (D-048).
- **Editing a month whose spends already exceed the new spendable:** allowed. Left goes negative (F-006 AC-14).
- **Keyboard covering the preview:** the preview may scroll out of view while typing, but Confirm stays reachable by scrolling.

## 5. Help text & copy *(Product Manager, finalised by Designer)*
| Control | Label | Description / tooltip |
|---|---|---|
| Screen title (first / new / edit) | `Set up your month` / `Set up this month` / `Edit this month` | — |
| Home empty-state button | `Set up your month` | Home empty-state description: `Tell us your salary and fixed costs, and we'll work out what you can spend each day.` |
| Home new-month notice | `Your new month has started` | Button `Set up this month`. Description: `Check last month's numbers and confirm.` |
| Home This month card | `This month` | `<dates> · <daily budget> a day`. Button `Edit this month` |
| Salary day | `Salary day` | `The day your salary usually arrives. Your budget month runs from this day to the day before the next one.` (i): `If your salary day is the 29th, 30th or 31st, short months start on their last day instead.` |
| Salary day (later months) | `Salary day: <ordinal>` (`1st`, `2nd`, `3rd`, `5th`, `22nd`, `31st`) | `Set in your first month.` |
| Salary day (first month, nothing chosen) | Placeholder `Choose a day` | Error: `Choose your salary day`. Preview month line: `Choose your salary day to see your budget month` |
| Salary day sheet | `Salary day` | Description `The day your salary usually arrives.` Footnote under the grid: `* In shorter months, the month starts on its last day.` Day chip screen reader: `<ordinal>, salary day[, selected]`. Button `Done`, hint `Close salary day options` |
| Monthly salary | `Monthly salary` | `What you receive in your bank account each month, after tax.` Errors: `Enter your salary` · `Salary must be more than ₹0` · `That's more than ₹10 crore. Please check the amount.` · `Use numbers only, with up to 2 decimals` |
| Target switch | `Spend less than my salary` | `Set a smaller amount to budget and keep the rest aside.` |
| Spending target | `Spending target` | `The amount you want to spend this month, including fixed costs.` Errors: `Enter a target` · `Target can't be more than your salary` · `Target must be more than ₹0` |
| Fixed costs header | `Fixed costs` | `Bills you pay every month, like rent or EMIs. They're taken out before your daily budget is worked out.` |
| Fixed cost item name | `Name` | Error: `Give this cost a name` |
| Fixed cost item amount | `Amount` | `Leave empty or 0 if there's nothing to pay this month.` |
| Delete item | (icon) | Tooltip: `Remove <name>` (`Remove item` when the name is empty). Snackbar `<name> removed` with `Undo` |
| + Add item | `+ Add item` | `Add another monthly cost.` At limit: `You can add up to 30 costs.` |
| Total fixed costs | `Total fixed costs` | — |
| Preview card title | `Your daily budget` | — |
| Preview — month | `Budget month` | `<start> – <end> · <n> days`. Mid-month: `<start> – <end> · <n> days left`; one day: `<date> · 1 day left` (no range) |
| Preview — spendable | `Spendable this month` | `<target or salary> − <fixed> fixed = <spendable>`. (i): F-006 "Spendable" |
| Preview — daily | `Daily budget` | `<amount> a day`. (i): F-006 "Daily budget". Empty: `Enter your salary to see your daily budget` |
| Shortfall card (preview) | — | `₹0 a day · <amount> short`. Text: `Your fixed costs are <amount> more than your salary.` (or `your spending target` / `the money you have left`). Equal case: `₹0 left for daily spending` with `Your fixed costs take up all of your salary.` (or `spending target` / `money left`). The spendable line shows the negative: `₹20,000 − ₹21,000 fixed = −₹1,000` |
| Equal-case sheet (D-043) | `Nothing left for daily spending` | `Your fixed costs take up all of your <salary / spending target / money left>, so there's ₹0 a day to spend.` Same two buttons as the shortfall |
| Shortfall dialog (a decision sheet, design system §7.8) | `Your numbers don't add up` | `Your fixed costs are <amount> more than your <salary / spending target / money left>.` For an edit: `This change leaves you <amount> short for the rest of the month.` |
| Fix my numbers | `Fix my numbers` | `Recommended. Change your costs or target so the month adds up.` |
| Continue anyway | `Continue anyway` | `Start with ₹0 a day. Every spend this month will count as overspent.` |
| Home shortfall line | — | `−<amount> this month` · `Every spend this month counts as overspent.` |
| Mid-month line (D-034) | — | `You're starting partway through the month, so we'll spread the money you have left over the <n> days until your next salary.` One day: `You're starting on the last day of this budget month, so all the money you have left is for today.` |
| Money left (edit mode, D-048) | `Money left on <first day>` (e.g. `Money left on 10 Nov`) | `What you had to spend when you started on <first day>. Change it if it was wrong. Days before today keep their budget.` |
| Money left now | `Money left now` | `How much you have to spend until your next salary.` Errors: `Enter how much you have left` · `Amount must be more than ₹0` · `That's more than ₹10 crore. Please check the amount.` |
| Fixed costs still to pay | `Fixed costs still to pay this month` | `Bills you haven't paid yet before your next salary, like rent due next week.` |
| Edit preview line | — | `From today (<date>): <amount> a day for the <n> days left. Days before today keep their budget.` One day left: `From today (<date>): <amount> for today, the last day of this budget month. Days before today keep their budget.` |
| Pre-fill line | — | `We've filled in last month's numbers. Check them and confirm.` |
| Confirm (new) | `Start my month` | Hint: `Save and start this budget month` |
| Confirm (edit) | `Save changes` | Hint: `Save the changes to this month` |
| Discard dialog | `Discard changes?` | `Your changes to this month won't be saved.` Buttons `Keep editing` (first; hint `Go back to your changes`) · `Discard` (hint `Leave without saving`) |
| Back button (setup screen) | (icon) | Tooltip `Back`. Hint `Leave this screen` |
| Bottom action dock line | `Daily budget` | `<amount> a day`; edit mode `From today` · `<amount> a day`; no salary yet `Enter your salary` · `—`; shortfall `◆ <amount> short`; equal `○ ₹0 a day` |
| Home empty state title | `Your daily budget lives here` | Kept from F-003. Button `Set up your month` hint: `Open month setup` |
| Home This month card, screen reader | — | `This month, <start> to <end>, <amount> a day.` Shortfall adds `Minus <amount> this month. Every spend this month counts as overspent.` Button `Edit this month` hint: `Change this month's salary, target or fixed costs` |
| Home new-month button hint | — | `Set up this month` hint: `Set up your new budget month` |

## 6. Out of scope
- Salary detected from SMS (Phase 4).
- Changing the salary **day** after the first month (Settings → Salary date stays a placeholder; see Suggested additions).
- Fixed-cost categories, due dates and reminders.
- The full Home summary and calendar (Phase 3).
- Income other than the salary, and multiple salaries.

## 7. How it works — technical *(Developer, filled in when the feature is Done)*
**What was built.** The month setup screen and the Home states around it. Tasks T-212a/b/c, T-213, T-214a/b, T-215, T-216, T-240, then T-243 and T-250 (a). Gate 3 approved 2026-11-13, Gate 4 conditional pass (D-071).

**Main files** (`app/lib/`)
- Pure Dart in `domain/budget/`: `amount_input.dart` (`parseAmount`, shared with F-009), `setup_draft.dart` (`SetupDraft`, validation in screen order, `preview`, `isChangedFrom`, `toPeriodValues`).
- Shared: `core/format/money_format.dart` (`formatRupees`, whole rupees rounded down, D-038, D-070) and `date_format.dart`; `core/providers/today_provider.dart` (`todayProvider`, midnight and resume), `core/providers/month_state_provider.dart` (`AppMonthState`: `NoMonthSetUp`, `NewMonthDue`, `ActiveMonth`); `core/widgets/` `amount_field.dart`, `decision_sheet.dart`, `action_dock.dart`, `budget_icon_button.dart`, `empty_state.dart` (optional action); `core/copy/month_setup_copy.dart`.
- Screen: `features/month_setup/month_setup_controller.dart` (modes `FirstSetupMode`, `NewMonthMode`, `EditMonthMode`; draft edits, Undo, `submit({continueAnyway})`), `month_setup_screen.dart`, `widgets/` (`salary_day_field`, `fixed_costs_section`, `setup_preview_card`, `setup_action_dock`, `shortfall_sheet`, `discard_sheet`).
- Home: `features/home/home_tab.dart` and `this_month_card.dart` (empty state, new-month card, This month card with Edit this month); `features/transactions/month_setup_launcher.dart` opens the screen from Home and Transactions with one screen per double tap (T-240).

**Data stored.** Nothing of its own; it writes through F-007. Confirm adds one `budget_months` row, its first `budget_periods` row and that period's `period_fixed_costs`, in one transaction. Save changes on an existing month adds a **new period** starting today with a full copy of the items; nothing is updated (D-037). An empty item amount is stored as 0; a shortfall continued with "Continue anyway" is stored with the period (D-036).

**Decisions:** D-034 (mid-month first setup), D-036 (shortfall choice), D-037 (edit adds a dated period), D-038 (whole rupees), D-040, D-042 (still-to-pay list), D-048, D-057 (late month is a fresh start), D-059 (engine code structure), D-069 (field shows digits as typed; grouped amount in the preview), D-070 (no `intl`), D-071.

**Deviations** (plan section 11, all approved at Gate 3 unless noted)
- T1 no `intl` (D-070). T2 no digit grouping while typing (D-069; Designer T-238). T3 to T7 shared widget and test-helper details.
- U1 state type named `AppMonthState`. U2 three modes instead of five (full or mid-month is the draft's kind). **U3 the daily amount does not count up** and **U5 two new copy lines for the mid-month form** (design changes; Designer records them in T-241, still To do). U4 no row collapse animation. U6 new `BudgetIconButton`. U7 edge cases not in the plan (Edit this month hidden when today is outside the month; an edit left open past its month ends; a pre-filled new month left open past its start day becomes a fresh start). U8 edit-mode card without the month line. U9 sweep lives in `month_setup_sweep_test.dart`. U10 launcher wiring (resolved by T-240).
- S1 to S9 (pure layer): `AmountParse` variant names, a fifth variant `AmountTooLarge`, `.5` and `40000.` accepted, `preview` without a month parameter, item-name length counted by the text field (graphemes) not the draft, errors as `FieldId` + `FieldProblem`, `toPeriodValues()` throws on an invalid draft.
- T-250 (a), design decision from T-248: the dock stays the Scaffold's bottom bar (so snackbars stay above it) and is lifted by the keyboard inset; Next on every field, Done on the last; Back with the keyboard open only closes it. First built inside the body column, which let the `Removed X` snackbar cover Start my month (TC-008-35 failed), so it was reverted.

**How it is tested** (`tests/F-008-month-setup.md`, 56 cases, 20 / 20 ACs)
- Unit: `test/domain/budget/amount_input_test.dart`, `setup_draft_test.dart`; `test/core/format/` and `test/architecture/money_format_only_test.dart` (TC-008-29, -30, -42); `test/core/providers/today_provider_test.dart`, `month_state_provider_test.dart`.
- Widget (on fake repositories, five theme cases, text scale 2.0, 360 x 640 and landscape): `test/features/month_setup/` (`month_setup_controller_test`, `month_setup_screen_test`, `month_setup_preview_test`, `month_setup_shortfall_test`, `month_setup_edit_test`, `month_setup_sweep_test` = TC-008-24, `month_setup_keyboard_test` = TC-008-27 keyboard rule), `test/features/home/home_month_states_test.dart`, `test/copy/month_setup_copy_test.dart`. TC-008-34's 41st-character case uses Latin, Devanagari and emoji names (PM condition S5).
- Integration on the emulator (T-243): `integration_test/month_setup_flow_test.dart` (TC-008-18 restart on the same database, TC-008-54 fresh install); 2 / 2 passed on emulator-5554, log `docs/reviews/emulator-phase-2/integration-month-setup-flow.log`. A probe with a wrong expected value failed both tests.
- Manual and device: TC-008-18, -38, -50 (R1 screens). T-250 tests were proved able to fail by probes (Back check removed, default Next order, dock not lifted).
- Result at Gate 4 (R1): 53 Pass of 56, 2 Partial (TC-008-27, -50), 1 Blocked-needs-human (TC-008-26), no bug; `check.ps1` 591 tests green.
- Result at the Gate 4 re-check (R5, 2026-11-16): 55 Pass of 56, 1 Blocked-needs-human (TC-008-26), no bug; `check.ps1` 606 tests green; integration 8 of 8. TC-008-27 and -50 now Pass (10-item first setup at 2.0x, keyboard rule, Dim theme walked, T-244).

**Known limitations and open items**
- **Gate 4 passed (D-071, re-check D-072).** T-243 (integration tests) and T-244 (device walks: 10-item first setup at 2.0x, Dim theme) are done and green in run R5, so the feature is Done.
- **TC-008-26 (TalkBack) is Blocked-needs-human**, accepted as open (D-071, same terms as D-066). Proofs in place: the accessibility tree dump carries the labels, and `decision_sheet_test.dart` and `amount_field_test.dart` pass. The walk must include the back arrow and an item remove x.
- TC-008-27 and -50 were Partial in R1 and are Pass in R5; the other P2 setup states are covered by the TC-008-24 widget sweep, not walked on the device.
- Low observation (Tester, R5): on the first-setup form the Next key after the salary field skips the `Spend less than my salary` switch and goes to the first item name. Accepted as built (D-072); not a bug.
- Nice to have, not blocking: T-242 (N1 dock copy constant, N2 `BudgetIconButton` over `NavTooltip`, N4 move the launcher to `features/month_setup/`, others). T-241 (U3 and U5 in the spec) and T-251 (spec numbers, snackbar line) are done.
- Amount fields do not group digits while typing (D-069); the grouped amount shows in the preview line.
- Depends on F-006, F-007. Used by F-010 (Home), F-009 (launcher), F-014 (month statement reads the periods).

## 8. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-10 | First version of the spec; OD-2, OD-4, OD-5, OD-6 pending | Product Manager |
| 2026-11-10 | Owner decisions applied: D-034 (mid-month first setup asks money left now, §2.6, AC-9), D-036 refined (shortfall card + dialog with Fix my numbers / Continue anyway, shortfall shown all month, §2.5, AC-8, new AC-18), D-037 refined (edit recalculates remaining days and adds a dated period, §2.9, AC-13). ACs 17 → 18. OD-6 still pending; Q-A/Q-B PM readings to confirm | Product Manager |
| 2026-11-10 | Final: D-038 (whole rupees rounded down on screen; examples now ₹1,333 / ₹830 / ₹666 / ₹163; AC-3, AC-6, new AC-19 for the shared integer-only formatter, look-ahead #12), D-042 (§2.6), D-043 (§2.5, AC-8). No PENDING items left. Status: final Spec, ready for the plan. 19 ACs | Product Manager |
| 2026-11-11 | OD-9 answered by the Owner (D-057): step 12 rewritten as a fresh start from today; new AC-20; §4 missed months. Status → Plan approved | Project Manager |
| 2026-11-10 | Gate 1 (PM): new step 12 = Owner decision OD-9 (late new-month setup), with the PM recommendation; §4 midnight rule (preview follows today live, D-048); §5 singular "1 day" copy, edit-mode money-left label (D-048). Status: approved except OD-9 | Project Manager |
| 2026-11-10 | §5 finalised by Designer (`docs/design/screens/month-setup.md`): salary day ordinal, placeholder, error and sheet copy; preview card title; equal-case text and sheet; negative spendable line; dock line; back, Home and discard hints (Keep editing first). "Dialog" means the design system decision sheet. No existing string reworded except `Salary day: <n>th` → `<ordinal>` | Designer |
| 2026-11-16 | Section 7 filled in (Step 9, T-246): built files, stored data, decisions, deviations (T1 to T7, U1 to U10, S1 to S9, T-250 dock), tests, open items (T-244, TC-008-26 TalkBack, Nice to haves). Status stays Testing until T-244 is green (D-071) | Developer |
| 2026-11-16 | Section 7 updated to the R5 results (606 tests, 8 integration tests, T-244 done, TC-008-27 and -50 Pass). Gate 4 re-check passed (D-072); status Done | Project Manager |

## Impact on existing features
- **F-003 AC-4 / §5 (Phase 1):** Home's placeholder empty state ("no buttons") is replaced by the Set up your month state and the This month card. The F-003 Home test cases must be updated when this is wired in, after Phase 1 is Owner-approved (phase overview scheduling, D-033). Dashboard and Transactions keep their F-003 behaviour except as F-009 changes Transactions.
- **F-004:** the Home first-time hint text may need a new hint ID if its wording changes (F-004 §4).

## Suggested additions *(for the CEO — not in scope until approved)*
- **Change salary day** from Settings, taking effect from the next month, with a preview of the next month's dates.
- **Quick-pick fixed-cost names** (Rent, EMI, SIP, Insurance, Maid, Gym, OTT) as chips under "+ Add item". Money Manager and Walnut-style apps do this to cut typing.
- **"Paid on" day per fixed cost** for reminders later (Phase 5).
