# Engineering & Design Standards

Every agent follows these. The Project Manager enforces them in every review. Changes to this file are recorded in `DECISIONS.md`.

## 1. Think before coding

- No code without an approved plan (phase plan, or a short task plan for anything non-trivial).
- Before writing, answer: What exactly must change? What could break? How will it be tested? Is there a simpler way?
- Prefer the simplest design that fully meets the acceptance criteria. No speculative features.
- Read existing code first and match its patterns. Reuse before adding.

## 2. Stay current

- Use the **latest stable** Flutter, Dart and package versions at the time of the work. Check pub.dev and the official docs rather than relying on memory, and record versions in `DECISIONS.md`.
- Prefer modern language features where they make code safer or clearer: Dart 3 sealed classes, pattern matching / switch expressions, records, `final` by default, exhaustiveness checks.
- Prefer current Material 3 components and theming APIs.
- Avoid deprecated APIs. Fix deprecation warnings when touching a file.
- Choose well-maintained packages (recent releases, good pub.dev score, null-safe). Every new package needs a one-line reason in `DECISIONS.md`.

## 3. Architecture

```
app/lib/
├── core/          shared utilities, theme, widgets (incl. help/tooltip widget)
├── data/          database, SMS source, repositories
├── domain/        pure Dart: models, budget engine, SMS parsers, categorizer
└── features/      one folder per feature (home, calendar, dashboard, setup, settings…)
```

- **`domain/` is pure Dart** — no Flutter imports. All money and date logic lives here and is 100% unit-tested.
- Transaction **sources** sit behind one interface (`TransactionSource`), so iOS Shortcuts / Account Aggregator / statement import can be added later without touching the rest.
- UI never talks to the database directly; it goes through repositories and Riverpod providers.
- Keep widgets small; split when a build method gets hard to read.

## 4. Money and dates (critical)

- **Money is stored as integer paise (`int`)**, never `double`. ₹1,333.33 = `133333`.
- Division must be exact over the month: when spendable money doesn't divide evenly by days, spread the leftover paise so the daily budgets add up **exactly** to the spendable amount. This is unit-tested.
- Format money only at the UI layer, using Indian grouping (`₹1,33,333`).
- Use local device dates (India is IST, no daylight saving). Budget months run from salary date to the day before the next salary date — test 28/29/30/31-day months, leap years, salary on the 29th–31st, and mid-month installs.
- Never compare money or dates with floating point.

## 5. Code quality

- `flutter analyze` must report **zero** issues. Strict lint set enabled (decided in Phase 0).
- `dart format` on every file.
- No `print` — use a logger. **Never log SMS bodies, amounts or personal data.**
- No dead code, commented-out code, unused imports, or TODOs without a task ID (`// TODO(T-305): …`).
- Clear names over comments. Comments explain *why*, not *what*.
- Unnamed constructors use the Dart 3.13 form `const new({super.key});` instead of repeating the class name (lint `unnecessary_type_name_in_constructor`, D-024). For named constructors follow whatever the analyzer asks; `dart fix --apply` converts flagged code.
- Handle every failure path: permission denied, empty inbox, unknown SMS format, database error.

## 6. Testing

| Layer | What | Target |
|---|---|---|
| Domain (budget engine, parsers, categorizer) | Unit tests | ~100% of branches |
| Repositories / database | Unit/integration tests | Main paths + failures |
| Widgets/screens | Widget tests, all 4 themes for key screens | Every screen |
| Main flows | Integration tests on the emulator | Onboarding, month setup, add transaction, calendar |

- Test cases are written by the Tester in `tests/F-xxx-name.md` **before** coding. Every automated test is **named with its test case ID**: `test('TC-002-03 salary on 31st in a 30-day month', …)`.
- **Bug fixes start with a failing test** that reproduces the bug. The fix makes it pass. The test stays forever, and the bug gets a permanent regression case in the feature's test file.
- **The full suite runs after every change and every bug fix** — not only the tests near the change.
- SMS parser tests use real-format sample messages with personal details replaced by fake ones.

## 7. Design

- Minimal and calm. One accent color. Large, readable numbers. No generic template look.
- All screens work in **Light, Dark, Dim and Auto**.
- **Every button, setting and number has a label plus a description or (i) tooltip.**
- Define empty, loading and error states for every screen.
- Touch targets ≥ 48 dp, text contrast meets WCAG AA, layout survives the largest system font size.
- Colors carry meaning only: green = saved, red = overspent, neutral otherwise.

## 8. Privacy & security

- All financial data stays on the device. No network calls with user data.
- Request permissions only when needed, always with a plain-language explanation first.
- The user can delete all app data from Settings.
- Read only SMS from the selected bank's sender IDs; ignore everything else.
