import 'dart:async';

import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:drift/drift.dart';

/// Row <-> domain mapping shared by the Drift repositories. Nothing here is
/// visible outside `data/`.

/// The `kind` column values of a period.
const fullKind = 'full';
const midMonthStartKind = 'midMonthStart';

/// The `direction` column values (D-047).
const spendDirection = 'spend';
const moneyInDirection = 'money_in';

SpendDirection directionOf(String column) => switch (column) {
  moneyInDirection => SpendDirection.moneyIn,
  _ => SpendDirection.spend,
};

String directionColumn(SpendDirection direction) => switch (direction) {
  SpendDirection.spend => spendDirection,
  SpendDirection.moneyIn => moneyInDirection,
};

StoredSpend storedSpendOf(TransactionRow row) => StoredSpend(
  spend: Spend(
    id: row.id,
    date: row.day,
    amount: row.amountPaise,
    createdAt: row.createdAt,
    direction: directionOf(row.direction),
  ),
  note: row.note.isEmpty ? null : row.note,
);

Cover coverOf(SavingsMoveRow row) => Cover(
  id: row.id,
  day: row.coveredDay,
  amount: row.amountPaise,
  madeAt: row.madeAt,
);

/// The shortfall column of [values]: how far the fixed costs overshoot the
/// money to spread, or ₹0 (D-036). The engine derives the same number when it
/// plans the period; it is stored so the record is complete (F-007 AC-17).
Paise shortfallOf(PeriodValues values) =>
    values.spendable.isNegative ? -values.spendable : Paise.zero;

/// One period with the rows of its fixed costs, as read from the database.
typedef PeriodRows = ({PeriodRow period, List<FixedCostRow> costs});

BudgetPeriod periodOf(PeriodRows rows) {
  final period = rows.period;
  final costs = [
    for (final cost in rows.costs)
      FixedCost(name: cost.name, amount: cost.amountPaise),
  ];
  final values = switch (period.kind) {
    fullKind => FullMonthValues(
      salary: period.salaryPaise!,
      target: period.targetPaise,
      fixedCosts: costs,
    ),
    midMonthStartKind => MidMonthStartValues(
      moneyLeft: period.moneyLeftPaise!,
      fixedCostsStillToPay: costs,
    ),
    // The CHECK on `kind` makes any other value impossible.
    _ => throw StateError('unknown period kind'),
  };
  return BudgetPeriod(
    start: period.startDay,
    changedAt: period.changedAt,
    values: values,
    continuedWithShortfall: period.continuedWithShortfall,
  );
}

/// The month rows and everything below them, grouped from the result of one
/// joined query (month, its periods, their fixed costs). Months come back in
/// the order they first appear, periods in id order.
List<StoredMonth> storedMonthsOf(Iterable<TypedResult> rows, AppDatabase db) {
  final months = <int, MonthRow>{};
  final periods = <int, Map<int, PeriodRows>>{};
  for (final row in rows) {
    final month = row.readTable(db.budgetMonths);
    months[month.id] = month;
    final period = row.readTableOrNull(db.budgetPeriods);
    if (period == null) continue;
    final inMonth = periods.putIfAbsent(month.id, () => {});
    final entry = inMonth.putIfAbsent(
      period.id,
      () => (period: period, costs: []),
    );
    final cost = row.readTableOrNull(db.periodFixedCosts);
    if (cost != null) entry.costs.add(cost);
  }
  return [
    for (final month in months.values)
      StoredMonth(
        id: month.id,
        // The salary day and the start give the same month the user saved.
        month: BudgetMonth.containing(month.salaryDay, month.startDay),
        firstBudgetedDay: month.firstBudgetedDay,
        confirmedAt: month.confirmedAt,
        periods: [
          for (final entry in (periods[month.id] ?? const {}).values)
            periodOf(entry),
        ],
      ),
  ];
}

/// The joined select behind every month read: months, their periods and the
/// periods' fixed costs, ordered so [storedMonthsOf] can group the rows.
JoinedSelectStatement<HasResultSet, dynamic> monthsQuery(AppDatabase db) {
  return db.select(db.budgetMonths).join([
    leftOuterJoin(
      db.budgetPeriods,
      db.budgetPeriods.monthId.equalsExp(db.budgetMonths.id),
    ),
    leftOuterJoin(
      db.periodFixedCosts,
      db.periodFixedCosts.periodId.equalsExp(db.budgetPeriods.id),
    ),
  ])..orderBy([
    OrderingTerm.asc(db.budgetMonths.startDay),
    OrderingTerm.asc(db.budgetPeriods.id),
    OrderingTerm.asc(db.periodFixedCosts.position),
  ]);
}

/// Runs [body], turning every storage error into a [StorageException] of
/// [kind]. Invalid input ([ArgumentError]) and programming errors are not
/// storage failures and pass through.
Future<T> guarded<T>(StorageFailureKind kind, Future<T> Function() body) async {
  try {
    return await body();
  } on Exception catch (error) {
    throw StorageException.from(error, kind: kind);
  }
}

/// Maps errors on a read stream to [StorageException] (kind read).
Stream<T> guardedStream<T>(Stream<T> source) => source.transform(
  StreamTransformer.fromHandlers(
    handleError: (error, stackTrace, sink) => sink.addError(
      error is Exception
          ? StorageException.from(error, kind: StorageFailureKind.read)
          : error,
      stackTrace,
    ),
  ),
);
