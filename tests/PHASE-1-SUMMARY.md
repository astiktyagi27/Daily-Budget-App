# Phase 1 test summary (final run R3, 2026-11-11)

Written by the Tester for the Project Manager (Gate 5 input). Source files: `tests/F-002 ... F-005`, `tests/REGRESSION.md`, `docs/BUGS.md`.

## Verdict
**Green. No failing case, no open bug.** Everything a script or the emulator can check passes. Four TalkBack cases cannot be run by an agent and stay **Blocked-needs-human** (D-066, not blocking Gate 5; listed as an open item for the phase report).

## Totals per feature
| Feature | Cases | Pass | Partial | Blocked-needs-human | Fail | Pending |
|---|---|---|---|---|---|---|
| F-002 Design system and themes | 47 | 47 | 0 | 0 | 0 | 0 |
| F-003 App shell and navigation | 31 | 29 | 1 (TC-003-03, step 4) | 1 (TC-003-18) | 0 | 0 |
| F-004 Help and tooltip system | 25 | 23 | 1 (TC-004-07, R1 check) | 1 (TC-004-04) | 0 | 0 |
| F-005 Welcome tour and permission explainers | 32 | 32 | 0 | 0 | 0 | 0 |
| **Total** | **135** | **131** | **2** | **2** | **0** | **0** |

F-004 has one more case than before: TC-004-25 (background and rotation with the help sheet open), added at the PM's request and run in R3 (Pass). No existing ID or title changed. Every AC in F-002 to F-005 has at least one green case; the two "Partial" cases are Pass except for their TalkBack step.

## Run on 2026-11-11 (R3, Tester, no code change)
| Check | Result |
|---|---|
| `tool/check.ps1` (pub get, format, `flutter analyze`, `dart analyze --fatal-infos`, test names, `flutter test`) | ALL CHECKS PASSED, exit 0; 336 tests, all passed |
| `flutter test integration_test -d emulator-5554` (from `app/`) | 2 of 2 pass (TC-002-11, TC-005-16); log `docs/reviews/emulator-phase-1/integration-tests-run-final.log` |
| `tool/tz_matrix.ps1` | PASSED in UTC, PST8PDT, IST; identical hash `B30996982B3C37EB...D59E4` |
| `tool/domain_coverage.ps1` | DOMAIN COVERAGE 100% (lines and branches, 17 files) |
| REGRESSION checks 1 to 12 | Pass (check 5: lock versions read, DECISIONS rows not re-compared; check 6: `print(` scan only) |
| Check 9 (fresh install on the emulator) | Pass |
| New check 17 / TC-004-25 (help sheet, rotation, Home key, reopen) | Pass; evidence `docs/reviews/emulator-phase-1/tc-004-bgrot-*` |
| Checks 13, 14, 15, 16 | Not re-run in R3: no code change since R2, R2 evidence stands (R2 Pass; 16 Partial). The release APK was not rebuilt |
| B-001 (predictive back on a tab) | **Closed** (D-065, F-003 section 4 reworded in T-229, TC-003-22 and TC-003-32 Pass). Honest limit: Dashboard and Transactions back-swipe previews were not photographed; Settings and Home were, and all tabs share one Back handler |
| Bugs | B-001 Closed; none open |

Not covered by an agent run: TalkBack (below), and the Designer's visual review (T-231).

## What remains before Gate 5
1. T-231 (Designer): visual review of the Bricolage headings and the remaining `*-scale2.png` shots. Blocks only if a Must fix is found.
2. T-232 (Developer): Step 9 for F-002 to F-005 (section 7 of each feature doc, INDEX to Done). T-229 and T-230 are done.
3. PM sign-off in the phase overview, then the CEO report. The phase report must list the four TalkBack cases as open items (D-066).
4. Optional, recommended for the Owner: the TalkBack run below, ideally before Phase 3.

## TalkBack cases for the Owner on a real phone (about 15 minutes)
Why these are blocked: adb cannot move TalkBack focus or read its speech, so an agent can neither pass nor fail them. Their widget-test proofs are green (TC-003-02/-17, TC-004-05/-06, hints tests). A failure found here becomes a bug fixed in Phase 3.

Setup: install the app (a debug build from `flutter run`, or the release APK). Settings > Accessibility > TalkBack > On. Finish the welcome tour once. Keep font size at default for the first pass. Swipe right/left moves focus; double-tap activates. For each result write Pass or Fail and what TalkBack said.

**1. TC-003-03 step 4 (bottom tab "selected")**
1. Open the app in the Light theme (Settings > Theme).
2. Swipe right until TalkBack focuses each bottom tab in turn.
3. Pass if the current tab is read like "Dashboard, tab 2 of 4, selected" and the other three do not say "selected". Check all four tabs by selecting each one.
4. Repeat in the Dim theme.

**2. TC-003-18 (walk through every tab)**
1. For font size Default and then Largest (Settings > Display > Font size), and in Light and Dim:
2. On Home, Dashboard, Transactions and Settings, swipe right from the top to the bottom of the screen.
3. Pass if everything is reachable, read in the order top bar title, page content (empty state title and text, or the Settings rows in order), then the four tabs; the "Coming soon" Settings rows are read like "Notifications, coming soon, not available yet. Budget warnings and an end-of-day summary". Write down any control skipped or read twice.

**3. TC-004-04 (focus after closing the help sheet)**
A. Settings tab: focus "More about Theme" (the (i) next to Theme), double-tap. The sheet opens. Focus "Got it", double-tap. Pass if focus lands back on "More about Theme, button".
B. Open the sheet again and swipe through all its items. Pass if the order is the title, the body, then "Got it", with no drag handle and no "Dismiss" stop. Then focus the scrim item ("Close", tap hint "Close Bottom Sheet") and double-tap. Pass if the sheet closes and focus returns to the (i).
C. Same as test 4 below (one run covers both).
D. Needs a physical or Bluetooth keyboard (skip if you have none): press Tab to reach the Theme (i) and a Settings row. Pass if each shows a clear focus ring (about 2 dp) and nothing on the screen jumps. Photograph each.

**4. TC-004-07 R1 and TC-004-04 part C (focus after a hint is dismissed)**
1. On a fresh install (or after Settings > Apps > Daily Budget App > Storage > Clear data) finish the tour so the first-time tip is visible on Home.
2. Focus the tip's "Got it" and double-tap.
3. Pass if focus lands on the page content where the card was (the empty-state title "Your daily budget lives here"), not on the tab bar ("Home, tab 1 of 4"). If it lands on the tab bar, log a Medium bug.
4. Repeat on Dashboard and Transactions (each shows its own tip the first time you open it).
