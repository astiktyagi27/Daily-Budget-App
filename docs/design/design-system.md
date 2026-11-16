# Design system: "Neel Khata"

**Owner of this file:** Designer · **Phase:** 1 (F-002 design system & themes, also used by F-003, F-004 and F-005) · **Status:** Approved at Gate 2 (Project Manager, 2026-11-05; `docs/reviews/design-phase-1.md`). Phase 3 additions (§3 rows, §4.3, §7.5, §7.6, §7.14–7.16, §8.4; 2026-11-11) pending Phase 3 Gate 2
**Read with:** `README.md` §5, `docs/STANDARDS.md` §7, `plans/phase-1-overview.md`, `docs/DECISIONS.md` (D-003 no network, D-007 themes, D-012 owner preview).

---

## 1. The direction: "Neel Khata" (indigo ledger)

A *bahi-khata* is the ledger book Indian shops have kept for generations: warm paper, ruled lines, one ink, every rupee written in its own column. **Neel Khata** is that book redrawn for a phone. *Neel* is indigo, the ink.

What this means on screen:

1. **Paper, not glass.** Surfaces are warm off-white paper (Light), true ink-black (Dark) or warm grey slate (Dim). There are no gradients, no glassmorphism and no purple-to-pink blobs.
2. **Ruled, not floating.** Structure comes from **hairline rules** (1 dp lines) and gentle tonal steps. Shadows appear only on things that really float: the bottom sheet and the snackbar. Cards sit flat on the page, with a hairline edge.
3. **One ink.** Indigo is the only accent. It is used for the primary action, the selected tab, today's ring and focus. Green and red appear **only** when money was saved or overspent (STANDARDS §7).
4. **Numbers are the hero.** Amounts are large, tabular and set like a ledger column, so ₹830 and ₹1,33,333 line up digit for digit. Words sit quietly around them.
5. **A ledger mark, not just a colour.** Every day result has a small shape as well as a colour: ● saved, ○ on budget, ◆ overspent. Colour-blind users and grey-scale screenshots still read the calendar correctly.
6. **Hand-set headings.** Headings use Bricolage Grotesque, a slightly quirky grotesque with ink-trap character. It is what stops the app looking like a stock Material template. Everything else uses the calm, highly readable IBM Plex Sans.

What we avoid on purpose: default Roboto, the Material 3 pill indicator under nav icons, purple gradients, emoji as UI icons, oversized drop shadows, and centred "hero illustration + three bullet points" layouts.

---

## 2. Colour tokens

Token names are the same in every theme. The Developer only switches the set.

| Token | Use | Light | Dark | Dim |
|---|---|---|---|---|
| `bg` | Page / scaffold background | `#F6F3ED` | `#0E0E12` | `#2A2825` |
| `surface` | Cards, sheets, nav bar, inputs | `#FFFDF8` | `#17171D` | `#34312D` |
| `sunken` | Pressed rows, calendar weekday strip, input fill | `#EEEAE2` | `#0A0A0D` | `#24221F` |
| `textPrimary` | Main text and amounts | `#1C1B22` | `#F2F0EA` | `#EEE9E0` |
| `textSecondary` | Descriptions, captions, future days | `#5C5864` | `#A8A5B1` | `#BEB7AB` |
| `accent` | Primary button, selected tab, today ring, links | `#3A3DB0` | `#9C9FFF` | `#ABACF6` |
| `onAccent` | Text/icons on a filled accent | `#FFFFFF` | `#14143D` | `#1B1B3D` |
| `accentSoft` | First-time hint card, selected chip fill | `#E7E6F6` | `#25264A` | `#3E3D55` |
| `saved` | Saved amounts, ● mark | `#1A7044` | `#52C98B` | `#80D3A1` |
| `savedSoft` | Saved day cell fill | `#DDEFE3` | `#16301F` | `#2F3F33` |
| `overspent` | Overspent amounts, ◆ mark, input errors | `#B4372F` | `#FF7B6F` | `#FF9C8E` |
| `overspentSoft` | Overspent day cell fill | `#F6E0DC` | `#3A1A17` | `#4A3230` |
| `neutral` | On-budget amounts, ○ mark, inactive nav icons | `#68646E` | `#9F9CA7` | `#B6AFA4` |
| `neutralSoft` | On-budget day cell fill, disabled fills | `#EAE6DF` | `#24242B` | `#3D3A35` |
| `border` | Hairline rules and card edges (decorative) | `#DED8CD` | `#2A2A33` | `#48453F` |
| `borderStrong` | Input outlines, checkbox/switch outlines | `#8A8377` | `#6A6876` | `#878073` |
| `focus` | 2 dp keyboard/accessibility focus ring | `#3A3DB0` | `#BDBFFF` | `#C6C7FF` |
| `inverseSurface` | Snackbar and tooltip bubble | `#1C1B22` | `#EEE9E0` | `#EEE9E0` |
| `onInverseSurface` | Text on snackbar/tooltip | `#F2F0EA` | `#1C1B22` | `#1C1B22` |
| `inverseAccent` | Action text on snackbar ("Undo") | `#ABACF6` | `#3A3DB0` | `#3A3DB0` |
| `scrim` | Behind bottom sheets | `#1C1B22` at 40 % | `#000000` at 60 % | `#000000` at 50 % |

**Theme choices (Settings → Theme):**
- **Light**: the Light set.
- **Dark**: the Dark set. A true dark for night use, near-black (not pure `#000000`, which smears on OLED when scrolling).
- **Dim**: the Dim set. Warm grey slate, lower contrast than Dark, easy on the eyes in the evening.
- **Auto** (default): follows the phone. Phone in light mode → Light, phone in dark mode → **Dark**. Dim is only used when the user picks it.

**Rules:**
- Red and green are never used for decoration, icons or branding. `overspent` also marks input errors, but always together with an icon and a written message.
- A status is never shown by colour alone. It always also has the mark (● ○ ◆) and/or words ("Saved ₹333").
- `border` is decorative only (1.4 : 1). Anything the user must see to operate a control uses `borderStrong` (≥ 3 : 1).

---

## 3. Contrast check (WCAG 2.2)

Ratios are computed with the WCAG relative-luminance formula. AA needs **4.5 : 1** for normal text and **3 : 1** for large text (≥ 18 sp regular / 14 sp bold) and for UI parts such as outlines and focus rings (1.4.11). Every text pair below passes **AA for normal text**, so no pair relies on the large-text allowance.

| Pair (foreground on background) | Light | Dark | Dim | Needed |
|---|---|---|---|---|
| `textPrimary` on `bg` | 15.43 | 16.90 | 12.16 | 4.5 |
| `textPrimary` on `surface` | 16.81 | 15.66 | 10.70 | 4.5 |
| `textPrimary` on `sunken` | 14.24 | 17.35 | 13.12 | 4.5 |
| `textSecondary` on `bg` | 6.25 | 7.96 | 7.39 | 4.5 |
| `textSecondary` on `surface` | 6.81 | 7.38 | 6.50 | 4.5 |
| `textSecondary` on `sunken` | 5.77 | 8.17 | 7.97 | 4.5 |
| `accent` on `bg` | 7.66 | 8.09 | 6.97 | 4.5 |
| `accent` on `surface` | 8.35 | 7.49 | 6.14 | 4.5 |
| `onAccent` on `accent` (filled button) | 8.49 | 7.36 | 7.84 | 4.5 |
| `accent` on `accentSoft` (hint card link) | 6.89 | 6.06 | 4.97 | 4.5 |
| `textPrimary` on `accentSoft` (hint text) | 13.87 | 12.67 | 8.67 | 4.5 |
| `saved` on `surface` | 6.00 | 8.57 | 7.24 | 4.5 |
| `saved` on `bg` | 5.50 | 9.25 | 8.22 | 4.5 |
| `saved` on `savedSoft` (saved cell) | 5.09 | 6.83 | 6.25 | 4.5 |
| `textPrimary` on `savedSoft` (day number) | 14.26 | 12.48 | 9.24 | 4.5 |
| `overspent` on `surface` | 5.86 | 7.07 | 6.41 | 4.5 |
| `overspent` on `bg` | 5.37 | 7.63 | 7.28 | 4.5 |
| `overspent` on `overspentSoft` (overspent cell) | 4.71 | 6.20 | 5.81 | 4.5 |
| `textPrimary` on `overspentSoft` (day number) | 13.52 | 13.75 | 9.70 | 4.5 |
| `neutral` on `surface` | 5.68 | 6.62 | 5.95 | 4.5 |
| `neutral` on `bg` | 5.21 | 7.14 | 6.76 | 4.5 |
| `neutral` on `neutralSoft` (on-budget cell) | 4.64 | 5.72 | 5.21 | 4.5 |
| `textPrimary` on `neutralSoft` | 13.73 | 13.53 | 9.36 | 4.5 |
| `onInverseSurface` on `inverseSurface` (snackbar) | 14.99 | 14.13 | 14.13 | 4.5 |
| `inverseAccent` on `inverseSurface` ("Undo") | 8.11 | 7.02 | 7.02 | 4.5 |
| `borderStrong` on `surface` (input outline) | 3.69 | 3.28 | 3.31 | 3.0 |
| `focus` on `surface` (focus ring) | 8.35 | 10.25 | 8.02 | 3.0 |
| `focus` on `bg` | 7.66 | 11.06 | 9.11 | 3.0 |
| `textSecondary` on `neutralSoft` ("Coming soon" tag, disabled button label) | 5.56 | 6.37 | 5.69 | 4.5 |
| `textSecondary` on `accentSoft` (hint card × icon) | 5.62 | 5.97 | 5.27 | 3.0 |
| `borderStrong` on `bg` (tour page indicator, other slides) | 3.39 | 3.54 | 3.76 | 3.0 |
| `accent` on `savedSoft` (change-day tick, Phase 3) | 7.09 | 5.97 | 5.30 | 3.0 |
| `accent` on `neutralSoft` (change-day tick) | 6.82 | 6.47 | 5.37 | 3.0 |
| `accent` on `overspentSoft` (change-day tick) | 6.72 | 6.58 | 5.57 | 3.0 |
| `textPrimary` on `neutralSoft` (category bar fill on its track, Phase 3) | 13.73 | 13.53 | 9.36 | 3.0 |

Tightest pairs: Light `overspent` on `overspentSoft` (4.71) and Light `neutral` on `neutralSoft` (4.64). **Do not lighten** `overspent`/`neutral` or darken those fills in Light without re-running this check. Error text on a filled red uses `onError` = `#FFFFFF` on `#B4372F` (5.95) in Light, and `#1C1B22` on `#FF7B6F` (6.76) / `#FF9C8E` (8.46) in Dark / Dim.

---

## 4. Typography

### 4.1 Families, weights and files (all bundled, no runtime download)

| Role | Family | Weights | Files in `app/assets/fonts/` | Licence |
|---|---|---|---|---|
| Headings: screen titles, month name, onboarding headlines, empty-state titles | **Bricolage Grotesque** (Mathieu Triay) | 600 SemiBold, 700 Bold | `BricolageGrotesque-SemiBold.ttf`, `BricolageGrotesque-Bold.ttf` | SIL OFL 1.1 → `assets/fonts/OFL-BricolageGrotesque.txt` |
| Everything else: body, labels, buttons, **all money** | **IBM Plex Sans** (IBM) | 400 Regular, 500 Medium, 600 SemiBold | `IBMPlexSans-Regular.ttf`, `IBMPlexSans-Medium.ttf`, `IBMPlexSans-SemiBold.ttf` | SIL OFL 1.1 → `assets/fonts/OFL-IBMPlexSans.txt` |

- Files come from the official upstream sources, pinned and hashed in `app/assets/fonts/SOURCES.md` (plan F-002 §2): Bricolage from `github.com/ateliertriay/bricolage` at commit `84745e5b96`, folder `fonts/ttf/`, the **unprefixed** static SemiBold/Bold (upstream has no 24pt set, so the unprefixed default instance is used; confirmed at Gate 1/2); IBM Plex Sans from the IBM release `@ibm/plex-sans@1.1.0`. If a later download names its statics with an optical-size prefix, use the 24pt instance and rename it to the names above.
- Fonts are declared in `pubspec.yaml` under `flutter: fonts:` with families `Bricolage` and `Plex`. Do **not** use the `google_fonts` package (it downloads at runtime; D-003, phase-1 overview risk).
- Both OFL licence texts are bundled and registered with `LicenseRegistry.addLicense` so they show on the Flutter licences page.
- **Why money is in Plex, not Bricolage:** IBM Plex Sans has the Indian rupee sign (U+20B9) and tabular figures. Keeping every digit in one family means amounts always align and the rupee sign never falls back to another font.
- **Developer check (part of F-002, now a permanent automated test, TC-002-42):** a Dart font-table reader confirms on every test run that each bundled Plex file contains U+20B9 in `cmap` and has **tabular figures**: either all ten default digits share one advance width, or `GSUB` has `tnum` (a one-time `fontTools` check is optional). *Gate 3 (PM, 2026-11-05): IBM Plex Sans 1.1.0 has no `tnum` feature because its default digits are already tabular (600 units in all three weights), which meets the intent of this rule. Money styles still set `FontFeature.tabularFigures()`.* If either is missing, stop and tell the Designer. Do not swap fonts silently. **Named fallback (only if U+20B9 is missing):** bundle **Noto Sans** Regular/Medium/SemiBold (SIL OFL 1.1, Google), subset to U+20B9 plus digits is acceptable, and add it as `fontFamilyFallback: ['NotoSans']` on every `money*` style. This is a contingency, not part of the plan unless the check fails. Bricolage is only ever used for words, so its digit and ₹ coverage do not matter. If a heading ever contains an amount, the amount is a separate Plex span.

### 4.2 Type scale

Sizes are in sp, so they scale with the phone's font size. Line height is given as a value in sp (Flutter `height` = line ÷ size).

| Token | Family / weight | Size / line | Letter spacing | Use |
|---|---|---|---|---|
| `displayHeadline` | Bricolage 700 | 32 / 38 | −0.5 | Welcome tour headline |
| `headline` | Bricolage 700 | 26 / 32 | −0.3 | Screen title ("Home", "November") |
| `title` | Bricolage 600 | 20 / 26 | −0.2 | Card titles, sheet titles, empty-state titles |
| `moneyHero` | Plex 600, tabular | 40 / 46 | −0.8 | The one big number on a screen ("₹16,700 left") |
| `moneyLarge` | Plex 600, tabular | 28 / 34 | −0.4 | Today's budget, day details total |
| `moneyMedium` | Plex 500, tabular | 18 / 24 | 0 | Summary figures, list row amounts |
| `moneySmall` | Plex 500, tabular | 12 / 16 | 0 | Calendar cell amounts |
| `bodyLarge` | Plex 400 | 16 / 24 | 0 | Main reading text, onboarding body |
| `body` | Plex 400 | 14 / 20 | 0.1 | Descriptions under labels, row subtitles |
| `label` | Plex 500 | 14 / 20 | 0.1 | Row titles, field labels, nav labels (12 / 16) |
| `button` | Plex 600 | 15 / 20 | 0.2 | Button text, sentence case (never ALL CAPS) |
| `caption` | Plex 400 | 12 / 16 | 0.2 | Weekday letters, timestamps, helper text |

- **Tabular numerals:** every `money*` style sets `fontFeatures: [FontFeature.tabularFigures()]`. Number count-up animations therefore never jitter in width.
- **Largest system font:** text scales up to the phone's maximum (Android allows 200 %). Layouts wrap, never clip. Screen titles are never in a fixed-height app bar; they sit in the scrolling body so they can wrap. Two things are capped at **1.3×**: the bottom-navigation labels (§7.7) and decorative text inside onboarding visuals (`screens/welcome-tour.md` §9). `moneySmall` inside calendar cells is also capped at 1.3× scale; at larger scales the cell hides the amount and shows only the day number and mark (the amount stays in day details and in the cell's screen-reader label).

### 4.3 Money formatting (Indian grouping)

- All money text comes from the one shared formatter `formatRupees(Paise)` (F-008 AC-19, plan F-008 §1.4). It takes **integer** rupees (`paise.abs() ~/ 100`, rounded toward ₹0) and groups them by hand in the Indian 3-then-2 pattern, with no `intl` package (D-070; the output is identical to `NumberFormat.decimalPattern('en_IN')` on whole rupees). **Never** `NumberFormat.currency` (it takes a `double` and rounds half-up, so ₹666.67 would show ₹667; look-ahead #12). Money is stored in paise (D-010), so convert on display only. *(Corrected at Gate 2, 2026-11-10.)*
- Examples: **₹1,33,333** · **₹40,000** · **₹15,100** · **₹830** · **₹1,00,000** · **₹12,34,567**.
- Paise are shown only inside input fields (D-038; see the rule below).
- No space between ₹ and the digits. Negative amounts use the true minus sign U+2212: **−₹467**. In the UI, overspending is normally written in words ("Overspent ₹467") rather than as a negative number.
- Plus sign only for a saved day result: **+₹333**.
- **Minus sign (confirmed for Phase 2, F-008 plan Q4):** always U+2212 `−`, never the hyphen `-`. Directly before the ₹ with a word joiner (U+2060) between them, so the sign never wraps away: `−₹1,000`. In arithmetic lines, a space on each side: `₹40,000 − ₹15,100 fixed = ₹24,900`.
- **Amounts never split across lines:** the formatter's output is one unbreakable unit (word joiner after ₹; grouping commas are not break points). Phrases that must stay together on screen ("spent ₹250") use non-breaking spaces.
- **Screen readers:** semantics labels spell the sign: "minus ₹1,000" (TalkBack does not read U+2212 consistently). Labels contain no invisible characters (no U+2060 / U+00A0).
- **No `−₹0`:** when the whole rupees are 0, there is no sign (−99 paise → `₹0`) (D-050).
- **Under ₹1 (D-050):** a day result or difference that is not exactly ₹0 but rounds to ₹0 (1–99 paise either way: left today, overspent, short, saved, a cover taken back) reads `less than ₹1` (`less than ₹1 left today`, `overspent less than ₹1`, `◆ less than ₹1 short`). The result word and colour follow the exact paise. Totals, budgets and single spends keep the plain formatter (`₹0`).
- **Short forms (Phase 3):** only inside calendar cells, amounts of ₹10,000 or more use `formatRupeesShort` (`₹12k`, `₹1.5L`, `₹10Cr`; rules in §7.5). Everywhere else amounts are written in full.
- **Arrows in working lines (Phase 3):** `→` (U+2192) is set in Plex like the digits. The F-002 font check adds U+2192 to the glyphs it confirms; if it is missing, the line uses the word `so` instead (`= ₹24,900 over 30 days, so ₹830/day`).
- **Whole rupees, rounded down (D-038):** every amount outside an input field shows whole rupees, rounded toward ₹0 (₹830.50 → ₹830; −₹120.50 → −₹120). Paise are shown only inside input fields while typing or editing. This replaces the earlier "₹830.50 for a single transaction" example.

---

## 5. Spacing, radii, elevation, motion

### 5.1 Spacing scale (dp, base 4)

| Token | Value | Typical use |
|---|---|---|
| `space1` | 4 | Icon to text inside a chip |
| `space2` | 8 | Label to description |
| `space3` | 12 | Inside list rows (vertical) |
| `space4` | 16 | Card padding, gap between cards |
| `space5` | 20 | **Screen side gutter** |
| `space6` | 24 | Between sections |
| `space7` | 32 | Above a screen title |
| `space8` | 40 | Empty-state spacing |
| `space9` | 56 | Onboarding top space |

Touch targets are at least **48 × 48 dp** even when the visible element is smaller (the 18 dp (i) icon, the calendar cell).

### 5.2 Corner radius

| Token | Value | Use |
|---|---|---|
| `radiusXs` | 6 | Calendar day cell, small chips |
| `radiusSm` | 10 | Snackbar, tooltip bubble |
| `radiusMd` | 14 | Buttons, inputs, hint card |
| `radiusLg` | 20 | Cards |
| `radiusXl` | 28 | Bottom sheet top corners |
| `radiusFull` | 999 | Pills, switch track, today ring |

### 5.3 Elevation

Neel Khata is flat. Depth comes from tone and hairlines.

| Level | Light | Dark / Dim | Used by |
|---|---|---|---|
| 0 Flat | no shadow, 1 dp `border` edge | no shadow, 1 dp `border` edge | Cards, inputs, nav bar (top rule only) |
| 1 Float | `0 4 16` `#1C1B22` at 8 % | no shadow; `surface` + 1 dp `border` | Snackbar, tooltip |
| 2 Sheet | `0 -8 32` `#1C1B22` at 12 % | no shadow; `surface` over `scrim` | Bottom sheet |

Material's surface tint is turned off (`surfaceTintColor: Colors.transparent`) so cards never turn purple-ish.

### 5.4 Motion

| Token | Duration | Easing | Use |
|---|---|---|---|
| `motionFast` | 120 ms | `standard` | Press states, (i) tooltip fade, switch |
| `motionBase` | 200 ms | `standard` | Tab change cross-fade, chip select |
| `motionEmphasis` | 320 ms | `decelerate` in / `accelerate` out (240 ms) | Bottom sheet, snackbar, hint card in/out |
| `motionCount` | 600 ms | `decelerate` | Money count-up when a number changes |

Easing curves: `standard` = `Cubic(0.2, 0.0, 0.0, 1.0)`, `decelerate` = `Cubic(0.05, 0.7, 0.1, 1.0)`, `accelerate` = `Cubic(0.3, 0.0, 0.8, 0.15)`.

Rules: nothing bounces, nothing spins. Movement is at most 16 dp (things slide in slightly and settle). When the phone has "Remove animations" on (`MediaQuery.disableAnimationsOf(context)`), every duration becomes 0 and count-ups jump straight to the final value.

---

## 6. Iconography

- Line icons with a **1.75 dp stroke**, round caps and joins, on a 24 dp grid with 20 dp live area. Filled variants are used only for the selected nav tab.
- Phase 1 uses Flutter's **built-in Material Icons** (`Icons.*_outlined` for line icons, the filled variant for the selected tab) as a stand-in. *(Gate 2 correction: the built-in icon font is not variable, so `Icon(weight: 300)` has no effect; a true 300-weight look needs the Material Symbols variable font from an extra package, which is not added in Phase 1.)* Custom icons can replace them later with no layout change (Phase 6).
- Nav icons: Home = house, Dashboard = bar chart, Transactions = list with ₹ (stand-in: `receipt_long`), Settings = sliders (stand-in: `tune`, not a gear).
- The info icon is a 18 dp ring with a lowercase "i" (`info` outlined).

---

## 7. Components

Every component works in all four themes using only tokens. "Hairline" = 1 dp `border`.

### 7.1 Button
| Variant | Look | Use |
|---|---|---|
| **Primary** | `accent` fill, `onAccent` text, `button` style, height 52 dp, `radiusMd`, full width on mobile | One per screen at most: "Continue", "Save" |
| **Secondary** | `surface` fill, 1 dp `borderStrong`, `textPrimary` text, height 52 dp | "Skip tour", "Not now" |
| **Text** | No fill, `accent` text, min 48 dp touch area | "Got it", "Learn more", "Undo" |
| **Destructive** | Secondary style with `overspent` text and a leading icon | "Delete" (Phase 2+); always followed by a confirm sheet |

States: pressed = 8 % `textPrimary` overlay (Light) / 10 % `#FFFFFF` overlay (Dark, Dim) for `motionFast`; disabled = `neutralSoft` fill, `textSecondary` text, no outline; focus = 2 dp `focus` ring offset 2 dp; loading = label replaced by a 20 dp progress ring, width unchanged. Text is sentence case, verb first, at most 3 words.

### 7.2 Card
`surface` fill, hairline edge, `radiusLg`, padding `space4` (16 dp; 20 dp for the summary card). Optional header row: `title` + optional (i). No shadow. Cards never stack inside cards.

### 7.3 Input (text and amount)
- Label above the field (`label`, `textPrimary`), description below the label (`body`, `textSecondary`), then the field. The label never disappears into the field (no floating-label animation).
- Field: height 56 dp, `sunken` fill, 1 dp `borderStrong` outline, `radiusMd`. Focused: 2 dp `accent` outline. Error: 2 dp `overspent` outline + error icon + message below in `overspent` `body`.
- Amount fields show a fixed "₹" prefix in `textSecondary`, use `moneyMedium` for the value, and the number keypad. The field shows the digits **exactly as typed** (`133333`), with no grouping while typing (D-069): nothing rewrites the text, so the cursor never jumps and the screen reader reads the same digits the keypad entered. The grouped amount (₹1,33,333) appears in the screen's live preview line under the form, in the same frame as the keystroke. Pasted text such as `₹40,000` is accepted and shown as typed.

### 7.4 List row
- Min height 56 dp (72 dp with a description). Padding `space5` sides, `space3` top/bottom.
- Layout: optional 40 dp leading (icon in a `neutralSoft` circle) · title (`label`) with description below (`body`, `textSecondary`) · trailing (amount in `moneyMedium`, switch, value + chevron, or (i)).
- Rows in a group are separated by hairlines inset to the text start. Pressed row = `sunken` fill.
- The whole row is the touch target. The (i) has its own 48 dp target and does not trigger the row.

### 7.5 Calendar day cell
Size: square, width = (content width − 2 × 20 dp gutters − 6 × 4 dp gaps) ÷ 7 (about 42–52 dp in portrait), with a 48 dp min touch target. In landscape or on wide screens the cell is capped at **56 dp** and the grid is centred. `radiusXs`. Inner padding 4 dp.
Content: day number top-left (`caption` weight 500), mark top-right (6 dp), net spent amount bottom-right (`moneySmall`, always with ₹, no paise).

**Amount rules (Phase 3, F-011 §2.2):**
- Whole rupees rounded toward ₹0 through the shared formatter (D-038, D-046). A past day with no spends shows `₹0`.
- **Fit:** the amount sits in `FittedBox(fit: BoxFit.scaleDown)` limited to the cell's inner width, so `₹9,999` on a 360 dp phone renders at about 11 sp instead of clipping. Never an ellipsis.
- **Short forms (cells only)** from the shared `formatRupeesShort(Paise)`, integer maths only, rounded toward ₹0, a trailing `.0` dropped:

  | Net spent (whole rupees) | Cell shows | Rule |
  |---|---|---|
  | below ₹10,000 | `₹9,999` | full amount, Indian grouping |
  | ₹10,000 – ₹99,999 | `₹10k` · `₹12k` (₹12,999) · `₹99k` | thousands, lower-case `k`, no decimal |
  | ₹1,00,000 – ₹99,99,999 | `₹1L` · `₹1.5L` (₹1,59,999) · `₹99.9L` | lakh, one decimal: `t = rupees ÷ 10,000`, shown `t ÷ 10` `.` `t % 10` |
  | ₹1,00,00,000 and above | `₹1Cr` · `₹10Cr` · `₹12.3Cr` | crore, one decimal: `t = rupees ÷ 10,00,000` |

  Negative net spends (refunds bigger than spends, D-047) keep the sign: `−₹1,300`, `−₹12k`. The full amount is always in day details and in the cell's screen-reader label.
- **First day of a new calendar month** inside a budget month: the number slot reads `1 Dec` (same style, also fitted).
- Above 1.3× text the amount is hidden; number and mark stay (§4.2).

| State | Fill | Day number | Amount | Mark | Screen reader label |
|---|---|---|---|---|---|
| **Saved** | `savedSoft` | `textPrimary` | net spent, in `saved` | ● filled circle, `saved` | "Monday 9 November, spent ₹620, saved ₹210" |
| **On budget** (incl. fully covered) | `neutralSoft` | `textPrimary` | net spent, in `neutral` | ○ ring 1.5 dp, `neutral` | "Tuesday 10 November, spent ₹830, on budget" |
| **Overspent** (incl. partly covered) | `overspentSoft` | `textPrimary` | net spent, in `overspent` | ◆ filled diamond, `overspent` | "Wednesday 11 November, spent ₹1,130, overspent ₹300" |
| **Today** | fill of today's result so far (or `surface` if nothing spent) | `accent`, weight 600 | spent so far, `textPrimary` | as its state | "Today, Friday 13 November, spent ₹420 so far, ₹410 left" |
| | + 2 dp `accent` ring (inside the cell edge) | | | | |
| **Future** (upcoming) | none; hairline `border` outline | `textSecondary` | none | none | "Saturday 14 November, upcoming" |
| **Not budgeted** (Phase 3: days before a mid-month first use or a late setup, D-034, D-057) | none, **no outline** | `textSecondary` at **100 %** (readable, unlike Outside) | none | none | "5 November, not budgeted, before you started" (late setup: "…, before this month's setup"). Not tappable, no press effect |
| **Outside month** (before salary date / after month end) | none | `textSecondary` at 50 % (decorative, not a tappable day) | none | none | excluded from screen reader |

How the three "empty-looking" cells differ without colour: **Future** has a hairline box; **Not budgeted** has no box but a full-strength number; **Outside** has no box and a faded number. A caption under the grid names the not-budgeted days (`screens/calendar.md` §5.4).

**Change-day marker (Phase 3, D-037):** on the first day of a new budget period (not the month's first period), a small **ink tick**, 12 × 3 dp, `accent`, `radiusFull`, centred horizontally 4 dp below the top edge (inside the today ring when both apply). It reuses the bottom-navigation tick (§7.7), the app's signature mark, so it reads as "something about the budget", not as a day result. Decorative; the label adds ", budget changed this day". Contrast of `accent` on every fill it can sit on is in §3 (lowest 5.30 : 1, Dim `savedSoft`).

Pressed: cell scales to 0.96 for `motionFast`. Tap opens day details (Phase 3, `screens/day-details.md`). The weekday header row (M T W T F S S, `caption`, `textSecondary`) sits on a `sunken` strip. Full calendar spec: `screens/calendar.md`.

### 7.6 Summary bar
The always-visible money summary at the top of Home (README §2 "Top summary").
- A **card** with: overline label "Left this month" + (i), `moneyHero` amount, a line "₹830/day · 1 – 30 Nov" in `body` `textSecondary`.
- Below a hairline: a ledger of figures in two columns (label left in `body` `textSecondary`, amount right in `moneyMedium`): Salary, Fixed costs, Spent so far, **Saved** (amount in `saved` with ●), **Overspent** (amount in `overspent` with ◆).
- A thin 4 dp progress rule under the hero shows spent ÷ spendable in `textPrimary` on `neutralSoft`. It is not coloured green/red, because it is not a day result.
- Collapsed mode on scroll (Phase 3): one 56 dp row "₹16,700 left · ₹830/day", pinned at the top of the Home body (there is no app bar; it sits under the status bar).
- Every figure has an (i) explaining it (copy owned by the feature docs).
- **Phase 3 additions** (full spec `screens/home-summary.md`): a `Safe to spend` line under the day line (F-017, a guide, never green or red); a savings-pot sub-line under Saved when covers exist; Spending target / Money left at start rows; the shortfall panel inside the card; a `Budget changed on …` line; a `Month statement` text button at the bottom; `Edit this month` in a ⋮ menu. A **₹0 Saved or Overspent figure is shown in `neutral` with no mark**: green ● and red ◆ appear only when there is money saved or overspent.

### 7.7 Bottom navigation
- Four destinations, always labelled: **Home**, **Dashboard**, **Transactions**, **Settings**.
- Height 64 dp + system gesture area. `surface` fill, top hairline, no shadow.
- Inactive: outlined icon + `label` 12 sp in `neutral`. Selected: filled icon + label in `accent`, weight 600, and a **4 × 16 dp ink tick** (`accent`, `radiusFull`) above the icon. This tick replaces Material's pill and is the app's signature detail.
- Change of tab: tick slides between items (`motionBase`), body cross-fades (`motionBase`). Each item is ≥ 48 dp wide and has the semantic label "Home, tab 1 of 4".
- **Label scaling at large text** (so "Transactions" never clips): (1) the label's text scale is clamped to **1.3×** (`textScaler.clamp(maxScaleFactor: 1.3)`), the icon never scales; (2) each label is one line, no ellipsis, inside `FittedBox(fit: BoxFit.scaleDown)` limited to the slot width − 8 dp, so it shrinks to fit if still too wide (e.g. 320 dp-wide screens); (3) long-press shows a tooltip and TalkBack reads the label at full size. The bar grows from 64 dp to about 72 dp at the cap. Full spec: `screens/app-shell.md` §3.2.

### 7.8 Bottom sheet
`surface` fill, `radiusXl` top corners, 32 × 4 dp drag handle in `borderStrong` placed 8 dp from the top edge. Title (`title`) + optional description, content, then actions. Max height 90 % of the screen; scrolls inside, with the actions pinned at the bottom of the sheet. Enters with `motionEmphasis`, over `scrim`. Dismiss by swipe down, tap on scrim, or back gesture. Every sheet opens through `showBudgetSheet` and has its own visible close choice (D-031). **Scrim label (T-231):** the scrim's screen-reader label is `Close`, not Flutter's stock "Scrim" (`barrierLabel` in `showBudgetSheet`). It names the action; on decision sheets it still means the safe, non-saving choice.
- **Decision sheet** (Phase 2): the app's only confirmation pattern. There are **no Material `AlertDialog`s**; wherever a feature doc says "dialog", this sheet is meant. Title (`title`), body (`bodyLarge`, `textPrimary`), then full-width buttons stacked vertically, each with an optional `caption` line under it (`textSecondary`). **Button 1 (top) is the one we recommend:** the safe choice when the sheet interrupts the user (shortfall: Fix my numbers; discard: Keep editing), the confirmed action when the user asked for it with a deliberate tap (Delete). Button 1 is Primary, or Destructive when it removes data; button 2 is Secondary or Destructive. Scrim / swipe / back always mean the safe, non-saving choice. Specs: `screens/month-setup.md` §8–9, `screens/transactions.md` §9.

### 7.9 Snackbar
Floating, 16 dp from the sides and 12 dp above the bottom nav. `inverseSurface` fill, `radiusSm`, `body` text in `onInverseSurface`, one optional text action in `inverseAccent` (e.g. "Undo"). One line preferred, two max. Shows for 4 s (6 s with an action); not auto-dismissed while a screen reader is on. No icons, no colour coding.

### 7.10 Empty state
Left-aligned (not centred), starting `space8` below whatever is above it (title or hint card): a 40 dp line icon in `neutral` inside a `neutralSoft` circle of 88 dp · `title` · one or two lines of `bodyLarge` in `textSecondary` explaining what will appear here and when (wraps freely) · optional button: Secondary by default, **Primary** when it is the only way forward on the screen (Home `Set up your month`, Transactions `Set up your month`). Example (Transactions, Phase 1): "No transactions yet" / "Spends from your bank SMS will show up here. You'll also be able to add them yourself." (copy owned by F-003 §5; full spec `screens/app-shell.md` §4).

### 7.11 Help pattern (F-004)
The one pattern every later button, setting and number uses (STANDARDS §7, README §3.8).

**a) Label + description** — the default. Label (`label`, `textPrimary`) with a short description directly below (`body`, `textSecondary`, `space1` gap). Aim for one or two lines; it always wraps and is **never** truncated (F-004 §4, `screens/help-pattern.md` §2.1). Used on every settings row and form field.

**b) Label + (i) → help sheet** — used where the explanation is longer than two lines or space is short (numbers in the summary, calendar header, chart legends).
- 18 dp info icon in `textSecondary` placed 4 dp after the label, with a 48 dp touch target that never triggers the row. Semantic label: "More about <label>", button.
- **Tap** opens a **help sheet** (§7.8 bottom sheet): title = the label (`title`), body (`bodyLarge`, `textPrimary`, scrolls if long), and a full-width Secondary **Got it** pinned at the bottom.
- Closes on Got it, scrim tap, swipe down or back; focus returns to the (i). (Changed from the first draft's auto-closing bubble, to meet F-004 §2.2; see `screens/help-pattern.md` §3.)
- **Long-press tooltips** (standard navigation controls only: tabs, ×, Skip): Flutter `Tooltip` with `inverseSurface`, `radiusSm`, `body` in `onInverseSurface`, max width 280 dp, fades in with `motionFast`. The same text is the screen-reader hint.

**c) First-time hint** — one per main tab, shown on the first visit after onboarding until dismissed.
- An inline **hint card** at the top of the tab body, under the title (not an overlay, so it never blocks the screen): `accentSoft` fill, `radiusMd`, padding `space4`. Top row: 20 dp lightbulb-outline icon in `accent`, overline "Tip" (`label` 600, `accent`), and a × close button (20 dp, `textSecondary`, 48 dp target) at the right. Then the hint in `body` `textPrimary`, and a text button "Got it" in `accent` aligned right.
- Example (Home, Phase 1): "Use the tabs at the bottom to move around. Home is where you'll check today's budget each day." All hint copy: `screens/help-pattern.md` §4.2 and F-004 §5.
- "Got it" or × collapses the card (`motionEmphasis`, height + fade) and saves "hint seen" for that tab. It never comes back unless the user taps "Show tips again" in Settings (later phase, if approved).
- At most one hint visible per screen.

### 7.12 Error states (and how they differ from "overspent")
Red is reserved for overspent (STANDARDS §7). Errors share the red hue (`ColorScheme.error` = `overspent`) so the palette keeps one red, but an error is **never** shown the same way as an overspent amount:

| | Error | Overspent |
|---|---|---|
| Where | Only next to the thing that went wrong: an input, or a field group | On amounts: day cells, summary ledger, day details |
| Shape | 2 dp outline on the field + 16 dp `error` icon (circle with "!") | ◆ ledger mark; never an icon in a circle |
| Words | A sentence that says how to fix it, in `body`: "Enter an amount above ₹0" | The word "Overspent" + amount: "Overspent ₹300" |
| Type | `body` in `overspent`, never bold, never a money style | `money*` styles |
| Screen reader | "Error: Enter an amount above ₹0" (live region) | "overspent ₹300" in the item's label |

- **App-level problems** (could not save, could not read SMS) use the neutral **snackbar** (§7.9) with a plain sentence and a "Try again" action. Never red, never a dialog unless the user must decide something.
- **Silent recovery first:** when the app can fall back safely (e.g. preferences unreadable → default theme), it does so with no message. This is the only error handling in Phase 1, so Phase 1 shows no error UI.
- Error copy rules: say what happened and what to do, no blame, no codes ("Something went wrong (E42)" is not allowed).

### 7.13 Action dock (Phase 2 forms)
A bar pinned to the bottom of a full-screen form, holding the screen's Primary button and, optionally, one live summary line above it.
- `surface` fill, 1 dp `border` top rule, no shadow, padding `space4` × `space5` + the system / keyboard inset.
- **Only in portrait at text ≤ 1.3×.** Above 1.3× or in landscape the dock's contents move inline to the end of the form, because a pinned bar would take too much of the screen.
- With the keyboard open the dock **sits directly on the keyboard and stays visible** (it follows the keyboard inset; being covered by the keyboard is a defect, T-248). Per screen: month setup keeps only the summary line (`Daily budget ₹830 a day`) and hides Confirm until the keyboard closes; Add/Edit spend keeps only Save.
- **Mechanism (T-251):** the dock is the Scaffold's bottom bar lifted by the keyboard inset, so a snackbar stays above the dock and never covers the Primary button.
- **Keyboard action key (T-248):** forms with a dock use **Next** on every field and **Done** on the last field; Done closes the keyboard and the Confirm button returns. Above 1.3× or in landscape there is no dock, so the Confirm button is the last item of the page and is reached by scrolling with the keyboard open.
- The summary line is decorative for screen readers (the full value is read in the form's own preview).
- Specs: `screens/month-setup.md` §6, `screens/transactions.md` §8.1.

### 7.14 Month switcher (Phase 3)
One row used by the calendar, the Dashboard and the month statement, so changing month works the same everywhere.
- Left: the range in `title` (`5 Nov – 4 Dec 2026`), wraps at 2.0×; optional suffix in `body` `textSecondary` (` · so far`). Right: two 48 dp icon buttons, ‹ (`chevron_left`) and › (`chevron_right`), in `textPrimary`; disabled = `textSecondary` at 50 % and not focusable as an action (TalkBack still reads the disabled hint).
- On a past month a **`This month`** Text button appears under the range (hint `Go back to the current month`), so the user never has to tap › many times. Not shown on the current month.
- Changing month: content cross-fades with a 16 dp slide in the direction of travel (`motionBase`); instant with Remove animations. Swipe left/right on the calendar grid does the same.
- Screen reader: the range is a heading; buttons `Previous month` / `Next month`, disabled hints `No earlier months` / `This is the current month`.

### 7.15 Chips and segmented control (Phase 3)
- **Filter chip** (Transactions): height 40 dp (48 dp target), `radiusSm` (10 dp), padding 12 dp, `label` text, trailing 18 dp `expand_more`. Idle: `surface` fill, 1 dp `borderStrong`, `textPrimary`. **Active:** `accentSoft` fill, no outline, leading 18 dp `check` icon in `accent`, text `textPrimary` weight 600. The tick and weight are the non-colour cues. A row of chips scrolls sideways; it never wraps or clips.
- **Category chip** (on a list row): height 24 dp visible / 48 dp target (the target extends over the row's second line), `radiusXs`, `neutralSoft` fill, `caption` weight 500 in `textSecondary` (5.56 / 6.37 / 5.69 : 1). Pressed: `sunken`. It is its own control, separate from the row.
- **Segmented control** (Dashboard): 2 segments, 44 dp tall (48 dp target), `sunken` track with 1 dp `border`, `radiusMd`. Selected segment: `surface` fill with 1 dp `borderStrong` edge, `label` weight 600 `textPrimary`, leading 16 dp `check`; unselected: no fill, `label` 500 `textSecondary`. Switch uses `motionBase`.

### 7.16 Share bar row (Phase 3, Dashboard)
A ranked row for "where the money went": line 1 = name (`label`, `textPrimary`) left; amount (`moneyMedium`) and share (`caption` 500, `textSecondary`, fixed 40 dp column, right-aligned: `70%`, `<1%`) right. Line 2 = a 6 dp bar, `radiusFull`, `textPrimary` fill on a `neutralSoft` track, length = exact share of the range total (integer paise), minimum 2 dp when the share is above 0. Ink, never green/red, never accent: it is a share, not a result. Bars are decorative; the amount and share text carry the meaning. No pies, no donuts, no axes.

---

## 8. Flutter mapping

### 8.1 Theme mode
| User choice | `MaterialApp.themeMode` | `theme` | `darkTheme` |
|---|---|---|---|
| Auto (default) | `ThemeMode.system` | Light | **Dark** |
| Light | `ThemeMode.light` | Light | Dark |
| Dark | `ThemeMode.dark` | Light | Dark |
| Dim | `ThemeMode.dark` | Light | **Dim** |

Dim is a dark-brightness theme (`Brightness.dark`), so status-bar icons are light on Dim, as on Dark.

### 8.2 `ColorScheme` (per theme, built with the `ColorScheme(...)` constructor, not `fromSeed`)
| `ColorScheme` field | Token |
|---|---|
| `brightness` | Light: `Brightness.light`; Dark, Dim: `Brightness.dark` |
| `primary` / `onPrimary` | `accent` / `onAccent` |
| `primaryContainer` / `onPrimaryContainer` | `accentSoft` / `textPrimary` |
| `secondary` / `onSecondary` | `accent` / `onAccent` (one accent only) |
| `secondaryContainer` / `onSecondaryContainer` | `accentSoft` / `textPrimary` |
| `tertiary` / `onTertiary` | `accent` / `onAccent` |
| `error` / `onError` | `overspent` / Light `#FFFFFF`, Dark & Dim `#1C1B22` |
| `errorContainer` / `onErrorContainer` | `overspentSoft` / `textPrimary` |
| `surface` / `onSurface` | `surface` / `textPrimary` |
| `onSurfaceVariant` | `textSecondary` |
| `surfaceContainerLowest` | `surface` |
| `surfaceContainerLow` / `surfaceContainer` | `bg` |
| `surfaceContainerHigh` / `surfaceContainerHighest` | `sunken` |
| `outline` / `outlineVariant` | `borderStrong` / `border` |
| `inverseSurface` / `onInverseSurface` / `inversePrimary` | `inverseSurface` / `onInverseSurface` / `inverseAccent` |
| `scrim` / `shadow` | `scrim` colour / `#1C1B22` (Light), `#000000` (Dark, Dim) |
| `surfaceTint` | `Colors.transparent` |

### 8.3 `ThemeData` settings
- `useMaterial3: true`, `scaffoldBackgroundColor: bg`, `fontFamily: 'Plex'`, `textTheme` built from §4.2 (`displaySmall` = `displayHeadline`, `headlineSmall` = `headline`, `titleLarge` = `title`, `bodyLarge`, `bodyMedium` = `body`, `labelLarge` = `button`, `labelMedium` = `label`, `bodySmall` = `caption`).
- `splashFactory: InkSparkle.splashFactory` is **not** used; use `InkRipple.splashFactory` (calmer).
- Component themes set from §7: `filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`, `cardTheme` (elevation 0, `radiusLg`, hairline side), `inputDecorationTheme` (filled `sunken`, outline borders), `listTileTheme`, `navigationBarTheme` is **not** used (custom bar with the ink tick, §7.7), `bottomSheetTheme` (`radiusXl`, `showDragHandle: true`), `snackBarTheme` (floating, `inverseSurface`), `tooltipTheme` (`inverseSurface`, `radiusSm`), `dividerTheme` (1 dp `border`), `appBarTheme` (bg colour, elevation 0, `scrolledUnderElevation: 0`, title in `headline`).
- `pageTransitionsTheme`: `FadeForwardsPageTransitionsBuilder` on Android (fade + small slide, matches §5.4).

### 8.4 `ThemeExtension`s
Everything `ColorScheme` cannot hold goes into extensions, read in widgets with `Theme.of(context).extension<BudgetColors>()!` (or a small `context.budgetColors` getter). Each implements `copyWith` and `lerp` (colour `Color.lerp`, numbers `lerpDouble`) so theme switches animate.

```
BudgetColors   (ThemeExtension<BudgetColors>)
  bg, surface, sunken, textPrimary, textSecondary,
  accent, onAccent, accentSoft,
  saved, savedSoft, overspent, overspentSoft, neutral, neutralSoft,
  border, borderStrong, focus,
  inverseSurface, onInverseSurface, inverseAccent, scrim
  → three const instances: BudgetColors.light / .dark / .dim (hex values from §2)

BudgetText     (ThemeExtension<BudgetText>)
  moneyHero, moneyLarge, moneyMedium, moneySmall   (Plex, tabular, from §4.2)
  displayHeadline, headline, title                  (Bricolage, from §4.2)

BudgetSpacing  (const class, not theme-dependent)
  space1 4 · space2 8 · space3 12 · space4 16 · space5 20 · space6 24 · space7 32 · space8 40 · space9 56
  touchTarget 48

BudgetRadii    (const class)
  xs 6 · sm 10 · md 14 · lg 20 · xl 28 · full 999

BudgetMotion   (const class)
  fast 120 ms · base 200 ms · emphasis 320 ms · emphasisExit 240 ms · count 600 ms
  standard Cubic(0.2, 0, 0, 1) · decelerate Cubic(0.05, 0.7, 0.1, 1) · accelerate Cubic(0.3, 0, 0.8, 0.15)

BudgetElevation (ThemeExtension<BudgetElevation>)
  float: List<BoxShadow>, sheet: List<BoxShadow>   (Light: §5.3 values; Dark & Dim: empty lists)
```

Day-state helper for the calendar and day details (pure UI mapping, kept out of `domain/`):
`DayStatus { saved, onBudget, overspent, future, notBudgeted }` → `(fill, amountColor, mark)` from `BudgetColors`; "today" is a separate flag that adds the ring, and "periodStart" is a separate flag that adds the change-day tick (§7.5). Outside-month cells are not a status (they are not days of the budget month).

### 8.5 Widget test hint for the Tester and Developer
Each theme's widget tests can assert the contrast table: a test helper computing the WCAG ratio for each pair in §3 from the `BudgetColors` instances (≥ 4.5 for text pairs, ≥ 3.0 for `borderStrong` and `focus`) protects these numbers from accidental edits.

---

## 9. Open items for the Project Manager
Resolved on 2026-11-05 with the Phase 1 screen specs (`docs/design/screens/`):
1. ~~Help-text copy alignment~~ **Done.** Final copy is in the four screen specs; where it differs from the feature docs (F-004 hint texts, F-005 slide 4, new Settings group headers and Theme row hint, new hint "Tip" overline) the feature docs' §5 were updated with change-history lines.
2. Custom icon set: still Phase 1 Material Symbols Rounded stand-ins (§6); custom icons are a Phase 6 polish item. No change.
3. Font glyph check (§4.1): stays a one-time Developer step in F-002. A bundled fallback (Noto Sans) is now named in case U+20B9 is missing.
4. **New, resolved:** bottom-navigation label scaling at 2.0× (§7.7, `screens/app-shell.md` §3.2).
5. **New, resolved:** error states vs overspent red (§7.12).
6. **New, for the PM:** F-003 §2.4 says Phase 1 empty states are "centred"; the design system places them left-aligned (§7.10). AC-4 is unaffected. Suggest the PM changes the wording to "per design system".
7. **New, design change:** the (i) now opens a help sheet instead of an auto-closing bubble, to satisfy F-004 §2.2 (§7.11b).
8. **Gate 2 (PM, 2026-11-05):** item 6 resolved (F-003 §2.4 now says "per design system (left-aligned)"). Approved; see `docs/reviews/design-phase-1.md`.

## 10. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-05 | First version | Designer |
| 2026-11-05 | Phase 1 screen specs: nav label scaling rule (§7.7, §4.2), (i) help sheet replaces bubble (§7.11b), hint card gets "Tip" overline and × (§7.11c), new §7.12 error states, ₹ fallback font named (§4.1), §9 resolved | Designer |
| 2026-11-05 | Gate 2 reconciliation (PM): §3 adds three pairs used on Phase 1 screens (`textSecondary` on `neutralSoft` and on `accentSoft`, `borderStrong` on `bg`; all ratios recomputed and confirmed); §4.1 font sources and automated ₹/`tnum` check; §6 icon stand-in corrected to built-in Material Icons; §7.10 empty state aligned with `screens/app-shell.md` §4 (40 dp icon, `space8`, F-003 copy); §7.11a description wraps, never truncated; status → Approved | Project Manager |
| 2026-11-05 | Gate 3 (PM): §4.1 ₹/figures check accepts tabular default digits (Plex has no `tnum` feature; its digits are all 600 units wide). No visual change | Project Manager |
| 2026-11-10 | Phase 2 screen specs (`screens/month-setup.md`, `screens/transactions.md`): §4.3 minus sign U+2212 confirmed, no-split and screen-reader rules, D-038 whole rupees (paise only in inputs); §7.8 decision sheet replaces dialogs, button order rule; §7.10 Primary button allowed in an empty state that is the only way forward; new §7.13 action dock. Existing Phase 1 components unchanged | Designer |
| 2026-11-10 | Gate 2 (PM, Phase 2): §4.3 formatter rule corrected (integer `decimalPattern`, never `NumberFormat.currency`), no `−₹0`, `less than ₹1` wording, no invisible characters in semantics labels (D-050). §7.8, §7.10, §7.13 approved as written | Project Manager |
| 2026-11-13 | T-238 (D-069, D-070): §7.3 amount fields show digits as typed (no grouping while typing; the grouped amount shows in the screen's live preview line); §4.3 the formatter groups by hand, no `intl` / `NumberFormat`. No token change | Designer |
| 2026-11-11 | T-231 (Gate 3 N1): §7.8 sheet scrim screen-reader label is `Close` instead of "Scrim". No visual change; code in T-233 | Designer |
| 2026-11-06 | T-128 (Gate 2 N1): Owner-preview Home mockup's hint card now shows the `Tip` overline, lightbulb and × like the real card (§7.11c). Mockup only; no spec change | Designer |
| 2026-11-11 | Phase 3 screen specs (planned ahead, D-033; `screens/home-summary.md`, `calendar.md`, `day-details.md`, `dashboard.md`, `month-statement.md`, `transactions-search.md`). §7.5: **Not budgeted** cell state, **change-day marker** (ink tick), amount fit rule and **short forms** `₹12k` / `₹1.5L` / `₹10Cr` (`formatRupeesShort`), negative net amounts, landscape cap 56 dp (phase-3 overview open item 7). §3: `accent` on the three day fills and the share-bar pair (computed, all ≥ 5.30). §4.3: short-form pointer, `→` glyph check. §7.6: Phase 3 summary additions, ₹0 saved/overspent shown neutral with no mark. New §7.14 month switcher, §7.15 chips and segmented control, §7.16 share bar row. §8.4 `DayStatus.notBudgeted` + `periodStart` flag. Existing Phase 1–2 components unchanged. **Phase 3 parts pending Gate 2** | Designer |
| 2026-11-13 | T-248 (D-071): §7.13 with the keyboard open the dock stays visible directly above it; Next / Done keyboard actions; the no-dock block at the end above 1.3x is intended | Designer |
| 2026-11-16 | T-251: §7.13 one line: the dock is the Scaffold bottom bar lifted by the keyboard inset, so snackbars stay above it. No visual change | Designer |

---

## Owner preview

### Palettes

**Light — "Paper"**
```
■ Page        #F6F3ED   ■ Card        #FFFDF8   ■ Sunken     #EEEAE2
■ Text        #1C1B22   ■ Text soft   #5C5864
■ Accent      #3A3DB0   (indigo ink)  ■ Accent soft #E7E6F6
■ Saved       #1A7044   ■ Saved fill  #DDEFE3
■ Overspent   #B4372F   ■ Over fill   #F6E0DC
■ Neutral     #68646E   ■ Neutral fill #EAE6DF
■ Border      #DED8CD   ■ Outline     #8A8377   ■ Focus      #3A3DB0
```

**Dark — "Ink"**
```
■ Page        #0E0E12   ■ Card        #17171D   ■ Sunken     #0A0A0D
■ Text        #F2F0EA   ■ Text soft   #A8A5B1
■ Accent      #9C9FFF   ■ Accent soft #25264A
■ Saved       #52C98B   ■ Saved fill  #16301F
■ Overspent   #FF7B6F   ■ Over fill   #3A1A17
■ Neutral     #9F9CA7   ■ Neutral fill #24242B
■ Border      #2A2A33   ■ Outline     #6A6876   ■ Focus      #BDBFFF
```

**Dim — "Slate"**
```
■ Page        #2A2825   ■ Card        #34312D   ■ Sunken     #24221F
■ Text        #EEE9E0   ■ Text soft   #BEB7AB
■ Accent      #ABACF6   ■ Accent soft #3E3D55
■ Saved       #80D3A1   ■ Saved fill  #2F3F33
■ Overspent   #FF9C8E   ■ Over fill   #4A3230
■ Neutral     #B6AFA4   ■ Neutral fill #3D3A35
■ Border      #48453F   ■ Outline     #878073   ■ Focus      #C6C7FF
```
**Auto** = Light by day, Dark by night (follows the phone). All text pairs meet WCAG AA (lowest: 4.64 : 1).

### Fonts
```
Bricolage Grotesque  Bold 700 / SemiBold 600   → headings: "November", "Home"
IBM Plex Sans        Regular 400 / Medium 500 / SemiBold 600
                     → body, buttons and ALL money, tabular figures
Money:  ₹1,33,333   ₹40,000   ₹15,100   ₹830   +₹333   ₹830.50
```

### Home screen shell with the summary card
```
┌──────────────────────────────────────┐
│ November                             │
│ 1 – 30 Nov · day 13 of 30            │
│                                      │
│ ╭──────────────────────────────────╮ │
│ │ Left this month              (i) │ │
│ │ ₹16,700                          │ │
│ │ ━━━━━━━━━━━░░░░░░░░░░░░░░░░░░░░░ │ │
│ │ ₹830/day · 1 – 30 Nov        (i) │ │
│ │──────────────────────────────────│ │
│ │ Salary                   ₹40,000 │ │
│ │ Fixed costs        (i)   ₹15,100 │ │
│ │ Spent so far              ₹8,200 │ │
│ │ Saved            (i)   ● ₹2,480  │ │
│ │ Overspent        (i)   ◆ ₹300    │ │
│ ╰──────────────────────────────────╯ │
│                                      │
│ ╭──────────────────────────────────╮ │
│ │ ☼ Tip                         ×  │ │
│ │ Tap any day on the calendar to   │ │
│ │ see what you spent.              │ │
│ │                          Got it  │ │
│ ╰──────────────────────────────────╯ │
│──────────────────────────────────────│
│  ▬                                   │
│  ⌂      ▥          ≣           ⫶     │
│ Home Dashboard Transactions Settings │
└──────────────────────────────────────┘
```
(Budget month 1–30 Nov, 30 days. Spendable ₹40,000 − ₹15,100 = ₹24,900 → ₹830/day. ₹24,900 − ₹8,200 spent = ₹16,700 left. Today is day 13: ₹420 spent so far, so the 12 finished days cost ₹7,780 against ₹9,960 of budget: saved ₹2,480, overspent ₹300. ☼ is the lightbulb icon and × the close button of the hint card. The ▬ above Home is the indigo ink tick of the selected tab. Saved is green, Overspent red, everything else ink. ⌂ ▥ ≣ ⫶ stand in for the line icons.)

### One calendar row, all day states
```
  M       T       W       T       F       S       S
╭─────╮ ╭─────╮ ╭─────╮ ╭─────╮ ┏━━━━━┓ ┌┄┄┄┄┄┐ ┌┄┄┄┄┄┐
│ 9  ●│ │10  ○│ │11  ◆│ │12  ●│ ┃13  ●┃ ┆14   ┆ ┆15   ┆
│ ₹620│ │ ₹830│ │₹1130│ │ ₹410│ ┃ ₹420┃ ┆     ┆ ┆     ┆
╰─────╯ ╰─────╯ ╰─────╯ ╰─────╯ ┗━━━━━┛ └┄┄┄┄┄┘ └┄┄┄┄┄┘
 saved  on bud. overspt  saved   TODAY   future  future
 green   grey    red     green  indigo  (hairline, no amount)
                                 ring; ₹410 left today
```
● saved (green fill) · ○ on budget (grey fill) · ◆ overspent (red fill) · thick ring = today (indigo) · dotted = future days.

### Phase 3 additions to the day cell
```
  not        outside   change day  short forms (big days only)
  budgeted   month     (₹552/day)
                       ╭──▬──╮    ╭─────╮ ╭─────╮ ╭─────╮
   5         2         │13  ●│    │ 3  ◆│ │ 4  ◆│ │ 5  ◆│
                       │ ₹500│    │ ₹12k│ │₹1.5L│ │₹10Cr│
                       ╰─────╯    ╰─────╯ ╰─────╯ ╰─────╯
 full-ink   faded     indigo ink  ₹12,999  ₹1,59,999  ₹10 crore
 number,    number,   tick on top
 no box     no box
```
Not budgeted (before you started) keeps a readable number but no box; outside days are faded. The ▬ is the same indigo tick as the selected tab, so it means "your budget changed here", never a result. Cells shorten only from ₹10,000; the full amount is one tap away.

### Why these choices
- **Indigo ink on warm paper** feels like a trusted Indian ledger, not another neon fintech app. Indigo is far from both green and red, so it never gets confused with "saved" or "overspent".
- **Bricolage Grotesque headings + IBM Plex Sans numbers** give character without hurting readability. All money is tabular, so columns of rupees line up like a real khata.
- **Flat surfaces, hairline rules and the ●○◆ marks** keep it calm and premium, and make day results readable without relying on colour alone.
