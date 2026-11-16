import 'package:daily_budget/data/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// An empty in-memory [AppDatabase] (real SQLite through Drift, look-ahead #4).
///
/// Streams close synchronously so a test ends without pending timers
/// (look-ahead #5). Call `close()` in `addTearDown`.
AppDatabase openTestDatabase() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);
