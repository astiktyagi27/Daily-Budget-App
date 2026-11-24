import 'dart:async';

import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/budget/fixtures.dart';
import '../helpers/fake_money_store.dart';
import '../helpers/phase3_data.dart';
import '../helpers/phase3_fixtures.dart';
import '../helpers/setup_harness.dart';
import '../helpers/theme_cases.dart';

/// What [P3Screen.open] leaves the test holding: the store and clock behind
/// the screen, and the completer of a held read (loading state).
typedef P3Opened = ({
  FakeMoneyStore store,
  MovableClock clock,
  Completer<void>? heldRead,
});

/// The Phase 3 screens as test states (F-010 section 0 "Home states (P3)"),
/// each driven through the real app on the fake repositories, like
/// `P1Screen`. The other Phase 3 tracks add their states here as their
/// screens land (calendar, day details, dashboard, statement, transactions
/// search), each with the fixture its test file names; the `hint.calendar.v1`
/// state waits for `HintId.calendar` (F-011 T-325).
enum P3Screen {
  homeA13('A13'),
  homeA13c300('A13c300'),
  homeS8('S8'),
  homeS8Plus150('S8+150'),
  homeZeroSpendable('Zero spendable month'),
  homeM20('M20'),
  homeF12('F12'),
  homeLateSetup('Late setup 12 Dec'),
  homeRefundToday('A13 with a refund today'),
  homeNegativeLeft('Negative Left (TC-010-47 b)'),
  homeCollapsedRow('A13 scrolled (collapsed row)'),
  homeNoMonth('No month'),
  homeNewMonthNotSetUp('New month not set up'),
  homeLoading('Loading'),
  homeLoadError('Load error'),
  homeWithHint('Home with its hint');

  new(this.description);

  final String description;

  /// The fixture behind this state, or null for the empty store.
  Phase3Fixture? get fixture => switch (this) {
    homeA13 ||
    homeCollapsedRow ||
    homeLoading ||
    homeLoadError ||
    homeWithHint => a13,
    homeA13c300 => a13c300,
    homeS8 => s8,
    homeS8Plus150 => s8Plus150,
    homeZeroSpendable => _zeroSpendable,
    homeM20 => m20,
    homeF12 => f12,
    homeLateSetup => _lateSetup,
    homeRefundToday => fixtureAPlusRefund,
    homeNegativeLeft => _negativeLeft,
    homeNoMonth => null,
    homeNewMonthNotSetUp => a13.copyWith(today: d(2026, 12, 5)),
  };

  /// Pumps a fresh app and drives it into this state, settled (the loading
  /// state stays loading until the returned `heldRead` is completed).
  Future<P3Opened> open(
    WidgetTester tester, {
    ThemeCase theme = ThemeCase.light,
    Size? size,
    double textScale = 1,
  }) async {
    // `setUpScreen` only sets what differs from the default and never undoes
    // it, so a sweep that opens many states in one test starts each from the
    // defaults.
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    await tester.pumpWidget(const SizedBox());

    final data = fixture;
    final store = data == null ? FakeMoneyStore() : storeFor(data);
    final clock = data == null ? MovableClock(d(2026, 11, 13)) : clockFor(data);
    Completer<void>? held;
    if (this == homeLoading) {
      held = store.readDelay = Completer<void>();
    }
    if (this == homeLoadError) store.readFails = true;

    await pumpHome(
      tester,
      money: store,
      clock: clock,
      theme: theme,
      size: size,
      textScale: textScale,
      hintsSeen: this != homeWithHint,
    );
    if (this == homeCollapsedRow) {
      // The summary card is taller than the screen: move in steps until it
      // has left, so the pinned row shows.
      for (var step = 0; step < 4; step++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
        await tester.pumpAndSettle();
      }
    }
    return (store: store, clock: clock, heldRead: held);
  }
}

/// Salary 20,00,000, Rent 15,00,000 + EMI 5,00,000 (fixed = salary), continued
/// anyway, Today(8 Nov), no spends (F-010 TC-010-15).
final _zeroSpendable = Phase3Fixture(
  name: 'zero spendable',
  today: d(2026, 11, 8),
  months: [
    FixtureMonth(
      month: nov2026,
      firstBudgetedDay: d(2026, 11, 5),
      periods: [
        period(
          d(2026, 11, 5),
          const FullMonthValues(
            salary: Paise(2000000),
            fixedCosts: [
              FixedCost(name: 'Rent', amount: Paise(1500000)),
              FixedCost(name: 'EMI', amount: Paise(500000)),
            ],
          ),
          changedAt: at(d(2026, 11, 4), 0),
          continued: true,
        ),
      ],
    ),
  ],
);

/// Month 5 Dec - 4 Jan set up on 12 Dec 2026 with 31,00,000 left (D-057,
/// F-010 TC-010-21).
final _lateSetup = Phase3Fixture(
  name: 'late setup',
  today: d(2026, 12, 12),
  months: [
    FixtureMonth(
      month: BudgetMonth.startIn(5, 2026, 12),
      firstBudgetedDay: d(2026, 12, 12),
      periods: [
        period(
          d(2026, 12, 12),
          const MidMonthStartValues(moneyLeft: Paise(3100000)),
          changedAt: at(d(2026, 12, 11), 0),
        ),
      ],
    ),
  ],
);

/// E2, Today(5 Nov), a spend of 25,00,000 (F-010 TC-010-47 b): Left −₹100.
final _negativeLeft = Phase3Fixture(
  name: 'negative left',
  today: d(2026, 11, 5),
  months: [
    FixtureMonth(
      month: nov2026,
      firstBudgetedDay: d(2026, 11, 5),
      periods: [
        period(d(2026, 11, 5), e2Values(), changedAt: at(d(2026, 11, 4), 0)),
      ],
      entries: [fixtureSpend(d(2026, 11, 5), 2500000)],
    ),
  ],
);
