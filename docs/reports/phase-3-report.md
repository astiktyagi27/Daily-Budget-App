# Phase 3 Report — Home summary, calendar, day details, dashboard, month statement and transaction search

*Written by the CEO for the Owner. 2026-11-24.*

**Your approval:** Waiting for you (Gate 6).

## In one line
Your month now has real screens. Home shows the summary, a calendar and a "Safe to spend" line. You can tap a day to see its details and cover an overspent day with savings. The Dashboard shows where the money went, the month statement explains the maths, and Transactions can be searched and filtered. All eight features (F-010 to F-017) are Done, all automated checks pass, no bug is open, and the Project Manager signed the phase off (Gate 5, 2026-11-24). It needs your approval before it is committed and pushed to GitHub.

No money rule changed. Phase 3 only shows the numbers the Phase 2 engine already worked out (the one new figure, Safe to spend, uses your own formula, D-058).

## What was built
Eight features, all Done. There is still no SMS reading; that is Phase 4.

- **F-010 Home summary.** The month at a glance: salary, left, saved, spent, today's budget and result, and a "Month statement" link. When you scroll, the summary shrinks to one line that stays on screen.
- **F-011 Calendar.** One cell per day of the budget month, with the amount and a mark for saved, on budget or overspent. Marks differ by shape as well as colour. Today has a ring, and a day where the budget changed has a small tick. Arrows move between months.
- **F-012 Day details and cover with savings.** Tap a day to see its budget, spends and result. "Cover with savings" is here, with a 6-second Undo and a Remove option.
- **F-013 Dashboard.** Spending by category with bars, the average day, the highest day, and a day-by-day strip. Choose This month, a past month or One day.
- **F-014 Month statement.** Explains in plain sentences how the month's daily budget was worked out, one block for each time salary, target or fixed costs changed. It notes when the total differs from the parts by a few rupees.
- **F-015 Transactions list.** Search by text or amount, and filter by type, category and dates. Past months can be browsed, and you can change a spend's category with an Undo.
- **F-016 Money back.** Enter a refund. It lowers that day's spending ("spent −₹80") and Home says "Includes ₹500 back from refunds".
- **F-017 Safe to spend.** One line on Home: what you can spend per day from now on. Example: ₹19,370 left plus ₹420 spent today, over 22 days, gives ₹899 a day.

## How to see it
1. Start the emulator, then run `flutter run` from the `app` folder.
2. Set up a month, add a few spends, and open **Home**. Check the summary, the Safe to spend line and the calendar. Scroll down to see the summary shrink to one line.
3. Tap a calendar day. Overspend on one day, then "Cover with savings", then Undo.
4. Open **Dashboard** and switch between This month, a past month and One day.
5. Tap **Month statement** on Home. Then add a money-back entry in Transactions and watch Home and the Today line change.
6. In **Transactions**, search for a word or an amount and try the filters.
7. Try the four themes and a very large text size.
8. Evidence (screenshots, logs): `docs/reviews/emulator-phase-3/`. Reviews: `docs/reviews/design-phase-3.md`, `docs/reviews/code-phase-3-tracks-ad.md`, `docs/reviews/code-phase-3-tracks-bc.md`, `docs/reviews/phase-3-signoff.md`.

## Quality
| Item | Result |
|---|---|
| Automated tests | **1,298 passed, 0 failed** (Project Manager's own run, 2026-11-24). `tool/check.ps1` (formatting, strict code checker, tests, coverage, time zones) passed on the final code |
| Code checker issues | 0 |
| Budget-logic coverage | **100%** of lines and branches |
| Time zones | Same results in UTC, US Pacific and India |
| Emulator | All end-to-end flows pass. Layout was walked by hand at 2x text, in landscape and in four themes, with no overflow |
| Stability | The Home screen's flakiest state ran 20 of 20 times clean, with no retries |
| Test strength | A "break the code on purpose" pass: 72 changes, 55 caught at once. The 17 missed were closed with new tests or judged harmless. Later re-checks: 10 of 10 caught |

**Test cases by feature** (Partial = accepted by the Project Manager, Blocked = needs a human with TalkBack)

| Feature | Cases | Pass | Partial | Blocked |
|---|---|---|---|---|
| F-010 Home summary | 59 | 58 | 0 | 1 |
| F-011 Calendar | 66 | 62 | 3 | 1 |
| F-012 Day details | 74 | 73 | 0 | 1 |
| F-013 Dashboard | 60 | 59 | 0 | 1 |
| F-014 Month statement | 60 | 58 | 1 | 1 |
| F-015 Transactions list | 67 | 66 | 0 | 1 |
| F-016 Money back | 47 | 45 | 1 | 1 |
| F-017 Safe to spend | 37 | 36 | 0 | 1 |

**Speed on the emulator** (with about 500 spends; Android release-like "profile" mode, see D-094 and D-100):

| Screen | Result | Limit |
|---|---|---|
| Calendar | 333 ms (month change 184 ms) | 500 ms |
| Home | 190 ms | 1,000 ms |
| Dashboard | 83 to 89 ms | 500 ms |
| Month statement | 110 to 123 ms | 1,000 ms |
| Transactions open and scroll | Smooth, no slow frames | |
| Transactions search | 273 ms | 300 ms (thin margin) |

## Bugs found and closed
Six bugs this phase. None above Medium, none Critical or High, **none open**. Bugs and fixes are listed in `docs/BUGS.md`.

| Bug | What | How it closed |
|---|---|---|
| B-001 | (Phase 1) Back swipe on Settings shows no Home preview | Accepted as is (D-065) |
| B-002 | Dashboard slow on first open in the slow "debug" build | Fast in the real-like build (83 to 89 ms); closed by ruling (D-100) |
| B-003 | A device test stopped after editing a refund | Test script fault, not the app. Fixed, 3 of 3 runs green |
| B-004 | Calendar a little over 500 ms in the first measurement | Measurement corrected (D-094); now 333 ms |
| B-005 | An old Phase 2 test waited for text removed from Home | Test updated, runs green |
| B-006 | Home text broke badly at the largest text size on a small phone | Fixed and checked on the device |

## Decisions you should know about
No new escalations. The team decided these (all in `docs/DECISIONS.md`):
- **D-058 Safe to spend** is your formula: (Left + today's net spend) ÷ days left including today, rounded down.
- **D-073 Short amounts in calendar cells:** ₹12k, ₹1.5L, ₹1.5Cr, so they fit. Full amounts are in the day details and are read out in full by TalkBack.
- **D-076 Safe to spend hides** when today is outside the budget month. It reads "less than ₹1 a day" for tiny amounts, and "Nothing left to spread over the rest of the month" in a shortfall.
- **D-080 Dashboard averages** leave today out until midnight, because today is not finished.
- **D-089 No rubber-band bounce** at the first and last month of the calendar (the design says nothing bounces).
- **D-094 and D-100 Speed is measured in the release-like build.** The limits were not loosened. The slow debug build is not what you will run.
- **D-107 and D-108 Accepted as Partial:** see "Open items".
- **D-062** (from Phase 2, "a few rupees") is now live on the statement.

## Open items (none blocks approval)
- **TalkBack (screen reader) walks, recommended, not required** (D-066, D-097, D-104). An agent cannot drive TalkBack. These 8 Phase 3 cases are Blocked-needs-human: TC-010-42, TC-011-36, TC-012-34, TC-013-31, TC-014-29, TC-015-39, TC-016-24, TC-017-27. The reading order and wording are proven by automated tests, which are green. Steps (about 15 to 20 minutes) are in `tests/PHASE-3-SUMMARY.md`, section 3.3. Phase 1 and Phase 2 TalkBack cases are also still open, as is TC-007-48 (phone-to-phone transfer, needs two phones).
- **Greyscale calendar look (D-096).** A one-minute check on your phone with colour correction set to greyscale: can you tell saved, on budget and overspent apart by shape? Automated tests and a screenshot say yes. Your eyes are the last proof. Optional.
- **Partial, accepted:**
  - TC-011-32, -33, -58: calendar edge cases covered by other tests (D-099).
  - TC-014-51: the 0.6 s highlight when you arrive from "Budget changed on this day". It lands in the right place; the flash was not caught on camera (D-108).
  - TC-016-35: at the largest text on the smallest phone, the Money back switch sits under the keyboard until you scroll. Nothing is cut and Save works (D-107).
- **Nice to have, not planned yet:** T-454, T-466, T-502 (debug-build guard for two speed tests), T-503 (a test of the highlight), T-504 (Designer: tidy the Money back row at 2x text), plus small polish items.

## Risks ahead
- **Thin speed margins.** Search is 273 of 300 ms, and the Transactions list in the slow debug build is 905 of 1,000 ms. If search gets slower, a pre-approved fix (a 200 ms wait before searching) is ready (T-469).
- **Two Phase 3 speed tests fail in the debug build** (they pass in profile). Not a problem for you, but the Developer should add a guard (T-502).
- **Phase 4 will feed real SMS spends into these screens,** so any bug in the Phase 3 display will start to matter with real data. The money engine is unchanged and fully tested (100%).
- **Screen reader use is not proven by a human yet.** See the TalkBack item above.
- **The first build after a clean checkout needs internet** (database library download, carried from Phase 2).

## Decisions needed from you
1. **Question:** Do you approve Phase 3 so the Orchestrator can commit it and push it to GitHub as "Phase 3: Home summary, calendar, day details, dashboard, month statement and transaction search"?
   **Options:** A) Approve. B) Request changes first.
   **Recommendation:** A. Every automated check passes, no bug is open, no money rule changed, and what is left needs a human with TalkBack or your eyes. These are not blockers.
   **If we wait:** Phase 4 (SMS reading) planning can go on, but nothing is published and Phase 4 cannot be signed off.
2. **Optional (no approval needed):** the TalkBack walks and the one-minute greyscale look. A failure would become a bug fixed in Phase 4.

Before the commit, the Orchestrator checks that no secrets or build files are included. It runs `tool/check.ps1` again only if any file under `app/` changed after the sign-off check (2026-11-24 19:12).

## Next phase
**Phase 4 — SMS reading.** The app will read bank SMS and turn them into spends in the same engine and database. It adds the first Android permission, so it needs your approval of the privacy wording. It starts only after you approve Phase 3.
