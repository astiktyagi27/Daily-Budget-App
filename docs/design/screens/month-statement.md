# Screen spec: Month statement

**Owner of this file:** Designer · **Phase:** 3 (planned ahead, D-033; docs only) · **Feature:** F-014 Month statement (uses F-002 tokens, design system §7.14 month switcher, F-004 help pattern, F-006 per-period results, F-007 period history) · **Status:** Draft for Phase 3 Gate 2
**Read with:** `docs/features/F-014-month-statement.md` (§5 updated to match this file), `home-summary.md`, `dashboard.md`, `day-details.md` (entry points), `month-setup.md` §5 (spendable line style), `docs/design/design-system.md` §4.3 (minus, no-split, arrows), §7.2, §7.14. Decisions D-036, D-037, D-038, D-042, D-043, D-046, D-047, D-050, D-053.

---

## 1. Purpose
A read-only page that shows how a month's budget was worked out, period by period, and that every number adds up, so the user never wonders why ₹830 became ₹552.

## 2. Design decisions

| # | Question | Decision | Why |
|---|---|---|---|
| S-1 | Route | **Full screen**, pushed (from Home, Dashboard or day details), back arrow; title in the scroll body. | It is a long document, and it is reached from three places. |
| S-2 | Order | Totals card → What changed → Period cards (oldest first) → footnote (F-014 §2.2). | Answer first ("where do I stand"), then "what changed", then the working. |
| S-3 | The working line | Set in its own **`sunken` working strip** inside the period card (`radiusMd`, padding 12 × 16 dp), `bodyLarge` with amounts in Plex 600 tabular; the daily result `→ ₹552/day` in Plex 600 followed by an (i). Wraps only at ` = `, `, minus ` and ` → ` (F-014 AC-16), relaxing to spaces only when a chunk is wider than the strip (§11). | It is the sum on the page, like the working in the margin of a khata. The strip separates "the calculation" from the values and totals around it. |
| S-4 | Which period is which | An overline `Period 2 of 2` (`caption` 500, `textSecondary`) above each heading; the current period gets ` · in progress`. | Two cards with similar numbers are easy to mix up when scrolling. |
| S-5 | The D-053 rounding note | An inline note (16 dp `info` icon + `body` `textSecondary`) directly **under the totals card**, only when the shown parts don't add up. | It sits next to the total it explains and stays quiet otherwise. |
| S-6 | Arriving from a day | The statement opens scrolled so the period card's top is `space6` below the top bar, and the card's fill flashes `accentSoft` → `surface` over 600 ms (`decelerate`; none with Remove animations). TalkBack focus goes to the period heading. | The user tapped "Budget changed on this day"; they should land on that period without hunting. |

## 3. Layout
| # | Part | Spec |
|---|---|---|
| 1 | Top bar | 56 dp, `bg`, back arrow, tooltip `Back`. |
| 2 | Title | `Month statement` (`headline`). |
| 3 | Month switcher | §7.14: range `1 – 30 Nov 2026`; current month suffix ` · so far (to Fri, 20 Nov)`; ‹ › with the F-011 limits; `Ended` tag and `This month` button on past months. |
| 4 | Not-budgeted line | Only for a mid-month first or late-setup month, inline note: `5 – 9 Nov: not budgeted (before you started).` |
| 5 | Totals card | §4, `space4` below. |
| 6 | Rounding note | §5 (S-5), only when needed. |
| 7 | What changed card | §6, `space4` below. |
| 8 | Period cards | §7, `space4` apart. |
| 9 | Footnote | `Amounts are in whole rupees. Calculations use exact amounts.` (`caption`, `textSecondary`), `space6` above, `space8` below. |

## 4. Totals card
Card, padding 20 dp. Header: `So far` (current month) or `Month total` (past) in `title`. Ledger rows (label + (i) left in `body` `textSecondary`, amount right in `moneyMedium` `textPrimary`; row 40 dp):
1. `Money for the month`
2. `Spent` — with refunds: `Spent`, `Refunds` (`−₹500`), `Net spent`
3. `Saved` (`● ₹2,115`: the mark and the amount in the status colour, **no extra word**, because the row label already says Saved; Gate 3, D-089 settles the earlier "● + `saved`" text against §8.1)
4. `Covered from savings`
5. `Overspent` (`◆ ₹537`, same rule; no extra word)
6. `Savings pot`
7. `Short this month` (only with a shortfall): `◆ −₹1,000` in `overspent`; less than ₹1: `◆ less than ₹1 short`
8. Hairline, then **`Left`** in `label` 600 with the amount in `moneyLarge` (`textPrimary`; negative `◆ −₹1,200` in `overspent`). Equals Home's Left.

**Zero rules (Gate 3, D-089; same as Home):** a Saved or Overspent of ₹0, or under ₹1 (which reads `₹0`), has **no mark** and is `textPrimary`; the mark and colour start at ₹1 (100 paise). A **Left below zero by less than ₹1 reads `₹0`**, neutral, no ◆ and never `−₹0` (D-050); ◆ starts at −₹1.

## 5. Rounding note (D-053)
`ⓘ Totals use exact amounts, so they can differ by a few rupees from the parts.` (D-062) Shown only when a shown month line differs from the sum of the shown period lines for the same figure (computed on the displayed whole rupees). Not shown otherwise.

## 6. What changed card
Card, padding 16 dp. Header `What changed` (`title`) + (i). Then one line per stored period record, oldest first, as a two-column ledger:
- Left column, 64 dp fixed: the date `1 Nov` (`label` 500, `textPrimary`); same-day changes add the time on a second line `10:00` (`caption`, `textSecondary`).
- Right column: the text (`body`, `textPrimary`, amounts Plex 600), wrapping only at ` → `, `, ` and ` · `:
  - `Month started: salary ₹40,000, fixed costs ₹15,100 → ₹830/day`
  - `Salary ₹40,000 → ₹35,000 → ₹552/day for the 18 days left`
  - replaced same day: `Rent ₹10,000 → ₹13,000 (replaced the same day)` in `textSecondary`
  - Wording (D-081 (5), (6)): **one line per stored record**, each comparing with the **previous stored record**, so a second change on the same day shows its own old value: `20 Nov 10:00 · Rent ₹10,000 → ₹13,000 (replaced the same day)` then `20 Nov 18:00 · Rent ₹13,000 → ₹11,000 → ₹763/day for the 15 days left`. Only the last record of a day carries `→ …/day`; earlier ones end `(replaced the same day)`.
  - Spending target (Gate 3, D-089): set `Spending target set to ₹25,000`; removed `Spending target removed`; changed `Spending target ₹20,000 → ₹25,000` (the same pattern as `Salary ₹40,000 → ₹35,000`). The day details line reuses these words (`day-details.md` §3.1).
  - Fixed cost added: `Fixed cost added: Gym ₹500 → ₹…/day for the 16 days left`; removed: `Fixed cost removed: EMI ₹5,000 → ₹…/day for the …`; renamed: `Rent renamed to House rent → ₹830/day for the 15 days left` (name only, so the daily amount does not move). Several changes in one save are joined with ` · ` (`Salary ₹40,000 → ₹35,000 · Rent ₹10,000 → ₹13,000`).
  - A day whose changes net to nothing: both lines are listed as above; the period reason (§7) reads `Changed and changed back`, and the daily budget is the same as before.
- Hairlines between lines. Single period: under the first line, `No changes this month.` (`body`, `textSecondary`).
- Mid-month first month: `10 Nov` · `Month started partway: money left ₹24,900, still to pay ₹0 → ₹996/day`.

## 7. Period card
Card, padding 16 dp:

| Part | Spec |
|---|---|
| Overline | `Period 2 of 2` (`caption` 500, `textSecondary`) |
| Heading | `13 Nov – 30 Nov · 18 days` (`title`) + ` · in progress` (`body`, `textSecondary`) for the current period. A **one-day** period has no range dash: `30 Nov · 1 day` (D-081 (4)). Semantics: heading. |
| Why it started | `history` icon 16 dp + reason (`label` 500, `textPrimary`): `Month started` · `Month started partway` · `Salary changed` · `Target changed` · `Rent changed` · `Fixed cost added: Gym ₹500` · `Fixed cost removed: EMI ₹5,000` · `Money left changed` · `Rent renamed to House rent` · `Changed and changed back` (same-day changes that net to nothing), several joined with ` · `. |
| Values in force | Ledger rows: `Salary` · `Spending target` (only if set) · `Fixed costs` with a trailing `expand_more` (the row is a button; expanded: items indented 16 dp in `body` `textSecondary`, `Rent ₹10,000`, `EMI ₹5,000`, `Subscriptions ₹100`; chevron rotates, `motionBase`). Mid-month first: `Money left` · `Still to pay` (expandable the same way when items exist). |
| Working strip (S-3) | `₹40,000 − ₹15,100 fixed = ₹24,900 over 30 days → ₹830/day (i)`; later period `₹35,000 − ₹15,100 fixed = ₹19,900, minus ₹9,960 already budgeted = ₹9,940 over 18 days → ₹552/day (i)`; mid-month `₹24,900 − ₹0 still to pay = ₹24,900 over 25 days → ₹996/day (i)`; 1-day period `… = ₹10,830 over 1 day → ₹10,830/day`. **Rules (D-081 (2), (3)):** the line starts with the amount **actually spread** (the spending target when one is set, else the salary) and never names the target, e.g. with a ₹20,000 target `₹20,000 − ₹15,100 fixed = ₹4,900 over 30 days → ₹163/day` (the Values rows above show Salary and Spending target); `, minus ₹X already budgeted` is **left out when X is ₹0**, e.g. a change on the first day `₹35,000 − ₹15,100 fixed = ₹19,900 over 30 days → ₹663/day`, or a change that removes a shortfall `₹30,000 − ₹21,000 fixed = ₹9,000 over 15 days → ₹600/day`. |
| Shortfall panel | Replaces the `→ …/day` ending: the strip reads `₹20,000 − ₹21,000 fixed = −₹1,000`, then under it an `overspentSoft` panel (`radiusMd`, padding 12): `◆ ₹1,000 short · ₹0/day (continued anyway)` (`label` 600, `overspent`). Zero case: `neutralSoft` panel, `○ ₹0 left for daily spending · ₹0/day` (`neutral`). Less than ₹1: `◆ less than ₹1 short · ₹0/day (continued anyway)`. |
| Totals for these days | Sub-heading `For these days` (`caption` 500, `textSecondary`), then ledger rows: `Budget` · `Spent` (+ `Refunds` `−₹500` · `Net spent` with refunds) · `Saved` ● · `Overspent` ◆ · `Covered from savings`. Same zero rule as Home (₹0 saved/overspent: `neutral`, no mark). **In the current period** (D-060): `Budget` is the whole period's budget, `Saved` counts ended days only, `Overspent` includes today, so Budget − Net spent is not expected to equal Saved − Overspent − Covered until the period ends (§8.1). |

## 8. Worked examples

### 8.1 Two-period month "so far" (example M20, today Fri 20 Nov)
Corrected 2026-11-16 (T-407, D-081 (8)); numbers are the Tester's seed M20 (`tests/F-013` section 0, `tests/F-014` TC-014-07, -08).
- Header: `1 – 30 Nov 2026 · so far (to Fri, 20 Nov)`.
- **So far:** Money for the month ₹19,900 · Spent ₹13,000 · Saved ● ₹2,115 · Covered from savings ₹200 · Overspent ◆ ₹537 · Savings pot ₹1,915 · **Left ₹6,900** (= Home).
- **What changed:** `1 Nov · Month started: salary ₹40,000, fixed costs ₹15,100 → ₹830/day` / `13 Nov · Salary ₹40,000 → ₹35,000 → ₹552/day for the 18 days left`.
- **Period 1 of 2 · 1 Nov – 12 Nov · 12 days · Month started:** Salary ₹40,000 · Fixed costs ₹15,100 · `₹40,000 − ₹15,100 fixed = ₹24,900 over 30 days → ₹830/day` · Budget ₹9,960 · Spent ₹9,000 · Saved ● ₹1,400 · Overspent ◆ ₹240 · Covered from savings ₹200.
- **Period 2 of 2 · 13 Nov – 30 Nov · 18 days · in progress · Salary changed:** Salary ₹35,000 · Fixed costs ₹15,100 · `₹35,000 − ₹15,100 fixed = ₹19,900, minus ₹9,960 already budgeted = ₹9,940 over 18 days → ₹552/day` · Budget ₹9,940 (the whole period) · Spent ₹4,000 (13–20 Nov) · Saved ● ₹715 (13–19 Nov, the days that have ended) · Overspent ◆ ₹297 (20 Nov, today, so far) · Covered ₹0.
- **How it adds up.** Parts: ₹1,400 + ₹715 = ₹2,115 saved; ₹240 + ₹297 = ₹537 overspent; spent ₹9,000 + ₹4,000 = ₹13,000; so no rounding note. Pot ₹2,115 − ₹200 covered = ₹1,915. **Left** ₹19,900 − ₹13,000 = ₹6,900. The 13–20 Nov check: those 8 days budgeted ₹4,417.80 (4 days of ₹552.23 and 4 of ₹552.22), spent ₹4,000, so ₹417.80 is left over; ₹715 saved − ₹297 overspent = ₹418 (shown whole rupees of 715.58 − 297.78 = 417.80). The check line (Budget − Spent = Saved − Overspent − Covered) holds for finished periods like Period 1 (₹960 = ₹1,400 − ₹240 − ₹200); for the current period only the 8 days so far are compared, because Budget is the whole period (D-060). The ₹552 (i): `₹9,940 doesn't divide evenly by 18 days, so the first 4 days get 1 paisa more. That's why you see ₹552 every day.`
- Replaces the first draft (Saved ₹1,856, Overspent ₹531, Pot ₹1,656; Period 2 Saved ₹456, Overspent ₹291), which could not be true: 8 days with ₹4,417.80 budgeted and ₹4,000 spent cannot save ₹456 and overspend ₹291.

### 8.2 The same month, finished (viewed 1 Dec; F-014 §2.6)
`Month total`: Money for the month ₹19,900 · Spent ₹19,000 · Refunds −₹500 · Net spent ₹18,500 · Saved ● ₹2,140 · Covered ₹200 · Overspent ◆ ₹540 · Savings pot ₹1,940 · **Left ₹1,400**. No `so far`, no `in progress`.

### 8.3 Rounding note (F-014 AC-12)
Two periods with net spent ₹4,500.60 each: each period shows `Net spent ₹4,500`; the month shows `₹9,001`; the note `Totals use exact amounts, so they can differ by a few rupees from the parts.` appears under the totals card.

### 8.4 Shortfall month (example S, today 8 Nov)
One period, `5 Nov – 4 Dec · 30 days · in progress · Month started`; Salary ₹20,000 · Fixed costs ₹21,000; strip `₹20,000 − ₹21,000 fixed = −₹1,000` + panel `◆ ₹1,000 short · ₹0/day (continued anyway)`. Totals: Money for the month ₹0 · Spent ₹200 · Saved ₹0 · Covered ₹0 · Overspent ◆ ₹200 · Savings pot ₹0 · Short this month ◆ −₹1,000 · Left ◆ −₹1,200.

### 8.5 One period (example A, today 13 Nov)
What changed: `5 Nov · Month started: salary ₹40,000, fixed costs ₹15,100 → ₹830/day` + `No changes this month.`; one period card; the (i) on ₹830/day reads `₹24,900 divides evenly over 30 days.`

### 8.6 Same-day changes and a one-day period (D-081 (4), (5), (6))
- **Two changes on 20 Nov** (rent to ₹13,000 at 10:00, then to ₹11,000 at 18:00; salary day 5, today 25 Nov): What changed `20 Nov 10:00 · Rent ₹10,000 → ₹13,000 (replaced the same day)` and `20 Nov 18:00 · Rent ₹13,000 → ₹11,000 → ₹763/day for the 15 days left`. One period card `20 Nov – 4 Dec · 15 days`, reason `Rent changed`, working `₹40,000 − ₹16,100 fixed = ₹23,900, minus ₹12,450 already budgeted = ₹11,450 over 15 days → ₹763/day`.
- **Changed and changed back** (rent to ₹13,000 at 10:00, back to ₹10,000 at 18:00): lines `20 Nov 10:00 · Rent ₹10,000 → ₹13,000 (replaced the same day)` and `20 Nov 18:00 · Rent ₹13,000 → ₹10,000 → ₹830/day for the 15 days left`; reason `Changed and changed back`; the daily budget stays ₹830.
- **Added / removed / renamed:** `Fixed cost added: Gym ₹500`, `Fixed cost removed: EMI ₹5,000`, `Rent renamed to House rent` (reason and What changed line use the same words).
- **One-day period** (salary raised on the last day, 30 Nov): heading `30 Nov · 1 day`; working `₹50,000 − ₹15,100 fixed = ₹34,900, minus ₹24,070 already budgeted = ₹10,830 over 1 day → ₹10,830/day`; (i) `₹10,830 divides evenly over 1 day.`
- **Change on day one** (salary lowered at 15:00 on 1 Nov): one card `1 Nov – 30 Nov · 30 days`; working has no `minus ₹0` part: `₹35,000 − ₹15,100 fixed = ₹19,900 over 30 days → ₹663/day`.

## 9. States

| State | What the user sees |
|---|---|
| First-time | Normal; no hint. |
| Normal | §3. |
| Empty | A month with no spends yet: all totals ₹0 (neutral, no marks), Left = Money for the month; periods and What changed as normal. There is always at least one period, so there is no empty screen. |
| Loading | Title and switcher shown; cards drawn with headers and the static placeholder bars (`home-summary.md` §7), never `₹0`. Semantics `Loading the statement`. Changing month keeps the old content until the new one is ready (AC-17: under 1 s for 10 periods). |
| Load error | Under the switcher: empty state (§7.10) `Couldn't load your data` · `Tap Try again. Nothing has been lost.` · Primary `Try again`. Neutral. |
| Shortfall month | §8.4; the change that caused a shortfall shows the panel in its own period (`₹2,550 short`). |
| Two-period month | §8.1; 10+ periods are all listed, never collapsed. |
| Mid-month first / late setup | Not-budgeted line at the top; one period `Month started partway`, `Money left` / `Still to pay`, no Salary row. |
| Past month | `Month total`, `Ended` tag, `This month` button, no `in progress`. |
| New month not set up | Opens on last month (as a past month). |
| Permission denied | Not applicable. |

## 10. Themes

| Element | Light | Dark | Dim |
|---|---|---|---|
| Working strip fill / text | `#EEEAE2` / `#1C1B22` (14.24) | `#0A0A0D` / `#F2F0EA` (17.35) | `#24221F` / `#EEE9E0` (13.12) |
| Shortfall panel | `#F6E0DC` / `#B4372F` (4.71) | `#3A1A17` / `#FF7B6F` (6.20) | `#4A3230` / `#FF9C8E` (5.81) |
| Saved / Overspent amounts | `#1A7044` / `#B4372F` on card | `#52C98B` / `#FF7B6F` | `#80D3A1` / `#FF9C8E` |
| Replaced-same-day line | `#5C5864` on card (6.81) | `#A8A5B1` (7.38) | `#BEB7AB` (6.50) |
| Arrival flash (start colour) | `#E7E6F6` | `#25264A` | `#3E3D55` |

All pairs in design system §3.

## 11. Largest text (2.0×, 360 × 640 dp) and landscape (640 × 360)
- **Working strip:** wraps only at ` = `, `, minus ` and ` → `; e.g. at 2.0× `₹35,000 − ₹15,100 fixed` / `= ₹19,900,` / `minus ₹9,960 already budgeted` / `= ₹9,940 over 18 days` / `→ ₹552/day (i)`. Amounts never split (word joiner after ₹, non-breaking digits, design system §4.3). **Relaxed rule (Gate 3, D-089):** when one of those chunks is itself wider than the strip, as at the largest text size on a 360 dp phone (the neat five-line layout above does not fit 256 dp at 2.0×), the line may also wrap at ordinary spaces; an operator (`−`, `=`, `→`) is then kept with the amount it belongs to, and a break never falls inside an amount, a date or `₹…/day`. The strict rule is used whenever it fits, and it is tested both ways (640 dp and 320 dp at 2.0×).
- **Ledger rows** stack label over amount above 1.3×.
- **What changed:** above 1.3× the date column moves above its text (date on its own line), so the text gets the full width.
- **Headings** wrap: `13 Nov – 30 Nov` / `· 18 days · in progress`.
- **Landscape:** content column max 600 dp, centred.

## 12. Accessibility
- Order: back → title → switcher → not-budgeted line → totals card (header heading, rows `Saved, ₹2,115` / `Short this month, minus ₹1,000`, each (i) after its row, Left last) → rounding note → What changed (heading, (i), each stored record as one sentence `1 November, month started: salary ₹40,000, fixed costs ₹15,100, ₹830 a day`; same day `20 November, 10:00, rent ₹10,000 to ₹13,000, replaced the same day`; `20 November, 18:00, rent ₹13,000 to ₹10,000, ₹830 a day for the 15 days left`; `Fixed cost added: Gym ₹500` read as written; refunds `Refunds, minus ₹500`; reason `Changed and changed back` read as written) → each period (heading `Period 2 of 2, 13 November to 30 November, 18 days, in progress`; a one-day period `Period 2 of 2, 30 November, 1 day`; reason; values; Fixed costs `Fixed costs, ₹15,100, collapsed, button`; working line as one sentence per F-014 AC-16: `35,000 rupees minus 15,100 rupees fixed equals 19,900 rupees, minus 9,960 rupees already budgeted equals 9,940 rupees, over 18 days, 552 rupees a day`; its (i); totals) → footnote.
- Arrows and marks are not read; the sentences carry them. Every target ≥ 48 dp.

## 13. Copy (final; F-014 §5 matches)

| Control | Label | Description / tooltip / hint |
|---|---|---|
| Back | (icon) | Tooltip `Back` |
| Title | `Month statement` | Month line `<start> – <end> <yyyy>` (+ ` · so far (to <Wkd, d MMM>)`) |
| Totals card | `So far` / `Month total` | — |
| Money for the month | `Money for the month` | (i): `All the daily budgets of this month added together.` |
| Spent / Refunds / Net spent | `Spent` / `Refunds` (`−<amount>`) / `Net spent` | (i) Spent: `Everything you spent, before any refunds.` (the gross figure; Home's `Spent so far` is net, and the Refunds and Net spent rows follow this one). Refunds as F-013; Net spent: `What you spent minus refunds.` |
| Saved / Covered / Overspent / Savings pot | `Saved` / `Covered from savings` / `Overspent` / `Savings pot` | (i) Saved: `Money left over on days that have ended. Today's leftover joins at midnight.` · Covered: `Money you moved from your savings pot to a day you overspent.` (day details says "to this day"; here it is a month, so "a day you overspent") · Overspent: `How much you went over on days that aren't covered from savings yet.` · Savings pot: `The money you saved, minus what you used to cover days.` Saved and Overspent are the F-010 words (Gate 3 N-D2: one copy source is a follow-up). |
| Short this month | `Short this month` | (i): F-006 "Shortfall" text |
| Left | `Left` | (i): F-006 "Left" text |
| Rounding note | — | `Totals use exact amounts, so they can differ by a few rupees from the parts.` |
| What changed | `What changed` | (i): `Every time you changed your salary, target or fixed costs. Days before a change keep their budget.` |
| Change line | — | First `Month started: salary <x>, fixed costs <y> → <daily>/day`; mid-month `Month started partway: money left <x>, still to pay <y> → <daily>/day`; later `<what changed> → <daily>/day for the <n> days left`; one line per stored record, each against the previous record; same day `<old> → <new> (replaced the same day)` with the time (only the day's last record carries `→ <daily>/day …`); `Fixed cost added: <name> <amount>` · `Fixed cost removed: <name> <amount>` · `<old name> renamed to <new name>` |
| Reason (period) | — | `Changed and changed back` when same-day changes net to nothing; others as §7 |
| No changes | — | `No changes this month.` |
| Period overline | `Period <i> of <n>` | — |
| Period heading | `<d MMM> – <d MMM> · <n> days` (+ ` · in progress`); one day `<d MMM> · 1 day` | Reasons as §7 |
| Fixed costs expand | `Fixed costs <total>` | Hint `Show the fixed costs in this period` / expanded `Hide the fixed costs` |
| For these days | `For these days` | — |
| Working line | — | As §7: starts with the amount spread (target if set, else salary), `, minus <x> already budgeted` only when x is above ₹0, ends `over <n> days` / `over 1 day → <daily>/day` |
| Shortfall | — | `<amount> short · ₹0/day (continued anyway)` / `₹0 left for daily spending · ₹0/day` / `less than ₹1 short · ₹0/day (continued anyway)` |
| Daily budget (i), singular | — | One extra-paisa day (r = 1): `<amount> doesn't divide evenly by <n> days, so the first day gets 1 paisa more. That's why you see <daily> every day.` (singular `the first day`, Gate 3, D-089) |
| Target change line | — | `Spending target set to <amount>` · `Spending target removed` · `Spending target <old> → <new>` (D-089) |
| Daily budget (i) | — | `<amount> doesn't divide evenly by <n> days, so the first <r> days get 1 paisa more. That's why you see <daily> every day.` / `<amount> divides evenly over <n> days.` |
| Not budgeted | — | `<start> – <end>: not budgeted (before you started).` |
| Footnote | — | `Amounts are in whole rupees. Calculations use exact amounts.` |
| Loading | — | `Loading the statement` |

## 14. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-11 | First version (Phase 3 planned ahead, D-033). Decisions S-1 … S-6 | Designer |
| 2026-11-16 | Rounding note now says "a few rupees" instead of "₹1" (Owner confirmed D-062 applies; T-227). Under-₹1 rule unchanged | Designer |
| 2026-11-16 | T-407 (D-081, D-086): §8.1 and the Owner preview corrected with seed M20 (month Saved ₹2,115, Overspent ◆ ₹537, Pot ₹1,915, Left ₹6,900; Period 2 Spent ₹4,000, Saved ₹715, Overspent ₹297) and the arithmetic shown; working line starts with the amount actually spread and drops `, minus ₹0 already budgeted`; one-day heading `30 Nov · 1 day`; What changed: one line per stored record, wording for added / removed / renamed fixed costs, old value on a same-day line; reason `Changed and changed back`; refunds `−₹500` confirmed (AC-11 aligned); new §8.6; accessibility sentences and copy rows added; the "a few rupees" note is unchanged | Designer |
| 2026-11-19 | T-465 (Gate 3, D-089): §11 and S-3 the working line relaxes to wrapping at ordinary spaces (operator kept with its amount, never inside an amount) when a chunk is wider than the strip; §4 totals marks read `● ₹2,115` with no extra word, ₹0 or under-₹1 Saved and Overspent have no mark, a Left below zero by under ₹1 reads `₹0`; §6 and §13 target-change wording, singular `the first day gets 1 paisa more`, and the (i) texts of Spent, Saved, Overspent, Savings pot and Covered | Designer |

## 15. Notes for the Project Manager
1. Refunds read `−₹500` here and in day details; F-014 AC-11 now says the same (D-081 (1)).
2. F-014 team note (₹(n−1) gap): resolved. The Owner confirmed on 2026-11-16 that D-062 "a few rupees" applies, so the note reads "can differ by a few rupees from the parts". This stays true with 3+ periods, where the gap can be ₹2 or more (T-227).
3. New copy: `Period <i> of <n>`, `For these days`, mid-month change line, `Hide the fixed costs`, `Loading the statement`.

---

## Owner preview

### Two-period month so far, today Fri 20 Nov (Light)
```
┌──────────────────────────────────────┐
│ ←                                    │
│ Month statement                      │
│ 1 – 30 Nov 2026 · so far     ‹    ›  │
│ (to Fri, 20 Nov)                     │
│ ╭──────────────────────────────────╮ │
│ │ So far                           │ │
│ │ Money for the month (i)  ₹19,900 │ │
│ │ Spent (i)                ₹13,000 │ │
│ │ Saved (i)               ● ₹2,115 │ │
│ │ Covered from savings (i)    ₹200 │ │
│ │ Overspent (i)           ◆   ₹537 │ │
│ │ Savings pot (i)           ₹1,915 │ │
│ │──────────────────────────────────│ │
│ │ Left (i)                  ₹6,900 │ │
│ ╰──────────────────────────────────╯ │
│ ╭──────────────────────────────────╮ │
│ │ What changed (i)                 │ │
│ │ 1 Nov   Month started: salary    │ │
│ │         ₹40,000, fixed costs     │ │
│ │         ₹15,100 → ₹830/day       │ │
│ │──────────────────────────────────│ │
│ │ 13 Nov  Salary ₹40,000 → ₹35,000 │ │
│ │         → ₹552/day for the 18    │ │
│ │         days left                │ │
│ ╰──────────────────────────────────╯ │
│ ╭──────────────────────────────────╮ │
│ │ Period 1 of 2                    │ │
│ │ 1 Nov – 12 Nov · 12 days         │ │
│ │ ⟲ Month started                  │ │
│ │ Salary                   ₹40,000 │ │
│ │ Fixed costs            ₹15,100 ⌄ │ │
│ │ ┌──────────────────────────────┐ │ │
│ │ │ ₹40,000 − ₹15,100 fixed      │ │ │
│ │ │ = ₹24,900 over 30 days       │ │ │
│ │ │ → ₹830/day (i)               │ │ │
│ │ └──────────────────────────────┘ │ │
│ │ For these days                   │ │
│ │ Budget                    ₹9,960 │ │
│ │ Spent                     ₹9,000 │ │
│ │ Saved                   ● ₹1,400 │ │
│ │ Overspent               ◆   ₹240 │ │
│ │ Covered from savings        ₹200 │ │
│ ╰──────────────────────────────────╯ │
│ ╭──────────────────────────────────╮ │
│ │ Period 2 of 2                    │ │
│ │ 13 Nov – 30 Nov · 18 days        │ │
│ │ · in progress                    │ │
│ │ ⟲ Salary changed                 │ │
│ │ Salary                   ₹35,000 │ │
│ │ Fixed costs            ₹15,100 ⌄ │ │
│ │ ┌──────────────────────────────┐ │ │
│ │ │ ₹35,000 − ₹15,100 fixed      │ │ │
│ │ │ = ₹19,900, minus ₹9,960      │ │ │
│ │ │ already budgeted = ₹9,940    │ │ │
│ │ │ over 18 days → ₹552/day (i)  │ │ │
│ │ └──────────────────────────────┘ │ │
│ │ For these days                   │ │
│ │ Budget                    ₹9,940 │ │
│ │ Spent                     ₹4,000 │ │
│ │ Saved                     ● ₹715 │ │
│ │ Overspent                 ◆ ₹297 │ │
│ │ Covered from savings          ₹0 │ │
│ ╰──────────────────────────────────╯ │
│ Amounts are in whole rupees.         │
│ Calculations use exact amounts.      │
└──────────────────────────────────────┘
```
(Every line adds up: ₹1,400 + ₹715 = ₹2,115 saved; ₹240 + ₹297 = ₹537 overspent; ₹9,000 + ₹4,000 = ₹13,000 spent; ₹2,115 − ₹200 covered = ₹1,915 in the pot; ₹19,900 − ₹13,000 = ₹6,900 left, the same as Home. In Period 2, Budget ₹9,940 is the whole period, Saved ₹715 counts 13–19 Nov and Overspent ₹297 is today's. The working is in a soft grey strip. Tapping (i) next to ₹552/day: "₹9,940 doesn't divide evenly by 18 days, so the first 4 days get 1 paisa more. That's why you see ₹552 every day.")

### What changed with same-day changes, and a one-day period (Dim)
```
┌──────────────────────────────────────┐
│ ╭──────────────────────────────────╮ │
│ │ What changed (i)                 │ │
│ │ 5 Nov   Month started: salary    │ │
│ │         ₹40,000, fixed costs     │ │
│ │         ₹15,100 → ₹830/day       │ │
│ │──────────────────────────────────│ │
│ │ 20 Nov  Rent ₹10,000 → ₹13,000   │ │
│ │ 10:00   (replaced the same day)  │ │
│ │──────────────────────────────────│ │
│ │ 20 Nov  Rent ₹13,000 → ₹10,000   │ │
│ │ 18:00   → ₹830/day for the 15    │ │
│ │         days left                │ │
│ ╰──────────────────────────────────╯ │
│ ╭──────────────────────────────────╮ │
│ │ Period 2 of 2                    │ │
│ │ 20 Nov – 4 Dec · 15 days         │ │
│ │ ⟲ Changed and changed back       │ │
│ ╰──────────────────────────────────╯ │
│ ╭──────────────────────────────────╮ │
│ │ Period 2 of 2                    │ │
│ │ 30 Nov · 1 day                   │ │
│ │ ⟲ Salary changed                 │ │
│ │ ┌──────────────────────────────┐ │ │
│ │ │ ₹50,000 − ₹15,100 fixed      │ │ │
│ │ │ = ₹34,900, minus ₹24,070     │ │ │
│ │ │ already budgeted = ₹10,830   │ │ │
│ │ │ over 1 day → ₹10,830/day (i) │ │ │
│ │ └──────────────────────────────┘ │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```
(Each stored change is its own line and compares with the one before it. The last card is from a different month, shown only to illustrate the one-day heading.)

### When the parts don't add up (Dim, totals only)
```
┌──────────────────────────────────────┐
│ ╭──────────────────────────────────╮ │
│ │ Month total                      │ │
│ │ Net spent (i)             ₹9,001 │ │
│ │ ...                              │ │
│ ╰──────────────────────────────────╯ │
│ ⓘ Totals use exact amounts, so they  │
│   can differ by a few rupees from    │
│   the parts.                         │
│ ...                                  │
│ Period 1 · Net spent      ₹4,500     │
│ Period 2 · Net spent      ₹4,500     │
└──────────────────────────────────────┘
```
(Each period really spent ₹4,500.60; together that's ₹9,001.20, so the total shows ₹9,001.)

### Shortfall month, today 8 Nov (Dark, period card)
```
┌──────────────────────────────────────┐
│ ╭──────────────────────────────────╮ │
│ │ Period 1 of 1                    │ │
│ │ 5 Nov – 4 Dec · 30 days          │ │
│ │ · in progress                    │ │
│ │ ⟲ Month started                  │ │
│ │ Salary                   ₹20,000 │ │
│ │ Fixed costs            ₹21,000 ⌄ │ │
│ │ ┌──────────────────────────────┐ │ │
│ │ │ ₹20,000 − ₹21,000 fixed      │ │ │
│ │ │ = −₹1,000                    │ │ │
│ │ └──────────────────────────────┘ │ │
│ │ ╭──────────────────────────────╮ │ │
│ │ │ ◆ ₹1,000 short · ₹0/day      │ │ │
│ │ │ (continued anyway)           │ │ │
│ │ ╰──────────────────────────────╯ │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```
(Totals card above it: Short this month ◆ −₹1,000, Left ◆ −₹1,200.)

### Why these choices
- **Reads like a bank statement you can check by hand:** totals first, then each period's working in a grey strip, ending in the daily budget it produced.
- **"What changed" is a dated ledger**, so "13 Nov · Salary ₹40,000 → ₹35,000 → ₹552/day" answers "why did my budget drop?" in one line; a second change on the same day is its own line with its own old value, and "Changed and changed back" says when nothing really moved.
- **The "so far" example now adds up to the rupee** (corrected with the Tester's seed): 8 days with ₹4,417.80 budgeted and ₹4,000 spent leave ₹418 (₹715 saved − ₹297 overspent).
- **The "a few rupees" rounding note only appears when it's needed**, right under the total it explains.
