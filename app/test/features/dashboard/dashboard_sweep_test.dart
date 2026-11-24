import 'dart:async';

import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/dashboard/dashboard_state.dart';
import 'package:daily_budget/features/dashboard/dashboard_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/accessibility.dart';
import '../../helpers/dashboard_harness.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/theme_cases.dart';

const _sweepTimeout = Timeout(Duration(minutes: 12));

/// A state of the Dashboard (F-013 test cases section 0 "D states"), opened
/// on [theme] at [scale] on [size].
typedef _Open = Future<void> Function(
  WidgetTester tester,
  ThemeCase theme,
  double scale,
  Size size,
);

CalendarDate _nov(int day) => d(2026, 11, day);

_Open _plain(
  Phase3Fixture fixture, {
  bool hintsSeen = true,
  Future<void> Function(WidgetTester tester)? then,
}) => (tester, theme, scale, size) async {
  await pumpDashboard(
    tester,
    fixture: fixture,
    theme: theme,
    textScale: scale,
    size: size,
    hintsSeen: hintsSeen,
  );
  if (then != null) await then(tester);
};

Future<void> _oneDay(WidgetTester tester) async {
  await tester.ensureVisible(find.text('One day'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('One day'));
  await tester.pumpAndSettle();
}

Phase3Fixture _five100() => fixtureA.copyWith(
  name: '500 Food, 500 Travel',
  entries: [
    fixtureSpend(_nov(6), 50000, category: 'travel'),
    fixtureSpend(_nov(7), 50000, category: 'food'),
  ],
);

final Map<String, _Open> _states = {
  'first-time hint': _plain(fixtureA, hintsSeen: false),
  'all other (A)': _plain(fixtureA),
  'single not other': _plain(
    fixtureA.mapEntries('A food', (e) => e.copyWith(categoryKey: 'food')),
  ),
  'several with the note (B)': _plain(fixtureB),
  'several without a note': _plain(_five100()),
  'nine categories': _plain(
    fixtureA.copyWith(
      name: 'nine',
      entries: [
        for (final (index, key) in loadCategoryKeys.indexed)
          fixtureSpend(_nov(6), (9 - index) * 100000, category: key),
      ],
    ),
  ),
  'refunds shown': _plain(fixtureAPlusRefund),
  'one day with a spend': _plain(fixtureA, then: _oneDay),
  'one day with nothing': _plain(
    fixtureA,
    then: (tester) async {
      await _oneDay(tester);
      // The picker itself is TC-013-09; here the day is set directly, so the
      // sweep also runs in landscape.
      ProviderScope.containerOf(tester.element(find.byType(DashboardTab)))
          .read(dashboardSelectionProvider.notifier)
          .pickDay(_nov(12));
      await tester.pumpAndSettle();
    },
  ),
  'first day of the month': _plain(
    fixtureA.copyWith(
      name: 'day one',
      today: _nov(5),
      entries: [fixtureSpend(_nov(5), 42000)],
    ),
  ),
  'month with no spends': _plain(fixtureA.copyWith(entries: [])),
  'shortfall month (S)': _plain(fixtureS),
  'two-period month (M20)': _plain(fixtureM20),
  'month with only refunds': _plain(
    fixtureA.copyWith(
      name: 'refund only',
      entries: [fixtureMoneyIn(_nov(12), 50000)],
    ),
  ),
  'past month (O1)': (tester, theme, scale, size) async {
    final store = storeFor(fixtureO1);
    await pumpDashboard(
      tester,
      fixture: fixtureO1,
      money: store,
      theme: theme,
      textScale: scale,
      size: size,
    );
    ProviderScope.containerOf(tester.element(find.byType(DashboardTab)))
        .read(dashboardSelectionProvider.notifier)
        .selectMonth(store.months.first.id);
    await tester.pumpAndSettle();
  },
  'loading': (tester, theme, scale, size) async {
    final store = storeFor(fixtureA)..readDelay = Completer<void>();
    await pumpDashboard(
      tester,
      fixture: fixtureA,
      money: store,
      theme: theme,
      textScale: scale,
      size: size,
    );
  },
  'load error': (tester, theme, scale, size) async {
    final store = storeFor(fixtureA)..readFails = true;
    await pumpDashboard(
      tester,
      fixture: fixtureA,
      money: store,
      theme: theme,
      textScale: scale,
      size: size,
    );
  },
  'no month': (tester, theme, scale, size) =>
      pumpDashboard(tester, theme: theme, textScale: scale, size: size),
};

Future<void> _scrollToEnd(WidgetTester tester) async {
  await tester.drag(
    find.byType(CustomScrollView).first,
    const Offset(0, -9000),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'TC-013-28 dashboard states pass the theme and text scale sweep',
    (tester) async {
      for (final MapEntry(key: name, value: open) in _states.entries) {
        for (final theme in ThemeCase.values) {
          for (final scale in [1.0, 2.0]) {
            final where = '$name, ${theme.name}, x$scale';
            await open(tester, theme, scale, kSmallPhone);
            await expectAccessible(tester, reason: where);
            await _scrollToEnd(tester);
            await expectAccessible(tester, reason: '$where (scrolled)');
            await tester.pumpWidget(const SizedBox());
          }
        }
      }
    },
    timeout: _sweepTimeout,
  );

  testWidgets('TC-013-28 dashboard states survive landscape', (tester) async {
    for (final MapEntry(key: name, value: open) in _states.entries) {
      for (final theme in [ThemeCase.light, ThemeCase.dim]) {
        for (final scale in [1.0, 2.0]) {
          final where = '$name, ${theme.name}, x$scale, landscape';
          await open(tester, theme, scale, kSmallLandscape);
          expectNoOverflow(tester, reason: where);
          await _scrollToEnd(tester);
          expectNoOverflow(tester, reason: '$where (scrolled)');
          await tester.pumpWidget(const SizedBox());
        }
      }
    }
  }, timeout: _sweepTimeout);

  testWidgets('TC-013-50 share rows stack at large text and no amount is cut', (
    tester,
  ) async {
    await pumpDashboard(tester, fixture: fixtureB, textScale: 2);
    final name = tester.getTopLeft(find.text('Other'));
    final amount = tester.getTopLeft(find.textContaining('₹3,910'));
    // Stacked: the name is on its own line above the amount.
    expect(amount.dy, greaterThan(name.dy));
    expectNoOverflow(tester);
  });
}
