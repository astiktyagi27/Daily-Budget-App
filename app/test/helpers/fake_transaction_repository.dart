import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';

import 'fake_money_store.dart';

/// In-memory [TransactionRepository] for widget tests (F-007 plan 2). Lists
/// come back in the real order: newest day, newest created, highest id.
final class FakeTransactionRepository implements TransactionRepository {
  const new(this.store);

  final FakeMoneyStore store;

  List<StoredSpend> _sorted(int monthId) {
    return [...store.spendsByMonth[monthId] ?? <StoredSpend>[]]..sort((a, b) {
      final byDay = b.spend.date.compareTo(a.spend.date);
      if (byDay != 0) return byDay;
      final byCreated = b.spend.createdAt.compareTo(a.spend.createdAt);
      return byCreated != 0 ? byCreated : b.spend.id.compareTo(a.spend.id);
    });
  }

  @override
  Stream<List<StoredSpend>> watchMonthSpends(int monthId) =>
      store.watch(() => _sorted(monthId));

  @override
  Future<SpendWriteOutcome> add(
    int monthId,
    SpendFields fields, {
    required CalendarDate today,
    required int now,
    SpendDirection direction = SpendDirection.spend,
  }) async {
    _validate(fields);
    store.checkWrite();
    final id = store.nextId();
    store.spendsByMonth
        .putIfAbsent(monthId, () => [])
        .add(
          StoredSpend(
            spend: Spend(
              id: id,
              date: fields.date,
              amount: fields.amount,
              createdAt: now,
              direction: direction,
            ),
            note: fields.note,
          ),
        );
    return _finish(id, monthId, today);
  }

  @override
  Future<SpendWriteOutcome> update(
    int id,
    SpendFields fields, {
    required CalendarDate today,
    required int now,
  }) async {
    _validate(fields);
    store.checkWrite();
    final (monthId, index) = _find(id);
    final old = store.spendsByMonth[monthId]![index].spend;
    store.spendsByMonth[monthId]![index] = StoredSpend(
      spend: Spend(
        id: id,
        date: fields.date,
        amount: fields.amount,
        createdAt: old.createdAt,
        direction: old.direction,
      ),
      note: fields.note,
    );
    return _finish(id, monthId, today);
  }

  @override
  Future<SpendWriteOutcome> delete(
    int id, {
    required CalendarDate today,
  }) async {
    store.checkWrite();
    final (monthId, index) = _find(id);
    store.spendsByMonth[monthId]!.removeAt(index);
    return _finish(id, monthId, today);
  }

  SpendWriteOutcome _finish(int id, int monthId, CalendarDate today) {
    final reductions = store.reconcile(monthId, today);
    store.notify();
    return SpendWriteOutcome(id: id, reductions: reductions);
  }

  (int, int) _find(int id) {
    for (final MapEntry(:key, :value) in store.spendsByMonth.entries) {
      final index = value.indexWhere((s) => s.spend.id == id);
      if (index >= 0) return (key, index);
    }
    throw ArgumentError.value(id, 'id', 'is not a stored transaction');
  }

  void _validate(SpendFields fields) {
    if (!fields.amount.isPositive) {
      throw ArgumentError.value(
        fields.amount.value,
        'amount',
        'must be above 0',
      );
    }
  }
}
