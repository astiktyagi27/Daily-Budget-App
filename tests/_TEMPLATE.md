# Test Cases — F-xxx: <Feature name>

| | |
|---|---|
| **Feature doc** | [`docs/features/F-xxx-<name>.md`](../docs/features/F-xxx-name.md) |
| **Plan** | [`plans/F-xxx-<name>.md`](../plans/F-xxx-name.md) |
| **Author** | Tester (written **before** development, approved by Project Manager at Gate 1) |
| **Status** | Draft · Approved · Executing · Passed · Failed |

## 1. Test cases
Types: **Auto-unit** · **Auto-widget** · **Auto-integration** · **Manual**.
Automated tests include the TC ID in their name, e.g. `test('TC-002-03 salary on 31st in a 30-day month', …)`.
**Regression = yes** means the case is re-run in every full regression (automated cases always are; mark important manual cases yes).

| ID | AC | Scenario | Test data | Steps | Expected | Type | Automated test | Regression |
|---|---|---|---|---|---|---|---|---|
| TC-xxx-01 | AC-1 | Happy path … | Salary ₹40,000, 30 days | 1… 2… | Daily budget ₹1,333.33 | Auto-unit | `budget_engine_test.dart` | yes |

## 2. Edge cases
Same columns. Always consider: ₹0 and very large amounts, paise rounding, 28/29/30/31-day months, leap year, salary on 29th–31st, mid-month install, empty data, permission denied, unknown SMS format, duplicate SMS, all 4 themes, largest system font, app killed in background.

| ID | AC | Scenario | Test data | Steps | Expected | Type | Automated test | Regression |
|---|---|---|---|---|---|---|---|---|

## 3. Regression cases from bugs
Every bug found in this feature adds a case here. It is never deleted.

| ID | Bug | Scenario | Expected | Automated test |
|---|---|---|---|---|

## 4. Test runs *(Tester)*
| Run | Date | Build / task | Passed | Failed | Notes |
|---|---|---|---|---|---|

### Latest run — detailed results
| ID | Result | Evidence / bug |
|---|---|---|

## 5. Test report to Project Manager *(Gate 4)*
- **Verdict:** Pass · Fail
- ACs covered: x / y
- Bugs logged: B-…
- Full regression (all automated tests + `REGRESSION.md`): green / red
- Notes: …
