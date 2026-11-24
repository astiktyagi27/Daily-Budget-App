// Phase 3 data seeding for the fake repositories (plan T-308). The data sets
// themselves are in `phase3_fixtures.dart`; this file puts them into a
// `FakeMoneyStore` and gives the screens a matching clock.

import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';

import '../domain/budget/fixtures.dart' show at;
import 'fake_money_store.dart';
import 'phase3_fixtures.dart';
import 'setup_harness.dart';

/// Adds every month of [fixture] to [store], oldest stored first, with its
/// entries and covers, and returns the stored months in that order. A
/// fixture entry's category key is carried on the spend (F-013 T-380).
List<StoredMonth> seedFixture(FakeMoneyStore store, Phase3Fixture fixture) {
  final stored = <StoredMonth>[];
  for (final month in fixture.months) {
    final storedMonth = StoredMonth(
      id: store.nextId(),
      month: month.month,
      firstBudgetedDay: month.firstBudgetedDay,
      confirmedAt: at(month.firstBudgetedDay, 8),
      periods: month.periods,
    );
    store.months.add(storedMonth);
    stored.add(storedMonth);
    for (final entry in month.entries) {
      store.spendsByMonth
          .putIfAbsent(storedMonth.id, () => [])
          .add(
            StoredSpend(spend: entry.toSpend(store.nextId()), note: entry.note),
          );
    }
    for (final cover in month.covers) {
      store.coversByMonth
          .putIfAbsent(storedMonth.id, () => [])
          .add(
            Cover(
              id: store.nextId(),
              day: cover.day,
              amount: Paise(cover.paise),
              madeAt: cover.madeAt,
            ),
          );
    }
  }
  return stored;
}

/// A new store holding [fixture].
FakeMoneyStore storeFor(Phase3Fixture fixture) {
  final store = FakeMoneyStore();
  seedFixture(store, fixture);
  return store;
}

/// A clock a test can move, set to the fixture's device date.
MovableClock clockFor(Phase3Fixture fixture) => MovableClock(fixture.today);

/// Example A (F-010 section 2.4) in [store].
void seedExampleA(FakeMoneyStore store) => seedFixture(store, fixtureA);

/// Example M (canonical M20, Today(20 Nov)) in [store].
void seedExampleM(FakeMoneyStore store) => seedFixture(store, m20);

/// Example F (F-010 section 2.7, first use 10 Nov) in [store].
void seedExampleF(FakeMoneyStore store) => seedFixture(store, f12);
