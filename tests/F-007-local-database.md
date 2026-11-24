# Test Cases — F-007: Local database

| | |
|---|---|
| **Feature doc** | [`docs/features/F-007-local-database.md`](../docs/features/F-007-local-database.md) (final Spec, 17 ACs; D-041 no extra encryption) |
| **Plan** | [`plans/F-007-local-database.md`](../plans/F-007-local-database.md) (Draft, read 2026-11-10 after these cases were written; its table, class and file names win over the proposals in §0. Its §6 proposed one TC per AC (TC-007-01 … -17); **this file is authoritative** and the AC → TC map is §2.4) |
| **Author** | Tester (written **before** development, approved by Project Manager at Gate 1) |
| **Status** | Approved (Gate 1, 2026-11-10); Step 8 run R1 2026-11-13: 46 Pass, 1 Partial, 1 Blocked, 0 Fail; **run R2 2026-11-16 (Gate 4 conditions, TC-007-33 kill timing re-run): 47 Pass, 1 Blocked (TC-007-48), 0 Fail** (report in section 5) |
| **Change history** | 2026-11-10 (Tester, Step 4): first version, TC-007-01 … TC-007-45. Same day: aligned with the Developer's draft plan (file names, impact §2.1, open questions in §2.3) and AC → TC map added (§2.4); no ID changed. 2026-11-10 (PM, Gate 1): D-045 applied to TC-007-19 (device transfer **included**); new TC-007-46 (stored cover changes, AC-18), TC-007-47 (money in, AC-19), TC-007-48 (device transfer on the emulator, AC-11); notes §2.3 answered; status Approved |
| | 2026-11-16 (Tester, T-312, D-078): Phase 3 additive repository changes covered by new TC-007-49 to -53 (`cover()` returns the stored id, `removeCovers`, `watchMonthIndex` cross-reference to F-011 TC-011-59 to -66). TC-007-10, -11, -12, -14 and -18 are unchanged and re-run when F-011 T-322 and F-012 T-341 land; F-007 stays Done and the recorded R1/R2 results are history |

## 0. How to run these cases

**Environment:** as F-002 §0 (Windows 11, PowerShell 5.1, Flutter 3.47.9 / Dart 3.13.7, emulator `emulator-5554` = AVD `Medium_Phone_API_37.0`, Android 17 / API 37; setup S1 from F-001 §0). Commands run from `app/` unless stated. **Scheduling (D-033):** cases that need Drift in `pubspec.yaml`, the manifest or startup files can only run after Phase 1 is Owner-approved; until then they are not run (not Blocked, not Fail).

**Where each case runs** (column "Type" plus a tag in the Scenario):

| Tag | Meaning |
|---|---|
| **[MEM]** | Real SQLite through Drift **in memory** in plain `flutter test` on Windows: `NativeDatabase.memory()` (look-ahead #4). No emulator. For stream tests open it as `DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true)` (look-ahead #5) |
| **[FILE]** | Real SQLite on a **file** in a per-test temp folder (`Directory.systemTemp.createTempSync('tc007')`), in `flutter test`. Used for restart (close + reopen), fixtures (v1 sample, newer version, corrupt) and byte comparisons. Deleted in `addTearDown` |
| **[EMU]** | Needs the emulator (integration test or manual). Recorded **Blocked** only for an environment failure (no emulator, SDK/NDK missing), with the exact error, as F-002 §0 [P] |
| **[FAKE]** | Widget test with in-memory **fake repositories** (no Drift in widget tests, look-ahead #5). The fakes implement the same repository interfaces; modes `ok` · `writeFails` · `readFails` · `openFails` |

**Definitions**

| Name | Meaning |
|---|---|
| **Seed E2** | One confirmed month: salary day 5; 5 Nov–4 Dec 2026; salary 40,00,000 paise; no target; fixed costs Rent 10,00,000 · EMI 5,00,000 · Subscriptions 10,000 (in that order); first budgeted day 5 Nov |
| **Seed T5** | Five transactions on Seed E2: 9 Nov 25,000 "Lunch"; 9 Nov 40,000 "Groceries"; 8 Nov 31,000 no note; 6 Nov 1,00,000 "रिक्शा 🛺"; 5 Nov 1 paisa "Tea". Plus 1 savings move: 6 Nov covered 17,000 |
| **Restart (sim, DB)** | Close the Drift database (`await db.close()`), drop every repository object, open a **new** database on the same file, read back through new repositories |
| **Restart (real)** | As F-002 §0: `adb shell am force-stop com.dailybudget.app`, then `adb shell am start -n com.dailybudget.app/.MainActivity` |
| **Row snapshot** | All rows of the period and fixed-cost tables read with raw SQL (`customSelect('SELECT * FROM …')`) into a list of maps, sorted by primary key |
| **Log capture** | `Logger.root.level = Level.ALL`; collect every `LogRecord` (message, error, stack) for the test; tests fail if a record contains any test value (TC-007-21) |

**Conventions:** test names start with `TC-007-NN ` (TC-001-12). Expected copy is a literal from F-007 §5. Dates in tests are built from year/month/day, never from the clock.

**Test files** (plan F-007 §2; the file names in the "Automated test" column are the Tester's proposal, the plan's names win): `test/data/database/*_test.dart` (schema, converter, open failures, time zones), `test/data/repositories/*_test.dart` (repositories on `test/helpers/test_database.dart`, in-memory Drift), `test/drift/app_database/…` (Drift schema snapshot + migration tests, `test_dir: test/drift/`), `test/architecture/repositories_only_test.dart` (TC-007-13), `test/architecture/no_data_in_logs_test.dart` (TC-007-21), `test/features/storage_error/*_test.dart` (TC-007-15, -16, -18, -34, -40, -45), `integration_test/persistence_test.dart` (TC-007-03, -24); fakes `test/helpers/fake_month_repository.dart` (and the transaction/savings fakes); fixtures in `test/fixtures/db/` (`v1_sample.sqlite`, `v99_newer.sqlite`, `corrupt.sqlite`) unless the plan names another folder. The three-zone run uses `tool/tz_matrix.ps1` (plan F-006 T-205).

## 1. Test cases
Types: **Auto-unit** · **Auto-widget** · **Auto-integration** · **Manual** (incl. **Manual (command)**).
Automated tests include the TC ID in their name, e.g. `test('TC-007-05 money columns round trip exactly', …)`.
**Regression = yes** means the case is re-run in every full regression (automated cases always are; mark important manual cases yes).

| ID | AC | Scenario | Test data | Steps | Expected | Type | Automated test | Regression |
|---|---|---|---|---|---|---|---|---|
| TC-007-01 | AC-1 | Everything survives a restart **[FILE]** | Seed E2 + Seed T5 | Write through the repositories; **Restart (sim, DB)**; read month, period, fixed costs, transactions, move | Every value identical: amounts in paise, calendar dates, notes byte-for-byte (incl. Hindi and emoji), fixed-cost order Rent, EMI, Subscriptions, transaction order (newest day first, newest first within a day), the move (6 Nov, 17,000) | Auto-unit | `TC-007-01 month costs spends and moves survive a database reopen` (`months_repository_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/repositories/months_repository_test.dart`. | yes |
| TC-007-02 | AC-1 | Survives force-stop and a full emulator restart **[EMU]** | Feature doc §2 example: confirm Seed E2 in the app (F-008), add ₹250 dated 9 Nov (F-009) | 1. **Restart (real)**. 2. `adb reboot`, wait for boot, open the app. 3. Open Home and Transactions each time | Month, the three fixed costs and the ₹250 spend on 9 Nov are shown exactly as entered after both restarts; the stored amount is 25,000 paise (checked in the integration test of TC-007-03) | Manual | — | yes |
| TC-007-03 | AC-1, AC-13 | Real-device round trip **[EMU]** | Seed E2 + Seed T5 | Integration test: write via repositories with the real `drift_flutter` opener; close; open a new database instance; read | Same as TC-007-01, on Android; the database file exists under the app's private data folder | Auto-integration | `TC-007-03 database round trip on the device` (`integration_test/persistence_test.dart`) **Files, Step 8 (2026-11-13, passing):** `integration_persistence_test.dart`. | yes |
| TC-007-04 | AC-2 | Money columns are integers **[MEM]** | Schema v1 | `PRAGMA table_info(<table>)` for every table; list columns the plan names as money | Every money column has declared type `INTEGER`; no column in any table has type `REAL`, `DOUBLE`, `FLOAT` or `NUMERIC`. The money-column list in the test is a literal agreed in the plan (salary, target, money left, shortfall, fixed-cost amount, transaction amount, move amount, any stored day budget) | Auto-unit | `TC-007-04 every money column is an integer column` (`schema_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/database/schema_test.dart`. | yes |
| TC-007-05 | AC-2 | Money round trip exact **[MEM]** | 1 · 1,33,333 · 24,90,000 · 10,00,00,00,000 paise, in **every** money column | Write each value, read back (also via raw SQL `typeof(col)`) | Same integers back; `typeof` = `integer`; 25,000 never becomes 24,999 | Auto-unit | `TC-007-05 money values round trip exactly in every column` (`schema_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/database/schema_test.dart`. | yes |
| TC-007-06 | AC-3 | Calendar-date converter, pure | 1 Jan 1970 (day 0), 9 Nov 2026, 29 Feb 2028, 31 Dec 2026 → 1 Jan 2027, 31 Dec 2099, 28 Feb 2027 → 1 Mar 2027 | Convert to the integer day number and back | Each round-trips to the same year/month/day; consecutive dates differ by exactly 1; 1 Jan 1970 = 0 (if the plan picks days-since-epoch; `yyyymmdd` is also allowed by the spec, then 9 Nov 2026 = 20261109); the converter never calls `toLocal`, `DateTime.now` or a local `DateTime` constructor | Auto-unit | `TC-007-06 calendar date converter round trips exact dates` (`calendar_date_converter_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/database/calendar_date_converter_test.dart`. | yes |
| TC-007-07 | AC-3 | Date columns are integer day numbers **[MEM]** | Schema v1; table sources in `lib/data/database/` | 1. `PRAGMA table_info`: every calendar-date column (transaction date, month start/end, first budgeted day, period start, covered day). 2. Scan table sources for `dateTime()` on those columns (§1.1 → TC-007-07) | 1. Type `INTEGER`; a raw read of 9 Nov 2026 returns the day number, not a timestamp. 2. `dateTime()` appears only for created/edited/move/change **times** (ordering only) | Auto-unit + Manual (command) | `TC-007-07 calendar date columns store integer day numbers` (`schema_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/database/schema_test.dart`. | yes |
| TC-007-08 | AC-3 | Saved 9 Nov reads back 9 Nov in three time zones **[FILE]** | Transaction dated 9 Nov 2026 | See §1.1 → TC-007-08: run `database_time_zone_test.dart` with `TZ=UTC`, `TZ=PST8PDT`, default (IST). Run 1 (default) writes the file to `build/tz/f007.sqlite`; runs 2 and 3 only read it | All three runs read 9 Nov 2026; the sentinel check in each run proves the zone was applied (`timeZoneOffset` 0 h / −8 h / +5:30 h, as TC-006-27). Negative control in the same file: a `DateTime` stored as a local timestamp **does** change day under UTC (shows the test can fail) | Manual (command) + Auto-unit | `TC-007-08 transaction date reads back the same day in every time zone` (`database_time_zone_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/database/database_time_zone_test.dart`. | yes |
| TC-007-09 | AC-4 | All-or-nothing month save **[MEM]** | Month with 4 fixed costs; test hook makes the insert of the 3rd cost throw | Confirm through the months repository | Repository returns/throws its failure type (no raw Drift exception escapes); afterwards 0 months, 0 periods, 0 fixed costs in the database (count via raw SQL) | Auto-unit | `TC-007-09 failed month save stores nothing` (`months_repository_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/repositories/months_repository_test.dart`. | yes |
| TC-007-10 | AC-4 | All-or-nothing edit and cover **[MEM]** | Seed E2; (a) edit (new period + 3 items) with the 2nd item insert failing; (b) savings move with a forced failure after the insert | Run each | (a) period count still 1; Row snapshot equal to before. (b) 0 moves; pot unchanged. Repository reports failure | Auto-unit | `TC-007-10 failed edit or cover stores nothing` (`savings_repository_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/repositories/savings_repository_test.dart`. | yes |
| TC-007-11 | AC-5 | Live updates for transactions **[MEM]** | Seed E2; listener on "this month's transactions" | Add 25,000 "Lunch"; edit it to 27,000; delete it; `await pumpEventQueue()` after each | Listener receives exactly: [] → [25,000] → [27,000] → [] (4 emissions, in order) without re-subscribing; no stale list | Auto-unit | `TC-007-11 transaction listeners update on add edit and delete` (`transactions_repository_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/repositories/transactions_repository_test.dart`. | yes |
| TC-007-12 | AC-5 | Live updates for months and savings **[MEM]** | Listeners on "current month" and "moves of this month" | Confirm a month; add an edit (new period); add a move | Month listener emits null → month → month with 2 periods; moves listener emits [] → [move]. Same turn, no reload | Auto-unit | `TC-007-12 month and savings listeners update live` (`months_repository_test.dart`) **Files, Step 8 (2026-11-13, passing):** `core/providers/database_providers_test.dart`, `data/repositories/months_repository_test.dart`. | yes |
| TC-007-13 | AC-6 | Screens and domain never touch the database | `lib/features/**.dart`, `lib/domain/**.dart` | Architecture test + §1.1 → TC-007-13 | 0 imports of `package:drift`, `package:drift_flutter`, `package:sqlite3`, or any file under `data/database/` from `features/` or `domain/`. A planted bad string proves the guard fails | Auto-unit + Manual (command) | `TC-007-13 features and domain never import the database` (`test/architecture/repositories_only_test.dart`) **Files, Step 8 (2026-11-13, passing):** `architecture/repositories_only_test.dart`. | yes |
| TC-007-14 | AC-7 | Schema v1, snapshot committed, migration test | `lib/data/database/`, the plan's snapshot folder (e.g. `drift_schemas/drift_schema_v1.json`), `test/fixtures/db/v1_sample.sqlite` | 1. Read `schemaVersion`. 2. Check the snapshot file exists and equals a fresh `dart run drift_dev make-migrations`/`schema dump` output (§1.1). 3. Migration test opens a **copy** of the v1 sample file with the current code **[FILE]** | 1. `1`. 2. Snapshot exists, no diff. 3. Opens without error; `PRAGMA user_version` = 1; every sample row (month, 3 periods, items, 5 transactions, 1 move) read back intact | Auto-unit + Manual (command) | `TC-007-14 v1 sample database opens intact with current code` (`migration_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/database/migration_test.dart`, `data/database/open_failure_test.dart`. | yes |
| TC-007-15 | AC-8 | Newer database is not destroyed **[FILE]** | Copy of `v99_newer.sqlite` (`user_version` 99, real tables with rows) | SHA-256 the file; open with the app's opener; then hash again | Opener returns the "newer version" failure (no exception escapes); no migration step runs (spy on `onUpgrade`); file hash unchanged; no `-wal`/`-journal` content committed. Widget part **[FAKE]**: `openFails(newer)` shows the storage error screen (copy as TC-007-16) | Auto-unit + Auto-widget | `TC-007-15 newer database version shows the error and is left untouched` (`open_failure_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/database/open_failure_test.dart`, `features/storage_error/storage_error_screen_test.dart`. | yes |
| TC-007-16 | AC-9 | Can't open → error screen, Try again **[FILE] + [FAKE]** | (a) `corrupt.sqlite` (random bytes with a valid-looking header); (b) open failure by test hook, cleared before Try again | (a) Open, hash before/after. (b) Pump the app with `openFails`; tap **Try again** after switching the fake to `ok` | (a) Failure reported, file hash unchanged, file not deleted or replaced. (b) Full screen shows title `We couldn't open your data`, text `Your budget data is still on this phone. Try again, and if this keeps happening, restart your phone.`, button `Try again` (semantics hint `Try to open your data again`); No crash (`takeException()` null); after Try again the app continues to Home. Theme from preferences still applied (stores are independent) | Auto-unit + Auto-widget | `TC-007-16 database open failure shows the storage error and recovers on try again` (`test/features/storage_error/storage_error_screen_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/database/open_failure_test.dart`, `features/storage_error/storage_error_screen_test.dart`. | yes |
| TC-007-17 | AC-9 | Corrupt database on the device **[EMU]** | Debug build; app run once | 1. `adb shell run-as com.dailybudget.app ls -R` to find the file. 2. Force-stop; overwrite the file with garbage via `run-as` (§1.1 → TC-007-17). 3. Start the app. 4. Tap Try again. 5. Restore a good copy, Try again | 3. Error screen, no crash (`adb logcat -d` has no `FATAL`/`AndroidRuntime` for the app). 4. Still the error screen; the garbage file is still there with the same size. 5. App opens normally | Manual | — | yes |
| TC-007-18 | AC-10 | Write failure keeps input (F-008 and F-009) **[FAKE]** | Fake repos `writeFails`; F-008 with Seed E2 values typed; F-009 Add spend with 250 "Lunch" | Tap **Start my month** / **Save** | `Couldn't save. Please try again.` shown; every typed value still in its field; fake store unchanged (0 records); no navigation. Also unit level **[MEM]**: repository maps a Drift/SQLite error to its failure type, never throws a raw `SqliteException` | Auto-widget + Auto-unit | `TC-007-18 save failure keeps the input and stores nothing` (`test/features/storage_error/storage_error_screen_test.dart`); the F-008/F-009 copies are TC-008-17 / TC-009-15 **Files, Step 8 (2026-11-13, passing):** `core/providers/database_providers_test.dart`, `data/repositories/transactions_repository_test.dart`. | yes |
| TC-007-19 | AC-11 | No cloud backup; device transfer included (D-045) | Merged manifest and backup XML of the debug **and** release build | See §1.1 → TC-007-19 | `android:allowBackup="false"`; `android:dataExtractionRules` (API 31+) and `android:fullBackupContent` (≤ API 30) exist; `<cloud-backup>` excludes every domain (database, sharedpref, file, root, external); `<device-transfer>` **includes** `database` and `sharedpref` and excludes nothing of them | Manual (command) | — **Files, Step 8 (2026-11-13, passing):** `architecture/backup_and_privacy_test.dart`. | yes |
| TC-007-20 | AC-11 | Backup off on the device **[EMU]** | Installed debug build | `adb shell dumpsys package com.dailybudget.app` → `flags=`/`privateFlags=`; `adb shell bmgr list transports`; `adb shell bmgr backupnow com.dailybudget.app` | `ALLOW_BACKUP` not in `flags`; `bmgr backupnow` reports the package is not eligible / backup not allowed | Manual | — | yes |
| TC-007-21 | AC-11 | No amounts, notes or dates in logs | **Log capture** over every F-007, F-008 and F-009 test (shared `setUp` in `test/support/`) | Run the suites; the helper checks each record against the values the test used: amounts in paise and rupees (`25000`, `250`, `₹250`), notes (`Lunch`, `रिक्शा`), dates (`2026-11-09`, `9 Nov`, day number) | 0 records contain any of them; messages like `transaction saved` allowed. Plus a grep of `lib/data/` and `lib/features/` for `log.*\$amount`-style interpolation (§1.1 → TC-007-21) | Auto-unit + Manual (command) | `TC-007-21 no log record contains an amount note or date` (`test/architecture/no_data_in_logs_test.dart`, plus the shared log guard used by every F-007/008/009 test file) **Files, Step 8 (2026-11-13, passing):** `architecture/no_data_in_logs_test.dart`, `core/logging/app_logging_test.dart`. | yes |
| TC-007-22 | AC-12 | No extra encryption, private storage (D-041) | `pubspec.yaml`, `pubspec.lock`, device, `docs/DECISIONS.md` | See §1.1 → TC-007-22 | No direct dependency on `sqlcipher_flutter_libs`, `sqlite3_flutter_libs`, `sqflite_sqlcipher`, `flutter_secure_storage`, `encrypt`, `pointycastle`; no `hooks: user_defines: sqlite3: source:` set to `sqlite3mc`/`sqlcipher`. The database file is only under `/data/user/0/com.dailybudget.app/`; `adb shell ls /sdcard/Android/data/com.dailybudget.app` has no database; another app's shell (`adb shell ls /data/user/0/com.dailybudget.app` without `run-as`) gets "Permission denied". D-041 row present | Manual (command) | — **Files, Step 8 (2026-11-13, passing):** `architecture/backup_and_privacy_test.dart`. | yes |
| TC-007-23 | AC-13 | Native build with NDK 28.2 and the `+eol` stubs **[EMU]** | Clean build (`flutter clean`); internet on (first build downloads SQLite, look-ahead #2) | See §1.1 → TC-007-23 | `flutter build apk --debug` exit 0; `ndkVersion` = `flutter.ndkVersion` (28.2.13676358); `pubspec.yaml` has neither stub as a direct dependency; in `pubspec.lock` they are absent or `0.6.0+eol` / `0.7.0+eol` (or a later `+eol`); `zipalign -c -P 16 -v 4` → `Verification successful`; installed app saves and reads back a month (TC-007-03 passes) | Manual (command) | — | yes |
| TC-007-24 | AC-14 | Speed with 500 transactions **[EMU]** | Seed E2 + 500 transactions spread over 5 Nov–4 Dec (integration-test seeding) | Integration test with `Stopwatch` and `binding.traceAction`: open Transactions; add, edit, delete one spend. Manual repeat by eye | List's first frame with rows < 1,000 ms after tapping the tab; each add/edit/delete reflected in the list < 500 ms. Record the times (5 runs, report the worst) | Auto-integration + Manual | `TC-007-24 five hundred spends list and save within the time limits` (`integration_test/persistence_test.dart`) **Files, Step 8 (2026-11-13, passing):** `integration_persistence_test.dart`. | yes |
| TC-007-25 | AC-15 | Regression after F-007 | Whole project | From root `& ".\tool\check.ps1"`; then `tests/REGRESSION.md` | ALL CHECKS PASSED, exit 0; every F-001 … F-005 Regression-yes case green | Manual (command) | — | yes |
| TC-007-26 | AC-16 | Period history is append-only (D-037) **[MEM]** | Seed E2 confirmed 5 Nov; rent → 13,00,000 on 20 Nov; EMI → 4,00,000 on 28 Nov | Row snapshot before and after each change | 3 period rows, each with its own fixed-cost rows; the 5 Nov period still has Rent 10,00,000 and EMI 5,00,000; every row of the "before" snapshot appears **unchanged** in the "after" snapshot (no update, no delete; only inserts). Repository API offers no update/delete for periods or items; the plan's SQLite triggers (T-207) make a raw `UPDATE`/`DELETE` on a period or item row fail (the test tries both) | Auto-unit | `TC-007-26 budget changes only add period rows` (`period_history_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/database/append_only_triggers_test.dart`, `data/repositories/period_history_test.dart`. | yes |
| TC-007-27 | AC-16 | Past day budgets reproducible after restart **[FILE]** | As TC-007-26 | Compute the 30 day budgets with the F-006 engine from the stored data; **Restart (sim, DB)**; compute again | Identical lists: 5–19 Nov 83,000; 20–27 Nov 63,000; 28 Nov–2 Dec 77,286; 3–4 Dec 77,285 (F-006 AC-21) | Auto-unit | `TC-007-27 stored periods reproduce the same day budgets after reopen` (`period_history_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/repositories/period_history_test.dart`. | yes |
| TC-007-28 | AC-17 | Mid-month start and shortfall stored **[FILE]** | (a) First setup 10 Nov 2026, money left 24,90,000, no costs to pay. (b) S1 month continued with shortfall 1,00,000 | Save each; **Restart (sim, DB)**; read | (a) first budgeted day 10 Nov 2026; money left 24,90,000; salary "none". (b) continued-with-shortfall flag true; shortfall 1,00,000 | Auto-unit | `TC-007-28 mid month start and shortfall flag survive reopen` (`months_repository_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/repositories/months_repository_test.dart`. | yes |

### 1.1 Commands

**TC-007-07** (from `app/`; shows every `dateTime()` column so the Tester can check each is a time, not a calendar date)
```powershell
Get-ChildItem lib\data\database -Recurse -Filter *.dart | Where-Object Name -notlike '*.g.dart' | Select-String -Pattern 'dateTime\(\)'
```
Expected: only created/edited/move/change time columns.

**TC-007-08** (from `app/`)
```powershell
$runs = @(@{tz=$null; off=330; mode='write'}, @{tz='UTC'; off=0; mode='read'}, @{tz='PST8PDT'; off=-480; mode='read'})
foreach ($r in $runs) {
  if ($r.tz) { $env:TZ = $r.tz } else { Remove-Item Env:TZ -ErrorAction SilentlyContinue }
  flutter test test/data/database/database_time_zone_test.dart --dart-define=EXPECT_TZ_OFFSET_MIN=$($r.off) --dart-define=TZ_MODE=$($r.mode); "exit $LASTEXITCODE"
}
Remove-Item Env:TZ -ErrorAction SilentlyContinue
```
Expected: three `exit 0`.

**TC-007-13** (from `app/`)
```powershell
Get-ChildItem lib\features, lib\domain -Recurse -Filter *.dart | Select-String -Pattern 'package:drift','package:sqlite3','data/database/'
```
Expected: no output.

**TC-007-14** step 2 (from `app/`; exact command per plan)
```powershell
dart run drift_dev schema dump lib/data/database/app_database.dart $env:TEMP\tc007_v1.json
Compare-Object (Get-Content $env:TEMP\tc007_v1.json) (Get-Content drift_schemas\drift_schema_v1.json)
```
Expected: no output from `Compare-Object`.

**TC-007-17** (from root; debug build only, `run-as` needs a debuggable app; path per TC-007-17 step 1)
```powershell
adb shell am force-stop com.dailybudget.app
adb shell run-as com.dailybudget.app cp <db path> <db path>.good
adb shell "run-as com.dailybudget.app sh -c 'head -c 4096 /dev/urandom > <db path>'"
adb shell am start -n com.dailybudget.app/.MainActivity
```
Restore: `adb shell run-as com.dailybudget.app cp <db path>.good <db path>`.

**TC-007-19** (from `app/`)
```powershell
flutter build apk --debug; flutter build apk --release
$bt = Get-ChildItem "$env:ANDROID_HOME\build-tools" | Sort-Object Name | Select-Object -Last 1
foreach ($a in 'debug','release') {
  & "$($bt.FullName)\aapt2.exe" dump xmltree build\app\outputs\flutter-apk\app-$a.apk --file AndroidManifest.xml | Select-String 'allowBackup|dataExtractionRules|fullBackupContent'
}
Get-ChildItem android\app\src\main\res\xml | ForEach-Object { $_.Name; Get-Content $_.FullName }
```
Expected: `allowBackup` = false (`0x0`), both rule attributes present in both builds; the XML excludes all domains from `cloud-backup` and includes `database` and `sharedpref` in `device-transfer` (D-045).

**TC-007-21** (from `app/`)
```powershell
Get-ChildItem lib\data, lib\features -Recurse -Filter *.dart | Select-String -Pattern '\b(log|_log|logger)\.\w+\(.*\$' 
```
Expected: every hit is reviewed; none interpolates an amount, note or date.

**TC-007-22** (from `app/`)
```powershell
Select-String -Path pubspec.yaml -Pattern 'sqlcipher|sqlite3_flutter_libs|sqflite_sqlcipher|flutter_secure_storage|\bencrypt\b|pointycastle|sqlite3mc|source:\s*(sqlite3mc|sqlcipher)'
adb shell run-as com.dailybudget.app find . -name "*.sqlite*" -o -name "*.db*"
adb shell ls /sdcard/Android/data/com.dailybudget.app
adb shell ls /data/user/0/com.dailybudget.app
Select-String -Path ..\docs\DECISIONS.md -Pattern '^\| D-041 '
```
Expected: line 1 no output; line 2 lists the database inside the private folder only; line 3 no database (folder may not exist); line 4 `Permission denied`; line 5 one row.

**TC-007-23** (from `app/`)
```powershell
flutter clean; flutter build apk --debug; "exit $LASTEXITCODE"
Select-String -Path android\app\build.gradle* -Pattern 'ndkVersion'
Select-String -Path pubspec.yaml -Pattern 'sqlite3_flutter_libs|sqlcipher_flutter_libs'
Select-String -Path pubspec.lock -Pattern '^\s{2}(sqlite3_flutter_libs|sqlcipher_flutter_libs):' -Context 0,5
$bt = Get-ChildItem "$env:ANDROID_HOME\build-tools" | Sort-Object Name | Select-Object -Last 1
& "$($bt.FullName)\zipalign.exe" -c -P 16 -v 4 build\app\outputs\flutter-apk\app-debug.apk | Select-Object -Last 1
```
Expected: `exit 0`; `ndkVersion = flutter.ndkVersion`; no output for `pubspec.yaml`; lock entries (if any) show `version: "0.6.0+eol"` / `"0.7.0+eol"` or a later `+eol`; `Verification successful`.

## 2. Edge cases
Same columns.

| ID | AC | Scenario | Test data | Steps | Expected | Type | Automated test | Regression |
|---|---|---|---|---|---|---|---|---|
| TC-007-29 | AC-1, AC-2 | Long notes with emoji and Hindi **[MEM]** | Notes: 100 × `a`; 100 characters mixing Hindi and emoji (`चाय ☕ ` repeated, counted as F-009 counts characters — grapheme clusters per plan); a ZWJ emoji `👨‍👩‍👧`; empty note → stored as null/empty per plan | Write, read back | Byte-identical strings; length unchanged; empty note reads back as "no note" | Auto-unit | `TC-007-29 long notes with hindi and emoji round trip exactly` (`transactions_repository_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/repositories/transactions_repository_test.dart`. | yes |
| TC-007-30 | AC-1 | Two identical spends are both stored **[MEM]** | 9 Nov 25,000 "Tea" twice | Add both | 2 rows with different IDs; list shows both | Auto-unit | `TC-007-30 identical manual spends are both kept` (`transactions_repository_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/repositories/transactions_repository_test.dart`. | yes |
| TC-007-31 | AC-5 | Delete is a real delete **[MEM]** | Seed T5 | Delete the 8 Nov spend; raw `SELECT COUNT(*)` | Row gone (count 4) — or, if the plan adds a soft-delete column, the row is flagged and never returned by any repository read. Plan decides; test follows | Auto-unit | `TC-007-31 deleting a spend removes it from every read` (`transactions_repository_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/repositories/transactions_repository_test.dart`. | yes |
| TC-007-32 | AC-10 | Disk full / write fails: existing data intact **[MEM]** | Seed E2 + T5; then a forced `SQLITE_FULL` on the next write | Add a spend | Failure reported; the 5 old transactions and the month unchanged (Row snapshot + transaction list equal) | Auto-unit | `TC-007-32 failed write leaves stored data intact` (`transactions_repository_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/repositories/transactions_repository_test.dart`. | yes |
| TC-007-33 | AC-4 | App killed mid-save **[EMU]** | Debug build; F-008 with 10 fixed costs | Tap **Start my month** and immediately `adb shell am kill com.dailybudget.app` / force-stop (repeat 10 times with different delays, 0–300 ms; a test-only delay hook in the debug build makes it repeatable if the plan provides one) | After each reopen: either the full month with all 10 items, or no month at all. Never a month with fewer items | Manual | — | yes |
| TC-007-34 | §4 two stores | Preferences and database are independent **[FAKE]** | (a) FakeStore `readFails` + fake money repos `ok`. (b) FakeStore seeded Dim + money repos `openFails` | Pump the app | (a) Money data shows normally; theme Auto. (b) Storage error screen in **Dim**; tour/hint flags still respected | Auto-widget | `TC-007-34 preferences and money storage fail independently` (`test/features/storage_error/storage_error_screen_test.dart`) **Files, Step 8 (2026-11-13, passing):** `features/storage_error/storage_error_screen_test.dart`. | yes |
| TC-007-35 | AC-4 | Foreign keys are enforced **[MEM]** | Insert a fixed cost for period ID 9999; insert a move for a month that doesn't exist | Raw insert | `PRAGMA foreign_keys` = 1 after open (look-ahead #9); both inserts fail | Auto-unit | `TC-007-35 foreign keys are on and enforced` (`schema_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/database/schema_test.dart`. | yes |
| TC-007-36 | §4 clear data | Clearing app data = fresh install **[EMU]** | Month + spends saved; theme Dim | `adb shell pm clear com.dailybudget.app`; open the app | Tour slide 1 (F-005); after onboarding Home shows `Set up your month`; theme Auto; no crash | Manual | — | yes |
| TC-007-37 | AC-3 | Time-zone change on the device **[EMU]** | Spend saved 9 Nov 2026 (emulator date set to 9 Nov 2026, IST) | `adb shell cmd alarm set-timezone America/Los_Angeles` (on the device IANA names work), reopen the app; then `Asia/Kolkata` again | The spend stays under `Mon, 9 Nov` (or `Today`/`Yesterday` as the date dictates); amount unchanged. Restore zone and automatic date afterwards (`adb shell settings put global auto_time 1`) | Manual | — | yes |
| TC-007-38 | AC-7 | Generated code is current (if committed, look-ahead #11) | `lib/data/database/*.g.dart` | `dart run build_runner build --delete-conflicting-outputs`, then `git diff --exit-code -- lib` | Exit 0 (no change). N/A if the plan does not commit generated files | Manual (command) | — | yes |
| TC-007-39 | AC-5 | Ordering within a day uses created time **[MEM]** | Two 9 Nov spends created 10:00 and 12:00; edit the 10:00 one at 13:00 | Read the list | Order stays 12:00, then 10:00 (edit does not move it to the top) — the spec says "created and last-edited time for ordering"; plan confirms which one; see §2.3 note 2 | Auto-unit | `TC-007-39 spends within a day keep created time order` (`transactions_repository_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/repositories/transactions_repository_test.dart`. | yes |
| TC-007-40 | §2.6 read fails | Read failure shows the load error **[FAKE]** | Fake transactions repo `readFails` (stream emits an error) on Transactions; months repo `readFails` on Home | Open each tab; then switch the fake to `ok`, tap Try again | `Couldn't load your data` + `Tap Try again. Nothing has been lost.` + **Try again**; no crash; after Try again the data shows | Auto-widget | `TC-007-40 read failure shows load error with try again` (`test/features/storage_error/storage_error_screen_test.dart`) **Files, Step 8 (2026-11-13, passing):** `core/providers/database_providers_test.dart`. | yes |
| TC-007-41 | AC-8 | Older-app-over-newer on the device **[EMU]** | Hard to stage with real APKs; use the debug `run-as` copy of `v99_newer.sqlite` over the app's file | Start the app; then restore the original | Storage error screen; the pushed file's SHA-256 (`run-as … sha256sum`) unchanged after start and after Try again | Manual | — | no |
| TC-007-42 | AC-2 | Negative and boundary values are refused by the repository **[MEM]** | Transaction amount 0 and −1; fixed cost −1; salary 0 | Write via repositories | Rejected with the repository's validation failure (or by a `CHECK` constraint — plan decides); nothing stored. ₹0 fixed cost **is** allowed | Auto-unit | `TC-007-42 repositories refuse non positive spend amounts` (`transactions_repository_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/database/schema_test.dart`, `data/repositories/months_repository_test.dart`, `data/repositories/transactions_repository_test.dart`. | yes |
| TC-007-43 | AC-16 | Same-day changes add rows with their time **[MEM]** | Seed E2; rent → 13,00,000 at 10:00 and → 11,00,000 at 18:00 on 20 Nov | Row snapshot | 3 period rows; the two 20 Nov rows have distinct change times in order; the latest is returned as effective | Auto-unit | `TC-007-43 same day changes are stored as separate timed periods` (`period_history_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/repositories/period_history_test.dart`. | yes |
| TC-007-44 | AC-14 | Many rows on the host (sanity, not proof) **[FILE]** | 5,000 transactions | Insert in one batch; reopen; read the month | Completes; read returns 5,000 rows in date order; time printed for information (look-ahead #16: ~40 ms per 500) | Auto-unit | `TC-007-44 five thousand spends insert and read back in order` (`transactions_repository_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/repositories/transactions_repository_test.dart`. | no |
| TC-007-46 | AC-18 | Cover changes are stored with the edit and never come back **[MEM]** | F-006 W2 data (covers 6 Nov and 7 Nov, 17,000 each, made 8/9 Nov); today 10 Nov | 1. Through the transactions repository, edit 5 Nov 50,000 → 83,000, then 8 Nov 20,000 → 83,000. 2. Raw `SELECT amount_paise FROM savings_moves`. 3. Edit 9 Nov 83,000 → 10,000 (pot grows by 73,000). 4. Fresh W1 + cover 6 Nov 17,000: edit 6 Nov 1,00,000 → 90,000. 5. Repeat 1 with a forced failure on the cover update | 1. The second edit returns reductions [(7 Nov, 17,000, 0), (6 Nov, 17,000, 0)]. 2. Both rows 0 (rows kept). 3. Both still 0; pot 73,000. 4. Stored 6 Nov cover 7,000, no reduction returned. 5. Spend and covers both unchanged (one transaction) | Auto-unit | `TC-007-46 cover changes are saved with the edit and stay` (`savings_repository_test.dart`) **Files, Step 8 (2026-11-13, passing):** `core/providers/database_providers_test.dart`, `data/repositories/savings_repository_test.dart`. | yes |
| TC-007-47 | AC-19 | Money in round trip (D-047) **[FILE]** | Seed E2; money in 50,000 on 12 Nov; spend 30,000 on 12 Nov | Write; Restart (sim, DB); read; raw insert with direction `refund` | Direction, amount and date identical after reopen; engine sees 12 Nov net −20,000; the raw insert with an unknown direction fails (CHECK) | Auto-unit | `TC-007-47 money in rows keep their direction` (`transactions_repository_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/database/schema_test.dart`, `data/repositories/transactions_repository_test.dart`. | yes |
| TC-007-48 | AC-11 | Device-to-device transfer includes the data **[EMU]** | Debug build on API 37 with a month and spends | Use Android's documented device-transfer test (`adb shell bmgr` with the D2D test transport, per the source the Developer records in plan F-007 §11 for T-210); clear data; restore | After restore the month and spends are back; a plain `bmgr backupnow` to the cloud transport still reports the app as not eligible. If the emulator has no D2D test transport: record **Blocked** with the exact output; TC-007-19 remains the proof | Manual | — | yes |
| TC-007-45 | AC-11 | Database file path is not in logs or error text | Open failure fixture | Capture logs and the error screen text | Neither contains the file path or the SQLite error message text (STANDARDS §8) | Auto-widget | `TC-007-45 storage errors do not show file paths or sqlite messages` (`test/features/storage_error/storage_error_screen_test.dart`) **Files, Step 8 (2026-11-13, passing):** `data/database/open_failure_test.dart`, `features/storage_error/storage_error_screen_test.dart`. | yes |
| TC-007-49 | AC-4 (Phase 3, D-078) | `SavingsRepository.cover()` returns the stored id **[MEM]** **[FAKE]** | Seed E2 (A13 data, pot 2,00,000); covers of 30,000 on 11 Nov and 10,000 on 11 Nov; then a refused cover (amount over the pot) | Call `cover(...)` three times; read the returned `({decision, coverId})` and raw `SELECT id, amount_paise FROM savings_moves` | The two accepted covers return `coverId` equal to the stored row ids (distinct integers, the second larger than the first); the refused cover returns its refusal `decision` and `coverId` null and stores nothing; a cover cut to 0 by D-040 returns the id of the 0 row (rows are kept, TC-007-46) or null as the plan's `coverId` rule says (id only when a row is stored). The existing `decision` values are exactly as before (TC-006-13, -44, -45 unchanged). Drift and fake return the same | Auto-unit | `TC-007-49 cover returns the id of the stored move` (`test/data/repositories/savings_repository_test.dart`) | yes |
| TC-007-50 | AC-4 (Phase 3, D-078) | `removeCovers(monthId, ids)` is one transaction **[MEM]** | Real Drift in memory; 11 Nov with two moves (10,000 and 20,000), 6 Nov with one (17,000); the ids from TC-007-49 | (a) `removeCovers(month, {both 11 Nov ids})`. (b) Again with a forced failure after the first delete. (c) `removeCovers(month, {id of another month's move})` | (a) Only the two 11 Nov rows are deleted, 6 Nov stays; the recompute shows 11 Nov overspent 30,000 again and the pot up by 30,000. (b) Throws `StorageException(write)` and **both** rows are still there (all or nothing). (c) Nothing is deleted: a move of another month is never touched. Same case as F-012 TC-012-43, which owns the screen side | Auto-unit | `TC-007-50 remove covers is atomic and limited to the month` (`test/data/repositories/savings_repository_test.dart`; the same body as TC-012-43) | yes |
| TC-007-51 | AC-4, AC-5 (Phase 3, D-078) | `removeCovers` ignores unknown ids and is idempotent (Undo after Remove) **[MEM]** **[FAKE]** | One stored cover with id N | `removeCovers(month, {N})` twice; `removeCovers(month, {9999})`; `removeCovers(month, {})` | The first call deletes the row; the other calls throw nothing and change nothing (a late Undo after a Remove is harmless); an empty set does nothing and emits nothing. Fake and Drift agree | Auto-unit | `TC-007-51 remove covers ignores unknown ids` (`test/data/repositories/savings_repository_test.dart`) | yes |
| TC-007-52 | AC-5 (Phase 3, D-078) | `removeCovers` is a live update **[MEM]** | Listener on "moves of this month" (TC-007-12 pattern) with two covers stored | `removeCovers` of one id; then of the other; `await pumpEventQueue()` after each | The listener emits [two] → [one] → [] in order, no re-subscribe; the day, month and Home listeners recompute (pot grows, day overspent again) without a reload. TC-007-12 itself is unchanged and re-run | Auto-unit | `TC-007-52 savings listeners update after remove covers` (`test/data/repositories/savings_repository_test.dart`) | yes |
| TC-007-53 | AC-5 (Phase 3, D-078) | `MonthRepository.watchMonthIndex()`: cross-reference **[MEM]** **[FAKE]** | See F-011 TC-011-59 to -66 (the cases live there: newest first, ids and first budgeted days, gaps of missed months, empty table, live add, fake parity, read failure as an error, `MonthBrowser`) | Run F-011 TC-011-59 to -64 (`test/data/repositories/month_index_test.dart`); re-run TC-007-11 and -12 | Those cases pass; the index reads `budget_months` only; TC-007-11 and -12 and the repository suites (Drift and fake parity) still pass unchanged. No schema change: the schema snapshot test TC-007-14 stays green (`removeCovers` and `watchMonthIndex` add no table, column or trigger) | Auto-unit | Cross-reference only; no separate test body | yes |

Not applicable to F-007: permission denied (no runtime permission is used), SMS formats and duplicates (Phase 4), all 4 themes and largest font (only the storage error screen is UI; it is swept in TC-008-24/TC-009-20 as a P2 screen — see §2.3 note 4), salary-day and month-length arithmetic (F-006).

### 2.1 Impact on existing features
Aligned with plan F-007 §8, plus the Tester's additions (marked *T*).
- **F-001 (plan §8):** `check.ps1` gains steps (Drift codegen up to date, `tool/domain_coverage.ps1`, `tool/tz_matrix.ps1`): the Tester updates **TC-001-44** (step list) and `tests/REGRESSION.md` **check 1** in that task.
- **F-001:** TC-001-17 (main manifest still has no `uses-permission`; F-007 adds backup attributes, not permissions); TC-001-24/-25 (new packages `drift`, `drift_flutter`, `drift_dev`, `build_runner`, maybe `intl`/`clock` each need a DECISIONS row with the exact locked version; D-018 updated to drift 2.35.4 / drift_dev 2.35.3); TC-001-34 (plugin packages present: Developer Mode not needed, D-029); TC-001-06 (domain stays free of `drift`, also TC-007-13); TC-001-12 (test names).
- **F-002 (plan §8):** `app.dart` gains the `DatabaseGate`; **TC-002-10** (first frame already in the saved theme, F-002 AC-7) must stay green — the gate must not show a frame in another theme. *T:* TC-002-14/-36 (preferences failures) must keep passing with the database present; TC-007-34 checks the stores are independent. The storage error screen joins the screen sweeps (TC-002-03/-22/-23/-24/-38/-39/-40) once it exists (§2.3 note 4).
- **F-003 (plan §8):** the shell now sits below the gate; `pumpBudgetApp` (`test/helpers/pump_app.dart`) gets an optional database-provider override (default: fakes), so existing tests need no change. *T:* startup (`main.dart`/`app.dart`) gains the database open and the storage error screen: TC-003-01 (first screen), TC-003-08/-09 (always opens on Home), TC-003-13 (app title) are re-run.
- **F-004/F-005 (plan §8):** no change; the gate must not block the tour. *T:* TC-005-01 (fresh install opens on slide 1) re-run, because startup now also opens the database.
- `tests/REGRESSION.md` check 5 (dependencies ↔ DECISIONS) gains the Drift rows; check 3 (no permissions) unchanged.

### 2.2 Regression
All F-001 to F-005 Regression-yes cases and `tests/REGRESSION.md`. New for REGRESSION.md after Step 8: TC-007-02 (restart keeps data), TC-007-19 (backup rules), TC-007-23 (native build).

### 2.3 Notes for the Project Manager / Product Manager
1. **AC-5 "within the same test pump/turn"**: for a repository unit test the closest objective form is "after `pumpEventQueue()` with no re-subscribe" (TC-007-11). In widget tests the repositories are fakes (look-ahead #5), so the Drift stream itself is only proven at unit level.
2. **Ordering within a day (TC-007-39):** answered (D-048): `created_at` descending, `id` as tie-break; an edit never moves a spend. TC-007-39 stands.
3. **AC-14 speed** is only meaningful on the emulator (TC-007-24); the host test (TC-007-44) is informational. Emulator timings vary; the Tester reports the worst of 5 runs.
4. **The storage error screen** is not listed in any theme/large-text AC of F-007. The Tester adds it to the Phase 2 screen sweep (TC-008-24) so it is checked in all four themes at text scale 2.0.
5. **AC-4 "app killed mid-write" (TC-007-33)** can't be timed exactly by hand. A debug-only delay hook in the save path (plan choice) would make it repeatable; without one it is best effort.
6. **AC-8 on a real device (TC-007-41)** needs a debuggable build and `run-as`; with a release build it is not testable, so the fixture test (TC-007-15) is the proof.
7. **Derived "what changed" and persisted reductions (plan F-007 §9 Q2/Q3):** both accepted (D-048). "What changed" is checked through the engine (TC-006-25); stored reductions by TC-007-46.

### 2.4 AC → test case map
| AC | Test cases |
|---|---|
| AC-1 | TC-007-01, -02, -03, -29, -30 |
| AC-2 | TC-007-04, -05, -29, -42 |
| AC-3 | TC-007-06, -07, -08, -37 |
| AC-4 | TC-007-09, -10, -33, -35, -49, -50, -51 |
| AC-5 | TC-007-11, -12, -31, -39, -51, -52, -53 |
| AC-6 | TC-007-13 |
| AC-7 | TC-007-14, -38 |
| AC-8 | TC-007-15, -41 |
| AC-9 | TC-007-16, -17 |
| AC-10 | TC-007-18, -32 (and TC-008-17, TC-009-15) |
| AC-11 | TC-007-19, -20, -21, -45, -48 |
| AC-12 | TC-007-22 |
| AC-13 | TC-007-03, -23 |
| AC-14 | TC-007-24, -44 |
| AC-15 | TC-007-25 |
| AC-16 | TC-007-26, -27, -43 |
| AC-17 | TC-007-28 |
| AC-18 | TC-007-46 |
| AC-19 | TC-007-47 |
| §2.6 read failure, §4 two stores, clear data | TC-007-40, -34, -36 |


## 3. Regression cases from bugs
Every bug found in this feature adds a case here. It is never deleted.

| ID | Bug | Scenario | Expected | Automated test |
|---|---|---|---|---|
| — | No bugs found in F-007 Step 8 (2026-11-13) | | | |

## 4. Test runs *(Tester)*
| Run | Date | Build / task | Passed | Failed | Notes |
|---|---|---|---|---|---|
| R1 | 2026-11-13 | T-206 … T-211 after PM Gate 3 (approved, no Must fix); Flutter 3.47.9 / Dart 3.13.7; emulator-5554 (Android 17, API 37, debug build) | 46 Pass of 48 | 0 | 1 Partial (TC-007-33), 1 Blocked (TC-007-48). 37 cases by named automated test (35 on the host, 2 on the device), 11 manual or command. `tool/check.ps1` ALL CHECKS PASSED (591 tests); `flutter test integration_test -d emulator-5554`: 5 of 5 pass; `domain_coverage.ps1` 100% (17 files); `tz_matrix.ps1` PASSED, hash `B30996982B3C37EB…D59E4`. No bug |
| R2 | 2026-11-16 | Regression run R5 (T-243, T-249, T-250 in the build); emulator-5554 (debug build) | 47 Pass of 48 | 0 | 1 Blocked (TC-007-48). TC-007-33 now Pass (valid 10-item draft, 7 timed kills). `tool/check.ps1` ALL CHECKS PASSED (606 tests); integration 8 of 8 (TC-007-03, -24 re-run); `domain_coverage.ps1` 100%; `tz_matrix.ps1` PASSED. Device checks 18, 19, 20 of `tests/REGRESSION.md` re-run: pass. No bug |

### R2 results (2026-11-16)
| ID | Result | Evidence (R2) |
|---|---|---|
| TC-007-33 | **Pass** (best effort) | Debug build, emulator date 5 Nov 2026. A **valid** draft this time: salary day 5th, salary 90,000, 10 fixed-cost rows (Rent, EMI, Subscriptions with empty amounts; Food 1000, Bus 1100, Phone 1200, Gym 1300, Net 1400, Water 1500, Gas 1600; total ₹9,100; Start my month was enabled). In one `adb shell`: `input tap` on **Start my month**, `sleep <delay>`, `am force-stop`; then the database and its `-wal` pulled with `run-as` and the rows counted. Delays 0, 0.10, 0.14 s: 0 months, 0 periods, 0 fixed costs (no month). Delays 0.15, 0.17, 0.20, 0.30 s: 1 month, 1 period, **10 fixed costs** (full). Seven kills bracket the commit moment; no month with fewer than 10 items appeared (`tc-007-33-r5-kill-timing.txt`). Together with TC-007-09/-10 (a trigger aborts the 3rd insert, 0 rows remain) the guarantee is shown both ways. Best effort because adb timing is only about ±50 ms |
| TC-007-02, -17, -19, -20, -22, -36, -41 | Pass (re-confirmed by regression checks 18 – 20) | Force-stop and `adb reboot` keep the month and spends (`tc-007-02-r5-after-reboot.png`); error screen for a random-bytes file and for `user_version` 99, file untouched by Try again, restore opens (`tc-007-17-r5-error-screen.png`, `tc-007-41-r5-newer-db.png`, `regression-r5-check20.txt`); debug and release manifests `allowBackup=false` + both rule attributes, `bmgr backupnow` → `Backup is not allowed`, only `app_flutter/budget.sqlite`, private folder `Permission denied` (`regression-r5-apk-checks.txt`, `regression-r5-device-checks.txt`) |

### R1 detailed results (2026-11-13)
Evidence folder: `docs/reviews/emulator-phase-2/`.

| Command / run | Result |
|---|---|
| `.\tool\check.ps1` (`check-run1.txt`) | PASS every step: pub get, **drift codegen up to date** (`wrote 0 outputs`, `Checked 2 generated file(s)`), format (0 changed), `flutter analyze`, `dart analyze --fatal-infos`, test names, `flutter test` **591 tests, All tests passed**, domain coverage 100%, time-zone matrix; exit 0 |
| `flutter test integration_test -d emulator-5554` (`integration-tests-run1.log`) | 5 of 5 pass: TC-005-16, TC-007-03, TC-007-24, TC-002-11, TC-009-19. TC-007-24 worst of 5 runs: **list 32 ms, single write 36 ms** (limits 1,000 / 500 ms). TC-009-19 (on-screen list of 500 spends after a restart): 450 / 108 / 105 / 165 / 112 ms, **worst 450 ms** (limit 1,000) |
| §1.1 TC-007-07 command | one hit, the comment in `tables.dart:10` ("There is no `dateTime()` column"); no real `dateTime()` column |
| §1.1 TC-007-13 command | no output |
| §1.1 TC-007-21 command | no output (no log call interpolates a value) |
| §1.1 TC-007-22 command | line 1 (`pubspec.yaml`): no output; `run-as … find`: only `./app_flutter/budget.sqlite`; `ls /sdcard/Android/data/com.dailybudget.app`: *No such file or directory*; `ls /data/user/0/com.dailybudget.app` without `run-as`: *Permission denied*; D-041 row present (`tc-007-20-22-device-checks.txt`) |
| §1.1 TC-007-19 command (`tc-007-19-23-apk-checks.txt`) | **debug and release** APK manifests: `allowBackup=false`, `dataExtractionRules` and `fullBackupContent` present; `data_extraction_rules.xml`: `<cloud-backup>` excludes root, file, database, sharedpref, external and the four `device_*` domains; `<device-transfer>` includes `database` and `sharedpref`, excludes nothing; `backup_rules.xml` (API 30 and lower) excludes all five domains |
| §1.1 TC-007-23 command | `flutter clean` + `flutter build apk --debug`: exit 0 (`tc-007-23-clean-build.log`); `ndkVersion = flutter.ndkVersion`; `pubspec.yaml` has neither stub; `pubspec.lock`: `sqlite3_flutter_libs` `0.6.0+eol` and `sqlcipher_flutter_libs` `0.7.0+eol`, both `dependency: transitive`; `sqlite3` 3.9.1 is `direct main` (accepted at Gate 3); `zipalign -c -P 16 -v 4` gives `Verification successful` for debug and release; no `hooks`/`user_defines` in `pubspec.yaml` |

| ID | Result | Evidence |
|---|---|---|
| TC-007-01, -03 … -13, -15, -16, -18, -19, -21, -22, -24, -26 … -32, -34, -35, -39, -40, -42 … -47 | Pass | Named tests in the files listed in each row's "Automated test" cell, inside the green `flutter test` of `check.ps1`; -03 and -24 also on the device (integration run above). -19 and -22 additionally by the manual commands above; -07, -13, -21 by their commands |
| TC-007-14 (incl. step 2), TC-007-38 | Pass | `migration_test.dart` and `open_failure_test.dart`; the `drift codegen is up to date` step of `check.ps1` regenerates, hashes every `*.g.dart` and schema snapshot before and after (`wrote 0 outputs`) and dumps the schema against the committed snapshot |
| TC-007-02 | Pass | Month (salary only, then E2) and a ₹250 "Lunch" spend saved on the emulator; `am force-stop` + restart, then `adb reboot` + restart: Home `This month, 5 November to 4 December` and Transactions `₹250, Lunch, Thursday 5 November`, Today line unchanged both times (`tc-007-02-after-force-stop.png`, `tc-007-02-after-reboot.png`). **Deviation:** the emulator date was set to 5 Nov 2026 (the case's 9 Nov needs E2 saved on 5 Nov first), so the spend is dated 5 Nov. The stored 25,000 paise is proved by TC-007-03 |
| TC-007-17 | Pass | Debug build, `run-as`: random 4,096 bytes over `app_flutter/budget.sqlite`. Start: screen `We couldn't open your data. Your budget data is still on this phone. Try again, and if this keeps happening, restart your phone.` + button `Try again`. **Try again** tapped: still the error screen, file still 4,096 bytes with the same SHA-256. Restore the good copy, **Try again**: Home `This month … ₹830 a day`. No `FATAL EXCEPTION` in logcat (`tc-007-17-error-screen.png`, `tc-007-17-logcat.txt`) |
| TC-007-20 | Pass | `dumpsys package`: `flags=[ DEBUGGABLE HAS_CODE ALLOW_CLEAR_USER_DATA ]` (no `ALLOW_BACKUP`); `bmgr backupnow com.dailybudget.app` → `Backup finished with result: Backup is not allowed`. Note: this AVD's backup manager is globally disabled (`bmgr enabled`), so the proof is the package flags plus the "not allowed" result |
| TC-007-23 | Pass | See the command row above (a `flutter clean` build) |
| TC-007-25 | Pass | `check.ps1` ALL CHECKS PASSED, exit 0; the F-001 … F-005 Regression-yes cases: `tests/REGRESSION.md` run R4 (automated all green; device checks run) |
| TC-007-33 (R1, superseded by R2) | Partial | Not repeatable by hand; no delay hook was built (Gate 3 decision). Several timed kills (`input tap` on **Start my month**, then `am force-stop` after 0 – 2 s) were run, but the draft I could drive over `adb` was not valid (a name or amount error stopped the save), so every attempt left 0 months, 0 periods, 0 fixed costs (rows counted by pulling the database). That proves "never a half month" only trivially. A valid 3-item save with no kill stored 1 month, 1 period, 3 fixed costs. The guarantee is proved by TC-007-09/-10 (a trigger aborts the 3rd cost insert; 0 rows remain) and SQLite's journal. **Recorded as covered by TC-007-09/-10, as the Gate 3 note allows** |
| TC-007-36 | Pass | Theme Dim chosen (Settings showed `Dim`), month and spend saved; `pm clear`; start: tour slide 1 `Spend a little each day`, light theme (Auto), no database file until the app opens it; after the tour Home shows `Set up your month` (`tc-007-36-dim-before-clear.png`, `tc-007-36-after-clear.png`) |
| TC-007-37 | Pass | Clock set to 6 Nov 2026 02:00 IST (`cmd alarm set-time`), spend of 5 Nov: IST shows it under `Yesterday` with `₹250`. `cmd alarm set-timezone America/Los_Angeles` (12:30 PST, 5 Nov): after a restart the spend is under `Today`, `₹250` unchanged; back to `Asia/Kolkata`: `Yesterday` again. The spend's own date (`Thursday 5 November`) never changed (`tc-007-37-*.png`). Clock, zone and automatic time restored afterwards |
| TC-007-41 | Pass | `user_version` bytes of the good file changed to 99 with `dd` over `run-as`: error screen; SHA-256 `d12825…828f` unchanged after start and after Try again; no `-wal`/`-journal` file created; original restored, app opens (`tc-007-41-newer-db.png`) |
| TC-007-48 | **Blocked** | The AVD has no Android device-transfer **test** transport. `bmgr list transports`: `com.android.localtransport/.LocalTransport`, `com.google.android.gms/.backup.migrate.service.D2dTransport`, `com.google.android.gms/.backup.BackupTransportService` (selected), `com.google.android.apps.restore/.transport.BackupTransportService`; `bmgr enabled`: "Backup Manager currently disabled". The D2D transport is Google's real one and cannot be driven from `adb`. A plain `bmgr backupnow` still reports `Backup is not allowed` (the cloud half of the case passes). **TC-007-19 remains the proof** (D2D rules in the merged XML), as the case allows. Android 16 QPR2 `cross-platform-transfer` (Gate 3 N2) cannot be checked: the image is Android 17 |

## 5. Test report to Project Manager *(Gate 4)*
- **Verdict: Pass, with two open items for the PM.** 46 of 48 cases Pass; TC-007-33 Partial (covered by TC-007-09/-10, as the Gate 3 note allows); TC-007-48 Blocked (no device-transfer test transport on the AVD; TC-007-19 is the proof). No failure, no bug.
- **ACs covered: 19 / 19** (AC-1 … AC-19 by the map in 2.4). AC-11 (privacy): merged XML for debug and release, package flags, `bmgr`, private-folder listing and a clean `pubspec.yaml`. AC-13: clean debug build and 16 KB alignment. AC-14: 450 ms on-screen worst case and 32 / 36 ms at repository level on the emulator.
- **Bugs logged: none.**
- **Full regression:** `check.ps1` 591 tests green; integration 5 of 5; `domain_coverage.ps1` and `tz_matrix.ps1` green; device regression checks 9, 13, 15, 16 (no new permission dialog) and 17 run; see `tests/REGRESSION.md` run R4. The Phase 1 TalkBack cases stay Blocked-needs-human (D-066).
- **Notes for the PM**
  1. TC-007-02 was run with the spend dated 5 Nov (emulator date 5 Nov), not 9 Nov; the saved amount in paise is proved by TC-007-03.
  2. TC-007-33 cannot show a half-written month either way without a delay hook; accepted as covered (Gate 3).
  3. TC-007-48: the cloud half passes; the device-transfer half is proved only by the XML (TC-007-19). A real phone-to-phone transfer is for the Owner to try if wanted.
  4. Observation, Low, not logged as a bug: the "today" value does not refresh when the time zone changes **while the app stays in the foreground** (it does on resume and at midnight; the screen was stale until reopened in the TC-007-37 run). Changing the zone in system settings backgrounds the app, so the resume refresh covers the normal path.

### R2 addendum for the Project Manager (Tester, 2026-11-16)
- **TC-007-33 is now Pass** (best effort, see R2 results): 7 timed kills of a valid 10-item save gave only "no month" or "the full month with 10 items". 47 of 48 Pass, TC-007-48 Blocked (accepted at Gate 4). No failure, no bug. T-245 (Step 9 for F-007) is not blocked by anything in this file.

### PM Gate 4 verdict (2026-11-13)
- **Pass.** 19 / 19 ACs covered, 46 of 48 Pass, no bug. TC-007-33 Partial **accepted** as covered by TC-007-09/-10 (Gate 3 note, D-071). TC-007-48 Blocked **accepted**: the cloud half passes and the merged XML (TC-007-19) proves the device-transfer rules; a real phone-to-phone transfer is optional for the Owner. Low observation (time zone changed in the foreground) accepted, D-071.
- Next: Developer Step 9 (T-245), then Gate 5.
