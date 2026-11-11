# Plan — F-005: Welcome tour & permission explainers (UI only)

| | |
|---|---|
| **Feature doc** | [`docs/features/F-005-welcome-tour-permission-explainers.md`](../docs/features/F-005-welcome-tour-permission-explainers.md) |
| **Test cases** | [`tests/F-005-welcome-tour-permission-explainers.md`](../tests/F-005-welcome-tour-permission-explainers.md) |
| **Design** | [`docs/design/screens/welcome-tour.md`](../docs/design/screens/welcome-tour.md) (tour, SMS explainer, notifications explainer, disclaimer, back, large text) |
| **Author** | Developer |
| **Status** | Approved (Gate 1, Project Manager, 2026-11-05) — see §10; T-125 no longer depends on Developer Mode (D-029) |

## 1. Approach
A small onboarding state decides the first screen. The tour is one `PageView` page. The three explainer screens are ordinary routes. No permission API, permission package or manifest entry is added anywhere.

1. **Onboarding stage (pure Dart).** `enum OnboardingStage { tour, explainers, finished }` lives in `domain/preferences/`. `static OnboardingStage fromFlags({required bool tourSeen, required bool finished})` returns `finished` if `finished` is true (it wins), `explainers` if only `tourSeen` is true, and `tour` otherwise. This is the table in feature doc §2.8. It is unit-tested for all four flag combinations, including the odd case "finished but not tourSeen", which maps to `finished`.
2. **Repository + state.** `OnboardingRepository` (`data/`) reads and writes `onboarding.tour_seen` and `onboarding.finished` through the F-002 `PreferencesStore`. Unreadable values count as `false`, so the flow is shown again: the app fails towards onboarding, never towards a blank screen (AC-15, TC-005-27). `onboardingProvider` is a `Notifier<OnboardingStage>` with:
   - `completeTour()`: only from `tour`; state becomes `explainers`, then it writes `tour_seen = true`.
   - `finish()`: only from `explainers`; state becomes `finished`, then it writes `finished = true`.

   Both methods are **idempotent**, so a double tap cannot advance twice (AC-13). State changes before the write, so a failed write still reaches Home this session (AC-15).
3. **`AppGate`** is `MaterialApp.home`. It watches the provider and switches on the stage, exhaustively:
   - `tour` → `TourScreen`
   - `explainers` → `SmsExplainerScreen`
   - `finished` → `AppShell` (F-003)

   Flags are read before the first frame (F-002 bootstrap), so the first frame is already the right screen, with no flash of Home or of the tour (welcome-tour §7). There is no bottom navigation on onboarding screens, because they are not inside `AppShell` (AC-1, §2.9).
4. **Tour** (`TourScreen`), per welcome-tour §2:
   - A `PageView` of 4 slides with `ClampingScrollPhysics`: nothing happens past either end, and swiping cannot skip the explainers (TC-005-23).
   - Each slide has a decorative visual card built from design-system parts (no image files; `ExcludeSemantics`), the title (`displayHeadline`, heading semantics) and the body.
   - The page indicator is `Semantics(label: 'Slide n of 4')`.
   - Next / Skip / Get started use `NavTooltip` (F-004) with the F-005 §5 hints.
   - The TalkBack order is set with `OrdinalSortKey`: title → body → position → Next / Get started → Skip. This is needed because Skip and the indicator sit visually above the title (welcome-tour §2.4).
   - **Back:** `PopScope(canPop: page == 0, onPopInvokedWithResult: … previousPage)`. On slide 1 the pop goes through to Android and the app goes to the background. Nothing is saved (AC-6).
   - **Next** animates over `motionEmphasis` (instant with Remove animations). While a page animation runs, Next is ignored. The target page is computed from the settled `page.round()`, so a double tap moves exactly one slide (AC-13).
   - **Skip** and **Get started** call `completeTour()`. `AppGate` then swaps its child to the SMS explainer, which becomes the root, so the tour is not in the history and back from the SMS explainer leaves the app (welcome-tour §2.4, AC-11).
5. **Explainers + disclaimer** share one `ExplainerScaffold`: title, bullet points, a primary button with its description underneath, and a secondary button.
   - At text scale ≤ 1.3 the buttons are pinned at the bottom. Above 1.3 they move to the end of the scroll content (welcome-tour §9), decided by `MediaQuery.textScalerOf(context).scale(1) > 1.3`.
   - `SmsExplainerScreen`: **Allow SMS access** and **Not now** both `push` `NotificationsExplainerScreen`.
   - `NotificationsExplainerScreen`: both buttons `push` `DisclaimerScreen`.
   - `DisclaimerScreen` has one button, **I understand**. It calls `finish()` and then `Navigator.popUntil((r) => r.isFirst)`. The root is now `AppShell` with Home selected, and the Home hint shows (F-004).
   - **No skip and no other way forward** on the disclaimer. Its `PopScope` lets back go to the notifications explainer (AC-11).
   - **Double-tap guard:** a forward handler returns early when `ModalRoute.of(context)?.isCurrent != true`. The route is no longer current as soon as the next one is pushed, and `finish()` is idempotent (AC-13).
   - Back follows the normal route stack: disclaimer → notifications → SMS (root) → app to the background. The stage is still `explainers`, so reopening shows the SMS explainer, not the tour (AC-11, AC-12).
6. **No permissions (AC-7, AC-8, AC-9).**
   - No permission package is added. No `MethodChannel` or permission API is called. The manifest is untouched.
   - An automated guard fails if `pubspec.lock` contains a known permission package (`permission_handler*`, `flutter_local_notifications`, `telephony`, `another_telephony`, `sms_advanced`, `readsms`), or if `lib/` contains `requestPermission`, `Permission.`, `POST_NOTIFICATIONS` or `READ_SMS`. It also reads the main `AndroidManifest.xml` and checks that it has no `READ_SMS`, `RECEIVE_SMS` or `POST_NOTIFICATIONS`.
   - The **merged release manifest** is checked on a real build in T-125 [P].
7. **Copy.** Slide, explainer and disclaimer texts go in `core/copy/screen_copy.dart`. Button descriptions and hints go in `core/copy/help_copy.dart` (F-004). Both match **F-005 §5 as finally worded**. The Designer changed slide 4 (the "no ads" claim was removed, welcome-tour §2.2) and says F-005 §5 "is updated". The copy test uses whatever F-005 §5 says at build time (§9 Q1).

**Alternatives rejected**
- *A nested `Navigator` for onboarding*: it adds back-dispatch plumbing (`NavigatorPopHandler`) for a three-screen linear flow. The root navigator with `AppGate` swapping its home does the same with less code.
- *Router package (`go_router` with a redirect)*: that is the F-003 decision (no router in Phase 1).
- *Saving the current tour slide or which explainer buttons were tapped*: the feature doc explicitly says not to (§2.8).
- *Permission request "stubs" that call the platform and ignore the result*: forbidden by AC-7/AC-8. Phase 4 and Phase 5 add the real requests.

## 2. Files / modules
| Path (under `app/` unless marked) | Add / Change | What |
|---|---|---|
| `lib/domain/preferences/onboarding_stage.dart` | Add | `OnboardingStage` + `fromFlags`. Pure Dart. |
| `lib/data/preferences/onboarding_repository.dart` | Add | Read/write the two flags. |
| `lib/core/providers/preferences_providers.dart` | Change | `onboardingRepositoryProvider`. |
| `lib/features/onboarding/onboarding_provider.dart` | Add | `OnboardingNotifier`, `onboardingProvider`. |
| `lib/features/onboarding/app_gate.dart` | Add | Stage → first screen. |
| `lib/features/onboarding/tour/tour_screen.dart` | Add | `PageView`, back, buttons, guards. |
| `lib/features/onboarding/tour/tour_slide.dart`, `tour_visuals.dart`, `page_indicator.dart` | Add | Slide layout, 4 decorative cards (welcome-tour §2.2), indicator. |
| `lib/features/onboarding/explainers/explainer_scaffold.dart` | Add | Shared layout, pinned/scrolling button block. |
| `lib/features/onboarding/explainers/sms_explainer_screen.dart`, `notifications_explainer_screen.dart`, `disclaimer_screen.dart` | Add | The three screens. |
| `lib/core/copy/screen_copy.dart`, `help_copy.dart` | Change | F-005 copy. |
| `lib/app.dart` | Change | `home: const AppGate()`. |
| `test/domain/preferences/onboarding_stage_test.dart` | Add | Flag table. |
| `test/features/onboarding/*_test.dart` | Add | TC-005-01…-06, -08, -10, -13…-15, -18…-20, -22…-27, -30, -31. |
| `test/architecture/no_permissions_test.dart` | Add | TC-005-11 + the main-manifest part of TC-005-12. |

## 3. Data model / database changes
No database. Two bool preference keys in the shared store (F-002 plan §3): `onboarding.tour_seen` and `onboarding.finished`. Missing or unreadable values count as `false`. Nothing else is saved: not the current slide, and not the "Allow / Not now" answers.

## 4. Packages (latest stable, checked on pub.dev)
**None.** In particular no permission package (`permission_handler` etc.) is added in Phase 1 (AC-9). Real requests come in Phase 4 (SMS) and Phase 5 (notifications), each with its own package decision.

## 5. Tasks
| ID | Task | Covers AC | Depends on | Status |
|---|---|---|---|---|
| T-121 | **Onboarding state + gate.** `OnboardingStage`, `OnboardingRepository`, `onboardingProvider`, `AppGate`, `home: AppGate`. Tests: launch routing for the three saved states (+ the odd fourth combination); fresh store → tour slide 1, no bottom nav, no tab content; corrupt flags → tour, no crash; `completeTour`/`finish` idempotent; failing write → stage still advances this session; simulated restart (new `ProviderScope` on the same store) with each state. | AC-1, AC-12, AC-15 | T-102, T-108 (F-002), T-114 (F-003 shell is `home`) | Code review (2026-11-10; see §11 T-121) |
| T-122 | **Tour.** `TourScreen`, 4 slides with exact §5 copy and visual cards, indicator semantics, Next/Skip/Get started with tooltips/hints, back on slides, clamping at both ends, double-tap and swipe+Skip guards, TalkBack order. Tests: copy character for character incl. `₹40,000 ₹10,000 ₹5,000 ₹100 ₹24,900 ₹830`; Next ×3 and drag ×3 → slides 2,3,4 and indicator updates; back/drag right on 4 → 3; Skip from 1, 2, 3 and Get started → SMS explainer + `tour_seen` saved; back on slide 1 → pop passes through, nothing saved; double-tap Next → one slide; drag + Skip → SMS once; theme flip on slide 3 → still slide 3; at 2.0 on 360×640 every figure is on one line (each `₹…` substring's text-box spans a single line) and buttons reachable; 5 theme cases + accessibility helper; no `FirstTimeHintCard`. | AC-2, AC-3, AC-4, AC-5, AC-6, AC-13, AC-14 | T-121, T-116 (`NavTooltip`) | Code review (phase B1, 2026-11-10; see §11 B1) |
| T-123 | **Explainers + disclaimer.** `ExplainerScaffold` and the three screens with exact copy; button routing; back chain; `finish()` + `popUntil`; double-tap guards; pinned vs scrolled button block. Tests: both SMS buttons → notifications explainer (and no platform-channel call: a `TestDefaultBinaryMessenger` handler records any non-framework channel call, expected none); both notification buttons → disclaimer; I understand → Home with bottom nav and Home hint, `finished` saved, no Skip on the disclaimer; back disclaimer → notifications → SMS → pop passes through; restart → SMS explainer; finished → restart ×3 → Home; double-tap on every forward button → exactly one screen, one back returns; 5 theme cases × 1.0/2.0 + accessibility helper; reading order. | AC-7, AC-8, AC-10, AC-11, AC-12, AC-13, AC-14, AC-15 | T-122 | Code review (phase B1, 2026-11-10; see §11 B1) |
| T-124 | **No-permission guard.** `no_permissions_test.dart` (pubspec.lock packages, `lib/` API strings, main manifest permissions), with a probe proof (temporary `READ_SMS` string in a `lib/` file makes it fail; probe removed). | AC-9 | T-123 | Code review (phase B1, 2026-11-10; see §11 B1) |
| T-125 | **[P] Emulator verification F-005.** On emulator-5554 (API 37): fresh install → slide 1 (TC-005-01 device check); force-stop mid-tour → slide 1 (TC-005-07); every explainer button shows **no** system dialog, app info lists no SMS permission, notification setting unchanged (TC-005-09); `flutter build apk --release` merged manifest (`build/app/intermediates/merged_manifests/release/…/AndroidManifest.xml`) and `aapt dump permissions` → no `READ_SMS`/`RECEIVE_SMS`/`POST_NOTIFICATIONS` (TC-005-12); whole flow + restarts with the real plugin (TC-005-16, -17); predictive back on slide 1 and on the SMS explainer (TC-005-28); reinstall → flow again (TC-005-29); visual walk (TC-005-21). | AC-6, AC-7, AC-8, AC-9, AC-11, AC-12, AC-14 (device parts) | T-124; plugin build available (Owner Developer Mode, or PM accepts F-002 §7 probe) | To do |

## 6. Acceptance criteria coverage
TC IDs come from the Tester's draft `tests/F-005-welcome-tour-permission-explainers.md` (2026-11-05). They are proposals until the PM reconciles them at Gate 1.

| AC | Built in task | Proved by test cases |
|---|---|---|
| AC-1 Tour on first launch, no tabs | T-121 | TC-005-01, TC-003-27 |
| AC-2 Slide content exact, with visual | T-122 | TC-005-02, TC-005-26 |
| AC-3 Navigating the tour | T-122 | TC-005-03, TC-005-23 |
| AC-4 Get started → SMS, tour seen saved | T-122 | TC-005-04 |
| AC-5 Skip → SMS (not Home), tour seen saved | T-122 | TC-005-05 |
| AC-6 Leaving on slides saves nothing | T-122, T-125 | TC-005-06, TC-005-07 [P], TC-005-28 |
| AC-7 SMS explainer, no real permission | T-123, T-125 | TC-005-08, TC-005-09 [P], TC-005-31 |
| AC-8 Notifications explainer, no real permission | T-123, T-125 | TC-005-09 [P], TC-005-10 |
| AC-9 No permissions in manifests or code | T-124, T-125 | TC-005-11, TC-005-12 [P] |
| AC-10 Disclaimer finishes onboarding | T-123 | TC-005-13, TC-005-30 |
| AC-11 Back on explainers, resume at SMS | T-123, T-125 | TC-005-14, TC-005-17 [P], TC-005-28 |
| AC-12 Resume and never repeat | T-121, T-123, T-125 | TC-005-15, TC-005-16 [P], TC-005-17 [P], TC-005-27 |
| AC-13 One step per tap | T-122, T-123 | TC-005-18, TC-005-24 |
| AC-14 Themes, large text, accessibility | T-122, T-123, T-125 | TC-005-19, TC-005-20, TC-005-21, TC-005-25, TC-005-26 |
| AC-15 Storage failure is safe | T-121, T-123 | TC-005-22, TC-005-27 |
| (Reinstall shows the flow again, edge case) | T-125 | TC-005-29 [P] |

## 7. Edge cases & risks
| Case / risk | How it is handled |
|---|---|
| App killed mid-tour / mid-explainers | Nothing saved mid-tour, so the next launch is slide 1. Mid-explainers the stage is `explainers`, so the next launch is the SMS explainer. |
| Theme change during the tour | `PageController` state is in the `TourScreen` state, and a theme change only rebuilds, so the same slide stays (TC-005-25). |
| Swiping past slide 4 / right on slide 1 | `ClampingScrollPhysics`, so nothing happens and there is no glow. |
| Rapid swipe + Skip | `completeTour()` idempotent. `AppGate` swaps once (TC-005-24). |
| Double-tap on forward buttons | Page-animation guard (tour), `isCurrent` guard (explainers), idempotent notifier methods (TC-005-18). |
| ₹ figures splitting at 2.0 | Unicode line breaking does not break inside a numeric run (`₹24,900` is PR + NU/IS) under ICU rules. The test asserts each figure renders on one line. If any engine version breaks one, join with U+2060 WORD JOINER in the copy, so copy equality still holds visually and the change is noted in §11. |
| "Allow SMS access" does nothing visible | Expected in Phase 1. Its description tells the user that they can add spends themselves. Phase 4 replaces the handler. |
| Android 13+ notifications | No request, no manifest entry (AC-8). Phase 5. |
| Privacy copy must stay true | No network code exists (D-003). `INTERNET` is absent from the main and release manifests (F-002 TC-002-27). Any later network change is an Owner escalation. |
| Predictive back on slide 1 / SMS explainer | Both pops pass through to Android (root route, `canPop` true), so the system shows the "leave app" preview. Checked on the device in T-125. |
| TalkBack order | `OrdinalSortKey` per welcome-tour §2.4. The automated semantics-order test is TC-005-20. |
| Storage failure | Stage advances in memory. Home this session. The flow may repeat next launch (accepted by AC-15). Never blank: `AppGate` always has a screen for every enum value (exhaustive `switch`). |
| Hints during onboarding | Impossible by construction (hints live only inside `AppShell`). F-004 T-119 also proves it (TC-005-30). |
| Developer Mode off | All logic is tested with in-memory stores and simulated restarts. Only the device checks are [P]. |

## 8. Impact on existing features
- **F-003:** `AppGate` replaces `AppShell` as `MaterialApp.home`. Shell tests pump `AppShell` directly, or the app with a store that has `onboarding.finished = true`. The F-003 harness default must seed "finished", otherwise every shell test would land on the tour. Re-run all TC-003 automated cases. TC-003-07/-08 (always opens on Home) now depends on the finished flag.
- **F-004:** the Home hint must appear right after I understand (TC-004-14, TC-005-30). Re-run TC-004-09, -14.
- **F-002:** onboarding screens join the "every Phase 1 screen" matrix (contrast, tap targets, 2.0×). The `SystemBarsStyle` `builder` covers these app-bar-less pages (TC-002-31).
- **F-001:** TC-001-17 (no `<uses-permission>` in the main manifest) must still pass. This feature adds none. TC-001-06 holds (`OnboardingStage` is pure Dart).
- Re-run: full `flutter test`, `tool/check.ps1`, TC-001-06, -17, the F-003/F-004 cases above, and REGRESSION check 3.

## 9. Open questions
1. **(PM / Product Manager) Final slide 4 copy:** the Designer removed "no ads tracking your money" and says F-005 §5 is updated. As I read F-005 §5 today, it still holds the first-draft sentence. The copy test (TC-005-02) needs one agreed string. The Product Manager updates §5 before Gate 1.
2. **(CEO) Suggested additions** ("Replay welcome tour", Settings → Disclaimer opens the same screen read-only, the SMS "See an example" link) are **not** planned. The disclaimer row reuse would be about one small task if approved, since `DisclaimerScreen` can take a `readOnly` flag.
3. **(PM) Merged release manifest check** needs a release build, which compiles fine without signing config in debug-signed form. Confirm that the default debug signing for `flutter build apk --release` is acceptable for this check. Release signing is Phase 7.

## 10. Project Manager review *(Gate 1 — cross-check of doc + plan + test cases)*
**Verdict:** **Approved** (Project Manager, 2026-11-05). Condition: the test-case updates in point 1 are done in **T-126** before T-122 starts. No permission is requested and none is added, so nothing needs the Owner.

Cross-check:
- [x] Every AC in the feature doc is covered by a task in this plan (AC-1…AC-15 → T-121…T-125, §6)
- [x] Every AC has at least one test case in the test file (TC-005-01…-31)
- [x] Edge cases in the doc appear in both the plan and the test cases (killed mid-tour/mid-explainers, theme change, overscroll, swipe + Skip, ₹ figures at 2.0, Allow does nothing, Android 13+, reinstall, privacy copy, predictive back, TalkBack)
- [x] Approach follows `docs/STANDARDS.md` (`OnboardingStage` pure Dart, exhaustive `switch` in `AppGate`, no permission package, guard test, copy in `core/copy/`)
- [x] Latest stable versions / modern APIs used (`PopScope`, `OrdinalSortKey`, `ClampingScrollPhysics`, no new package)

| # | Point | Type | Resolution |
|---|---|---|---|
| 1 | **Test cases to update (Tester).** **TC-005-02**: write all four slide literals out; slide 4 body is final: `Your bank SMS are read on this phone and never leave it. No login, and nothing is uploaded.` (no ads mention). The visual = the decorative card of welcome-tour §2.2 (`ExcludeSemantics`). **§2.3**: "slide 4 not final" and "visual not specified" resolved; "finished but tour seen missing → Home" confirmed (F-005 §2.8 table now has the row; TC-005-27 as written). **[P] note**: drop the Developer Mode wording (D-029). Header: plan exists. | Must fix (Tester, T-126; blocks T-122) | Scheduled as T-126. |
| 2 | **Slide 4 copy (§9 Q1).** F-005 §5 already holds the Designer's string (checked today; the change-history line is there). The copy test uses it. The suggestion "confirm no ads / no analytics" stays with the CEO; nothing in Phase 1 depends on it. | Resolved | — |
| 3 | **Inconsistent saved state.** `finished = true` with `tour_seen` missing or unreadable → Home ("finished" wins), as the plan's `fromFlags` already does. Showing the tour again to someone who finished onboarding would be worse than skipping a flag. | Resolved | F-005 §2.8 edited. |
| 4 | **Release-manifest check with debug signing (§9 Q3).** Approved for TC-002-27 / TC-005-12: permissions in the merged manifest do not depend on the signing key. The release APK built this way is a test artefact only: never installed on a real phone or shared, and `build/` stays ignored. Real release signing is Phase 7. | Resolved | — |
| 5 | **Suggested additions (§9 Q2)** stay out of scope (CEO). | Resolved | — |
| 6 | **"I understand" → Home transition.** With `finish()` + `popUntil(isFirst)`, Home appears under the disclaimer's reverse page transition. Check in T-123 that it reads as the fade welcome-tour §5 asks for; if not, give the onboarding routes a fade-only transition. Not blocking. | Nice to have (Developer, T-123) | Noted in TASKS T-123. |
| 7 | **Rule for buttons without a description.** Get started, Not now and I understand carry a screen-reader hint only; F-004 §2.3 now states that a long-press tooltip is required only for icon-only controls and tabs, so the F-005 §5 table is complete as written. | Resolved | F-004 doc edited. |

## 11. Implementation notes *(Developer, filled in during the build)*
Deviations from the plan and why (each approved by the Project Manager).

### Phase B1 (T-122, T-123, T-124), Developer B, 2026-11-10
Built out of the planned order on the Orchestrator's instruction: Developer A is editing the preference store, `app.dart`, `main.dart`, help and Settings for T-109/T-118 at the same time (D-033, separate files). So T-122/T-123 were built **before T-121**, behind a small interface, and nothing is wired into the app yet.

**What was built**
- `lib/features/onboarding/onboarding_actions.dart`: `OnboardingActions` (`completeTour()`, `finish()`, both must be idempotent) and `onboardingActionsProvider`, which throws until it is overridden. This is the plug-in point for T-121: the screens only report what the user did; the gate decides what shows next.
- `lib/features/onboarding/tour/`: `tour_screen.dart` (`PageView` with clamping physics and no overscroll indicator, `PopScope` back, Next/Skip/Get started, guards, `OrdinalSortKey` reading order), `tour_slide.dart` (`TourSlideData` enum + slide layout), `tour_visuals.dart` (the four decorative cards, `ExcludeSemantics`, text capped at 1.3×, 200 dp / 160 dp above 1.3×), `page_indicator.dart` (ticks + `Slide n of 4`).
- `lib/features/onboarding/explainers/`: `explainer_scaffold.dart` (pinned button block up to 1.3×, scrolled above), `sms_explainer_screen.dart`, `notifications_explainer_screen.dart`, `disclaimer_screen.dart` (`finish()` + `popUntil(isFirst)`). No permission API, package, channel or manifest entry.
- `lib/core/copy/onboarding_copy.dart`: all F-005 §5 copy plus the visual-card texts.
- Tests: `test/features/onboarding/welcome_tour_test.dart` (25), `test/features/onboarding/explainers_test.dart` (19), `test/architecture/no_permission_request_test.dart` (3); helper `test/features/onboarding/onboarding_host.dart` (fake actions, a fake gate standing in for `AppGate`, route counter, platform-message recorder). `tool/check.ps1`: ALL CHECKS PASSED, 163 tests.

**Deviations (for the Project Manager)**
| # | Item | Why |
|---|---|---|
| B1-1 | **Built before T-121; screens talk to `OnboardingActions`, not to `onboardingProvider` directly.** T-121's notifier implements the interface and `onboardingActionsProvider` returns it (`ref.watch(onboardingProvider.notifier)`). | Parallel work without touching A's files; the screens are tested with a fake. |
| B1-2 | **Copy in a new `core/copy/onboarding_copy.dart`** (one class for screen and help strings), not in `screen_copy.dart` / `help_copy.dart` as §1 step 7 says. | Those two files are being edited for T-109/T-118. They can be merged later if the PM prefers; T-119's `copy_tables_test.dart` should add the F-005 strings from this file. |
| B1-3 | **Second double-tap guard on the explainers: a screen ignores taps for `kDoubleTapTimeout` (300 ms) after it appears**, on top of the plan's `isCurrent` check. The `isCurrent` check alone does not work: a pushed route takes taps while it slides in, so the second tap of a double tap on Allow SMS access landed on Turn on notifications (same place) and advanced two screens; the same happened from Get started onto the SMS explainer. Same idea as review M2 (help sheet scrim). | AC-13. TC-005-18 caught it. |
| B1-4 | **Next also has a 300 ms cooldown** besides the "ignored while the page animates" rule, and Get started is ignored while a Next is in progress. With Remove animations on, the page jumps at once, so the animation guard alone let a double tap move two slides; and the second tap of a double tap on Next (slide 3) could land on Get started. TC-005-18 runs with animations on and off. | AC-13. |
| B1-5 | **No overscroll indicator on the tour `PageView`** (`ScrollConfiguration(... overscroll: false)`). `ClampingScrollPhysics` alone still shows the Material 3 stretch at both ends, which welcome-tour §2.4 forbids. This also removes the stretch on the slides' own vertical scroll. | Design §2.4. |
| B1-6 | **Explainer button descriptions are read as the button's hint** (`semanticsHint`) and the visible caption is excluded from semantics, so TalkBack reads it once, with the button. Get started, Not now and I understand carry a hint only; Next and Skip use `NavTooltip` (§10 point 7). | F-004 §2.3, TC-005-20. |
| B1-7 | **No U+2060 word joiner in the slide 2 body.** TC-005-26 passes at 2.0 on 360 and 320 dp without it (ICU does not break inside `₹24,900`), so the copy stays character for character equal to F-005 §5. | Plan §7 says to add it only if a figure breaks. |
| B1-8 | **Tests that need the saved state, the real gate or Home are not written yet:** TC-005-01 (first frame, no tab content), -04/-05 (flag saved), -06/-14 (restart part), -13 (real Home with bottom navigation and Home hint), -15, -22, -27, and TC-005-18's "I understand → Home → back". For each of these B1 has an interim test under the same ID with the fake (D6 rule): it checks the screen shown, that `completeTour()` / `finish()` was reported exactly once, and the back behaviour. The Tester's exact-title tests come with T-121. | Need T-121 and `app.dart`. |
| B1-9 | **Test file names** follow the Tester's proposals (`welcome_tour_test.dart`, `explainers_test.dart`, `no_permission_request_test.dart`), not plan §2's `*_test.dart` / `no_permissions_test.dart`. I did not edit `tests/F-005…` (instruction); the Tester adds the files to the case rows. | — |
| B1-10 | **The guard (T-124) is broader than §1 step 6:** it also bans `RECEIVE_SMS`, `permission_handler`, `flutter_local_notifications` and `telephony` in `lib/`, and checks every `android/app/src/*/AndroidManifest.xml` (main, debug, profile) for the three permissions. Probes: a temporary `lib/` file with `READ_SMS` and a temporary manifest with `POST_NOTIFICATIONS` each made it FAIL; both removed. | AC-9. |

**For T-121 (notes, not done here)**
- `AppGate` should switch with `AnimatedSwitcher` (fade + 16 dp rise, `motionBase`; instant with Remove animations) for Skip / Get started, since the gate swaps the root page instead of pushing a route.
- **Double tap on I understand:** the disclaimer's reverse transition ignores pointers, so the second tap of a double tap goes through to Home, where the bottom navigation sits near the button. Suggest the gate ignores pointers on Home for `kDoubleTapTimeout` after switching to `finished` (or the disclaimer stays absorbing), and a TC-005-18 test with the real Home.
- The F-003/F-004 harness must seed "onboarding finished" (§8).
- Nice to have §10 point 6 (I understand → Home as a fade) is still open: the theme's `FadeForwardsPageTransitionsBuilder` reverse transition is used as is.


**PM Gate 3 (2026-11-10, `docs/reviews/code-phase-1.md` §Re-review … F-005 phase B1):** B1-1 and B1-3…B1-10 approved. B1-2 is interim: at T-121 the strings move into `HelpCopy` / `ScreenCopy` (C3). The double tap on I understand is decided (D-044): `AppGate` absorbs pointers on Home for `kDoubleTapTimeout` after a session change to finished (C4). T-121 conditions C3–C6 are in the review.

### T-121 (onboarding state, gate, wiring), Developer B, 2026-11-10
Meets the Gate 3 conditions C3–C6 and Nice to have N8 from `docs/reviews/code-phase-1.md` §Re-review … F-005 phase B1.

**What was built**
- `lib/domain/preferences/onboarding_stage.dart`: `OnboardingStage` + `fromFlags` ("finished" wins).
- `lib/data/preferences/onboarding_repository.dart`: reads and saves `onboarding.tour_seen` / `onboarding.finished`; wrong-type or unreadable values count as not set; never throws. Keys in `PreferenceKeys` and `allowList`; `onboardingRepositoryProvider` in `preferences_providers.dart` (C5).
- `lib/features/onboarding/onboarding_provider.dart`: `OnboardingNotifier implements OnboardingActions`; `completeTour()` only from `tour`, `finish()` only from `explainers`, each sets the state first and then saves (unawaited), so both are idempotent and a failed save still advances this session. `onboardingActionsProvider` now returns the notifier (it moved here from `onboarding_actions.dart`, which keeps only the interface) (C5).
- `lib/features/onboarding/app_gate.dart`: exhaustive `switch` on the stage → `TourScreen` / `SmsExplainerScreen` / `AppShell`. An `AnimatedSwitcher` (fade + 16 dp rise, `motionBase`, instant with Remove animations) swaps the root page, which also gives I understand → Home its fade (§10 point 6). When the stage changes to `finished` during the session, Home is wrapped in `AbsorbPointer` for `kDoubleTapTimeout` (D-044, C4). `app.dart`: `home: const AppGate()`. `main.dart` unchanged (the store is already opened before `runApp`).
- C3: all `onboarding_copy.dart` strings moved, help strings (8 hints/descriptions) to `HelpCopy`, the rest (titles, labels, slide texts, `slidePosition`, card texts) to `ScreenCopy`; the file is deleted.
- N8: `lib/core/widgets/tap_cooldown.dart` (`TapCooldown`: `start({onEnd})`, `isActive`, `dispose()`), used by all four guards: the sheet route (D-031), the tour's Next, the explainer buttons and the gate.
- Harness (C5): `pumpBudgetApp` and `restartApp` take `onboarded` (default `true`) and wrap the store in `OnboardedStore` (`test/helpers/pump_app.dart`), which answers the two onboarding flags as `true` and passes everything else, including failures, to the real store. All F-002/F-003/F-004 tests are green unchanged.
- Tests (C6): `test/features/onboarding/onboarding_routing_test.dart` (10, the Tester's exact titles: TC-005-01, -04, -05, -06, -13, -14, -15, -18 (I understand with the real Home, animations on and off), -22, -27), `test/features/onboarding/onboarding_provider_test.dart` (3), `test/data/preferences/onboarding_repository_test.dart` (4), `test/domain/preferences/onboarding_stage_test.dart` (2). `tool/check.ps1`: ALL CHECKS PASSED, **182 tests**. `flutter build apk --debug`: OK.
- Probe: with the gate's `AbsorbPointer` disabled, the new TC-005-18 test FAILS (the second tap selects a tab: `Settings` instead of `Home`); restored.

**Deviations (for the Project Manager)**
| # | Item | Why |
|---|---|---|
| T121-1 | **Harness "seeds" finished by wrapping, not by writing** (`OnboardedStore`). | Several F-002/F-004 tests use `FailingPreferencesStore` (`readFails` / `writeFails`) or compare the store's exact contents; a real write would fail or show up there. The wrapper keeps those tests' store behaviour for every other key. |
| T121-2 | **The B1 interim tests with fakes keep their checks but are renamed** with "(screen level)" (TC-005-04, -05, -06, -13, -14), so each Tester title exists exactly once, in `onboarding_routing_test.dart`. | Avoid two tests with the same title (D6 rule allows several tests per ID). |
| T121-3 | **`OnboardingActions` methods stay `void`**; the notifier saves with `unawaited`. Tests let the write finish with a microtask (`Future.delayed(Duration.zero)`) or `pumpAndSettle`. | The screens never wait for a save (AC-15: state first). |
| T121-4 | **`TapCooldown` lives in `core/widgets/`** and also replaced the sheet route's own timer (`budget_sheet.dart`); TC-004-17's two tests stay green. | N8: one place for all four guards. |
| T121-5 | **TC-005-16 (integration test with the real plugin) is not written:** it is [P] and needs the emulator, which this run must not use. It belongs to T-125. | — |
| T121-6 | During the 200 ms gate swap the outgoing screen (e.g. the tour) is still in the tree under the incoming one; taps go to the incoming screen (top of the stack) and the outgoing `PopScope` is gone when the swap ends. | Accepted as is; not observable in tests. |

**For T-119:** the F-005 strings are now in `HelpCopy` / `ScreenCopy`, ready for `copy_tables_test.dart`.


**PM Gate 3 (2026-11-10, `docs/reviews/code-phase-1.md` §T-121):** T121-1…T121-6 approved. T121-5: TC-005-16 moves to T-125. T121-6: Nice to have N9 (outgoing gate page excluded from pointers and semantics) is in T-132.

**T-132 (Developer, 2026-11-11): N9 done.** `AppGate`'s `AnimatedSwitcher` has a `layoutBuilder` that wraps each outgoing page in `IgnorePointer`, `ExcludeSemantics`, no focus and Back passed through (`RootPageScope(current: false)`); the page keeps its key so its state survives. Test in `test/features/onboarding/app_gate_test.dart`. No deviation.

**PM Gate 3 (2026-11-11):** T-132 N9 (`AppGate` `layoutBuilder`) approved. Nice to have: give its test its own case ID (it is titled TC-005-18, the Home tap guard).

**T-125 emulator verification (Developer, 2026-11-11; evidence `docs/reviews/emulator-phase-1/`, details in the T-125 row of `docs/TASKS.md`):** new `app/integration_test/onboarding_flow_test.dart` (`TC-005-16 onboarding flow persists with the real preferences plugin`) passed on emulator-5554 with the real plugin (D-063). TC-005-07, -09, -17, -21, -28, -29 and REGRESSION check 9 Pass. **TC-005-12 part 2 Partial:** the release APK dump shows no INTERNET, SMS or notification permission, only the androidx.core `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (see plan F-002 section 11, T-110). `dumpsys package` on the debug build lists no READ_SMS, RECEIVE_SMS or POST_NOTIFICATIONS and no system dialog ever took focus. No app code changed.
