import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import 'repository_setup.dart';

void main() {
  test('TC-013-53 a stored category key is read, an unknown key reads as '
      'Other and no key stays null', () async {
    final repos = openMemoryRepos();
    final month = await repos.months.confirmMonth(e2NewMonth());
    var created = at(d(2026, 11, 6), 9);
    Future<void> insert(String? category) => repos.db
        .into(repos.db.transactions)
        .insert(
          TransactionsCompanion.insert(
            monthId: month.id,
            day: d(2026, 11, 6),
            amountPaise: const Paise(1000),
            category: Value(category),
            createdAt: created,
            editedAt: created++,
          ),
        );
    await insert('food');
    await insert('bills_recharge');
    await insert('crypto');
    await insert(null);

    final spends = await repos.spends.watchMonthSpends(month.id).first;
    // Newest created first: null, crypto, bills_recharge, food.
    expect(
      [for (final s in spends) s.spend.category],
      [
        null,
        SpendCategory.other,
        SpendCategory.billsRecharge,
        SpendCategory.food,
      ],
    );
  });
}
