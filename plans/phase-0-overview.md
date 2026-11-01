# Phase 0 — Setup & team: Overview

**Status:** Signed off by the Project Manager (Gate 5, 2026-11-01). Remaining steps: the CEO phase report, then the Owner's approval. T-010 (the Orchestrator's phase commit and push) and TC-001-48 (the Tester's post-push check) follow the CEO report.

## Phase goal *(CEO)*
- **At the end of this phase the Owner can:** open the project and see a real (but empty) Flutter app in `app/` that starts, passes its automated checks with zero problems, and — once Android Studio is installed — opens on the Android emulator showing a simple placeholder screen. The Owner can also read, in plain language, which core libraries the team chose and why (`docs/DECISIONS.md`).
- **In scope:**
  - Agent team, workflow docs, templates, feature index and regression checklist *(already done before this phase overview)*.
  - **F-001 Project foundation:**
    - Flutter project created in `app/` (Android target).
    - Folder layout from `docs/STANDARDS.md` section 3: `lib/core/`, `lib/data/`, `lib/domain/` (pure Dart), `lib/features/`.
    - Strict lint rules, with `flutter analyze` reporting zero issues and `dart format` clean.
    - Test setup: `flutter test` runs and passes at least one real test, with tests named by test case ID.
    - A minimal placeholder app that launches (one plain screen — no design, no real features).
    - Git repository initialised with a proper `.gitignore`. **No commits are made until the Owner approves committing.**
    - Core library choices (state management, local database, logging, lints, etc.) recorded in `docs/DECISIONS.md`, latest stable versions, no paid dependencies.
  - Everything above must be doable and verifiable on the laptop **without** the Android SDK (`flutter create`, `flutter analyze`, `flutter test` all run on the host).
  - **Last item, may complete later:** "app runs on the Android emulator". This depends on the Owner finishing the Android Studio / Android SDK / emulator install (README section 13). It is the only Phase 0 item allowed to wait for that; the phase cannot be signed off until it is verified.
- **Out of scope:**
  - Design system, colours, fonts, the 4 themes, custom icons (Phase 1).
  - Navigation shell and any real screens: onboarding, home, calendar, settings (Phases 1–3).
  - Database tables, budget engine, money logic (Phase 2).
  - SMS reading, permissions, notifications (Phases 4–5).
  - Commits by agents during the phase, force-pushes and CI. (Changed 2026-11-01 by Owner decision D-014 / CLAUDE.md rule 9: the remote `origin` = `https://github.com/astiktyagi27/Daily-Budget-App.git` is set up in T-001, and the Orchestrator makes one phase commit `Phase 0: Project foundation` and pushes it to `main` after Gate 5 and the CEO report — task T-010.)
  - Real-phone testing and release builds (Phases 6–7).

## Features in this phase *(CEO + Product Manager)*
| ID | Feature | Doc | Plan | Tests | Status |
|---|---|---|---|---|---|
| F-001 | Project foundation | [docs/features/F-001-project-foundation.md](../docs/features/F-001-project-foundation.md) | [plans/F-001-project-foundation.md](F-001-project-foundation.md) | [tests/F-001-project-foundation.md](../tests/F-001-project-foundation.md) | Done |

## Build order *(Developer, approved by Project Manager)*
1. **F-001 Project foundation** — the only feature in Phase 0; everything later builds on it. Approved at Gate 1 on 2026-11-01. Task order (see `docs/TASKS.md`):
   1. T-001 git repo at the root (`git init -b main`), `.gitignore`, `.gitattributes` — first, so ignore and line-ending rules exist before any generated file.
   2. T-002 `flutter create --empty --platforms android …`, application ID placeholder `com.dailybudget.app`.
   3. T-003 strict lints (`very_good_analysis` 11.0.0).
   4. T-004 layer folders + domain purity guard test.
   5. T-005 placeholder screen + widget tests.
   6. T-006 one-command check script `tool/check.ps1`.
   7. T-007 record decisions in `DECISIONS.md` (can run any time after T-003, in parallel with T-004–T-006).
   8. T-008 run on the Android emulator — **Blocked** until the Owner finishes the Android Studio / SDK / emulator install (README §13); Phase 0 cannot be signed off before it passes.
   - T-009 (Tester) tidies the test case file in parallel; must be done before test execution (Step 8).
   - T-010 (Orchestrator) — last: one phase commit + push to `origin main` after Gate 5 and the CEO report (CLAUDE.md rule 9).
   - Run T-002 → T-005 as soon as possible: the AC-12 "no Android SDK" check is only reproducible until the SDK install finishes (if it is too late, AC-12 is recorded as "precondition no longer reproducible" — not a blocker).

## Phase sign-off *(Project Manager — Gate 5)*
**Signed off: 2026-11-01, Project Manager.** Phase 0 is complete apart from the post-sign-off publishing steps below.

- [x] Every feature Done (doc, plan and test files all complete). F-001: doc §1–§8 complete, including the technical section §7; plan §10 (Gate 1) and §11 (implementation notes 1–9, with every deviation approved); test file §4 has runs R1 and R2, and §5 has the Tester reports and the PM's Gate 4 reviews. INDEX = Done. Tasks T-001 … T-009 and T-011 are Done.
- [x] No open High/Critical bugs. `docs/BUGS.md` has no bugs at all for Phase 0.
- [x] Final full regression green: run R2 on the machine with the Android SDK. `tool/check.ps1` ALL CHECKS PASSED (`dart format` clean, `flutter analyze` 0 issues, `flutter test` 5/5, test names valid). All Regression-yes cases pass, and `tests/REGRESSION.md` checks 1–9 pass, including the app running on the emulator (Android 17 / API 37). The PM re-ran `tool/check.ps1` independently at sign-off and it passed again.
- **All 13 acceptance criteria of F-001 pass.**

**Improvements made beyond the original plan**
1. **Automatic architecture guard.** The test `TC-001-06` fails the build if `domain/` ever imports Flutter, so STANDARDS §3 is enforced for every future phase, not just checked once.
2. **One-command check (`tool/check.ps1`).** It runs format, analyze, test-name validation and tests in one go. It fails fast, restores the shell's folder even after an error, and works from PowerShell and Git Bash on the path with a space.
3. **Test names are enforced.** The script rejects any test whose name does not start with a TC ID, so traceability from tests to requirements is automatic.
4. **Stricter "no buttons" test.** TC-001-15 also checks the accessibility tree for anything tappable, so a new tappable widget of any type is caught.
5. **Large-font layout from day one.** The placeholder is proven to fit at 3× text size on a small 320×568 screen (TC-001-43), following STANDARDS §7.
6. **Privacy hardening of git.** The ignore rules also cover `.env` files, certificates and private keys, and local database files that could contain personal SMS data. This was in place before the first commit.
7. **Line-ending policy (`.gitattributes`).** Formatting checks give the same result on Windows whatever the git settings are.
8. **Modern Dart 3.13 code style** (D-024) and a strict, maintained lint set (`very_good_analysis` 11).
9. **Reproducible setup.** Every tool and library version is recorded (D-015 … D-025), including the NDK pin and the README step a fresh machine needs.

**Open items carried forward (none blocking)**
- **T-010 (Orchestrator), after the CEO report:** run `tool/check.ps1`, check `git status` for secrets and build outputs, make the one commit `Phase 0: Project foundation`, and run `git push -u origin main`. Then the Tester runs **TC-001-48** once, and the PM retires **TC-001-19**.
- **Owner decisions later:** the final application ID and app name (Phase 7, D-021), and database encryption (Phase 2 plan).
- **Phase 1:** switch on Windows Developer Mode before the first plugin package is added.
- **Phase 2:** re-check that the native SQLite build compiles with NDK 30 (D-025), and consider extending the domain guard to check layer direction (Gate 1 point 12).
- **Tester tidy-up:** remove the historical "Blocked" wording from TC-001-29 and TC-001-46.
