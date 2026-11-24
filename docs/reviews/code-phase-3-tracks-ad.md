# Code review, Phase 3 Tracks A and D (Gate 3)

Reviewer: Project Manager (reviewer 1), 2026-11-19. Scope: **Track A** F-010 Home summary (T-300 to T-307) and F-017 Safe to spend (T-360 to T-362); **Track D** F-014 Month statement (T-400 to T-405). Reviewer 2 reviews Tracks B and C (`docs/reviews/code-phase-3-tracks-bc.md`, if present).

Method: files read only. The orchestrator is running `tool/check.ps1` and a Developer is editing app code, so the reviewer ran no flutter, dart or check. **Every approval below is conditional on that check run being green** (analyzer clean, full suite) on the final code. No app code was edited by the reviewer.

Read: the TASKS rows, plans F-010, F-017 and F-014 section 11, `home_summary.dart`, `safe_to_spend.dart`, `today_line.dart`, `month_statement.dart`, `whole_rupees.dart`, `money_format.dart`, everything under `lib/features/home` (except the calendar, which is Track B) and `lib/features/statement`, `core/widgets/today_result_line.dart`, `ledger_row.dart`, `home_copy.dart`, `safe_to_spend_copy.dart`, `statement_copy.dart`, `statement_text.dart`, the test names and the key tests, the designs `home-summary.md` and `month-statement.md`, and the Tester's case tables.

| Task | Verdict |
|---|---|
| T-300 HomeSummary model | **Approved**, Ready for test |
| T-301 homeViewProvider and states | **Approved**, Ready for test |
| T-302 Summary card | **Must fix** (2 items), In progress |
| T-303 Today card and `TodayResultLine` | **Approved**, Ready for test |
| T-304 Collapsed row | **Approved**, Ready for test (deviation 2 approved, Designer note T-465) |
| T-305 Home assembly | **Approved**, Ready for test |
| T-306 Navigation wiring | Both defaults push the real screens: moved to **Code review** (1 small item) |
| T-307 Sweeps and speed | **Must fix** (flaky state), In progress |
| T-360 Safe to spend function | **Approved**, Ready for test |
| T-361 Strip and copy | **Approved**, Ready for test |
| T-362 Wire into Home, live cases | **Approved**, Ready for test |
| T-400 Statement model | **Approved**, Ready for test |
| T-401 Copy and text builders | **Must fix** (3 small items), In progress |
| T-402 Statement screen | **Must fix** (2 items), In progress |
| T-403 Arrival and entry points | **Approved**, Ready for test |
| T-404 Sweeps and speed | **Approved**, Ready for test (speed test and TalkBack are for the Tester on the emulator) |
| T-405 Launcher seam | Stays **Ready for test**; the default now pushes the real screen, `TC-014-01` has a real test |

No Owner decision is needed. No money rule is touched: `HomeSummary`, `SafeToSpend` and `buildStatement` read engine numbers (`totals`, `currentPeriod`, `PeriodResult`) and add only display facts (the progress permille, a gross-spent sum, the paise-remainder day count that mirrors D-035). The statement's identity property test (500 random months, exact in paise) is the proof.

---

## Track A: F-010 Home summary and F-017 Safe to spend

### Correctness against plan, docs and the Tester's cases
- **Model.** `HomeSummary.from` takes every figure from `totals` and `currentPeriod`. `target` shows only when lower than the salary (AC-10), `moneyLeftAtStart` only for a mid-month start, `latestChangeDay` is the last non-superseded period's start when there is more than one, `progressPermille` is integer (222 for example A), full when nothing is budgeted or spent is at least the budget (checked first), empty at spent of ₹0 or less. Overspent is `totals.overspent`, which includes today (D-060). No money arithmetic in any widget: only `-amount` for a sign, as the Today line already did.
- **Safe to spend.** `safeToSpendFrom` classifies by the amount to spread (`left + todayNetSpend`), never by the rounded daily figure; days below 1 count as 1; under ₹1 reads `less than ₹1 a day`; nothing left only at ₹0 or below. `safeToSpendPerDay` returns `Unavailable` outside the budgeted days (D-076 (1)) and is hidden on screen. Spending today lowers `left` and raises today's net spend equally, so the figure holds all day (AC-2); covers change neither (AC-3). It feeds nothing back (AC-10; `safe_to_spend_scope_test` and TC-017-20 purity). Domain coverage 100 percent (reported by the Developer, TC-017-21).
- **States.** `HomeView` is a sealed type, the widget an exhaustive switch; loading is grey bars, never a `₹0`; the error state keeps Try again and never offers set-up (F-008 AC-11). The Today card and strip are left out when today is not a budgeted day (TC-010-59).
- **Shared Today line.** `TodayResultLine` was extracted first, F-009's cases and the Transactions sweep ran before and after (Developer's record). `TodayLine` gained only an optional `moneyIn`; existing callers compile unchanged.
- **Tests exist and can fail.** Names carry TC IDs, every automated case of T-300 to T-307 and T-360 to T-362 has its test; the literals follow the Tester's corrected numbers. TC-010-42 and TC-017-27 (TalkBack) are manual, TC-010-43 (500 spends) is an integration test written but not run (no emulator): both are for the Tester.

### Judgement of the Track A deviations
| # | Deviation | Ruling |
|---|---|---|
| 1 | Hero in `FittedBox(scaleDown)` instead of wrapping below the overline | **Approved.** At 80 sp a one-line figure cannot fit 280 dp for `₹10,00,00,000`; scaling down only when needed keeps it whole and readable (about 38 sp at the worst case) and normal figures are unscaled. Every other amount stays plain `Text`. The design (section 10) says "wrap as a unit": a **Designer note** records the change (T-465). |
| 2 | Pinned row takes its own space (not an overlay), measured in scroll offsets | **Approved, with a Designer note.** A row that a screen reader scrolls into view can never sit under an overlay, and measuring in scroll offsets stops the flicker the layout shift would cause. The cost is that the page content moves down by 56 dp plus the status bar when the row appears; it is animated (`AnimatedSize`, fade and slide in `motionFast`) and happens only once the card has left the screen, so it reads as the row pushing in. The design (section 6) says "pins under the status bar"; T-465 asks the Designer to describe this and confirm. No AC changes. |
| 3 | Display rules in `HomeSummary` (`isOver` at -₹1 or lower, no mark at ₹0) | **Approved.** A Left of -99 paise reads `₹0` and is not "over", so `−₹0` never appears (D-050). `formatRupees` also never writes `−₹0`. Tested (home_summary_test, left -99 and saved 99). Saved and Overspent get their mark and colour at 100 paise or more, the same cut as the statement's rows (consistent). |
| 4 | Tester's numbers corrected to the engine (TC-010-48, -59, TC-017-30 (c)) | **Accepted.** The Tester has already corrected the case texts; the engine is the source. |
| 5 | Day line `1 – 30 Nov` inside one month | **Approved** (design 7.6 and TC-010-16 say so; `formatCompactRange` in `date_format.dart`). See Must fix 2 of T-401: the statement keeps a private copy that must go. |
| 6 | Ledger rows use `Wrap` | **Approved.** A very large amount drops under its label rather than overflowing; at 1.3x and below the usual case is one line; above 1.3x the stacked column takes over. |

### Must fix (Track A)
**T-302, item 1: the day line cannot wrap at ` · `.** `summary_hero.dart` line 76 reads `unbreakable(HomeCopy.dayLineTail(...)).replaceFirst(' · ', ' · ')`. Both arguments are the same string (U+00A0, `·`, U+00A0), so the call does nothing, and `unbreakable` has turned **every** space of `/day · 5 Nov – 4 Dec` into a non-breaking one. The design (section 10) says the day line wraps only at ` · `. With no break opportunity at all, at 2.0x (about 400 dp of text in a 320 dp card) Flutter breaks inside the text: `₹830/day · 5 Nov – 4 De` / `c`, which splits a date and may split the amount. The sweep does not see this (it checks overflow and contrast, not where lines break). Fix: make the second argument the ordinary-space version, `.replaceFirst(' · ', ' · ')`, so the line breaks only at the dot (the dot then sits at the end of the first line), or build the tail as two spans like the Safe to spend value does. The `.replaceFirst` as written is also dead code (STANDARDS section 5). Add a test `TC-010-41` (or a new line in it) at 2.0x on a 360 dp phone: the day line is two lines, the second line starts with the range (`5 Nov – 4 Dec`), and no line ends inside an amount or a date; also for `₹33,33,333/day · 5 Nov – 4 Dec` in TC-010-44.

**T-302, item 2: none other.** (Item 1 is the only blocker of the summary card.)

**T-306 (small, then Ready for test).** The statement and day details defaults now push the real screens (`monthStatementLauncherProvider` pushes `MonthStatementScreen`; `dayDetailsLauncherProvider` pushes `DayDetailsScreen`, T-345). Home needs no code change. What is left is the proof against the real routes that T-306 promised: add to `home_summary_card_test.dart` (TC-010-19) and `home_today_card_test.dart` (TC-010-32) one test each **without a launcher override**: tapping `Month statement` shows the screen titled `Month statement`; tapping the Today card shows the day details screen for today; Back returns to Home at the same scroll position. Then T-306 is Ready for test, and the TC-010-19 and -32 stub tests stay for the double-tap case (TC-010-53).

**T-307, flaky state (must be settled before Ready for test).** The Developer saw one Home sweep state fail once (A13 scrolled, collapsed row, Light, x1.0): `expectNoOverflow` reported a clipped `₹19,370 left · ₹830/day` paragraph, then three passes. Reading the code, the collapsed row's `Text.rich` sits in a `FittedBox` (unbounded width, no `maxLines`), so `didExceedMaxLines` should never be true; the failure therefore points at something timing-dependent, not at the layout. I cannot reproduce it by reading, and a test that fails one run in four will fail the Tester's regression and the Gate 5 final run at random. Ruling: **a flaky test is not Ready for test.** Required, in this order:
1. The orchestrator runs only that state (`homeCollapsedRow`, Light, x1.0, and the other three themes and x2.0) 20 times on the final code. If all 20 pass, record it in the T-307 row (and the Developer's note that a Developer was editing app files while the first run happened, which is a plausible cause of a transient failure) and set T-307 to Ready for test, no code change.
2. If any run fails, the Developer finds the cause (suspects: the collapsed row appears through `AnimatedSize` and `AnimatedSwitcher` while `expectAccessible` runs, or the post-frame `_measure` and the four drag steps in `P3Screen.open`; end the open step with `pumpAndSettle` after a final `pump(Duration(seconds: 1))` and assert `find.byKey(const ValueKey('collapsed-row'))` is present before the check) and fixes it, then repeats the 20 runs.
Do not mask it with a retry.

### Nice to have (Track A)
- **N-A1** `HomeTab` returns two different trees (`page` alone, or `page` inside the `Column` with the pinned row) depending on text scale and orientation. Crossing 1.3x or rotating re-mounts the page subtree (the calendar's state and the hint card are rebuilt, the scroll position survives because the controller is the shell's). Keeping one tree and building the row as `SizedBox.shrink` when not pinned would avoid it. Not blocking: rotating is rare and the state lost is small.
- **N-A2** `_collapsed` is not reset when the row is not built (rotation); it re-measures on the next scroll. Harmless.
- **N-A3** `HomeCopy.potSeparator` is only used inside `potSubLine`, which the screen reader label uses, while the visible sub-line builds from parts: fine, but keep the two in step.

### Designer notes (not blocking, T-465)
Record deviations 1 and 2 in `home-summary.md` sections 6 and 10, and the ledger `Wrap` fallback in section 10. Design changes are shown to the Owner, not escalated.

---

## Track D: F-014 Month statement

### Correctness
- **Model (T-400).** `buildStatement` returns typed data, no strings. One change line per stored record, each against the previous record (D-081 (5)); a card per non-superseded record; reasons compare against the previous **card**, so same-day double changes name the net change and `Changed and changed back` appears when the net is empty; a rename is one delta (one removed and one added cost with the same amount and nothing else changed). Working: `base` is the amount actually spread (target when set, salary otherwise, money left for a mid-month start), `alreadyBudgeted = spendable - amountToSpread` (the engine's own definition), left out of the line when ₹0; `spreadDays` runs from the period start to the month end; `extraPaiseDays = amountToSpread % spreadDays` mirrors D-035 and is guarded by the property test. Totals `spent = netSpent + moneyIn` (gross), `left = totals.left` (so the statement's Left equals Home's, TC-014-07). `roundingNoteNeeded` compares the month line with the sum of the period lines **as shown** in whole rupees, using `Paise.wholeRupees`, the same rule as `formatRupees` (which was refactored onto it with no behaviour change; the money-format and F-008 tests are reported unchanged). Domain coverage 100 percent (reported).
- **Screen (T-402).** Read-only; shows the engine's figures. Totals card, rounding note under it only when needed, What changed, period cards oldest first, footnote, not-budgeted line, the shared `MonthSwitcher` (`Ended` on past months, `This month`, limits from `MonthBrowse`), keeps the old content while the next month loads, loading bars never show `₹0`, error with Try again, live through `monthStatementProvider`. Arrival: scroll, 600 ms `accentSoft` to `surface` flash (none with Remove animations), heading focus (T-403).
- **Entry points.** Home, Dashboard and Day details all call `openMonthStatement` already (`home_tab.dart`, `dashboard_tab.dart`, `day_details_screen.dart`), so T-403 needs no change in those tracks.
- **Layers and tokens.** `domain/` has no Flutter import; widgets use tokens and `formatRupees` / `formatRupeesForSpeech` / `formatRupeesSpoken`; no `~/ 100` or `₹` literal in `features/statement` (the amount pattern in `rich_money.dart` only reads `formatRupees` output).

### Judgement of the Track D deviations and questions
| Item | Ruling |
|---|---|
| `formatRupeesSpoken` in `money_format.dart` (`35,000 rupees`, `1 rupee`, `minus 1,000 rupees`) | **Approved** (AC-16 wants whole rupees in words; it lives with its siblings; sign omitted when the whole rupees are 0). **Must fix: it has no unit test of its own** (see T-401 below). |
| Working-line wrapping: strict between chunks, relaxed at 2.0x | **Approved.** The design's own five-line example cannot fit 256 dp at 2.0x; relaxing to spaces with an operator kept to its amount and no split inside an amount is the safe fallback and is tested both ways (TC-014-27, 640 dp and 320 dp at 2.0x). Designer note T-465 records the relaxed rule in section 11. |
| Reason lines carry amounts (`Fixed cost added: Gym ₹500`) | **Approved.** Matches design section 7 and D-081 (5); the Tester's TC-014-47 already has the amounts. |
| `LedgerRow` gained an optional `status` | **Approved, additive.** Default `null` gives the old output exactly (same widgets, same colour, same semantics); the Dashboard (Refunds, Net spent) and Day details callers do not pass it. The mark is decorative and the caller's `amountSpeech` stays the spoken text. Small stale comment to fix (T-402 item 2). |
| `No earlier months` copy | **Approved.** It is the shared `CalendarCopy.noEarlierMonths` (not a statement string), so the ‹ disabled hint matches the Calendar and the Dashboard. |
| (i) texts for Spent, Saved, Savings pot, Covered | **Decided: approved as written, no new design task blocks them.** `Spent`: `Everything you spent, before any refunds.` is accurate for the gross line (Home's Spent so far is net, the statement's Spent is gross: the Refunds and Net spent rows follow it). `Saved`, `Overspent`, `Left` reuse the F-010 words; `Savings pot` is the F-012 text word for word; `Covered`: `Money you moved from your savings pot to a day you overspent.` fits the totals line (the F-012 text says "to this day"). Duplicated strings: **N-D2**. |
| Target-change lines (`Spending target set to ₹25,000`, `Spending target removed`, `Spending target ₹20,000 → ₹25,000`) | **Decided: approved.** Same pattern as `Salary ₹40,000 → ₹35,000`, and the before-and-after form is already in the design for every other value. The Designer records the wording in `month-statement.md` section 13 (T-465). |
| `the first day gets 1 paisa more` (singular) | **Approved.** Correct grammar for one extra-paisa day; design only shows the plural. |
| Card at the top of the viewport on arrival (not `space6` below the bar) | **Approved** (deviation 7; the screen has no pinned bar, so there is nothing to clear). |
| Period cards show no (i) on their rows | **Approved** (design preview and section 7: only the totals card has them). |

### Must fix (Track D)
**T-401 (small, three items):**
1. **No unit test for `formatRupeesSpoken`.** Add to `money_format_test.dart` (name the cases `TC-014-28` for the AC-16 sentences): `35,000 rupees`, `1 rupee` (singular), `0 rupees` for `Paise(99)` and for `Paise(-99)` (no `minus`), `minus 1,000 rupees`, `12,34,567 rupees` (Indian grouping), and `1,00,00,000 rupees`. A money-format function with branches (singular and sign) needs its own cases, not only coverage through screen sentences (STANDARDS section 6).
2. **Dead copy.** `StatementCopy.savedWord` and `StatementCopy.overspentWord` are never used (the screen shows the mark only; the label already says Saved or Overspent). Delete both and the comment above them ("`● saved`, `◆ overspent`"). The design section 4 says "● + `saved`", but section 8.1 and the Owner preview show `Saved ● ₹2,115`; the screen follows 8.1 and that is the clearer reading (the row label already carries the word), see T-465.
3. **Duplicate helper.** `statement_text.dart` ends with a private `_compactRange` that is the same rule as the shared `formatCompactRange` in `core/format/date_format.dart` (Track A added it; plan F-010 deviation 5 says "the statement track keeps its own private copy", which was only true before it landed). Delete `_compactRange` and call `formatCompactRange` in `monthRangeText` and `notBudgetedText`; the tests of both lines stay.

**T-402 (two items):**
1. **Three automated cases have no test.** The Tester's table marks **TC-014-06** (the shown whole-rupee lines add up: Budget ₹9,960 + ₹9,940 = ₹19,900, Net spent, Saved, Overspent, Covered, and Budget − Net spent = Saved − Overspent − Covered on the shown figures for ended periods), **TC-014-42** (refunds written `−₹500`) and **TC-014-52** (the statement follows midnight: `paused` then `resumed` on the open statement, header moves to `so far (to Sat, 21 Nov)`, Overspent and Left unchanged) as Auto-widget, and no test in `app/test` carries those IDs (the sums of -06 are only implied by TC-014-19, `−₹500` is asserted inside other tests, and nothing covers midnight). Under the rule of `code-phase-3.md` T-389 item 4, a case is run only when its full test exists. Add one test per ID in `month_statement_screen_test.dart` named exactly `TC-014-06 ...`, `TC-014-42 refunds are written with a minus` and `TC-014-52 so far line moves to the new day at midnight` (the last one needs the harness clock to move and a lifecycle `resumed`; the test must read the header text and the Overspent and Left rows both times). If TC-014-52 shows the header does not move, that is a bug in the screen to fix, not a reason to drop the test.
2. **Stale doc comment on the shared widget.** `core/widgets/ledger_row.dart` class comment still says "a ledger line states a fact, so it is never red or green". It now can be, through `status`. Reword: "A plain fact is never red or green; the optional `status` adds the mark and colour of a Saved or Overspent amount (the month statement's totals)." Also add one line to the `LedgerRow` test (or the statement test) proving that a `LedgerRow` without `status` is unchanged for the Dashboard.

### Nice to have (Track D)
- **N-D1** `month_statement_screen.dart` shows the load-error state for `AsyncData(value: null)` (a month id that no longer exists) with "Try again", which cannot succeed. Acceptable today (the month can only be missing through a deleted-data race); a plain "This month is no longer there" would be kinder.
- **N-D2** Four strings are duplicated across copy files: `StatementCopy.savedInfo`, `overspentInfo` and `leftInfo` equal the `HomeCopy` texts, and `potInfo` equals the `DayDetailsCopy` text. Reference the one copy so a later wording change cannot split them. Do after Phase 3 sign-off; no behaviour change.
- **N-D3** `SingleChildScrollView` with a `Column` builds every period card at once. Fine for the specified 10 periods and the speed test (TC-014-30, not run, for the Tester); revisit if a month ever has dozens.
- **N-D4** `roundingNoteNeeded` and the per-period "shown" sums use `wholeRupees` directly; a one-line comment pointing at `formatRupees` for why (so the note compares what the screen shows) is already there. No change.

### Designer notes (not blocking, T-465)
Record in `month-statement.md`: the relaxed wrapping at 2.0x (section 11), the target-change wording and the singular `the first day gets 1 paisa more` (section 13), the Spent and Covered (i) texts, and that the totals card marks are `● ₹2,115` with no extra word (section 4 text vs section 8.1).

---

## Reading of the flaky note, shortly
One Home sweep state failed once and passed three times. It is **T-307's blocker** (above) and nothing else: do not release T-307 to the Tester until 20 clean runs of that state are on record or the cause is fixed.

## For the Owner
Nothing to decide. Three small design differences from the written designs are shown rather than escalated (they are documented by the Designer in T-465): the pinned Home row pushes the page down instead of floating over it (so a screen reader can reach every row), very large Home figures shrink instead of wrapping, and the statement's working line wraps at spaces on the biggest text size when the design's neat five-line layout cannot fit.
