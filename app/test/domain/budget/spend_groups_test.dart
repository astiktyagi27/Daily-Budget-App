import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

final CalendarDate _nov9 = d(2026, 11, 9);

Spend _spend(int id, CalendarDate date, int amount, int createdAt) =>
    Spend(id: id, date: date, amount: p(amount), createdAt: createdAt);

void main() {
  test('TC-009-13 groups newest day first and newest added first', () {
    final groups = groupSpendsByDay([
      _spend(1, d(2026, 11, 5), 10000, at(d(2026, 11, 5), 10)),
      _spend(2, d(2026, 11, 8), 31000, at(d(2026, 11, 8), 10)),
      _spend(3, _nov9, 25000, at(_nov9, 10)),
      _spend(4, _nov9, 40000, at(_nov9, 13)),
    ], _nov9);
    expect(
      [for (final g in groups) g.date],
      [_nov9, d(2026, 11, 8), d(2026, 11, 5)],
    );
    expect(
      [for (final g in groups) g.label],
      [DayLabel.today, DayLabel.yesterday, DayLabel.other],
    );
    expect([for (final g in groups) g.total], [p(65000), p(31000), p(10000)]);
    expect(
      [for (final s in groups.first.spends) s.amount],
      [p(40000), p(25000)],
    );
  });

  test('TC-009-13 input order and edits never reorder a day', () {
    final spends = [
      _spend(1, _nov9, 100, at(_nov9, 9)),
      _spend(2, _nov9, 200, at(_nov9, 11)),
      _spend(3, _nov9, 300, at(_nov9, 11)),
      _spend(4, _nov9, 400, at(_nov9, 10)),
    ];
    List<int> ids(List<Spend> list) => [
      for (final s in groupSpendsByDay(list, _nov9).single.spends) s.id,
    ];
    // Same time: the higher id (added later) first.
    expect(ids(spends), [3, 2, 4, 1]);
    expect(ids(spends.reversed.toList()), [3, 2, 4, 1]);
    // An edit changes the amount, not the created time: the row stays.
    final edited = [
      for (final s in spends)
        if (s.id == 1) _spend(1, _nov9, 999, s.createdAt) else s,
    ];
    expect(ids(edited), [3, 2, 4, 1]);
  });

  test(
    'TC-009-13 no spends give no groups and the last spend of a day ends it',
    () {
      expect(groupSpendsByDay(const [], _nov9), isEmpty);
      final one = _spend(1, _nov9, 100, at(_nov9, 9));
      final other = _spend(2, d(2026, 11, 8), 100, at(d(2026, 11, 8), 9));
      expect(groupSpendsByDay([one, other], _nov9), hasLength(2));
      expect(groupSpendsByDay([other], _nov9).single.date, d(2026, 11, 8));
    },
  );

  test('TC-009-32 fifty-five spends on a day total exactly', () {
    final groups = groupSpendsByDay([
      for (var i = 0; i < 55; i++) _spend(i, _nov9, 101, at(_nov9, 9) + i),
    ], _nov9);
    expect(groups.single.total, p(5555));
    expect(groups.single.spends, hasLength(55));
    expect(groups.single.spends.first.id, 54);
  });

  test('TC-009-30 a spend dated after today keeps its own heading', () {
    final nov10 = d(2026, 11, 10);
    final groups = groupSpendsByDay([
      _spend(1, d(2026, 11, 12), 5000, at(d(2026, 11, 11), 9)),
      _spend(2, nov10, 3000, at(nov10, 9)),
    ], nov10);
    expect(
      [for (final g in groups) (g.date, g.label)],
      [(d(2026, 11, 12), DayLabel.other), (nov10, DayLabel.today)],
    );
  });

  test('TC-009-13 the labels follow today when midnight passes', () {
    final spends = [_spend(1, _nov9, 100, at(_nov9, 9))];
    expect(groupSpendsByDay(spends, _nov9).single.label, DayLabel.today);
    expect(
      groupSpendsByDay(spends, d(2026, 11, 10)).single.label,
      DayLabel.yesterday,
    );
    expect(
      groupSpendsByDay(spends, d(2026, 11, 11)).single.label,
      DayLabel.other,
    );
  });

  test('TC-009-13 money in lowers the day total', () {
    final groups = groupSpendsByDay([
      _spend(1, _nov9, 30000, at(_nov9, 9)),
      Spend(
        id: 2,
        date: _nov9,
        amount: p(50000),
        createdAt: at(_nov9, 10),
        direction: SpendDirection.moneyIn,
      ),
    ], _nov9);
    expect(groups.single.total, p(-20000));
  });
}
