import 'package:daily_budget/core/theme/budget_colors.dart';
import 'package:daily_budget/features/transactions/today_line_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/accessibility.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/theme_cases.dart';
import '../../helpers/transactions_harness.dart';
import '../../support/find_copy.dart';

/// The result part of the Today line and its colour.
(String, Color) _result(WidgetTester tester) {
  final texts = find.descendant(
    of: find.byKey(TodayLineView.lineKey),
    matching: find.byType(Text),
  );
  final result = tester.widget<Text>(texts.last);
  final span = result.textSpan! as TextSpan;
  return (plainCopy(span.toPlainText()), span.style!.color!);
}

FakeMoneyStore _spent(int paise) {
  final store = e2Store();
  if (paise > 0) addSpendTo(store, d(2026, 11, 9), paise, note: 'Test');
  return store;
}

void main() {
  testWidgets('TC-009-39 today line wording for left on budget and overspent', (
    tester,
  ) async {
    const colors = BudgetColors.light;
    for (final (paise, line, color) in [
      (0, 'budget ₹830 · spent ₹0 · ₹830 left today', colors.saved),
      (83000, 'budget ₹830 · spent ₹830 · on budget', colors.neutral),
      (83100, 'budget ₹830 · spent ₹831 · overspent ₹1', colors.overspent),
    ]) {
      await pumpTransactions(tester, money: _spent(paise));
      expect(todayLineText(tester), line);
      expect(_result(tester).$2, color, reason: line);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('TC-009-40 today line uses exact paise for the result word', (
    tester,
  ) async {
    await pumpTransactions(tester, money: _spent(82999));
    expect(
      todayLineText(tester),
      'budget ₹830 · spent ₹829 · less than ₹1 left today',
    );
    expect(_result(tester).$2, BudgetColors.light.saved);
    await tester.pumpWidget(const SizedBox());

    await pumpTransactions(tester, money: _spent(83001));
    expect(
      todayLineText(tester),
      'budget ₹830 · spent ₹830 · overspent less than ₹1',
    );
    expect(_result(tester).$2, BudgetColors.light.overspent);
  });

  testWidgets('TC-009-23 today line uses the latest period and shows a '
      'shortfall', (tester) async {
    final raised = e2Store(
      periods: [
        period(d(2026, 11, 5), e2Values()),
        period(d(2026, 11, 20), e2Values(rent: 1300000)),
      ],
    );
    addSpendTo(raised, d(2026, 11, 19), 25000);
    addSpendTo(raised, d(2026, 11, 20), 25000, note: 'Test');
    await pumpTransactions(
      tester,
      money: raised,
      clock: TestClock(DateTime(2026, 11, 20, 10)),
    );
    expect(todayLineText(tester), 'budget ₹630 · spent ₹250 · ₹380 left today');
    await tester.pumpWidget(const SizedBox());

    final shortfall = e2Store(
      periods: [period(d(2026, 11, 5), s1Values(), continued: true)],
    );
    addSpendTo(shortfall, d(2026, 11, 6), 20000, note: 'Test');
    await pumpTransactions(
      tester,
      money: shortfall,
      clock: TestClock(DateTime(2026, 11, 6, 10)),
    );
    expect(todayLineText(tester), 'budget ₹0 · spent ₹200 · overspent ₹200');
    expect(findCopy('−₹1,000 this month'), findsOneWidget);
  });

  testWidgets('TC-009-24 todays leftover joins the pot only after midnight', (
    tester,
  ) async {
    final store = e2Store();
    for (var day = 5; day <= 8; day++) {
      addSpendTo(store, d(2026, 11, day), 83000);
    }
    addSpendTo(store, d(2026, 11, 9), 25000, note: 'Test');
    final clock = TestClock(DateTime(2026, 11, 9, 23, 59));
    await pumpTransactions(tester, money: store, clock: clock);
    expect(todayLineText(tester), 'budget ₹830 · spent ₹250 · ₹580 left today');
    clock.now = DateTime(2026, 11, 10, 0, 1);
    await tester.pump(const Duration(minutes: 2));
    await tester.pumpAndSettle();
    expect(todayLineText(tester), 'budget ₹830 · spent ₹0 · ₹830 left today');
  });

  testWidgets('TC-009-33 ten crore spend shows a large overspend without '
      'breaking layout', (tester) async {
    for (final scale in [1.0, 2.0]) {
      await pumpTransactions(
        tester,
        money: _spent(10000000000),
        textScale: scale,
      );
      expect(
        todayLineText(tester),
        'budget ₹830 · spent ₹10,00,00,000 · overspent ₹9,99,99,170',
      );
      expectNoOverflow(tester, reason: 'scale $scale');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('TC-009-21 the Today card and its result stay readable in '
      'every theme', (tester) async {
    for (final theme in ThemeCase.values) {
      await pumpTransactions(tester, money: _spent(25000), theme: theme);
      final (_, color) = _result(tester);
      expect(color, theme.colors.saved, reason: theme.name);
      await expectAccessible(tester, reason: theme.name);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
