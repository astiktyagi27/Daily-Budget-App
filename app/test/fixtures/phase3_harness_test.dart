// Checks of the Phase 3 harness additions (plan T-308): the seeding helpers,
// `addMoneyInTo`, `FakeMoneyStore.readDelay` and `readFailsFor`.

import 'dart:async';

import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/budget/fixtures.dart';
import '../helpers/fake_money_store.dart';
import '../helpers/fake_month_repository.dart';
import '../helpers/fake_transaction_repository.dart';
import '../helpers/phase3_data.dart';
import '../helpers/phase3_fixtures.dart';
import '../helpers/setup_harness.dart';
import '../helpers/transactions_harness.dart';

void main() {
  test('TC-010-25 addMoneyInTo stores money in beside spends', () {
    final store = storeFor(fixtureA);
    addMoneyInTo(store, d(2026, 11, 13), 50000, note: 'Amazon return');
    final stored = storedSpends(store);
    final refund = stored.last;
    expect(refund.spend.direction, SpendDirection.moneyIn);
    expect(refund.spend.amount, const Paise(50000));
    expect(refund.note, 'Amazon return');
    expect(stored.first.spend.direction, SpendDirection.spend);
    expect(
      storedResult(store, d(2026, 11, 13)).totals.spentSoFar,
      const Paise(503000),
    );
  });

  test('TC-010-03 seed helpers store each example with distinct ids', () {
    final a = FakeMoneyStore();
    seedExampleA(a);
    final ids = [for (final s in storedSpends(a)) s.spend.id];
    expect(ids.toSet(), hasLength(9));
    expect(storedResult(a, d(2026, 11, 13)).totals.left, const Paise(1937000));

    final m = FakeMoneyStore();
    seedExampleM(m);
    expect(m.months.single.periods, hasLength(2));
    expect(storedResult(m, d(2026, 11, 20)).totals.left, const Paise(690000));

    final f = FakeMoneyStore();
    seedExampleF(f);
    expect(f.months.single.firstBudgetedDay, d(2026, 11, 10));
  });

  test('TC-011-25 a stored cover and two months seed in order', () {
    final store = storeFor(octNov);
    expect(store.months.map((m) => m.month.start), [
      d(2026, 10, 5),
      d(2026, 11, 5),
    ]);
    final withCover = storeFor(fixtureAPlusCover);
    expect(withCover.coversByMonth[withCover.months.single.id], hasLength(1));
  });

  test('TC-010-37 readDelay holds the first read until released', () async {
    final store = storeFor(fixtureA);
    final gate = store.readDelay = Completer<void>();
    final repo = FakeMonthRepository(store);
    final emissions = <Object?>[];
    final sub = repo.watchMonthIndex().listen(emissions.add);
    addTearDown(sub.cancel);

    await pumpEventQueue();
    expect(emissions, isEmpty, reason: 'held');
    gate.complete();
    await pumpEventQueue();
    expect(emissions, hasLength(1));
  });

  test('TC-011-50 readFailsFor fails one month and not the others', () async {
    final store = storeFor(octNov);
    final october = store.months.first.id;
    final november = store.months.last.id;
    final months = FakeMonthRepository(store);
    final spends = FakeTransactionRepository(store);
    store.readFailsFor(october);

    await expectLater(
      months.watchMonth(october),
      emitsError(isA<StorageException>()),
    );
    await expectLater(
      spends.watchMonthSpends(october),
      emitsError(isA<StorageException>()),
    );
    expect((await months.watchMonth(november).first)!.id, november);
    expect(await months.watchMonthIndex().first, hasLength(2));

    store.readFailsFor(october, fails: false);
    expect((await months.watchMonth(october).first)!.id, october);
  });

  test('TC-011-49 delayReadsOf holds one month only', () async {
    final store = storeFor(octNov);
    final october = store.months.first.id;
    final gate = store.delayReadsOf(october);
    final months = FakeMonthRepository(store);
    final got = <int>[];
    final sub = months.watchMonth(october).listen((m) => got.add(m!.id));
    addTearDown(sub.cancel);

    expect(
      (await months.watchMonth(store.months.last.id).first)!.id,
      isNot(october),
    );
    await pumpEventQueue();
    expect(got, isEmpty);
    gate.complete();
    await pumpEventQueue();
    expect(got, [october]);
  });
}
