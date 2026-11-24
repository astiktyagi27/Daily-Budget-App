import 'dart:math';

import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_money_store.dart';
import '../../helpers/fake_savings_repository.dart';
import '../../helpers/fake_transaction_repository.dart';
import 'fixtures.dart';

// TC-012-56: through the fake repositories (which use the engine and the same
// cover reconciliation as Drift) the pot is never negative and a cover never
// moves more than the pot or the day's overspend.

/// The amounts of the grid (paise): 0.01, 1, 47.78, 100, 250, 300, 1,000 and
/// 10,00,000 rupees.
const _grid = [1, 100, 4778, 10000, 25000, 30000, 100000, 100000000];

FakeMoneyStore _store({required bool shortfall}) {
  final store = FakeMoneyStore();
  final first = d(2026, 11, 5);
  store.months.add(
    StoredMonth(
      id: store.nextId(),
      month: nov2026,
      firstBudgetedDay: first,
      confirmedAt: at(first, 8),
      periods: [
        if (shortfall)
          period(first, s1Values(), continued: true)
        else
          period(first, e2Values()),
      ],
    ),
  );
  return store;
}

void main() {
  test(
    'TC-012-56 pot never negative and cover never above pot or overspend',
    () async {
      final random = Random(propertySeed);
      for (var sequence = 0; sequence < 300; sequence++) {
        final shortfall = random.nextBool();
        final store = _store(shortfall: shortfall);
        final monthId = store.months.single.id;
        final spends = FakeTransactionRepository(store);
        final savings = FakeSavingsRepository(store);
        final today = d(2026, 11, 7 + random.nextInt(6));
        final steps = <String>[];
        var clock = 1;
        CalendarDate anyDay() => d(2026, 11, 5 + random.nextInt(today.day - 4));
        String why() =>
            'seed $propertySeed, sequence $sequence, '
            '${shortfall ? 'S1' : 'E2'}, today ${today.iso}: $steps';

        MonthResult result() => computeMonth(store.inputFor(monthId, today));

        void checkInvariants() {
          final r = result();
          expect(r.totals.pot.isNegative, isFalse, reason: why());
          expect(
            Paise.sum(r.effectiveCovers.map((c) => c.amount)).value,
            lessThanOrEqualTo(r.totals.saved.value),
            reason: why(),
          );
          for (final day in r.days) {
            if (day.result == null) continue;
            final grossOverspend = (day.netSpent - day.budget!).orZero;
            expect(
              day.covered.value,
              lessThanOrEqualTo(grossOverspend.value),
              reason: '${day.date.iso} ${why()}',
            );
          }
          // Stored covers are what the engine says they move (the fakes store
          // the reconciled amounts).
          expect(
            [
              for (final c in store.coversByMonth[monthId] ?? <Cover>[])
                c.amount,
            ],
            [for (final c in r.effectiveCovers) c.amount],
            reason: why(),
          );
          expectPeriodsAddUp(r);
        }

        for (var step = 0; step < 14; step++) {
          final stored = store.spendsByMonth[monthId] ?? <StoredSpend>[];
          final kind = random.nextInt(5);
          if (kind == 0 || (stored.isEmpty && kind < 3)) {
            final day = anyDay();
            final amount = _grid[random.nextInt(_grid.length)];
            final moneyIn = random.nextInt(5) == 0;
            steps.add('add ${day.iso} $amount${moneyIn ? ' in' : ''}');
            await spends.add(
              monthId,
              (
                amount: Paise(amount),
                date: day,
                note: null,
                category: null,
                direction: moneyIn
                    ? SpendDirection.moneyIn
                    : SpendDirection.spend,
              ),
              today: today,
              now: clock++,
            );
          } else if (kind == 1) {
            final target = stored[random.nextInt(stored.length)].spend;
            final amount = _grid[random.nextInt(_grid.length)];
            steps.add('edit ${target.id} $amount');
            await spends.update(
              target.id,
              (
                amount: Paise(amount),
                date: target.date,
                note: null,
                category: null,
                direction: SpendDirection.spend,
              ),
              today: today,
              now: clock++,
            );
          } else if (kind == 2) {
            final target = stored[random.nextInt(stored.length)].spend;
            steps.add('delete ${target.id}');
            await spends.delete(target.id, today: today);
          } else {
            final day = anyDay();
            final amount = _grid[random.nextInt(_grid.length)];
            steps.add('cover ${day.iso} $amount');
            final before = result();
            final uncovered = (-before.dayOn(day).result!).orZero;
            final pot = before.totals.pot;
            final attempt = await savings.cover(
              monthId,
              day,
              Paise(amount),
              today: today,
              now: clock++,
            );
            if (attempt.decision is CoverAllowed) {
              expect(attempt.coverId, isNotNull, reason: why());
              expect(
                amount,
                lessThanOrEqualTo(uncovered.atMost(pot).value),
                reason: why(),
              );
            } else {
              expect(attempt.coverId, isNull, reason: why());
              expect(dump(result()), dump(before), reason: why());
            }
          }
          checkInvariants();
        }
      }
    },
  );
}
