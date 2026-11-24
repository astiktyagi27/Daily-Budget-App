import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/drift_fixture_seed.dart';
import '../../helpers/phase3_fixtures.dart';
import 'repository_setup.dart';

/// F-016 T-441: what a money back (refund) does to the engine's figures and
/// to the stored covers, written through the real Drift repository (in-memory
/// SQLite), the same write path the editor uses. No engine, schema or money
/// rule is built here; if one of these fails it is an engine or F-007 bug.
void main() {
  final nov7 = d(2026, 11, 7);
  final nov11 = d(2026, 11, 11);
  final nov12 = d(2026, 11, 12);
  final nov13 = d(2026, 11, 13);

  Future<int> addRefund(
    Repos repos,
    int monthId,
    CalendarDate day,
    int paise, {
    required CalendarDate today,
    String? note,
    int hour = 15,
  }) async => (await repos.spends.add(
    monthId,
    fields(day, paise, note, null, SpendDirection.moneyIn),
    today: today,
    now: at(today, hour),
  )).id;

  Future<List<Paise>> storedCovers(Repos repos, int monthId) async => [
    for (final cover in await repos.savings.watchCovers(monthId).first)
      cover.amount,
  ];

  test('TC-016-05 a refund today gives the engine values of the worked '
      'example', () async {
    final repos = openMemoryRepos();
    final seed = await seedDriftFixture(repos, fixtureA);
    final monthId = seed.currentMonthId;
    final before = await storedResult(repos, monthId, nov13);
    expect(before.dayOn(nov13).netSpent, const Paise(42000));

    await addRefund(
      repos,
      monthId,
      nov13,
      50000,
      today: nov13,
      note: 'Amazon return',
    );
    final after = await storedResult(repos, monthId, nov13);
    final today = after.dayOn(nov13);
    expect(today.netSpent, const Paise(-8000));
    expect(today.moneyIn, const Paise(50000));
    expect(today.result, const Paise(91000), reason: 'left today');
    expect(after.totals.spentSoFar, const Paise(503000));
    expect(after.totals.left, const Paise(1987000));
    expect(after.totals.moneyIn, const Paise(50000));
    expect(after.totals.saved, before.totals.saved);
    expect(after.totals.overspent, before.totals.overspent);
    expect(after.totals.pot, before.totals.pot);
  });

  test(
    'TC-016-06 net spend below zero is saved by budget plus refund',
    () async {
      final repos = openMemoryRepos();
      final seed = await seedDriftFixture(repos, fixtureA);
      final monthId = seed.currentMonthId;
      final before = await storedResult(repos, monthId, nov13);
      expect(before.dayOn(nov12).result, const Paise(83000));

      await addRefund(repos, monthId, nov12, 150000, today: nov13);
      final after = await storedResult(repos, monthId, nov13);
      final day = after.dayOn(nov12);
      expect(day.status, DayStatus.saved);
      expect(
        day.netSpent,
        const Paise(-150000),
        reason: 'calendar cell −₹1,500',
      );
      expect(day.result, const Paise(233000), reason: 'Saved ₹2,330');
      expect(after.totals.saved, const Paise(350000), reason: 'was ₹2,000');
      expect(after.totals.pot, const Paise(350000));
      expect(after.totals.overspent, before.totals.overspent);
    },
  );

  test(
    'TC-016-10 editing a money back changes the day to the new net',
    () async {
      final repos = openMemoryRepos();
      final seed = await seedDriftFixture(repos, fixtureAPlusRefund);
      final monthId = seed.currentMonthId;
      final refund = seed.entryIds.single.last;

      final edited = await repos.spends.update(
        refund,
        fields(nov13, 30000, 'Amazon return', null, SpendDirection.moneyIn),
        today: nov13,
        now: at(nov13, 16),
      );
      expect(edited.reductions, isEmpty);
      final day = (await storedResult(repos, monthId, nov13)).dayOn(nov13);
      expect(day.netSpent, const Paise(12000), reason: '₹120');
      expect(day.moneyIn, const Paise(30000));
      expect(day.result, const Paise(71000), reason: '₹710 left today');
    },
  );

  test('TC-016-11 switching a refund off turns it into a spend and back, '
      'in place', () async {
    final repos = openMemoryRepos();
    final seed = await seedDriftFixture(repos, fixtureAPlusRefund);
    final monthId = seed.currentMonthId;
    final refund = seed.entryIds.single.last;
    await repos.spends.update(
      refund,
      fields(nov13, 30000, 'Amazon return', null, SpendDirection.moneyIn),
      today: nov13,
      now: at(nov13, 16),
    );

    await repos.spends.update(
      refund,
      fields(nov13, 30000, 'Amazon return'),
      today: nov13,
      now: at(nov13, 17),
    );
    var stored = (await repos.spends.watchMonthSpends(monthId).first)
        .firstWhere((s) => s.spend.id == refund);
    expect(stored.spend.direction, SpendDirection.spend);
    expect(stored.spend.createdAt, at(nov13, 12), reason: 'keeps its place');
    var day = (await storedResult(repos, monthId, nov13)).dayOn(nov13);
    expect(day.netSpent, const Paise(72000), reason: '₹720');
    expect(day.moneyIn, Paise.zero, reason: 'no refunds line');
    expect(day.result, const Paise(11000), reason: '₹110 left today');

    await repos.spends.update(
      refund,
      fields(nov13, 30000, 'Amazon return', null, SpendDirection.moneyIn),
      today: nov13,
      now: at(nov13, 18),
    );
    stored = (await repos.spends.watchMonthSpends(monthId).first).firstWhere(
      (s) => s.spend.id == refund,
    );
    expect(stored.spend.direction, SpendDirection.moneyIn);
    day = (await storedResult(repos, monthId, nov13)).dayOn(nov13);
    expect(day.netSpent, const Paise(12000));
  });

  test('TC-016-13 deleting a money back restores the figures', () async {
    final repos = openMemoryRepos();
    final seed = await seedDriftFixture(repos, fixtureAPlusRefund);
    final monthId = seed.currentMonthId;
    final outcome = await repos.spends.delete(
      seed.entryIds.single.last,
      today: nov13,
    );
    expect(outcome.reductions, isEmpty);
    final result = await storedResult(repos, monthId, nov13);
    expect(result.dayOn(nov13).netSpent, const Paise(42000));
    expect(result.dayOn(nov13).result, const Paise(41000));
    expect(result.totals.spentSoFar, const Paise(553000));
    expect(result.totals.moneyIn, Paise.zero);
  });

  test('TC-016-14 money back on a covered day cuts the cover and it never '
      'comes back', () async {
    final repos = openMemoryRepos();
    final seed = await seedDriftFixture(repos, fixtureAPlusCover);
    final monthId = seed.currentMonthId;
    final start = await storedResult(repos, monthId, nov13);
    expect(start.totals.pot, const Paise(170000));
    expect(start.totals.overspent, const Paise(17000));

    final refund = await addRefund(repos, monthId, nov11, 20000, today: nov13);
    final added = await storedResult(repos, monthId, nov13);
    final day = added.dayOn(nov11);
    expect(day.netSpent, const Paise(93000));
    expect(day.status, DayStatus.onBudget);
    expect(day.covered, const Paise(10000), reason: 'cover cut to ₹100');
    expect(added.totals.pot, const Paise(190000), reason: 'up by ₹200');
    expect(added.reductions, isEmpty, reason: 'no Savings pot updated note');
    expect(await storedCovers(repos, monthId), [const Paise(10000)]);

    final deleted = await repos.spends.delete(refund, today: nov13);
    expect(deleted.reductions, isEmpty);
    final after = await storedResult(repos, monthId, nov13);
    expect(await storedCovers(repos, monthId), [const Paise(10000)]);
    final overspent = after.dayOn(nov11);
    expect(overspent.status, DayStatus.overspent);
    expect(overspent.result, const Paise(-20000), reason: '◆ Overspent ₹200');
    expect(after.totals.pot, const Paise(190000));
    expect(after.totals.overspent, const Paise(37000), reason: '₹370');
  });

  test('TC-016-16 deleting a refund cuts the newest cover first', () async {
    final repos = openMemoryRepos();
    final seed = await seedDriftFixture(repos, p1);
    final monthId = seed.currentMonthId;
    final refund = seed.entryIds.single[6];
    expect(await storedCovers(repos, monthId), [
      const Paise(50000),
      const Paise(100000),
      const Paise(100000),
    ]);

    final outcome = await repos.spends.delete(refund, today: nov13);
    expect(
      [
        for (final r in outcome.reductions)
          (r.day, r.oldAmount.value, r.newAmount.value),
      ],
      [(d(2026, 11, 10), 100000, 50000)],
    );
    final after = await storedResult(repos, monthId, nov13);
    expect(after.totals.saved, const Paise(200000));
    expect(after.totals.pot, Paise.zero, reason: 'never negative');
    expect(await storedCovers(repos, monthId), [
      const Paise(50000),
      const Paise(100000),
      const Paise(50000),
    ]);
    final tenth = after.dayOn(d(2026, 11, 10));
    expect(tenth.covered, const Paise(50000));
    expect(tenth.status, DayStatus.overspent);
    expect(tenth.result, const Paise(-50000));
  });

  test('TC-016-18 several covers are cut in one write newest first', () async {
    final repos = openMemoryRepos();
    final seed = await seedDriftFixture(repos, p1b);
    final monthId = seed.currentMonthId;
    expect(
      (await storedResult(repos, monthId, nov13)).totals.pot,
      const Paise(100000),
    );

    final outcome = await repos.spends.delete(
      seed.entryIds.single[8],
      today: nov13,
    );
    expect(
      [
        for (final r in outcome.reductions)
          (r.day, r.oldAmount.value, r.newAmount.value, r.cut.value),
      ],
      [
        (d(2026, 11, 10), 100000, 0, 100000),
        (d(2026, 11, 9), 100000, 0, 100000),
        (d(2026, 11, 8), 50000, 34000, 16000),
      ],
    );
    final after = await storedResult(repos, monthId, nov13);
    expect(after.totals.saved, const Paise(34000));
    expect(after.totals.pot, Paise.zero);
    expect(await storedCovers(repos, monthId), [
      const Paise(34000),
      Paise.zero,
      Paise.zero,
    ]);
  });

  test('TC-016-19 lowering a money back cuts a cover only when the pot is '
      'short', () async {
    // (amount after the edit, saved, pot, the cut of the newest cover)
    const cases = [
      (100000, 300000, 50000, 0),
      (50000, 250000, 0, 0),
      (40000, 240000, 0, 10000),
    ];
    for (final (paise, saved, pot, cut) in cases) {
      final repos = openMemoryRepos();
      final seed = await seedDriftFixture(repos, p1);
      final monthId = seed.currentMonthId;
      final outcome = await repos.spends.update(
        seed.entryIds.single[6],
        fields(nov12, paise, null, null, SpendDirection.moneyIn),
        today: nov13,
        now: at(nov13, 16),
      );
      final result = await storedResult(repos, monthId, nov13);
      expect(result.totals.saved, Paise(saved), reason: 'for $paise');
      expect(result.totals.pot, Paise(pot), reason: 'for $paise');
      expect(
        outcome.reductions.map((r) => r.cut.value).toList(),
        cut == 0 ? isEmpty : [cut],
        reason: 'for $paise',
      );
      expect(
        (await storedCovers(repos, monthId)).last,
        Paise(100000 - cut),
        reason: 'newest cover for $paise',
      );
      await repos.db.close();
    }
  });

  test('TC-016-26 left rises above the spendable', () async {
    final repos = openMemoryRepos();
    final seed = await seedDriftFixture(
      repos,
      fixtureA.copyWith(name: 'A no spends', entries: const []),
    );
    final monthId = seed.currentMonthId;
    await addRefund(repos, monthId, nov13, 30000, today: nov13);
    final result = await storedResult(repos, monthId, nov13);
    expect(result.totals.spentSoFar, const Paise(-30000));
    expect(result.totals.left, const Paise(2520000));
    expect(result.dayOn(nov13).result, const Paise(113000));
  });

  test('TC-016-28 sub rupee refund makes a saved day', () async {
    final repos = openMemoryRepos();
    final seed = await seedDriftFixture(
      repos,
      fixtureA.copyWith(
        name: 'A one spend',
        entries: [fixtureSpend(nov7, 83000)],
      ),
    );
    final monthId = seed.currentMonthId;
    expect(
      (await storedResult(repos, monthId, nov13)).dayOn(nov7).status,
      DayStatus.onBudget,
    );
    await addRefund(repos, monthId, nov7, 40, today: nov13);
    final day = (await storedResult(repos, monthId, nov13)).dayOn(nov7);
    expect(day.status, DayStatus.saved);
    expect(day.result, const Paise(40));
  });

  test('TC-016-29 turning a covered spend into money back removes the '
      'cover', () async {
    final repos = openMemoryRepos();
    final seed = await seedDriftFixture(repos, fixtureAPlusCover);
    final monthId = seed.currentMonthId;
    final phoneBill = seed.entryIds.single[7];

    final outcome = await repos.spends.update(
      phoneBill,
      fields(nov11, 113000, 'Phone bill', null, SpendDirection.moneyIn),
      today: nov13,
      now: at(nov13, 16),
    );
    expect(outcome.reductions, isEmpty, reason: 'the pot grew: no note');
    final result = await storedResult(repos, monthId, nov13);
    final day = result.dayOn(nov11);
    expect(day.netSpent, const Paise(-113000));
    expect(day.result, const Paise(196000));
    expect(day.covered, Paise.zero);
    expect(await storedCovers(repos, monthId), [Paise.zero]);
    expect(result.totals.pot, const Paise(396000));
    expect(result.totals.covered, Paise.zero);
    expect(result.totals.overspent, const Paise(17000), reason: '₹170');
  });

  test('TC-016-31 ten crore refund is exact', () async {
    final repos = openMemoryRepos();
    final seed = await seedDriftFixture(
      repos,
      fixtureA.copyWith(name: 'A no spends', entries: const []),
    );
    final monthId = seed.currentMonthId;
    await addRefund(repos, monthId, nov13, 10000000000, today: nov13);
    final result = await storedResult(repos, monthId, nov13);
    expect(result.dayOn(nov13).netSpent, const Paise(-10000000000));
    expect(result.dayOn(nov13).result, const Paise(10000083000));
  });

  test('TC-016-37 refund day saved at midnight', () async {
    final repos = openMemoryRepos();
    final seed = await seedDriftFixture(repos, fixtureAPlusRefund);
    final monthId = seed.currentMonthId;
    final before = await storedResult(repos, monthId, nov13);
    final next = await storedResult(repos, monthId, d(2026, 11, 14));
    expect(next.dayOn(nov13).status, DayStatus.saved);
    expect(next.dayOn(nov13).result, const Paise(91000));
    expect(
      next.totals.saved,
      before.totals.saved + const Paise(91000),
      reason: 'Saved this month ₹2,910',
    );
    expect(next.totals.saved, const Paise(291000));
    expect(next.totals.pot, before.totals.pot + const Paise(91000));
  });

  test('TC-016-46 converting a categorised spend clears its category in one '
      'write', () async {
    final repos = openMemoryRepos();
    final seed = await seedDriftFixture(repos, fixtureAF);
    final lunch = seed.entryIds.single[8];
    final before =
        (await repos.spends.watchMonthSpends(seed.currentMonthId).first)
            .firstWhere((s) => s.spend.id == lunch);
    expect(before.spend.category, SpendCategory.food);

    await repos.spends.update(
      lunch,
      fields(nov13, 42000, 'Lunch', null, SpendDirection.moneyIn),
      today: nov13,
      now: at(nov13, 16),
    );
    final row =
        (await repos.db
                .customSelect(
                  'SELECT direction, category, source FROM transactions '
                  'WHERE id = ?',
                  variables: [Variable.withInt(lunch)],
                )
                .getSingle())
            .data;
    expect(row, {
      'direction': 'money_in',
      'category': null,
      'source': 'manual',
    });
  });

  test('TC-016-47 a forced failure leaves the covers and the refund as they '
      'were', () async {
    final repos = openMemoryRepos();
    final seed = await seedDriftFixture(repos, p1);
    final monthId = seed.currentMonthId;
    final refund = seed.entryIds.single[6];
    final before = (
      await rowSnapshot(repos.db, 'transactions'),
      await rowSnapshot(repos.db, 'savings_moves'),
    );
    // A write that fails half way: the transaction rolls back as a whole.
    await repos.db.customStatement('''
      CREATE TRIGGER fail_cover_cut BEFORE UPDATE ON savings_moves
      BEGIN SELECT RAISE(ABORT, 'forced failure'); END;
    ''');
    await expectLater(
      repos.spends.delete(refund, today: nov13),
      throwsA(isA<StorageException>()),
    );
    expect(await rowSnapshot(repos.db, 'transactions'), before.$1);
    expect(await rowSnapshot(repos.db, 'savings_moves'), before.$2);
    expect(
      (await storedResult(repos, monthId, nov13)).totals.pot,
      const Paise(100000),
    );
  });
}
