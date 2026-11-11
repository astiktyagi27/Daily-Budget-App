# Screen spec: App shell, bottom navigation and tab placeholders

**Owner of this file:** Designer · **Phase:** 1 · **Feature:** F-003 (uses F-002 tokens, F-004 hint card) · **Status:** Approved at Gate 2 (PM, 2026-11-05)
**Read with:** `docs/design/design-system.md` (§4, §7.7, §7.10, §7.11), `docs/features/F-003-app-shell-navigation.md`, `docs/features/F-004-help-tooltip-system.md`.
Copy here matches F-003 §5 and F-004 §5 word for word. If they ever differ, the feature doc wins and this file is fixed.

---

## 1. Purpose
The frame every tab lives in: four labelled tabs at the bottom, a title at the top, and a calm empty state that says what will appear on each tab.

## 2. The shared frame (all four tabs)

Top to bottom:

| # | Part | Component / tokens | Notes |
|---|---|---|---|
| 1 | Status bar | System, transparent, drawn over `bg` | Icons dark on Light, light on Dark and Dim (F-002 AC-18). |
| 2 | **Title header** | `headline` (Bricolage 700, 26/32), `textPrimary`, `space7` (32 dp) above, `space5` (20 dp) side gutters, `space4` below | **Not** a fixed-height app bar. The title is the first item of the scrolling body, so it can wrap to 2–3 lines at large text and scrolls away with the content. Background `bg`, no shadow, no hairline. |
| 3 | First-time hint card | F-004 hint card (design system §7.11c) | First visit only, until dismissed. Sits directly under the title, `space5` gutters. Copy in `help-pattern.md` §4. |
| 4 | Body | Tab content. Phase 1: empty state (§4) or the Settings list (`settings.md`) | Scrolls. Bottom padding = nav height + `space6`, so the last item is never hidden behind the bar. |
| 5 | **Bottom navigation** | Design system §7.7 | Always visible on the four tabs. Never visible during the welcome flow. |
| 6 | System navigation area | Gesture bar or 3-button bar | The nav bar's `surface` fill extends under it (edge-to-edge); system nav bar is transparent; nav items sit above the inset, never under it. |

Top-bar titles (F-003 §2.3): Home `Daily Budget App` · Dashboard `Dashboard` · Transactions `Transactions` · Settings `Settings`.
Semantics: the title is a heading (`Semantics(header: true)`), read first on every tab.

## 3. Bottom navigation

### 3.1 Look
- 4 equal slots across the full width (90 dp each on a 360 dp phone). `surface` fill, 1 dp `border` top hairline, no shadow.
- Each slot, top to bottom: **ink tick** (4 × 16 dp, `accent`, `radiusFull`, only on the selected tab; the space is reserved on all tabs so nothing jumps) · 8 dp · icon 24 dp · 4 dp · label.
- Icons (Material Icons, outlined; filled when selected (design system §6)): Home `home`, Dashboard `bar_chart`, Transactions `receipt_long`, Settings `tune`.
- Inactive: outlined icon + label in `neutral`, `label` style at 12/16, weight 500.
- Selected: filled icon + label in `accent`, weight 600, plus the ink tick. The selected state is shown by **three** non-colour cues (tick, filled icon, heavier label), so it reads in greyscale (F-003 AC-2).
- Bar height: 64 dp at text scale 1.0. It grows with the label (never clips) to a maximum of about 72 dp at the label cap below.

### 3.2 Label scaling rule at large text (resolves F-002 / F-003 edge case "Transactions must not clip")
"Transactions" is the longest label. At 12 sp it is about 77 dp wide, and a slot leaves 82 dp for text (90 dp − 2 × 4 dp padding). At 2.0× it would be about 154 dp, so it cannot simply scale.

The rule, in this order:
1. **Cap.** Nav labels follow the system text scale up to **1.3×** and no further (`MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3)` on the label only). The icon size never changes.
2. **Fit.** Each label is one line, no ellipsis, no wrap, inside `FittedBox(fit: BoxFit.scaleDown)` constrained to the slot width minus 8 dp. If the capped label is still too wide (for example "Transactions" at 1.3×, or any label on a 320 dp-wide screen), it shrinks just enough to fit. It is never cut off and never shows "…".
3. **Floor.** The shrink never needs to go below 10 sp in practice (worst case: "Transactions" at 1.3× on a 320 dp screen ≈ 10.4 sp rendered). The Developer adds a widget test for 360 dp and 320 dp widths at scale 1.0, 1.3 and 2.0 asserting no overflow and an untruncated label.
4. **Full-size alternative.** Long-press on any tab shows its tooltip (§3.4) at full system scale, and TalkBack reads the full label, so users who need 2.0× text still get the name at their size.

Why: this is how Material's own components and iOS tab bars treat bar labels. Body text keeps the full 2.0× scale; only the four one-word bar labels are capped, because the bar is navigation chrome that must stay one row.

### 3.3 Copy and semantics
| Tab | Label | Long-press tooltip / screen-reader hint | Screen-reader label |
|---|---|---|---|
| Home | `Home` | `Today's budget and your calendar` | `Home, tab 1 of 4` (+ `, selected` when selected) |
| Dashboard | `Dashboard` | `Where your money goes` | `Dashboard, tab 2 of 4` |
| Transactions | `Transactions` | `Every spend and credit` | `Transactions, tab 3 of 4` |
| Settings | `Settings` | `Theme and app options` | `Settings, tab 4 of 4` |

### 3.4 Interactions
- **Tap another tab:** tick slides to the new slot (`motionBase`, 200 ms, `standard`); icon swaps outlined → filled; the new tab's body fades in (`motionBase`). No sideways page slide.
- **Tap the selected tab:** if scrolled, the body scrolls to the top (`motionEmphasis`, 320 ms, `decelerate`); if already at top, nothing happens (no flash, no haptic).
- **Long-press a tab:** Material tooltip above the bar (`inverseSurface`, `radiusSm`, `body` in `onInverseSurface`), plus the standard long-press haptic. Does not switch tab.
- **Pressed:** ripple limited to the slot, `InkRipple`, 8 % `textPrimary` (Light) / 10 % white (Dark, Dim).
- **Rapid taps:** the last tap wins; no stacking (F-003 edge cases).
- **Android back:** Dashboard / Transactions / Settings → Home (tick slides back to Home). Home → app goes to background. If a help sheet, the theme picker or a tooltip is open, back closes that first.
- **Remove animations on:** all of the above happen instantly.

## 4. Tab placeholder empty states (Home, Dashboard, Transactions)

Component: design system §7.10 empty state. Placed under the title (and under the hint card on a first visit), **left-aligned**, starting `space8` (40 dp) below whatever is above it. Contents: 88 dp `neutralSoft` circle with a 40 dp line icon in `neutral` → `space5` → title (`title`, `textPrimary`) → `space2` → description (`bodyLarge`, `textSecondary`, wraps freely, max width 320 dp). No button, no amounts, no sample data (F-003 AC-4).

| Tab | Icon | Title | Description |
|---|---|---|---|
| Home | `today` | `Your daily budget lives here` | `Once you set up your month, you'll see what you can spend today, what you've spent and your calendar.` |
| Dashboard | `insights` | `Insights are on their way` | `After a few days of spending, you'll see where your money goes and how many days you saved.` |
| Transactions | `receipt_long` | `No transactions yet` | `Spends from your bank SMS will show up here. You'll also be able to add them yourself.` |

- The icon circle is decorative (`excludeSemantics`). TalkBack reads title then description as one item: "Your daily budget lives here. Once you set up your month, …".
- The empty state is static: no animation, no pulsing, no illustration that suggests data.
- **Resolved at Gate 1/2 (PM, 2026-11-05):** F-003 §2.4 now reads "placed in the body per design system (left-aligned)". Left-aligned stays: it avoids the generic centred-hero look and keeps the hint card and empty state on one reading line.

Settings has no empty state; its body is the list in `settings.md`.

## 5. States

| State | What the user sees |
|---|---|
| **First-time** (first visit to a tab after onboarding) | Title, then the tab's hint card (`help-pattern.md` §4), then the empty state / Settings list. |
| **Normal** (hint dismissed) | Title, then the empty state / Settings list. The empty state moves up into the hint's place with the hint's collapse animation. |
| **Empty** | In Phase 1 the empty state *is* the normal content of Home, Dashboard and Transactions. |
| **Loading** | None on screen. Saved preferences (theme, onboarding, hint flags) are read before the first Flutter frame, so the first frame is already correct (F-002 AC-7). Until then the Android launch screen shows the generated Flutter launch theme (white, or black in system dark mode); theming it to `bg` is Phase 6/7 polish (F-002 §6). No spinner, no skeleton. |
| **Error** | Phase 1 has no user-visible errors. If preferences cannot be read or written, the app uses safe defaults silently (Auto theme, hints shown) and never shows an error message (F-002 AC-8, F-004 AC-12). The error pattern for later phases is in design system §7.12. |
| **Permission denied** | Not applicable in Phase 1 (no permissions are requested). |

## 6. Themes

| Element | Light | Dark | Dim | Auto |
|---|---|---|---|---|
| Page `bg` | `#F6F3ED` warm paper | `#0E0E12` ink | `#2A2825` slate | Light or Dark, following the phone |
| Nav bar `surface` + hairline | `#FFFDF8` / `#DED8CD` | `#17171D` / `#2A2A33` | `#34312D` / `#48453F` | as above |
| Selected tab (tick, icon, label) | `#3A3DB0` | `#9C9FFF` | `#ABACF6` | as above |
| Inactive tab | `#68646E` | `#9F9CA7` | `#B6AFA4` | as above |
| Empty-state circle / icon | `#EAE6DF` / `#68646E` | `#24242B` / `#9F9CA7` | `#3D3A35` / `#B6AFA4` | as above |
| Status/nav bar icons | dark | light | light | follows the active set |

All pairs are in design system §3 (lowest here: `neutral` on `neutralSoft`, 4.64 : 1 Light). A live theme change (picker or Auto) cross-fades colours via `ThemeExtension.lerp` over `motionBase`; the tab, scroll position and any open hint stay as they are.

## 7. Largest text (2.0×, 360 × 640 dp)
- **Title:** wraps. "Daily Budget App" at 52 sp takes 2 lines ("Daily Budget / App" or "Daily / Budget App" depending on width); it is never truncated. It scrolls with the body.
- **Hint card and empty state:** wrap freely; the body scrolls. On Home at 2.0× the empty-state description starts below the first screen and is reached by scrolling (allowed by F-004 edge case "very short screens").
- **Bottom navigation:** labels capped at 1.3× and fitted (§3.2). Bar grows to about 72 dp.
- **Display size (zoom) largest, 320 dp width, text 1.0:** no overflow; "Transactions" shrinks to fit its 80 dp slot (§3.2).

## 8. Accessibility
- Reading order on every tab: title (heading) → hint card (if shown) → body → bottom navigation (F-003 AC-12).
- Each nav slot is ≥ 48 dp tall and 90 dp wide.
- Tab change announces nothing extra; the new tab's title heading is focused by TalkBack's normal page-change behaviour.

## Change history
| Date | Change | By |
|---|---|---|
| 2026-11-05 | First version | Designer |
| 2026-11-05 | Gate 2 review (Project Manager, `docs/reviews/design-phase-1.md`): §5 loading state reworded (the generated Android launch theme shows until Flutter starts; theming it is Phase 6/7); status → Approved at Gate 2 | Project Manager |
| 2026-11-06 | T-128 (Gate 2 N2): change-history table added. No spec content changed | Designer |
| 2026-11-06 | T-133 (Gate 3 N5, `docs/reviews/code-phase-1.md`): §3.1 icon set corrected to Material Icons, outlined / filled when selected (design system §6); §3.4 tab change: the new tab's body fades in (`motionBase`), not a cross-fade (Gate 1 plan F-003 §10 point 12). Docs alignment only | Designer |

---

## Owner preview

### Home, first visit (Light, text 1.0)
```
┌──────────────────────────────────────┐
│ 9:41                        ▴ ◢ ▮    │
│                                      │
│ Daily Budget App                     │
│                                      │
│ ╭──────────────────────────────────╮ │
│ │ ☼ Tip                         ×  │ │
│ │ Use the tabs at the bottom to    │ │
│ │ move around. Home is where       │ │
│ │ you'll check today's budget      │ │
│ │ each day.                        │ │
│ │                          Got it  │ │
│ ╰──────────────────────────────────╯ │
│                                      │
│  ╭────╮                              │
│  │ ▦  │                              │
│  ╰────╯                              │
│ Your daily budget lives here         │
│ Once you set up your month, you'll   │
│ see what you can spend today, what   │
│ you've spent and your calendar.      │
│                                      │
│──────────────────────────────────────│
│   ▬                                  │
│   ⌂       ▥        ≣         ⫶       │
│ Home Dashboard Transactions Settings │
└──────────────────────────────────────┘
```
(☼ = lightbulb icon in indigo; the tip card is a soft indigo tint. ▬ = the indigo ink tick over the selected tab.)

### Transactions, after the tip is dismissed (Dark, text 1.0)
```
┌──────────────────────────────────────┐
│                                      │
│ Transactions                         │
│                                      │
│  ╭────╮                              │
│  │ ≣  │                              │
│  ╰────╯                              │
│ No transactions yet                  │
│ Spends from your bank SMS will show  │
│ up here. You'll also be able to add  │
│ them yourself.                       │
│                                      │
│                                      │
│──────────────────────────────────────│
│                     ▬                │
│   ⌂       ▥        ≣         ⫶       │
│ Home Dashboard Transactions Settings │
└──────────────────────────────────────┘
```
(Near-black page, light text, soft lilac-indigo tick and label on Transactions.)

### Bottom bar at text 2.0 (labels capped at 1.3× and fitted)
```
┌──────────────────────────────────────┐
│──────────────────────────────────────│
│   ▬                                  │
│   ⌂        ▥        ≣        ⫶       │
│ Home Dashboard Transactions Settings │
│ (bigger)       (shrinks to fit slot) │
└──────────────────────────────────────┘
```

### Why these choices
- **Titles live in the page, not in a fixed bar**, so at 2.0× text "Daily Budget App" wraps instead of being cut off, and the screen keeps the ledger-page feel.
- **Bar labels cap at 1.3× and shrink to fit**: "Transactions" can never clip, and long-press or TalkBack still gives the full-size name.
- **Left-aligned empty states with one quiet icon** say what is coming without fake numbers or a generic centred illustration.
