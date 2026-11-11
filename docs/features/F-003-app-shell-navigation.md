# F-003: App shell & navigation

| | |
|---|---|
| **Phase** | 1 |
| **Status** | Done |
| **Plan** | [`plans/F-003-app-shell-navigation.md`](../../plans/F-003-app-shell-navigation.md) |
| **Test cases** | [`tests/F-003-app-shell-navigation.md`](../../tests/F-003-app-shell-navigation.md) |
| **Tasks** | T-111 … T-115 (`docs/TASKS.md`) |

## 1. What it is *(Product Manager)*
The frame of the app: a bottom navigation bar with the four main tabs, **Home, Dashboard, Transactions and Settings**, each with a top bar and a placeholder body. Phase 1 has no money data, so each tab shows a friendly empty state that says what will appear there. Settings lists placeholder rows for the items coming in later phases, plus the working **Theme** row from F-002. The app is called "Daily Budget App" on screen and on the Android launcher (placeholder name until Phase 7, D-021). This shell replaces the Phase 0 placeholder screen. Every later phase fills these tabs rather than building new navigation.

**User stories:**
- As a **user**, I want four clearly labelled tabs at the bottom so that I can always see where I am and get anywhere in one tap.
- As a **first-time user**, I want each empty tab to tell me what will show up there so that an empty screen doesn't look broken.
- As the **Owner**, I want to open the app on the emulator and move between the real tabs so that I can judge the look and feel before any money features exist.

## 2. How it behaves *(Product Manager)*
Visual details (icons, spacing, colours, illustration style) are **per design system** (`docs/design/design-system.md`).

1. **Launch.** When onboarding is finished (F-005), the app always opens on **Home**, even if another tab was open when it was closed. On a fresh install, the F-005 welcome flow shows first and ends on Home.
2. **Bottom navigation.** Four tabs in this order: Home, Dashboard, Transactions, Settings. Each tab has an icon **and** a text label, and all four labels are always visible (not only the selected one). The selected tab is shown with an indicator/shape and a filled icon, not by colour alone. Tapping a tab switches to it at once. Tapping the already-selected tab scrolls it back to the top if it is scrolled, and otherwise does nothing.
3. **Top bar.** Home shows the app name `Daily Budget App`. The other tabs show their tab name (`Dashboard`, `Transactions`, `Settings`).
4. **Tab bodies (placeholders).** Each of Home, Dashboard and Transactions shows one empty state placed in the body per design system (left-aligned, design system §7.10): an icon or illustration, a title and a short description (copy in section 5). No numbers, no fake data, no buttons that do nothing.
5. **Settings tab.** A scrollable list using the F-004 label + description + (i) pattern:
   - **Theme** (works, from F-002). It shows the current choice and opens the theme picker.
   - Placeholder rows, in this order: **Notifications, Bank account, Salary date, Categories, Privacy & data, How this app works, Disclaimer**. They match the README §4 settings list. Each shows its label, its description and a **"Coming soon"** tag. They are visibly inactive, and tapping one does nothing: no navigation, no error. A screen reader announces them as, for example, "Notifications, coming soon, not available yet".
   - Optional grouping headers (e.g. "Appearance", "Money", "Help") are per design system.
6. **Keeping state.** Switching tabs keeps each tab's scroll position for the current session. Closing the app resets everything to Home at the top.
7. **Android back button / gesture.** On Dashboard, Transactions or Settings, back goes to **Home**. On Home, back leaves the app (sends it to the background, as Android normally does). With the theme picker or an (i) explanation open, back closes that first. A first-time hint (F-004) is part of the page, not an overlay: back ignores it (it is **not** dismissed and **not** saved as seen) and follows the tab rule above.
8. **App name.**
   - The Android launcher label is `Daily Budget App`, replacing the generated `daily_budget`.
   - The task/recents title is `Daily Budget App`.
   - The Phase 0 placeholder screen ("Setting things up…") is removed.

**Example:** the Owner finishes the welcome flow and lands on Home, which says "Your daily budget lives here". They tap Transactions and see "No transactions yet". They tap Settings, see Theme set to "Auto (follows your phone)" and the "Coming soon" rows, and press back. They are on Home again. Pressing back once more closes the app.

## 3. Acceptance criteria *(Product Manager)*
"Small phone", "all four themes" and "every Phase 1 screen" are as defined in F-002 section 3.

| ID | Given / When / Then |
|---|---|
| AC-1 | **Four tabs in order.** Given onboarding is finished, when the app opens, then a bottom navigation bar shows exactly four tabs in the order Home, Dashboard, Transactions, Settings, each with an icon and its text label visible, and Home is selected. |
| AC-2 | **Selected state not by colour alone.** Given any tab is selected, when the Tester views the bar (also in a greyscale screenshot), then the selected tab is distinguishable from the others by a shape/indicator or icon change, and a screen reader announces it as selected (e.g. "Dashboard, tab 2 of 4, selected"). |
| AC-3 | **Switching tabs.** Given any tab is shown, when the user taps another tab, then that tab's body and top-bar title (section 5) appear and the tapped tab becomes selected; this works for all 12 from→to combinations. |
| AC-4 | **Placeholder empty states.** Given Home, Dashboard and Transactions, when each is shown, then it displays exactly the empty-state title and description from section 5 (character for character) with an icon/illustration, and contains no amounts, no sample data and no buttons. |
| AC-5 | **Settings rows.** Given the Settings tab, when it is shown, then it lists the Theme row first followed by the placeholder rows Notifications, Bank account, Salary date, Categories, Privacy & data, How this app works, Disclaimer, in that order, each with the label and description from section 5 using the F-004 pattern; every placeholder row shows a "Coming soon" tag. |
| AC-6 | **Placeholder rows do nothing.** Given the Settings tab, when the user taps each placeholder row, then nothing navigates, no dialog opens, no error is logged, and the screen reader exposes the row as disabled/not available with the words "coming soon". Tapping the Theme row opens the F-002 theme picker. |
| AC-7 | **Always opens on Home.** Given onboarding is finished and the user was on Settings, when the app is force-stopped and reopened, then it opens on Home, scrolled to the top. |
| AC-8 | **Back button.** Given the user is on Dashboard, Transactions or Settings, when they press Android back, then Home is shown. Given the user is on Home, when they press back, then the app goes to the background (it is not stuck and does not crash), and reopening it from recents shows Home. |
| AC-9 | **Scroll position kept between tabs.** Given Settings is scrolled down (at text scale 2.0 so it scrolls), when the user switches to Home and back to Settings, then Settings is still at the same scroll position. When the user taps the already-selected Settings tab, then it scrolls to the top. |
| AC-10 | **App name.** Given the built app, when the Tester checks `app/android/app/src/main/AndroidManifest.xml`, then `android:label` is `Daily Budget App`; on the emulator the launcher icon label reads "Daily Budget App" (a launcher shortening it with "…" for lack of space is acceptable); the recents screen shows "Daily Budget App"; and the Home top bar shows `Daily Budget App`. |
| AC-11 | **Phase 0 placeholder gone.** Given the app source and the running app, when the Tester searches `app/lib/` for `PlaceholderScreen` and the text `Setting things up. Your daily budget will appear here soon.`, then there are 0 matches; and the F-001 placeholder test cases (TC-001-14, -15, -16, -43) are retired or replaced in `tests/F-001-project-foundation.md` with a note pointing to F-003, so `tool/check.ps1` stays green. |
| AC-12 | **All themes, large text, accessibility.** Given every tab (and the Settings list fully scrolled), when shown in all four themes at text scale 1.0 and 2.0 on a small phone, then F-002 AC-12, AC-13 and AC-14 pass (contrast, 48 dp targets, no overflow/clipping), and every tab body is reachable and readable with TalkBack in a logical order: top bar, body, then bottom navigation. |

## 4. Edge cases *(Product Manager)*
- **Rapid tab tapping** (e.g. five taps across tabs in under a second): the last tapped tab is shown and selected. No duplicate screens are stacked, so one back press reaches Home.
- **Back while the theme picker or an (i) explanation is open:** the first back closes the overlay only (section 2 step 7). **Back with a hint visible:** the hint stays undismissed and back follows the tab rule (Home, or leave the app from Home).
- **Predictive back (Android 14+):** The back preview must never be a blank screen. Leaving the app from Home shows the system preview of the app shrinking over the launcher. On Dashboard, Transactions or Settings the system's back chip alone is acceptable; releasing goes to Home.
- **Theme change while on Settings** (F-002): Settings stays open at the same scroll position. The app does not jump to Home.
- **Text scale 2.0:** navigation labels follow the design system's documented scaling rule (F-002 edge cases). Settings rows wrap onto more lines and the list scrolls. A "Coming soon" tag may wrap below the label but is never clipped.
- **Long or translated labels later:** "How this app works" is the longest row label. It must wrap, not truncate.
- **App killed by the system in the background:** reopening shows Home (AC-7). Losing tab state here is expected.
- **Gesture navigation vs three-button navigation:** the bottom bar is not covered by the system gesture area or the button bar in either mode, and it respects the safe area (edge-to-edge is per design system).
- **Launcher label truncation:** many launchers cut long names ("Daily Budget A…"). That is launcher behaviour and is accepted (AC-10). The final short name comes in Phase 7.
- **Tablet / wide screen:** not a target. The layout must not crash. It may simply stretch.
- **Riverpod introduction:** if this feature adds the first provider, the plan records the code-generation decision (phase overview, D-017).

## 5. Help text & copy *(Product Manager, finalised by Designer)*
| Control | Label | Description / tooltip |
|---|---|---|
| Nav tab: Home | `Home` | Tooltip/hint: `Today's budget and your calendar` |
| Nav tab: Dashboard | `Dashboard` | Tooltip/hint: `Where your money goes` |
| Nav tab: Transactions | `Transactions` | Tooltip/hint: `Every spend and credit` |
| Nav tab: Settings | `Settings` | Tooltip/hint: `Theme and app options` |
| Home top bar | `Daily Budget App` | — |
| Home empty state | `Your daily budget lives here` | `Once you set up your month, you'll see what you can spend today, what you've spent and your calendar.` |
| Dashboard empty state | `Insights are on their way` | `After a few days of spending, you'll see where your money goes and how many days you saved.` |
| Transactions empty state | `No transactions yet` | `Spends from your bank SMS will show up here. You'll also be able to add them yourself.` |
| Settings group header 1 (above Theme, Notifications) | `General` | Heading for screen readers |
| Settings group header 2 (above Bank account, Salary date, Categories) | `Money` | Heading for screen readers |
| Settings group header 3 (above Privacy & data, How this app works, Disclaimer) | `Privacy & help` | Heading for screen readers |
| Settings → Theme | `Theme` | See F-002 section 5 |
| Settings → Notifications | `Notifications` | `Budget warnings and an end-of-day summary` |
| Settings → Bank account | `Bank account` | `The one bank account the app tracks` |
| Settings → Salary date | `Salary date` | `The day your budget month starts` |
| Settings → Categories | `Categories` | `How your spends are grouped, like Food or Travel` |
| Settings → Privacy & data | `Privacy & data` | `Your data stays on this phone. Manage or delete it here.` |
| Settings → How this app works | `How this app works` | `A short guide to daily budgets and saving` |
| Settings → Disclaimer | `Disclaimer` | `What the app can and can't track` |
| "Coming soon" tag | `Coming soon` | Screen reader, whole row as one disabled item: `<label>, coming soon, not available yet. <description>`, e.g. `Notifications, coming soon, not available yet. Budget warnings and an end-of-day summary` (TalkBack then adds "disabled") |

## 6. Out of scope
- Real content on any tab: top summary, today's card, calendar, dashboard charts, transaction list, search or filters (Phases 2–3).
- Working Settings items other than Theme (later phases). The "How this app works" page is Phase 6.
- Day details, add/edit transaction and month setup screens (Phases 2–3).
- Deep links, app shortcuts and widgets.
- Restoring the last-open tab after restart (by design, the app always opens on Home).
- Tab-switch animations beyond the basic default transition (Phase 6).
- Final app name, icon and application ID (Phase 7, D-021).

## 7. How it works — technical *(Developer, filled in when the feature is Done)*
- **What was built:** the app frame. `AppShell` with four tabs (Home, Dashboard, Transactions, Settings) behind a bottom navigation bar with an ink tick, each tab keeping its own state, a fade between tabs, left-aligned empty states, and the Settings list in three groups with "Coming soon" rows. Back always goes to Home first, then leaves the app. Built in T-111 … T-114, T-132 (review N2 and N4) and verified on the emulator in T-115. Gate 4 passed with accepted open items 2026-11-11.
- **Main files** (`app/lib/`): `features/shell/` (`app_shell.dart`, `app_tab.dart` the single source of the tab titles, `budget_navigation_bar.dart` with `BudgetNavTick`, `tab_page.dart`); `features/home/home_tab.dart`, `features/dashboard/dashboard_tab.dart`, `features/transactions/transactions_tab.dart` (empty states); `features/settings/settings_tab.dart` and `coming_soon_row.dart`; `core/widgets/` (`BudgetListRow`, `EmptyState`, `FocusRing`); `core/copy/screen_copy.dart`. `AndroidManifest.xml` has the label `Daily Budget App` and `android:enableOnBackInvokedCallback="true"`.
- **Data stored:** none. The last-open tab is deliberately not saved: the app always opens on Home.
- **Decisions applied:** D-021 (final app name and ID are a Phase 7 task), D-030 (landscape works), D-031 (every sheet closes with Back before the tab changes), D-032 (a row with an (i) is one explicit semantics node), D-065 (predictive back on a tab, see below), D-066 (TalkBack cases).
- **Deviations from the plan** (plan section 11, approved F3-1 … F3-10): no separate `ComingSoonTag` widget, `ComingSoonRow` uses `BudgetListRow` with a tag; the tab fade is one shell controller on the selected tab (an `AnimatedOpacity` per child would not fade, offstage tabs have muted tickers); one sliding `BudgetNavTick`; tests live in `test/features/shell/`, `tabs/`, `settings/`; TC-003-15 also has an automated aid; icons are Material line icons; the tag width is now measured (N2, T-132) instead of estimated at 120 dp; M3 made `AppTab.title` the only source of titles; the nav bar is 64 dp at 1.0 and "Transactions" shrinks to fit at large text.
- **How it is tested:** 31 cases TC-003-01 … -32 in `tests/F-003-app-shell-navigation.md` (29 Pass, 1 Partial, 1 Blocked-needs-human). Automated in `app/test/features/shell/app_shell_test.dart`, `app_name_test.dart`, `tabs/empty_tabs_test.dart`, `settings/settings_tab_test.dart`, `core/widgets/budget_list_row_test.dart` and the sweeps in `p1_screen_sweeps_test.dart`. Emulator (T-115, T-230): launcher and recents label, back gesture and button, 3-button navigation, predictive back previews, colour-blind (greyscale) view. B-001 (blank-looking back preview on a tab) is Closed.
- **Depends on / used by:** depends on F-002 (theme, components). Hosts F-004 hints and the Theme row, and F-005's gate swaps it in. All Phase 2 and 3 screens are tabs or routes inside it.
- **Known limitations:**
  - **Blocked-needs-human (D-066):** TC-003-18 (TalkBack walk through every tab, default and largest font) and the TalkBack step of TC-003-03 (the selected tab is read "selected"; TC-003-03 is Partial because the greyscale view passed). adb cannot move TalkBack focus or read its speech. Their widget-test proofs are green (TC-003-02, -17 semantics and reading order). Steps for the Owner are in `tests/PHASE-1-SUMMARY.md`. A failure becomes a bug in Phase 3.
  - **Predictive back on Dashboard, Transactions and Settings** shows only the system back chip, no Home preview (D-065, option b); never blank. Home shows the app shrinking over the launcher. The Dashboard and Transactions previews were not photographed (Home and Settings were); all tabs share one `PopScope` Back handler.
  - The launcher shortens the label to "Daily Budget" in recents; accepted by the case.
  - `BudgetListRow` still estimates a trailing widget next to a tag at 48 dp (Gate 3 Nice to have); no screen has that combination yet. Measure it when one does.
  - Designer Nice to have items: N4 the "Transactions" nav label baseline at 2.0x (T-236).
  - Not built (out of scope): real tab content (Phases 2 and 3), "How this app works" (Phase 6), deep links.

## 8. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-05 | First version of the spec | Product Manager |
| 2026-11-05 | §5 finalised by Designer (`docs/design/screens/app-shell.md`, `settings.md`): added the three Settings group headers (row order unchanged). All other copy unchanged. Designer note for PM: §2.4 "centred" empty state vs design system's left-aligned empty state, see design-system §9 item 6. | Designer |
| 2026-11-05 | Gate 1 reconciliation (PM): §2.4 empty state placed per design system (left-aligned) instead of "centred"; §2.7 and §4 back with a hint visible = hint ignored, not dismissed (matches F-004 and app-shell §3.4); §5 exact Coming soon screen-reader string; status → Plan approved, task IDs added. No AC changed. |
| 2026-11-11 | §4 predictive-back edge case reworded (D-065, B-001, T-229): back preview never blank; leaving from Home shows the system app-shrinking preview; on Dashboard, Transactions or Settings the system back chip alone is acceptable and release goes to Home. AC numbers and AC-8 unchanged. | Product Manager | Project Manager |
| 2026-11-11 | Step 9: section 7 (technical) filled in; status → Done after Gate 4 passed | Developer |

## Suggested additions *(for the CEO — not in scope until approved)*
- **Settings → "Show tips again"** and **"Replay welcome tour"** rows, so users and the Tester can reset F-004 hints and the F-005 tour without clearing app data. Google apps and Indian fintech apps such as Jupiter offer a "replay intro" option.
- **Settings → app version line** at the bottom (e.g. "Version 0.1.0"). It helps the Owner report which build a bug was seen on.
- **Settings → "Delete all app data"** placeholder row now. STANDARDS §8 requires the feature, and showing it early sets the privacy expectation. The real action comes with the database in Phase 2.
- **Double-back-to-exit is not recommended.** Android's guidance discourages "press back again to exit". Plain back-to-background (AC-8) is the modern pattern.
