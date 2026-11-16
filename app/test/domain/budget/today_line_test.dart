import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

// The Today line numbers (plan F-009 §1.1): worked from the engine result.

final CalendarDate _nov9 = d(2026, 11, 9);

/// The E2 month on 9 Nov with the worked-example spends of [amounts] (paise)
/// on 9 Nov.
MonthResult _nov9With(List<int> amounts, {List<Spend> more = const []}) =>
    e2Month(
      today: _nov9,
      spends: [
        for (final (i, amount) in amounts.indexed)
          spend(_nov9, amount, id: i + 1),
        ...more,
      ],
    );

/// (budget, net spent, amount after the word, kind) of the Today line.
(int, int, int, TodayResultKind) _line(MonthResult result) {
  final line = TodayLine.from(result);
  return (line.budget.value, line.netSpent.value, line.amount.value, line.kind);
}

void main() {
  test('TC-009-10 the worked example gives the engine exact values', () {
    // After each step: today's spent, left (budget 83,000 on 9 Nov).
    final steps = <(List<int>, int, int)>[
      ([25000], 25000, 58000), // 1 add 250
      ([25000, 40000], 65000, 18000), // 2 add 400
      ([25000, 40000, 30050], 95050, -12050), // 3 add 300.50
      ([25000, 27000, 30050], 82050, 950), // 4 edit Groceries to 270
      ([25000, 27000], 52000, 31000), // 5 delete the 300.50
    ];
    for (final (i, (amounts, spent, left)) in steps.indexed) {
      final line = TodayLine.from(_nov9With(amounts));
      expect(line.budget, p(83000), reason: 'step ${i + 1}');
      expect(line.netSpent, p(spent), reason: 'step ${i + 1}');
      expect(line.result, p(left), reason: 'step ${i + 1}');
    }
    // 6 add 310 dated 8 Nov: today is unchanged, 8 Nov spent is 31,000.
    final six = _nov9With(
      [25000, 27000],
      more: [spend(d(2026, 11, 8), 31000, id: 9)],
    );
    final line = TodayLine.from(six);
    expect((line.netSpent, line.result), (p(52000), p(31000)));
    expect(six.dayOn(d(2026, 11, 8)).spent, p(31000));
  });

  test('TC-009-09 the Today line parts and words for every step', () {
    expect(_line(_nov9With([25000])), (
      83000,
      25000,
      58000,
      TodayResultKind.leftToday,
    ));
    expect(_line(_nov9With([25000, 40000])), (
      83000,
      65000,
      18000,
      TodayResultKind.leftToday,
    ));
    // 12,050 paise over shows as `overspent ₹120`; 950 left as `₹9 left today`.
    expect(_line(_nov9With([25000, 40000, 30050])), (
      83000,
      95050,
      12050,
      TodayResultKind.overspent,
    ));
    expect(_line(_nov9With([25000, 27000, 30050])), (
      83000,
      82050,
      950,
      TodayResultKind.leftToday,
    ));
    expect(_line(_nov9With([25000, 27000])), (
      83000,
      52000,
      31000,
      TodayResultKind.leftToday,
    ));
  });

  test('TC-009-39 the Today line in each result state', () {
    expect(_line(_nov9With([])), (83000, 0, 83000, TodayResultKind.leftToday));
    expect(_line(_nov9With([83000])), (
      83000,
      83000,
      0,
      TodayResultKind.onBudget,
    ));
    expect(_line(_nov9With([83100])), (
      83000,
      83100,
      100,
      TodayResultKind.overspent,
    ));
  });

  test('TC-009-40 less than a rupee either way gets its own words', () {
    // ₹829.99 spent: 1 paisa left. ₹830.01: 1 paisa over.
    expect(_line(_nov9With([82999])).$4, TodayResultKind.leftUnderRupee);
    expect(_line(_nov9With([83001])).$4, TodayResultKind.overspentUnderRupee);
    // The edges of the rupee: 99 paise is under, 100 is not.
    expect(_line(_nov9With([82901])).$4, TodayResultKind.leftUnderRupee);
    expect(_line(_nov9With([82900])).$4, TodayResultKind.leftToday);
    expect(_line(_nov9With([83099])).$4, TodayResultKind.overspentUnderRupee);
    expect(_line(_nov9With([83100])).$4, TodayResultKind.overspent);
    expect(TodayLine.from(_nov9With([82999])).amount, p(1));
  });

  test('TC-009-23 the line uses the latest period after a change', () {
    final nov19 = d(2026, 11, 19);
    final nov20 = d(2026, 11, 20);
    final result = e2Month(
      today: nov20,
      periods: [
        period(d(2026, 11, 5), e2Values()),
        period(nov20, e2Values(rent: 1300000)),
      ],
      spends: [spend(nov19, 25000, id: 1), spend(nov20, 25000, id: 2)],
    );
    expect(_line(result), (63000, 25000, 38000, TodayResultKind.leftToday));
    // 19 Nov is still judged against its own 83,000: saved 58,000.
    expect(result.dayOn(nov19).budget, p(83000));
    expect(result.dayOn(nov19).result, p(58000));
    expect(TodayLine.from(result).hasShortfall, isFalse);
  });

  test('TC-009-23 a shortfall month has a zero budget and the shortfall', () {
    final result = e2Month(
      today: d(2026, 11, 6),
      periods: [period(d(2026, 11, 5), s1Values(), continued: true)],
      spends: [spend(d(2026, 11, 6), 20000, id: 1)],
    );
    expect(_line(result), (0, 20000, 20000, TodayResultKind.overspent));
    final line = TodayLine.from(result);
    expect((line.shortfall, line.hasShortfall), (p(100000), true));
  });

  test('TC-009-47 a past day is judged against the budget of its day', () {
    final nov19 = d(2026, 11, 19);
    final nov20 = d(2026, 11, 20);
    final result = e2Month(
      today: d(2026, 11, 22),
      periods: [
        period(d(2026, 11, 5), e2Values()),
        period(nov20, e2Values(rent: 1300000)),
      ],
      spends: [spend(nov19, 70000, id: 1)],
    );
    expect(result.dayOn(nov19).result, p(13000));
    expect(_line(result), (63000, 0, 63000, TodayResultKind.leftToday));
  });

  test('TC-009-24 the leftover joins the pot at midnight', () {
    final spends = [
      for (var day = 5; day <= 8; day++)
        spend(d(2026, 11, day), 83000, id: day),
      spend(_nov9, 25000, id: 20),
    ];
    final today = e2Month(today: _nov9, spends: spends);
    expect(TodayLine.from(today).result, p(58000));
    expect(today.totals.pot, Paise.zero);

    final tomorrow = e2Month(today: d(2026, 11, 10), spends: spends);
    expect(tomorrow.dayOn(_nov9).result, p(58000));
    expect(tomorrow.totals.pot, p(58000));
    expect(_line(tomorrow), (83000, 0, 83000, TodayResultKind.leftToday));
  });

  test('TC-009-33 a ten crore spend is a huge overspend without overflow', () {
    final line = TodayLine.from(_nov9With([10000000000]));
    expect(line.netSpent, p(10000000000));
    // ₹9,99,99,170 over.
    expect(
      (line.amount, line.kind),
      (p(9999917000), TodayResultKind.overspent),
    );
  });

  test('TC-009-32 many spends on one day add up exactly', () {
    final line = TodayLine.from(_nov9With(List.filled(55, 101)));
    expect(line.netSpent, p(5555));
    expect(line.result, p(77445));
  });

  test('TC-009-09 money in reduces the net spend on the line', () {
    final line = TodayLine.from(
      _nov9With([25000], more: [spend(_nov9, 10000, id: 9, moneyIn: true)]),
    );
    expect((line.netSpent, line.result), (p(15000), p(68000)));
  });

  test('TC-009-24 today outside the budgeted days has no line', () {
    expect(
      () => TodayLine.from(e2Month(today: d(2026, 11, 4))),
      throwsArgumentError,
    );
    expect(
      () => TodayLine.from(e2Month(today: d(2026, 12, 5))),
      throwsArgumentError,
    );
    // A mid-month start: days before the first budgeted day are not today.
    final late = e2Month(
      today: d(2026, 11, 8),
      firstBudgetedDay: d(2026, 11, 10),
      periods: [
        period(d(2026, 11, 10), MidMonthStartValues(moneyLeft: p(2490000))),
      ],
    );
    expect(() => TodayLine.from(late), throwsArgumentError);
  });

  test('TC-009-17 a covered day counts in the result', () {
    // 6 Nov overspent 17,000 and covered; today is 8 Nov.
    final result = e2Month(
      today: d(2026, 11, 8),
      spends: [
        spend(d(2026, 11, 5), 50000, id: 1),
        spend(d(2026, 11, 6), 100000, id: 2),
        spend(d(2026, 11, 8), 20000, id: 3),
      ],
      covers: [cover(1, d(2026, 11, 6), 17000, at(d(2026, 11, 7), 21))],
    );
    expect(_line(result), (83000, 20000, 63000, TodayResultKind.leftToday));
    expect(result.dayOn(d(2026, 11, 6)).result, Paise.zero);
  });
}
