import 'package:daily_budget/core/theme/budget_colors.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/day_details/day_details_screen.dart';
import 'package:daily_budget/features/day_details/open_day_details.dart';
import 'package:daily_budget/features/statement/open_month_statement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/setup_harness.dart';
import '../../helpers/transactions_harness.dart' show addSpendTo;
import '../../support/app_lifecycle.dart';
import '../../support/find_copy.dart';
import 'home_harness.dart';

// Home's Today card (F-010, plan T-303). Literals from
// tests/F-010-home-summary.md.

final CalendarDate _nov13 = d(2026, 11, 13);

/// A13 with 13 Nov replaced by [entries].
Phase3Fixture _a13Today(String name, List<FixtureEntry> entries) =>
    a13.copyWith(
      name: name,
      entries: [
        ...a13.current.entries.where((e) => e.date != _nov13),
        ...entries,
      ],
    );

/// The colour of the result words and of the mark of the Today line.
(Color?, Color?) _resultColors(WidgetTester tester) {
  final texts = find.descendant(
    of: find.byKey(const ValueKey('today-line')),
    matching: find.byType(Text),
  );
  final words = tester.widget<Text>(texts.last);
  final mark = tester.widget<Text>(find.byKey(const ValueKey('today-mark')));
  return ((words.textSpan! as TextSpan).style?.color, mark.style?.color);
}

void main() {
  testWidgets('TC-010-04 today card matches worked example A', (tester) async {
    await openFixture(tester, a13);
    expect(findCopy('Today · Fri, 13 Nov'), findsOneWidget);
    expect(todayCardText(), 'budget ₹830 · spent ₹420 · ₹410 left today');
    expect(find.text('●'), findsWidgets);
    expect(_resultColors(tester).$1, BudgetColors.light.saved);
  });

  testWidgets('TC-010-08 home moves to the new day after midnight', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final clock = MovableClock(_nov13)..now = DateTime(2026, 11, 13, 23, 59);
    await openFixture(tester, a13, clock: clock);
    expect(findCopy('Today · Fri, 13 Nov'), findsOneWidget);

    clock.now = DateTime(2026, 11, 14, 0, 1);
    sendToBackground(tester);
    bringToForeground(tester);
    await tester.pumpAndSettle();

    expect(findCopy('Today · Sat, 14 Nov'), findsOneWidget);
    expect(todayCardText(), 'budget ₹830 · spent ₹0 · ₹830 left today');
    expect(ledgerRow('Saved this month', '₹2,410'), findsOneWidget);
    expect(ledgerRow('Spent so far', '₹5,530'), findsOneWidget);
    expect(findCopy('₹19,370'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-010-09 today card result for left on budget and overspent', (
    tester,
  ) async {
    const colors = BudgetColors.light;
    for (final (paise, line, color, mark) in [
      (42000, 'budget ₹830 · spent ₹420 · ₹410 left today', colors.saved, '●'),
      (83000, 'budget ₹830 · spent ₹830 · on budget', colors.neutral, '○'),
      (
        95050,
        'budget ₹830 · spent ₹950 · overspent ₹120',
        colors.overspent,
        '◆',
      ),
      (
        82940,
        'budget ₹830 · spent ₹829 · less than ₹1 left today',
        colors.saved,
        '●',
      ),
      (
        83040,
        'budget ₹830 · spent ₹830 · overspent less than ₹1',
        colors.overspent,
        '◆',
      ),
    ]) {
      await tester.pumpWidget(const SizedBox());
      await openFixture(
        tester,
        _a13Today('today $paise', [fixtureSpend(_nov13, paise)]),
      );
      expect(todayCardText(), line);
      expect(_resultColors(tester).$1, color, reason: line);
      expect(_resultColors(tester).$2, color, reason: line);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('today-mark'))).data,
        mark,
      );
    }
  });

  testWidgets('TC-010-25 today card shows net spend and the refunds line', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openFixture(
      tester,
      _a13Today('refund today', [
        fixtureSpend(_nov13, 70000),
        fixtureMoneyIn(_nov13, 50000),
      ]),
    );
    expect(todayCardText(), 'budget ₹830 · spent ₹200 · ₹630 left today');
    expect(findCopy('Includes ₹500 back from refunds'), findsOneWidget);
    expect(ledgerRow('Spent so far', '₹5,310'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Today, Friday 13 November: budget ₹830, spent ₹200, ₹630 left '
        'today. Includes ₹500 back from refunds.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('TC-010-26 negative net spend today reads minus and more than '
      'the budget left', (tester) async {
    await openFixture(
      tester,
      _a13Today('bigger refund', [
        fixtureSpend(_nov13, 30000),
        fixtureMoneyIn(_nov13, 50000),
      ]),
    );
    expect(todayCardText(), 'budget ₹830 · spent −₹200 · ₹1,030 left today');
    expect(findCopy('Includes ₹500 back from refunds'), findsOneWidget);
    expect(_resultColors(tester).$1, BudgetColors.light.saved);
  });

  testWidgets('TC-010-27 refunds line only when today has refunds', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openFixture(
      tester,
      fixtureAPlusRefund.copyWith(
        name: 'refund on 12 Nov',
        entries: [
          ...a13.current.entries,
          fixtureMoneyIn(d(2026, 11, 12), 50000),
        ],
      ),
    );
    expect(find.textContaining('back from refunds'), findsNothing);
    expect(ledgerRow('Spent so far', '₹5,030'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-010-48 forty paise spent shows spent zero', (tester) async {
    final semantics = tester.ensureSemantics();
    final fixture = customFixture(
      name: 'forty paise',
      today: d(2026, 11, 9),
      values: e2Values(),
      entries: [fixtureSpend(d(2026, 11, 9), 40)],
    );
    await openFixture(tester, fixture);
    expect(ledgerRow('Spent so far', '₹0'), findsOneWidget);
    expect(todayCardText(), 'budget ₹830 · spent ₹0 · ₹829 left today');
    expect(ledgerRow('Overspent', '₹0'), findsOneWidget);
    // 5 - 8 Nov ended with nothing spent: 4 x ₹830 saved (the case text
    // says ₹0, which only fits a first day; the engine's figure stands).
    expect(ledgerRow('Saved this month', '₹3,320'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-010-32 today card and month statement navigate', (
    tester,
  ) async {
    final days = <(int, CalendarDate)>[];
    final statements = <int>[];
    final overrides = [
      dayDetailsLauncherProvider.overrideWithValue(
        (context, {required monthId, required date}) =>
            days.add((monthId, date)),
      ),
      monthStatementLauncherProvider.overrideWithValue(
        (context, monthId, {scrollToPeriodStart}) => statements.add(monthId),
      ),
    ];
    final semantics = tester.ensureSemantics();
    final store = await openFixture(tester, a13, overrides: overrides);
    final id = store.months.single.id;

    // The statement row first: scrolled up to later, it would sit under
    // the pinned row.
    await tapVisible(tester, findCopy('Month statement'));
    await tester.pumpAndSettle();
    expect(statements, [id]);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Month statement')).hint,
      "See how this month's budget was worked out",
    );

    await tester.ensureVisible(findCopy('Today · Fri, 13 Nov'));
    await tester.pumpAndSettle();
    final card = find.bySemanticsLabel(
      'Today, Friday 13 November: budget ₹830, spent ₹420, ₹410 left today.',
    );
    expect(tester.getSemantics(card).hint, "See today's details");
    await tester.tap(findCopy('Today · Fri, 13 Nov'));
    await tester.pumpAndSettle();
    expect(days, [(id, _nov13)]);
    semantics.dispose();
  });

  testWidgets('TC-010-32 the real routes open and Back keeps the scroll', (
    tester,
  ) async {
    await openFixture(tester, a13);
    double scroll() => tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .pixels;

    await tester.ensureVisible(findCopy('Today · Fri, 13 Nov'));
    await tester.pumpAndSettle();
    final before = scroll();
    await tester.tap(findCopy('Today · Fri, 13 Nov'));
    await tester.pumpAndSettle();
    expect(find.byType(DayDetailsScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(DayDetailsScreen), findsNothing);
    expect(scroll(), before);
    expect(findCopy('Today · Fri, 13 Nov'), findsOneWidget);
  });

  testWidgets('TC-010-53 double tap opens one screen', (tester) async {
    final days = <CalendarDate>[];
    final statements = <int>[];
    final overrides = [
      dayDetailsLauncherProvider.overrideWithValue(
        (context, {required monthId, required date}) => days.add(date),
      ),
      monthStatementLauncherProvider.overrideWithValue(
        (context, monthId, {scrollToPeriodStart}) => statements.add(monthId),
      ),
    ];
    await openFixture(tester, a13, overrides: overrides);

    await tapVisible(tester, findCopy('Month statement'));
    await tester.tap(findCopy('Month statement'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(statements, hasLength(1));

    final card = findCopy('Today · Fri, 13 Nov');
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.tap(card, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(days, hasLength(1));
  });

  testWidgets('TC-010-54 resuming on the same day changes nothing', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openFixture(tester, a13);
    sendToBackground(tester);
    bringToForeground(tester);
    await tester.pump();

    expect(findCopy('Today · Fri, 13 Nov'), findsOneWidget);
    expect(todayCardText(), 'budget ₹830 · spent ₹420 · ₹410 left today');
    expect(findCopy('₹19,370'), findsOneWidget);
    expect(ledgerRow('Spent so far', '₹5,530'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-010-59 today not budgeted hides today card and strip', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    // (a) F12 with the date set back to 8 Nov: before the first budgeted day
    // (10 Nov). The 10 and 11 Nov spends are future-dated and in no total.
    final clock = MovableClock(d(2026, 11, 8));
    await openFixture(tester, f12, clock: clock);
    expect(find.textContaining('Today ·'), findsNothing);
    expect(findCopy('Safe to spend'), findsNothing);
    expect(ledgerRow('Spent so far', '₹0'), findsOneWidget);
    expect(findCopy('₹24,900'), findsWidgets);
    expect(findCopy('Month statement'), findsOneWidget);
    expect(find.textContaining("Couldn't load"), findsNothing);
    expect(tester.takeException(), isNull);

    // Resuming at the real date shows the Today card again.
    clock.moveTo(d(2026, 11, 12));
    sendToBackground(tester);
    bringToForeground(tester);
    await tester.pumpAndSettle();
    expect(findCopy('Today · Thu, 12 Nov'), findsOneWidget);
    expect(findCopy('Safe to spend'), findsOneWidget);

    // (b) A13 data with the date set back to 2 Nov: before the month.
    await tester.pumpWidget(const SizedBox());
    await openFixture(tester, a13, clock: MovableClock(d(2026, 11, 2)));
    expect(find.textContaining('Today ·'), findsNothing);
    expect(findCopy('Safe to spend'), findsNothing);
    expect(ledgerRow('Spent so far', '₹0'), findsOneWidget);
    expect(findCopy('Month statement'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('TC-010-59 a date after the last day is the new month card', (
    tester,
  ) async {
    // Today(5 Dec) with December not set up is the new-month state of
    // TC-010-36, not an unbudgeted day of November.
    await openFixture(tester, a13, clock: MovableClock(d(2026, 12, 5)));
    expect(findCopy('Your new month has started'), findsOneWidget);
    expect(find.textContaining('Today ·'), findsNothing);
    expect(findCopy('Safe to spend'), findsNothing);
  });

  testWidgets('TC-010-31 a spend added today moves the today line', (
    tester,
  ) async {
    final store = await openFixture(tester, a13);
    await change(tester, store, () => addSpendTo(store, _nov13, 41000));
    expect(todayCardText(), 'budget ₹830 · spent ₹830 · on budget');
  });
}
