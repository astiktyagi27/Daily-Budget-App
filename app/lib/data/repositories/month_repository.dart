import 'package:daily_budget/domain/budget/budget.dart';

/// A confirmed budget month with every period ever saved for it (D-037).
final class StoredMonth {
  const new({
    required this.id,
    required this.month,
    required this.firstBudgetedDay,
    required this.confirmedAt,
    required this.periods,
  });

  final int id;

  final BudgetMonth month;

  /// The month's start, or the setup day of a mid-month start (D-034, D-057).
  final CalendarDate firstBudgetedDay;

  /// When the month was confirmed (UTC milliseconds since 1970).
  final int confirmedAt;

  /// Every period, oldest saved first. Never edited or removed.
  final List<BudgetPeriod> periods;
}

/// What F-008 saves when the user confirms a month: the month and its first
/// period with that period's fixed costs, as one unit (F-007 AC-4).
final class NewMonth {
  const new({
    required this.month,
    required this.firstBudgetedDay,
    required this.firstPeriod,
    required this.confirmedAt,
  });

  final BudgetMonth month;

  final CalendarDate firstBudgetedDay;

  final BudgetPeriod firstPeriod;

  /// UTC milliseconds since 1970, from the caller's clock.
  final int confirmedAt;
}

/// Budget months and their append-only period history (F-007 plan 2).
///
/// Every failure of the storage is a `StorageException`; input the screens
/// never send (a month without a salary, a name of 0 or 41 characters) is an
/// [ArgumentError], as in the engine (F-006 section 2.9).
abstract interface class MonthRepository {
  /// The month that contains [today], or null when there is none. Emits again
  /// whenever a month, period or fixed cost changes.
  Stream<StoredMonth?> watchCurrentMonth(CalendarDate today);

  /// The month with the latest start, or null before the first setup.
  Stream<StoredMonth?> watchLatestMonth();

  /// One month by id, or null if it does not exist.
  Stream<StoredMonth?> watchMonth(int monthId);

  Future<StoredMonth?> latestConfirmedMonth();

  /// Saves the month, its first period and the period's fixed costs in one
  /// transaction: all or nothing.
  Future<StoredMonth> confirmMonth(NewMonth month);

  /// Adds [period] to the month's history, with its own copy of the fixed
  /// costs, in one transaction. Existing periods are never touched.
  Future<void> addPeriod(int monthId, BudgetPeriod period);
}
