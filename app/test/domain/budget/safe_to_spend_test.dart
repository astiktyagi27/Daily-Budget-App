import 'dart:math';

import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phase3_fixtures.dart';
import 'fixtures.dart';

// Safe to spend (F-017, D-058). Every expected value is a paise literal from
// tests/F-017-safe-to-spend.md, never computed here.

/// What a [SafeToSpend] says, as comparable text.
String _says(SafeToSpend value) => switch (value) {
  SafeToSpendAmount(:final perDay, :final daysLeft) =>
    'amount ${perDay.value} paise, $daysLeft days left',
  SafeToSpendUnderRupee(:final daysLeft) => 'under a rupee, $daysLeft days',
  SafeToSpendNothingLeft() => 'nothing left',
  SafeToSpendUnavailable() => 'unavailable',
};

String _core(int left, int todayNet, int days) => _says(
  safeToSpendFrom(left: p(left), todayNetSpend: p(todayNet), daysLeft: days),
);

String _onDay(Phase3Fixture fixture, CalendarDate today) =>
    _says(safeToSpendPerDay(fixture.current.result(today)));

void main() {
  test('TC-017-01 example A gives 89,954 paise', () {
    // 19,79,000 / 22 = 89,954.54, rounded down.
    expect(_core(1937000, 42000, 22), 'amount 89954 paise, 22 days left');
  });

  test('TC-017-02 the helper reads left today and days from the month '
      'result', () {
    final result = fixtureA.result;
    expect(result.totals.left, p(1937000));
    expect(result.dayOn(d(2026, 11, 13)).netSpent, p(42000));
    expect(
      _says(safeToSpendPerDay(result)),
      'amount 89954 paise, 22 days left',
    );
  });

  test('TC-017-05 spending today never changes the figure', () {
    String withTodaySpend(int paise) {
      final month = fixtureA.current;
      final others = month.entries.where((e) => e.date != d(2026, 11, 13));
      final entries = [
        ...others,
        if (paise > 0) fixtureSpend(d(2026, 11, 13), paise),
      ];
      final result = month.copyWith(entries: entries).result(d(2026, 11, 13));
      return _says(safeToSpendPerDay(result));
    }

    // Today's spend 0, 1 paisa, 100, 41,000, 5,00,000, 19,37,000 and the
    // original 42,000: Left falls by the same amount each time. The base is
    // A13 without its 13 Nov spend, whose numerator is 19,79,000.
    final base = withTodaySpend(0);
    expect(base, 'amount 89954 paise, 22 days left');
    for (final paise in [1, 100, 41000, 42000, 500000, 1937000]) {
      expect(withTodaySpend(paise), base, reason: '$paise paise');
    }

    // Random spends on random days of the E2 month: for any spend added
    // today the figure is the same as without it.
    final random = Random(propertySeed);
    for (var i = 0; i < 200; i++) {
      final today = d(2026, 11, 5).addDays(random.nextInt(30));
      final past = [
        for (
          var day = d(2026, 11, 5);
          day.isBefore(today);
          day = day.addDays(1)
        )
          if (random.nextBool())
            fixtureSpend(day, uniformUpTo(random, 300000) + 1),
      ];
      final spent = uniformUpTo(random, 2000000) + 1;
      final month = fixtureA.current;
      final without = month.copyWith(entries: past).result(today);
      final withSpend = month
          .copyWith(entries: [...past, fixtureSpend(today, spent)])
          .result(today);
      expect(
        _says(safeToSpendPerDay(withSpend)),
        _says(safeToSpendPerDay(without)),
        reason: '${today.iso} spent $spent',
      );
    }
  });

  test('TC-017-08 example A tomorrow gives 92,238 paise', () {
    expect(_core(1937000, 0, 21), 'amount 92238 paise, 21 days left');
    expect(_onDay(a14, d(2026, 11, 14)), 'amount 92238 paise, 21 days left');
  });

  test('TC-017-10 day one figures equal the day budget', () {
    expect(_core(2490000, 0, 30), 'amount 83000 paise, 30 days left');
    expect(_core(2490000, 0, 25), 'amount 99600 paise, 25 days left');
    expect(_onDay(e2Day1, d(2026, 11, 5)), 'amount 83000 paise, 30 days left');
  });

  test('TC-017-12 example M gives 70,454 paise', () {
    final result = m20.result;
    expect(result.totals.left, p(690000));
    expect(result.dayOn(d(2026, 11, 20)).netSpent, p(85000));
    // 7,75,000 / 11 = 70,454.5, rounded down; 20 - 30 Nov is 11 days.
    expect(
      _says(safeToSpendPerDay(result)),
      'amount 70454 paise, 11 days left',
    );
  });

  test('TC-017-14 the line switches from nothing to less than a rupee to an '
      'amount', () {
    for (final nothing in [-120000, -1, 0]) {
      expect(_core(nothing, 0, 1), 'nothing left', reason: '$nothing');
    }
    for (final tiny in [1, 50, 99]) {
      expect(_core(tiny, 0, 1), 'under a rupee, 1 days', reason: '$tiny');
    }
    for (final (paise, perDay) in [
      (100, 100),
      (101, 101),
      (199, 199),
      (200, 200),
    ]) {
      expect(
        _core(paise, 0, 1),
        'amount $perDay paise, 1 days left',
        reason: '$paise',
      );
    }
    // The amount to spread is Left plus today's net spend.
    expect(_core(-30, 80, 1), 'under a rupee, 1 days');
    expect(_core(80, -80, 1), 'nothing left');
  });

  test('TC-017-17 refund example gives 92,227 paise', () {
    expect(_core(1987000, 42000, 22), 'amount 92227 paise, 22 days left');
    // The same through the engine: a refund of 50,000 on 12 Nov.
    final withRefund = fixtureA.plus(
      name: 'A + refund 12 Nov',
      entries: [fixtureMoneyIn(d(2026, 11, 12), 50000)],
    );
    expect(
      _onDay(withRefund, d(2026, 11, 13)),
      'amount 92227 paise, 22 days left',
    );
  });

  test('TC-017-18 results are exact integers rounded down and days left is '
      'at least one', () {
    for (final (toSpread, days, perDay) in [
      (1979000, 22, 89954),
      (1937000, 21, 92238),
      (2490000, 30, 83000),
      (2490000, 25, 99600),
      (775000, 11, 70454),
      (2029000, 22, 92227),
      (2307000, 29, 79551),
      (2490000, 1, 2490000),
    ]) {
      expect(
        _core(toSpread, 0, days),
        'amount $perDay paise, $days days left',
        reason: '$toSpread / $days',
      );
    }
    // Days left of 0 or -3 count as 1: never an exception.
    for (final days in [0, -3]) {
      expect(_core(2490000, 0, days), 'amount 2490000 paise, 1 days left');
      expect(_core(50, 0, days), 'under a rupee, 1 days');
    }
  });

  test('TC-017-19 ten crore is exact', () {
    // 10,00,00,00,000 paise over 22 days is 45,45,454 rupees a day.
    expect(_core(10000000000, 0, 22), 'amount 454545454 paise, 22 days left');
  });

  test('TC-017-22 computing the figure never changes the engine output', () {
    final result = fixtureA.result;
    final before = dump(result);
    for (var i = 0; i < 3; i++) {
      safeToSpendPerDay(result);
    }
    expect(dump(result), before);
  });

  test('TC-017-35 a tiny amount over many days reads less than one rupee', () {
    expect(_core(10, 0, 22), 'under a rupee, 22 days');
    for (final paise in [1, 21, 22]) {
      expect(_core(paise, 0, 22), 'under a rupee, 22 days', reason: '$paise');
    }
    expect(_core(2200, 0, 22), 'amount 100 paise, 22 days left');
  });

  test('TC-017-37 engine result layer returns unavailable outside the '
      'budgeted days', () {
    // (a) A13 before, inside and after the month.
    expect(_onDay(fixtureA, d(2026, 11, 2)), 'unavailable');
    expect(
      _onDay(fixtureA, d(2026, 11, 13)),
      'amount 89954 paise, 22 days left',
    );
    expect(_onDay(fixtureA, d(2026, 12, 5)), 'unavailable');
    // (b) F12: first budgeted day 10 Nov. The 11 Nov spend is future-dated
    // on 10 Nov and not counted.
    expect(_onDay(f12, d(2026, 11, 8)), 'unavailable');
    expect(_onDay(f12, d(2026, 11, 10)), 'amount 99600 paise, 25 days left');
    // (c) The core never returns Unavailable and never throws.
    expect(_core(2490000, 0, 0), _core(2490000, 0, 1));
    expect(_core(2490000, 0, -3), _core(2490000, 0, 1));
  });

  test('TC-017-37 the last day of the month counts one day left', () {
    expect(_onDay(e2Last, d(2026, 12, 4)), 'amount 2490000 paise, 1 days left');
  });
}
