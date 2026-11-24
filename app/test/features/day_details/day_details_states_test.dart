import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/transactions/spend_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/bundled_fonts.dart';
import '../../helpers/day_details_harness.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/setup_harness.dart';
import '../../support/app_lifecycle.dart';

// F-012 §2.6, §4: read-only, upcoming, not budgeted, load error, big days.

void main() {
  setUpAll(loadBundledFonts);

  testWidgets('TC-012-19 no add spend on upcoming days and past months', (
    tester,
  ) async {
    await openDay(tester, a13, nov(14));
    expect(find.text('Add spend'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await openDay(tester, octNov, CalendarDate(2026, 10, 6), monthIndex: 0);
    expect(find.text('Add spend'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await openDay(tester, a13, nov(13));
    expect(find.text('Add spend'), findsOneWidget);
  });

  testWidgets('TC-012-28 past month days are read only', (tester) async {
    await openDay(tester, octNov, CalendarDate(2026, 10, 6), monthIndex: 0);
    expect(figure(tester, 'Budget'), '₹803');
    expect(figure(tester, 'Spent'), '₹1,000');
    expect(find.text('◆ Overspent ₹196'), findsWidgets);
    expect(
      find.text("This month has ended, so its days can't be changed."),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    final row = tester.widget<SpendRow>(find.byType(SpendRow));
    expect(row.onTap, isNull);
    expect(find.text('Add spend'), findsNothing);
    expect(find.text('Cover with savings'), findsNothing);
    expect(find.text('Remove'), findsNothing);
    final handle = tester.ensureSemantics();
    expect(
      tester
          .getSemantics(find.bySemanticsLabel(RegExp('^₹1,000, No note, ')))
          .hint,
      isNot('Edit'),
    );
    handle.dispose();
  });

  testWidgets('TC-012-29 upcoming day shows only the budget', (tester) async {
    await openDay(tester, a13, nov(14));
    expect(find.text('Sat, 14 Nov'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(figure(tester, 'Budget'), '₹830');
    expect(find.text("This day hasn't happened yet."), findsOneWidget);
    for (final absent in [
      'Spent',
      'Day result',
      'Spends',
      'Add spend',
      'Cover with savings',
    ]) {
      expect(find.text(absent), findsNothing, reason: absent);
    }
  });

  testWidgets('TC-012-46 midnight turns todays status into the final result', (
    tester,
  ) async {
    final clock = MovableClock(nov(13));
    await openDay(tester, a13o, nov(13), clock: clock);
    expect(find.text('◆ Today · overspent ₹170'), findsOneWidget);
    clock.moveTo(nov(14));
    // The phone clock moved past midnight and the app was resumed.
    sendToBackground(tester);
    bringToForeground(tester);
    await tester.pumpAndSettle();
    expect(find.text('Fri, 13 Nov'), findsOneWidget);
    expect(find.text('◆ Overspent ₹170'), findsWidgets);
    expect(find.text('Cover with savings'), findsOneWidget);
    expect(
      find.text('Spending more today will make it overspent again.'),
      findsNothing,
    );
  });

  testWidgets('TC-012-48 ten crore day wraps and covers at most the pot', (
    tester,
  ) async {
    final big = a13.plus(
      name: 'A+10Cr',
      entries: [fixtureSpend(nov(12), 10000000000)],
    );
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(const SizedBox());
      await openDay(tester, big, nov(12), textScale: scale);
      expect(figure(tester, 'Spent'), '₹10,00,00,000', reason: 'x$scale');
      expect(tester.takeException(), isNull, reason: 'x$scale');
      await tester.ensureVisible(find.text('Cover with savings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cover with savings'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '1170',
      );
      expect(find.text('This uses your whole savings pot.'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'sheet x$scale');
    }
  });

  testWidgets('TC-012-51 future dated spend is listed with its note', (
    tester,
  ) async {
    final future = a13.plus(
      name: 'A+future',
      entries: [fixtureSpend(nov(15), 50000, note: 'Booked')],
    );
    await openDay(tester, future, nov(15));
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Booked'), findsOneWidget);
    expect(find.text('Dated in the future'), findsOneWidget);
    expect(find.text('Add spend'), findsNothing);
  });

  testWidgets('TC-012-62 not budgeted day shows only its note', (tester) async {
    await openDay(tester, f12, nov(7));
    expect(find.text('Sat, 7 Nov'), findsOneWidget);
    expect(find.text('Not budgeted: you started on 10 Nov.'), findsOneWidget);
    for (final absent in ['Budget', 'Spent', 'Add spend', 'Spends']) {
      expect(find.text(absent), findsNothing, reason: absent);
    }
  });

  testWidgets('TC-012-63 day details read failure can be retried', (
    tester,
  ) async {
    final opened = await openDay(tester, a13, nov(11));
    opened.store.readFails = true;
    opened.store.notify();
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load your data"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    opened.store.readFails = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load your data"), findsNothing);
    expect(find.text('◆ Overspent ₹300'), findsWidgets);
  });
}
