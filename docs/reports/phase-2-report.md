# Phase 2 Report — Budget engine, database, month setup and manual transactions

*Written by the CEO for the Owner. 2026-11-16.*

**Your approval:** Waiting for you (Gate 6).

## In one line
The app now does real budget maths. You can set up a month by hand, add and edit spends, and see today's budget, spend and result. Everything is saved on the phone and is still there after a restart. All automated checks pass, no bug was found, and the Project Manager signed the phase off (Gate 5, 2026-11-16). It needs your approval before it is committed and pushed to GitHub.

**The sign-off question from the plan: "are the calculations correct using manual entries?"** The answer from the tests is yes. The README examples come out exactly: ₹40,000 over 30 days is ₹1,333 a day; with ₹15,100 of fixed costs it is ₹830 a day; with a ₹20,000 target it is ₹666 a day. You can check this yourself on the emulator (see "How to see it").

## What was built
Four features, all Done. There is still no SMS reading, no calendar and no Dashboard; those come in Phases 3 and 4.

- **F-006 Budget engine (the "brain").**
  - Works out the budget month from the salary day, including salary on the 29th, 30th or 31st when the next month is shorter, and leap years.
  - Spendable money = target minus fixed costs. The daily budget is worked out in exact paise, and the leftover paise are spread over the first days, so the days always add up exactly to the spendable money (D-035).
  - The **Today line**: today's budget, what was spent, and the result: saved, on budget or overspent.
  - **The rules:** saved money collects in a savings pot and is never carried to tomorrow on its own. "Cover with savings" moves money from the pot to an overspent day and cannot take more than the pot holds. Mid-month changes re-spread the remaining days only, and past days keep their numbers (D-037).
  - Mid-month first use divides the money left over the remaining days (D-034). Fixed costs bigger than the target give a warning with the shortfall, not a silent error (D-036).
  - It has no screen of its own and uses no phone features, so it can be tested in isolation. Every line and every branch of it is covered by tests (100%).
- **F-007 Local on-device database.**
  - Salary months, fixed costs, spends and savings-pot movements are stored on the phone, in paise. Nothing is sent anywhere.
  - Every change to salary, target or fixed costs is kept as a dated period (a history), so past days can always be recalculated. This is what the month statement in Phase 3 will use.
  - A startup guard never deletes or downgrades the database file. If the storage is broken, the app shows a plain error screen instead of losing data.
  - The database is protected by Android's private, phone-encrypted app storage, with no extra encryption (your decision D-041). Cloud backup is off.
- **F-008 Month setup screen.**
  - Enter the salary, optionally a lower spending target, and the fixed costs (rent, EMIs, subscriptions, "+ Add item") with edit, delete and Undo. Last month's fixed costs are pre-filled.
  - A live preview shows the daily budget before you confirm. Every field has a label and a short description or (i).
  - The bottom bar follows the keyboard and has Next and Done keys. Works in all four themes and at very large text.
- **F-009 Manual transactions.**
  - **Transactions tab:** a "Today: budget · spent · result" line, this month's spends grouped by day, and an **Add spend** button.
  - **Spend editor:** add, edit and delete a spend (amount, date, note). If an edit or delete would make a "cover with savings" impossible, the app reduces the newest covers first and tells you in a short note (D-040).
- **Home "This month" card.** Home now shows your month: a "Set up my month" prompt on a fresh install, and the month summary once it is set up. The full Home summary, calendar and Dashboard are Phase 3.

**What it means for the app:** the maths and the storage that every later phase depends on are now built, proven and frozen. Phase 3 only has to show these numbers in nicer screens. Phase 4 (SMS) will feed real spends into the same engine and database.

## How to see it
1. Start the emulator in Android Studio, then run `flutter run` in a terminal from the `app` folder.
2. On Home, tap **Set up your month**. Enter a salary of 40000 and a salary day. Check that the preview reads ₹1,333 a day (a full 30-day month). Add fixed costs totalling 15100 and check that it reads ₹830. Turn on "Spend less than my salary", enter 20000, and check ₹666 (adjust the fixed costs as the README example does). Confirm the month.
3. Open the **Transactions** tab. Tap **Add spend**, enter an amount and save. Watch the Today line change between saved, on budget and overspent.
4. Edit and delete a spend. Try a spend larger than today's budget, then "Cover with savings".
5. Close and reopen the app (swipe it away). Your month and spends are still there.
6. Try the other themes, and a very large text size in the phone's settings.
7. Evidence (screenshots, logs): `docs/reviews/emulator-phase-2/`. The Designer's review is in `docs/reviews/design-phase-2.md`, and the Project Manager's code review is in `docs/reviews/code-phase-2.md`.

## Quality
| Item | Result |
|---|---|
| Tasks done | 46 / 54. The other 8 are optional Nice-to-haves (below) |
| Automated tests | 606 passed, 0 failed (`tool/check.ps1`: formatting, code checker with the strict flag, database code generation up to date, test names, all tests, engine coverage, three time zones) |
| Emulator integration tests | 8 of 8 passed on the emulator (Phase 1's 2, plus database persistence, month setup and manual-transactions flows) |
| Test cases | 213 across the four features: 209 Pass, 4 Blocked-needs-human, 0 Fail, 1 Not applicable by decision |
| F-006 Budget engine | 60 cases: 60 Pass, 0 Blocked. 25 / 25 acceptance rules covered |
| F-007 Local database | 48 cases: 47 Pass, 1 Blocked (TC-007-48, phone-to-phone transfer). 19 / 19 rules covered |
| F-008 Month setup | 56 cases: 55 Pass, 1 Blocked (TC-008-26, TalkBack). 20 / 20 rules covered |
| F-009 Manual transactions | 49 cases: 47 Pass, 1 Blocked (TC-009-22, TalkBack), 1 N/A. 19 / 19 rules covered |
| Bugs found / fixed / still open | 0 found in Phase 2 / 0 / 0. (The only bug on the list, B-001 from Phase 1, is closed) |
| Analyzer issues | 0 |
| Engine code coverage | 100% of lines and branches in all 17 engine files |
| Time zones | Same results in three time zones (UTC, US Pacific, India); the engine output is byte-for-byte identical |
| Speed with 500 spends (on the emulator) | Worst case on screen: first row visible in 450 ms. Saving and reading from the database: about 32 and 36 ms |
| Other checks | Fresh install works; the release app asks for no permission of its own; Dim theme and landscape checked on the device |

## Improvements beyond the plan
*(From the Project Manager and Designer reviews)*
- A full change history for each month (salary, target and fixed costs per period), so past days stay reproducible (D-037).
- Cover reductions are stored in the same step as the edit that caused them, so the pot and the covers can never disagree.
- A startup guard that never deletes or downgrades your database and shows a storage error screen.
- Cloud backup is off, and the phone-to-phone transfer rules were checked against Android's documentation (D-045, D-049).
- The health check (`tool/check.ps1`) gained database code generation, the strict analyzer, 100% engine coverage and a three-time-zone check.
- Property tests that prove, over many random cases, that the daily budgets always add up exactly to the spendable money.
- 500-spend speed tests on the real emulator.
- Two end-to-end flows (month setup, manual transactions) run on the emulator as automatic tests.
- The month setup bottom bar follows the keyboard, with Next and Done keys. The first-time tip sits below the Today card at large text.
- Amounts such as ₹10 crore are accepted and shown correctly (₹10,00,00,000), with an input limit.

## Problems we faced
- **Interrupted runs.** One Developer's database work was stopped halfway by the laptop restart. It was inspected, finished and checked, not restarted from scratch.
- **Missing on-device tests.** At the first test round, the two end-to-end flows did not exist. The Project Manager made them required (D-071), and they now pass.
- **Keyboard covering the setup button.** The pinned bar sat under the keyboard. The Designer decided it should follow the keyboard; it was built and walked on the device (T-248, T-250).
- **Digit grouping while typing.** The design said "₹40,000" would be formatted as you type. That makes the cursor jump, so it was changed (D-069, below).
- **Test helpers.** The speed and layout checks needed several device walks, because the keyboard and 2x text change the layout. All were completed.

## Risks ahead
- **TalkBack (the screen reader) was not run on a real phone** for four Phase 1 cases and two Phase 2 cases. The automated proofs are green. A real-phone check is recommended before Phase 3 puts more content on these screens, not required for approval.
- **Phone-to-phone transfer (TC-007-48)** is proved only by reading the final Android settings file, not by moving data between two phones.
- **The first build after a clean checkout needs internet**, because the database library downloads its SQLite files once (about 7 MB). Later builds work offline.
- **Time zone changed while the app stays open:** the "today" value refreshes when you return to the app or at midnight, not mid-change. Android sends the app to the background to change the zone, so this is not noticeable in normal use (accepted, D-071).

## Decisions needed from you
1. **Question:** Do you approve Phase 2 so the Orchestrator can commit it (Phase 2 files only; Phase 3 files stay out) and push it to GitHub as "Phase 2: Budget engine, database, month setup and manual transactions"?
   **Options:** A) Approve. B) Request changes first.
   **Recommendation:** A. Every automated check passes, there is no open bug, and the open cases need a real phone or a screen reader that an agent cannot drive. Each has a passing automated proof.

**For your information (no action needed unless you disagree):**
- **D-062 "a few rupees".** The month statement's rounding note now reads "Totals use exact amounts, so they can differ by a few rupees from the parts." You confirmed this on 2026-11-16, and the Designer's wording change (T-227) is done.
- **D-063 `integration_test` dev dependency.** The testing package that ships with Flutter. It now holds the 8 emulator tests. It is not in the released app. You were told about it in Phase 1.
- **D-064 Permission line.** The release app asks for no permission itself (no internet, SMS or notifications). One extra internal line from an Android library appears in the built file and only this app can use it (carried from Phase 1, still true).
- **D-065 Back-preview wording.** On Dashboard, Transactions and Settings the back chip alone is acceptable (carried from Phase 1).
- **D-066 Sign-off with TalkBack cases open.** Applies the same way in Phase 2 (D-071). You may overrule this.
- **D-069 Amounts shown as typed.** While you type an amount, the field shows the digits as typed (no commas). The grouped amount (for example ₹40,000) appears in the preview line below. Pasting "₹40,000" still works. The reason: grouping while typing moves the cursor and makes TalkBack re-read the field on every key. This is a design change, kept for your feedback.
- **D-070 No `intl`.** The rupee grouping (₹1,00,00,000) and the date names are done by our own small code, tested at every boundary. One less package to maintain and no language data to load at start-up.
- **D-071 and D-072 Rulings.** The Project Manager's Gate 4 rulings: the two emulator flow tests were required and are now done; the blocked cases may stay open at sign-off on the same terms as D-066; two small Low observations were accepted (the "Next" key after the salary skips the "Spend less than my salary" switch; at 2x text with the first-time tip showing, the Add spend button sits over the lower part of the tip, never over the Today line).
- **New wording lines (shown, not escalated).** For a first setup that starts partway through the month, the preview says "Enter the money you have left to see your daily budget" and the bottom bar says "Enter how much you have left". The spend editor can say "Pick a day this month, up to today." if the phone clock moves while you add a spend. Tell the team if you want different words.
- **No count-up change.** The design said the daily amount would roll to its new value over about half a second as you type your salary. It now changes at once, because the preview must be right on every keystroke. The roll still happens on the Transactions Today line after you save a spend.
- **Android 16 phone-to-iPhone transfer.** The backup rules cover Android-to-Android moves (D-045, D-049). Android 16's newest "move to an iPhone" transfer is a separate switch we did not set, so on those phones the data might be offered if you start such a move yourself. It never goes to a server. An extra setting could block it. **Do you want it blocked?** It is a small change, and not needed for this approval.

## Open items (none blocks approval)
- **TC-007-48:** phone-to-phone transfer. Blocked on the emulator, which has no transfer test channel. The cloud half passes, and the transfer rules are proved by the merged settings file (TC-007-19). A real two-phone transfer is for you to try if wanted.
- **TalkBack, Phase 2:** TC-008-26 (month setup, including the Back arrow and the item remove x) and TC-009-22 (Transactions and spend editor). Blocked-needs-human. Widget-test proofs and the accessibility tree dump are green.
- **TalkBack, Phase 1 (D-066):** TC-003-03 step 4, TC-003-18, TC-004-04 and TC-004-07's focus check. The exact steps are in [`tests/PHASE-1-SUMMARY.md`](../../tests/PHASE-1-SUMMARY.md), under "TalkBack cases for the Owner on a real phone" (about 15 minutes). Write Pass or Fail and what TalkBack said. A failure becomes a bug fixed in Phase 3.
- **Nice-to-haves (all To do, none needed now):**
  - T-221: a "numbers check" table of every day's budget, spent and result.
  - T-222: automatic snapshot of the database before a future migration.
  - T-223: Home card could also show the earlier daily budget after a mid-month change (Phase 3 input).
  - T-234 to T-237: four small layout points at 2x text size (theme picker scroll cue, tour text cut off, Transactions label height, tour ledger width).
  - T-242: small code tidy-ups (the dock's own wording constant, a shared tooltip helper).

## Not part of this approval
Phase 3 planning documents already exist in the working folder (feature docs F-010 to F-017, the Phase 3 overview and the Phase 3 screen designs, as you allowed in D-033). They are **not** part of this approval and **not** signed off. The Phase 2 commit will contain only Phase 2's files. The three shared records (the feature index, the task list and the decision list) carry both phases' lines, so their diffs will be checked before committing.

## Next phase
**Phase 3 — Calendar, Dashboard and Home figures:** real content on Home, Calendar, Dashboard and the Transactions list with search and filter, plus the month statement. It builds on the numbers and storage finished here. Phase 3 starts being signed off only after you approve Phase 2.
