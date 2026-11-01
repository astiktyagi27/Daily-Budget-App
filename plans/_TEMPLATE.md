# Plan — F-xxx: <Feature name>

| | |
|---|---|
| **Feature doc** | [`docs/features/F-xxx-<name>.md`](../docs/features/F-xxx-name.md) |
| **Test cases** | [`tests/F-xxx-<name>.md`](../tests/F-xxx-name.md) |
| **Author** | Developer |
| **Status** | Draft · In review · Approved · In progress · Done |

## 1. Approach
How the feature will be built, in a few sentences. Why this approach over the alternatives.

## 2. Files / modules
| Path | Add / Change | What |
|---|---|---|

## 3. Data model / database changes
…

## 4. Packages (latest stable, checked on pub.dev)
| Package | Version | Why |
|---|---|---|

## 5. Tasks
| ID | Task | Covers AC | Depends on | Status |
|---|---|---|---|---|

## 6. Acceptance criteria coverage
Every AC from the feature doc must be listed here.
| AC | Built in task | Proved by test cases |
|---|---|---|
| AC-1 | T-… | TC-xxx-01, TC-xxx-02 |

## 7. Edge cases & risks
| Case / risk | How it is handled |
|---|---|

## 8. Impact on existing features
Which existing features could be affected, and which of their test cases must be re-run.

## 9. Open questions
- …

## 10. Project Manager review *(Gate 1 — cross-check of doc + plan + test cases)*
**Verdict:** Approved · Changes requested · Needs Owner decision

Cross-check:
- [ ] Every AC in the feature doc is covered by a task in this plan
- [ ] Every AC has at least one test case in the test file
- [ ] Edge cases in the doc appear in both the plan and the test cases
- [ ] Approach follows `docs/STANDARDS.md`
- [ ] Latest stable versions / modern APIs used

| # | Point | Type | Resolution |
|---|---|---|---|
| 1 | … | Must fix / Nice to have | … |

## 11. Implementation notes *(Developer, filled in during the build)*
Deviations from the plan and why (each approved by the Project Manager).
