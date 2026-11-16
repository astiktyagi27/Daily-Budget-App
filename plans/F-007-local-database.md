# Plan — F-007: Local database

| | |
|---|---|
| **Feature doc** | [`docs/features/F-007-local-database.md`](../docs/features/F-007-local-database.md) (final spec, 17 ACs) |
| **Test cases** | [`tests/F-007-local-database.md`](../tests/F-007-local-database.md) (Approved at Gate 1; the Tester's TC IDs are used in §6) |
| **Design** | Storage error screen: uses the existing `EmptyState` + `BudgetButton` pattern; the Designer confirms or specs it at Step 6 |
| **Inputs** | D-003, D-018, D-019, D-027, D-029, D-037, D-041; `docs/reviews/phase-2-lookahead.md` #1–#11, #14, #17 |
| **Author** | Developer |
| **Status** | Approved (Gate 1, Project Manager, 2026-11-10) |

## 1. Approach
Drift (D-018) over plain SQLite (D-041: no extra encryption), with a thin layer:

```
features/ ──► providers (core/providers/) ──► repositories (data/repositories/, interfaces + Drift impls)
                                               └─► data/database/ (Drift tables, converters, connection)
domain/budget/ (F-006 types) ◄── mapped to/from rows by the repositories
```

1. **The database stores facts only.** Months, append-only budget periods with their own fixed-cost items, transactions and savings moves.
   - **Day budgets are not stored.** The repositories hand the stored periods to the F-006 engine, which recomputes them (F-007 §2.1 "recomputed", F-006 plan §1.3).
   - Past budgets cannot change after a later edit, because the periods they come from are immutable (AC-16).
2. **Append-only is enforced by the database itself**, not only by code. SQLite triggers `BEFORE UPDATE` and `BEFORE DELETE` on `budget_periods` and `period_fixed_costs` do `RAISE(ABORT, 'append-only')`. A bug can't rewrite history, and the AC-16 test can prove it.
3. **Calendar dates are `INTEGER` day numbers** through a `TypeConverter<CalendarDate, int>` (look-ahead #7). Money is `INTEGER` paise through `TypeConverter<Paise, int>`. There is no `DateTimeColumn` for any calendar date. `created_at`/`edited_at`/`changed_at`/`made_at` are `INTEGER` UTC epoch ms, used only for ordering.
4. **Opening is guarded and never destructive.**
   - We use `drift_flutter`'s `driftDatabase(name: 'budget', native: DriftNativeOptions(setup: _guard))`. The `setup` callback (checked in drift_flutter 0.3.1 source) runs on the raw connection **before Drift's migration logic**. It reads `PRAGMA user_version`; if it is newer than `schemaVersion`, it throws `DatabaseTooNewException`.
   - This matters because Drift itself calls `onUpgrade(from: 2, to: 1)` on a downgrade and then **writes the lower version** (drift 2.35.4 `engines.dart`), which would change the file. AC-8 needs the bytes unchanged.
   - `onUpgrade` also throws if `from > to`, as a second guard.
   - It also runs `PRAGMA foreign_keys = ON` (look-ahead #9).
5. **Startup gate.** `appDatabaseProvider` is a `FutureProvider<AppDatabase>`. It opens the database and runs a probe query (`SELECT count(*) FROM budget_months`), which catches corrupt files and failed opens.
   - On error, the app shows `StorageErrorScreen` (F-007 §5 copy) instead of the money tabs. **Try again** calls `ref.invalidate(appDatabaseProvider)`.
   - The file is never deleted or recreated.
   - The preferences store is opened separately as today (D-026), so theme and tour still work when the database fails (§4 "two stores").
6. **Repositories are interfaces with one Drift implementation and one in-memory fake.**
   - `MonthRepository`, `TransactionRepository`, `SavingsRepository` live in `data/repositories/`.
   - They return F-006 domain types and Drift `watch()` streams (AC-5).
   - **Widget tests in F-008/F-009 use the fakes** (`test/helpers/fake_*_repository.dart`), so they never touch Drift. This avoids the widget-test hang seen in the look-ahead (#5).
   - The Drift implementations are tested with `NativeDatabase.memory()` in plain `flutter test` (look-ahead #4).
7. **Errors.** Every repository call wraps Drift/sqlite exceptions in a typed `StorageException(kind)` (`open`, `read`, `write`, `tooNew`, `corrupt`). Screens map it to the §5 copy. Each write is one `transaction(...)`, so it is all-or-nothing (AC-4).
8. **Riverpod without codegen** (keeps D-027). About 8 small manual providers. Riverpod codegen would force `flutter_riverpod` 3.5.0 + `riverpod_lint` 3.2.0 (look-ahead #10) for little gain.
9. **Generated Drift code is committed** (`*.g.dart`, schema snapshot). Then `check.ps1`, the Tester and a fresh clone need no generate step. A new `check.ps1` step regenerates and fails if any generated file changed (look-ahead #1, #11).

## 2. Files / modules
| Path | Add / Change | What |
|---|---|---|
| `app/pubspec.yaml`, `pubspec.lock` | Change | Packages in §4; `flutter pub upgrade sqlite3` so sqlite3 ≥ 3.9.1 (look-ahead #17) |
| `app/build.yaml` | Add | Drift options: `databases: app_database: lib/data/database/app_database.dart`, `schema_dir: drift_schemas/`, `test_dir: test/drift/`; `store_date_time_values_as_text: false` (unused, we have no `DateTime` columns) |
| `app/lib/data/database/tables.dart` | Add | Table classes (§3) |
| `app/lib/data/database/converters.dart` | Add | `CalendarDateConverter` (int day number ↔ `CalendarDate`), `PaiseConverter` (int ↔ `Paise`) |
| `app/lib/data/database/app_database.dart` (+ `.g.dart`) | Add | `@DriftDatabase`, `schemaVersion => 1`, `MigrationStrategy` (`onCreate` incl. triggers + indexes, `onUpgrade` step-by-step via `drift_dev make-migrations`, throws on `from > to`, `beforeOpen` foreign keys) |
| `app/lib/data/database/database_connection.dart` | Add | `openAppDatabase({QueryExecutor? executor})`, the `setup` version guard, `DatabaseTooNewException` |
| `app/drift_schemas/app_database/drift_schema_v1.json` | Add | Schema snapshot v1 (`dart run drift_dev make-migrations`) |
| `app/test/drift/app_database/…` | Add | Generated migration test scaffolding + our v1-with-sample-data fixture test (AC-7) |
| `app/lib/data/repositories/storage_exception.dart` | Add | `StorageException` + `StorageFailureKind` |
| `app/lib/data/repositories/month_repository.dart` | Add | Interface: `watchCurrentMonth(today)`, `latestConfirmedMonth()`, `confirmMonth(NewMonth)`, `addPeriod(monthId, BudgetPeriod)` (an edit), `watchMonthInput(monthId)` |
| `app/lib/data/repositories/transaction_repository.dart` | Add | Interface: `watchMonthSpends(monthId)`, `add`, `update`, `delete`. Each write returns `SpendWriteOutcome(reductions)` (D-040) |
| `app/lib/data/repositories/savings_repository.dart` | Add | Interface: `watchCovers(monthId)`, `cover(monthId, day, amount, today)` (checked by `checkCover`; no UI until Phase 3, used by tests) |
| `app/lib/data/repositories/drift_*_repository.dart` | Add | Drift implementations. After every spend write, inside the **same transaction**: load the month, run `computeMonth`, store any reduced/clamped cover amounts, return the reductions |
| `app/lib/core/providers/database_providers.dart` | Add | `appDatabaseProvider` (FutureProvider), the 3 repository providers, `monthInputProvider(monthId)` (StreamProvider family combining periods + spends + covers), `monthResultProvider` (engine output) |
| `app/lib/features/storage_error/storage_error_screen.dart` | Add | §5 copy, **Try again**; `Semantics` per F-004 |
| `app/lib/core/copy/storage_copy.dart` | Add | F-007 §5 strings (single source, used by F-008/F-009 for the save/load errors) |
| `app/lib/app.dart` | Change | `home:` becomes `DatabaseGate(child: AppShell())`. While the database opens: a blank themed frame (no spinner flash under ~100 ms); on error: `StorageErrorScreen` |
| `app/lib/main.dart` | Change | Hook `Logger.root` (D-019): in debug, print `level: logger: message`; never record parameters. No other change: the database opens lazily in the gate, so the first frame still comes from the preferences store (F-002 AC-7) |
| `app/android/app/src/main/AndroidManifest.xml` | Change | `android:allowBackup="false"`, `android:fullBackupContent="false"`, `android:dataExtractionRules="@xml/data_extraction_rules"` (look-ahead #14) |
| `app/android/app/src/main/res/xml/data_extraction_rules.xml` | Add | `<cloud-backup>` excludes every domain (`root`, `file`, `database`, `sharedpref`, `external`); `<device-transfer>` **includes** `database` and `sharedpref` (D-045, D-049). On API 31+ `allowBackup="false"` does not stop device transfer, so the rules decide; on API ≤ 30 `allowBackup="false"` stops both (accepted, D-049) |
| `app/test/helpers/fake_month_repository.dart`, `fake_transaction_repository.dart`, `fake_savings_repository.dart` | Add | In-memory fakes with `StreamController.broadcast`, an optional `failNextWrite` flag (AC-10) and the same engine call for reductions |
| `app/test/helpers/test_database.dart` | Add | `AppDatabase` on `DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true)` (look-ahead #5) |
| `app/test/data/database/*_test.dart`, `test/data/repositories/*_test.dart`, `test/features/storage_error/*_test.dart`, `test/architecture/repositories_only_test.dart`, `test/architecture/no_data_in_logs_test.dart` | Add | Tests named `TC-007-NN …` |
| `app/integration_test/persistence_test.dart` | Add | Emulator: save → force-stop/reopen is manual (Tester); the automated part saves and reloads through a fresh `AppDatabase` on the real file, plus 500-row timing (AC-1, AC-14) |
| `tool/check.ps1` | Change | New steps: Drift codegen up to date; `tool/domain_coverage.ps1`; `tool/tz_matrix.ps1` on the date test files (F-006 + F-007) |
| `README.md` §13 | Change | "The first build after a clean needs internet access (sqlite3 binaries from GitHub, ~7 MB)" (look-ahead #2) |
| `docs/DECISIONS.md` | Change | D-018 versions updated; new entries for D-019 activation, append-only triggers, recompute-not-store, backup rules |

## 3. Data model / database changes
Schema **v1** (all money `INTEGER` paise; all calendar dates `INTEGER` day numbers; all times `INTEGER` UTC epoch ms):

| Table | Columns | Notes |
|---|---|---|
| `budget_months` | `id` PK · `start_day` · `end_day` · `salary_day` (1–31, CHECK) · `first_budgeted_day` · `confirmed_at` | UNIQUE(`start_day`). One row per confirmed month; no update except none needed in Phase 2 |
| `budget_periods` | `id` PK · `month_id` FK → months · `start_day` · `changed_at` · `kind` (`full` / `midMonthStart`, CHECK) · `salary_paise` NULL · `target_paise` NULL · `money_left_paise` NULL · `continued_with_shortfall` (bool) · `shortfall_paise` (≥ 0) | **Append-only** (triggers). INDEX(`month_id`, `start_day`, `changed_at`). CHECK: `full` → salary NOT NULL; `midMonthStart` → money_left NOT NULL |
| `period_fixed_costs` | `id` PK · `period_id` FK → periods · `position` · `name` (1–40 chars, CHECK) · `amount_paise` (≥ 0) | **Append-only** (triggers). Each period has its own copy (§2.1). "Still to pay" items of a mid-month start are the same table |
| `transactions` | `id` PK · `month_id` FK · `day` · `amount_paise` (> 0, CHECK) · `direction` (`spend` / `money_in`, CHECK, default `spend`; D-047) · `note` (≤ 100 chars, default '') · `source` (`manual`, CHECK; Phase 4 adds `sms`) · `category` NULL · `created_at` · `edited_at` | INDEX(`month_id`, `day`). Real delete in Phase 2; **no soft-delete column yet** (Phase 4 adds what SMS de-duplication needs, by migration) |
| `savings_moves` | `id` PK · `month_id` FK · `covered_day` · `amount_paise` (≥ 0) · `made_at` | Updated in place only when D-040 reduces a cover or an edit clamps it to a lower overspend, in the same transaction as that edit (D-048; an amount of 0 is kept as history: "taken back") |

- **Foreign keys** on, `ON DELETE RESTRICT` (no month delete in Phase 2).
- **Triggers** are created in `onCreate` and are part of the v1 snapshot.
- **Migrations:** step-by-step (`stepByStep` from `make-migrations`). There is one committed JSON snapshot per version, plus a generated test per step and our fixture test, which opens a committed v1 file with sample rows and checks the values (AC-7).
- **Newer file:** guarded in `setup` (§1.4).
- **The file lives in** `getApplicationDocumentsDirectory()` (drift_flutter's default; `/data/user/0/<app id>/app_flutter/budget.sqlite`). This is app-private: no other app can read it (AC-12).

## 4. Packages (latest stable, checked on pub.dev 2026-11-10)
| Package | Version | Why |
|---|---|---|
| `drift` | `^2.35.4` | Type-safe SQLite, migrations, reactive streams (D-018; 2.35.4 is newer than D-018's 2.35.3) |
| `drift_flutter` | `^0.3.1` | Opens the database in app storage on a background isolate; `setup` hook used for the version guard. Brings `sqlite3_flutter_libs 0.6.0+eol` / `sqlcipher_flutter_libs 0.7.0+eol` as empty stubs (AC-13, look-ahead #6) |
| `logging` | `^1.3.0` | D-019, first feature that logs (open/close/failure kinds only, never values) |
| `drift_dev` (dev) | `^2.35.3` | Code generation + `make-migrations` |
| `build_runner` (dev) | `^2.17.1` | Runs `drift_dev` |
| `integration_test` (dev, SDK) | from Flutter SDK | AC-1/AC-14 on the emulator |
| `sqlite3` | 3.9.1 (transitive, via `flutter pub upgrade sqlite3`) | Native SQLite 3.54 via build hooks; prebuilt, 16 KB aligned, NDK 28.2 (look-ahead #2, #3) |

**Not added:** `sqlite3_flutter_libs`, `sqlcipher_flutter_libs` or any encryption package as a direct dependency (D-041, AC-12, AC-13); `path_provider` (drift_flutter handles the path); Riverpod codegen packages (§1.8). `riverpod_lint` stays 3.1.9 with `flutter_riverpod` 3.4.3 (the lock keeps 3.4.3; `flutter pub add` must not bump it, which is checked after the `pub add`).

## 5. Tasks
**All F-007 tasks wait for Phase 1 Owner approval** (or for the Project Manager confirming the touched files are closed). They touch `pubspec.yaml/.lock`, `main.dart`, `app.dart`, the manifest, `check.ps1` and `README.md` (D-033, F-007 §2.10).

| ID | Task | Covers AC | Depends on | Status |
|---|---|---|---|---|
| T-206 | **Packages + build check.** `flutter pub add` (§4), `flutter pub upgrade sqlite3`, `build.yaml`. Verify riverpod stays 3.4.3, `dart analyze --fatal-infos` clean, `flutter build apk --debug` on NDK 28.2. Add the `check.ps1` steps (codegen up to date, domain coverage, TZ matrix). README §13 internet note. Record versions in DECISIONS | AC-13 (build, lock stubs), AC-15 | **Phase 1 approved**; T-205 | Code review |
| T-207 | **Schema v1.** Tables (incl. `transactions.direction`, D-047), converters (+ pure converter tests: 9 Nov 2026, 29 Feb 2028, 31 Dec → 1 Jan), CHECKs, indexes, append-only triggers, foreign keys, `make-migrations` snapshot v1, v1 fixture file + migration test | AC-2, AC-3, AC-7, AC-16 (triggers), AC-19 (schema) | T-206 | Code review |
| T-208 | **Opening and failures.** `openAppDatabase` with the `setup` version guard, `appDatabaseProvider` + probe, `DatabaseGate` in `app.dart`, `StorageErrorScreen` + `storage_copy.dart`, Try again, logging hook in `main.dart` (D-019). Tests: newer-version fixture (file bytes unchanged, SHA-256 before/after), corrupt fixture, forced open failure via a provider override, preferences still work | AC-8, AC-9 | T-207 | Code review |
| T-209 | **Repositories + providers + fakes.** Three interfaces, Drift implementations (transactions per write; D-040 reductions persisted in the same transaction), `StorageException` mapping, `database_providers.dart`, the three fakes and `test_database.dart`. Tests: round-trips, all-or-nothing via a **test-only SQLite trigger** that aborts the 3rd fixed-cost insert (no hook in app code), live updates, append-only (rows compared before/after each change), mid-month + shortfall round-trip, an architecture test that `features/` and `domain/` import no `drift`/`sqlite3`/`data/database/` | AC-1 (host part), AC-2, AC-4, AC-5, AC-6, AC-10 (repository part), AC-16, AC-17, AC-18, AC-19 | T-208, T-204 | Code review |
| T-210 | **Privacy.** Manifest flags + `data_extraction_rules.xml` (cloud backup off, device transfer **on**, D-045/D-049); a test that reads the merged manifest after `flutter build apk --debug` (`build/app/intermediates/merged_manifests/…`) for `allowBackup="false"` and the rules; a log-capture test (`Logger.root.onRecord`) over the F-007 repository tests asserting no amount/note/date appears; a check that no encryption package is a direct dependency | AC-11, AC-12 | T-209 | Code review |
| T-211 | **On-device persistence + speed.** `integration_test/persistence_test.dart`: real file, save the AC-1 data set, reopen, compare; 500 transactions, list query < 1 s, single write < 500 ms. Hand the force-stop/emulator-restart steps to the Tester | AC-1, AC-13 (device), AC-14 | T-210 (and F-009 T-218 for the list timing on screen) | Code review |

## 6. Acceptance criteria coverage
TC IDs are the Tester's (`tests/F-007-local-database.md` §2.4), reconciled at Gate 1.

| AC | Built in task | Proved by test cases |
|---|---|---|
| AC-1 Data survives restart | T-209 (host), T-211 (device) | TC-007-01, -02, -03, -29, -30 |
| AC-2 Integer paise | T-207, T-209 | TC-007-04, -05, -29, -42 |
| AC-3 Calendar dates as day numbers, 3 `TZ` runs | T-207 (+ `tz_matrix.ps1` from T-205) | TC-007-06, -07, -08, -37 |
| AC-4 All-or-nothing month save | T-209 | TC-007-09, -10, -33, -35 |
| AC-5 Live updates | T-209 | TC-007-11, -12, -31, -39 |
| AC-6 Repositories only | T-209 | TC-007-13 |
| AC-7 Schema v1 + migration test | T-207 | TC-007-14, -38 |
| AC-8 Newer database not destroyed | T-208 | TC-007-15, -41 |
| AC-9 Can't open → error screen, Try again | T-208 | TC-007-16, -17 |
| AC-10 Write failure keeps input | T-209 (repository), F-008 T-215 / F-009 T-219 (screens) | TC-007-18, -32 (and TC-008-17, TC-009-15) |
| AC-11 No cloud backup, device transfer included (D-045), no data in logs | T-210 | TC-007-19, -20, -21, -45, -48 |
| AC-12 No extra encryption, private storage | T-210 | TC-007-22 |
| AC-13 Native build, only `+eol` stubs | T-206, T-211 | TC-007-03, -23 |
| AC-14 Speed (500 rows) | T-211 | TC-007-24, -44 |
| AC-15 Regression | T-206 … T-211 (each ends with `check.ps1`) | TC-007-25 |
| AC-16 Period history never overwritten | T-207 (triggers), T-209 | TC-007-26, -27, -43 |
| AC-17 Mid-month start and shortfall stored | T-209 | TC-007-28 |
| AC-18 Cover reductions and clamps stored with the edit (D-048) | T-209 | TC-007-46 |
| AC-19 Money in stored (D-047) | T-207, T-209 | TC-007-47 |
| §2.6 read failure, §4 two stores, clear data | T-208, T-209 | TC-007-40, -34, -36 |

## 7. Edge cases & risks
| Case / risk | How it is handled |
|---|---|
| Disk full / write fails | One transaction per write; `StorageException(write)`; the screen keeps the input (AC-10). Earlier data untouched |
| App killed mid-write | SQLite transaction (rollback journal): full record or nothing |
| Long note with emoji / Hindi (100 chars) | `TEXT` UTF-8; round-trip test with `'चाय ☕…'`; the 100-character limit is counted in **user-perceived characters** by F-009 (see F-009 plan), with a CHECK `length(note) <= 400` (SQLite counts code points) as a backstop |
| Duplicate spends | Never merged (no UNIQUE on spends) |
| Older app over newer database | `setup` guard → `tooNew` → error screen; bytes unchanged (AC-8) |
| Corrupt file | Probe query fails → error screen; file kept |
| Clearing app data | Fresh database; expected |
| Device-to-device transfer | **Included** in `data_extraction_rules.xml` `<device-transfer>` (D-045); cloud backup excluded. Android ≤ 11: no transfer (D-049). A restored database is a normal v1+ file, so the open guard and migrations apply unchanged |
| Time zone / clock change | Day numbers (AC-3); times only order rows |
| Database failure vs preferences | Separate stores; `DatabaseGate` sits below the theme, so theme/tour work with a broken database (test in T-208) |
| Risk: Drift stream + widget tests hang | Widget tests use fakes; the few Drift-backed tests use `closeStreamsSynchronously: true`, `runAsync` writes, `pump()` (look-ahead #5) |
| Risk: first build offline | README §13 note; `.dart_tool` caches the binaries after the first build |
| Risk: Phase 1 still open when F-006 ends | F-007 waits; F-006 does not depend on it |
| Risk: generated code drifts from sources | Committed + `check.ps1` regenerate-and-compare step |

## 8. Impact on existing features
- **F-001:** `check.ps1` gains steps (TC-001-44 step list and `tests/REGRESSION.md` check 1 need updating by the Tester); `analysis_options.yaml` is unchanged (generated files carry `ignore_for_file: type=lint`, look-ahead #11).
- **F-002:** `app.dart` changes (`DatabaseGate`). F-002 AC-7 (first frame already in the saved theme) must stay green. Re-run TC-002 Regression-yes cases.
- **F-003:** the shell is now below the gate. Re-run TC-003 shell cases. `pumpBudgetApp` in `test/helpers/pump_app.dart` gets an optional override for the database providers (default: fakes), so existing tests need no change.
- **F-004/F-005:** no change. Re-run Regression-yes cases (the tour runs before the shell; the gate must not block it).
- Full `flutter test`, `tool/check.ps1`, `tests/REGRESSION.md` after every task.

## 9. Open questions
1. **Owner (privacy):** should the budget data move to a new phone with Android's device-to-device transfer? The plan **excludes** it (data stays on this phone only, D-003 spirit). Including it is one line in `data_extraction_rules.xml`. Flagged in F-007 "Suggested additions".
2. **PM:** "what changed from the previous period" is derived by the engine (F-006 plan §9 Q3) rather than stored. Accept?
3. **PM:** D-040 reductions persisted by the repository (F-006 plan §9 Q2). Accept?
4. **PM / CEO:** "Delete all app data" (STANDARDS §8) stays out of Phase 2 per F-007 §6; the repositories make it a small task later (close the database, delete the file, clear preferences).

*Answered at Gate 1 (PM, 2026-11-10):* Q1 decided by the Owner, **D-045: device-to-device transfer includes the budget data**; cloud backup stays off (the plan's "exclude" is reversed, see §2 and §7). Q2 accepted (derived, D-048). Q3 accepted (persisted, D-048, AC-18). Q4 agreed: "Delete all app data" stays out of Phase 2 (F-007 §6; already in the F-007 Suggested additions for the CEO).

## 10. Project Manager review *(Gate 1 — cross-check of doc + plan + test cases)*
**Verdict:** **Approved** (Project Manager, 2026-11-10). Every task waits for the Owner's Phase 1 approval (they touch `pubspec`, `main.dart`, `app.dart`, the manifest, `check.ps1`, `README.md`; D-033).

Cross-check:
- [x] Every AC in the feature doc is covered by a task in this plan (AC-1 … AC-19 → T-206 … T-211, §6)
- [x] Every AC has at least one test case in the test file (TC-007-01 … -48)
- [x] Edge cases in the doc appear in both the plan and the test cases (disk full, killed mid-write, long Hindi/emoji notes, duplicates, real delete, clear data, older app over newer file, device transfer, time zones, two independent stores)
- [x] Approach follows `docs/STANDARDS.md` (repositories + providers, no Drift in `features/`/`domain/`, integer paise and day numbers, typed failures, nothing in logs)
- [x] Latest stable versions / modern APIs used (drift 2.35.4, drift_flutter 0.3.1 build hooks, `make-migrations` step-by-step, sqlite3 ≥ 3.9.1, no `sqlite3_flutter_libs`; look-ahead §2)

| # | Point | Type | Resolution |
|---|---|---|---|
| 1 | **D-045 device transfer included.** The plan excluded it; reversed. `<cloud-backup>` excludes every domain; `<device-transfer>` includes `database` and `sharedpref`; `allowBackup="false"` stays. On Android 12+ (target 31+) `allowBackup="false"` disables cloud backup but not device transfer, so the rules decide. On Android 11 and older the two are tied, so there is no transfer there; we accept that rather than risk any cloud copy (D-003 wins, D-049). **T-210 condition:** the Developer checks this against the current Android "data backup / device-to-device transfer" docs and records the source in plan §11; the Tester proves it with TC-007-19 (XML) and TC-007-48 (device transfer test transport on the emulator, if available). | Must fix → done by PM | F-007 §2.7, §4, AC-11; plan §2, §7, T-210; TC-007-19 updated, TC-007-48 added. |
| 2 | **D-047 money in.** `transactions.direction` (`spend` / `money_in`, CHECK) in schema v1, so Phase 4 SMS credits need no migration for it. `amount_paise` stays > 0. Phase 2 screens write only `spend`. | Must fix → done by PM | F-007 §2.1, AC-19; plan §3, T-207/T-209; TC-007-47 added. |
| 3 | **Cover reductions and clamps stored with the edit** (F-006 plan Q2). Accepted; same transaction as the spend write; a later pot increase never restores them. | Resolved (D-048) | F-007 §2.1, AC-18; TC-007-46 added. |
| 4 | **Order within a day** (test note 2). `created_at` descending, then `id` descending as the tie-break. An edit (even a date change) does not change `created_at`, so it never jumps to the top. | Resolved (D-048) | F-007 §2.1; TC-007-39 expectation confirmed; F-009 §2.1 wording "newest added first". |
| 5 | **"What changed" derived** — no column. | Resolved | F-007 §2.1. |
| 6 | **Storage error screen and load-error state design** (plan "Design" row). Specified at Gate 2 in `month-setup.md` §10.4–10.5 and `transactions.md` §6.5 (PM addition; empty-state pattern, no new component). | Resolved | `docs/reviews/design-phase-2.md`. |
| 7 | **Generated code committed** + regenerate-and-compare in `check.ps1`: agreed (look-ahead #1, #11). TC-007-38 applies (not N/A). | Resolved | — |
| 8 | **D-018 versions**: update to drift 2.35.4 / drift_dev 2.35.3 in T-206, with `intl` 0.20.3 and `logging` 1.3.0 rows (TC-001-24/-25). | Resolved | T-206. |
| 9 | **Nice to have:** a debug-only delay hook in the save path would make TC-007-33 repeatable (test note 5). Only if it costs one line behind `kDebugMode`; otherwise best effort. | Nice to have | Developer's choice in T-209; noted in §11. |
| 10 | **Nice to have:** "automatic local snapshot before each migration" (F-007 Suggested additions) — revisit with the first v2 migration (Phase 3/4). | Nice to have | Follow-up task T-222. |

## 11. Implementation notes *(Developer A, 2026-11-13)*
Tasks T-206 to T-211 are in Code review. A previous session built most of the files; this pass inspected each against the plan, fixed what was missing and verified everything.

Deviations and findings:
- **`intl` is not a dependency.** D-070 dropped it (unused); removed from `pubspec.yaml` and the lock in T-206. The plan's package list (section 4) did not name `intl`, D-067 did.
- **`sqlite3` 3.9.1** needs `flutter pub upgrade sqlite3 hooks meta record_use` (the plain upgrade stays at 3.5.2); recorded in D-067.
- **Repository interface names** differ slightly from section 2: `watchCurrentMonth`, `watchLatestMonth`, `watchMonth`, `latestConfirmedMonth`, `confirmMonth`, `addPeriod`; fakes share one `FakeMoneyStore` (`test/helpers/fake_money_store.dart`).
- **Logging hook** lives in `core/logging/app_logging.dart` (not inline in `main.dart`).
- **TC-007-02, -17, -20, -23, -25, -33, -36, -37, -38, -41, -48** are manual/device cases for the Tester (no automated test by design); -25 and -38 are what `tool/check.ps1` runs. No debug delay hook for TC-007-33 (PM Nice to have 9, not built).
- **Android backup source (D-049, PM condition):** Android developer docs "Back up user data with Auto Backup" and "Configure data extraction rules" (`android:dataExtractionRules`, API 31+; `android:fullBackupContent` API 23 to 30; `allowBackup="false"` disables cloud backup, and on API 31+ `<device-transfer>` rules still apply). Built to that behaviour; not re-fetched this session. The merged manifest of the debug build carries all three attributes (TC-007-19).
- Verification: `tool/check.ps1` ALL CHECKS PASSED (452 tests, drift codegen current, domain coverage 100%, TZ matrix 3 zones). On-device: `flutter test integration_test/persistence_test.dart -d emulator-5554` 2/2 pass; 500 rows list 58 ms, write 63 ms.
- **PM Gate 3 (2026-11-13):** Android backup behaviour re-checked by the Project Manager against the Android developer page "Auto Backup for Apps" (API 31+ `dataExtractionRules` with separate `<cloud-backup>` and `<device-transfer>`; API 30 and lower `fullBackupContent`; with `allowBackup="false"` some manufacturers still do device-to-device transfer). Matches the build. TC-007-33 hook not built: accepted. Nice to have N2 (no `<cross-platform-transfer>` section, Android 16 QPR2) is in `docs/reviews/code-phase-2.md`.
