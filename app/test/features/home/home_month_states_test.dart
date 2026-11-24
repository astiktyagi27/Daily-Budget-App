import 'package:daily_budget/core/widgets/empty_state.dart';
import 'package:daily_budget/features/home/widgets/summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/setup_harness.dart';
import '../../helpers/shell.dart';
import '../../support/find_copy.dart';
import 'home_harness.dart';

Finder get _setUpScreen => find.text('Start my month');

void main() {
  testWidgets('TC-008-01 home without a month offers set up your month', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpHome(
      tester,
      money: FakeMoneyStore(),
      clock: MovableClock(d(2026, 11, 5)),
    );

    expect(findCopy('Your daily budget lives here'), findsOneWidget);
    expect(
      findCopy(
        "Tell us your salary and fixed costs, and we'll work out what you can "
        'spend each day.',
      ),
      findsOneWidget,
    );
    expect(
      findCopy(
        "Once you set up your month, you'll see what you can spend today",
      ),
      findsNothing,
    );
    final button = find.widgetWithText(FilledButton, 'Set up your month');
    expect(button, findsOneWidget, reason: 'a Primary button');
    expect(
      find.descendant(
        of: find.byType(EmptyState),
        matching: find.byType(FilledButton),
      ),
      findsOneWidget,
    );
    expect(tester.getSemantics(button).hint, 'Open month setup');

    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(findCopy('Set up your month'), findsOneWidget, reason: 'the title');
    expect(_setUpScreen, findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-008-57 home shows the summary card and edit lives in the '
      'menu', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpHome(
      tester,
      money: storeWithMonth(),
      clock: MovableClock(d(2026, 11, 9)),
    );

    expect(find.byType(SummaryCard), findsOneWidget);
    expect(findCopy('This month'), findsNothing);
    expect(find.text('Edit this month'), findsNothing);
    expect(findCopy('₹830/day · 5 Nov – 4 Dec'), findsOneWidget);
    expect(findCopy('Your daily budget lives here'), findsNothing);

    await tapVisible(tester, find.byTooltip('More'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('Edit this month')).hint,
      "Change this month's salary, target or fixed costs",
    );
    await tester.tap(find.text('Edit this month'));
    await tester.pumpAndSettle();
    expect(findCopy('Edit this month'), findsOneWidget, reason: 'the title');
    expect(find.text('Save changes'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-008-57 a phone date before the month shows the card but no '
      'edit menu', (tester) async {
    await pumpHome(
      tester,
      money: storeWithMonth(),
      clock: MovableClock(d(2026, 11, 1)),
    );
    expect(findCopy('₹830/day · 5 Nov – 4 Dec'), findsOneWidget);
    expect(find.byTooltip('More'), findsNothing);
  });

  testWidgets('TC-008-03 home shows the new month notice once the month has '
      'ended', (tester) async {
    for (final today in [d(2026, 12, 5), d(2026, 12, 20)]) {
      await tester.pumpWidget(const SizedBox());
      await pumpHome(
        tester,
        money: storeWithMonth(),
        clock: MovableClock(today),
      );
      expect(findCopy('Your new month has started'), findsOneWidget);
      expect(
        findCopy("Check last month's numbers and confirm."),
        findsOneWidget,
      );
      expect(findCopy('Left this month'), findsNothing);
      expect(findCopy('Safe to spend'), findsNothing);
      expect(findCopy('Today'), findsNothing);
      await tapText(tester, 'Set up this month');
      expect(findCopy('Set up this month'), findsOneWidget, reason: 'title');
      expect(_setUpScreen, findsOneWidget);
    }

    await tester.pumpWidget(const SizedBox());
    await pumpHome(
      tester,
      money: storeWithMonth(),
      clock: MovableClock(d(2026, 12, 4)),
    );
    expect(findCopy('Left this month'), findsOneWidget);
    expect(findCopy('Your new month has started'), findsNothing);
  });

  testWidgets('TC-008-49 double tap opens one setup screen', (tester) async {
    await pumpHome(
      tester,
      money: FakeMoneyStore(),
      clock: MovableClock(d(2026, 11, 5)),
    );
    final button = find.text('Set up your month');
    await tester.tap(button);
    await tester.tap(button, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(_setUpScreen, findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_setUpScreen, findsNothing, reason: 'one screen was pushed');
    expect(findCopy('Your daily budget lives here'), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byType(Scaffold).first)).canPop(),
      isFalse,
    );
  });

  testWidgets('TC-008-49 double tap on edit this month opens one screen', (
    tester,
  ) async {
    await pumpHome(
      tester,
      money: storeWithMonth(),
      clock: MovableClock(d(2026, 11, 9)),
    );
    await tapVisible(tester, find.byTooltip('More'));
    await tester.pumpAndSettle();
    final item = find.text('Edit this month');
    await tester.tap(item);
    await tester.tap(item, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Save changes'), findsNothing);
    expect(findCopy('Left this month'), findsOneWidget);
  });

  testWidgets('TC-008-51 home hint still works with the month card', (
    tester,
  ) async {
    for (final money in [FakeMoneyStore(), storeWithMonth()]) {
      await tester.pumpWidget(const SizedBox());
      await pumpHome(
        tester,
        money: money,
        clock: MovableClock(d(2026, 11, 9)),
        hintsSeen: false,
      );
      expect(findCopy('Tip'), findsOneWidget);
      expect(
        findCopy(
          "Use the tabs at the bottom to move around. Home is where you'll "
          "check today's budget each day.",
        ),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(findCopy('Tip')).dy,
        lessThan(
          tester
              .getTopLeft(
                find.byWidgetPredicate(
                  (w) => w is EmptyState || w is SummaryCard,
                ),
              )
              .dy,
        ),
        reason: 'the hint stays above the new content',
      );
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      // The home tip is gone. With a calendar under the cards its own tip
      // (F-011, design H-7) takes the slot; never two at once.
      expect(
        findCopy('Use the tabs at the bottom to move around.'),
        findsNothing,
      );
    }
  });

  testWidgets('TC-008-52 home read failure shows the load error', (
    tester,
  ) async {
    final store = storeWithMonth()..readFails = true;
    await pumpHome(tester, money: store, clock: MovableClock(d(2026, 11, 9)));

    expect(findCopy("Couldn't load your data"), findsOneWidget);
    expect(findCopy('Tap Try again. Nothing has been lost.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);
    expect(find.text('Set up your month'), findsNothing);
    expect(findCopy('Left this month'), findsNothing);

    store.readFails = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(findCopy('₹830/day · 5 Nov – 4 Dec'), findsOneWidget);
  });

  testWidgets('TC-008-59 shortfall panel shows on every day of the month', (
    tester,
  ) async {
    final store = storeWithMonth(
      periods: [
        period(
          d(2026, 11, 5),
          s1Values(),
          changedAt: at(d(2026, 11, 4), 0),
          continued: true,
        ),
      ],
    );
    final semantics = tester.ensureSemantics();
    for (final day in [d(2026, 11, 5), d(2026, 11, 20), d(2026, 12, 4)]) {
      await tester.pumpWidget(const SizedBox());
      await pumpHome(tester, money: store, clock: MovableClock(day));
      expect(findCopy('−₹1,000 this month'), findsOneWidget, reason: day.iso);
      expect(
        findCopy('Every spend this month counts as overspent.'),
        findsOneWidget,
      );
      expect(findCopy('₹0/day · 5 Nov – 4 Dec'), findsOneWidget);
      expect(findCopy('This month'), findsNothing);
      expect(
        find.bySemanticsLabel(
          'Minus ₹1,000 this month. Every spend this month counts as '
          'overspent.',
        ),
        findsOneWidget,
        reason: day.iso,
      );
    }
    semantics.dispose();
  });

  testWidgets('TC-008-58 the other tabs keep working with the month states', (
    tester,
  ) async {
    await pumpHome(
      tester,
      money: storeWithMonth(),
      clock: MovableClock(d(2026, 11, 9)),
    );
    await tapTab(tester, 'Dashboard');
    expect(find.text('Dashboard'), findsWidgets);
    await tapTab(tester, 'Home');
    expect(findCopy('Left this month'), findsOneWidget);
  });

  testWidgets('TC-008-60 home shows the daily amount after an edit', (
    tester,
  ) async {
    for (final (field, text, daily, budget) in [
      ('rent', '13000', '₹630', 'budget ₹630'),
      ('salary', '35000', '₹496', 'budget ₹496'),
    ]) {
      await tester.pumpWidget(const SizedBox());
      await pumpHome(
        tester,
        money: storeWithMonth(),
        clock: MovableClock(d(2026, 11, 20)),
      );
      await tapEditThisMonth(tester);
      if (field == 'rent') {
        await tester.enterText(itemAmountFields.at(0), text);
      } else {
        await tester.enterText(amountInput('Monthly salary'), text);
      }
      await tester.pump();
      await tapText(tester, 'Save changes');

      expect(findCopy('$daily/day · 5 Nov – 4 Dec'), findsOneWidget);
      expect(findCopy('$daily a day'), findsNothing, reason: 'old card text');
      expect(todayCardText(), startsWith(budget), reason: field);
      if (field == 'rent') {
        expect(findCopy('Budget changed on 20 Nov'), findsOneWidget);
        expect(findCopy('See month statement'), findsOneWidget);
      }
    }
  });

  testWidgets('TC-008-61 home shows the shortfall panel after an edit', (
    tester,
  ) async {
    await pumpHome(
      tester,
      money: storeWithMonth(),
      clock: MovableClock(d(2026, 11, 20)),
    );
    await tapEditThisMonth(tester);
    await tapVisible(tester, find.byType(Switch));
    await tester.pumpAndSettle();
    await typeAmount(tester, 'Spending target', '25000');
    await tapText(tester, 'Save changes');
    await tester.tap(find.text('Continue anyway'));
    await tester.pumpAndSettle();

    expect(findCopy('−₹2,550 this month'), findsOneWidget);
    expect(
      findCopy('Every spend this month counts as overspent.'),
      findsOneWidget,
    );
    expect(findCopy('Left this month'), findsOneWidget);
    // The hero is negative: U+2212, then U+2060, then the rupees.
    expect(find.textContaining('−⁠₹'), findsWidgets);
  });
}
