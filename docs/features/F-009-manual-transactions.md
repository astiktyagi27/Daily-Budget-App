# F-009: Manual transactions

| | |
|---|---|
| **Phase** | 2 |
| **Status** | Plan approved (Gate 1, 2026-11-10). D-034, D-036 to D-040, D-046, D-047 (engine only, D-051), D-048, D-050 are applied; AC-14 (category) is N/A in Phase 2 |
| **Plan** | [`plans/F-009-manual-transactions.md`](../../plans/F-009-manual-transactions.md) |
| **Test cases** | [`tests/F-009-manual-transactions.md`](../../tests/F-009-manual-transactions.md) |
| **Tasks** | T-217 … T-220 (shared widgets in T-212c) |

## 1. What it is *(Product Manager)*
Lets the user **add, edit and delete a spend by hand**: amount, date and an optional note (README §3.3 "Manual add / edit / delete for anything missed"). The Transactions tab shows a simple list of this budget month's spends and a plain **Today** line, "budget · spent · result", worked out by the F-006 engine. The Owner can then check the Phase 2 numbers with manual entries. It is the only way to record spends until SMS reading arrives in Phase 4, and it stays as the backup afterwards (D-002). Search, filters, the full Home summary and the calendar are Phase 3.

**User stories:**
- As a **user**, I want to add a spend in a few taps so that my daily budget stays accurate.
- As a **user**, I want to fix or remove a wrong entry so that my numbers are right.
- As the **Owner**, I want to see today's budget, spend and result change as I add spends so that I can check the calculations.

## 2. How it behaves *(Product Manager)*
Layout per design system. The Designer writes the screen spec at Step 6.

1. **Transactions tab** (replaces the F-003 placeholder once a month is confirmed):
   - **No confirmed month:** the empty state `Set up your month first` with a **Set up your month** button (opens F-008). Adding a spend is not possible.
   - **Month confirmed, no spends:** the Today line, then the empty state `No spends yet this month` with an **Add spend** button.
   - **With spends:** the **Today line** at the top, then the list.
     - The list covers this budget month, grouped by day with the newest day first.
     - Day headings read `Today`, `Yesterday`, or e.g. `Mon, 9 Nov`, each with that day's total.
     - Within a day, the newest **added** entry comes first; editing an entry does not move it (D-048).
     - Each row shows the amount (Indian grouping) and the note, or `No note` in secondary text.
   - A floating **Add spend** button is always visible when a month is confirmed.
2. **Today line.**
   - Format: `Today: budget ₹830 · spent ₹250 · ₹580 left today`.
   - The result reads `₹x left today` while today's spend is under budget, `on budget` at exactly ₹0, or `overspent ₹x`. It uses the saved/overspent colours **plus** the words, not colour alone.
   - Today's leftover is **not** in the savings pot until the day ends at midnight (D-039). It then shows as "Saved" for that day.
   - It updates immediately after any add, edit or delete.
   - **Less than ₹1 (D-050):** when the result is not exactly ₹0 but less than ₹1 either way, the word follows the exact paise and the amount reads `less than ₹1`: `less than ₹1 left today` or `overspent less than ₹1` (never `₹0 left today` or `overspent ₹0`).
   - Every amount is shown in **whole rupees, rounded down**, using the shared money formatter (F-008 AC-19, D-038). The calculations use exact paise. So the shown parts can differ by ₹1 from the budget, e.g. step 4 below: ₹820 spent + ₹9 left = ₹829 against ₹830, because the exact figures are ₹820.50 + ₹9.50.
   - **Shortfall month (D-036, Continue anyway):** budget is ₹0, so the line reads e.g. `Today: budget ₹0 · spent ₹200 · overspent ₹200`, followed by the month's shortfall `−₹1,000 this month`.
   - **After a mid-month change (D-037):** the line uses today's budget from the latest period, e.g. ₹630 after the 20 Nov rent change.
3. **Add spend** (a full screen or sheet, per design system).
   - **Amount (₹):** required. More than ₹0 and at most ₹10,00,00,000. Up to 2 decimals. Numeric keyboard, focused on open.
   - **Date:** defaults to today. The picker allows only days **in the current budget month, up to today** (no future dates).
     - After a mid-month first setup (D-034), days before the first budgeted day are not selectable. Example: first setup on 10 Nov, so 5–9 Nov are blocked.
   - **Note:** optional, up to 100 characters, with a character counter near the limit.
   - **Save** stores it (F-007), closes the screen and shows `Spend added`. The list and Today line update. A double tap saves once.
4. **Edit.**
   - Tapping a row opens the same screen pre-filled, titled `Edit spend`.
   - **Save changes** updates it. Changing the date moves it to the other day in the list.
   - The engine recomputes that day's result and the pot (F-006).
   - If the edit shrinks the savings pot below what was already used to cover days, the newest covers are reduced first and the pot never goes below ₹0 (D-040).
   - A short note then explains what changed, e.g. `Your savings pot went down, so the ₹170 that covered Fri, 6 Nov was taken back. 6 Nov is overspent again.`
5. **Delete.**
   - On the edit screen, **Delete** asks `Delete this spend?` with the spend's amount and date, e.g. `₹250 on Mon, 9 Nov. This can't be undone.`
   - **Delete** removes it, and **Cancel** keeps it. The list and Today line update.
6. **Leaving without saving.** Back with unsaved changes asks `Discard this spend?` (add) or `Discard changes?` (edit).
7. **New month started but not set up.** Add spend is blocked with `Set up your new month first` and a button to F-008. The previous month's list stays viewable. This is a PM proposal. The alternative is to store spends without a month and attach them later; see Suggested additions.

**Worked example** (E2 month 5 Nov – 4 Dec 2026, ₹830 a day; today Mon 9 Nov):

| Step | Action | Today line after |
|---|---|---|
| 1 | Add ₹250, note "Lunch" | `budget ₹830 · spent ₹250 · ₹580 left today` |
| 2 | Add ₹400, note "Groceries" | `budget ₹830 · spent ₹650 · ₹180 left today` |
| 3 | Add ₹300.50, no note | `budget ₹830 · spent ₹950 · overspent ₹120` (exact ₹950.50 / ₹120.50) |
| 4 | Edit "Groceries" to ₹270 | `budget ₹830 · spent ₹820 · ₹9 left today` (exact ₹820.50 / ₹9.50) |
| 5 | Delete the ₹300.50 spend | `budget ₹830 · spent ₹520 · ₹310 left today` |
| 6 | Add ₹310 dated Sun 8 Nov | Today unchanged (`spent ₹520 · ₹310 left today`). The list shows `Yesterday` with ₹310 |

## 3. Acceptance criteria *(Product Manager)*
"Small phone", "all four themes" and accessibility checks are as defined in F-002 section 3. Tests use a fixed "today".

| ID | Given / When / Then |
|---|---|
| AC-1 | **Tab states.** Given no confirmed month, when Transactions opens, then it shows `Set up your month first` with a button to F-008 and no Add spend button. Given a confirmed month with no spends, then it shows the Today line, `No spends yet this month` and Add spend. |
| AC-2 | **Add a spend.** Given a confirmed month, when the user taps Add spend, enters 250 and note "Lunch" and taps Save, then the screen closes, `Spend added` appears, the list shows ₹250 "Lunch" under `Today`, and exactly one transaction is stored with 25,000 paise, today's date and source `manual`. |
| AC-3 | **Amount validation.** Given the Add spend screen, when the amount is (a) empty, (b) 0, (c) 10,00,00,001, (d) 12.345, (e) letters, then Save shows the section 5 error and nothing is stored; 300.50, 1 and 10,00,00,000 are accepted, stored exactly (30,050 / 100 / 10,00,00,00,000 paise) and shown in the list as ₹300, ₹1 and ₹10,00,00,000 (D-038). |
| AC-4 | **Date limits.** Given today 9 Nov and the month 5 Nov – 4 Dec, when the date picker opens, then 5–9 Nov are selectable and 10 Nov onwards and anything before 5 Nov are not; the default is 9 Nov. Given a mid-month first setup on 10 Nov (D-034) and today 12 Nov, then only 10–12 Nov are selectable. |
| AC-5 | **Note.** Given the note field, when 100 characters are typed, then a 101st is not accepted and a counter shows the limit; an empty note is allowed and the row shows `No note`; notes with emoji and Hindi text are stored and shown exactly. |
| AC-6 | **Today line — worked example.** Given the §2 worked example, when steps 1–6 are performed, then after each step the Today line shows exactly the text in the table (whole rupees rounded down, D-038), the engine's exact values match the paise in brackets, and the result is shown with words plus colour. |
| AC-7 | **Edit.** Given a ₹400 "Groceries" spend on 9 Nov, when the user edits it to ₹270 and saves, then the list shows ₹270, the 9 Nov day total and the Today line update, and the stored record has 27,000 paise with an updated edited time; when the date is changed to 8 Nov, then it moves under `Yesterday`. |
| AC-8 | **Delete with confirmation.** Given a spend, when the user taps Delete, then the dialog shows its amount and date; **Cancel** keeps it; **Delete** removes it from the list and the database and updates the Today line. |
| AC-9 | **List order and grouping.** Given spends on 5, 8 and 9 Nov (two on 9 Nov), when the list is shown, then the groups are `Today` (9 Nov), `Yesterday` (8 Nov), `Thu, 5 Nov`, each with its day total, and the two 9 Nov spends appear newest first. |
| AC-10 | **Past-day edits reach the engine.** Given 6 Nov overspent ₹170 and covered ₹170 (F-006 test data), when its spend is reduced by ₹100 in F-009, then the engine's results for 6 Nov and the pot match F-006's rule for an over-covered day (cover above the overspend returns to the pot) — checked through the repository/engine, since no cover UI exists in Phase 2. |
| AC-11 | **Once per tap; save failure.** Given the Add spend screen, when Save is double-tapped, then exactly one transaction is stored. Given a forced write failure, when Save is tapped, then the F-007 save-error message appears, the input stays, and nothing is stored. |
| AC-12 | **Discard.** Given unsaved input on Add spend (or Edit), when back is pressed, then `Discard this spend?` (or `Discard changes?`) appears; Keep editing keeps the input; Discard leaves with nothing stored. With no input, back leaves directly. |
| AC-13 | **New month not set up.** Given the last confirmed month ended yesterday and no new month is set up, when the user taps Add spend, then `Set up your new month first` is shown with a button to F-008 and nothing can be saved; the previous month's list is still visible. |
| AC-14 | **Category — N/A in Phase 2 (Gate 1, 2026-11-10).** The plan leaves the picker out (automatic categories come in Phase 4); transactions store no category (the nullable column stays empty, checked in TC-009-03). *Original text:* if the plan includes a category picker, it lists the README §3.4 categories, defaults to `Other`, and the choice is stored and shown on the row. |
| AC-15 | **Persistence and speed.** Given 500 spends in the month, when the app is force-stopped and reopened and Transactions is opened, then all 500 are listed correctly and the list appears in under 1 second (F-007 AC-14); scrolling to the oldest day works. |
| AC-16 | **Help, themes, large text, accessibility.** Given the Transactions tab (all states), the Add/Edit screen and the Delete dialog, when shown in all four themes at text scale 1.0 and 2.0 on a small phone (and landscape 640×360, D-030), then F-002 AC-12–AC-14 pass, every control has its section 5 label and description/tooltip via F-004, TalkBack reads each row as "<amount>, <note>, <date>", and the Today line is read as one sentence including the result word. |
| AC-17 | **Today line after a change or shortfall.** Given the E2 month with rent raised to ₹13,000 on 20 Nov (D-037), when today is 20 Nov and ₹250 is spent, then the Today line reads `budget ₹630 · spent ₹250 · ₹380 left today`, and a ₹250 spend on 19 Nov still shows against 19 Nov's ₹830 budget (saved ₹580). Given a month continued with a ₹1,000 shortfall (D-036), when ₹200 is spent today, then the line reads `budget ₹0 · spent ₹200 · overspent ₹200` and shows `−₹1,000 this month`. |
| AC-18 | **Today's leftover and the pot (D-039).** Given today 9 Nov with ₹250 spent against ₹830, when the Tester reads the engine's pot, then today's ₹580 is not in it and the Today line says `₹580 left today`; when the date becomes 10 Nov (test clock), then 9 Nov is Saved ₹580 and the pot includes it. |
| AC-19 | **Cover taken back after an edit, with a note (D-040).** Given 5 Nov saved ₹330 and 6 Nov overspent ₹170 and covered ₹170 (test data, pot ₹160) and today 8 Nov, when the user edits the 5 Nov spend from ₹500 to ₹830 and saves, then the 6 Nov cover is reduced to ₹0, the pot is ₹0 (never negative), and the note `Your savings pot went down, so the ₹170 that covered Fri, 6 Nov was taken back. 6 Nov is overspent again.` is shown once; when an edit causes no cover change, then no note is shown. |

## 4. Edge cases *(Product Manager)*
- **Midnight passes while the app is open:** the Today line and headings update to the new day when the tab is next shown or the app resumes. A spend added just after midnight defaults to the new date.
- **The new date is a new budget month:** AC-13.
- **Device date set back** (a "future" spend then exists): it stays in its day. It appears under its date heading but is not counted in "spent so far" until that date arrives (F-006 AC-13). The date picker still never allows future dates.
- **Time-zone change:** spends keep their stored calendar date (F-007 AC-3).
- **Many spends on one day** (50+): the list scrolls, the day total is exact, and the Today line is exact.
- **Huge spend** (₹10 crore): accepted. The Today line shows a large overspend in Indian grouping (₹9,99,99,170 over in E2), with no overflow or layout break.
- **Paise amounts** (₹0.01): accepted (more than ₹0) and stored as 1 paisa. Outside the input field it is shown as **₹0**, like every amount (D-038, whole rupees rounded down); the edit field shows the exact `0.01`.
- **Editing a "future" spend after the device date was set back:** the date picker for that spend allows the month's days up to the later of today and the spend's own date, so its date stays valid and other fields can be changed (D-048).
- **Two identical spends** (₹250 "Tea" twice): both are stored. They are legitimate and not de-duplicated (that is Phase 4, for SMS).
- **Editing a spend from the previous month:** in Phase 2 the list only shows the current month, so old months are read-only and not shown. Edits are within the current month only.
- **Delete the last spend of a day:** that day's heading disappears.
- **Back on the Delete dialog:** same as Cancel.
- **Text scale 2.0:** the Today line wraps onto several lines and is never truncated. Amounts never split across lines.

## 5. Help text & copy *(Product Manager, finalised by Designer)*
| Control | Label | Description / tooltip |
|---|---|---|
| Today line | `Today` | `budget <x> · spent <y> · <z> left today` / `on budget` / `overspent <z>`; less than ₹1: `less than ₹1 left today` / `overspent less than ₹1` (D-050). (i): `Today's budget minus what you've spent today. Whatever is left at midnight goes to your savings pot.` |
| Cover taken back note | — | `Your savings pot went down, so the <amount> that covered <day> was taken back. <day> is overspent again.` For a partial cut: `… so <amount> of the cover on <day> was taken back.` Several covers cut by one save: one paragraph per cover in one sheet, newest cover first (D-048). An amount less than ₹1 reads `less than ₹1`. Button `OK` |
| Today line, shortfall month | — | `Today: budget ₹0 · spent <y> · overspent <y>` · `−<shortfall> this month` |
| No month empty state | `Set up your month first` | `Your spends need a budget month. It takes a minute.` Button `Set up your month` |
| No spends empty state | `No spends yet this month` | `Add what you spend and we'll keep your daily budget up to date.` No button of its own: the floating `Add spend` button serves this state (`transactions.md` §6.2) |
| Add spend (FAB) | `Add spend` | Tooltip: `Add a spend by hand` |
| Add screen title / Edit title | `Add spend` / `Edit spend` | — |
| Amount | `Amount` | `How much you spent.` Errors: `Enter an amount` · `Amount must be more than ₹0` · `That's more than ₹10 crore. Please check the amount.` · `Use numbers only, with up to 2 decimals` |
| Date | `Date` | `When you spent it. You can pick any day this month up to today.` |
| Note | `Note (optional)` | `For example, "Lunch with Riya" or "Petrol".` Counter `<n>/100` |
| Category (if in plan) | `Category` | `What kind of spend this is. Automatic categories come later.` |
| Save (add / edit) | `Save` / `Save changes` | Hints: `Save this spend` / `Save your changes` |
| Saved confirmation | `Spend added` / `Spend updated` / `Spend deleted` | — |
| Delete button | `Delete` | Hint: `Delete this spend` |
| Delete dialog | `Delete this spend?` | `<amount> on <date>. This can't be undone.` Buttons `Delete` · `Cancel` |
| Discard dialog | `Discard this spend?` / `Discard changes?` | Buttons `Discard` · `Keep editing` |
| New month blocked | `Set up your new month first` | `Your last budget month has ended. Confirm this month's numbers to keep adding spends.` Button `Set up this month` |
| Row (no note) | — | `No note` |
| Today line, screen reader | — | One sentence: `Today: budget ₹830, spent ₹250, ₹580 left today.` Shortfall adds `Minus ₹1,000 this month.` |
| Day header | `Today` / `Yesterday` / `Sat, 7 Nov` + day total | Screen reader: `<heading>, total <amount>` |
| Row, screen reader | — | `<amount>, <note or No note>, <weekday day month>` e.g. `₹250, Lunch, Monday 9 November`. Tap hint `Edit` (none on last month's read-only rows) |
| No month button | `Set up your month` | Hint `Open month setup` |
| New month block button | `Set up this month` | Hint `Set up your new budget month` |
| New month block sheet (on Add spend) | `Set up your new month first` | Same body as the block. Buttons `Set up this month` · `Not now` (hint `Close`) |
| Last month list label | `Last month · <start> – <end>` | e.g. `Last month · 5 Oct – 4 Nov` |
| Editor close | (icon ×) | Tooltip `Close`. Hint `Leave without saving` |
| Date value | — | `Today · Mon, 9 Nov` / `Yesterday · Sun, 8 Nov` / `Sat, 7 Nov` |
| Date picker | — | Help text `Pick the day you spent it`. Buttons `Cancel` · `OK` |
| Delete dialog Cancel | `Cancel` | Hint `Keep this spend` |
| Discard dialog bodies | — | Add: `What you've typed won't be saved.` Edit: `Your changes to this spend won't be saved.` Buttons `Keep editing` (first; hint `Go back to your spend`) · `Discard` (hint `Leave without saving`) |
| Cover taken back sheet | `Savings pot updated` | Body per the cover note row. Button `OK`, hint `Close` |

## 6. Out of scope
- Search, filters, edit category from the list, and the full transactions list design (Phase 3).
- Home top summary, calendar, day details and the "Cover with savings" button (Phase 3).
- Income other than the salary. **Manual "money in" (refunds) entry** is not offered in Phase 2: the engine and the database already support money in (D-047, F-006 AC-25, F-007 AC-19), and Phase 4 SMS credits use it (D-051). SMS transactions and duplicate detection (Phase 4).
- Previous months' transactions view.
- Undo after delete (the confirmation dialog is used instead).

## 7. How it works — technical *(Developer, filled in when the feature is Done)*
**What was built.** The Transactions tab and the Add / Edit spend screen. Tasks T-217 to T-220, T-240, T-249, then T-243 and T-250 (b). Gate 3 approved 2026-11-13 (T-219 after Must fix M1 and M2), Gate 4 conditional pass (D-071).

**Main files** (`app/lib/`)
- Pure Dart in `domain/budget/`: `today_line.dart` (`TodayLine`, `TodayResultKind`), `spend_groups.dart` (`groupSpendsByDay`, `DayGroup`), `spend_draft.dart` (`SpendDraft`, `spendDateLimits`); `CoverReductionCut` extension in `month_result.dart` (M1: the money arithmetic of the cover note lives in the engine layer).
- `features/transactions/`: `transactions_tab.dart`, `transactions_state.dart` (sealed `NoMonthView` / `NewMonthView` / `CurrentMonthView`), `today_line_view.dart`, `spend_list.dart` (lazy per day), `spend_editor_screen.dart`, `spend_editor_flow.dart` (`openSpendEditor`, hosts the cover-taken-back note), `add_spend_button.dart`, `month_setup_launcher.dart`, `widgets/` (`cover_taken_back_sheet`, `delete_spend_sheet`, `discard_spend_sheet`, `new_month_blocked_sheet`, `new_month_card`, `note_field`); `core/copy/transactions_copy.dart`.
- Small additive changes to Phase 1 files: `TabPage.slivers`, `NavTooltip(hint:)`, date picker theme in `budget_theme.dart`, one line in `app_shell.dart` (the Add spend button is the shell's floating button, Transactions tab only).

**Data stored.** Writes `transactions` rows through F-007: add inserts (`source = manual`, `category` empty, `created_at = edited_at = now`), edit updates day, amount, note and `edited_at`, delete is a real delete. Each write runs the engine inside the same transaction and stores any D-040 cover reductions, returned as `SpendWriteOutcome`. There is no manual money-in entry in Phase 2 (D-051) and no category picker (AC-14 is N/A).

**Decisions:** D-034 (no dates before the first budgeted day), D-036, D-037 (Today line uses the latest period), D-038, D-039 (leftover joins the pot at midnight), D-040 (note when covers are reduced), D-047, D-048 (order within a day, editing a future-dated spend), D-050 and D-055 (`less than ₹1` wording), D-051, D-059, D-070, D-071.

**Deviations** (plan section 11)
- G1 `TodayLine.from(MonthResult)` has no `today` parameter. G2 five result kinds (D-050). G3 day order: newest day, then newest `createdAt`, then id. G4 `toFields` instead of `toSpend`. G5 `spendDateLimits`. G6 note length counted by the field (graphemes), not the draft. All approved at Gate 3.
- C1 the tab reads the shared month state and calls `TodayLine.from` only when today is a budgeted day (a phone date set back gives a read-only list). **C2 the Add spend button lives in the shell.** C3 additive shared-widget changes. C4 lazy per day, not per row. C5 no `spend_editor_controller.dart` (form state in the screen's `State`). C6 launcher wiring, resolved by T-240. C7 new small text: the date error `Pick a day this month, up to today.` (Designer records it in T-241, still To do). C8 the Today line wraps between its parts; the note field is its own widget.
- T-250 (b), design decision from T-247: above 1.3x text the first-time tip moves below the Today card so Add spend never covers the Today line.

**How it is tested** (`tests/F-009-manual-transactions.md`, 49 cases, 19 ACs)
- Unit: `test/domain/budget/today_line_test.dart`, `spend_groups_test.dart`, `spend_draft_test.dart`, `savings_pot_test.dart` (TC-009-25, -27); the worked example is checked to the paisa against the engine.
- Widget (fake repositories; five theme cases, text scale 2.0): `test/features/transactions/` (`transactions_tab_test`, `spend_editor_screen_test`, `delete_spend_test`, `cover_note_test`, `today_line_test`, `transactions_sweep_test` = TC-009-20). TC-009-08's 101st-character case uses Latin, Hindi and emoji (PM condition G6). TC-009-48 (an edit that fails keeps the input and the old record) and TC-009-49 (close button focus ring, renamed from TC-009-16) were added by T-249; TC-009-46 at 2.0x is in `transactions_tab_test.dart` (T-250).
- Integration on the emulator: `integration_test/transactions_500_test.dart` (TC-009-19; worst on-screen first row 450 ms of five runs, limit 1,000 ms) and, from T-243, `integration_test/manual_transactions_flow_test.dart` (TC-009-45: steps 1 to 5 on 9 Nov, Today line after each step and after a restart); 1 / 1 passed on emulator-5554, log `docs/reviews/emulator-phase-2/integration-manual-transactions-flow.log`.
- Manual and device (R1): TC-009-31, -43, -45, -46 (screens in `docs/reviews/emulator-phase-2/`).
- Result at Gate 4 (R1): 45 Pass of 49, 1 Partial (TC-009-46), 1 Blocked-needs-human (TC-009-22), TC-009-48 not run at the time (since added by T-249), TC-009-18 N/A; no bug; `check.ps1` 591 tests green.
- Result at the Gate 4 re-check (R5, 2026-11-16): 47 Pass of 49, 1 Blocked-needs-human (TC-009-22), 1 N/A (TC-009-18), no bug; `check.ps1` 606 tests green; integration 8 of 8. TC-009-46 now Pass (Dim theme, 2.0x), TC-009-48 Pass (T-249 done).

**Known limitations and open items**
- **Gate 4 passed (D-071, re-check D-072).** T-243 is built and green; T-249 is done (TC-009-48 and TC-009-49 exist and pass in the 606-test run) and T-244 (Tester: Dim theme for TC-009-46 and the other R4 screens) is done, so the feature is Done.
- **TC-009-22 (TalkBack) is Blocked-needs-human**, accepted as open (D-071). Proofs in place: the accessibility tree dump has the exact texts (Today sentence, row labels, Add spend, Delete sheet) and the semantics tests are green. The walk must include the close button focus ring with an external keyboard.
- TC-009-46 was Partial in R1 and is Pass in R5; other states (delete sheet, discard sheets, cover note, load error, 50-spend day) are covered by the TC-009-20 sweep, not walked on the device.
- Low observation (Tester, R5): at the top of the page at 2.0x with the first-time tip showing, the Add spend button sits over the lower part of the tip text until the page is scrolled or the tip dismissed. Accepted (T-247 design, D-072); it never covers the Today line.
- Category picker not in Phase 2 (AC-14 N/A); manual money in not offered (D-051). The time zone changing while the app stays in the foreground is re-read only on resume and at midnight (accepted, D-071).
- Nice to have, not blocking: T-242 (N3 replace the `_Busy` notifier in `openSpendEditor`, N5 `formatDayMonthLong` for the spoken date, N6 a double tap on Delete can open two sheets, N7 fade the Add spend button with the tab). T-241 (C7 in the spec) and T-251 (Today card figure) are done. T-247 is decided and built (T-250).
- Depends on F-006, F-007, F-008 (month state, launcher). Used by F-012 (day details) and F-015 (transactions list).

## 8. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-10 | First version of the spec; OD-2, OD-6 pending; category left to the plan (phase overview) | Product Manager |
| 2026-11-10 | Owner decisions applied: D-034 (dates before the first budgeted day blocked, §2.3, AC-4; "today not budgeted" state removed because today is always budgeted), D-036 (₹0-budget Today line with the shortfall, §2.2), D-037 (Today line uses the latest period, new AC-17). Month statement suggested for Phase 3. ACs 16 → 17. OD-6 still pending | Product Manager |
| 2026-11-10 | Final: D-038 (whole rupees rounded down; worked example, AC-3, AC-6), D-039 ("₹X left today", leftover joins the pot at midnight; new AC-18), D-040 (newest covers reduced first with a note; §2.4, new AC-19). No PENDING items left. Status: final Spec, ready for the plan. 19 ACs | Product Manager |
| 2026-11-10 | Gate 1 (PM): §4 ₹0.01 shown as ₹0 (D-038, the Designer's pending correction); AC-14 N/A; within-day order = newest added (D-048); "less than ₹1" result wording (D-050); several covers in one note; editing a future-dated spend; manual money in out of Phase 2 (D-047/D-051). Status → Plan approved | Project Manager |
| 2026-11-10 | §5 finalised by Designer (`docs/design/screens/transactions.md`): no-spends empty state uses the floating Add spend button (no second button); added screen-reader strings, day header, last-month label, new-month sheet, editor close, date value and picker copy, Cancel/Keep editing hints, discard bodies, cover sheet title. "Dialog" means the design system decision sheet. ₹0.01 follows D-038 (shown ₹0) pending the PM's §4 correction | Designer |
| 2026-11-16 | Section 7 filled in (Step 9, T-246): built files, stored data, decisions, deviations (G1 to G6, C1 to C8, T-250 tip), tests, open items (T-244, TC-009-22 TalkBack, Nice to haves). Status stays Testing until T-244 is green (D-071) | Developer |
| 2026-11-16 | Section 7 updated to the R5 results (606 tests, 8 integration tests, T-249 and T-244 done, TC-009-46 and -48 Pass). Gate 4 re-check passed (D-072); status Done | Project Manager |

## Impact on existing features
- **F-003 AC-4 / §5:** the Transactions placeholder empty state is replaced by the AC-1 states once wired in, after Phase 1 is Owner-approved (D-033). F-003 Transactions test cases are updated then.
- **F-004:** the Transactions first-time hint wording ("from your bank SMS") still fits. Revisit in Phase 4.

## Suggested additions *(for the CEO — not in scope until approved)*
- **Flag for the CEO: "Month statement" screen, suggested as a Phase 3 feature (D-037).** It shows each budget period of the month with its dates, the values in force (salary, target, fixed costs), the daily budget, and spent / saved / overspent / covered, plus the month totals and a plain list of what changed when. Example: `5–19 Nov: salary ₹40,000, fixed ₹15,100 → ₹830/day` and `20 Nov – 4 Dec: rent ₹10,000 → ₹13,000 → ₹630/day`. PDF export comes later. Phase 2 already stores the history (F-007 AC-16) and computes per-period results (F-006 AC-21), so this is a screen only. It also answers the Owner's sign-off question ("are the calculations correct?") for past months.
- **A "Numbers check" view** (debug or Settings) listing every day's budget, spent, result, the pot and the month totals. Phase 2 has no cover UI or summary, so without it the Owner can't check the pot or totals by eye at sign-off ("are the calculations correct?").
- **Quick-amount chips** (₹50, ₹100, ₹200, ₹500) and recent notes as suggestions. Google Pay-style quick entry, which suits small daily spends.
- **Allow adding spends before the new month is set up** (kept unattached, then joined to the month on confirm), instead of the AC-13 block.
- **Refunds as negative spends** (e.g. a cancelled Swiggy order) in Phase 3/4.
