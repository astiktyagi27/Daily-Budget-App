# Plan — F-008: Month setup screen

| | |
|---|---|
| **Feature doc** | [`docs/features/F-008-month-setup.md`](../docs/features/F-008-month-setup.md) (final spec, 19 ACs) |
| **Test cases** | [`tests/F-008-month-setup.md`](../tests/F-008-month-setup.md) (Approved at Gate 1; the Tester's TC IDs are used in §6) |
| **Design** | `docs/design/screens/month-setup.md` and the Home "This month" card: written and **approved at Gate 2** (`docs/reviews/design-phase-2.md`): action dock + inline preview card, decision sheets (no Material dialogs), U+2212 minus. Components come from `docs/design/design-system.md` and the existing `core/widgets/`, `core/help/` |
| **Inputs** | D-034 … D-038, D-042, D-043; F-006 / F-007 plans; `docs/reviews/phase-2-lookahead.md` #12, #13 |
| **Author** | Developer |
| **Status** | Approved (Gate 1, Project Manager, 2026-11-10; OD-9 closed by the Owner's D-057, 2026-11-11) |

## 1. Approach
One screen, `MonthSetupScreen`, in four **modes**. It is driven by a Riverpod `Notifier` that owns a plain, immutable **draft**. Every number on it comes from the F-006 engine.

1. **Modes as a sealed class** `SetupMode`, chosen by `currentMonthStateProvider` (F-006 `monthStateFor`):

   | Mode | When | Fields |
   |---|---|---|
   | `FirstFullMonth` | No month yet, today is a month start day for the chosen salary day | Salary day, salary, target switch/target, fixed costs (Rent, EMI, Subscriptions, empty) |
   | `FirstMidMonth` | No month yet, today is not the start day (D-034) | Salary day, Money left now, Fixed costs still to pay (empty) (D-042), explanation line |
   | `NewMonth(prefill)` | Today **is** the start day of the month after the last confirmed one | Salary day read-only; salary, target, items pre-filled from the last confirmed month's **latest** period; pre-fill line |
   | `LateMonthStart(month)` | Today is after the start of the month containing today and the last confirmed month is older (late or missed months, **D-057**) | Salary day read-only, Money left now, Fixed costs still to pay (empty), explanation line; first budgeted day = today |
   | `EditCurrent(month)` | **Edit this month** | Same as its kind (full or mid-month), saved values, salary day read-only, Save disabled until changed, "From today" line |

   The salary day picker changes the mode live between `FirstFullMonth` and `FirstMidMonth`, because whether today is the start day depends on the salary day.
2. **The draft is pure Dart and fully unit-tested** (`domain/budget/setup_draft.dart`).
   - It holds the raw text of each field, the target switch and a list of `DraftItem(key, name, amountText)`.
   - It exposes:
     - `validate() → List<FieldError>`, in screen order, so the first one gets focus;
     - `toPeriodValues()`;
     - `isChangedFrom(initial)`;
     - `preview(month, today, earlierBudgets) → SetupPreview`.
   - The widget layer only renders the draft and forwards edits. AC-6/AC-7 numbers are therefore proved in fast unit tests as well as in widget tests.
3. **Amount input parsing is one pure function** `parseAmount(String) → AmountParse` (sealed: `Empty`, `BadFormat`, `TooManyDecimals`, `Value(Paise)`), shared with F-009.
   - It strips `₹` and spaces, and accepts Indian or Western grouping commas.
   - It rejects a decimal comma (`99,50`) and letters, and accepts leading zeros and at most 2 decimals.
   - It converts to paise **by string**: integer part × 100 + decimals padded to 2. There is no `double`.
   - Range rules (> ₹0, ≤ ₹10 crore, target ≤ salary) live in the draft's `validate()`.
4. **One money formatter** `formatRupees(Paise)` in `core/format/money_format.dart` (AC-19, D-038, look-ahead #12):
   - rupees = `paise.value.abs() ~/ 100` (rounded down **toward ₹0**, so −12,050 → `−₹120`);
   - Indian grouping done by hand on that **int** (last three digits, then pairs; D-070, no `intl`);
   - prefix `₹`, sign `−` (U+2212, confirmed at Gate 2) followed by a word joiner U+2060 so the sign never wraps away (design system §4.3). No sign when the whole rupees are 0 (−99 paise → `₹0`, never `−₹0`; D-050). Semantics labels use the separate `formatRupeesForSpeech` ("minus ₹1,000", no invisible characters).

   Integer-only. An architecture test fails if any file in `features/` calls `NumberFormat` or contains `'₹'` with string interpolation other than through `formatRupees` (code check for AC-19). Date labels (`5 Nov – 4 Dec`, `Mon, 9 Nov`) come from `core/format/date_format.dart`, built from fixed English month and weekday name lists on the calendar date's numbers (D-070, no `DateFormat`), also shared with F-009.
5. **"Today" is injected.** `todayProvider` (`core/providers/today_provider.dart`) is a `Notifier<CalendarDate>`.
   - It reads the device date once from `clockProvider` (a `Provider<DateTime Function()>`, default `DateTime.now`).
   - It refreshes on app resume (`AppLifecycleListener`) and at the next local midnight (`Timer`).
   - Tests override `clockProvider` / `todayProvider` with fixed dates. The engine only ever sees the `CalendarDate`.
6. **Saving goes through `MonthRepository` only** (F-007). The calls are `confirmMonth` (new month: month row + first period + items, one transaction) and `addPeriod` (edit: new period dated today).
   - Results come back as a sealed `SubmitOutcome`: `Saved`, `Invalid(firstField)`, `NeedsShortfallChoice(amount, kind)`, `ZeroSpendableChoice`, `Failed(StorageException)`.
   - An `isSaving` flag ignores a second tap (AC-10).
7. **Widget tests use fake repositories** (`test/helpers/fake_month_repository.dart` from F-007 T-209), never Drift (look-ahead #5).

**Alternatives rejected:**
- A form package (`flutter_form_builder`, `reactive_forms`). The draft is small, a package would hide the validation rules, and it is one more dependency.
- A separate preview service. The engine already gives `planPeriod`.

## 2. Files / modules
| Path | Add / Change | What |
|---|---|---|
| `app/lib/domain/budget/amount_input.dart` | Add | `parseAmount` + `AmountParse` (shared with F-009) |
| `app/lib/domain/budget/setup_draft.dart` | Add | `SetupDraft`, `DraftItem`, `FieldId`, `FieldError`, `SetupPreview` (month, days, spendable line parts, daily budget **exact paise** or shortfall/zero, "from today" range) |
| `app/lib/core/format/money_format.dart` | Add | `formatRupees(Paise)` (AC-19) |
| `app/lib/core/format/date_format.dart` | Add | `formatDayMonth`, `formatRange`, `formatWeekdayDayMonth`, ordinal `5th` |
| `app/lib/core/providers/today_provider.dart` | Add | `clockProvider`, `todayProvider` |
| `app/lib/core/providers/month_state_provider.dart` | Add | `currentMonthStateProvider`: sealed `MonthState` = `NoMonth` / `NewMonthStarted(lastMonth)` / `Current(month, result)` (shared by Home, F-008, F-009) |
| `app/lib/features/month_setup/month_setup_controller.dart` | Add | `NotifierProvider.autoDispose.family<…, SetupMode>`: draft edits, undo buffer, `submit({continueAnyway})` |
| `app/lib/features/month_setup/month_setup_screen.dart` | Add | `Scaffold` + scrolling form, `PopScope` discard guard, title per mode |
| `app/lib/features/month_setup/widgets/salary_day_field.dart` | Add | Day 1–31 picker (sheet via `showBudgetSheet`, D-031), read-only variant |
| `app/lib/core/widgets/amount_field.dart` | Add | Wraps `BudgetTextField` with `₹` prefix, `TextInputType.numberWithOptions(decimal: true)`, error text, `LabelDescription` + `InfoButton` (F-004). Shared with F-009; built in **T-212c** (location decided at Gate 1: `core/widgets/`, a new file, after Phase 1 approval) |
| `app/lib/core/widgets/decision_sheet.dart`, `action_dock.dart` | Add | Design system §7.8 decision sheet (`showDecisionSheet` on top of `showBudgetSheet`, D-031; button 1 = recommended; scrim/back = safe choice) and §7.13 action dock. Built in **T-212c**, used by F-008 and F-009 |
| `app/lib/core/widgets/empty_state.dart` | Change | Optional Primary button (design system §7.10 Phase 2 allowance). T-212c, after Phase 1 approval |
| `app/lib/features/month_setup/widgets/fixed_costs_section.dart` | Add | Header + (i), item rows (`ValueKey(item.key)`), delete `IconButton` (tooltip `Remove <name>`) → `SnackBar` with **Undo** (restores at the same index), **+ Add item** (focuses the new name; disabled at 30 with hint), Total fixed costs |
| `app/lib/features/month_setup/widgets/setup_preview_card.dart` | Add | Month line, spendable line, daily budget / empty prompt / shortfall card / zero card / "From today" line |
| `app/lib/features/month_setup/widgets/shortfall_sheet.dart`, `discard_sheet.dart` | Add | Decision sheets (no `AlertDialog`), copy from §5; **Fix my numbers** Primary first (moves focus to the first fixed-cost amount), **Continue anyway** Secondary; discard: **Keep editing** first |
| `app/lib/features/month_setup/widgets/setup_action_dock.dart` | Add | The dock line (`Daily budget` · `₹830 a day` / edit / shortfall / zero / empty) + Confirm, portrait ≤ 1.3× only (`month-setup.md` §6) |
| `app/lib/core/copy/month_setup_copy.dart` | Add | Every F-008 §5 string (help text tables are checked by `test/copy/copy_tables_test.dart`, as in Phase 1) |
| `app/lib/features/home/home_tab.dart` | Change | `MonthState` switch: empty state with **Set up your month**; **Your new month has started** + **Set up this month**; **This month** card (dates, today's daily budget via `formatRupees`, **Edit this month**, shortfall line `−₹1,000 this month` + text). First-time hint unchanged (F-004) |
| `app/lib/features/home/this_month_card.dart` | Add | The card |
| `app/lib/core/copy/screen_copy.dart` | Change | Home empty-state copy replaced by the F-008 §5 strings (F-003 impact) |
| `app/test/domain/budget/amount_input_test.dart`, `setup_draft_test.dart` | Add | Unit tests, `TC-008-NN …` |
| `app/test/core/format/money_format_test.dart` | Add | AC-19 table, exhaustively plus ±1-paisa boundaries |
| `app/test/features/month_setup/*_test.dart`, `test/features/home/home_month_states_test.dart` | Add | Widget tests on fakes, all four themes via `ThemeCase`, text scale 2.0, 640×360 |
| `app/test/architecture/money_format_only_test.dart` | Add | AC-19 code check (no `NumberFormat`, `toStringAsFixed`, `/ 100` in `features/`) |

## 3. Data model / database changes
None beyond F-007. Mapping:
- **Confirm (new month):** a `budget_months` row (start/end from `BudgetMonth.containing(salaryDay, today)`, `first_budgeted_day` = start, or today for `FirstMidMonth`), plus the first `budget_periods` row (`kind`, `start_day` = first budgeted day, `changed_at` = now, values, `continued_with_shortfall`, `shortfall_paise`), plus its `period_fixed_costs` (position = list order). One transaction.
- **Save changes (edit):** a new `budget_periods` row with `start_day` = today, plus a full copy of the items. Nothing is updated (append-only, F-007 AC-16).
- **Empty item amount** → stored as 0 paise. An item with an empty name blocks Confirm (AC-5).
- **Pre-fill** reads the last confirmed month's latest effective period (F-006 ordering).

## 4. Packages (latest stable, checked on pub.dev 2026-11-10)
| Package | Version | Why |
|---|---|---|
| — | — | **None new.** `intl` was planned here (Indian grouping and date labels) but D-070 dropped it: grouping and date names are done by hand, so no `intl` anywhere in F-008 |

No form package, no `clock` package (a provider is enough).

## 5. Tasks
All F-008 tasks wait for **Phase 1 approval**, because they touch `pubspec` (via T-206), `home_tab.dart`, `screen_copy.dart` and test helpers. One exception, T-212a, is pure Dart in new `domain/budget/` files and *could* start now if the PM agrees (§9 Q2).

| ID | Task | Covers AC | Depends on | Status |
|---|---|---|---|---|
| T-212 | **Money and input basics**, in three parts. **T-212a** `parseAmount` (pure, `domain/budget/`; **may start now**, after T-202). **T-212b** `formatRupees` (+ speech form, U+2060, D-050 rules), date formatters incl. ordinals and singular "1 day", the AC-19 architecture test (no `intl`, D-070). **T-212c** shared widgets: `amount_field`, decision sheet, action dock, Primary option on `EmptyState` (design system §7.8, §7.10, §7.13) | AC-3 (parse/format part), AC-17 (shared widgets), AC-19 | T-202 (T-212a); T-206 (T-212b); T-212b + Phase 1 approval (T-212c) | In progress (T-212a, T-212b, T-212c in Code review) |
| T-213 | **Shared state.** `clockProvider`, `todayProvider` (resume + midnight), `currentMonthStateProvider` (no month / new month started / current, missed months; late setup = `LateMonthStart`, D-057) on the F-007 repositories; unit tests with fake repositories and a fake clock | AC-1 (state part), AC-12 (missed/new month) | T-209, T-212 | Code review (today provider approved at Gate 3; `currentMonthStateProvider` in Code review) |
| T-214 | **Setup draft + controller**, in two parts. **T-214a** `SetupDraft` (pure, `domain/budget/`; **may start now**, after T-204 and T-212a): both value sets kept, validation order, pre-fill, `isChangedFrom`, preview via `planPeriod`, edit-mode money-left meaning (D-048). **T-214b** `MonthSetupController.submit` (confirm vs add period, shortfall/zero choice, once per tap, storage failure, Confirm re-reads today) and the mode choice (incl. `LateMonthStart`, D-057) | AC-3, AC-4, AC-5 (rules), AC-6, AC-8 (outcomes), AC-9, AC-10, AC-11, AC-12, AC-13, AC-15, AC-18 | T-212a, T-204 (T-214a); T-214a, T-213 (T-214b) | Code review (T-214a approved at Gate 3; T-214b in Code review) |
| T-215 | **Setup screen UI** per `month-setup.md` (Gate 2 approved): fields, salary day sheet, mode cross-fade, fixed-costs list with Undo (stacked rows above 1.3×), preview card with count-up and polite live region, action dock (portrait ≤ 1.3×), shortfall/zero/discard decision sheets, discard guard, focus to the first error, help (i) on every control, four themes, text scale 2.0, landscape, keyboard never hides the focused field | AC-2, AC-5, AC-7, AC-8, AC-14, AC-16, AC-17 | T-214b, T-212c | Code review |
| T-216 | **Home wiring.** `home_tab.dart` states and the This month card (incl. shortfall line); navigation to setup/edit; update the F-003 Home widget tests with the Tester (F-003 AC-4 impact) | AC-1, AC-8 (Home line), AC-10 (Home after save), AC-18 (Home line) | T-215 | Code review |

## 6. Acceptance criteria coverage
TC IDs are the Tester's (`tests/F-008-month-setup.md` §2.4), reconciled at Gate 1.

| AC | Built in task | Proved by test cases |
|---|---|---|
| AC-1 Entry points | T-213, T-216 | TC-008-01, -02, -03, -49, -51, -52 |
| AC-2 First-month fields | T-215 | TC-008-04 |
| AC-3 Salary validation | T-212a, T-214a, T-215 | TC-008-05, -06, -31, -32 |
| AC-4 Target | T-214a, T-215 | TC-008-07, -36 |
| AC-5 Fixed costs add / edit / delete / Undo / 30 limit | T-214a, T-215 | TC-008-08, -09, -33, -34, -35 |
| AC-6 Live preview — README examples (₹1,333 / ₹830 / ₹666 / ₹163) | T-214a | TC-008-10, -54 |
| AC-7 Preview updates in the same pump | T-215 | TC-008-11 |
| AC-8 Shortfall warning and choices; equal case (D-043) | T-214a/b, T-215, T-216 | TC-008-12, -13, -33, -44, -53 |
| AC-9 Mid-month first setup (D-034, D-042) | T-214a/b, T-215 | TC-008-14, -15, -43, -44, -55 |
| AC-10 Confirm saves atomically, once | T-214b, T-216 | TC-008-16, -18, -38 |
| AC-11 Save failure keeps input | T-214b, T-215 | TC-008-17, -47, -52 |
| AC-12 Pre-fill next month | T-213, T-214a/b | TC-008-19, -39, -42 |
| AC-20 Late or missed-month setup is a fresh start (D-057) | T-213, T-214a/b, T-215 | TC-008-41, -56 |
| AC-13 Edit this month: remaining days (D-037) | T-214a/b, T-215 | TC-008-20, -21, -40, -45, -46, -47 |
| AC-14 Discard changes | T-215 | TC-008-22, -37 |
| AC-15 Month-length cases on screen | T-214a, T-215 | TC-008-23, -48 |
| AC-16 Help on every field | T-215 | TC-008-25 |
| AC-17 Themes, large text, accessibility | T-212c (shared widgets), T-215 | TC-008-24, -26, -27, -50 |
| AC-18 Edit causing a shortfall | T-214a/b, T-215, T-216 | TC-008-28 |
| AC-19 Shared formatter rounds down | T-212b | TC-008-29, -30 |

## 7. Edge cases & risks
| Case / risk | How it is handled |
|---|---|
| Salary day 29–31, leap year | Engine clamp; AC-15 widget cases with a fixed today |
| Missed months | `monthStateFor` returns the month containing today; pre-fill from the last confirmed month |
| Paste `₹40,000` / `40,000.00` / leading zeros / `99,50` / letters | `parseAmount` cases (unit tests) |
| 30 items × ₹10 crore | Sum in `Paise` (int64); shortfall card; no overflow (test) |
| Duplicate item names / all items deleted / target = salary | Allowed; tests |
| Rotation / backgrounding | Draft lives in the controller (survives rebuilds); system kill loses input (accepted, §4) |
| Midnight while open | `todayProvider` updates and the preview follows at once (F-008 §4 reworded, D-048); **Confirm** re-reads today and saves the month containing it |
| Edit when spends already exceed the new spendable | Allowed; left negative (F-006 AC-14) |
| Keyboard over the preview | Scroll view + `Scrollable.ensureVisible` on focus; Confirm reachable by scrolling (AC-17) |
| Edit on the month's first day | The new period supersedes period 1 (F-006); preview says "From today (5 Nov) … 30 days left" |
| Double tap Confirm | `isSaving` guard plus the button disabled while saving |
| Risk: the Designer's spec is not ready when T-214 ends | T-214 is logic only; T-215 waits. Placeholder layout is not built |
| Risk: Phase 1 F-003 Home tests break | T-216 updates them together with the Tester (they are Phase 2 changes to Phase 1 tests after approval) |

## 8. Impact on existing features
- **F-003 (Home tab):** the AC-4 empty state ("no buttons") is replaced. TC-003 Home cases and `test/features/tabs/empty_tabs_test.dart` need updates (Tester + T-216). Navigation, tab order and scroll-to-top stay.
- **F-004:** every new control uses `LabelDescription`/`InfoButton`. The Home first-time hint keeps its ID unless the Designer changes its wording (F-004 §4).
- **F-002:** new screens use tokens only (`tokens_only_test.dart` covers `features/`).
- **F-005:** no change (the tour still ends on Home, now in the "Set up your month" state).
- Re-run: full suite, `check.ps1`, `tests/REGRESSION.md`, F-002/F-003/F-004 Regression-yes cases.

## 9. Open questions
1. **Designer:** the preview "always visible near the Confirm button" (§2.3). Sticky at the bottom in portrait and inline at the end of the form in landscape / text scale 2.0? The plan defaults to **inline above Confirm** (always reachable, never covering fields) unless the spec says otherwise.
2. **PM:** may **T-212a** (`parseAmount`, pure Dart, a new file in `domain/budget/`) and the pure part of T-214 (`SetupDraft`) be built now alongside F-006? They touch no Phase 1 file.
3. **PM:** `amount_field.dart` is shared with F-009. Keep it in `features/month_setup/widgets/` and import it from F-009, or put it in `core/widgets/` (cleaner, but `core/` is a Phase 1 folder; it would be a new file there)? The plan proposes `core/widgets/amount_field.dart`, created in T-215 after Phase 1 approval.
4. **Designer:** the minus sign on screen: `−` (U+2212) or `-`? AC-19 says "per design system".

*Answered at Gate 1 / Gate 2 (PM, 2026-11-10):* Q1 Designer: **both** — a pinned one-line action dock (portrait, text ≤ 1.3×) plus the full preview card inline at the end; inline only in landscape or above 1.3× (`month-setup.md` §2, §6). Q2 **yes**: T-212a and T-214a may start now (D-052). Q3 `core/widgets/amount_field.dart`, a new file built in T-212c after Phase 1 approval, together with the decision sheet and action dock (D-052). Q4 U+2212 with a word joiner (design system §4.3).

## 10. Project Manager review *(Gate 1 — cross-check of doc + plan + test cases)*
**Verdict:** **Approved** (Project Manager, 2026-11-10; final 2026-11-11 after the Owner answered OD-9 with D-057). T-212a and T-214a may start now; T-212b/c, T-213, T-214b, T-215, T-216 wait for Phase 1 approval only.

Cross-check:
- [x] Every AC in the feature doc is covered by a task in this plan (AC-1 … AC-20 → T-212 … T-216, §6)
- [x] Every AC has at least one test case in the test file (TC-008-01 … -56)
- [x] Edge cases in the doc appear in both the plan and the test cases (salary day 29–31, leap year, missed months, paste/leading zeros/decimal comma, 30 × ₹10 crore, duplicate names, all items deleted, target = salary, rotation, midnight, edit below spent, keyboard)
- [x] Approach follows `docs/STANDARDS.md` (pure draft + engine, no money arithmetic in widgets, one formatter, fakes in widget tests, copy in `core/copy/`)
- [x] Latest stable versions / modern APIs used (hand-written integer formatting without `intl` per D-070, `PopScope`, `AppLifecycleListener`, `NotifierProvider.autoDispose.family`, sealed modes and outcomes)

| # | Point | Type | Resolution |
|---|---|---|---|
| 1 | **OD-9 — a new month set up after its start day** (missed months, test note 5, any late "Set up this month"). **Decided by the Owner: D-057** (the PM recommendation): a fresh start like D-034 — Money left now spread from today, still-to-pay list empty, earlier days not budgeted and never Saved. `SetupMode` gains `LateMonthStart(month, firstBudgetedDay = today)` (same fields as `FirstMidMonth`, salary day read-only, no pre-fill line); `monthStateFor` reports `NewMonthStarted` with the month containing today; the engine needs no change (`MidMonthStartValues`). | Resolved (D-057) | F-008 §2 step 12, new AC-20; TC-008-41 fixed, TC-008-56 added; T-213/T-214b no longer wait for an Owner decision. |
| 2 | **Pinned preview bar + end card** (Q1). Approved: the one number the user watches is always on screen while typing; the full working-out stays readable at the end; no dock where it would crowd (landscape, > 1.3×). | Resolved | Gate 2. |
| 3 | **Shared widgets** (dock, decision sheet, amount field, Primary empty-state button) are real build work the plan did not list. Moved into **T-212c**, so F-008 and F-009 tracks both start their UI on the same components, and no screen invents its own dialog. | Must fix → done by PM | §2, §5. |
| 4 | **No Material dialogs.** Every "dialog" in F-008 is a design system §7.8 decision sheet via `showBudgetSheet` (D-031). File names changed to `*_sheet.dart`. Widget tests find sheets by their text and semantics, never by `AlertDialog`/`Dialog` type; back on a sheet = the safe choice. | Must fix → done by PM | §2; tests §0 note. |
| 5 | **Midnight with the screen open** (test note 4). The preview follows `todayProvider` live (plan §7 already did this); F-008 §4 said "updates when reopened" — reworded. | Resolved (D-048) | F-008 §4; TC-008-39. |
| 6 | **Missing copy** (test notes 6–8): ordinals fixed by the Designer (`<ordinal>`); singular "1 day" lines added; edit-mode label `Money left on <first day>` added (F-006 point 6); mid-month dialog/card wording kept as two literals. | Must fix → done by PM | F-008 §5, `month-setup.md` §4.5, §5. |
| 7 | **Formatter: −99 paise.** `₹0`, never `−₹0` (D-050). TC-008-29 stands. | Resolved (D-050) | — |
| 8 | **Home empty-state title.** F-008 §5/design keep `Your daily budget lives here`; TC-008-01 expected it to be gone. Test corrected. | Must fix → done by PM | TC-008-01. |
| 9 | **Riverpod codegen** stays off (D-027 kept): ~6 manual providers. | Resolved | — |
| 10 | **Nice to have:** quick-pick fixed-cost name chips (F-008 Suggested additions) — CEO item, not Phase 2 scope. | Nice to have | Left with the CEO. |

## 11. Implementation notes *(Developer, filled in during the build)*

### T-212a and T-214a (Developer, 2026-11-11)
**Built (pure Dart, new files in `app/lib/domain/budget/`, each its own library exported from `budget.dart`, D-059):**
- `amount_input.dart`: `parseAmount` and the sealed `AmountParse` (`AmountEmpty`, `AmountBadFormat`, `AmountTooManyDecimals`, `AmountTooLarge`, `AmountValue`), `maxAmount` (₹10 crore), `amountInputText` (paise back to field text), and `positiveAmountProblem` (shared with F-009's `SpendDraft`).
- `setup_draft.dart`: `SetupDraft`, `DraftItem`, `SetupKind`, `FieldId`, `FieldProblem`, `FieldError`, `SetupPreview` (`PreviewNeedsSalaryDay`, `PreviewNeedsAmount`, `PreviewReady`).

**Tests** (`test/domain/budget/amount_input_test.dart`, `setup_draft_test.dart`, named by TC ID): TC-008-04, -05, -06, -07, -08, -09, -10, -12, -13, -14, -15, -19, -20, -21, -23, -28, -31, -32, -33, -34, -35, -36, -40, -41, -43, -44, -45, -46, -48, -55, -56. They prove the pure rules behind those cases to the paisa. The widget halves of the same IDs (text on screen, focus, sheets) are T-215. `domain_coverage.ps1`: `amount_input` L 42/42 B 26/26, `setup_draft` L 198/198 B 95/95. `tool/check.ps1` ALL CHECKS PASSED.

| # | Deviation / decision | Why |
|---|---|---|
| S1 | The `AmountParse` variants are named `AmountEmpty`, `AmountBadFormat`, `AmountTooManyDecimals`, `AmountValue` (plan: `Empty`, `BadFormat`, `TooManyDecimals`, `Value`). | Everything is exported through the one `budget.dart` barrel; `Empty` and `Value` are too generic. |
| S2 | A fifth variant, `AmountTooLarge`: more than 12 whole-rupee digits (after leading zeros). | Such text is never turned into an `int`, so nothing can overflow; the draft shows the same "more than ₹10 crore" problem as for a value above `maxAmount`. |
| S3 | `.5` and `40000.` are accepted (50 paise, ₹40,000), as TC-008-32 allows. Spaces and `₹` are removed anywhere in the text. A comma is only grouping: Indian (`1,00,000`) or Western (`1,000,000`) positions, else `AmountBadFormat` (`99,50`, `4,0000`). | The plan said "plan decides". |
| S4 | `preview({today, earlierBudgets})` has no `month` parameter: the month is `BudgetMonth.containing(salaryDay, today)`, and the first budgeted day is `today` minus the number of earlier budgets. | One source of truth: the preview can never be given a month that disagrees with the salary day or today. An edit passes the engine's budgets of the days before today. |
| S5 | The draft does not count characters of an item name (40) or note. `maxItemNameLength` / `maxNoteLength` are exported for the text fields. | Counting what the user sees needs grapheme clusters (Hindi, emoji); `package:characters` is not a direct dependency and the Flutter field already counts correctly (plan F-009 §1.3). A code-point count would wrongly reject valid Hindi names. |
| S6 | Problems are a `FieldId` plus a `FieldProblem` (missing, badFormat, notPositive, tooLarge, aboveSalary) and an optional item key; the copy per pair is the screen's (T-215). A bad or empty fixed-cost amount counts as ₹0 in the preview and the Total. | The pure layer holds no strings. |
| S7 | Constructors: `firstSetup`, `lateStart` (D-057), `newMonth(previous)` (pre-fill: a full period keeps everything; after a mid-month period the salary is empty and the items are the ones still to pay, F-008 §2.6) and `forEdit(saved)`. `chooseSalaryDay` re-derives the kind (D-034) and keeps both value sets (TC-008-55). `isChangedFrom` compares normalised values (`10000.00` equals `10000`, an empty item amount equals `0`, keys and hidden fields ignored). | Plan §1.2. |
| S8 | `toPeriodValues()` throws `StateError` when `validate()` finds a problem. `addItem` and `insertItem` throw `StateError` at 30 items. | Nothing is fixed silently. |
| S9 | Edit-mode money-left meaning (D-048): `preview` passes the draft's money left to `planPeriod` with the earlier budgets, so the engine subtracts what the earlier days budgeted (TC-008-20 mid-month case). A target equal to the salary is kept as the target (same spendable as no target). | Matches F-006. |

**Not built here (still T-212b/c, T-213, T-214b):** `formatRupees`, date formatters, widgets, providers, the controller and the mode choice.

**Project Manager, Gate 3 (2026-11-11, `docs/reviews/code-phase-2.md` "Re-review"):** T-212a and T-214a approved. **S1, S2, S3, S6, S7, S8, S9 approved. S4 approved**, on condition that T-214b/T-215 pass the engine's budgets of the budgeted days before today as `earlierBudgets` and use one `todayProvider` value. **S5 approved**, on condition that T-215 owns TC-008-34's 41st-character case as a widget test with grapheme counting (include a Hindi or emoji name).

### T-212b, T-212c and the first half of T-213 (Developer B, 2026-11-11)
**Built:**
- `core/format/money_format.dart`: `formatRupees` (whole rupees rounded toward zero, Indian grouping, `−` + U+2060 for a negative, no sign when the whole rupees are 0) and `formatRupeesForSpeech` (`minus ₹1,000`, no invisible characters). `core/format/date_format.dart`: `formatDayMonth` (`5 Nov`), `formatRange` (`5 Nov – 4 Dec`), `formatWeekdayDayMonth` (`Mon, 9 Nov`), `formatFullDate` (`Monday 9 November`), `formatOrdinal`, `formatDayCount` (`1 day`).
- `core/widgets/amount_field.dart`, `decision_sheet.dart`, `action_dock.dart`; `empty_state.dart` and `budget_text_field.dart` extended; `test/support/find_copy.dart` and `app_lifecycle.dart`.
- `core/providers/today_provider.dart`: `clockProvider`, `todayProvider`.

**Tests (58 new, all named by TC ID):** `money_format_test` 6, `date_format_test` 6, `money_format_only_test` 2 (TC-008-29, -30, -42, -02, -48, TC-009-13, -21); `today_provider_test` 10 (TC-008-39, TC-009-29); `amount_field_test` 9, `decision_sheet_test` 11, `action_dock_test` 9, `empty_state_action_test` 5. The component tests carry the TC ID of the AC they serve (there is no TC for a shared component alone). Full `flutter test`: 406 passed. `tool/check.ps1`: stopped at Developer A's "drift codegen is up to date" step (their work in progress); format and `flutter analyze` are clean for every file of mine.

| # | Deviation / decision | Why |
|---|---|---|
| T1 | **No `intl`.** `formatRupees` groups the integer rupees by hand (last three digits, then pairs) and the date labels use English month and weekday names taken from the calendar date's numbers. The plan said `NumberFormat.decimalPattern('en_IN')` and `DateFormat`. | The result is identical, but `DateFormat` for `en_IN` needs `initializeDateFormatting` and a locale at startup, and the weekday would go through a `DateTime`. By hand, one date always reads the same and the formatter has no dependency, which keeps TC-008-30 trivially true (`~/` and `%` only). `intl` is in the pubspec (T-206) and is not used by F-008; the PM may remove it if nothing else needs it. |
| T2 | **No digit grouping while the user types** (design system §7.3, month-setup §4.2: `40,000`). `AmountField` keeps the text as typed. | The approved test cases expect the typed text unchanged (`Enter 16000`, `salary 40000`, `Monthly salary, edit box, 40000`, TC-008-19/-26/-31/-32); a grouping formatter would turn `40000` into `40,000` and the cursor handling is its own risk. `parseAmount` already accepts both groupings. **Design / PM decision needed:** either the spec says "as you type" and the Tester changes those cases, or the spec drops it. Adding it later is one `TextInputFormatter` in `AmountField`. |
| T3 | `showDecisionSheet<T>` takes `paragraphs` (a list, for F-009's one paragraph per cover) and a required `dismissValue`, the safe choice returned for scrim, swipe and back; it returns `T`, never null. Options are `DecisionOption.primary`, `.destructive` or the plain secondary one, each with an optional caption and hint. The text scrolls in the upper area and the buttons are pinned below it; the buttons scroll by themselves only when they would take more than 60 % of the sheet (2.0 text on 360 x 640 overflowed otherwise). | Back on a sheet is the safe choice (design system §7.8), so the caller cannot forget it. |
| T4 | `ActionDock({line, action})` plus `ActionDock.fits(context)` (portrait and text 1.3 or less). With the keyboard open it keeps the line when there is one (month setup), otherwise the action (Add spend). It is meant for `Scaffold.bottomNavigationBar`; the screen decides dock or inline with `fits`. | §7.13. |
| T5 | `EmptyState`'s action (Secondary or Primary) is as wide as the text, at most 320 dp. | A full-width Primary under left-aligned text that stops at 320 dp looked out of line on wide screens; identical on a 360 dp phone. |
| T6 | `BudgetTextField` (Phase 1 file) gained `info`, `large`, `textInputAction`, `onSubmitted`; amounts use the decimal keypad; the label block is now `LabelDescription` (same style and spacing, still read by the field's own semantics node, the (i) stays its own item). The Phase 1 tests still pass unchanged. | Plan: `AmountField` wraps `BudgetTextField` with `LabelDescription` and `InfoButton`. |
| T7 | `todayProvider` tests dispose the `ProviderContainer` inside the test. | A pending midnight timer fails a test that has finished, and a tear-down runs too late. Widget tests with a `ProviderScope` are unaffected (the scope is disposed with the tree). |

**Not built (blocked):** `currentMonthStateProvider` (needs the F-007 repositories, T-209) and T-214b `MonthSetupController` (needs `MonthRepository`, T-209, and the month state). Both start when Developer A reports T-209.

**For the Tester:** the TC-008-30 command (`[^~/]/[^/=*]` over `lib\core\format`) also matches the `import 'package:daily_budget/...'` lines; the automated guard skips `import`, `export` and comment lines, and the manual command needs the same filter. Test file names are in the "Automated test" column already for TC-008-29 and TC-008-30; the shared-component tests are named in this section.

**Project Manager, Gate 3 (2026-11-13, `docs/reviews/code-phase-2.md` "T-212b, T-212c, T-213 first half"):** approved, no Must fix. **T1** approved (D-070: `intl` is unused, remove it from the pubspec; this plan's sections 1.4 and 4 and plan F-009 section 4 still name `intl`, Developer to correct). **T2** approved as a spec change (D-069: the field keeps the text as typed; Designer updates the design lines, T-238; the test cases stay). **T3, T4, T5, T6, T7** approved.

### T-213 (second half), T-214b, T-215, T-216 (Developer B, 2026-11-13)
**Built:**
- `core/providers/month_state_provider.dart`: sealed `AppMonthState` (`NoMonthSetUp`, `NewMonthDue(lastMonth, month, missedMonths)`, `ActiveMonth(stored, result)`), `latestMonthProvider` (the F-007 `watchLatestMonth` stream) and `currentMonthStateProvider` (`AsyncValue<AppMonthState>`): the engine's `monthStateFor` on the last stored month and the one `todayProvider` value; `ActiveMonth` carries the live `MonthResult` (`monthResultProvider`). A failed read is an `AsyncError`, never `NoMonthSetUp` (AC-11).
- `features/month_setup/month_setup_controller.dart`: sealed `SetupMode` (`FirstSetupMode`, `NewMonthMode(lastMonth)`, `EditMonthMode(stored)`), `MonthSetupState`, `MonthSetupController` (draft edits, Undo through `RemovedItem`, `previewFor`, `submit({continueAnyway})`), sealed `SubmitOutcome` (`SubmitSaved`, `SubmitInvalid(first)`, `SubmitNeedsChoice(kind, shortfall, basis, isEdit)`, `SubmitFailed`, `SubmitIgnored`, `SubmitMonthEnded`) and `setupPreviewProvider`.
  - A first setup is `FirstSetupMode`; full or mid-month follows the chosen salary day and today inside `SetupDraft` (D-034), and the controller listens to `todayProvider` so a midnight or a resume moves the form (TC-008-39).
  - `NewMonthMode` is pre-filled on the start day and a fresh start (`lateStart`) on any later day (D-057).
  - **S4 condition met:** an edit passes the engine's budgets of the budgeted days before today as `earlierBudgets` (`computeMonth` on the stored periods; day budgets do not depend on spends), and the preview, the dock and `submit` all read the one `todayProvider` value.
- Screen: `month_setup_screen.dart` and `widgets/` `salary_day_field.dart` (field, read-only text, day sheet), `fixed_costs_section.dart` (rows, `ItemFieldRegistry`), `setup_preview_card.dart`, `setup_action_dock.dart` (`SetupDockLine`), `shortfall_sheet.dart`, `discard_sheet.dart`. Every string is in `core/copy/month_setup_copy.dart`.
- Home: `features/home/home_tab.dart` (states: loading, load error with Try again, no month, new month, This month) and `this_month_card.dart` (`ThisMonthCard`, `NewMonthCard`). `ScreenCopy.homeEmptyDescription` is now the F-008 text.
- Shared: `core/widgets/budget_icon_button.dart` (new, see U6), `AmountField.prefix`.

**Tests (91 new, all named by TC ID):** `test/core/providers/month_state_provider_test.dart` 7 (TC-008-01, -02, -03, -39, -41, -52); `test/features/month_setup/month_setup_controller_test.dart` 25 (TC-008-05, -06, -08, -09, -12, -13, -14, -15, -16, -17, -19, -20, -21, -28, -39, -41, -44, -45, -46, -47, -56); `month_setup_screen_test.dart` 28 (TC-008-04, -05, -06, -07, -08, -09, -11, -14, -15, -16, -17, -19, -22, -25, -31, -32, -34, -35, -36, -37, -39, -41, -42, -43, -55, -56); `month_setup_preview_test.dart` 4 (TC-008-10, -23, -33, -48); `month_setup_shortfall_test.dart` 4 (TC-008-12, -13, -44, -53); `month_setup_edit_test.dart` 10 (TC-008-20, -21, -22, -28, -40, -45, -46, -47); `month_setup_sweep_test.dart` 2 (TC-008-24: 16 states x 5 themes x text 1.0 / 2.0 on 360 x 640, then landscape 640 x 360 in Light and Dim, each with the F-002 contrast, tap-target, label and overflow checks and Confirm reached by scrolling); `test/features/home/home_month_states_test.dart` 10 (TC-008-01, -02, -03, -12, -49, -51, -52); `test/copy/month_setup_copy_test.dart` 1 (every string of the new copy file against a literal). **PM condition S5 met:** TC-008-34's 41st-character case is a widget test (Latin, Devanagari `कि`, an emoji and a ZWJ family emoji: 40 accepted, the 41st dropped). Test files are named in the "Automated test" column of every TC row.

**Phase 1 test files changed** (the Home body is new, and Home now has a lifecycle listener): `test/features/tabs/empty_tabs_test.dart` (Home: new copy, its one button, the button and the four tabs tappable), `test/copy/copy_tables_test.dart`, `hints_test.dart` and `app_name_test.dart` (Home copy and button), `p1_screen_sweeps_test.dart` (the last element of Home is the button), `help_rule_test.dart` (Home controls: `Set up your month`, hint `Open month setup`), `theme_choice_test.dart` (`sendToBackground` / `bringToForeground` instead of a bare `paused` to `resumed`, which `AppLifecycleListener` rejects). No expectation was weakened. The Tester updates the TC-003 rows (TC-003-05, -17, -31).

| # | Deviation / decision | Why |
|---|---|---|
| U1 | The shared state type is `AppMonthState` with `NoMonthSetUp`, `NewMonthDue`, `ActiveMonth`; the plan said `MonthState` / `NoMonth` / `NewMonthStarted` / `Current`. | The engine already exports `MonthState`, `NoMonthYet`, `CurrentMonth` and `NewMonthStarted` (F-006). F-009 already uses the new names. |
| U2 | Three modes, not five: `FirstSetupMode`, `NewMonthMode(lastMonth)`, `EditMonthMode(stored)`. The plan's `FirstFullMonth`, `FirstMidMonth` and `LateMonthStart` are the `SetupKind` of the draft (`full` / `midMonth`) plus `NewMonthMode` on a day after the start. The mode carries its data, so the controller family is keyed by the object the screen keeps. | The salary day changes the kind live (D-034); a mode for it would have to change under the screen. |
| U3 | **The daily amount does not count up** (design: 600 ms, `motionCount`). | AC-7 and TC-008-11 want the new number in the same pump; a count would show old and in-between numbers while typing. Everything else of the preview behaves as designed (one polite live region on the daily line that speaks after 1 s without typing). **Design / PM decision needed.** |
| U4 | Deleting an item removes the row at once; it does not collapse over `motionEmphasis`. | A removed row cannot animate without an animated list; Total, preview and Undo are immediate. Visual polish only. |
| U5 | **New copy** (not in F-008 §5): the empty preview line in the mid-month form says `Enter the money you have left to see your daily budget` (the spec only has the salary version), and the dock label there reuses `Enter how much you have left`. | `Enter your salary` above a field called Money left now would be wrong. **Designer / PM to confirm the wording.** |
| U6 | New core widget `BudgetIconButton` (48 dp target, tooltip, label, hint, focus ring). | The help-rule architecture test forbids `IconButton` and `Tooltip` in `features/`; the back arrow and the x of an item need one. F-009 can use it too. |
| U7 | Edge cases not in the plan: **Edit this month** is left out of the Home card when today is outside the month (phone date set back); an edit left open past the end of its month returns `SubmitMonthEnded`, shows no preview and the screen closes on Save; a pre-filled new month left open past its start day becomes a fresh start (typed values are dropped). | `planPeriod` would throw for a date outside the month; D-057 forbids a pre-filled setup after the start day. Tested (TC-008-39, TC-008-02). |
| U8 | The preview card in **edit mode** has no `Budget month` line (the design's edit mockup omits it); the Spendable and Daily labels use `LabelDescription` (label style) so the (i) is the F-004 component. | Mockup and F-004 consistency. |
| U9 | TC-008-24 lives in `test/features/month_setup/month_setup_sweep_test.dart`, not `test/a11y/phase2_screen_sweep_test.dart` (shared with F-009, not mine to create). The storage error screen (F-007) is not in this sweep; it has its own test. | Avoids a file clash with Developer C. |
| U10 | The Transactions tab (F-009, Developer C) reaches setup through `monthSetupLauncherProvider`, whose default does nothing. **Not wired**: it is C's file. To finish: default to `MonthSetupScreen.open(context, const FirstSetupMode())` for no month and `NewMonthMode(lastMonth)` for a new month (its `NewMonthView` has `lastMonth`). | Task boundary. |

**Not done / open:** TC-008-18 and -54 (integration on the emulator), TC-008-26, -27, -38, -50 (manual, emulator, TalkBack). Plan note N2 is built: the dock line is decorative and each preview line is its own readable item.

**U10 resolved (Developer D, 2026-11-13).** `monthSetupLauncherProvider` now takes `(context, SetupMode)` and by default opens `MonthSetupScreen.open`, with its own once-per-open guard (TC-008-49). The Transactions tab passes `FirstSetupMode()` (no month) or `NewMonthMode(lastMonth)` (new month card and the Add spend decision sheet). Home still opens the same screen through its own guard. Both tabs update after Confirm from `currentMonthStateProvider` (stream-backed, no manual refresh). Tests: TC-009-01, TC-009-17, TC-008-49 in `test/features/transactions/transactions_tab_test.dart`. The two Phase 1 Home cases (TC-003-05, TC-003-17) already pass; no change.

**Project Manager, Gate 3 (2026-11-13, `docs/reviews/code-phase-2.md` "Gate 3: F-008 and F-009 screens"):** T-213 (second half), T-214b, T-215, T-216 approved, no Must fix. S4 and S5 conditions met. U1, U2, U4, U6, U7, U8, U9 approved; **U3 and U5 approved as design changes** (Designer records them in the spec, T-241; shown to the Owner); U6 fits the help-rule guard (a core control, the guard scans `features/` only). U10 resolved by T-240, approved.

### T-250 part (a) and T-243 (Developer, 2026-11-16)
**T-250 (a), month setup / new month / Edit this month:** the dock stays the Scaffold's `bottomNavigationBar` (so snackbars still sit above it) but is lifted by the keyboard inset (`resizeToAvoidBottomInset: false` while docked), so `Daily budget ₹830 a day` is directly above the keyboard. Keyboard keys: Next on every field, Done on the last field of the form (last item's Amount; with no items the last of salary / target / money left); Next goes to the next text field and skips the remove buttons (`onEditingComplete`, new optional parameter on `BudgetTextField` / `AmountField`). Back (system or arrow) with the keyboard open only closes it. Above 1.3x and in landscape there is no dock; Start my month is the last page item, reached by scrolling. Files: `month_setup_screen.dart`, `fixed_costs_section.dart`, `amount_field.dart`, `budget_text_field.dart`. Tests: `test/features/month_setup/month_setup_keyboard_test.dart` (TC-008-27, 10 tests; the keyboard rule of TC-008-27 (b) is now automated, the device walk stays with T-244). Probes (reverted): Back check removed, default Next traversal, dock not lifted: each made tests fail.
**Deviation:** first built with the dock inside the body column; the "Removed X" snackbar then covered Start my month (TC-008-35 failed), so the dock stayed a `bottomNavigationBar`.
**T-243:** `integration_test/month_setup_flow_test.dart` (TC-008-54 fresh install incl. onboarding on the real preferences plugin; TC-008-18 restart on the same database file, Edit this month shows 40000 / 10000 / 5000 / 100), shared helpers in `integration_test/real_app.dart` (not run by `check.ps1`). Run on emulator-5554: 2 / 2 passed (`docs/reviews/emulator-phase-2/integration-month-setup-flow.log`). Probe with a wrong expected value failed both tests.
