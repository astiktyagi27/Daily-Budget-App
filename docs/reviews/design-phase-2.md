# Gate 2 — Design review, Phase 2

**Reviewer:** Project Manager · **Date:** 2026-11-10 · **Scope:** `docs/design/screens/month-setup.md` (F-008, Home month states), `docs/design/screens/transactions.md` (F-009), design system edits §4.3 (money), §7.8 (decision sheet), §7.10 (Primary button in an empty state), §7.13 (action dock). Read with F-006 … F-009 (docs, plans, tests) and D-034 … D-047.

## Verdict
**Approved.** The Must-fix points below were small and the PM made them directly (change-history lines in each file). Nothing is waiting on the Designer. Status of both screen specs → Approved.

## What is good
- **The daily number stays visible while typing.** The one-line action dock shows `₹830 a day` changing as the user types Rent near the top of the form; the full working-out sits at the end. This is better than the plan's inline-only default, and the dock is dropped where it would crowd the screen (landscape, text above 1.3×).
- **The shortfall is shown as overspending, not as an error** (soft red with ◆, `₹1,000 short`). "Fix my numbers" is the big first button and "Continue anyway" is one honest tap away. This matches D-036/D-043 exactly.
- **One confirmation pattern for the whole app** (the §7.8 decision sheet). There are no Material dialogs. The button order rule is clear: the safe choice comes first when the sheet interrupts the user, and the confirmed action comes first when the user asked for it (Delete). Scrim and back always mean the safe choice.
- **The full-screen Add/Edit spend** fits at 2.0× text and with the date picker. It behaves the same way as month setup.
- **The new-month block uses two parts.** An inline card shows the state before the user tries anything. A sheet answers the Add spend tap, so the button never silently does nothing.
- **Accessibility is designed in:**
  - The Today line is one sentence, and the result word carries the meaning without colour.
  - The minus sign is spelled out as "minus" for TalkBack.
  - Amounts never split across lines.
  - The live region on the daily line is polite and only speaks after 1 s.
  - The dock line is excluded from semantics because the card is the readable source.
- **Every theme pair** is taken from design system §3 (contrast already verified there). Auto follows the phone.

## Gate 2 checklist
| Check | Result |
|---|---|
| Help text on every control | Pass. Every field has a label and description; (i) on Salary day, Spendable, Daily budget and Today; tooltips and hints on ×, back, delete and FAB |
| All 4 themes | Pass. §12 / §11 tables; Auto = Light/Dark |
| All states | Pass after PM additions. Load error (Home, Transactions) and the storage error screen were missing (F-007 §5 copy existed, no spec), so they were added as `month-setup.md` §10.4–10.5 and `transactions.md` §6.5 |
| Accessibility | Pass. ≥ 48 dp targets, reading orders, semantics strings, live region, 2.0× and landscape layouts |
| Fewer taps / clearer wording | Pass. A typical spend takes three taps; the pre-fill line; "From today (20 Nov): ₹630 a day …" states the effect before saving |
| Consistency | Pass after the §4.3 fix (point 1) |

## Points
| # | Point | Type | Resolution |
|---|---|---|---|
| 1 | **Design system §4.3 told developers to use `NumberFormat.currency(... decimalDigits: 0)`.** That takes a `double` and rounds half-up, so ₹666.67 would show as **₹667** (look-ahead #12). That breaks D-038 and the README example, and conflicts with TC-008-30, which forbids `NumberFormat.currency`. | Must fix → done by PM | §4.3 now says: one `formatRupees(Paise)` on integer rupees with `decimalPattern('en_IN')`, never `currency`. |
| 2 | **Missing states:** Home and Transactions "Couldn't load your data", and the F-007 storage error screen. | Must fix → done by PM | `month-setup.md` §10.4, §10.5; `transactions.md` §6.5. Neutral empty-state layout, Primary `Try again`, no red, no technical text. |
| 3 | **Missing copy:** `1 day left` (setup on the last day), the one-day edit line, edit-mode label for money left (D-048), two covers taken back by one save, results less than ₹1 (`₹0 left today` / `overspent ₹0` read as bugs), and `−₹0`. | Must fix → done by PM | `month-setup.md` §4.5, §5; `transactions.md` §4, §9.2; design system §4.3 (D-050); F-008/F-009 §5 updated to match. |
| 4 | **U+2212 minus + word joiner (U+2060).** Approved. Line breaking would otherwise allow a break between `−` and `₹`. Consequence for tests: on-screen text contains U+2060 and U+00A0, so widget tests compare through a shared `findCopy` helper that normalises them. Formatter unit tests compare the raw string. Semantics labels contain no invisible characters. | Resolved | F-008 tests §0, F-009 tests §0; F-008 plan §1.4. |
| 5 | **No Material dialogs.** Approved. Plans renamed `*_dialog.dart` → `*_sheet.dart`. The Tester finds sheets by text and semantics, never by `AlertDialog` type. The only Material dialog left is `showDatePicker`, which is a picker, not a confirmation. | Resolved | Plans F-008/F-009 §2; tests §0. |
| 6 | **Extra build work** (dock, decision sheet, amount field, Primary option on `EmptyState`) is shared by both screens. It is moved into one task, **T-212c**, so Track 1 (F-008) and Track 2 (F-009) both build on the same components. `EmptyState` is a Phase 1 file, so T-212c waits for Phase 1 approval. Screen-specific work stays in T-215/T-219: the setup dock contents, count-up animation, live region, mode cross-fade, stacked fixed-cost rows above 1.3×, and the editor's dock. | Resolved | Plans F-008/F-009 §5; `docs/TASKS.md`. |
| 7 | **Within-day order.** "Newest entry first" was ambiguous after an edit. It is now "newest added; an edit never moves a row" (D-048). | Must fix → done by PM | `transactions.md` §5. |
| 8 | Owner-preview mockup showed `Tue, 4 Nov`; 4 Nov 2026 is a Wednesday. | Nice to have → done by PM | Mockup corrected. |
| 9 | **Home This-month card after a mid-month edit** shows only today's daily budget. A second line such as `₹830 a day until 19 Nov` would explain the change without opening the editor. Phase 3 Home summary territory. | Nice to have | Follow-up task T-223 (Designer, Phase 3 input). |
| 10 | **Count-up animation on the Today line result.** Keep it, but it must never animate across the result word change (left → overspent). The word changes instantly and only the number counts. | Nice to have | Note for T-218 (in `docs/TASKS.md`). |

## For the Owner (preview, no approval needed)
Shown with the Phase 2 previews in the two screen specs ("Owner preview" sections). The only open money question from this review round is OD-9 (late month setup). It is in plan F-008 §10, not a design matter.

## T-238 (D-069, D-070): amounts shown as typed, grouped amount in the live preview — Gate 2 (2026-11-13)

**Verdict: Approved. No Must fix.** T-238 goes to **Ready for test** (the Developer builds to it in T-215).

**Reviewed (files only):** `design/design-system.md` 7.3 and 4.3 and the change-log row, `design/screens/month-setup.md` 4.2, 4.4, 5 and the mockup field; searched `docs/design/` for "as you type", "grouping as", `en_IN`, `intl`: no leftover.

| Check | Result |
|---|---|
| 7.3 | Says the field shows the digits exactly as typed (`133333`), nothing rewrites the text, the screen reader reads what the keypad entered, the grouped amount is in the live preview line in the same frame, a pasted `₹40,000` is accepted and shown as typed. Matches D-069 and the approved TC-008-19/-26/-31/-32 (`edit box, 40000`). |
| 4.3 | Says the formatter groups integer rupees by hand, 3 then 2s, no `intl`, and the output equals `NumberFormat.decimalPattern('en_IN')` on whole rupees (D-070); `NumberFormat.currency` still forbidden (look-ahead #12). |
| month-setup 4.2 | Drops "grouping as you type"; says where the grouped amount appears (Spendable line of the preview card, Total fixed costs line); the mockup field reads `₹ 40000`. |
| Accessibility / themes / states | Unchanged. The change removes a rewrite-on-every-key behaviour, which is better for TalkBack. No colour or token change, so all 4 themes are unaffected. |
| Consistency | design-system 7.3 and the screen spec agree; the change-log row records T-238. |

**Nice to have (follow-up, no task unless the Designer wants one):** only the salary (through Spendable), the target and the fixed-cost total are echoed grouped. A single fixed-cost row (for example `1000000`) or the mid-month money-left field has no grouped echo of its own, so a long typed number is harder to read. If the Owner dislikes this at phase-end feedback, the fix is the one `TextInputFormatter` named in D-069 or a small grouped hint under the field.

**For the Owner (soft, not blocking, kept in the phase-end feedback list):** amount fields show the digits as you type (`40000`); the grouped amount (`₹40,000`) shows right below in the summary. Say so if you want grouping inside the field itself.
