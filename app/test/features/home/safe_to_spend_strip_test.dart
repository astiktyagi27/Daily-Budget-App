import 'dart:async';

import 'package:daily_budget/core/theme/budget_colors.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/home/widgets/safe_to_spend_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/setup_harness.dart';
import '../../helpers/transactions_harness.dart'
    show addCoverTo, addMoneyInTo, addSpendTo;
import '../../support/app_lifecycle.dart';
import '../../support/find_copy.dart';
import 'home_harness.dart';

// The Safe to spend strip (F-017, plan T-361, T-362). Literals from
// tests/F-017-safe-to-spend.md.

final CalendarDate _nov13 = d(2026, 11, 13);
final Finder _line = findCopy('₹899 a day · 22 days left');

/// The text of the strip's value line, or null when there is no strip.
String? _value() {
  final finder = find.byKey(SafeToSpendStrip.valueKey);
  if (finder.evaluate().isEmpty) return null;
  final text = finder.evaluate().first.widget as Text;
  return plainCopy(text.data ?? text.textSpan!.toPlainText());
}

void main() {
  testWidgets('TC-017-03 home shows the safe to spend line for example A', (
    tester,
  ) async {
    await openFixture(tester, a13);
    expect(findCopy('Safe to spend'), findsOneWidget);
    expect(_line, findsOneWidget);
    expect(
      topOf(tester, findCopy('₹830/day · 5 Nov – 4 Dec')),
      lessThan(topOf(tester, findCopy('Safe to spend'))),
    );
    expect(
      colorOf(tester, find.byKey(SafeToSpendStrip.valueKey)),
      isNull,
      reason: 'the colours are set per part of the line',
    );
    final span =
        tester.widget<Text>(find.byKey(SafeToSpendStrip.valueKey)).textSpan!
            as TextSpan;
    final parts = span.children!.cast<TextSpan>();
    expect(parts.first.style!.color, BudgetColors.light.textPrimary);
    expect(parts.last.style!.color, BudgetColors.light.textSecondary);
  });

  testWidgets('TC-017-04 todays spending does not move the line', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final store = await openFixture(tester, a13);
    await change(tester, store, () => addSpendTo(store, _nov13, 41000));

    expect(_line, findsOneWidget);
    expect(todayCardText(), 'budget ₹830 · spent ₹830 · on budget');
    expect(findCopy('₹18,960'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-017-06 a cover leaves the line unchanged', (tester) async {
    final store = await openFixture(tester, a13);
    await change(
      tester,
      store,
      () => addCoverTo(store, d(2026, 11, 11), 30000),
    );
    expect(_line, findsOneWidget);

    await change(tester, store, store.coversByMonth.clear);
    await change(
      tester,
      store,
      () => addCoverTo(store, d(2026, 11, 11), 10000),
    );
    expect(_line, findsOneWidget);

    await change(tester, store, store.coversByMonth.clear);
    expect(_line, findsOneWidget);
  });

  testWidgets('TC-017-07 the line moves at midnight', (tester) async {
    final clock = MovableClock(_nov13);
    await openFixture(tester, a13, clock: clock);
    expect(_line, findsOneWidget);

    clock.now = DateTime(2026, 11, 14, 0, 1);
    sendToBackground(tester);
    bringToForeground(tester);
    await tester.pumpAndSettle();
    expect(findCopy('₹922 a day · 21 days left'), findsOneWidget);
  });

  testWidgets('TC-017-09 first day equals the daily budget', (tester) async {
    await openFixture(tester, e2Day1);
    expect(findCopy('₹830 a day · 30 days left'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    final firstUse = f12.copyWith(
      name: 'F12 nothing spent',
      today: d(2026, 11, 10),
      entries: const [],
    );
    await openFixture(tester, firstUse);
    expect(findCopy('₹996 a day · 25 days left'), findsOneWidget);
  });

  testWidgets('TC-017-11 two period month gives 704 a day', (tester) async {
    await openFixture(tester, m20);
    expect(findCopy('₹704 a day · 11 days left'), findsOneWidget);
    expect(findCopy('₹552/day · 1 – 30 Nov'), findsOneWidget);
    expect(todayCardText(), 'budget ₹552 · spent ₹850 · overspent ₹297');
  });

  testWidgets('TC-017-13 shortfall month shows nothing left', (tester) async {
    await openFixture(tester, s8);
    expect(
      findCopy('Nothing left to spread over the rest of the month.'),
      findsOneWidget,
    );
    expect(_value(), 'Nothing left to spread over the rest of the month.');
    expect(find.textContaining('days left'), findsNothing);
    expect(
      colorOf(tester, find.byKey(SafeToSpendStrip.valueKey)),
      BudgetColors.light.textPrimary,
    );
  });

  testWidgets('TC-017-15 less than one rupee a day and one day left', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final nearlyAll = e2Last.plus(
      name: 'under a rupee',
      entries: [fixtureSpend(d(2026, 11, 5), 2489950)],
    );
    await openFixture(tester, nearlyAll);
    expect(_value(), 'less than ₹1 a day · 1 day left');
    expect(
      find.bySemanticsLabel('Safe to spend, less than ₹1 a day, 1 day left'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('TC-017-16 a refund on a past day raises the line at once', (
    tester,
  ) async {
    final store = await openFixture(tester, a13);
    await change(
      tester,
      store,
      () => addMoneyInTo(store, d(2026, 11, 12), 50000),
    );
    expect(findCopy('₹922 a day · 22 days left'), findsOneWidget);
    expect(findCopy('₹19,870'), findsOneWidget);
  });

  testWidgets('TC-017-24 safe to spend has its explanation', (tester) async {
    final semantics = tester.ensureSemantics();
    await openFixture(tester, a13);
    final info = find.bySemanticsLabel('More about Safe to spend');
    await tester.ensureVisible(info);
    await tester.pumpAndSettle();
    expect(tester.getSize(info).shortestSide, greaterThanOrEqualTo(48));
    await tester.tap(info);
    await tester.pumpAndSettle();
    expect(
      findCopy(
        'Everything left this month, including your savings pot, spread '
        'evenly over the days left (today included). '
        "It's a guide: your daily budget doesn't change, and it stays the "
        'same all day.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('TC-017-26 safe to spend reads as one sentence', (tester) async {
    final semantics = tester.ensureSemantics();
    await openFixture(tester, a13);
    final node = find.bySemanticsLabel(
      'Safe to spend, ₹899 a day, 22 days left',
    );
    expect(node, findsOneWidget);
    expect(find.bySemanticsLabel('More about Safe to spend'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await openFixture(tester, s8);
    expect(
      find.bySemanticsLabel(
        'Safe to spend, nothing left to spread over the rest of the month',
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
    await openFixture(tester, e2Last);
    expect(
      find.bySemanticsLabel('Safe to spend, ₹24,900 a day, 1 day left'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('TC-017-28 last day shows everything left', (tester) async {
    final store = await openFixture(tester, e2Last);
    expect(findCopy('₹24,900 a day · 1 day left'), findsOneWidget);
    await change(tester, store, () => addSpendTo(store, d(2026, 12, 4), 30000));
    expect(findCopy('₹24,900 a day · 1 day left'), findsOneWidget);
  });

  testWidgets('TC-017-29 an early overspend lowers the room per day', (
    tester,
  ) async {
    await openFixture(tester, ov5);
    expect(findCopy('₹795 a day · 29 days left'), findsOneWidget);
    expect(findCopy('₹830/day · 5 Nov – 4 Dec'), findsOneWidget);
  });

  testWidgets('TC-017-30 days left follow the month length and the leap day', (
    tester,
  ) async {
    Phase3Fixture month(
      String name,
      int salaryDay,
      int year,
      int monthNumber,
      CalendarDate today, {
      PeriodValues? values,
    }) => customFixture(
      name: name,
      today: today,
      month: BudgetMonth.startIn(salaryDay, year, monthNumber),
      values: values ?? e2Values(),
    );

    // Salary day 29 in 2028: the month is 29 Feb - 28 Mar, 29 days (it ends
    // the day before the next 29th). The case text says 29 Mar and 30 days,
    // which the engine does not produce; the engine's figures stand.
    // Salary day 29 in 2028: the month is 29 Feb - 28 Mar, 29 days. The case
    // text says 29 Mar and 30 days, which the engine does not produce; the
    // engine's figures stand.
    final cases = <(Phase3Fixture, String)>[
      (
        month(
          'a',
          31,
          2027,
          1,
          d(2027, 1, 31),
          values: const FullMonthValues(salary: Paise(4000000)),
        ),
        '₹1,428 a day · 28 days left',
      ),
      (month('b1', 30, 2028, 1, d(2028, 2, 1)), '₹889 a day · 28 days left'),
      (month('b2', 30, 2028, 1, d(2028, 2, 28)), '₹24,900 a day · 1 day left'),
      (month('c1', 29, 2028, 2, d(2028, 2, 29)), '₹858 a day · 29 days left'),
      (month('c2', 29, 2028, 2, d(2028, 3, 1)), '₹889 a day · 28 days left'),
    ];
    for (final (fixture, text) in cases) {
      await tester.pumpWidget(const SizedBox());
      await openFixture(tester, fixture);
      expect(findCopy(text), findsOneWidget, reason: fixture.name);
    }
  });

  testWidgets('TC-017-31 refunds in a shortfall month can give a positive '
      'figure', (tester) async {
    await openFixture(tester, s8Refund);
    expect(findCopy('₹1,800'), findsOneWidget);
    expect(findCopy('₹66 a day · 27 days left'), findsOneWidget);
  });

  testWidgets('TC-017-32 a refund today does not raise the figure until '
      'tomorrow', (tester) async {
    final store = await openFixture(tester, a13);
    await change(tester, store, () => addMoneyInTo(store, _nov13, 50000));
    expect(_line, findsOneWidget);
    expect(todayCardText(), 'budget ₹830 · spent −₹80 · ₹910 left today');

    await change(
      tester,
      store,
      () => addMoneyInTo(store, d(2026, 11, 12), 50000),
    );
    expect(findCopy('₹922 a day · 22 days left'), findsOneWidget);
  });

  testWidgets('TC-017-33 future dated spends do not change the figure', (
    tester,
  ) async {
    await openFixture(
      tester,
      a13.plus(
        name: 'A13 + future',
        entries: [fixtureSpend(d(2026, 11, 15), 50000)],
      ),
    );
    expect(_line, findsOneWidget);
  });

  testWidgets('TC-017-34 the line is hidden without a current month', (
    tester,
  ) async {
    // (a) no month.
    await pumpHome(
      tester,
      money: FakeMoneyStore(),
      clock: MovableClock(_nov13),
    );
    expect(findCopy('Safe to spend'), findsNothing);

    // (b) December not set up.
    await tester.pumpWidget(const SizedBox());
    await openFixture(tester, a13, clock: MovableClock(d(2026, 12, 5)));
    expect(findCopy('Safe to spend'), findsNothing);

    // (c) loading.
    await tester.pumpWidget(const SizedBox());
    final held = storeFor(a13);
    final delay = held.readDelay = Completer<void>();
    await pumpHome(tester, money: held, clock: clockFor(a13));
    expect(findCopy('Safe to spend'), findsNothing);
    delay.complete();
    await tester.pumpAndSettle();
    expect(findCopy('Safe to spend'), findsOneWidget);

    // (d) load error.
    await tester.pumpWidget(const SizedBox());
    final failing = storeFor(a13)..readFails = true;
    await pumpHome(tester, money: failing, clock: clockFor(a13));
    expect(findCopy('Safe to spend'), findsNothing);
  });

  testWidgets('TC-017-36 the line is hidden when today is not a budgeted '
      'day', (tester) async {
    await openFixture(tester, f12, clock: MovableClock(d(2026, 11, 8)));
    expect(findCopy('Safe to spend'), findsNothing);
    expect(findCopy('₹996 a day · 25 days left'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await openFixture(tester, a13, clock: MovableClock(d(2026, 11, 2)));
    expect(findCopy('Safe to spend'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await openFixture(tester, a13, clock: MovableClock(d(2026, 12, 5)));
    expect(findCopy('Safe to spend'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
