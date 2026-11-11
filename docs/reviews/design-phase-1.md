# Design review (Gate 2): Phase 1

| | |
|---|---|
| **Reviewer** | Project Manager |
| **Date** | 2026-11-05 |
| **Files reviewed** | `docs/design/design-system.md` ("Neel Khata"), `docs/design/screens/app-shell.md`, `settings.md`, `help-pattern.md`, `welcome-tour.md` |
| **Checked against** | F-002…F-005 feature docs §2–§5 (as reconciled at Gate 1), `docs/STANDARDS.md` §7, plans F-002…F-005 |
| **Verdict** | **Approved.** No Must-fix items remain. I made the small reconciliation edits listed below myself. Two Nice-to-have items go to the Designer (T-128). |

## 1. Gate 2 checklist

| Check | Result | Notes |
|---|---|---|
| All 4 themes | Pass | Every screen spec has a Light / Dark / Dim table and states that Auto follows the phone (Light or Dark, never Dim). Each colour is a token from design §2, so nothing is hand-picked per screen. |
| Contrast (WCAG AA) | Pass | I recomputed all 28 pairs in design §3 with the WCAG formula. Every value matches to two decimals. Lowest text pair: Light `neutral` on `neutralSoft` 4.64. I **added** three pairs that Phase 1 screens use but §3 did not list: `textSecondary` on `neutralSoft` (Coming soon tag and disabled label, 5.56 / 6.37 / 5.69), `textSecondary` on `accentSoft` (hint ×, 5.62 / 5.97 / 5.27) and `borderStrong` on `bg` (page indicator, 3.39 / 3.54 / 3.76). All pass. TC-002-21 now checks 31 pairs. |
| Help text on every control | Pass | Every control in the four specs has a label plus a description, an (i), or a screen-reader hint (with a long-press tooltip for icon-only controls and tabs). This matches the §5 tables of F-002…F-005 and the Tester's list `tests/F-004…` §1.2. F-004 §2.3/§2.4 now say clearly that a tooltip is needed only for icon-only controls and tabs, which is how the specs already work. |
| All states | Pass | Every spec defines first-time, normal, empty, loading, error and permission-denied states. Phase 1 has no visible error UI by design (silent fallback, design §7.12). |
| Accessibility | Pass | 48 dp targets everywhere (the 18 dp (i) and 20 dp × have 48 dp targets). The selected tab has three non-colour cues. Status marks ●○◆. Reading order is defined for tabs and onboarding (`OrdinalSortKey` on slides). TalkBack strings are given for every control. Remove animations makes every motion instant. |
| Largest text (2.0×, 360 × 640) | Pass | Titles live in the scroll body, not a fixed app bar. Nav labels are capped at 1.3× and fitted (app-shell §3.2), which settles the F-002/F-003 edge case. Coming soon tags move under the text. Explainer buttons move to the end of the scroll above 1.3×. Money figures never split. |
| Fewer taps / clearer wording | Pass | Theme applies live and the sheet stays open (one tap to try each theme). "Not now" is a full button, not a hidden link. Hint copy no longer repeats the empty state under it. Privacy copy says only what is true under D-003 and does not mention ads. |
| Consistency | Pass after edits | See §2. |

## 2. Conflicts between design, docs and tests: how each was resolved

| # | Conflict | Resolution |
|---|---|---|
| 1 | (i) explanation: auto-closing bubble vs F-004's sheet with Got it | **Resolved by the Designer:** a help sheet with title, scrolling body and a pinned **Got it** (help-pattern §3, design §7.11b). Tests TC-004-02/-03 fit as written; TC-004-03 (c) loses its "only if a sheet" condition (T-126). |
| 2 | Hint card without × | **Resolved by the Designer:** Tip overline, × and Got it (help-pattern §4.1). TC-004-09 must use the final hint texts (T-126). |
| 3 | Nav label scaling at 2.0× undefined | **Resolved by the Designer:** cap 1.3×, one line, `FittedBox` shrink, tooltip and TalkBack at full size (app-shell §3.2, design §7.7). New TC-003-30, TC-002-24/-25 expected text updated (T-126). |
| 4 | Screen-reader label "About" vs "More about" | **Resolved:** design §7.11b and help-pattern §3.1 say `More about <label>`. TC-004-05 already matches. |
| 5 | Description "max 2 lines" vs "never truncated" | **Resolved (PM edit):** design §7.11a now says "aim for one or two lines; it always wraps and is never truncated", matching help-pattern §2.1 and F-004 §4. |
| 6 | Empty state centred (F-003 §2.4) vs left-aligned (design) | **Decided: left-aligned** (it avoids the stock centred-hero look and keeps the hint and empty state on one reading line; AC-4 unaffected). F-003 §2.4 reworded. Design §7.10 also aligned with app-shell §4 (40 dp icon, `space8`, F-003 copy instead of an older Transactions sentence). |
| 7 | Coming soon screen-reader string | **Decided:** one disabled item `<Label>, coming soon, not available yet. <Description>` (status first, then what it will do). F-003 §5 and settings.md §2.3 updated; TC-003-07 updated in T-126. |
| 8 | Back with a hint visible (F-003 §2.7 vs F-004) | **Decided:** the hint is page content, not an overlay. Back ignores it (not dismissed, not saved as seen) and follows the tab rule. F-003 §2.7 and §4 reworded; TC-003-21 gets case (c). |
| 9 | Coming soon tag colours undefined | **Resolved by the Designer:** `neutralSoft` pill, `caption` 500 in `textSecondary` (settings.md §2.3, §6). Pair added to design §3 (PM). |
| 10 | "Finished but tour not seen" | **Decided: Home** ("finished" wins). F-005 §2.8 table has the row; TC-005-27 as written. |
| 11 | F-005 slide 4 mentioned ads | **Resolved:** `Your bank SMS are read on this phone and never leave it. No login, and nothing is uploaded.` is in F-005 §5 and welcome-tour §2.2. TC-005-02 writes the literal (T-126). |

## 3. Findings and edits made at Gate 2 (PM)

| # | Finding | Type | Resolution |
|---|---|---|---|
| 1 | Design §6 said the Phase 1 stand-in icons are "Material Symbols Rounded, bundled with Flutter, weight 300 via `Icon(weight: 300)`". Flutter bundles the static Material Icons font, not Material Symbols, so `weight` has no effect, and no plan included an icon package. | Resolved (PM edit) | §6 now says built-in Material Icons (outlined, filled for the selected tab). A 300-weight look would need an extra package; not worth it before the Phase 6 custom icons. All named icons exist in the built-in set. Note: `bar_chart` and `tune` look nearly the same outlined and filled. That is fine, because the tick and the heavier label are the other two cues. |
| 2 | Design §3 missed three pairs used on Phase 1 screens. | Resolved (PM edit) | Added (see §1). |
| 3 | Design §4.1 described a Google Fonts zip and a conditional 24pt instance. The plan uses the upstream repos, and upstream has no 24pt set. | Resolved (PM edit) | §4.1 names the pinned upstream sources and the unprefixed instances. The ₹/`tnum` check is now a permanent automated test (TC-002-42). |
| 4 | Design §7.10 empty state disagreed with app-shell §4 (56 vs 40 dp icon, "top third" vs `space8`, an older Transactions sentence). | Resolved (PM edit) | §7.10 now follows app-shell §4 and F-003 §5. |
| 5 | App-shell §5 said the Android launch screen shows a plain `bg` colour. That needs launch-theme work, which F-002 §6 puts out of scope. | Resolved (PM edit) | Reworded: the generated launch theme (white, or black in system dark mode) shows until Flutter starts; theming it is Phase 6/7. |
| 6 | Status lines of all five files. | Resolved | → "Approved at Gate 2". |
| N1 | The design-system "Owner preview" Home mockup shows a hint card without the `Tip` overline and ×. It is an illustrative Phase 3 screen, but it should show the real card. | Nice to have (Designer, T-128) | — |
| N2 | The four screen specs have no change-history table. My edits are noted only in the status lines and in this review. | Nice to have (Designer, T-128) | — |
| N3 | Theme picker: Done is needed to close (three taps to change theme and leave). The live preview is worth it, and swipe/scrim/back also close it. No change. | Info | — |

## 4. Owner visibility
All of these designs were previewed in the chat as they were made (CLAUDE.md rule 8). The Gate 2 edits change no colour and no visible layout except the empty-state icon size (40 dp in the 88 dp circle, as the app-shell mockups already showed), so no new preview is needed.
