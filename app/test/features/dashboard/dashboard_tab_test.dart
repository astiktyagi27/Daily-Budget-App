import 'dart:async';

import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/core/widgets/budget_icon_button.dart';
import 'package:daily_budget/core/widgets/share_bar_row.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/month_setup/month_setup_controller.dart';
import 'package:daily_budget/features/shell/app_tab.dart';
import 'package:daily_budget/features/shell/selected_tab_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/dashboard_harness.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/shell.dart';
import '../../helpers/transactions_harness.dart';
import '../../support/app_lifecycle.dart';
import '../../support/find_copy.dart';

CalendarDate _nov(int day) => d(2026, 11, day);

const _tip =
    'Spends without a category go into Other. Pick one when you add a spend, '
    'or change it in Transactions. Later, spends from your bank SMS will be '
    'sorted for you.';

/// Lets a store change reach the screen: the stream event, then the frame.
Future<void> _settleStream(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

Future<void> _tapOneDay(WidgetTester tester) async {
  await tester.tap(find.text('One day'));
  await tester.pumpAndSettle();
}

Future<void> _pickDay(WidgetTester tester, String chip, int day) async {
  await tester.tap(findCopy(chip));
  await tester.pumpAndSettle();
  await tester.tap(find.text('$day').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(findCopy(text)).dy;

/// E2, Today(13 Nov), spends as given as (day, paise, category key).
Phase3Fixture _spends(
  List<(int, int, String?)> entries, {
  List<FixtureEntry> extra = const [],
  CalendarDate? today,
}) => fixtureA.copyWith(
  name: 'custom',
  today: today ?? _nov(13),
  entries: [
    for (final (day, paise, key) in entries)
      fixtureSpend(_nov(day), paise, category: key),
    ...extra,
  ],
);

void main() {
  testWidgets('TC-013-01 dashboard shows the month layout', (tester) async {
    await pumpDashboard(tester, fixture: fixtureA);
    expect(findCopy('Dashboard'), findsWidgets);
    expect(findCopy('5 Nov – 4 Dec 2026 · so far'), findsOneWidget);
    expect(find.text('This month'), findsOneWidget);
    expect(find.text('One day'), findsOneWidget);
    expect(find.text('Where your money went'), findsOneWidget);
    expect(find.text('This month in numbers'), findsOneWidget);
    expect(find.text('Month statement'), findsOneWidget);
    expect(find.text('No dashboard yet'), findsNothing);
    final ys = [
      _top(tester, '5 Nov – 4 Dec 2026 · so far'),
      _top(tester, 'Where your money went'),
      _top(tester, 'This month in numbers'),
      _top(tester, 'Month statement'),
    ];
    expect(ys, [...ys]..sort());
  });

  testWidgets('TC-013-02 dashboard without a month asks to set up first', (
    tester,
  ) async {
    final calls = await pumpDashboard(tester);
    expect(find.text('Set up your month first'), findsOneWidget);
    expect(
      find.text('Your spends need a budget month. It takes a minute.'),
      findsOneWidget,
    );
    expect(find.text('Where your money went'), findsNothing);
    await tester.tap(find.text('Set up your month'));
    await _settleStream(tester);
    expect(calls.setups.single, isA<FirstSetupMode>());
  });

  testWidgets('TC-013-03 all other shows one sentence and no bars', (
    tester,
  ) async {
    await pumpDashboard(tester, fixture: fixtureA);
    expect(findCopy('All ₹5,530 so far is in Other.'), findsOneWidget);
    expect(find.byType(ShareBarRow), findsNothing);
    expect(find.textContaining('%'), findsNothing);
    expect(findCopy(_tip), findsOneWidget);
  });

  testWidgets('TC-013-04 other hint opens transactions and cannot be '
      'dismissed', (tester) async {
    await pumpDashboard(tester, fixture: fixtureA);
    expect(find.text('Tip'), findsOneWidget);
    expect(find.text('Got it'), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go to Transactions'));
    await tester.pumpAndSettle();
    expect(
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first))
          .read(selectedTabProvider),
      AppTab.transactions,
    );
    expect(find.byTooltip('Add a spend by hand'), findsOneWidget);
  });

  testWidgets('TC-013-49 other hint shows for a one day all other state', (
    tester,
  ) async {
    await pumpDashboard(tester, fixture: fixtureA);
    await _tapOneDay(tester);
    await _pickDay(tester, 'Fri, 13 Nov', 11);
    expect(findCopy('All ₹1,130 on Wed, 11 Nov is in Other.'), findsOneWidget);
    expect(find.text('Tip'), findsOneWidget);
    expect(findCopy(_tip), findsOneWidget);
    await _pickDay(tester, 'Wed, 11 Nov', 12);
    expect(findCopy('Nothing spent on Thu, 12 Nov.'), findsOneWidget);
    expect(find.text('Tip'), findsNothing);
    expect(findCopy(_tip), findsNothing);
  });

  testWidgets('TC-013-05 single non other category has no tip', (tester) async {
    await pumpDashboard(
      tester,
      fixture: fixtureA.mapEntries(
        'A food',
        (e) => e.copyWith(categoryKey: 'food'),
      ),
    );
    expect(findCopy('All ₹5,530 so far is in Food.'), findsOneWidget);
    expect(findCopy(_tip), findsNothing);
    expect(find.text('Go to Transactions'), findsNothing);
    expect(find.byType(ShareBarRow), findsNothing);
  });

  testWidgets('TC-013-06 several categories show ranked rows and the '
      'rounding note', (tester) async {
    await pumpDashboard(tester, fixture: fixtureB);
    for (final text in [
      'Other',
      '₹3,910',
      '70%',
      'Shopping',
      '₹1,000',
      '18%',
      'Food',
      '₹620',
      '11%',
    ]) {
      expect(findCopy(text), findsOneWidget, reason: text);
    }
    expect(_top(tester, 'Other'), lessThan(_top(tester, 'Shopping')));
    expect(_top(tester, 'Shopping'), lessThan(_top(tester, 'Food')));
    final widths = [
      for (final bar in find.byKey(ShareBarRow.barKey).evaluate())
        tester.getSize(find.byWidget(bar.widget)).width,
    ];
    expect(widths, hasLength(3));
    // Bars are exact shares of the total: Shopping : Other = 100 : 391.
    expect(widths[1] / widths[0], closeTo(1.0 / 3.91, 0.01));
    expect(
      findCopy(
        'Percentages are rounded down, so they may add up to less than 100%.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('All ₹'), findsNothing);
    expect(findCopy(_tip), findsNothing);
  });

  testWidgets('TC-013-07 exact hundred percent shows no note and ties use '
      'readme order', (tester) async {
    await pumpDashboard(
      tester,
      fixture: _spends([(6, 50000, 'travel'), (7, 50000, 'food')]),
    );
    expect(findCopy('50%'), findsNWidgets(2));
    expect(_top(tester, 'Food'), lessThan(_top(tester, 'Travel')));
    expect(find.textContaining('Percentages are rounded'), findsNothing);
  });

  testWidgets('TC-013-08 a share under one percent reads less than one', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      fixture: _spends([(6, 995000, null), (7, 5000, 'health')]),
    );
    expect(findCopy('99%'), findsOneWidget);
    expect(findCopy('<1%'), findsOneWidget);
    expect(findCopy('0%'), findsNothing);
    expect(find.textContaining('Percentages are rounded'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Health, ₹50, less than 1 percent'),
      findsOneWidget,
    );
  });

  testWidgets('TC-013-09 one day shows that day and limits the picker', (
    tester,
  ) async {
    await pumpDashboard(tester, fixture: fixtureA);
    expect(find.bySemanticsLabel('One day, 2 of 2'), findsOneWidget);
    await _tapOneDay(tester);
    expect(find.bySemanticsLabel('One day, selected, 2 of 2'), findsOneWidget);
    expect(findCopy('Fri, 13 Nov'), findsOneWidget);
    expect(findCopy('All ₹420 on Fri, 13 Nov is in Other.'), findsOneWidget);

    await tester.tap(findCopy('Fri, 13 Nov'));
    await tester.pumpAndSettle();
    final picker = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    expect(picker.firstDate, DateTime(2026, 11, 5));
    expect(picker.lastDate, DateTime(2026, 11, 13));
    expect(find.text('Pick a day'), findsWidgets);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await _pickDay(tester, 'Fri, 13 Nov', 11);
    expect(findCopy('All ₹1,130 on Wed, 11 Nov is in Other.'), findsOneWidget);
    await _pickDay(tester, 'Wed, 11 Nov', 12);
    expect(findCopy('Nothing spent on Thu, 12 Nov.'), findsOneWidget);
    expect(findCopy(_tip), findsNothing);
    expect(find.byType(ShareBarRow), findsNothing);
  });

  testWidgets('TC-013-10 refunds and net spent follow the categories', (
    tester,
  ) async {
    await pumpDashboard(tester, fixture: fixtureAPlusRefund);
    expect(findCopy('All ₹5,530 so far is in Other.'), findsOneWidget);
    expect(findCopy('Refunds'), findsOneWidget);
    expect(findCopy('−₹500'), findsOneWidget);
    expect(findCopy('Net spent'), findsOneWidget);
    expect(findCopy('₹5,030'), findsOneWidget);
    expect(find.bySemanticsLabel('Refunds, minus ₹500'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('More about Refunds'));
    await tester.pumpAndSettle();
    expect(
      find.text('Money paid back to you. It lowers what you spent.'),
      findsOneWidget,
    );
  });

  testWidgets('TC-013-11 refunds larger than the day show a negative net', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      fixture: _spends(
        [(12, 20000, null)],
        extra: [fixtureMoneyIn(_nov(12), 150000)],
      ),
    );
    await _tapOneDay(tester);
    await _pickDay(tester, 'Fri, 13 Nov', 12);
    expect(findCopy('All ₹200 on Thu, 12 Nov is in Other.'), findsOneWidget);
    expect(findCopy('−₹1,500'), findsOneWidget);
    expect(findCopy('−₹1,300'), findsOneWidget);
  });

  testWidgets('TC-013-45 a refund only day shows the refund lines', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      fixture: _spends([], extra: [fixtureMoneyIn(_nov(12), 50000)]),
    );
    await _tapOneDay(tester);
    await _pickDay(tester, 'Fri, 13 Nov', 12);
    expect(findCopy('Nothing spent on Thu, 12 Nov.'), findsOneWidget);
    expect(findCopy('Refunds'), findsOneWidget);
    expect(findCopy('−₹500'), findsNWidgets(2));
    expect(findCopy('Net spent'), findsOneWidget);
    expect(findCopy(_tip), findsNothing);
  });

  testWidgets('TC-013-54 a month with only refunds shows the refund lines', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      fixture: _spends([], extra: [fixtureMoneyIn(_nov(12), 50000)]),
    );
    expect(findCopy('Nothing spent yet this month.'), findsOneWidget);
    expect(findCopy(_tip), findsNothing);
    expect(findCopy('Refunds'), findsOneWidget);
    expect(findCopy('Net spent'), findsOneWidget);
    expect(findCopy('−₹500'), findsNWidgets(2));
    expect(find.bySemanticsLabel('Net spent, minus ₹500'), findsOneWidget);
    expect(findCopy('No spends yet'), findsOneWidget);
    expect(findCopy('−₹62 a day'), findsOneWidget);
    expect(find.textContaining('₹0 spent'), findsNothing);
  });

  testWidgets('TC-013-34 a month with no spends hides the refund lines', (
    tester,
  ) async {
    await pumpDashboard(tester, fixture: _spends([]));
    expect(findCopy('Nothing spent yet this month.'), findsOneWidget);
    expect(findCopy('Refunds'), findsNothing);
    expect(findCopy(_tip), findsNothing);
  });

  testWidgets('TC-013-26 a category change updates the breakdown at once', (
    tester,
  ) async {
    final store = storeFor(fixtureA);
    await pumpDashboard(tester, fixture: fixtureA, money: store);
    expect(findCopy('All ₹5,530 so far is in Other.'), findsOneWidget);
    // Ids: month 1, then the spends 2, 3, ...: 6 Nov Shoes is the second.
    setCategoryOf(store, 3, SpendCategory.shopping);
    await _settleStream(tester);
    expect(findCopy('₹4,530'), findsOneWidget);
    expect(findCopy('81%'), findsOneWidget);
    expect(findCopy('₹1,000'), findsOneWidget);
    expect(findCopy('18%'), findsOneWidget);
    expect(find.textContaining('Percentages are rounded'), findsOneWidget);
    expect(findCopy(_tip), findsNothing);
  });

  testWidgets('TC-013-36 a category with no spends leaves the list', (
    tester,
  ) async {
    final store = storeFor(fixtureB);
    await pumpDashboard(tester, fixture: fixtureB, money: store);
    expect(findCopy('Shopping'), findsOneWidget);
    store.spendsByMonth[store.months.first.id]!.removeWhere(
      (s) => s.note == 'Shoes',
    );
    store.notify();
    await _settleStream(tester);
    expect(findCopy('Shopping'), findsNothing);
    expect(findCopy('86%'), findsOneWidget);
    expect(findCopy('13%'), findsOneWidget);
    expect(find.textContaining('Percentages are rounded'), findsOneWidget);
    expect(findCopy(_tip), findsNothing);
  });

  testWidgets('TC-013-27 spends refunds and covers update the dashboard live', (
    tester,
  ) async {
    final store = storeFor(fixtureA);
    await pumpDashboard(tester, fixture: fixtureA, money: store);
    final id = addSpendTo(store, _nov(13), 10000);
    store.notify();
    await _settleStream(tester);
    expect(findCopy('All ₹5,630 so far is in Other.'), findsOneWidget);

    addMoneyInTo(store, _nov(13), 5000);
    store.notify();
    await _settleStream(tester);
    expect(findCopy('Refunds'), findsOneWidget);
    expect(findCopy('Net spent'), findsOneWidget);

    store.coversByMonth
        .putIfAbsent(store.months.first.id, () => [])
        .add(
          Cover(
            id: store.nextId(),
            day: _nov(11),
            amount: const Paise(30000),
            madeAt: at(_nov(13), 9),
          ),
        );
    store.notify();
    await _settleStream(tester);
    expect(findCopy('incl. 1 covered from savings'), findsOneWidget);
    expect(findCopy('◆ 1 overspent'), findsNothing);

    store.spendsByMonth[store.months.first.id]!.removeWhere(
      (s) => s.spend.id == id,
    );
    store.notify();
    await _settleStream(tester);
    expect(findCopy('All ₹5,630 so far is in Other.'), findsNothing);
    expect(findCopy('All ₹5,530 so far is in Other.'), findsOneWidget);
  });

  testWidgets('TC-013-35 all nine categories are listed', (tester) async {
    await pumpDashboard(
      tester,
      fixture: _spends([
        for (final (index, key) in loadCategoryKeys.indexed)
          (6, (9 - index) * 100000, key),
      ]),
    );
    for (final name in [
      'Food',
      'Groceries',
      'Shopping',
      'Travel',
      'Bills & Recharge',
      'Entertainment',
      'Health',
      'Friends & People',
      'Other',
    ]) {
      await tester.ensureVisible(findCopy(name));
      expect(findCopy(name), findsOneWidget, reason: name);
    }
    for (final share in [
      '20%',
      '17%',
      '15%',
      '13%',
      '11%',
      '8%',
      '6%',
      '4%',
      '2%',
    ]) {
      expect(findCopy(share), findsOneWidget, reason: share);
    }
    expect(find.textContaining('Percentages are rounded'), findsOneWidget);
  });

  testWidgets('TC-013-37 paise only category shows zero rupees and less than '
      'one percent', (tester) async {
    await pumpDashboard(
      tester,
      fixture: _spends([(6, 50000, null), (7, 40, 'health')]),
    );
    expect(findCopy('₹0'), findsOneWidget);
    expect(findCopy('<1%'), findsOneWidget);
    expect(findCopy('99%'), findsOneWidget);
    expect(find.textContaining('Percentages are rounded'), findsOneWidget);
  });

  testWidgets('TC-013-29 dashboard controls have help copy', (tester) async {
    // A tall screen, so every (i) can be tapped without scrolling.
    await pumpDashboard(
      tester,
      fixture: fixtureAPlusRefund,
      size: const Size(360, 1600),
    );
    expect(
      find.bySemanticsLabel('This month, selected, 1 of 2'),
      findsOneWidget,
    );
    final semantics = tester.getSemantics(find.text('One day'));
    expect(semantics.hint, 'Show spending for one day');
    for (final (label, body) in [
      (
        'Where your money went',
        'Your spends grouped by category. Spends without a category count '
            'as Other.',
      ),
      (
        'Highest-spending day',
        'The day you spent the most. If two days tie, the earlier one is '
            'shown.',
      ),
      (
        'Average daily spend',
        'What you spent on the days that have ended, divided by the number '
            'of those days.',
      ),
      (
        'Days',
        'How the days that have ended turned out. A day fully covered from '
            'savings counts as on budget.',
      ),
      (
        'Net spent',
        'Spends minus refunds. This matches "Spent so far" on Home.',
      ),
    ]) {
      final button = find.byWidgetPredicate(
        (w) => w is InfoButton && w.label == label,
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text(body), findsOneWidget, reason: label);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
    }
    final link = tester.getSemantics(find.text('Month statement'));
    expect(link.hint, "See how this month's budget was worked out");
    await tester.tap(find.text('One day'));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(findCopy('Fri, 13 Nov')).hint, 'Pick a day');
  });

  testWidgets('TC-013-30 dashboard semantics read as full sentences', (
    tester,
  ) async {
    await pumpDashboard(tester, fixture: fixtureB);
    expect(
      find.bySemanticsLabel('Shopping, ₹1,000, 18 percent'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Days, 4 saved, 2 on budget, 2 overspent'),
      findsOneWidget,
    );
    final highest = find.bySemanticsLabel(
      'Highest-spending day, Wednesday 11 November, ₹1,130',
    );
    expect(highest, findsOneWidget);
    expect(tester.getSemantics(highest).hint, 'See this day');
    // Bars and the day strip are not in the semantics tree.
    expect(find.bySemanticsLabel(RegExp('^[●○◆]')), findsNothing);
  });

  testWidgets('TC-013-30 days sentence names the covered days', (tester) async {
    await pumpDashboard(tester, fixture: fixtureAPlusCover);
    expect(
      find.bySemanticsLabel(
        'Days, 4 saved, 3 on budget, 1 overspent, including 1 covered from '
        'savings',
      ),
      findsOneWidget,
    );
  });

  testWidgets('TC-013-39 the dashboard follows midnight and keeps a chosen '
      'day', (tester) async {
    final clock = TestClock(DateTime(2026, 11, 13, 23, 59));
    await pumpDashboard(tester, fixture: fixtureA, clock: clock);
    await _tapOneDay(tester);
    expect(findCopy('Fri, 13 Nov'), findsOneWidget);
    clock.now = DateTime(2026, 11, 14, 0, 1);
    sendToBackground(tester);
    bringToForeground(tester);
    await tester.pumpAndSettle();
    expect(findCopy('Sat, 14 Nov'), findsOneWidget);

    await _pickDay(tester, 'Sat, 14 Nov', 11);
    clock.now = DateTime(2026, 11, 15, 0, 1);
    sendToBackground(tester);
    bringToForeground(tester);
    await tester.pumpAndSettle();
    expect(findCopy('Wed, 11 Nov'), findsOneWidget);
  });

  testWidgets('TC-013-42 the range choice does not change the month figures', (
    tester,
  ) async {
    await pumpDashboard(tester, fixture: fixtureA);
    expect(findCopy('₹638 a day'), findsOneWidget);
    await _tapOneDay(tester);
    await _pickDay(tester, 'Fri, 13 Nov', 11);
    expect(findCopy('₹638 a day'), findsOneWidget);
    expect(findCopy('Wed, 11 Nov · ₹1,130'), findsOneWidget);

    await tapTab(tester, 'Home');
    await tapTab(tester, 'Dashboard');
    expect(find.bySemanticsLabel('One day, selected, 2 of 2'), findsOneWidget);
    expect(findCopy('Wed, 11 Nov'), findsWidgets);

    // A fresh start (new provider scope) is This month again.
    await tester.pumpWidget(const SizedBox());
    await pumpDashboard(tester, fixture: fixtureA);
    expect(
      find.bySemanticsLabel('This month, selected, 1 of 2'),
      findsOneWidget,
    );
  });

  testWidgets('TC-013-43 loading and error states never show a false zero', (
    tester,
  ) async {
    final held = storeFor(fixtureA)..readDelay = Completer<void>();
    await pumpDashboard(tester, fixture: fixtureA, money: held);
    expect(find.bySemanticsLabel('Loading your dashboard'), findsOneWidget);
    expect(find.textContaining('₹0'), findsNothing);
    expect(find.textContaining('0%'), findsNothing);
    held.readDelay!.complete();
    await tester.pumpAndSettle();
    expect(findCopy('All ₹5,530 so far is in Other.'), findsOneWidget);

    final failing = storeFor(fixtureA)..readFails = true;
    await pumpDashboard(tester, fixture: fixtureA, money: failing);
    expect(find.text("Couldn't load your data"), findsOneWidget);
    expect(find.text('Tap Try again. Nothing has been lost.'), findsOneWidget);
    failing.readFails = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(findCopy('All ₹5,530 so far is in Other.'), findsOneWidget);
  });

  testWidgets('TC-013-44 dashboard hint still works with the new content', (
    tester,
  ) async {
    await pumpDashboard(tester, fixture: fixtureA, hintsSeen: false);
    const text =
        "Check back after a week of spending. That's when your patterns "
        'start to show.';
    expect(find.text(text), findsOneWidget);
    expect(findCopy('Where your money went'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text(text), findsNothing);
  });

  testWidgets('TC-013-47 a month that is not set up shows last month', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      fixture: fixtureA.copyWith(today: d(2026, 12, 5)),
    );
    expect(findCopy('Last month · 5 Nov – 4 Dec 2026'), findsOneWidget);
    expect(find.textContaining('so far'), findsNothing);
    expect(findCopy('Based on all 30 days.'), findsOneWidget);
    expect(findCopy('All ₹5,530 is in Other.'), findsOneWidget);
  });

  testWidgets('TC-013-21 a past month reads as ended and defaults to its '
      'last day', (tester) async {
    final store = storeFor(fixtureO1);
    await pumpDashboard(tester, fixture: fixtureO1, money: store);
    await tester.tap(find.bySemanticsLabel('Previous month'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Ended, 5 Oct – 4 Nov 2026'), findsOneWidget);
    expect(findCopy('This month'), findsWidgets);
    expect(findCopy('5 Oct – 4 Nov 2026'), findsOneWidget);
    expect(find.textContaining('so far'), findsNothing);
    expect(findCopy('Based on all 31 days.'), findsOneWidget);
    expect(findCopy('Sat, 10 Oct · ₹1,400'), findsOneWidget);
    expect(findCopy('₹72 a day'), findsOneWidget);
    expect(findCopy('All ₹2,250 is in Other.'), findsOneWidget);
    await _tapOneDay(tester);
    expect(findCopy('Wed, 4 Nov'), findsOneWidget);
    expect(findCopy('All ₹250 on Wed, 4 Nov is in Other.'), findsOneWidget);

    // Moving to another month keeps One day and resets the day.
    await tester.tap(find.bySemanticsLabel('Next month'));
    await tester.pumpAndSettle();
    expect(findCopy('Fri, 13 Nov'), findsOneWidget);
    expect(find.bySemanticsLabel('One day, selected, 2 of 2'), findsOneWidget);
  });

  testWidgets('TC-013-48 past month day picker is limited to that month', (
    tester,
  ) async {
    final store = storeFor(fixtureO1);
    await pumpDashboard(tester, fixture: fixtureO1, money: store);
    await tester.tap(find.bySemanticsLabel('Previous month'));
    await tester.pumpAndSettle();
    await _tapOneDay(tester);
    expect(findCopy('Wed, 4 Nov'), findsOneWidget);
    await tester.tap(findCopy('Wed, 4 Nov'));
    await tester.pumpAndSettle();
    final picker = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    expect(picker.firstDate, DateTime(2026, 10, 5));
    expect(picker.lastDate, DateTime(2026, 11, 4));
    expect(picker.initialDate, DateTime(2026, 11, 4));
    expect(find.text('Pick a day'), findsWidgets);
  });

  testWidgets('TC-013-55 the old month stays on screen while the next one '
      'loads', (tester) async {
    final store = storeFor(fixtureO1);
    await pumpDashboard(tester, fixture: fixtureO1, money: store);
    expect(findCopy('All ₹5,530 so far is in Other.'), findsOneWidget);

    final october = store.months.first.id;
    final gate = store.delayReadsOf(october);
    await tester.tap(find.bySemanticsLabel('Previous month'));
    await _settleStream(tester);
    // The October read is held: the November content is still there, with no
    // placeholder bars and no false zero.
    expect(findCopy('All ₹5,530 so far is in Other.'), findsOneWidget);
    expect(find.bySemanticsLabel('Loading your dashboard'), findsNothing);
    expect(find.textContaining('₹0'), findsNothing);
    expect(find.textContaining('0%'), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
    expect(findCopy('All ₹2,250 is in Other.'), findsOneWidget);
    expect(findCopy('All ₹5,530 so far is in Other.'), findsNothing);
    expect(findCopy('5 Oct – 4 Nov 2026'), findsOneWidget);
  });

  testWidgets('TC-013-22 month arrows stop at the first and the current '
      'month', (tester) async {
    final store = storeFor(fixtureO1);
    await pumpDashboard(tester, fixture: fixtureO1, money: store);
    IconButtonProbe arrows() => (
      previous: tester.widget<BudgetIconButton>(
        find.widgetWithIcon(BudgetIconButton, Icons.chevron_left),
      ),
      next: tester.widget<BudgetIconButton>(
        find.widgetWithIcon(BudgetIconButton, Icons.chevron_right),
      ),
    );
    expect(arrows().next.onPressed, isNull);
    expect(arrows().previous.onPressed, isNotNull);
    await tester.tap(find.bySemanticsLabel('Previous month'));
    await tester.pumpAndSettle();
    expect(arrows().previous.onPressed, isNull);
    expect(arrows().next.onPressed, isNotNull);
    await tester.tap(find.bySemanticsLabel('Next month'));
    await tester.pumpAndSettle();
    expect(find.textContaining('5 Nov – 4 Dec 2026 · so far'), findsOneWidget);
    expect(arrows().next.onPressed, isNull);

    // With A alone both arrows are disabled.
    await pumpDashboard(tester, fixture: fixtureA);
    expect(arrows().next.onPressed, isNull);
    expect(arrows().previous.onPressed, isNull);
  });
}

typedef IconButtonProbe = ({BudgetIconButton previous, BudgetIconButton next});
