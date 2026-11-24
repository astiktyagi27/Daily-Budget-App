// F-014 AC-14: the shared month switcher on the statement (F-011 limits).

import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/bundled_fonts.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/statement_harness.dart';
import '../../support/find_copy.dart';

const _tall = Size(360, 4000);

List<String> _texts(WidgetTester tester) => [
  for (final r in tester.widgetList<RichText>(find.byType(RichText)))
    plainCopy(r.text.toPlainText(includeSemanticsLabels: false))
        .replaceAll('\uFFFC', ''),
];

/// A stored month on salary day 5 with E2 values and no spends.
FixtureMonth _month(int year, int month) {
  final budget = BudgetMonth.startIn(5, year, month);
  return FixtureMonth(
    month: budget,
    firstBudgetedDay: budget.start,
    periods: [period(budget.start, e2Values(), changedAt: at(budget.start, 8))],
  );
}

Finder get _previous => find.byTooltip('Previous month');
Finder get _next => find.byTooltip('Next month');

void main() {
  setUpAll(loadBundledFonts);

  testWidgets('TC-014-23 a past month statement reads as ended', (
    tester,
  ) async {
    await pumpStatement(tester, fixtureO1, size: _tall);
    expect(findCopy('So far'), findsOneWidget);

    await tester.tap(_previous);
    await tester.pumpAndSettle();

    final texts = _texts(tester);
    for (final text in [
      '5 Oct – 4 Nov 2026',
      '5 Oct – 4 Nov · 31 days',
      'Month started',
      '₹40,000 − ₹9,000 fixed = ₹31,000 over 31 days → ₹1,000/day',
      '₹31,000',
      '₹2,250',
      '● ₹29,150',
      '◆ ₹400',
      '₹28,750',
    ]) {
      expect(texts, contains(text), reason: text);
    }
    expect(findCopy('Ended'), findsOneWidget);
    expect(findCopy('Month total'), findsOneWidget);
    expect(findCopy('This month'), findsOneWidget);
    expect(texts.where((t) => t.contains('so far')), isEmpty);
    expect(texts.where((t) => t.contains('in progress')), isEmpty);
    await tester.tap(find.bySemanticsLabel('More about daily budget'));
    await tester.pumpAndSettle();
    expect(findCopy('₹31,000 divides evenly over 31 days.'), findsOneWidget);
  });

  testWidgets('TC-014-24 every stored month has a statement and limits match '
      'the calendar', (tester) async {
    final fixture = Phase3Fixture(
      name: 'four months',
      today: d(2026, 11, 13),
      months: [
        _month(2026, 8),
        _month(2026, 9),
        _month(2026, 10),
        _month(2026, 11),
      ],
    );
    await pumpStatement(tester, fixture, size: _tall);

    const current = '5 Nov – 4 Dec 2026 · so far (to Fri, 13 Nov)';
    expect(_texts(tester), contains(current));
    // › is disabled on the current month.
    await tester.tap(_next, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(_texts(tester), contains(current));
    for (final expected in [
      '5 Oct – 4 Nov 2026',
      '5 Sep – 4 Oct 2026',
      '5 Aug – 4 Sep 2026',
    ]) {
      await tester.tap(_previous);
      await tester.pumpAndSettle();
      expect(_texts(tester), contains(expected));
      expect(findCopy('Month total'), findsOneWidget);
    }
    // The first stored month: ‹ is disabled and says why.
    final semantics = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Previous month')).hint,
      contains('No earlier months'),
    );
    semantics.dispose();
    await tester.tap(_previous, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(_texts(tester), contains('5 Aug – 4 Sep 2026'));

    // This month returns to the current month, which then has no button.
    await tester.tap(findCopy('This month'));
    await tester.pumpAndSettle();
    expect(
      _texts(tester),
      contains('5 Nov – 4 Dec 2026 · so far (to Fri, 13 Nov)'),
    );
    expect(findCopy('This month'), findsNothing);
    for (var i = 0; i < 3; i++) {
      await tester.tap(_previous);
      await tester.pumpAndSettle();
    }
    for (var i = 0; i < 3; i++) {
      await tester.tap(_next);
      await tester.pumpAndSettle();
    }
    expect(findCopy('So far'), findsOneWidget);
  });

  testWidgets('TC-014-36 a missed month has no statement', (tester) async {
    final fixture = Phase3Fixture(
      name: 'Aug and Oct',
      today: d(2026, 11, 13),
      months: [_month(2026, 8), _month(2026, 10)],
    );
    await pumpStatement(tester, fixture, size: _tall);

    await tester.tap(_previous);
    await tester.pumpAndSettle();

    expect(_texts(tester), contains('5 Aug – 4 Sep 2026'));
    expect(_texts(tester).where((t) => t.contains('5 Sep')), isEmpty);
  });

  testWidgets('TC-014-40 a month that is not set up opens on last month', (
    tester,
  ) async {
    await pumpStatement(
      tester,
      fixtureA.copyWith(today: d(2026, 12, 5)),
      size: _tall,
    );

    final texts = _texts(tester);
    expect(texts, contains('5 Nov – 4 Dec 2026'));
    expect(texts.where((t) => t.contains('so far')), isEmpty);
    expect(findCopy('Month total'), findsOneWidget);
    expect(findCopy('So far'), findsNothing);
    expect(findCopy('This month'), findsNothing);
    expect(find.byTooltip('Next month'), findsOneWidget);
  });
}
