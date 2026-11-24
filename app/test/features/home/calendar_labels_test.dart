import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/home/calendar/calendar_labels.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/phase3_fixtures.dart';

// F-011 §2.3 and calendar.md §4: one screen-reader sentence per cell.

String? _label(Phase3Fixture f, CalendarDate date, {bool late = false}) {
  final cell = CalendarGrid.of(f.result).cells
      .singleWhere((c) => c.date == date);
  return calendarCellLabel(cell, lateSetup: late);
}

CalendarDate _nov(int day) => d(2026, 11, day);

void main() {
  test('TC-011-08 example A labels read as the table', () {
    const expected = {
      5: 'Thursday 5 November, spent ₹500, saved ₹330',
      6: 'Friday 6 November, spent ₹1,000, overspent ₹170',
      7: 'Saturday 7 November, spent ₹830, on budget',
      8: 'Sunday 8 November, spent ₹200, saved ₹630',
      9: 'Monday 9 November, spent ₹620, saved ₹210',
      10: 'Tuesday 10 November, spent ₹830, on budget',
      11: 'Wednesday 11 November, spent ₹1,130, overspent ₹300',
      12: 'Thursday 12 November, nothing spent, saved ₹830',
      13: 'Today, Friday 13 November, spent ₹420 so far, ₹410 left',
      14: 'Saturday 14 November, upcoming',
    };
    for (final MapEntry(key: day, value: label) in expected.entries) {
      expect(_label(fixtureA, _nov(day)), label, reason: '$day Nov');
    }
    final grid = CalendarGrid.of(fixtureA.result);
    expect(calendarCellLabel(grid.cells.first), isNull, reason: 'outside');
  });

  test('TC-011-14 covered days say what savings covered', () {
    expect(
      _label(a13c300, _nov(11)),
      'Wednesday 11 November, spent ₹1,130, on budget, '
      '₹300 covered from savings',
    );
    final partly = fixtureA.plus(
      name: 'A+100',
      covers: [
        FixtureCover(day: _nov(11), paise: 10000, madeAt: at(_nov(13), 9)),
      ],
    );
    expect(
      _label(partly, _nov(11)),
      'Wednesday 11 November, spent ₹1,130, overspent ₹200 after ₹100 from '
      'savings',
    );
  });

  test('TC-011-45 today overspent, nothing spent, on budget today', () {
    expect(
      _label(a13o, _nov(13)),
      'Today, Friday 13 November, spent ₹1,000 so far, overspent ₹170',
    );
    final none = fixtureA.copyWith(
      name: 'A-none',
      entries: [
        for (final e in fixtureA.current.entries)
          if (e.date != _nov(13)) e,
      ],
    );
    expect(
      _label(none, _nov(13)),
      'Today, Friday 13 November, spent ₹0 so far, ₹830 left',
    );
    expect(
      _label(s8, _nov(8)),
      'Today, Sunday 8 November, spent ₹0 so far, on budget',
    );
  });

  test('TC-011-16 shortfall month labels', () {
    expect(
      _label(s8, _nov(6)),
      'Friday 6 November, spent ₹200, overspent ₹200',
    );
    expect(
      _label(s8, _nov(5)),
      'Thursday 5 November, nothing spent, on budget',
    );
  });

  test('TC-011-18 the change day adds its words', () {
    final label = _label(m20, _nov(13))!;
    expect(label, endsWith(', budget changed this day'));
    expect(_label(m20, _nov(14)), isNot(contains('changed')));
  });

  test('TC-011-20 not budgeted labels carry the weekday', () {
    expect(
      _label(f12, _nov(5)),
      'Thursday 5 November, not budgeted, before you started',
    );
    expect(
      _label(f12, _nov(5), late: true),
      "Thursday 5 November, not budgeted, before this month's setup",
    );
  });

  test('TC-011-22 refund days say net after refunds', () {
    FixtureEntry spent(int paise) => fixtureSpend(_nov(12), paise);
    final big = fixtureA.plus(
      name: 'refund-big',
      entries: [spent(20000), fixtureMoneyIn(_nov(12), 150000)],
    );
    expect(
      _label(big, _nov(12)),
      'Thursday 12 November, net minus ₹1,300 after refunds, saved ₹2,130',
    );
    final small = r16;
    expect(
      _label(small, d(2026, 11, 16)),
      'Monday 16 November, net ₹200 after refunds, saved ₹630',
    );
  });

  test('TC-011-38 less than one rupee never reads as zero rupees', () {
    final over = fixtureA.plus(
      name: 'A+50',
      entries: [fixtureSpend(_nov(12), 83050)],
    );
    expect(
      _label(over, _nov(12)),
      'Thursday 12 November, spent ₹830, overspent less than ₹1',
    );
    final under = fixtureA.plus(
      name: 'A-50',
      entries: [fixtureSpend(_nov(12), 82950)],
    );
    expect(
      _label(under, _nov(12)),
      'Thursday 12 November, spent ₹829, saved less than ₹1',
    );
    final today = fixtureA.mapEntries(
      'A-today-under',
      (e) => e.date == _nov(13) ? e.copyWith(paise: 82950) : e,
    );
    expect(
      _label(today, _nov(13)),
      'Today, Friday 13 November, spent ₹829 so far, less than ₹1 left',
    );
    for (final f in [over, under]) {
      final label = _label(f, _nov(12))!;
      for (final bad in ['overspent ₹0', 'saved ₹0', '−₹0', 'minus ₹0']) {
        expect(label, isNot(contains(bad)));
      }
    }
  });

  test('TC-011-38 the labels switch to rupees at exactly 100 paise', () {
    // Paise over or under the ₹830 budget, and the label (the spent amount
    // shows whole rupees, rounded down).
    const over = {
      99: 'Thursday 12 November, spent ₹830, overspent less than ₹1',
      100: 'Thursday 12 November, spent ₹831, overspent ₹1',
      101: 'Thursday 12 November, spent ₹831, overspent ₹1',
    };
    const under = {
      99: 'Thursday 12 November, spent ₹829, saved less than ₹1',
      100: 'Thursday 12 November, spent ₹829, saved ₹1',
      101: 'Thursday 12 November, spent ₹828, saved ₹1',
    };
    for (final MapEntry(key: paise, value: label) in over.entries) {
      final f = fixtureA.plus(
        name: 'over $paise',
        entries: [fixtureSpend(_nov(12), 83000 + paise)],
      );
      expect(_label(f, _nov(12)), label, reason: '+$paise paise');
    }
    for (final MapEntry(key: paise, value: label) in under.entries) {
      final f = fixtureA.plus(
        name: 'under $paise',
        entries: [fixtureSpend(_nov(12), 83000 - paise)],
      );
      expect(_label(f, _nov(12)), label, reason: '-$paise paise');
    }
  });

  test('TC-011-24 labels carry the full amount, never a short form', () {
    final big = fixtureA.plus(
      name: 'big',
      entries: [fixtureSpend(_nov(12), 12999 * 100)],
    );
    final label = _label(big, _nov(12))!;
    expect(label, contains('₹12,999'));
    expect(label, isNot(contains('12k')));
    expect(label, isNot(contains('lakh')));
  });
}
