import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  test('TC-006-01 budget month dates match the spec table', () {
    // (salary day, start, end, days) — F-006 §2.1, all 12 rows.
    final rows = <(int, CalendarDate, CalendarDate, int)>[
      (5, d(2026, 10, 5), d(2026, 11, 4), 31),
      (5, d(2026, 11, 5), d(2026, 12, 4), 30),
      (1, d(2027, 2, 1), d(2027, 2, 28), 28),
      (31, d(2027, 1, 31), d(2027, 2, 27), 28),
      (31, d(2027, 2, 28), d(2027, 3, 30), 31),
      (31, d(2027, 3, 31), d(2027, 4, 29), 30),
      (30, d(2028, 1, 30), d(2028, 2, 28), 30),
      (30, d(2028, 2, 29), d(2028, 3, 29), 30),
      (29, d(2027, 1, 29), d(2027, 2, 27), 30),
      (29, d(2028, 1, 29), d(2028, 2, 28), 31),
      (1, d(2026, 12, 1), d(2026, 12, 31), 31),
      (25, d(2026, 12, 25), d(2027, 1, 24), 31),
    ];
    for (final (salaryDay, start, end, days) in rows) {
      final reason = 'salary day $salaryDay, ${start.iso}';
      for (final inside in [start, end]) {
        final month = BudgetMonth.containing(salaryDay, inside);
        expect(month.start, start, reason: reason);
        expect(month.end, end, reason: reason);
        expect(month.length, days, reason: reason);
        expect(month.days, hasLength(days), reason: reason);
        expect(month.days.first, start, reason: reason);
        expect(month.days.last, end, reason: reason);
        expect(month.salaryDay, salaryDay, reason: reason);
      }
      final byStart = BudgetMonth.startIn(salaryDay, start.year, start.month);
      expect(byStart.start, start, reason: reason);
      expect(byStart.end, end, reason: reason);
      expect(byStart.contains(start), isTrue, reason: reason);
      expect(byStart.contains(end), isTrue, reason: reason);
      expect(byStart.contains(start.addDays(-1)), isFalse, reason: reason);
      expect(byStart.contains(end.addDays(1)), isFalse, reason: reason);
    }

    // Dates are plain calendar values: y/m/d round trip and ISO text.
    final leapDay = d(2028, 2, 29);
    expect((leapDay.year, leapDay.month, leapDay.day), (2028, 2, 29));
    expect(leapDay.iso, '2028-02-29');
    expect(d(1969, 12, 31).dayNumber, -1);
    expect(d(1970, 1, 1).dayNumber, 0);
    expect(
      CalendarDate.fromDateTime(DateTime(2026, 11, 9, 23, 59)),
      d(2026, 11, 9),
    );
    expect(
      CalendarDate.fromDateTime(DateTime.utc(2026, 11, 9)),
      CalendarDate.fromDayNumber(d(2026, 11, 9).dayNumber),
    );
    expect(d(2026, 11, 5).compareTo(d(2026, 11, 6)), -1);
    expect(d(2026, 11, 6).compareTo(d(2026, 11, 6)), 0);
    expect(d(2026, 11, 6).isAfter(d(2026, 11, 5)), isTrue);
    expect(d(2026, 11, 6).daysUntil(d(2026, 11, 1)), -5);
  });

  test('TC-006-34 salary day 31 survives short and leap months', () {
    var month = BudgetMonth.startIn(31, 2028, 1);
    final expected = <(CalendarDate, CalendarDate, int)>[
      (d(2028, 1, 31), d(2028, 2, 28), 29),
      (d(2028, 2, 29), d(2028, 3, 30), 31),
      (d(2028, 3, 31), d(2028, 4, 29), 30),
      (d(2028, 4, 30), d(2028, 5, 30), 31),
    ];
    for (final (start, end, days) in expected) {
      expect(month.start, start);
      expect(month.end, end);
      expect(month.length, days);
      expect(month.salaryDay, 31);
      month = month.next;
    }
    // Back again, through the same short months.
    month = month.previous;
    for (final (start, end, _) in expected.reversed) {
      expect(month.start, start);
      expect(month.end, end);
      month = month.previous;
    }
  });
}
