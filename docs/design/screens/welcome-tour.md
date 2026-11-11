# Screen spec: Welcome tour, SMS and notification explainers, disclaimer

**Owner of this file:** Designer · **Phase:** 1 · **Feature:** F-005 (uses F-002 tokens, F-004 help pattern) · **Status:** Approved at Gate 2 (PM, 2026-11-05)
**Read with:** `docs/design/design-system.md`, `docs/features/F-005-welcome-tour-permission-explainers.md` (§5 updated to match this file), `help-pattern.md` §5 (tooltips).

---

## 1. Purpose
In under a minute, explain the one-number daily budget, say honestly why the app will later ask for SMS and notifications, and set expectations before the user lands on Home.

**Flow:** Slide 1 → 2 → 3 → 4 → SMS explainer → Notifications explainer → Disclaimer → Home. Skip on slides 1–3 jumps to the SMS explainer. No bottom navigation on any of these pages (F-005 §2.9).

**Copy rule (Owner):** these screens make only claims that are true today and stay true while D-003 holds: data stays on the phone, there is no login, nothing is uploaded. They do **not** mention ads or analytics, because that is not decided.

---

## 2. Tour slides (4 pages)

### 2.1 Layout (top to bottom, every slide)
| # | Part | Spec |
|---|---|---|
| 1 | Top row | Left: **page indicator**. Right: **Skip** (Text button, slides 1–3 only; slide 4 keeps the space empty). Row height 48 dp, `space5` gutters, `space4` below the status bar. |
| 2 | **Visual card** | A card (`surface`, hairline, `radiusLg`, padding `space5`) built from real design-system parts (no image files, no stock illustration). Height about 200 dp at text 1.0. Decorative: `excludeSemantics`. `space6` below. |
| 3 | Title | `displayHeadline` (Bricolage 700, 32/38), `textPrimary`, left-aligned, heading semantics. `space3` below. |
| 4 | Body | `bodyLarge` (Plex 400, 16/24), `textSecondary`, left-aligned, max width 360 dp. |
| 5 | Flexible space | |
| 6 | **Primary button** | `Next` (slides 1–3) / `Get started` (slide 4). Full width, 52 dp, `space5` gutters, pinned `space5` above the system inset. |

Page indicator: four ink ticks in a row, 4 dp tall, 6 dp apart. Current slide: 24 dp wide in `accent`; others: 8 dp wide in `borderStrong` (3.39 / 3.54 / 3.76 : 1 on `bg`). Position is shown by length as well as colour. Screen reader: `Slide <n> of 4`. The current tick stretches/shrinks with `motionBase` as pages change.

### 2.2 Slide copy and visuals

| Slide | Title | Body | Visual card (decorative) |
|---|---|---|---|
| 1 | `Spend a little each day` | `Daily Budget App turns your monthly money into one simple number: what you can spend today.` | Overline "Today you can spend" (`label`, `textSecondary`), then **₹830** in `moneyHero`, then a 4 dp progress rule (empty, `neutralSoft`). |
| 2 | `Your daily budget, worked out` | `Salary ₹40,000 − rent ₹10,000 − EMI ₹5,000 − subscription ₹100 = ₹24,900 to spend. Over a 30-day month, that's ₹830 a day.` | A ledger, labels left (`body`, `textSecondary`), amounts right (`moneyMedium`, tabular): Salary ₹40,000 · Rent −₹10,000 · EMI −₹5,000 · Subscription −₹100 · hairline · To spend ₹24,900 · ÷ 30 days · **₹830 a day** (`moneyLarge`, `textPrimary`). |
| 3 | `Saved days add up` | `Spend less than your daily budget and the rest goes into your savings pot. Overspent? You choose whether to cover it from savings.` | Three calendar day cells (design system §7.5): "9 ● ₹620" saved, "10 ○ ₹830" on budget, "11 ◆ ₹1,130" overspent; below them a ledger line "Savings pot" with **● ₹210** in `saved`. |
| 4 | `Private by design` | `Your bank SMS are read on this phone and never leave it. No login, and nothing is uploaded.` | A 40 dp `smartphone` line icon in `accent`, then three lines each led by a `check` icon in `accent`: "Stays on this phone" · "No login" · "Nothing uploaded". |

Slide 4 changed from the F-005 first draft, which ended "No login, no cloud, no ads tracking your money". The ads claim is removed (not decided by the Owner). "Nothing is uploaded" says the same thing as "no cloud" in plainer words. F-005 §5 is updated.

The visual on slide 2 repeats the body's numbers as a ledger on purpose: the body is the exact text the screen reader reads and AC-2 checks; the card is the at-a-glance version. On slide 3 green and red are used only for their meanings (saved, overspent), each with its ●/◆ mark.

### 2.3 Controls
| Control | Label | Tooltip / screen-reader hint |
|---|---|---|
| Next | `Next` | `Go to the next slide` |
| Skip | `Skip` | `Skip the tour and continue setup` |
| Get started | `Get started` | `Finish the tour and continue setup` |
| Page indicator | — | `Slide <n> of 4` |

### 2.4 Interactions
- Swipe left/right moves between slides; the page follows the finger (direct manipulation). Tapping **Next** animates to the next page over `motionEmphasis` (320 ms, `decelerate`).
- Swiping right on slide 1 or left on slide 4 does nothing (no overscroll glow that hints at more pages; clamping physics).
- Android back: previous slide; on slide 1 the app goes to the background.
- **Skip** / **Get started**: open the SMS explainer with the standard page transition (fade + 16 dp rise); the tour is removed from history, so back from the SMS explainer leaves the app (F-005 §2.7).
- All forward buttons ignore a second tap while the transition runs (F-005 AC-13).
- Remove animations on: pages jump.
- TalkBack reading order (F-005 edge cases): title, body, page position (`Slide <n> of 4`), Next / Get started, Skip. The visual card is skipped. Implement with `Semantics(sortKey: OrdinalSortKey(...))` because Skip and the indicator sit visually above the title.

---

## 3. SMS explainer

### 3.1 Layout
| # | Part | Spec |
|---|---|---|
| 1 | Icon | 56 dp `accentSoft` circle with a 28 dp `sms` line icon in `accent`. `space9` (56 dp) from the top inset. Decorative. |
| 2 | Title | `Read your bank SMS`, `displayHeadline`, heading. `space5` above, `space5` below. |
| 3 | Points | Three rows, each: 20 dp line icon in `textSecondary` · 12 dp · text in `bodyLarge` `textPrimary`. `space4` between rows. |
| 4 | Flexible space | |
| 5 | Button block (pinned at text ≤ 1.3×) | Primary `Allow SMS access` · `space2` · its description in `caption` `textSecondary`, centred under the button · `space3` · Secondary `Not now`. |

| Point icon | Text |
|---|---|
| `sms` | `To track spends for you, the app reads the SMS your bank sends when money moves.` |
| `filter_alt` | `Only your bank's messages are read. OTPs, personal chats and other senders are ignored.` |
| `phonelink_lock` | `Everything stays on this phone. Nothing is uploaded or shared.` |

| Control | Label | Description / hint |
|---|---|---|
| Allow SMS access | `Allow SMS access` | Description under the button: `You can still add spends yourself if you say no.` |
| Not now | `Not now` | Hint: `Continue without SMS access for now` |

Both buttons open the notifications explainer; no system dialog (F-005 AC-7). Primary first because it is the recommended path; "Not now" is a full Secondary button (not a small grey link), so saying no is never hidden.

## 4. Notifications explainer
Same layout as §3. Icon `notifications` in the circle.

- Title: `Get gentle nudges`

| Point icon | Text |
|---|---|
| `donut_large` | `A heads-up when you've used 80% of today's budget.` |
| `notifications_active` | `An alert if you go over.` |
| `bedtime` | `An end-of-day summary of what you saved or overspent.` |
| `tune` | `Optional. You can change this anytime in Settings.` |

| Control | Label | Description / hint |
|---|---|---|
| Turn on notifications | `Turn on notifications` | Description under the button: `Notifications are created on your phone. Nothing is sent anywhere.` |
| Not now | `Not now` | Hint: `Continue without notifications` |

Both buttons open the disclaimer; no system dialog (F-005 AC-8). Point icons are neutral (`textSecondary`); "go over" is not shown in red because nothing has been overspent.

## 5. Disclaimer
Same layout as §3, one button. Icon `info` in the circle.

- Title: `Before you start`

| Point icon | Text |
|---|---|
| `account_balance` | `The app tracks one bank account.` |
| `credit_card_off` | `Credit card spends are not included.` |
| `edit` | `Automatic detection can get things wrong sometimes. You can edit any transaction or category.` |

| Control | Label | Hint |
|---|---|---|
| I understand | `I understand` (Primary) | `Finish setup and open the app` |

No Skip, no secondary button (F-005 AC-10). Points are neutral information, not warnings: no red, no warning icons. **I understand** opens Home with a fade (`motionBase`); the Home hint card is already in place.

## 6. Back behaviour (explainers)
Disclaimer → back → Notifications explainer → back → SMS explainer → back → app to background (F-005 AC-11). Transitions in reverse (fade + 16 dp drop).

## 7. States

| State | What the user sees |
|---|---|
| First-time | This whole flow *is* the first-time state. No F-004 hint cards appear here (F-004 AC-11). |
| Normal | Never shown again once onboarding is finished. Resume rules: tour seen but not finished → opens on the SMS explainer. |
| Empty | n/a |
| Loading | None; onboarding flags are read before the first frame, so the right page is the first frame (no flash of Home or the tour). |
| Error (flags can't be saved) | Nothing shown; Home still opens this session; the flow may show again next launch (F-005 AC-15). |
| Permission denied | Not in Phase 1 (no real requests). Phase 4/5 specs will add the denied and "don't ask again" states to these same screens. |

## 8. Themes

| Element | Light | Dark | Dim |
|---|---|---|---|
| Page | `#F6F3ED` | `#0E0E12` | `#2A2825` |
| Visual card | `#FFFDF8` + `#DED8CD` hairline | `#17171D` + `#2A2A33` | `#34312D` + `#48453F` |
| Title / point text | `#1C1B22` | `#F2F0EA` | `#EEE9E0` |
| Body / descriptions / point icons | `#5C5864` | `#A8A5B1` | `#BEB7AB` |
| Primary button | `#3A3DB0` fill, white text | `#9C9FFF` fill, `#14143D` text | `#ABACF6` fill, `#1B1B3D` text |
| Icon circle | `#E7E6F6` + `#3A3DB0` | `#25264A` + `#9C9FFF` | `#3E3D55` + `#ABACF6` |
| Slide 3 saved / overspent | `#1A7044` / `#B4372F` on their soft fills | `#52C98B` / `#FF7B6F` | `#80D3A1` / `#FF9C8E` |
| Indicator: current / other | `#3A3DB0` / `#8A8377` | `#9C9FFF` / `#6A6876` | `#ABACF6` / `#878073` |

Auto uses Light or Dark with the phone. A live theme switch re-renders the current page in place (F-005 edge cases).

## 9. Largest text (2.0×, 360 × 640 dp)
- **Every page scrolls vertically** inside the page; horizontal swipe still changes slides.
- **Visual card** shrinks to at most 160 dp tall and scrolls with the content. Its own text (amounts in the ledger) is capped at 1.3× because it is decorative and repeated in the body; the body itself is not capped.
- **Money never splits:** every amount in the body is wrapped in a no-break unit (the Developer joins "₹" and digits, and the "−" with its amount, with U+2060 WORD JOINER or builds the text with non-breaking spans), so "₹24,900" and "₹40,000" always stay whole (F-005 edge cases).
- **Title** wraps (slide 1 at 64 sp: about 3 lines).
- **Buttons:**
  - Tour: the single Next / Get started button stays pinned at the bottom at all scales (it grows to about 64 dp).
  - Explainers and disclaimer: at text ≤ 1.3× the button block is pinned. Above 1.3× the block moves to the **end of the scroll content** (it would otherwise take almost half the screen), and a small pinned bar is **not** added. The page opens scrolled to the top; the user scrolls once to reach the buttons. TalkBack reaches them in order after the last point.
- Skip grows with text and stays in the top row; the page indicator stays to its left and the row wraps onto two lines if needed (indicator above Skip).

## Change history
| Date | Change | By |
|---|---|---|
| 2026-11-05 | First version | Designer |
| 2026-11-05 | Gate 2 review (Project Manager, `docs/reviews/design-phase-1.md`): status → Approved at Gate 2 | Project Manager |
| 2026-11-06 | T-128 (Gate 2 N2): change-history table added. No spec content changed | Designer |

---

## Owner preview

### Slide 2 of 4 (Light)
```
┌──────────────────────────────────────┐
│ ▬▬▬ ▬ ▬ ▬                      Skip  │
│ (2nd tick long = slide 2)            │
│ ╭──────────────────────────────────╮ │
│ │ Salary                   ₹40,000 │ │
│ │ Rent                    −₹10,000 │ │
│ │ EMI                      −₹5,000 │ │
│ │ Subscription               −₹100 │ │
│ │──────────────────────────────────│ │
│ │ To spend                 ₹24,900 │ │
│ │ ÷ 30 days                        │ │
│ │                    ₹830 a day    │ │
│ ╰──────────────────────────────────╯ │
│                                      │
│ Your daily budget,                   │
│ worked out                           │
│                                      │
│ Salary ₹40,000 − rent ₹10,000 − EMI  │
│ ₹5,000 − subscription ₹100 = ₹24,900 │
│ to spend. Over a 30-day month,       │
│ that's ₹830 a day.                   │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │               Next               │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### Slide 3 of 4 (Dark)
```
┌──────────────────────────────────────┐
│ ▬ ▬ ▬▬▬ ▬                      Skip  │
│ ╭──────────────────────────────────╮ │
│ │ ╭──────╮  ╭──────╮  ╭──────╮     │ │
│ │ │ 9   ●│  │10   ○│  │11   ◆│     │ │
│ │ │  ₹620│  │  ₹830│  │₹1,130│     │ │
│ │ ╰──────╯  ╰──────╯  ╰──────╯     │ │
│ │  saved    on budget  overspent   │ │
│ │──────────────────────────────────│ │
│ │ Savings pot              ● ₹210  │ │
│ ╰──────────────────────────────────╯ │
│                                      │
│ Saved days add up                    │
│                                      │
│ Spend less than your daily budget    │
│ and the rest goes into your savings  │
│ pot. Overspent? You choose whether   │
│ to cover it from savings.            │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │               Next               │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```
(Green cell and "● ₹210" for saved, grey ring for on budget, red diamond for overspent.)

### Slide 4 of 4 (Dim)
```
┌──────────────────────────────────────┐
│ ▬ ▬ ▬ ▬▬▬                            │
│ ╭──────────────────────────────────╮ │
│ │  ▯                               │ │
│ │  ✓ Stays on this phone           │ │
│ │  ✓ No login                      │ │
│ │  ✓ Nothing uploaded              │ │
│ ╰──────────────────────────────────╯ │
│                                      │
│ Private by design                    │
│                                      │
│ Your bank SMS are read on this phone │
│ and never leave it. No login, and    │
│ nothing is uploaded.                 │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │           Get started            │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### SMS explainer (Light)
```
┌──────────────────────────────────────┐
│                                      │
│  ╭────╮                              │
│  │ ✉  │                              │
│  ╰────╯                              │
│ Read your bank SMS                   │
│                                      │
│ ✉  To track spends for you, the app  │
│    reads the SMS your bank sends     │
│    when money moves.                 │
│ ⏚  Only your bank's messages are     │
│    read. OTPs, personal chats and    │
│    other senders are ignored.        │
│ ⌂  Everything stays on this phone.   │
│    Nothing is uploaded or shared.    │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │         Allow SMS access         │ │
│ └──────────────────────────────────┘ │
│  You can still add spends yourself   │
│        if you say no.                │
│ ┌──────────────────────────────────┐ │
│ │             Not now              │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### Notifications explainer (Dark)
```
┌──────────────────────────────────────┐
│  ╭────╮                              │
│  │ ♪  │                              │
│  ╰────╯                              │
│ Get gentle nudges                    │
│                                      │
│ ◔  A heads-up when you've used 80%   │
│    of today's budget.                │
│ ♪  An alert if you go over.          │
│ ☾  An end-of-day summary of what you │
│    saved or overspent.               │
│ ⫶  Optional. You can change this     │
│    anytime in Settings.              │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │      Turn on notifications       │ │
│ └──────────────────────────────────┘ │
│  Notifications are created on your   │
│     phone. Nothing is sent anywhere. │
│ ┌──────────────────────────────────┐ │
│ │             Not now              │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### Disclaimer (Light)
```
┌──────────────────────────────────────┐
│  ╭────╮                              │
│  │ i  │                              │
│  ╰────╯                              │
│ Before you start                     │
│                                      │
│ ⌂  The app tracks one bank account.  │
│ ▭  Credit card spends are not        │
│    included.                         │
│ ✎  Automatic detection can get       │
│    things wrong sometimes. You can   │
│    edit any transaction or category. │
│                                      │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │           I understand           │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### Slide 1 at text 2.0 (Light, scrolled to top)
```
┌──────────────────────────────────────┐
│ ▬▬▬ ▬ ▬ ▬                     Skip   │
│ ╭──────────────────────────────────╮ │
│ │ Today you can spend              │ │
│ │ ₹830                             │ │
│ ╰──────────────────────────────────╯ │
│ Spend a                              │
│ little each                          │
│ day                                  │
│ Daily Budget App                     │
│ turns your monthly                   │
│ money into one        (scrolls ↓)    │
│ ┌──────────────────────────────────┐ │
│ │              Next                │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### Why these choices
- **Every slide's picture is a real piece of the app** (a today card, a ledger, calendar cells, a privacy checklist), so the tour previews the product instead of showing stock illustrations.
- **"Not now" is a full button, not a hidden link**, and the privacy promises are only ones we can keep: on this phone, no login, nothing uploaded. Nothing about ads.
- **At 2.0× text the explainer buttons move to the end of the page** rather than covering half the screen; the tour's single Next button stays pinned.
