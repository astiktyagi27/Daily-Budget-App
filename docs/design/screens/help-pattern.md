# Screen spec: Help pattern ((i) explanation, tooltips, first-time hints)

**Owner of this file:** Designer · **Phase:** 1 · **Feature:** F-004 (used by F-002, F-003, F-005 and every later feature) · **Status:** Approved at Gate 2 (PM, 2026-11-05)
**Read with:** `docs/design/design-system.md` §7.11 (updated to match this file), `docs/features/F-004-help-tooltip-system.md`.

---

## 1. Purpose
One consistent way for every control to explain itself, so a first-time user never has to guess what a button, setting or number means.

## 2. The three parts and when to use which

| Part | Use when | Phase 1 examples |
|---|---|---|
| **a) Label + description** (default) | There is room for one or two lines under the label. | Every Settings row; the theme picker options; the explainer buttons in the welcome flow. |
| **b) Label + (i) → help sheet** | The explanation is longer than two lines, or space is short (numbers, headers). | Theme row. From Phase 2: every number in the summary card. |
| **c) Long-press tooltip + screen-reader hint** | Standard navigation controls only (tabs, Next, Skip, ×, Done). | Bottom tabs; hint card ×. |

Plus the **first-time hint card**, one per main tab (§4).

### 2.1 Label + description
- Label `label` (Plex 500, 14/20) in `textPrimary`; description directly below in `body` (Plex 400, 14/20) `textSecondary`, `space1` (4 dp) gap.
- Description wraps; it is **never** truncated with "…" (F-004 edge cases). Two lines is a writing target, not a clip.
- One semantics node: TalkBack reads `<Label>. <Description>.` (F-004 AC-1).

## 3. (i) explanation: the help sheet

**Change from the first design-system draft:** the draft used a small tooltip bubble that closed by itself after 6 s. F-004 asks for a title, a body, a **Got it** button, scrolling for long text and swipe-down to close, and focus returning to the (i). A bottom sheet does all of that natively and reads better at 2.0× text, so **every (i) opens a help sheet**. The bubble style survives only as the long-press tooltip (§5). Design system §7.11 is updated to match.

### 3.1 The (i) button
- 18 dp `info` outlined icon in `textSecondary`, placed 4 dp after the label text (it follows the last word if the label wraps). Touch target 48 × 48 dp, centred on the icon. The (i) wins hit-testing inside its 48 dp area, so a tap on it never triggers the row (F-004 AC-2).
- Pressed: 40 dp circular ripple.
- Screen reader: `More about <label>`, button role (F-004 AC-4). Separate focus stop from the row.
- Non-text contrast of the icon: `textSecondary` on `surface` 6.81 / 7.38 / 6.50 : 1.

### 3.2 The help sheet
Design system §7.8 bottom sheet, natural height up to 90 % of the screen.

Top to bottom:
1. Drag handle (32 × 4 dp, `borderStrong`).
2. Title: the control's label, `title` (Bricolage 600, 20/26), `textPrimary`, `space6` below the handle.
3. Body: `bodyLarge` (Plex 400, 16/24), `textPrimary`, `space3` below the title. Plain sentences; no bullet lists in Phase 1. Scrolls inside the sheet if long.
4. `Got it`: **Secondary** button, full width, pinned to the bottom of the sheet (`space4` above, `space5` + system inset below), so it stays reachable while the body scrolls (F-004 AC-13).

- Copy for each (i) lives in that feature's §5 (Phase 1: only Theme, in F-002 §5 and `settings.md` §4).
- `Got it` screen-reader hint: `Close this explanation`.
- **Opens:** slides up 16 dp + fades in, `motionEmphasis` (320 ms, `decelerate`), scrim fades in.
- **Closes four ways** (F-004 AC-3): Got it, tap on the scrim, swipe down, Android back. Exit 240 ms `accelerate`. Afterwards TalkBack focus returns to the (i) button.
- Double-tap on (i) opens one sheet only (the second tap lands on the scrim area and is ignored while the sheet animates in).
- Opened over a visible hint card: the hint stays as it was when the sheet closes (not dismissed).
- Theme change while open: the sheet re-renders in the new theme and stays open.

## 4. First-time hint card

### 4.1 Look
An inline card at the top of the tab body, directly under the title (`app-shell.md` §2). Not an overlay: everything else on the tab stays usable (F-004 AC-10).

```
╭───────────────────────────────────────╮
│ [bulb]  Tip                       [×] │
│ <hint text, body, wraps>              │
│                               Got it  │
╰───────────────────────────────────────╯
```
- Fill `accentSoft`, no border, `radiusMd` (14 dp), padding `space4` (16 dp), `space5` side gutters, `space4` below the card.
- Row 1: 20 dp `lightbulb` outline icon in `accent` · 8 dp · overline `Tip` in `label` weight 600 `accent` · flexible space · × button (20 dp `close` icon in `textSecondary`, 48 dp target, overlapping the card's padding so the card does not grow).
- Hint text: `body` (Plex 400, 14/20) in `textPrimary`, `space2` below row 1. Wraps freely.
- `Got it`: **Text** button in `accent`, right-aligned, 48 dp tall target, `space2` above.
- Contrast: hint text 13.87 / 12.67 / 8.67; `accent` on `accentSoft` 6.89 / 6.06 / 4.97; × icon 5.62 / 5.97 / 5.27 : 1 (Light / Dark / Dim).

### 4.2 Copy (per tab)
| Tab | Hint text |
|---|---|
| Home | `Use the tabs at the bottom to move around. Home is where you'll check today's budget each day.` |
| Dashboard | `Check back after a week of spending. That's when your patterns start to show.` |
| Transactions | `Spotted a wrong amount or category later? You'll be able to fix it right here.` |
| Settings | `Change the theme and other options here. Tap (i) next to a setting to learn what it does.` |

| Control | Label | Tooltip / screen reader |
|---|---|---|
| Card | `Tip` (overline) | Card reads as one item: `Tip. <hint text>` |
| Dismiss button | `Got it` | Hint: `Dismiss this tip. It won't show again.` |
| Close (×) | (icon only) | Long-press tooltip and screen-reader label: `Dismiss tip` |

**Why the hint copy changed from F-004's first draft:** in Phase 1 each tab already shows an empty state that says what will appear there. The first-draft hints repeated the empty state almost word for word ("Today's budget and your calendar will appear here" next to "you'll see what you can spend today … and your calendar"). Each hint now teaches one *different* thing: how to move around (Home), when the tab becomes useful (Dashboard), what you can do there later (Transactions). Settings was already distinct and is unchanged. F-004 §5 is updated with a change-history line.

### 4.3 Behaviour
- Shown on the first visit to each tab after onboarding is finished; never during the welcome flow (F-004 AC-11).
- **Got it** or **×**: the card collapses (height to 0 + fade, `motionEmphasis` 320 ms; instant with Remove animations); content below moves up smoothly; "seen" is saved for that tab only. TalkBack focus moves to the first item after where the card was.
- Not dismissed → it shows again next time (tab switch or restart; F-004 AC-9).
- At most one card per screen (one per tab).
- Each hint has its own ID (`hint.home.v1`, `hint.dashboard.v1`, `hint.transactions.v1`, `hint.settings.v1`) so a later phase can show a new tip by bumping the version.

## 5. Long-press tooltip (standard navigation controls)
- Flutter `Tooltip` styled by `tooltipTheme`: `inverseSurface` fill, `radiusSm` (10 dp), `body` text in `onInverseSurface`, padding 12 × 8 dp, max width 280 dp, shown above the control with 8 dp gap; Light gets the `float` shadow, Dark/Dim none.
- Trigger: long-press (and hover/focus where applicable). Fades in `motionFast`, stays 1.5 s after release.
- Text follows the full system text scale (no cap), wrapping as needed.
- Contrast `onInverseSurface` on `inverseSurface`: 14.99 / 14.13 / 14.13 : 1.
- The same text is the control's screen-reader hint.

## 6. States

| State | Help sheet | Hint card |
|---|---|---|
| First-time | n/a (opens on demand) | Visible |
| Normal | Opens on (i) tap | Hidden once dismissed |
| Empty | n/a | n/a |
| Loading | None (copy is bundled) | None (seen-flags read before first frame) |
| Error (preferences unreadable/unwritable) | Unaffected | Shown again on next launch if the flag can't be read; a dismiss this session stays dismissed this session (F-004 AC-12). No message. |
| Permission denied | n/a | n/a |

## 7. Themes

| Element | Light | Dark | Dim |
|---|---|---|---|
| Hint card fill | `#E7E6F6` | `#25264A` | `#3E3D55` |
| Hint icon / Tip / Got it | `#3A3DB0` | `#9C9FFF` | `#ABACF6` |
| Hint text | `#1C1B22` | `#F2F0EA` | `#EEE9E0` |
| Help sheet | `#FFFDF8` + shadow over 40 % scrim | `#17171D` over 60 % black | `#34312D` over 50 % black |
| (i) icon | `#5C5864` | `#A8A5B1` | `#BEB7AB` |
| Tooltip | `#1C1B22` with `#F2F0EA` text | `#EEE9E0` with `#1C1B22` text | `#EEE9E0` with `#1C1B22` text |

Auto uses the Light or Dark column.

## 8. Largest text (2.0×, 360 × 640 dp)
- Hint card: text wraps to about 6–8 lines; Tip row and Got it stay; the card pushes the tab content down and the body scrolls.
- Help sheet: the Theme body (longest Phase 1 text) at 32 sp is about 12 lines, taller than the sheet's 90 % limit with the title. The body scrolls; title stays at top, `Got it` stays pinned.
- Tooltip: wraps within 280 dp; may cover neighbouring tabs while visible, which is fine for a transient tooltip.

## 9. Errors are not "overspent" (resolves F-002 edge case)
Red means overspent. Errors use the same red **hue** (one red keeps the palette calm), but always look different. Full rule in design system §7.12; summary:
- An **error** always has the `error` icon (circle with "!") **and** a written sentence that says what to fix ("Enter an amount above ₹0"). It appears only next to the thing that went wrong (input outline + message under it).
- An **overspent** amount never has an icon of its own; it has the ◆ ledger mark and the word "Overspent" next to an amount.
- App-level problems ("Couldn't save. Try again.") use the neutral snackbar, never red.
Phase 1 has no visible errors.

## Change history
| Date | Change | By |
|---|---|---|
| 2026-11-05 | First version | Designer |
| 2026-11-05 | Gate 2 review (Project Manager, `docs/reviews/design-phase-1.md`): status → Approved at Gate 2 | Project Manager |
| 2026-11-06 | T-128 (Gate 2 N2): change-history table added. No spec content changed | Designer |

---

## Owner preview

### Hint card on Dashboard (Light)
```
┌──────────────────────────────────────┐
│ Dashboard                            │
│                                      │
│ ╭──────────────────────────────────╮ │
│ │ ☼ Tip                         ×  │ │
│ │ Check back after a week of       │ │
│ │ spending. That's when your       │ │
│ │ patterns start to show.          │ │
│ │                          Got it  │ │
│ ╰──────────────────────────────────╯ │
│                                      │
│  ╭────╮                              │
│  │ ⟋  │                              │
│  ╰────╯                              │
│ Insights are on their way            │
│ After a few days of spending, you'll │
│ see where your money goes and how    │
│ many days you saved.                 │
└──────────────────────────────────────┘
```

### (i) tapped on the Theme row (Light)
```
┌──────────────────────────────────────┐
│░ Settings ░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░ ◐ Theme (i) ░░░░░░░░░░░░░░░░░░░░░ › │
│░   Auto (follows your phone) ░░░░░░░░│
│╭────────────────────────────────────╮│
│               ────                   │
│  Theme                               │
│                                      │
│  Choose how the app looks. Auto      │
│  switches between Light and Dark     │
│  with your phone's setting. Dim is   │
│  a softer, warm grey theme that's    │
│  easy on the eyes at any time of     │
│  day.                                │
│  ┌────────────────────────────────┐  │
│  │             Got it             │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

### Long-press on the Transactions tab (Dim)
```
┌──────────────────────────────────────┐
│                ╭──────────────────╮  │
│                │ Every spend and  │  │
│                │ credit           │  │
│                ╰────────▾─────────╯  │
│──────────────────────────────────────│
│                     ▬                │
│   ⌂       ▥        ≣         ⫶       │
│ Home Dashboard Transactions Settings │
└──────────────────────────────────────┘
```

### Why these choices
- **(i) opens a sheet, not a bubble**: it has room for a title, scrolls at large text, and gives a clear "Got it", exactly what F-004 asks for.
- **Tips sit inside the page, never on top of it**, in a soft indigo card with a lightbulb, so they help without blocking anything.
- **Each tip teaches something new** instead of repeating the empty state underneath it.
