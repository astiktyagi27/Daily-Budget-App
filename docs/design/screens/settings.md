# Screen spec: Settings tab and Theme picker

**Owner of this file:** Designer · **Phase:** 1 · **Features:** F-003 (Settings list), F-002 (Theme row and picker), F-004 (help pattern) · **Status:** Approved at Gate 2 (PM, 2026-11-05)
**Read with:** `docs/design/design-system.md` (§2, §7.4, §7.8, §7.11), `app-shell.md` (frame, bottom nav), `help-pattern.md` (help sheet, hint card), `docs/features/F-002-design-system-themes.md` §5, `docs/features/F-003-app-shell-navigation.md` §5.

---

## 1. Purpose
One calm list where the user changes the theme today and sees, honestly marked "Coming soon", every option that arrives in later updates.

## 2. Layout (top to bottom)

1. **Title header** `Settings` (`app-shell.md` §2).
2. **Hint card** on the first visit (`help-pattern.md` §4, Settings copy).
3. **Group header "General"**, then a card with: Theme, Notifications.
4. **Group header "Money"**, then a card with: Bank account, Salary date, Categories.
5. **Group header "Privacy & help"**, then a card with: Privacy & data, How this app works, Disclaimer.
6. `space8` bottom spacing above the bottom nav.

The row order is exactly F-003 AC-5 (Theme, Notifications, Bank account, Salary date, Categories, Privacy & data, How this app works, Disclaimer); the headers only group neighbours and never reorder.

**Group header:** `caption` weight 500, `textSecondary`, sentence case (not ALL CAPS), `space6` above, `space2` below, aligned to the row text start (20 dp gutter). Marked as a heading for screen readers.
**Group card:** design system §7.2 card, padding 0, rows separated by hairlines inset to the text start.

### 2.1 Row anatomy (design system §7.4, F-004 label + description)
```
[ leading icon 40 ]  Label  (i)                  [ trailing ]
                     Description, up to 2 lines,
                     wraps further at large text
```
- Leading: 24 dp line icon in a 40 dp `neutralSoft` circle (decorative).
- Label `label` (Plex 500, 14/20). Description `body` (Plex 400, 14/20) in `textSecondary`, `space1` gap.
- Min height 72 dp; grows with text. Padding 20 dp sides, 12 dp top/bottom.

### 2.2 Theme row (works)
| Part | Spec |
|---|---|
| Icon | `contrast` |
| Label | `Theme` in `textPrimary` |
| (i) | Right after the label, 18 dp icon, 48 dp target. Opens the help sheet (`help-pattern.md` §3). Does **not** open the picker (F-004 AC-2). |
| Description | The current choice: `Auto (follows your phone)` / `Light` / `Dark` / `Dim`. Updates the moment a new theme is picked. |
| Trailing | `chevron_right`, 20 dp, `textSecondary` |
| Tap (anywhere except the (i)) | Opens the theme picker (§3). Pressed fill `sunken`. |
| Screen reader | `Theme. Auto (follows your phone). Button.` Hint: `Opens theme options`. The (i) is a separate focus stop: `More about Theme, button`. |

### 2.3 "Coming soon" rows (7 rows, inactive)
| Part | Spec |
|---|---|
| Label | `textSecondary` (not `textPrimary`): 6.81 / 7.38 / 6.50 : 1 on `surface`, above the 4.5 : 1 F-002 requires for disabled labels |
| Description | `textSecondary`, `body` |
| Icon | as the table below, in `neutral` (not dimmed further) |
| Trailing | **"Coming soon" tag**: pill, `radiusFull`, `neutralSoft` fill, padding 8 × 4 dp, text `caption` weight 500 in `textSecondary` (5.56 / 6.37 / 5.69 : 1). No chevron. |
| Tap | Nothing: no ripple, no navigation, no snackbar, no haptic (F-003 AC-6). |
| Screen reader | One disabled item: `<Label>, coming soon, not available yet. <Description>` (exact string fixed at Gate 1, F-003 §5), e.g. `Notifications, coming soon, not available yet. Budget warnings and an end-of-day summary`. TalkBack adds "disabled". |
| No (i) | The description already explains the row; an (i) on a row that does nothing would be one more dead control. |

The inactive look comes from three cues together: secondary-colour label, no chevron and the tag. Opacity is **not** lowered, so text stays readable.

| Row | Icon | Label | Description |
|---|---|---|---|
| 2 | `notifications` | `Notifications` | `Budget warnings and an end-of-day summary` |
| 3 | `account_balance` | `Bank account` | `The one bank account the app tracks` |
| 4 | `event` | `Salary date` | `The day your budget month starts` |
| 5 | `category` | `Categories` | `How your spends are grouped, like Food or Travel` |
| 6 | `lock` | `Privacy & data` | `Your data stays on this phone. Manage or delete it here.` |
| 7 | `menu_book` | `How this app works` | `A short guide to daily budgets and saving` |
| 8 | `info` | `Disclaimer` | `What the app can and can't track` |

Group headers: `General` · `Money` · `Privacy & help`.

## 3. Theme picker (bottom sheet)

Component: design system §7.8 bottom sheet. It is short, so it opens at its natural height (not full screen).

1. Drag handle.
2. Title `Choose a theme` (`title`).
3. Four option rows, in this order: Auto, Light, Dark, Dim.
4. A **Secondary** button `Done` (Secondary, not Primary, because the choice is already applied and saved; Done only closes), full width, `space5` gutters, `space4` above and `space5` + system inset below.

**Option row:** min height 64 dp. Leading radio (20 dp): unselected = 2 dp `borderStrong` ring; selected = 2 dp `accent` ring + 10 dp `accent` dot. Label `label`; selected label weight 600. Description `body` `textSecondary`. Trailing: selected row also shows a `check` icon in `accent`. The selected state is therefore shown by the dot, the check and the heavier label, not by colour alone (F-002 AC-1).

| Option | Label | Description |
|---|---|---|
| 1 | `Auto` | `Matches your phone's light or dark setting` |
| 2 | `Light` | `Bright and clean` |
| 3 | `Dark` | `True dark, best at night` |
| 4 | `Dim` | `Soft warm grey, easy on the eyes` |

`Done`: hint `Close theme options`.

**Behaviour**
- Tapping an option applies it to the whole app **at once** and saves it. The sheet **stays open**, so the user sees the new theme (the sheet itself, the dimmed screen behind, the nav bar) and can try another. All colours cross-fade over `motionBase` (200 ms).
- The radio dot moves to the new row (`motionFast`).
- TalkBack announces `Theme changed to <name>` (for example `Theme changed to Dim`). Each option reads `Auto. Matches your phone's light or dark setting. Radio button, 1 of 4, selected`.
- Close: `Done`, swipe down, tap the scrim, or back. All four are equal; the choice is already saved.
- Rapid taps: the last one wins (F-002 edge cases).
- Auto + phone switches light/dark while the sheet is open: the sheet re-renders in the new theme and keeps Auto selected.
- After closing, focus returns to the Theme row, whose description now shows the new choice.

## 4. Theme (i) help sheet
Opened from the (i) on the Theme row; uses the help sheet in `help-pattern.md` §3.
- Title: `Theme`
- Body: `Choose how the app looks. Auto switches between Light and Dark with your phone's setting. Dim is a softer, warm grey theme that's easy on the eyes at any time of day.`
- Button: `Got it`

This is the longest (i) body in Phase 1, so it is the one the Tester uses for F-004 AC-13.

## 5. States

| State | What the user sees |
|---|---|
| First-time | Title, Settings hint card, then the three groups. |
| Normal | Title, then the three groups. |
| Empty | Not possible: the list is fixed. |
| Loading | None. The saved theme is read before the first frame, so the Theme row description is correct immediately. |
| Error (theme cannot be saved) | Nothing shown. The theme still changes for this session; next launch falls back to Auto if it cannot be read (F-002 edge cases). No dialog, no snackbar. |
| Permission denied | Not applicable. |

## 6. Themes

| Element | Light | Dark | Dim |
|---|---|---|---|
| Group card | `#FFFDF8` on page `#F6F3ED`, hairline `#DED8CD` | `#17171D` on `#0E0E12`, hairline `#2A2A33` | `#34312D` on `#2A2825`, hairline `#48453F` |
| Active label / inactive label | `#1C1B22` / `#5C5864` | `#F2F0EA` / `#A8A5B1` | `#EEE9E0` / `#BEB7AB` |
| "Coming soon" tag | `#5C5864` on `#EAE6DF` (5.56) | `#A8A5B1` on `#24242B` (6.37) | `#BEB7AB` on `#3D3A35` (5.69) |
| Radio selected / unselected | `#3A3DB0` / `#8A8377` | `#9C9FFF` / `#6A6876` | `#ABACF6` / `#878073` |
| Sheet over scrim | `#1C1B22` 40 %, sheet shadow | `#000` 60 %, no shadow | `#000` 50 %, no shadow |

**Auto** shows the Light or Dark column, following the phone.

## 7. Largest text (2.0×, 360 × 640 dp)
- Rows grow: label and description wrap; "How this app works" wraps to two lines at 28 sp, never truncated (F-003 edge case).
- The "Coming soon" tag moves **below** the description (left-aligned under the text) when the row's text column would be narrower than 160 dp. It is never clipped and never squeezes the label to one word per line.
- The Theme row's (i) stays right after the label; if the label wraps, the (i) follows the last word.
- The list scrolls; the whole list at 2.0× is about two and a half screens tall (F-003 AC-9 relies on this).
- Theme picker at 2.0×: rows wrap; the sheet grows up to 90 % of the screen, then the option list scrolls inside it while `Done` stays pinned at the bottom.

## Change history
| Date | Change | By |
|---|---|---|
| 2026-11-05 | First version | Designer |
| 2026-11-05 | Gate 2 review (Project Manager, `docs/reviews/design-phase-1.md`): §2.3 "Coming soon" screen-reader string set to one disabled item `<Label>, coming soon, not available yet. <Description>`; status → Approved at Gate 2 | Project Manager |
| 2026-11-06 | T-128 (Gate 2 N2): change-history table added. No spec content changed | Designer |

---

## Owner preview

### Settings, first visit (Light)
```
┌──────────────────────────────────────┐
│ Settings                             │
│ ╭──────────────────────────────────╮ │
│ │ ☼ Tip                         ×  │ │
│ │ Change the theme and other       │ │
│ │ options here. Tap (i) next to a  │ │
│ │ setting to learn what it does.   │ │
│ │                          Got it  │ │
│ ╰──────────────────────────────────╯ │
│ General                              │
│ ╭──────────────────────────────────╮ │
│ │ ◐ Theme (i)                    › │ │
│ │   Auto (follows your phone)      │ │
│ │──────────────────────────────────│ │
│ │ ♫ Notifications    [Coming soon] │ │
│ │   Budget warnings and an         │ │
│ │   end-of-day summary             │ │
│ ╰──────────────────────────────────╯ │
│ Money                                │
│ ╭──────────────────────────────────╮ │
│ │ ⌂ Bank account     [Coming soon] │ │
│ │   The one bank account the app   │ │
│ │   tracks                         │ │
│ │──────────────────────────────────│ │
│ │ ▤ Salary date      [Coming soon] │ │
│ │   The day your budget month      │ │
│ │   starts                         │ │
│ ╰─────────────── … ────────────────╯ │
│──────────────────────────────────────│
│                                  ▬   │
│   ⌂       ▥        ≣         ⫶       │
│ Home Dashboard Transactions Settings │
└──────────────────────────────────────┘
```
(Below, scrolling: Categories, then "Privacy & help": Privacy & data, How this app works, Disclaimer, all "Coming soon". Coming-soon labels are grey, Theme is full ink.)

### Theme picker, Dim just chosen (Dim theme)
```
┌──────────────────────────────────────┐
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░ (Settings, dimmed) ░░░░░░░░░░░│
│╭────────────────────────────────────╮│
│               ────                   │
│  Choose a theme                      │
│                                      │
│  ○ Auto                              │
│    Matches your phone's light or     │
│    dark setting                      │
│  ○ Light                             │
│    Bright and clean                  │
│  ○ Dark                              │
│    True dark, best at night          │
│  ◉ Dim                            ✓  │
│    Soft warm grey, easy on the eyes  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │              Done              │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```
(Warm grey slate sheet; the Dim dot and check are soft indigo. The app behind has already switched to Dim.)

### Theme (i) help sheet (Dark)
```
┌──────────────────────────────────────┐
│░░░░░░░░░ (Settings, dimmed) ░░░░░░░░░│
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
│                                      │
│  ┌────────────────────────────────┐  │
│  │             Got it             │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

### One "Coming soon" row at text 2.0
```
┌──────────────────────────────────────┐
│ ╭──────────────────────────────────╮ │
│ │ ◇ How this app                   │ │
│ │   works                          │ │
│ │   A short guide to               │ │
│ │   daily budgets and              │ │
│ │   saving                         │ │
│ │   [Coming soon]                  │ │
│ ╰──────────────────────────────────╯ │
└──────────────────────────────────────┘
```

### Why these choices
- **Picking a theme applies it live and keeps the sheet open**, so the user sees Dim before committing; "Done" is just a way out, nothing is lost by swiping away.
- **"Coming soon" rows stay fully readable** (grey label, tag, no chevron) instead of faded out, so the Owner and users can see the whole plan at a glance.
- **Three small groups** (General, Money, Privacy & help) make eight rows scannable without changing the order the feature doc fixes.
