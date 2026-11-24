import 'dart:io';

import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import 'repository_setup.dart';

void main() {
  final today = d(2026, 11, 10);

  test(
    'TC-007-01 month costs spends and moves survive a database reopen',
    () async {
      final path = '${tempFolder('tc007_01').path}/budget.sqlite';
      var repos = openFileRepos(File(path));
      final stored = await repos.months.confirmMonth(e2NewMonth());
      final id = stored.id;
      // Seed T5, added oldest first so created times increase.
      final adds = <(CalendarDate, int, String?)>[
        (d(2026, 11, 9), 25000, 'Lunch'),
        (d(2026, 11, 9), 40000, 'Groceries'),
        (d(2026, 11, 8), 31000, null),
        (d(2026, 11, 6), 100000, 'रिक्शा 🛺'),
        (d(2026, 11, 5), 1, 'Tea'),
      ];
      for (final (i, (date, amount, note)) in adds.indexed) {
        await repos.spends.add(
          id,
          fields(date, amount, note),
          today: today,
          now: at(today, 8, i),
        );
      }
      final decision = await repos.savings.cover(
        id,
        d(2026, 11, 6),
        const Paise(17000),
        today: today,
        now: at(today, 9),
      );
      expect(decision.decision, isA<CoverAllowed>());
      expect(decision.coverId, isNotNull);
      await repos.db.close();

      // Restart (sim, DB): a new database object on the same file.
      repos = openFileRepos(File(path));
      final month = (await repos.months.latestConfirmedMonth())!;
      expect(month.id, id);
      expect(month.month.start, d(2026, 11, 5));
      expect(month.month.end, d(2026, 12, 4));
      expect(month.month.salaryDay, 5);
      expect(month.firstBudgetedDay, d(2026, 11, 5));
      expect(month.confirmedAt, at(d(2026, 11, 5), 8));
      expect(month.periods, hasLength(1));
      final values = month.periods.single.values as FullMonthValues;
      expect(values.salary, const Paise(4000000));
      expect(values.target, isNull);
      expect(
        [for (final c in values.fixedCosts) (c.name, c.amount.value)],
        [('Rent', 1000000), ('EMI', 500000), ('Subscriptions', 10000)],
      );
      final spends = await repos.spends.watchMonthSpends(id).first;
      expect(
        [
          for (final s in spends)
            (s.spend.date.iso, s.spend.amount.value, s.note),
        ],
        [
          ('2026-11-09', 40000, 'Groceries'),
          ('2026-11-09', 25000, 'Lunch'),
          ('2026-11-08', 31000, null),
          ('2026-11-06', 100000, 'रिक्शा 🛺'),
          ('2026-11-05', 1, 'Tea'),
        ],
      );
      final covers = await repos.savings.watchCovers(id).first;
      expect(
        [for (final c in covers) (c.day.iso, c.amount.value)],
        [('2026-11-06', 17000)],
      );
    },
  );

  test('TC-007-09 failed month save stores nothing', () async {
    final repos = openMemoryRepos();
    // Test-only trigger: the 3rd fixed-cost insert of the save aborts.
    await repos.db.customStatement(
      'CREATE TRIGGER fail_third BEFORE INSERT ON period_fixed_costs '
      'WHEN (SELECT count(*) FROM period_fixed_costs) = 2 '
      "BEGIN SELECT RAISE(ABORT, 'forced failure'); END",
    );
    final fourCosts = FullMonthValues(
      salary: const Paise(4000000),
      fixedCosts: [
        for (final name in ['Rent', 'EMI', 'Phone', 'Gym'])
          FixedCost(name: name, amount: const Paise(1000)),
      ],
    );
    await expectLater(
      repos.months.confirmMonth(e2NewMonth(values: fourCosts)),
      throwsA(
        isA<StorageException>().having(
          (e) => e.kind,
          'kind',
          StorageFailureKind.write,
        ),
      ),
    );
    expect(await countRows(repos.db, 'budget_months'), 0);
    expect(await countRows(repos.db, 'budget_periods'), 0);
    expect(await countRows(repos.db, 'period_fixed_costs'), 0);
  });

  test('TC-007-12 month and savings listeners update live', () async {
    final repos = openMemoryRepos();
    final current = Collected(repos.months.watchCurrentMonth(today));
    await pumpEventQueue();
    expect(current.values, [isNull]);

    final stored = await repos.months.confirmMonth(e2NewMonth());
    await pumpEventQueue();
    final moves = Collected(repos.savings.watchCovers(stored.id));
    await pumpEventQueue();
    expect(current.values, hasLength(2));
    expect(current.values.last!.periods, hasLength(1));
    expect(moves.values, [isEmpty]);

    await repos.months.addPeriod(
      stored.id,
      period(d(2026, 11, 20), e2Values(rent: 1300000)),
    );
    await pumpEventQueue();
    expect(current.values, hasLength(3));
    expect(current.values.last!.periods, hasLength(2));

    // A spend of 1,00,000 on 6 Nov makes that day overspent by 17,000, and a
    // cover of 17,000 is allowed because 5 Nov saved 83,000.
    await repos.spends.add(
      stored.id,
      fields(d(2026, 11, 6), 100000),
      today: today,
      now: at(today, 8),
    );
    final decision = await repos.savings.cover(
      stored.id,
      d(2026, 11, 6),
      const Paise(17000),
      today: today,
      now: at(today, 9),
    );
    expect(decision.decision, isA<CoverAllowed>());
    expect(decision.coverId, isNotNull);
    await pumpEventQueue();
    expect(moves.values, hasLength(2));
    expect(moves.values.last.single.amount, const Paise(17000));
    // A refused cover stores nothing and does not notify.
    final refused = await repos.savings.cover(
      stored.id,
      d(2026, 11, 7),
      const Paise(1),
      today: today,
      now: at(today, 10),
    );
    expect(refused.decision, isA<CoverRefused>());
    expect(refused.coverId, isNull);
    await pumpEventQueue();
    expect(moves.values, hasLength(2));
    expect(current.errors, isEmpty);
  });

  test('TC-007-28 mid month start and shortfall flag survive reopen', () async {
    final path = '${tempFolder('tc007_28').path}/budget.sqlite';
    var repos = openFileRepos(File(path));
    // (a) First setup on 10 Nov 2026 with money left 24,90,000, no costs.
    final midMonth = await repos.months.confirmMonth(
      NewMonth(
        month: nov2026,
        firstBudgetedDay: today,
        firstPeriod: period(
          today,
          const MidMonthStartValues(moneyLeft: Paise(2490000)),
        ),
        confirmedAt: at(today, 8),
      ),
    );
    // (b) The S1 month continued with a 1,00,000 shortfall (D-036).
    final shortfall = await repos.months.confirmMonth(
      NewMonth(
        month: oct2026,
        firstBudgetedDay: oct2026.start,
        firstPeriod: period(oct2026.start, s1Values(), continued: true),
        confirmedAt: at(oct2026.start, 8),
      ),
    );
    await repos.db.close();

    repos = openFileRepos(File(path));
    final a = (await repos.months.watchMonth(midMonth.id).first)!;
    expect(a.firstBudgetedDay, today);
    expect(a.periods.single.continuedWithShortfall, isFalse);
    final aValues = a.periods.single.values as MidMonthStartValues;
    expect(aValues.moneyLeft, const Paise(2490000));
    expect(aValues.fixedCostsStillToPay, isEmpty);
    final rawA = await repos.db
        .customSelect(
          'SELECT kind, salary_paise, money_left_paise, shortfall_paise '
          'FROM budget_periods WHERE month_id = ${midMonth.id}',
        )
        .getSingle();
    expect(rawA.read<String>('kind'), 'midMonthStart');
    expect(rawA.data['salary_paise'], isNull);
    expect(rawA.read<int>('money_left_paise'), 2490000);

    final b = (await repos.months.watchMonth(shortfall.id).first)!;
    expect(b.periods.single.continuedWithShortfall, isTrue);
    final rawB = await repos.db
        .customSelect(
          'SELECT continued_with_shortfall, shortfall_paise '
          'FROM budget_periods WHERE month_id = ${shortfall.id}',
        )
        .getSingle();
    expect(rawB.read<int>('continued_with_shortfall'), 1);
    expect(rawB.read<int>('shortfall_paise'), 100000);
    // The engine, fed from the stored month, reports the same shortfall.
    final result = computeMonth(
      MonthInput(
        month: b.month,
        firstBudgetedDay: b.firstBudgetedDay,
        periods: b.periods,
        today: d(2026, 10, 10),
      ),
    );
    expect(result.totals.shortfall, const Paise(100000));
  });

  test(
    'TC-007-42 invalid months are refused before anything is stored',
    () async {
      final repos = openMemoryRepos();
      expect(
        () => repos.months.confirmMonth(
          e2NewMonth(
            values: const FullMonthValues(
              salary: Paise(4000000),
              fixedCosts: [FixedCost(name: 'Rent', amount: Paise(-1))],
            ),
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => repos.months.confirmMonth(
          e2NewMonth(
            values: const FullMonthValues(
              salary: Paise(4000000),
              fixedCosts: [FixedCost(name: '', amount: Paise(1))],
            ),
          ),
        ),
        throwsArgumentError,
      );
      // A fixed cost of ₹0 is allowed.
      await repos.months.confirmMonth(
        e2NewMonth(
          values: const FullMonthValues(
            salary: Paise(4000000),
            fixedCosts: [FixedCost(name: 'Gift', amount: Paise.zero)],
          ),
        ),
      );
      expect(await countRows(repos.db, 'budget_months'), 1);
      // The same month cannot be confirmed twice.
      await expectLater(
        repos.months.confirmMonth(e2NewMonth()),
        throwsA(isA<StorageException>()),
      );
      expect(await countRows(repos.db, 'budget_months'), 1);
    },
  );
}
