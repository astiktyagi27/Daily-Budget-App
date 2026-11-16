import 'package:daily_budget/data/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:sqlite3/common.dart';

/// The schema version this app knows. It must equal
/// [AppDatabase.schemaVersion] (a test checks it): the guard below runs in the
/// background isolate, where there is no [AppDatabase] to ask.
const knownSchemaVersion = 1;

/// The file holds a newer schema than this app knows (an older app installed
/// over a newer one). The file is left untouched (F-007 AC-8).
final class DatabaseTooNewException implements Exception {
  const new({required this.found, required this.known});

  final int found;

  final int known;

  @override
  String toString() => 'DatabaseTooNewException($found > $known)';
}

/// Throws [DatabaseTooNewException] when the file's `user_version` is newer
/// than [knownSchemaVersion].
///
/// It runs on the raw connection before Drift's migration logic: Drift would
/// otherwise call `onUpgrade(from: 2, to: 1)` and then write the lower
/// version into the file (plan F-007 1.4). Reading `PRAGMA user_version`
/// writes nothing.
void guardAgainstNewerDatabase(CommonDatabase database) {
  final found = database.select('PRAGMA user_version').single.values.first;
  if (found is int && found > knownSchemaVersion) {
    throw DatabaseTooNewException(found: found, known: knownSchemaVersion);
  }
}

/// Opens (or creates) the money database file `budget.sqlite` in the app's
/// private documents folder, on a background isolate (F-007 AC-12).
///
/// [databasePath] and [tempDirectoryPath] exist for tests that must not call
/// the platform plugins; the app passes neither.
DatabaseConnection openDatabaseConnection({
  Future<String> Function()? databasePath,
  Future<String?> Function()? tempDirectoryPath,
}) => driftDatabase(
  name: 'budget',
  native: DriftNativeOptions(
    setup: guardAgainstNewerDatabase,
    databasePath: databasePath,
    tempDirectoryPath: tempDirectoryPath,
  ),
);

/// The app's database. Opening is lazy: Drift opens the file on the first
/// query, which is the probe in `appDatabaseProvider`. [executor] replaces the
/// real file in tests.
AppDatabase openAppDatabase({QueryExecutor? executor}) =>
    AppDatabase(executor ?? openDatabaseConnection());
