# F-004: Help & tooltip system

| | |
|---|---|
| **Phase** | 1 |
| **Status** | Done |
| **Plan** | [`plans/F-004-help-tooltip-system.md`](../../plans/F-004-help-tooltip-system.md) |
| **Test cases** | [`tests/F-004-help-tooltip-system.md`](../../tests/F-004-help-tooltip-system.md) |
| **Tasks** | T-116 … T-120 (`docs/TASKS.md`) |

## 1. What it is *(Product Manager)*
The shared way the app explains itself, so a first-time user is never confused (README §3.8, STANDARDS §7). It has three reusable parts that every later button, setting and number will use:
1. **Label + description**: a control's name with a short line of plain text under it.
2. **(i) explanation**: a small (i) button next to a label or number that opens a longer explanation.
3. **First-time hint**: a dismissible tip card shown the first time the user opens each main tab. Once dismissed, it is never shown again.

In Phase 1 these parts are built once in `core/` and used on the F-002 Theme row, the F-003 tabs and Settings, and the F-005 screens. From Phase 2 on, every new control uses them instead of its own help text.

**User stories:**
- As a **first-time user**, I want every button and setting to say what it does so that I can use the app without guessing.
- As a **curious user**, I want to tap (i) for a fuller explanation so that I understand terms like "Dim" or, later, "savings pot".
- As a **returning user**, I want tips to go away once I've read them so that the app doesn't nag me.
- As the **team**, we want one help component so that help looks and behaves the same everywhere and nobody forgets it.

## 2. How it behaves *(Product Manager)*
Visual form (sheet vs popup, card style, icon) is **per design system** (`docs/design/design-system.md`).

1. **Label + description.**
   - The label is shown in the label text style. The description is one or two short lines under it in the secondary text style.
   - It can be used on a list row (Settings), next to a button, or under a number (later phases).
   - A screen reader reads label and description together as one item, e.g. "Notifications. Budget warnings and an end-of-day summary."
2. **(i) explanation.**
   - An (i) icon sits after the label. It has a visible icon and a touch target of ≥ 48 dp.
   - Tapping it opens an explanation (bottom sheet or popup, per design system) with a title (usually the label), the body text and a **Got it** button.
   - It closes on: Got it, tapping outside, swipe down (if a sheet), or Android back.
   - After closing, screen-reader focus returns to the (i) button.
   - The screen reader announces the (i) button as "More about <label>, button".
   - Long text scrolls inside the explanation.
   - Opening (i) never triggers the row's own action. On the Theme row, the (i) opens the explanation and does **not** open the theme picker.
3. **Standard navigation controls** (bottom tabs, Back, Next, Skip, Close/×, Done, Got it, Get started, Not now, I understand) don't need a visible description. Their label is self-explanatory. They carry a **screen-reader hint** instead (copy in each feature's section 5). Icon-only controls (×) and the bottom tabs also carry a **long-press tooltip** with the same text; text-labelled buttons may have one too (Next, Skip) but don't need it.
4. **The rule (STANDARDS §7):** every interactive control has a visible label **plus** one of: a visible description, an (i) explanation, or (for standard navigation controls only) a screen-reader hint, plus a long-press tooltip when the control is icon-only or a bottom tab. Each feature's section 5 table is the list the Tester checks.
5. **First-time hints.**
   - The first time the user opens each of the four main tabs **after onboarding is finished** (F-005), a hint card appears at a fixed place per design system (for example, under the top bar). It shows one short tip (section 5) with a **Got it** button and a close (×) button.
   - Both buttons dismiss it and save "seen" for that tab in the shared preferences store (the same store as F-002/F-005).
   - A dismissed hint never shows again on that tab, including after restart.
   - Each tab's hint is independent. Dismissing Home's hint doesn't affect Dashboard's.
   - A hint is only "seen" once it is **dismissed**. Just looking at it, switching tabs or closing the app doesn't count, so it shows again next time.
   - The hint doesn't block the screen: the tab body, the Settings rows and the bottom navigation all stay usable while it is visible.
   - At most one hint is visible at a time (one per tab).
   - Hints never appear during the welcome tour or the explainers.
6. **One home for help copy.** All help strings (descriptions, (i) bodies, hint text) are defined in one place in code. The Designer can then finalise wording without hunting through screens, and translation stays possible later.

**Example:** after the welcome flow, Home shows the hint "Use the tabs at the bottom to move around. Home is where you'll check today's budget each day." The user taps **Got it** and the hint is gone. They open Settings and see its own hint. They switch to Home and back without dismissing it, and the Settings hint is still there. They tap (i) next to **Theme** and read about Dim, then tap outside to close it. They close and reopen the app: Home has no hint, and Settings still shows its hint because it was never dismissed.

## 3. Acceptance criteria *(Product Manager)*
"Small phone", "all four themes" and "every Phase 1 screen" are as defined in F-002 section 3.

| ID | Given / When / Then |
|---|---|
| AC-1 | **Label + description component.** Given the shared help component with a label and a description, when it is rendered, then the label and description both appear in the design-system text styles, and a screen reader reads them as one item ("<label>. <description>"). |
| AC-2 | **(i) opens the explanation.** Given a control with an (i), when the user taps the (i), then an explanation opens showing the title and body text defined for that control and a **Got it** button; the control's own action (e.g. opening the theme picker) does **not** run. |
| AC-3 | **(i) closes four ways.** Given an open explanation, when the user taps Got it, taps outside it, swipes it down (if a sheet) or presses Android back, then it closes each time, the screen underneath is unchanged, and screen-reader focus returns to the (i) button. |
| AC-4 | **(i) accessible.** Given any (i) button, when the Tester measures it and inspects semantics, then its touch target is ≥ 48 × 48 dp and its screen-reader label is "More about <label>" (button role). |
| AC-5 | **Coverage of the rule.** Given every Phase 1 screen, when the Tester lists every interactive control and compares with the section 5 tables of F-002, F-003, F-004 and F-005, then every control has a visible label plus a visible description, an (i), or (standard navigation controls only) a long-press tooltip and screen-reader hint; and all text matches the tables. Any control without one fails. |
| AC-6 | **Shared component used.** Given the source under `app/lib/features/`, when the Tester (or a check agreed in the plan) inspects how labels, descriptions, (i) buttons and hints are built, then they all use the shared component(s) from `app/lib/core/`, and all help strings come from the single help-copy location (section 2 step 6). |
| AC-7 | **Hint shows on first visit.** Given onboarding is finished and no hints have been dismissed, when the user opens each of Home, Dashboard, Transactions and Settings for the first time, then each shows its own hint text from section 5 with Got it and × buttons. |
| AC-8 | **Dismissed hint never returns.** Given the Home hint is visible, when the user taps Got it (and, separately on another tab, ×), then the hint disappears at once; it does not reappear when switching tabs or after the app is force-stopped and reopened; and the hints of the other tabs still show until they are dismissed. |
| AC-9 | **Undismissed hint returns.** Given the Dashboard hint is visible and not dismissed, when the user switches to another tab and back, and separately when the app is force-stopped and reopened, then the Dashboard hint is shown again each time. |
| AC-10 | **Hint doesn't block.** Given a hint is visible on Settings, when the user taps the Theme row, scrolls the list or taps another tab, then each action works as if the hint were not there. |
| AC-11 | **No hints during onboarding.** Given a fresh install, when the welcome tour and explainers (F-005) are on screen, then no first-time hint is shown; the Home hint appears only after the user reaches Home. |
| AC-12 | **Storage failure is safe.** Given the preferences store cannot be read or written, when a tab opens or a hint is dismissed, then the app does not crash or show an error; a hint dismissed this session stays hidden for this session; on next launch hints whose seen-state cannot be read are shown again (fail towards showing help, never towards crashing). |
| AC-13 | **Themes and large text.** Given an (i) explanation with the longest Phase 1 body text and every hint card, when shown in all four themes at text scale 1.0 and 2.0 on a small phone, then F-002 AC-12, AC-13 and AC-14 pass, all of the explanation text can be reached by scrolling, and Got it stays reachable. |

## 4. Edge cases *(Product Manager)*
- **Double-tap on (i):** only one explanation opens, not two stacked.
- **(i) tapped while a hint is visible:** the explanation opens on top. Closing it leaves the hint as it was (not dismissed).
- **Back while an explanation is open:** it closes the explanation only and does not leave the tab (F-003 back rules).
- **Theme changes while an explanation is open** (Auto + system switch): the explanation re-renders in the new theme and stays open.
- **Rotation / app backgrounded with an explanation open:** on return it is either still open or closed cleanly. No duplicate, no crash.
- **Reinstall / cleared app data:** all hints show again, as on a fresh install. This is expected.
- **Hint seen-flags for tabs that later get real content:** when a later phase changes a tab's hint text, it may need a new hint ID so users see the new tip. Each hint has its own ID so this is possible (plan detail).
- **TalkBack users:** a hint is announced when the tab opens (it is first in reading order after the top bar), and its Got it button is focusable.
- **Very short screens at 2.0 text** (360 × 640 dp): the hint card must not push the empty state off-screen in a way that can't be scrolled to.
- **Description longer than two lines** (later features): it wraps. It is never truncated with "…", because hidden help defeats the purpose.
- **Plugin build environment:** Windows Developer Mode is not needed (D-029). If the plugin build fails for an environment reason, the device restart parts of AC-8/AC-9 are **Blocked**, not failed.

## 5. Help text & copy *(Product Manager, finalised by Designer)*
| Control | Label | Description / tooltip |
|---|---|---|
| (i) button (any) | (icon only) | Screen reader: `More about <label>` |
| Explanation close button | `Got it` | Screen reader hint: `Close this explanation` |
| (i) explanation | Title = the control's label | Shown as a bottom sheet (help sheet) with the body and a `Got it` button |
| Hint card overline | `Tip` | Screen reader reads the card as `Tip. <hint text>` |
| Hint — Home | — | `Use the tabs at the bottom to move around. Home is where you'll check today's budget each day.` |
| Hint — Dashboard | — | `Check back after a week of spending. That's when your patterns start to show.` |
| Hint — Transactions | — | `Tap a spend to fix it, or tap its category to change it.` |
| Hint — Settings | — | `Change the theme and other options here. Tap (i) next to a setting to learn what it does.` |
| Hint — Calendar | — | `Tap a day to see its spends.` |
| Hint dismiss button | `Got it` | Screen reader hint: `Dismiss this tip. It won't show again.` |
| Hint close (×) | (icon only) | Tooltip / screen reader: `Dismiss tip` |

Explanation bodies for specific controls live in each feature's own section 5 (e.g. the Theme (i) text is in F-002).

## 6. Out of scope
- The Settings → "How this app works" page (Phase 6).
- Multi-step guided coach marks that point at specific UI elements with arrows or spotlights (Phase 6 polish if wanted).
- Hints for screens that don't exist yet (day details, month setup and others). Those features add their own hints using this component.
- Resetting hints from Settings (see F-003 Suggested additions).
- Translations and remote/updated help content (no network).

## 7. How it works — technical *(Developer, filled in when the feature is Done)*
- **What was built:** one help system for every screen. An (i) button after a label opens a help sheet (title, scrolling body, pinned Got it); long-press tooltips on icon-only controls and the four tabs; screen-reader labels and hints on every control; a first-time hint card per tab that stays dismissed for good; and all help text in two copy files. Built in T-116 … T-119 and T-132, verified on the emulator in T-120 and T-230, scrim label in T-233. Gate 4 passed with accepted open items 2026-11-11.
- **Main files** (`app/lib/`):
  - `core/help/`: `info_button.dart` (`InfoButton`, 48 dp target, `InkResponse`, focus return), `help_sheet.dart` (`showHelpSheet`), `help_info.dart`, `label_description.dart` (places the (i) after the last word, measured with the real text style), `nav_tooltip.dart`, `first_time_hint.dart` (card with Got it and ×), `hint_seen_provider.dart`.
  - `core/widgets/budget_sheet.dart` (`showBudgetSheet`, `BudgetSheetFrame`, `_BudgetSheetRoute`), `tap_cooldown.dart`, `focus_ring.dart`; `BudgetButton.semanticsHint`.
  - `core/copy/help_copy.dart` (every help string) and `screen_copy.dart`; `domain/preferences/hint_id.dart`; `data/preferences/hint_repository.dart` (keys `hint.<id>.seen` in `PreferenceKeys`).
- **Data stored:** four booleans in `shared_preferences`, one "seen" flag per tab hint (`home.v1`, `dashboard.v1`, `transactions.v1`, `settings.v1`). An unreadable value means the hint shows again; a failed save still hides the hint for the session.
- **Decisions applied:** D-031 (every sheet opens through `showBudgetSheet`; its scrim closes only after the entrance animation and a double-tap interval; every sheet has its own visible close button), D-032 (a row with an (i) is one explicit semantics node, the (i) a separate child "More about <label>"), D-026 (store behind an interface), D-029 and D-030 as for F-002.
- **Deviations from the plan** (plan section 11 items 1 to 19, approved F4-1 … F4-8 and Gate 3 M1, M2): `showBudgetSheet` pushes its own `ModalBottomSheetRoute` subclass so a double tap on (i) opens exactly one sheet, with or without Remove animations (M2, TC-004-17); the sheet draws its own fill, corners, Light shadow and decorative handle (C1); no `MergeSemantics` on a row with an (i) (C2); measured (i) placement including Bold text (M1); `ScreenCopy` created here; the hint collapses with `AnimatedSwitcher` and moves focus to the next item after a dismissal when a screen reader or keyboard focus is in use; `InMemoryPreferencesStore.allowing(…)`; `TapCooldown` is the one guard for sheet, tour, explainers and gate; one driver `P1Screen` (18 states) for TC-004-06; the shared-component guard bans `Tooltip(`, `showModalBottomSheet(`, `showBottomSheet(`, `showDialog(`, `ListTile(`, `IconButton(` in `lib/features/`; **T-233:** the sheet scrim label is `Close` (was the stock "Scrim"), tap hint `Close Bottom Sheet`.
- **How it is tested:** 25 cases TC-004-01 … -25 in `tests/F-004-help-tooltip-system.md` (23 Pass, 1 Partial, 1 Blocked-needs-human). Automated in `app/test/core/help/` (`label_description_test.dart`, `help_sheet_test.dart`, `hints_test.dart`), `app/test/copy/copy_tables_test.dart`, `app/test/architecture/help_rule_test.dart` (TC-004-06: every tappable semantics node of all 18 Phase 1 states must match the label and hint tables exactly), `app/test/architecture/shared_components_test.dart` (TC-004-08), `app/test/core/widgets/focus_ring_test.dart` and `app/test/features/settings/theme_setting_row_test.dart`. Emulator: hints across a real force-stop and a fresh install (TC-004-11), help sheet with rotation, Home key and reopen (TC-004-25), labels and nodes on a real screen (TC-004-07). Every can-it-fail probe is recorded in plan section 11.
- **Depends on / used by:** depends on F-002 (theme, sheet and button components, preferences store) and F-003 (tabs host the hints; the Theme row has the first (i)). Used by F-005 (Got it hints, tooltips on Next and Skip) and every later feature, which must add its own (i), hints and copy through these components and its screens to `help_rule_test.dart`.
- **Known limitations:**
  - **Blocked-needs-human (D-066):** TC-004-04 (TalkBack focus returns to the (i) after the sheet closes, the handle is not a stop, the scrim node closes the sheet, and the keyboard focus ring) and the TalkBack R1 check of TC-004-07 (after a hint is dismissed TalkBack focus should land on the page content, not the tab bar; risk R1 of Gate 3). adb cannot drive or read TalkBack. Proofs that are green: keyboard-focus tests, semantics tests, TC-004-05 and -06. Owner steps in `tests/PHASE-1-SUMMARY.md` (3 and 4). If focus lands on the tab bar, it is logged as a Medium bug and fixed in Phase 3. The keyboard focus ring check (N4) was inconclusive on the emulator.
  - TalkBack reads the scrim node as "Close, Close Bottom Sheet" (the stock tap hint is kept).
  - A hint scrolled out of view still counts as not seen and shows again next time (accepted, AC-10).
  - Designer Nice to have items: N2 the picker and help sheets give no cue that the body scrolls and the selected theme can be off screen at 2.0x text (T-234); N3 the same missing cue under the tour's pinned button (T-235, F-005).
  - Help copy is Dart constants (`HelpCopy`, `ScreenCopy`); moving to `gen-l10n` is a mechanical change when a second language is approved. No custom lint: `help_rule_test.dart` is the guard.

## 8. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-05 | First version of the spec | Product Manager |
| 2026-11-05 | §5 finalised by Designer (`docs/design/screens/help-pattern.md`): Home, Dashboard and Transactions hint texts rewritten so they no longer repeat the empty state shown under them; added the `Tip` overline and the help-sheet form of the (i) explanation. Settings hint unchanged. The §2 example (Home hint text) is illustrative; §5 is the source of truth. | Designer |
| 2026-11-05 | Gate 1 reconciliation (PM): §2.3/§2.4 rule clarified — standard navigation controls need a screen-reader hint, and a long-press tooltip only when icon-only or a bottom tab (Material guidance; matches the §5 tables); §2.5 example uses the final Home hint; Developer Mode edge case replaced (D-029); status → Plan approved, task IDs added. No AC changed. | Project Manager |
| 2026-11-11 | Step 9: section 7 (technical) filled in; status → Done after Gate 4 passed | Developer |
| 2026-11-16 | T-311 (D-078): §5 gains the `hint.calendar.v1` row, `Tap a day to see its spends.` (same wording as `help-pattern.md` §4.2; shown on Home above the calendar after `hint.home.v1` is dismissed, F-011 §5). Additive copy only, no AC changed | Product Manager |
| 2026-11-16 | T-452 (Gate 2, `docs/reviews/design-phase-3.md` Must fix 1): §5 `Hint — Transactions` row now reads `Tap a spend to fix it, or tap its category to change it.` (id `hint.transactions.v1` unchanged), replacing the Phase 1 text; same wording as `help-pattern.md` §4.2, as done for `hint.calendar.v1` in T-311. Copy only, no AC changed | Product Manager |

## Suggested additions *(for the CEO — not in scope until approved)*
- **"Show tips again"** in Settings (also listed in F-003). It resets all hint flags in one tap and makes manual testing much faster.
- **Inline glossary links** inside (i) explanations (e.g. "savings pot" opens its own explanation) from Phase 2, when money terms appear. Groww and Jupiter use this to explain finance words without long paragraphs.
- **A lint/test guard** that fails the build when a new tappable widget in `features/` has no semantics label. It turns STANDARDS §7 into an automatic check for every later phase.
