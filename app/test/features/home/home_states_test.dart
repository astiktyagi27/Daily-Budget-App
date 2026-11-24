import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/setup_harness.dart';
import '../../support/app_lifecycle.dart';
import '../../support/find_copy.dart';
import 'home_harness.dart';

// Home's states (F-010 AC-16, plan T-301). Literals from
// tests/F-010-home-summary.md.

void main() {
  testWidgets('TC-010-35 home without a month shows only the empty state', (
    tester,
  ) async {
    await pumpHome(
      tester,
      money: FakeMoneyStore(),
      clock: MovableClock(d(2026, 11, 5)),
    );
    expect(findCopy('Your daily budget lives here'), findsOneWidget);
    expect(find.text('Set up your month'), findsOneWidget);
    expect(findCopy('Left this month'), findsNothing);
    expect(find.textContaining('Today ·'), findsNothing);
    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byTooltip('More'), findsNothing);
  });

  testWidgets('TC-010-36 home shows the new month card and last months '
      'calendar', (tester) async {
    // Today(5 Dec) with only November stored, and Today(5 Nov) with only
    // October stored.
    await openFixture(tester, a13, clock: MovableClock(d(2026, 12, 5)));
    expect(findCopy('Your new month has started'), findsOneWidget);
    expect(find.text('Set up this month'), findsOneWidget);
    expect(findCopy('Left this month'), findsNothing);
    expect(find.textContaining('Today ·'), findsNothing);
    expect(findCopy('Safe to spend'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    final october = customFixture(
      name: 'October only',
      today: d(2026, 11, 5),
      month: oct2026,
      values: e2Values(),
    );
    await openFixture(tester, october);
    expect(findCopy('Your new month has started'), findsOneWidget);
    expect(findCopy('Safe to spend'), findsNothing);
  });

  testWidgets('TC-010-37 loading home never shows a zero placeholder', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final store = storeFor(a13);
    final held = store.readDelay = Completer<void>();
    await pumpHome(tester, money: store, clock: clockFor(a13));

    expect(findCopy('Left this month'), findsOneWidget);
    expect(findCopy('Salary'), findsOneWidget);
    expect(find.textContaining('₹'), findsNothing);
    expect(find.bySemanticsLabel('Loading your month'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);

    held.complete();
    await tester.pumpAndSettle();
    expect(findCopy('₹19,370'), findsOneWidget);
    expect(find.bySemanticsLabel('Loading your month'), findsNothing);
    semantics.dispose();
  });

  testWidgets('TC-010-38 home read failure shows try again and recovers', (
    tester,
  ) async {
    final store = storeFor(a13)..readFails = true;
    await pumpHome(tester, money: store, clock: clockFor(a13));

    expect(findCopy("Couldn't load your data"), findsOneWidget);
    expect(findCopy('Tap Try again. Nothing has been lost.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(findCopy('Left this month'), findsNothing);

    store.readFails = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(findCopy('₹19,370'), findsOneWidget);
    expect(findCopy("Couldn't load your data"), findsNothing);
  });

  testWidgets('TC-010-46 home on the last day and the day after', (
    tester,
  ) async {
    final clock = MovableClock(d(2026, 12, 4));
    await openFixture(tester, a13, clock: clock);
    expect(findCopy('Today · Fri, 4 Dec'), findsOneWidget);
    expect(findCopy('₹19,370 a day · 1 day left'), findsOneWidget);

    clock.now = DateTime(2026, 12, 5, 0, 1);
    sendToBackground(tester);
    bringToForeground(tester);
    await tester.pumpAndSettle();
    expect(findCopy('Your new month has started'), findsOneWidget);
    expect(find.textContaining('Today ·'), findsNothing);
  });
}
