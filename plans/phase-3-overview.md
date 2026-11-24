# Phase 3 — Calendar & dashboard: Overview

**Status:** Planning only (D-033 chain). Phase 1 is finishing and Phase 2 is in Gate 1. **No Phase 3 code is written until Phase 2's engine (F-006) and database (F-007) exist**, and nothing in Phase 3 is signed off before Phase 2 is Owner-approved (CLAUDE.md rule 5).

## Phase goal *(CEO)*
- **At the end of this phase the Owner can:** use the app fully with manual entries (README §11). Home shows the top summary and a card for today. A calendar runs from salary date to salary date, with each day marked saved (green ●), on budget (grey ○) or overspent (red ◆). Tapping a day shows its spends, budget and result, with "Cover with savings" for an overspent day. The Dashboard shows where the money went. The month statement explains every change to the budget during the month. The Transactions list can be searched and filtered. **Owner sign-off question: "is the app fully usable with manual entries?"**
- **In scope:**
  - **F-010 Home summary:**
    - The top summary: Salary · Fixed · Spent so far · Saved this month · Overspent · Left (README §2).
    - A **Today card**: today's budget, spent, "₹210 left today" or overspent (D-039).
    - It replaces Phase 2's simple "This month" card and Today line on Home.
    - It covers the shortfall month ("−₹1,000 this month", D-036/D-043), the mid-month first month (D-034/D-042), and the empty and error states.
  - **F-011 Calendar:**
    - The budget month from salary date to the day before the next salary date, spanning two calendar months where needed.
    - Day cells with the ledger marks ● ○ ◆ plus colour and spent amount (design system §5), a **ring on today**, and future days shown as not yet happened.
    - Days before the first budgeted day of a mid-month install are not budgeted (D-034).
    - Past budget months can be viewed. Every day cell has a full screen-reader sentence ("9 November, spent ₹620, saved ₹210").
  - **F-012 Day details:**
    - The chosen day's spends, budget and result, opened from the calendar and from Home's Today card.
    - **"Cover with savings"** on an overspent past day, using the engine rules (never more than the pot holds; D-040 note when a later edit shrinks the pot).
    - Add, edit and delete a spend for that day, reusing the F-009 flows.
  - **F-013 Dashboard:**
    - Spending by category for the month and for a chosen day.
    - Highest-spending day, average daily spend, and days saved vs on budget vs overspent.
    - **It must read well when almost everything is "Other"**, because categories are only manual or "Other" until Phase 4's auto-categories. Examples: a single-category state, a one-line hint that categories become automatic later, and no empty-looking charts.
  - **F-014 Month statement** (D-037):
    - Each budget period of the month with its dates, the values in force (salary, target, fixed costs), its daily budget and its totals.
    - What changed and when (for example "13 Nov: salary changed to ₹35,000 → ₹552/day"), plus whole-month totals that add up exactly with the D-038/D-046 rounding.
    - Available for the current month so far and for past months. **PDF export is not in this phase.**
  - **F-015 Transactions list** (README §11 Phase 3; F-009 §out-of-scope):
    - The full list design with **search** (note, amount) and **filters** (date range, category).
    - Editing a spend's category from the list. Category changes are not "remembered per merchant" until Phase 4.
    - Usable with hundreds of spends.
  - All screens work in the four themes, at large font sizes and in landscape (D-030), and use the F-004 help pattern. Each design is shown to the Owner in the chat as it is made (CLAUDE.md rule 8).
  - One Phase 3 commit and push after sign-off and the CEO report, separate from Phases 1 and 2 (CLAUDE.md rules 5 and 9).
- **Out of scope:**
  - SMS reading, auto-categories and "remember my correction" per merchant (Phase 4).
  - Notifications (Phase 5).
  - PDF or Excel export of the statement (later; D-037), and backup or cloud (D-003, D-041).
  - Animations beyond the basic transitions, first-time hints beyond the Phase 1 pattern, and the "How this app works" page (Phase 6).
  - **Any change to how money is calculated.** Phase 3 only displays the engine's numbers. A new money rule goes back to F-006 and to the Owner.

## Features in this phase *(CEO + Product Manager)*
| ID | Feature | Doc | Plan | Tests | Status |
|---|---|---|---|---|---|
| F-010 | Home summary | [docs/features/F-010-home-summary.md](../docs/features/F-010-home-summary.md) | [plans/F-010-home-summary.md](F-010-home-summary.md) | [tests/F-010-home-summary.md](../tests/F-010-home-summary.md) | Done |
| F-011 | Calendar | [docs/features/F-011-calendar.md](../docs/features/F-011-calendar.md) | [plans/F-011-calendar.md](F-011-calendar.md) | [tests/F-011-calendar.md](../tests/F-011-calendar.md) | Done |
| F-012 | Day details & cover with savings | [docs/features/F-012-day-details.md](../docs/features/F-012-day-details.md) | [plans/F-012-day-details.md](F-012-day-details.md) | [tests/F-012-day-details.md](../tests/F-012-day-details.md) | Done |
| F-013 | Dashboard | [docs/features/F-013-dashboard.md](../docs/features/F-013-dashboard.md) | [plans/F-013-dashboard.md](F-013-dashboard.md) | [tests/F-013-dashboard.md](../tests/F-013-dashboard.md) | Done |
| F-014 | Month statement | [docs/features/F-014-month-statement.md](../docs/features/F-014-month-statement.md) | [plans/F-014-month-statement.md](F-014-month-statement.md) | [tests/F-014-month-statement.md](../tests/F-014-month-statement.md) | Done |
| F-015 | Transactions list (search & filter) | [docs/features/F-015-transactions-list.md](../docs/features/F-015-transactions-list.md) | [plans/F-015-transactions-list.md](F-015-transactions-list.md) | [tests/F-015-transactions-list.md](../tests/F-015-transactions-list.md) | Done |
| F-016 | Money back (manual refund entry) (D-054) | [docs/features/F-016-money-back-entry.md](../docs/features/F-016-money-back-entry.md) | [plans/F-016-money-back-entry.md](F-016-money-back-entry.md) | [tests/F-016-money-back-entry.md](../tests/F-016-money-back-entry.md) | Done |
| F-017 | Safe to spend (per day) (D-056, formula D-058) | [docs/features/F-017-safe-to-spend.md](../docs/features/F-017-safe-to-spend.md) | [plans/F-017-safe-to-spend.md](F-017-safe-to-spend.md) | [tests/F-017-safe-to-spend.md](../tests/F-017-safe-to-spend.md) | Done |

*Owner additions (2026-11-11, D-053..D-056):* cover Undo/Remove is in F-012 §2.5; the Add/Edit category picker is in F-015 §2.4a; manual refund entry is **F-016**; Safe to spend is **F-017** (formula option A confirmed, D-058). F-016 and the F-015 picker both change the F-009 editor, so the Project Manager sequences them.

*Dependencies (for the Developer's build order):*
- Every Phase 3 feature reads its numbers from **F-006** (engine: day results, savings pot, cover, period totals) and its data from **F-007** (repositories and providers), so no Phase 3 code starts before both exist.
- F-010 replaces parts of F-008/F-009's Home and Today line. F-012 reuses F-009's add/edit/delete flows. F-015 replaces the F-009 list. F-014 needs F-006's per-period history (D-037). F-013's category totals depend on F-009's category decision (AC-14).
- Within the phase, F-011 and F-012 go together (tap a day → details). F-010, F-013, F-014 and F-015 can run as parallel tracks on separate folders (D-033), with shared files sequenced by the Project Manager.

## Questions to settle during planning *(CEO)*
- **Owner, if they become money rules:** **refunds** (for example a cancelled order) counted as negative spends or not (F-009 suggestion). This is Phase 3 or 4 and touches money, so it is the Owner's call (WORKFLOW "Escalate to Owner").
- **Team (Product Manager / Project Manager), not the Owner:** how far back past months can be viewed, tie-breaking for "highest day", and whether the in-progress month's statement is labelled "so far".

### Open items for the Project Manager at Phase 3 Gate 1 *(Product Manager, 2026-11-11)*
All Owner questions are answered (D-047, D-053 to D-058), and the feature docs F-010 to F-017 are final. These are team questions only:
1. ~~**F-010 Q-1**~~ **Closed by D-060:** Overspent includes today's live overspend (F-010 AC-6 stays ₹350).
2. **F-013 Q-1:** the average daily spend and the highest day leave **today** out until midnight. Confirm this, or include today labelled "so far". **Closed by D-080 (Gate 1, 2026-11-16): confirmed.**
3. ~~**F-014 rounding note**~~ **Closed by D-062:** the Owner chose "a few rupees" for the note wording.
4. **F-015 past months:** a past month's spend may have its **category** changed, while its amount and date stay read-only. Confirm. **Closed by D-082 (3) (Gate 1, 2026-11-16): confirmed.**
5. **F-009 editor sequencing:** F-016 (Money back switch) and F-015 §2.4a (Category row) both change the F-009 Add/Edit screen. One owner, or a set order, is needed. **Decided (D-074):** T-342, then F-015 T-420, then F-015 T-424, then F-016 T-442. **Closed (Gate 1, 2026-11-16, D-085): one owner at a time, F-012 T-342 then F-015 T-420, T-424, then F-016 T-442; F-016 T-440 and T-441 may start after T-420.**
6. **F-007 delete for savings moves:** F-012 §2.5 (Undo / Remove cover) needs the savings repository to delete a day's savings moves in one transaction. **Approved (D-078):** `cover()` returns the id and `removeCovers` is added (F-012 T-341).
7. **Design system §7.5 additions** (for the Designer): a not-budgeted day cell, a change-day marker, and lakh/crore short forms (`₹1.5L`, `₹10Cr`) (F-011). **Decided:** short forms approved by the Owner (D-073); not-budgeted label with weekday and grid gutters at most 14 dp (D-075, T-310); reviewed at Gate 2 (T-313).

## Carried forward *(from Phase 2)*
- Owner money and display rules apply on every Phase 3 screen: D-034 (mid-month remaining days), D-035 (leftover paise on the first days), D-036/D-043 (shortfall month), D-037 (change history and statement), D-038/D-046 (whole rupees rounded toward zero, so every line adds up), D-039 (today's saving joins the pot at midnight), D-040 (newest covers reduced first) and D-042 (fixed costs still to pay).
- Privacy: database protection per D-041 and the phone-to-phone transfer per D-045. Phase 3 adds no network use and no permission.
- **F-009 category decision** (AC-14) feeds F-013 and F-015.
- **Speed:** the 500-spend checks from F-009 T-220 extend to the calendar, dashboard and list.
- **Regression:** all F-001 to F-009 Regression-yes cases and `tests/REGRESSION.md` stay green after every Phase 3 change.
- Not this phase: final app name and application ID (Phase 7, D-021).

## Build order *(Developer, approved by Project Manager)*
**Batch A: F-010, F-011, F-012, F-017 (Project Manager A, Gate 1 passed 2026-11-16, D-073 to D-079).** Phase 2 is approved and pushed, so building starts now. Developer tracks (D-033): **A** = F-010 with F-017's strip; **B** = F-011 and F-012 together; F-013, F-014 and F-015 are separate parallel tracks (Project Manager B); F-016 follows the editor order. Tasks are on `docs/TASKS.md` (T-300 to T-362 for batch A).
1. **First, in parallel:** T-308 (shared test harness), T-309 (Tester fixes), T-310 (Designer), T-313 (Gate 2) and the pure-domain tasks that need none of them: T-320, T-322, T-340, T-341, T-342, T-360.
2. **Shared month browsing (D-074).** F-011 owns it for **F-011, F-013, F-014 and F-015**: `MonthRepository.watchMonthIndex` (T-322), then `MonthBrowser` and the core `MonthSwitcher` (T-323). These land before the consumers' UI tasks. The F-013, F-014 and F-015 plans use them and write no month index or switcher of their own.
3. **Spend editor, one owner at a time (D-074):** F-012 T-342 (additive) then F-015 T-420 then F-015 T-424 then F-016 T-442. Each is merged green (analyze and the full suite) before the next starts.
4. **Track A (F-010 and F-017):** T-303 (extract `TodayResultLine`, F-009 cases before and after), T-300, T-301, T-360, T-361, T-302, T-304, T-305 (**owns `home_tab.dart`**), T-362, T-307. **T-306** (statement links and the Today card's day details) comes last and **waits for F-014's statement route** (D-077).
5. **Track B (F-011 and F-012):** T-320, T-321, T-322, T-323, T-324, T-340, T-341, T-342, T-343, T-344, T-325, T-345, T-326, T-346. F-011 T-326 and F-012 T-345 edit `home_tab.dart` only after F-010 T-305 is merged.
6. **Gate 3 per task, Gate 4 per feature.** F-010 and F-012 cannot be Done before F-014's route is wired (T-306, F-012 notice); the Phase 3 commit waits for that too.
7. **Batch B (F-013 to F-016):** Project Manager B appends its build order below.

## Phase sign-off *(Project Manager — Gate 5)*
**Signed off 2026-11-24 (D-110). Full record: `docs/reviews/phase-3-signoff.md`. Waiting for the CEO report and the Owner's approval (Gate 6).**
- [x] Every feature Done (doc, plan and test files all complete): F-010 to F-017, INDEX set to Done
- [x] No open High/Critical bugs (none was ever logged above Medium; B-001 to B-006 are all Closed)
- [x] Final full regression green: `tool/check.ps1` ALL CHECKS PASSED on the final code (2026-11-24), 1,298 of 1,298 tests, analyzer clean, domain coverage 100 %, TZ matrix identical, emulator and profile runs by Tester 1, `tests/REGRESSION.md` checks 22 to 31
- Improvements made beyond the original plan: pure display rules moved into the domain layer (D-090); profile-mode speed measurement rule (D-083, D-094, D-100); a 72-mutant mutation pass with every survivor closed or ruled (D-102); a test that reads the real colours of the calendar day numbers; the Home line-break component `ChunkedText` (B-006); Undo for a cover and the Save-before-leave rules; shared month browsing built once (D-074); a Safe to spend line (F-017) and manual refunds (F-016) added by the Owner.
- Open items, none blocking: TalkBack walks by the Owner (D-066, D-097, D-104); grey-scale look (D-096); Partial and accepted cases TC-011-32, -33, -58, TC-014-51, TC-016-35 (D-099, D-107, D-108); Nice to have T-454, T-466, T-469, T-502, T-503, T-504.
