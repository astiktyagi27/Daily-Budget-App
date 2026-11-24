# Code review, Phase 3 foundations (Gate 3)

Reviewer: Project Manager, 2026-11-16. Method: files read only (the orchestrator was running `tool/check.ps1`; no flutter, dart or check run by the reviewer). Approvals below are conditional on that check run being green (analyzer clean, full suite, TC-003-04, -10, -19, -20, -30 and TC-007-11, -12).

| Task | Verdict |
|---|---|
| T-308 shared harness | **Approved**, Ready for test |
| T-389 shared fixtures | **Must fix** (small), back to In progress |
| T-322 month index | **Approved**, Ready for test |
| T-386 selected tab provider | **Approved**, Ready for test |
| T-405 statement launcher seam | **Approved**, Ready for test |

## T-308 Shared harness
- **Correct.** `FakeMoneyStore.watch` without `async*` is the right fix (a cancel of a generator waiting on the next change never finished). It keeps the old behaviour: first emission, an emission per change, `StorageException` as a stream error and then close, a cancelled stream is not woken. A start that finds `readFails` also errors and closes. `readDelay` holds every first emission; `delayReadsOf` and `readFailsFor` act per month and the month index is not affected, as TC-011-49 and -50 need. `readFailsFor` notifies, so open watchers see the failure.
- **Tests can fail.** TC-010-37 (held read then released), TC-011-49 and TC-011-50 (one month held or failing, the other not) assert both sides; TC-010-25 checks direction, amount, note and the net.
- **Sweep skeleton** (deviation 7): accepted. `sweep` runs a list of states through 4 themes x text 1 and 2 x small phone with `expectAccessible`, and the one test uses A13 only. The F-010 body is T-307. Landscape and the other tracks' states are added with their screens.
- **Deviation 2 (data sets live in `phase3_fixtures.dart`, not `phase3_data.dart`):** accepted, cleaner (pure data apart from the store seeding). Plan section 11 of F-010 records it.
- **Nice to have:** none.

## T-389 Shared fixtures: Must fix
Checked against `tests/F-010`, `F-011`, `F-013`, `F-016` section 0: the literals of A, A+cover, A+refund, S, S8+150, F12, F, M-full, canonical M20, O1, OCT-NOV, N, P250, W3, R16, P1, P1b, E2c, E2s, C4, Mx match. Name clashes confirmed: **F12 (F-010) vs F (F-013, F-016)** and **OCT-NOV (F-011) vs O1 (F-013)** are different data sets on purpose, and the file header lists them. Keeping `fixtureF` and `fixtureO1` for the F-013 names and `f12` and `octNov` for the F-010 and F-011 names is right. Category keys carried but not stored (deviation 3) is accepted: the field is data for T-380 and T-420 and nothing reads it yet.

1. **Must fix: dead and stale code.** `m20F010` and `m20cF010` and the test `TC-010-18 the superseded F-010 M20 keeps its own literals` are dead: the Tester has since re-based F-010 on the canonical M20 (`tests/F-010` section 0: "this file no longer has an M20 of its own ... no case uses it"). Delete them, and the header lines 13 to 17 ("the Tester is re-basing ...") and the comment above `m20F010`. STANDARDS section 5 (no dead code).
2. **Must fix: add `m20nc`.** `tests/F-010` section 0 defines **M20nc** (canonical M20 without its cover) for TC-010-17 and -18, "in code: `fixtureM20` month `copyWith(covers: const [])`". It is a shared fixture, so it belongs in this file (one owner). Literals: Saved 2,11,558 · covered 0 · pot 2,11,558 · overspent 73,778 · Left 6,90,000. Rename the canonical M20 test to `TC-010-18 fixtures M20 and M20nc match the engine` and check both.
3. **Must fix: four test IDs name a different case.** The convention "a fixture check is named after a case that uses that data set" is acceptable (it keeps every test findable by TC ID), but these four use an ID whose case is about something else: the N test is `TC-013-10` (A+refund) and should be `TC-013-33` (N); the canonical M20 test is `TC-013-33` (N), see item 2; the F test is `TC-016-05` (A+refund) and should be `TC-016-25` (F, Tue 10 Nov); the A2 and A3 checks sit in one test named `TC-015-03` (A) and should be two tests, `TC-015-05` (A2) and `TC-015-04` (A3).
4. **Rule for the Tester (all helper, seam and skeleton tests):** a test named for a case does **not** close that case. A case is run only when its full test exists (for example TC-010-40 stays open until T-307's sweep, TC-014-01 until T-403, TC-013-04's "Go to Transactions" part until T-384). The Tester's Step 8 reports count a case only with the test that matches the whole case text.
5. **Nice to have:** `TC-012-01 variants of A: A13o, A14, A13 +410` reuses the ID of "opens from the calendar cell". Rename to the first F-012 case that uses each variant when T-340 to T-344 land.

**M-full and the 18,50,000 question (deviation 7): the code is right, the doc is right, no doc task.** `tests/F-013` section 0 (M-full) and `tests/F-014` TC-014-04 / -05 say: spent 19,00,000, refunds 50,000, **net 18,50,000**, Left 1,40,000 (= 19,90,000 - 18,50,000). `docs/features/F-014` section 2.6 and AC-3 say Net spent ₹18,500. "Spent so far" on Home is net of refunds (F-010 §3, D-047). The engine's `totals.spentSoFar` 18,50,000 is therefore what Home and the statement's Net spent show; 19,00,000 is the gross "Spent" line. The comment in the test already says so.

**M20 cover day (deviation 1):** the cover is for **6 Nov** (made 7 Nov 21:00). The earlier "8 Nov" instruction was wrong: 8 Nov is an on-budget day in that seed, so no cover fits there. `tests/F-013` section 0 and F-010 TC-010-16 (`₹200 used to cover days`) agree with 6 Nov. Accepted.

## T-322 Month index
- **Correct and additive.** `MonthRef` is a small class (`BudgetMonth` has no `==`; tests compare the fields). Drift reads `budget_months` only, `ORDER BY start_day DESC`, so a period, fixed-cost or spend write does not re-emit (TC-011-62). The month is built with `BudgetMonth.containing(salaryDay, startDay)`, the same as the existing mapper. The fake sorts the same way. `guardedStream` turns a read failure into a `StorageException` error, never an empty list (TC-011-64). No schema change, no change to existing methods: D-078 (1) holds. F-007 stays Done; TC-007-11, -12 are re-run by the full suite.
- **Tests.** TC-011-59 to -62 share one body for memory Drift and the fake (-63 parity is also a direct comparison), -61 asserts one empty emission and no error, -62 asserts no duplicate and a cancelled listener hears nothing. Drift read failure by dropping `budget_months` (deviation 4): accepted. A closed database throws a `StateError`, not a storage error, so dropping the table is the honest way to get a real read error; `PRAGMA foreign_keys = OFF` first is correct.
- Plan section 11 of F-011 has the note. **Nice to have:** none.

## T-386 Selected tab provider
- **Phase 1 behaviour is unchanged by reading the code.** `selectedTabProvider` starts on Home (AC-7), nothing is saved. `AppShell` keeps the same `IndexedStack`, per-tab `ScrollController`s, `TickerMode` and `FadeTransition`. A re-tap on the selected tab still scrolls to the top and does nothing else; Back on another tab goes Home through `_select`; on Home `canPop` is true so Back leaves the app. The fade now starts in `ref.listen`, so any writer fades the same way (the plan wants that). `previous == next` guard is harmless. No `setState` is lost: `ref.watch` rebuilds.
- `// ignore: use_setters_to_change_properties` has its reason (a Notifier method) and the same pattern exists in `spend_editor_flow.dart`. Accepted.
- **Tests.** `selected_tab_provider_test.dart` (TC-013-04 seam): starts on Home and follows the bar; a write switches the page with no new route and Back goes Home; a new ProviderScope is a new session. They can fail. TC-003-04, -10, -19, -20, -30 are unchanged in `app_shell_test.dart`; the reviewer did not run them: the orchestrator's check run must show them green.
- Plan section 11 of F-013 has the note. **Nice to have:** none.

## T-405 Statement launcher seam
- Same pattern as `monthSetupLauncherProvider`; default does nothing; `openMonthStatement` reads it through `ProviderScope.containerOf(context)`. Signature matches plan F-014 section 5. Tests: default does nothing and pushes no route; an override sees the month and the period start. They can fail. The IDs (TC-014-01) follow the rule in T-389 item 4: the seam tests do not close TC-014-01. Plan section 11 of F-014 says T-402 must keep the signature.
- **Nice to have:** none.

## Decisions on the Developer's seven deviations
| # | Deviation | Ruling |
|---|---|---|
| 1 | M20 cover on 6 Nov, not "8 Nov" | Accepted: 6 Nov is right (orchestrator's slip) |
| 2 | Data sets in `phase3_fixtures.dart`, seeding in `phase3_data.dart` | Accepted |
| 3 | Category keys carried, not stored | Accepted (data for T-380 / T-420) |
| 4 | Test names carry the ID of the case they serve | Accepted with the rule in T-389 item 4, and four wrong IDs fixed (T-389 item 3) |
| 5 | Drift read failure by dropping the table | Accepted |
| 6 | Name clashes F12/F, OCT-NOV/O1 kept apart, in the header | Confirmed |
| 7 | `spentSoFar` net of refunds (M-full reads 18,50,000) | Correct per tests and docs; no doc task |
| (sweep skeleton) | One real sweep state, helper for the rest | Accepted |

No Owner decision is needed. No money rule is touched (tests and seams only; no app calculation changed).
