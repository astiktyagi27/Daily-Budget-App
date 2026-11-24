# Plan — F-016: Money back (manual refund entry)

| | |
|---|---|
| **Feature doc** | [`docs/features/F-016-money-back-entry.md`](../docs/features/F-016-money-back-entry.md) (final spec, 12 ACs) |
| **Test cases** | [`tests/F-016-money-back-entry.md`](../tests/F-016-money-back-entry.md) (Tester, Step 4; the TC IDs in §6 were reconciled to the Tester's file at Gate 1) |
| **Design** | [`docs/design/screens/transactions-search.md`](../docs/design/screens/transactions-search.md) §9 (editor layout for F-015 and F-016), `transactions.md` §8, §9 |
| **Inputs** | D-047, D-048 (6), D-050, D-051, D-054, D-040, D-055, D-057, D-069; F-006 AC-25, F-007 AC-18 / AC-19, F-009 plan §11 |
| **Author** | Developer 2 |
| **Status** | Plan approved (Gate 1, 2026-11-16, Project Manager B; D-084) |

## 1. Approach
**Entry UI only.** The money rule (D-047) is already built and tested: the engine counts `SpendDirection.moneyIn` against the day it arrives (`DayResult.moneyIn`, `netSpent`), the database stores `transactions.direction` (`spend` / `money_in`), `TransactionRepository.add` already accepts a direction, `groupSpendsByDay` already nets money in, and every write reconciles covers in the same transaction (`reconcileStoredCovers`, D-040 / D-048 (6)). F-016 adds the switch, the copy, and the edit / delete variants, and **proves the existing effects through the new entry path**. No engine, schema or money-rule change, so no Owner decision.

1. **Switch in the F-009 editor.** `SpendEditorScreen` gets a `Money back / refund` row right after Amount (a `LabelDescription` plus a `Switch` in one semantics node: `Money back / refund, switch, off` + description). Off by default on Add; on for a refund row opened with **Edit**. It sits under the amount so it is reachable with the keyboard open (design §9).
2. **The draft decides everything.** `SpendDraft.moneyBack` (added in F-015 T-420, tested in T-440) feeds `toFields`: direction `moneyIn`, category `null` (a refund has none), amount and note as typed. `isChangedFrom` includes the flag, so turning it on or off in Edit enables `Save changes` and arms the discard guard (AC-7, AC-11). The chosen category stays in the draft while the switch is on and comes back if it is turned off again; it is not stored for a refund.
3. **One screen, mode-driven strings.** `core/copy/money_back_copy.dart` (new file, no collision with `transactions_copy.dart`) holds every F-016 §5 string. The editor picks title (`Add money back` / `Edit money back`), Amount label and description (`Amount back` / `How much you got back.`), note placeholder and the Save hints by `draft.moneyBack`, with the design's `motionBase` cross-fade (instant with Remove animations). The **Category row** collapses with `motionEmphasis` when the switch is on.
4. **Small shared-widget changes (additive):** `AmountField` gets a `prefix` parameter (default `₹`; the money back mode passes `+₹`, design T-6 / §9); `NoteField` takes `description` and the placeholder as parameters (today it uses the Phase 2 strings directly). Defaults keep F-008 and the spend mode unchanged.
5. **Delete and discard variants.** `showDeleteSpendSheet(... isMoneyBack)` shows `Delete this money back?` with `₹500 back on Fri, 13 Nov. This can't be undone.` and the hints `Delete this money back` / `Keep this money back`; `showDiscardSpendSheet(... kind)` adds `Discard this money back?` for Add (Edit stays `Discard changes?`). Both use the existing `showDecisionSheet`.
6. **Outcome and snackbars.** `SpendEditorOutcome` gets `moneyBackAdded`, `moneyBackUpdated`, `moneyBackDeleted`; the editor returns the one that matches the **result** (turning the switch off on Edit and saving gives `Spend updated`). `openSpendEditor` maps outcomes to the six snackbar texts. The existing cover-taken-back sheet (`Savings pot updated`) already runs from `result.reductions`, so a money back deleted or lowered below the pot shows it before the snackbar (AC-10) with no new code.
7. **Effects are proved, not rebuilt.** Repository tests on in-memory Drift (like TC-009-14) and on the fake store run the spec's examples through `add` / `update` / `delete`: AC-5 (past day beyond its budget), AC-9 (covered day, cover cut to ₹100, stays cut after delete), AC-10 (pot shrink, newest cover cut, never negative), the shortfall month (₹0/day, ₹500 alone makes the day Saved ₹500, F-006 AC-25), a `₹0.40` entry (listed `+₹0`, D-050). If any of them fails, it is an engine or F-007 bug and goes to the bug flow, not patched here.
8. **Where the numbers show.** `TodayLine` already uses `netSpent`, so the Transactions tab's Today card reads `spent −₹80` without change. Home's `Includes ₹500 back from refunds` line, Spent so far and Left belong to **F-010** (it needs `moneyIn` on its today model); the calendar cell `−₹1,500` and day details belong to **F-011 / F-012**; the Refund row and the `Type: Refunds` filter belong to **F-015**. F-016 owns the entry and its engine effects. Cross-feature ACs (AC-4, AC-5) are proved at engine / repository level in T-441 and again through those screens in T-443 once they exist (§7).
9. **Sequencing with F-015 (open item 5).** F-016 changes the same editor files as F-015 §2.4a. Recommendation (details in the F-015 plan §1.9): one editor owner and a fixed order, **F-012 T-342 (editor seam) → F-015 T-420 (plumbing) → F-015 T-424 (Category row) → F-016 T-442 (switch)**. F-016 T-440 and T-441 touch no editor file and can start right after T-420. Why this order: F-016 AC-1 and AC-2 are about the Category row being visible and hidden, so the row must exist first; the reverse order would leave F-015's `Money back` clause untestable.

**Alternatives rejected:** a second "Add money back" screen or button (the Owner chose a switch on Add spend, D-054, and it halves the code); detecting salary typed as money back (out of scope, Phase 4 SMS rule); storing a category for refunds (F-013 shows refunds as one line).

## 2. Files / modules
| Path | Add / Change | What |
|---|---|---|
| `app/lib/domain/budget/spend_draft.dart` | Change (F-015 T-420 adds the field; **tests here in T-440**) | `moneyBack`; `toFields`; `isChangedFrom`; `forEdit` reads `spend.direction` |
| `app/lib/core/copy/money_back_copy.dart` | Add (T-440) | All F-016 §5 strings |
| `app/lib/core/widgets/amount_field.dart` | Change (T-442) | `prefix` parameter, `AmountField.moneyBackPrefix = '+₹'` next to the existing `prefix` |
| `app/lib/features/transactions/widgets/note_field.dart` | Change (T-442) | Description / placeholder parameters |
| `app/lib/features/transactions/widgets/money_back_switch.dart` | Add (T-442) | Switch row (label, description, one semantics node; stacks at 2.0x per design §13) |
| `app/lib/features/transactions/spend_editor_screen.dart` | Change (T-442) | Switch, mode strings, Category row collapse, outcome by result, delete / discard variants |
| `app/lib/features/transactions/widgets/delete_spend_sheet.dart`, `discard_spend_sheet.dart` | Change (T-442) | Money back variants |
| `app/lib/features/transactions/spend_editor_flow.dart` | Change (T-442) | Six snackbar texts; reductions sheet unchanged |
| `app/test/domain/budget/spend_draft_test.dart` | Change (T-440) | `TC-016-NN ...` cases for the flag |
| `app/test/data/repositories/money_back_effects_test.dart` | Add (T-441) | Engine effects through the repository (in-memory Drift and the fake) |
| `app/test/features/transactions/money_back_editor_test.dart`, `money_back_sweep_test.dart` | Add (T-442) | Widget tests and the AC-12 sweep |
| `app/integration_test/money_back_flow_test.dart` | Add (T-443) | Add ₹500 back on 13 Nov on a seeded E2 database, check the numbers on the screens that exist, edit, convert, delete, restart |

## 3. Data model / database changes
None. A refund is a `transactions` row with `direction = 'money_in'`, `category = NULL`, `source = 'manual'` (F-007 AC-19, D-051). `update` must be able to write the direction (the Phase 2 `update` did not, because it was never needed); that is F-015 T-420's `SpendFields.direction`, covered by tests in T-441. Converting a spend to money back clears its category in the same write. **Gate 1 (D-084 (3)):** a conversion is an ordinary `update` that writes `direction`; F-007's append-only triggers cover only periods and fixed costs (not `transactions`), so it is allowed, and T-441 asserts it.

## 4. Packages (latest stable, checked on pub.dev)
| Package | Version | Why |
|---|---|---|
| none | | Material `Switch` through the existing theme (design §12: track / thumb colours per theme) |

## 5. Tasks
| ID | Task | Covers AC | Depends on | Status |
|---|---|---|---|---|
| T-440 | **Domain tests and copy.** `TC-016` unit tests for the draft's money back behaviour (direction, no category, changed detection, edit of a refund, limits identical to a spend: empty, 0, 10,00,00,001, 12.345, letters, date limits incl. mid-month and late start), and `money_back_copy.dart` with its copy-table test | AC-3 (fields), AC-6, AC-7 (draft), AC-11 (discard rule) | F-015 T-420 | Code review |
| T-441 | **Engine effects through the repository** (no new app code expected): AC-3 stored values, AC-5, AC-7 net spent / spent figures, AC-8 delete, AC-9 covered day and delete afterwards, AC-10 pot shrink with `reductions`, shortfall month, ₹0.40, once-per-write and forced failure | AC-3, AC-5, AC-7 to AC-11 (data) | F-015 T-420 | Code review |
| T-442 | **Editor UI:** switch row, mode strings and cross-fade, `+₹` prefix, Category row collapse, titles, delete / discard variants, snackbars, outcome by result, double tap = one record, failure keeps the input; four themes, 2.0x, landscape, TalkBack | AC-1, AC-2, AC-3, AC-6 to AC-8, AC-11, AC-12; F-015 AC-17 third clause | **F-015 T-424** (editor owner), T-440 | Code review |
| T-443 | **Cross-feature proof and hand-over:** `money_back_flow_test.dart`; re-check AC-4 on Home (F-010), AC-5 on the calendar cell and day details (F-011 / F-012) and the Refund row (F-015) once those are built; list for the Tester's regression and the F-009 / F-015 re-runs | AC-4, AC-5, AC-12 | T-442; F-010, F-011, F-012, F-015 T-423 | Code review |

## 6. Acceptance criteria coverage
Test case IDs are the Tester's (`tests/F-016-money-back-entry.md`, authoritative); the plan's earlier proposed slots are retired (Gate 1; plan edge -13 = TC-016-25, -14 = -26, -15 = -28, -16 = -29, -17 = -44, -18 = -02).

| AC | Built in task | Proved by test cases |
|---|---|---|
| AC-1 Switch shown after Amount, off by default, description, title `Add spend`, Category visible | T-442 | TC-016-01, -42 |
| AC-2 Switch on: title, label, placeholder, Category hidden; off restores all four | T-442 | TC-016-02, -44 |
| AC-3 Save money back: one row, 50,000 paise, direction in, no category, `manual`; snackbar; list row `Refund · +₹500 · Amazon return` | T-440, T-441, T-442 (list row: F-015 T-423) | TC-016-03, -08, -27, -28, -31, -32, -34, -36, -38, -40, -41 |
| AC-4 Today's figures (`spent −₹80 · ₹910 left today`, `Includes ₹500 back from refunds` on Home, ₹5,030, ₹19,870) | engine (exists); F-010 shows it; proved in T-441 (numbers) and T-443 (screen) | TC-016-04, -05, -26, -37 |
| AC-5 Past day beyond its budget: Saved ₹2,330, cell `−₹1,500`, Home Saved ₹3,500 | T-441; screens F-011 / F-012 / F-010 (T-443) | TC-016-06 |
| AC-6 Limits: empty, 0, 10,00,00,001, 12.345, letters, date picker limits | T-440, T-442 | TC-016-07, -08, -09, -25, -30 |
| AC-7 Edit and convert (₹300 → net `₹120`; off → spend, spent `₹720`) | T-440, T-441, T-442 | TC-016-10, -11, -12, -34, -39 |
| AC-8 Delete sheet text, Cancel, Delete, snackbar, Today card back to `spent ₹420 · ₹410 left today` (both Today cards) | T-441, T-442 | TC-016-13, -34, -43 |
| AC-9 Covered day: ○ On budget, cover ₹100, pot +₹200, no note; delete leaves cover ₹100 and ◆ Overspent ₹200 | T-441 (D-048 (6) via `reconcileStoredCovers`) | TC-016-14, -15, -29 |
| AC-10 Pot shrinks (D-040): newest cover cut ₹1,000 → ₹500, pot ₹0, one `Savings pot updated` sheet | T-441, T-442 (sheet host exists from F-009) | TC-016-16, -17, -18, -19, -45 |
| AC-11 Discard, once per tap, forced write failure | T-440, T-442 | TC-016-20, -21 |
| AC-12 Help, themes, large text, landscape, TalkBack | T-442, T-443 | TC-016-22, -23, -24, -33, -35 |

## 7. Edge cases & risks
| Case / risk | How it is handled |
|---|---|
| First budgeted day of a late-started month (D-057) | Same `spendDateLimits` as a spend: allowed on it, blocked before |
| Money back larger than all the month's spends | Spent so far goes negative (engine, F-010 §4); the Today card prints `−₹80`-style values through `formatRupees` |
| Salary typed as money back | Not detected; the switch description warns (`Not for your salary.`); Phase 4 SMS rule |
| ₹0.40 | Accepted (> ₹0); list `+₹0`; may turn an exact on-budget day into `saved less than ₹1` (D-050 / D-055 wording is F-010 / F-012's) |
| Convert a spend on a covered day | The D-040 / over-cover rules of the existing write path; the `reductions` sheet shows when a cover was cut |
| Converting a categorised spend | Category cleared on Save; returns only in the draft while the editor is open |
| Money back for last month | Not possible: picker limited to the current month (F-009) |
| Past-month refund rows | Read-only like past spends (no editor); category chip absent |
| Double tap on Save / on Delete | Existing `_saving` guard (TC-009-15 pattern), one record |
| Save failure | `StorageException` → `Couldn't save. Please try again.`, input and the switch state stay |
| Switch toggled with text typed | Value kept (design §9 row 3); the amount error state is recomputed with the new label |
| Back with input | `Discard this money back?` (Add) or `Discard changes?` (Edit) |
| Risk: **AC-4 / AC-5 need F-010, F-011, F-012** | Proved at engine / repository level first (T-441), then through the screens in T-443 when they exist; if a screen is not ready at Gate 4 the Tester marks the screen part Blocked-until-built, not failed |
| Risk: editor merge conflicts with F-015 | Sequencing in §1.9; new copy file; F-016 edits the editor only after F-015 T-424 is in Code review |
| Risk: the Transactions-tab Today card | F-009's card shows `spent −₹80` already. Whether it should also show `Includes ₹500 back from refunds` is not in F-015 / F-016 (Home only); decided at Gate 1: no, the Home card carries the line and the Transactions card keeps the F-009 layout (D-084 (1)) |
| Risk: TalkBack reads the switch twice | One `MergeSemantics` node with label + description, as `LabelDescription` does elsewhere (F-004); tested in AC-12 |

Edge cases (Tester IDs): late-start first day TC-016-25; refund larger than the month -26; ₹0.40 -28; convert on a covered day -29; category not stored with a refund -44 (the convert-a-categorised-spend case is added by T-444); toggle with typed text -02; salary typed as money back -27; ₹10 crore -31; notes -32; midnight -37; two identical refunds -38; past-month refund row -39.

## 8. Impact on existing features
- **F-009 (most affected):** add, edit, delete, discard, snackbars and sheets all change inside the editor. Re-run its Regression-yes cases: TC-009-02/-03 (add), -11 (edit), -12 (delete), -15 (once per tap, failure), -16 (discard), -42, -45 (flow on device), -20 (sweep), and the cover-taken-back cases -25 to -28. F-009 §6 "no manual money in" is superseded for Phase 3 (the doc's own Impact note).
- **F-015:** Category row hidden while on (AC-17 third clause); Refund rows and `Type: Refunds` filter display what this feature records.
- **F-006 / F-007:** unchanged code; their AC-25 / AC-19 / AC-18 are now exercised by a real entry path. Re-run TC-006 money-in cases and TC-007 AC-18 / AC-19.
- **F-008:** `AmountField` gets an optional `prefix` (default unchanged): re-run `amount_field_test.dart` and the F-008 screen tests.
- **F-004:** the switch needs its label and description (`help_rule_test.dart`). **F-002:** switch colours per theme (`tokens_only_test.dart`).
- **F-010 / F-011 / F-012:** they display the effects (Today card line, calendar cell, day details); their refund cases (F-010 AC-11) depend on this entry path for end-to-end proof.

## 9. Open questions
*All answered at Gate 1 (2026-11-16): see §10 and D-084.*
1. **PM (open item 5): editor sequencing.** Recommendation: F-015 T-420 → T-424, then F-016 T-442, one editor owner (see F-015 §1.9). Please confirm or choose the reverse.
2. **PM:** should the **Transactions tab's** Today card also show `Includes ₹500 back from refunds`? The specs put it on Home only (F-010 AC-11, F-016 AC-4) and F-015 keeps the F-009 card unchanged. Plan: no (the card already shows the net `spent −₹80`). A yes is a small extra task in F-015 or F-010.
3. **PM:** F-016 AC-8 says "the Today card returns to `spent ₹420 · ₹410 left today`": which card is meant? Plan proves it on both (the Transactions card in T-442, Home in T-443).
4. **Designer:** the converted entry's snackbar follows the **resulting** type (`Spend updated` when the switch was turned off). Confirm.
5. **Owner decisions:** none. The rule is D-047 (already approved), the entry is D-054 (approved), and F-016 adds no permission, no new data kind and nothing that leaves the phone.

## 10. Project Manager review *(Gate 1 — cross-check of doc + plan + test cases)*
**Verdict:** **Approved** (2026-11-16, Project Manager B). The Must fix points below were resolved in the plan and test file in this pass. Owner decisions: none (entry UI only; the rule is D-047 and the entry is D-054, both approved; no permission, nothing leaves the phone).

Cross-check:
- [x] Every AC in the feature doc is covered by a task in this plan (12 of 12; AC-4 and AC-5 proved at engine level in T-441 and on the screens in T-443)
- [x] Every AC has at least one test case in the test file (12 of 12; map in §6 and `tests/F-016` §2.4, 45 cases)
- [x] Edge cases in the doc appear in both the plan and the test cases (§4: six bullets, TC-016-25, -26, -27, -28, -29, -30)
- [x] Approach follows `docs/STANDARDS.md` (no engine, schema or money-rule change; money flows only through the existing write path with cover reconciliation; no package; money rules D-034 to D-062 and D-069 to D-072 untouched, D-047 / D-048 (6) / D-040 are exercised, not changed)
- [x] Latest stable versions / modern APIs used (Material 3 `Switch` through the theme; no package)

| # | Point | Type | Resolution |
|---|---|---|---|
| 1 | Editor files are changed by F-012, F-015 and F-016 | Must fix | Done: one owner at a time, order **F-012 T-342 → F-015 T-420 → F-015 T-424 → F-016 T-442**; T-440 and T-441 touch no editor file and may start after T-420 (§1.9, task dependencies) |
| 2 | §6 used proposed slots and edge slots that differ from the Tester's IDs | Must fix | Done: §6 and the edge-case line rewritten with the Tester's IDs |
| 3 | AC-4 and AC-8 say "Today card": which one | Ruling | AC-4 names Home's card (F-010: `Includes ₹500 back from refunds`); AC-8's sentence is proved on both cards. The Transactions tab's Today card keeps the F-009 layout and shows the net `spent −₹80` without the extra line (D-084 (1)); TC-016-04, -13 follow |
| 4 | Seed P1 / P1b for AC-10 (the doc gives no day list) | Ruling | Confirmed (D-084 (2)); numbers re-checked: saved 3,50,000, covers 2,50,000, pot 1,00,000, newest cover 1,00,000 |
| 5 | Converting between spend and money back changes `direction` on a stored row; is it allowed by F-007's append-only rules | Ruling | Yes: the triggers cover periods and fixed costs, not `transactions`; the category is cleared in the same write; T-441 asserts it (D-084 (3)) |
| 6 | Snackbar after turning the switch off on Edit | Ruling | Follows the result: `Spend updated` (D-084 (4)); TC-016-11 stands |
| 7 | Salary typed as money back, very large amounts: no warning or dialog | Ruling | None: the switch description warns and a Phase 4 SMS rule separates salary credits (D-084 (5)); TC-016-27 stands |
| 8 | `SpendFields` shape | Ruling | As approved in F-015 (D-082 (2)); built once in F-015 T-420 |
| 9 | Missing case: a categorised spend converted to money back must lose its category in the same write | Nice to have | Tester task T-444 adds `TC-016-46`; the plan's edge slot -17 was dropped in the Tester's mapping |
| 10 | AC-4, AC-5 and AC-9 screen halves need F-010, F-011, F-012 | Ruling | Proved at engine level now (T-441); screen halves are "Not run until built" and become Blocked-until-built, not Failed, at Gate 4 (as the plan's §7 says) |

## 11. Implementation notes *(Developer, filled in during the build)*
Deviations from the plan and why (each approved by the Project Manager).

**B-003 (Developer 1, 2026-11-23).** The app was right; `money_back_flow_test.dart` looked for the Today line while the list was scrolled down (the line is built lazily). `_expectLine` now scrolls it into view; `_openTransactions` waits for the tab bar after a restart. Green on the emulator 4 times. No app code changed.

2026-11-20 (Developer, Track E): T-440 and T-442 built in code (switch, prefix, titles, delete/discard variants, outcome by result, category collapse with AnimatedSize, no cross-fade of the amount description).

2026-11-20 (Developer E3): finished F-016 on top of that code; no app code was rewritten.
- **T-441** `test/data/repositories/money_back_effects_test.dart` (16 tests, in-memory Drift, seeds from `phase3_fixtures.dart`): TC-016-05, -06, -10, -11, -13, -14, -16, -18, -19, -26, -28, -29, -31, -37, -46, plus TC-016-47 (an added case, not in the Tester's file: a forced failure in the cover write rolls the whole delete back). TC-016-41 is in `transactions_repository_test.dart`. All effects held with no engine change: no bug found. AC-5, AC-9, AC-10 are proved through `add` / `update` / `delete` (covered day: cover cut to 10,000 and stays after delete; P1: newest cover 1,00,000 to 50,000, pot 0; P1b: three covers cut newest first, reductions listed). Seeds P1 and P1b match `phase3_fixtures.dart` (T-444 confirmation).
- **T-442 tests** `money_back_editor_test.dart` (23 widget tests: TC-016-01, -02, -07 to -13, -17, -20 to -23, -25, -27, -30, -32, -38, -42, -43, -46), `money_back_sweep_test.dart` (TC-016-33: 12 states x 5 themes x 1.0x / 2.0x with the F-002 accessibility checks, TC-016-35: landscape Light / Dim and the stacking of the switch row at 2.0x), `test/copy/money_back_copy_test.dart` (copy table, named TC-016-22). The thin TC-016-02 and -03 from the previous agent stay in `transactions_search_test.dart` (F-015's file, not touched); TC-016-02 therefore appears twice, the full one is in `money_back_editor_test.dart`.
- **T-443** `money_back_screens_test.dart` (11 tests): TC-016-04 (Home and Transactions Today cards, D-084 (1)), -06 (day details, Home Saved, calendar cell), -15, -18, -26, -28 (`Saved less than ₹1` on day details), -31 (also at 2.0x), -37, -39, -40 (list, Dashboard, Month statement), -45. Home, Calendar and Day details needed no code change for refunds; Tracks A and B had built them. `integration_test/money_back_flow_test.dart` (TC-016-34) is written and analyzes clean, but was **not run on the emulator** (E2 holds it): to run in the Tester's pass.
- **Day details refund row (TC-012-58):** the row already opened the editor, which is now `Edit money back` (the draft reads `direction`). TC-012-58 in `day_details_edit_test.dart` now opens it, checks the title, the switch on, the filled amount and that saving updates the day and the Refunds figure. The row's hint stays `Edit` (design `day-details.md` section 14 says so); no copy changed.
- **T-444** done in tests: draft (`TC-016-46` in `spend_draft_test.dart`), repository (`category_write_test.dart` and `money_back_effects_test.dart`) and widget (`money_back_editor_test.dart`: category cleared in the same write, snackbar `Money back updated`). Snackbar by result is TC-016-11 (`Spend updated` after switching off).
- **Not done / open:** TC-016-24 (TalkBack, manual), TC-016-36 (kill with input, manual), the emulator run of TC-016-34 and the 2.0x / landscape hand walk of TC-016-35. TC-016-45 is proved with the pot-sheet host of F-009 (the same sheet, one per action). The statement half of TC-016-40 uses the real statement screen on the store the editor wrote.
- **Probes (each run on the new tests, change reverted afterwards; failing IDs in brackets):** draft keeps the category for a refund [TC-016-44, -46 draft and widget]; covers cut not stored [TC-016-14, -16, -18, -19, and -29]; outcome by start type [TC-016-10, -11, -46]; Home refunds line off [TC-016-04, -26]; `amountLabel` copy changed [copy table, TC-016-02, -22, -23]; `stackAbove` 1.3 to 9 [TC-016-35, not -33: at 2.0x the row still fits without stacking, so the sweep only proves no overflow]; delete sheet ignoring money back [TC-016-13, -43]; `forEdit` ignoring direction [TC-012-58, TC-016-10, -11, -12, -21]; repository `update` not writing direction [TC-016-11, -29, -46]; note description not switched [TC-016-02]; delete Cancel hint changed [TC-016-13, -22]. A probe of the switch row's `minHeight` (56 to 10) did **not** fail the sweep (the Switch itself keeps the 48 dp target), so that guard is not claimed. TC-016-47 (forced failure) and TC-016-37 / -39 / -40 / -45 were not probed.
- **Finding for the notes (not a bug):** day details tests need `setUpAll(loadBundledFonts)`; without the real fonts the `Day result` row overflows in the test font.

2026-11-21 (E3) check run: `tool/check.ps1` could not pass its `dart format` step while E2's emulator build left `app/build/shared_preferences_android/...` (a path over the Windows 260 limit that `dart format .` cannot list). The steps were therefore run by hand on `lib test integration_test`: full `flutter test` 1269 passed, 0 failed; domain coverage 100% lines and branches (`tool/domain_coverage.ps1`); time-zone matrix passed; my files are format- and analyze-clean. `flutter analyze` / `dart analyze --fatal-infos` still report issues only in E2's in-progress F-015 files (`transactions_search_queries_test.dart`, `test/scratch/dbg_test.dart`) and `transactions_filters_test.dart` (unused `_tapIn`). ALL CHECKS PASSED is therefore not yet shown: re-run `tool/check.ps1` once E2 has finished.
