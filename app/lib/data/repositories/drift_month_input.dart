import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/data/repositories/cover_reconciliation.dart';
import 'package:daily_budget/data/repositories/drift_mappers.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:drift/drift.dart';

/// Loads every stored fact of one month as the engine's input, as of [today]
/// (F-007 plan 1.1: day budgets are recomputed, never stored). Must run inside
/// the write's transaction when it is used to reconcile covers.
Future<MonthInput> loadMonthInput(
  AppDatabase db,
  int monthId,
  CalendarDate today,
) async {
  final rows = await (monthsQuery(
    db,
  )..where(db.budgetMonths.id.equals(monthId))).get();
  final stored = storedMonthsOf(rows, db).single;
  final spends = await (db.select(
    db.transactions,
  )..where((t) => t.monthId.equals(monthId))).get();
  final covers = await (db.select(
    db.savingsMoves,
  )..where((m) => m.monthId.equals(monthId))).get();
  return MonthInput(
    month: stored.month,
    firstBudgetedDay: stored.firstBudgetedDay,
    periods: stored.periods,
    today: today,
    spends: [for (final row in spends) storedSpendOf(row).spend],
    covers: [for (final row in covers) coverOf(row)],
  );
}

/// Recomputes the month after a spend write and lowers any stored cover the
/// engine now moves less, inside the caller's transaction (D-040, D-048).
/// Returns the covers reduced by the pot shrinking, for the screen's note.
Future<List<CoverReduction>> reconcileStoredCovers(
  AppDatabase db,
  int monthId,
  CalendarDate today,
) async {
  final reconciliation = reconcileCovers(
    await loadMonthInput(db, monthId, today),
  );
  for (final cover in reconciliation.toStore) {
    await (db.update(db.savingsMoves)..where((m) => m.id.equals(cover.coverId)))
        .write(SavingsMovesCompanion(amountPaise: Value(cover.amount)));
  }
  return reconciliation.reductions;
}
