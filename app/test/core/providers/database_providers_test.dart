import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../data/repositories/repository_setup.dart' show e2NewMonth;
import '../../domain/budget/fixtures.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/fake_month_repository.dart';
import '../../helpers/fake_savings_repository.dart';
import '../../helpers/fake_transaction_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final today = d(2026, 11, 10);

  ProviderContainer containerOn(FakeMoneyStore store) {
    final container = ProviderContainer(
      overrides: [
        monthRepositoryProvider.overrideWithValue(FakeMonthRepository(store)),
        transactionRepositoryProvider.overrideWithValue(
          FakeTransactionRepository(store),
        ),
        savingsRepositoryProvider.overrideWithValue(
          FakeSavingsRepository(store),
        ),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 10, 9)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('TC-007-12 month result provider updates live from the fakes', () async {
    final store = FakeMoneyStore();
    final container = containerOn(store);
    final month = await FakeMonthRepository(store).confirmMonth(e2NewMonth());
    final results = <MonthResult?>[];
    container.listen(
      monthResultProvider(month.id),
      (previous, next) => results.add(next.value),
      fireImmediately: true,
    );
    await pumpEventQueue();
    expect(results.last?.dayOn(today).budget, const Paise(83000));

    // A spend on today changes the live day result at once.
    await FakeTransactionRepository(store).add(
      month.id,
      (
        amount: const Paise(25000),
        date: today,
        note: 'Lunch',
        category: null,
        direction: SpendDirection.spend,
      ),
      today: today,
      now: at(today, 9),
    );
    await pumpEventQueue();
    expect(results.last?.dayOn(today).result, const Paise(58000));

    // A new period re-spreads the remaining days.
    await FakeMonthRepository(store)
        .addPeriod(month.id, period(today, e2Values(rent: 1300000)));
    await pumpEventQueue();
    expect(results.last?.periods, hasLength(2));
  });

  test('TC-007-12 month input provider is null for an unknown month', () async {
    final container = containerOn(FakeMoneyStore())
      ..listen(monthInputProvider(99), (_, _) {});
    await pumpEventQueue();
    expect(container.read(monthInputProvider(99)).value, isNull);
    expect(container.read(monthResultProvider(99)).value, isNull);
  });

  test(
    'TC-007-40 a read failure reaches the provider as a storage error',
    () async {
      final store = FakeMoneyStore();
      final container = containerOn(store);
      final month = await FakeMonthRepository(store).confirmMonth(e2NewMonth());
      store.readFails = true;
      container.listen(monthInputProvider(month.id), (_, _) {});
      await pumpEventQueue();
      final state = container.read(monthInputProvider(month.id));
      expect(state.hasError, isTrue);
      expect(
        state.error,
        isA<StorageException>().having(
          (e) => e.kind,
          'kind',
          StorageFailureKind.read,
        ),
      );
    },
  );

  test(
    'TC-007-46 the fakes reconcile covers like the real repository',
    () async {
      final store = FakeMoneyStore();
      final months = FakeMonthRepository(store);
      final spends = FakeTransactionRepository(store);
      final month = await months.confirmMonth(e2NewMonth());
      final ids = <CalendarDate, int>{};
      for (final (i, s) in w2Spends().indexed) {
        final outcome = await spends.add(
          month.id,
          (
            amount: s.amount,
            date: s.date,
            note: null,
            category: null,
            direction: SpendDirection.spend,
          ),
          today: today,
          now: at(d(2026, 11, 5), 8, i),
        );
        ids[s.date] = outcome.id;
      }
      store.coversByMonth[month.id] = w2Covers();
      await spends.update(
        ids[d(2026, 11, 5)]!,
        (
          amount: const Paise(83000),
          date: d(2026, 11, 5),
          note: null,
          category: null,
          direction: SpendDirection.spend,
        ),
        today: today,
        now: at(today, 8),
      );
      final outcome = await spends.update(
        ids[d(2026, 11, 8)]!,
        (
          amount: const Paise(83000),
          date: d(2026, 11, 8),
          note: null,
          category: null,
          direction: SpendDirection.spend,
        ),
        today: today,
        now: at(today, 9),
      );
      expect(
        [
          for (final r in outcome.reductions)
            (r.day, r.oldAmount.value, r.newAmount.value),
        ],
        [(d(2026, 11, 7), 17000, 0), (d(2026, 11, 6), 17000, 0)],
      );
      expect(store.coversByMonth[month.id]!.map((c) => c.amount.value), [0, 0]);
    },
  );

  test(
    'TC-007-18 fake writes fail once on request and store nothing',
    () async {
      final store = FakeMoneyStore();
      final months = FakeMonthRepository(store);
      store.failNextWrite = true;
      await expectLater(
        months.confirmMonth(e2NewMonth()),
        throwsA(isA<StorageException>()),
      );
      expect(store.months, isEmpty);
      // The flag is used up: the next write works.
      await months.confirmMonth(e2NewMonth());
      expect(store.months, hasLength(1));
    },
  );
}
