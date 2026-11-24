import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phase3_fixtures.dart';
import 'fixtures.dart';

CalendarDate _nov(int day) => d(2026, 11, day);

MonthFigures _figuresOf(Phase3Fixture fixture, [CalendarDate? today]) =>
    monthFigures(fixture.current.result(today ?? fixture.today));

({int saved, int onBudget, int overspent, int covered}) _counts(
  int saved,
  int onBudget,
  int overspent,
  int covered,
) => (saved: saved, onBudget: onBudget, overspent: overspent, covered: covered);

void main() {
  test('TC-013-13 statistics for example a are exact to the paisa', () {
    final f = _figuresOf(fixtureA);
    expect(f.endedDays, 8);
    expect(f.noEndedDays, isFalse);
    expect(f.average, const Paise(63875));
    expect(f.highest, (
      date: _nov(11),
      amount: const Paise(113000),
      moreDays: 0,
    ));
    expect(f.counts, _counts(4, 2, 2, 0));
    // 5 - 12 Nov: saved, overspent, on budget, saved, saved, on budget,
    // overspent, saved. Today (13 Nov) is not in the strip.
    expect(f.strip, [
      DayStatus.saved,
      DayStatus.overspent,
      DayStatus.onBudget,
      DayStatus.saved,
      DayStatus.saved,
      DayStatus.onBudget,
      DayStatus.overspent,
      DayStatus.saved,
    ]);
  });

  test('TC-013-15 a fully covered day counts as on budget, a part covered '
      'day as overspent', () {
    final covered = _figuresOf(fixtureAPlusCover);
    expect(covered.counts, _counts(4, 3, 1, 1));
    // A cover is not a spend: highest and average are unchanged.
    expect(covered.average, const Paise(63875));
    expect(covered.highest!.date, _nov(11));
    expect(covered.highest!.amount, const Paise(113000));
    expect(covered.strip[6], DayStatus.onBudget);

    // M20: 6 Nov is covered 20,000 of 44,000, so it stays overspent but
    // counts as covered.
    final m = _figuresOf(fixtureM20);
    expect(m.counts.covered, 1);
    expect(m.strip[5], DayStatus.overspent);
  });

  test('TC-013-16 ties go to the earliest date', () {
    final tie = fixtureA.mapEntries(
      'A tie',
      (entry) => entry.date == _nov(6) ? entry.copyWith(paise: 113000) : entry,
    );
    final f = _figuresOf(tie);
    expect(f.highest, (
      date: _nov(6),
      amount: const Paise(113000),
      moreDays: 1,
    ));

    final three = tie.mapEntries(
      'A tie 3',
      (entry) => entry.date == _nov(5) ? entry.copyWith(paise: 113000) : entry,
    );
    expect(_figuresOf(three).highest, (
      date: _nov(5),
      amount: const Paise(113000),
      moreDays: 2,
    ));
  });

  test('TC-013-19 average is rounded toward zero', () {
    final f = _figuresOf(fixtureS);
    expect(f.endedDays, 3);
    expect(f.average, const Paise(6666)); // 20,000 / 3
    expect(f.highest, (date: _nov(6), amount: const Paise(20000), moreDays: 0));
    expect(f.counts, _counts(0, 2, 1, 0));
    expect(f.strip, [
      DayStatus.onBudget,
      DayStatus.overspent,
      DayStatus.onBudget,
    ]);
  });

  test('TC-013-20 a mid month start counts only budgeted days', () {
    final f = _figuresOf(fixtureF);
    expect(f.endedDays, 2);
    expect(f.average, const Paise(100000));
    expect(f.highest, (
      date: _nov(10),
      amount: const Paise(150000),
      moreDays: 0,
    ));
    expect(f.counts, _counts(1, 0, 1, 0));
  });

  test('TC-013-21 a past month counts all its days', () {
    final october = fixtureO1.months.first.result(fixtureO1.today);
    final f = monthFigures(october);
    expect(f.endedDays, 31);
    expect(f.average, const Paise(7258)); // 2,25,000 / 31
    expect(f.highest, (
      date: d(2026, 10, 10),
      amount: const Paise(140000),
      moreDays: 0,
    ));
    expect(f.counts, _counts(30, 0, 1, 0));
  });

  test('TC-013-33 a negative average rounds toward zero', () {
    final n = _figuresOf(fixtureN);
    expect(n.endedDays, 8);
    expect(n.average, const Paise(-3750));
    expect(n.highest, (date: _nov(5), amount: const Paise(20000), moreDays: 0));
    expect(n.counts, _counts(8, 0, 0, 0));

    // -30,001 / 8 is -3,750.125: toward zero is -3,750, not -3,751.
    final odd = monthFigures(
      e2Month(
        today: _nov(13),
        spends: [
          spend(_nov(5), 20000, id: 1),
          spend(_nov(6), 50001, id: 2, moneyIn: true),
        ],
      ),
    );
    expect(odd.average, const Paise(-3750));
  });

  test('TC-013-34 no spends: no highest day and a zero average', () {
    final f = monthFigures(e2Month(today: _nov(13)));
    expect(f.highest, isNull);
    expect(f.average, Paise.zero);
    expect(f.counts, _counts(8, 0, 0, 0));
  });

  test('TC-013-17 the first day has not ended: no figures', () {
    final f = _figuresOf(e2Day1);
    expect(f.endedDays, 0);
    expect(f.noEndedDays, isTrue);
    expect(f.highest, isNull);
    expect(f.average, isNull);
    expect(f.strip, isEmpty);
    expect(f.counts, _counts(0, 0, 0, 0));

    // A mid month first day: 5 - 9 Nov are not budgeted and not counted.
    final first = monthFigures(fixtureF.current.result(_nov(10)));
    expect(first.noEndedDays, isTrue);
  });

  test('TC-013-40 the running day is left out of the figures', () {
    final noon = _figuresOf(fixtureA);
    final big = fixtureA.plus(
      name: 'A big',
      entries: [fixtureSpend(_nov(13), 1000000)],
    );
    // A big spend today does not move any figure until midnight.
    final bigNoon = _figuresOf(big);
    expect(bigNoon.average, noon.average);
    expect(bigNoon.highest, noon.highest);
    expect(bigNoon.counts, noon.counts);

    final after = _figuresOf(fixtureA, _nov(14));
    expect(after.endedDays, 9);
    expect(after.average, const Paise(61444)); // 5,53,000 / 9
    expect(after.counts, _counts(5, 2, 2, 0));

    final bigAfter = _figuresOf(big, _nov(14));
    expect(bigAfter.average, const Paise(172555)); // 15,53,000 / 9
    expect(bigAfter.highest, (
      date: _nov(13),
      amount: const Paise(1042000),
      moreDays: 0,
    ));
    expect(bigAfter.counts, _counts(4, 2, 3, 0));
  });

  test('TC-013-41 a mid month change needs no special display', () {
    final f = _figuresOf(fixtureM20);
    expect(f.endedDays, 19);
    expect(f.average, const Paise(63947)); // 12,15,000 / 19
    expect(f.highest, (
      date: _nov(6),
      amount: const Paise(127000),
      moreDays: 0,
    ));
    expect(f.counts, _counts(12, 6, 1, 1));
  });

  test('TC-013-46 highest day with only refunds', () {
    final f = monthFigures(
      e2Month(
        today: _nov(13),
        spends: [spend(_nov(6), 50000, id: 1, moneyIn: true)],
      ),
    );
    expect(f.highest, isNull);
    expect(f.average, const Paise(-6250)); // -50,000 / 8
    expect(f.counts, _counts(8, 0, 0, 0));
  });

  test('TC-013-25 ten crore for thirty one days stays exact', () {
    const crore10 = 10000000000;
    final october = computeMonth(
      MonthInput(
        month: oct2026,
        firstBudgetedDay: d(2026, 10, 5),
        periods: [period(d(2026, 10, 5), e2Values())],
        today: _nov(5),
        spends: [
          for (var day = 0; day < 31; day++)
            Spend(
              id: day + 1,
              date: d(2026, 10, 5).addDays(day),
              amount: const Paise(crore10),
              createdAt: day,
            ),
        ],
      ),
    );
    final f = monthFigures(october);
    expect(f.endedDays, 31);
    expect(f.average, const Paise(crore10));
    expect(f.highest, (
      date: d(2026, 10, 5),
      amount: const Paise(crore10),
      moreDays: 30,
    ));
    expect(f.counts, _counts(0, 0, 31, 0));
  });
}
