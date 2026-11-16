import 'dart:io';

import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import 'repository_setup.dart';

/// The day budgets of the stored month, recomputed by the engine.
Future<List<Paise>> budgetsFor(Repos repos, StoredMonth month) async {
  final stored = (await repos.months.watchMonth(month.id).first)!;
  final result = computeMonth(
    MonthInput(
      month: stored.month,
      firstBudgetedDay: stored.firstBudgetedDay,
      periods: stored.periods,
      today: d(2026, 11, 28),
    ),
  );
  return allBudgets(result);
}

void main() {
  final nov20 = d(2026, 11, 20);
  final nov28 = d(2026, 11, 28);

  test('TC-007-26 budget changes only add period rows', () async {
    final repos = openMemoryRepos();
    final month = await repos.months.confirmMonth(e2NewMonth());
    final snapshots = <List<Map<String, Object?>>>[
      await rowSnapshot(repos.db, 'budget_periods'),
    ];
    final itemSnapshots = <List<Map<String, Object?>>>[
      await rowSnapshot(repos.db, 'period_fixed_costs'),
    ];
    await repos.months.addPeriod(
      month.id,
      period(nov20, e2Values(rent: 1300000)),
    );
    snapshots.add(await rowSnapshot(repos.db, 'budget_periods'));
    itemSnapshots.add(await rowSnapshot(repos.db, 'period_fixed_costs'));
    await repos.months.addPeriod(
      month.id,
      period(nov28, e2Values(rent: 1300000, emi: 400000)),
    );
    snapshots.add(await rowSnapshot(repos.db, 'budget_periods'));
    itemSnapshots.add(await rowSnapshot(repos.db, 'period_fixed_costs'));

    // Only inserts: every earlier row is still there, unchanged.
    for (var i = 1; i < snapshots.length; i++) {
      expect(snapshots[i], hasLength(i + 1));
      expect(snapshots[i].take(i).toList(), snapshots[i - 1]);
      expect(itemSnapshots[i], hasLength(3 * (i + 1)));
      expect(itemSnapshots[i].take(3 * i).toList(), itemSnapshots[i - 1]);
    }
    final stored = (await repos.months.watchMonth(month.id).first)!;
    expect(stored.periods, hasLength(3));
    List<(String, int)> costs(BudgetPeriod p) => [
      for (final c in (p.values as FullMonthValues).fixedCosts)
        (c.name, c.amount.value),
    ];
    expect(costs(stored.periods[0]), [
      ('Rent', 1000000),
      ('EMI', 500000),
      ('Subscriptions', 10000),
    ]);
    expect(costs(stored.periods[1]), [
      ('Rent', 1300000),
      ('EMI', 500000),
      ('Subscriptions', 10000),
    ]);
    expect(costs(stored.periods[2]), [
      ('Rent', 1300000),
      ('EMI', 400000),
      ('Subscriptions', 10000),
    ]);
    // The database refuses an update or a delete of history, and the
    // repository code has no such call.
    for (final sql in [
      'UPDATE budget_periods SET salary_paise = 1',
      'DELETE FROM budget_periods',
      'UPDATE period_fixed_costs SET amount_paise = 1',
      'DELETE FROM period_fixed_costs',
    ]) {
      await expectLater(
        repos.db.customStatement(sql),
        throwsA(predicate((e) => e.toString().contains('append-only'))),
      );
    }
    expect(await rowSnapshot(repos.db, 'budget_periods'), snapshots.last);
    for (final path in [
      'lib/data/repositories/month_repository.dart',
      'lib/data/repositories/drift_month_repository.dart',
    ]) {
      final code = File(path).readAsStringSync();
      expect(
        RegExp(r'\.(update|delete)\(').hasMatch(code),
        isFalse,
        reason: path,
      );
      expect(code.contains('Future<void> update'), isFalse, reason: path);
      expect(code.contains('Future<void> delete'), isFalse, reason: path);
    }
  });

  test(
    'TC-007-27 stored periods reproduce the same day budgets after reopen',
    () async {
      final path = '${tempFolder('tc007_27').path}/budget.sqlite';
      var repos = openFileRepos(File(path));
      final month = await repos.months.confirmMonth(e2NewMonth());
      await repos.months.addPeriod(
        month.id,
        period(nov20, e2Values(rent: 1300000)),
      );
      await repos.months.addPeriod(
        month.id,
        period(nov28, e2Values(rent: 1300000, emi: 400000)),
      );
      final before = await budgetsFor(repos, month);
      await repos.db.close();

      repos = openFileRepos(File(path));
      final after = await budgetsFor(repos, month);
      final expected = runs([(15, 83000), (8, 63000), (5, 77286), (2, 77285)]);
      expect(before, expected);
      expect(after, expected);
    },
  );

  test(
    'TC-007-43 same day changes are stored as separate timed periods',
    () async {
      final repos = openMemoryRepos();
      final month = await repos.months.confirmMonth(e2NewMonth());
      await repos.months.addPeriod(
        month.id,
        period(nov20, e2Values(rent: 1300000), changedAt: at(nov20, 10)),
      );
      await repos.months.addPeriod(
        month.id,
        period(nov20, e2Values(rent: 1100000), changedAt: at(nov20, 18)),
      );
      final rows = await repos.db
          .customSelect(
            'SELECT start_day, changed_at FROM budget_periods ORDER BY id',
          )
          .get();
      expect(rows, hasLength(3));
      expect(rows[1].read<int>('start_day'), nov20.dayNumber);
      expect(rows[2].read<int>('start_day'), nov20.dayNumber);
      expect(rows[1].read<int>('changed_at'), at(nov20, 10));
      expect(rows[2].read<int>('changed_at'), at(nov20, 18));

      final stored = (await repos.months.watchMonth(month.id).first)!;
      final result = computeMonth(
        MonthInput(
          month: stored.month,
          firstBudgetedDay: stored.firstBudgetedDay,
          periods: stored.periods,
          today: d(2026, 11, 21),
        ),
      );
      // The 18:00 change is the one in force; the 10:00 one is history only.
      expect(result.periods[1].superseded, isTrue);
      expect(result.periods[2].superseded, isFalse);
      expect(result.currentPeriod.period.changedAt, at(nov20, 18));
      final rent = (result.currentPeriod.period.values as FullMonthValues)
          .fixedCosts
          .first;
      expect(rent.amount, const Paise(1100000));
    },
  );
}
