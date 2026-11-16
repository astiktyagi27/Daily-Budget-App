# F-007: Local database

| | |
|---|---|
| **Phase** | 2 |
| **Status** | Plan approved (Gate 1, 2026-11-10). D-034, D-036, D-037, D-041, D-045, D-047, D-048 and the look-ahead findings (`docs/reviews/phase-2-lookahead.md` #6–#8) are applied |
| **Plan** | [`plans/F-007-local-database.md`](../../plans/F-007-local-database.md) |
| **Test cases** | [`tests/F-007-local-database.md`](../../tests/F-007-local-database.md) |
| **Tasks** | T-206 … T-211 (+ T-222) |

## 1. What it is *(Product Manager)*
The app's on-phone storage for money data: budget months, fixed costs, transactions and savings-pot moves, all amounts in integer paise. It uses Drift (SQLite, D-018). Screens never use it directly. They go through **repositories** in `app/lib/data/` and Riverpod providers (STANDARDS §3). It starts at **schema version 1** with a written migration strategy, so later phases (SMS transactions in Phase 4, categories) can add to it without losing anyone's data. Nothing leaves the phone: no cloud, no login and no Android cloud backup of this data (D-003). Theme, tour and hint flags stay in the Phase 1 preferences store (D-026). Only money data goes here.

**User stories:**
- As a **user**, I want my month setup and spends kept on my phone after I close the app or restart the phone so that I never re-enter them.
- As a **privacy-conscious user**, I want my money data to stay only on this phone so that nobody else can see it.
- As a **user**, I want a clear message if storage fails, never silently lost data, so that I know what happened.
- As the **team**, we want a versioned schema and repositories so that later phases can add tables and the UI never depends on SQL.

## 2. How it behaves *(Product Manager)*
1. **What is stored.** These are the requirements; the exact columns are the Developer's.

   | Record | Must hold |
   |---|---|
   | Budget month | Start date, end date, salary day, first budgeted day (D-034: today for a mid-month install), date confirmed |
   | Budget period (D-037) | Which month, start date, time of the change, the values in force (salary or "none", target or "none", or "money left now" for a mid-month first month, in paise), whether it was continued with a shortfall and the shortfall amount (D-036). "What changed from the previous period" is **derived** by the engine from two consecutive periods, not stored (D-048) |
   | Fixed-cost item | Which **period**, name, amount (paise), display order. Each period keeps its own copy of the items, so an edit never changes an earlier period |
   | Transaction | Calendar date (no time zone shift), amount (paise, always > 0), **direction** = spend or money in (D-047; Phase 2 screens only create spends, Phase 4 SMS credits use money in), note (optional), source = `manual` (SMS in Phase 4), category (optional / empty in Phase 2, see F-009), created time (orders entries within a day: newest created first; an edit does not move an entry) and last-edited time |
   | Savings-pot move | Which month, covered day, amount (paise), time of the move. When an edit takes a cover back (D-040) or lowers it to a day's new overspend, the stored amount is lowered **in the same save** as the edit and stays lowered (D-048) |
   | Daily budgets | Must be reproducible exactly for every past day: either stored per period, or recomputed from the stored periods by the engine (F-006 §2.7). The plan decides which. Past days' budgets must never change after a later edit (D-037) |

   **Period history is append-only (D-037):**
   - Every change to salary, target, fixed costs or money left adds a **new** period record. Existing period records and their fixed-cost items are **never updated or deleted**.
   - Same-day changes add another record with its time. The latest one applies from that day (F-006 AC-22).
   - Confirming a month creates its first period.
   - This history is what the Phase 3 month statement will read.

2. **Money and dates.**
   - Every amount is an integer number of paise (`INTEGER` column, Dart `int`). There are no `REAL`/`double` columns for money.
   - Transaction, month and period dates are stored as **calendar dates**: an `INTEGER` **day number** (e.g. days since 1970-01-01) through a Drift type converter, **not** a `DateTime` column.
     - The look-ahead (#7) reproduced the problem with `DateTime` columns: 9 Nov saved under IST read back as 8 Nov under UTC and PST8PDT.
     - With day numbers, changing the phone's time zone never moves a spend to another day.
     - Created/edited times (for ordering only) may stay timestamps.
3. **Repositories.** One per area: months (with fixed costs), transactions, savings. Each offers the reads and writes F-006, F-008 and F-009 need, and **live updates**: when data changes, screens watching it update without a manual refresh.
4. **All-or-nothing saves.** Confirming a month (the month plus all its fixed costs) is saved as one unit. A failure part-way leaves nothing half-saved. The same applies to an edit and to a cover.
5. **Schema version 1 and migrations.**
   - The first release creates schema v1.
   - The plan defines the migration strategy (e.g. Drift's step-by-step migrations with a committed schema snapshot per version and a migration test).
   - Every later version change must upgrade existing data without loss.
   - If the database on the phone is **newer** than the app (an older app installed over a newer one), the app shows the storage error and **does not delete or overwrite** the data.
6. **Failure handling.**
   - **Can't open the database** (corrupt file, disk full, newer version): a full-screen error in plain language with **Try again** (copy in section 5). The app does not crash, delete or recreate the database silently.
   - **A write fails:** the screen shows an error message, keeps what the user typed, and nothing is saved.
   - **A read fails:** the screen's error state shows with **Try again** (STANDARDS §7: every screen has an error state).
7. **Privacy.**
   - The database file lives in the app's private storage. No other app can read it.
   - It is **excluded from Android cloud backup** (Auto Backup to Google Drive), so nothing goes through the cloud (D-003, D-041).
   - It **is included in Android device-to-device transfer** (setting up a new phone from the old one, by cable or direct Wi-Fi), so the user keeps their history when changing phones (D-045). Theme, tour and hint preferences travel with it.
   - No logging of amounts, notes or dates (STANDARDS §5, D-019). Logs may say "transaction saved", never "₹250 Swiggy".
8. **Protection without extra encryption (D-041).**
   - The database is plain SQLite through Drift, with **no extra database encryption** in Phase 2.
   - It is protected by Android's private app storage plus the phone's own device encryption, and cloud backup is off (AC-11).
   - No encryption package is a direct dependency.
   - SQLite3MultipleCiphers can be added later in place if the Owner ever wants it (D-041).
9. **Native build check (carried forward).** Drift's native SQLite (`sqlite3` 3.x build hooks through `drift_flutter`, D-018) must build with the NDK in use, Flutter's default 28.2 (D-029). `drift_flutter` 0.3.1 brings in `sqlite3_flutter_libs 0.6.0+eol` and `sqlcipher_flutter_libs 0.7.0+eol`. Both are empty stubs that "no longer do anything" (look-ahead #6). They may appear in `pubspec.lock` as transitive entries, but neither may be a direct dependency, and no older non-stub version may be resolved.
10. **Scheduling (phase overview, D-033).** F-007's own files under `data/database/` can be planned and test-cased now. Adding Drift to `pubspec.yaml`/`pubspec.lock` and touching startup or manifest files waits until Phase 1 is Owner-approved, or until the Project Manager confirms those files are no longer open.

**Example:** the Owner confirms a month (salary ₹40,000, rent ₹10,000, EMI ₹5,000, subscription ₹100) and adds a ₹250 spend dated 9 Nov. They force-stop the app and restart the emulator. On reopening, the month, all three fixed costs and the ₹250 spend on 9 Nov are exactly as entered: 25,000 paise, not 24,999.

## 3. Acceptance criteria *(Product Manager)*
| ID | Given / When / Then |
|---|---|
| AC-1 | **Data survives restart.** Given a confirmed month with 3 fixed costs, 5 transactions and 1 savings move, when the app is force-stopped and reopened (and, on the emulator, after a full emulator restart), then all of them are read back with identical values (amounts in paise, dates, notes, order). |
| AC-2 | **Money is integer paise.** Given the schema, when the Tester inspects it, then every money column is an integer type, no money column is `REAL`/floating point, and a round-trip test of 1 paisa, ₹1,333.33 (1,33,333), ₹24,900 and ₹10 crore (10,00,00,00,000) returns exactly the same integers. |
| AC-3 | **Dates are calendar dates (integer day numbers).** Given the schema, when the Tester inspects it, then every calendar-date column (transaction date, month start/end, first budgeted day, period start) is an `INTEGER` day number written and read through a type converter, not a `DateTime` column; the converter has its own pure unit tests (9 Nov 2026, 29 Feb 2028, 31 Dec → 1 Jan round-trip to the same date). And given a transaction saved for 9 Nov 2026, when the F-007 date test file is run in three separate test processes with POSIX time-zone settings `TZ=UTC`, `TZ=PST8PDT` and the default (IST) (look-ahead #8: IANA names such as `America/Los_Angeles` are ignored on Windows), then each run reads back 9 Nov 2026. |
| AC-4 | **All-or-nothing month save.** Given a month with 4 fixed costs is being confirmed, when a failure is forced on the 3rd fixed cost (test hook), then no month and no fixed costs are stored, and the repository reports a failure. |
| AC-5 | **Live updates.** Given a screen-level listener on this month's transactions, when a transaction is added, edited or deleted through the repository, then the listener receives the new list within the same test pump/turn without a manual reload. |
| AC-6 | **Repositories only.** Given `app/lib/features/` and `app/lib/domain/`, when the architecture test runs, then no file there imports Drift, `sqlite3` or anything under `data/database/`; screens get data only through repositories/providers. |
| AC-7 | **Schema v1 and migration strategy.** Given the codebase, when the Tester inspects it, then the database reports schema version 1, a schema snapshot for v1 is committed, and a migration test exists that opens a v1 database file containing sample data with the current code and checks the data is intact. |
| AC-8 | **Newer database is not destroyed.** Given a database file whose schema version is higher than the app knows (test fixture), when the app opens it, then the storage error screen is shown, no exception escapes, and the file's bytes are unchanged afterwards. |
| AC-9 | **Can't open → error screen.** Given the database cannot be opened (corrupt fixture file, or an open failure forced by a test hook), when the app starts, then the error screen with the section 5 copy and **Try again** is shown, the app does not crash, and the corrupt file is not deleted or replaced. When the failure is removed and **Try again** is tapped, the app continues normally. |
| AC-10 | **Write failure keeps input.** Given a write failure is forced while saving a spend (F-009) or confirming a month (F-008), when the user taps Save/Confirm, then the section 5 save-error message is shown, the user's input stays on screen, and nothing is stored. |
| AC-11 | **No cloud backup, device transfer allowed, no data in logs.** Given the built app, when the Tester inspects the merged manifest and backup rules, then the database (and every other domain) is excluded from Android cloud backup (`allowBackup="false"` plus `dataExtractionRules` whose `<cloud-backup>` excludes everything, and `fullBackupContent` for Android 11 and older), and the `<device-transfer>` section **includes** the database and preferences (D-045); and when the Tester runs every F-007/F-008/F-009 test with logging captured, then no log line contains an amount, a note text or a transaction date. |
| AC-12 | **No extra encryption, private storage (D-041).** Given the built app, when the Tester inspects `pubspec.yaml`, `pubspec.lock` and the device, then no encryption package (SQLCipher, SQLite3MultipleCiphers or similar) is a direct dependency; the database file lives only in the app's private data folder (not on shared/external storage, not readable by another app); and `DECISIONS.md` D-041 records the decision. Together with AC-11 (no cloud backup), this is the Phase 2 data protection. |
| AC-13 | **Native build.** Given Drift is added, when the Tester runs `flutter build apk --debug` and launches the app on the emulator, then the build succeeds with the project's NDK (D-029); `sqlite3_flutter_libs` and `sqlcipher_flutter_libs` are **not direct dependencies** in `pubspec.yaml`, and if they appear in `pubspec.lock` they are only the `+eol` stubs (`0.6.0+eol` / `0.7.0+eol` or later `+eol`), never an older build-script version; and the app opens the database (a month can be saved and read back on the device). |
| AC-14 | **Speed.** Given a database with one month and 500 transactions, when the transactions list is opened on the emulator, then the list appears in under 1 second, and a single add/edit/delete is stored and reflected in under 500 ms. |
| AC-15 | **Regression.** Given all F-007 changes, when `tool/check.ps1` runs, then it passes, and all F-001 to F-005 Regression-yes cases and `tests/REGRESSION.md` stay green. |
| AC-16 | **Period history is never overwritten (D-037).** Given a confirmed E2 month, when the rent is changed on 20 Nov and the EMI on 28 Nov (F-006 AC-21), then the database holds 3 period records, each with its own fixed-cost items and values; the 5 Nov period still shows rent ₹10,000 and EMI ₹5,000; no period row or item row was updated or deleted (checked by a test that compares rows before and after each change); and after force-stop and reopen the engine reproduces exactly the same day budgets for 5 Nov – 4 Dec as before the restart. |
| AC-17 | **Mid-month start and shortfall stored.** Given a first setup on 10 Nov 2026 with money left ₹24,900 (D-034), and separately a month continued with a ₹1,000 shortfall (D-036), when each is saved and read back after restart, then the first budgeted day (10 Nov), the money-left amount (24,90,000 paise), the "continued with shortfall" flag and the shortfall (1,00,000 paise) are returned exactly. |
| AC-18 | **Cover changes are kept (D-040, D-048).** Given the F-006 AC-12 data stored, when the edit that takes both covers back is saved, then both stored cover amounts are 0 in the same transaction as the edit (a forced failure stores neither), and a later edit that grows the pot does not bring them back; given an edit that lowers a covered day's overspend (F-006 §4), then the stored cover is lowered to the new overspend in the same way. |
| AC-19 | **Money in is stored (D-047).** Given schema v1, when a transaction with direction money in is written and read back (also after reopening), then its direction, amount and date are identical, the direction column only allows spend or money in, and the engine receives it as money in. Phase 2 screens never create one. |

## 4. Edge cases *(Product Manager)*
- **Disk full** when saving: a write failure (AC-10). The data already stored stays intact.
- **App killed mid-write** (force-stop during save): on reopen there is either the full record or nothing (AC-4 rule), never a half-saved month.
- **Very long note** (F-009 limit 100 characters): stored and read back exactly, including emoji and Hindi text in notes.
- **Duplicate save** (double tap): F-009/F-008 prevent it. The repository does not merge identical manual spends, because two equal spends on one day are legitimate.
- **Deleting a transaction** is a real delete in Phase 2 (no trash), confirmed in F-009. A soft-delete column for Phase 4 SMS de-duplication is a plan choice.
- **Deleting a month:** not offered in Phase 2.
- **Clearing app data from Android settings:** everything is gone, the same as a fresh install. Expected (no cloud).
- **Older app over newer database:** AC-8.
- **Device-to-device transfer** (new phone setup): the database and preferences are included (D-045); cloud backup stays off. On Android 11 and older the system ties transfer to backup, so with cloud backup off there is no transfer on those versions (D-049).
- **Time zone or clock changes:** dates are stored as calendar dates (AC-3). Created/edited times are used only for ordering within a day.
- **The two stores** (preferences and database) are independent. A database failure must not affect the theme, tour or hint flags, and a preferences failure must not affect money data.

## 5. Help text & copy *(Product Manager, finalised by Designer)*
| Control | Label | Description / tooltip |
|---|---|---|
| Storage error screen — title | `We couldn't open your data` | `Your budget data is still on this phone. Try again, and if this keeps happening, restart your phone.` |
| Storage error — button | `Try again` | Hint: `Try to open your data again` |
| Save error (snackbar / inline) | `Couldn't save. Please try again.` | — |
| Load error (screen error state) | `Couldn't load your data` | `Tap Try again. Nothing has been lost.` |

## 6. Out of scope
- Backup, export, import, cloud or sync (D-003).
- "Delete all app data" in Settings (STANDARDS §8; see Suggested additions).
- SMS-transaction fields and de-duplication (Phase 4), the categories table and merchant memory (Phase 4).
- Moving the theme, tour and hint preferences into the database (they stay in D-026's store).
- Multiple accounts (D-006).

## 7. How it works — technical *(Developer, filled in when the feature is Done)*
**What was built.** The on-device store for all money data: Drift over plain SQLite (D-018, D-067), a guarded open that never deletes or downgrades the file, three repositories with Drift implementations and in-memory fakes, a startup gate with a storage error screen, the Android backup rules, and the quality gates (D-068). Tasks T-206 to T-211, Gate 3 approved 2026-11-13, Gate 4 passed (D-071).

**Main files** (`app/`)
- `lib/data/database/`: `tables.dart` (tables), `triggers.drift` (append-only triggers), `converters.dart` (`CalendarDate` and `Paise` converters), `app_database.dart` (+ committed `.g.dart`; schema v1, `onCreate`, step-by-step `onUpgrade`, throws when `from > to`), `database_connection.dart` (`openAppDatabase`, `setup` version guard, `DatabaseTooNewException`, foreign keys on). Schema snapshot in `drift_schemas/app_database/`, generated migration tests in `test/drift/`.
- `lib/data/repositories/`: interfaces `month_repository.dart`, `transaction_repository.dart`, `savings_repository.dart`; Drift implementations `drift_month_repository.dart`, `drift_transaction_repository.dart`, `drift_savings_repository.dart`; `drift_mappers.dart`, `drift_month_input.dart`, `cover_reconciliation.dart` (D-040 reductions and D-048 clamps inside the write transaction); `storage_exception.dart` (`StorageException` with kind).
- `lib/core/providers/database_providers.dart` (`appDatabaseProvider`, repository providers, month input and result providers); `lib/features/storage_error/` (`database_gate.dart`, `storage_error_screen.dart`); `lib/core/copy/storage_copy.dart`; `lib/core/logging/app_logging.dart` (D-019).
- `android/app/src/main/AndroidManifest.xml` (`allowBackup="false"`, `fullBackupContent`, `dataExtractionRules`) and `res/xml/data_extraction_rules.xml`, `backup_rules.xml`.
- Test helpers: `test/helpers/fake_money_store.dart` and the fake repositories, `test_database.dart`. `tool/check.ps1` steps from D-068 (Drift codegen up to date, domain coverage, time-zone matrix).

**Data stored** (schema v1; money as integer paise, calendar dates as integer day numbers, times as UTC epoch milliseconds for ordering only)
- `budget_months`, `budget_periods` and `period_fixed_costs` (**append-only**, enforced by `BEFORE UPDATE` and `BEFORE DELETE` triggers; D-037), `transactions` (with `direction`, D-047, and a nullable `category`, empty in Phase 2), `savings_moves` (updated in place only for D-040 reductions and D-048 clamps, in the same transaction as the edit).
- Day budgets are **not stored**: the repositories give the periods, spends and covers to the F-006 engine, which recomputes them.
- File: `app_flutter/budget.sqlite` in the app's private storage. No extra encryption (D-041). Cloud backup off; device-to-device transfer includes `database` and `sharedpref` (D-045, D-049). Preferences stay in their own store (D-026), so theme and tour work when the database fails.

**Decisions:** D-018 / D-067 (packages), D-019 (logging), D-037 (period history), D-040, D-041, D-045, D-047, D-048, D-049, D-051, D-068 (check.ps1 steps), D-070 (no `intl`), D-071 (Gate 4 rulings).

**Deviations** (plan section 11): `intl` not a dependency (D-070); `sqlite3` 3.9.1 needs `flutter pub upgrade sqlite3 hooks meta record_use` (D-067); repository method names differ slightly from plan section 2 (`watchCurrentMonth`, `watchLatestMonth`, `watchMonth`, `latestConfirmedMonth`, `confirmMonth`, `addPeriod`) and the fakes share one `FakeMoneyStore`; the logging hook is in `core/logging/app_logging.dart`; no debug delay hook for TC-007-33 (PM Nice to have, accepted at Gate 3); the Android backup behaviour (D-049) was checked by the Project Manager against the Android developer page "Auto Backup for Apps" and matches.

**How it is tested** (`tests/F-007-local-database.md`, 48 cases, 19 / 19 ACs)
- Automated, named `TC-007-NN`: `test/data/database/` (`schema_test`, `append_only_triggers_test`, `calendar_date_converter_test`, `database_time_zone_test` in three zones, `migration_test`, `open_failure_test`), `test/data/repositories/` (`months_repository_test`, `period_history_test`, `savings_repository_test`, `transactions_repository_test`), `test/drift/` (generated migration tests), architecture guards (repositories only, no data in logs), storage error screen tests. Integration on the emulator: `integration_test/persistence_test.dart` (TC-007-03, -24).
- Gates in `tool/check.ps1`: Drift codegen up to date (TC-007-14, -38), domain coverage 100%, time-zone matrix.
- Manual and command cases run by the Tester (run R1, 2026-11-13): TC-007-02, -17, -19 to -23, -36, -37, -41; evidence in `docs/reviews/emulator-phase-2/`.
- Result at Gate 4 (R1): 46 Pass of 48, 1 Partial, 1 Blocked, no bug; `check.ps1` 591 tests green; integration 5 of 5; worst on-screen list of 500 spends 450 ms, repository level 32 ms list and 36 ms write on the emulator.
- Result at the Gate 4 re-check (R5, 2026-11-16): 47 Pass of 48, 1 Blocked (TC-007-48), no bug; `check.ps1` 606 tests green; integration 8 of 8; TC-007-33 now Pass (7 timed kills of a valid 10-item save, only none or all 10 items).

**Known limitations and open items**
- **TC-007-48 (device-to-device transfer) is Blocked:** the emulator has no device-transfer test transport. The cloud half passes (`bmgr backupnow`: `Backup is not allowed`); the transfer half is proved only by the merged XML (TC-007-19), as the case allows. A real phone-to-phone transfer is recommended, not required (D-071).
- **TC-007-33 (kill during a save)** was Partial in R1 and is **Pass (best effort)** in R5: seven timed `am force-stop` kills around the commit moment gave only "no month" or "the full month with 10 items"; TC-007-09 and -10 prove the other half (a trigger aborts the third cost insert and no rows remain).
- Android 16 QPR2 `cross-platform-transfer` (move to an iPhone) is not in the XML (Gate 3 N2, needs iOS ids); not checkable on the Android 17 emulator. Owner was told.
- The "today" value does not refresh when the time zone changes while the app stays in the foreground; it refreshes on resume and at midnight. Accepted (D-071).
- Not built: T-222 (automatic snapshot before each migration, until the first v2 migration), Gate 3 N1 (swapped doc comments in `database_providers.dart`, to be tidied with the next edit) and N3 (keep the test that `knownSchemaVersion` matches `schemaVersion` when v2 lands).
- Depends on F-006 (engine). Used by F-008, F-009 and Phase 3 features (F-010 to F-017); Phase 4 adds the SMS source and de-duplication columns by migration.

## 8. Change history
| Date | Change | By |
|---|---|---|
| 2026-11-10 | First version of the spec; encryption (OD-1) pending the look-ahead and the Owner | Product Manager |
| 2026-11-10 | Owner decisions applied: D-037 (append-only budget period history, fixed costs per period, past budgets reproducible; §2.1, new AC-16), D-034/D-036 (first budgeted day, money left, shortfall flag stored; new AC-17). ACs 15 → 17. OD-1 still pending | Product Manager |
| 2026-11-10 | Final: D-041 applied (no extra encryption, §2.8, AC-12 rewritten); look-ahead findings applied: dates as integer day numbers via a converter, with POSIX `TZ` per process (§2.2, AC-3, #7–#8); `sqlite3_flutter_libs` / `sqlcipher_flutter_libs` not direct dependencies, only `+eol` stubs allowed in the lock (§2.9, AC-13, #6). No PENDING items left. Status: final Spec, ready for the plan. 17 ACs | Product Manager |
| 2026-11-10 | Gate 1 reconciliation: D-045 device-to-device transfer included, cloud backup still off (§2.7, §4, AC-11; Suggested addition removed); D-047 transaction direction (§2.1, new AC-19); D-048 cover reductions and clamps stored with the edit (§2.1, new AC-18), "what changed" derived, created-time order within a day. 19 ACs. Status → Plan approved | Project Manager |
| 2026-11-16 | Section 7 filled in (Step 9, T-245): what was built, files, stored data, decisions, deviations, tests, limitations (TC-007-48 Blocked, TC-007-33 Partial accepted, D-071). Gate 4 passed. INDEX status not changed here | Developer |

## Open decisions *(all closed)*
| ID | Question | Decision |
|---|---|---|
| OD-1 | Encrypt the database? | D-041: no extra encryption; private storage and device encryption, cloud backup off (§2.8, AC-12) |
| OD-5 | Mid-month changes | D-037: append-only period history (§2.1, AC-16) |

## Suggested additions *(for the CEO — not in scope until approved)*
- **"Delete all app data" in Settings in Phase 2.** STANDARDS §8 requires it, and once money data exists users will expect it. It is one confirmed action that empties the database and preferences.
- **Automatic local snapshot before each migration** (a copy of the file in private storage), so a failed upgrade can be rolled back.
