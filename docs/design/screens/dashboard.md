# Screen spec: Dashboard tab

**Owner of this file:** Designer · **Phase:** 3 (planned ahead, D-033; docs only) · **Feature:** F-013 Dashboard (replaces the F-003 placeholder; uses F-002 tokens, design system §7.14 month switcher, §7.15 segmented control, §7.16 share bar row, F-004 help pattern) · **Status:** Draft for Phase 3 Gate 2
**Read with:** `docs/features/F-013-dashboard.md` (§5 updated to match this file), `app-shell.md` (frame, Dashboard hint), `calendar.md` (same months and limits), `transactions-search.md` (categories), `month-statement.md`, `docs/design/design-system.md`. Decisions D-034, D-036, D-037, D-038, D-039, D-046, D-047, D-050, D-056, D-057.

---

## 1. Purpose
Answer "where did my money go?" in plain sentences and a few honest numbers, and still make sense when almost every spend is "Other".

## 2. Design decisions

| # | Question | Decision | Why |
|---|---|---|---|
| B-1 | Chart form | A **ranked list of share bars** (design system §7.16): name, amount and % on one line, a thin ink bar under it. No pie, donut or axes (F-013 §2). | Every row is readable as text; the bar only adds a glance. Ink, not colours, because a category share is neither good nor bad. |
| B-2 | **"Mostly Other"** (one category) | **A sentence, not a chart:** a 40 dp icon circle + `All ₹5,530 so far is in Other.` Then the **Other hint card** directly under the section card (not inside it), with `Go to Transactions`. | A single 100 % bar or one-slice pie looks broken. One sentence is honest and still useful (it states the total). |
| B-3 | The Other hint | Same look as the F-004 hint card (§7.11c: `accentSoft`, lightbulb, `Tip`) but **no × and no Got it**: it disappears by itself once a second category exists. | F-013 §2.2: not dismissible while the state lasts. Reusing the hint look teaches that it is advice, not an error. |
| B-4 | Days at a glance | Under the `Days` figure, a **day strip**: one ledger mark per ended day in date order (● ○ ◆, 10 dp, coloured), wrapping. Decorative; the text says the counts. | Shows the rhythm of the month (e.g. two ◆ in a row) without a chart, in the calendar's own language. |
| B-5 | Figures layout | In **This month in numbers** each figure is stacked: label + (i) on line 1, value on line 2 (`moneyMedium`). | Values like `Wed, 11 Nov · ₹1,130 +1 more day` are too long to share a line with a label on a phone. |
| B-6 | Dashboard hint | `hint.dashboard.v1` stays as is: `Check back after a week of spending. That's when your patterns start to show.` | Still true in Phase 3; rewording would need a new hint ID and re-show it to users who dismissed it. |
| B-7 | **Bar length basis** (D-080 (4)) | A bar is the category's **exact share of the range total** (design system §7.16): Other `70%` fills 70 % of the track, Food `11%` fills 11 %. It is **not** scaled to the biggest row, so the biggest bar is never full unless it is the whole total. Minimum 2 dp when the share is above 0. | The bar and the written `%` must say the same thing; a bar stretched to the biggest row would make 70 % look like 100 %. |
| B-8 | **A range with only refunds** (D-080 (5)) | The category card says `Nothing spent on <date>.` (This month: `Nothing spent yet this month.`), then the same hairline and the `Refunds` and `Net spent` lines (§4.4). `Net spent` is negative (`−₹500`). No sentence, rows or hint card. | A refund still changed the money; hiding the lines would make Net spent unexplained. The Empty sentence stays true: nothing was spent. |
| B-9 | **Range choice memory** (D-080 (6)) | `This month` / `One day` and the chosen day are **kept while the app is open** (also when you leave the tab and come back) and **reset when the app restarts** (back to `This month`, today). Changing the month resets only the **day** (to that month's default day: today, or the last day of a past month); `One day` stays selected. Nothing is saved to the phone. | Switching tabs should not lose your place, but a fresh start should show the usual overview. |

## 3. Layout (month confirmed)
Shared tab frame (`app-shell.md` §2), `space5` gutters:
1. Title `Dashboard` (`headline`).
2. `hint.dashboard.v1` (first visits, unchanged).
3. **Month switcher** (§7.14): `5 Nov – 4 Dec 2026` + ` · so far` on the current month; ‹ › with F-011's limits; `Ended` tag and `This month` button on past months; `Last month · …` when a new month is not set up.
4. **Where your money went** card (§4), `space4` below.
5. **Other hint card** (§4.3), only in the all-Other state, `space3` below the card.
6. **This month in numbers** card (§5), `space4` below.
7. **Month statement** row (§6), `space4` below.
8. Bottom padding: nav height + `space6`.

## 4. Where your money went (card)
Card, padding 16 dp.
- Header: `Where your money went` (`title`) + (i).
- **Segmented control** (§7.15), `space3` below, full width, **48 dp tall** (the control and its touch target are the same size; Gate 3, D-089): `This month` | `One day`. Default `This month`.
- **Date chip** (only for One day), `space3` below: an outlined chip (§7.15 filter-chip idle look) with leading `calendar_today` 18 dp, text `Fri, 13 Nov`, trailing `expand_more`. Tap opens the Material date picker (`transactions.md` §8.2 theming), limited to this month's budgeted days up to today (past month: all its budgeted days), help text `Pick a day`. Default: today; past month: its last day. The segmented choice and the picked day are kept while the app is open and reset on restart; a month change resets the day (B-9).
- Content (`space4` below), one of:

### 4.1 Several categories
Share bar rows (§7.16), `space4` between rows, sorted by amount, ties in README order; ₹0 categories hidden; all 9 shown when used (never truncated):
- `Other` `₹3,910` `70%` / `Shopping` `₹1,000` `18%` / `Food` `₹620` `11%`.
- `<1%` for a share above 0 and under 1 %.
- **Bar length (B-7):** each bar's length is that row's exact share of the range total, not a share of the biggest row. With Other 70 %, Shopping 18 %, Food 11 % the bars fill about 70 %, 18 % and 11 % of the track. Shares are computed from exact paise; the written `%` is the rounded-down figure of the same share.
- Rounding note (only when the shown shares don't add to 100): `Percentages are rounded down, so they may add up to less than 100%.` (`caption`, `textSecondary`), `space3` below the last row.

### 4.2 Single category
A row: 40 dp `neutralSoft` circle with the category icon (`transactions-search.md` §7.2) in `neutral` · `space3` · sentence in `bodyLarge` `textPrimary`, amount Plex 600, category name weight 600:
- This month: `All ₹5,530 so far is in Other.` (past month: `All ₹18,500 is in Other.`, F-013 §5 wording without "so far").
- One day: `All ₹1,130 on Wed, 11 Nov is in Other.`
- Not Other: `All ₹5,530 so far is in Food.` (no hint card).

### 4.3 Other hint card (single category = Other)
Under the section card: `accentSoft`, `radiusMd`, padding 16 dp. Row 1: lightbulb (20 dp, `accent`) + `Tip` (`label` 600, `accent`). Text (`body`, `textPrimary`): `Spends without a category go into Other. Pick one when you add a spend, or change it in Transactions. Later, spends from your bank SMS will be sorted for you.` Text button `Go to Transactions` (`accent`, right-aligned, hint `Open Transactions to set categories`) → switches to the Transactions tab (ink tick slides, no new route). No × / Got it (B-3). It also shows for One day when that day is all Other.

### 4.4 Refunds in the range
Under the rows or sentence: hairline, then two ledger rows (label + (i) left `body` `textSecondary`, amount right `moneyMedium`): `Refunds` `−₹500` and `Net spent` `₹5,030` (Net spent equals Home's Spent so far for This month; the day's net for One day). Negative net: `Net spent` `−₹1,300`.

### 4.5 Nothing in the range
`Nothing spent yet this month.` / `Nothing spent on Thu, 12 Nov.` (`bodyLarge`, `textSecondary`). No icon, no chart, no hint.

### 4.6 A range with only refunds (B-8)
When the range has no spends but at least one refund (for example Thu 12 Nov, a ₹500 refund and nothing else): the sentence of §4.5 (`Nothing spent on Thu, 12 Nov.`), `space4` below it the hairline and the two ledger rows of §4.4: `Refunds` `−₹500` and `Net spent` `−₹500`. No category rows, no 40 dp icon circle, no Other hint card. The numbers card is not affected (it counts ended days only; a day with only a refund has a net spend below ₹0, so it is never the highest day, §5).

## 5. This month in numbers (card)
Card, padding 16 dp. Header `This month in numbers` (`title`). Rows stacked (B-5), hairlines between:

| Figure | Line 1 | Line 2 (value) |
|---|---|---|
| Highest day | `Highest-spending day` + (i) | `Wed, 11 Nov · ₹1,130` (`moneyMedium`; date part in `label` 500) + trailing `chevron_right`; the row is a button → day details for that date. Tie: `+1 more day` (`body`, `textSecondary`) after the amount. No ended day has a net spend above ₹0 (all ₹0, or only refund days): `No spends yet` (`moneyMedium`, not a button, no chevron). Today is left out until midnight (D-080 (1)). |
| Average | `Average daily spend` + (i) | `₹638 a day` (negative possible: `−₹37 a day`; still shown when the highest day is `No spends yet`) |
| Days | `Days` + (i) | `● 4 saved · ○ 2 on budget · ◆ 2 overspent` (`label` 500; each mark and its number in the status colour, the words `textPrimary`; a count of 0 keeps its mark but in `neutral`). Covers: `incl. <n> covered from savings` (`body`, `textSecondary`) below; n counts ended days with **any** cover above ₹0, full or partial (D-080 (3)), and the line is left out when n is 0. Then the **day strip** (B-4): one 10 dp mark per ended day, date order, 4 dp gaps, wraps, decorative. |

Caption at the bottom (`caption`, `textSecondary`): `Based on the 8 days that have ended. Today isn't counted until midnight.` (one day: `Based on the 1 day that has ended. …`); past month `Based on all 31 days.`
**No ended days:** the three rows are replaced by `Your first day isn't over yet. Check back tomorrow.` (`bodyLarge`, `textSecondary`); no caption.

## 6. Month statement row
Full-width row (56 dp) on the page, not a card: `Month statement` (`label` 600, `accent`) + `chevron_right`. Hint `See how this month's budget was worked out`. → F-014 for the month shown.

## 7. Worked examples
- **Example A** (today Fri 13 Nov, no categories): This month → `All ₹5,530 so far is in Other.` + hint. Numbers: `Wed, 11 Nov · ₹1,130`, `₹638 a day`, `● 4 saved · ○ 2 on budget · ◆ 2 overspent`, strip `● ◆ ○ ● ● ○ ◆ ●` (5–12 Nov), caption `Based on the 8 days that have ended…`.
- **After covering 11 Nov ₹300:** Days `● 4 saved · ○ 3 on budget · ◆ 1 overspent` + `incl. 1 covered from savings`; the strip's 11 Nov mark becomes ○.
- **Example B** (6 Nov → Shopping, 9 Nov ₹620 → Food): rows Other ₹3,910 70%, Shopping ₹1,000 18%, Food ₹620 11%, rounding note; no hint.
- **Refund** (₹500 today): rows unchanged (₹5,530), then `Refunds −₹500`, `Net spent ₹5,030`.
- **Refund-only day** (One day, Thu 12 Nov, only a ₹500 refund): `Nothing spent on Thu, 12 Nov.`, then `Refunds −₹500`, `Net spent −₹500`. If every ended day of the month were only refunds or ₹0, Highest-spending day reads `No spends yet` while the average is still shown.
- **Range kept** (user picks One day · Tue 10 Nov, goes to Home, comes back): still `One day`, `Tue, 10 Nov`. After the app is closed and opened again: `This month`. Moving to October resets the day to 4 Nov (October's last day) and keeps `One day`.
- **Shortfall (example S, 8 Nov):** `All ₹200 so far is in Other.` + hint; `Fri, 6 Nov · ₹200`, `₹66 a day`, `● 0 saved · ○ 2 on budget · ◆ 1 overspent`. The zero count keeps its mark in `neutral` (H-3 rule: no green for nothing).
- **Two-period month (example M, 20 Nov):** nothing special: 19 ended days, each judged by the engine against its own period's budget; header `1 – 30 Nov 2026 · so far`.
- **Mid-month first (example F, 12 Nov):** header `10 Nov – 4 Dec 2026 · so far`; caption `Based on the 2 days that have ended…`; 5–9 Nov never appear.

## 8. States

| State | Dashboard shows |
|---|---|
| First-time | Title, `hint.dashboard.v1`, then the normal content (usually the all-Other state). |
| Normal | §3. |
| No confirmed month | Under the title and hint, the empty state (§7.10) with **Primary**: icon `insights`, title `Set up your month first`, description `Your spends need a budget month. It takes a minute.`, button `Set up your month` (hint `Open month setup`) → F-008 (same copy as F-009 AC-1). |
| Month with no spends | Category card `Nothing spent yet this month.`; numbers card as normal (ended days all saved) or the first-day line. |
| One day with only refunds | §4.6: `Nothing spent on <Wkd, d MMM>.` then `Refunds −<amount>` and `Net spent −<amount>`. No rows, no hint card. Same for a month with only refunds (`Nothing spent yet this month.`). |
| Coming back to the tab | The range (`This month` / `One day`) and the picked day are as the user left them while the app stays open (B-9); after a restart: `This month`. |
| First day of the month | Category card shows today's spends; numbers card `Your first day isn't over yet. Check back tomorrow.` |
| Loading | Cards drawn with headers and the static placeholder bars of `home-summary.md` §7 in place of rows and values; never `₹0` or `0%`. Semantics: `Loading your dashboard`. Month change keeps the old content until the new month is ready (AC-17: 500 ms). |
| Load error | Empty state (§7.10): icon `error_outline` (`neutral`), `Couldn't load your data`, `Tap Try again. Nothing has been lost.`, Primary `Try again` (hint `Try to load your data again`). Never red. |
| Shortfall month | §7. No shortfall panel here (it is on Home). |
| Two-period month | §7. |
| Past month | Header without `so far`, `Ended` tag, `This month` button; One day defaults to the last day; caption `Based on all <n> days.` |
| New month not set up | Last month, header `Last month · 5 Oct – 4 Nov`, › disabled; behaves as a past month. |
| Permission denied | Not applicable. |

## 9. Interactions and motion
- Segmented control and date changes cross-fade the card content (`motionBase`); bars grow from 0 to their length over `motionBase` on first show and on change (instant with Remove animations). Nothing else animates. **No count-up on this screen** (decided at Gate 3, D-089): the Dashboard figures change by cross-fade only. The count-up (`motionCount`) is kept only for the Home hero and day details, where it is a Nice to have (T-466); it is never required for a figure to be correct.
- Highest-day row → day details (push). `Go to Transactions` → tab switch. Month statement → push. Live updates (AC-15) re-render in place without animation.

## 10. Themes

| Element | Light | Dark | Dim |
|---|---|---|---|
| Bar / track | `#1C1B22` on `#EAE6DF` | `#F2F0EA` on `#24242B` | `#EEE9E0` on `#3D3A35` |
| Share % (`textSecondary` on card) | `#5C5864` (6.81) | `#A8A5B1` (7.38) | `#BEB7AB` (6.50) |
| Segmented selected / track | `#FFFDF8` + `#8A8377` edge on `#EEEAE2` | `#17171D` + `#6A6876` on `#0A0A0D` | `#34312D` + `#878073` on `#24221F` |
| Other hint card | `#E7E6F6`, text `#1C1B22` (13.87), link `#3A3DB0` (6.89) | `#25264A`, `#F2F0EA` (12.67), `#9C9FFF` (6.06) | `#3E3D55`, `#EEE9E0` (8.67), `#ABACF6` (4.97) |
| Days counts ● / ○ / ◆ | `#1A7044` / `#68646E` / `#B4372F` on card | `#52C98B` / `#9F9CA7` / `#FF7B6F` | `#80D3A1` / `#B6AFA4` / `#FF9C8E` |
| Statement link | `#3A3DB0` on `#F6F3ED` (7.66) | `#9C9FFF` (8.09) | `#ABACF6` (6.97) |
| Refund-only day: sentence / Refunds, Net spent labels / amounts | `#5C5864` (6.81) / `#5C5864` / `#1C1B22` | `#A8A5B1` (7.38) / `#A8A5B1` / `#F2F0EA` | `#BEB7AB` (6.50) / `#BEB7AB` / `#EEE9E0` |
| `No spends yet` (Highest day, not a button) | `#1C1B22` | `#F2F0EA` | `#EEE9E0` |
| Bar fill at its exact share | as the Bar / track row; a share of 70 % fills 70 % of the track in every theme | | |

All pairs in design system §3. Negative amounts (`−₹500`) keep `textPrimary` (a refund is not a result, so no red or green).

## 11. Largest text (2.0×, 360 × 640 dp) and landscape (640 × 360)
- **Share rows:** above 1.3× line 1 stacks: name on its own line, then amount and % on the next; the bar stays full width below.
- **Segmented control:** grows in height; labels wrap to two lines if needed (never clipped); both segments keep equal width.
- **Sentences, hint, caption:** wrap freely. Amounts never split.
- **Refund-only day (§4.6):** the sentence wraps; `Refunds` and `Net spent` rows stack label over amount above 1.3× (same as §4.4); `No spends yet` wraps and is never cut. At 2.0× the date chip and the segmented control keep their own rows; the bar length is a share of the full width in every size.
- **Numbers:** already stacked; values wrap at ` · `. The day strip wraps.
- **Landscape:** content column max 600 dp, centred.

## 12. Accessibility
- Order: title → hint → month switcher → section heading + (i) → segmented control (`This month, selected, 1 of 2`) → date chip (`Date, Friday 13 November, button`, hint `Pick a day`) → rows (`Shopping, ₹1,000, 18 percent`; `<1%` read `less than 1 percent`) or the sentence → rounding note → refunds rows (`Refunds, minus ₹500`) → hint card + `Go to Transactions` → numbers heading → each figure (`Highest-spending day, Wednesday 11 November, ₹1,130`, button, hint `See this day`; `Days, 4 saved, 2 on budget, 2 overspent, including 1 covered from savings`) → caption → Month statement.
- Refund-only day: `Nothing spent on Thursday 12 November.` → `Refunds, minus ₹500` → `Net spent, minus ₹500`. Highest day with no spends: `Highest-spending day, No spends yet` (not a button, no hint). The range choice kept while the app is open is not announced; after a restart the control reads `This month, selected, 1 of 2` again.
- Bars and the day strip are excluded from semantics (the bar's length is the same share the row's text already says). Every target ≥ 48 dp.

## 13. Copy (final; F-013 §5 matches)

| Control | Label | Description / tooltip / hint |
|---|---|---|
| Title | `Dashboard` | — |
| Month header | `<start> – <end> <yyyy>` (+ ` · so far`) | ‹ › / `This month` / `Ended` as `calendar.md` §12 |
| Range control | `This month` / `One day` | Hints `Show spending for the month` / `Show spending for one day` |
| Date chip | `<Wkd, d MMM>` | Hint `Pick a day`; picker help `Pick a day` |
| Section | `Where your money went` | (i): `Your spends grouped by category. Spends without a category count as Other.` |
| Single category | — | `All <amount> so far is in <category>.` / past month `All <amount> is in <category>.` / `All <amount> on <Wkd, d MMM> is in <category>.` |
| Other hint | `Tip` | `Spends without a category go into Other. Pick one when you add a spend, or change it in Transactions. Later, spends from your bank SMS will be sorted for you.` Button `Go to Transactions` (hint `Open Transactions to set categories`) |
| Rounding note | — | `Percentages are rounded down, so they may add up to less than 100%.` |
| Refunds | `Refunds` | `−<amount>`. (i): `Money paid back to you. It lowers what you spent.` |
| Net spent | `Net spent` | (i): `Spends minus refunds. This matches "Spent so far" on Home.` |
| Empty | — | `Nothing spent yet this month.` / `Nothing spent on <Wkd, d MMM>.` (with refunds only, the same sentence, then the `Refunds` and `Net spent` lines; see §4.6) |
| Numbers | `This month in numbers` | Caption `Based on the <n> days that have ended. Today isn't counted until midnight.` (`the 1 day that has ended`) / `Based on all <n> days.` |
| Highest day | `Highest-spending day` | (i): `The day you spent the most. If two days tie, the earlier one is shown.` Value `<Wkd, d MMM> · <amount>` (+ ` +<n> more day` / ` +<n> more days`); none `No spends yet` (no ended day has a net spend above ₹0). Hint `See this day` |
| Average | `Average daily spend` | (i): `What you spent on the days that have ended, divided by the number of those days.` Value `<amount> a day` |
| Days | `Days` | (i): `How the days that have ended turned out. A day fully covered from savings counts as on budget.` Value `<a> saved · <b> on budget · <c> overspent` (+ `incl. <n> covered from savings`, n = ended days with any cover above ₹0, full or partial) |
| No ended days | — | `Your first day isn't over yet. Check back tomorrow.` |
| Statement link | `Month statement` | Hint `See how this month's budget was worked out` |
| No month | `Set up your month first` | `Your spends need a budget month. It takes a minute.` · `Set up your month` (hint `Open month setup`) |
| Loading | — | `Loading your dashboard` |
| Load error | `Couldn't load your data` | `Tap Try again. Nothing has been lost.` · `Try again` |

## 14. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-11 | First version (Phase 3 planned ahead, D-033). Decisions B-1 … B-6 | Designer |
| 2026-11-16 | T-388 (D-080, D-086): B-7 bar length is the exact share of the range total (§4.1, preview bars redrawn to 70 / 18 / 11 %); B-8 / §4.6 range with only refunds (`Nothing spent on <date>.` then `Refunds` and `Net spent`); B-9 range and day kept while the app is open, reset on restart, month change resets the day; highest day `No spends yet` also when only refund days; `incl. n covered` counts any cover; themes, 2.0×, landscape, accessibility sentences and copy rows added; new worked examples and preview | Designer |
| 2026-11-19 | T-465 (Gate 3, D-089): segmented control is 48 dp tall (§4; design system §7.15 aligned); §9 states there is no count-up on the Dashboard | Designer |

## 15. Notes for the Project Manager
1. The day strip (B-4) is decorative and adds no figure; no AC needed. Say if you'd rather drop it.
2. New copy: `Go to Transactions` hint, past-month single-category sentence without "so far", `+<n> more days` plural, `Loading your dashboard`. F-013 §5 updated.

---

## Owner preview

### Mostly "Other": example A, today Fri 13 Nov (Light)
```
┌──────────────────────────────────────┐
│ Dashboard                            │
│ 5 Nov – 4 Dec 2026 · so far ‹    ›   │
│ ╭──────────────────────────────────╮ │
│ │ Where your money went (i)        │ │
│ │ ┌───────────────┬──────────────┐ │ │
│ │ │ ✓ This month  │   One day    │ │ │
│ │ └───────────────┴──────────────┘ │ │
│ │ ╭──╮ All ₹5,530 so far is in     │ │
│ │ │⋯ │ Other.                      │ │
│ │ ╰──╯                             │ │
│ ╰──────────────────────────────────╯ │
│ ╭──────────────────────────────────╮ │
│ │ ☼ Tip                            │ │
│ │ Spends without a category go     │ │
│ │ into Other. Pick one when you    │ │
│ │ add a spend, or change it in     │ │
│ │ Transactions. Later, spends from │ │
│ │ your bank SMS will be sorted for │ │
│ │ you.          Go to Transactions │ │
│ ╰──────────────────────────────────╯ │
│ ╭──────────────────────────────────╮ │
│ │ This month in numbers            │ │
│ │ Highest-spending day (i)         │ │
│ │ Wed, 11 Nov · ₹1,130           › │ │
│ │──────────────────────────────────│ │
│ │ Average daily spend (i)          │ │
│ │ ₹638 a day                       │ │
│ │──────────────────────────────────│ │
│ │ Days (i)                         │ │
│ │ ● 4 saved · ○ 2 on budget ·      │ │
│ │ ◆ 2 overspent                    │ │
│ │ ● ◆ ○ ● ● ○ ◆ ●                  │ │
│ │ Based on the 8 days that have    │ │
│ │ ended. Today isn't counted until │ │
│ │ midnight.                        │ │
│ ╰──────────────────────────────────╯ │
│ Month statement                    › │
└──────────────────────────────────────┘
```
(No chart at all while everything is Other: one sentence and a tip. The tip is a soft indigo card. ₹5,110 over 8 ended days = ₹638 a day.)

### Some categories set: example B (Dark)
```
┌──────────────────────────────────────┐
│ ╭──────────────────────────────────╮ │
│ │ Where your money went (i)        │ │
│ │ ┌───────────────┬──────────────┐ │ │
│ │ │ ✓ This month  │   One day    │ │ │
│ │ └───────────────┴──────────────┘ │ │
│ │ Other              ₹3,910   70%  │ │
│ │ ━━━━━━━━━━━━━━━━━━━━━━░░░░░░░░░░ │ │
│ │ Shopping           ₹1,000   18%  │ │
│ │ ━━━━━━░░░░░░░░░░░░░░░░░░░░░░░░░░ │ │
│ │ Food                 ₹620   11%  │ │
│ │ ━━━░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │ │
│ │ Percentages are rounded down, so │ │
│ │ they may add up to less than     │ │
│ │ 100%.                            │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```
(Bars are plain light ink on a dark track: shares are not good or bad, so no green or red. Each bar is its exact share of the total: 70 % fills 70 % of the track, so the longest bar is not full.)

### One day, with a refund (Dim)
```
┌──────────────────────────────────────┐
│ ╭──────────────────────────────────╮ │
│ │ Where your money went (i)        │ │
│ │ ┌───────────────┬──────────────┐ │ │
│ │ │  This month   │ ✓ One day    │ │ │
│ │ └───────────────┴──────────────┘ │ │
│ │ ( ▦ Fri, 13 Nov ⌄ )              │ │
│ │ ╭──╮ All ₹420 on Fri, 13 Nov is  │ │
│ │ │⋯ │ in Other.                   │ │
│ │ ╰──╯                             │ │
│ │──────────────────────────────────│ │
│ │ Refunds (i)                −₹500 │ │
│ │ Net spent (i)               −₹80 │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```

### One day with only a refund: Thu 12 Nov (Light)
```
┌──────────────────────────────────────┐
│ ╭──────────────────────────────────╮ │
│ │ Where your money went (i)        │ │
│ │ ┌───────────────┬──────────────┐ │ │
│ │ │  This month   │ ✓ One day    │ │ │
│ │ └───────────────┴──────────────┘ │ │
│ │ ( ▦ Thu, 12 Nov ⌄ )              │ │
│ │ Nothing spent on Thu, 12 Nov.    │ │
│ │──────────────────────────────────│ │
│ │ Refunds (i)                −₹500 │ │
│ │ Net spent (i)              −₹500 │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```
(No bars, no icon, no tip: nothing was spent, but the refund still shows and explains the negative Net spent. In the numbers card, if no ended day had a spend, `Highest-spending day` reads `No spends yet`, not tappable, while `Average daily spend` is still shown. Pick One day, leave the tab, come back: it is still One day; close and reopen the app: back to This month.)

### Shortfall month, today 8 Nov (Light, numbers only)
```
│ │ Highest-spending day (i)         │ │
│ │ Fri, 6 Nov · ₹200              › │ │
│ │ Average daily spend (i)          │ │
│ │ ₹66 a day                        │ │
│ │ Days (i)                         │ │
│ │ ● 0 saved · ○ 2 on budget ·      │ │
│ │ ◆ 1 overspent                    │ │
│ │ ○ ◆ ○                            │ │
```
(The "● 0 saved" mark is grey, not green: nothing was saved.)

### First day of a month (Light, numbers card)
```
│ ╭──────────────────────────────────╮ │
│ │ This month in numbers            │ │
│ │ Your first day isn't over yet.   │ │
│ │ Check back tomorrow.             │ │
│ ╰──────────────────────────────────╯ │
```

### Why these choices
- **Honest when there's little to show:** with everything in "Other" you get one clear sentence and a tip on how to sort spends, never a sad one-slice pie.
- **Ranked ink bars with the amount and % written out**, so the list is readable without the bars and calm in every theme.
- **The month's rhythm in one line of ● ○ ◆ marks**, the same language as the calendar, next to the three numbers that matter.
