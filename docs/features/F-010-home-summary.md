# F-010: Home summary

| | |
|---|---|
| **Phase** | 3 |
| **Status** | Spec (final, ready for the plan; planned ahead, D-033). D-034 to D-043, D-046 to D-048, D-050, D-054, D-057 and D-060 are applied; the "Safe to spend" line is F-017 (formula confirmed, D-058) |
| **Plan** | [`plans/F-010-home-summary.md`](../../plans/F-010-home-summary.md) |
| **Test cases** | [`tests/F-010-home-summary.md`](../../tests/F-010-home-summary.md) |
| **Tasks** | T-3xx (assigned by the Project Manager at Step 5) |

## 1. What it is *(Product Manager)*
The top of the Home tab. It answers two questions at a glance: **"How is my month going?"** and **"What can I still spend today?"**
- The **summary card** shows the README §2 top summary: Salary · Fixed · Spent so far · Saved this month · Overspent · Left. "Left this month" is the big number.
- The **Today card** shows today's budget, what has been spent and what is left ("₹410 left today"), or how much is overspent.

It replaces Phase 2's plain **This month** card (F-008 §2.1) on Home. The calendar (F-011) sits under these two cards. Every number comes from the F-006 engine. This feature adds **no money rule**. It only shows the engine's numbers, in whole rupees rounded toward ₹0 (D-038, D-046), through the shared formatter (F-008 AC-19).

**User stories:**
- As a **user**, I want to see how much money I have left this month, and how much I can still spend today, the moment I open the app.
- As a **user who overspent**, I want to see how much I'm over, and how much I have in savings to cover it.
- As a **user in a shortfall month** (D-036), I want the shortfall shown honestly all month so that I am not misled.
- As a **user who changed my numbers mid-month** (D-037), I want Home to use today's budget and tell me that the budget changed.

## 2. How it behaves *(Product Manager)*
Layout per design system §7.2 (card) and §7.6 (summary bar). The Designer writes the screen spec at Step 6.

### 2.1 Home layout (month confirmed)
Top to bottom:
1. Title and the Home first-time hint (F-004, unchanged).
2. **Summary card** (§2.2).
3. **Today card** (§2.3).
4. The **calendar** (F-011).

When the user scrolls, the summary card collapses into one pinned row (design system §7.6): `₹19,370 left · ₹830/day`. It expands again when the user scrolls back to the top.

### 2.2 Summary card
- **Hero:** the overline `Left this month` with an (i), then the engine's **Left** amount (F-006 §2.5) in `moneyHero`.
- **Under the hero:** `₹<today's daily budget>/day · <month start> – <month end>`.
- **Safe to spend line** (D-056, specified in **F-017**): `Safe to spend ₹899 a day · 22 days left`. It is shown under the hero line; the formula is option A, confirmed by the Owner (D-058).
- **Progress rule:** spent so far ÷ spendable. It is full when spent ≥ spendable, or when spendable is ₹0 or less. It is not coloured green or red (design system §7.6).
- **The ledger.** Each row has a label, an amount and an (i):

  | Row | Engine value (F-006 §2.5) | When shown |
  |---|---|---|
  | `Salary` | current period's salary | Always, except a mid-month first month (see below) |
  | `Spending target` | current period's target | Only when a target lower than the salary is set |
  | `Money left at start` | the mid-month "money left now" (D-034) | Only in a mid-month first month, in place of Salary |
  | `Fixed costs` | current period's fixed costs (or "fixed costs still to pay", D-042) | Always (₹0 when there are none) |
  | `Spent so far` | spent so far, **net of refunds** (D-047) | Always |
  | `Saved this month` | saved (days before today, D-039), with ● | Always |
  | `Overspent` | uncovered overspend, with ◆ | Always |

- **Savings pot sub-line.** When any cover exists, a line appears under `Saved this month`: `₹1,700 in your savings pot · ₹300 used to cover days`. The pot is the engine's pot value. With no covers, saved and pot are equal and the line is hidden.
- **Shortfall panel** (D-036, D-043: month or period continued anyway). It is shown inside the card, under the hero: `◆ −₹1,000 this month` and `Every spend this month counts as overspent.` It stays all month, as in F-008 AC-8. A zero-spendable month (D-043) shows `○ ₹0 left for daily spending` instead.
- **Budget changed line** (D-037). When the month has more than one period, this line is shown: `Budget changed on 13 Nov · See month statement`. Tapping it opens F-014.
- **Month statement link.** A text button `Month statement` is always shown at the bottom of the card and opens F-014 for this month.
- **Edit this month** (F-008) moves into the card's overflow (⋮) menu, as `Edit this month`. Nothing else changes in F-008.

### 2.3 Today card
- Header: `Today · Fri, 13 Nov` with an (i).
- **The line:** `budget ₹830 · spent ₹420 · ₹410 left today`. The result part uses the same words, colours and marks as F-009 §2.2 / `transactions.md` §4: `₹x left today` (● saved colour), `on budget` (○), `overspent ₹x` (◆).
- **Refunds today (D-047, entered through F-016).** "Spent" is today's **net** spend. When today has refunds, a second line says `Includes ₹500 back from refunds`. If refunds are bigger than today's spends, spent shows a negative figure (`spent −₹200`) and the result is `₹1,030 left today`.
- **Less than ₹1 (D-050, D-055):** a result that is not exactly ₹0 but less than ₹1 reads `less than ₹1 left today` or `overspent less than ₹1`; never `₹0 left today` or `overspent ₹0`.
- **Tap** anywhere on the card to open today's Day details (F-012).
- The card updates immediately after any add, edit, delete, refund or cover.

### 2.4 Worked example A (normal month, ₹830 a day)
**Setup:** salary day 5, month 5 Nov – 4 Dec 2026 (30 days). Salary ₹40,000 − rent ₹10,000 − EMI ₹5,000 − subscription ₹100 = ₹24,900. 24,90,000 paise ÷ 30 = 83,000, so **₹830/day** exactly. Today is **Fri 13 Nov**.

| Day | Spent | Result |
|---|---|---|
| Thu 5 Nov | ₹500 | Saved ₹330 |
| Fri 6 Nov | ₹1,000 | Overspent ₹170 |
| Sat 7 Nov | ₹830 | On budget |
| Sun 8 Nov | ₹200 | Saved ₹630 |
| Mon 9 Nov | ₹620 | Saved ₹210 |
| Tue 10 Nov | ₹830 | On budget |
| Wed 11 Nov | ₹1,130 | Overspent ₹300 |
| Thu 12 Nov | ₹0 (no spends) | Saved ₹830 |
| **Fri 13 Nov (today)** | ₹420 | live: ₹410 left today |

**Arithmetic:**
- Past days 5–12 Nov: budget 8 × ₹830 = ₹6,640. Spent ₹5,110.
- Saved = 330 + 630 + 210 + 830 = **₹2,000**.
- Overspent = 170 + 300 = **₹470**.
- Check: 6,640 − 5,110 = 1,530 = 2,000 − 470 ✓.
- Spent so far = 5,110 + 420 = **₹5,530**.
- Left = 24,900 − 5,530 = **₹19,370**.
- Progress = 5,530 ÷ 24,900 = 22 %.

**Home shows:**
```
Left this month (i)
₹19,370
₹830/day · 5 Nov – 4 Dec
[■■■■□□□□□□□□□□□□□□]
Salary            ₹40,000
Fixed costs       ₹15,100
Spent so far       ₹5,530
Saved this month ● ₹2,000
Overspent        ◆   ₹470
Month statement

Today · Fri, 13 Nov (i)
budget ₹830 · spent ₹420 · ● ₹410 left today
```
**After covering 11 Nov with ₹300 (F-012):**
- Saved this month stays ₹2,000.
- The sub-line becomes `₹1,700 in your savings pot · ₹300 used to cover days`.
- Overspent becomes **₹170**.
- Left stays ₹19,370, because covers never change Left (F-006 §2.5).

**At midnight (Sat 14 Nov, nothing more spent; D-039):**
- 13 Nov becomes Saved ₹410, and Saved this month becomes ₹2,410.
- The Today card reads `budget ₹830 · spent ₹0 · ₹830 left today`.

### 2.5 Worked example S (shortfall month, −₹1,000)
**Setup:** salary ₹20,000, rent ₹15,000 + EMI ₹6,000 = fixed ₹21,000. The month was continued anyway (F-006 S1), so every day is **₹0**. Today is **Sun 8 Nov**. The only spend so far is ₹200 on 6 Nov.
- Spent so far ₹200, saved ₹0, overspent ₹200.
- Left = 0 − 200 − 1,000 = **−₹1,200**.

```
Left this month (i)
−₹1,200
₹0/day · 5 Nov – 4 Dec
◆ −₹1,000 this month
  Every spend this month counts as overspent.
Salary            ₹20,000
Fixed costs       ₹21,000
Spent so far         ₹200
Saved this month      ₹0
Overspent        ◆   ₹200

Today · Sun, 8 Nov
budget ₹0 · spent ₹0 · ○ on budget
```
A negative Left is shown with the minus sign (U+2212) in the `overspent` colour with ◆, plus the caption `You're ₹1,200 over for this month.` Colour is never the only signal.

After a ₹150 spend today:
- The Today card reads `budget ₹0 · spent ₹150 · ◆ overspent ₹150`.
- Spent so far becomes ₹350, and Left becomes **−₹1,350**.
- Overspent shows the engine's figure. Overspent **includes today's live overspend** (D-060: every budgeted day up to and including today), so it is **₹350** (₹200 on 6 Nov + ₹150 today). Saved, by contrast, counts days before today only (D-039).

### 2.6 Worked example M (mid-month change, two periods; D-037)
**Setup:** salary day 1, month 1–30 Nov 2026.
- **Period 1, 1–12 Nov:** salary ₹40,000, fixed ₹15,100, so ₹830/day. 12 × ₹830 = ₹9,960 was budgeted.
- **Period 2, from 13 Nov:** the salary changed to ₹35,000. ₹35,000 − ₹15,100 = ₹19,900, minus ₹9,960 already budgeted = ₹9,940 over 18 days. 9,94,000 ÷ 18 = 55,222 remainder 4, so 13–16 Nov get ₹552.23 and 17–30 Nov get ₹552.22. On screen this is **₹552/day** (D-038).

Today is **Fri 20 Nov**. Spent so far is ₹9,000 (1–12 Nov) + ₹4,000 (13–20 Nov) = ₹13,000.
- Left = 19,900 − 13,000 = **₹6,900**.
- Under the hero: `₹552/day · 1 – 30 Nov`.
- Salary row: `₹35,000` (the current period).
- The line `Budget changed on 13 Nov · See month statement` is shown.
- The Today card: today's budget ₹552.22 is shown as `budget ₹552`. Today's spend is ₹850 (inside the ₹4,000 of period 2), so the card reads `budget ₹552 · spent ₹850 · overspent ₹297`.
- This is the canonical seed M20 (`tests/F-013-dashboard.md` §0): with the ₹200 cover on 6 Nov, Saved is ₹2,115, Overspent ₹537 (₹240 on 6 Nov + ₹297 today, D-060), the pot ₹1,915, and Safe to spend (F-017) is ₹704 a day · 11 days left.

### 2.7 Worked example F (mid-month first month; D-034, D-042)
**Setup:** salary day 5, first use 10 Nov 2026, money left ₹24,900, nothing still to pay. 24,90,000 ÷ 25 = 99,600, so **₹996/day** over 10 Nov – 4 Dec.
- The Salary row is replaced by `Money left at start ₹24,900`.
- Fixed costs shows `₹0` (the still-to-pay total).
- Under the hero: `₹996/day · 10 Nov – 4 Dec`, which is the budgeted range, not 5 Nov.
- A caption says `This month's budget started on 10 Nov.` The same layout and caption apply to any month set up after its start day (late setup or after missed months), which is treated as a fresh start (D-057).
- From the next month on, Home is the normal layout.

### 2.8 Other states
| State | Home shows |
|---|---|
| No confirmed month | The F-008 empty state, unchanged (`Your daily budget lives here` + **Set up your month**). No summary, Today card or calendar |
| New month started, not set up | The F-008 `Your new month has started` card in place of the summary and Today cards. The calendar shows **last month**, read-only, labelled `Last month · 5 Oct – 4 Nov` (F-011) |
| Loading | Card outlines without figures. A `₹0` placeholder is **never** shown, so the user never sees a false ₹0 |
| Load error | The F-007 load error state (`Couldn't load your data` + **Try again**) in place of the cards |

## 3. Acceptance criteria *(Product Manager)*
"Small phone", "all four themes" and accessibility checks are as defined in F-002 §3. Tests use a fixed "today" and engine test data from F-006, with refunds seeded through the repository where needed.

| ID | Given / When / Then |
|---|---|
| AC-1 | **Layout replaces the This month card.** Given a confirmed month, when Home opens, then it shows, in order: title (and hint), summary card, Today card, calendar (F-011); the F-008 `This month` card is no longer shown; `Edit this month` is reachable from the summary card's ⋮ menu and opens F-008 edit mode. |
| AC-2 | **Worked example A figures.** Given example A (§2.4) and today 13 Nov, when Home is shown, then it reads exactly: Left this month `₹19,370`; `₹830/day · 5 Nov – 4 Dec`; Salary `₹40,000`; Fixed costs `₹15,100`; Spent so far `₹5,530`; Saved this month `₹2,000` with ●; Overspent `₹470` with ◆; no Spending target row; no savings pot sub-line; and the Today card `budget ₹830 · spent ₹420 · ₹410 left today` with ●. |
| AC-3 | **Cover updates the summary.** Given example A, when 11 Nov is covered with ₹300 through F-012, then without leaving Home the summary shows Saved `₹2,000`, the sub-line `₹1,700 in your savings pot · ₹300 used to cover days`, Overspent `₹170`, and Left still `₹19,370`. |
| AC-4 | **Midnight (D-039).** Given example A at 23:59 on 13 Nov with Home open, when the test clock passes midnight and the app resumes (or the tab is shown again), then the Today card reads `Today · Sat, 14 Nov`, `budget ₹830 · spent ₹0 · ₹830 left today`, Saved this month is `₹2,410`, and the calendar's today ring is on 14 Nov. |
| AC-5 | **Today card results.** Given ₹830/day, when today's spends total (a) ₹420, (b) ₹830, (c) ₹950.50, (d) ₹829.40, (e) ₹830.40, then the result reads (a) `₹410 left today` ●, (b) `on budget` ○, (c) `overspent ₹120` ◆ (spent shown `₹950`, D-038/D-046), (d) `less than ₹1 left today` ●, (e) `overspent less than ₹1` ◆ (D-050, D-055), each with words, colour and mark. |
| AC-6 | **Shortfall month (D-036).** Given example S (§2.5) and today 8 Nov, when Home is shown, then Left reads `−₹1,200` (U+2212, overspent colour, ◆ and the caption `You're ₹1,200 over for this month.`), `₹0/day`, the panel `◆ −₹1,000 this month` + `Every spend this month counts as overspent.`, Salary `₹20,000`, Fixed `₹21,000`, Spent `₹200`, Saved `₹0`, Overspent `₹200`, Today `budget ₹0 · spent ₹0 · on budget`; and the panel is present on 5 Nov, 20 Nov and 4 Dec. After a ₹150 spend today, Left reads `−₹1,350` and the Today card `overspent ₹150`; Overspent shows the engine's total, **₹350**: it includes today's live overspend (D-060). Before the ₹150 spend, Overspent is ₹200. |
| AC-7 | **Zero spendable (D-043).** Given fixed costs equal to the salary (continued anyway), when Home is shown, then the panel reads `○ ₹0 left for daily spending` (no shortfall amount), and `₹0/day` is shown. |
| AC-8 | **Mid-month change (D-037).** Given example M (§2.6) and today 20 Nov, when Home is shown, then Left is `₹6,900`, the line under the hero is `₹552/day · 1 – 30 Nov`, Salary is `₹35,000`, the Today card reads `budget ₹552 · spent ₹850 · overspent ₹297`, and `Budget changed on 13 Nov · See month statement` is shown and opens F-014 for November. Given a month with one period, then that line is absent. |
| AC-9 | **Mid-month first month (D-034, D-042).** Given example F (§2.7) and today 12 Nov, when Home is shown, then there is no Salary row, `Money left at start ₹24,900` is shown, Fixed costs `₹0`, the hero line is `₹996/day · 10 Nov – 4 Dec`, and `This month's budget started on 10 Nov.` is shown; given a month set up late on 12 Dec after missed months (D-057), then the same layout and caption (`…started on 12 Dec.`) are shown; given ₹4,900 still to pay instead, then Fixed costs reads `₹4,900` and the daily figure `₹800/day`. |
| AC-10 | **Target row.** Given salary ₹40,000 and target ₹20,000 with fixed ₹15,100, when Home is shown, then both `Salary ₹40,000` and `Spending target ₹20,000` rows are shown and the hero line reads `₹163/day`; with no target, then no target row is shown. |
| AC-11 | **Refunds (D-047).** Given ₹830/day and today's entries of a ₹700 spend and a ₹500 refund, when Home is shown, then the Today card reads `budget ₹830 · spent ₹200 · ₹630 left today` plus `Includes ₹500 back from refunds`, and Spent so far is net of the refund. Given today a ₹300 spend and a ₹500 refund, then it reads `spent −₹200 · ₹1,030 left today`. Given no refunds today, then no refunds line is shown. |
| AC-12 | **Rounding toward zero (D-038, D-046).** Given engine values with paise (left 19,37,050 paise; overspent 12,050; left −1,20,050), when shown, then they read `₹19,370`, `₹120` and `−₹1,200`; every amount on Home goes through the shared formatter (code check agreed in the plan). |
| AC-13 | **Live updates.** Given Home open, when a spend is added, edited or deleted (F-009/F-012), or a cover is made, then every affected figure and the Today card update before the next screen is shown, with no manual refresh (F-007 AC-5). |
| AC-14 | **Navigation.** Given Home, when the user taps the Today card, then F-012 opens for today; when the user taps `Month statement`, then F-014 opens for the current month. |
| AC-15 | **Collapse on scroll.** Given example A, when the user scrolls the calendar up, then the summary collapses to one pinned row `₹19,370 left · ₹830/day`; scrolling back to the top expands it; TalkBack reads the collapsed row as `₹19,370 left this month, ₹830 a day`. The pinned row exists in portrait up to text scale 1.3×; at larger text and in landscape (D-030) it is not shown and the title area scrolls with the page (design `home-summary.md` §6; Gate 1, D-077). |
| AC-16 | **States.** Given (a) no confirmed month, (b) a new month started but not set up, (c) a slow load, (d) a forced read failure, when Home is shown, then it shows (a) the F-008 empty state only, (b) the new-month card and last month's calendar labelled `Last month · 5 Oct – 4 Nov`, (c) placeholders with no `₹0`, (d) `Couldn't load your data` with **Try again**, which reloads successfully once the failure is removed. |
| AC-17 | **Help on every figure.** Given the summary and Today cards, when the Tester checks each figure against §5, then each has its label and (i) through F-004, and each (i) opens its explanation. |
| AC-18 | **Themes, large text, accessibility.** Given examples A and S, when Home is shown in all four themes at text scale 1.0 and 2.0 on a small phone and in landscape 640×360 (D-030), then F-002 AC-12–AC-14 pass, no amount is truncated or split, the ledger wraps label above amount at 2.0×, TalkBack reads each ledger row as one sentence (`Overspent, ₹470`) with the (i) as its own stop, and the Today card as one sentence (`Today, Friday 13 November: budget ₹830, spent ₹420, ₹410 left today.`). |
| AC-19 | **Speed.** Given a month with 500 spends, when Home opens from a cold start on the emulator, then the summary and Today card show their final figures within 1 second. |

## 4. Edge cases *(Product Manager)*
- **First day of the month:** saved and overspent are ₹0, and Left = spendable − today's spend.
- **Last day of the month:** Home works normally. The next day, the new-month card appears (F-008).
- **Left exactly ₹0:** shown as `₹0`, neutral, with no ◆.
- **Spent more than the whole month's money** (Left −₹100, F-006 AC-14): negative style, as in AC-6.
- **₹10 crore figures:** `₹10,00,00,000` fits in `moneyHero` on a small phone. At 2.0× text it wraps below the label and is never truncated.
- **Paise only** (a ₹0.40 spend): Spent so far shows `₹0` (D-038). This is accepted.
- **Several changes in one month:** the line names the latest change date: `Budget changed on 28 Nov`.
- **A change that removes a shortfall:** the panel shows the current period's shortfall. When that is ₹0, the panel is hidden (F-006 §4).
- **Device date moved back:** Home uses today's date as given. Future-dated spends are not counted (F-006 AC-13). If today is not a budgeted day (before the first budgeted day or outside the month), the Today card and the Safe to spend line are left out and the summary shows as the engine gives it (Gate 1, D-077; TC-010-59).
- **A refund bigger than everything spent this month:** Spent so far can be negative (`−₹300`). Left is then bigger than spendable, and the progress rule is empty.
- **Home opened while a cover sheet is open in F-012:** not possible (modal).

## 5. Help text & copy *(Product Manager, finalised by Designer)*
| Control | Label | Description / tooltip |
|---|---|---|
| Hero | `Left this month` | (i): F-006 "Left": `What's budgeted for this month minus what you've spent so far.` |
| Hero line | — | `<daily>/day · <start> – <end>` |
| Negative left caption | — | `You're <amount> over for this month.` |
| Salary | `Salary` | (i): `The salary you entered for this month. If you changed it, this is the latest amount.` |
| Spending target | `Spending target` | (i): `The amount you chose to spend this month, including fixed costs.` |
| Money left at start | `Money left at start` | (i): `How much you had when you started using the app partway through the month.` |
| Fixed costs | `Fixed costs` | (i): `Rent, EMIs and other monthly bills. They're taken out before your daily budget is worked out.` |
| Spent so far | `Spent so far` | (i): `Everything you've spent this month up to now, after refunds.` |
| Saved this month | `Saved this month` | (i): `Money left over on days that have ended. Today's leftover joins at midnight.` |
| Savings pot sub-line | — | `<pot> in your savings pot · <covered> used to cover days` |
| Overspent | `Overspent` | (i): `How much you went over on days that aren't covered from savings yet.` |
| Shortfall panel | — | `−<amount> this month` · `Every spend this month counts as overspent.` Equal case: `₹0 left for daily spending` |
| Budget changed line | `Budget changed on <date>` | Button text `See month statement`, hint `Open the month statement` |
| Month statement button | `Month statement` | Hint `See how this month's budget was worked out` |
| Late-start caption (D-034, D-057) | — | `This month's budget started on <date>.` |
| Safe to spend | see F-017 §5 | — |
| Overflow menu | (icon ⋮) | Tooltip `More`. Item `Edit this month` (hint `Change this month's salary, target or fixed costs`) |
| Today card | `Today · <weekday, d MMM>` | Line as in F-009. (i): F-009 Today line. Tap hint `See today's details` |
| Refunds line | — | `Includes <amount> back from refunds` |
| Collapsed row | — | `<left> left · <daily>/day`. Negative Left: `<amount> over this month · <daily>/day` (with ◆). Hint `Scroll to the top` |
| ₹0 figures (Designer) | — | `Saved this month` / `Overspent` of ₹0 are shown in the neutral colour with **no** ● / ◆ (marks only when money was saved or overspent) |
| Calendar hint (Designer) | `Tip` | `Tap a day to see its spends.` New hint `hint.calendar.v1`, shown above the calendar only after `hint.home.v1` is dismissed |
| Loading | — | Screen reader `Loading your month` |
| Screen reader, summary | — | `Left this month, <amount>. <daily> a day, <start> to <end>.` Negative: `minus <amount>` |

## 6. Out of scope
- Any new money rule. Every figure is the engine's.
- Animations beyond the design system's count-up and the collapse transition (Phase 6).
- Notifications (Phase 5). SMS, salary detection and auto-categories (Phase 4).
- Showing previous months on Home. Past months are viewed in the calendar (F-011) and the statement (F-014).
- Recording refunds: that is **F-016** (D-054). This doc only shows them.
- Working out "Safe to spend": that is **F-017**. This doc only reserves its place.

## 7. How it works — technical *(Developer, filled in when the feature is Done)*
**What was built.** The Home summary: the summary card (hero figure, progress, ledger, shortfall notice, budget-changed line, `Month statement` link), the Today card, the pinned collapsed row and the loading, empty, error and new-month states. Tasks T-300 to T-307 (Track A), the B-006 fix, T-492 and the Gate 3 fixes. Gate 3 approved 2026-11-19 (D-088, conditional on a green check run), Gate 4 conditional pass 2026-11-23 (D-098). Home only displays the F-006 engine's numbers: no money rule was added.

**Main files** (`app/lib/`)
- Pure Dart in `domain/budget/`: `home_summary.dart` (`HomeSummary.from`: ledger flags, `progressPermille`, `latestChangeDay`, the display rules of D-090 (3)); `today_line.dart` gained optional `moneyIn` and `hasRefunds`.
- `features/home/`: `home_tab.dart` (state switch, slivers, pinned-row stack), `home_state.dart` (`HomeView`, `homeViewProvider`), `widgets/` (`summary_card`, `summary_hero`, `summary_ledger`, `home_ledger_row`, `notice_panel`, `budget_changed_line`, `home_today_card`, `collapsed_summary_row`, `home_loading`, `new_month_card`, `counting_amount`, `home_layout` with `ChunkedText`). `this_month_card.dart` was deleted.
- Shared: `core/widgets/today_result_line.dart` (the Today line, extracted from the Transactions tab and shared with `TodayLineView`), `core/copy/home_copy.dart`, `core/format/date_format.dart` (`formatCompactRange`, `1 – 30 Nov`); `MonthSetupCopy` lost the strings no screen uses. `home_tab.dart` also hosts F-011's `CalendarSection` and F-017's strip (placed by `summary_card.dart`).
- Seams: `Month statement` and `See month statement` go through `openMonthStatement`, the Today card opens `openDayDetails`; both now push the real F-014 and F-012 routes (T-306).

**Data stored.** None new. Home reads the shared month state and writes nothing.

**Decisions:** D-047, D-050 and D-055 (`less than ₹1` wording), D-054, D-056, D-057, D-060 (Overspent includes today's live overspend), D-077 (AC-15 pinned row up to 1.3x text only; `Month statement` never hidden; Today not a budgeted day leaves out the Today card and Safe to spend; Undo), D-079, D-088, D-089 (4) (pinned row takes its own space, not an overlay), (5) (`FittedBox` for very large figures, ledger rows as a `Wrap`), (7) (count-up is a Nice to have), D-090 (3) (display rules live in `HomeSummary`), D-094, D-097, D-098, D-099.

**Deviations** (plan section 11; Gate 3 in `docs/reviews/code-phase-3-tracks-ad.md`)
- Deviation 1: the hero amount is in a `FittedBox(scaleDown)` so `₹10,00,00,000` and 2.0x text never truncate or split on 360 dp (the plan said no `FittedBox` for amounts; every other amount is plain `Text`). Deviation 2: the pinned row is not a `Stack` overlay but takes its own space above the page, so a row a screen reader scrolls into view is never hidden. Deviation 3: the display rules sit inside `HomeSummary` (a Left of −99 paise reads `₹0`; a ₹0 Saved or Overspent has no mark; progress is full when nothing is budgeted or spent reaches the budget). Deviation 5: the day line uses `1 – 30 Nov` inside one month. Deviation 6: one-line ledger rows use a `Wrap`.
- Deviation 4: Tester numbers corrected to the engine, no rule changed (TC-010-48 Saved `₹3,320`; TC-010-59 (a), (b) Spent so far `₹0` and Left `₹24,900`; (c) is the new-month card).
- Gate 3 fixes: T-302 (the day line breaks only after the dot, with a word joiner after the en dash; test `TC-010-41` shown to fail on the reverted code); T-306 (`TC-010-19` and `-32` each have a test against the real routes); T-307 (60 of 60 clean runs of `homeCollapsedRow`, no retry wrapper).
- B-006 (2026-11-23): `ChunkedText` keeps a chunk whole while it fits one line and otherwise breaks between its words, so a word or amount is never split (savings-pot sub-line and Today heading); a `Spacer` that halved the heading width was removed. Tests carry `TC-010-60` (`home_line_breaks_test.dart`, real fonts), shown to fail with the fix reverted.
- Shared test harness and fixtures (T-308, T-389): `FakeMoneyStore.watch` is no longer an `async*` generator; the named data sets are in `test/helpers/phase3_fixtures.dart`. Orchestrator ruling: `m20` is the F-013 / F-014 seed, the F-010 file's own M20 is kept as `m20F010` only for TC-010-16, -17, -18.

**How it is tested** (`tests/F-010-home-summary.md`, 59 cases, 19 ACs)
- Unit: `test/domain/budget/home_summary_test.dart` (18 tests), `today_line_test.dart`; `money_format_only_test.dart` (TC-010-30).
- Widget (fake repositories; four themes, text scale 2.0): `test/features/home/` (`home_summary_card_test`, `home_today_card_test`, `home_collapsed_row_test`, `home_states_test`, `home_day_line_test`, `home_line_breaks_test`, `home_month_states_test` with TC-008-57 to -61 replacing the retired F-008 Home cases), `test/copy/home_copy_test.dart`, `phase3_screen_sweep_test.dart` (TC-010-40, TC-008-62).
- Integration on the emulator: `integration_test/home_500_test.dart` (TC-010-43, 500 spends, limit 1,000 ms). The first runs printed `0 ms` in profile (the stopwatch started after `pumpAndSettle`, found at Gate 4, D-098); T-492 re-measured from before `pumpWidget` in 16 ms frames until `₹18,652` and `₹6,247` show. Profile, five runs: 190, 112, 144, 135, 97 ms, worst 190 ms (`docs/reviews/emulator-phase-3/dev-t492-profile-home_500.log`). The Tester's re-run (T-491) is still to do.
- Mutation pass: the Home sweep probe S7 (collapsed row never measured) is killed by TC-010-33 and TC-010-34 (`tests/PHASE-3-SUMMARY.md` 6.2).
- Device (A13 seed, 13 Nov 2026, `docs/reviews/emulator-phase-3/s8-*.png`): figures, Today card and strip match the engine; collapsed row at 360 x 640 dp; text 2.0, large display size and landscape show no overflow lines; four themes at x2.0; force-stop and kill keep the data; the Month statement link and a calendar day open the real routes.
- Result at Gate 4 (2026-11-23, D-098): conditional pass, 58 Pass of 59, 1 Blocked-needs-human (TC-010-42); `tool/check.ps1` green (1,285 tests on the 2026-11-23 re-run, 1,267 on 2026-11-21), domain coverage 100 %, time-zone matrix identical.

**Known limitations and open items**
- **Still blocks Done (Gate 4 conditions, D-098):** T-491 (Tester 1: re-run `home_500` in profile on an idle machine; also closes B-005 with `month_setup_flow_test`), T-493 (Tester 1: verify B-006 on the device at 2.0x on 360 dp and at 411 dp; the screenshot `s8-tc011-12-greyscale.png` predates the fix), T-496 (Tester 1: the 20-run flakiness check of the collapsed-row sweep state, a Gate 3 Must fix never run), T-501 (Project Manager: Gate 3 of the test-only changes, then Gate 5). B-006 stays `Fixed pending Tester verification` until T-493.
- **TC-010-42 (TalkBack) is Blocked-needs-human**, open under D-097 (D-066 and D-071 precedent). Proofs in place: the semantics tests and the `uiautomator` order evidence. Steps in `tests/PHASE-3-SUMMARY.md` 3.3. TC-010-42 and TC-017-27 are the same Home screen (about two minutes).
- The pinned row is not built above 1.3x text or in landscape (the title scrolls, D-077 (1)).
- Nice to have, not blocking: T-466 (count-up of the hero figure, `motionCount`; the status line cross-fades today); T-465 (Designer: record the build deviations in `home-summary.md`) is done.
- Depends on F-006 (engine), F-007, F-008 (month state, new-month card), F-009 (Today line). Used by F-011 (hosts the calendar section), F-012 (Today card opens day details), F-014 (statement link), F-017 (strip inside the summary card).

## 8. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-10 | First version of the spec (Phase 3 planned ahead, D-033). D-047 refunds applied for display. 19 ACs | Product Manager |
| 2026-11-11 | Owner answers applied: D-054 (refunds entered through F-016; Q-2 closed); D-050/D-055 "under ₹1" wording (§2.3, AC-5 extended); D-056 Safe to spend line reserved and specified in F-017; D-057 late-start caption (§2.7, AC-9 extended). Q-1 stays open with the team. 19 ACs | Product Manager |
| 2026-11-11 | Small-amount wording switched from "under ₹1" to the Owner's literal "less than ₹1" (`overspent less than ₹1`, `saved less than ₹1`, `less than ₹1 left today`, `less than ₹1 short`, `less than ₹1 a day`), matching the Phase 2 change to D-050/D-055. Wording only, no AC added | Product Manager |
| 2026-11-11 | Status set to final Spec, ready for the plan (all Owner questions answered: D-053 to D-058). Remaining team questions go to the Project Manager at Phase 3 Gate 1 (phase overview, open items) | Product Manager |
| 2026-11-11 | §5 finalised by the Designer (`docs/design/screens/home-summary.md`): negative collapsed row `<amount> over this month`, ₹0 saved/overspent shown without marks, new `hint.calendar.v1`, overflow item hint, loading label. No AC changed | Designer |
| 2026-11-11 | D-060 applied (T-225): Overspent includes today's live overspend; Q-1 closed. §2.5 and AC-6 now state ₹350 as the rule, not an assumption. No AC value changed | Product Manager |
| 2026-11-16 | Gate 1 (Project Manager A): AC-15 states the pinned row is portrait up to 1.3× only; §4 says what Home shows when today is not a budgeted day; §2.5 example block no longer draws a mark on `₹0` saved (§5 and design H-3). No other AC changed | Project Manager |
| 2026-11-16 | Docs aligned to canonical seed M20 (`tests/F-013-dashboard.md` §0): §2.6 and AC-8 now give the Today card as `budget ₹552 · spent ₹850 · overspent ₹297` and the M20 totals (Saved ₹2,115, Overspent ₹537, pot ₹1,915, Safe to spend ₹704). No rule changed; AC-6 ₹350 untouched (D-060) | Product Manager |
| 2026-11-23 | Step 9: section 7 (technical) filled in. Status stays Testing: Done waits for T-491, T-493, T-496, T-501 (Gate 5) | Developer |

## Impact on existing features
- **F-008 §2.1 / AC-1:** the This month card is replaced by the summary card. `Edit this month` moves to the ⋮ menu, and the shortfall line moves into the summary. F-008 Home test cases are updated when this is built.
- **F-009:** the Today line on Transactions stays. Home's Today card uses the same copy.
- **F-006 / F-007 (D-047, D-051):** refunds are already in the engine (F-006 AC-25) and the database (`transactions.direction`, F-007 AC-19); F-016 adds the manual entry.
- **F-017:** adds the Safe to spend line to the summary card (formula D-058).

## Owner / team questions
- ~~Q-1~~ **Closed by D-060:** Overspent includes today's live overspend (Month and period totals alike). AC-6 stays at ₹350.
- ~~Q-2~~ **Closed by D-054:** manual "Money back / refund" entry comes in Phase 3 as **F-016**.

## Suggested additions *(for the CEO — not in scope until approved)*
- ~~Safe to spend~~: accepted by the Owner (D-056), now **F-017**.
- **Swipe between Today and Yesterday** on the Today card.
