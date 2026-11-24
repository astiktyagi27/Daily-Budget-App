# Test Cases — F-017: Safe to spend (per day)

| | |
|---|---|
| **Feature doc** | [`docs/features/F-017-safe-to-spend.md`](../docs/features/F-017-safe-to-spend.md) (final Spec, 11 ACs; formula option A confirmed by the Owner, D-058; D-038, D-048, D-050, D-056 (3) applied) |
| **Plan** | [`plans/F-017-safe-to-spend.md`](../plans/F-017-safe-to-spend.md) (Draft, read 2026-11-16 **after** these cases were written; its names win: `safeToSpendFrom` (pure core) and `safeToSpendPerDay(MonthResult)` (D-076 (4)), sealed `SafeToSpend`, `safe_to_spend_strip_test.dart`, `safe_to_spend_scope_test.dart`. Its §6 proposes one TC per AC; **this file is authoritative** and the AC → TC map is §2.4. The **Plan task** column of §2.4 is filled from plan §6 for the Project Manager to confirm at Gate 1) |
| **Design** | [`docs/design/screens/home-summary.md`](../docs/design/screens/home-summary.md) H-1, §4 part 6, §7, §11, §12 |
| **Author** | Tester (written **before** development, to be approved by the Project Manager at Gate 1) |
| **Status** | Approved at Gate 1 (Project Manager A, 2026-11-16); Tester fixes tracked in T-309 and T-312 (see the plan, section 10); Step 8 run 2026-11-21/23 (Tester 1): see section 4; Gate 4 report in section 5 (Conditional Pass) |
| **Change history** | 2026-11-16 (Tester, Step 4): first version, TC-017-01 … TC-017-36 |
| | 2026-11-16 (Tester, T-309, Gate 1 fixes): two-layer function naming (`safeToSpendFrom` and `safeToSpendPerDay(MonthResult)`, D-076 (4)) applied to the cases; TC-017-35 and -36 marked decided (D-076 (1), (2)); new TC-017-37 (engine-result layer); §2.3 notes 7 and 8 and §2.4 updated |
| | 2026-11-19 (Tester, Track A corrections; the engine is right): TC-017-30 (c) salary day 29 in 2028 gives the month 29 Feb – 28 Mar (29 days): `₹858 a day · 29 days left` and `₹889 a day · 28 days left`; TC-017-36 (c) is the new-month state (F-010 TC-010-36), not an unbudgeted day |
| | 2026-11-23 (Tester 1, Step 8): results recorded in sections 4 and 5 (check run 1285 tests green, emulator regression, device checks on A13) |

## 0. How to run these cases

**Environment and shared definitions:** as F-010 §0 (data sets **A13**, **A13c300**, **S8**, **M20** (the canonical shared seed, `phase3_fixtures` `m20`), **F12**, the harness list and the harness additions), which uses F-002 §0 (**T5**, **Small**, **X1/X2**), F-007 §0 (**[MEM]**), F-008 §0 (**Today(d)**, `findCopy`) and F-009 §0. The real F-006 engine feeds the function; nothing is faked except the repositories in widget tests. **This feature is a new money figure**, so every worked number below is an integer-paise literal copied from F-017 §2.2 or derived by hand and cross-checked in the "Check" column (budgets of the days left + savings pot − uncovered overspend − shortfall = Left + today's net spend).

**The functions (two layers, Gate 1, D-076 (4)).** (1) The pure core `safeToSpendFrom({required Paise left, required Paise todayNetSpend, required int daysLeft})` in `lib/domain/budget/safe_to_spend.dart`: raw numbers in, a `SafeToSpend` out; a `daysLeft` below 1 counts as 1; it classifies by the amount to spread (Left plus today's net spend). The cases that pass raw numerators and days (TC-017-01, -08, -10, -12, -14, -17, -18, -19) call this one. (2) `safeToSpendPerDay(MonthResult)` reads `totals.left`, today's `netSpent` and the days from today to the month end, calls the core, and returns `SafeToSpendUnavailable` when today is not a budgeted day. The cases that start from an engine result (TC-017-02, -03, -05, -22, -37) call this one. **Names:** the Tester's `perDay(Paise)`, `lessThanRupee` and `nothingLeft` are the plan's `SafeToSpendAmount(perDay, daysLeft)`, `SafeToSpendUnderRupee(daysLeft)` and `SafeToSpendNothingLeft`; the plan adds `SafeToSpendUnavailable` (line hidden). The plan's names win in the code; the expected values below do not change. **Days left** = the number of days from today to the month's last day, inclusive, at least 1.

**Additional definitions**

| Name | Meaning |
|---|---|
| **A13 / A13c300 / S8 / M20 / F12** | As F-010 §0 (A13: Left 19,37,000, today spent 42,000, 22 days left) |
| **A13 +410** | A13 plus a spend of 41,000 on 13 Nov (today's spend 83,000, Left 18,96,000) |
| **A14** | A13 with the clock at 14 Nov, nothing spent on 14 Nov (Left 19,37,000, today's spend 0, 21 days left) |
| **E2 day 1** | E2, Today(5 Nov), no spends: Left 24,90,000, 30 days left |
| **E2 last** | E2, Today(4 Dec), no spends in the month: saved 29 days × 83,000 = 24,07,000, Left 24,90,000, 1 day left |
| **OV5** | E2; 5 Nov spent 1,83,000 (overspent 1,00,000), Today(6 Nov), nothing spent today: Left 23,07,000, 29 days left |
| **S8-refund** | S8 plus money in of 3,00,000 on 7 Nov (7 Nov saved 3,00,000); Today(8 Nov), nothing spent today: Left 1,80,000, 27 days left |
| **Home states** | The shared P3 Home states of F-010 §0 |

**Test files** (proposals): `test/domain/budget/safe_to_spend_test.dart` (pure), `test/features/home/safe_to_spend_strip_test.dart`, `test/architecture/safe_to_spend_scope_test.dart`, `test/a11y/phase3_screen_sweep_test.dart` (shared with F-010).

## 1. Test cases
Types: **Auto-unit** · **Auto-widget** · **Auto-integration** · **Manual** (incl. **Manual (command)**).
Automated tests include the TC ID in their name, e.g. `test('TC-017-01 example A gives 89,954 paise', …)`.
**Regression = yes** means the case is re-run in every full regression (automated cases always are; mark important manual cases yes).
The on-screen line is `Safe to spend` (label) + value `₹899 a day · 22 days left` inside the strip on Home's summary card.

| ID | AC | Scenario | Test data | Steps | Expected | Type | Automated test | Regression |
|---|---|---|---|---|---|---|---|---|
| TC-017-01 | AC-1 | Example A: the domain function returns 89,954 paise | `left` 19,37,000; `todayNetSpend` 42,000; `daysLeft` 22 | Call `safeToSpendFrom` | `perDay(Paise(89954))` (19,79,000 ÷ 22 = 89,954.54, rounded **down**, not 89,955). Check: 22 × 83,000 = 18,26,000 + pot 2,00,000 − overspent 47,000 = 19,79,000 | Auto-unit | `TC-017-01 example A gives 89,954 paise` (`test/domain/budget/safe_to_spend_test.dart`) | yes |
| TC-017-02 | AC-1 | Example A from the real engine result | A13 through `computeMonth` and `safeToSpendPerDay(MonthResult)` (the engine-result layer) | Compute | `perDay(Paise(89954))` with days left 22 (13 Nov – 4 Dec); the inputs read from the result are Left 19,37,000 and today's net 42,000 | Auto-unit | `TC-017-02 the helper reads left today and days from the month result` (`test/domain/budget/safe_to_spend_test.dart`) | yes |
| TC-017-03 | AC-1 | The line on Home under the hero line **[FAKE]** | A13; Today(13 Nov) | Pump Home; read the summary card | Strip with label `Safe to spend` and value `₹899 a day · 22 days left`, directly under the day line `₹830/day · 5 Nov – 4 Dec` (design H-2); the amount in ink (`textPrimary`, never green or red), `· 22 days left` in `textSecondary`; an (i) | Auto-widget | `TC-017-03 home shows the safe to spend line for example A` (`test/features/home/safe_to_spend_strip_test.dart`) | yes |
| TC-017-04 | AC-2 | Stable during the day: a ₹410 spend leaves the line unchanged **[FAKE]** | A13 then A13 +410 | Add a spend of ₹410 for 13 Nov through F-009; read | Line still `₹899 a day · 22 days left`; Today card now `on budget` (spent ₹830, ○); Left `₹18,960`. The amount does not animate (no count-up) | Auto-widget | `TC-017-04 todays spending does not move the line` (`test/features/home/safe_to_spend_strip_test.dart`) | yes |
| TC-017-05 | AC-2 | The same invariant in the function (property) | A13 data; today's spend raised in steps 0, 1 paisa, 100, 41,000, 5,00,000, 19,37,000 (Left falls by the same amount each time) | Call `safeToSpendPerDay(MonthResult)` after each | Always 89,954 paise (numerator Left + today's spend stays 19,79,000) while Left ≥ 0; the property is run over `Random(2026)` for 200 random spends and 200 random day positions: for any spend `s` added today, the figure is unchanged | Auto-unit | `TC-017-05 spending today never changes the figure` (`test/domain/budget/safe_to_spend_test.dart`) | yes |
| TC-017-06 | AC-3 | Covers do not change it **[FAKE]** | A13; then a cover of 30,000 on 11 Nov | Read the line | Still `₹899 a day · 22 days left`; also after a partial cover of 10,000 and after Undo / Remove (F-012). The function input Left is 19,37,000 in all four states | Auto-widget | `TC-017-06 a cover leaves the line unchanged` (`test/features/home/safe_to_spend_strip_test.dart`) | yes |
| TC-017-07 | AC-4 | Next day: 92,238 and 21 days **[FAKE]** | A14: A13, clock moved to 14 Nov 00:01, app resumed, no new spends | Read the line | `Safe to spend ₹922 a day · 21 days left` (19,37,000 ÷ 21 = 92,238.09 → 92,238 paise). Check: 21 × 83,000 = 17,43,000 + pot 2,41,000 − overspent 47,000 = 19,37,000 | Auto-widget | `TC-017-07 the line moves at midnight` (`test/features/home/safe_to_spend_strip_test.dart`) | yes |
| TC-017-08 | AC-4 | Next day in the function | `left` 19,37,000; today's net 0; 21 days | Call | `perDay(Paise(92238))` | Auto-unit | `TC-017-08 example A tomorrow gives 92,238 paise` (`test/domain/budget/safe_to_spend_test.dart`) | yes |
| TC-017-09 | AC-5 | Day one equals the daily budget **[FAKE]** | (a) E2 day 1, Today(5 Nov). (b) F12 on 10 Nov with nothing spent (first use) | Read the line | (a) `₹830 a day · 30 days left` (24,90,000 ÷ 30 = 83,000). (b) `₹996 a day · 25 days left` (24,90,000 ÷ 25 = 99,600) | Auto-widget | `TC-017-09 first day equals the daily budget` (`test/features/home/safe_to_spend_strip_test.dart`) | yes |
| TC-017-10 | AC-5 | Day one in the function | (24,90,000, 0, 30) and (24,90,000, 0, 25) | Call | 83,000 and 99,600 paise | Auto-unit | `TC-017-10 day one figures equal the day budget` (`test/domain/budget/safe_to_spend_test.dart`) | yes |
| TC-017-11 | AC-6 | Mid-month change, example M **[FAKE]** | M20; Today(20 Nov) | Read the line | `Safe to spend ₹704 a day · 11 days left` (Left 6,90,000 + today's net spend 85,000 = 7,75,000 ÷ 11 = 70,454.5); the day line says `₹552/day · 1 – 30 Nov` (higher than the budget because of earlier savings); today is overspent (`spent ₹850 · overspent ₹297`) and the line does not move for it | Auto-widget | `TC-017-11 two period month gives 704 a day` (`test/features/home/safe_to_spend_strip_test.dart`) | yes |
| TC-017-12 | AC-6 | Example M in the function | M20 engine result: Left 6,90,000; today's net spend 85,000; 20 – 30 Nov = 11 days | Call | `perDay(Paise(70454))` (7,75,000 ÷ 11 = 70,454.5). Check: 11 × 55,222 = 6,07,442 + pot 1,91,558 − uncovered overspend on ended days 24,000 (6 Nov after its cover; today's 29,778 is not an ended day) = 7,75,000 | Auto-unit | `TC-017-12 example M gives 70,454 paise` (`test/domain/budget/safe_to_spend_test.dart`) | yes |
| TC-017-13 | AC-7 | Nothing left: shortfall month **[FAKE]** | S8; Today(8 Nov) | Read the strip | The value line is `Nothing left to spread over the rest of the month.` (`textPrimary`, no amount, no `a day`, no `days left`) | Auto-widget | `TC-017-13 shortfall month shows nothing left` (`test/features/home/safe_to_spend_strip_test.dart`) | yes |
| TC-017-14 | AC-7 | The numerator at its edges (D-050) | Numerator (paise) with 1 day left: −1,20,000 · −1 · 0 · 1 · 50 · 99 · 100 · 101 · 199 · 200 | Call | `nothingLeft` for −1,20,000, −1 and 0; `lessThanRupee` for 1, 50, 99; `perDay(100)` (₹1) for 100 and 101; `perDay(199)` and `perDay(200)` (shown `₹1` and `₹2`) | Auto-unit | `TC-017-14 the line switches from nothing to less than a rupee to an amount` (`test/domain/budget/safe_to_spend_test.dart`) | yes |
| TC-017-15 | AC-7 | Less than ₹1 on the card **[FAKE]** | A numerator of 50 paise with 1 day left: E2 with spends so that on 4 Dec Left + today's spend = 50 (spend 24,89,950 paise over the month) | Read the strip | `less than ₹1 a day · 1 day left` (so the line reads `Safe to spend less than ₹1 a day · 1 day left`); `1 day left` singular | Auto-widget | `TC-017-15 less than one rupee a day and one day left` (`test/features/home/safe_to_spend_strip_test.dart`) | yes |
| TC-017-16 | AC-8 | Money back on a past day raises it at once **[FAKE]** | A13; add money in 50,000 dated 12 Nov (F-016, `addMoneyInTo`) | Read the line | `₹922 a day · 22 days left` (Left 19,87,000 + 42,000 = 20,29,000 ÷ 22 = 92,227.27 → 92,227 paise); Left on the card `₹19,870` | Auto-widget | `TC-017-16 a refund on a past day raises the line at once` (`test/features/home/safe_to_spend_strip_test.dart`) | yes |
| TC-017-17 | AC-8 | Money back in the function | (19,87,000, 42,000, 22) | Call | `perDay(Paise(92227))` | Auto-unit | `TC-017-17 refund example gives 92,227 paise` (`test/domain/budget/safe_to_spend_test.dart`) | yes |
| TC-017-18 | AC-9 | Integer maths, rounding down, never divides by zero | The table below plus `daysLeft` 0 and −3 | Call | (left + today → days = paise): 19,79,000 / 22 = 89,954 · 19,37,000 / 21 = 92,238 · 24,90,000 / 30 = 83,000 · 24,90,000 / 25 = 99,600 · 7,75,000 / 11 = 70,454 · 20,29,000 / 22 = 92,227 · 23,07,000 / 29 = 79,551 · 24,90,000 / 1 = 24,90,000 · `daysLeft` 0 or −3 is treated as 1 (never an exception, never a division by 0) | Auto-unit | `TC-017-18 results are exact integers rounded down and days left is at least one` (`test/domain/budget/safe_to_spend_test.dart`) | yes |
| TC-017-19 | AC-9 | ₹10 crore amounts are exact | `left` 10,00,00,00,000 paise (₹10 crore); today 0; 22 days | Call | `perDay(Paise(454545454))`, shown `₹45,45,454 a day` (exact integer division, no float error) | Auto-unit | `TC-017-19 ten crore is exact` (`test/domain/budget/safe_to_spend_test.dart`) | yes |
| TC-017-20 | AC-9 | No `double`, no `num`, no `/`, only `domain` imports | `lib/domain/budget/safe_to_spend.dart` | Automated guard (extends `domain_purity_test.dart`) | The file uses `~/` and `%` only: no `double`, `num`, `/`, `.round`, `.floor`, `.ceil`, `.toDouble`, `toStringAsFixed`; imports only `lib/domain`; no Flutter, clock or database import | Auto-unit | `TC-017-20 safe to spend is pure integer maths in the domain layer` (`test/architecture/domain_purity_test.dart`, extended) | yes |
| TC-017-21 | AC-9 | 100 % branch coverage (D-048 (10)) | `flutter test --branch-coverage test/domain/` then `tool/domain_coverage.ps1` | Run the command; read `coverage/lcov.info` for the new file | For `lib/domain/budget/safe_to_spend.dart`: `BRH == BRF` and `LH == LF`. Record the numbers. Any uncovered branch is a Fail | Manual (command) | — | yes |
| TC-017-22 | AC-10 | The figure changes nothing in the engine output | A13 engine result | Dump `computeMonth` (F-006 `dump`) before; call `safeToSpendPerDay(MonthResult)` three times; dump again | The two dumps are byte-identical (day budgets, results, pot, totals); the function takes values, not a mutable result | Auto-unit | `TC-017-22 computing the figure never changes the engine output` (`test/domain/budget/safe_to_spend_test.dart`) | yes |
| TC-017-23 | AC-10 | Only on Home's summary card **[FAKE]** | A13; Home, Home scrolled (collapsed row), Transactions tab, Dashboard tab, Day details of today, the calendar | Search each for the text `Safe to spend` and its amount | Found exactly once, inside the summary card on Home. **Not** in the Today card, the calendar, the collapsed row, the Transactions Today line, Day details, the Dashboard; F-013 and F-014 are added to the sweep when they are built | Auto-widget | `TC-017-23 safe to spend appears only on the home summary card` (`test/architecture/safe_to_spend_scope_test.dart`) | yes |
| TC-017-24 | AC-11 | Help text and (i) **[FAKE]** | A13, Light, X1 | Tap the strip's (i) | F-004 sheet with `Everything left this month, including your savings pot, spread evenly over the days left (today included). It's a guide: your daily budget doesn't change, and it stays the same all day.`; the (i) has its tooltip and 48 dp target | Auto-widget | `TC-017-24 safe to spend has its explanation` (`test/features/home/safe_to_spend_strip_test.dart`) | yes |
| TC-017-25 | AC-11 | Sweep: themes, text scale, small phone, landscape **[FAKE]** | Home states with the line: A13, A14, F12, M20, S8 (nothing left), less than ₹1, ₹10 crore; T5 × X1/X2 × Small; plus 640 × 360 at X1/X2 in Light and Dim | Render; contrast; tap targets; Overflow check | Wraps without truncation (the value line becomes two lines at X2: `₹899 a day` / `22 days left`, wrapping only at ` · `); the strip uses the `sunken` fill with ink text (contrast ≥ 4.5: Light 14.24, Dark 17.35, Dim 13.12 for the amount); never green or red | Auto-widget | `TC-017-25 safe to spend line passes the theme and text scale sweep` (`test/a11y/phase3_screen_sweep_test.dart`) | yes |
| TC-017-26 | AC-11 | Screen reader sentence **[FAKE]** | A13; semantics on | Read the strip's semantics | One node `Safe to spend, ₹899 a day, 22 days left` and the (i) its own stop; nothing-left variant reads `Safe to spend, nothing left to spread over the rest of the month` (the visible sentence); `1 day left` singular | Auto-widget | `TC-017-26 safe to spend reads as one sentence` (`test/features/home/safe_to_spend_strip_test.dart`) | yes |
| TC-017-27 | AC-11 | TalkBack on the emulator **[EMU]** | TalkBack on; A13 data on the emulator (date 13 Nov 2026) | Swipe from the hero to the ledger | Order hero → its (i) → ⋮ → `Safe to spend, ₹899 a day, 22 days left` → its (i) → ledger; no marks read as words | Manual | — | yes |

## 2. Edge cases
Same columns.

| ID | AC | Scenario | Test data | Steps | Expected | Type | Automated test | Regression |
|---|---|---|---|---|---|---|---|---|
| TC-017-28 | AC-1 | Last day of the month: all of Left plus today's spend | E2 last (Today(4 Dec)); then a spend of 30,000 today | Read the line | `₹24,900 a day · 1 day left` before and after (24,90,000 ÷ 1; after the spend Left 24,60,000 + 30,000); check: today's 83,000 + pot 24,07,000 = 24,90,000 | Auto-widget | `TC-017-28 last day shows everything left` (`test/features/home/safe_to_spend_strip_test.dart`) | yes |
| TC-017-29 | AC-1 | The user who overspent sees the real room **[FAKE]** | OV5; Today(6 Nov) | Read the line and the day line | `₹795 a day · 29 days left` (23,07,000 ÷ 29 = 79,551.7 → 79,551 paise) while the day line says `₹830/day`; check: 29 × 83,000 = 24,07,000 + pot 0 − overspent 1,00,000 = 23,07,000 | Auto-widget | `TC-017-29 an early overspend lowers the room per day` (`test/features/home/safe_to_spend_strip_test.dart`) | yes |
| TC-017-30 | AC-5 | Month lengths and leap years: days left counts the real calendar | (a) Salary day 31 month 31 Jan – 27 Feb 2027, salary 40,00,000 no fixed costs, Today(31 Jan). (b) E2 values, month 30 Jan – 28 Feb 2028, Today(1 Feb 2028) and Today(28 Feb 2028), no spends. (c) E2 values, salary day 29, month 29 Feb – 28 Mar 2028 (29 days), Today(29 Feb) and Today(1 Mar) | Read the line | (a) `₹1,428 a day · 28 days left` (40,00,000 ÷ 28 = 1,42,857). (b) 1 Feb: `₹889 a day · 28 days left` (24,90,000 ÷ 28 = 88,928; check 28 × 83,000 + pot 1,66,000); 28 Feb: `₹24,900 a day · 1 day left`. (c) 29 Feb: `₹858 a day · 29 days left` (24,90,000 ÷ 29 = 85,862.07, so 85,862 paise); 1 Mar: `₹889 a day · 28 days left` (24,90,000 ÷ 28 = 88,928.57, so 88,928 paise; no spends, so Left is unchanged). The leap day counts as a day of the month it belongs to | Auto-widget | `TC-017-30 days left follow the month length and the leap day` (`test/features/home/safe_to_spend_strip_test.dart`) | yes |
| TC-017-31 | AC-7 | Refunds can make a shortfall month positive (F-016) **[FAKE]** | S8-refund | Read the line and the hero | Left `₹1,800`; line `₹66 a day · 27 days left` (1,80,000 ÷ 27 = 6,666.7 → 6,666 paise). Check: budgets 0 + pot 3,00,000 − overspent 20,000 − shortfall 1,00,000 = 1,80,000 | Auto-widget | `TC-017-31 refunds in a shortfall month can give a positive figure` (`test/features/home/safe_to_spend_strip_test.dart`) | yes |
| TC-017-32 | AC-2 | Refund received today does not raise today's figure (start-of-today rule, §4) **[FAKE]** | A13; add money in 50,000 dated today (13 Nov); then add a further money in 50,000 dated 12 Nov | Read after each | After the refund today: Left 19,87,000, today's net spend −8,000 (42,000 − 50,000), numerator 19,79,000: still `₹899 a day · 22 days left`; Today card `spent −₹80 · ₹910 left today`. After the refund dated 12 Nov: `₹922 a day` (TC-017-16 arithmetic on top) | Auto-widget | `TC-017-32 a refund today does not raise the figure until tomorrow` (`test/features/home/safe_to_spend_strip_test.dart`) | yes |
| TC-017-33 | AC-4 | Device date moved back and future-dated spends | A13 plus a spend 50,000 dated 15 Nov; Today(13 Nov) | Read the line | Still `₹899 a day · 22 days left` (future-dated spends are ignored, F-006 AC-13) | Auto-widget | `TC-017-33 future dated spends do not change the figure` (`test/features/home/safe_to_spend_strip_test.dart`) | yes |
| TC-017-34 | AC-10 | Hidden when there is no current month **[FAKE]** | (a) no month. (b) A13 data and Today(5 Dec) with no December month (new month not set up). (c) loading. (d) load error | Pump Home | No `Safe to spend` text in any of the four states (the strip is only on the summary card of a confirmed, current month; a past month is only viewed in the calendar, never in the card) | Auto-widget | `TC-017-34 the line is hidden without a current month` (`test/features/home/safe_to_spend_strip_test.dart`) | yes |
| TC-017-35 | AC-7 | Fewer paise than days: the daily quotient rounds to 0 paise **[decided, D-076 (2)]** | Numerator 10 paise, 22 days left (unit); on Home a month fixture with 22 days left and Left 10 paise | Call; read the strip | **Decided (D-076 (2)): any positive amount to spread reads `less than ₹1 a day`** (classified by Left plus today's net spend being above ₹0, not by the daily quotient): `safeToSpendFrom(10 paise, 0, 22)` is `SafeToSpendUnderRupee(22)` and Home reads `Safe to spend less than ₹1 a day · 22 days left`. `Nothing left to spread over the rest of the month.` appears only when the amount to spread is ₹0 or less (TC-017-14). Numerators 1, 21 and 22 paise over 22 days go the same way (quotient 0 paise, still `less than ₹1 a day`, never `₹0 a day`) | Auto-unit + Auto-widget | `TC-017-35 a tiny amount over many days reads less than one rupee` (`test/domain/budget/safe_to_spend_test.dart`) | yes |
| TC-017-36 | AC-10 | Today is not a budgeted day: the line is hidden (D-076 (1), decided) **[FAKE]** | (a) F12 (first budgeted day 10 Nov) with the device date set back to 8 Nov. (b) A13 data with the device date set back to 2 Nov (before the month). (c) A13 data with Today(5 Dec 2026) while December is not set up and the viewed month is still November (after the month's last day; see TC-017-34 (b)): this is the new-month state, not an unbudgeted day | Pump Home | No `Safe to spend` text (the plan's `Unavailable`); no exception; in (c) Home shows the `Your new month has started` card (button `Set up this month`) in place of the summary and Today cards (F-010 TC-010-36); the rest of Home renders as the engine gives it (F-006 AC-13, D-048 (3)). **Decided (D-076 (1)): hide, not clamp** (clamping would show a number for a day that was never today); the F12 day-one `₹996 a day · 25 days left` is never shown by this path. (a) and (b) are the same state as F-010 TC-010-59 (Today card hidden too); (c) is F-010 TC-010-59 (c) / TC-010-36 | Auto-widget | `TC-017-36 the line is hidden when today is not a budgeted day` (`test/features/home/safe_to_spend_strip_test.dart`) | yes |
| TC-017-37 | AC-10, AC-9 | Two layers: the engine-result layer hides the line, the core never throws (D-076 (4)) | (a) A13 `MonthResult` with today 2 Nov, 13 Nov and 5 Dec 2026 (before, inside, after the month). (b) F12 `MonthResult` with today 8 Nov (before the first budgeted day 10 Nov) and 10 Nov. (c) The core with `daysLeft` 0 and −3 | Call `safeToSpendPerDay(MonthResult)` for (a) and (b); call `safeToSpendFrom` for (c) | (a) `SafeToSpendUnavailable`, `SafeToSpendAmount(89954, 22)`, `SafeToSpendUnavailable`. (b) `SafeToSpendUnavailable`, then on 10 Nov `SafeToSpendAmount(99600, 25)` (F12: Left 24,10,000 after the 80,000 spent that day, plus 80,000 today = 24,90,000 / 25; the 11 Nov spend is future-dated and not counted). (c) treated as 1 day: same result as `daysLeft` 1, no exception, no division by zero. `Unavailable` is returned only by the `MonthResult` layer, never by the core | Auto-unit | `TC-017-37 engine result layer returns unavailable outside the budgeted days` (`test/domain/budget/safe_to_spend_test.dart`) | yes |

### 2.1 Impact on existing features (plan section 8 to confirm)
- **F-010:** the line is part of the summary card (TC-010-03 and -58 check its place; TC-010-33 checks it is not in the collapsed row). A change to the card layout re-runs this file.
- **F-006:** reads `totals.left`, today's net spend and the month end; TC-006-18, -21 (totals), -31 (coverage) re-run. The new file joins the 100 % coverage gate (`tool/domain_coverage.ps1`) and `domain_purity_test.dart`.
- **F-012 / F-016:** covers and money back change Left but (covers) not the figure (TC-017-06, -16, -32).
- **F-013 / F-014:** must not show the line (TC-017-23 gets their screens when they exist).
- **`tests/REGRESSION.md`:** add "Safe to spend ₹899 then ₹922 next day (example A) on the emulator" after Step 8.

### 2.2 Regression
All F-001 to F-009 Regression-yes cases, `tests/REGRESSION.md`, and every F-010 to F-012 case after any change to this function or to the engine totals.

### 2.3 Notes for the Project Manager / Product Manager / Designer
1. **A new money figure, no Owner example beyond §2.2.** Every extra worked number here (TC-017-28 to -31, -15) is the Tester's own arithmetic from the D-058 formula, each with its "Check" line (days × daily budget + pot − overspent − shortfall). The Product Manager should glance at them once; if any disagrees with the Owner's intent it is a spec question, not a test fix.
2. **AC-5 "equals the daily budget on day one"** is exact only when the spendable amount divides evenly (E2: 83,000). With a remainder (salary ₹40,000 over 30 days: days of 1,33,334 then 1,33,333) the figure is the **lower** one, 1,33,333 (₹1,333, the same rupees). TC-017-30 (a) shows it (1,42,857 against 1,42,858 on the first days). Please confirm that is acceptable wording.
3. **AC-9 "100 % branch coverage"** is checked by the command in TC-017-21 (BRH = BRF, LH = LF, D-048 (10)); a `switch` on a sealed result may report no branch (F-006 note). Accepted as in F-006.
4. **AC-7 "less than ₹1" with 1 day left** needs a hand-built month (TC-017-15, a spend of ₹24,899.50). The pure case TC-017-14 carries the weight; the widget case proves the wording.
5. **Edge in the spec (§4) "refunds today do not raise today's figure"** is covered by TC-017-32. It may surprise a user (a refund received today only helps tomorrow); a Designer note, no money change.
6. **Past month:** the spec says "not shown for a past month". Home's card always shows the current month, so the only past-month view is the calendar, which never shows the line (TC-017-23, -34).

7. **Plan questions Q1 and Q2: decided at Gate 1 (D-076).** Q1: today not a budgeted day hides the line (TC-017-36, -37). Q2: any positive amount to spread reads `less than ₹1 a day`, `Nothing left` only at ₹0 or below (TC-017-35, -14). AC-5 wording (D-076 (3)): the figure equals the lowest daily amount when the money does not divide evenly (TC-017-30).
8. **Plan cross-check (2026-11-16):** every AC has a plan task and at least one case. TC-017-20 relies on `domain_purity_test.dart`, which the plan does not list as changed: Developer, extend it (or confirm it already scans every file of `lib/domain/budget/`). **Closed at Gate 1: the row is added to the plan's section 2 and to T-360.**

### 2.4 AC → test case map
| AC | Test cases | Plan task (from plan F-017 §6; Project Manager confirms at Gate 1) |
|---|---|---|
| AC-1 | TC-017-01, -02, -03, -28, -29 | T-360, T-361, T-362 |
| AC-2 | TC-017-04, -05, -32 | T-360, T-362 |
| AC-3 | TC-017-06 | T-360, T-362 |
| AC-4 | TC-017-07, -08, -33 | T-360, T-362 |
| AC-5 | TC-017-09, -10, -30 | T-360, T-362 |
| AC-6 | TC-017-11, -12 | T-360 |
| AC-7 | TC-017-13, -14, -15, -31, -35 | T-360, T-361 |
| AC-8 | TC-017-16, -17 | T-360, T-362 |
| AC-9 | TC-017-18, -19, -20, -21, -37 | T-360 |
| AC-10 | TC-017-22, -23, -34, -36, -37 | T-360, T-362 |
| AC-11 | TC-017-24, -25, -26, -27 | T-361 |

## 3. Regression cases from bugs
Every bug found in this feature adds a case here. It is never deleted.

| ID | Bug | Scenario | Expected | Automated test |
|---|---|---|---|---|
| — | none yet | | | |

## 4. Test runs *(Tester)*
| Run | Date | Build / task | Passed | Failed | Notes |
|---|---|---|---|---|---|
| Step 8 R2 | 2026-11-23 | Tester 1, Gate 3 trees (T-300 to T-362 as they stand) | `tool/check.ps1` ALL CHECKS PASSED: 1285 tests (re-run 2026-11-23; first run 1267 on 2026-11-21), analyzers, domain coverage 100 %, TZ matrix UTC / PST8PDT / IST identical engine dumps | 0 | `docs/reviews/emulator-phase-3/check-run-step8-r2.txt` |
| Step 8 R1 emulator | 2026-11-21 and 2026-11-23 | Emulator-5554, debug and profile builds | See the table "Emulator regression" below | see table | Logs in `docs/reviews/emulator-phase-3/` |
| Step 8 R1 device | 2026-11-21 | Debug APK, A13 seeded into the app database (adb `run-as`, Python sqlite3), clock 13 Nov 2026 10:30 IST (`cmd alarm set-time`) | device checks in the result column | 0 failures in this feature unless a row says Fail | screenshots `s8-*.png` and `uiautomator` dumps |

**Emulator regression (debug = `flutter test integration_test/<file> -d emulator-5554`; profile = `flutter drive --driver=test_driver/integration_test.dart --target=... --profile`):**
| Test | Case | Debug 2026-11-21 (batch / re-run) | Debug 2026-11-23 (fresh boot) | Profile | Result |
|---|---|---|---|---|---|
| `home_500_test` | TC-010-43 | worst 1039 ms (fail) / 17 ms | 14 ms | 0 ms (2026-11-21), 0 ms (11-23) | Pass |
| `calendar_500_test` | TC-011-37 | grid worst 2652 / 1851 ms; change 443 / 479 ms | grid 1768 ms, change 463 ms | grid 515 / 525 / 516 / 495 / 524 ms, 11-23: 548 / 498 / 494 / 517 / 497 ms; change 56-82 ms | **Fail (B-004)**: limit 500 ms, profile worst 525 and 548 |
| `day_details_cover_flow_test` | TC-012-08, -37, -39 | exit 0 (47 s) / n/a | exit 0 (37 s) | n/a | Pass |
| `statement_speed_test` | TC-014-30 | worst 1087 ms (fail, cold) / 745 ms | 667 ms | 123 ms, 110 ms | Pass (profile; debug cold run 1087 ms reported) |
| `dashboard_500_test` | TC-013-32 | finder error (loaded machine) / run 0 723 ms | run 0 1349 ms, runs 1-4 157-213 ms | 89 ms, 83 ms | Debug Fail (B-002), profile Pass |
| `manual_transactions_flow_test` | F-009 flow | exit 0 | exit 0 | n/a | Pass |
| `money_back_flow_test` | TC-016-34 | fails at edit to ₹300 (twice) | fails again | n/a | **Fail (B-003)**, app correct by hand |
| `month_setup_flow_test` | TC-008-18, -27 | fails (twice) | fails | n/a | **Fail (B-005)**: stale Phase 2 test text |
| `persistence_test` | F-007 | exit 0 | exit 0 | n/a | Pass |
| `transactions_500_test` | TC-009-19 | worst 905 ms | 724 ms | n/a | Pass |
| `transactions_search_test` | TC-015-27, -28 | open 830-935 ms; frame limit fails in debug; search worst 304-368 ms (loaded) | open 1267 ms, search 326 ms (cold boot) | open 86-90 ms; scroll worst raster 24 ms (11-21) and 14.7 ms (11-23); search worst 276 / 273 ms, category 57 / 31 ms, dates 52 / 49 ms | Pass in profile |
| `onboarding_flow_test`, `preferences_persistence_test` | F-005, F-002 | exit 0 | n/a | n/a | Pass |

Debug-mode numbers vary a lot with machine load (other test runs were active on 2026-11-21) and with a cold emulator; the profile build is the measurement for the limits, as agreed for TC-015-27/-28. Limits were not loosened. Cold first runs in debug exceed their limits for home (1039 ms), statement (1087 ms) and dashboard (562-1349 ms); they pass in profile.

### Latest run — detailed results
| ID | Result | Evidence / bug |
|---|---|---|
| TC-017-01 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-02 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-03 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-04 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23). Device A13 13 Nov: `₹899 a day, 22 days left`; after a ₹100 spend today still `₹899 a day` (Left ₹19,270); on 14 Nov `₹922 a day, 21 days left` (`docs/reviews/emulator-phase-3/s8-tc017-next-day-922.png`) |
| TC-017-05 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-06 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-07 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-08 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-09 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-10 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-11 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-12 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-13 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-14 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-15 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-16 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-17 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-18 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-19 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-20 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-21 | Pass | `tool/domain_coverage.ps1` (inside check, 2026-11-23): `safe_to_spend.dart L 20/20  B 10/10` |
| TC-017-22 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-23 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-24 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-25 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-26 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-27 | Blocked-needs-human | TalkBack cannot be driven by an agent; steps in `tests/PHASE-3-SUMMARY.md` section 3.3. Partial evidence: the strip is one node `Safe to spend, ₹899 a day, 22 days left` with its (i) `More about Safe to spend`, between the hero and the ledger (uiautomator) |
| TC-017-28 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-29 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-30 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-31 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-32 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-33 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-34 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-35 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-36 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |
| TC-017-37 | Pass | Named automated test green in `tool/check.ps1` (1285 tests, 2026-11-23) |


## 5. Test report to Project Manager *(Gate 4)*
- **Verdict:** **Conditional Pass.** Safe to spend ₹899 a day, 22 days left, unchanged after a ₹100 spend today, ₹922 a day and 21 days left the next day on the device; domain coverage 20/20 lines and 10/10 branches. TC-017-27 is Blocked-needs-human.
- Cases (37): Pass 36, Blocked-needs-human 1. "Pass" = a named automated test green in the check run, plus the device or emulator result where one is written in the row. "Partial" = the behaviour is covered by a green test under another ID, or only part of the case could be run. "Not run" = no automated test carries the ID (rule T-389 item 4). "Blocked-needs-human" = TalkBack (D-066), steps in `tests/PHASE-3-SUMMARY.md` 3.3, not a Gate 5 blocker (Phase 1 precedent).
- ACs covered: all with a case; AC-11 TalkBack blocked (TC-017-27).
- Bugs logged: none.
- Full regression (all automated tests + emulator integration tests): `tool/check.ps1` green (1285 tests (re-run 2026-11-23; first run 1267 on 2026-11-21)); emulator regression has three red integration tests that are not feature-10/11/12/17 app defects (B-003, B-005) or are over their limit (B-004); see section 4.
- Not done by Tester 1: the T-307 20-run flakiness check of the collapsed-row sweep state and the mutation pass of `tests/PHASE-3-SUMMARY.md` section 2 (separate work after the Developers' test additions land); TalkBack cases; a real-phone walk.
- `tests/REGRESSION.md`: key device checks to add (A13 on the emulator: figures, cover 11 Nov ₹300 then Undo then Remove, Safe to spend ₹899 then ₹922 next day, Home to Month statement and day details routes) are listed in `tests/PHASE-3-SUMMARY.md` section 6.

## 6. Project Manager Gate 4 verdict *(Project Manager A, 2026-11-23)*
- **Verdict: Pass** (D-098). 36 of 37 cases Pass; TC-017-27 (TalkBack) is open under D-097 (not a blocker). Device: Safe to spend ₹899 a day with 22 days left, unchanged after a ₹100 spend today, ₹922 a day and 21 days left next day (screenshots `s8-tc017-after-spend-today.png`, `s8-tc017-next-day-922.png`); domain coverage 20/20 lines and 10/10 branches. No bugs.
- **Remaining steps:** Gate 3 of the shared test-only changes (T-501), step 9 (T-500, section 7 of the feature doc), then INDEX Done. INDEX status set to `Testing`.
