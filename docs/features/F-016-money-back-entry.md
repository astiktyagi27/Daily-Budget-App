# F-016: Money back (manual refund entry)

| | |
|---|---|
| **Phase** | 3 |
| **Status** | Spec (final, ready for the plan; planned ahead, D-033). Added by the Owner's D-054. Applies D-047, D-048, D-050 and D-051 |
| **Plan** | [`plans/F-016-money-back-entry.md`](../../plans/F-016-money-back-entry.md) |
| **Test cases** | [`tests/F-016-money-back-entry.md`](../../tests/F-016-money-back-entry.md) |
| **Tasks** | T-440 to T-444 in `docs/TASKS.md` (Gate 1, 2026-11-16) |

## 1. What it is *(Product Manager)*
A **Money back / refund** switch on the F-009 Add spend screen (D-054). The user can record money paid back to them, such as a cancelled Swiggy order, an Amazon return, or a friend paying back their share. They don't have to wait for SMS reading in Phase 4.

The money rule already exists and is the Owner's (D-047, built in F-006 AC-25 and stored as `transactions.direction` in F-007 AC-19, D-051):
- money back **reduces the spend of the day it arrives**;
- if it is more than that day's spends, the day's net spend goes below ₹0, and the day counts as saved by more than its budget;
- **salary credits are not refunds.**

This feature adds **only the entry UI**, and **no new money rule**. Showing refunds is in F-010 to F-015.

**User stories:**
- As a **user**, I want to record a refund so that my day's spend is correct.
- As a **user**, I want to fix or remove a wrong refund the same way as a spend.

## 2. How it behaves *(Product Manager)*
Layout per `docs/design/screens/transactions.md` §8. The Designer adds the switch at Step 6.

1. **The switch.** On **Add spend**, a switch row comes after the Amount field: `Money back / refund`, off by default. When it is on:
   - the title changes to `Add money back`, and the Amount label to `Amount back`;
   - the Note placeholder becomes `For example, "Amazon return" or "Riya paid me back"`;
   - the **Category** row (F-015 §2.4a) is hidden, because refunds have no category;
   - **Save** stores one transaction with direction **in** (F-007), the snackbar says `Money back added`, and the screen closes.
2. **Limits** are the same as a spend (F-009 §2.3):
   - more than ₹0 and at most ₹10 crore, with up to 2 decimals;
   - the date is in the current budget month, up to today, and not before the first budgeted day (D-034, D-057);
   - the note can be up to 100 characters.
3. **Edit.** Tapping a refund row opens the editor titled `Edit money back`, with the switch on.
   - The switch can be turned off to change the entry into a spend, or on for the reverse. That counts as an unsaved change.
   - `Save changes` updates it, and the snackbar says `Money back updated`.
4. **Delete.** A decision sheet asks `Delete this money back?` with `₹500 back on Fri, 13 Nov. This can't be undone.` The buttons are **Delete** and **Cancel**. The snackbar says `Money back deleted`.
5. **Effects** come from the F-006 engine, shown by F-010 to F-015:
   - **Example (₹830/day, today Fri 13 Nov, ₹420 spent):** add ₹500 money back today. Today's net spent is 420 − 500 = −₹80, so the Today card reads `budget ₹830 · spent −₹80 · ₹910 left today` with `Includes ₹500 back from refunds`. Home's Spent so far drops from ₹5,530 to ₹5,030, and Left rises from ₹19,370 to ₹19,870.
   - **Past day (Thu 12 Nov, nothing spent, saved ₹830):** add ₹1,500 money back. 12 Nov's net is −₹1,500, so the day is Saved ₹2,330 and the pot rises by ₹1,500.
   - **Covered overspent day (11 Nov, overspent ₹300, covered ₹300):** add ₹200 money back. The overspend is now ₹100, so the cover is cut to ₹100 and ₹200 goes back to the pot. There is no note (F-006 §4), and the cut is stored and never comes back (D-048 (6)).
   - **Shortfall month (₹0/day):** ₹500 money back alone makes that day Saved ₹500 (F-006 AC-25).
6. **Deleting or lowering money back can shrink the pot** below the covers already made. Then D-040 applies: the newest covers are cut first, with F-009's `Savings pot updated` sheet (several covers in one sheet, D-048 (6)). Example: AC-10.
7. **Salary is not money back.** The switch description says so. The app does not detect a salary typed as money back (see Edge cases).
8. **Discard.** Back with input asks `Discard this money back?` (add) or `Discard changes?` (edit). The F-009 buttons are unchanged.

### Gate 1 clarifications *(Project Manager, 2026-11-16; D-084)*
- **Which Today card:** the line `Includes ₹500 back from refunds` belongs to **Home's** Today card (F-010, AC-4). The Transactions tab's Today card (F-009 layout, unchanged by F-015 AC-2) shows the same net numbers (`spent −₹80 · ₹910 left today`) without that line. AC-8's "Today card returns to `spent ₹420 · ₹410 left today`" holds on both cards.
- **Converting** between spend and money back is an ordinary edit: `direction` changes, the category is cleared when the entry becomes money back, and the cover rules apply as for any edit. The snackbar follows the result (`Spend updated` or `Money back updated`).
- **No extra warning** for very large amounts or a salary typed as money back (Phase 4 SMS rule).

## 3. Acceptance criteria *(Product Manager)*
Fixed "today", example A data (F-010 §2.4). Themes and accessibility per F-002 §3.

| ID | Given / When / Then |
|---|---|
| AC-1 | **Switch shown, off by default.** Given Add spend, when it opens, then a `Money back / refund` switch row is shown after Amount, off, with its description; the title is `Add spend` and the Category row is visible. |
| AC-2 | **Switch on.** Given Add spend, when the switch is turned on, then the title reads `Add money back`, the Amount label `Amount back`, the Note placeholder changes, and the Category row is hidden; turning it off restores all four. |
| AC-3 | **Save money back.** Given today 13 Nov, when the user enters 500, note `Amazon return`, switch on, and saves, then exactly one transaction is stored with 50,000 paise, direction **in**, date 13 Nov, no category, source `manual`; `Money back added` is shown; the Transactions row reads `Refund · +₹500 · Amazon return`. |
| AC-4 | **Today's figures.** Given AC-3, when Home is shown, then the Today card reads `budget ₹830 · spent −₹80 · ₹910 left today` plus `Includes ₹500 back from refunds`, Spent so far `₹5,030` and Left `₹19,870`. |
| AC-5 | **Past day beyond its budget (D-047).** Given 12 Nov with nothing spent, when ₹1,500 money back is added for 12 Nov, then 12 Nov is ● Saved ₹2,330 in day details and the calendar (cell `−₹1,500`), and Home's Saved this month rises from ₹2,000 to ₹3,500. |
| AC-6 | **Limits.** Given the switch on, when the amount is empty, 0, 10,00,00,001, 12.345 or letters, then the F-009 errors are shown and nothing is stored; when the date picker opens, then it allows the same days as Add spend (F-009 AC-4, including the mid-month and late-start limits). |
| AC-7 | **Edit and convert.** Given the ₹500 money back, when its row is tapped, then `Edit money back` opens with the switch on; when the amount is changed to ₹300 and saved, then `Money back updated` is shown and 13 Nov's net spent reads `₹120`; when the switch is turned off and saved, then the entry is a ₹300 spend (direction **out**) and 13 Nov's spent reads `₹720`. |
| AC-8 | **Delete.** Given the ₹500 money back, when Delete is tapped, then the sheet reads `Delete this money back?` / `₹500 back on Fri, 13 Nov. This can't be undone.`; **Cancel** keeps it; **Delete** removes it, shows `Money back deleted`, and the Today card returns to `spent ₹420 · ₹410 left today`. |
| AC-9 | **Covered day (D-048 (6)).** Given 11 Nov overspent ₹300 and covered ₹300, when ₹200 money back is added for 11 Nov, then 11 Nov is ○ On budget with `Covered from savings ₹100`, the pot rises by ₹200, no note is shown, and deleting the money back afterwards leaves the cover at ₹100 and 11 Nov `◆ Overspent ₹200`. |
| AC-10 | **Pot shrinks (D-040).** Given test data where saved this month is ₹3,500 (including 12 Nov's ₹1,500 money back) and covers total ₹2,500 (pot ₹1,000; newest cover ₹1,000), when the 12 Nov money back is deleted, then saved falls to ₹2,000, the newest cover is cut from ₹1,000 to ₹500, the pot is ₹0 (never negative), and the F-009 `Savings pot updated` sheet is shown once naming that cut. |
| AC-11 | **Discard and once per tap.** Given input (an amount or note typed) with the switch on, when back is pressed, then `Discard this money back?` is shown; given Add with only the switch turned on and nothing typed, when back is pressed, then the screen leaves at once (the switch alone is not input; on Edit the switch counts as a change); given a double tap on Save, then exactly one transaction is stored; given a forced write failure, then the F-007 save error is shown and the input stays. |
| AC-12 | **Help, themes, large text, accessibility.** Given the editor with the switch on and off, in all four themes at text scale 1.0 and 2.0 on a small phone and in landscape (D-030), then F-002 AC-12–AC-14 pass, the switch row has its §5 label and description via F-004, and TalkBack reads it as `Money back / refund, switch, off` with the description. |

## 4. Edge cases *(Product Manager)*
- **Money back on the first budgeted day of a late-started month** (D-057): allowed. Earlier days are blocked.
- **Money back bigger than the whole month's spends:** Spent so far goes negative (F-010 §4).
- **The salary typed as money back:** not detected. The day is shown as hugely saved. The switch description warns against it. A Phase 4 SMS rule separates salary credits.
- **₹0.40 money back:** accepted. It is listed as `+₹0` (a single amount, D-050). If it turns an exact on-budget day into saved, that reads `saved less than ₹1`.
- **Converting a spend into money back on a covered day:** the D-040 / over-cover rules apply as for any edit.
- **Money back for last month:** not possible. The picker is limited to the current month (F-009). It counts on the day it arrives, which is this month (D-047).

## 5. Help text & copy *(Product Manager, finalised by Designer)*
| Control | Label | Description / tooltip |
|---|---|---|
| Switch | `Money back / refund` | `Turn on for money paid back to you, like a refund or a friend paying you back. It lowers what you spent that day. Not for your salary.` |
| Title (add / edit) | `Add money back` / `Edit money back` | — |
| Amount | `Amount back` | `How much you got back.` Prefix `+₹` while the switch is on (Designer). Errors as F-009 |
| Note placeholder | `Note (optional)` | `For example, "Amazon return" or "Riya paid me back".` |
| Save | `Save` / `Save changes` | Hints `Save this money back` / `Save your changes` |
| Snackbars | — | `Money back added` / `Money back updated` / `Money back deleted` |
| Delete sheet | `Delete this money back?` | `<amount> back on <weekday, d MMM>. This can't be undone.` Buttons `Delete` (hint `Delete this money back`) · `Cancel` (hint `Keep this money back`) |
| Discard sheet | `Discard this money back?` | `What you've typed won't be saved.` Buttons as F-009 |

## 6. Out of scope
- Detecting refunds from SMS (Phase 4, D-051).
- Linking a refund to the original spend.
- Income other than refunds. Salary stays in month setup.
- Categories on refunds (F-013 shows refunds as one line).
- Any new money rule. D-047 is the rule.

## 7. How it works — technical *(Developer, filled in when the feature is Done)*
**What was built.** Manual entry of money back (a refund) in the same Add / Edit screen as a spend: a Money back switch right after Amount, a `+₹` prefix on the amount while it is on, the Category row collapsing when it is on, matching titles, Delete and Discard wording, and the snackbar that follows the result. A refund lowers the day's net spend through the engine (F-006 AC-25); the engine was not changed. Turning a spend into money back, or back, is an ordinary edit. Tasks T-440 to T-444 (T-441 and T-443 tests, T-444 category cleared in the same write); Gate 1 D-084 and D-085, Gate 3 D-091, D-092 (5), Gate 4 D-100 to D-105.

**Main files** (`app/lib/`)
- `features/transactions/widgets/money_back_switch.dart` (the switch row; stacks above 1.3x text), `spend_editor_screen.dart` and `spend_editor_flow.dart` (titles `Add money back` / `Edit money back`, prefix, Category row collapse with `AnimatedSize`, no cross-fade of the amount description), `delete_spend_sheet.dart` and `discard_spend_sheet.dart` (money-back variants), `category_field.dart` (hidden for money back); copy in `core/copy/money_back_copy.dart`.
- Pure Dart: `domain/budget/spend_draft.dart` (`SpendDraft` reads and writes `direction`; `forEdit` reads the stored direction; a refund draft has no category and `toFields` clears it); `SpendDirection.moneyIn` already existed from F-006.
- Additive changes to F-007 code that belong to this feature: **`SpendFields.direction`** (shared with F-015, which added `category` in the same change, D-082 (2) and D-084 (6)) and **`update` writing `direction`** in one transaction with the cover rules and the category being cleared (D-084 (3)). `add` takes the direction from `SpendFields`.
- Rows that already existed and needed no change: Home, Calendar, Day details, Dashboard and Month statement already show refunds (built by their own features); the refund row on Day details opens the editor, now titled `Edit money back` (TC-012-58, row hint stays `Edit`).
- Not this feature: `removeCovers` and the cover id (F-012 Undo and Remove cover, D-056), `watchMonthIndex` (F-011), `updateCategory` and the category column read (F-015 and F-013).

**Data stored.** The existing `transactions.direction` column (`in` for money back, F-007 AC-19); no schema change, no migration, no trigger touched (F-007's append-only triggers cover periods and fixed costs only). Money back is stored with `source = manual`, a positive amount and an empty category. Each write runs the engine in the same transaction and stores D-040 cover reductions, returned in `SpendWriteOutcome`; a delete rolls back completely when the cover write fails (TC-016-47).

**Decisions:** D-084 (1) the `Includes ₹500 back from refunds` line is on Home's Today card only (the Transactions Today card keeps the F-009 layout and shows the net `spent −₹80`); (2) seeds P1 and P1b for AC-10 confirmed; (3) converting is an ordinary `update` writing `direction`, category cleared in the same write; (4) the snackbar follows the result; (5) no confirm or warning for a very large amount or a salary typed as money back (Phase 4 SMS rule); (6) `SpendFields` as in D-082 (2). Also D-047, D-054 (refunds entered by hand), D-050 and D-055, D-040 (covers cut newest first), D-051, D-085, D-091, D-092 (5) (on Add the switch alone is not input; with an amount or note typed Back asks `Discard this money back?`; on Edit the switch is a change), D-100 to D-105.

**Deviations** (plan section 11)
- No app code was rewritten after the first build; T-441 to T-444 added tests. Day details refund row: no copy change.
- TC-016-47 (a forced failure in the cover write rolls the whole delete back) is an added case not in the Tester's first file. TC-016-45 is proved with the F-009 pot-sheet host (one sheet per action). TC-016-02 appears twice (the full case in `money_back_editor_test.dart`, a thin one in F-015's `transactions_search_test.dart`).
- **B-003 was a test-script fault, not an app fault** (D-101): `money_back_flow_test.dart` looked for the Today line while the list was scrolled down, and the line is built lazily. `_expectLine` now scrolls it into view and `_openTransactions` waits for the tab bar after a restart; every expected text is unchanged. Green four times on the emulator (Developer); the status stays `Fixed pending Tester verification`.
- Finding, not a bug: Day details tests need `setUpAll(loadBundledFonts)`; with the test font the `Day result` row overflows.

**How it is tested** (`tests/F-016-money-back-entry.md`, 47 cases, 12 / 12 ACs)
- Repository (in-memory Drift, seeds from `phase3_fixtures.dart`): `test/data/repositories/money_back_effects_test.dart` (16 tests: TC-016-05, -06, -10, -11, -13, -14, -16, -18, -19, -26, -28, -29, -31, -37, -46, -47), `transactions_repository_test.dart` (TC-016-41), `category_write_test.dart`; AC-5, AC-9 and AC-10 hold through `add`, `update` and `delete` with no engine change (a covered day keeps its cover cut to 10,000 after a delete; P1: newest cover 1,00,000 to 50,000, pot 0; P1b: three covers cut newest first with the reductions listed). Unit: `spend_draft_test.dart` (TC-016-46).
- Widget (fake repositories; five theme cases, 1.0x and 2.0x, landscape): `test/features/transactions/money_back_editor_test.dart` (23 tests), `money_back_screens_test.dart` (11 tests: Home and Transactions Today cards, Day details, Home Saved, calendar cell, Dashboard, Month statement), `money_back_sweep_test.dart` (TC-016-33: 12 states x 5 themes x 1.0 / 2.0 with the F-002 accessibility checks; TC-016-35 landscape and switch-row stacking), `test/copy/money_back_copy_test.dart` (TC-016-22), TC-012-58 in `day_details_edit_test.dart`.
- Integration on the emulator: `integration_test/money_back_flow_test.dart` (TC-016-34: AC-3, AC-7, AC-8 on the device). It failed first at the Today line in two Tester 1 logs (B-003); after the test-script fix it passed four times in the Developer's runs (`dev-final-money_back_flow-run1.log` to `-run3.log` and `dev-money_back_flow.log`, debug; this is a functional test, no speed limit).
- Mutation pass and probes: T-470 items TC-016-37 (money in counted as a spend in the day result), -39 (past-month refund row gets `onOpen`), -40 (refund line dropped from the Dashboard) and -45 (pot sheet only for spends): **4 of 4 killed**, by 19, 1, 8 and 2 failing tests. Developer probes (reverted): draft keeps the category for a refund, covers cut not stored, outcome by start type, Home refunds line off, `amountLabel` copy changed, `stackAbove` 1.3 to 9, delete sheet ignoring money back, `forEdit` ignoring direction, `update` not writing direction, note description not switched, delete Cancel hint changed. A probe of the switch row's `minHeight` did not fail the sweep (the Switch itself keeps 48 dp), so that guard is not claimed; `stackAbove` is proved by TC-016-35 and not by -33. TC-016-47, -37, -39, -40 and -45 were not probed by the Developer.
- Result (Tester, state at the Gate 4 review): 47 cases, Pass 43, Partial 1, Fail 1 (TC-016-34, B-003, now fixed in the script), Blocked 1 (TC-016-24), Pending 1. `tool/check.ps1` last run: 1,285 tests green, domain coverage 100 %, TZ matrix passed. Gate 4: conditional pass (D-103). Section 4 and 5 of the test file are to be updated by Tester 1 after T-445.

**Known limitations and open items**
- **Not Done yet.** Open before Done (D-103, D-104): Tester 1's session T-445: re-run `money_back_flow_test.dart` (and `month_setup_flow_test.dart`, B-005) on an idle machine and close B-003; TC-016-35 (font 2.0 and landscape by hand) and **TC-016-36** (kill with the Money back switch on and 500 typed: nothing stored, nothing resumed; a data-safety check with no widget-test equivalent). Also a green `tool/check.ps1` on the final code (Orchestrator), and Gate 5 with the Tester's final session.
- **TC-016-24 (TalkBack) is Blocked-needs-human**, accepted as open (D-104). Proofs in place: the semantics sentences (TC-016-23) and the sweeps are green. A real-phone walk is recommended, not required.
- No warning for a very large amount or for a salary typed as money back (D-084 (5); the Phase 4 SMS rule covers it). Money back has no category by design. The Transactions Today card shows only the net `spent −₹80`, not the `Includes …` line (D-084 (1)).
- Nice to have: none new from the Gate 4 review.
- Depends on F-006 (AC-25 refunds in the engine), F-007 (`direction`, `SpendFields`, `update`, AC-18 and AC-19), F-009 (editor, list, Today card), F-015 (category row, shared files). Used by F-010 (Today card line), F-011, F-012, F-013 (Refunds and Net spent lines), F-014 (`Refunds −₹…`).

## 8. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-11 | First version of the spec, from the Owner's D-054 (closes F-010 Q-2). 12 ACs | Product Manager |
| 2026-11-11 | Small-amount wording switched from "under ₹1" to the Owner's literal "less than ₹1" (`overspent less than ₹1`, `saved less than ₹1`, `less than ₹1 left today`, `less than ₹1 short`, `less than ₹1 a day`), matching the Phase 2 change to D-050/D-055. Wording only, no AC added | Product Manager |
| 2026-11-11 | Status set to final Spec, ready for the plan (all Owner questions answered: D-053 to D-058). Remaining team questions go to the Project Manager at Phase 3 Gate 1 (phase overview, open items) | Product Manager |
| 2026-11-11 | §5 finalised by the Designer (`docs/design/screens/transactions-search.md` §9): `+₹` amount prefix while the switch is on, Delete/Cancel hints. Layout: switch row right after Amount, Category row collapses when on. No AC changed | Designer |
| 2026-11-16 | Gate 1 (Project Manager B, D-084): clarifications on which Today card shows the `Includes …` line, conversion and no extra warning. No AC changed. 12 ACs | Project Manager |
| 2026-11-21 | Gate 3 Track E (D-091): AC-11 says the Money back switch alone on Add is not input (back leaves at once); Edit unchanged. No rule changed | Product Manager |
| 2026-11-23 | Section 7 filled in (Step 9, T-446): built files, stored data (`direction`, no schema change), decisions D-084 to D-105, deviations (B-003 was a test-script fault), tests (4 of 4 mutants killed), open items (T-445 session, TC-016-35 and -36, TC-016-24 TalkBack). Status stays Testing until those are closed (D-103, D-105) | Developer |

## Impact on existing features
- **F-009:** the editor gets the switch, and the `Add money back` / `Edit money back` titles, delete text and discard text. F-009 §6 "manual money in not offered in Phase 2" stays true for Phase 2. This adds it in Phase 3.
- **F-015:** the Category row is hidden while the switch is on (F-015 §2.4a).

## Suggested additions *(for the CEO — not in scope until approved)*
- **"Refund for…"**: pick the original spend, and pre-fill its note and amount.
