import 'package:daily_budget/core/help/first_time_hint.dart';
import 'package:daily_budget/features/month_setup/month_setup_controller.dart';
import 'package:daily_budget/features/transactions/today_line_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/bundled_fonts.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/setup_harness.dart' as setup;
import '../../helpers/shell.dart';
import '../../helpers/theme_cases.dart';
import '../../helpers/transactions_harness.dart';
import '../../support/find_copy.dart';

void main() {
  testWidgets('TC-009-01 transactions without a month asks to set up first', (
    tester,
  ) async {
    final modes = <SetupMode>[];
    await pumpTransactions(
      tester,
      money: FakeMoneyStore(),
      onSetUpMonth: modes.add,
    );
    expect(find.text('Set up your month first'), findsOneWidget);
    expect(
      find.text('Your spends need a budget month. It takes a minute.'),
      findsOneWidget,
    );
    expect(find.text('No transactions yet'), findsNothing);
    expect(find.byTooltip('Add a spend by hand'), findsNothing);
    expect(addSpendButton, findsNothing);
    await tester.tap(find.text('Set up your month'));
    await tester.pump();
    expect(modes, hasLength(1));
    expect(modes.single, isA<FirstSetupMode>());
  });

  testWidgets('TC-009-01 set up your month opens the real setup screen and '
      'both tabs update after confirming', (tester) async {
    final store = FakeMoneyStore();
    await pumpTransactions(
      tester,
      money: store,
      clock: TestClock(DateTime(2026, 11, 5, 10)),
    );
    await tester.tap(find.text('Set up your month'));
    await tester.pumpAndSettle();
    expect(find.text('Start my month'), findsOneWidget);

    await setup.pickSalaryDay(tester, 5);
    await setup.enterE2(tester);
    await setup.tapText(tester, 'Start my month');

    expect(store.months, hasLength(1));
    expect(find.text('Start my month'), findsNothing);
    expect(todayLineText(tester), 'budget ₹830 · spent ₹0 · ₹830 left today');
    expect(find.text('Set up your month first'), findsNothing);
    await tapTab(tester, 'Home');
    expect(findCopy('₹830/day · 5 Nov – 4 Dec'), findsOneWidget);
    expect(find.text('Set up your month'), findsNothing);
  });

  testWidgets('TC-008-49 double tap on set up your month in the Transactions '
      'tab opens one screen', (tester) async {
    await pumpTransactions(
      tester,
      money: FakeMoneyStore(),
      clock: TestClock(DateTime(2026, 11, 5, 10)),
    );
    final button = find.text('Set up your month');
    await tester.tap(button);
    await tester.tap(button, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Start my month'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Start my month'), findsNothing);
    expect(find.text('Set up your month first'), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byType(Scaffold).first)).canPop(),
      isFalse,
    );

    // The guard is released: a later tap opens the screen again.
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Start my month'), findsOneWidget);
  });

  testWidgets('TC-009-02 month without spends shows today line and empty '
      'state', (tester) async {
    await pumpTransactions(tester, money: e2Store());
    expect(todayLineText(tester), 'budget ₹830 · spent ₹0 · ₹830 left today');
    expect(find.text('No spends yet this month'), findsOneWidget);
    expect(
      find.text(
        "Add what you spend and we'll keep your daily budget up to "
        'date.',
      ),
      findsOneWidget,
    );
    // The floating button is the only Add spend control.
    expect(find.text('Add spend'), findsOneWidget);
    expect(find.byTooltip('Add a spend by hand'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('TC-009-13 list is grouped by day newest first', (tester) async {
    final store = e2Store();
    addSpendTo(store, d(2026, 11, 5), 10000, note: 'Tea');
    addSpendTo(store, d(2026, 11, 8), 31000, note: 'Petrol');
    addSpendTo(
      store,
      d(2026, 11, 9),
      25000,
      note: 'Lunch',
      createdAt: at(d(2026, 11, 9), 10),
    );
    addSpendTo(
      store,
      d(2026, 11, 9),
      40000,
      note: 'Groceries',
      createdAt: at(d(2026, 11, 9), 13),
    );
    // Tall enough for every day: the search and chips push the list down.
    await pumpTransactions(tester, money: store, size: const Size(360, 1600));

    Finder heading(String text) => findCopy(text);
    final today = tester.getTopLeft(heading('Today').first).dy;
    final yesterday = tester.getTopLeft(heading('Yesterday')).dy;
    final thu = tester.getTopLeft(heading('Thu, 5 Nov')).dy;
    expect(today, lessThan(yesterday));
    expect(yesterday, lessThan(thu));
    expect(findCopy('₹650'), findsOneWidget);
    expect(findCopy('₹310'), findsNWidgets(2));
    expect(findCopy('₹100'), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.text('Groceries')).dy,
      lessThan(tester.getTopLeft(find.text('Lunch')).dy),
    );
    expect(todayLineText(tester), 'budget ₹830 · spent ₹650 · ₹180 left today');
  });

  testWidgets('TC-009-17 adding is blocked until the new month is set up', (
    tester,
  ) async {
    final store = e2Store();
    addSpendTo(store, d(2026, 11, 20), 52000, note: 'Groceries');
    final modes = <SetupMode>[];
    await pumpTransactions(
      tester,
      money: store,
      clock: TestClock(DateTime(2026, 12, 5, 10)),
      onSetUpMonth: modes.add,
    );
    expect(find.text('Set up your new month first'), findsOneWidget);
    expect(find.text('Last month · 5 Nov – 4 Dec'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    // Last month's rows are read-only.
    expect(find.text('Today'), findsNothing);

    await tester.tap(addSpendButton);
    await tester.pumpAndSettle();
    expect(find.text('Set up your new month first'), findsNWidgets(2));
    expect(find.text('Not now'), findsOneWidget);
    expect(find.text('Amount'), findsNothing);
    await tester.tap(find.text('Set up this month').last);
    await tester.pumpAndSettle();
    expect(modes, hasLength(1));
    expect(modes.single, isA<NewMonthMode>());
    expect(storedSpends(store), hasLength(1));
  });

  testWidgets('TC-009-17 both set up buttons open new month setup with last '
      "month's numbers", (tester) async {
    final store = e2Store();
    await pumpTransactions(
      tester,
      money: store,
      clock: TestClock(DateTime(2026, 12, 5, 10)),
    );
    await tester.tap(find.text('Set up this month'));
    await tester.pumpAndSettle();
    expect(find.text('Start my month'), findsOneWidget);
    expect(setup.typed(tester, setup.amountInput('Monthly salary')), '40000');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(addSpendButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set up this month').last);
    await tester.pumpAndSettle();
    expect(find.text('Start my month'), findsOneWidget);
    expect(setup.typed(tester, setup.amountInput('Monthly salary')), '40000');

    await setup.tapText(tester, 'Start my month');
    expect(store.months, hasLength(2));
    expect(find.text('Set up your new month first'), findsNothing);
    expect(find.text('Today'), findsWidgets);
  });

  testWidgets('TC-009-29 the tab moves to the new day after midnight', (
    tester,
  ) async {
    final store = e2Store();
    addSpendTo(store, d(2026, 11, 9), 25000, note: 'Lunch');
    final clock = TestClock(DateTime(2026, 11, 9, 23, 59));
    await pumpTransactions(tester, money: store, clock: clock);
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Yesterday'), findsNothing);

    clock.now = DateTime(2026, 11, 10, 0, 1);
    await tester.pump(const Duration(minutes: 2));
    await tester.pumpAndSettle();
    expect(find.text('Yesterday'), findsOneWidget);
    expect(todayLineText(tester), 'budget ₹830 · spent ₹0 · ₹830 left today');
    await tester.tap(addSpendButton);
    await tester.pumpAndSettle();
    expect(find.textContaining('Today · Tue, 10 Nov'), findsOneWidget);
  });

  testWidgets('TC-009-30 a future dated spend after a clock change stays on '
      'its day', (tester) async {
    final store = e2Store();
    addSpendTo(store, d(2026, 11, 12), 20000, note: 'Dinner');
    final clock = TestClock(DateTime(2026, 11, 10, 10));
    await pumpTransactions(tester, money: store, clock: clock);
    expect(find.text('Thu, 12 Nov'), findsOneWidget);
    expect(todayLineText(tester), 'budget ₹830 · spent ₹0 · ₹830 left today');

    await tapRow(tester, 'Dinner');
    expect(find.text('Edit spend'), findsOneWidget);
    expect(find.textContaining('Thu, 12 Nov'), findsWidgets);
    await tester.ensureVisible(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    final picker = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    expect(picker.lastDate, DateTime(2026, 11, 12));
    expect(picker.firstDate, DateTime(2026, 11, 5));
  });

  testWidgets('TC-009-32 fifty five spends on one day add up exactly', (
    tester,
  ) async {
    final store = e2Store();
    for (var i = 0; i < 55; i++) {
      addSpendTo(
        store,
        d(2026, 11, 9),
        101,
        note: 'Item $i',
        createdAt: at(d(2026, 11, 9), 8, i),
      );
    }
    await pumpTransactions(tester, money: store);
    expect(todayLineText(tester), 'budget ₹830 · spent ₹55 · ₹774 left today');
    expect(findCopy('₹55'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Item 0'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Item 0'), findsOneWidget);
  });

  testWidgets('TC-009-41 transactions read failure shows the load error', (
    tester,
  ) async {
    final store = e2Store()..readFails = true;
    await pumpTransactions(tester, money: store);
    expect(find.text("Couldn't load your data"), findsOneWidget);
    expect(find.text('Tap Try again. Nothing has been lost.'), findsOneWidget);
    expect(addSpendButton, findsNothing);
    store.readFails = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load your data"), findsNothing);
    expect(find.text('No spends yet this month'), findsOneWidget);
  });

  testWidgets('TC-009-42 double tap on add spend opens one screen', (
    tester,
  ) async {
    await pumpTransactions(tester, money: e2Store());
    await tester.tap(addSpendButton);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(addSpendButton, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Add spend'), findsNWidgets(1));
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Amount'), findsNothing);
  });

  testWidgets('TC-009-44 transactions hint still works with the new tab '
      'content', (tester) async {
    await pumpTransactions(tester, money: FakeMoneyStore(), hintsSeen: false);
    const hint = 'Tap a spend to fix it, or tap its category to change it.';
    expect(find.text(hint), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text(hint), findsNothing);
    expect(find.text('Set up your month first'), findsOneWidget);
  });

  testWidgets('TC-009-21 transaction controls have help and readable '
      'semantics', (tester) async {
    final store = e2Store();
    addSpendTo(store, d(2026, 11, 9), 25000, note: 'Lunch');
    addSpendTo(store, d(2026, 11, 9), 30000);
    final semantics = tester.ensureSemantics();
    await pumpTransactions(tester, money: store);

    expect(
      find.bySemanticsLabel('Today: budget ₹830, spent ₹550, ₹280 left today.'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('More about Today'), findsOneWidget);
    expect(
      find.bySemanticsLabel('₹250, Lunch, Other, Monday 9 November'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('₹300, No note, Other, Monday 9 November'),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(
        find.bySemanticsLabel('₹250, Lunch, Other, Monday 9 November'),
      ),
      matchesSemantics(
        label: '₹250, Lunch, Other, Monday 9 November',
        hint: 'Edit',
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    expect(find.bySemanticsLabel('Today, total ₹550'), findsOneWidget);
    expect(find.byTooltip('Add a spend by hand'), findsOneWidget);

    // The (i) opens the Today explanation.
    await tester.tap(find.bySemanticsLabel('More about Today'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "Today's budget minus what you've spent today. Whatever is left at "
        'midnight goes to your savings pot.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  for (final theme in [ThemeCase.light, ThemeCase.dim]) {
    testWidgets(
      'TC-009-46 at 2.0x text the tip is below the Today card and Add spend '
      'does not cover it (${theme.name})',
      (tester) async {
        // Real glyph widths: the square test font wraps the card far more.
        await loadBundledFonts();
        await pumpTransactions(
          tester,
          money: e2Store(),
          theme: theme,
          textScale: 2,
          hintsSeen: false,
        );
        final card = tester.getRect(find.byType(TodayLineView));
        final tip = tester.getRect(find.byType(FirstTimeHintCard));
        final button = tester.getRect(addSpendButton);
        expect(tip.top, greaterThanOrEqualTo(card.bottom));
        expect(button.overlaps(card), isFalse);
      },
    );
  }

  for (final scale in [1.0, 1.3]) {
    testWidgets(
      'TC-009-46 at $scale times text the tip stays above the Today card',
      (tester) async {
        await loadBundledFonts();
        await pumpTransactions(
          tester,
          money: e2Store(),
          textScale: scale,
          hintsSeen: false,
        );
        final card = tester.getRect(find.byType(TodayLineView));
        final tip = tester.getRect(find.byType(FirstTimeHintCard));
        expect(tip.bottom, lessThanOrEqualTo(card.top));
      },
    );
  }
}
