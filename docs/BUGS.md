# Bug List

Owned by the Tester. Statuses: `Open → Fixed – awaiting review → Re-testing → Closed` (or `Reopened`).
Severity: **Critical** (wrong money, data loss, crash) · **High** (feature broken) · **Medium** (wrong in some cases) · **Low** (cosmetic).

## Summary
| ID | Title | Task | Severity | Status |
|---|---|---|---|---|
| B-001 | Predictive back on Settings shows only the back chip, no Home preview | T-111/T-115 | Low | **Closed 2026-11-11** (option b, D-065; no code change) |

## Details
<!-- Use this format:
### B-001: <short title>
Task: T-xxx · Severity: … · Status: Open
Steps to reproduce: 1… 2… 3…
Expected: …
Actual: …
Evidence: …
Cause & fix (Developer): …
Regression test: <test name>
-->

### B-001: Predictive back on a tab other than Home shows no Home preview
Task: T-115 (T-111 shell) · Feature: F-003 · Severity: Low · Status: Closed (2026-11-11, option b, D-065)
Steps to reproduce: 1. Android 17 emulator (API 37), gesture navigation, debug build. 2. Open Settings. 3. Start a back swipe from the screen edge and hold it. 4. Compare with a held back swipe on Home.
Expected: `docs/features/F-003-app-shell-navigation.md` edge case: "the back preview animation must show the correct destination (Home, or leaving the app). It must never show a blank screen." TC-003-22: on Settings the preview shows Home.
Actual: On Home the window shrinks over the launcher (correct). On Settings only the round back chip appears at the left edge; the Settings page does not shrink and Home is not previewed. It is never blank or black, and the back action itself works (goes Home). The tab Back is handled inside the app, so Android has no previous destination to preview.
Evidence: `docs/reviews/emulator-phase-1/tc-003-22-predictive-back-settings-mid-gesture.png` (Settings, back chip only) and `tc-003-22-predictive-back-home-mid-gesture.png` (Home, correct); Developer note in `docs/TASKS.md` T-115. `docs/design/screens/app-shell.md` does not describe a preview, so the Designer has not specified one.
Decision needed (PM + Designer): (a) fix it so Android 14+ can animate the Home preview for tab Back; or (b) relax the F-003 sentence (never blank; preview only when leaving the app) and reword TC-003-22. Closing rule: (a) retest on the emulator, full regression; (b) feature doc and TC-003-22 updated, then Tester closes.
PM decision (Gate 4, 2026-11-11): option (b), D-065. No code change. Closing rule: feature doc sentence reworded (T-229), TC-003-22/-32 already reworded by the PM, Tester closes (T-230).
Cause & fix (Developer): none needed; the in-app tab Back (`PopScope`) is handled by the app, so Android has no destination to animate.
Closed (Tester, T-230, 2026-11-11): the PM chose option (b) (D-065). F-003 section 4 now reads "The back preview must never be a blank screen. Leaving the app from Home shows the system preview of the app shrinking over the launcher. On Dashboard, Transactions or Settings the system's back chip alone is acceptable; releasing goes to Home." (T-229); TC-003-22 and TC-003-32 carry the same wording. Re-run against the reworded text: Home shows the app shrinking over the launcher, Settings shows only the back chip and is never blank, release goes Home (R2 screenshots, opened by the Tester, plus TC-003-10/-11/-20 for the Back result). Full regression run 2026-11-11 (R3): `tool/check.ps1` ALL CHECKS PASSED (336 tests), integration tests 2 of 2, `tests/REGRESSION.md` run R3. No open bugs remain.
Regression test: TC-003-32 in `tests/F-003-app-shell-navigation.md` section 3 (manual on the emulator; an automated test with this ID after a fix).
