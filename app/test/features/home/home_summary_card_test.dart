import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/home/widgets/summary_card.dart';
import 'package:daily_budget/features/statement/month_statement_screen.dart';
import 'package:daily_budget/features/statement/open_month_statement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/setup_harness.dart';
import '../../helpers/transactions_harness.dart' show addCoverTo, addSpendTo;
import '../../support/find_copy.dart';
import 'home_harness.dart';

// The Home summary card (F-010, plan T-302). Every figure is a literal from
// tests/F-010-home-summary.md.

final CalendarDate _nov13 = d(2026, 11, 13);
final CalendarDate _nov5 = d(2026, 11, 5);

/// The savings-pot sub-line (its spaces are non-breaking).
Finder _potLine(String pot, String covered) =>
    findCopy('$pot in your savings pot · $covered used to cover days');

void main() {
  testWidgets('TC-010-01 home shows summary card today card and calendar in '
      'order', (tester) async {
    await openFixture(tester, a13);

    expect(find.byType(SummaryCard), findsOneWidget);
    expect(findCopy('This month'), findsNothing);
    expect(find.text('Edit this month'), findsNothing);
    final title = topOf(tester, find.text('Daily Budget App'));
    final card = topOf(tester, find.byType(SummaryCard));
    final today = topOf(tester, findCopy('Today · Fri, 13 Nov'));
    expect(title, lessThan(card));
    expect(card, lessThan(today));
  });

  testWidgets('TC-010-02 edit this month opens from the overflow menu', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openFixture(tester, a13);

    await tapVisible(tester, find.byTooltip('More'));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<bool>), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Edit this month')).hint,
      "Change this month's salary, target or fixed costs",
    );
    await tester.tap(find.text('Edit this month'));
    await tester.pumpAndSettle();
    expect(findCopy('Edit this month'), findsOneWidget, reason: 'the title');
    expect(typed(tester, amountInput('Monthly salary')), '40000');
    expect(saveEnabled(tester), isFalse);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(findCopy('Left this month'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-010-03 summary card matches worked example A', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openFixture(tester, a13);

    expect(findCopy('Left this month'), findsOneWidget);
    expect(findCopy('₹19,370'), findsOneWidget);
    expect(colorOf(tester, findCopy('₹19,370')), lightColors.textPrimary);
    expect(findCopy('₹830/day · 5 Nov – 4 Dec'), findsOneWidget);
    expect(ledgerRow('Salary', '₹40,000'), findsOneWidget);
    expect(ledgerRow('Fixed costs', '₹15,100'), findsOneWidget);
    expect(ledgerRow('Spent so far', '₹5,530'), findsOneWidget);
    expect(ledgerRow('Saved this month', '₹2,000'), findsOneWidget);
    expect(ledgerRow('Overspent', '₹470'), findsOneWidget);
    // One mark in the ledger, one in the Today line.
    expect(find.text('●'), findsNWidgets(2));
    expect(find.text('◆'), findsOneWidget);
    expect(colorOf(tester, find.text('●')), lightColors.saved);
    expect(colorOf(tester, find.text('◆')), lightColors.overspent);
    expect(findCopy('Spending target'), findsNothing);
    expect(find.textContaining('savings pot'), findsNothing);
    expect(find.textContaining('Budget changed'), findsNothing);
    expect(findCopy('Month statement'), findsOneWidget);
    // The order of the ledger: Salary, Fixed costs, Spent, Saved, Overspent.
    final order = [
      for (final label in [
        'Salary',
        'Fixed costs',
        'Spent so far',
        'Saved this month',
        'Overspent',
        'Month statement',
      ])
        topOf(tester, findCopy(label)),
    ];
    expect([...order]..sort(), order);
    semantics.dispose();
  });

  testWidgets('TC-010-58 card order matches the design', (tester) async {
    await openFixture(tester, a13);
    final order = [
      topOf(tester, findCopy('₹19,370')),
      topOf(tester, findCopy('₹830/day · 5 Nov – 4 Dec')),
      topOf(tester, findCopy('Safe to spend')),
      topOf(tester, findCopy('Salary')),
      topOf(tester, findCopy('Month statement')),
    ];
    expect([...order]..sort(), order);
    expect(order.toSet(), hasLength(order.length));
  });

  testWidgets('TC-010-06 a cover updates the summary card in place', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final store = await openFixture(tester, a13);

    await change(
      tester,
      store,
      () => addCoverTo(store, d(2026, 11, 11), 30000),
    );

    expect(ledgerRow('Saved this month', '₹2,000'), findsOneWidget);
    expect(
      findCopy('₹1,700 in your savings pot · ₹300 used to cover days'),
      findsOneWidget,
    );
    expect(
      topOf(tester, findCopy('Saved this month')),
      lessThan(topOf(tester, _potLine('₹1,700', '₹300'))),
    );
    expect(ledgerRow('Overspent', '₹170'), findsOneWidget);
    expect(findCopy('₹19,370'), findsOneWidget);
    expect(findCopy('₹899 a day · 22 days left'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-010-07 removing a cover removes the pot sub line', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final store = await openFixture(tester, a13c300);
    expect(_potLine('₹1,700', '₹300'), findsOneWidget);

    await change(tester, store, store.coversByMonth.clear);

    expect(ledgerRow('Overspent', '₹470'), findsOneWidget);
    expect(find.textContaining('savings pot'), findsNothing);
    expect(ledgerRow('Saved this month', '₹2,000'), findsOneWidget);
    expect(findCopy('₹19,370'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-010-11 shortfall month matches worked example S', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openFixture(tester, s8);

    expect(findCopy('−₹1,200'), findsOneWidget);
    expect(colorOf(tester, findCopy('−₹1,200')), lightColors.overspent);
    expect(findCopy("You're ₹1,200 over for this month."), findsOneWidget);
    expect(findCopy('₹0/day · 5 Nov – 4 Dec'), findsOneWidget);
    expect(findCopy('−₹1,000 this month'), findsOneWidget);
    expect(
      findCopy('Every spend this month counts as overspent.'),
      findsOneWidget,
    );
    expect(ledgerRow('Salary', '₹20,000'), findsOneWidget);
    expect(ledgerRow('Fixed costs', '₹21,000'), findsOneWidget);
    expect(ledgerRow('Spent so far', '₹200'), findsOneWidget);
    expect(ledgerRow('Saved this month', '₹0'), findsOneWidget);
    expect(ledgerRow('Overspent', '₹200'), findsOneWidget);
    // Saved ₹0 has no mark; Overspent has the diamond (plus the hero's and
    // the panel's).
    expect(find.text('●'), findsNothing);
    expect(todayCardText(), 'budget ₹0 · spent ₹0 · on budget');
    semantics.dispose();
  });

  testWidgets('TC-010-12 shortfall panel is shown on every day of the month', (
    tester,
  ) async {
    final s1 = customFixture(
      name: 'S1 continued',
      today: _nov5,
      values: s1Values(),
      continued: true,
    );
    for (final day in [_nov5, d(2026, 11, 20), d(2026, 12, 4)]) {
      await tester.pumpWidget(const SizedBox());
      await openFixture(tester, s1.copyWith(today: day));
      expect(findCopy('−₹1,000 this month'), findsOneWidget, reason: day.iso);
      expect(
        findCopy('Every spend this month counts as overspent.'),
        findsOneWidget,
      );
      expect(todayCardText(), 'budget ₹0 · spent ₹0 · on budget');
    }
  });

  testWidgets('TC-010-13 shortfall month counts todays overspend in '
      'overspent', (tester) async {
    final semantics = tester.ensureSemantics();
    final store = await openFixture(tester, s8);
    expect(ledgerRow('Overspent', '₹200'), findsOneWidget);

    await change(tester, store, () => addSpendTo(store, d(2026, 11, 8), 15000));

    expect(todayCardText(), 'budget ₹0 · spent ₹150 · overspent ₹150');
    expect(ledgerRow('Spent so far', '₹350'), findsOneWidget);
    expect(findCopy('−₹1,350'), findsOneWidget);
    expect(findCopy("You're ₹1,350 over for this month."), findsOneWidget);
    expect(ledgerRow('Overspent', '₹350'), findsOneWidget);
    expect(ledgerRow('Saved this month', '₹0'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-010-15 zero spendable month shows the left for daily '
      'spending panel', (tester) async {
    final zero = customFixture(
      name: 'zero',
      today: d(2026, 11, 8),
      continued: true,
      values: const FullMonthValues(
        salary: Paise(2000000),
        fixedCosts: [
          FixedCost(name: 'Rent', amount: Paise(1500000)),
          FixedCost(name: 'EMI', amount: Paise(500000)),
        ],
      ),
    );
    final store = await openFixture(tester, zero);

    expect(findCopy('₹0 left for daily spending'), findsOneWidget);
    expect(findCopy('○'), findsNWidgets(2), reason: 'panel and Today line');
    expect(findCopy('₹0/day · 5 Nov – 4 Dec'), findsOneWidget);
    expect(findCopy('₹0'), findsWidgets);
    expect(find.textContaining('over for this month'), findsNothing);
    expect(find.text('◆'), findsNothing);

    await change(tester, store, () => addSpendTo(store, d(2026, 11, 8), 10000));

    expect(findCopy('−₹100'), findsOneWidget);
    expect(findCopy("You're ₹100 over for this month."), findsOneWidget);
    expect(findCopy('₹0 left for daily spending'), findsOneWidget);
  });

  testWidgets('TC-010-16 two period month matches worked example M', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openFixture(tester, m20);

    expect(findCopy('₹6,900'), findsOneWidget);
    expect(findCopy('₹552/day · 1 – 30 Nov'), findsOneWidget);
    expect(ledgerRow('Salary', '₹35,000'), findsOneWidget);
    expect(ledgerRow('Fixed costs', '₹15,100'), findsOneWidget);
    expect(ledgerRow('Spent so far', '₹13,000'), findsOneWidget);
    expect(ledgerRow('Saved this month', '₹2,115'), findsOneWidget);
    expect(
      findCopy('₹1,915 in your savings pot · ₹200 used to cover days'),
      findsOneWidget,
    );
    expect(ledgerRow('Overspent', '₹537'), findsOneWidget);
    expect(todayCardText(), 'budget ₹552 · spent ₹850 · overspent ₹297');
    expect(findCopy('Today · Fri, 20 Nov'), findsOneWidget);
    expect(findCopy('Budget changed on 13 Nov'), findsOneWidget);
    expect(findCopy('See month statement'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-010-17 example M with a cover shows pot and overspent', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final store = await openFixture(tester, m20nc);

    expect(ledgerRow('Saved this month', '₹2,115'), findsOneWidget);
    expect(find.textContaining('savings pot'), findsNothing);
    expect(ledgerRow('Overspent', '₹737'), findsOneWidget);
    expect(findCopy('₹6,900'), findsOneWidget);

    await change(tester, store, () => addCoverTo(store, d(2026, 11, 6), 20000));

    expect(ledgerRow('Saved this month', '₹2,115'), findsOneWidget);
    expect(
      findCopy('₹1,915 in your savings pot · ₹200 used to cover days'),
      findsOneWidget,
    );
    expect(ledgerRow('Overspent', '₹537'), findsOneWidget);
    expect(findCopy('₹6,900'), findsOneWidget);
    expect(todayCardText(), 'budget ₹552 · spent ₹850 · overspent ₹297');
    semantics.dispose();
  });

  testWidgets('TC-010-19 budget changed line names the latest change and '
      'opens the statement', (tester) async {
    final opened = <int>[];
    final overrides = [
      monthStatementLauncherProvider.overrideWithValue(
        (context, monthId, {scrollToPeriodStart}) => opened.add(monthId),
      ),
    ];
    final store = await openFixture(tester, m20, overrides: overrides);
    await tapVisible(tester, find.text('See month statement'));
    await tester.pumpAndSettle();
    expect(opened, [store.months.single.id]);

    await tester.pumpWidget(const SizedBox());
    final third = m20.copyWith(
      name: 'M20 third period',
      today: d(2026, 11, 28),
      periods: [
        ...m20.current.periods,
        period(d(2026, 11, 28), e2Values(salary: 3500000, rent: 1100000)),
      ],
    );
    await openFixture(tester, third);
    expect(findCopy('Budget changed on 28 Nov'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await openFixture(tester, a13);
    expect(find.textContaining('Budget changed'), findsNothing);
    expect(findCopy('See month statement'), findsNothing);
    expect(findCopy('Month statement'), findsOneWidget);
  });

  testWidgets('TC-010-19 the real month statement opens and Back keeps the '
      'scroll', (tester) async {
    await openFixture(tester, m20);
    double scroll() => tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .pixels;

    await tapVisible(tester, find.text('See month statement'));
    await tester.pumpAndSettle();
    expect(find.byType(MonthStatementScreen), findsOneWidget);
    expect(findCopy('Month statement'), findsWidgets);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(MonthStatementScreen), findsNothing);
    final before = scroll();
    expect(findCopy('See month statement'), findsOneWidget);
    expect(before, scroll());
  });

  testWidgets('TC-010-20 mid month first month shows money left at start', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openFixture(tester, f12);

    expect(findCopy('Salary'), findsNothing);
    expect(ledgerRow('Money left at start', '₹24,900'), findsOneWidget);
    expect(ledgerRow('Fixed costs', '₹0'), findsOneWidget);
    expect(findCopy('₹23,000'), findsOneWidget);
    expect(findCopy('₹996/day · 10 Nov – 4 Dec'), findsOneWidget);
    expect(findCopy("This month's budget started on 10 Nov."), findsOneWidget);
    expect(ledgerRow('Saved this month', '₹196'), findsOneWidget);
    expect(ledgerRow('Overspent', '₹104'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-010-21 late setup shows the fresh start layout', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final late = customFixture(
      name: 'late',
      today: d(2026, 12, 12),
      month: BudgetMonth.startIn(5, 2026, 12),
      first: d(2026, 12, 12),
      values: const MidMonthStartValues(moneyLeft: Paise(3100000)),
    );
    await openFixture(tester, late);

    expect(findCopy("This month's budget started on 12 Dec."), findsOneWidget);
    expect(ledgerRow('Money left at start', '₹31,000'), findsOneWidget);
    expect(findCopy('₹1,291/day · 12 Dec – 4 Jan'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-010-22 still to pay costs lower the daily figure', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final stillToPay = customFixture(
      name: 'still to pay',
      today: d(2026, 11, 10),
      first: d(2026, 11, 10),
      values: const MidMonthStartValues(
        moneyLeft: Paise(2490000),
        fixedCostsStillToPay: [FixedCost(name: 'Rent', amount: Paise(490000))],
      ),
    );
    await openFixture(tester, stillToPay);

    expect(ledgerRow('Money left at start', '₹24,900'), findsOneWidget);
    expect(ledgerRow('Fixed costs', '₹4,900'), findsOneWidget);
    expect(findCopy('₹800/day · 10 Nov – 4 Dec'), findsOneWidget);
    expect(findCopy('₹20,000'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-010-23 target row is shown when a lower target is set', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openFixture(
      tester,
      customFixture(
        name: 'target',
        today: _nov5,
        values: e2Values(target: 2000000),
      ),
    );

    expect(ledgerRow('Salary', '₹40,000'), findsOneWidget);
    expect(ledgerRow('Spending target', '₹20,000'), findsOneWidget);
    expect(
      topOf(tester, findCopy('Salary')),
      lessThan(topOf(tester, findCopy('Spending target'))),
    );
    expect(findCopy('₹163/day · 5 Nov – 4 Dec'), findsOneWidget);
    expect(findCopy('₹4,900'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-010-24 no target row without a lower target', (tester) async {
    await openFixture(tester, a13);
    expect(findCopy('Spending target'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await openFixture(
      tester,
      customFixture(
        name: 'equal target',
        today: _nov5,
        values: e2Values(target: 4000000),
      ),
    );
    expect(findCopy('Spending target'), findsNothing);
  });

  testWidgets('TC-010-29 home shows no paise', (tester) async {
    final paise = a13.mapEntries('A13 with paise', (entry) {
      if (entry.date == d(2026, 11, 9) && entry.paise == 25000) {
        return entry.copyWith(paise: 25050);
      }
      if (entry.date == d(2026, 11, 11)) return entry.copyWith(paise: 113050);
      return entry;
    });
    await openFixture(tester, paise);

    final moneyTexts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
        .where((text) => text.contains('₹'));
    expect(moneyTexts, isNotEmpty);
    for (final text in moneyTexts) {
      expect(RegExp(r'\d\.\d').hasMatch(text), isFalse, reason: text);
    }
  });

  testWidgets('TC-010-31 home updates on add edit and delete', (tester) async {
    final semantics = tester.ensureSemantics();
    final store = await openFixture(tester, a13);
    final monthId = store.months.single.id;

    await change(tester, store, () => addSpendTo(store, _nov13, 10000));
    expect(ledgerRow('Spent so far', '₹5,630'), findsOneWidget);
    expect(findCopy('₹19,270'), findsOneWidget);
    expect(todayCardText(), 'budget ₹830 · spent ₹520 · ₹310 left today');

    await change(tester, store, () {
      final list = store.spendsByMonth[monthId]!;
      final index = list.indexWhere(
        (s) => s.spend.amount == const Paise(113000),
      );
      list[index] = StoredSpend(
        spend: spend(d(2026, 11, 11), 83000, id: list[index].spend.id),
      );
    });
    expect(ledgerRow('Overspent', '₹170'), findsOneWidget);
    expect(findCopy('₹19,570'), findsOneWidget);

    await change(tester, store, () {
      store.spendsByMonth[monthId]!.removeWhere((s) => s.spend.date == _nov5);
    });
    expect(ledgerRow('Saved this month', '₹2,500'), findsOneWidget);
    expect(ledgerRow('Spent so far', '₹4,830'), findsOneWidget);
    expect(findCopy('₹20,070'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-010-39 every home figure has its label and help', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final helps = <String, String>{
      'Left this month':
          "What's budgeted for this month minus what you've spent so far.",
      'Salary':
          'The salary you entered for this month. If you changed it, this is '
          'the latest amount.',
      'Fixed costs':
          "Rent, EMIs and other monthly bills. They're taken out before your "
          'daily budget is worked out.',
      'Spent so far':
          "Everything you've spent this month up to now, after refunds.",
      'Saved this month':
          "Money left over on days that have ended. Today's leftover joins at "
          'midnight.',
      'Overspent':
          "How much you went over on days that aren't covered from savings "
          'yet.',
      'Today':
          "Today's budget minus what you've spent today. Whatever is left at "
          'midnight goes to your savings pot.',
    };
    await openFixture(tester, a13);
    for (final MapEntry(key: label, value: body) in helps.entries) {
      final info = find.bySemanticsLabel('More about $label');
      await tester.ensureVisible(info.first);
      await tester.pumpAndSettle();
      await tester.tap(info.first);
      await tester.pumpAndSettle();
      expect(findCopy(body), findsOneWidget, reason: label);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
    }

    // The two rows of other states.
    for (final (fixture, label, body) in [
      (
        f12,
        'Money left at start',
        'How much you had when you started using the app partway through '
            'the month.',
      ),
      (
        customFixture(
          name: 'target',
          today: _nov5,
          values: e2Values(target: 2000000),
        ),
        'Spending target',
        'The amount you chose to spend this month, including fixed costs.',
      ),
    ]) {
      await tester.pumpWidget(const SizedBox());
      await openFixture(tester, fixture);
      final info = find.bySemanticsLabel('More about $label');
      await tester.ensureVisible(info.first);
      await tester.pumpAndSettle();
      await tester.tap(info.first);
      await tester.pumpAndSettle();
      expect(findCopy(body), findsOneWidget, reason: label);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
    }
    semantics.dispose();
  });

  testWidgets('TC-010-41 ledger stacks at large text and rows read as one '
      'sentence', (tester) async {
    final semantics = tester.ensureSemantics();
    await openFixture(tester, a13);
    // Below 1.3x one line: the amount sits level with its label.
    expect(
      (topOf(tester, findCopy('Overspent')) - topOf(tester, find.text('₹470')))
          .abs(),
      lessThan(14),
    );
    expect(ledgerRow('Overspent', '₹470'), findsOneWidget);
    expect(ledgerRow('Saved this month', '₹2,000'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Left this month, ₹19,370. ₹830 a day, 5 November to 4 December.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Today, Friday 13 November: budget ₹830, spent ₹420, ₹410 left today.',
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
    await openFixture(tester, a13, textScale: 2);
    expect(
      topOf(tester, find.text('₹470')),
      greaterThan(topOf(tester, findCopy('Overspent')) + 20),
      reason: 'stacked above 1.3x',
    );
    expect(ledgerRow('Overspent', '₹470'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await openFixture(tester, s8);
    expect(
      find.bySemanticsLabel(
        "Left this month, minus ₹1,200. You're ₹1,200 over for this month.",
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Minus ₹1,000 this month. Every spend this month counts as '
        'overspent.',
      ),
      findsOneWidget,
    );
    expect(ledgerRow('Saved this month', '₹0'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-010-44 ten crore left fits the hero', (tester) async {
    final huge = customFixture(
      name: 'ten crore',
      today: _nov5,
      values: const FullMonthValues(salary: Paise(10000000000)),
    );
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(const SizedBox());
      await openFixture(tester, huge, textScale: scale);
      expect(findCopy('₹10,00,00,000'), findsWidgets, reason: 'x$scale');
      expect(findCopy('₹33,33,333/day · 5 Nov – 4 Dec'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'x$scale');
      final box = find.ancestor(
        of: find.text('₹10,00,00,000').first,
        matching: find.byType(FittedBox),
      );
      expect(tester.getSize(box.first).width, lessThanOrEqualTo(360 - 80));
    }
  });

  testWidgets('TC-010-45 first day of the month has no saved or overspent', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final store = await openFixture(tester, e2Day1);

    expect(findCopy('₹24,900'), findsOneWidget);
    expect(ledgerRow('Saved this month', '₹0'), findsOneWidget);
    expect(ledgerRow('Overspent', '₹0'), findsOneWidget);
    // Only the Today line's mark: Saved and Overspent are ₹0, no marks.
    expect(find.text('●'), findsOneWidget);
    expect(find.text('◆'), findsNothing);
    expect(todayCardText(), 'budget ₹830 · spent ₹0 · ₹830 left today');
    expect(findCopy('₹830 a day · 30 days left'), findsOneWidget);

    await change(tester, store, () => addSpendTo(store, _nov5, 25000));
    expect(findCopy('₹24,650'), findsOneWidget);
    expect(todayCardText(), 'budget ₹830 · spent ₹250 · ₹580 left today');
    expect(ledgerRow('Saved this month', '₹0'), findsOneWidget);
    expect(ledgerRow('Overspent', '₹0'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-010-47 left of zero is neutral and below zero is overspent', (
    tester,
  ) async {
    final exactlyZero = e2Day1.plus(
      name: 'left zero',
      entries: [fixtureSpend(_nov5, 2490000)],
    );
    await openFixture(tester, exactlyZero);
    expect(findCopy('₹0'), findsWidgets);
    expect(colorOf(tester, findCopy('₹0')), lightColors.textPrimary);
    expect(find.text('◆'), findsNWidgets(2), reason: 'Overspent row, Today');
    expect(find.textContaining('over for this month'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    final below = e2Day1.plus(
      name: 'left below zero',
      entries: [fixtureSpend(_nov5, 2500000)],
    );
    await openFixture(tester, below);
    expect(findCopy('−₹100'), findsOneWidget);
    expect(colorOf(tester, findCopy('−₹100')), lightColors.overspent);
    expect(findCopy("You're ₹100 over for this month."), findsOneWidget);
    expect(find.textContaining('₹0 left for daily spending'), findsNothing);
  });

  testWidgets('TC-010-49 a change that removes the shortfall hides the '
      'panel', (tester) async {
    final removed = customFixture(
      name: 'shortfall removed',
      today: d(2026, 11, 10),
      values: s1Values(),
      entries: [fixtureSpend(d(2026, 11, 6), 20000)],
      periods: [
        period(
          _nov5,
          s1Values(),
          changedAt: at(d(2026, 11, 4), 0),
          continued: true,
        ),
        period(d(2026, 11, 10), s1Values(emi: 300000)),
      ],
    );
    await openFixture(tester, removed);

    expect(find.textContaining('this month'), findsNWidgets(2));
    expect(
      findCopy('Every spend this month counts as overspent.'),
      findsNothing,
    );
    expect(findCopy('₹1,800'), findsOneWidget);
    expect(findCopy('₹80/day · 5 Nov – 4 Dec'), findsOneWidget);
    expect(findCopy('Budget changed on 10 Nov'), findsOneWidget);
    expect(findCopy('₹72 a day · 25 days left'), findsOneWidget);
  });

  testWidgets('TC-010-50 future dated spends are not counted on home', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final future = a13.plus(
      name: 'A13 + future',
      entries: [fixtureSpend(d(2026, 11, 15), 50000)],
    );
    await openFixture(tester, future);
    expect(ledgerRow('Spent so far', '₹5,530'), findsOneWidget);
    expect(findCopy('₹19,370'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-010-51 refund larger than all spends gives negative spent '
      'so far', (tester) async {
    final semantics = tester.ensureSemantics();
    final refund = e2Day1.plus(
      name: 'refund only',
      entries: [fixtureMoneyIn(_nov5, 30000)],
    );
    await openFixture(tester, refund);

    expect(ledgerRow('Spent so far', 'minus ₹300'), findsOneWidget);
    expect(findCopy('₹25,200'), findsOneWidget);
    expect(todayCardText(), 'budget ₹830 · spent −₹300 · ₹1,130 left today');
    semantics.dispose();
  });
}
