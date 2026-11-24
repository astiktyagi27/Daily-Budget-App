import 'package:daily_budget/core/format/date_format.dart';
import 'package:flutter_test/flutter_test.dart';

/// The stored form of a local wall-clock time: UTC milliseconds.
int _stored(int hour, int minute) =>
    DateTime(2026, 11, 20, hour, minute).toUtc().millisecondsSinceEpoch;

void main() {
  test('TC-014-10 clock time is 24 hour hh:mm in local time', () {
    // Built from the same local value the screen reads back, so the result
    // does not depend on the zone the test runs in.
    expect(formatClockTime(_stored(10, 0)), '10:00');
    expect(formatClockTime(_stored(18, 5)), '18:05');
    expect(formatClockTime(_stored(0, 0)), '00:00');
    expect(formatClockTime(_stored(0, 9)), '00:09');
    expect(formatClockTime(_stored(12, 30)), '12:30');
    expect(formatClockTime(_stored(23, 59)), '23:59');
  });
}
