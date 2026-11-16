import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TC-008-42 salary day ordinals for every day from 1 to 31', () {
    const expected = {
      1: '1st',
      2: '2nd',
      3: '3rd',
      4: '4th',
      5: '5th',
      10: '10th',
      11: '11th',
      12: '12th',
      13: '13th',
      14: '14th',
      20: '20th',
      21: '21st',
      22: '22nd',
      23: '23rd',
      24: '24th',
      30: '30th',
      31: '31st',
    };
    for (final MapEntry(key: day, value: text) in expected.entries) {
      expect(formatOrdinal(day), text);
    }
    for (var day = 1; day <= 31; day++) {
      expect(formatOrdinal(day), startsWith('$day'));
      expect(formatOrdinal(day), matches(r'^\d+(st|nd|rd|th)$'));
    }
  });

  test('TC-008-02 a budget month range and a single day', () {
    final start = CalendarDate(2026, 11, 5);
    final end = CalendarDate(2026, 12, 4);
    expect(formatDayMonth(start), '5 Nov');
    expect(formatRange(start, end), '5 Nov \u2013 4 Dec');
    expect(
      formatRange(CalendarDate(2026, 12, 5), CalendarDate(2027, 1, 4)),
      '5 Dec \u2013 4 Jan',
    );
    expect(formatDayMonth(CalendarDate(2026, 12, 31)), '31 Dec');
    expect(formatDayMonth(CalendarDate(2028, 2, 29)), '29 Feb');
  });

  test('TC-009-13 weekday headings such as Thu, 5 Nov', () {
    expect(formatWeekdayDayMonth(CalendarDate(2026, 11, 5)), 'Thu, 5 Nov');
    expect(formatWeekdayDayMonth(CalendarDate(2026, 11, 9)), 'Mon, 9 Nov');
    expect(formatWeekdayDayMonth(CalendarDate(2026, 11, 8)), 'Sun, 8 Nov');
    expect(formatWeekdayDayMonth(CalendarDate(2026, 11, 7)), 'Sat, 7 Nov');
  });

  test('TC-009-21 the full date for a screen reader', () {
    expect(formatFullDate(CalendarDate(2026, 11, 9)), 'Monday 9 November');
    expect(formatFullDate(CalendarDate(2026, 11, 6)), 'Friday 6 November');
    expect(formatFullDate(CalendarDate(2027, 1, 1)), 'Friday 1 January');
  });

  test('TC-008-29 weekdays are right across a leap year and before 1970', () {
    var day = CalendarDate(2024, 2, 26);
    const week = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (var i = 0; i < 20; i++) {
      expect(
        formatWeekdayDayMonth(day).substring(0, 3),
        week[i % 7],
        reason: day.iso,
      );
      day = day.addDays(1);
    }
    expect(formatWeekdayDayMonth(CalendarDate(1969, 12, 31)), 'Wed, 31 Dec');
  });

  test('TC-008-48 one day is singular', () {
    expect(formatDayCount(1), '1 day');
    expect(formatDayCount(2), '2 days');
    expect(formatDayCount(31), '31 days');
    expect(formatDayCount(0), '0 days');
  });
}
