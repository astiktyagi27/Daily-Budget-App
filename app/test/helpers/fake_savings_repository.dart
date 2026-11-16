import 'package:daily_budget/data/repositories/savings_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';

import 'fake_money_store.dart';

/// In-memory [SavingsRepository] for widget tests (F-007 plan 2).
final class FakeSavingsRepository implements SavingsRepository {
  const new(this.store);

  final FakeMoneyStore store;

  @override
  Stream<List<Cover>> watchCovers(int monthId) => store.watch(() {
    return [...store.coversByMonth[monthId] ?? <Cover>[]]..sort((a, b) {
      final byTime = a.madeAt.compareTo(b.madeAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
  });

  @override
  Future<CoverDecision> cover(
    int monthId,
    CalendarDate day,
    Paise amount, {
    required CalendarDate today,
    required int now,
  }) async {
    store.checkWrite();
    final result = computeMonth(store.inputFor(monthId, today));
    final decision = checkCover(result, day, amount);
    if (decision is CoverAllowed) {
      store.coversByMonth
          .putIfAbsent(monthId, () => [])
          .add(
            Cover(id: store.nextId(), day: day, amount: amount, madeAt: now),
          );
      store.notify();
    }
    return decision;
  }
}
