# Gate 2 — Design review, Phase 3 (T-313)

**Reviewer:** Project Manager · **Date:** 2026-11-16 · **Scope:** `docs/design/screens/home-summary.md`, `calendar.md`, `day-details.md`, `dashboard.md`, `month-statement.md`, `transactions-search.md` and `docs/design/design-system.md` §7.5 (calendar cell), §7.14 (month switcher), §7.15 (chips, segmented control), §7.16 (share bar row). Read with the feature docs F-010 to F-017 and decisions D-073 to D-087.
Replaces the file name `design-phase-3-batch-a.md` that T-313 first named: one review covers all six designs.

## Verdict per design

| Design | Verdict | Notes |
|---|---|---|
| `home-summary.md` (F-010, F-017) | **Approved** | No Must fix. |
| `calendar.md` + design system §7.5 and §7.14 (F-011) | **Approved** | No Must fix. 14 dp gutters, weekday label and short forms all confirmed (below). |
| `day-details.md` (F-012) | **Approved** | No Must fix. |
| `dashboard.md` + §7.15, §7.16 (F-013) | **Approved** | Refund-only state confirmed and widened to a whole month (D-087). |
| `month-statement.md` (F-014) | **Approved** | The corrected M20 example verified line by line. |
| `transactions-search.md` (F-015, F-016) | **Approved with 2 small Must fix** | The Money back switch and the Category row are fully specified in §9. Two one-line gaps (T-450) must land before the two tasks named below are code-reviewed. |

## Checks run
- **Contrast.** Every colour pair named in the six specs was recomputed with the WCAG formula for Light, Dark and Dim (script, not copied): `textSecondary` on `bg` / `neutralSoft` / `sunken` / `surface`, `accent` on `savedSoft` / `neutralSoft` / `overspentSoft` / `surface` / `bg`, `textPrimary` on `neutralSoft` (share bar), plus the §3 pairs the specs cite. All agree with §3 to two decimals, except `accent` on `savedSoft` Light (7.08 computed; §3 says 7.09) and `accent` on `overspentSoft` Light (6.71; §3 says 6.72): rounding only, both far above 3. Lowest pairs: Light `neutral` on `neutralSoft` 4.64, `overspent` on `overspentSoft` 4.71, Dim `accent` on `accentSoft` 4.97, all at or above 4.5. **No new colour pair and no new token** in any of the six designs, so the "tokens only" rule holds.
- **Money arithmetic in every worked example** was recomputed. Example A (Left ₹19,370, Safe to spend ₹899, 22 days left, average ₹638, strip, 70/18/11 %), S, F, and the statement examples (one-day period ₹10,830, ₹763, ₹663, ₹600) all add up. Example B shares (70 / 18 / 11, sum 99, so the rounding note is right).
- **Copy against the feature docs.** F-010, F-011, F-012, F-013, F-014 and F-016 section 5 tables match the specs. Hint text and the F-012 / F-014 `Refunds −₹500` wording are aligned (D-077 (3), D-081 (1)). The two differences found are in the Must fix and Nice to have lists.
- **Help text on every control.** Every button, chip, switch, segmented control, date chip and ‹ › has a label plus a tooltip, hint or (i); figures have an (i); decorative things (progress rule, bars, day strip, marks) are excluded from semantics and say so. Pass.
- **All four themes.** Each spec has a theme table built from §3 pairs; Auto = Light or Dark. Pass.
- **All states.** Normal, first-time, empty, loading (never `₹0`), load error (neutral), no month, new month not set up, shortfall, two-period, mid-month first, past month, and (new) refund-only are defined on every screen that needs them. Pass.
- **Accessibility.** Reading orders, one-sentence semantics, 48 dp targets, 2.0x and landscape layouts, shapes plus words instead of colour alone. Pass.

## The seven questions the Orchestrator asked

1. **Calendar 14 dp gutters (cell 44 dp, pitch 48.0 dp at 360 dp): confirmed.** Cell = (360 − 28 − 24) ÷ 7 = 44.0 dp; pitch = cell + 4 = (width − 24) ÷ 7 = 48.0 dp. Phones under 360 dp cannot reach 48 dp with seven columns (42.3 dp at 320 dp): the documented exception (D-075) is honest, heights stay at least 48 dp, and 42.3 dp is far above the WCAG 2.5.8 minimum of 24 dp. Cells grow taller than wide with text, the 14 dp is one named constant shared by the strip and the grid, and the inner width (36 dp) fits `₹9,999` at about 11 sp (floor 9 sp). Price: the grid is 6 dp wider each side than the cards above it; acceptable, and noted for the Owner as a preview fact.
2. **Weekday in the not-budgeted label: confirmed.** `Thursday 5 November, not budgeted, before you started` reads like every other cell (D-075 (3)); F-011 AC-9, TC-011-20 and -21 already carry it; not a button, no ripple, caption names the range.
3. **Short money forms in day cells only (D-073, Owner approved): confirmed.** The table is exact and the boundary values check out (₹9,999 stays full; ₹99,999 `₹99k`; ₹1,00,000 `₹1L`; ₹9,99,999 `₹9.9L`; ₹10,00,000 `₹10L`; ₹99,99,999 `₹99L`; ₹1,00,00,000 `₹1Cr`; ₹12,34,56,789 `₹12Cr`). Amounts are cut, never rounded up; the amount alone decides, never the phone; the label, day details and every other screen show the full amount; TalkBack never says lakh, crore or k. One cell, one function, integer maths. Only inside calendar cells: no other screen specifies a short form.
4. **Refund-only state (`dashboard.md` B-8): confirmed and amended.** B-8 also covers a **whole month** with only refunds (`Nothing spent yet this month.` then `Refunds −₹500` and `Net spent −₹500`), while D-080 (5) only names **One day**. The wider reading is right: a refund still moved money, hiding it would make Net spent (which equals Home's Spent so far, negative) unexplained, and the numbers card already behaves (highest day `No spends yet`, average may be negative, D-080 (2)). D-080 (5) is amended by **D-087** to cover the range, month or day. Follow-ups: F-013 doc wording and a Tester case (T-452, T-453).
5. **Corrected "so far on 20 Nov" example (M20): confirmed.** Saved ₹2,115 (₹1,400 + ₹715), Overspent ₹537 (₹240 + ₹297), Spent ₹13,000 (₹9,000 + ₹4,000), Covered ₹200, Pot ₹1,915 (₹2,115 − ₹200), Left ₹6,900 (₹19,900 − ₹13,000), Money for the month ₹19,900 (₹9,960 + ₹9,940). The 13–20 Nov check holds: 4 × ₹552.23 + 4 × ₹552.22 = ₹4,417.80 budgeted, ₹4,000 spent, ₹417.80 left = ₹715.58 − ₹297.78. Period 1: ₹9,960 − ₹9,000 = ₹960 = ₹1,400 − ₹240 − ₹200. No rounding note needed (month exact: 2,115.58 and 537.78 cut to ₹2,115 and ₹537). The same numbers appear in the Home two-period mockup, the Dashboard and the statement preview. Safe to spend (₹6,900 + ₹300) ÷ 11 = ₹654 also checks.
6. **Transactions-search Dates sheet: approved.** Radio rows with descriptions; when the new month is not set up the default is `Last month` (real range), the `This month` row stays in place, disabled (no outline, `neutralSoft` fill) with `Set up your month first` and a clear TalkBack sentence; tapping it does nothing and does not close the sheet; the list of choices never changes shape; `Custom range` works; it re-activates the moment the month is set up. Matches D-083 (3) and TC-015-63.
7. **F-016 Money back: a design spec exists.** `transactions-search.md` §9 holds the editor order (switch row after Amount, Category row last), the mode strings and `+₹` prefix, the cross-fade, the Category collapse that keeps the draft category but stores none, delete and discard variants, snackbars, the keyboard-open behaviour, themes and accessibility; copy §15 matches F-016 §5 word for word. Not a new Designer task for the whole editor. One gap (conversion snackbar, Must fix 2 below).

## Must fix (become Designer / PM tasks; none changes a money figure)
| # | Where | Point | Why | Task |
|---|---|---|---|---|
| 1 | `help-pattern.md` §4.2 and F-004 §5 (hint table) | `hint.transactions.v1` has new text in the design (T-7: `Tap a spend to fix it, or tap its category to change it.`), but both Phase 1 tables still hold the old `Spotted a wrong amount or category later? You'll be able to fix it right here.`, and TC-004-09 asserts the old text. The `hint.calendar.v1` row was done for T-310 / T-311, this one was not. | Two documents disagree on a visible string; the Developer would build whichever they read. Gates the hint text in **T-423**. | T-450 (Designer, `help-pattern.md`), T-452 (Product Manager, F-004 §5), T-453 (Tester, TC-004-09) |
| 2 | `transactions-search.md` §9 and §15 | Converting an existing entry (switch turned on or off while editing) is not covered: which snackbar shows, and that the category is cleared in the same write when an entry becomes money back. F-016 §2 and TC-016-11 say: snackbar follows the **result** (`Money back updated` after a spend becomes money back, `Spend updated` after money back becomes a spend); D-084 (3). | One expected string for the Developer and the Tester, and the design must say what happens to the Category value the user picked before switching. Gates **T-442**. | T-450 (Designer) |

## Nice to have (follow-up tasks, do not block)
| # | Point | Task |
|---|---|---|
| 3 | `calendar.md` §5.1: add one sentence that a budget month starting on the 1st shows a plain `1` on its first day (D-075 (2); the design system §7.5 and F-011 already say so). | T-451 |
| 4 | `day-details.md` §16 note 1 is stale: F-012 AC-16 and F-014 AC-11 were aligned to `Refunds −₹500` by D-077 (3) and D-081 (1). Remove the note. | T-451 |
| 5 | Design system §3 and `calendar.md` §9 differ by 0.01 on two Light tick ratios (7.09 / 7.08, 6.72 / 6.71). Use the computed values (7.08, 6.71). | T-451 |
| 6 | Design system §7.5 says the 9 sp floor is reached only by a negative `−₹100Cr`; a negative `−₹9,999` (7 glyphs) is almost as wide. It still fits at about 9.6 sp, so nothing breaks, but the Developer must **measure** both on the 360 dp test phone, not rely on the sentence. | T-454 (Developer, in the T-326 sweep) |
| 7 | F-015 AC-10 says the filtered day total reads `₹250`; the design (T-3) and TC-015-19 show the visible word `₹250 shown`. | T-452 |

## Gate 2 checklist
| Check | Result |
|---|---|
| Help text on every control | Pass |
| All 4 themes (Light, Dark, Dim, Auto) | Pass; no new colour pair |
| All states | Pass; refund-only added by T-388 and confirmed |
| Accessible (48 dp, semantics, 2.0x, landscape, not colour alone) | Pass; calendar sub-48 dp exception below 360 dp documented (D-075) |
| Copy consistent with F-010 to F-017 and D-073 to D-086 | Pass, except Must fix 1 and Nice to have 7 |
| Tokens only, no new colour pair without a ratio | Pass |

## What is approved for which tasks (UI tasks may start now)
| Design | Approved for tasks |
|---|---|
| `home-summary.md` | T-302, T-303, T-304, T-305, T-307, T-361, T-362. **T-306** is also approved but still waits for F-014's route (D-077). |
| `calendar.md`, design system §7.5, §7.14 | T-323 (the `MonthSwitcher` widget), T-324, T-325, T-326 |
| `day-details.md` | T-343, T-344, T-345, T-346 |
| `dashboard.md`, design system §7.15, §7.16 | T-383, T-384, T-385 |
| `month-statement.md` | T-401, T-402, T-403, T-404 |
| `transactions-search.md` | **T-422, T-424, T-425 now.** **T-423** may start; its hint text waits for T-450, T-452 (Must fix 1). **T-442** may start the switch row and strings; the conversion snackbar waits for T-450 (Must fix 2). T-443 follows T-442. |

Order rules are unchanged: the editor owner order F-012 T-342, F-015 T-420, F-015 T-424, F-016 T-442 (D-074, D-085); `home_tab.dart` belongs to F-010 T-305 (D-077); T-306 waits for F-014. One naming slip on the task board: the F-013, F-014 and F-015 task rows say `T-325 MonthSwitcher`, but T-323 builds `MonthBrowser` and `MonthSwitcher` and T-325 is the calendar section (D-085 repeats the slip). The dependency means **T-323**; the Developer should read it that way.

## For the Owner (shown, not asked)
- The calendar grid is 6 dp wider on each side than the cards above it, so each day is a full 48 dp to touch on a 360 dp phone. On a narrower phone the days are slightly smaller (42 dp on the 320 dp test phone).
- The calendar shows `₹12k`, `₹1.5L`, `₹10Cr` only for very large days, only inside day cells (you approved this, D-073). Every other place and the screen reader show the full amount.
- A month where you only recorded money back (no spends) reads "Nothing spent yet this month" followed by the Refunds and Net spent lines (D-087).
- No design in this review asks for a decision or changes how money is calculated.
