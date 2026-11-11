# Plan — F-004: Help & tooltip system

| | |
|---|---|
| **Feature doc** | [`docs/features/F-004-help-tooltip-system.md`](../docs/features/F-004-help-tooltip-system.md) |
| **Test cases** | [`tests/F-004-help-tooltip-system.md`](../tests/F-004-help-tooltip-system.md) |
| **Design** | [`docs/design/screens/help-pattern.md`](../docs/design/screens/help-pattern.md) (the (i) opens a **help sheet**, hint card with Got it + ×, long-press tooltip), design system §7.8, §7.11 |
| **Author** | Developer |
| **Status** | Approved (Gate 1, Project Manager, 2026-11-05) — see §10; T-120 no longer depends on Developer Mode (D-029) |

## 1. Approach
Three reusable parts live in `core/`. Every help string comes from one copy file. Hint "seen" flags are stored in the shared preferences store from F-002.

1. **One home for help copy (AC-6, feature doc §2.6).** `lib/core/copy/help_copy.dart` holds `abstract final class HelpCopy` with `static const` strings, grouped by feature:
   - row descriptions;
   - (i) titles and bodies;
   - hint texts;
   - long-press tooltips and screen-reader hints;
   - the `More about <label>` pattern (as a function).

   Screen copy that is not help (titles, empty states, slides) lives next to it in `lib/core/copy/screen_copy.dart` (F-003/F-005). Plain Dart constants keep it simple, and the Designer edits one file. Switching to `gen-l10n`/ARB later is mechanical (§9 Q2).
2. **Label + description (AC-1).** `LabelDescription` (label in `label` style, description in `body` `textSecondary`, `space1` gap; it wraps and never ellipsizes). Screen readers get **one** node: `Semantics(label: '$label. $description', child: ExcludeSemantics(...))`, so TalkBack reads exactly "<label>. <description>". `BudgetListRow` (F-002 T-107) uses it for its text column and gains an optional `info: HelpInfo` slot.
3. **(i) explanation (AC-2…AC-4).** `InfoButton`:
   - an 18 dp `info_outline` icon inside a 48 × 48 dp target, placed after the label;
   - `Semantics(button: true, label: 'More about <label>')`;
   - it is its own gesture target inside the row, so it wins hit-testing and never runs the row's `onTap` (help-pattern §3.1).

   Tapping it calls `showHelpSheet(context, info)`, a **bottom sheet** per help-pattern §3.2. It opens through the shared `showBudgetSheet()` in `core/widgets/budget_sheet.dart` (`showModalBottomSheet`, `isScrollControlled`, max 90 % height, drag handle, scrim). The sheet holds the title, a scrollable body and a **Got it** button (screen-reader hint "Close this explanation").
   - It closes four ways: Got it, scrim tap, swipe down, back. All four are standard modal-route behaviour.
   - When the sheet's future completes, `InfoButton` puts keyboard focus back on its `FocusNode` and sends a `FocusSemanticEvent` from its render object, so TalkBack focus returns to the (i) (AC-3).
   - A per-button `_open` flag ignores a second tap while the sheet is open, so there is no stacked double (edge case).
4. **Standard navigation controls (feature doc §2.3).** These are bottom tabs, Next, Skip, ×, Done. `NavTooltip` (in `core/help/`) wraps a control in a Flutter `Tooltip` (long-press, styled by `tooltipTheme`) and adds `Semantics(hint: …)`. Features use only this wrapper, so the rule is applied the same way everywhere.
5. **First-time hints (AC-7…AC-12).**
   - `HintId { home, dashboard, transactions, settings }` is a pure-Dart enum in `domain/preferences/`. Each value carries a **versioned** storage suffix (`home.v1` …), so a later phase can change a tip and show it again with `v2` (edge case "new hint ID").
   - `HintRepository` (`data/`) reads and writes `hint.<id>.seen` through `PreferencesStore`. An unreadable value counts as **not seen**: the app fails towards showing help (AC-12).
   - `hintSeenProvider`: `NotifierProvider.family<HintSeenNotifier, bool, HintId>`. `build()` reads synchronously. `dismiss()` sets `true` first and then awaits the write, so a write failure still hides the hint for the session (AC-12) and the hint comes back on the next launch.
   - `FirstTimeHintCard` (`core/help/`) per help-pattern §4: `accentSoft` card with a lightbulb icon, the `Tip` overline, a **×** (`NavTooltip` "Dismiss tip", 48 dp) and a **Got it** text button (hint "Dismiss this tip. It won't show again."). Either one calls `dismiss()`. The card collapses with `AnimatedSize` + fade (`motionEmphasis`, 0 with Remove animations).
   - `FirstTimeHint(id)` watches the provider and renders the card or nothing. It goes into the `TabPage.hint` slot (F-003), under the title. The card sits inline in the scroll content, so it **never blocks** the body, the rows or the bar (AC-10). There is one per tab.
   - Only being **dismissed** counts as seen. Switching tabs or closing the app does not write anything (AC-9).
   - Hints appear only inside `AppShell` tabs. F-005's `AppGate` shows the shell only after onboarding is finished, so no hint ever shows during the tour or explainers (AC-11).
6. **Automated rule checks (AC-5, AC-6).**
   - **Copy test**: every `HelpCopy` / `ScreenCopy` string equals the feature-doc §5 tables of F-002…F-005. The strings are written as literals in the test, as in F-001 Gate 1 point 3.
   - **Rule test**: for every Phase 1 screen, walk the semantics tree. Every node with a tap action must have a non-empty label and either a merged description, an adjacent "More about" (i), or a tooltip/hint. Controls without one fail.
   - **Shared-component guard** (architecture test): `lib/features/` must not call `Tooltip(`, `showModalBottomSheet(`, `ListTile(` or `IconButton(` directly. It uses `NavTooltip`, `showBudgetSheet`, `BudgetListRow` and `InfoButton`.
   - The "Suggested additions" lint guard for semantics labels is covered by the rule test for Phase 1 screens. A build-wide lint is not planned (§9 Q3).

**Alternatives rejected**
- *Tooltip bubble for (i)* (first design draft): the design moved to a sheet (help-pattern §3, "Change from the first draft") because F-004 needs a title, Got it, scrolling and swipe-down.
- *Overlay/coach-mark hints*: they block the screen, against AC-10 and the design. Out of scope (feature doc §6).
- *One "hints seen" JSON blob in one key*: one bool per hint is simpler. A corrupt value then affects only its own hint, and the `allowList` stays explicit (TC-004-21, -24).
- *`gen-l10n` ARB files now*: Phase 1 is English only. They add generated code and a build step. Deferred (§9 Q2).

## 2. Files / modules
| Path (under `app/`) | Add / Change | What |
|---|---|---|
| `lib/core/copy/help_copy.dart` | Add | All help strings (F-002…F-005 §5 help rows). `moreAbout(String label)` → `'More about $label'`. |
| `lib/core/help/help_info.dart` | Add | `typedef HelpInfo = ({String title, String body});` |
| `lib/core/help/label_description.dart` | Add | Label + description with a single semantics node. |
| `lib/core/help/info_button.dart` | Add | (i) button, guard, focus return. |
| `lib/core/help/help_sheet.dart` | Add | `showHelpSheet()` (title, scrollable body, Got it). |
| `lib/core/help/nav_tooltip.dart` | Add | Long-press tooltip + screen-reader hint wrapper. |
| `lib/core/help/first_time_hint.dart` | Add | `FirstTimeHintCard` + `FirstTimeHint(id)` (provider-aware). |
| `lib/core/help/hint_seen_provider.dart` | Add | `HintSeenNotifier`, `hintSeenProvider` family. |
| `lib/core/widgets/budget_sheet.dart` | Add | `showBudgetSheet()`, shared by the help sheet and the F-002 theme picker. |
| `lib/core/widgets/budget_list_row.dart` | Change | Uses `LabelDescription`; optional `info` slot with `InfoButton`. |
| `lib/domain/preferences/hint_id.dart` | Add | `enum HintId` + `storageSuffix`. Pure Dart. |
| `lib/data/preferences/hint_repository.dart` | Add | `isSeen` / `markSeen`. |
| `lib/data/preferences/preference_keys.dart` | Change | Hint keys from `HintId.values` (also in the `allowList`). |
| `lib/core/providers/preferences_providers.dart` | Change | `hintRepositoryProvider`. |
| `lib/features/home/home_tab.dart` (and dashboard, transactions, settings) | Change (T-118) | `hint: FirstTimeHint(id: HintId.<tab>)`. |
| `test/core/help/*_test.dart` | Add | Component tests (TC-004-01…-05, -16…-20, -22, -23). |
| `test/core/help/hints_test.dart` | Add | TC-004-09, -10, -12, -13, -15, -18, -21, -24 (with in-memory/failing stores). |
| `test/copy/copy_tables_test.dart` | Add | Copy equals feature docs (part of TC-004-06). |
| `test/architecture/help_rule_test.dart`, `shared_components_test.dart` | Add | TC-004-06 (rule walk), TC-004-08 (guard). |

## 3. Data model / database changes
No database. Four bool preference keys, `hint.home.v1.seen`, `hint.dashboard.v1.seen`, `hint.transactions.v1.seen` and `hint.settings.v1.seen`, in the shared store (F-002 plan §3). Missing, unreadable or wrong-type values count as `false`, so the hint shows.

## 4. Packages (latest stable, checked on pub.dev)
No new packages. It uses `flutter_riverpod` 3.4.3 and the F-002 `PreferencesStore` (`shared_preferences` 2.5.6).

## 5. Tasks
| ID | Task | Covers AC | Depends on | Status |
|---|---|---|---|---|
| T-116 | **Help copy + label/description.** `help_copy.dart` (F-002/F-003/F-004 rows; F-005 added in T-122/T-123), `LabelDescription`, `BudgetListRow` uses it, `NavTooltip`, `copy_tables_test.dart` for the strings present so far. Tests: TC-004-01 (styles from theme, one semantics node "<label>. <description>", wraps at 2.0 without ellipsis); tooltip on long-press + hint. | AC-1, AC-5 (part), AC-6 (part) | T-107 (F-002) | Code review |
| T-117 | **(i) button + help sheet.** `InfoButton`, `showHelpSheet`, `showBudgetSheet`, `info` slot on `BudgetListRow`. Tests: tap (i) on a row with its own `onTap` → sheet opens with title/body/Got it, row callback **not** called; close by Got it / scrim tap / drag down / back → closed, underlying tree unchanged, focus on (i); 48 dp + "More about <label>" button semantics; double-tap → one sheet; theme flip while open → still open and re-themed; longest Phase 1 body (Theme (i), F-002 §5) at 2.0 on 360×640 scrolls to the end and Got it reachable, 5 theme cases. | AC-2, AC-3, AC-4, AC-13 | T-116 | Code review |
| T-118 | **First-time hints.** `HintId`, `HintRepository`, keys + allowList, `hintSeenProvider`, `FirstTimeHintCard`, `FirstTimeHint`, wire into the four `TabPage`s. Tests: each tab shows its own text with Got it and × on first visit; Got it on Home and × on Dashboard → gone at once, gone after tab switch and after a simulated restart (new `ProviderScope` over the same in-memory store), others still shown; undismissed hint returns after tab switch and simulated restart; Theme row tap / scroll / tab tap work with a hint visible; reading order title → hint → body, Got it focusable; double-tap Got it → one write, no error; (i) on Settings with hint visible → hint unchanged after closing; failing store (read throws) → hints shown, no crash; failing write → hidden this session, shown after simulated restart; corrupt value (`"yes"` string) → shown; separate keys per hint. | AC-7, AC-8, AC-9, AC-10, AC-12, AC-13 (hint cards) | T-117, T-102 (F-002), T-113/T-114 (F-003 tabs) | Code review |
| T-119 | **Rule, copy and shared-component checks across all Phase 1 screens.** Complete `copy_tables_test.dart` with F-005 copy; `help_rule_test.dart` walks every Phase 1 screen (four tabs, picker, help sheet, four slides, both explainers, disclaimer) in one theme at 1.0; `shared_components_test.dart` guard with a probe proof (a temporary `Tooltip(` in `features/` makes it fail; probe removed). **No-hints-during-onboarding** test: fresh store → tour/explainers show no `FirstTimeHintCard`; after I understand → Home hint appears. | AC-5, AC-6, AC-11 | T-118, T-123 (F-005 screens), T-109 (picker) | Code review |
| T-120 | **[P] Emulator verification F-004.** Hints across real force-stop (TC-004-11); TalkBack focus returns to (i) (TC-004-04); manual rule walk (TC-004-07); backgrounded/rotated with sheet open (TC-004-20). | AC-3, AC-5, AC-8, AC-9 (device parts) | T-119; plugin build available (Owner Developer Mode, or PM accepts F-002 §7 probe) | To do |

## 6. Acceptance criteria coverage
TC IDs come from the Tester's draft `tests/F-004-help-tooltip-system.md` (2026-11-05). They are proposals until the PM reconciles them at Gate 1.

| AC | Built in task | Proved by test cases |
|---|---|---|
| AC-1 Label + description, one screen-reader item | T-116 | TC-004-01 |
| AC-2 (i) opens explanation, row action not run | T-117 | TC-004-02, TC-004-17, TC-004-18 |
| AC-3 Closes four ways, focus returns | T-117, T-120 | TC-004-03, TC-004-04, TC-004-19, TC-004-20 |
| AC-4 (i) 48 dp, "More about <label>" | T-117 | TC-004-05 |
| AC-5 Rule coverage on every Phase 1 screen | T-116, T-119, T-120 | TC-004-06, TC-004-07 |
| AC-6 Shared components, one copy home | T-116, T-119 | TC-004-08 |
| AC-7 Hint on first visit per tab | T-118 | TC-004-09 |
| AC-8 Dismissed hint never returns | T-118, T-120 | TC-004-10, TC-004-11 [P], TC-004-18, TC-004-21, TC-004-23, TC-004-24 |
| AC-9 Undismissed hint returns | T-118, T-120 | TC-004-11 [P], TC-004-12 |
| AC-10 Hint doesn't block | T-118 | TC-004-13 |
| AC-11 No hints during onboarding | T-119 | TC-004-14 (also TC-005-30) |
| AC-12 Storage failure is safe | T-118 | TC-004-15 |
| AC-13 Themes and large text | T-117, T-118 | TC-004-16, TC-004-22 |

## 7. Edge cases & risks
| Case / risk | How it is handled |
|---|---|
| Double-tap on (i) | `_open` guard in `InfoButton`, so there is one sheet (TC-004-17). |
| (i) while a hint is visible | The sheet is a route on top. Hint state is untouched (TC-004-18). |
| Back with sheet open | Modal route pops first. The tab stays (F-003 back rules). |
| Theme change with sheet open | The sheet is under `MaterialApp`, so it re-themes and stays open (TC-004-19). |
| Rotation / background with sheet open | Route state survives a configuration change. A process kill drops it cleanly (no restoration). Manual in T-120. |
| Reinstall / cleared data | All keys gone, so hints show again (expected). |
| New hint text in a later phase | Bump `HintId` suffix `v1` → `v2` (new key). The old key is ignored. |
| TalkBack order and focus | Hint first after the title (`TabPage` order). Got it is a focusable button. After dismissal, focus moves to the next item (help-pattern §4.3). |
| 360×640 at 2.0 | Hint and empty state scroll inside `TabPage`. Nothing is pushed out of reach (TC-004-16). |
| Description > 2 lines later | `LabelDescription` has no `maxLines`, so it wraps and never ellipsizes. |
| Focus return on Android | Keyboard focus via `FocusNode` is unit-testable. Accessibility focus uses `FocusSemanticEvent`. TalkBack behaviour is checked manually (TC-004-04). If Android ignores the event, report it rather than fake it. |
| Rule test heuristics | The semantics walk can't judge wording. The copy test checks the text exactly, and the manual walk (TC-004-07) covers what automation can't. |
| Developer Mode off | All hint logic is tested with in-memory/failing stores and simulated restarts. Only TC-004-11 needs the real plugin [P]. |

## 8. Impact on existing features
- **F-002:** `BudgetListRow` changes (text column → `LabelDescription`, new `info` slot). Re-run TC-002-19 and the component theme matrix. The Theme row (T-109) uses `InfoButton`, so TC-002-01/-07 confirm the (i) does not open the picker (TC-004-02).
- **F-003:** `TabPage.hint` slot filled; Settings rows use `LabelDescription`. Re-run TC-003-05, -06, -07, -12, -16, -17 (a hint at the top changes scroll extents and reading order).
- **F-001:** no direct impact. TC-001-06 holds (`HintId` is pure Dart).
- Re-run: full `flutter test`, `tool/check.ps1`.

## 9. Open questions
1. **(PM) Hint placement when the hint and the Settings list scroll:** the design puts the hint inline at the top of the scroll content, so it scrolls away with the list. AC-10 ("doesn't block") is met. Confirm that a hint scrolled out of view but not dismissed is acceptable. It counts as not seen and shows again next time.
2. **(PM) Copy as Dart constants vs `gen-l10n`/ARB now:** I plan constants in `core/copy/` (English only). Moving to ARB is mechanical when a second language is approved.
3. **(CEO) "Lint/test guard for semantics labels" suggestion:** the plan covers it for Phase 1 screens with `help_rule_test.dart`. Every later phase adds its screens to that test. A custom lint rule is not planned.
4. **(Tester) TC-004-04 focus return:** automated tests can assert keyboard focus on the (i). TalkBack accessibility focus is device-only (manual).

## 10. Project Manager review *(Gate 1 — cross-check of doc + plan + test cases)*
**Verdict:** **Approved** (Project Manager, 2026-11-05). Condition: the test-case updates in point 1 are done in **T-126** before T-116 / T-118 start; the guard list in point 3 is applied in T-119.

Cross-check:
- [x] Every AC in the feature doc is covered by a task in this plan (AC-1…AC-13 → T-116…T-120, §6)
- [x] Every AC has at least one test case in the test file (TC-004-01…-24)
- [x] Edge cases in the doc appear in both the plan and the test cases (double-tap (i), (i) over a hint, back, theme change, rotation/background, reinstall, versioned hint IDs, TalkBack order, short screens, long descriptions)
- [x] Approach follows `docs/STANDARDS.md` (`HintId` pure Dart in `domain/`, repository in `data/`, components in `core/`, one copy file, guards for features)
- [x] Latest stable versions / modern APIs used (records for `HelpInfo`, `NotifierProvider.family`, `FocusSemanticEvent`, no new package)

| # | Point | Type | Resolution |
|---|---|---|---|
| 1 | **Test cases to update (Tester).** **TC-004-09**: the expected hint texts are the old first draft; use F-004 §5 as finalised: Home `Use the tabs at the bottom to move around. Home is where you'll check today's budget each day.` · Dashboard `Check back after a week of spending. That's when your patterns start to show.` · Transactions `Spotted a wrong amount or category later? You'll be able to fix it right here.` · Settings unchanged; also check the `Tip` overline. **TC-004-03 (c)**: the explanation is always a sheet now → drop "(only if it is a sheet)". **TC-004-08**: align with the plan's guard (point 3): patterns `Tooltip(`, `showModalBottomSheet(`, `showBottomSheet(`, `showDialog(`, `ListTile(`, `IconButton(`; **remove `Icons\.info`** (the Disclaimer row and screen legitimately use the `info` icon); the theme picker is covered because it opens through `showBudgetSheet` in `core/`; help-copy file = `lib/core/copy/help_copy.dart` (screen copy lives in `screen_copy.dart` and is not a help string). **§1.2**: Coming soon rows read `<Label>, coming soon, not available yet. <Description>`; the picker does have `Done`. **§2.3**: notes 1–4 resolved (design now uses a help sheet with Got it, `More about <label>`, hint has Got it + ×, descriptions wrap and never truncate). | Must fix (Tester, T-126; blocks T-116, T-118) | Scheduled as T-126. |
| 2 | **Design conflicts.** All four from test §2.3 are resolved in the design: (i) opens a help sheet with title, scrolling body and a pinned **Got it** (help-pattern §3); screen-reader label `More about <label>` (design §7.11b, help-pattern §3.1); hint card has Got it **and** × (§7.11c, help-pattern §4.1); description "max 2 lines" changed to "aim for two lines, wraps, never truncated" (design §7.11a, edited by the PM at Gate 2). | Resolved | — |
| 3 | **Shared-component guard (T-119).** Use one list for the plan guard and TC-004-08: `Tooltip(`, `showModalBottomSheet(`, `showBottomSheet(`, `showDialog(`, `ListTile(`, `IconButton(` are not allowed in `lib/features/`. Do **not** ban `Icons.info` (see point 1). | Must fix (Developer, T-119) | Written into TASKS T-119. |
| 4 | **Rule for navigation controls clarified.** F-004 §2.3/§2.4 now say: standard navigation controls (tabs, Next, Skip, ×, Done, Got it, Get started, Not now, I understand) need a screen-reader hint; a long-press tooltip is required only for icon-only controls and the bottom tabs. This is Material guidance (tooltips are for icon-only controls) and is exactly what the §5 tables already specify, so TC-004-06 can pass as written. `NavTooltip` may still be used on Next/Skip. | Resolved | Doc edited. |
| 5 | **Hint scrolled out of view (§9 Q1).** Acceptable: it is still not seen and shows again next time; AC-10 is met. | Resolved | — |
| 6 | **Copy as Dart constants (§9 Q2).** Approved: `abstract final class HelpCopy` / `ScreenCopy` with `static const` strings in `core/copy/`. Moving to `gen-l10n` is a mechanical later change when a second language is approved. | Resolved | — |
| 7 | **Semantics lint (§9 Q3).** `help_rule_test.dart` is enough; every later phase adds its screens to it. No custom lint. | Resolved | — |
| 8 | **Focus return (§9 Q4).** Keyboard focus in widget tests + TalkBack by hand (TC-004-04). If Android ignores the `FocusSemanticEvent`, report it; do not fake it. | Resolved | — |
| 9 | **Hint keys.** F-002 plan §3 (`hint.<tab>.v1.seen`) and §3 here (`hint.<id>.seen`, id `home.v1`) produce the same four keys. Keep the keys only in `preference_keys.dart`. | Resolved | — |

## 11. Implementation notes *(Developer, filled in during the build)*
Deviations from the plan and why (each approved by the Project Manager).

### T-116 / T-117 (Developer, 2026-11-06)
1. **`showBudgetSheet` pushes its own `ModalBottomSheetRoute` subclass instead of calling `showModalBottomSheet`.** The only change is that the scrim ignores taps until the entrance animation has completed. With the stock route the second tap of a double tap on (i) lands on the scrim and closes the sheet it just opened, so TC-004-17 ("exactly one explanation") failed. All four close paths (Got it, scrim, swipe down, back) work as before once the sheet is open. Everything else is the same as `showModalBottomSheet` (captured themes, scrim label and hint, `isScrollControlled`, 90 % max height, theme scrim colour, motion tokens, none with Remove animations).
2. **Review C1: the sheet draws its own frame.** The route's Material is transparent with elevation 0 and no Material drag handle; `BudgetSheetFrame` paints `surface`, `radiusXl` top corners, `context.budgetElevation.sheet` (the Light shadow; an empty list in Dark and Dim) and a decorative 32 × 4 dp handle 8 dp from the top. A child cannot draw the shadow under Material's own handle, so the handle moved into the frame. The handle has no semantics of its own (Material's handle offers a "dismiss" action); the sheet still closes by Got it, back and the scrim for TalkBack users.
3. **Review C2: no `MergeSemantics` on a row that has an (i).** Nothing can escape a `MergeSemantics` (checked in the Flutter source: `mergeIntoParent` is inherited by every descendant), so a container boundary inside it would not help. `BudgetListRow(info:)` therefore uses one explicit `Semantics(container: true, label, button, enabled, hint)` node for the row; the `InkWell`'s tap lands on it, and the `InfoButton`'s own container node becomes a separate child item `More about <label>`, button. On such a row `trailing` is excluded from semantics, so it must be decorative (chevron or value; the Theme row in T-109). Rows without an (i) keep the approved E5 `MergeSemantics` form, so a trailing `Switch` is still part of the labelled row.
4. **Placing the (i) after the label's last word with a 48 dp target.** `LabelDescription` measures the label with a `TextPainter` (same style and text scaler) and positions the `InfoButton` 4 dp after the end of the last line; the label keeps 37 dp free on its right for it. To keep the 48 × 48 target inside the widget (hit-testing never reaches outside a box), the text gets an inset of (48 − label line height) / 2 above and below (14 dp at 1.0), and `BudgetListRow` takes that inset off its own 12 dp vertical padding, so the row height is unchanged at 1.0 (label 14 dp from the top instead of 12).
5. **`ScreenCopy` created in T-116** (the plan put it in F-003), because Got it is needed by the help sheet. `HelpCopy` already holds the F-002 Theme strings (row descriptions, (i) body, row hint, option descriptions, Done hint) so T-109 only uses them.
6. **`BudgetButton` gains `semanticsHint`** (the Got it hint `Close this explanation`; later the hint card's Got it and F-005 buttons), merged into the button's own node. `NavTooltip` merges its hint into the control's node the same way and sets `excludeFromSemantics` on the `Tooltip`, so the text is read once.
7. **Test files and component-level proof.** Tests live in `test/core/help/label_description_test.dart`, `test/core/help/help_sheet_test.dart` and `test/copy/copy_tables_test.dart` (TC-004-06 copy check). TC-004-02/-03/-05/-16/-17/-19/-20 run on a host row that carries the Theme (i) copy; their Settings-level steps (Theme (i) does not open the picker, Settings scroll offset) are added when T-109 builds the Theme row. A NavTooltip component test is filed under TC-004-06 as an interim aid (D6 rule).
8. **`InfoButton` uses `InkResponse`** (40 dp circular ripple, help-pattern §3.1) rather than `IconButton`; focus returns through its `FocusNode` plus a `FocusSemanticEvent` (TalkBack check stays manual, TC-004-04).

**PM Gate 3 (2026-11-06, `docs/reviews/code-phase-1.md` §T-116 … T-114):** items 1–8 approved (F4-1…F4-8; D-031, D-032). Item 2: every sheet opened through `showBudgetSheet` must contain its own visible close button. Item 4 (measured placement) is approved with Must fix M1: measure with the style `Text` really uses, including the Bold text setting. Item 1 (scrim guard) is approved with Must fix M2: the scrim becomes dismissible only after the entrance animation **and** `kDoubleTapTimeout`, so the guard also works with Remove animations. The Developer adds both fixes here as item 9.

9. **Review M1 and M2 (Developer, 2026-11-06).**
   - **M1, Bold text:** `LabelDescription._withInfo` resolves the measured style exactly as `Text` does: `DefaultTextStyle.of(context).style.merge(labelStyle)`, then `FontWeight.bold` merged in when `MediaQuery.boldTextOf(context)` is true. The `TextPainter` also takes `textWidthBasis` and `textHeightBehavior` from the `DefaultTextStyle` (falling back to `DefaultTextHeightBehavior.maybeOf`), as `Text` does. New test `TC-004-05 info button follows the last word with bold text on` (D6): a 240 dp host with the label `How this app works` (wraps at 2.0), Bold text off and on × 1.0 and 2.0; the gap from the end of the **real** label's last line (`RenderParagraph.getBoxesForSelection`) to the (i) is 4 ± 1.5 dp and the (i) is on that line. It loads the bundled Plex/Bricolage fonts first (`test/helpers/bundled_fonts.dart`): in the square test font every weight has the same width, so the check could not fail. Proven: with the bold merge disabled the gap is 1.96 dp and the test fails.
   - **M2, double tap with Remove animations:** `_BudgetSheetRoute.barrierDismissible` is now `_doubleTapWindowOver && animation.isCompleted`. A `Timer(kDoubleTapTimeout)` started in `didPush` sets the flag and calls `changedInternalState()` if the route is still active; it is cancelled in `dispose`. Got it and Back are unaffected. D-031 already states the rule. New test `TC-004-17 double tap with remove animations opens one explanation` (D6): Remove animations on, two taps 50 ms apart → exactly one sheet, route count +1; after 300 ms a scrim tap closes it. Proven: without the time guard the sheet closes at once and the test fails. TC-004-03 stays green without changes (its 320 ms entrance outlasts the 300 ms guard).
   - `pumpBudgetWidget` / `setUpScreen` gained `disableAnimations`.

### T-118 (Developer, 2026-11-10)
10. **Collapse with `AnimatedSwitcher` (size + fade) instead of `AnimatedSize` + fade.** The card is replaced by an empty full-width box; the switcher's `SizeTransition` from the top and `FadeTransition` give the help-pattern §4.3 collapse over `motionEmphasis` with `decelerate`, and both become instant with Remove animations through `BudgetMotion.of(context)` (TC-002-45). `AnimatedSize` would need the old card kept in the tree by hand while it shrinks.
11. **Focus after a dismissal (help-pattern §4.3, §7 "TalkBack order and focus").** The card sits in a `Focus` node that is never focused itself. On Got it or ×, if keyboard focus is inside the card or a screen reader is on (`MediaQuery.accessibleNavigationOf`), focus steps forward with the normal traversal until it leaves the card, and a `FocusSemanticEvent` is sent from the new item (on Settings: the Theme row). A plain finger tap moves nothing. New test `TC-004-22 dismissing a hint moves focus to the next item` (D6). TalkBack itself is still checked by hand (TC-004-04 style, T-120).
12. **Review N1 as a named constructor.** `InMemoryPreferencesStore.allowing(allowList, [values])` instead of an optional `allowList` parameter, so the unrestricted `InMemoryPreferencesStore()` used by older store-level tests is unchanged. The app harness and the runtime fallback use `PreferenceKeys.allowList`. N3: `preferences_providers_test.dart` uses `ProviderContainer.test()`.
13. Back with a hint visible is covered by `TC-003-21 back closes overlays before leaving the tab` part (c) (F-003 §2.7): Back goes to Home, nothing is saved, the hint is still shown on return.

**PM Gate 3 (2026-11-10, `docs/reviews/code-phase-1.md` §Re-review … F-005 phase B1):** item 9 (M1/M2) resolved; items 10–13 approved. Item 11 carries risk R1: on tabs whose next keyboard stop is the tab bar, TalkBack may skip the empty state. This is checked on the device in T-120 and filed as a bug if seen.

### T-119 (Developer, 2026-11-10)
14. **One driver for all Phase 1 states.** `test/support/p1_screens.dart` (`P1Screen`, 18 states, the real app through `AppGate`) is the "P1-screens driver" plan F-002 §11 T-106 item 2 names, so the later F-002 sweeps (TC-002-03/-22/-23/-24/-38…) can reuse it. TC-004-06 runs on a 400 × 1400 view: the traversal leaves out off-screen items of a scrolling page, so a phone-sized view could not list every control at once (Light, X1 as the case says). The four slides are reached with Next and the explainers with Skip / Not now.
15. **The sheet scrim is an allowed extra node.** Every modal route adds a dismiss node over the scrim (label `Close` since T-233, first the stock `Scrim`; tap hint `Close Bottom Sheet`; review F4-2 counts it as a close path). TC-004-06 allows exactly one on the picker and the explanation and none elsewhere; every other unlisted tap target fails.
16. **Guard with word boundaries.** A word boundary before each name (`Tooltip(` etc.), so the shared `NavTooltip(` in `features/` is allowed (it is the component the rule asks for). The TC-004-08 §1.1 command as written would list those three lines.
17. **"One home for help copy" checked from the file itself.** The test reads the `HelpCopy` constants from `help_copy.dart` (adjacent literals joined, escapes undone, whole-line comments ignored) and requires each, plus the fixed parts of `moreAbout`, `comingSoon` and `themeChanged`, to occur in exactly that one `lib/` file. A floor of 30 strings stops a broken parse from passing. The copy test also became complete: every `static` string in both copy files needs a literal in `copy_tables_test.dart`.
18. **TC-004-14 lives in `hints_test.dart`** with the other hint cases, not in a new file. No app code or copy changed in T-119.

**Project Manager, Gate 3 (2026-11-11, `docs/reviews/code-phase-1.md` "T-132 shell batch, T-137 crypto, T-119"):** T-119 approved; items 14 to 18 approved. The TC-002-03/-22/-23/-24 sweeps are the new task T-138.

### T-233 (Developer, 2026-11-11)
19. **The sheet scrim label is `Close`** (Gate 3 N1, Designer decision in `docs/reviews/design-phase-1-evidence.md`, design-system §7.8). `showBudgetSheet` passes the literal `'Close'` as `barrierLabel` instead of `localizations.scrimLabel` ("Scrim"); the tap hint stays `Close Bottom Sheet`. `_scrimLabel` in `help_rule_test.dart` follows. The English-only literal sits in code like the other Phase 1 strings; it moves to the copy files with `gen-l10n` if a second language is approved. No visual change; `check.ps1` ALL CHECKS PASSED (336 tests).

**T-120 emulator verification (Developer, 2026-11-11; evidence `docs/reviews/emulator-phase-1/`, details in the T-120 row of `docs/TASKS.md`):** TC-004-11 Pass (hints across a real force-stop and a fresh install). TC-004-07 Partial: control labels, descriptions, hints, sheet and scrim nodes and the nav long-press tooltip all match table 1.2 (Pass); the TalkBack R1 focus check is **Blocked** (adb cannot drive or read TalkBack). TC-004-04 **Blocked**: TalkBack focus return, handle not a stop and scrim node need a human; the N4 keyboard ring check was inconclusive because four injected TAB key events changed nothing on screen. Background/rotation with a sheet open was not in the Pending list and was not run. No app code changed.
