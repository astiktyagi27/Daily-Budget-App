# Phase 0 Report — Setup & team

*Written by the CEO for the Owner. 2026-11-01.*

## In one line
The app's foundation is ready. An empty starter app builds, passes every automated check and opens on the Android emulator. The Project Manager has signed off the phase, and it now needs your approval.

## What was built
- **The agent team and the way it works.** Six team roles, the workflow, quality rules and templates.
- **F-001 Project foundation**, the only feature in this phase:
  - A real Flutter app in `app/`, for Android only.
  - Tidy folders for the parts of the app we will add later: shared pieces, data, money logic and screens.
  - Strict automatic code-quality rules. The checker currently reports **0 problems**.
  - Automated tests. Each test is named after the test case it proves, so every requirement can be traced to a result.
  - A single placeholder screen showing "Daily Budget App" and "Setting things up. Your daily budget will appear here soon."
  - A version-history (git) repository, set to ignore secrets, keys and any files that could hold personal data. **Nothing has been committed yet.**
  - Every tool and library choice is written down with its reason in `docs/DECISIONS.md` (D-013 to D-025). All of them are free.

## How to see it
1. Open the screenshot of the app running on the emulator: [`docs/reviews/r2-emulator.png`](../reviews/r2-emulator.png). The red "DEBUG" ribbon is normal for a test build.
2. Or run it yourself. Start the emulator in Android Studio, then run `flutter run` in a terminal from the `app` folder.
3. After this report, the Orchestrator publishes the phase to GitHub at https://github.com/astiktyagi27/Daily-Budget-App with one commit, "Phase 0: Project foundation" (D-014).

## Quality
| Item | Result |
|---|---|
| Tasks done | 10 / 11. The last one, T-010 (commit and push to GitHub), comes right after this report |
| Automated tests | 5 passed, 0 failed |
| Test cases (F-001) | 41 passed, 0 failed. 1 waits for the GitHub push, 1 does not apply yet, and 1 was replaced once the Android tools were installed |
| Test runs | R1 (before the Android tools): 40/40 passed. R2 (full re-run on the emulator): 35/35 passed |
| Acceptance criteria | 13 / 13 met |
| Bugs found / fixed / still open | 0 / 0 / 0 |
| Analyzer issues | 0 |
| Code review | Approved with no must-fix items. Four small suggestions were done as T-011 |

## Improvements beyond the plan
*(From the Project Manager's reviews)*
- **Automatic architecture guard.** The build fails if the money-logic layer is ever mixed with screen code, and this check keeps running in every future phase.
- **One-command health check (`tool/check.ps1`).** It runs the formatting check, code checker, test-name check and all tests together.
- **Test names are enforced.** A test without its test-case ID is rejected.
- **Large text works from day one.** The screen fits at 3× text size on a small phone.
- **Extra privacy rules in git.** Keys, certificates, `.env` files and local database files can never be committed by accident.
- **Same results on any Windows setup.** Line endings are fixed so the formatting check behaves the same on every machine.
- **Reproducible setup.** Every version is recorded, so a new laptop can rebuild exactly the same project.

## Problems we faced
- **Android Studio was installed partway through the phase.** We built and checked everything we could without it first, then ran the emulator test once it was ready. This cost some waiting but no rework.
- **An Android component failed to install itself.** Flutter tried to download NDK 28.2 (a toolkit Android needs) and the download failed. You installed the newer NDK 30 through Android Studio, and the project is now set to use it (D-025). Any other computer must install the same NDK 30 version. We will switch back to Flutter's default once Flutter moves to version 30.
- **One rule was relaxed.** The strict rule set required a comment on every piece of code, which does not suit an app. The Project Manager switched off that one rule (D-013).

## Risks ahead
- **Phase 2:** the local database needs the NDK 30 toolkit to build correctly. The Phase 2 plan re-checks this.
- **Phase 1:** plugins will not install unless Windows Developer Mode is on (see below).
- **The app ID `com.dailybudget.app` is temporary.** It cannot change once the app is on Google Play, so it must be final before the first upload in Phase 7.

## Decisions needed from you
1. **Question:** Do you approve Phase 0 (Gate 6)?
   **Options:** A) Approve, and Phase 1 can start. B) Ask for changes first.
   **Recommendation:** A. Every check passed, there are no bugs, and the app runs on the emulator.

**One small action before Phase 1 (not a decision):** turn on Windows Developer Mode under **Settings → System → For developers → Developer Mode → On**. Phase 1 adds plugins, and they need it.

**No action needed now:** the final app name and app ID. Both will be chosen in Phase 7, before the first Play Store upload.

## Next phase
**Phase 1 — Design system & app shell:** colours, fonts and components; the four themes (Light, Dark, Dim, Auto); the main navigation (Home, Dashboard, Transactions, Settings); the help/tooltip component; and the welcome tour and permission screens, without the real logic yet. Each design will be previewed for you in the chat as it is made, and you can give feedback at any time without holding up the work.
