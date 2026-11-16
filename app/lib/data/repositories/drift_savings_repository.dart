import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/data/repositories/drift_mappers.dart';
import 'package:daily_budget/data/repositories/drift_month_input.dart';
import 'package:daily_budget/data/repositories/savings_repository.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:drift/drift.dart';

/// [SavingsRepository] on the Drift database.
final class DriftSavingsRepository implements SavingsRepository {
  const new(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Cover>> watchCovers(int monthId) {
    final query = _db.select(_db.savingsMoves)
      ..where((m) => m.monthId.equals(monthId))
      ..orderBy([
        (m) => OrderingTerm.asc(m.madeAt),
        (m) => OrderingTerm.asc(m.id),
      ]);
    return guardedStream(
      query.watch().map((rows) => [for (final row in rows) coverOf(row)]),
    );
  }

  @override
  Future<CoverDecision> cover(
    int monthId,
    CalendarDate day,
    Paise amount, {
    required CalendarDate today,
    required int now,
  }) {
    return guarded(
      StorageFailureKind.write,
      () => _db.transaction(() async {
        final result = computeMonth(await loadMonthInput(_db, monthId, today));
        final decision = checkCover(result, day, amount);
        if (decision is CoverAllowed) {
          await _db
              .into(_db.savingsMoves)
              .insert(
                SavingsMovesCompanion.insert(
                  monthId: monthId,
                  coveredDay: day,
                  amountPaise: amount,
                  madeAt: now,
                ),
              );
        }
        return decision;
      }),
    );
  }
}
