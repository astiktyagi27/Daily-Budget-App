# Phase 2 — Budget engine & month setup: Overview

**Status:** Built, tested and signed off by the Project Manager (Gate 5, 2026-11-16); waiting for the CEO report and the Owner's approval.

## Phase goal *(CEO)*
- **At the end of this phase the Owner can:** set up a budget month by hand and check the numbers. That means entering the salary, optionally a lower spending target, and the fixed costs (rent, EMIs, subscriptions, "+ Add item"), then seeing the daily budget before confirming. The Owner can then add, edit and delete spends by hand and see today's budget, spend and result (saved, on budget or overspent). Everything is saved on the phone and still there after a restart. The README §2 examples come out exactly right: ₹40,000 over 30 days gives ₹1,333 a day; with ₹15,100 of fixed costs it gives ₹830 a day; with a ₹20,000 target it gives ₹666 a day. **Owner sign-off question: "are the calculations correct using manual entries?"** (README §11).
- **In scope:**
  - **F-006 Budget engine** (pure Dart in `lib/domain/`, no Flutter imports, 100% branch-tested; STANDARDS §3–4):
    - The budget month runs from the salary date to the day before the next salary date, including salary on the 29th, 30th or 31st when the next month is shorter.
    - Spendable money = monthly target − fixed costs. The target is the salary or a lower amount.
    - The daily budget is in **integer paise**. Leftover paise are spread so that the daily budgets add up **exactly** to the spendable money.
    - Day result = daily budget − spent: saved, on budget or overspent.
    - The **savings pot**: saved amounts collect in the pot and are never carried to tomorrow automatically (D-005). **"Cover with savings"** moves money from the pot to an overspent day and cannot take more than the pot holds.
    - Month totals for the top summary: salary, fixed costs, spent so far, saved, overspent, left.
  - **F-007 Local database** (Drift, D-018): tables for budget months, fixed costs, transactions and savings-pot movements, all money in paise. It includes the first schema version with a migration strategy, repositories in `data/` (the UI never talks to the database directly; STANDARDS §3), and database-failure handling. Database encryption is decided in this feature's plan (see Owner decisions).
  - **F-008 Month setup screen:** salary entered by hand (SMS detection comes in Phase 4), an optional lower spending target, a fixed-costs list with "+ Add item", edit and delete. Last month's fixed costs are pre-filled. A live daily-budget preview is shown before confirming. Every field carries a label and description or (i) using the F-004 help pattern, and the screen works in all four themes.
  - **F-009 Manual transactions:** add, edit and delete a spend (amount, date, note; category picker only if the plan keeps it small, since auto-categories come in Phase 4). A simple list of this month's transactions with a plain "Today: budget · spent · result" line, so the Owner can check the numbers. The full Home summary, calendar and search/filter list come in Phase 3.
  - Edge cases every feature doc and test file must cover (STANDARDS §4):
    - 28-, 29-, 30- and 31-day budget months, and leap years (Feb 29 2028).
    - Salary on the 29th, 30th or 31st, and a following month that has no such day.
    - **Mid-month install**: the app is first used partway through a budget month.
    - **₹0** salary, target, fixed cost or spend, and fixed costs equal to or **larger than** the target (no money left or negative money left).
    - **Huge amounts** (for example ₹10 crore): no overflow, an input limit and readable Indian formatting (₹1,00,00,000).
    - Amounts that do not split evenly (₹40,000 ÷ 30 days) and a sum exact to the paisa.
    - Editing or deleting a past transaction or a fixed cost mid-month, and covering with more than the pot holds.
    - Device date or time-zone changes (India is IST, no daylight saving).
  - Riverpod code generation revisited in the first Phase 2 plan that adds providers (D-027).
  - One phase commit and push after sign-off and the CEO report, separate from the Phase 1 commit (CLAUDE.md rules 5 and 9).
- **Out of scope:**
  - Reading SMS, detecting salary from SMS, auto-categories and bank selection (Phase 4).
  - Calendar, Home top summary, Dashboard and the full transactions list with search and filter (Phase 3). Phase 2 only provides the engine numbers they will show.
  - Notifications (Phase 5).
  - Backup, export, cloud or sync. The data stays on the phone (D-003).
  - More than one bank account, credit cards (D-006) and income other than the salary, unless the Owner decides otherwise below.

## Features in this phase *(CEO + Product Manager)*
| ID | Feature | Doc | Plan | Tests | Status |
|---|---|---|---|---|---|
| F-006 | Budget engine | [docs/features/F-006-budget-engine.md](../docs/features/F-006-budget-engine.md) | [plans/F-006-budget-engine.md](F-006-budget-engine.md) | [tests/F-006-budget-engine.md](../tests/F-006-budget-engine.md) | Plan approved |
| F-007 | Local database | [docs/features/F-007-local-database.md](../docs/features/F-007-local-database.md) | [plans/F-007-local-database.md](F-007-local-database.md) | [tests/F-007-local-database.md](../tests/F-007-local-database.md) | Plan approved |
| F-008 | Month setup screen | [docs/features/F-008-month-setup.md](../docs/features/F-008-month-setup.md) | [plans/F-008-month-setup.md](F-008-month-setup.md) | [tests/F-008-month-setup.md](../tests/F-008-month-setup.md) | Plan approved |
| F-009 | Manual transactions | [docs/features/F-009-manual-transactions.md](../docs/features/F-009-manual-transactions.md) | [plans/F-009-manual-transactions.md](F-009-manual-transactions.md) | [tests/F-009-manual-transactions.md](../tests/F-009-manual-transactions.md) | Plan approved |

## Scheduling with the overlap *(CEO, for the Developer and the Project Manager; D-033)*
- **F-006 can be built straight away, in parallel with Phase 1.** It is pure Dart in `lib/domain/` and needs no new packages, so it touches no Phase 1 file. The domain purity guard TC-001-06 must stay green.
- **F-007, F-008 and F-009 must not touch Phase 1's open files** until Phase 1 is Owner-approved. Those files are startup (`main.dart`, `app.dart`), preferences (`data/preferences/`), Settings, the navigation shell, the shared theme and help components, **and `pubspec.yaml`/`pubspec.lock`** (F-007 adds Drift there). In practice, F-007's own files in `data/database/` and F-008/F-009's screen code can be planned and test-cased now, but adding packages and wiring screens into the shell is scheduled **after Phase 1 is approved**, unless the Project Manager confirms that a specific file is no longer open.
- All Phase 2 planning (feature docs, plans, test cases, Gate 1) may run now. Nothing in Phase 2 is signed off before Phase 1 is approved, and the Phase 1 commit contains only Phase 1 files.

## Decisions the Owner will be asked *(CEO; to be raised from the plans with options and a recommendation)*
**All decided by the Owner on 2026-11-10:** 1 → D-041 · 2 → D-034 (+ D-042) · 3 → D-035 · 4 → D-036 (+ D-043) · 5 → D-037. Related: D-038, D-039, D-040, D-045, D-046. The original questions are kept below for the record.

These touch money calculations or privacy, so they go to the Owner (WORKFLOW "Escalate to Owner"):
1. **Database encryption** (F-007): encrypt the on-phone database or not, weighing the privacy gain against size, speed and the NDK/native-build work.
2. **Mid-month install** (F-006/F-008): split the money over the **remaining** days only, or over the whole month with the earlier days left empty.
3. **Where leftover paise go** (F-006): for example, the first days get ₹0.01 more. Whatever is chosen, the total stays exact.
4. **Fixed costs bigger than the target** (F-006/F-008): block confirming, or allow it and show ₹0 a day with a warning.
5. **Changes mid-month** (F-006/F-008): whether editing the target or fixed costs mid-month re-spreads only the remaining days or the whole month.

## Carried forward *(from the Phase 0 and Phase 1 overviews)*
- **Native SQLite build check:** re-verify that Drift's native SQLite (`sqlite3` 3.x build hooks via `drift_flutter`; never `sqlite3_flutter_libs`, D-018) builds with the NDK now in use, which is Flutter's default 28.2 (D-029, superseding D-025). This belongs in the F-007 plan and tests.
- **Database encryption decision** (above, Owner decision 1).
- **Domain guard, layer direction:** extend TC-001-06 so `domain/` also cannot import `data/` or `features/` (Phase 0 Gate 1 point 12). This fits F-006.
- **Riverpod code generation** revisit (D-027).
- **Logging** (`logging` 1.3.0, D-019) is added in the first feature that logs, and never logs amounts or personal data.
- **Regression:** all F-001 to F-005 Regression-yes cases and `tests/REGRESSION.md` stay green after every Phase 2 change.
- Not this phase: final app name and application ID (Phase 7, D-021).

## Build order *(Developer, approved by Project Manager)*
*Proposed by the Developer, 2026-11-10; **approved by the Project Manager at Gate 1 (2026-11-10)** with the changes in each plan §10. Tasks T-201 … T-223 are in `docs/TASKS.md` (T-212 and T-214 are split into a/b/c parts). Gate 2 approved: `docs/reviews/design-phase-2.md`.*

**Stage A: now, in parallel with Phase 1 (D-033). New files only** under `lib/domain/budget/`, `test/domain/budget/`, `test/architecture/` (a new file) and `tool/` (new scripts).
1. **F-006 T-201 → T-202 → T-203 → T-204 → T-205** (one Developer, in order).
   - *Why first:* every other Phase 2 feature calls the engine for its numbers. It needs no package and touches no Phase 1 file.
   - Its tests (AC-1 … AC-24) prove the money rules before any screen exists.
2. **Approved by the PM (D-052):** the pure parts **T-212a** (`parseAmount`, after T-202), **T-214a** (`SetupDraft`, after T-204) and **T-217** (`TodayLine`, `groupSpendsByDay`, `SpendDraft`, after T-204). They are new `domain/budget/` files.

**Stage B: after Phase 1 is Owner-approved** (or after the PM confirms that the touched files are closed).

3. **F-007 T-206.** All packages in **one** `pubspec` change: Drift, `drift_flutter`, `logging`, `intl`, `drift_dev`, `build_runner`, `integration_test`, plus `flutter pub upgrade sqlite3`.
   - This task also covers the native build check and the new `check.ps1` steps.
   - *Why one change:* `pubspec.lock` is shared, so it should be touched once and verified once.
4. **F-007 T-207 → T-208 → T-209.** Schema, then opening and failure handling, then repositories, providers and fakes.
   - *Why before the screens:* F-008/F-009 widget tests need the repository **fakes** from T-209.
   - In parallel with T-207 … T-209, a second Developer can do **F-008 T-212** (formatters; `intl` is in from T-206).
5. **F-007 T-210** (backup manifest, logs, privacy), then **F-008 T-213** (`todayProvider`, `currentMonthStateProvider`; needs T-209).
6. **Two parallel tracks** (separate folders; shared files `screen_copy.dart` and `test/helpers/pump_app.dart` are edited by one track at a time, the PM sequences them):
   - **Track 1, F-008:** T-214 → T-215 → T-216. *Why:* a month must exist before spends make sense, and T-216 makes Home the entry point.
   - **Track 2, F-009:** T-217 → T-218 → T-219.

   T-215, T-216, T-218 and T-219 use the approved screen specs (Gate 2). Shared widgets come first in **T-212c** (after T-212b), so both tracks build on them. OD-9 is answered (D-057: a late or missed-month setup is a fresh start from today).
7. **F-007 T-211** and **F-009 T-220** last: on-device persistence and the 500-spend speed checks run on the finished screens, followed by the Tester's full regression (F-001 … F-009 and `tests/REGRESSION.md`).

## Phase sign-off *(Project Manager — Gate 5)*
**Project Manager sign-off: 2026-11-16. Phase 2 is NOT approved yet: only the Owner approves (CLAUDE.md rule 5), after the CEO report.**
- [x] Every feature Done (doc, plan and test files all complete): F-006, F-007, F-008, F-009 are Done in `docs/features/INDEX.md`; section 7 of each feature doc is filled in and matches run R5 (606 tests, 8 integration tests).
- [x] No open High/Critical bugs: `docs/BUGS.md` has only B-001 (Low, Closed); no bug was found in Phase 2.
- [x] Final full regression green: `tool/check.ps1` run by the Project Manager on 2026-11-16, ALL CHECKS PASSED (606 tests, domain coverage 100% on 17 files, time-zone matrix UTC / PST8PDT / IST identical); the Tester's run R5 (`tests/REGRESSION.md`, every feature test file, integration 8 of 8 on emulator-5554, backup and permission checks, Dim and landscape device checks) is green. Spot-checked evidence in `docs/reviews/emulator-phase-2/` (`check-run-r5.txt`, `integration-tests-run-r5.log`, `tc-007-33-r5-kill-timing.txt`, `regression-r5-*.txt`, `tc-008-27-r5-*.png`, `tc-009-46-r5-*.png`) matches the recorded results.
- Records current: README tracker and status line, `docs/TASKS.md`, INDEX, `docs/DECISIONS.md` (D-071, D-072).
- Open at sign-off (listed in the CEO report, none blocks it): **TC-007-48** device-to-device transfer (Blocked on the emulator; proved by the merged XML, TC-007-19); **TC-008-26 and TC-009-22** TalkBack walks (Blocked-needs-human; widget-test proofs and the accessibility tree dump are green); the four Phase 1 TalkBack cases (D-066); **D-062** "a few rupees" question (T-227 held); the two accepted Low observations (D-072); Nice to have tasks T-221, T-222, T-223, T-234 to T-237, T-242. A real-phone check of the three Phase 2 manual cases is recommended, not required (D-071).
- Improvements made beyond the original plan: append-only budget period history with fixed costs per period (D-037), so past days stay reproducible; cover reductions and clamps stored in the same transaction as the edit (D-040, D-048); a startup guard that never deletes or downgrades the database file and shows a storage error screen (F-007); cloud backup off and device transfer rules checked against the Android documentation (D-045, D-049); `tool/check.ps1` gained Drift codegen, `dart analyze --fatal-infos`, 100% domain coverage and a three-time-zone matrix (D-068); property tests proving the day budgets always sum exactly to the spendable money; 500-spend speed tests on the device (worst on-screen first row 450 ms); two emulator integration flows (month setup, manual transactions) added at Gate 4 (D-071); month setup dock that follows the keyboard with Next and Done keys, and the first-time tip moved below the Today card at large text (T-248, T-247); Indian digit grouping in the preview line instead of while typing (D-069, D-070).
- **Phase 3 files in the working tree that must stay out of the Phase 2 commit (CLAUDE.md rules 5 and 9):** `plans/phase-3-overview.md`; `docs/features/F-010` to `F-017` (8 files); `docs/design/screens/` `home-summary.md`, `calendar.md`, `day-details.md`, `dashboard.md`, `month-statement.md`, `transactions-search.md`. Files that mix both phases and need a review of the diff before committing (Phase 3 lines to be held back or accepted by the Owner): `docs/features/INDEX.md` (rows F-010 to F-017), `docs/DECISIONS.md` and `docs/TASKS.md` (D-060 to D-062 and T-225, T-227 are Phase 3 related). The Phase 3 plans and test files `plans/F-010` to `F-017` and `tests/F-010` to `F-017` do not exist yet (the INDEX links to them are dangling until Phase 3 Step 3 and 4).
