import 'dart:async';

import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The device clock. Tests override it with a fixed or movable time; nothing
/// else in the app reads `DateTime.now()` (plan F-008 §1.5).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Today's calendar date on the device (India has one time zone and no
/// daylight saving, STANDARDS §4).
///
/// Read from [clockProvider] once, then refreshed when the app comes back to
/// the foreground and at the next local midnight, so a screen left open over
/// midnight moves to the new day (F-008 AC-12, F-009 §7). Every screen and
/// controller reads this one value, so the preview and Confirm can never
/// disagree about the day.
final todayProvider = NotifierProvider<TodayNotifier, CalendarDate>(
  TodayNotifier.new,
);

class TodayNotifier extends Notifier<CalendarDate> {
  Timer? _midnight;

  @override
  CalendarDate build() {
    final listener = AppLifecycleListener(onResume: refresh);
    ref.onDispose(() {
      listener.dispose();
      _midnight?.cancel();
    });
    final now = ref.read(clockProvider)();
    _scheduleMidnight(now);
    return CalendarDate.fromDateTime(now);
  }

  /// Reads the clock again and keeps the midnight timer in step with it.
  /// Called on resume and by the timer; a date that has not changed leaves
  /// the state alone, so nothing rebuilds.
  void refresh() {
    final now = ref.read(clockProvider)();
    final date = CalendarDate.fromDateTime(now);
    if (date != state) state = date;
    _scheduleMidnight(now);
  }

  void _scheduleMidnight(DateTime now) {
    _midnight?.cancel();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(nextMidnight.difference(now), refresh);
  }
}
