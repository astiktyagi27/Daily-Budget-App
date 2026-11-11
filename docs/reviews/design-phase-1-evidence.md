# Design review of the Phase 1 emulator evidence (T-231)

**Reviewer:** Designer · **Date:** 2026-11-11 · **Task:** T-231 · **Covers:** F-002 AC-14, AC-16; F-005 AC-14
**Checked against:** `docs/design/design-system.md` (§2 colours, §3 contrast, §4 type, §7 components), `docs/design/screens/app-shell.md`, `settings.md`, `help-pattern.md`, `welcome-tour.md`.
**Method:** every screenshot was opened as an image. No app was run, no code changed.

## Verdict: PASS. No Must fix.

There is no clipping, no overflow, no wrong font and no contrast failure in any of the files. Buttons are reachable in every state. Five Nice to have items follow (one is the scrim decision). None of them blocks Gate 5.

## What was reviewed (50 files)

| Set | Files | Seen |
|---|---|---|
| `tc-002-25-{light,dim}-*-scale2.png`: home, dashboard, transactions, settings (each plain and with hint), settings-end, theme-info sheet, theme-picker sheet | 22 | all 22 |
| `tc-005-21-{light,dim}-*-scale2.png`: tour slides 1 to 4, SMS explainer, notifications explainer, disclaimer (each plain and `-buttons`) | 28 | 24 opened. The 4 Dim `slide1-4-buttons` files are byte-identical to their plain files (same MD5), so nothing more to see. Light `slide4-buttons` differs from plain only in encoding; both were opened and look the same |

All shots are Light or Dim at 2.0 text scale on a 360 dp-wide phone (1080 px, 3x), debug build (the red DEBUG ribbon is the Flutter debug banner, not part of the design).

## Checks

| Check | Result |
|---|---|
| **Fonts: headings** | Pass. "Daily Budget App", "Dashboard", "Transactions", "Settings", the empty-state titles, tour headlines ("Spend a little each day", "Saved days add up") and explainer headlines ("Read your bank SMS", "Before you start") are all clearly Bricolage Grotesque Bold: wide stance, ink-trap joins, single-storey "y" and the quirky "g". Sheet titles ("Theme", "Choose a theme") use `title` (Bricolage 600) in code (`help_sheet.dart`, `theme_picker_sheet.dart`); at SemiBold they read calmer than the Bold headlines, as expected |
| **Fonts: body, labels, buttons, money** | Pass. Descriptions, row labels, nav labels, button text and the tour ledger are IBM Plex Sans (double-storey "g", slab "I", mono-like numerals). ₹ renders as a Plex glyph in "₹830", "₹40,000", "−₹10,000", "₹1,130", "₹210" with no fallback-font look. "÷" and "−" in the ledger also render in Plex, so the §4.3 glyph note holds |
| **Clipping or overflow** | Pass. Titles wrap ("Daily Budget App" on one line, others on two or three), none is cut. No text is truncated with an ellipsis. Text sliced by the pinned button or nav bar is scrolling content leaving the viewport (the tour body under Next, Home and Settings bodies above the nav bar, the picker list above Done), which is the spec (`welcome-tour.md` §9, `app-shell.md`). The tour visual card is about 160 dp tall, as the spec caps it, and its amounts keep to the 1.3x cap |
| **Pinned buttons reachable** | Pass. Tour Next / Get started: pinned, full width, about 52 dp, always visible. Sheets: Got it and Done are pinned at the sheet bottom. Explainers and disclaimer: at 2.0x the button block sits at the end of the scroll content (spec `welcome-tour.md` §9); the `-buttons` shots show Allow SMS access, Not now, Turn on notifications and I understand fully visible, with their description lines, after one scroll |
| **Bottom navigation at 2.0x** | Pass. All four labels fit on one line, no ellipsis. "Transactions" shrinks to fit the slot (FittedBox, spec §7.7). The ink tick and the filled icon mark the selected tab in both themes |
| **Contrast** | Pass. Nothing contradicts §3. Light: primary text on `bg`, grey `textSecondary` descriptions, white on indigo buttons, indigo "Got it" and "Tip" on `accentSoft`, the "Coming soon" tag, day-cell numbers and amounts in the tour (green on mint, grey on grey, red on rose) all read clearly. Dim: `#EEE9E0` text, `#BEB7AB` descriptions, `#ABACF6` Next button with dark `#1B1B3D` label, lilac "Got it" on the slate-violet hint card, the green and red amounts on their dark fills and the disabled "Coming soon" tag are all legible. Outlines of the secondary buttons (Not now, Done, Got it) are visible in both themes. The page indicator dots are visible against `bg` |
| **Colour rules** | Pass. Green and red appear only on the tour's saved / overspent day cells and the savings-pot figure, each with its mark (dot, ring, diamond) and a word under it. No red or green is used for decoration |
| **Design system and screen specs** | Pass. Hint card: lightbulb, "Tip" overline, ×, "Got it" (§7.11c). Empty states are left-aligned with the 88 dp neutral circle (§7.10). Settings is grouped cards with 40 dp icon circles, hairlines inset to the text, (i) after "Theme", "Coming soon" tags (§7.4). Sheets have the 28 dp top radius, drag handle, title, pinned Secondary button over the scrim (§7.8). Tour matches `welcome-tour.md` (page indicator and Skip in the top row, no Skip on slide 4, visual card, headline, body, pinned button). Ruled, flat look with hairlines and no shadows in Dim, as §5.3 says |
| **Themes** | Light "Paper" and Dim "Slate" both match the §2 palettes. The scrim over the Dim sheets is darker than the sheet, so the sheet stays clear |

## Nice to have (none blocks Gate 5)

| # | File(s) | What is wrong | Suggested fix | When |
|---|---|---|---|---|
| **N1** | (not a screenshot) `app/lib/core/widgets/budget_sheet.dart` | TalkBack reads the sheet scrim as "Scrim" (Gate 3 N1) | Decision below: use `Close`. Task T-233 | Phase 1 walk-through or Phase 3 |
| **N2** | `tc-002-25-dim-theme-picker-scale2.png`, `tc-002-25-light-theme-picker-scale2.png` | At 2.0x the picker shows Auto, Light and a cut "True dark, best at night", with **Dim** and the current choice off the screen. In the Dim shot no option shows as selected, so the user cannot see which theme is active without scrolling. The cut-off line has no cue that more follows | Open the picker scrolled so the selected row is in view, and/or add a short fade at the bottom edge of any scrolling sheet body | Phase 3 polish |
| **N3** | `tc-005-21-{light,dim}-slide1/2/3/4-scale2.png` (and the `-buttons` copies) | At 2.0x the tour body is cut mid-line above the pinned Next button, with no cue that it scrolls (spec: scrolls) | Same bottom fade as N2, shared in the pinned-button area | Phase 3 polish |
| **N4** | `tc-002-25-*-scale2.png` (nav bar) | At 2.0x "Transactions" shrinks to about 80 percent of its neighbours and sits a few px higher than the other three labels | Align the shrunk label to the shared baseline (bottom align the FittedBox). Allowed by §7.7 as is | Phase 6 polish |
| **N5** | `tc-005-21-{light,dim}-slide2-scale2.png` | The ledger inside the tour visual uses only the left half of the card at 2.0x, with the right half empty (amounts are capped at 1.3x as specified, so they do not fill the width) | Let the ledger fill the card width at large text. Decorative only | Phase 6 polish |

## Decision: sheet scrim label (Gate 3 N1)

**Change the label to `Close`.**

- Why: TalkBack currently announces "Scrim", a graphics word that tells a first-time user nothing. STANDARDS §7 and the designer rule say every control says what it does. The scrim's job is to close the sheet, so the label is the action, in plain words.
- Why not "Close sheet" or "Dismiss": "Close" matches the spoken action of the sheet's own buttons (Done, Got it) and is the shortest. "Sheet" is jargon, "Dismiss" is less common in everyday English.
- It stays accurate on decision sheets, where scrim means the safe, non-saving choice (Cancel, Keep editing, Not now). The buttons on those sheets still name their own consequences, so a blind user who taps "Close" gets exactly what the spec promises for scrim / swipe / back.
- It does not clash with the tip's `Dismiss tip` label or with any tab label.
- Recorded in `docs/design/design-system.md` §7.8 and its change history. Code follows in **T-233** (Developer): set `barrierLabel` in `budget_sheet.dart` to `Close` and update the test constant `_scrimLabel` in `app/test/architecture/help_rule_test.dart`. No visual change.

## Evidence notes for the Tester

- Only Light and Dim at 2.0x are covered by these shots. Dark is covered by `TC-002-03/-22/-23/-24` sweeps (T-138), not by a screenshot.
- The `-buttons` tour shots add nothing over the plain shots: the Next button is pinned, so the two are identical. Not a defect.
- All shots come from a debug build. Release behaviour of layout and fonts is the same.

## Result for T-231

Design review of the emulator evidence: **Pass, no Must fix**. T-231 set to Done in `docs/TASKS.md`. Gate 5 is not blocked by design.
