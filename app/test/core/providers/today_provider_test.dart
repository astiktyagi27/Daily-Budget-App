import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_lifecycle.dart';

/// The clock of a test; the test moves it by hand, as the widget tests of
/// F-008 and F-009 do.
class _Clock {
  new(this.now);

  DateTime now;
}

/// A container whose clock reads `clock.now`, and every date the provider
/// has shown. The test disposes the container itself before it ends: a
/// pending midnight timer fails a test that is over, and a tear-down runs
/// too late.
({ProviderContainer container, List<CalendarDate> seen}) _open(_Clock clock) {
  final container = ProviderContainer(
    overrides: [clockProvider.overrideWithValue(() => clock.now)],
  );
  final seen = <CalendarDate>[];
  container.listen(
    todayProvider,
    (previous, next) => seen.add(next),
    fireImmediately: true,
  );
  return (container: container, seen: seen);
}

CalendarDate _date(int month, int day, [int year = 2026]) =>
    CalendarDate(year, month, day);

void main() {
  testWidgets('TC-008-39 today is the device date, read once', (tester) async {
    final clock = _Clock(DateTime(2026, 11, 5, 14, 30));
    final (:container, :seen) = _open(clock);

    expect(container.read(todayProvider), _date(11, 5));
    // The clock is read at the start, not on every read.
    clock.now = DateTime(2026, 11, 6, 9);
    expect(container.read(todayProvider), _date(11, 5));
    expect(seen, [_date(11, 5)]);
    container.dispose();
  });

  testWidgets('TC-008-39 today moves at the next local midnight', (
    tester,
  ) async {
    final clock = _Clock(DateTime(2026, 12, 4, 23, 59, 30));
    final (:container, :seen) = _open(clock);
    expect(container.read(todayProvider), _date(12, 4));

    // 29 seconds later it is still 4 Dec: no change, no notification.
    clock.now = DateTime(2026, 12, 4, 23, 59, 59);
    await tester.pump(const Duration(seconds: 29));
    expect(container.read(todayProvider), _date(12, 4));
    expect(seen, [_date(12, 4)]);

    // Midnight passes.
    clock.now = DateTime(2026, 12, 5, 0, 0, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(container.read(todayProvider), _date(12, 5));
    expect(seen, [_date(12, 4), _date(12, 5)]);
    container.dispose();
  });

  testWidgets('TC-008-39 the timer is set again for every following midnight', (
    tester,
  ) async {
    final clock = _Clock(DateTime(2026, 11, 9, 23));
    final (:container, :seen) = _open(clock);

    clock.now = DateTime(2026, 11, 10, 0, 0, 1);
    await tester.pump(const Duration(hours: 1));
    expect(container.read(todayProvider), _date(11, 10));

    clock.now = DateTime(2026, 11, 11, 0, 0, 1);
    await tester.pump(const Duration(hours: 24));
    expect(container.read(todayProvider), _date(11, 11));
    expect(seen, [_date(11, 9), _date(11, 10), _date(11, 11)]);
    container.dispose();
  });

  testWidgets('TC-008-39 an early timer fires again for the real midnight', (
    tester,
  ) async {
    final clock = _Clock(DateTime(2026, 11, 9, 23, 59));
    final (:container, :seen) = _open(clock);

    // The timer fires, but the clock still reads 9 Nov.
    clock.now = DateTime(2026, 11, 9, 23, 59, 59, 900);
    await tester.pump(const Duration(minutes: 1));
    expect(container.read(todayProvider), _date(11, 9));
    expect(seen, [_date(11, 9)]);

    // The new timer is for the real midnight, 100 ms away.
    clock.now = DateTime(2026, 11, 10, 0, 0, 0, 50);
    await tester.pump(const Duration(milliseconds: 150));
    expect(container.read(todayProvider), _date(11, 10));
    container.dispose();
  });

  testWidgets('TC-009-29 today is read again when the app is resumed', (
    tester,
  ) async {
    final clock = _Clock(DateTime(2026, 11, 9, 23, 59));
    final (:container, :seen) = _open(clock);
    expect(container.read(todayProvider), _date(11, 9));

    // Backgrounded over midnight: the timer may not have run.
    sendToBackground(tester);
    clock.now = DateTime(2026, 11, 10, 0, 1);
    bringToForeground(tester);

    expect(container.read(todayProvider), _date(11, 10));
    expect(seen, [_date(11, 9), _date(11, 10)]);
    container.dispose();
  });

  testWidgets('TC-009-29 resuming on the same day changes nothing', (
    tester,
  ) async {
    final clock = _Clock(DateTime(2026, 11, 9, 10));
    final (:container, :seen) = _open(clock);

    sendToBackground(tester);
    clock.now = DateTime(2026, 11, 9, 22);
    bringToForeground(tester);

    expect(container.read(todayProvider), _date(11, 9));
    expect(seen, [_date(11, 9)]);
    container.dispose();
  });

  testWidgets('TC-009-29 a device date set back is followed too (D-048)', (
    tester,
  ) async {
    final clock = _Clock(DateTime(2026, 11, 9, 10));
    final (:container, :seen) = _open(clock);

    sendToBackground(tester);
    clock.now = DateTime(2026, 11, 7, 10);
    bringToForeground(tester);

    expect(container.read(todayProvider), _date(11, 7));
    expect(seen, [_date(11, 9), _date(11, 7)]);
    container.dispose();
  });

  testWidgets('TC-008-39 the date ignores the time of day and month ends', (
    tester,
  ) async {
    final clock = _Clock(DateTime(2028, 2, 28, 23, 59, 59));
    final (:container, :seen) = _open(clock);
    expect(container.read(todayProvider), _date(2, 28, 2028));

    clock.now = DateTime(2028, 2, 29, 0, 0, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(container.read(todayProvider), _date(2, 29, 2028));

    clock.now = DateTime(2028, 3, 1, 0, 0, 1);
    await tester.pump(const Duration(hours: 24));
    expect(container.read(todayProvider), _date(3, 1, 2028));
    container.dispose();
  });

  testWidgets('TC-008-39 disposing the provider stops the timer and listener', (
    tester,
  ) async {
    final clock = _Clock(DateTime(2026, 11, 9, 10));
    final (:container, :seen) = _open(clock);
    container.dispose();

    clock.now = DateTime(2026, 11, 10, 0, 1);
    await tester.pump(const Duration(hours: 24));
    bringToForeground(tester);
    expect(seen, [_date(11, 9)]);
    // A pending timer would fail the test at its end.
  });

  testWidgets('TC-008-39 the default clock is the real device time', (
    tester,
  ) async {
    final container = ProviderContainer();
    final before = DateTime.now();
    final today = container.read(todayProvider);
    final after = DateTime.now();
    expect([
      CalendarDate.fromDateTime(before),
      CalendarDate.fromDateTime(after),
    ], contains(today));
    container.dispose();
  });
}
