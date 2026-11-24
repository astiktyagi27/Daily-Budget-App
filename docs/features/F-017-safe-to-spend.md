# F-017: Safe to spend (per day)

| | |
|---|---|
| **Phase** | 3 |
| **Status** | Spec (final, ready for the plan). Formula confirmed by the Owner: option A (D-058). D-038, D-048, D-050 and D-056 (3) are applied |
| **Plan** | [`plans/F-017-safe-to-spend.md`](../../plans/F-017-safe-to-spend.md) |
| **Test cases** | [`tests/F-017-safe-to-spend.md`](../../tests/F-017-safe-to-spend.md) |
| **Tasks** | T-3xx (assigned by the Project Manager at Step 5) |

## 1. What it is *(Product Manager)*
One extra line on Home's summary card (F-010): **`Safe to spend ₹899 a day · 22 days left`**. It answers the question "If I spread everything I have left this month over the days that remain, how much is that per day?". Jupiter, Fi and other Indian money apps show a similar figure.

It is a **guide only**:
- it never changes a day's budget, a day result, the savings pot or any total;
- savings are still never moved into tomorrow's budget automatically (D-005).

It is a **new money figure**. The Owner confirmed its formula as option A (D-058).

**User stories:**
- As a **user who saved earlier in the month**, I want to see how much I could spend per day for the rest of the month if I used everything.
- As a **user who overspent**, I want to see what my per-day room really is now.

## 2. How it behaves *(Product Manager)*

### 2.1 The formula (confirmed, D-058)
**Option A, confirmed by the Owner (D-058):**
```
Safe to spend per day = (Left this month + today's net spend) ÷ days left including today
```
- **Left this month** is the engine's Left (F-006 §2.5): money for the month − spent so far − shortfall.
- **Today's net spend** is added back, so the figure is "the money there was **at the start of today**". It therefore **does not drop as you spend today**: it stays the same all day. Today's own result is shown by the Today card.
- **Days left including today** = today to the last day of the budget month (at least 1).
- Integer paise: the numerator ÷ days, rounded down. It is shown in whole rupees (D-038). If the amount to spread (Left + today's net spend) is above ₹0 but the figure is less than ₹1, it reads `less than ₹1 a day` (D-050), for example 10 paise over 22 days. Only when that amount is ₹0 or below does the line read `Nothing left to spread over the rest of the month.`
- **Why this is the right "everything left" number:** Left already contains the savings pot. Written out (no covers on today):

  `Left + today's spend = budgets of today and the remaining days + savings pot − uncovered overspend on ended days − shortfall`

  So the pot is counted **once**, unpaid overspends are subtracted, and **covers don't change the figure** (a cover moves money from the pot to a day, and both are already in Left).

**Options the Owner compared** (A chosen, D-058):
| | Formula | Example A result | Drawback |
|---|---|---|---|
| **A (chosen, D-058)** | (Left + today's spend) ÷ days left incl. today | **₹899** | — |
| B | (Left + today's spend − savings pot) ÷ days left | ₹808 | Leaves savings out (closer to D-005), but **covering a day raises it** (₹822 after a ₹300 cover), which is confusing |
| C | (Left + savings pot) ÷ days left | ₹971 | **Counts the pot twice** (Left already contains it), so it is ₹72 a day too high, and it drops with every rupee spent today |

### 2.2 Worked examples (option A)
**Example A** (F-010 §2.4: ₹830/day, month 5 Nov – 4 Dec, today Fri 13 Nov, ₹420 spent today, pot ₹2,000, uncovered overspend ₹470):
- 19,370 + 420 = ₹19,790, spread over the 22 days 13 Nov – 4 Dec.
- 19,79,000 ÷ 22 = 89,954 paise (rounded down), shown as **`Safe to spend ₹899 a day · 22 days left`**.
- Cross-check: 22 × 830 = 18,260 + pot 2,000 − overspent 470 = 19,790 ✓.
- **Spending another ₹410 today:** Left falls to ₹18,960, but today's spend rises to ₹830 (18,960 + 830 = 19,790), so the figure is still **₹899**.
- **After covering 11 Nov with ₹300:** Left is unchanged, so the figure is still **₹899**.
- **Tomorrow, Sat 14 Nov** (13 Nov ended at ₹420, nothing spent yet): 19,370 + 0 = 19,370 ÷ 21 = 92,238 paise, so **₹922 a day · 21 days left**. Cross-check: 21 × 830 = 17,430 + pot 2,410 − 470 = 19,370 ✓.

**First day of a normal month** (5 Nov, nothing spent): 24,900 ÷ 30 = **₹830**, equal to the daily budget, as it should be.

**Mid-month first month** (example F, 10 Nov, nothing spent): 24,900 ÷ 25 = **₹996**, equal to the daily budget.

**Mid-month change** (example M = canonical seed M20, 1–30 Nov, today Fri 20 Nov, Left ₹6,900, ₹850 spent today):
- (6,90,000 + 85,000) paise = 7,75,000 paise ÷ 11 days (20–30 Nov) = 70,454 paise (rounded down), so **₹704 a day · 11 days left**.
- The daily budget is ₹552. The extra comes from savings made earlier in the month.

**Shortfall month** (example S, today 8 Nov, Left −₹1,200, nothing spent today):
- The result is ₹0 or below, so the line reads **`Nothing left to spread over the rest of the month.`**

**Last day** (4 Dec): 1 day left, so the figure is all of (Left + today's spend).

### 2.3 Where it shows
- **On Home's summary card** (F-010 §2.2), on its own line under the hero line: `Safe to spend ₹899 a day · 22 days left`, with an (i).
- **Not** in the Today card, the calendar or the collapsed row, so that it is never mistaken for today's budget.
- **Not shown** for a past month, or when no month is confirmed or a new month is not set up.
- It updates with every add, edit, delete or refund, and at midnight. Covers don't change it.

## 3. Acceptance criteria *(Product Manager)*
Option A is confirmed (D-058). Fixed "today", engine data from F-006 / F-010.

| ID | Given / When / Then |
|---|---|
| AC-1 | **Example A.** Given example A and today 13 Nov, when Home is shown, then the summary card shows `Safe to spend ₹899 a day · 22 days left` under the hero line, and the domain function returns 89,954 paise. |
| AC-2 | **Stable during the day.** Given AC-1, when a ₹410 spend is added today, then the line still reads `₹899 a day · 22 days left` while the Today card shows `on budget`. |
| AC-3 | **Covers don't change it.** Given AC-1, when 11 Nov is covered with ₹300, then the line still reads `₹899 a day`. |
| AC-4 | **Next day.** Given example A, when the test clock moves to 14 Nov with no new spends, then the line reads `Safe to spend ₹922 a day · 21 days left` (92,238 paise). |
| AC-5 | **Equals the daily budget on day one.** Given the E2 month on 5 Nov with nothing spent, then it reads `₹830 a day · 30 days left`; given example F on 10 Nov with nothing spent, then `₹996 a day · 25 days left`. When the amount does not divide evenly, it equals the lowest of the month's daily budgets (they differ by 1 paisa, D-035). |
| AC-6 | **Mid-month change.** Given example M, today 20 Nov, Left ₹6,900 and ₹850 spent today, then it reads `Safe to spend ₹704 a day · 11 days left`. |
| AC-7 | **Nothing left.** Given example S on 8 Nov (Left −₹1,200), then the line reads `Nothing left to spread over the rest of the month.` with no amount; given a numerator of 50 paise and 1 day left, then it reads `Safe to spend less than ₹1 a day · 1 day left` (D-050). |
| AC-8 | **Refunds.** Given AC-1, when ₹500 money back is added for 12 Nov (F-016), then Left rises by ₹500 and the line reads `₹922 a day · 22 days left` (20,29,000 ÷ 22 = 92,227 paise). |
| AC-9 | **Integer and pure.** Given the domain function in `app/lib/domain/`, when unit-tested, then it uses integer paise only (no `double`/`num`), rounds down, never divides by 0 (days left ≥ 1), has 100% branch coverage (D-048 (10) definition), and gives exact results for ₹10 crore amounts. |
| AC-10 | **Not a budget.** Given AC-1, when the engine output (day budgets, results, pot, totals) is compared before and after the figure is computed, then it is identical; the figure appears only on Home's summary card, not on the Today card, calendar, collapsed row, Dashboard or statement. |
| AC-11 | **Help, themes, large text, accessibility.** Given the line, when shown in all four themes at text scale 1.0 and 2.0 on a small phone and in landscape (D-030), then it wraps without truncation, its (i) opens the §5 explanation via F-004, and TalkBack reads `Safe to spend, ₹899 a day, 22 days left`. |

## 4. Edge cases *(Product Manager)*
- **Today has a cover:** Left and today's spend are unchanged by the cover, so the figure is unchanged.
- **Huge refunds** (net spend below ₹0 today): today's net spend is negative and is added back, so refunds received today do **not** raise today's figure until tomorrow. This is the same "start of today" rule. Refunds on past days raise it at once (AC-8).
- **Device date moved back:** it uses the given today. Future-dated spends are ignored (F-006 AC-13). If today is not a budgeted day (before the first budgeted day or outside the month), the line is hidden (Gate 1, D-076).
- **Month changes at midnight and the new month is not set up:** the line is hidden.
- **A ₹10 crore Left:** `₹45,45,454 a day` wraps at 2.0×.

## 5. Help text & copy *(Product Manager, finalised by Designer)*
| Control | Label | Description / tooltip |
|---|---|---|
| Line | `Safe to spend` | `<amount> a day · <n> days left` (`1 day left`). (i): `Everything left this month, including your savings pot, spread evenly over the days left (today included). It's a guide: your daily budget doesn't change, and it stays the same all day.` |
| Nothing left | — | `Nothing left to spread over the rest of the month.` |
| Less than ₹1 | — | `less than ₹1 a day` |

## 6. Out of scope
- Changing day budgets from this figure (D-005 stays).
- Notifications based on it (Phase 5).
- Showing it on past months.

## 7. How it works — technical *(Developer, filled in when the feature is Done)*
**What was built.** The Safe to spend line on Home: how much can be spent each remaining day (including today) of the month, D-058 option A, with three visible variants and no line when nothing can be computed. Tasks T-360 to T-362. Gate 3 approved 2026-11-19 (D-088), Gate 4 pass 2026-11-23 (D-098).

**Main files** (`app/lib/`)
- Pure Dart: `domain/budget/safe_to_spend.dart` (`safeToSpendFrom`, `safeToSpendPerDay`, sealed `SafeToSpend` = `SafeToSpendAmount`, `SafeToSpendUnderRupee`, `SafeToSpendNothingLeft`, `SafeToSpendUnavailable`), exported from `budget.dart`. It works from exact paise (never from the rounded Left).
- `features/home/widgets/safe_to_spend_strip.dart` (`Unavailable` renders nothing; (i) through `InfoButton`; one screen-reader sentence; the value is one `Text` with non-breaking spaces so it wraps only at the dot), placed by `summary_card.dart`; `homeViewProvider` calls `safeToSpendPerDay`. `core/copy/safe_to_spend_copy.dart` holds the strings.

**Data stored.** None (derived from the F-006 totals each time).

**Decisions:** D-056 (3) (the line exists), D-058 (formula option A, confirmed by the Owner), D-050 and D-055 (`less than ₹1 a day`), D-059 (barrel export), D-076 (hidden when today is not a budgeted day; any positive amount to spread under ₹1 a day reads `less than ₹1 a day`; `Nothing left to spread` only at ₹0 or below), D-077 (4), D-079, D-088, D-097, D-098.

**Deviations** (plan section 11)
- TC-017-30 (c): salary day 29 in 2028 gives the month 29 Feb – 28 Mar (29 days), so the engine reads `₹858 a day · 29 days left` on 29 Feb and `₹889 a day · 28 days left` on 1 Mar; the test asserts those and the Tester corrected the case.
- TC-017-36 (c): with Today(5 Dec) and December not set up the state is the new-month card (F-010 TC-010-36), not an unbudgeted day.
- AC-5 "equals the daily budget on day one" is exact only when the spendable amount divides evenly; with a remainder the figure is the lower one (`tests/F-017` note 2).

**How it is tested** (`tests/F-017-safe-to-spend.md`, 37 cases, 11 ACs)
- Unit: `test/domain/budget/safe_to_spend_test.dart` (TC-017-01, -02, -05, -08, -10, -12, -14, -17, -18, -19, -22, -35, -37, literals from the spec); `test/architecture/domain_purity_test.dart` (TC-017-20: no `double`, `num`, `/` or rounding calls in `safe_to_spend.dart`); `test/architecture/safe_to_spend_scope_test.dart` (TC-017-23: the figure appears only in the Home summary files). TC-017-21: `tool/domain_coverage.ps1` reports `safe_to_spend.dart` L 20/20, B 10/10.
- Widget: `test/features/home/safe_to_spend_strip_test.dart` (variants, four themes, 2.0x, landscape, semantics: TC-017-03, -04, -06, -07, -09, -11, -13, -15, -16, -24, -26, -28 to -34, -36); `phase3_screen_sweep_test.dart` (TC-017-25).
- Device (A13 seed): Safe to spend `₹899` a day with 22 days left, unchanged after a ₹100 spend today, then `₹922` a day with 21 days left the next day (`s8-tc017-after-spend-today.png`, `s8-tc017-next-day-922.png`).
- No integration test of its own, and the sources record no probe or mutation result for this feature (the Step 8 mutation plan lists no F-017 file).
- Result (2026-11-23): 36 Pass of 37, 1 Blocked-needs-human (TC-017-27), no bug; `tool/check.ps1` green (1,285 tests on the 2026-11-23 re-run, 1,267 on 2026-11-21).

**Known limitations and open items**
- **Still blocks Done:** T-501 (Project Manager: Gate 3 of the shared test-only changes, then Gate 5 and the Tester's final regression). No Tester task is left for F-017.
- **TC-017-27 (TalkBack) is Blocked-needs-human**, open under D-097; the one-node strip sentence is proven by the semantics test. Same Home screen as TC-010-42 (about two minutes together; steps in `tests/PHASE-3-SUMMARY.md` 3.3).
- The line is hidden when today is not a budgeted day (D-076); a positive amount under ₹1 a day reads `less than ₹1 a day`.
- Depends on F-006 totals (Left, today's net spend, days left) and F-010 (the strip sits inside the summary card). Used by F-010 only (AC-10: the figure appears nowhere else).

## 8. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-11 | First version of the spec, from the Owner's D-056 (3). Formula option A proposed, with options B and C compared. **Owner to confirm the formula.** 11 ACs | Product Manager |
| 2026-11-11 | Small-amount wording switched from "under ₹1" to the Owner's literal "less than ₹1" (`overspent less than ₹1`, `saved less than ₹1`, `less than ₹1 left today`, `less than ₹1 short`, `less than ₹1 a day`), matching the Phase 2 change to D-050/D-055. Wording only, no AC added | Product Manager |
| 2026-11-11 | Owner confirmed option A (D-058). Status set to final Spec, ready for the plan. ACs unchanged. 11 ACs | Product Manager |
| 2026-11-16 | Gate 1 (Project Manager A, D-076): §2.1 says any positive amount under ₹1 a day reads `less than ₹1 a day`; AC-5 notes the lowest-daily-budget case; §4 hides the line when today is not a budgeted day. ACs otherwise unchanged. 11 ACs | Project Manager |
| 2026-11-16 | Example M and AC-6 aligned to canonical seed M20: ₹850 spent today (was ₹300), (6,90,000 + 85,000) ÷ 11 = 70,454 paise, so `₹704 a day · 11 days left` (was ₹654). Formula (D-058 option A) unchanged | Product Manager |
| 2026-11-23 | Step 9: section 7 (technical) filled in. Status stays Testing: Done waits for T-501 (Gate 5) | Developer |

## Owner question
- ~~Q-1~~ **Closed by D-058:** option A, (Left this month + today's net spend) ÷ days left including today, rounded down (₹899 in example A).
