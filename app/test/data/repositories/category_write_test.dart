import 'package:daily_budget/domain/budget/budget.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/drift_fixture_seed.dart';
import '../../helpers/phase3_fixtures.dart';
import 'repository_setup.dart';

/// F-015 T-420: the write side of the category and the direction, on the
/// real Drift repository (in-memory SQLite).
void main() {
  final nov13 = d(2026, 11, 13);

  Future<Map<int, SpendCategory?>> categories(Repos repos, int monthId) async {
    final stored = await repos.spends.watchMonthSpends(monthId).first;
    return {for (final s in stored) s.spend.id: s.spend.category};
  }

  test(
    'TC-015-22 changing categories never changes the engine output',
    () async {
      final repos = openMemoryRepos();
      final seed = await seedDriftFixture(repos, fixtureAPlusCover);
      final monthId = seed.currentMonthId;
      final before = dump(await storedResult(repos, monthId, nov13));
      final coversBefore = await rowSnapshot(repos.db, 'savings_moves');

      // Every spend gets a different one of the nine categories.
      final ids = seed.entryIds.single;
      for (final (i, id) in ids.indexed) {
        await repos.spends.updateCategory(
          id,
          SpendCategory.values[i % SpendCategory.values.length],
          now: at(nov13, 15, i),
        );
      }
      expect(
        dump(await storedResult(repos, monthId, nov13)),
        before,
        reason: 'a category is not money',
      );
      expect(await rowSnapshot(repos.db, 'savings_moves'), coversBefore);

      for (final id in ids) {
        await repos.spends.updateCategory(id, null, now: at(nov13, 16));
      }
      expect(dump(await storedResult(repos, monthId, nov13)), before);
      expect(
        (await categories(repos, monthId)).values,
        everyElement(isNull),
        reason: 'null restores no category',
      );
    },
  );

  test('TC-015-54 every category has a stable stored key', () async {
    final repos = openMemoryRepos();
    final seed = await seedDriftFixture(repos, fixtureA);
    final id = seed.entryIds.single.first;
    const keys = {
      SpendCategory.food: 'food',
      SpendCategory.groceries: 'groceries',
      SpendCategory.shopping: 'shopping',
      SpendCategory.travel: 'travel',
      SpendCategory.billsRecharge: 'bills_recharge',
      SpendCategory.entertainment: 'entertainment',
      SpendCategory.health: 'health',
      SpendCategory.friendsPeople: 'friends_people',
      SpendCategory.other: 'other',
    };
    for (final MapEntry(key: category, value: key) in keys.entries) {
      await repos.spends.updateCategory(id, category, now: at(nov13, 15));
      final rows = await repos.db
          .customSelect(
            'SELECT category FROM transactions WHERE id = ?',
            variables: [Variable.withInt(id)],
          )
          .get();
      expect(rows.single.read<String?>('category'), key);
      expect((await categories(repos, seed.currentMonthId))[id], category);
    }
    expect(SpendCategory.values, hasLength(keys.length));
  });

  test(
    'TC-015-20 a category write changes one record and its edit time',
    () async {
      final repos = openMemoryRepos();
      final seed = await seedDriftFixture(repos, fixtureA);
      final ids = seed.entryIds.single;
      final lunch9 = ids[4];
      final before = await rowSnapshot(repos.db, 'transactions');
      await repos.spends.updateCategory(
        lunch9,
        SpendCategory.food,
        now: at(nov13, 18),
      );
      final after = await rowSnapshot(repos.db, 'transactions');
      for (final (i, row) in after.indexed) {
        if (row['id'] == lunch9) {
          expect(row['category'], 'food');
          expect(row['edited_at'], at(nov13, 18));
          expect(row['created_at'], before[i]['created_at']);
          expect(row['amount_paise'], before[i]['amount_paise']);
          expect(row['day'], before[i]['day']);
          expect(row['note'], before[i]['note']);
        } else {
          expect(row, before[i], reason: 'only one record changes');
        }
      }
    },
  );

  test('TC-015-24 a category can be changed in a past month', () async {
    final repos = openMemoryRepos();
    final seed = await seedDriftFixture(repos, fixtureO1);
    final october = seed.monthIds.first;
    final id = seed.entryIds.first.first;
    await repos.spends.updateCategory(
      id,
      SpendCategory.travel,
      now: at(nov13, 9),
    );
    expect((await categories(repos, october))[id], SpendCategory.travel);
  });

  test('TC-015-20 a money in row has no category to change', () async {
    final repos = openMemoryRepos();
    final seed = await seedDriftFixture(repos, fixtureAPlusRefund);
    final refund = seed.entryIds.single.last;
    await expectLater(
      repos.spends.updateCategory(
        refund,
        SpendCategory.food,
        now: at(nov13, 9),
      ),
      throwsArgumentError,
    );
    await expectLater(
      repos.spends.updateCategory(9999, SpendCategory.food, now: at(nov13, 9)),
      throwsArgumentError,
    );
    expect((await categories(repos, seed.currentMonthId))[refund], isNull);
  });

  test('TC-015-30 add stores the category and the direction', () async {
    final repos = openMemoryRepos();
    final month = await repos.months.confirmMonth(e2NewMonth());
    await repos.spends.add(
      month.id,
      fields(nov13, 25000, 'Lunch', SpendCategory.food),
      today: nov13,
      now: at(nov13, 12),
    );
    await repos.spends.add(
      month.id,
      fields(nov13, 50000, 'Amazon return', null, SpendDirection.moneyIn),
      today: nov13,
      now: at(nov13, 13),
    );
    final stored = await repos.spends.watchMonthSpends(month.id).first;
    expect(
      [for (final s in stored) (s.note, s.spend.category, s.spend.direction)],
      [
        ('Amazon return', null, SpendDirection.moneyIn),
        ('Lunch', SpendCategory.food, SpendDirection.spend),
      ],
    );
    expect(stored.last.noted, (spend: stored.last.spend, note: 'Lunch'));
  });

  test('TC-015-20 money in never stores a category', () async {
    final repos = openMemoryRepos();
    final month = await repos.months.confirmMonth(e2NewMonth());
    expect(
      () => repos.spends.add(
        month.id,
        fields(nov13, 50000, null, SpendCategory.food, SpendDirection.moneyIn),
        today: nov13,
        now: at(nov13, 12),
      ),
      throwsArgumentError,
    );
    expect(await countRows(repos.db, 'transactions'), 0);
  });

  test(
    'TC-015-33 an edit writes category and direction, covers follow',
    () async {
      final repos = openMemoryRepos();
      final seed = await seedDriftFixture(repos, fixtureAPlusCover);
      final nov11 = d(2026, 11, 11);
      final phoneBill = seed.entryIds.single[7];
      // A plain edit that keeps the amount: category written, cover untouched.
      await repos.spends.update(
        phoneBill,
        fields(nov11, 113000, 'Phone bill', SpendCategory.billsRecharge),
        today: nov13,
        now: at(nov13, 15),
      );
      final stored = await repos.spends
          .watchMonthSpends(seed.currentMonthId)
          .first;
      final row = stored.firstWhere((s) => s.spend.id == phoneBill);
      expect(row.spend.category, SpendCategory.billsRecharge);
      expect(
        row.spend.createdAt,
        at(nov11, 12),
        reason: 'an edit never reorders',
      );
      final covers = await repos.savings.watchCovers(seed.currentMonthId).first;
      expect(covers.single.amount, const Paise(30000));
    },
  );

  test(
    'TC-016-46 converting a spend writes the direction and clears the category',
    () async {
      final repos = openMemoryRepos();
      final seed = await seedDriftFixture(repos, fixtureAPlusCover);
      final monthId = seed.currentMonthId;
      final nov11 = d(2026, 11, 11);
      final phoneBill = seed.entryIds.single[7];
      await repos.spends.updateCategory(
        phoneBill,
        SpendCategory.billsRecharge,
        now: at(nov13, 10),
      );
      // The categorised spend becomes money back in one write.
      await repos.spends.update(
        phoneBill,
        fields(nov11, 113000, 'Phone bill', null, SpendDirection.moneyIn),
        today: nov13,
        now: at(nov13, 15),
      );
      final stored = await repos.spends.watchMonthSpends(monthId).first;
      final converted = stored.firstWhere((s) => s.spend.id == phoneBill);
      expect(
        (converted.spend.direction, converted.spend.category),
        (SpendDirection.moneyIn, null),
      );
      // And back to a spend: no category until one is picked.
      await repos.spends.update(
        phoneBill,
        fields(nov11, 113000, 'Phone bill'),
        today: nov13,
        now: at(nov13, 16),
      );
      final back = (await repos.spends.watchMonthSpends(monthId).first)
          .firstWhere((s) => s.spend.id == phoneBill);
      expect(
        (back.spend.direction, back.spend.category),
        (SpendDirection.spend, null),
      );
    },
  );
}
