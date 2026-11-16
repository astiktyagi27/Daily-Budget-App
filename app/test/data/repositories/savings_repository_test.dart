import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import 'repository_setup.dart';

/// Stores the F-006 W2 data (tests/F-006 AC-12): the spends of [w2Spends] and
/// the two covers of [w2Covers] (inserted as rows, so their made times are the
/// spec's, not "now"). Today is 10 Nov.
Future<(Repos, int)> seedW2({List<Spend>? spends}) async {
  final repos = openMemoryRepos();
  final month = await repos.months.confirmMonth(e2NewMonth());
  for (final (i, s) in (spends ?? w2Spends()).indexed) {
    await repos.spends.add(
      month.id,
      (amount: s.amount, date: s.date, note: null),
      today: d(2026, 11, 10),
      now: at(d(2026, 11, 5), 8, i),
    );
  }
  for (final c in w2Covers()) {
    await repos.db
        .into(repos.db.savingsMoves)
        .insert(
          SavingsMovesCompanion.insert(
            monthId: month.id,
            coveredDay: c.day,
            amountPaise: c.amount,
            madeAt: c.madeAt,
          ),
        );
  }
  return (repos, month.id);
}

Future<List<int>> storedCoverAmounts(Repos repos) async {
  final rows = await repos.db
      .customSelect('SELECT amount_paise FROM savings_moves ORDER BY id')
      .get();
  return [for (final row in rows) row.read<int>('amount_paise')];
}

void main() {
  final nov6 = d(2026, 11, 6);
  final nov7 = d(2026, 11, 7);
  final today = d(2026, 11, 10);

  test('TC-007-10 failed edit stores nothing', () async {
    // An edit (a new period with 3 fixed costs) whose 2nd item insert fails:
    // the history is exactly as before.
    final repos = openMemoryRepos();
    final month = await repos.months.confirmMonth(e2NewMonth());
    final periodsBefore = await rowSnapshot(repos.db, 'budget_periods');
    final itemsBefore = await rowSnapshot(repos.db, 'period_fixed_costs');
    await repos.db.customStatement(
      'CREATE TRIGGER fail_second BEFORE INSERT ON period_fixed_costs '
      'WHEN (SELECT count(*) FROM period_fixed_costs) = 4 '
      "BEGIN SELECT RAISE(ABORT, 'forced failure'); END",
    );
    await expectLater(
      repos.months.addPeriod(
        month.id,
        period(d(2026, 11, 20), e2Values(rent: 1300000)),
      ),
      throwsA(isA<StorageException>()),
    );
    expect(await rowSnapshot(repos.db, 'budget_periods'), periodsBefore);
    expect(await rowSnapshot(repos.db, 'period_fixed_costs'), itemsBefore);
    expect(await countRows(repos.db, 'budget_periods'), 1);
  });

  test('TC-007-10 failed cover stores nothing', () async {
    // A cover whose insert aborts: no move, the pot is unchanged.
    final (repos, id) = await seedW2();
    await repos.db.customStatement('DELETE FROM savings_moves');
    final potBefore = computeMonth(await _input(repos, id, today)).totals.pot;
    await repos.db.customStatement(
      'CREATE TRIGGER no_moves AFTER INSERT ON savings_moves '
      "BEGIN SELECT RAISE(ABORT, 'forced failure'); END",
    );
    await expectLater(
      repos.savings.cover(
        id,
        nov6,
        const Paise(17000),
        today: today,
        now: at(today, 9),
      ),
      throwsA(isA<StorageException>()),
    );
    expect(await countRows(repos.db, 'savings_moves'), 0);
    expect(computeMonth(await _input(repos, id, today)).totals.pot, potBefore);
  });

  test('TC-007-46 cover changes are saved with the edit and stay', () async {
    // 1-2. W2 stored; edit 5 Nov 50,000 -> 83,000, then 8 Nov 20,000 -> 83,000.
    final (repos, month) = await seedW2();
    final ids = await _spendIds(repos, month);
    final first = await repos.spends.update(
      ids[d(2026, 11, 5)]!,
      fields(d(2026, 11, 5), 83000),
      today: today,
      now: at(today, 8),
    );
    expect(first.reductions, isEmpty);
    final second = await repos.spends.update(
      ids[d(2026, 11, 8)]!,
      fields(d(2026, 11, 8), 83000),
      today: today,
      now: at(today, 9),
    );
    expect(
      [
        for (final r in second.reductions)
          (r.day, r.oldAmount.value, r.newAmount.value),
      ],
      [(nov7, 17000, 0), (nov6, 17000, 0)],
    );
    expect(await storedCoverAmounts(repos), [0, 0]);
    expect(await countRows(repos.db, 'savings_moves'), 2);

    // 3. 9 Nov 83,000 -> 10,000 grows the pot by 73,000; the covers stay 0.
    await repos.spends.update(
      ids[d(2026, 11, 9)]!,
      fields(d(2026, 11, 9), 10000),
      today: today,
      now: at(today, 10),
    );
    expect(await storedCoverAmounts(repos), [0, 0]);
    expect(
      computeMonth(await _input(repos, month, today)).totals.pot,
      const Paise(73000),
    );
  });

  test(
    'TC-007-46 an edit that lowers an overspend clamps the stored cover',
    () async {
      // 4. W1 with a cover of 17,000 on 6 Nov (spent 1,00,000 of 83,000).
      final w1 = w1Spends();
      final (repos, month) = await seedW2(spends: w1);
      await repos.db.customStatement('DELETE FROM savings_moves');
      await repos.db
          .into(repos.db.savingsMoves)
          .insert(
            SavingsMovesCompanion.insert(
              monthId: month,
              coveredDay: nov6,
              amountPaise: const Paise(17000),
              madeAt: at(d(2026, 11, 8), 21),
            ),
          );
      final ids = await _spendIds(repos, month);
      final outcome = await repos.spends.update(
        ids[nov6]!,
        fields(nov6, 90000),
        today: d(2026, 11, 8),
        now: at(today, 8),
      );
      expect(outcome.reductions, isEmpty, reason: 'a clamp is not a reduction');
      expect(await storedCoverAmounts(repos), [7000]);
    },
  );

  test(
    'TC-007-46 a failed cover update stores neither spend nor covers',
    () async {
      // 5. Step 1 again with the cover update forced to fail.
      final (repos, month) = await seedW2();
      final ids = await _spendIds(repos, month);
      await repos.spends.update(
        ids[d(2026, 11, 5)]!,
        fields(d(2026, 11, 5), 83000),
        today: today,
        now: at(today, 8),
      );
      final spendsBefore = await rowSnapshot(repos.db, 'transactions');
      final movesBefore = await rowSnapshot(repos.db, 'savings_moves');
      await repos.db.customStatement(
        'CREATE TRIGGER no_cover_updates BEFORE UPDATE ON savings_moves '
        "BEGIN SELECT RAISE(ABORT, 'forced failure'); END",
      );
      await expectLater(
        repos.spends.update(
          ids[d(2026, 11, 8)]!,
          fields(d(2026, 11, 8), 83000),
          today: today,
          now: at(today, 9),
        ),
        throwsA(isA<StorageException>()),
      );
      expect(await rowSnapshot(repos.db, 'transactions'), spendsBefore);
      expect(await rowSnapshot(repos.db, 'savings_moves'), movesBefore);
      expect(await storedCoverAmounts(repos), [17000, 17000]);
    },
  );
}

Future<MonthInput> _input(Repos repos, int month, CalendarDate today) async {
  final stored = (await repos.months.watchMonth(month).first)!;
  return MonthInput(
    month: stored.month,
    firstBudgetedDay: stored.firstBudgetedDay,
    periods: stored.periods,
    today: today,
    spends: [
      for (final s in await repos.spends.watchMonthSpends(month).first) s.spend,
    ],
    covers: await repos.savings.watchCovers(month).first,
  );
}

Future<Map<CalendarDate, int>> _spendIds(Repos repos, int month) async => {
  for (final s in await repos.spends.watchMonthSpends(month).first)
    s.spend.date: s.spend.id,
};
