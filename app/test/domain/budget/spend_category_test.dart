import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  test('TC-013-53 unknown category key reads as Other', () {
    expect(SpendCategory.fromKey('crypto'), SpendCategory.other);
    expect(SpendCategory.fromKey(''), SpendCategory.other);
    expect(
      SpendCategory.fromKey('Food'),
      SpendCategory.other,
    ); // keys are exact
    expect(SpendCategory.fromKey(null), SpendCategory.other);
  });

  test('TC-013-23 the nine categories keep the readme order and keys', () {
    expect(
      [for (final c in SpendCategory.values) c.key],
      [
        'food',
        'groceries',
        'shopping',
        'travel',
        'bills_recharge',
        'entertainment',
        'health',
        'friends_people',
        'other',
      ],
    );
  });

  test('TC-013-23 every stored key reads back as its own category', () {
    for (final category in SpendCategory.values) {
      expect(SpendCategory.fromKey(category.key), category);
    }
  });

  test('TC-013-23 only Other is Other', () {
    expect(
      [
        for (final c in SpendCategory.values)
          if (c.isOther) c,
      ],
      [SpendCategory.other],
    );
  });

  test('TC-013-23 a category on a spend does not change the engine result', () {
    // The engine never reads the category (T-380: no money rule, no change).
    final plain = [spend(d(2026, 11, 5), 50000, id: 1)];
    final categorised = [
      Spend(
        id: 1,
        date: d(2026, 11, 5),
        amount: const Paise(50000),
        createdAt: at(d(2026, 11, 5), 12),
        category: SpendCategory.travel,
      ),
    ];
    final today = d(2026, 11, 8);
    expect(
      dump(e2Month(today: today, spends: categorised)),
      dump(e2Month(today: today, spends: plain)),
    );
  });
}
