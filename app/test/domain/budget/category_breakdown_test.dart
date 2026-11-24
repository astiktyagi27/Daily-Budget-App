import 'dart:math';

import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phase3_fixtures.dart';
import 'fixtures.dart';

/// The spends of [fixture]'s current month, ids 1, 2, ... in list order.
List<Spend> _spendsOf(Phase3Fixture fixture) => [
  for (final (index, entry) in fixture.current.entries.indexed)
    entry.toSpend(index + 1),
];

/// The range the engine counts: first budgeted day to today, never past the
/// month's end.
CategoryBreakdown _breakdownOf(Phase3Fixture fixture) {
  final result = fixture.result;
  final last = result.today.isAfter(result.month.end)
      ? result.month.end
      : result.today;
  return categoryBreakdown(_spendsOf(fixture), result.firstBudgetedDay, last);
}

CalendarDate _nov(int day) => d(2026, 11, day);

Spend _spend(
  int day,
  int paise, {
  SpendCategory? category,
  int id = 0,
  bool moneyIn = false,
}) => Spend(
  id: id,
  date: _nov(day),
  amount: Paise(paise),
  createdAt: at(_nov(day), 12),
  direction: moneyIn ? SpendDirection.moneyIn : SpendDirection.spend,
  category: category,
);

List<(SpendCategory, int, int)> _shown(CategoryBreakdown b) => [
  for (final row in b.rows) (row.category, row.amount.value, row.percent),
];

void main() {
  test('TC-013-03 one category gives the single category state', () {
    final b = _breakdownOf(fixtureA);
    expect(b.kind, BreakdownKind.single);
    expect(b.singleCategory, SpendCategory.other);
    expect(b.spent, const Paise(553000));
    expect(b.hasRefunds, isFalse);
    expect(b.roundingNoteNeeded, isFalse);
    expect(b.rows.single.percent, 100);
    expect(b.rows.single.barPermille, 1000);
  });

  test('TC-013-03 a single category that is not Other is named', () {
    final food = fixtureA.mapEntries(
      'A food',
      (entry) => entry.copyWith(categoryKey: 'food'),
    );
    final b = _breakdownOf(food);
    expect(b.kind, BreakdownKind.single);
    expect(b.singleCategory, SpendCategory.food);
  });

  test('TC-013-06 shares are whole percent rounded down in integers', () {
    final b = _breakdownOf(fixtureB);
    expect(b.kind, BreakdownKind.several);
    expect(b.singleCategory, isNull);
    expect(_shown(b), [
      (SpendCategory.other, 391000, 70),
      (SpendCategory.shopping, 100000, 18),
      (SpendCategory.food, 62000, 11),
    ]);
    // The bar is the exact share in thousandths: 707, 180, 112.
    expect([for (final row in b.rows) row.barPermille], [707, 180, 112]);
    expect(b.percentsAddUpTo100, isFalse);
    expect(b.roundingNoteNeeded, isTrue);
    expect(b.spent, const Paise(553000));
  });

  test('TC-013-07 ties sort in readme order', () {
    final travelFirst = categoryBreakdown(
      [
        _spend(6, 50000, category: SpendCategory.travel, id: 1),
        _spend(7, 50000, category: SpendCategory.food, id: 2),
      ],
      _nov(5),
      _nov(13),
    );
    expect(_shown(travelFirst), [
      (SpendCategory.food, 50000, 50),
      (SpendCategory.travel, 50000, 50),
    ]);
    // Shares add up to 100: no rounding note.
    expect(travelFirst.percentsAddUpTo100, isTrue);
    expect(travelFirst.roundingNoteNeeded, isFalse);

    // Other is last among equal amounts, first when it has more.
    final otherLast = categoryBreakdown(
      [
        _spend(6, 100, id: 1),
        _spend(6, 100, category: SpendCategory.health, id: 2),
        _spend(6, 100, category: SpendCategory.groceries, id: 3),
      ],
      _nov(5),
      _nov(13),
    );
    expect(
      [for (final row in otherLast.rows) row.category],
      [SpendCategory.groceries, SpendCategory.health, SpendCategory.other],
    );
  });

  test('TC-013-08 a positive share under one percent is marked tiny', () {
    // Other 9,950 rupees and Health 50 rupees: 0.5 percent.
    final b = categoryBreakdown(
      [
        _spend(6, 995000, id: 1),
        _spend(7, 5000, category: SpendCategory.health, id: 2),
      ],
      _nov(5),
      _nov(13),
    );
    expect(_shown(b), [
      (SpendCategory.other, 995000, 99),
      (SpendCategory.health, 5000, 0),
    ]);
    expect(b.rows.first.underOnePercent, isFalse);
    expect(b.rows.last.underOnePercent, isTrue);
    expect(b.roundingNoteNeeded, isTrue);
  });

  test('TC-013-60 share boundaries around one percent', () {
    // (Other paise, Health paise, shown percent, shown as <1%).
    const cases = <(int, int, int, bool)>[
      (990000, 10000, 1, false), // exactly 1.00 %
      (980100, 19900, 1, false), // 1.99 %
      (990100, 9900, 0, true), // 0.99 %
    ];
    for (final (other, health, percent, tiny) in cases) {
      final b = categoryBreakdown(
        [
          _spend(6, other, id: 1),
          _spend(7, health, category: SpendCategory.health, id: 2),
        ],
        _nov(5),
        _nov(13),
      );
      final row = b.rows.last;
      expect(row.category, SpendCategory.health, reason: '$health paise');
      expect(row.percent, percent, reason: '$health paise');
      expect(row.underOnePercent, tiny, reason: '$health paise');
    }
  });

  test('TC-013-37 forty paise is under one percent and ₹0', () {
    final b = categoryBreakdown(
      [
        _spend(6, 50000, id: 1),
        _spend(7, 40, category: SpendCategory.health, id: 2),
      ],
      _nov(5),
      _nov(13),
    );
    expect(b.rows.last.percent, 0);
    expect(b.rows.last.underOnePercent, isTrue);
    expect(b.rows.last.amount, const Paise(40));
    expect(b.rows.first.percent, 99);
  });

  test('TC-013-10 net spent equals the engine spent so far', () {
    final b = _breakdownOf(fixtureAPlusRefund);
    expect(b.spent, const Paise(553000));
    expect(b.refunds, const Paise(50000));
    expect(b.netSpent, const Paise(503000));
    expect(b.hasRefunds, isTrue);
    expect(b.netSpent, fixtureAPlusRefund.result.totals.spentSoFar);
    // Money in is not a category: the rows stay as without the refund.
    expect(b.kind, BreakdownKind.single);
  });

  test('TC-013-10 net spent equals the engine for random months', () {
    final random = Random(propertySeed);
    for (var round = 0; round < 200; round++) {
      final today = _nov(5).addDays(random.nextInt(35));
      final spends = [
        for (var i = 0; i < random.nextInt(25); i++)
          Spend(
            id: i + 1,
            // Some before the month, some after today, some past its end.
            date: _nov(1).addDays(random.nextInt(45)),
            amount: Paise(1 + random.nextInt(300000)),
            createdAt: i,
            direction: random.nextInt(4) == 0
                ? SpendDirection.moneyIn
                : SpendDirection.spend,
            category: random.nextBool()
                ? null
                : SpendCategory.values[random.nextInt(9)],
          ),
      ];
      final result = e2Month(today: today, spends: spends);
      final last = today.isAfter(result.month.end) ? result.month.end : today;
      final b = categoryBreakdown(spends, result.firstBudgetedDay, last);
      var rowSum = 0;
      for (final row in b.rows) {
        rowSum += row.amount.value;
      }
      expect(
        rowSum - b.refunds.value,
        result.totals.spentSoFar.value,
        reason: 'round $round',
      );
      expect(b.netSpent, result.totals.spentSoFar, reason: 'round $round');
    }
  });

  test('TC-013-45 only refunds in the range is empty with refund lines', () {
    final b = categoryBreakdown(
      [_spend(12, 50000, moneyIn: true, id: 1)],
      _nov(5),
      _nov(13),
    );
    expect(b.kind, BreakdownKind.empty);
    expect(b.rows, isEmpty);
    expect(b.singleCategory, isNull);
    expect(b.spent, Paise.zero);
    expect(b.refunds, const Paise(50000));
    expect(b.netSpent, const Paise(-50000));
    expect(b.roundingNoteNeeded, isFalse);
  });

  test('TC-013-34 nothing in the range is empty', () {
    final b = categoryBreakdown(const [], _nov(5), _nov(13));
    expect(b.kind, BreakdownKind.empty);
    expect(b.hasRefunds, isFalse);
    expect(b.netSpent, Paise.zero);
  });

  test('TC-013-09 only spends in the range count, both ends included', () {
    final spends = [
      _spend(4, 111, id: 1),
      _spend(5, 200, id: 2),
      _spend(9, 300, id: 3),
      _spend(10, 400, id: 4),
      _spend(10, 999, moneyIn: true, id: 5),
    ];
    final b = categoryBreakdown(spends, _nov(5), _nov(9));
    expect(b.spent, const Paise(500));
    expect(b.refunds, Paise.zero);
    final day = categoryBreakdown(spends, _nov(10), _nov(10));
    expect(day.spent, const Paise(400));
    expect(day.refunds, const Paise(999));
    expect(day.netSpent, const Paise(-599));
  });

  test('TC-013-35 nine categories give nine rows in amount order', () {
    final b = categoryBreakdown(
      [
        for (final (index, category) in SpendCategory.values.indexed)
          _spend(6, (9 - index) * 100000, category: category, id: index + 1),
      ],
      _nov(5),
      _nov(13),
    );
    expect([for (final row in b.rows) row.category], SpendCategory.values);
    expect(
      [for (final row in b.rows) row.percent],
      [20, 17, 15, 13, 11, 8, 6, 4, 2],
    );
    expect(b.percentsAddUpTo100, isFalse); // 96
  });

  test('TC-013-23 statistics give the worked numbers in integers', () {
    final b = _breakdownOf(fixtureB);
    // 3,91,000 x 100 ~/ 5,53,000 = 70; 1,00,000 -> 18; 62,000 -> 11.
    expect([for (final row in b.rows) row.percent], [70, 18, 11]);
  });

  test('TC-013-25 ten crore for thirty one days stays exact', () {
    const crore10 = 10000000000; // paise
    final allOther = categoryBreakdown(
      [
        for (var day = 0; day < 31; day++)
          Spend(
            id: day + 1,
            date: _nov(1).addDays(day),
            amount: const Paise(crore10),
            createdAt: day,
          ),
      ],
      _nov(1),
      _nov(30).addDays(1),
    );
    expect(allOther.spent, const Paise(31 * crore10));
    expect(allOther.kind, BreakdownKind.single);
    expect(allOther.rows.single.percent, 100);
    expect(allOther.rows.single.barPermille, 1000);

    final mixed = categoryBreakdown(
      [
        for (var day = 0; day < 31; day++)
          Spend(
            id: day + 1,
            date: _nov(1).addDays(day),
            amount: const Paise(crore10),
            createdAt: day,
            category: day < 8 ? SpendCategory.values[day] : null,
          ),
      ],
      _nov(1),
      _nov(30).addDays(1),
    );
    // Other has 23 days: 23 / 31 = 74.19 percent; each of eight others 3.22.
    expect(mixed.rows.first.category, SpendCategory.other);
    expect(mixed.rows.first.percent, 74);
    expect(mixed.rows.first.barPermille, 741);
    expect(mixed.rows.last.percent, 3);
    expect(mixed.rows.last.barPermille, 32);
  });
}
