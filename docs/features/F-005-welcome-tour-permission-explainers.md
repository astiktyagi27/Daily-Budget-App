# F-005: Welcome tour & permission explainers (UI only)

| | |
|---|---|
| **Phase** | 1 |
| **Status** | Done |
| **Plan** | [`plans/F-005-welcome-tour-permission-explainers.md`](../../plans/F-005-welcome-tour-permission-explainers.md) |
| **Test cases** | [`tests/F-005-welcome-tour-permission-explainers.md`](../../tests/F-005-welcome-tour-permission-explainers.md) |
| **Tasks** | T-121 … T-125 (`docs/TASKS.md`) |

## 1. What it is *(Product Manager)*
What a new user sees the very first time they open the app:
- a short **welcome tour** of 4 slides that explains the daily-budget idea;
- an **SMS explainer** and a **notifications explainer** that say why each permission is needed and that data never leaves the phone;
- a **disclaimer**: one bank account only, credit cards not tracked, detection may need correcting.

The app remembers when this has been done, so it shows only once. This feature is **UI only**. The buttons on the explainer screens move to the next screen and **do not request any real Android permission**, and the manifest gets no new permissions. The real SMS request comes in Phase 4 and the notifications request in Phase 5. Bank selection and salary entry, which come between these screens in the final onboarding (README §3.1), are added in Phase 2.

**User stories:**
- As a **new user**, I want a quick explanation of the daily budget before I start so that I understand what the app will do for me.
- As a **privacy-conscious user**, I want to know exactly why the app wants my SMS and that nothing leaves my phone before I'm asked, so that I can trust it.
- As a **returning user**, I want the tour to never show again once I've finished or skipped it.

## 2. How it behaves *(Product Manager)*
Layout, illustrations and button styles are **per design system** (`docs/design/design-system.md`). Copy is in section 5.

1. **First launch** (fresh install or cleared data) opens **tour slide 1 of 4**, before any tab is shown.
2. **Tour slides:**
   1. **The idea.** "Spend a little each day".
   2. **How it's worked out.** A worked example with real numbers:
      - Salary ₹40,000 − rent ₹10,000 − EMI ₹5,000 − subscription ₹100 = ₹24,900 to spend.
      - ₹24,900 ÷ 30 days = **₹830 a day**.

      This is fixed text, not calculated. The budget engine is Phase 2.
   3. **Saving.** Spend less and the rest goes to your savings pot. Overspend and you choose whether to cover it from savings (D-005).
   4. **Privacy.** Everything stays on your phone, with no login and no cloud (D-003).
3. **Moving through the tour.**
   - **Next** (slides 1–3) or swiping left moves forward. Swiping right or Android back moves to the previous slide.
   - A page indicator shows the position ("1 of 4" for screen readers).
   - **Skip** is on slides 1–3. Slide 4 shows **Get started** instead of Next.
   - **Get started** on slide 4, or **Skip** on any slide, saves "tour seen" and opens the **SMS explainer**. Skipping the tour does not skip the explainers or disclaimer, because those set expectations the user must see.
   - Android back on slide 1 leaves the app (to the background). Nothing is saved, so the tour starts again at slide 1 next time.
4. **SMS explainer.**
   - Title, three short points (why it's needed, only your bank's SMS are read, nothing leaves the phone), and two buttons: **Allow SMS access** and **Not now**.
   - In Phase 1 **both buttons go to the notifications explainer**. No system permission dialog appears.
5. **Notifications explainer.**
   - Title, what the notifications are (80% warning, over-budget alert, end-of-day summary), that they are optional and can be changed in Settings later, and two buttons: **Turn on notifications** and **Not now**.
   - In Phase 1 **both buttons go to the disclaimer**. No system dialog appears.
6. **Disclaimer.**
   - Title and three points: one bank account only; credit cards not tracked; automatic detection may need correcting, and you can edit any transaction.
   - One button: **I understand**. There is no skip. Tapping it saves "onboarding finished" and opens **Home** (F-003). The first-time hint then appears there (F-004).
7. **Back on the explainers.**
   - Back on the notifications explainer returns to the SMS explainer, and back on the disclaimer returns to the notifications explainer.
   - Back on the SMS explainer leaves the app. The tour is not shown again because it was already seen.
8. **Remembering progress** (shared preferences store with F-002/F-004):

   | Saved state at launch | App opens on |
   |---|---|
   | Nothing saved (fresh) | Tour slide 1 |
   | Tour seen, onboarding not finished | SMS explainer |
   | Onboarding finished | Home |
   | Onboarding finished, but "tour seen" missing or unreadable | Home ("finished" wins; Gate 1) |

   Which explainer buttons were tapped is **not** saved in Phase 1, since no real permission is involved. Closing mid-explainers restarts at the SMS explainer.
9. **No bottom navigation** is visible during the tour and explainers. These are full-screen pages.

**Example:** the Owner installs the app and sees "Spend a little each day". They tap Next and read the ₹830-a-day example, then tap **Skip** on slide 3. The SMS explainer appears. They tap **Not now**, then **Not now** again on notifications, then **I understand**. Home opens with its tip. They close and reopen the app, and it goes straight to Home.

## 3. Acceptance criteria *(Product Manager)*
"Small phone", "all four themes" and "every Phase 1 screen" are as defined in F-002 section 3.

| ID | Given / When / Then |
|---|---|
| AC-1 | **Tour on first launch.** Given a fresh install (or cleared app data), when the app is opened, then tour slide 1 of 4 is shown, no bottom navigation is visible, and no tab content is shown first. |
| AC-2 | **Slide content.** Given the tour, when the Tester views slides 1–4, then each shows exactly the title and body text from section 5 (character for character), including slide 2's figures ₹40,000, ₹10,000, ₹5,000, ₹100, ₹24,900 and ₹830 in Indian grouping, and each slide has an illustration/visual per design system. |
| AC-3 | **Navigating the tour.** Given slide 1, when the user taps Next three times (and, separately, swipes left three times), then slides 2, 3, 4 appear in order and the page indicator updates each time; when the user then swipes right or presses back on slide 4, then slide 3 appears. Slides 1–3 show Next and Skip; slide 4 shows Get started and no Skip. A screen reader announces the position as "<n> of 4". |
| AC-4 | **Finish the tour.** Given slide 4, when the user taps Get started, then the SMS explainer appears and "tour seen" is saved. |
| AC-5 | **Skip the tour.** Given any of slides 1–3, when the user taps Skip, then the SMS explainer appears (not Home) and "tour seen" is saved. |
| AC-6 | **Leaving on slide 1 saves nothing.** Given slide 1 on a fresh install, when the user presses Android back, then the app goes to the background without crashing; and when the app is force-stopped and reopened, then slide 1 is shown again. The same holds if the app is force-stopped on slides 2–4 before Get started or Skip. |
| AC-7 | **SMS explainer, no real permission.** Given the SMS explainer, when the user taps **Allow SMS access** (and separately **Not now**), then the notifications explainer appears, **no** system permission dialog is shown, and the Android app info screen lists no SMS permission for the app. |
| AC-8 | **Notifications explainer, no real permission.** Given the notifications explainer, when the user taps **Turn on notifications** (and separately **Not now**), then the disclaimer appears, **no** system permission dialog is shown (including on Android 13+, where notifications need a runtime permission), and the app's notification setting in Android is unchanged. |
| AC-9 | **No permissions in the manifest.** Given the built app, when the Tester inspects the main `app/android/app/src/main/AndroidManifest.xml` and the merged release manifest, then there is no `READ_SMS`, `RECEIVE_SMS` or `POST_NOTIFICATIONS` permission (F-001 AC-8 still holds for the main manifest), and no Dart code calls a permission-request API. |
| AC-10 | **Disclaimer finishes onboarding.** Given the disclaimer, when the user taps **I understand**, then Home is shown with the bottom navigation (F-003) and its first-time hint (F-004), and "onboarding finished" is saved. The disclaimer has no Skip and no other way forward. |
| AC-11 | **Back on explainers.** Given the disclaimer, when the user presses back, then the notifications explainer appears; pressing back again shows the SMS explainer; pressing back again sends the app to the background, and reopening it (after force-stop) shows the SMS explainer, not the tour. |
| AC-12 | **Resume and never repeat.** Given "tour seen" is saved but onboarding is not finished, when the app is force-stopped and reopened, then the SMS explainer is shown. Given onboarding is finished, when the app is force-stopped and reopened (tested 3 times), then Home is shown every time and the tour and explainers never appear. |
| AC-13 | **One step per tap.** Given any forward button (Next, Get started, Skip, Allow SMS access, Not now, Turn on notifications, I understand), when the user double-taps it quickly, then the app advances exactly one screen, and one back press returns to the previous screen (or, from Home, leaves the app). |
| AC-14 | **Themes, large text, accessibility.** Given every tour slide, both explainers and the disclaimer, when shown in all four themes at text scale 1.0 and 2.0 on a small phone, then F-002 AC-12, AC-13 and AC-14 pass, all text can be scrolled into view, the main buttons stay reachable, and every control has the label and description/tooltip from section 5 (F-004 AC-5). |
| AC-15 | **Storage failure is safe.** Given the preferences store cannot be written, when the user finishes the flow, then Home is still shown this session without crash or error; on next launch the flow may show again (acceptable), but the app never gets stuck on a blank screen. |

## 4. Edge cases *(Product Manager)*
- **App killed mid-tour** (by the user or the system): next launch is slide 1. Mid-explainers it is the SMS explainer (section 2 step 8).
- **Theme change during the tour** (Auto + system switch): the current slide stays and re-renders in the new theme.
- **Swiping past slide 4:** nothing happens, so overscroll doesn't skip the explainers. Swiping right on slide 1 does nothing.
- **Rapid swipe plus tap on Skip:** the result is the SMS explainer exactly once (AC-13).
- **Text scale 2.0 on 360 × 640 dp:** slide 2's arithmetic lines may wrap, but each figure stays whole. "₹24,900" never splits across lines. The illustration may shrink or scroll away so text and buttons fit.
- **"Allow SMS access" does nothing visible in Phase 1:** expected and documented. In Phase 4 the same button will open the real system dialog. The Phase 4 doc must cover denied, "don't ask again" and the explainer reappearing.
- **Android 13+ notifications:** no request in Phase 1 (AC-8). Phase 5 handles the real `POST_NOTIFICATIONS` request.
- **User reinstalls:** the flow shows again. Expected (no cloud, D-003).
- **Privacy copy must stay true:** the screens say data never leaves the phone. That remains true only while the app makes no network calls (D-003, STANDARDS §8). Any later change to it is an Owner escalation.
- **Back gesture (predictive back) on slide 1 or the SMS explainer:** the preview shows the app leaving, not a blank page.
- **TalkBack:** reading order on each slide is title, body, page position, then buttons. Swiping between slides isn't required for TalkBack users, because Next and Skip are reachable.
- **Plugin build environment:** Windows Developer Mode is not needed (D-029). If the plugin build fails for an environment reason, the device restart parts of AC-4–AC-6 and AC-10–AC-12 are **Blocked**, not failed.

## 5. Help text & copy *(Product Manager, finalised by Designer)*
| Control | Label | Description / tooltip |
|---|---|---|
| Slide 1 | `Spend a little each day` | `Daily Budget App turns your monthly money into one simple number: what you can spend today.` |
| Slide 2 | `Your daily budget, worked out` | `Salary ₹40,000 − rent ₹10,000 − EMI ₹5,000 − subscription ₹100 = ₹24,900 to spend. Over a 30-day month, that's ₹830 a day.` |
| Slide 3 | `Saved days add up` | `Spend less than your daily budget and the rest goes into your savings pot. Overspent? You choose whether to cover it from savings.` |
| Slide 4 | `Private by design` | `Your bank SMS are read on this phone and never leave it. No login, and nothing is uploaded.` |
| Page indicator | — | Screen reader: `Slide <n> of 4` |
| Next | `Next` | Tooltip/hint: `Go to the next slide` |
| Skip | `Skip` | Tooltip/hint: `Skip the tour and continue setup` |
| Get started | `Get started` | Hint: `Finish the tour and continue setup` |
| SMS explainer title | `Read your bank SMS` | — |
| SMS explainer points | — | `To track spends for you, the app reads the SMS your bank sends when money moves.` · `Only your bank's messages are read. OTPs, personal chats and other senders are ignored.` · `Everything stays on this phone. Nothing is uploaded or shared.` |
| Allow SMS access | `Allow SMS access` | Description under button: `You can still add spends yourself if you say no.` |
| Not now (SMS) | `Not now` | Hint: `Continue without SMS access for now` |
| Notifications explainer title | `Get gentle nudges` | — |
| Notifications points | — | `A heads-up when you've used 80% of today's budget.` · `An alert if you go over.` · `An end-of-day summary of what you saved or overspent.` · `Optional. You can change this anytime in Settings.` |
| Turn on notifications | `Turn on notifications` | Description under button: `Notifications are created on your phone. Nothing is sent anywhere.` |
| Not now (notifications) | `Not now` | Hint: `Continue without notifications` |
| Disclaimer title | `Before you start` | — |
| Disclaimer points | — | `The app tracks one bank account.` · `Credit card spends are not included.` · `Automatic detection can get things wrong sometimes. You can edit any transaction or category.` |
| I understand | `I understand` | Hint: `Finish setup and open the app` |

Note (resolved 2026-11-05): the Owner has not decided on ads, so no screen mentions ads or analytics. Privacy copy states only what is true under D-003: data stays on the phone, no login, nothing is uploaded.

## 6. Out of scope
- Real SMS and notification permission requests, and denied / "don't ask again" handling (Phases 4 and 5).
- Bank selection, salary entry and month setup screens in the onboarding flow (Phase 2).
- Saving the user's "Allow / Not now" answers (meaningful only once real requests exist).
- Re-opening the tour or disclaimer from Settings (the Disclaimer row is a placeholder in F-003; see Suggested additions).
- Slide animations beyond basic page transitions, and Lottie/animated illustrations (Phase 6).
- Calculating slide 2 from real data (Phase 2 budget engine).

## 7. How it works — technical *(Developer, filled in when the feature is Done)*
- **What was built:** the first-run flow, UI only. A four-slide welcome tour (Next, Skip, Get started), the SMS and notification explainers (Allow … / Not now, both just move on), and the disclaimer ("I understand" finishes onboarding). `AppGate` decides the first screen from two saved flags and swaps the root page with a fade. No real permission is requested anywhere. Built in T-122 … T-125 (phase B1: T-122, T-123, T-124; then T-121), verified on the emulator in T-125 and T-230. Gate 4 passed 2026-11-11 (32 of 32 cases).
- **Main files** (`app/lib/`): `features/onboarding/app_gate.dart`, `onboarding_provider.dart` (`OnboardingNotifier`), `onboarding_actions.dart` (interface the screens talk to); `tour/` (`tour_screen.dart`, `tour_slide.dart`, `tour_visuals.dart`, `page_indicator.dart`); `explainers/` (`explainer_scaffold.dart`, `sms_explainer_screen.dart`, `notifications_explainer_screen.dart`, `disclaimer_screen.dart`); `domain/preferences/onboarding_stage.dart`; `data/preferences/onboarding_repository.dart`; `core/widgets/tap_cooldown.dart`; copy in `HelpCopy` and `ScreenCopy`. `app.dart` uses `home: const AppGate()`.
- **Data stored:** two booleans in `shared_preferences`, `onboarding.tour_seen` and `onboarding.finished`. "Finished" wins over everything; an unreadable value counts as not set. The user's Allow / Not now answers are not saved (nothing is requested yet).
- **Decisions applied:** D-044 (`AppGate` absorbs pointers on Home for 300 ms after onboarding finishes, so the second tap of a double tap on "I understand" cannot hit a tab), D-031 (guard timing idea reused), D-063 (`integration_test`, TC-005-16), D-064 (release permission wording, TC-005-12), D-029 and D-030 as for F-002.
- **Deviations from the plan** (plan section 11, approved B1-1 … B1-10 and T121-1 … T121-6): screens report to `OnboardingActions`, not to the provider directly, so they could be built before the gate; a 300 ms cooldown after each explainer appears and on Next, with Get started ignored while a Next is in progress (a double tap otherwise skipped two screens, caught by TC-005-18); no overscroll stretch on the tour `PageView`; explainer descriptions are read as the button hint; no word joiner in the slide 2 body (the figure does not break at 2.0 on 360 and 320 dp); copy moved to `HelpCopy` and `ScreenCopy` at T-121 (C3); the test harness seeds "finished" by wrapping the store (`OnboardedStore`), not by writing; `OnboardingActions` methods are `void` and saves are not awaited (state first, AC-15); the permission guard also bans `RECEIVE_SMS`, `permission_handler`, `flutter_local_notifications`, `telephony` and checks all manifests; `TC-005-32` (AppGate hides the outgoing screen and ignores back during the swap, renamed from TC-005-18 in T-228).
- **How it is tested:** 32 cases TC-005-01 … -32 in `tests/F-005-welcome-tour-permission-explainers.md`, all Pass. Automated in `app/test/features/onboarding/` (`welcome_tour_test.dart`, `explainers_test.dart`, `onboarding_routing_test.dart`, `onboarding_provider_test.dart`, `app_gate_test.dart`), `app/test/data/preferences/onboarding_repository_test.dart`, `app/test/domain/preferences/onboarding_stage_test.dart`, `app/test/architecture/no_permission_request_test.dart` (AC-9) and `app/integration_test/onboarding_flow_test.dart` (TC-005-16, real plugin). Emulator: release APK permissions, 2.0x text scale on every screen (28 screenshots), force-stop and fresh install. The double-tap guard was proven by a probe (guard removed, the test fails).
- **Depends on / used by:** depends on F-002 (theme, components, store), F-003 (the shell it hands over to) and F-004 (hints, Next and Skip tooltips, button hints). Phases 4 and 5 replace the explainer buttons' "just move on" with the real permission requests and add the saved answers.
- **Known limitations:**
  - No real permission request exists yet, and the Allow / Not now answers are not stored.
  - The tour cannot be replayed and the Disclaimer row in Settings is a placeholder (suggested additions in this document).
  - During the 200 ms gate swap the outgoing screen is still under the incoming one; taps go to the incoming screen (accepted, not observable).
  - TalkBack was not part of this feature's cases (none Blocked-needs-human); the reading order and hints are proven by widget tests (TC-005-20).
  - Designer Nice to have items: N3 at 2.0x the tour body is cut above the pinned Next button with no cue that it scrolls (T-235); N5 the ledger in tour slide 2 uses only the left half of the card at 2.0x (T-237). All 50 screenshots passed the Designer's review with no Must fix.

## 8. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-05 | First version of the spec | Product Manager |
| 2026-11-05 | §5 finalised by Designer (`docs/design/screens/welcome-tour.md`): slide 4 body no longer claims "no ads" (Owner has not decided) and now reads "No login, and nothing is uploaded." All other copy unchanged. | Designer |
| 2026-11-05 | Gate 1 reconciliation (PM): §2.8 table adds the inconsistent state "finished but tour seen missing" → Home; Developer Mode edge case replaced (D-029); slide 4 copy confirmed final (no ads mention); status → Plan approved, task IDs added. No AC changed. | Project Manager |
| 2026-11-11 | Step 9: section 7 (technical) filled in; status → Done after Gate 4 passed | Developer |

## Suggested additions *(for the CEO — not in scope until approved)*
- **"Replay welcome tour"** in Settings (also in F-003 suggestions).
- **Make the Settings → Disclaimer row open the same disclaimer screen now** (read-only, no "I understand" side effects). It is cheap, since the screen exists, and it keeps the disclaimer always reachable, which Play Store reviewers like to see for SMS-reading apps.
- **SMS explainer "See an example" link** showing a fake bank SMS and what the app extracts from it (amount, merchant, date). Indian expense apps such as Walnut and Axio built trust this way, and it previews Phase 4.
- **Confirm the no-ads / no-analytics promise** as a D-0xx decision so the privacy copy on slide 4 and the explainers can state it confidently.
