import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phase3_fixtures.dart';
import 'fixtures.dart';

// F-012 plan §1.1: the day builder. Every literal is paise, from the F-012
// worked tables (tests/F-012 section 1) and the shared Phase 3 fixtures.

final CalendarDate _nov5 = d(2026, 11, 5);
final CalendarDate _nov6 = d(2026, 11, 6);
final CalendarDate _nov11 = d(2026, 11, 11);
final CalendarDate _nov12 = d(2026, 11, 12);
final CalendarDate _nov13 = d(2026, 11, 13);
final CalendarDate _nov14 = d(2026, 11, 14);

DaySummary _day(Phase3Fixture fixture, CalendarDate date) =>
    DaySummary.of(fixture.result, date);

int? _max(DaySummary day) => switch (day.coverOffer) {
  CoverAvailable(:final max) => max.value,
  _ => null,
};

void main() {
  test('TC-012-04 day details figures are the engine values in paise', () {
    final a13 = fixtureA;
    // (day, spent, result, covered) of the six rows of the §2.2 table.
    final rows = <(CalendarDate, int, int?)>[
      (_nov5, 50000, 33000),
      (_nov6, 100000, -17000),
      (_nov11, 113000, -30000),
      (_nov12, 0, 83000),
      (_nov13, 42000, 41000),
      (_nov14, 0, null),
    ];
    for (final (date, spent, result) in rows) {
      final day = _day(a13, date);
      expect(day.budget, p(83000), reason: date.iso);
      expect(day.spent, p(spent), reason: date.iso);
      expect(day.netSpent, p(spent), reason: date.iso);
      expect(day.result?.value, result, reason: date.iso);
      expect(day.covered, Paise.zero, reason: date.iso);
      expect(day.hasCover, isFalse, reason: date.iso);
      expect(day.hasRefunds, isFalse, reason: date.iso);
      expect(day.pot, p(200000), reason: date.iso);
    }
    expect(_max(_day(a13, _nov6)), 17000);
    expect(_max(_day(a13, _nov11)), 30000);
    for (final date in [_nov5, _nov12, _nov13, _nov14]) {
      expect(_day(a13, date).coverOffer, isA<CoverNone>(), reason: date.iso);
    }
  });

  test('TC-012-03 each day of example A has the words of the table', () {
    final a13 = fixtureA;
    expect(_day(a13, _nov5).resultKind, DayResultKind.saved);
    expect(_day(a13, _nov6).resultKind, DayResultKind.overspent);
    expect(_day(a13, _nov12).resultKind, DayResultKind.saved);
    final today = _day(a13, _nov13);
    expect(today.isLive, isTrue);
    expect(today.resultKind, DayResultKind.saved, reason: '₹410 left');
    expect(today.overspend, Paise.zero);
    final upcoming = _day(a13, _nov14);
    expect(upcoming.isUpcoming, isTrue);
    expect(upcoming.resultKind, isNull);
    expect(upcoming.overspend, Paise.zero);
    expect(_day(a13, _nov6).isLive, isFalse);
    expect(_day(a13, _nov6).overspend, p(17000));
  });

  test('TC-012-06 cover is offered only on overspent days of this month', () {
    final a13 = fixtureA;
    for (final day in [5, 7, 8, 9, 10, 12, 13, 14, 20]) {
      expect(
        _day(a13, d(2026, 11, day)).coverOffer,
        isA<CoverNone>(),
        reason: '$day Nov',
      );
    }
    for (final day in [6, 11]) {
      expect(
        _day(a13, d(2026, 11, day)).coverOffer,
        isA<CoverAvailable>(),
        reason: '$day Nov',
      );
    }
    // An overspent day of a month that has ended: no cover.
    final october = octNov.months.first.result(_nov13);
    final oct6 = DaySummary.of(october, d(2026, 10, 6));
    expect(oct6.isEnded, isTrue);
    expect(oct6.resultKind, DayResultKind.overspent);
    expect(oct6.coverOffer, isA<CoverNone>());
    expect(oct6.canAddSpend, isFalse);
    expect(oct6.canRemoveCover, isFalse);
    // The current month is not ended.
    expect(_day(a13, _nov6).isEnded, isFalse);
  });

  test(
    'TC-012-07 todays overspend can be covered, today within budget not',
    () {
      final today = _day(a13o, _nov13);
      expect(today.isLive, isTrue);
      expect(today.result, p(-17000));
      expect(today.resultKind, DayResultKind.overspent);
      expect(_max(today), 17000);
      expect(_day(fixtureA, _nov13).coverOffer, isA<CoverNone>());
    },
  );

  test('TC-012-10 a partly covered day offers the rest', () {
    final partly = fixtureA.plus(
      name: 'A+cover100',
      covers: [FixtureCover(day: _nov11, paise: 10000, madeAt: at(_nov13, 9))],
    );
    final day = _day(partly, _nov11);
    expect(day.covered, p(10000));
    expect(day.result, p(-20000));
    expect(day.overspend, p(20000));
    expect(_max(day), 20000);
    expect(day.hasCover, isTrue);
    expect(day.canRemoveCover, isTrue);
    expect(day.isFullyCovered, isFalse);
    expect(day.pot, p(190000));
  });

  test('TC-012-08 a fully covered day is on budget with a Remove', () {
    final day = _day(a13c300, _nov11);
    expect(day.covered, p(30000));
    expect(day.result, Paise.zero);
    expect(day.resultKind, DayResultKind.onBudget);
    expect(day.coverOffer, isA<CoverNone>());
    expect(day.isFullyCovered, isTrue);
    expect(day.canRemoveCover, isTrue);
    expect(day.coverIds, {1});
    expect(day.pot, p(170000));
    // Another day has none of it.
    expect(_day(a13c300, _nov12).coverIds, isEmpty);
    expect(_day(a13c300, _nov12).isFullyCovered, isFalse);
  });

  test('TC-012-11 the pot is the limit when it is smaller', () {
    final day = _day(p250, _nov11);
    expect(day.pot, p(25000));
    expect(day.overspend, p(30000));
    final offer = day.coverOffer as CoverAvailable;
    expect(offer.max, p(25000));
    expect(offer.limitedByPot, isTrue);
    // With the whole pot the day is overspent by the rest and the pot is 0.
    final covered = p250.plus(
      name: 'P250+cover',
      covers: [FixtureCover(day: _nov11, paise: 25000, madeAt: at(_nov13, 9))],
    );
    final after = _day(covered, _nov11);
    expect(after.result, p(-5000));
    expect(after.pot, Paise.zero);
    expect(after.coverOffer, isA<CoverPotEmpty>());
  });

  test('TC-012-10 the overspend is the limit when the pot is larger', () {
    final offer = _day(fixtureA, _nov11).coverOffer as CoverAvailable;
    expect(offer.limitedByPot, isFalse);
  });

  test('TC-012-15 an empty pot offers no button', () {
    final day = _day(s8, _nov6);
    expect(day.budget, Paise.zero);
    expect(day.spent, p(20000));
    expect(day.resultKind, DayResultKind.overspent);
    expect(day.overspend, p(20000));
    expect(day.pot, Paise.zero);
    expect(day.coverOffer, isA<CoverPotEmpty>());
  });

  test('TC-012-14 the paise maximum 47.78 and the exact zero after it', () {
    final m20x = m20.mapEntries(
      'M20-18',
      (entry) =>
          entry.date == d(2026, 11, 18) ? entry.copyWith(paise: 60000) : entry,
    );
    final nov18 = d(2026, 11, 18);
    final day = _day(m20x, nov18);
    expect(day.overspend, p(4778));
    expect(day.pot, p(181336));
    final offer = day.coverOffer as CoverAvailable;
    expect(offer.max, p(4778));
    expect(offer.limitedByPot, isFalse);
    expect(amountInputText(offer.max), '47.78');
    final covered = m20x.plus(
      name: 'M20-18c',
      covers: [FixtureCover(day: nov18, paise: 4778, madeAt: at(nov18, 21))],
    );
    expect(_day(covered, nov18).result, Paise.zero);
    expect(_day(covered, nov18).resultKind, DayResultKind.onBudget);
  });

  test(
    'TC-012-47 a day overspent by less than a rupee covers to the paisa',
    () {
      final tiny = fixtureA.plus(
        name: 'A+40',
        entries: [fixtureSpend(_nov12, 83040)],
      );
      final day = _day(tiny, _nov12);
      expect(day.result, p(-40));
      expect(day.resultKind, DayResultKind.overspentUnderRupee);
      expect(day.pot, p(117000));
      final offer = day.coverOffer as CoverAvailable;
      expect(offer.max, p(40));
      expect(amountInputText(offer.max), '0.40');
    },
  );

  test('TC-012-72 overspend under one rupee flag at 99 and 100 paise', () {
    DaySummary over(int paise) => _day(
      fixtureA.plus(
        name: 'A+$paise',
        entries: [fixtureSpend(_nov12, 83000 + paise)],
      ),
      _nov12,
    );
    expect(over(99).overspendUnderRupee, isTrue, reason: '(a) 99 paise');
    expect(over(1).overspendUnderRupee, isTrue, reason: '(c) 1 paisa');
    expect(over(100).overspendUnderRupee, isFalse, reason: '(b) exactly ₹1');
    expect(over(100).overspend, p(100));
    expect(
      _day(fixtureA, _nov12).overspendUnderRupee,
      isFalse,
      reason: '(d) saved day',
    );
    expect(over(100000).overspendUnderRupee, isFalse, reason: '(e) ₹1,000');
  });

  test('TC-012-47 overspend under a rupee is under 100 paise', () {
    DaySummary nov12Spent(int paise) => _day(
      fixtureA.plus(
        name: 'A+$paise',
        entries: [fixtureSpend(_nov12, 83000 + paise)],
      ),
      _nov12,
    );
    expect(nov12Spent(99).overspend, p(99));
    expect(nov12Spent(99).overspendUnderRupee, isTrue);
    expect(nov12Spent(1).overspendUnderRupee, isTrue);
    expect(nov12Spent(100).overspend, p(100));
    expect(nov12Spent(100).overspendUnderRupee, isFalse);
    // Not overspent: never "less than a rupee".
    expect(_day(fixtureA, _nov12).overspendUnderRupee, isFalse);
    expect(_day(fixtureA, _nov14).overspendUnderRupee, isFalse);
  });

  test('TC-012-03 result words follow the exact paise (D-050, D-055)', () {
    final words = <int, DayResultKind>{
      33000: DayResultKind.saved,
      100: DayResultKind.saved,
      99: DayResultKind.savedUnderRupee,
      1: DayResultKind.savedUnderRupee,
      0: DayResultKind.onBudget,
      -1: DayResultKind.overspentUnderRupee,
      -99: DayResultKind.overspentUnderRupee,
      -100: DayResultKind.overspent,
      -30000: DayResultKind.overspent,
    };
    for (final MapEntry(key: paise, value: kind) in words.entries) {
      expect(dayResultKind(p(paise)), kind, reason: '$paise paise');
    }
  });

  test('TC-012-25 a refund day shows spent, refunds and net', () {
    final day = _day(r16, d(2026, 11, 16));
    expect(day.spent, p(70000));
    expect(day.moneyIn, p(50000));
    expect(day.netSpent, p(20000));
    expect(day.result, p(63000));
    expect(day.resultKind, DayResultKind.saved);
    expect(day.hasRefunds, isTrue);
    expect(_day(r16, d(2026, 11, 17)).hasRefunds, isFalse);
  });

  test('TC-012-26 a refund larger than the spend gives a negative net', () {
    final big = r16.mapEntries(
      'R16-150',
      (entry) => entry.moneyIn ? entry.copyWith(paise: 150000) : entry,
    );
    final day = _day(big, d(2026, 11, 16));
    expect(day.netSpent, p(-80000));
    expect(day.result, p(163000));
    expect(day.resultKind, DayResultKind.saved);
  });

  test('TC-012-27 the period start day knows what changed', () {
    final m = m20;
    final change = _day(m, d(2026, 11, 13));
    expect(change.isChangeDay, isTrue);
    expect(change.budget, p(55223));
    final salary = change.changes.single;
    expect(salary.field, PeriodField.salary);
    expect((salary.before, salary.after), (p(4000000), p(3500000)));
    expect(_day(m, d(2026, 11, 14)).isChangeDay, isFalse);
    expect(_day(m, d(2026, 11, 14)).changes, isEmpty);
    // The first period's own first day is not a change.
    expect(_day(m, d(2026, 11, 1)).isChangeDay, isFalse);
    // Shortfall day (example S).
    final shortfall = _day(s8, _nov6);
    expect(shortfall.budget, Paise.zero);
    expect(shortfall.resultKind, DayResultKind.overspent);
  });

  test('TC-012-73 same day changes net out: changed back has no changes', () {
    final month = m20.months.first;
    final first = month.periods.first;
    final back = month.copyWith(
      periods: [
        ...month.periods,
        BudgetPeriod(
          start: d(2026, 11, 13),
          changedAt: month.periods.last.changedAt + 1000,
          values: first.values,
        ),
      ],
    );
    final day = DaySummary.of(back.result(d(2026, 11, 20)), d(2026, 11, 13));
    expect(day.isChangeDay, isTrue);
    expect(day.changes, isEmpty);
    // A double change that ends on a new salary names the net change only.
    final net = DaySummary.of(m20.result, d(2026, 11, 13));
    expect(net.changes, hasLength(1));
  });

  test('TC-012-41 a cover cut to zero by D-040 has no Remove', () {
    // W3, then the 5 Nov spend raised to 83,000: the pot falls to 0 and the
    // 17,000 cover on 6 Nov is cut to 0 by the engine (nothing stored yet).
    final cut = w3.mapEntries(
      'W3-cut',
      (entry) => entry.date == _nov5 ? entry.copyWith(paise: 83000) : entry,
    );
    final day = _day(cut, _nov6);
    expect(day.covered, Paise.zero);
    expect(day.hasCover, isFalse);
    expect(day.canRemoveCover, isFalse);
    expect(day.isFullyCovered, isFalse);
    expect(day.coverIds, {1}, reason: 'the stored row is still removable');
    expect(day.resultKind, DayResultKind.overspent);
    // Before the edit the same day is covered and removable.
    final before = _day(w3, _nov6);
    expect(before.canRemoveCover, isTrue);
    expect(before.coverIds, {1});
  });

  test('TC-012-28 a past month is read only', () {
    final october = octNov.months.first.result(_nov13);
    final day = DaySummary.of(october, d(2026, 10, 6));
    expect(day.isEnded, isTrue);
    expect(day.budget!.value ~/ 100, 803);
    expect(day.spent, p(100000));
    expect(day.overspend.value ~/ 100, 196);
    expect(day.canAddSpend, isFalse);
    expect(day.coverOffer, isA<CoverNone>());
    // A covered day of a month that has ended offers no Remove.
    final covered = fixtureA.plus(
      name: 'A+cover',
      covers: [FixtureCover(day: _nov11, paise: 30000, madeAt: at(_nov13, 9))],
    );
    final newMonthDue = covered.copyWith(name: 'A5Dec', today: d(2026, 12, 5));
    final ended = _day(newMonthDue, _nov11);
    expect(ended.isEnded, isTrue);
    expect(ended.hasCover, isTrue);
    expect(ended.canRemoveCover, isFalse);
    expect(ended.isFullyCovered, isFalse);
    expect(_day(newMonthDue, _nov6).coverOffer, isA<CoverNone>());
  });

  test('TC-012-29 an upcoming day has only its budget', () {
    final day = _day(fixtureA, _nov14);
    expect(day.status, DayStatus.upcoming);
    expect(day.budget, p(83000));
    expect(day.result, isNull);
    expect(day.resultKind, isNull);
    expect(day.canAddSpend, isFalse);
    expect(day.isBudgeted, isTrue);
  });

  test('TC-012-62 a not budgeted day is only a note', () {
    final day = _day(f12, d(2026, 11, 7));
    expect(day.status, DayStatus.notBudgeted);
    expect(day.isBudgeted, isFalse);
    expect(day.budget, isNull);
    expect(day.result, isNull);
    expect(day.firstBudgetedDay, d(2026, 11, 10));
    expect(day.canAddSpend, isFalse);
    expect(day.coverOffer, isA<CoverNone>());
  });

  test('TC-012-18 add spend is offered on a budgeted day up to today', () {
    expect(_day(fixtureA, d(2026, 11, 8)).canAddSpend, isTrue);
    expect(_day(fixtureA, _nov13).canAddSpend, isTrue);
  });

  test('TC-012-03 a date outside the month is refused', () {
    expect(
      () => DaySummary.of(fixtureA.result, d(2026, 12, 5)),
      throwsArgumentError,
    );
  });

  test('TC-012-05 entries are listed newest added first, edits keep order', () {
    final spends = [
      spend(_nov12, 100, id: 1),
      Spend(id: 2, date: _nov13, amount: p(25000), createdAt: at(_nov13, 13)),
      Spend(id: 3, date: _nov13, amount: p(37000), createdAt: at(_nov13, 20)),
      // Same time as 2: the higher id is the newer one.
      Spend(
        id: 4,
        date: _nov13,
        amount: p(50000),
        createdAt: at(_nov13, 13),
        direction: SpendDirection.moneyIn,
      ),
    ];
    expect([for (final s in spendsOnDay(spends, _nov13)) s.id], [3, 4, 2]);
    expect(spendsOnDay(spends, _nov12).single.id, 1);
    expect(spendsOnDay(spends, _nov14), isEmpty);
    // Editing the amount of 2 does not move it: ordering ignores the amount.
    final edited = [
      for (final s in spends)
        if (s.id == 2)
          Spend(id: 2, date: _nov13, amount: p(26000), createdAt: s.createdAt)
        else
          s,
    ];
    expect([for (final s in spendsOnDay(edited, _nov13)) s.id], [3, 4, 2]);
  });
}
