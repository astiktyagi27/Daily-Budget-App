import 'dart:io';

import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

// Set by tool/tz_matrix.ps1 (and the TC-006-27 command): the offset the
// process must really have, and the name of its dump file.
const _hasExpectedOffset = bool.hasEnvironment('EXPECT_TZ_OFFSET_MIN');
const _expectedOffset = int.fromEnvironment('EXPECT_TZ_OFFSET_MIN');
const _zoneName = String.fromEnvironment('TZ_NAME');

void main() {
  test('TC-006-27 engine output does not depend on the time zone', () {
    if (_hasExpectedOffset) {
      // The sentinel: the zone change was real, not silently ignored.
      expect(
        DateTime(2026, 11, 9).timeZoneOffset.inMinutes,
        _expectedOffset,
        reason: 'TZ=$_zoneName',
      );
    }
    final nov5 = d(2026, 11, 5);
    final nov10 = d(2026, 11, 10);
    final nov20 = d(2026, 11, 20);
    final w2 = e2Month(today: nov10, spends: w2Spends(), covers: w2Covers());
    final c1 = e2Month(
      today: nov10,
      spends: w2Spends(),
      covers: w2Covers(),
      periods: [
        period(nov5, e2Values()),
        period(nov10, e2Values(rent: 1300000)),
      ],
    );
    final c4 = e2Month(
      today: nov20,
      spends: w2Spends(),
      covers: w2Covers(),
      periods: [
        period(nov5, e2Values()),
        period(nov20, e2Values(target: 2500000), continued: true),
      ],
    );
    // A month over the US daylight-saving change (14 Mar 2027).
    final march = BudgetMonth.startIn(5, 2027, 3);
    final dst = computeMonth(
      MonthInput(
        month: march,
        firstBudgetedDay: march.start,
        periods: [period(march.start, e2Values())],
        today: d(2027, 3, 15),
      ),
    );

    // The local date of a local DateTime is the calendar date, in any zone.
    expect(CalendarDate.fromDateTime(DateTime(2026, 11, 9)), d(2026, 11, 9));
    expect(w2.totals.pot, p(62000));
    expect(c1.periods.last.amountToSpread, p(1775000));
    expect(c4.totals.shortfall, p(255000));
    expect(march.length, 31);
    expect(allBudgets(dst), runs([(18, 80323), (13, 80322)]));

    final text = [w2, c1, c4, dst].map(dump).join('\n');
    if (_zoneName.isNotEmpty) {
      File('build/tz/$_zoneName.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync(text);
    }
  });
}
