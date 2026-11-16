import 'dart:io';

import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/data/repositories/drift_month_repository.dart';
import 'package:daily_budget/data/repositories/drift_savings_repository.dart';
import 'package:daily_budget/data/repositories/drift_transaction_repository.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/data/repositories/savings_repository.dart';
import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/test_database.dart';

/// The three Drift repositories on one database.
final class Repos {
  new(this.db)
    : months = DriftMonthRepository(db),
      spends = DriftTransactionRepository(db),
      savings = DriftSavingsRepository(db);

  final AppDatabase db;
  final MonthRepository months;
  final TransactionRepository spends;
  final SavingsRepository savings;
}

/// Repositories on a fresh in-memory database (look-ahead #4), closed when the
/// test ends.
Repos openMemoryRepos() {
  final db = openTestDatabase();
  addTearDown(db.close);
  return Repos(db);
}

/// Repositories on the database file [file] (created if missing), closed when
/// the test ends unless the test closes it first. "Restart (sim, DB)" is
/// `await repos.db.close()` followed by `openFileRepos(file)` again.
Repos openFileRepos(File file) {
  final db = AppDatabase(NativeDatabase(file));
  addTearDown(db.close);
  return Repos(db);
}

/// A fresh temporary folder for a file-based test, deleted afterwards.
Directory tempFolder(String name) {
  final folder = Directory.systemTemp.createTempSync(name);
  addTearDown(() {
    try {
      folder.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows can keep a file locked for a moment; the OS cleans /tmp.
    }
  });
  return folder;
}

/// Seed E2 (tests/F-007 section 0): salary day 5, 5 Nov - 4 Dec 2026, salary
/// 40,00,000, Rent / EMI / Subscriptions, first budgeted day 5 Nov.
NewMonth e2NewMonth({PeriodValues? values, bool continued = false}) => NewMonth(
  month: nov2026,
  firstBudgetedDay: d(2026, 11, 5),
  firstPeriod: period(
    d(2026, 11, 5),
    values ?? e2Values(),
    continued: continued,
  ),
  confirmedAt: at(d(2026, 11, 5), 8),
);

/// `SpendFields` of [amount] paise on [date].
SpendFields fields(CalendarDate date, int amount, [String? note]) =>
    (amount: Paise(amount), date: date, note: note);

/// The rows of [table] as raw maps sorted by id (a "Row snapshot").
Future<List<Map<String, Object?>>> rowSnapshot(
  AppDatabase db,
  String table,
) async {
  final rows = await db.customSelect('SELECT * FROM $table ORDER BY id').get();
  return [for (final row in rows) row.data];
}

Future<int> countRows(AppDatabase db, String table) async {
  final row = await db
      .customSelect('SELECT count(*) AS n FROM $table')
      .getSingle();
  return row.read<int>('n');
}

/// Collects everything a stream emits, for "after pumpEventQueue()" checks.
final class Collected<T> {
  new(Stream<T> stream) {
    final subscription = stream.listen(values.add, onError: errors.add);
    addTearDown(subscription.cancel);
  }

  final List<T> values = [];
  final List<Object> errors = [];
}
