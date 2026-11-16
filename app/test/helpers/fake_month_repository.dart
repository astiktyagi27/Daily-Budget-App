import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';

import 'fake_money_store.dart';

/// In-memory [MonthRepository] for widget tests (F-007 plan 2).
final class FakeMonthRepository implements MonthRepository {
  const new(this.store);

  final FakeMoneyStore store;

  @override
  Stream<StoredMonth?> watchCurrentMonth(CalendarDate today) => store.watch(
    () => store.months.where((m) => m.month.contains(today)).firstOrNull,
  );

  @override
  Stream<StoredMonth?> watchLatestMonth() => store.watch(
    () => ([
      ...store.months,
    ]..sort((a, b) => a.month.start.compareTo(b.month.start))).lastOrNull,
  );

  @override
  Stream<StoredMonth?> watchMonth(int monthId) =>
      store.watch(() => store.monthById(monthId));

  @override
  Future<StoredMonth?> latestConfirmedMonth() => watchLatestMonth().first;

  @override
  Future<StoredMonth> confirmMonth(NewMonth month) async {
    month.firstPeriod.values.validate();
    store.checkWrite();
    final stored = StoredMonth(
      id: store.nextId(),
      month: month.month,
      firstBudgetedDay: month.firstBudgetedDay,
      confirmedAt: month.confirmedAt,
      periods: [month.firstPeriod],
    );
    store.months.add(stored);
    store.notify();
    return stored;
  }

  @override
  Future<void> addPeriod(int monthId, BudgetPeriod period) async {
    period.values.validate();
    store.checkWrite();
    final index = store.months.indexWhere((m) => m.id == monthId);
    final old = store.months[index];
    store.months[index] = StoredMonth(
      id: old.id,
      month: old.month,
      firstBudgetedDay: old.firstBudgetedDay,
      confirmedAt: old.confirmedAt,
      periods: [...old.periods, period],
    );
    store.notify();
  }
}
