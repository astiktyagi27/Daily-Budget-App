# Screen spec: Home — summary card, Safe to spend and the Today card

**Owner of this file:** Designer · **Phase:** 3 (planned ahead, D-033; docs only) · **Features:** F-010 Home summary, F-017 Safe to spend (uses F-002 tokens, F-004 help pattern, F-006 engine numbers, F-008 states) · **Status:** Draft for Phase 3 Gate 2
**Read with:** `docs/features/F-010-home-summary.md`, `docs/features/F-017-safe-to-spend.md` (§5 of both updated to match this file), `calendar.md` (the calendar under these cards), `day-details.md`, `month-setup.md` §10 (Home month states it replaces), `transactions.md` §4 (Today line), `docs/design/design-system.md` §4.3, §7.2, §7.6, §7.8, §7.11. Decisions D-034 … D-043, D-046, D-047, D-050, D-055, D-057, D-058.
Worked numbers are F-010 §2.4 (example A), §2.5 (S), §2.6 (M), §2.7 (F) and F-017 §2.2.

---

## 1. Purpose
Answer two questions the moment Home opens: "how is my month going?" (summary card) and "what can I still spend today?" (Today card), with the calendar right below.

## 2. Design decisions

| # | Question | Decision | Why |
|---|---|---|---|
| H-1 | Where does Safe to spend sit, and how does it avoid looking like today's budget? | A **guide strip** inside the summary card, under the day line: `sunken` fill, `radiusMd`, its own label and (i). Amount in `moneyMedium` **ink** (never green), not in the Today card, calendar or collapsed row (F-017 §2.3). | It is a different kind of number (a guide, not a result). A tinted strip separates it from both the hero and the ledger without a second card. |
| H-2 | Order inside the card | Hero → progress rule → day line → Safe to spend strip → (shortfall panel / late-start caption / budget-changed line) → ledger → `Month statement`. | Matches design system §7.6 (rule directly under the hero). The things that explain the daily number sit next to it. |
| H-3 | ₹0 Saved or Overspent | Shown in `neutral`, **no mark**. ● / ◆ and green / red appear only when the amount is above ₹0. | A green ● next to `₹0` saved (example S) says "good" when nothing was saved. Words carry the meaning; colour only adds to it. |
| H-4 | Negative Left (shortfall or overspent month) | Hero in `overspent` with a 14 dp ◆ before it: `◆ −₹1,200`, then the caption `You're ₹1,200 over for this month.` Collapsed row: `◆ ₹1,200 over this month · ₹0/day` (not `−₹1,200 left`). | "−₹1,200 left" is not plain English. Three cues: sign, ◆, words. |
| H-5 | `Edit this month` | In a ⋮ menu at the top-right of the summary card (F-010 §2.2). | Editing is rare; the card stays a calm read-out. |
| H-6 | Is the Today card tappable-looking? | Yes: trailing `chevron_right` in `textSecondary` on the header row, whole card pressable (`sunken` press fill). | A card that opens something must look like it (F-010 AC-14). |
| H-7 | A new first-time hint for the calendar? | One new hint, `hint.calendar.v1`: `Tap a day to see its spends.` (F-011 §5), shown **above the calendar** and only **after** `hint.home.v1` has been dismissed, so a screen never shows two tips (design system §7.11c). Same card, same behaviour. | Tapping a day is the one non-obvious action on Home. Needs a line in F-004 §5 / `help-pattern.md` §4.2 (Phase 1 docs, not edited here; see §14). |

## 3. Layout (month confirmed)
Inside the shared tab frame (`app-shell.md` §2), top to bottom:
1. Title `Daily Budget App` (`headline`, scrolls).
2. First-time hint `hint.home.v1` (unchanged).
3. **Summary card** (§4), `space4` below the hint / title.
4. **Today card** (§5), `space4` gap. **Left out when today is not a budgeted day** (device date before the first budgeted day or outside the month; D-077 (4), TC-010-59): the summary card is followed directly by the calendar block, with no gap left behind.
5. `hint.calendar.v1` (H-7), only when shown.
6. **Calendar** (`calendar.md`), `space6` above.
7. Bottom padding: nav height + `space6`.

The pinned **collapsed row** (§6) appears once the summary card has scrolled out of view.

## 4. Summary card
Card (design system §7.2), padding 20 dp.

| # | Part | Spec |
|---|---|---|
| 1 | Header row | Overline `Left this month` (`label` 500, `textSecondary`) + (i). Right: ⋮ icon button (`more_vert`, 24 dp, 48 dp target, `textSecondary`), tooltip `More`. Opens a menu (Material `PopupMenu` themed `surface`, hairline, `radiusSm`) with one item `Edit this month` (`label`, 48 dp) → F-008 edit mode. |
| 2 | Hero | Engine **Left** in `moneyHero` `textPrimary`: `₹19,370`. Negative: `◆ −₹1,200` in `overspent` (◆ 14 dp, `space2` gap), then caption `You're ₹1,200 over for this month.` (`body`, `textPrimary`). Exactly ₹0: `₹0` in `textPrimary`, no mark. **A Left below zero by less than ₹1 (−99 paise or less negative) reads `₹0`**, neutral, no ◆ and never `−₹0` (D-050; built as a display rule of the summary model, Gate 3, D-089); ◆ and the caption start at −₹1. Counts up/down over `motionCount` on change. |
| 3 | Progress rule | 4 dp, `radiusFull`, `textPrimary` on `neutralSoft`, full card width, `space3` under the hero. Spent so far ÷ spendable; full when spent ≥ spendable or spendable ≤ ₹0; empty when spent so far ≤ ₹0. Decorative. |
| 4 | Day line | `body` `textSecondary`, `space3` below: `₹830/day · 5 Nov – 4 Dec` (amount in Plex 600 `textPrimary`). Mid-month first or late setup: `₹996/day · 10 Nov – 4 Dec`. |
| 5 | Late-start caption | Only for a mid-month first month or a late setup (D-034, D-057): `This month's budget started on 10 Nov.` (`body`, `textSecondary`), directly under the day line. |
| 6 | Safe to spend strip (F-017) | `space3` below. `sunken` fill, `radiusMd`, padding 12 × 16 dp. Line 1: `Safe to spend` (`label` 500, `textSecondary`) + (i). Line 2: `₹899 a day` (`moneyMedium`, `textPrimary`) + ` · 22 days left` (`body`, `textSecondary`); wraps only at ` · `. Variants: **any positive amount below ₹1 a day, including 10 paise over 22 days, reads `less than ₹1 a day · 1 day left`** (D-076 (2)); `Nothing left to spread over the rest of the month.` (`body`, `textPrimary`, no amount) appears only when the amount to spread is ₹0 or below. Never coloured green or red. **Hidden** for a past month, no month, a new month not set up, and **when today is not a budgeted day** (D-076 (1): it is hidden, never clamped to a day that was never today; the summary card still shows). |
| 7 | Shortfall panel | Only in a shortfall month (D-036) or zero month (D-043), under the strip. As `month-setup.md` §10.2: `overspentSoft` fill, `radiusMd`, padding 16 dp. Line 1 `◆ −₹1,000 this month` (`label` 600, `overspent`); line 2 `Every spend this month counts as overspent.` (`body`, `textPrimary`). Zero month: `neutralSoft` fill, `○ ₹0 left for daily spending` (`label` 600, `neutral`), no line 2. Hidden when the current period's shortfall is ₹0. |
| 8 | Budget-changed line | Only when the month has more than one period (D-037). Inline note: 16 dp `history` icon (`textSecondary`) + `Budget changed on 13 Nov` (`body`, `textSecondary`) + ` · ` + Text button `See month statement` (`accent`, 48 dp target). Names the latest change date. → F-014 for this month. |
| 9 | Ledger | Hairline, then rows (label + (i) left in `body` `textSecondary`; amount right in `moneyMedium` `textPrimary`; row min 40 dp; the (i) has its own 48 dp target): `Salary` · `Spending target` (only when a lower target is set) · `Money left at start` (mid-month / late first month, in place of Salary) · `Fixed costs` · `Spent so far` · `Saved this month` (`saved` + ● when > ₹0, H-3) · `Overspent` (`overspent` + ◆ when > ₹0). **Mark rule (Gate 3, D-089):** Saved and Overspent get their mark and colour at ₹1 or more (100 paise); an amount of ₹0 (including 99 paise or less, which reads `₹0`) is `textPrimary` with **no mark**, the same cut as the month statement's rows. Each ledger row is a `Wrap`: when a very large amount does not fit beside its label it drops under the label (above 1.3× the stacked column takes over, §10). |
| 10 | Savings-pot sub-line | Only when any cover exists, directly under `Saved this month`, indented 16 dp: `₹1,700 in your savings pot · ₹300 used to cover days` (`body`, `textSecondary`, amounts Plex 600 `textPrimary`). Wraps at ` · `. |
| 11 | Month statement | Hairline, then a full-width Text-style row (48 dp): `Month statement` (`label` 600, `accent`) + trailing `chevron_right` (`accent`). Hint `See how this month's budget was worked out`. → F-014 current month. |

**Refunds bigger than spends** (F-010 §4): Spent so far can read `−₹300`; the rule is then empty and Left is above spendable. Nothing else changes.

## 5. Today card
Card (§7.2), padding 16 dp, `space4` below the summary card. Whole card is one button (press fill `sunken`, `motionFast`).
- Header row: `Today · Fri, 13 Nov` (`title`) + (i), trailing `chevron_right` (`textSecondary`). (i) title `Today`, body `Today's budget minus what you've spent today. Whatever is left at midnight goes to your savings pot.` (same as `transactions.md` §4).
- **The line** exactly as `transactions.md` §4 (words, colours, marks, no-break units, wrap only at ` · `): `budget ₹830 · spent ₹420 · ● ₹410 left today`. Results: `₹x left today` ● `saved` · `on budget` ○ `neutral` · `overspent ₹x` ◆ `overspent` · `less than ₹1 left today` ● · `overspent less than ₹1` ◆.
- **Refunds line** (only when today has refunds): `Includes ₹500 back from refunds` (`body`, `textSecondary`), under the line. Negative net: `budget ₹830 · spent −₹200 · ● ₹1,030 left today`.
- **Covered today** (D-048 (2)): the line reflects the engine result (`on budget` after a full cover). No extra line here; day details explains it.
- **Shortfall month:** the line reads `budget ₹0 · spent ₹0 · ○ on budget`. The shortfall panel is **not** repeated here (it is in the summary card); on the Transactions tab the F-009 Today card keeps its own panel.
- Tap → day details for today (`day-details.md`). Tap hint `See today's details`.
- Semantics: one sentence, `Today, Friday 13 November: budget ₹830, spent ₹420, ₹410 left today.` (+ ` Includes ₹500 back from refunds.`), button, hint `See today's details`. The (i) is its own stop.

## 6. Collapsed row (on scroll)
- When the summary card's bottom edge scrolls above the top of the body, a 56 dp row appears above the page content, under the status bar: `surface` fill, 1 dp `border` bottom rule, padding `space5`. **It is not an overlay (Gate 3, D-089):** the row takes its own 56 dp of space at the top of the Home tab, so the page content below it moves **down by 56 dp** (plus the status bar inset) when the row appears and back up when it leaves; the change is animated (`AnimatedSize`, together with the fade and slide below, `motionFast`). The card is measured in scroll offsets, and the row only appears once the card has fully left the screen, so the shift happens off-screen and reads as the row pushing in. Why: a row a screen reader scrolls into view can then never sit under the pinned row, and measuring in scroll offsets stops the flicker a layout shift would cause. Content: `₹19,370 left · ₹830/day` (`moneyMedium` for amounts, `body` `textSecondary` for words). Negative: `◆ ₹1,200 over this month · ₹0/day` with ◆ and the amount in `overspent`.
- Enters with a 120 ms fade + 8 dp slide down (`motionFast`); leaves the same way when the card returns. Tapping it scrolls Home to the top (`motionEmphasis`).
- Safe to spend is **not** in this row (F-017 §2.3).
- Semantics: `₹19,370 left this month, ₹830 a day`, button, hint `Scroll to the top`. Negative: `₹1,200 over this month, ₹0 a day`.
- Not shown at text scale above 1.3× or in landscape (it would cover too much of the screen); the title area simply scrolls.

## 7. States

| State | Home shows |
|---|---|
| First-time (month just confirmed) | Title, `hint.home.v1`, summary card, Today card, calendar. Day 1: Saved and Overspent `₹0` (neutral, no marks), Safe to spend equals the daily budget (`₹830 a day · 30 days left`). |
| Normal | §3. |
| Today not a budgeted day (device date before the first budgeted day, or outside the month) | Title, hints as usual, summary card **without** the Safe to spend strip, **no Today card**, calendar with every budget day upcoming and no today ring (`calendar.md` §5.4). The ledger, hero and day line are unchanged. Reading order skips both. |
| No confirmed month | `month-setup.md` §10.1 empty state only (`Your daily budget lives here` + Primary `Set up your month`). No cards, no calendar. |
| New month started, not set up | `month-setup.md` §10.3 card (`Your new month has started` + `Set up this month`) in place of both cards; then the calendar showing last month, header `Last month · 5 Oct – 4 Nov`, read-only (`calendar.md` §6.6). No Safe to spend. |
| Loading | Card outlines with static placeholder bars (`neutralSoft`, `radiusXs`, 12 dp tall) where figures go: hero bar 160 dp wide, ledger bars 64 dp. Labels are shown; **no figure, no `₹0`**. No shimmer or pulse. Semantics: one node `Loading your month`. Normally invisible (data is ready before the first frame); appears only for slow reads. |
| Load error | `month-setup.md` §10.4 (`Couldn't load your data` · `Tap Try again. Nothing has been lost.` · Primary `Try again`) in place of the cards and calendar. Neutral, never red. |
| Shortfall month (example S) | Hero `◆ −₹1,200` + caption; day line `₹0/day · 5 Nov – 4 Dec`; Safe to spend `Nothing left to spread over the rest of the month.`; shortfall panel; ledger with Saved `₹0` neutral, Overspent `◆ ₹200`; Today `budget ₹0 · spent ₹0 · ○ on budget`. |
| Zero month (D-043) | Hero `₹0` (or negative once spent), `○ ₹0 left for daily spending` panel, `₹0/day`. |
| Two-period month (example M, 20 Nov) | Day line `₹552/day · 1 – 30 Nov` (today's budget); Salary row `₹35,000` (current period); budget-changed line `Budget changed on 13 Nov · See month statement`; Today card `budget ₹552 · …`. |
| Mid-month first / late setup (example F) | No Salary row; `Money left at start ₹24,900`; Fixed costs `₹0` (still to pay); day line `₹996/day · 10 Nov – 4 Dec`; caption `This month's budget started on 10 Nov.` |
| Error after an action | Not on Home: saves happen in F-009 / F-012, which show their own errors. |
| Permission denied | Not applicable (Phase 3 asks for no permission). |

## 8. Interactions and motion
- Any add, edit, delete, refund or cover updates every figure in place; changed amounts count to the new value (`motionCount`, 600 ms; instant with Remove animations or TalkBack on). Safe to spend does not change for covers or for today's own spends (F-017), so it does not animate then.
- Midnight while Home is in the background: on resume, the Today card header, line and calendar ring move to the new day without animation (a cross-fade `motionBase` of the Today card only). Undo snackbars (cover, day details) stay up while TalkBack is on (design system §7.9, D-077 (5)); Home adds none.
- (i) → help sheet (§7.11b). ⋮ → menu. `See month statement` / `Month statement` → F-014 (push, standard transition). Today card → day details (push).
- Back from day details / statement returns to Home at the same scroll position (F-012 AC-1).

## 9. Themes

| Element | Light | Dark | Dim |
|---|---|---|---|
| Card / page | `#FFFDF8` on `#F6F3ED` | `#17171D` on `#0E0E12` | `#34312D` on `#2A2825` |
| Hero / negative hero | `#1C1B22` / `#B4372F` (5.86 on card) | `#F2F0EA` / `#FF7B6F` (7.07) | `#EEE9E0` / `#FF9C8E` (6.41) |
| Safe to spend strip fill / amount / words | `#EEEAE2` / `#1C1B22` (14.24) / `#5C5864` (5.77) | `#0A0A0D` / `#F2F0EA` (17.35) / `#A8A5B1` (8.17) | `#24221F` / `#EEE9E0` (13.12) / `#BEB7AB` (7.97) |
| Saved ● / Overspent ◆ amounts | `#1A7044` (6.00) / `#B4372F` (5.86) | `#52C98B` (8.57) / `#FF7B6F` (7.07) | `#80D3A1` (7.24) / `#FF9C8E` (6.41) |
| ₹0 saved / overspent | `#68646E` (5.68) | `#9F9CA7` (6.62) | `#B6AFA4` (5.95) |
| Progress rule | `#1C1B22` on `#EAE6DF` | `#F2F0EA` on `#24242B` | `#EEE9E0` on `#3D3A35` |
| Shortfall panel | `#F6E0DC` / `#B4372F` (4.71) | `#3A1A17` / `#FF7B6F` (6.20) | `#4A3230` / `#FF9C8E` (5.81) |
| `Month statement`, `See month statement` | `#3A3DB0` (8.35) | `#9C9FFF` (7.49) | `#ABACF6` (6.14) |
| Collapsed row | `#FFFDF8` + `#DED8CD` rule | `#17171D` + `#2A2A33` | `#34312D` + `#48453F` |

Every pair is in design system §3. Auto follows the phone (Light or Dark).

## 10. Largest text (2.0×, 360 × 640 dp) and landscape (640 × 360)
- **Hero:** `moneyHero` 80 sp at 2.0×. `₹19,370` fits; `₹10,00,00,000` and `◆ −₹1,200` do **not** wrap: the hero sits in a `FittedBox(scaleDown)` on one line, so a figure too wide for the card shrinks as a whole (about 38 sp for `₹10,00,00,000` at 2.0× on 360 dp) and is never truncated or split; normal figures are not scaled (Gate 3, D-089; replaces "wrap as a unit below the overline"). Every other amount stays plain text. The ⋮ stays top-right of the header row.
- **Ledger:** below 1.3× label and amount share a line. Above 1.3× each row stacks: label + (i) on the first line, amount on the next, left-aligned (F-010 AC-18). Hairlines stay between rows. At 1.3× and below the row is a `Wrap`: label and amount share a line, and a very large amount drops under its label rather than overflowing.
- **Day line:** the line `₹830/day · 5 Nov – 4 Dec` breaks only at ` · `, so a long line is `₹830/day ·` / `5 Nov – 4 Dec`; a date or an amount never splits (Track A fix at Gate 3).
- **Day line, strip, sub-line, Today line:** wrap only at ` · `. The strip's line 2 can become two lines (`₹899 a day` / `22 days left`).
- **Today card:** header `Today · Fri, 13 Nov` wraps; chevron stays top-right.
- **Collapsed row:** not used above 1.3× (§6).
- **Landscape:** one column, content max width 600 dp, centred on `bg`. Cards and calendar keep their portrait layout at that width (calendar cells capped at 56 dp, design system §7.5). No collapsed row.

## 11. Accessibility
- Reading order: title → hint → summary card (overline + hero as one node `Left this month, ₹19,370. ₹830 a day, 5 November to 4 December.`; negative `Left this month, minus ₹1,200. You're ₹1,200 over for this month.`) → its (i) → ⋮ `More` → late-start caption → Safe to spend (`Safe to spend, ₹899 a day, 22 days left`) → its (i) → shortfall panel (`Minus ₹1,000 this month. Every spend this month counts as overspent.`) → budget-changed line → each ledger row (`Overspent, ₹470`; ₹0: `Saved this month, ₹0`) then its (i) → savings-pot sub-line → `Month statement` → Today card → calendar.
- The progress rule and marks are decorative (excluded). Every target ≥ 48 dp.
- Live updates are not announced (the user caused them, and the snackbar of the action already speaks).

## 12. Copy (final; F-010 §5 and F-017 §5 match)

| Control | Label | Description / tooltip / hint |
|---|---|---|
| Hero | `Left this month` | (i): `What's budgeted for this month minus what you've spent so far.` |
| Negative caption | — | `You're <amount> over for this month.` |
| Day line | — | `<daily>/day · <start> – <end>` |
| Late-start caption | — | `This month's budget started on <d MMM>.` |
| Safe to spend | `Safe to spend` | Value `<amount> a day · <n> days left` (`1 day left`); `less than ₹1 a day · <n> days left`; nothing: `Nothing left to spread over the rest of the month.` (i): `Everything left this month, including your savings pot, spread evenly over the days left (today included). It's a guide: your daily budget doesn't change, and it stays the same all day.` |
| Shortfall panel | — | `−<amount> this month` · `Every spend this month counts as overspent.`; zero: `₹0 left for daily spending` |
| Budget changed | `Budget changed on <d MMM>` | Button `See month statement`, hint `Open the month statement` |
| Salary | `Salary` | (i): `The salary you entered for this month. If you changed it, this is the latest amount.` |
| Spending target | `Spending target` | (i): `The amount you chose to spend this month, including fixed costs.` |
| Money left at start | `Money left at start` | (i): `How much you had when you started using the app partway through the month.` |
| Fixed costs | `Fixed costs` | (i): `Rent, EMIs and other monthly bills. They're taken out before your daily budget is worked out.` |
| Spent so far | `Spent so far` | (i): `Everything you've spent this month up to now, after refunds.` |
| Saved this month | `Saved this month` | (i): `Money left over on days that have ended. Today's leftover joins at midnight.` |
| Savings-pot sub-line | — | `<pot> in your savings pot · <covered> used to cover days` |
| Overspent | `Overspent` | (i): `How much you went over on days that aren't covered from savings yet.` |
| Month statement | `Month statement` | Hint `See how this month's budget was worked out` |
| Overflow | (icon ⋮) | Tooltip `More`; item `Edit this month` (hint `Change this month's salary, target or fixed costs`) |
| Today card | `Today · <Wkd, d MMM>` | (i) title `Today`: `Today's budget minus what you've spent today. Whatever is left at midnight goes to your savings pot.` Hint `See today's details` |
| Refunds line | — | `Includes <amount> back from refunds` |
| Collapsed row | — | `<left> left · <daily>/day`; negative `<amount> over this month · <daily>/day`; hint `Scroll to the top` |
| Calendar hint (`hint.calendar.v1`) | `Tip` | `Tap a day to see its spends.` |
| Loading | — | Screen reader `Loading your month` |

## 13. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-11 | First version (Phase 3 planned ahead, D-033). Decisions H-1 … H-7 | Designer |
| 2026-11-16 | T-310 consistency check (D-076, D-077): Today card and Safe to spend hidden when today is not a budgeted day (§3, §4 item 6, §7); any positive amount reads `less than ₹1 a day`, `Nothing left` only at ₹0 or below (§4 item 6); Undo snackbar note (§8); collapsed row rule already matches D-077 (1). `hint.calendar.v1` row now exists in `help-pattern.md` §4.2 (note 1) | Designer |
| 2026-11-16 | Two-period "example M" mockup (§10) aligned to the corrected seed M20 (T-407, `month-statement.md` §8.1): Saved ₹1,856 → ₹2,115, pot ₹1,656 → ₹1,915, Overspent ₹531 → ₹537 (Left ₹6,900, ₹200 covered unchanged) | Designer |
| 2026-11-16 | Two-period mockup (§10) Today card now `budget ₹552 · spent ₹850 · ◆ overspent ₹297` and Safe to spend `₹704 a day · 11 days left` (canonical M20; caption recomputed: (₹6,900 + ₹850) ÷ 11) | Designer |
| 2026-11-19 | T-465 (Gate 3, D-089): §6 the pinned row takes its own space and pushes the page down 56 dp (not an overlay; animated; measured in scroll offsets); §10 very large hero figures shrink with `FittedBox` instead of wrapping, ledger rows are a `Wrap`, the day line breaks only at ` · `; §4 a Left below zero by under ₹1 reads `₹0` (never `−₹0`), Saved and Overspent show their mark from ₹1 (₹0 and amounts under ₹1 have no mark) | Designer |

## 14. Notes for the Project Manager
1. **`hint.calendar.v1`** (H-7) needs a row in F-004 §5 and `help-pattern.md` §4.2 (done in `help-pattern.md` §4.2 by T-310; F-004 §5 is T-311).
2. **H-3** changes how F-010 §2.5's example block draws `Saved this month ● ₹0`: it becomes `₹0` with no mark. AC-6 only checks the amount, so no AC changes.
3. The collapsed row is not shown above 1.3× text or in landscape (§6). F-010 AC-15 tests it at 1.0×, so it still passes.

---

## Owner preview

### Normal month, today Fri 13 Nov (Light)
```
┌──────────────────────────────────────┐
│ Daily Budget App                     │
│ ╭──────────────────────────────────╮ │
│ │ Left this month (i)            ⋮ │ │
│ │ ₹19,370                          │ │
│ │ ━━━━━━━░░░░░░░░░░░░░░░░░░░░░░░░░ │ │
│ │ ₹830/day · 5 Nov – 4 Dec         │ │
│ │ ┌──────────────────────────────┐ │ │
│ │ │ Safe to spend (i)            │ │ │
│ │ │ ₹899 a day · 22 days left    │ │ │
│ │ └──────────────────────────────┘ │ │
│ │──────────────────────────────────│ │
│ │ Salary (i)               ₹40,000 │ │
│ │ Fixed costs (i)          ₹15,100 │ │
│ │ Spent so far (i)          ₹5,530 │ │
│ │ Saved this month (i)   ● ₹2,000  │ │
│ │ Overspent (i)          ◆   ₹470  │ │
│ │──────────────────────────────────│ │
│ │ Month statement                › │ │
│ ╰──────────────────────────────────╯ │
│ ╭──────────────────────────────────╮ │
│ │ Today · Fri, 13 Nov (i)        › │ │
│ │ budget ₹830 · spent ₹420 ·       │ │
│ │ ● ₹410 left today                │ │
│ ╰──────────────────────────────────╯ │
│ 5 Nov – 4 Dec 2026          ‹    ›   │
│ (calendar continues, see calendar.md)│
│──────────────────────────────────────│
│   ▬                                  │
│   ⌂       ▥        ≣         ⫶       │
│ Home Dashboard Transactions Settings │
└──────────────────────────────────────┘
```
(Spendable ₹24,900; spent ₹5,530 = 22 % of the rule. Safe to spend = (₹19,370 + ₹420 spent today) ÷ 22 days = ₹899. "● ₹2,000" and "● ₹410 left today" are green, "◆ ₹470" red; the Safe to spend strip is a soft grey inset, ink text.)

### After covering 11 Nov with ₹300 (Light, ledger only)
```
│ │ Saved this month (i)   ● ₹2,000  │ │
│ │   ₹1,700 in your savings pot ·   │ │
│ │   ₹300 used to cover days        │ │
│ │ Overspent (i)          ◆   ₹170  │ │
```
(Left stays ₹19,370 and Safe to spend stays ₹899: a cover only moves money you already have.)

### Shortfall month, today Sun 8 Nov (Dim)
```
┌──────────────────────────────────────┐
│ ╭──────────────────────────────────╮ │
│ │ Left this month (i)            ⋮ │ │
│ │ ◆ −₹1,200                        │ │
│ │ You're ₹1,200 over for this      │ │
│ │ month.                           │ │
│ │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │ │
│ │ ₹0/day · 5 Nov – 4 Dec           │ │
│ │ ┌──────────────────────────────┐ │ │
│ │ │ Safe to spend (i)            │ │ │
│ │ │ Nothing left to spread over  │ │ │
│ │ │ the rest of the month.       │ │ │
│ │ └──────────────────────────────┘ │ │
│ │ ╭──────────────────────────────╮ │ │
│ │ │ ◆ −₹1,000 this month         │ │ │
│ │ │ Every spend this month       │ │ │
│ │ │ counts as overspent.         │ │ │
│ │ ╰──────────────────────────────╯ │ │
│ │──────────────────────────────────│ │
│ │ Salary (i)               ₹20,000 │ │
│ │ Fixed costs (i)          ₹21,000 │ │
│ │ Spent so far (i)            ₹200 │ │
│ │ Saved this month (i)          ₹0 │ │
│ │ Overspent (i)          ◆    ₹200 │ │
│ │──────────────────────────────────│ │
│ │ Month statement                › │ │
│ ╰──────────────────────────────────╯ │
│ ╭──────────────────────────────────╮ │
│ │ Today · Sun, 8 Nov (i)         › │ │
│ │ budget ₹0 · spent ₹0 ·           │ │
│ │ ○ on budget                      │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```
(Coral "◆ −₹1,200" hero on warm slate. Saved ₹0 is plain grey with no ●. Left = ₹0 − ₹200 − ₹1,000 short.)

### Two-period month: 1–12 Nov ₹830/day, then ₹552/day; today Fri 20 Nov (Dark)
```
┌──────────────────────────────────────┐
│ ╭──────────────────────────────────╮ │
│ │ Left this month (i)            ⋮ │ │
│ │ ₹6,900                           │ │
│ │ ━━━━━━━━━━━━━━━━━━━━━░░░░░░░░░░░ │ │
│ │ ₹552/day · 1 – 30 Nov            │ │
│ │ ┌──────────────────────────────┐ │ │
│ │ │ Safe to spend (i)            │ │ │
│ │ │ ₹704 a day · 11 days left    │ │ │
│ │ └──────────────────────────────┘ │ │
│ │ ⟲ Budget changed on 13 Nov ·     │ │
│ │   See month statement            │ │
│ │──────────────────────────────────│ │
│ │ Salary (i)               ₹35,000 │ │
│ │ Fixed costs (i)          ₹15,100 │ │
│ │ Spent so far (i)         ₹13,000 │ │
│ │ Saved this month (i)   ● ₹2,115  │ │
│ │   ₹1,915 in your savings pot ·   │ │
│ │   ₹200 used to cover days        │ │
│ │ Overspent (i)          ◆   ₹537  │ │
│ │──────────────────────────────────│ │
│ │ Month statement                › │ │
│ ╰──────────────────────────────────╯ │
│ ╭──────────────────────────────────╮ │
│ │ Today · Fri, 20 Nov (i)        › │ │
│ │ budget ₹552 · spent ₹850 ·       │ │
│ │ ◆ overspent ₹297                 │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```
(Salary changed ₹40,000 → ₹35,000 on 13 Nov. ₹19,900 − ₹13,000 = ₹6,900 left. Saved ₹2,115 − ₹200 covered = ₹1,915 pot; numbers are seed M20 as in `month-statement.md` §8.1. Overspent ₹537 = ₹240 on 6 Nov after the cover + ₹297 today (today's ₹850 spend is inside Spent so far ₹13,000). Safe to spend (₹6,900 + ₹850) ÷ 11 = ₹704, higher than ₹552 because of earlier savings. ⟲ is the small history icon; "See month statement" is an indigo link.)

### Mid-month first month, today 12 Nov (Light, top of card)
```
│ │ Left this month (i)            ⋮ │ │
│ │ ₹23,000                          │ │
│ │ ━━░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │ │
│ │ ₹996/day · 10 Nov – 4 Dec        │ │
│ │ This month's budget started on   │ │
│ │ 10 Nov.                          │ │
│ │ ...                              │ │
│ │ Money left at start (i)  ₹24,900 │ │
│ │ Fixed costs (i)               ₹0 │ │
```
(₹1,900 spent so far in this illustration.)

### Scrolled down: the collapsed row (Light)
```
┌──────────────────────────────────────┐
│ ₹19,370 left · ₹830/day              │
│──────────────────────────────────────│
│  M    T    W    T    F    S    S     │
│  9●  10○  11◆  12●  13●  14   15     │
└──────────────────────────────────────┘
```

### Loading (Dark)
```
┌──────────────────────────────────────┐
│ ╭──────────────────────────────────╮ │
│ │ Left this month (i)              │ │
│ │ ▒▒▒▒▒▒▒▒▒▒▒▒                     │ │
│ │──────────────────────────────────│ │
│ │ Salary                 ▒▒▒▒▒     │ │
│ │ Fixed costs            ▒▒▒▒▒     │ │
│ │ Spent so far           ▒▒▒▒▒     │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```
(Still grey bars, no "₹0" ever; usually never seen.)

### Why these choices
- **One big number, one honest ledger:** Left is the hero; every other figure sits in a ruled column like a khata, and green ● / red ◆ appear only when there really is money saved or overspent.
- **Safe to spend lives in its own grey inset**, in ink, so it reads as a guide ("spread what's left") and never gets mistaken for today's budget.
- **Changes explain themselves:** a two-period month says "Budget changed on 13 Nov" right next to the ₹552, one tap from the full statement.
