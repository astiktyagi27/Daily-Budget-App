// ignore_for_file: no_adjacent_strings_in_list, long expected texts
// F-014 T-402: the statement screen on the fake repositories and the real
// engine. Expected texts are literals of tests/F-014 (section 1, 2).

import 'dart:async';

import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/statement/widgets/period_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/bundled_fonts.dart';
import '../../helpers/day_details_harness.dart' show openDay;
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/statement_harness.dart';
import '../../support/app_lifecycle.dart';
import '../../support/find_copy.dart';

/// Every rich text on screen as a person reads it.
List<String> _texts(WidgetTester tester) => [
  for (final r in tester.widgetList<RichText>(find.byType(RichText)))
    plainCopy(r.text.toPlainText(includeSemanticsLabels: false))
        .replaceAll('￼', ''),
];

void _expectTexts(WidgetTester tester, List<String> wanted) {
  final texts = _texts(tester);
  for (final text in wanted) {
    expect(texts, contains(text), reason: text);
  }
}

void _expectNoText(WidgetTester tester, String text) =>
    expect(_texts(tester), isNot(contains(text)), reason: text);

/// A tall phone so that the whole statement is built at once.
const _tall = Size(360, 4000);

/// The whole rupees of every semantics label that starts `<label>, `, in
/// reading order (the totals card first, then each period card).
List<int> _shown(WidgetTester tester, String label) {
  final found = find.bySemanticsLabel(RegExp('^$label, '));
  return [
    for (var i = 0; i < found.evaluate().length; i++)
      int.parse(
        RegExp(r'₹([\d,]+)')
            .firstMatch(tester.getSemantics(found.at(i)).label)!
            .group(1)!
            .replaceAll(',', ''),
      ),
  ];
}

/// A one-month fixture (E2 values unless a list of periods is given).
Phase3Fixture _fx({
  required CalendarDate today,
  required List<BudgetPeriod> periods,
  BudgetMonth? month,
  CalendarDate? first,
  List<FixtureEntry> entries = const [],
}) {
  final m = month ?? nov2026;
  return Phase3Fixture(
    name: 'custom',
    today: today,
    months: [
      FixtureMonth(
        month: m,
        firstBudgetedDay: first ?? m.start,
        periods: periods,
        entries: entries,
      ),
    ],
  );
}

BudgetPeriod _first() =>
    period(d(2026, 11, 5), e2Values(), changedAt: at(d(2026, 11, 4), 0));

void main() {
  setUpAll(loadBundledFonts);

  testWidgets('TC-014-03 november statement matches example m', (tester) async {
    await pumpStatement(tester, fixtureMFull, size: _tall);

    expect(findCopy('Month statement'), findsOneWidget);
    _expectTexts(tester, [
      '1 – 30 Nov 2026',
      'Period 1 of 2',
      'Period 2 of 2',
      '1 Nov – 12 Nov · 12 days',
      '13 Nov – 30 Nov · 18 days',
      'Month started',
      'Salary changed',
      '₹40,000 − ₹15,100 fixed = ₹24,900 over 30 days → ₹830/day',
      '₹35,000 − ₹15,100 fixed = ₹19,900, minus ₹9,960 already budgeted = '
          '₹9,940 over 18 days → ₹552/day',
      'Amounts are in whole rupees. Calculations use exact amounts.',
    ]);
    expect(_texts(tester).where((t) => t.contains('so far')), isEmpty);
    expect(_texts(tester).where((t) => t.contains('in progress')), isEmpty);
    // The period lines (label then amount, in order).
    for (final text in [
      '₹9,960',
      '₹9,000',
      '₹1,400',
      '₹240',
      '₹9,940',
      '₹10,000',
      '−₹500',
      '₹9,500',
      '₹740',
      '₹300',
    ]) {
      expect(
        _texts(tester).where((t) => t.endsWith(text)),
        isNotEmpty,
        reason: text,
      );
    }
  });

  testWidgets('TC-014-04 month total card matches example m', (tester) async {
    await pumpStatement(tester, fixtureMFull, size: _tall);

    expect(findCopy('Month total'), findsOneWidget);
    expect(findCopy('So far'), findsNothing);
    expect(findCopy('Short this month'), findsNothing);
    final semantics = tester.ensureSemantics();
    for (final label in [
      'Money for the month, ₹19,900',
      'Spent, ₹19,000',
      'Refunds, minus ₹500',
      'Net spent, ₹18,500',
      'Saved, ₹2,140',
      'Covered from savings, ₹200',
      'Overspent, ₹540',
      'Savings pot, ₹1,940',
      'Left, ₹1,400',
    ]) {
      expect(find.bySemanticsLabel(label), findsWidgets, reason: label);
    }
    semantics.dispose();
    // Each total row has its (i).
    for (final name in [
      'Money for the month',
      'Spent',
      'Refunds',
      'Net spent',
      'Saved',
      'Covered from savings',
      'Overspent',
      'Savings pot',
      'Left',
    ]) {
      expect(find.bySemanticsLabel('More about $name'), findsOneWidget);
    }
    expect(find.byIcon(Icons.info_outline), findsWidgets);
  });

  testWidgets('TC-014-06 shown lines add up and satisfy the check line', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpStatement(tester, fixtureMFull, size: _tall);

    final money = _shown(tester, 'Money for the month');
    final budget = _shown(tester, 'Budget');
    final spent = _shown(tester, 'Spent');
    final net = _shown(tester, 'Net spent');
    final saved = _shown(tester, 'Saved');
    final overspent = _shown(tester, 'Overspent');
    final covered = _shown(tester, 'Covered from savings');
    // Totals card first; period 1 has no refunds, so its Spent is its net.
    expect(money, [19900]);
    expect(budget, [9960, 9940]);
    expect(spent, [19000, 9000, 10000]);
    expect(net, [18500, 9500]);
    expect(saved, [2140, 1400, 740]);
    expect(overspent, [540, 240, 300]);
    expect(covered, [200, 200, 0]);

    expect(budget[0] + budget[1], money[0]);
    expect(spent[1] + net[1], net[0]);
    expect(saved[1] + saved[2], saved[0]);
    expect(overspent[1] + overspent[2], overspent[0]);
    expect(covered[1] + covered[2], covered[0]);
    // Budget - Net spent = Saved - Overspent - Covered, as shown.
    expect(budget[0] - spent[1], saved[1] - overspent[1] - covered[1]);
    expect(budget[1] - net[1], saved[2] - overspent[2] - covered[2]);
    expect(money[0] - net[0], saved[0] - overspent[0] - covered[0]);
    semantics.dispose();
  });

  testWidgets('TC-014-42 refunds are written with a minus', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpStatement(tester, fixtureMFull, size: _tall);

    final refunds = _texts(tester).where((t) => t.endsWith('₹500')).toList();
    expect(refunds, ['−₹500', '−₹500'], reason: 'month card and period 2');
    expect(find.bySemanticsLabel('Refunds, minus ₹500'), findsNWidgets(2));
    expect(_texts(tester), isNot(contains('₹500')));
    semantics.dispose();
  });

  testWidgets('TC-014-52 so far line moves to the new day at midnight', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final shown = await pumpStatement(tester, fixtureM20, size: _tall);
    shown.clock.now = DateTime(2026, 11, 20, 23, 59);
    sendToBackground(tester);
    bringToForeground(tester);
    await tester.pumpAndSettle();
    expect(
      _texts(tester),
      contains('1 – 30 Nov 2026 · so far (to Fri, 20 Nov)'),
    );
    expect(find.bySemanticsLabel('Overspent, ₹537'), findsOneWidget);
    expect(find.bySemanticsLabel('Left, ₹6,900'), findsOneWidget);

    shown.clock.now = DateTime(2026, 11, 21, 0, 1);
    sendToBackground(tester);
    bringToForeground(tester);
    await tester.pumpAndSettle();
    expect(
      _texts(tester),
      contains('1 – 30 Nov 2026 · so far (to Sat, 21 Nov)'),
    );
    expect(
      _texts(tester),
      isNot(contains('1 – 30 Nov 2026 · so far (to Fri, 20 Nov)')),
    );
    expect(find.bySemanticsLabel('Overspent, ₹537'), findsOneWidget);
    expect(find.bySemanticsLabel('Saved, ₹2,115'), findsOneWidget);
    expect(find.bySemanticsLabel('Left, ₹6,900'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-014-07 so far statement matches home left', (tester) async {
    await pumpStatement(tester, fixtureM20, size: _tall);

    _expectTexts(tester, [
      '1 – 30 Nov 2026 · so far (to Fri, 20 Nov)',
      '₹19,900',
      '₹13,000',
      '● ₹2,115',
      '₹200',
      '◆ ₹537',
      '₹1,915',
      '₹6,900',
      '13 Nov – 30 Nov · 18 days · in progress',
    ]);
    expect(findCopy('So far'), findsOneWidget);
    expect(findCopy('Month total'), findsNothing);
    _expectNoText(
      tester,
      'Totals use exact amounts, so they can differ by a '
      'few rupees from the parts.',
    );
  });

  testWidgets('TC-014-09 what changed lists each stored change in order', (
    tester,
  ) async {
    await pumpStatement(tester, fixtureMFull, size: _tall);

    _expectTexts(tester, [
      'Month started: salary ₹40,000, fixed costs ₹15,100 → ₹830/day',
      'Salary ₹40,000 → ₹35,000 → ₹552/day for the 18 days left',
    ]);
    expect(findCopy('No changes this month.'), findsNothing);

    await pumpStatement(tester, fixtureA, size: _tall);
    _expectTexts(tester, [
      'Month started: salary ₹40,000, fixed costs ₹15,100 → ₹830/day',
    ]);
    expect(findCopy('No changes this month.'), findsOneWidget);
    expect(findCopy('Period 1 of 1'), findsOneWidget);
    // (i) of daily budget: exact.
    await tester.tap(find.bySemanticsLabel('More about daily budget'));
    await tester.pumpAndSettle();
    expect(findCopy('₹24,900 divides evenly over 30 days.'), findsOneWidget);
  });

  testWidgets('TC-014-10 same day changes are listed and only the last sets '
      'the budget', (tester) async {
    await pumpStatement(tester, e2s, size: _tall);

    _expectTexts(tester, [
      'Rent ₹10,000 → ₹13,000 (replaced the same day)',
      'Rent ₹13,000 → ₹11,000 → ₹763/day for the 15 days left',
      '5 Nov – 19 Nov · 15 days',
      '20 Nov – 4 Dec · 15 days',
      '₹40,000 − ₹16,100 fixed = ₹23,900, minus ₹12,450 already budgeted = '
          '₹11,450 over 15 days → ₹763/day',
    ]);
    expect(findCopy('Period 2 of 2'), findsOneWidget);
    expect(findCopy('Period 3 of 3'), findsNothing);
    expect(findCopy(_clock(d(2026, 11, 20), 10)), findsOneWidget);
    expect(findCopy(_clock(d(2026, 11, 20), 18)), findsOneWidget);
  });

  testWidgets('TC-014-11 three periods match the f 006 example', (
    tester,
  ) async {
    await pumpStatement(tester, e2c, size: _tall);

    expect(findCopy('Period 3 of 3'), findsOneWidget);
    _expectTexts(tester, [
      '5 Nov – 19 Nov · 15 days',
      '20 Nov – 27 Nov · 8 days',
      '28 Nov – 4 Dec · 7 days',
      'Rent changed',
      'EMI changed',
      '₹40,000 − ₹18,100 fixed = ₹21,900, minus ₹12,450 already budgeted = '
          '₹9,450 over 15 days → ₹630/day',
      '₹40,000 − ₹17,100 fixed = ₹22,900, minus ₹17,490 already budgeted = '
          '₹5,410 over 7 days → ₹772/day',
      '₹22,900',
    ]);
  });

  testWidgets('TC-014-12 period values keep what was true then', (
    tester,
  ) async {
    await pumpStatement(tester, fixtureMFull, size: _tall);

    expect(findCopy('Rent'), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('^Fixed costs, ₹15,100')),
      findsNWidgets(2),
    );
    await tester.tap(find.text('Fixed costs').first);
    await tester.pumpAndSettle();
    expect(findCopy('Rent'), findsOneWidget);
    expect(findCopy('EMI'), findsOneWidget);
    expect(findCopy('Subscriptions'), findsOneWidget);
    expect(find.text('₹10,000'), findsWidgets);
    // Period 1 keeps the salary of then.
    expect(findCopy('Salary'), findsNWidgets(2));
    expect(find.text('₹40,000'), findsOneWidget);
    expect(find.text('₹35,000'), findsOneWidget);
    await tester.tap(find.text('Fixed costs').first);
    await tester.pumpAndSettle();
    expect(findCopy('Rent'), findsNothing);
  });

  testWidgets('TC-014-13 shortfall statement shows the short line and '
      'totals', (tester) async {
    await pumpStatement(tester, fixtureS, size: _tall);

    expect(findCopy('◆'), findsWidgets);
    _expectTexts(tester, ['₹20,000 − ₹21,000 fixed = −₹1,000']);
    expect(
      findCopy('₹1,000 short · ₹0/day (continued anyway)'),
      findsOneWidget,
    );
    expect(findCopy('Short this month'), findsOneWidget);
    _expectTexts(tester, ['◆ −₹1,200', '◆ −₹1,000']);
    expect(findCopy('5 Nov – 4 Dec · 30 days · in progress'), findsOneWidget);
  });

  testWidgets('TC-014-14 a change that causes a shortfall is shown in its own '
      'period', (tester) async {
    await pumpStatement(tester, c4, size: _tall);

    _expectTexts(tester, [
      '₹25,000 − ₹15,100 fixed = ₹9,900, minus ₹12,450 already budgeted = '
          '−₹2,550',
      '◆ −₹2,550',
    ]);
    expect(
      findCopy('₹2,550 short · ₹0/day (continued anyway)'),
      findsOneWidget,
    );
  });

  testWidgets('TC-014-15 equal salary and fixed costs read as zero left', (
    tester,
  ) async {
    await pumpStatement(
      tester,
      _fx(
        today: d(2026, 11, 8),
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
            continued: true,
          ),
        ],
      ),
      size: _tall,
    );

    expect(findCopy('₹0 left for daily spending · ₹0/day'), findsOneWidget);
    expect(findCopy('Short this month'), findsNothing);
    expect(findCopy('○'), findsOneWidget);
  });

  testWidgets('TC-014-16 mid month first month statement', (tester) async {
    await pumpStatement(tester, fixtureF, size: _tall);

    _expectTexts(
      tester,
      ['5 Nov – 9 Nov: not budgeted (before you started).']
          .map((t) => t.replaceFirst('5 Nov – 9 Nov', '5 – 9 Nov'))
          .toList(),
    );
    _expectTexts(tester, [
      'Month started partway',
      '10 Nov – 4 Dec · 25 days · in progress',
      '₹24,900 − ₹0 still to pay = ₹24,900 over 25 days → ₹996/day',
      'Month started partway: money left ₹24,900, still to pay ₹0 → ₹996/day',
    ]);
    expect(findCopy('Money left'), findsOneWidget);
    expect(findCopy('Still to pay'), findsOneWidget);
    expect(findCopy('Salary'), findsNothing);
    await tester.tap(find.bySemanticsLabel('More about daily budget'));
    await tester.pumpAndSettle();
    expect(findCopy('₹24,900 divides evenly over 25 days.'), findsOneWidget);
  });

  testWidgets('TC-014-17 refund lines appear only where there are refunds', (
    tester,
  ) async {
    await pumpStatement(tester, fixtureMFull, size: _tall);

    // Month card and period 2: Refunds and Net spent; period 1: only Spent.
    expect(findCopy('Refunds'), findsNWidgets(2));
    expect(findCopy('Net spent'), findsNWidgets(2));
    expect(findCopy('Spent'), findsNWidgets(3));
    expect(find.text('−₹500'), findsNothing);
    _expectTexts(tester, ['−₹500', '₹9,500', '₹18,500']);
    await tester.tap(find.bySemanticsLabel('More about Refunds'));
    await tester.pumpAndSettle();
    expect(
      findCopy('Money paid back to you. It lowers what you spent.'),
      findsOneWidget,
    );
  });

  testWidgets('TC-014-18 rounding note appears when parts do not add up', (
    tester,
  ) async {
    await pumpStatement(tester, mx, size: _tall);

    expect(
      findCopy(
        'Totals use exact amounts, so they can differ by a few rupees from '
        'the parts.',
      ),
      findsOneWidget,
    );
    _expectTexts(tester, ['₹9,001', '₹4,500']);
  });

  testWidgets('TC-014-19 no rounding note when the lines add up', (
    tester,
  ) async {
    for (final fixture in [fixtureMFull, fixtureM20, fixtureA]) {
      await pumpStatement(tester, fixture, size: _tall);
      expect(
        findCopy(
          'Totals use exact amounts, so they can differ by a few rupees '
          'from the parts.',
        ),
        findsNothing,
        reason: fixture.name,
      );
    }
  });

  testWidgets('TC-014-20 three periods of one hundred rupees ninety show a '
      'two rupee gap', (tester) async {
    await pumpStatement(
      tester,
      e2c.copyWith(
        entries: [
          fixtureSpend(d(2026, 11, 6), 10090),
          fixtureSpend(d(2026, 11, 22), 10090),
          fixtureSpend(d(2026, 11, 30), 10090),
        ],
      ),
      size: _tall,
    );

    expect(find.text('₹302'), findsWidgets);
    expect(
      findCopy(
        'Totals use exact amounts, so they can differ by a few rupees from '
        'the parts.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('TC-014-21 daily budget help explains the extra paise', (
    tester,
  ) async {
    await pumpStatement(tester, fixtureMFull, size: _tall);

    await tester.tap(find.bySemanticsLabel('More about daily budget').last);
    await tester.pumpAndSettle();
    expect(
      findCopy(
        "₹9,940 doesn't divide evenly by 18 days, so the first 4 days get 1 "
        "paisa more. That's why you see ₹552 every day.",
      ),
      findsOneWidget,
    );
    await tester.tap(findCopy('Got it'));
    await tester.pumpAndSettle();
    expect(findCopy('Got it'), findsNothing);
  });

  testWidgets('TC-014-22 daily budget help for an exact period', (
    tester,
  ) async {
    await pumpStatement(tester, fixtureMFull, size: _tall);

    await tester.tap(find.bySemanticsLabel('More about daily budget').first);
    await tester.pumpAndSettle();
    expect(findCopy('₹24,900 divides evenly over 30 days.'), findsOneWidget);
  });

  testWidgets('TC-014-39 e1 help names the first ten days', (tester) async {
    await pumpStatement(
      tester,
      _fx(
        today: d(2026, 11, 9),
        periods: [
          period(
            d(2026, 11, 5),
            const FullMonthValues(salary: Paise(4000000)),
            changedAt: at(d(2026, 11, 4), 0),
          ),
        ],
      ),
      size: _tall,
    );

    await tester.tap(find.bySemanticsLabel('More about daily budget'));
    await tester.pumpAndSettle();
    expect(
      findCopy(
        "₹40,000 doesn't divide evenly by 30 days, so the first 10 days get "
        "1 paisa more. That's why you see ₹1,333 every day.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('TC-014-25 statement is read only and updates live', (
    tester,
  ) async {
    final opened = await pumpStatement(tester, fixtureM20, size: _tall);

    expect(find.byType(TextField), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(Checkbox), findsNothing);

    // A spend of ₹100 on 20 Nov added elsewhere.
    final id = opened.store.months.last.id;
    opened.store.spendsByMonth[id]!.add(
      StoredSpend(
        spend: Spend(
          id: opened.store.nextId(),
          date: d(2026, 11, 20),
          amount: const Paise(10000),
          createdAt: at(d(2026, 11, 20), 12),
        ),
      ),
    );
    opened.store.notify();
    await tester.pumpAndSettle();

    _expectTexts(tester, ['₹13,100', '₹6,800', '₹4,100', '◆ ₹397']);
  });

  testWidgets('TC-014-31 a change on day one replaces the first period', (
    tester,
  ) async {
    final day1 = d(2026, 11, 1);
    await pumpStatement(
      tester,
      _fx(
        today: d(2026, 11, 2),
        month: BudgetMonth.startIn(1, 2026, 11),
        periods: [
          period(day1, e2Values(), changedAt: at(day1, 9)),
          period(day1, e2Values(salary: 3500000), changedAt: at(day1, 15)),
        ],
      ),
      size: _tall,
    );

    expect(findCopy('Period 2 of 2'), findsNothing);
    _expectTexts(tester, [
      '1 Nov – 30 Nov · 30 days · in progress',
      '₹35,000 − ₹15,100 fixed = ₹19,900 over 30 days → ₹663/day',
      'Month started: salary ₹40,000, fixed costs ₹15,100 (replaced the same '
          'day)',
    ]);
    expect(findCopy(_clock(d(2026, 11, 1), 9)), findsOneWidget);
    expect(findCopy(_clock(d(2026, 11, 1), 15)), findsOneWidget);
  });

  testWidgets('TC-014-58 a change made today starts a period with no past '
      'days', (tester) async {
    final day13 = d(2026, 11, 13);
    final semantics = tester.ensureSemantics();
    await pumpStatement(
      tester,
      _fx(
        today: day13,
        periods: [
          _first(),
          period(day13, e2Values(salary: 3500000), changedAt: at(day13, 10)),
        ],
      ),
      size: _tall,
    );

    _expectTexts(tester, [
      'Period 2 of 2',
      '5 Nov – 12 Nov · 8 days',
      '13 Nov – 4 Dec · 22 days · in progress',
      'Salary changed',
      '₹35,000 − ₹15,100 fixed = ₹19,900, minus ₹6,640 already budgeted = '
          '₹13,260 over 22 days → ₹602/day',
    ]);
    expect(
      _texts(tester).where((t) => t.contains('in progress')),
      hasLength(1),
      reason: 'only the period that starts today is in progress',
    );
    // The last period's own lines: Budget ₹13,260, nothing else above ₹0.
    expect(_shown(tester, 'Budget'), [6640, 13260]);
    // Lists read: the totals card, then Period 1, then Period 2.
    expect(_shown(tester, 'Spent'), [0, 0, 0]);
    expect(_shown(tester, 'Saved'), [6640, 6640, 0]);
    expect(_shown(tester, 'Overspent'), [0, 0, 0]);
    expect(_shown(tester, 'Covered from savings'), [0, 0, 0]);
    // No mark on a zero Saved or Overspent.
    expect(findCopy('● ₹0'), findsNothing);
    expect(findCopy('◆ ₹0'), findsNothing);
    _expectTexts(tester, [
      'Salary ₹40,000 → ₹35,000 → ₹602/day for the 22 days left',
    ]);
    await tester.tap(find.bySemanticsLabel('More about daily budget').last);
    await tester.pumpAndSettle();
    expect(
      findCopy(
        "₹13,260 doesn't divide evenly by 22 days, so the first 16 days get 1 "
        "paisa more. That's why you see ₹602 every day.",
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('TC-014-59 a month without fixed costs has no expander', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpStatement(
      tester,
      _fx(
        today: d(2026, 11, 9),
        periods: [
          period(
            d(2026, 11, 5),
            const FullMonthValues(salary: Paise(4000000)),
            changedAt: at(d(2026, 11, 4), 0),
          ),
        ],
      ),
      size: _tall,
    );

    expect(find.bySemanticsLabel('Fixed costs, ₹0'), findsOneWidget);
    expect(findCopy('Fixed costs'), findsOneWidget);
    final row = tester.getSemantics(find.bySemanticsLabel('Fixed costs, ₹0'));
    expect(row.hint, isNot(contains('Show the fixed costs')));
    expect(row.getSemanticsData().flagsCollection.isButton, isFalse);
    expect(find.byIcon(Icons.expand_more), findsNothing);
    expect(find.bySemanticsLabel('Money for the month, ₹40,000'), findsWidgets);
    _expectTexts(tester, [
      '₹40,000 − ₹0 fixed = ₹40,000 over 30 days → ₹1,333/day',
    ]);
    // Tapping the row does nothing and shows no list.
    final before = _texts(tester);
    await tester.tap(findCopy('Fixed costs'));
    await tester.pumpAndSettle();
    expect(_texts(tester), before);
    expect(find.text('Rent'), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('TC-014-32 a one day period reads over 1 day', (tester) async {
    await pumpStatement(
      tester,
      _fx(
        today: d(2026, 12, 1),
        month: BudgetMonth.startIn(1, 2026, 11),
        periods: [
          period(d(2026, 11, 1), e2Values(), changedAt: at(d(2026, 10, 31), 0)),
          period(d(2026, 11, 30), e2Values(salary: 5000000)),
        ],
      ),
      size: _tall,
    );

    _expectTexts(tester, [
      '30 Nov · 1 day',
      '₹50,000 − ₹15,100 fixed = ₹34,900, minus ₹24,070 already budgeted = '
          '₹10,830 over 1 day → ₹10,830/day',
    ]);
    await tester.tap(find.bySemanticsLabel('More about daily budget').last);
    await tester.pumpAndSettle();
    expect(findCopy('₹10,830 divides evenly over 1 day.'), findsOneWidget);
  });

  testWidgets('TC-014-33 a renamed fixed cost starts a period with the same '
      'budget', (tester) async {
    final day20 = d(2026, 11, 20);
    await pumpStatement(
      tester,
      _fx(
        today: d(2026, 11, 25),
        periods: [
          _first(),
          period(
            day20,
            FullMonthValues(
              salary: const Paise(4000000),
              fixedCosts: [
                const FixedCost(name: 'House rent', amount: Paise(1000000)),
                e2Costs()[1],
                e2Costs()[2],
              ],
            ),
          ),
        ],
      ),
      size: _tall,
    );

    _expectTexts(tester, [
      'Rent renamed to House rent',
      'Rent renamed to House rent → ₹830/day for the 15 days left',
      '₹40,000 − ₹15,100 fixed = ₹24,900, minus ₹12,450 already budgeted = '
          '₹12,450 over 15 days → ₹830/day',
    ]);
  });

  testWidgets('TC-014-34 a change that removes a shortfall hides the short '
      'row', (tester) async {
    await pumpStatement(
      tester,
      _fx(
        today: d(2026, 11, 25),
        periods: [
          period(
            d(2026, 11, 5),
            s1Values(),
            changedAt: at(d(2026, 11, 4), 0),
            continued: true,
          ),
          period(
            d(2026, 11, 20),
            const FullMonthValues(
              salary: Paise(3000000),
              fixedCosts: [
                FixedCost(name: 'Rent', amount: Paise(1500000)),
                FixedCost(name: 'EMI', amount: Paise(600000)),
              ],
            ),
          ),
        ],
      ),
      size: _tall,
    );

    expect(
      findCopy('₹1,000 short · ₹0/day (continued anyway)'),
      findsOneWidget,
    );
    _expectTexts(tester, [
      '₹30,000 − ₹21,000 fixed = ₹9,000 over 15 days → ₹600/day',
    ]);
    expect(findCopy('Short this month'), findsNothing);
  });

  testWidgets('TC-014-35 eleven periods are all listed', (tester) async {
    await pumpStatement(
      tester,
      _fx(
        today: d(2026, 12, 4),
        periods: [
          _first(),
          for (var i = 1; i <= 10; i++)
            period(
              d(2026, 11, 5 + i),
              e2Values(salary: 4000000 + i * 10000),
              changedAt: at(d(2026, 11, 5 + i), 9),
            ),
        ],
      ),
      size: const Size(360, 12000),
    );

    expect(findCopy('Period 1 of 11'), findsOneWidget);
    expect(findCopy('Period 11 of 11'), findsOneWidget);
    expect(find.textContaining('show more'), findsNothing);
  });

  testWidgets('TC-014-38 a shortfall under one rupee reads less than one '
      'rupee', (tester) async {
    await pumpStatement(
      tester,
      _fx(
        today: d(2026, 11, 8),
        periods: [
          period(
            d(2026, 11, 5),
            const FullMonthValues(
              salary: Paise(1500000),
              fixedCosts: [FixedCost(name: 'Rent', amount: Paise(1500050))],
            ),
            continued: true,
          ),
        ],
      ),
      size: _tall,
    );

    expect(
      findCopy('less than ₹1 short · ₹0/day (continued anyway)'),
      findsOneWidget,
    );
    _expectTexts(tester, ['◆ less than ₹1 short']);
    _expectNoText(tester, '₹0 short');
  });

  testWidgets('TC-014-41 a first day without spends shows neutral zeros', (
    tester,
  ) async {
    await pumpStatement(tester, e2Day1, size: _tall);

    expect(findCopy('● ₹0'), findsNothing);
    expect(findCopy('◆ ₹0'), findsNothing);
    _expectTexts(tester, ['₹24,900', '₹0']);
    expect(findCopy('No changes this month.'), findsOneWidget);
  });

  testWidgets('TC-014-44 short this month row appears only in a shortfall', (
    tester,
  ) async {
    await pumpStatement(tester, fixtureA, size: _tall);
    expect(findCopy('Short this month'), findsNothing);
    expect(findCopy('Left'), findsOneWidget);

    await pumpStatement(tester, c4, size: _tall);
    expect(findCopy('Short this month'), findsOneWidget);
  });

  testWidgets('TC-014-46 period overline and heading', (tester) async {
    await pumpStatement(tester, fixtureM20, size: _tall);

    expect(findCopy('Period 1 of 2'), findsOneWidget);
    expect(
      _texts(tester).where((t) => t.contains('in progress')),
      hasLength(1),
    );
    await pumpStatement(tester, fixtureMFull, size: _tall);
    expect(_texts(tester).where((t) => t.contains('in progress')), isEmpty);
  });

  testWidgets('TC-014-56 a target month starts the working line with the '
      'target', (tester) async {
    await pumpStatement(
      tester,
      _fx(
        today: d(2026, 11, 9),
        periods: [
          period(
            d(2026, 11, 5),
            e2Values(target: 2000000),
            changedAt: at(d(2026, 11, 4), 0),
          ),
        ],
      ),
      size: _tall,
    );

    expect(findCopy('Spending target'), findsOneWidget);
    _expectTexts(tester, [
      '₹20,000 − ₹15,100 fixed = ₹4,900 over 30 days → ₹163/day',
    ]);
    await tester.tap(find.bySemanticsLabel('More about daily budget'));
    await tester.pumpAndSettle();
    expect(
      findCopy(
        "₹4,900 doesn't divide evenly by 30 days, so the first 10 days get 1 "
        "paisa more. That's why you see ₹163 every day.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('TC-014-57 a reverted same day change reads as changed and '
      'changed back', (tester) async {
    final day20 = d(2026, 11, 20);
    await pumpStatement(
      tester,
      _fx(
        today: d(2026, 11, 25),
        periods: [
          _first(),
          period(day20, e2Values(rent: 1300000), changedAt: at(day20, 10)),
          period(day20, e2Values(), changedAt: at(day20, 18)),
        ],
      ),
      size: _tall,
    );

    expect(findCopy('Changed and changed back'), findsOneWidget);
    _expectTexts(tester, [
      'Rent ₹10,000 → ₹13,000 (replaced the same day)',
      'Rent ₹13,000 → ₹10,000 → ₹830/day for the 15 days left',
    ]);
  });

  testWidgets('TC-014-28 statement semantics read as full sentences', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpStatement(tester, fixtureM20, size: _tall);

    for (final label in [
      'Period 2 of 2, 13 November to 30 November, 18 days, in progress',
      '35,000 rupees minus 15,100 rupees fixed equals 19,900 rupees, minus '
          '9,960 rupees already budgeted equals 9,940 rupees, over 18 days, '
          '552 rupees a day',
      '40,000 rupees minus 15,100 rupees fixed equals 24,900 rupees, over 30 '
          'days, 830 rupees a day',
      '1 November, month started: salary ₹40,000, fixed costs ₹15,100, ₹830 '
          'a day',
      '13 November, salary ₹40,000 to ₹35,000, ₹552 a day for the 18 days '
          'left',
      'Saved, ₹2,115',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    expect(
      find.bySemanticsLabel(RegExp('^Fixed costs, ₹15,100')),
      findsNWidgets(2),
    );
    final heading = tester.getSemantics(
      find.bySemanticsLabel(RegExp('^Period 1 of 2')),
    );
    expect(heading.flagsCollection.isHeader, isTrue);
    semantics.dispose();
  });

  testWidgets('TC-014-28 shortfall and same day lines are read as written', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpStatement(tester, fixtureS, size: _tall);
    expect(
      find.bySemanticsLabel('Short this month, minus ₹1,000'),
      findsOneWidget,
    );
    await pumpStatement(tester, e2s, size: _tall);
    for (final label in [
      '20 November, ${_clock(d(2026, 11, 20), 10)}, rent ₹10,000 to ₹13,000, '
          'replaced the same day',
      '20 November, ${_clock(d(2026, 11, 20), 18)}, rent ₹13,000 to ₹11,000, '
          '₹763 a day for the 15 '
          'days left',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    semantics.dispose();
  });

  /// The lines the working strip of the second period is drawn in.
  Future<List<String>> workingLines(
    WidgetTester tester, {
    required Size size,
    required double scale,
  }) async {
    await pumpStatement(tester, fixtureMFull, size: size, textScale: scale);
    final strip = find.byWidgetPredicate(
      (w) =>
          w is RichText &&
          plainCopy(w.text.toPlainText(includeSemanticsLabels: false))
              .contains('already budgeted ='),
    );
    final paragraph = tester.renderObject<RenderParagraph>(strip);
    final text = paragraph.text.toPlainText(includeSemanticsLabels: false);
    final painter = TextPainter(
      text: TextSpan(
        children: [
          for (final span in _textSpans(paragraph.text))
            TextSpan(text: span.text, style: span.style),
        ],
        style: paragraph.text.style,
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.linear(scale),
    )..layout(maxWidth: paragraph.size.width);
    final lines = <String>[];
    for (var at = 0; at < text.length;) {
      final line = painter.getLineBoundary(TextPosition(offset: at));
      if (line.end <= at) break;
      lines.add(plainCopy(text.substring(line.start, line.end)).trim());
      at = line.end;
    }
    return lines;
  }

  testWidgets('TC-014-27 working line breaks only at the allowed points', (
    tester,
  ) async {
    // Wide enough for every chunk: the line wraps between chunks only.
    final lines = await workingLines(
      tester,
      size: const Size(640, 4000),
      scale: 1.3,
    );

    expect(lines.length, greaterThan(1));
    for (final line in lines.skip(1)) {
      expect(
        line.startsWith('=') ||
            line.startsWith('minus') ||
            line.startsWith('→'),
        isTrue,
        reason: 'a line starts with "$line"',
      );
    }
  });

  testWidgets('TC-014-27 working line never splits an amount at 2.0x', (
    tester,
  ) async {
    // Too narrow for the chunks: the line wraps at spaces, never inside an
    // amount.
    final lines = await workingLines(
      tester,
      size: const Size(320, 4000),
      scale: 2,
    );

    expect(lines.length, greaterThan(3));
    final whole = lines.join(' ');
    for (final amount in RegExp('₹[0-9,]+').allMatches(whole)) {
      expect(
        lines.any((line) => line.contains(amount[0]!)),
        isTrue,
        reason: '${amount[0]} is on one line',
      );
    }
  });

  testWidgets('TC-014-37 ten crore salary wraps without splitting', (
    tester,
  ) async {
    await pumpStatement(
      tester,
      _fx(
        today: d(2026, 11, 9),
        periods: [
          period(
            d(2026, 11, 5),
            const FullMonthValues(
              salary: Paise(10000000000),
              fixedCosts: [FixedCost(name: 'Rent', amount: Paise(1000000))],
            ),
            changedAt: at(d(2026, 11, 4), 0),
          ),
        ],
      ),
      size: const Size(360, 8000),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(_texts(tester).any((t) => t.contains('₹10,00,00,000')), isTrue);
    for (final text in _texts(tester)) {
      expect(text, isNot(contains('₹1\n')));
    }
  });

  testWidgets('TC-014-45 statement loading and error states', (tester) async {
    final store = storeFor(fixtureM20);
    final held = store.readDelay = Completer<void>();
    final semantics = tester.ensureSemantics();
    await pumpStatement(tester, fixtureM20, store: store, settle: false);
    await tester.pump();

    expect(findCopy('Month statement'), findsOneWidget);
    expect(find.bySemanticsLabel('Loading the statement'), findsOneWidget);
    expect(find.text('₹0'), findsNothing);
    held.complete();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Loading the statement'), findsNothing);

    final failing = storeFor(fixtureM20)..readFails = true;
    await pumpStatement(tester, fixtureM20, store: failing);
    expect(findCopy("Couldn't load your data"), findsOneWidget);
    expect(findCopy('Tap Try again. Nothing has been lost.'), findsOneWidget);
    failing.readFails = false;
    await tester.tap(findCopy('Try again'));
    await tester.pumpAndSettle();
    expect(findCopy("Couldn't load your data"), findsNothing);
    expect(findCopy('Month total'), findsNothing);
    expect(findCopy('So far'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-014-02 statement from a change day scrolls to that period', (
    tester,
  ) async {
    await pumpStatement(
      tester,
      fixtureM20,
      scrollToPeriodStart: d(2026, 11, 13),
    );

    final heading = find.bySemanticsLabel(RegExp('^Period 2 of 2'));
    expect(heading, findsOneWidget);
    final top = tester.getTopLeft(find.text('Period 2 of 2')).dy;
    expect(top, lessThan(200), reason: 'Period 2 is near the top');
    // Period 1 is above: scrolling up reaches it.
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, 3000),
    );
    await tester.pumpAndSettle();
    expect(findCopy('Period 1 of 2'), findsOneWidget);
  });
  Set<Color?> periodFills(WidgetTester tester) => {
    for (final card in tester.widgetList<Card>(
      find.descendant(of: find.byType(PeriodCard), matching: find.byType(Card)),
    ))
      card.color,
  };

  testWidgets('TC-014-02 arrival flash goes from accent soft to surface', (
    tester,
  ) async {
    await pumpStatement(
      tester,
      fixtureM20,
      scrollToPeriodStart: d(2026, 11, 13),
      settle: false,
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    expect(periodFills(tester), hasLength(2), reason: 'one card is flashing');
    await tester.pumpAndSettle();
    expect(periodFills(tester), hasLength(1), reason: 'flash is over');
  });

  testWidgets('TC-014-60 a change day of a past month scrolls to its period', (
    tester,
  ) async {
    final oct = FixtureMonth(
      month: oct2026,
      firstBudgetedDay: d(2026, 10, 5),
      periods: [
        period(d(2026, 10, 5), e2Values(), changedAt: at(d(2026, 10, 4), 0)),
        period(
          d(2026, 10, 20),
          e2Values(salary: 3500000),
          changedAt: at(d(2026, 10, 20), 10),
        ),
      ],
    );
    final fixture = Phase3Fixture(
      name: 'OCT change on 20 Oct',
      today: d(2026, 11, 13),
      months: [oct, fixtureA.current],
    );
    await openDay(tester, fixture, d(2026, 10, 20), monthIndex: 0);

    // A past month is read only, yet its change line is there and opens the
    // statement of October (not November).
    final notice = find.textContaining('Budget changed on this day');
    expect(notice, findsOneWidget);
    await tester.tap(notice);
    await tester.pumpAndSettle();

    expect(findCopy('Month statement'), findsOneWidget);
    expect(findCopy('5 Oct – 4 Nov 2026'), findsOneWidget);
    expect(find.bySemanticsLabel('Ended, 5 Oct – 4 Nov 2026'), findsOneWidget);
    expect(_texts(tester).where((t) => t.contains('so far')), isEmpty);
    expect(_texts(tester).where((t) => t.contains('in progress')), isEmpty);
    _expectTexts(tester, ['20 Oct – 4 Nov · 16 days']);
    final top = tester.getTopLeft(find.text('Period 2 of 2')).dy;
    expect(top, lessThan(200), reason: 'Period 2 is near the top');
    // Period 1 is above: scrolling up reaches it.
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, 3000),
    );
    await tester.pumpAndSettle();
    expect(findCopy('Period 1 of 2'), findsOneWidget);
    _expectTexts(tester, ['5 Oct – 19 Oct · 15 days']);
  });

  testWidgets('TC-014-51 arrival flash obeys remove animations', (
    tester,
  ) async {
    await pumpStatement(
      tester,
      fixtureM20,
      scrollToPeriodStart: d(2026, 11, 13),
      disableAnimations: true,
      settle: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(periodFills(tester), hasLength(1));
    await tester.pumpAndSettle();
    final top = tester.getTopLeft(find.text('Period 2 of 2')).dy;
    expect(top, lessThan(200), reason: 'still at the right place');
  });
}

/// The time a stored change shows: the stored UTC instant on this phone.
String _clock(CalendarDate day, int hour) => formatClockTime(at(day, hour));

/// The text spans of [root] (the placeholder of the (i) is left out).
List<TextSpan> _textSpans(InlineSpan root) {
  final spans = <TextSpan>[];
  root.visitChildren((span) {
    if (span is TextSpan && span.text != null) spans.add(span);
    return true;
  });
  return spans;
}
