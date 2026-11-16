import 'dart:io';

import 'package:daily_budget/data/database/converters.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const converter = CalendarDateConverter();

  test('TC-007-06 calendar date converter round trips exact dates', () {
    // (year, month, day, expected day number since 1970-01-01).
    const cases = <(int, int, int, int)>[
      (1970, 1, 1, 0),
      (2026, 11, 9, 20766),
      (2028, 2, 29, 21243),
      (2026, 12, 31, 20818),
      (2027, 1, 1, 20819),
      (2027, 2, 28, 20877),
      (2027, 3, 1, 20878),
      (2099, 12, 31, 47481),
    ];
    for (final (year, month, day, number) in cases) {
      final date = CalendarDate(year, month, day);
      expect(converter.toSql(date), number, reason: date.iso);
      final back = converter.fromSql(number);
      expect((back.year, back.month, back.day), (year, month, day));
      expect(back, date);
    }
    // 31 Dec -> 1 Jan and 28 Feb -> 1 Mar are consecutive days.
    expect(
      converter.toSql(CalendarDate(2027, 1, 1)) -
          converter.toSql(CalendarDate(2026, 12, 31)),
      1,
    );
    expect(
      converter.toSql(CalendarDate(2027, 3, 1)) -
          converter.toSql(CalendarDate(2027, 2, 28)),
      1,
    );
    // Dates before 1970 are negative day numbers and still round trip.
    final before = CalendarDate(1969, 12, 31);
    expect(converter.toSql(before), -1);
    expect(converter.fromSql(-1), before);
  });

  test('TC-007-06 converter sources never read the clock or a time zone', () {
    // The converter and the table definitions only move integers: no local
    // DateTime, no clock, no zone (F-007 AC-3).
    for (final path in [
      'lib/data/database/converters.dart',
      'lib/data/database/tables.dart',
    ]) {
      final code = File(path)
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');
      for (final forbidden in [
        'toLocal',
        'DateTime.now',
        'DateTime(',
        'timeZoneOffset',
        'dateTime()',
      ]) {
        expect(code.contains(forbidden), isFalse, reason: '$path: $forbidden');
      }
    }
  });
}
