import 'package:daily_budget/data/database/database_connection.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';

/// Why storage failed. Screens map each kind to the F-007 section 5 copy;
/// none of them ever shows the cause (paths, SQLite text, TC-007-45).
enum StorageFailureKind { open, read, write, tooNew, corrupt }

/// The only error repositories and the database provider throw (F-007 plan
/// 1.7). It carries the [kind] and nothing else: no message, path, amount or
/// SQL, so printing it can never leak data (STANDARDS section 5).
final class StorageException implements Exception {
  const new(this.kind);

  /// Maps whatever Drift or SQLite threw to a [StorageException] of [kind],
  /// or of a more specific kind for a newer or damaged file. An error that is
  /// already a [StorageException] is returned unchanged.
  factory from(Object error, {required StorageFailureKind kind}) {
    if (error is StorageException) return error;
    final cause = _rootCause(error);
    return StorageException(switch (cause) {
      DatabaseTooNewException() => StorageFailureKind.tooNew,
      // SQLITE_CORRUPT (11) and SQLITE_NOTADB (26): a damaged or foreign file.
      SqliteException(:final resultCode)
          when resultCode == 11 || resultCode == 26 =>
        StorageFailureKind.corrupt,
      _ => kind,
    });
  }

  final StorageFailureKind kind;

  @override
  String toString() => 'StorageException(${kind.name})';
}

/// The error a Drift background isolate wrapped, if any.
Object _rootCause(Object error) {
  var current = error;
  for (var depth = 0; depth < 4; depth++) {
    if (current is DriftRemoteException) {
      current = current.remoteCause;
    } else {
      break;
    }
  }
  return current;
}
