# Phase 3 sign-off (Gate 5) - Project Manager

Date: 2026-11-24 · Decisions: D-106 to D-110 · Task T-501

**Verdict: Phase 3 passes Gate 5.** All eight features (F-010 to F-017) are Done. What is left is the CEO report and the Owner's approval (Gate 6), then the one Phase 3 commit (CLAUDE.md rules 5 and 9).

## 1. Gate 3 of the six test-only changes (T-475, T-476, T-477, T-490, T-492, T-494)
| Check | Result |
|---|---|
| Test-only | Yes. They touch `app/test` and `app/integration_test` (including `real_app.dart`). No `app/lib` file is newer than the last green `tool/check.ps1` (`s9-final-check.txt`, 2026-11-24 19:12). The only `lib` edits of 23 Nov are the B-006 fix, read and accepted (small `ChunkedText`, painter disposed, copy unchanged, TC-010-60 proves it) |
| Tests carry TC IDs | Yes (the check step "test names start with TC-NNN-NN" passes; the model test for TC-011-03..-07 and -40 names them) |
| No limit loosened | Yes. `calendar_500` 500 ms and `home_500` 1,000 ms, worst of 5 with run 0 counted. They now time from before `pumpWidget` to the final cells with the seed sums computed in the test, which is stricter than AC-18 / AC-17 |
| Probes proven | Developer probes are in plans F-010 and F-011 section 11. I re-applied three in a scratch copy outside the project: change days without the `superseded` filter (G4), under-one-rupee threshold `<= 100` (G7a, grid and labels). All failed their named tests (TC-011-19, TC-011-38). Scratch copy removed. T-490 and T-492 are measurement fixes; the number went from 0 ms to 97-190 ms |
| Suite | `flutter analyze` clean; full `flutter test` 1,298 of 1,298 green (run by me, 2026-11-24) |

## 2. Rulings on the Tester's open points
- **TC-016-35 keyboard at 2.0x on 360 x 640 dp (D-107): acceptable, not a bug.** The row is reachable by scrolling, nothing is cut, Save is reachable, the draft is kept. The pass rule is reworded: visible above the keyboard at 1.0x to 1.3x, reachable by scrolling at 2.0x on the smallest phone. Nice to have T-504 (Designer).
- **TC-014-51 flash, TC-016-35 missing walks (D-108): may stay Partial.** The flash is cosmetic and arrival at the right place is proved in both settings; the delete sheet and Light landscape are covered by the four-theme sweep and by the walked discard sheet and Dim landscape. Optional five minutes for Tester 1; Nice to have T-503 (a test of the flash).
- **`transactions_500_test.dart` TC-009-19 (D-109): leave as is.** It passes in debug (724-905 ms) against 1,000 ms, so it is stricter, not broken. `calendar_500` and `home_500` do exit 1 in debug (profile passes, 333 and 190 ms); a debug guard like D-100 is Nice to have T-502, not a blocker.
- No fix is needed from the Developer before sign-off.

## 3. Records
- Bugs: B-001 Closed (D-065), B-002 Closed by ruling (D-100), B-003 Closed (test-script fault, 3 of 3 green), B-004 Closed (profile worst 333 ms, D-094), B-005 Closed (5 of 6 clean, first-run flake noted), B-006 Closed (device, TC-010-60). I corrected the B-005 status line and added the B-003 closure line so the summary table, headers and details agree. None is above Medium; no High or Critical bug was ever open.
- `docs/features/INDEX.md`: F-010 to F-017 Testing -> Done. `plans/phase-3-overview.md`: feature table Done and the sign-off section filled. README status line updated. `docs/TASKS.md`: stale "Ready for test" / "Code review" / "In progress" rows of Phase 3 set to Done (55 rows), T-475 to T-477, T-490 to T-494, T-496, T-501 and the Tester 1 session tasks (T-392, T-409, T-430, T-445) Done; new Nice to have T-502, T-503, T-504.
- **One records fix to flag:** the case-row statuses of Tester 1's device cases in `tests/F-011`, `F-013`, `F-014`, `F-015`, `F-016` still said Fail or Pending although the Tester's own notes of 2026-11-24 record Pass. I re-marked the rows and totals from those notes (each row says "re-marked by the Project Manager"); nothing was re-run or changed in substance.

## 4. Final numbers per feature (cases)
| Feature | Cases | Pass | Partial (accepted) | Blocked (TalkBack) |
|---|---|---|---|---|
| F-010 | 59 | 58 | 0 | 1 |
| F-011 | 66 | 62 | 3 (TC-011-32, -33, -58) | 1 |
| F-012 | 74 | 73 | 0 | 1 |
| F-013 | 60 | 59 | 0 | 1 |
| F-014 | 60 | 58 | 1 (TC-014-51) | 1 |
| F-015 | 67 | 66 | 0 | 1 |
| F-016 | 47 | 45 | 1 (TC-016-35) | 1 |
| F-017 | 37 | 36 | 0 | 1 |

## 5. Gate 5 checklist
- [x] Every feature has its three files complete (doc section 7, plan section 11, test report)
- [x] No open High or Critical bug
- [x] Final full regression green: `tool/check.ps1` ALL CHECKS PASSED on the final code, 100 % domain coverage, TZ matrix identical in UTC, PST8PDT, IST, T-496 20 of 20 for both Home states, emulator and profile runs on record, REGRESSION checks 22 to 31
- [x] No money rule changed in Phase 3 (display only; D-058 formula was the Owner's)

## 6. Open items for the CEO report (none blocks)
1. TalkBack walks, Owner recommended not required (D-066, D-097, D-104): TC-010-42, TC-011-36, TC-012-34, TC-013-31, TC-014-29, TC-015-39, TC-016-24, TC-017-27 (steps in `tests/PHASE-3-SUMMARY.md` 3.3); the Phase 1 carry-over cases and TC-007-48 (two phones).
2. Grey-scale look at the calendar, one minute (D-096).
3. Partial and accepted: TC-011-32, -33, -58 (D-099), TC-014-51 (D-108), TC-016-35 (D-107, D-108).
4. Thin margins to watch: search 273 of 300 ms (T-469 armed, 200 ms debounce pre-approved), transactions list debug 905 of 1,000 ms.
5. Nice to have: T-454, T-466, T-502, T-503, T-504, the Gate 3 polish items.
6. Before the commit (Orchestrator): `git status` shows no secrets or build outputs; one more `tool/check.ps1` only if any file under `app/` changes after 2026-11-24 19:12 (none did at the time of sign-off).
