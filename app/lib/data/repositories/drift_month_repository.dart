import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/data/repositories/drift_mappers.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:drift/drift.dart';

/// [MonthRepository] on the Drift database (F-007 plan 1.6). Each write is one
/// transaction; each read is a Drift stream that fires again when a month,
/// period or fixed cost changes.
final class DriftMonthRepository implements MonthRepository {
  const new(this._db);

  final AppDatabase _db;

  @override
  Stream<StoredMonth?> watchCurrentMonth(CalendarDate today) => _watchFirst(
    (m) =>
        m.startDay.isSmallerOrEqualValue(today.dayNumber) &
        m.endDay.isBiggerOrEqualValue(today.dayNumber),
  );

  @override
  Stream<StoredMonth?> watchLatestMonth() => _watchFirst(
    (m) => const CustomExpression<bool>(
      'budget_months.start_day = (SELECT max(start_day) FROM budget_months)',
    ),
  );

  @override
  Stream<StoredMonth?> watchMonth(int monthId) =>
      _watchFirst((m) => m.id.equals(monthId));

  @override
  Future<StoredMonth?> latestConfirmedMonth() =>
      guarded(StorageFailureKind.read, () => watchLatestMonth().first);

  @override
  Future<StoredMonth> confirmMonth(NewMonth month) {
    _validateNewMonth(month);
    return guarded(StorageFailureKind.write, () async {
      final id = await _db.transaction(() async {
        final monthId = await _db
            .into(_db.budgetMonths)
            .insert(
              BudgetMonthsCompanion.insert(
                startDay: month.month.start,
                endDay: month.month.end,
                salaryDay: month.month.salaryDay,
                firstBudgetedDay: month.firstBudgetedDay,
                confirmedAt: month.confirmedAt,
              ),
            );
        await _insertPeriod(monthId, month.firstPeriod);
        return monthId;
      });
      return (await watchMonth(id).first)!;
    });
  }

  @override
  Future<void> addPeriod(int monthId, BudgetPeriod period) {
    period.values.validate();
    _validateCostNames(period.values);
    return guarded(
      StorageFailureKind.write,
      () => _db.transaction(() => _insertPeriod(monthId, period)),
    );
  }

  Stream<StoredMonth?> _watchFirst(
    Expression<bool> Function($BudgetMonthsTable month) where,
  ) {
    final query = monthsQuery(_db)..where(where(_db.budgetMonths));
    return guardedStream(
      query.watch().map((rows) => storedMonthsOf(rows, _db).firstOrNull),
    );
  }

  Future<void> _insertPeriod(int monthId, BudgetPeriod period) async {
    final values = period.values;
    final periodId = await _db
        .into(_db.budgetPeriods)
        .insert(
          BudgetPeriodsCompanion.insert(
            monthId: monthId,
            startDay: period.start,
            changedAt: period.changedAt,
            kind: switch (values) {
              FullMonthValues() => fullKind,
              MidMonthStartValues() => midMonthStartKind,
            },
            salaryPaise: Value(switch (values) {
              FullMonthValues(:final salary) => salary,
              MidMonthStartValues() => null,
            }),
            targetPaise: Value(switch (values) {
              FullMonthValues(:final target) => target,
              MidMonthStartValues() => null,
            }),
            moneyLeftPaise: Value(switch (values) {
              FullMonthValues() => null,
              MidMonthStartValues(:final moneyLeft) => moneyLeft,
            }),
            continuedWithShortfall: Value(period.continuedWithShortfall),
            shortfallPaise: Value(shortfallOf(values)),
          ),
        );
    final costs = switch (values) {
      FullMonthValues(:final fixedCosts) => fixedCosts,
      MidMonthStartValues(:final fixedCostsStillToPay) => fixedCostsStillToPay,
    };
    for (final (position, cost) in costs.indexed) {
      await _db
          .into(_db.periodFixedCosts)
          .insert(
            PeriodFixedCostsCompanion.insert(
              periodId: periodId,
              position: position,
              name: cost.name,
              amountPaise: cost.amount,
            ),
          );
    }
  }

  void _validateNewMonth(NewMonth month) {
    if (!month.month.contains(month.firstBudgetedDay)) {
      throw ArgumentError.value(
        month.firstBudgetedDay.iso,
        'firstBudgetedDay',
        'is not in the month',
      );
    }
    month.firstPeriod.values.validate();
    _validateCostNames(month.firstPeriod.values);
  }

  void _validateCostNames(PeriodValues values) {
    final costs = switch (values) {
      FullMonthValues(:final fixedCosts) => fixedCosts,
      MidMonthStartValues(:final fixedCostsStillToPay) => fixedCostsStillToPay,
    };
    for (final cost in costs) {
      if (cost.name.isEmpty) {
        throw ArgumentError.value(cost.name, 'name', 'must not be empty');
      }
    }
  }
}
