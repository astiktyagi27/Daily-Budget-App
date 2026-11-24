// F-011 TC-011-34 and F-012 TC-012-30: the calendar and the day details
// states through the four themes, text scale 1 and 2 on the small phone, and
// landscape in Light and Dim, with the F-002 checks on each.

import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/home/calendar/day_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/accessibility.dart';
import '../helpers/bundled_fonts.dart';
import '../helpers/day_details_harness.dart';
import '../helpers/phase3_data.dart';
import '../helpers/phase3_fixtures.dart';
import '../helpers/pump_app.dart';
import '../helpers/setup_harness.dart';
import '../helpers/theme_cases.dart';

/// A calendar state: a data set, with the date to scroll to.
typedef _CalendarState = (String, Phase3Fixture);

/// A day details state: a data set and the day to open.
typedef _DayState = (String, Phase3Fixture, CalendarDate, int?);

final List<_CalendarState> _calendarStates = [
  ('A13', a13),
  ('A13 covered', a13c300),
  ('M20 six rows and a change day', m20),
  ('S8 shortfall', s8),
  ('F12 not budgeted days', f12),
  ('R16 refund day', r16),
  (
    'New month not set up',
    a13.copyWith(name: 'A5Dec', today: CalendarDate(2026, 12, 5)),
  ),
];

final List<_DayState> _dayStates = [
  ('overspent with the cover card', a13, nov(11), null),
  ('saved', a13, nov(5), null),
  ('today', a13, nov(13), null),
  ('today overspent', a13o, nov(13), null),
  ('upcoming', a13, nov(14), null),
  ('empty day', a13, nov(12), null),
  ('covered day', a13c300, nov(11), null),
  ('refund day', r16, nov(16), null),
  ('period change day', m20, nov(13), null),
  ('shortfall with an empty pot', s8, nov(6), null),
  ('past month day', octNov, CalendarDate(2026, 10, 6), 0),
  ('not budgeted day', f12, nov(7), null),
];

Future<void> _openCalendar(
  WidgetTester tester,
  Phase3Fixture fixture, {
  required ThemeCase theme,
  required Size size,
  required double scale,
}) async {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  tester.platformDispatcher.clearTextScaleFactorTestValue();
  await tester.pumpWidget(const SizedBox());
  await pumpHome(
    tester,
    money: storeFor(fixture),
    clock: clockFor(fixture),
    theme: theme,
    size: size,
    textScale: scale,
  );
  final cell = find.byType(DayCell).first;
  await tester.ensureVisible(cell);
  await tester.pumpAndSettle();
  // Bring the whole grid on screen: the last cell.
  await tester.ensureVisible(find.byType(DayCell).last);
  await tester.pumpAndSettle();
}

Future<void> _openDayState(
  WidgetTester tester,
  _DayState state, {
  required ThemeCase theme,
  required Size size,
  required double scale,
}) async {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  tester.platformDispatcher.clearTextScaleFactorTestValue();
  await tester.pumpWidget(const SizedBox());
  await openDay(
    tester,
    state.$2,
    state.$3,
    monthIndex: state.$4,
    theme: theme,
    size: size,
    textScale: scale,
  );
}

void main() {
  setUpAll(loadBundledFonts);

  testWidgets('TC-011-34 calendar states pass the theme and text sweep', (
    tester,
  ) async {
    for (final (name, fixture) in _calendarStates) {
      for (final theme in ThemeCase.values) {
        for (final scale in const [1.0, 2.0]) {
          await _openCalendar(
            tester,
            fixture,
            theme: theme,
            size: kSmallPhone,
            scale: scale,
          );
          await expectAccessible(
            tester,
            reason: '$name / ${theme.name} / x$scale',
          );
        }
      }
    }
  });

  testWidgets('TC-011-34 calendar states survive landscape in Light and Dim', (
    tester,
  ) async {
    for (final (name, fixture) in _calendarStates) {
      for (final theme in [ThemeCase.light, ThemeCase.dim]) {
        for (final scale in const [1.0, 2.0]) {
          await _openCalendar(
            tester,
            fixture,
            theme: theme,
            size: kSmallLandscape,
            scale: scale,
          );
          await expectAccessible(
            tester,
            reason: '$name / ${theme.name} / x$scale / landscape',
          );
        }
      }
    }
  });

  testWidgets('TC-012-30 day details states pass the theme and text sweep', (
    tester,
  ) async {
    for (final state in _dayStates) {
      for (final theme in ThemeCase.values) {
        for (final scale in const [1.0, 2.0]) {
          await _openDayState(
            tester,
            state,
            theme: theme,
            size: kSmallPhone,
            scale: scale,
          );
          await expectAccessible(
            tester,
            reason: '${state.$1} / ${theme.name} / x$scale',
          );
        }
      }
    }
  });

  testWidgets('TC-012-30 day details states survive landscape in Light and '
      'Dim', (tester) async {
    for (final state in _dayStates) {
      for (final theme in [ThemeCase.light, ThemeCase.dim]) {
        for (final scale in const [1.0, 2.0]) {
          await _openDayState(
            tester,
            state,
            theme: theme,
            size: kSmallLandscape,
            scale: scale,
          );
          await expectAccessible(
            tester,
            reason: '${state.$1} / ${theme.name} / x$scale / landscape',
          );
        }
      }
    }
  });

  testWidgets('TC-012-30 the cover sheet passes the sweep', (tester) async {
    for (final theme in ThemeCase.values) {
      for (final scale in const [1.0, 2.0]) {
        await _openDayState(
          tester,
          _dayStates.first,
          theme: theme,
          size: kSmallPhone,
          scale: scale,
        );
        await tester.ensureVisible(find.text('Cover with savings'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cover with savings'));
        await tester.pumpAndSettle();
        await expectAccessible(
          tester,
          reason: 'cover sheet / ${theme.name} / x$scale',
        );
        // An error showing.
        await tester.enterText(find.byType(TextField), '999');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cover'));
        await tester.pumpAndSettle();
        await expectAccessible(
          tester,
          reason: 'cover sheet error / ${theme.name} / x$scale',
        );
      }
    }
  });
}
