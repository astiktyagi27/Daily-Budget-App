# Phase 1 Report — Design system & app shell

*Written by the CEO for the Owner. 2026-11-11.*

**Your approval:** Waiting for you (Gate 6).

## In one line
The app now has its real look and feel: four themes, four main tabs, a help pattern with first-time tips, and a welcome tour. All automated checks pass and there are no open bugs. The Project Manager signed the phase off (Gate 5). It needs your approval before it is committed and pushed to GitHub.

## What was built
Four features, all Done. There is no money, bank or SMS logic yet; every tab shows a placeholder.

- **F-002 Design system and themes.**
  - Final colours, fonts and shapes. One accent colour; green means saved, red means overspent.
  - Four themes: Light, Dark, Dim and Auto. Auto follows the phone. Your choice is remembered after the app is closed. The default is Auto.
  - Fonts are bundled inside the app, so nothing is downloaded and the app makes no network calls.
  - Text contrast, touch-target size and very large system fonts were checked in every theme.
- **F-003 App shell and navigation.**
  - Bottom bar with Home, Dashboard, Transactions and Settings. Each tab has an empty-state message.
  - Settings has a working Theme row and seven "Coming soon" rows for later features.
  - The app name and Android launcher label are "Daily Budget App" (placeholder until Phase 7).
  - The Phase 0 placeholder screen is gone.
- **F-004 Help and tooltip system.**
  - The shared "label + short description + (i)" pattern that every later button, setting and number will use. Tapping the (i) opens a short explanation.
  - A one-time tip on each main tab. It stays dismissed once you close it.
- **F-005 Welcome tour and permission explainers (screens only).**
  - A short welcome tour on first launch, remembered once finished or skipped.
  - Explainers for SMS and notifications: why each is needed, and that data never leaves the phone. Also the disclaimer (one bank account, no credit cards, detection may need correcting).
  - **No button on these screens asks for a real permission.** The real requests come in Phases 4 and 5. An automated test enforces this.

## How to see it
1. Start the emulator in Android Studio, then run `flutter run` in a terminal from the `app` folder.
2. Walk through the welcome tour, then try the four tabs.
3. Open Settings and change the theme. Close and reopen the app to see that it is remembered.
4. Tap an (i) to see the help sheet.
5. Screenshots are in `docs/reviews/emulator-phase-1/`. The Designer's review is in `docs/reviews/design-phase-1-evidence.md`.

## Quality
| Item | Result |
|---|---|
| Tasks done | 44 / 44 for Phase 1 |
| Automated tests | 336 passed, 0 failed (`tool/check.ps1`: formatting, code checker, test names, all tests) |
| Emulator integration tests | 2 of 2 passed (theme and onboarding survive a restart with the real storage plugin) |
| Test cases (all four features) | 135 cases: 131 Pass, 2 Partial, 2 Blocked-needs-human, 0 Fail. The Partial ones are Pass except for their TalkBack step |
| Per feature | F-002 47/47 Pass. F-003 31 (29 Pass, 1 Partial, 1 Blocked). F-004 25 (23 Pass, 1 Partial, 1 Blocked). F-005 32/32 Pass |
| Other checks | Same results in three time zones. Money-logic code coverage 100%. Fresh install on the emulator works |
| Bugs found / fixed / still open | 1 / 1 / 0. B-001 (Low) was closed by decision D-065, see below |
| Analyzer issues | 0 |

## Improvements beyond the plan
*(From the Project Manager and Designer reviews)*
- Custom bottom bar with a sliding marker; labels stay on one line at large text sizes.
- Every sheet opens one way, with a visible close button. The scrim ignores the second tap of a double tap, so a sheet never closes by accident.
- Each row reads as one item for screen readers. The (i) is a separate button.
- Theme and sheets respect Android's "Remove animations" setting.
- The first screen is already drawn in your saved theme, with no flash of the wrong one.
- Finishing the tour with a double tap cannot tap through to the bottom bar (D-044).
- Focus moves to the next item after a tip is dismissed.
- Automatic checks that catch hard-coded colours, hidden network use and unwanted permissions.
- Screens were tested across 18 combinations of theme, text size, rotation and bold text.
- `dart analyze` was added to the health check so the Riverpod lint rules are enforced (D-017).
- The Designer reviewed 50 emulator screenshots and found nothing that must be fixed.

## Problems we faced
- **Predictive back (B-001).** On Dashboard, Transactions and Settings, the Android back-swipe shows only a round back chip, not a preview of Home. It is never blank and Back works. A real preview would break the tab design. See D-065.
- **Font digits.** The chosen body font has no "tabular numbers" switch because its digits are already equal width. Amounts still line up. The test was reworded and the Project Manager accepted it.
- **Interrupted runs.** Some Developer runs stopped partway. Each was found, checked against the plan and finished.
- **A plugin-lint gap.** `flutter analyze` did not run the Riverpod lint rules. The health check now runs `dart analyze` as well.
- **Windows Developer Mode is not needed** after all (D-029): this app is Android-only.

## Risks ahead
- **TalkBack was not run on a real phone** (see below). The widget-test proofs are green. Phase 3 puts real content on these screens, so a real-phone check is best done before then.
- **Permission wording must be re-checked** when dependencies change. Phase 2 adds the database and Phase 4 adds SMS.
- **Text at 2x size** has four small cosmetic issues, listed under Nice-to-haves.

## Decisions needed from you
1. **Question:** Do you approve Phase 1 so the Orchestrator can commit it and push it to GitHub as "Phase 1: Design system and app shell"?
   **Options:** A) Approve. B) Ask for changes first.
   **Recommendation:** A. Every automated check passes, there are no open bugs, and the four open TalkBack cases are polish, not safety. Each is covered by a passing widget test and cannot be run by an agent.

**For your information (no action needed unless you disagree):**
- **D-064 Permission line.** The release app asks for no permission itself: no internet, SMS or notifications. One extra line appears in the built file, an Android library's own internal permission that only this app can use. A literal "zero permission lines" cannot be met with Android's standard libraries. Nothing leaves the phone and no access is granted. Permissions are an escalation topic, so you are being told.
- **D-065 Back-preview wording.** The Project Manager relaxed one sentence in the F-003 feature doc. On Dashboard, Transactions and Settings the back chip alone is acceptable. Leaving the app from Home shows the app shrinking over the launcher. This was a small cosmetic relaxation, not a money, permission or privacy change, so it was not escalated.
- **D-066 Sign-off with four TalkBack cases open.** These four cases are TC-003-03 step 4, TC-003-18, TC-004-04 and TC-004-07's focus check. They are not blocking the phase, provided their widget-test proofs stay green (they are). Marking them Pass would be false and Fail would be wrong. You may overrule this.
- **D-063 `integration_test` dev dependency.** This is a testing package that ships with Flutter. It is not in the released app and costs nothing. It holds the two on-device tests. Please note it, since new dependencies are an escalation topic.

## TalkBack check on a real phone (optional, recommended, about 15 minutes)
TalkBack is Android's screen reader. We could not drive it from the computer, so four cases are marked "Blocked-needs-human". The exact steps are in [`tests/PHASE-1-SUMMARY.md`](../../tests/PHASE-1-SUMMARY.md), under "TalkBack cases for the Owner on a real phone". In short:
1. Check the bottom tab says "selected" (TC-003-03).
2. Swipe through every tab and confirm everything is reachable in a sensible order (TC-003-18).
3. Check focus returns to the (i) after closing a help sheet (TC-004-04).
4. Check focus lands on the page content, not the tab bar, after dismissing a tip (TC-004-07).

Write Pass or Fail and what TalkBack said. A failure becomes a bug fixed in Phase 3. This is not needed for your approval.

## Open Nice-to-haves (none blocks approval, all To do for Phase 3)
- **T-234:** at 2x text size the theme picker hides the selected option, with no cue that it scrolls.
- **T-235:** at 2x text size the welcome tour body is cut off, with no cue that it scrolls.
- **T-236:** at 2x text size the "Transactions" tab label sits slightly higher than the others.
- **T-237:** at 2x text size the ledger on tour slide 2 uses only half the card width.

There are also two small notes: the "Close" label wording could move into the shared copy file (Phase 3), and one animation check used a screenshot burst rather than frame-by-frame.

## Not part of this approval
Phase 2 and Phase 3 work runs in parallel with Phase 1, as you decided in D-033. It is **not** part of this approval:
- **Phase 2:** the budget engine (F-006) is Done. The database, month setup and manual transactions (F-007 to F-009) are planned or in progress. Phase 2 will be signed off, reported and approved separately.
- **Phase 3:** planning only (calendar, dashboard, Home figures, Transactions content).

The Phase 1 commit will contain only Phase 1's files.

## Next phase
**Phase 2 — Budget engine and month setup:** the engine and database come first, then the setup screen where you enter salary, salary day and fixed costs, and manual transactions. Phase 3 then puts real content on Home, Calendar, Dashboard and Transactions.
