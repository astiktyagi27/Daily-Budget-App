# Plan — F-003: App shell & navigation

| | |
|---|---|
| **Feature doc** | [`docs/features/F-003-app-shell-navigation.md`](../docs/features/F-003-app-shell-navigation.md) |
| **Test cases** | [`tests/F-003-app-shell-navigation.md`](../tests/F-003-app-shell-navigation.md) |
| **Design** | [`docs/design/screens/app-shell.md`](../docs/design/screens/app-shell.md), [`docs/design/screens/settings.md`](../docs/design/screens/settings.md), design system §7.4, §7.7, §7.10 |
| **Author** | Developer |
| **Status** | Approved (Gate 1, Project Manager, 2026-11-05) — see §10; T-115 no longer depends on Developer Mode (D-029) |

## 1. Approach
A single `AppShell` widget holds the four tabs in an **`IndexedStack`**, with the **custom bottom bar** from design §7.7 and app-shell §3. No router package is used.

1. **Navigation state.** The shell keeps the selected tab index in local widget state (`StatefulWidget`). It is not a provider and is not persisted, because the app always opens on Home (AC-7, feature doc §6). The `IndexedStack` keeps every tab's widget alive, so scroll positions survive tab switches for the session (AC-9). Each tab owns a `ScrollController`. Tapping the selected tab calls `animateTo(0)` with `BudgetMotion.emphasis` (instant when Remove animations is on). At offset 0 the tap does nothing (AC-9). Switching tabs cross-fades the body (`AnimatedSwitcher` over the visible child is not used, because it would rebuild tabs; instead each `IndexedStack` child sits in an `AnimatedOpacity` keyed to `index == i`, with `BudgetMotion.base`).
2. **Back (AC-8).** `PopScope(canPop: index == 0, onPopInvokedWithResult: (didPop, _) { if (!didPop) select(0); })`. On Home the pop goes through to Android, which sends the app to the background. Sheets, the theme picker and help sheets are routes above the shell, so back closes them first, as Navigator normally does (TC-003-21). Predictive back: on Home the system's "back to launcher" preview shows. On other tabs the pop is intercepted (no preview), and the tab changes to Home. Nothing is ever blank (TC-003-22).
3. **Bottom bar (`BudgetNavigationBar`)**, built as specified in app-shell §3:
   - Four equal slots: ink tick (space reserved on every slot), icon (outlined, or filled when selected), label.
   - The tick slides between slots (`AnimatedAlign`, `motionBase`).
   - Labels are scaled with `MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3)`, one line, inside `FittedBox(fit: BoxFit.scaleDown)`. They never clip or ellipsize, and the bar grows with the label.
   - `surface` fill with a top hairline. It extends under the system navigation area, and the items sit above `MediaQuery.paddingOf(context).bottom`.
   - Each slot is a `Semantics(button: true, selected: …, label: 'Home, tab 1 of 4')` wrapped in a `Tooltip` with the F-003 §5 hint (long-press), with a ≥ 48 dp target and an `InkRipple` ripple.
   - The bar is a feature widget (`features/shell/`) and uses tokens only (F-002 AC-9 guard).
   - Material's `NavigationBar` is **not** used. Its pill indicator is exactly what the design replaces (design §1, §8.3).
4. **Tab page frame (`TabPage`).** This is the shared layout from app-shell §2. It is a `CustomScrollView` with the tab's controller, containing:
   - the **title header** as the first sliver (`headline`, `Semantics(header: true)`; no fixed `AppBar`, so the title wraps at 2.0×);
   - an optional **hint slot** (filled by F-004 T-118);
   - the body;
   - bottom padding equal to the bar height + `space6`.

   Reading order is title → hint → body → bottom bar (AC-12, TC-003-17). The bar sits after the page in the shell's semantics order.
5. **Placeholder tabs.** Home, Dashboard and Transactions each show the shared `EmptyState` component (`core/widgets/empty_state.dart`, design §7.10). It has an 88 dp `neutralSoft` circle with a line icon, a title and a description. It is left-aligned per app-shell §4 (see §9 Q1) and contains no button. The copy is exactly F-003 §5.
6. **Settings tab.** A `TabPage` whose body is the list from `settings.md`:
   - the **Theme row** first (built by F-002 T-109, inserted into the list's first slot);
   - then the seven **Coming soon** rows: Notifications, Bank account, Salary date, Categories, Privacy & data, How this app works, Disclaimer;
   - optional group headers as `settings.md` §2 defines them.

   Each Coming soon row is a `BudgetListRow` with the F-004 label + description pattern and a `ComingSoonTag` trailing. The tag moves below the description when the text column would be narrower than 160 dp (`LayoutBuilder`, settings.md §7).
   Each row is **disabled**: no `onTap` and no ripple. It has `Semantics(enabled: false, label: '<label>, coming soon, not available yet')` with the description merged in. Tapping it does nothing: no route, no dialog and no log (AC-6).
7. **App name (AC-10).** `android:label="Daily Budget App"` in `AndroidManifest.xml`. `MaterialApp.title` is already `Daily Budget App`, which sets the recents title. The Home title header shows `Daily Budget App`.
8. **Phase 0 placeholder removed (AC-11).** Delete `lib/features/placeholder/` and `test/features/placeholder/`. `app.dart`'s `home` becomes `AppShell`. F-005 T-121 later puts `AppGate` in front of it. The F-001 test cases are handled in §8.

All copy comes from the copy files:
- `lib/core/copy/screen_copy.dart`: tab titles, empty states, row labels.
- `lib/core/copy/help_copy.dart` (F-004): row descriptions, nav tooltips and hints, the Coming soon screen-reader text.

**Alternatives rejected**
- *`go_router` with `StatefulShellRoute`*: it works, but it adds a package and a URL model for four fixed tabs and a linear onboarding flow. There are no deep links in scope (feature doc §6). Reconsider in a later phase if deep links or app shortcuts are approved.
- *Material `NavigationBar`*: its pill indicator and label behaviour conflict with design §7.7. Restyling it to hide the pill and add the tick costs more than a small custom bar, and label scaling would still need custom work.
- *`PageView` for tabs*: sideways swiping between tabs is not in the design ("no sideways page slide", app-shell §3.4).
- *A separate `Navigator` per tab*: there are no sub-pages in Phase 1. Add it when Phase 3 brings day details if the design asks for it.

## 2. Files / modules
| Path (under `app/` unless marked) | Add / Change | What |
|---|---|---|
| `lib/features/shell/app_shell.dart` | Add | `AppShell`: index state, `IndexedStack`, per-tab `ScrollController`s, `PopScope`, re-tap to top. |
| `lib/features/shell/budget_navigation_bar.dart` | Add | Custom bar (ink tick, label cap + fit, semantics, tooltips, ripple). |
| `lib/features/shell/app_tab.dart` | Add | `enum AppTab { home, dashboard, transactions, settings }` with icon (outlined/filled) and copy keys. Order is fixed by the enum. |
| `lib/features/shell/tab_page.dart` | Add | Shared tab frame (title header, hint slot, body, bottom padding). |
| `lib/core/widgets/empty_state.dart` | Add | Design §7.10 component (icon circle, title, description, optional button slot, unused in Phase 1). |
| `lib/features/home/home_tab.dart`, `lib/features/dashboard/dashboard_tab.dart`, `lib/features/transactions/transactions_tab.dart` | Add | `TabPage` + `EmptyState`. |
| `lib/features/settings/settings_tab.dart` | Add | Settings list (Theme row slot + 7 Coming soon rows, group headers). |
| `lib/features/settings/coming_soon_row.dart` | Add | Disabled `BudgetListRow` + `ComingSoonTag` + semantics. |
| `lib/core/copy/screen_copy.dart` | Add | Screen copy (shared with F-005). |
| `lib/core/copy/help_copy.dart` | Change | F-003 row descriptions, nav tooltips (the file is created by F-004 T-116). |
| `lib/app.dart` | Change | `home: const AppShell()` (T-114). |
| `lib/features/placeholder/placeholder_screen.dart` | **Delete** | Phase 0 placeholder (AC-11). |
| `test/features/placeholder/placeholder_screen_test.dart` | **Delete** | Its four tests (TC-001-14/-15/-16/-43); see §8. |
| `android/app/src/main/AndroidManifest.xml` | Change | `android:label="Daily Budget App"`. Nothing else changes; still no `<uses-permission>`. |
| `test/features/shell/app_shell_test.dart`, `budget_navigation_bar_test.dart` | Add | TC-003-01…-04, -10, -12, -19…-21, -23, -25, -26. |
| `test/features/tabs/empty_tabs_test.dart` | Add | TC-003-05. |
| `test/features/settings/settings_tab_test.dart` | Add | TC-003-06, -07, -16. |
| `test/features/shell/app_name_test.dart` | Add | TC-003-13 (Home title; manifest label read from `android/app/src/main/AndroidManifest.xml` via `dart:io`), TC-003-15 (search `lib/` for `PlaceholderScreen` and the Phase 0 status text → 0). |
| `test/features/shell/reading_order_test.dart` | Add | TC-003-17. |
| *(root)* `tests/F-001-project-foundation.md` | Change (by Tester) | Retire TC-001-14/-15/-16/-43 with a pointer to F-003 (§8). |
| *(root)* `tests/REGRESSION.md` | Change (by Tester) | Check 9 wording: "shows Home with the bottom navigation" instead of the placeholder. |

## 3. Data model / database changes
None. The selected tab and scroll positions are session-only widget state (AC-7: always open on Home). The Theme row's value comes from F-002's `theme.choice` key.

## 4. Packages (latest stable, checked on pub.dev)
No new packages. It uses `flutter_riverpod` 3.4.3 from F-002 T-101 (to read `themeChoiceProvider` for the Theme row, and from F-004 for hint state). No router package (§1, alternatives).

## 5. Tasks
| ID | Task | Covers AC | Depends on | Status |
|---|---|---|---|---|
| T-111 | **Shell + bottom bar + back.** `AppTab`, `AppShell`, `BudgetNavigationBar`, `TabPage` frame. Widget tests: four tabs in order, Home selected; selected = tick + filled icon + `selected` semantics ("Dashboard, tab 2 of 4, selected"); all 12 from→to switches show the right title; rapid taps → last wins, one back → Home; back on tabs 2–4 → Home, back on Home → pop passes through (`SystemNavigator` call observed via `tester.binding.defaultBinaryMessenger` mock for `SystemNavigator.pop` / route pop result); long-press tooltip + semantics hint per tab; bar labels at 360 and 320 dp wide × scale 1.0, 1.3, 2.0 untruncated, no overflow (app-shell §3.2 item 3); bar above `viewPadding.bottom` for gesture and 3-button insets; 1024×768 wide screen no crash; theme flip while on a scrolled tab keeps tab and offset (F-002 AC-4). | AC-1, AC-2, AC-3, AC-8, AC-9 (mechanics), AC-12 (bar) | T-107, T-108 (F-002) | Code review |
| T-112 | **Placeholder tabs.** `EmptyState`, Home/Dashboard/Transactions tabs with exact copy. Tests: exact title + description strings (literals in tests), icon present, no amounts (`find.textContaining('₹')` → none), no buttons/sample data; 5 theme cases × 1.0/2.0 on 360×640 → accessibility helper passes. | AC-4, AC-12 | T-111 | Code review |
| T-113 | **Settings tab.** List with the Theme-row slot first and the seven Coming soon rows in order, F-004 label + description, `ComingSoonTag` (reflows under the description below 160 dp), disabled semantics "<label>, coming soon, not available yet". Tests: order and copy; tapping each placeholder row → no new route (`NavigatorObserver`), no dialog, no exception, no log output; semantics disabled + text; at 2.0 the list scrolls; scroll offset kept after Settings → Home → Settings; re-tap Settings → offset 0. | AC-5, AC-6, AC-9, AC-12 | T-111, T-116 (F-004 label + description) | Code review |
| T-114 | **Remove placeholder, app name.** Delete the placeholder screen and its test; `home: AppShell`; manifest label `Daily Budget App`; app-name test and "placeholder gone" search test; reading-order test across tabs. **Coordinated with the Tester in the same change:** TC-001-14/-15/-16/-43 marked retired in `tests/F-001-project-foundation.md` before `check.ps1` runs (§8). | AC-7, AC-10, AC-11, AC-12 (reading order) | T-112, T-113 | Code review |
| T-115 | **[P] Emulator verification F-003.** Debug build on emulator-5554: launcher label and recents title (TC-003-14); back button and back gesture, predictive back preview (TC-003-11, -22); greyscale + TalkBack walk (TC-003-03, -18); gesture vs 3-button nav (TC-003-24); force-stop on Settings → reopens on Home at top, and after `adb shell am kill` (TC-003-09). Screenshots to `docs/reviews/`. | AC-2, AC-7, AC-8, AC-10, AC-12 (device parts) | T-114, T-109; plugin build available (Owner Developer Mode, or PM accepts F-002 §7 probe) | To do |

## 6. Acceptance criteria coverage
TC IDs come from the Tester's draft `tests/F-003-app-shell-navigation.md` (2026-11-05). They are proposals until the PM reconciles them at Gate 1.

| AC | Built in task | Proved by test cases |
|---|---|---|
| AC-1 Four tabs in order, icon + label, Home selected | T-111 | TC-003-01, TC-003-19, TC-003-25, TC-003-26, TC-003-27 (with F-005) |
| AC-2 Selected state not by colour alone | T-111, T-115 | TC-003-02, TC-003-03 |
| AC-3 Switching tabs (12 combinations) | T-111 | TC-003-04, TC-003-20 |
| AC-4 Placeholder empty states, exact copy | T-112 | TC-003-05 |
| AC-5 Settings rows, order, copy, Coming soon | T-113 (+ Theme row T-109) | TC-003-06 |
| AC-6 Placeholder rows do nothing; Theme row opens picker | T-113, T-109 | TC-003-07 |
| AC-7 Always opens on Home | T-111 (no persisted index), T-114, T-115 | TC-003-08, TC-003-09 [P] |
| AC-8 Back button | T-111, T-115 | TC-003-10, TC-003-11, TC-003-20, TC-003-21, TC-003-22 |
| AC-9 Scroll kept between tabs; re-tap to top | T-111, T-113 | TC-003-12 |
| AC-10 App name everywhere | T-114, T-115 | TC-003-13, TC-003-14 |
| AC-11 Phase 0 placeholder gone; F-001 cases retired | T-114 | TC-003-15 |
| AC-12 All themes, large text, accessibility, reading order | T-111…T-114, T-115 | TC-003-16, TC-003-17, TC-003-18, TC-003-23, TC-003-24, TC-003-26 |
| (Riverpod introduced, edge case) | F-002 T-101 | TC-003-28 |

## 7. Edge cases & risks
| Case / risk | How it is handled |
|---|---|
| Rapid tab tapping | `select(i)` is idempotent. There are no route pushes for tabs, so nothing stacks and one back reaches Home (TC-003-20). |
| Back with picker / (i) / hint open | Picker and help sheet are modal routes, so back pops them first. The hint card is inline (not an overlay), so back on a tab with a hint goes to Home, as the design intends (help-pattern §4). TC-003-21. |
| Predictive back (Android 14+) | `PopScope` drives it. Home → system preview of leaving. Other tabs → intercepted, no blank preview. Verified on API 37 in T-115. If the system shows a blank preview, stop and report. |
| Theme change while on Settings | The theme rebuild does not touch the `IndexedStack` children's state, so index and offset are kept (test in T-111). |
| Text scale 2.0 | Titles wrap (no fixed app bar). Nav labels are capped at 1.3 and fitted. Settings rows wrap and the tag reflows. The list scrolls. |
| "How this app works" longest label | Wraps, never truncates (no `maxLines`/ellipsis on labels; test at 2.0 asserts the full text is found and no overflow). |
| App killed in background | Nothing persisted, so it reopens on Home (AC-7). |
| Gesture vs 3-button navigation, edge-to-edge | Bar pads by `MediaQuery.paddingOf(context).bottom`. Tests use both insets (e.g. 24 dp gesture, 48 dp buttons). |
| Launcher truncation | Accepted (AC-10). |
| Wide screen / tablet | Not a target. The test at 1024×768 checks for no crash or overflow. |
| Placeholder rows tapped by accident | No `onTap`. `InkWell` absent, so there is no ripple. Semantics `enabled: false`. No logging anyway (no logger in Phase 1). |
| Hint slot before F-004 | `TabPage.hint` is nullable. F-004 T-118 fills it, so F-003 tests do not depend on hint state. |
| Riverpod first provider | Introduced in F-002 T-101 (decision recorded there, D-027). |

## 8. Impact on existing features
**F-001 placeholder tests: TC-001-14, TC-001-15, TC-001-16, TC-001-43.** These four automated tests pump `DailyBudgetApp` and assert the Phase 0 placeholder: exactly two `Text` widgets, no buttons or navigation bar, nothing tappable, and text scale 3.0 on 320×568. After T-114 every one of them would **fail by design**, because the app now shows the shell with a navigation bar, buttons and many texts. Plan:

| Case | What happens | Replacement (proves the same intent for the new home screen) |
|---|---|---|
| TC-001-14 placeholder shows title and status text | **Retired**, superseded by F-003. Test removed with the placeholder in T-114. | TC-003-05 (exact empty-state copy), TC-003-13 (Home title `Daily Budget App`), TC-003-15 (Phase 0 text gone) |
| TC-001-15 placeholder has no buttons or text fields | **Retired**. The shell is meant to have buttons. | TC-003-05 (empty states have no buttons), TC-003-07 (Settings placeholder rows inert) |
| TC-001-16 placeholder renders without exceptions | **Retired**. | TC-003-26 (shell in every theme on all tabs, no exceptions), TC-002-03 |
| TC-001-43 placeholder fits at text scale 3.0 on small screen | **Retired**. | TC-003-16 and TC-002-24 (2.0 on 360×640, the AC's definition). Suggestion for the Tester: keep the F-001 margin by also running one shell smoke test at 3.0 on 320×568 (cheap, same harness). |

- IDs are **retired, never reused** (F-001 rule). The Tester marks them in `tests/F-001-project-foundation.md`: "Retired: superseded by F-003 (T-114), see TC-003-…". The F-001 test-file status line and `REGRESSION.md` check 9 are updated in the same change, so `tool/check.ps1` stays green and the regression list has no dangling automated name. In F-002 T-108 these four tests first get the `ProviderScope` harness so they keep passing until T-114 (F-002 plan §8).
- **TC-001-35** (counter-sample strings) is unaffected. `FloatingActionButton` stays absent from `lib/`.
- **TC-001-17** (no `<uses-permission>` in the main manifest): only `android:label` changes. Re-run.
- **TC-001-04/-05** (structure): `lib/` still holds only `core`, `data`, `domain`, `features`, `main.dart`, `app.dart`. Re-run.
- **TC-001-06** domain guard: F-003 adds nothing to `domain/`. Re-run.
- **F-002:** the Theme row lives in this Settings list. A picker regression would show in TC-003-07. Re-run TC-002-01, -07.
- Re-run: full `flutter test`, `tool/check.ps1`, TC-001-04/-05/-06/-17/-35, REGRESSION checks 2, 3, 9.

## 9. Open questions
1. **(PM/PM-doc owner) Empty-state alignment:** F-003 §2.4 says "centred in the body". The design (design §7.10, app-shell §4) places it left-aligned on purpose, and the Designer proposes rewording F-003 to "placed in the body per design system". AC-4 does not depend on alignment. **I plan left-aligned per the design.** The Product Manager rewords §2.4.
2. **(Tester) TC-001-43 margin:** keep one 3.0× smoke test on the shell (the suggestion in §8), or rely on the 2.0× ACs only?
3. **(PM) Settings group headers:** `settings.md` §2 defines group headers. AC-5 only fixes row order. The plan follows the design's headers. Confirm they don't count as "rows" for TC-003-06.
4. **(CEO) Suggested additions** ("Show tips again", "Replay welcome tour", version line, "Delete all app data" placeholder) are **not** planned. If approved, each is a small extra row task.

## 10. Project Manager review *(Gate 1 — cross-check of doc + plan + test cases)*
**Verdict:** **Approved** (Project Manager, 2026-11-05). Condition: the test-case updates in point 1 are done in **T-126** before T-111 / T-113 start.

Cross-check:
- [x] Every AC in the feature doc is covered by a task in this plan (AC-1…AC-12 → T-111…T-115, §6)
- [x] Every AC has at least one test case in the test file (TC-003-01…-28, plus -29/-30 added in T-126)
- [x] Edge cases in the doc appear in both the plan and the test cases (rapid taps, back with overlays, predictive back, theme change on Settings, 2.0 text, longest label, system kill, gesture vs 3-button, launcher truncation, wide screen, Riverpod)
- [x] Approach follows `docs/STANDARDS.md` (no new package, tokens-only bar in `features/`, copy in `core/copy/`, small widgets)
- [x] Latest stable versions / modern APIs used (`PopScope.onPopInvokedWithResult`, `TextScaler.clamp`, no router package — justified for four fixed tabs without deep links)

| # | Point | Type | Resolution |
|---|---|---|---|
| 1 | **Test cases to update (Tester).** **TC-003-07**: exact semantics label of a Coming soon row is now fixed (F-003 §5): `<Label>, coming soon, not available yet. <Description>`, e.g. `Notifications, coming soon, not available yet. Budget warnings and an end-of-day summary`, and `isEnabled` false. **TC-003-21**: add (c) Settings hint visible → Back → Home; hint **not** marked seen; back on Settings the hint is still shown. **TC-003-28**: `riverpod_lint` 3.1.9 is checked in `analysis_options.yaml` `plugins:` (not in `pubspec.yaml`/`pubspec.lock`); `flutter_riverpod` 3.4.3 in pubspec + lock; codegen decision = D-027. **New TC-003-29** (Auto-widget, regression yes) `TC-003-29 shell survives text scale 3 on a small screen`: 320×568, text scale 3.0, Light, each tab + Settings scrolled to the end: no exception, no overflow (keeps the F-001 TC-001-43 margin). **New TC-003-30** (Auto-widget, regression yes) `TC-003-30 nav labels are capped and fitted at large text`: 360 and 320 dp wide × 1.0 / 1.3 / 2.0: each label one line, full text, not ellipsized, inside its slot, no overflow, icon size unchanged (app-shell §3.2). **§2.2**: TC-001-43 → retired, replaced by TC-003-29 + TC-002-24. **§2.3**: empty-state alignment, Coming soon string and back-with-hint resolved (doc edited). Header: plan exists. | Must fix (Tester, T-126; blocks T-111, T-113) | Scheduled as T-126. |
| 2 | **Empty-state alignment (§9 Q1).** Left-aligned per design system §7.10 / app-shell §4. F-003 §2.4 reworded by the PM (AC-4 unchanged). | Resolved | Doc edited. |
| 3 | **Back with a hint visible.** The hint is inline page content, not an overlay. Back ignores it: not dismissed, not saved as seen, normal tab rule. This matches the plan §7, app-shell §3.4 and F-004 §2.5 ("only dismissed counts as seen"). F-003 §2.7 and §4 reworded. | Resolved | Doc edited; TC-003-21 (c). |
| 4 | **Coming soon screen-reader string.** Status first, then the description, so a TalkBack user learns at once that the row is unavailable: `'$label, coming soon, not available yet. $description'` on a `Semantics(enabled: false)` node, the same no-final-full-stop form as `LabelDescription` (`'$label. $description'`). F-003 §5 and settings.md §2.3 updated. | Resolved | Doc + design edited. |
| 5 | **3.0× margin (§9 Q2).** Keep one cheap shell smoke case at 3.0× (TC-003-29). | Resolved | Point 1. |
| 6 | **Group headers (§9 Q3).** They are headings, not rows; TC-003-06 already allows them. | Resolved | — |
| 7 | **Suggested additions (§9 Q4)** stay out of scope (CEO). | Resolved | — |
| 8 | **F-001 retirements (§8).** TC-001-14/-15/-16/-43 are retired **in T-114, in the same change** that deletes the placeholder (Tester edits `tests/F-001-project-foundation.md` with the notes of test file §2.2), so `check.ps1` is never red. Before that, T-108 moves them onto the `ProviderScope` harness. TC-001-12 pattern, TC-001-29 / REGRESSION check 9 expected screen and the TC-001-29/-46 "Blocked" wording are updated earlier, in T-126. Schedule confirmed. | Resolved | TASKS T-108, T-114, T-126. |
| 9 | **T-113 vs the Theme row.** T-113 builds the list with an empty first slot; the Theme row arrives in T-109. So TC-003-06/-07 pass fully only after T-109; T-113's tests cover the seven rows and the slot. Note it in the T-113 Gate 3 so nobody reads it as a gap. | Nice to have (Developer) | Noted in TASKS T-113. |
| 10 | **Predictive back on Android 13–15.** Add `android:enableOnBackInvokedCallback="true"` to `<application>` in T-114 (you edit the manifest there anyway). On Android 16+ with target SDK 36 predictive back is already on by default, so this only makes older phones consistent; it adds no permission (TC-001-17 unaffected). | Nice to have (Developer, T-114) | Noted in TASKS T-114. |
| 11 | **Icons.** Design §6 now says built-in Material Icons (the font is not variable, so weight 300 is not possible without a package). `bar_chart` and `tune` look almost the same outlined and filled; that is fine because the tick and the heavier label are the other two cues. TC-003-02 compares the `IconData` used. | Nice to have (info) | Design §6 edited. |
| 12 | **Cross-fade with `IndexedStack`.** `AnimatedOpacity` per child only fades the new tab in (the old one is offstage at once). That is acceptable for Phase 1; full cross-fade polish is Phase 6. Make sure offstage tabs keep `TickerMode` off so their animations do not run. | Nice to have (Developer, T-111) | — |

## 11. Implementation notes *(Developer, filled in during the build)*
Deviations from the plan and why (each approved by the Project Manager).

### T-111 … T-114 (Developer, 2026-11-06)
1. **No separate `ComingSoonTag` widget.** `ComingSoonRow` passes `tag: 'Coming soon'` to `BudgetListRow`, whose `BudgetTag` and reflow rule (T-107) already match settings.md §2.3/§7. Review N2 (measure the tag instead of the 120 dp estimate) is not done: TC-003-16 checks every tag inside its row at 2.0 in all T5 cases and passes, so I propose leaving it for a later polish task.
2. **Tab fade.** One shell `AnimationController` drives a `FadeTransition` on the selected tab only (offstage tabs get `kAlwaysCompleteAnimation`), restarted on every switch. An `AnimatedOpacity` per child (plan §1.1) would not fade in reliably, because its controller is muted while the tab is offstage (`TickerMode` off, §10 point 12). Duration `motionBase`, zero with Remove animations.
3. **Ink tick.** One `BudgetNavTick` that slides with `AnimatedAlign` across the four slots (design "tick slides"), drawn in a layer over the slots; every slot keeps the tick's space. Bar height 64 dp at 1.0 (4 + 4 tick + 8 + 24 icon + 4 + 16 label + 4).
4. **Test layout.** `test/features/shell/app_shell_test.dart` (T-111 cases), `test/features/tabs/empty_tabs_test.dart`, `test/features/settings/settings_tab_test.dart` (TC-003-06, -07, -12, -16, -29) and `test/features/shell/app_name_test.dart` (TC-003-08, -13, -15, -17; no separate `reading_order_test.dart`). Helper `test/helpers/shell.dart` (pumps the whole app since T-114); `pumpBudgetWidget` gained `navigatorObservers` and `scaffold`.
5. **TC-003-15 has an automated aid** (search of lib/ and test/ plus the two folders), in addition to the Manual (command) case.
6. **Route count in shell tests** is `Navigator.canPop()` on the root navigator (the app's `MaterialApp` takes no test observer); for a root navigator this is the same as "no route was pushed". The help-sheet tests use a `NavigatorObserver`.
7. **E6 (review T-103…T-108):** the tab-level interim tests in `test/core/theme/theme_choice_test.dart` were renamed to the Tester's exact titles and now run on the tabs: TC-002-02 (Home and Settings), -05 (Settings scrolled at 2.0, tab, offset and route kept, background variant), -10, -13, -14, -31 (every tab); -36 already had its exact title. Their picker steps (open the picker, pick) still use the notifier until T-109.
8. **Theme row slot.** The General group holds only Notifications until T-109 inserts the Theme row (`TODO(T-109)`), as §10 point 9 expects. TC-003-06/-07's Theme parts, TC-003-21 (needs the picker, the Theme (i) and the T-118 hint) and TC-002-03/-22/-23/-24 sweeps come later.
9. **Icons.** Line icons from Material Icons: rows `notifications_outlined`, `account_balance_outlined`, `event_outlined`, `category_outlined`, `lock_outline`, `menu_book_outlined`, `info_outlined` (Disclaimer); empty states `today_outlined`, `insights_outlined`, `receipt_long_outlined`; tabs `*_outlined` / filled. Manifest also has `android:enableOnBackInvokedCallback="true"` (§10 point 10).
10. **Extra test (D6):** TC-003-26 also has `empty tabs are accessible in every theme` (T5 × 1.0/2.0 on Small, F-002 guidelines + overflow), which is the interim proof for the retired TC-001-16 until the TC-002-03 sweep exists.

**PM Gate 3 (2026-11-06, `docs/reviews/code-phase-1.md` §T-116 … T-114):** items 1–10 approved (F3-1…F3-10). Item 1: N2 deferred to T-132. Item 9: app-shell.md §3/§3.4 wording aligned by the Designer in T-133. Must fix for T-111: M3 (dead field `AppTab.title`); the Developer adds the fix here as item 11.

11. **Review M3 (Developer, 2026-11-06): `AppTab.title` is the single source of the tab titles.** `HomeTab`, `DashboardTab`, `TransactionsTab` and `SettingsTab` now pass `AppTab.<tab>.title` to `TabPage` instead of their own `ScreenCopy` constant; the enum's titles are unchanged (`Daily Budget App`, `Dashboard`, `Transactions`, `Settings`). No behaviour change; TC-003-01/-04/-13 assert the literal titles and stay green.

12. **TC-003-21 and TC-003-31 (Developer, 2026-11-10).** `TC-003-21 back closes overlays before leaving the tab` is in `test/features/shell/app_shell_test.dart` (written with T-109/T-118, as §10 point 9 expected). With the list scrolled at 2.0 the page title can be out of view, so "still on Settings" is checked by the selected tab, no route left and the same scroll offset. The optional `TC-003-31 empty states are left aligned on the page gutter` is in `test/features/tabs/empty_tabs_test.dart`; it measures where the glyphs start (`RenderParagraph.getBoxesForSelection`), not the paragraph box, because a centred line in a full-width box would still have its box on the gutter.

**PM Gate 3 (2026-11-10):** item 11 (M3) resolved.

13. **T-132 (Developer, 2026-11-11): review N4 and N2.** N4: the shared `FocusRing` wrapper (`lib/core/widgets/focus_ring.dart`, built on `FocusRingPainter`, 2 dp ring, 2 dp offset) shows on `InfoButton` and on `BudgetListRow` (drawn inside the row edge) when keyboard-focused; tests `TC-004-05` and `TC-002-19` in `test/core/widgets/focus_ring_test.dart`. N2: `BudgetListRow` measures the trailing tag with `BudgetTag.widthOf` instead of the 120 dp estimate; `TC-003-16` in `budget_list_row_test.dart` checks the reflow from the measured width. No deviation from the plan.

**PM Gate 3 (2026-11-11):** item 13 (T-132: N4, N2) approved, no deviation. T-132 is Ready for test.

**T-115 emulator verification (Developer, 2026-11-11; evidence `docs/reviews/emulator-phase-1/`, details in the T-115 row of `docs/TASKS.md`):** TC-003-09 Pass, TC-003-11 Pass (button and edge-swipe), TC-003-14 steps 2-3 Pass, TC-003-24 Pass (gesture and 3-button). **TC-003-22 Partial:** on Home the back swipe previews the app leaving to the launcher; on Settings it shows only the back chip, no Home preview (tab Back is handled in-app, so the system has nothing to preview); never blank. Spec/design decision for Designer and PM: either relax the expected text or move the tab history into the route stack. **TC-003-03 Partial** (greyscale shots converted from normal screencaps because screencap ignores the colour transform; selected tab obvious) and **TC-003-18 Blocked**: TalkBack is installed and turns on, but adb cannot move its focus or read its speech, so a human must do those steps. No app code changed.
