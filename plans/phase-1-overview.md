# Phase 1 — Design system & app shell: Overview

**Status:** Built, tested and signed off by the Project Manager (Gate 5, 2026-11-11). Waiting for the CEO report and the Owner's approval (Gate 6)

## Phase goal *(CEO)*
- **At the end of this phase the Owner can:** open the app on the emulator and see its real look and feel. This means the final colours, fonts and shapes; a choice of Light, Dark, Dim or Auto that is still remembered after the app is closed; the four main tabs (Home, Dashboard, Transactions, Settings) with placeholder content; the shared "label + description + (i)" help pattern with first-time hints; and the welcome tour and permission explainer screens. No money, bank or SMS features yet. The Owner will also have seen every design as an ASCII mockup and palette in the chat while it was being made (CLAUDE.md rule 8).
- **In scope:**
  - **F-002 Design system & themes:**
    - Design tokens: colours (one accent; green = saved, red = overspent, neutral otherwise), fonts, text sizes, spacing, corner radius and the base components (buttons, cards, list rows, inputs).
    - The four themes Light, Dark, Dim and Auto. Auto follows the phone's setting.
    - A theme choice in Settings that is **remembered across restarts**. The default is Auto.
    - Custom fonts **bundled with the app** (free, open licence). They are never downloaded at runtime, because the app makes no network calls (D-003, STANDARDS §8).
    - WCAG AA text contrast, 48 dp touch targets, layouts that hold at the largest system font (STANDARDS §7).
  - **F-003 App shell & navigation:**
    - Bottom navigation with Home, Dashboard, Transactions and Settings. Each tab shows a placeholder body with an empty state.
    - Settings has placeholder rows for later items. The theme choice row comes from F-002.
    - App name "Daily Budget App" on screen and as the Android launcher label. It is a placeholder until Phase 7 (D-021).
    - Replaces the Phase 0 placeholder screen.
  - **F-004 Help & tooltip system:**
    - A reusable pattern of label, short description and (i) tooltip that every later button, setting and number will use (STANDARDS §7).
    - First-time hints on the main tabs, shown once and remembered after they are dismissed.
  - **F-005 Welcome tour & permission explainers (UI only):**
    - A welcome tour of 3–4 slides explaining the daily-budget idea, shown on first launch and remembered once finished or skipped.
    - Explainer screens for SMS and notifications: why each is needed and that data never leaves the phone. Plus the disclaimer (one bank account only, no credit cards, detection may need correcting).
    - Buttons on these screens **do not request any real permission**. The real requests come in Phase 4 (SMS) and Phase 5 (notifications).
  - Riverpod (`flutter_riverpod` 3.4.3 + `riverpod_lint` 3.1.9, D-017) is added with the first provider. The Phase 1 plan decides on code generation (recommendation from Phase 0: none at first).
  - Widget tests for every new screen in all four themes (STANDARDS §6). All checks stay green through `tool/check.ps1`.
  - One phase commit and push to GitHub after sign-off and the CEO report (CLAUDE.md rule 9, D-014).
- **Out of scope:**
  - Money logic, budget engine and the month setup flow (Phase 2).
  - The local database (Phase 2). Phase 1 settings such as theme, "tour seen" and "hint seen" are simple app preferences, not money data.
  - Bank selection, salary entry, SMS reading and real permission requests (Phases 2 and 4).
  - Notifications (Phase 5).
  - Real content on Home, Calendar, Dashboard and Transactions (Phase 3).
  - Animations and polish beyond the basic transitions, and the "How this app works" page (Phase 6).
  - Final app name, icon and application ID (Phase 7).

## Features in this phase *(CEO + Product Manager)*
| ID | Feature | Doc | Plan | Tests | Status |
|---|---|---|---|---|---|
| F-002 | Design system & themes | [docs/features/F-002-design-system-themes.md](../docs/features/F-002-design-system-themes.md) | [plans/F-002-design-system-themes.md](F-002-design-system-themes.md) | [tests/F-002-design-system-themes.md](../tests/F-002-design-system-themes.md) | Done |
| F-003 | App shell & navigation | [docs/features/F-003-app-shell-navigation.md](../docs/features/F-003-app-shell-navigation.md) | [plans/F-003-app-shell-navigation.md](F-003-app-shell-navigation.md) | [tests/F-003-app-shell-navigation.md](../tests/F-003-app-shell-navigation.md) | Done |
| F-004 | Help & tooltip system | [docs/features/F-004-help-tooltip-system.md](../docs/features/F-004-help-tooltip-system.md) | [plans/F-004-help-tooltip-system.md](F-004-help-tooltip-system.md) | [tests/F-004-help-tooltip-system.md](../tests/F-004-help-tooltip-system.md) | Done |
| F-005 | Welcome tour & permission explainers | [docs/features/F-005-welcome-tour-permission-explainers.md](../docs/features/F-005-welcome-tour-permission-explainers.md) | [plans/F-005-welcome-tour-permission-explainers.md](F-005-welcome-tour-permission-explainers.md) | [tests/F-005-welcome-tour-permission-explainers.md](../tests/F-005-welcome-tour-permission-explainers.md) | Done |

*Dependencies (for the Developer's build order):* F-002 comes first, because every screen uses its tokens. F-003 needs F-002. F-004 needs F-002 and sits on the F-003 tabs. F-005 needs F-002 and F-004. F-002, F-004 and F-005 should share one small preferences store, so it is chosen once.

## Owner actions and risks *(CEO)*
- ~~**Owner action, before the first plugin is added:** turn on Windows Developer Mode.~~ **No longer needed (Gate 1, 2026-11-05, D-029).** Flutter 3.47.9 only creates plugin symlinks when a `windows/` or `linux/` folder exists; this app is Android-only (D-020). The Developer's probe built an APK with `shared_preferences` while Developer Mode was off, and the PM confirmed it in the Flutter source. No Owner action is needed for Phase 1.
- **Design visibility:** every design (tokens, palette, each theme, each screen) is shown to the Owner in the chat as an ASCII mockup plus palette as soon as it is made. Work does not stop for approval (CLAUDE.md rule 8, D-012). Gate 2 is the Project Manager's.
- **Risk: the Dim theme is new ground.** A warm-grey middle theme must still meet AA contrast for green and red. The Designer checks contrast for every theme × colour pair.
- **Risk: privacy of fonts.** Font packages that download at runtime (for example `google_fonts` in its default mode) would make network calls. Fonts must be bundled.
- **Escalation check:** nothing in this phase changes money, permissions, privacy or cost. If a plan adds a paid dependency or a real permission request, it goes to the Owner (WORKFLOW "Escalate to Owner").

## Carried forward from Phase 0 *(from the Phase 0 sign-off)*
- **Phase 1:** ~~Windows Developer Mode on before the first plugin~~ (not needed, D-029). Riverpod code-generation decision (in the F-002 or F-003 plan, whichever adds the first provider). The Android launcher label changes from the generated `daily_budget` to "Daily Budget App" (F-003).
- **Tester tidy-up:** remove the historical "Blocked" wording from TC-001-29 and TC-001-46 in `tests/F-001-project-foundation.md`.
- **Regression:** all F-001 Regression-yes cases and `tests/REGRESSION.md` stay green. In particular, the domain purity guard TC-001-06 must hold, so `domain/` stays pure Dart.
- **Not this phase (kept on the list):** Phase 2: re-check the native SQLite build with the NDK in use (Flutter's default from T-101, D-029), extend the domain guard to check layer direction, and decide database encryption. Phase 7: final app name and application ID (D-021).

## Build order *(Developer, approved by Project Manager)*
*Proposed by the Developer on 2026-11-05; **approved by the Project Manager at Gate 1 (2026-11-05)**, with Tester task T-126 (test-case updates) running in parallel with T-101/T-102 and finished before T-103.* Features are built in the order F-002 → F-004 components → F-003 → F-002 theme picker → F-004 hints → F-005. F-002 comes first because every screen uses its tokens, store and harness. F-004's label/description and (i) components come before the F-003 Settings list, because those rows are built from them. The theme picker and the hints are built once the tabs exist. F-005 comes last, because its `AppGate` sits in front of the finished shell. Task IDs are T-101…T-125, unique across the four plans.

| # | Task | Feature | What | Needs plugin build / emulator |
|---|---|---|---|---|
| 1 | T-101 | F-002 | Packages (Riverpod 3.4.3, `shared_preferences` 2.5.6, `riverpod_lint` 3.1.9 plugin), DECISIONS rows | Only its final `flutter build apk` step |
| 2 | T-102 | F-002 | Preferences store interface + in-memory fake/fallback + plugin adapter | — |
| 3 | T-103 | F-002 | Bundled fonts, licences, ₹/`tnum` font-table test | — |
| 4 | T-104 | F-002 | Design tokens + contrast test | — |
| 5 | T-105 | F-002 | `ThemeData` builder, theme mapping, system bars | — |
| 6 | T-106 | F-002 | Test harness (5 theme cases, sizes, accessibility) + tokens-only guard | — |
| 7 | T-107 | F-002 | Base components | — |
| 8 | T-108 | F-002 | Theme choice state + `main()` bootstrap | — |
| 9 | T-116 | F-004 | Help copy, label + description, `NavTooltip` | — |
| 10 | T-117 | F-004 | (i) button + help sheet | — |
| 11 | T-111 | F-003 | App shell, custom bottom bar, back, scroll | — |
| 12 | T-112 | F-003 | Home/Dashboard/Transactions empty states | — |
| 13 | T-113 | F-003 | Settings list with Coming soon rows | — |
| 14 | T-114 | F-003 | Remove the Phase 0 placeholder, app name (with the Tester: retire TC-001-14/-15/-16/-43) | — |
| 15 | T-109 | F-002 | Theme row + picker sheet | — |
| 16 | T-118 | F-004 | First-time hints on the four tabs | — |
| 17 | T-121 | F-005 | Onboarding state + `AppGate` | — |
| 18 | T-122 | F-005 | Welcome tour | — |
| 19 | T-123 | F-005 | SMS/notifications explainers + disclaimer | — |
| 20 | T-124 | F-005 | No-permission guard | — |
| 21 | T-119 | F-004 | Rule, copy and shared-component checks across all Phase 1 screens | — |
| 22 | T-110, T-115, T-120, T-125 | F-002…F-005 | Emulator verification per feature (restart persistence, live Auto, system bars, back/predictive back, TalkBack, manifests) | **Yes [P]** (no Owner dependency) |

**Plugin build / Developer Mode.** All tasks 1–21 run and are fully tested with `flutter test` using the in-memory store, so they do not wait for the Owner. Only the [P] steps need the real plugin build. A probe on 2026-11-05 (in a scratch copy, outside the project) found that this Android-only app builds with `shared_preferences` while Developer Mode is **off**. Flutter 3.47.9 only needs symlinks when a `windows/` or `linux/` folder exists. See plan F-002 §7. **Accepted at Gate 1 (D-029):** the [P] tasks are not blocked on the Owner. T-101 also returns the app to Flutter's default NDK 28.2.13676358, which plugins need anyway (D-025 amended).

## Phase sign-off *(Project Manager — Gate 5)*
**Verdict (2026-11-11): Phase 1 passes Gate 5. Not approved: only the Owner approves the phase (Gate 6).**
- [x] Every feature Done (doc, plan and test files all complete): F-002, F-003, F-004, F-005 are Done in `docs/features/INDEX.md`; section 7 of each doc is filled in; each plan has its Gate 1 review and section 11; each test file has results (R1 to R3) and the PM's Gate 4 verdict. Cases: F-002 47/47 Pass, F-003 31 (29 Pass, 1 Partial, 1 Blocked-needs-human), F-004 25 (23 Pass, 1 Partial, 1 Blocked-needs-human), F-005 32/32 Pass; 0 Fail.
- [x] No open High/Critical bugs: `docs/BUGS.md` has one bug, B-001 (Low, predictive back preview on a tab), Closed by D-065. No open bug of any severity.
- [x] Final full regression green. PM re-run on 2026-11-11: `tool/check.ps1` ALL CHECKS PASSED (pub get, format, `flutter analyze`, `dart analyze --fatal-infos`, test names, `flutter test`), **336 tests, all passed**. Emulator evidence cited from `tests/PHASE-1-SUMMARY.md` (Tester run R3): integration tests 2 of 2 on emulator-5554 (TC-002-11, TC-005-16), `tool/tz_matrix.ps1` PASSED (UTC, PST8PDT, IST), `tool/domain_coverage.ps1` 100 %, `tests/REGRESSION.md` checks 1 to 12 Pass and check 9 (fresh install) Pass, TC-004-25 (rotation with the help sheet) Pass; checks 13 to 16 not re-run in R3 because no code changed since R2 (R2 Pass, 16 Partial). The PM did not re-run the emulator.
- Records current: README tracker (Phase 1 development, testing and PM sign-off ticked; CEO report and Owner approval still open), `docs/TASKS.md` (all Phase 1 build and test tasks Done), `docs/features/INDEX.md`, `docs/DECISIONS.md` (D-061 to D-066), BUGS.md. Feature doc status lines for F-002 to F-005 were still "Plan approved" and were set to Done by the PM at this gate.
- **Open items for the CEO report (none blocks sign-off):**
  1. Four TalkBack cases are **Blocked-needs-human** (D-066): TC-003-03 step 4 and TC-003-18 (F-003), TC-004-04 and TC-004-07 R1 check (F-004). adb cannot drive TalkBack. Their widget-test proofs are green. The Owner is recommended, not required, to run the steps in `tests/PHASE-1-SUMMARY.md` on a real phone (about 15 minutes), ideally before Phase 3.
  2. D-064: the release APK carries one AndroidX-own signature-level permission line (`DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`); nothing is requested by the app (no INTERNET, SMS or notifications). Owner FYI because permissions are an escalation topic.
  3. D-065: on Dashboard, Transactions and Settings the predictive-back preview is only the system back chip, never blank; Home shows the app shrinking. Dashboard and Transactions were not photographed (same Back handler as Settings).
  4. D-066 itself (TalkBack Blocked cases do not block the phase).
  5. Nice to haves, none blocking, still To do in `docs/TASKS.md`: T-234 (theme picker at 2.0x hides the selected option, no scroll cue), T-235 (tour body cut at 2.0x, no cue), T-236 ("Transactions" nav label baseline at 2.0x), T-237 (tour slide 2 ledger width at 2.0x). They are polish for Phase 3.
  6. Smaller notes: the `Close` scrim label literal could move to `ScreenCopy` (Phase 3); TC-002-12 was checked with a screenshot burst, not frame by frame (no ffmpeg); the TC-002-03 sweep reads the expected background from the same token (token values are covered by `theme_tokens_test.dart`); the Dark theme has no screenshot, only sweeps; the TalkBack R1 focus risk (hint dismissal could land on the tab bar) is covered by the Blocked case above.
  7. Not Phase 1: T-206 to T-211, T-212b/c, T-213, T-214b, T-215, T-216, T-218 to T-220 (Phase 2, To do) and T-221 to T-223, T-227 (Nice to have, To do) are Phase 2/3 work and do not affect this sign-off. Phase 2 has planning and parallel building under D-033; it is signed off separately.
- Improvements made beyond the original plan: custom bottom bar with a sliding ink tick and a label cap at 1.3x with `FittedBox`; one explicit semantics node per row with a separate (i) button (D-032); every sheet opens through one `showBudgetSheet` with a scrim that ignores the second tap of a double tap, a visible close button, and a Close screen-reader label (D-031, T-233); `dart analyze --fatal-infos` added to `tool/check.ps1` so the `riverpod_lint` plugin is enforced; `ProviderContainer.test` false positive fixed in the test-name check; a preferences allow list so only registered keys are stored; the first frame is already in the saved theme (store read before `runApp`); Remove animations respected by the theme switch, sheets, hints and gate swap; `AppGate` absorbs the second tap of a double tap on "I understand" (D-044); focus moves to the next item after a hint is dismissed; 18-state screen sweeps (theme x size x text scale x landscape x bold) with proven failing probes; permission guard test (`no_permissions_test.dart`); on-device integration tests (D-063); `crypto` used for font SHA-256 checks (D-061); the Designer's Phase 1 visual review of 50 emulator screenshots (no Must fix).
