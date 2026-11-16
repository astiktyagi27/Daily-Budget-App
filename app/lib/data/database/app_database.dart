import 'package:daily_budget/data/database/converters.dart';
import 'package:daily_budget/data/database/tables.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// The money database: facts only (months, periods, fixed costs, spends and
/// savings moves). Day budgets are never stored; the engine recomputes them.
@DriftDatabase(
  tables: [
    BudgetMonths,
    BudgetPeriods,
    PeriodFixedCosts,
    Transactions,
    SavingsMoves,
  ],
  include: {'triggers.drift'},
)
class AppDatabase extends _$AppDatabase {
  new(super.e);

  /// The newest schema version this app knows (F-007 AC-7). It must stay a
  /// plain integer literal: `drift_dev make-migrations` reads it from here.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // A database newer than this app is refused before it gets here (see
    // database_connection.dart); this is the second guard (plan 1.4).
    onUpgrade: (m, from, to) async {
      if (from > to) {
        throw StateError('database version $from is newer than $to');
      }
      // Schema v1 has no earlier version. The first v2 migration (T-222) runs
      // `dart run drift_dev make-migrations`, which then generates
      // `stepByStep()`; until then an upgrade nobody wrote must fail loudly.
      throw StateError('no migration from version $from to $to');
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
