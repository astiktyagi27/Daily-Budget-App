# Screen spec: Calendar (on Home)

**Owner of this file:** Designer · **Phase:** 3 (planned ahead, D-033; docs only) · **Feature:** F-011 Calendar (uses F-002 tokens, design system §7.5 day cell and §7.14 month switcher, F-004 help pattern, F-006 day results) · **Status:** Draft for Phase 3 Gate 2
**Read with:** `docs/features/F-011-calendar.md` (§2.5 and §5 updated to match this file; AC-9, AC-16, AC-17), `home-summary.md` (cards above it), `day-details.md` (what a tap opens), `docs/design/design-system.md` §4.2, §4.3, §7.5, §7.14. Decisions D-034, D-036, D-037, D-038, D-039, D-046, D-047, D-050, D-055, D-057, D-075, D-077.

---

## 1. Purpose
Show the whole budget month at a glance, so the user can see which days went well (● green), exactly to plan (○ grey) or over (◆ red), and tap any day to see why.

## 2. Design decisions

| # | Question | Decision | Why |
|---|---|---|---|
| C-1 | Card or bare? | **Bare on the page** under a section header, not inside a card. | The cells already have fills; a card around them would stack surfaces (design system: cards never contain cards, and the grid reads like a ruled ledger page). |
| C-2 | Change-day marker | The **ink tick** (12 × 3 dp `accent`, top centre of the cell; design system §7.5), not a dot at the bottom-left as first drafted in F-011 §2.5. The legend gains `▬ Budget changed` in months that have a change. | The bottom of the cell holds the amount, so a bottom-left dot would collide with `₹1,130`. The tick is the app's signature mark (selected tab), so it reads as "budget" rather than as a fourth result. F-011 §2.5 updated. |
| C-3 | Not-budgeted days | Own state (§7.5): no box, full-strength number, no mark, plus **one caption under the grid** naming them. Read like every other cell, **with the weekday** (D-075): `Thursday 5 November, not budgeted, before you started`. | Without the caption a user who started on 10 Nov sees five blank days and wonders if data is missing. |
| C-4 | Getting back from an old month | A `This month` text button under the range on past months (§7.14), plus an `Ended` tag next to the range. | ‹ goes back to the first stored month, so returning could take many taps. The tag stops a past month being mistaken for the current one while the summary card above shows this month. |
| C-5 | Amounts that don't fit | Scale down to fit (no ellipsis, floor 9 sp), and short forms from ₹10,000 by amount alone (`₹12k`, `₹1.5L`, `₹12L`, `₹10Cr`; one decimal only below ₹10 L / ₹10 Cr); full amount in the label and day details. Exact table: design system §7.5. | F-011 AC-11 needs `₹9,999` in full on a 360 dp phone; at 12 sp it is about 39 dp, the cell's inner width is about 35 dp. The amount alone decides, so one day reads the same on every phone. A decimal on a two-digit lakh (`₹12.3L`) would shrink under 10 sp. |
| C-6 | Grid width and touch pitch | The grid and weekday strip use **14 dp** side gutters (page text stays 20 dp, so the grid is 6 dp wider each side). Cells grow taller than wide when text is scaled. | The touch pitch is cell + 4 dp gap = (screen width − 24) ÷ 7. With 20 dp gutters it is 46 dp on 360 dp; with 16 dp it was 47.4 dp, 0.6 dp under the 48 dp rule (STANDARDS §7). With 14 dp it is **exactly 48.0 dp on 360 dp** (cell 44 dp, D-075). Phones narrower than 360 dp (grid area under 336 dp = 7 × 48) cannot reach 48 dp with seven columns: documented exception, e.g. 42.3 dp on the 320 dp test phone; heights stay at least 48 dp. |

## 3. Layout
Under the Today card (and `hint.calendar.v1` when shown), `space6` above, `space5` gutters (the weekday strip and the grid use a **14 dp** gutter, C-6; it is not a spacing-scale step, so it is the named constant `calendarGridGutter`):
1. **Month switcher** (design system §7.14): range `5 Nov – 4 Dec 2026` in `title`, ‹ › on the right. Past month: an `Ended` tag after the range (`caption` 500, `textSecondary` on `neutralSoft`, `radiusXs`, 4 × 8 dp padding) and the `This month` Text button under it. New month not set up: the range reads `Last month · 5 Oct – 4 Nov`, › disabled, no tag (the words already say it).
2. **Legend row**, `space2` below: `● Saved  ○ On budget  ◆ Overspent` (`caption`, `textSecondary`; each mark drawn in its own colour, 6 dp) + (i). In a month with a change: `  ▬ Budget changed` is added (tick drawn 12 × 3 dp `accent`). Wraps between items at large text.
3. **Weekday strip**, `space3` below: `M T W T F S S` (`caption`, `textSecondary`) on a `sunken` strip, `radiusXs`, 28 dp tall, 14 dp gutters like the grid, columns aligned with the cells.
4. **Grid**, `space2` below the strip: weeks Monday–Sunday, 4 to 6 rows, 4 dp gaps, cells per §7.5.
5. **Caption** (only when the month has not-budgeted days), `space3` below the grid, `body` `textSecondary`: `Days before 10 Nov aren't budgeted. You started on 10 Nov.` Late setup (D-057): `Days before 12 Dec aren't budgeted. This month was set up on 12 Dec.`

## 4. Day cells — example A (₹830/day, 5 Nov – 4 Dec 2026, today Fri 13 Nov)
Grid Mon 2 Nov – Sun 6 Dec, 35 cells in 5 rows. 2–4 Nov and 5–6 Dec are **outside**; the 1 Dec cell's number reads `1 Dec`.

| Date | State | Cell | Screen-reader label (button, hint `See this day`) |
|---|---|---|---|
| Thu 5 Nov | Saved | `savedSoft`, ●, `₹500` in `saved` | `Thursday 5 November, spent ₹500, saved ₹330` |
| Fri 6 Nov | Overspent | `overspentSoft`, ◆, `₹1,000` | `Friday 6 November, spent ₹1,000, overspent ₹170` |
| Sat 7 Nov | On budget | `neutralSoft`, ○, `₹830` | `Saturday 7 November, spent ₹830, on budget` |
| Sun 8 Nov | Saved | ●, `₹200` | `Sunday 8 November, spent ₹200, saved ₹630` |
| Mon 9 Nov | Saved | ●, `₹620` | `Monday 9 November, spent ₹620, saved ₹210` |
| Tue 10 Nov | On budget | ○, `₹830` | `Tuesday 10 November, spent ₹830, on budget` |
| Wed 11 Nov | Overspent | ◆, `₹1,130` (fits at ~11 sp) | `Wednesday 11 November, spent ₹1,130, overspent ₹300` |
| Thu 12 Nov | Saved | ●, `₹0` | `Thursday 12 November, nothing spent, saved ₹830` |
| Fri 13 Nov | Today | `savedSoft` (result so far) + 2 dp `accent` ring, number `accent` 600, ●, `₹420` in `textPrimary` | `Today, Friday 13 November, spent ₹420 so far, ₹410 left` |
| Sat 14 Nov – Fri 4 Dec | Upcoming | hairline box, `textSecondary` number, nothing else | `Saturday 14 November, upcoming` |

**Covered days** (F-012): 11 Nov fully covered with ₹300 → ○ `₹1,130`, label `…, spent ₹1,130, on budget, ₹300 covered from savings`. Covered with ₹100 → stays ◆, label `…, overspent ₹200 after ₹100 from savings`. The amount is still the net spend (covers are not spends).

**Less than ₹1** (D-050, D-055): ₹830.50 spent → ◆ `₹830`, label ends `overspent less than ₹1`; ₹829.50 → ● `₹829`, label ends `saved less than ₹1`. Never `overspent ₹0`, `saved ₹0` or `−₹0`.

**Refund days** (D-047): ₹200 spend + ₹1,500 refund → ● `−₹1,300` in `saved`, label `…, net minus ₹1,300 after refunds, saved ₹2,130`. ₹700 spend + ₹500 refund → ● `₹200`, label `…, net ₹200 after refunds, saved ₹630`.

**Big days (short forms, design system §7.5):** cell text is chosen by the amount only; the label always has the full amount.

| Net spent | Cell | Screen-reader label |
|---|---|---|
| ₹9,999 | `₹9,999` | `…, spent ₹9,999, overspent ₹9,169` |
| ₹12,999 | `₹12k` | `…, spent ₹12,999, overspent ₹12,169` |
| ₹1,59,999 | `₹1.5L` | `…, spent ₹1,59,999, overspent ₹1,59,169` |
| ₹12,99,999 | `₹12L` | `…, spent ₹12,99,999, overspent ₹12,99,169` |
| ₹10,00,00,000 | `₹10Cr` | `…, spent ₹10,00,00,000, overspent ₹9,99,99,170` |
| refunds, net −₹1,50,000 | `−₹1.5L` in `saved` | `…, net minus ₹1,50,000 after refunds, saved ₹1,50,830` |

**Today overspent:** fill `overspentSoft`, ◆, label `Today, Friday 13 November, spent ₹1,000 so far, overspent ₹170`. **Today with nothing spent:** `surface` fill (no result yet), ring, no mark, `₹0`, label `Today, Friday 13 November, spent ₹0 so far, ₹830 left`.

## 5. Special months

### 5.1 A month across two calendar months
The 1st of the new calendar month reads `1 Dec` in the number slot (fitted). A month crossing the year reads `25 Dec 2026 – 24 Jan 2027` in the switcher (wraps at the ` – ` at large text) and `1 Jan` in the cell. A budget month that starts on the 1st of a calendar month shows a plain `1` on its first day, with no month name (D-075 (2); design system §7.5 and F-011 say the same); the month name appears only on the 1st of the following calendar month inside a month that crosses over.

### 5.2 Shortfall month (example S, ₹0/day, today Sun 8 Nov)
5 and 7 Nov: ○ `₹0`, `…, nothing spent, on budget`. 6 Nov: ◆ `₹200`, `Friday 6 November, spent ₹200, overspent ₹200`. 8 Nov: today ring, `surface`, `₹0`, `Today, Sunday 8 November, spent ₹0 so far, on budget`. No extra shortfall panel here; it is on the summary card.

### 5.3 Two-period month (example M: 1–12 Nov ₹830/day, from 13 Nov ₹552/day; today Fri 20 Nov)
Grid Mon 26 Oct – Sun 6 Dec, 6 rows. Cells up to 12 Nov are judged against ₹830, from 13 Nov against the engine's ₹552.23 / ₹552.22.
- **13 Nov** carries the ink tick; its label adds `, budget changed this day`: `Friday 13 November, spent ₹500, saved ₹52, budget changed this day`. No other cell has the tick (a same-day replaced change does not add a second tick).
- 18 Nov: ◆ `₹600`, `Wednesday 18 November, spent ₹600, overspent ₹47`.
- The legend shows `▬ Budget changed`. The (i) explains it.

### 5.4 Mid-month first month or late setup (example F: first use 10 Nov)
5–9 Nov: **Not budgeted** cells: no box, number in `textSecondary` at full strength, no mark, no amount, not tappable, label `Thursday 5 November, not budgeted, before you started` (late setup: `Saturday 5 December, not budgeted, before this month's setup`; the weekday is there like on every other cell, D-075). The caption under the grid names the range (§3 item 5). 10 Nov onward behaves normally against ₹996.
- **Told apart without colour or box:** upcoming = hairline box; not budgeted = no box, full-strength number; outside = no box, faded number and no screen-reader node. The caption is the explanation, so the three never need a legend entry.
- **No ripple, no scale, no focus stop as a button.** TalkBack reads the cell as plain text (not "button") and says nothing about double-tapping.
- **Past months:** the first month's not-budgeted days and the caption stay when it is viewed later (`Ended`).
- **Text 2.0×:** the number stays (capped 1.3×), there is no amount to hide; landscape: same 56 dp cap, nothing else changes. The label keeps the weekday at every size.
- **Today not budgeted:** when today falls before the first budgeted day, no cell carries the today ring; the Today card and Safe to spend line are hidden on Home (D-076, D-077; `home-summary.md` §7). All budget days show as upcoming.
- The change tick and the not-budgeted state never meet (a not-budgeted day has no period).

## 6. Past months and navigation

### 6.1 ‹ and ›
‹ goes to the previous stored budget month, back to the first one; › goes forward, disabled on the current month (hint `This is the current month`). ‹ is disabled on the first stored month (hint `No earlier months`). Missed months don't exist, so ‹ can jump from Dec to Sep; the range shows the real dates.

### 6.2 Swipe
Swiping the grid left → next month, right → previous month (same limits). A swipe at a limit does nothing: the grid does not move, nothing bounces (the design system rule "nothing bounces"), no haptic, no month change (Gate 3, D-089: the 16 dp rubber band is dropped).

### 6.3 Past month look
`Ended` tag + `This month` button (§3). Every day has its final result: no ring, no upcoming boxes. The change tick still shows on a past month's change days. Cells are tappable and open day details **read-only**.

### 6.4 Transition
Content cross-fades with a 16 dp slide in the direction of travel (`motionBase`, 200 ms); the switcher range changes at once, with no cross-fade (it comes from the month index, so it never waits for the grid, and a screen reader hears it immediately). While the next grid loads, the old grid stays on screen. Instant with Remove animations (Gate 3, D-089).

### 6.5 Coming back to Home
The calendar always reopens on the current month when the app starts or returns from the background after midnight. Switching tabs keeps the month being viewed.

### 6.6 New month started, not set up
The calendar shows last month: range `Last month · 5 Oct – 4 Nov`, › disabled (hint `This is the latest month`), every day final, cells open read-only day details.

## 7. Tap
| Cell | Tap |
|---|---|
| Past or today, current month | Day details (push, `day-details.md`) |
| Upcoming | Day details in its upcoming form (budget only) |
| Past month | Day details, read-only |
| Not budgeted, outside | Nothing (no ripple, no scale) |

Pressed: the cell scales to 0.96 (`motionFast`) with the `sunken`-tinted ripple clipped to `radiusXs`.

## 8. States

| State | Calendar shows |
|---|---|
| First-time | Normal grid; `hint.calendar.v1` above it once `hint.home.v1` is gone (`home-summary.md` H-7). Day 1 of a month: today ring, every other day upcoming. |
| Normal | §3–§4. |
| Empty (no spends yet) | Past days show ● `₹0` saved (nothing spent is a saved day); upcoming days are boxes. No special empty message: the grid itself is the content. |
| No confirmed month | Not shown (Home shows only the F-008 empty state). |
| Loading | Switcher, legend and weekday strip are drawn; the grid shows hairline boxes with day numbers only, no fills, marks or amounts. Never a `₹0`. Semantics: the grid is one node `Loading your calendar`. Switching month with ‹ / › keeps the old grid until the new one is ready (AC-18: under 500 ms), so the user never sees an empty frame. |
| Load error | Home's load error state replaces everything (`home-summary.md` §7). If only a past month fails to load: the grid area shows `Couldn't load this month.` (`body`, `textSecondary`) and a Secondary `Try again` (hint `Try to load this month again`). Neutral, never red. |
| Shortfall month | §5.2. |
| Two-period month | §5.3. |
| Mid-month first / late setup | §5.4. |
| New month not set up | §6.6. |
| Permission denied | Not applicable. |

## 9. Themes
Cell fills, marks and amounts use the pairs in design system §3 (lowest: Light `neutral` on `neutralSoft` 4.64, `overspent` on `overspentSoft` 4.71; change tick lowest 5.30). **No new colour pair and no new token** for the not-budgeted cell, the tick or the short forms: the number is `textSecondary` on `bg`, the tick is the `accent` pairs already in §3 (re-computed 2026-11-16: Light 7.08 / 6.82 / 6.71 / 8.35 / 7.66, Dark 5.97 / 6.47 / 6.58 / 7.49 / 8.09, Dim 5.30 / 5.37 / 5.57 / 6.14 / 6.97 on `savedSoft` / `neutralSoft` / `overspentSoft` / `surface` / `bg`), and short forms use the same amount colours as full amounts.

| Element | Light | Dark | Dim |
|---|---|---|---|
| Saved cell / mark+amount | `#DDEFE3` / `#1A7044` | `#16301F` / `#52C98B` | `#2F3F33` / `#80D3A1` |
| On-budget cell / mark+amount | `#EAE6DF` / `#68646E` | `#24242B` / `#9F9CA7` | `#3D3A35` / `#B6AFA4` |
| Overspent cell / mark+amount | `#F6E0DC` / `#B4372F` | `#3A1A17` / `#FF7B6F` | `#4A3230` / `#FF9C8E` |
| Today ring + number, change tick | `#3A3DB0` | `#9C9FFF` | `#ABACF6` |
| Upcoming box / number | `#DED8CD` / `#5C5864` | `#2A2A33` / `#A8A5B1` | `#48453F` / `#BEB7AB` |
| Not budgeted number | `#5C5864` on `#F6F3ED` (6.25) | `#A8A5B1` on `#0E0E12` (7.96) | `#BEB7AB` on `#2A2825` (7.39) |
| Outside number (decorative, 50 %) | `#5C5864` at 50 % | `#A8A5B1` at 50 % | `#BEB7AB` at 50 % |
| Weekday strip | `#EEEAE2` + `#5C5864` | `#0A0A0D` + `#A8A5B1` | `#24221F` + `#BEB7AB` |
| `Ended` tag | `#5C5864` on `#EAE6DF` (5.56) | `#A8A5B1` on `#24242B` (6.37) | `#BEB7AB` on `#3D3A35` (5.69) |

In Dark the upcoming hairline (`#2A2A33`) is faint on purpose: upcoming days are "not yet" and should recede; the number (7.96 : 1) is what the user reads.

## 10. Largest text (2.0×, 360 × 640 dp) and landscape (640 × 360)
- **Up to 1.3×:** number, mark and amount (amount capped at 1.3× and fitted).
- **Cells grow:** at 1.3× the cell height becomes the content height (taller than wide) instead of clipping; rows share the tallest height.
- **Above 1.3×:** amount hidden; number (capped at 1.3× so two digits and `1 Dec` fit, fitted) and mark stay. The screen-reader label keeps the amount (F-011 AC-16). This is the only thing on Home that does not follow 2.0× in full; tapping a day shows its amounts at full size.
- **Amount fit, measured on paper (T-454, 2026-11-16):** inner width 36 dp (44 dp cell − 2 × 4 dp) on a 360 dp phone; `moneySmall` is IBM Plex Sans Medium 12 sp, tabular. Advances read from `app/assets/fonts/IBMPlexSans-Medium.ttf` (units per em 1000): each digit 0.600 em, `,` 0.290 em, `₹` 0.615 em, `−` (U+2212) 0.600 em; the word joiner after `₹` has no width. Widths: `₹9,999` = 3.305 em, `−₹9,999` = 3.905 em (7 glyphs). The fitted size is the smaller of the natural size and 36 ÷ width, and it does not depend on the text scale, because the natural size at 1.0× (12) is already above the fitted size:

  | Amount | Fitted size at 1.0× | at 1.3× | at 2.0× |
  |---|---|---|---|
  | `₹9,999` | 10.9 (12 sp natural, shrunk) | 10.9 | amount hidden (above 1.3×, rule above) |
  | `−₹9,999` | **9.2**, above the 9 sp floor by 0.2 | **9.2**, still shown | amount hidden |

  Result: both stay visible at 1.0× to 1.3× on a 360 dp phone. The design system's earlier "about 9.6 sp" for `−₹9,999` was a rough guess; the measured value is 9.2. **Margin is thin:** on a 320 dp phone (cell 42.3 dp, inner 34.3 dp) `−₹9,999` fits at 8.8, below the floor, so there the amount is hidden by the 9 sp rule (the label keeps it); `₹9,999` still fits at 10.4. Assumptions: Plex Medium advances as above, no letter spacing on `moneySmall`, `FittedBox` scales text uniformly, "sp" read as the rendered size of the glyphs. T-454 (Developer, T-326 sweep) still confirms on a real render, including `₹99k`, `₹9.9L`, `−₹100Cr`.
- **Switcher range** wraps to two lines at 2.0×; ‹ › stay on the first line's right.
- **Legend** wraps between items; the (i) stays after the last item.
- **Caption** wraps freely.
- **Grid gutters (C-6):** 14 dp at every text size. At 2.0× the cell is 44 dp wide on a 360 dp phone (the pitch does not depend on text size); only the height grows, so targets stay at least 48 × 48 dp.
- **Landscape (640 × 360):** grid centred in the 600 dp content column, cells capped at 56 dp (pitch 60 dp), 48 dp targets kept; the 14 dp gutter applies only below the cap, so on a wide screen the grid simply centres with the space left over. 6-row months make Home scroll; nothing is clipped.

## 11. Accessibility
- Order (F-011 AC-17): range (heading) → `Ended` → `This month` → ‹ → › → legend (`Saved, On budget, Overspent` + `Budget changed` when shown) → legend (i) → budget days in date order (outside skipped; not-budgeted read but marked not a button) → caption.
- Each budget day is a button with the full sentence (§4, F-011 §5). Today, upcoming and not-budgeted days are included.
- Grey-scale check (AC-4): ●, ○ and ◆ are filled circle, ring and diamond; the today ring and change tick are shapes too.
- Touch target: the cell plus half of each 4 dp gap, so no two overlap: **48.0 dp wide on a 360 dp phone** (14 dp gutters; under 360 dp it shrinks to 42.3 dp at 320 dp, the documented exception, D-075), at least 48 dp tall (design system §7.5). Not-budgeted and outside cells have no target.
- Short forms: the cell is one merged node whose label holds the full amount; `₹1.5L` is never read and no label contains `lakh`, `crore`, `L`, `k` or `Cr`.
- Colour is never the only signal: fill + shape (● ○ ◆) + amount for results; hairline box for upcoming; tick shape for a change; the caption for not-budgeted days.

## 12. Copy (final; F-011 §5 matches)

| Control | Label | Tooltip / hint / description |
|---|---|---|
| Range | `<d MMM> – <d MMM> <yyyy>` (year on both sides when they differ) | New month not set up: `Last month · <start> – <end>` |
| Ended tag | `Ended` | Read with the range: `5 October to 4 November 2026, ended` |
| This month | `This month` | Hint `Go back to the current month` |
| Previous month | (icon ‹) | Tooltip / hint `Previous month`; disabled `No earlier months` |
| Next month | (icon ›) | Tooltip / hint `Next month`; disabled `This is the current month` (new month not set up: `This is the latest month`) |
| Legend | `● Saved ○ On budget ◆ Overspent` (+ `▬ Budget changed`) | (i) title `Calendar`: `Each day shows what you spent. Green ● means you spent less than the day's budget, grey ○ exactly the budget, red ◆ more. A small indigo line at the top of a day means your budget changed that day. Tap a day to see its spends.` |
| Not-budgeted caption | — | `Days before <d MMM> aren't budgeted. You started on <d MMM>.` / late setup: `Days before <d MMM> aren't budgeted. This month was set up on <d MMM>.` |
| Day cell (screen reader) | — | As F-011 §5 and §4 above; change day adds `, budget changed this day`; tap hint `See this day` |
| Not-budgeted cell (screen reader, not a button) | — | `Thursday 5 November, not budgeted, before you started` / late setup `Saturday 5 December, not budgeted, before this month's setup` (F-011 AC-9, TC-011-20, -21) |
| Loading | — | `Loading your calendar` |
| Past-month load error | — | `Couldn't load this month.` + `Try again` (hint `Try to load this month again`) |
| Calendar hint | `Tip` | `Tap a day to see its spends.` (`hint.calendar.v1`, `home-summary.md` H-7; row in `help-pattern.md` §4.2) |

## 13. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-11 | First version (Phase 3 planned ahead, D-033). Decisions C-1 … C-5; design system §7.5 additions | Designer |
| 2026-11-16 | Phase 3 open item 7 finished: short-form table made exact (`₹12.3L` becomes `₹12L`; amount alone decides; floor 9 sp; TalkBack and `formatRupees` consistency in design system §7.5); big-day label examples (§4); not-budgeted cell notes (§5.4); C-6 grid gutters 16 dp and 47.4 to 48 dp touch pitch; cells grow with text (§10); no new colour pair (§9). Pending Gate 2 | Designer |
| 2026-11-16 | T-451 / T-454 (Gate 2 Nice to have 3, 5, 6): §5.1 sentence that a budget month starting on the 1st shows a plain `1`; tick ratios already 7.08 / 6.71 here (recomputed, design system §3 now matches); §10 paper measurement of the fitted amount: `₹9,999` 10.9, `−₹9,999` 9.2 on 360 dp (above the 9 sp floor), 8.8 on 320 dp (hidden) | Designer |
| 2026-11-16 | T-310 (D-075, D-076, D-077): not-budgeted label gets the weekday (C-3, §5.4, §12); C-6 gutters 16 dp to **14 dp** so the pitch is 48.0 dp on 360 dp (cell 44 dp, exception below 360 dp), §3, §10, §11 and design system §7.5 updated; today-not-budgeted note (§5.4); `hint.calendar.v1` row added to `help-pattern.md` §4.2. Pending Gate 2 (T-313) | Designer |
| 2026-11-19 | T-465 (Gate 3, D-089): §6.2 a swipe at a limit does nothing (no 16 dp rubber band, "nothing bounces"); §6.4 the switcher range changes at once, no cross-fade (the grid still cross-fades with the slide) | Designer |

## 14. Notes for the Project Manager
1. F-011 AC-8 says "the 13 Nov cell carries the change marker"; the marker is now the ink tick (C-2). The AC still holds.
2. T-310: F-011 AC-9 text and TC-011-20, -21 already carry the weekday; T-324 builds the 14 dp gutter as one constant shared by the weekday strip and the grid.
3. `This month`, `Ended`, the not-budgeted caption and the past-month load error are new copy (F-011 §5 updated).

---

## Owner preview
(The ₹ sign is dropped inside the cells below only to fit 40 characters; the real cells show `₹500`, `₹1,000` and so on.)

### Normal month, today Fri 13 Nov (Light)
```
┌──────────────────────────────────────┐
│ 5 Nov – 4 Dec 2026          ‹    ›   │
│ ● Saved ○ On budget ◆ Overspent (i)  │
│ ┌──────────────────────────────────┐ │
│ │ M    T    W    T    F    S    S  │ │
│ └──────────────────────────────────┘ │
│  2    3    4   ╭───╮╭───╮╭───╮╭───╮  │
│  ·    ·    ·   │5 ●││6 ◆││7 ○││8 ●│  │
│                │500││1,0││830││200│  │
│ ╭───╮╭───╮╭───╮╭───╮┏━━━┓┌┄┄┄┐┌┄┄┄┐  │
│ │9 ●││10○││11◆││12●│┃13●┃┆14 ┆┆15 ┆  │
│ │620││830││1.1││  0│┃420┃┆   ┆┆   ┆  │
│ ╰───╯╰───╯╰───╯╰───╯┗━━━┛└┄┄┄┘└┄┄┄┘  │
│ ┌┄┄┄┐┌┄┄┄┐┌┄┄┄┐┌┄┄┄┐┌┄┄┄┐┌┄┄┄┐┌┄┄┄┐  │
│ ┆16 ┆┆17 ┆┆18 ┆┆19 ┆┆20 ┆┆21 ┆┆22 ┆  │
│ ┌┄┄┄┐┌┄┄┄┐┌┄┄┄┐┌┄┄┄┐┌┄┄┄┐┌┄┄┄┐┌┄┄┄┐  │
│ ┆23 ┆┆24 ┆┆25 ┆┆26 ┆┆27 ┆┆28 ┆┆29 ┆  │
│ ┌┄┄┄┐┌┄┄┄┐┌┄┄┄┐┌┄┄┄┐┌┄┄┄┐            │
│ ┆30 ┆┆1De┆┆ 2 ┆┆ 3 ┆┆ 4 ┆  5    6    │
└──────────────────────────────────────┘
```
(Side gutters are 14 dp, so the grid is 6 dp wider each side than the page text and each day is exactly 48 dp pitch on a 360 dp phone. Mockup cells are 3 characters wide, so `1,0` = ₹1,000, `1.1` = ₹1,130, `1De` = "1 Dec"; on the phone they read in full. Green fills ● 5, 8, 9, 12; grey ○ 7, 10; red ◆ 6, 11; the thick indigo box is today; dotted boxes are upcoming; 2–4 Nov and 5–6 Dec are faded, outside the month.)

### Two-period month, today Fri 20 Nov (Dark)
```
┌──────────────────────────────────────┐
│ 1 – 30 Nov 2026             ‹    ›   │
│ ● Saved ○ On budget ◆ Overspent      │
│ ▬ Budget changed (i)                 │
│  M    T    W    T    F    S    S     │
│ 26   27   28   29   30   31   1 ●    │
│                               630    │
│ 2 ◆  3 ○  4 ○  5 ●  6 ○  7 ●  8 ○    │
│1,070 830  830  530  830  430 1,030   │
│ 9 ○ 10 ●  11 ○ 12 ● 13▬● 14 ◆ 15 ●   │
│ 830  630  830  530  500  700  400    │
│16 ◆ 17 ● 18 ◆ 19 ◆ [20●] 21   22     │
│ 600  300  600  600  300              │
│ 23   24   25   26   27   28   29     │
│ 30    1    2    3    4    5    6     │
└──────────────────────────────────────┘
```
(₹830 a day until 12 Nov, ₹552 from 13 Nov, where the indigo ▬ tick sits. 8 Nov went ₹200 over but was covered from savings, so it shows grey ○. 18 Nov: ₹600 against ₹552 = ◆ "overspent ₹47". 26–31 Oct and 1–6 Dec are faded outside days.)

### Past month (Light, top only)
```
┌──────────────────────────────────────┐
│ 5 Oct – 4 Nov 2026 [Ended]  ‹    ›   │
│ This month                           │
│ ● Saved ○ On budget ◆ Overspent (i)  │
│  M    T    W    T    F    S    S     │
│ ...every day has its final mark...   │
└──────────────────────────────────────┘
```
(‹ greyed out here if October is the first month in the app. "This month" jumps straight back to November.)

### Mid-month first month, started 10 Nov, today 12 Nov (Dim)
```
┌──────────────────────────────────────┐
│ 5 Nov – 4 Dec 2026          ‹    ›   │
│  M    T    W    T    F    S    S     │
│  2    3    4    5    6    7    8     │
│ ┄┄┄┄┄┄┄┄┄faded┄┄┄  readable, no box  │
│  9   10 ●  11 ◆ [12 ]  13   14   15  │
│      800  1,100  0                   │
│ ...                                  │
│ Days before 10 Nov aren't budgeted.  │
│ You started on 10 Nov.               │
└──────────────────────────────────────┘
```
(₹996 a day from 10 Nov. 5–9 Nov keep a readable number with no box and no mark; TalkBack reads `Thursday 5 November, not budgeted, before you started`; 2–4 Nov are faded outside days.)

### Text at 2.0× (Light, one row)
```
┌──────────────────────────────────────┐
│ ╭───╮╭───╮╭───╮╭───╮┏━━━┓┌┄┄┄┐┌┄┄┄┐  │
│ │ 9 ││10 ││11 ││12 │┃13 ┃┆14 ┆┆15 ┆  │
│ │  ●││  ○││  ◆││  ●│┃  ●┃┆   ┆┆   ┆  │
│ ╰───╯╰───╯╰───╯╰───╯┗━━━┛└┄┄┄┘└┄┄┄┘  │
└──────────────────────────────────────┘
```
(Amounts hide above 1.3×; TalkBack still says "spent ₹620, saved ₹210", and a tap shows them full size.)

### Why these choices
- **Shape + colour + amount in every cell**, so the month reads in one glance and still works in grey-scale or for colour-blind users.
- **The indigo tick marks the day your budget changed**, the same mark as the selected tab, so it never looks like a fourth kind of result.
- **Quiet past and future:** upcoming days are empty boxes, days before you started are plainly labelled, and past months say "Ended" with a one-tap way back.
