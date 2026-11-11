# F-002: Design system & themes

| | |
|---|---|
| **Phase** | 1 |
| **Status** | Done |
| **Plan** | [`plans/F-002-design-system-themes.md`](../../plans/F-002-design-system-themes.md) |
| **Test cases** | [`tests/F-002-design-system-themes.md`](../../tests/F-002-design-system-themes.md) |
| **Tasks** | T-101 … T-110 (`docs/TASKS.md`) |

## 1. What it is *(Product Manager)*
The app's visual language, built into code once so every screen in every later phase looks and behaves the same. It turns the Designer's design system (`docs/design/design-system.md`) into design tokens (colours, fonts, text sizes, spacing, corner radius) and a small set of base components (buttons, cards, list rows, inputs). It provides the four theme options from the README, **Light, Dark, Dim and Auto**, plus a **Theme** choice in Settings. The choice is remembered after the app is closed. The default is **Auto**, which follows the phone's light/dark setting. Fonts are bundled inside the app and never downloaded, because the app makes no network calls (D-003, STANDARDS §8). Every theme meets WCAG AA contrast, every touch target is at least 48 dp, and layouts still work at the largest system font size (STANDARDS §7).

**User stories:**
- As a **user**, I want to pick Light, Dark, Dim or Auto so that the app is comfortable to read in the morning, at night and in between.
- As a **user**, I want my theme choice remembered so that I don't have to set it again every time I open the app.
- As a **user with large system text or weaker eyesight**, I want every screen to stay readable and usable so that I can manage my money without strain.
- As the **team**, we want one set of tokens and base components so that later screens never hard-code colours, sizes or fonts.

## 2. How it behaves *(Product Manager)*
Exact colours, fonts, sizes and component shapes are **per design system** (`docs/design/design-system.md`, written by the Designer in parallel). This doc says what must be true. It does not say what the values are.

1. **Tokens.** Every colour, font, text size, spacing step and corner radius used on screen comes from the design-system tokens. Screens and components never use their own raw values.
   - **Colour meaning (README §5):** one accent colour for primary actions and selection. **Green means saved** and **red means overspent**. Everything else is neutral. Green and red are reserved for these meanings. The accent colour is neither green nor red, so a primary button is never mistaken for a "saved" or "overspent" signal.
   - Each theme defines its own value for every colour token: background, surface, text (primary, secondary), accent, on-accent, saved, overspent, divider/outline, disabled.
   - A "large number" text style is defined for money amounts (used from Phase 2/3). It is a token only in Phase 1.
2. **Base components** (per design system), each built once and used everywhere:
   - Buttons: primary (accent), secondary, and text/low-emphasis. Each has enabled, pressed, focused and disabled states.
   - Card.
   - List row: label, optional description, optional trailing item (value, chevron, switch, "Coming soon" tag). F-004 uses it as the base for its label + description + (i) pattern.
   - Text input: label, helper text, error text, and enabled/focused/disabled/error states. No input is used on a Phase 1 screen. It exists for Phase 2.
3. **Themes.**
   - **Light:** bright, clean.
   - **Dark:** true dark, for night use.
   - **Dim:** a soft middle theme (warm grey), easy on the eyes.
   - **Auto (default):** uses **Light** when the phone is in light mode and **Dark** when the phone is in dark mode. Auto never picks Dim.
4. **Choosing a theme.** Settings → **Theme** row (the row sits in the F-003 Settings tab). The row shows the current choice, for example "Auto (follows your phone)". Tapping it opens a picker (dialog or bottom sheet, per design system) with four options in this order: Auto, Light, Dark, Dim. Each option has a one-line description (section 5). The current option is marked with a check/radio **and** a non-colour cue. Selecting an option applies it to the whole app **immediately**, with no restart, and saves it.
5. **Remembered.** The choice is saved in the app's simple preferences store. F-004 and F-005 use the same store (phase overview). This is not the money database. After the app is closed, swiped away, force-stopped or the phone restarts, the app opens in the saved theme. The **first frame** is already in the saved theme, with no flash of a different theme. (The Android system splash shown before Flutter starts is out of scope; see section 6.)
6. **Auto follows live changes.** With Auto selected, switching the phone between light and dark mode (quick-settings tile or system settings) changes the app theme while it is open, or as soon as it returns to the foreground. No restart is needed.
7. **System bars.** Status bar and navigation bar icons stay legible in every theme: dark icons on light backgrounds, light icons on dark/dim backgrounds.
8. **Fonts.** The custom font family/families (per design system, free open licence such as SIL OFL) are files inside the app's assets. They are never fetched from the internet, and the app looks the same in airplane mode on first launch. Each font's licence is bundled and registered so it appears in the app's licence list.
9. **Accessibility.**
   - Text contrast meets WCAG 2.1 AA in every theme: **≥ 4.5:1** for normal text and **≥ 3:1** for large text (≥ 18 pt, or ≥ 14 pt bold). Meaningful non-text parts (button outlines, input borders, focus rings, selected-state indicators, the (i) icon, saved/overspent colour used as a signal) have **≥ 3:1** against their background. The Designer lists every theme × colour pair with its ratio in the design system.
   - Disabled controls are exempt from AA by WCAG. In this app a disabled control's **label** must still be readable at ≥ 4.5:1, because Phase 1 shows "Coming soon" rows.
   - Every tappable element has a touch target of at least **48 × 48 dp**, even when the visible icon is smaller.
   - Layouts survive the system font scale at **2.0** (Android's largest "Font size" setting is 200% on current versions). Nothing overflows and nothing is clipped; long content scrolls.

**Example:** the Owner opens Settings → Theme and picks **Dim**. The whole app turns warm grey at once. They swipe the app away and reopen it: it opens straight in Dim. They pick **Auto** and turn on the phone's dark mode from quick settings: the app switches to Dark while it is open.

## 3. Acceptance criteria *(Product Manager)*
"Every Phase 1 screen" means: the four tabs (F-003), the theme picker (this feature), the (i) explanation and first-time hints (F-004), and the tour slides, SMS explainer, notifications explainer and disclaimer (F-005). "Small phone" means a 360 × 640 dp screen. "All four themes" means Light, Dark, Dim, plus Auto under system light **and** under system dark.

| ID | Given / When / Then |
|---|---|
| AC-1 | **Four options exist.** Given Settings is open, when the user taps the **Theme** row, then a picker shows exactly four options in the order Auto, Light, Dark, Dim, each with the label and description from section 5, and the current choice is marked by a check/radio indicator (not by colour alone). |
| AC-2 | **Each theme renders.** Given each of Light, Dark and Dim is selected in turn, when the Tester views every Phase 1 screen, then the screen uses that theme's tokens (background and text colours match the design system values for that theme), and no exceptions are thrown. Light, Dark and Dim each produce a visibly different background colour. |
| AC-3 | **Auto follows the system.** Given Auto is selected, when the phone is in light mode, then the app shows the Light theme; when the phone is in dark mode, then the app shows the Dark theme. Auto never shows Dim. |
| AC-4 | **Auto reacts live.** Given Auto is selected and the app is open, when the Tester switches the phone's dark mode on or off, then the app changes to Dark/Light within 1 second (or on return to the foreground if the switch was made from system Settings), with no restart and with the current tab and scroll position kept. |
| AC-5 | **Change applies instantly.** Given any theme is active, when the user selects a different option in the picker, then the whole app (including the bottom navigation and the Settings row's current-value text) shows the new theme without a restart, and the Theme row description updates to the new choice. |
| AC-6 | **Default is Auto.** Given a fresh install (or cleared app data), when the app opens for the first time, then the theme choice is Auto. |
| AC-7 | **Choice persists across restart.** Given the user selected Dim (then repeated for Light, Dark and Auto), when the app is force-stopped (or swiped away) and reopened, then the app opens in the saved choice, the picker shows it selected, and the first rendered frame is already in that theme (no visible flash of another theme). |
| AC-8 | **Fallback on bad or missing saved value.** Given the stored theme value is missing, unreadable or unknown (e.g. `"blue"`), when the app starts, then it uses Auto, shows no error to the user, does not crash, and the next valid selection is saved normally. |
| AC-9 | **Tokens only.** Given the app source, when the Tester (or a code check agreed in the plan) inspects `app/lib/features/`, then no screen uses a raw colour value (e.g. `Color(0x…)`, `Colors.*`) or a raw font family; all come from the theme/tokens in `core/`. |
| AC-10 | **Colour meaning.** Given the design system and the theme code, when the Tester compares them, then every theme defines a *saved* (green family) and an *overspent* (red family) colour plus one accent colour; the accent is not in the green or red family; and the values in code match the design system for all three themes. |
| AC-11 | **Base components.** Given each base component (primary, secondary and text button; card; list row with and without description; text input), when it is rendered in all four themes in its enabled, pressed/focused, disabled and (input only) error states, then it renders without exceptions and matches the design system's shape, spacing and colours. |
| AC-12 | **WCAG AA contrast.** Given every text-colour/background pair and every meaningful non-text pair listed in the design system, when contrast is computed for each theme (Light, Dark, Dim), then normal text is ≥ 4.5:1, large text is ≥ 3:1, non-text UI and the saved/overspent colours used as signals are ≥ 3:1, and disabled-row labels are ≥ 4.5:1. Any pair below its threshold fails. On screens, an automated text-contrast check (e.g. Flutter's `textContrastGuideline`) passes on every Phase 1 screen in all four themes. |
| AC-13 | **48 dp touch targets.** Given every Phase 1 screen in all four themes, when the Tester runs a tap-target check (e.g. Flutter's `androidTapTargetGuideline`), then every tappable element is at least 48 × 48 dp and the check passes. |
| AC-14 | **Largest font size.** Given text scale 2.0 on a small phone (360 × 640 dp), when every Phase 1 screen is shown in all four themes, then there are no overflow errors (no yellow-black stripes, no `RenderFlex overflowed` in the log), no text is clipped or cut off mid-word, and any content taller than the screen can be scrolled to fully. (Bottom-navigation labels follow the scaling rule the design system documents; see section 4.) |
| AC-15 | **Bundled fonts, no network.** Given the app, when the Tester inspects it, then: the custom font files are listed as assets in `app/pubspec.yaml` and present in the repo; no dependency downloads fonts at runtime (e.g. `google_fonts` is absent, or present with runtime fetching turned off, which the plan must state); the main `AndroidManifest.xml` still has no `<uses-permission>` entries (F-001 AC-8 holds, so no `INTERNET`); and when the app is first launched on an emulator in airplane mode, text renders in the custom font, the same as when online. |
| AC-16 | **Custom font in use.** Given the running app, when the Tester checks the theme's text styles, then they use the bundled font family named in the design system (not the platform default Roboto), on every Phase 1 screen. |
| AC-17 | **Font licence bundled.** Given the app, when the Tester checks the app's licence registry (e.g. a test reading `LicenseRegistry`), then each bundled font's licence text is present under the font's name. |
| AC-18 | **System bars legible.** Given each of Light, Dark and Dim, when the Tester views any tab on the emulator, then the status bar and navigation bar icons have visibly contrasting colour against the area behind them (dark icons on light, light icons on dark/dim). |

## 4. Edge cases *(Product Manager)*
- **Phone without a system dark mode** (Android 9 and older report "light" always): Auto shows Light. Not a bug.
- **Battery saver forcing dark mode:** the phone reports dark, so Auto shows Dark.
- **System theme changes while the app is in the background:** on resume the app shows the right theme (AC-4).
- **Theme change while the picker is open (Auto + system switch):** the picker itself re-renders in the new theme and keeps the current selection.
- **Rapid repeated selection** (tapping Light, Dark, Dim quickly): the last tap wins, both on screen and in storage after restart.
- **Preferences store fails** (write error, corrupt file, storage full): the theme still changes for this session. On next launch, Auto is used if the value can't be read (AC-8). No crash, no error dialog.
- **Plugin build environment:** Windows Developer Mode is **not** needed for this Android-only app (D-029, Gate 1). If the plugin build fails for an environment reason (SDK/NDK missing), the device parts of AC-7 are recorded **Blocked**, not failed.
- **Dim contrast risk** (phase overview): green/red on warm grey is the hardest pair. AC-12 must be met for Dim exactly like the others. The Designer may adjust the Dim shades of green/red.
- **Error colour vs overspent red:** STANDARDS §7 reserves red for "overspent". Error states (input error text in Phase 2) need a treatment the design system defines, for example an icon plus text. It must not be confused with an overspent amount. The Designer decides and documents it.
- **Very large font + narrow bottom navigation:** "Transactions" at 2.0× will not fit a 90 dp tab slot. The design system must document how navigation labels scale (for example, a cap on label scaling as in Material, or a smaller label style). Clipping and overflow are never allowed (AC-14).
- **Display size (zoom) set to largest as well as font size:** the logical width can drop below 360 dp. Layouts must not overflow at 320 dp width with text scale 1.0. Combined maximum zoom plus 2.0 text only needs to stay scrollable and crash-free.
- **Bold text / high-contrast text system settings:** must not break layout. Higher contrast is welcome.
- **Landscape:** portrait is **not** locked (D-030, Gate 1), so every Phase 1 screen must not overflow in landscape on a small phone.
- **Fonts with Indian rupee sign and Indian digits:** the chosen font must include `₹` and render `₹1,33,333`. If it lacks `₹`, the design system names a fallback font that is also bundled.
- **Hindi/regional text:** not in scope (English only for v1). Characters missing from the custom font fall back to the system font without crashing.

## 5. Help text & copy *(Product Manager, finalised by Designer)*
| Control | Label | Description / tooltip |
|---|---|---|
| Settings → Theme row | `Theme` | Description (shows current choice): `Auto (follows your phone)` / `Light` / `Dark` / `Dim`. (i): `Choose how the app looks. Auto switches between Light and Dark with your phone's setting. Dim is a softer, warm grey theme that's easy on the eyes at any time of day.` |
| Settings → Theme row, screen reader | — | Reads `Theme. <current choice>. Button.` Hint: `Opens theme options` |
| Theme (i) explanation title | `Theme` | Body as in the Theme row (i) above. Button `Got it` (F-004). |
| Theme picker title | `Choose a theme` | — (a bottom sheet; options apply at once and the sheet stays open) |
| Option: Auto | `Auto` | `Matches your phone's light or dark setting` |
| Option: Light | `Light` | `Bright and clean` |
| Option: Dark | `Dark` | `True dark, best at night` |
| Option: Dim | `Dim` | `Soft warm grey, easy on the eyes` |
| Picker close button (bottom of the sheet) | `Done` | Tooltip/hint: `Close theme options` |
| Screen-reader announcement on change | — | `Theme changed to Dim` (uses the chosen name) |

## 6. Out of scope
- The design system document itself, its exact colours, fonts and component shapes (Designer, `docs/design/design-system.md`).
- Custom icons and illustrations beyond what Phase 1 screens need (designer's call, per design system); app icon (Phase 7).
- Animations beyond basic theme/screen transitions (Phase 6).
- Android native splash screen theming, which shows before Flutter starts (Phase 6/7 polish).
- Per-screen theme overrides, custom accent colour choice, AMOLED-black variant, scheduled theme (by time of day).
- Material You dynamic colour from the wallpaper (it would replace the one-accent identity).
- Languages other than English.
- A visible "Open-source licences" screen (see Suggested additions). AC-17 only requires the licences to be registered.

## 7. How it works — technical *(Developer, filled in when the feature is Done)*
- **What was built:** the design foundation every screen uses. Tokens (colours for Light "Paper", Dark and Dim "Slate", type scale, spacing, radii, elevation, motion), the Material 3 `ThemeData` for each theme, the base components, bundled fonts, and a theme choice (Auto / Light / Dark / Dim) that is saved and applied without a restart or a wrong-theme frame. Built in T-101 … T-110, T-127 and the screen sweeps of T-138. Gate 4 passed 2026-11-11 (47 of 47 cases).
- **Main files** (`app/lib/`):
  - `core/theme/`: `budget_colors.dart` (`BudgetColors`, 4 palettes), `budget_tokens.dart` (spacing, radii, `BudgetMotion`), `budget_text.dart` (`BudgetTypeScale`, money and heading styles), `budget_elevation.dart`, `budget_theme.dart` (`themeConfigFor`, the four `ThemeData`), `theme_context.dart`, `system_bars.dart`, `font_licenses.dart`, `theme_choice_provider.dart` (Riverpod notifier, chained saves).
  - `core/widgets/`: `BudgetButton`, `BudgetCard`, `BudgetListRow`, `BudgetTextField`, `EmptyState`, `RootPage`, `FocusRing`.
  - `domain/preferences/theme_choice.dart` (pure Dart); `data/preferences/` (`PreferencesStore` interface, `SharedPreferencesStore` the only file importing the plugin, `InMemoryPreferencesStore`, `ThemePreferenceRepository`, `PreferenceKeys` with the allow list); `core/providers/preferences_providers.dart`.
  - `features/settings/theme/` (`theme_setting_row.dart`, `theme_picker_sheet.dart`, `theme_names.dart`); `app.dart` (theme, Remove animations, `AppGate`); fonts in `app/assets/fonts/` with `SOURCES.md` (SHA-256 of every file).
- **Data stored:** one preference, `theme.choice` (`auto`, `light`, `dark`, `dim`) in `shared_preferences`; a missing, wrong-type or unreadable value means Auto, and a failed read or write never crashes.
- **Decisions applied:** D-024 (Dart 3.13 constructors), D-026 (preferences store behind an interface, allow list), D-027 (manual Riverpod, `riverpod_lint` as an analysis plugin), D-028 (bundled Bricolage Grotesque and IBM Plex Sans, no `google_fonts`, licences registered), D-029 (NDK back on the Flutter default, no Developer Mode needed), D-030 (orientation not locked), D-063 (`integration_test` dev dependency), D-064 (release permission wording, TC-002-27).
- **Deviations from the plan** (plan section 11, all approved): `flutter analyze` does not run analyzer plugins, so `dart analyze --fatal-infos` was added to `check.ps1` (T-101); `main.dart` wraps the app in `ProviderScope` from T-101; IBM Plex Sans has no `tnum` feature because its digits are tabular by default, so TC-002-42 asserts "tnum or equal digit advances" (T-103, approved); `.gitattributes` keeps the Plex licence file's line endings; `ThemeChoice` was created in T-105 instead of T-108; the 12 text styles are `BudgetTypeScale` constants; bottom sheet and snackbar use Material elevation 0 and the components draw the shadows; saved choices are chained so the last choice wins (TC-002-33); TC-002-47 hashes the fonts with a small test-only SHA-256, not a new package; the sweeps run in one `testWidgets` per case that loops all 18 screen states and 5 theme cases (T-138, rework after Gate 3 rejection 1: `P1Screen.open` resets view, scale and accessibility state before every open).
- **How it is tested:** 47 cases TC-002-01 … -47 in `tests/F-002-design-system-themes.md`. Automated in `app/test/core/theme/`, `app/test/core/widgets/`, `app/test/data/preferences/`, `app/test/features/settings/`, the 8 screen sweeps in `app/test/features/screens/p1_screen_sweeps_test.dart` (TC-002-03, -22, -23, -24, -29, -38, -39, -40; each proved able to fail by a temporary probe) and `app/integration_test/preferences_persistence_test.dart` (TC-002-11, real plugin). Emulator checks (T-110, `docs/reviews/emulator-phase-1/`): system dark mode change, restart, force-stop and reboot, airplane mode, release APK permissions. `tool/check.ps1` ALL CHECKS PASSED, 336 tests.
- **Depends on / used by:** depends on F-001. Used by every screen: F-003 (shell, Settings), F-004 (help sheet, hints), F-005 (tour and explainers), and all later features.
- **Known limitations:**
  - The release APK has one `uses-permission` line, AndroidX's own `…DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (signature level, from `androidx.core`). The case wording was changed to allow it (D-064).
  - The TC-002-03 sweep reads the expected background from the same token, so a token value change is caught by `theme_tokens_test.dart`, not by the sweep. TC-002-29 checks the font family on each text span, not the glyph source (`fonts_test.dart` covers loading).
  - TC-002-12 was checked with a screenshot burst, not frame by frame (no ffmpeg), so one wrong frame between shots could be missed.
  - Input fields do not group digits the Indian way while typing yet (waits for the Phase 2 money formatter).
  - Designer Nice to have items (`docs/reviews/design-phase-1-evidence.md`): N2 the theme picker at 2.0x text scale hides the selected option, with no scroll cue (T-234); N4 the "Transactions" nav label sits a few px above the others at 2.0x (T-236). The Dark theme is covered by the sweeps, not by a screenshot.
  - Not built (out of scope): custom icons, a licences screen, Material You colour, per-screen themes.

## 8. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-05 | First version of the spec | Product Manager |
| 2026-11-05 | §5 finalised by Designer (`docs/design/screens/settings.md`): added Theme row screen-reader hint and (i) title; picker is a bottom sheet with a Done button. No existing text changed. | Designer |
| 2026-11-05 | Gate 1 reconciliation: §4 Developer Mode edge case replaced (D-029), landscape edge case and portrait suggestion settled (D-030); status → Plan approved, task IDs added. No AC changed. | Project Manager |
| 2026-11-11 | Step 9: section 7 (technical) filled in; status → Done after Gate 4 passed | Developer |

## Suggested additions *(for the CEO — not in scope until approved)*
- **Debug-only component gallery screen** listing every token and base component in the current theme. The Owner could see the real design system on the emulator, and the Tester could check AC-11 visually. Not reachable in release builds.
- **Settings → "Open-source licences" row** (Flutter's built-in licence page), so OFL font credit is visible to users. Many Play Store apps do this, and it costs one row.
- ~~**Lock portrait orientation** for v1.~~ *Declined at Gate 1 (D-030): WCAG 2.1 SC 1.3.4 (AA) asks apps not to restrict orientation, and Android 16+ ignores orientation locks on large screens for apps targeting API 36.*
- **Theme preview thumbnails** in the picker (small swatches for each theme), as Google apps do. They make Dim easier to understand before choosing it.
