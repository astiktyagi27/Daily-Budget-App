# F-013: Dashboard

| | |
|---|---|
| **Phase** | 3 |
| **Status** | Spec (final, ready for the plan; planned ahead, D-033). D-034, D-036 to D-039, D-046 to D-048, D-050, D-054, D-056 and D-057 are applied |
| **Plan** | [`plans/F-013-dashboard.md`](../../plans/F-013-dashboard.md) |
| **Test cases** | [`tests/F-013-dashboard.md`](../../tests/F-013-dashboard.md) |
| **Tasks** | T-380 to T-389 in `docs/TASKS.md` (Gate 1, 2026-11-16) |

## 1. What it is *(Product Manager)*
The Dashboard tab (README §3.6, screen 7) answers **"Where did my money go?"**:
- **Spending by category**, for the month so far or for one chosen day.
- **Three month figures:** the highest-spending day, the average daily spend, and how many days were saved, on budget or overspent.

It replaces the F-003 Dashboard placeholder.

**Until Phase 4 almost every spend is "Other".** Phase 2 stores no category (F-009 AC-14 is N/A), so every Phase 2 spend counts as **Other**. From Phase 3 the user can pick a category when adding or editing a spend, or change it from the list (F-015, D-056 (2)). Automatic categories come with SMS in Phase 4. The Dashboard must therefore **read well with one category**: one honest sentence instead of a one-slice chart, plus a hint saying how categories can be set.

Spend totals and day statuses come from the F-006 engine. The category split, the average and the highest day are **display statistics** worked out from stored spends (pure Dart in `domain/`, integer paise, unit-tested). They **never** change any budget, so they are not money rules.

**User stories:**
- As a **user**, I want to see which kinds of spending take most of my money.
- As a **user**, I want to know my average day and my worst day, so I can set a better target next month.
- As a **new user with only "Other" spends**, I want the Dashboard to make sense and tell me how to get more out of it.

## 2. How it behaves *(Product Manager)*
Layout per design system. The Designer writes the screen spec at Step 6 and picks the chart form within these rules:
- a ranked list of horizontal bars;
- **no pie or donut with one slice**;
- no empty axes.

### 2.1 Layout
1. **Title** `Dashboard` and the first-time hint (F-004, existing `hint.dashboard.v1` reworded if needed).
2. **Month header:** `5 Nov – 4 Dec 2026`, with ‹ › to change month (the same months and limits as F-011 §2.7). The current month adds `so far`.
3. **Where your money went.** A segmented control, **This month** | **One day**. With **One day**, a date chip (`Fri, 13 Nov`, defaults to today, or to the month's last day for a past month) opens a date picker limited to this month's budgeted days up to today.
4. **Category breakdown** (§2.2).
5. **This month in numbers** (§2.3).
6. A link **Month statement** → F-014.

### 2.2 Category breakdown
- **Categories:**
  - The README §3.4 list: Food, Groceries, Shopping, Travel, Bills & Recharge, Entertainment, Health, Friends & People, Other.
  - A spend with **no category stored counts as Other**.
- **Rows:** each category with spends gets a row with its name, amount, share and a bar. Rows are sorted by amount, highest first; ties are in README order. Categories with ₹0 are not shown.
- **Shares** use exact paise and are shown as **whole percent rounded down**. A share above 0 but under 1 % shows `<1%`. A note under the list says `Percentages are rounded down, so they may add up to less than 100%.`, shown only when the shares don't add up to 100.
- **Refunds (D-047)** are not split by category. Category rows show **spends**. When the range has refunds, two lines follow the list: `Refunds −₹500` and `Net spent ₹5,030`. Net spent always equals the engine's spent figure for the range: spent so far for **This month**, or the day's net spend for **One day**.
- **Single-category state** (only one category has spends, usually Other):
  - No bars. One sentence instead: `All ₹5,530 so far is in Other.`
  - Below it, a hint card (design system §7.11c style, not dismissible while the state lasts): `Spends without a category go into Other. Pick one when you add a spend, or change it in Transactions. Later, spends from your bank SMS will be sorted for you.` A text button `Go to Transactions` opens F-015.
  - When the one category is not Other (for example all Food), the sentence reads `All ₹5,530 so far is in Food.` and no hint is shown.
- **Empty state** (no spends in the range): `Nothing spent yet this month.` (month) or `Nothing spent on <date>.` (day), with no chart.

### 2.3 This month in numbers
Over the month's **ended days**: budgeted days before today (D-039; for a past month, every budgeted day). Today is still running, so it is left out, and the caption says so.

| Figure | Rule (integer paise) | Shown as |
|---|---|---|
| **Highest-spending day** | The ended day with the largest **net** spend (spends − refunds). On a tie, the **earliest** date wins, and `+<n> more day(s)` is added | `Wed, 11 Nov · ₹1,130` (tap → F-012) |
| **Average daily spend** | Sum of net spend on ended days ÷ number of ended days, rounded down toward ₹0 | `₹638 a day` |
| **Days** | Count of ended days by engine status: saved ●, on budget ○, overspent ◆. A fully covered day counts as on budget, and a partly covered day as overspent | `4 saved · 2 on budget · 2 overspent`. When covers exist: `incl. 1 covered from savings` |

- The caption reads `Based on the 8 days that have ended. Today isn't counted until midnight.`
- **No ended days yet** (the first day of a month, or a mid-month first day): `Your first day isn't over yet. Check back tomorrow.` in place of the three figures.

### 2.4 Worked example A (data as in F-010 §2.4; today Fri 13 Nov; every spend has no category)
- **This month:** spent so far ₹5,530, all Other, so the single-category state shows `All ₹5,530 so far is in Other.` + hint.
- **One day, Wed 11 Nov:** `All ₹1,130 on Wed, 11 Nov is in Other.` (the same hint).
- **One day, Thu 12 Nov:** `Nothing spent on Thu, 12 Nov.`
- **Numbers** (ended days 5–12 Nov = 8 days, net spent 500 + 1,000 + 830 + 200 + 620 + 830 + 1,130 + 0 = ₹5,110):
  - Highest day: `Wed, 11 Nov · ₹1,130`.
  - Average: 5,11,000 ÷ 8 = 63,875 paise, shown as **`₹638 a day`**.
  - Days: `4 saved · 2 on budget · 2 overspent`.
- **After covering 11 Nov with ₹300:** Days reads `4 saved · 3 on budget · 1 overspent` and `incl. 1 covered from savings`. The highest day and average are unchanged, because covers are not spends.

### 2.5 Worked example B (some categories set in F-015)
Example A, with 6 Nov's ₹1,000 set to **Shopping** and 9 Nov's ₹620 set to **Food**:

| Category | Amount | Exact share | Shown |
|---|---|---|---|
| Other | ₹3,910 (5,530 − 1,000 − 620) | 70.70 % | `70%` |
| Shopping | ₹1,000 | 18.08 % | `18%` |
| Food | ₹620 | 11.21 % | `11%` |

The shares add up to 99, so the rounding note is shown. The single-category hint is not shown, because there is more than one category.

### 2.6 Refund example (D-047)
Example A plus a ₹500 refund on Fri 13 Nov (today).
- Spends by category still total ₹5,530.
- Then `Refunds −₹500` and `Net spent ₹5,030`, which equals the engine's spent so far.
- The numbers section is unchanged, because today isn't counted.

### 2.7 Other months
- **Shortfall month** (example S, today 8 Nov): `All ₹200 so far is in Other.`. Ended days 5–7 Nov: highest `Fri, 6 Nov · ₹200`, average 200 ÷ 3 = 66.66, shown as `₹66 a day`, days `0 saved · 2 on budget · 1 overspent`.
- **Mid-month first month** (example F), or a month set up late (D-057): only budgeted days (from 10 Nov) count. 5–9 Nov are ignored, and the header reads `10 Nov – 4 Dec 2026`.
- **Mid-month change** (example M): nothing special. Days are judged by the engine against each period's budget.
- **Past month:** all budgeted days have ended, so the caption reads `Based on all 30 days.` and **One day** defaults to the month's last day.

### 2.8 Gate 1 clarifications *(Project Manager, 2026-11-16; D-080)*
- **Today** stays out of the average and the highest day until midnight (Q-1 closed). Today's spends still count in the category section and in `Net spent`.
- **Highest-spending day** reads `No spends yet` (not tappable) when no ended day has a net spend above ₹0 (all ₹0, or only refund days). The average is still shown and can be negative.
- **`incl. <n> covered from savings`** counts ended days with any cover above ₹0, full or partial (a partly covered day also counts as overspent).
- **Bar length** is the category's exact share of the range's total spends (design system §7.16), not relative to the biggest row, and at least 2 dp wide when the share is above 0.
- **A range with only refunds (D-087):** One day reads `Nothing spent on <date>.`; a whole month (This month) reads `Nothing spent yet this month.` Then the `Refunds −<amount>` and `Net spent −<amount>` lines follow, e.g. a month with only a ₹500 refund shows `Refunds −₹500` and `Net spent −₹500`, which equals Home's `Spent so far`. The highest day reads `No spends yet` and the average can be negative (above).
- **This month | One day** and the chosen day are kept while the app is open (also across tab switches) and are *This month* again after a restart. Changing the month resets the day to its default.
- `Go to Transactions` only switches the tab. It sets no filter.

## 3. Acceptance criteria *(Product Manager)*
Fixed "today" and seeded spends (category NULL unless stated). Themes and accessibility per F-002 §3.

| ID | Given / When / Then |
|---|---|
| AC-1 | **Replaces the placeholder.** Given a confirmed month, when the Dashboard tab opens, then it shows the title, month header `5 Nov – 4 Dec 2026 · so far`, the This month / One day control (This month selected), the category section, This month in numbers and the Month statement link; given no confirmed month, then it shows the F-008 `Set up your month first`-style empty state with **Set up your month** (same copy as F-009 AC-1). |
| AC-2 | **Single-category state — all Other.** Given example A (no categories stored), when the Dashboard is shown, then the category section reads exactly `All ₹5,530 so far is in Other.`, shows no bar, no percentage and no chart, and shows the hint card with `Go to Transactions`, which opens F-015. |
| AC-3 | **Single category that isn't Other.** Given every spend set to Food, when shown, then it reads `All ₹5,530 so far is in Food.` with no hint card. |
| AC-4 | **Several categories.** Given example B, when shown, then rows appear in the order Other `₹3,910` `70%`, Shopping `₹1,000` `18%`, Food `₹620` `11%`, each with a bar whose length is proportional to its paise (within 1 dp), no ₹0 categories are listed, and the rounding note is shown; given shares that add up to exactly 100 (₹500 Food, ₹500 Travel), then no note is shown. |
| AC-5 | **Tiny share and ties.** Given Other ₹9,950 and Health ₹50 (0.5 %), then Health shows `<1%`; given Food ₹500 and Travel ₹500, then Food is listed first (README order). |
| AC-6 | **One day.** Given example A, when One day is selected, then the date chip shows `Fri, 13 Nov` and the section reads `All ₹420 on Fri, 13 Nov is in Other.`; when 11 Nov is picked, then `All ₹1,130 on Wed, 11 Nov is in Other.`; when 12 Nov is picked, then `Nothing spent on Thu, 12 Nov.`; the picker allows only 5–13 Nov. |
| AC-7 | **Refunds (D-047).** Given the §2.6 data, when This month is shown, then the category total is ₹5,530 and `Refunds −₹500` and `Net spent ₹5,030` follow, and Net spent equals the engine's spent so far; given a day whose refunds exceed its spends (₹200 spend, ₹1,500 refund), when One day shows it, then `Refunds −₹1,500` and `Net spent −₹1,300` are shown. |
| AC-8 | **Numbers — example A.** Given example A and today 13 Nov, when shown, then Highest-spending day reads `Wed, 11 Nov · ₹1,130` (tap opens F-012 for 11 Nov), Average daily spend `₹638 a day` (63,875 paise rounded down), Days `4 saved · 2 on budget · 2 overspent` with ● ○ ◆, and the caption `Based on the 8 days that have ended. Today isn't counted until midnight.` |
| AC-9 | **Covers in the numbers.** Given example A with 11 Nov covered ₹300, when shown, then Days reads `4 saved · 3 on budget · 1 overspent` with `incl. 1 covered from savings`, and Highest and Average are unchanged. |
| AC-10 | **Highest-day tie.** Given ended days 6 Nov and 11 Nov both with net spend ₹1,130 and no higher day, when shown, then the highest day reads `Fri, 6 Nov · ₹1,130 +1 more day`. |
| AC-11 | **No ended days.** Given today 5 Nov (first day of the month) with ₹420 spent, when shown, then the category section shows today's ₹420 and the numbers section reads `Your first day isn't over yet. Check back tomorrow.`; the same for a mid-month first setup on its first day. |
| AC-12 | **Shortfall and mid-month months.** Given example S and today 8 Nov, then Highest `Fri, 6 Nov · ₹200`, Average `₹66 a day`, Days `0 saved · 2 on budget · 1 overspent`. Given example F and today 12 Nov, then only 10–11 Nov are counted (caption `Based on the 2 days that have ended…`) and the header reads `10 Nov – 4 Dec 2026 · so far`. |
| AC-13 | **Past months.** Given October stored, when ‹ is tapped, then the header reads `5 Oct – 4 Nov 2026` (no "so far"), the numbers caption reads `Based on all 31 days.`, One day defaults to 4 Nov, and › returns to November; ‹/› limits match F-011 AC-12. |
| AC-14 | **Integer statistics.** Given the statistics code in `app/lib/domain/`, when the Tester runs its unit tests, then average, shares and highest day use integer paise only (no `double`/`num` for money; share computed as `paise × 100 ÷ total` in integers), 100 % of its branches are covered, and an amount of ₹10 crore × 31 days gives exact results with no overflow. |
| AC-15 | **Live updates.** Given the Dashboard on screen, when a spend's category is changed in F-015, or a spend, refund or cover is added, then the breakdown and numbers update without a manual refresh. |
| AC-16 | **Help, themes, large text, accessibility.** Given each state (single category, several, refunds, no ended days, empty), when shown in all four themes at text scale 1.0 and 2.0 on a small phone and in landscape (D-030), then F-002 AC-12–AC-14 pass; every figure has its §5 label and (i) via F-004; no bar is the only carrier of meaning (every row has amount and % text); TalkBack reads each category row as `Shopping, ₹1,000, 18 percent` and the days figure as `4 saved, 2 on budget, 2 overspent`. |
| AC-17 | **Speed.** Given a month with 500 spends in 9 categories, when the Dashboard opens or the month / day changes, then the final figures appear within 500 ms on the emulator. |

## 4. Edge cases *(Product Manager)*
- **All 9 categories used:** all 9 rows are shown. The list is never truncated.
- **A category whose only spend was deleted:** its row disappears.
- **Net spend for the month is negative** (refunds bigger than spends): `Net spent −₹300`, and the average can be negative (`−₹37 a day`).
- **Exactly ₹0 spent on every ended day:** highest day reads `No spends yet`, average `₹0 a day`, days `8 saved…`.
- **Paise-only amounts** (₹0.40 Health): the row shows `₹0` and `<1%` (D-038).
- **Huge amounts:** shares stay exact (integer maths, AC-14). Amounts wrap at 2.0× and are never truncated.
- **Device date moved back:** future-dated spends are not counted (F-006 AC-13).
- **The month changes at midnight while the Dashboard is open:** on resume it shows the new month. If the new month is not set up, it shows last month with `Last month ·` in the header (as in F-011).

## 5. Help text & copy *(Product Manager, finalised by Designer)*
| Control | Label | Description / tooltip |
|---|---|---|
| Title | `Dashboard` | — |
| Month header | `<start> – <end> <year>` (+ ` · so far`) | ‹ › as F-011 |
| Range control | `This month` / `One day` | Hint `Show spending for the month` / `Show spending for one day` |
| Date chip | `<weekday, d MMM>` | Hint `Pick a day` |
| Section | `Where your money went` | (i): `Your spends grouped by category. Spends without a category count as Other.` |
| Single category | — | `All <amount> so far is in <category>.` / past month: `All <amount> is in <category>.` / `All <amount> on <date> is in <category>.` |
| "Other" hint | `Tip` | `Spends without a category go into Other. Pick one when you add a spend, or change it in Transactions. Later, spends from your bank SMS will be sorted for you.` Button `Go to Transactions` (hint `Open Transactions to set categories`). Hint-card look with no × or Got it |
| Rounding note | — | `Percentages are rounded down, so they may add up to less than 100%.` |
| Refunds line | `Refunds` | `−<amount>`. (i): `Money paid back to you. It lowers what you spent.` |
| Net spent | `Net spent` | (i): `Spends minus refunds. This matches "Spent so far" on Home.` |
| Empty | — | `Nothing spent yet this month.` / `Nothing spent on <date>.` |
| Numbers section | `This month in numbers` | Caption `Based on the <n> days that have ended. Today isn't counted until midnight.` / `Based on all <n> days.` |
| Highest day | `Highest-spending day` | (i): `The day you spent the most. If two days tie, the earlier one is shown.` Value `<date> · <amount>` (+ ` +1 more day` / ` +<n> more days`); all ended days ₹0: `No spends yet`. Hint `See this day` |
| Loading / error / no month | — | Screen reader `Loading your dashboard`; error `Couldn't load your data` · `Tap Try again. Nothing has been lost.` · `Try again`; no month `Set up your month first` · `Your spends need a budget month. It takes a minute.` · `Set up your month` |
| Average | `Average daily spend` | (i): `What you spent on the days that have ended, divided by the number of those days.` Value `<amount> a day` |
| Days | `Days` | (i): `How the days that have ended turned out. A day fully covered from savings counts as on budget.` Value `<a> saved · <b> on budget · <c> overspent` (+ `incl. <n> covered from savings`) |
| No ended days | — | `Your first day isn't over yet. Check back tomorrow.` |
| Statement link | `Month statement` | Hint `See how this month's budget was worked out` |

## 6. Out of scope
- Automatic categories and per-merchant memory (Phase 4).
- Splitting refunds by category (see Suggested additions).
- Trends across months, comparisons and exports (later).
- Charts other than the ranked bar list. Animations beyond `motionBase` (Phase 6).
- Any change to the budget. These statistics are display only.

## 7. How it works — technical *(Developer, filled in when the feature is Done)*
**What was built.** The Dashboard tab: a read-only view over the engine's `MonthResult` and the stored spends. It shows where the money went (category rows with share bars, or a sentence and a hint card when everything is Other), the Refunds and Net spent lines, the numbers card (average a day, highest day, saved, overspent, covered), a `This month` / `One day` choice with a day picker, the shared month switcher, and links to Transactions, Day details and the Month statement. Nothing is written and no money rule changed. Tasks T-380, T-382 to T-386, T-387 (Tester), T-390, T-471; Gate 1 D-080 and D-085, Gate 3 D-088, Gate 4 D-100 to D-105.

**Main files** (`app/lib/`)
- Pure Dart in `domain/budget/`: `spend_category.dart` (`SpendCategory`, key round trip, unknown key reads as Other, order as README 3.4; shared with F-015 and F-016), `category_breakdown.dart` (`categoryBreakdown`: ranked rows, whole-percent shares rounded down, `underOnePercent`, integer `barPermille`, `BreakdownKind` empty / single / several, gross spent, refunds, net), `month_figures.dart` (`monthFigures`: average a day with `~/` toward zero, highest day with the earliest date winning ties and `moreDays`, saved, overspent, covered). `Spend.category` is an additive field the engine never reads. Both statistics are exported from `budget.dart` (D-059).
- `features/dashboard/`: `dashboard_tab.dart` (keeps the last view on screen while the next month loads), `dashboard_state.dart` (one `dashboardSelectionProvider` for range, day and month), `widgets/` (`where_money_went_card`, `category_rows`, `single_category_view`, `other_hint_card`, `refund_lines`, `numbers_card`, `day_chip`, `day_strip`, `statement_link_row`).
- Shared widgets added here (used by F-014 and F-015 too): `core/widgets/segmented_control.dart`, `share_bar_row.dart`, `ledger_row.dart`, `category_icon.dart`; copy in `core/copy/dashboard_copy.dart` and `category_copy.dart`.
- Seams: `selectedTabProvider` read and written by `features/shell/app_shell.dart` (T-386, no behaviour change; `Go to Transactions` uses it); `features/day_details/open_day_details.dart` (`openDayDetails`, wired by F-012); `openMonthStatement` (F-014).
- Small additive change to F-007 code that belongs to this feature: the mapper in `data/repositories/drift_mappers.dart` now reads the existing `category` column into `Spend.category`. The month index and switcher it uses (`watchMonthIndex`, `MonthSwitcher`, `MonthBrowser`) belong to F-011 (T-322, T-323, T-325), not here.

**Data stored.** None. No schema change, no migration. The range choice and the chosen day live in memory only: kept while the app is open, back to `This month` after a restart, and a month change resets the day (D-080 (6)).

**Decisions:** D-080 (1) today stays out of the average and the highest day until midnight, today's spends still count in the category section; (2) highest day reads `No spends yet` when no ended day has a net spend above ₹0; (3) `incl. n covered from savings` counts ended days with any cover above ₹0; (4) a bar is the category's exact share of the range total; (5) refund-only day, widened to a whole month by D-087 (2); (6) range kept while open; (7) `Go to Transactions` only switches the tab; (8) month browsing is F-011's. Also D-085 (T-386 seam), D-086 and D-087 (Designer follow-ups), D-088 (Gate 3), D-100 and D-102 to D-105 (Gate 4), and the money rules it displays (D-038, D-039, D-046, D-050, D-055, D-060).

**Deviations** (plan section 11)
- Month switcher is F-011's shared one; while another month loads the old view stays, including the header range text (the review asked for the new range at once). One `dashboardSelectionProvider` instead of the three named in the plan. Segmented control is 48 dp tall (design said 44) so it passes the tap-target guideline. Header range reads `1 – 30 Nov 2026` inside one month, otherwise `5 Nov – 4 Dec 2026`. The sweep lives in `dashboard_sweep_test.dart`, not the shared a11y file. Live updates need up to three frame pumps in a widget test.
- T-390 (test only): `dashboard_500_test.dart` applies the 500 ms limit in profile mode (`speedLimitMs`), with a 3,000 ms guard in debug (D-100).

**How it is tested** (`tests/F-013-dashboard.md`, 60 cases, 17 / 17 ACs)
- Unit: `test/domain/budget/category_breakdown_test.dart`, `month_figures_test.dart`, `spend_category_test.dart`, `test/data/repositories/spend_category_read_test.dart`; every worked example (A, B, refunds, shortfall S, mid-month F, covers, ties, all ₹0, negative net, paise-only, ₹10 crore x 31 days) and a property check against `computeMonth`. The engine is unchanged: F-006 suite, TZ matrix (UTC, PST8PDT, IST identical) and domain coverage (100 % lines and branches) re-run.
- Widget (fake repositories; five theme cases, text scale 2.0, small phone, landscape): `test/features/dashboard/` (`dashboard_tab_test`, `dashboard_numbers_test`, `dashboard_sweep_test`), `test/core/widgets/dashboard_widgets_test.dart`, helper `test/helpers/dashboard_harness.dart`, shared fixtures `phase3_fixtures.dart`. T-471 added TC-013-49, -57, -58, -59, -60, split TC-013-48 out of TC-013-21 and renamed the old-month-stays test TC-013-55.
- Integration on the emulator: `integration_test/dashboard_500_test.dart` (TC-013-32, 500 spends, limit 500 ms). Profile mode (D-100), `flutter drive --profile -d emulator-5554 --driver=test_driver/integration_test.dart --target=integration_test/dashboard_500_test.dart`: worst of 5 is 83 ms in the clean run (`step8-clean-profile-dashboard_500.log`), 98 ms in the Developer's T-390 run (`dev-t390-profile-dashboard_500.log`), 89 ms in Tester 1's. In debug the cold first open was 562 to 1,349 ms and runs 1 to 4 were 157 to 504 ms; debug numbers are logged only and do not decide (D-100). This was B-002, closed by ruling.
- Mutation pass: 28 mutants of this file, 19 killed on 2026-11-21 and the 9 survivors killed on the 2026-11-23 re-run, so all 28 killed. The Developer's probes were re-applied by Tester 2 on the final code: C1, C1b, C2b, C2c, C4b, C6a, C6b, C15 (T-471) and S3a, plus F-015's T25b, **10 of 10 killed on the final code** (D-102). The two ledger-row height constants S3b and S3c are equivalent (the (i) button already gives 48 dp). No survivor was a money-calculation bug.
- Result (Tester 2, 2026-11-23): Pass 56, Partial 1 (TC-013-50, device half), Fail 0, Blocked 1 (TC-013-31), Pending 2 (TC-013-51, -52). `tool/check.ps1` last run: 1,285 tests green, domain coverage 100 %, TZ matrix passed. Gate 4: conditional pass (D-103).

**Known limitations and open items**
- **Not Done yet.** Open before Done (D-103): Tester 1's emulator session T-392: TC-013-50 (by-hand device half), TC-013-51, TC-013-52 (kill case). Also a green `tool/check.ps1` on the final code (Orchestrator), and Gate 5 with the Tester's final session for the phase.
- **TC-013-31 (TalkBack) is Blocked-needs-human**, accepted as open (D-104, same terms as D-066 and D-071). Proofs in place: the semantics sentences TC-013-30 and the sweeps are green. A real-phone walk is recommended, not required.
- Highest day and the average leave today out until midnight (D-080 (1)). The bar is drawn from an integer permille but its width is a layout `double` (never shown as money). Live updates have no refresh gesture and need none.
- Nice to have: none new from the Gate 4 review.
- Depends on F-006 (`MonthResult`), F-007 (spends, category column), F-011 (month index, `MonthSwitcher`, `MonthBrowser`), F-012 (`openDayDetails`), F-014 (`openMonthStatement`), `selectedTabProvider` (T-386). Used by F-015 and F-016 (they write the categories and refunds it displays; AC-15 live update is proved through the F-015 flow) and by F-014 (shares `LedgerRow`).

## 8. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-10 | First version of the spec (Phase 3 planned ahead, D-033). Team question "highest day tie" decided: earliest date wins, with "+n more". D-047 refunds applied for display. 17 ACs | Product Manager |
| 2026-11-11 | D-056 (2): the "Other" hint now mentions picking a category when adding a spend (§2.2, §5); refunds come from F-016 (D-054); a late-started month (D-057) counts only budgeted days, as §2.7 mid-month. No AC change. 17 ACs | Product Manager |
| 2026-11-11 | Status set to final Spec, ready for the plan (all Owner questions answered: D-053 to D-058). Remaining team questions go to the Project Manager at Phase 3 Gate 1 (phase overview, open items) | Product Manager |
| 2026-11-11 | §5 finalised by the Designer (`docs/design/screens/dashboard.md`): past-month single-category sentence without "so far", `Tip` overline and `Go to Transactions` hint, plural `+<n> more days`, `No spends yet`, loading/error/no-month copy. `hint.dashboard.v1` unchanged. No AC changed | Designer |
| 2026-11-16 | Gate 1 (Project Manager B, D-080): Q-1 closed (today excluded); new §2.8 with the rulings on highest day with no spend, `incl. n covered`, bar basis, refund-only day, range kept while the app is open. No AC changed. 17 ACs | Project Manager |
| 2026-11-16 | T-452 (Gate 2, D-087): §2.8 refund-only rule now covers a whole month as well as One day (`Nothing spent yet this month.`, then the Refunds and Net spent lines). No AC changed (AC-7 stays as written). 17 ACs | Product Manager |
| 2026-11-23 | Section 7 filled in (Step 9, T-393): built files, stored data (none), decisions D-080 to D-105, deviations, tests (profile-mode speed run, mutation pass), open items (T-392 emulator cases, TC-013-31 TalkBack). Status stays Testing until those are closed (D-103, D-105) | Developer |

## Impact on existing features
- **F-003:** the Dashboard placeholder empty state is replaced. F-003 Dashboard test cases are updated when this is built.
- **F-004:** `hint.dashboard.v1` wording may change, which needs a new hint ID.

## Owner / team questions
- **Q-1 (team, PM):** the average and the highest day leave out **today** until midnight (D-039 style). The alternative is to include today, labelled "so far". This doc chooses to leave it out, so the figures don't jump during the day. **Closed by D-080 (Gate 1, 2026-11-16): confirmed as written.**

## Suggested additions *(for the CEO — not in scope until approved)*
- **Refunds per category** (a Shopping refund lowers Shopping). It needs a category on refunds, and negative category rows.
- **"Compared with last month"** per category (CRED and Jupiter show this). Needs two full months of data.
- **Daily spend bar chart** for the month (one bar per day, coloured by status, with marks).
