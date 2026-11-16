# Phase 2 technical look-ahead

**By:** Developer C (look-ahead), 2026-11-10 · **Scope:** what could block Phase 2 (F-006 budget engine, F-007 local database, F-008 month setup, F-009 manual transactions) before it starts.
**Method:** a throwaway Flutter 3.47.9 / Dart 3.13.7 project in a folder **with a space in its path** (`…\scratchpad\phase2-spike\phase 2 spike\`). It used the app's `analysis_options.yaml` (very_good_analysis 11 + `riverpod_lint` 3.1.9 plugin), an Android-only `flutter create`, `ndkVersion = flutter.ndkVersion` and Windows Developer Mode **off**. Nothing in `app/`, `plans/`, `tests/` or `docs/features/` was touched. The spike folder was deleted afterwards.

## Summary

- **No hard blocker.** Drift code generation, `flutter test` with a real SQLite on Windows, the debug and release APK builds, and `dart analyze --fatal-infos` all work.
- **Two spec corrections are needed before Gate 1:**
  - F-007 AC-13 cannot pass as written. `drift_flutter` 0.3.1 always brings in `sqlite3_flutter_libs 0.6.0+eol`, an empty stub.
  - F-007 AC-3 will fail if dates use Drift's default `DateTimeColumn`. A measured example is in the table.
- **One Owner decision:** OD-1, database encryption. Sizes, speed and licences were measured; see §3.

## 1. Risk table

| # | Risk | Finding (measured) | Recommendation | Who decides |
|---|---|---|---|---|
| 1 | `build_runner` fails on Windows with a space in the path | **Works.** Running `dart run build_runner build` in `phase 2 spike\` gave `database.g.dart`. The first run took 65 s (it compiles the builders once). Later runs took 3–9 s; with Riverpod codegen added, the first run took 47 s. | No action. Put "run `dart run build_runner build` after any table change" in the F-007 plan and in `tool/check.ps1`, either as a step or as a check that the generated files are up to date. | Developer (plan) |
| 2 | Native SQLite needs a new NDK or CMake, or a large download | **No compile.** `sqlite3` 3.9.1's build hook **downloads prebuilt SQLite 3.54** from the package's GitHub release and checks each file's sha256. NDK 28.2.13676358 (`flutter.ndkVersion`, D-029) was picked automatically; NDK 30 is not needed. **Download sizes:** `libsqlite3.so` is 1.83–1.90 MB per ABI (arm, arm64, x64), plus a 1.73 MB `sqlite3.dll` for host tests. That is about 7 MB in total, cached in `.dart_tool/hooks_runner/shared/sqlite3/`. `flutter build apk --debug` succeeded in 102 s. | **The first build after a clean needs internet access to github.com.** Note it in README §13. No NDK change. | — |
| 3 | Play's 16 KB page-size requirement for native libraries | **Passes.** All three `libsqlite3.so` (and `libsqlite3mc.so` / `libsqlcipher.so`) have `LOAD` alignment `0x4000` (checked with `llvm-readelf`). `zipalign -c -P 16 -v 4` on the APK printed `Verification successful`. | No action. The Tester can repeat the `zipalign -P 16` check for AC-13. | — |
| 4 | Drift does not run in plain `flutter test` on Windows | **Works.** `NativeDatabase.memory()` runs on the host's downloaded `sqlite3.dll`. Tests covered insert, `watchSingle()` stream updates (`[0, 133333]`) and foreign keys. Three DB tests took 5.6 s warm and 17 s cold. | Repository tests use `NativeDatabase.memory()`, so no emulator is needed for F-007 unit tests. | Developer (plan) |
| 5 | **Drift streams hang in widget tests** | **Hit and fixed.** A widget test that inserted inside `tester.runAsync` and then called `pumpAndSettle()` **hung until the 300 s timeout**. A working pattern took about 1 s per test: open the database as `DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true)`; do writes in `tester.runAsync(...)`; then `pump()` (not `pumpAndSettle`); at the end, pump an empty widget and `await tester.runAsync(db.close)`. | Better still: **keep Drift out of widget tests.** Screens get repositories through providers (F-007 AC-6), so widget tests override them with in-memory fakes. Use the pattern above only for the few DB+UI tests. Write it into the F-007 plan so nobody loses a day to a hanging test. | Developer (plan) |
| 6 | **F-007 AC-13 says no `sqlite3_flutter_libs` in `pubspec.lock`** | `drift_flutter` 0.3.1 depends on `sqlite3_flutter_libs: ^0.6.0+eol` **and** `sqlcipher_flutter_libs: ^0.7.0+eol`. Both are **empty stubs** ("no longer does anything") that stop an app from using the old 0.5.x build scripts. They always appear in the lock as transitive dependencies. | Change AC-13 to: "`sqlite3_flutter_libs`/`sqlcipher_flutter_libs` are not **direct** dependencies; if they are in the lock, they are `+eol` (≥ 0.6.0 / ≥ 0.7.0)". D-018's wording ("do not add") is still right. | Product Manager (AC wording), PM at Gate 1 |
| 7 | **Dates move to another day when the time zone changes (F-007 AC-3)** | **Reproduced.** A Drift `DateTimeColumn` stored `DateTime(2026, 11, 9)` under IST and read it back as **`2026-11-08 18:30` under UTC** and **`2026-11-08 10:30` under PST8PDT**, so the day was 8 instead of 9. The default column stores a Unix timestamp of the *local* time. Storing it as text has the same problem. | Store calendar dates as an **`INTEGER` day number**: days since 1970-01-01, computed from `DateTime.utc(y, m, d)`, or `yyyymmdd`. Map it with a Drift `TypeConverter` to a small pure-Dart `CalendarDate` value type in `domain/`. Never use `DateTimeColumn` for budget or transaction dates. Created/edited timestamps can stay `DateTimeColumn`, because they are only used for ordering. | Developer (plan), PM at Gate 1 |
| 8 | Time-zone tests (AC-3) cannot change the zone during a test run | Dart has no in-process time-zone override. On Windows, the `TZ` environment variable **does** work per process, but only in POSIX form (`TZ=UTC`, `TZ=PST8PDT`, `TZ=IST-5:30`). IANA names such as `America/Los_Angeles` and `Asia/Kolkata` are **silently ignored**: the process stays in IST. | Test the converter itself as a pure function; with the integer design in #7 it never touches the local zone. In addition, run the F-007 date test file 3 times with POSIX `TZ` values (e.g. a `check.ps1` step: `TZ=UTC`, `TZ=PST8PDT`, default). The Tester should write AC-3 with POSIX zone names. | Tester + Developer |
| 9 | Foreign keys are off by default in SQLite | They are enforced only after `PRAGMA foreign_keys = ON` (tested). | Turn them on in `MigrationStrategy.beforeOpen`. | Developer (plan) |
| 10 | Riverpod + Drift version conflicts | **None.** `drift_dev` 2.35.3 needs `analyzer >=13 <15` and resolved **analyzer 14.7.0**. `riverpod_generator` 4.0.10 needs the same range, so codegen for **both** works in one `build_runner` run (tested). Note: `riverpod_annotation` 4.0.8 pins **riverpod 3.5.0** exactly, and `riverpod_lint` 3.2.0 does too, while `riverpod_lint` 3.1.9 pins 3.4.3. Riverpod codegen therefore means moving to flutter_riverpod 3.5.0 + riverpod_lint 3.2.0 together. | **Stay on manual providers in Phase 2** (keep D-027) unless the plan shows a clear gain. Phase 2 needs only a handful of providers. If codegen is chosen, bump `flutter_riverpod` 3.5.0 and `riverpod_lint` 3.2.0 together (both released 2026-11-06). | Developer (plan), PM at Gate 1 |
| 11 | `dart analyze --fatal-infos` fails on generated code | **Clean, no `exclude:` needed.** Drift and Riverpod generated files start with `// ignore_for_file: type=lint`. `riverpod_lint` still fires with Drift present (a probe gave `avoid_public_notifier_properties` in `dart analyze`). Hand-written Drift code must follow D-024: the database constructor is `new([QueryExecutor? e]) : super(...)`, and codegen accepts that. | Keep D-013/D-016 unchanged. Decide in the plan whether to commit `*.g.dart` files. **Recommended: commit them**, so `check.ps1` and the Tester don't need a generate step, plus a check that they are current. | Developer (plan) |
| 12 | Indian money format (`₹1,33,333`) | **`intl` 0.20.3 works:** `NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(133333)` → `₹1,33,333`; 10 crore → `₹10,00,00,000`. **Pitfalls:** (a) it takes `num`, so formatting paise as `paise / 100` brings in a `double` (STANDARDS §4); (b) it **rounds half-up** (`666.67` → `₹667`, `2.5` → `₹3`), but README example 3 shows `₹666`; (c) negatives print `-₹467` with ASCII hyphen-minus. | Write a small `formatPaise(int)` in `core/`. It formats the **integer rupees** (`paise ~/ 100`) with `NumberFormat.decimalPattern('en_IN')`, so no doubles. It then adds `₹`, the sign (`−` U+2212 if the design wants it) and the paise part according to **OD-6** (truncate, not round, if README's `₹666` is meant). Unit-test it with TC IDs. `intl` gives tested Indian grouping; the wrapper keeps it integer-only. | Developer (plan); OD-6 display rule: Owner |
| 13 | Salary dates 29–31 and leap years | Not a tool issue, but easy to get wrong: (a) clamp the salary day to the month's length (`DateTime.utc(y, m + 1, 0).day`); (b) store the **salary day** (e.g. 31), not the last start date, or months drift to the 28th forever after February; (c) count days with UTC dates (`DateTime.utc(...).difference(...).inDays`), never local `DateTime` + `Duration(days: 1)`, which breaks under DST zones; (d) "today" must be injectable for tests (`clock` 1.1.3, Dart team, or a provider). | Required unit tests: salary 31 → 31 Jan–27 Feb, 28 Feb–30 Mar (2026); 29 Feb 2028; salary 29/30 in February; mid-month install; a 28-day month at ₹40,000 with leftover paise spread exactly. | Developer + Tester |
| 14 | Database not excluded from cloud backup (F-007 AC-11, D-003) | The current `AndroidManifest.xml` has **no `allowBackup` / `dataExtractionRules`**. Android Auto Backup is **on by default**, so the Phase 1 preferences are already eligible for Google Drive backup. | Add `android:allowBackup="false"` **plus** `android:dataExtractionRules` (API 31+, where `allowBackup=false` alone still allows device-to-device transfer) and `android:fullBackupContent` (≤ API 30). This is a manifest change, so it waits until Phase 1's files are closed (F-007 §2.10). If encryption is chosen, this matters more: a restored database without its Keystore key cannot be read. | Developer (plan); PM; the device-transfer choice → Owner (F-007 edge case) |
| 15 | Windows Developer Mode | Developer Mode is **off** on this machine, and all builds and tests passed. Hooks need no symlinks (consistent with D-029). | No action. | — |
| 16 | Test speed | Cold `flutter test` with Drift: about 17 s (includes the one-time hook download). Warm full spike suite: 5–8 s. Batch of 500 inserts: about 40 ms; a single insert: about 4.5 ms; reopen + read 520 rows: 16 ms (host, plain SQLite). | No concern for AC-14 (< 1 s list, < 500 ms write). The emulator check is still the Tester's. | — |
| 17 | Newer versions than D-018 / D-017 | Newer: **drift 2.35.4** and **drift_dev 2.35.3** (both 2026-11-08). drift_flutter 0.3.1 and build_runner 2.17.1 are unchanged. `flutter_riverpod` 3.5.0 / `riverpod_lint` 3.2.0 are out (2026-11-06). Note: `flutter pub get` first resolved an **older cached `sqlite3` 3.5.2**; `flutter pub upgrade` moved it to 3.9.1. | Use the versions in §2. Run `flutter pub upgrade sqlite3` when adding Drift, so `sqlite3` is ≥ 3.9.1. Update D-018 in the F-007 plan. | Developer (plan) |

## 2. Exact working versions (tested together, 2026-11-10)

| Package | Version | Kind |
|---|---|---|
| Flutter / Dart | 3.47.9 / 3.13.7 | toolchain |
| `drift` | **2.35.4** (`^2.35.4`) | dependency |
| `drift_flutter` | 0.3.1 (`^0.3.1`) | dependency |
| `drift_dev` | **2.35.3** (`^2.35.3`) | dev |
| `build_runner` | 2.17.1 (`^2.17.1`) | dev |
| `sqlite3` | 3.9.1 (transitive; SQLite 3.54.1 / sqlite3mc on 3.54.0 / SQLCipher 4.20.0 community) | transitive |
| `sqlite3_flutter_libs` / `sqlcipher_flutter_libs` | 0.6.0+eol / 0.7.0+eol (empty stubs, from drift_flutter) | transitive |
| `sqlparser` / `analyzer` | 0.45.1 / 14.7.0 | transitive |
| `hooks` / `code_assets` / `native_toolchain_c` | 2.2.0 / 2.2.0 / 0.19.6 | transitive |
| `path_provider` | 2.1.6 | transitive |
| `flutter_riverpod` | 3.4.3 (app) — 3.5.0 also works | dependency |
| `riverpod_lint` | 3.1.9 plugin (app) — 3.2.0 if moving to 3.5.0 | analyzer plugin |
| `riverpod_annotation` / `riverpod_generator` | 4.0.8 / 4.0.10 (only if codegen; forces riverpod 3.5.0) | optional |
| `intl` | 0.20.3 (`^0.20.3`) | dependency |
| `clock` | 1.1.3 (optional, for an injectable "today") | optional |
| `flutter_secure_storage` | 11.2.0 (only if encryption is chosen, for the key) | optional |
| Android NDK / CMake | 28.2.13676358 (`flutter.ndkVersion`) / 3.22.1 — nothing new installed | toolchain |

## 3. Database encryption (OD-1) — the options

Measured with `flutter build apk --release --target-platform android-arm64`. The sizes are for one ABI, which is what a Play (AAB) user downloads per device. All three builds needed **no NDK compile**, and all were 16 KB aligned. They are switched with `hooks: user_defines: sqlite3: source: …` in `pubspec.yaml`.

| | A. Plain SQLite + Android protection | B. SQLite3MultipleCiphers (`source: sqlite3mc`) | C. SQLCipher (`source: sqlcipher`) |
|---|---|---|---|
| Builds here | Yes | Yes | Yes |
| Host `flutter test` | Yes | Yes (cipher `chacha20`; wrong key fails; file header not readable) | Yes (`cipher_version` 4.20.0 community) |
| Native library (arm64) | 1.75 MB | 2.03 MB (**+0.28 MB**) | 5.26 MB (**+3.5 MB**, bundles OpenSSL) |
| Release APK (arm64) | 18.2 MB | 18.5 MB | 21.7 MB |
| Open cost (host; a phone is roughly 3–5× slower) | 16 ms reopen + read 520 rows | 57 ms (key derivation) | 140 ms |
| Licence | Public domain | MIT | BSD-style (attribution) + OpenSSL Apache-2.0 notices |
| Maintenance | SQLite upstream; prebuilt by `sqlite3` package (active, 2026-11-08) | utelle/SQLite3MultipleCiphers, active; prebuilt by the same package | Zetetic community edition; the bundled build may lag behind upstream SQLite (package README) |
| Extra work | Backup exclusion (#14), already required | + key in Android Keystore via `flutter_secure_storage` (1 plugin), key-loss handling, AC-12 tests | Same as B, plus licence notices |
| What it protects | Android app sandbox + file-based encryption (default on Android 10+) protect a locked or stolen phone. **Not protected:** a rooted phone, or anyone with the unlocked phone and debug access | + the database file can't be read if copied off a rooted phone or through a backup leak | Same as B |
| Main risk | Weaker against root/forensics | **Lost key = all data unreadable** (Keystore wiped by some OEM resets or restores, device-to-device transfer copies the file but not the key) | Same as B, plus 3.5 MB |

**Recommendation:**
- **Option A for Phase 2.** Plain SQLite, with backup and transfer excluded (#14) and no data in logs. For an app with no cloud and no login, the Android sandbox plus file-based encryption already covers the realistic threat (a lost or stolen phone). Encryption adds a new way to lose *all* data (key loss), which matters more to users than root-level attacks.
- **If the Owner wants encryption, choose B, not C.** B is a small size cost (+0.28 MB vs +3.5 MB), uses a simple MIT licence, has no OpenSSL, and works through the same package with a one-line pubspec switch.
- **The decision can be changed later.** sqlite3mc can encrypt an existing plain database in place (`PRAGMA rekey`), so choosing A now does not block B in a later phase. That would only need a migration step plus the key plugin.

**This is an Owner decision** (privacy, D-003; already listed as OD-1 in F-007 and as Owner decision 1 in `plans/phase-2-overview.md`). The CEO should put it to the Owner in plain words. Suggested wording: "Keep the data in Android's private, phone-encrypted storage (simplest, no risk of locking yourself out), or add a second lock on the database file (+0.3 MB, but if the phone loses the key, the budget data can't be recovered)?"

## 4. Items for the Phase 2 plan checklist

1. Date columns are `INTEGER` day numbers with a `TypeConverter` (#7). Foreign keys are on in `beforeOpen` (#9).
2. AC-13 wording fixed (#6). AC-3 uses POSIX `TZ` names, with multi-`TZ` runs (#8).
3. Decide whether to commit generated files, and whether to add a `build_runner` step to `check.ps1` (#1, #11).
4. Widget tests use repository fakes; the Drift-in-widget pattern is documented (#5).
5. `formatPaise(int)` wrapper over `intl` en_IN; follows OD-6 (#12).
6. Manifest backup rules: `allowBackup`, `dataExtractionRules`, `fullBackupContent` (#14), applied after Phase 1 files are closed.
7. Note internet access for the first native build in README §13 (#2).
8. Update D-018 to drift 2.35.4 / drift_dev 2.35.3; run `flutter pub upgrade sqlite3` (#17).
