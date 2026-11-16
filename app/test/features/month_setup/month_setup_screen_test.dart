import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/setup_harness.dart';
import '../../helpers/shell.dart';
import '../../support/app_lifecycle.dart';
import '../../support/find_copy.dart';

final Finder _start = find.text('Start my month');

const _salaryDayHelp =
    'The day your salary usually arrives. Your budget month runs from this '
    'day to the day before the next one.';
const _fixedCostsHelp =
    "Bills you pay every month, like rent or EMIs. They're taken out before "
    'your daily budget is worked out.';

/// [text] inside the scrolling form (the dock above Confirm is outside it).
Finder _inForm(String text) => find.descendant(
  of: find.byType(SingleChildScrollView),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is Text && plainCopy(widget.data ?? '') == plainCopy(text),
  ),
);

Future<void> _openFirstSetup(
  WidgetTester tester, {
  CalendarDate? today,
  FakeMoneyStore? money,
  MovableClock? clock,
  Size? size = kSmallPhone,
  double textScale = 1,
}) async {
  await pumpHome(
    tester,
    money: money ?? FakeMoneyStore(),
    clock: clock ?? MovableClock(today ?? d(2026, 11, 5)),
    size: size,
    textScale: textScale,
  );
  await tapText(tester, 'Set up your month');
}

/// A first setup on 5 Nov with salary day 5 chosen.
Future<FakeMoneyStore> _openOnStartDay(WidgetTester tester) async {
  final store = FakeMoneyStore();
  await _openFirstSetup(tester, money: store);
  await pickSalaryDay(tester, 5);
  return store;
}

Future<void> _tapStart(WidgetTester tester) =>
    tapText(tester, 'Start my month');

Future<void> _addItem(WidgetTester tester) => tapText(tester, '+ Add item');

bool _hasFocus(WidgetTester tester, Finder field) =>
    tester.widget<TextField>(field).focusNode!.hasFocus;

PeriodValues _savedValues(FakeMoneyStore store) =>
    store.months.single.periods.single.values;

void main() {
  testWidgets(
    'TC-008-04 first setup shows every field with its label and help',
    (tester) async {
      await _openFirstSetup(tester);
      for (final text in [
        'Set up your month',
        'Salary day',
        _salaryDayHelp,
        'Choose a day',
        'Monthly salary',
        'What you receive in your bank account each month, after tax.',
        'Spend less than my salary',
        'Set a smaller amount to budget and keep the rest aside.',
        'Fixed costs',
        _fixedCostsHelp,
        "Leave empty or 0 if there's nothing to pay this month.",
        '+ Add item',
        'Total fixed costs',
        '₹0',
        'Your daily budget',
        'Choose your salary day to see your budget month',
        'Enter your salary to see your daily budget',
        'Enter your salary',
        '—',
        'Start my month',
      ]) {
        expect(findCopy(text), findsOneWidget, reason: text);
      }
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(findCopy('Spending target'), findsNothing);
      expect(typed(tester, amountInput('Monthly salary')), isEmpty);
      expect(
        [for (var i = 0; i < 3; i++) typed(tester, itemNameFields.at(i))],
        ['Rent', 'EMI', 'Subscriptions'],
      );
      for (var i = 0; i < 3; i++) {
        expect(typed(tester, itemAmountFields.at(i)), isEmpty);
      }
    },
  );

  testWidgets('TC-008-25 every setup control has its label and help', (
    tester,
  ) async {
    await _openOnStartDay(tester);
    await enterE2(tester);
    InfoButton infoOf(String label) => tester.widget<InfoButton>(
      find.byWidgetPredicate((w) => w is InfoButton && w.label == label),
    );
    final helps = {
      'Salary day':
          'If your salary day is the 29th, 30th or 31st, short months start '
          'on their last day instead.',
      'Spendable this month': 'Your monthly target minus your fixed costs.',
      'Daily budget':
          'What you can spend each day: your spendable money divided by the '
          'days left in your budget month.',
    };
    expect(find.byType(InfoButton), findsNWidgets(helps.length));
    for (final MapEntry(key: label, value: body) in helps.entries) {
      expect(infoOf(label).info.title, label);
      await tester.ensureVisible(
        find.byWidgetPredicate((w) => w is InfoButton && w.label == label),
      );
      await tester.tap(
        find.byWidgetPredicate((w) => w is InfoButton && w.label == label),
      );
      await tester.pumpAndSettle();
      expect(findCopy(body), findsOneWidget, reason: label);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
    }
    // Every button and field carries its label to a screen reader.
    final semantics = tester.ensureSemantics();
    for (final label in [
      'Monthly salary',
      'Back',
      'Remove Rent',
      'Name, item 1 of 3',
      'Amount for Rent',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    semantics.dispose();
  });

  testWidgets('TC-008-05 invalid salaries show their error and save nothing', (
    tester,
  ) async {
    final store = await _openOnStartDay(tester);
    for (final (text, message) in [
      ('', 'Enter your salary'),
      ('0', 'Salary must be more than ₹0'),
      ('100000001', "That's more than ₹10 crore. Please check the amount."),
      ('12.345', 'Use numbers only, with up to 2 decimals'),
      ('abc', 'Use numbers only, with up to 2 decimals'),
    ]) {
      await tester.enterText(amountInput('Monthly salary'), text);
      await _tapStart(tester);
      expect(_inForm(message), findsOneWidget, reason: '"$text"');
      expect(
        _hasFocus(tester, amountInput('Monthly salary')),
        isTrue,
        reason: '"$text" moves focus to the salary',
      );
      expect(store.months, isEmpty, reason: '"$text"');
    }
  });

  testWidgets('TC-008-05 no salary day is an error on the day field', (
    tester,
  ) async {
    final store = FakeMoneyStore();
    await _openFirstSetup(tester, money: store);
    await _tapStart(tester);
    expect(findCopy('Choose your salary day'), findsOneWidget);
    expect(store.months, isEmpty);
  });

  testWidgets('TC-008-06 valid salaries are stored to the paisa and shown in '
      'whole rupees', (tester) async {
    for (final (text, line, paise) in [
      ('40000', '₹40,000 − ₹0 fixed = ₹40,000', 4000000),
      ('99.50', '₹99 − ₹0 fixed = ₹99', 9950),
      ('100000000', '₹10,00,00,000 − ₹0 fixed = ₹10,00,00,000', 10000000000),
    ]) {
      await tester.pumpWidget(const SizedBox());
      final store = await _openOnStartDay(tester);
      await typeAmount(tester, 'Monthly salary', text);
      expect(findCopy(line), findsOneWidget, reason: text);
      await _tapStart(tester);
      expect((_savedValues(store) as FullMonthValues).salary, p(paise));
      expect(findCopy('This month'), findsOneWidget, reason: text);
    }
  });

  testWidgets('TC-008-07 the spending target is validated and removed with '
      'the switch', (tester) async {
    final store = await _openOnStartDay(tester);
    await typeAmount(tester, 'Monthly salary', '40000');
    await tapVisible(tester, find.byType(Switch));
    await tester.pumpAndSettle();
    expect(findCopy('Spending target'), findsOneWidget);
    expect(
      findCopy(
        'The amount you want to spend this month, including fixed costs.',
      ),
      findsOneWidget,
    );

    await _tapStart(tester);
    expect(findCopy('Enter a target'), findsOneWidget);
    for (final (text, message) in [
      ('40000.01', "Target can't be more than your salary"),
      ('0', 'Target must be more than ₹0'),
    ]) {
      await typeAmount(tester, 'Spending target', text);
      expect(findCopy(message), findsOneWidget, reason: text);
    }
    await typeAmount(tester, 'Spending target', '20000');
    expect(findCopy('₹20,000 − ₹0 fixed = ₹20,000'), findsOneWidget);
    expect(findCopy('₹666 a day'), findsWidgets);

    await tapVisible(tester, find.byType(Switch));
    await tester.pumpAndSettle();
    expect(findCopy('Spending target'), findsNothing);
    expect(findCopy('₹40,000 − ₹0 fixed = ₹40,000'), findsOneWidget);
    expect(findCopy('₹1,333 a day'), findsWidgets);
    await _tapStart(tester);
    expect((_savedValues(store) as FullMonthValues).target, isNull);
  });

  testWidgets('TC-008-36 a target equal to the salary is allowed', (
    tester,
  ) async {
    final store = await _openOnStartDay(tester);
    await enterE2(tester);
    await tapVisible(tester, find.byType(Switch));
    await tester.pumpAndSettle();
    await typeAmount(tester, 'Spending target', '40000');
    expect(findCopy('₹830 a day'), findsWidgets);
    await _tapStart(tester);
    expect((_savedValues(store) as FullMonthValues).target, p(4000000));
  });

  testWidgets('TC-008-08 fixed costs can be added edited deleted and undone', (
    tester,
  ) async {
    final store = await _openOnStartDay(tester);
    await enterE2(tester);

    await _addItem(tester);
    expect(itemNameFields, findsNWidgets(4));
    expect(_hasFocus(tester, itemNameFields.at(3)), isTrue);
    await tester.enterText(itemNameFields.at(3), 'Gym');
    await tester.enterText(itemAmountFields.at(3), '1500');
    await tester.pump();
    expect(findCopy('₹16,600'), findsOneWidget);

    await tester.enterText(itemAmountFields.at(0), '12000');
    await tester.pump();
    expect(findCopy('₹18,600'), findsOneWidget);

    await tapVisible(tester, find.byTooltip('Remove EMI'));
    await tester.pumpAndSettle();
    expect(findCopy('EMI removed'), findsOneWidget);
    expect(findCopy('₹13,600'), findsOneWidget);
    expect(itemNameFields, findsNWidgets(3));
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(typed(tester, itemNameFields.at(1)), 'EMI');
    expect(typed(tester, itemAmountFields.at(1)), '5000');
    expect(findCopy('₹18,600'), findsOneWidget);

    await _addItem(tester);
    await tester.enterText(itemAmountFields.at(4), '200');
    await tester.pump();
    await _tapStart(tester);
    expect(findCopy('Give this cost a name'), findsOneWidget);
    expect(store.months, isEmpty);
  });

  testWidgets('TC-008-09 the thirty first fixed cost cannot be added', (
    tester,
  ) async {
    await _openOnStartDay(tester);
    for (var i = 0; i < 27; i++) {
      await _addItem(tester);
    }
    expect(itemNameFields, findsNWidgets(30));
    final add = find.widgetWithText(TextButton, '+ Add item');
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(add).onPressed, isNull);
    expect(findCopy('You can add up to 30 costs.'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Remove Rent'));
    await tapVisible(tester, find.byTooltip('Remove Rent'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(add).onPressed, isNotNull);
    expect(findCopy('You can add up to 30 costs.'), findsNothing);
  });

  testWidgets('TC-008-35 deleting every fixed cost leaves the salary to '
      'spend', (tester) async {
    final store = await _openOnStartDay(tester);
    await typeAmount(tester, 'Monthly salary', '40000');
    for (final name in ['Rent', 'EMI', 'Subscriptions']) {
      await tapVisible(tester, find.byTooltip('Remove $name'));
      await tester.pumpAndSettle();
    }
    expect(itemNameFields, findsNothing);
    expect(findCopy('₹0'), findsOneWidget, reason: 'Total fixed costs');
    expect(findCopy('₹40,000 − ₹0 fixed = ₹40,000'), findsOneWidget);
    expect(findCopy('₹1,333 a day'), findsWidgets);
    await _tapStart(tester);
    expect(store.months.single.periods.single.values.fixedCostsTotal, p(0));
    expect((_savedValues(store) as FullMonthValues).fixedCosts, isEmpty);
  });

  testWidgets('TC-008-11 preview and total update on every change in the same '
      'frame', (tester) async {
    await _openOnStartDay(tester);
    await enterE2(tester);

    await tester.enterText(amountInput('Monthly salary'), '35000');
    await tester.pump();
    expect(findCopy('₹35,000 − ₹15,100 fixed = ₹19,900'), findsOneWidget);
    expect(findCopy('₹663 a day'), findsWidgets);

    await tapVisible(tester, find.byType(Switch));
    await tester.pump();
    await tester.enterText(amountInput('Spending target'), '20000');
    await tester.pump();
    expect(findCopy('₹20,000 − ₹15,100 fixed = ₹4,900'), findsOneWidget);
    expect(findCopy('₹163 a day'), findsWidgets);

    await tapVisible(tester, find.byTooltip('Remove EMI'));
    await tester.pump();
    expect(findCopy('₹10,100'), findsOneWidget);
    expect(findCopy('₹20,000 − ₹10,100 fixed = ₹9,900'), findsOneWidget);
    expect(findCopy('₹330 a day'), findsWidgets);

    await tester.pump(const Duration(seconds: 1)); // the snackbar slides in
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(findCopy('₹163 a day'), findsWidgets);

    await tester.tap(find.text('+ Add item'));
    await tester.pump();
    await tester.pump();
    await tester.enterText(itemNameFields.at(3), 'Gym');
    await tester.enterText(itemAmountFields.at(3), '1500');
    await tester.pump();
    expect(findCopy('₹16,600'), findsOneWidget);
    expect(findCopy('₹20,000 − ₹16,600 fixed = ₹3,400'), findsOneWidget);
    expect(findCopy('₹113 a day'), findsWidgets);
  });

  testWidgets('TC-008-14 a mid month first setup asks for the money left', (
    tester,
  ) async {
    final store = FakeMoneyStore();
    await _openFirstSetup(tester, today: d(2026, 11, 10), money: store);
    await pickSalaryDay(tester, 5);

    expect(findCopy('Money left now'), findsOneWidget);
    expect(
      findCopy('How much you have to spend until your next salary.'),
      findsOneWidget,
    );
    expect(findCopy('Fixed costs still to pay this month'), findsOneWidget);
    expect(
      findCopy(
        "Bills you haven't paid yet before your next salary, like rent due "
        'next week.',
      ),
      findsOneWidget,
    );
    expect(itemNameFields, findsNothing);
    expect(findCopy('Monthly salary'), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(
      findCopy(
        "You're starting partway through the month, so we'll spread the "
        'money you have left over the 25 days until your next salary.',
      ),
      findsOneWidget,
    );

    await typeAmount(tester, 'Money left now', '24900');
    expect(findCopy('10 Nov – 4 Dec · 25 days left'), findsOneWidget);
    expect(findCopy('₹996 a day'), findsWidgets);
    await _tapStart(tester);

    final stored = store.months.single;
    expect(stored.firstBudgetedDay, d(2026, 11, 10));
    expect((_savedValues(store) as MidMonthStartValues).moneyLeft, p(2490000));
    expect(budgetPaise(storedResult(store, d(2026, 11, 10))), [
      ...List.filled(25, 99600),
    ]);
  });

  testWidgets('TC-008-15 mid month split and start day setup', (tester) async {
    final store = FakeMoneyStore();
    await _openFirstSetup(tester, today: d(2026, 11, 11), money: store);
    await pickSalaryDay(tester, 5);
    await typeAmount(tester, 'Money left now', '20000');
    expect(findCopy('11 Nov – 4 Dec · 24 days left'), findsOneWidget);
    expect(findCopy('₹833 a day'), findsWidgets);
    await _tapStart(tester);
    expect(budgetPaise(storedResult(store, d(2026, 11, 11))), [
      ...List.filled(8, 83334),
      ...List.filled(16, 83333),
    ]);

    await tester.pumpWidget(const SizedBox());
    await _openFirstSetup(tester);
    await pickSalaryDay(tester, 5);
    expect(findCopy('Monthly salary'), findsOneWidget);
    expect(findCopy('Money left now'), findsNothing);
    expect(itemNameFields, findsNWidgets(3));
  });

  testWidgets('TC-008-55 changing the salary day switches between full and '
      'mid month setup', (tester) async {
    await _openFirstSetup(tester, today: d(2026, 11, 10));
    await pickSalaryDay(tester, 10);
    expect(findCopy('Monthly salary'), findsOneWidget);
    await typeAmount(tester, 'Monthly salary', '40000');

    await pickSalaryDay(tester, 5);
    expect(findCopy('Money left now'), findsOneWidget);
    expect(findCopy('Monthly salary'), findsNothing);
    expect(findCopy('10 Nov – 4 Dec · 25 days left'), findsOneWidget);
    await typeAmount(tester, 'Money left now', '24900');
    expect(findCopy('₹996 a day'), findsWidgets);

    await pickSalaryDay(tester, 10);
    expect(typed(tester, amountInput('Monthly salary')), '40000');
    await pickSalaryDay(tester, 5);
    expect(typed(tester, amountInput('Money left now')), '24900');
    expect(findCopy('Discard changes?'), findsNothing);
  });

  testWidgets('TC-008-43 money left now is validated', (tester) async {
    final store = FakeMoneyStore();
    await _openFirstSetup(tester, today: d(2026, 11, 10), money: store);
    await pickSalaryDay(tester, 5);
    for (final (text, message) in [
      ('', 'Enter how much you have left'),
      ('0', 'Amount must be more than ₹0'),
      ('100000001', "That's more than ₹10 crore. Please check the amount."),
      ('abc', 'Use numbers only, with up to 2 decimals'),
    ]) {
      await tester.enterText(amountInput('Money left now'), text);
      await _tapStart(tester);
      expect(_inForm(message), findsOneWidget, reason: '"$text"');
      expect(store.months, isEmpty);
    }
  });

  testWidgets('TC-008-16 double tap on start my month saves once', (
    tester,
  ) async {
    final store = await _openOnStartDay(tester);
    await enterE2(tester);

    await tester.tap(_start);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(_start, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(store.months, hasLength(1));
    expect(store.months.single.periods, hasLength(1));
    expect((_savedValues(store) as FullMonthValues).fixedCosts, hasLength(3));
    expect(_start, findsNothing, reason: 'one navigation back to Home');
    // The second tap may land on the bar below the closing screen.
    await tapTab(tester, 'Home');
    expect(findCopy('5 Nov – 4 Dec · ₹830 a day'), findsOneWidget);
  });

  testWidgets('TC-008-17 failed save keeps the entered values', (tester) async {
    final store = await _openOnStartDay(tester);
    await enterE2(tester);
    await tapVisible(tester, find.byType(Switch));
    await tester.pumpAndSettle();
    await typeAmount(tester, 'Spending target', '20000');

    store.failNextWrite = true;
    await _tapStart(tester);

    expect(findCopy("Couldn't save. Please try again."), findsOneWidget);
    expect(_start, findsOneWidget, reason: 'still on the setup screen');
    expect(typed(tester, amountInput('Monthly salary')), '40000');
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(typed(tester, amountInput('Spending target')), '20000');
    expect(typed(tester, itemNameFields.at(2)), 'Subscriptions');
    expect(typed(tester, itemAmountFields.at(0)), '10000');
    expect(store.months, isEmpty);

    await tapVisible(tester, find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(findCopy('Set up your month'), findsWidgets);
    expect(findCopy('Your daily budget lives here'), findsOneWidget);
  });

  testWidgets('TC-008-22 leaving with changes asks to discard', (tester) async {
    final store = FakeMoneyStore();
    await _openFirstSetup(tester, money: store);
    await pickSalaryDay(tester, 5);
    await typeAmount(tester, 'Monthly salary', '40000');

    for (final viaButton in [false, true]) {
      if (viaButton) {
        await tapVisible(tester, find.byTooltip('Back'));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(findCopy('Discard changes?'), findsOneWidget);
      expect(
        findCopy("Your changes to this month won't be saved."),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('Keep editing')).dy,
        lessThan(tester.getTopLeft(find.text('Discard')).dy),
        reason: 'Keep editing comes first',
      );
      if (!viaButton) {
        await tester.tap(find.text('Keep editing'));
        await tester.pumpAndSettle();
        expect(findCopy('Discard changes?'), findsNothing);
        expect(typed(tester, amountInput('Monthly salary')), '40000');
      }
    }
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(_start, findsNothing);
    expect(store.months, isEmpty);
    expect(findCopy('Your daily budget lives here'), findsOneWidget);
  });

  testWidgets('TC-008-22 an unchanged setup leaves at once', (tester) async {
    await _openFirstSetup(tester);
    await tapVisible(tester, find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(findCopy('Discard changes?'), findsNothing);
    expect(_start, findsNothing);
  });

  testWidgets('TC-008-19 new month opens with last months numbers', (
    tester,
  ) async {
    final store = storeWithMonth(values: e2Values(target: 2000000));
    await pumpHome(tester, money: store, clock: MovableClock(d(2026, 12, 5)));
    await tapText(tester, 'Set up this month');

    expect(findCopy('Set up this month'), findsOneWidget);
    expect(findCopy('Salary day: 5th'), findsOneWidget);
    expect(findCopy('Set in your first month.'), findsOneWidget);
    expect(findCopy('5 Dec – 4 Jan · 31 days'), findsOneWidget);
    expect(
      findCopy("We've filled in last month's numbers. Check them and confirm."),
      findsOneWidget,
    );
    expect(typed(tester, amountInput('Monthly salary')), '40000');
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(typed(tester, amountInput('Spending target')), '20000');
    expect(
      [
        for (var i = 0; i < 3; i++)
          (
            typed(tester, itemNameFields.at(i)),
            typed(tester, itemAmountFields.at(i)),
          ),
      ],
      [('Rent', '10000'), ('EMI', '5000'), ('Subscriptions', '100')],
    );
    expect(findCopy('₹20,000 − ₹15,100 fixed = ₹4,900'), findsOneWidget);
    expect(findCopy('₹158 a day'), findsWidgets);
    expect(store.months, hasLength(1), reason: 'nothing saved until Confirm');
  });

  testWidgets('TC-008-42 salary day label uses the right ordinal', (
    tester,
  ) async {
    for (final (day, label) in [
      (1, '1st'),
      (2, '2nd'),
      (3, '3rd'),
      (4, '4th'),
      (11, '11th'),
      (12, '12th'),
      (13, '13th'),
      (21, '21st'),
      (22, '22nd'),
      (23, '23rd'),
      (31, '31st'),
    ]) {
      await tester.pumpWidget(const SizedBox());
      final month = BudgetMonth.startIn(day, 2026, 11);
      await pumpHome(
        tester,
        money: storeWithMonth(month: month),
        clock: MovableClock(month.next.start),
      );
      await tapText(tester, 'Set up this month');
      expect(findCopy('Salary day: $label'), findsOneWidget, reason: label);
    }
  });

  testWidgets('TC-008-41 after missed months setup is a fresh start', (
    tester,
  ) async {
    final store = storeWithMonth(month: oct2026);
    await pumpHome(tester, money: store, clock: MovableClock(d(2026, 12, 20)));
    await tapText(tester, 'Set up this month');

    expect(findCopy('Set up this month'), findsOneWidget);
    expect(findCopy('Salary day: 5th'), findsOneWidget);
    expect(findCopy('Money left now'), findsOneWidget);
    expect(findCopy('Fixed costs still to pay this month'), findsOneWidget);
    expect(itemNameFields, findsNothing);
    expect(findCopy('Monthly salary'), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(findCopy("We've filled in last month's numbers"), findsNothing);
    expect(findCopy('over the 16 days until your next salary.'), findsNothing);
    expect(
      findCopy(
        "You're starting partway through the month, so we'll spread the "
        'money you have left over the 16 days until your next salary.',
      ),
      findsOneWidget,
    );

    await typeAmount(tester, 'Money left now', '16000');
    expect(findCopy('20 Dec – 4 Jan · 16 days left'), findsOneWidget);
    expect(findCopy('₹1,000 a day'), findsWidgets);
    await _tapStart(tester);

    expect(store.months, hasLength(2));
    final stored = store.months.last;
    expect(stored.month.start, d(2026, 12, 5));
    expect(stored.firstBudgetedDay, d(2026, 12, 20));
    expect(
      budgetPaise(computeMonth(store.inputFor(stored.id, d(2026, 12, 20)))),
      List.filled(16, 100000),
    );
  });

  testWidgets('TC-008-56 a late month setup starts fresh from today', (
    tester,
  ) async {
    final store = storeWithMonth();
    await pumpHome(tester, money: store, clock: MovableClock(d(2026, 12, 12)));
    await tapText(tester, 'Set up this month');
    expect(
      findCopy(
        "You're starting partway through the month, so we'll spread the "
        'money you have left over the 24 days until your next salary.',
      ),
      findsOneWidget,
    );
    await typeAmount(tester, 'Money left now', '24000');
    expect(findCopy('12 Dec – 4 Jan · 24 days left'), findsOneWidget);
    expect(findCopy('₹1,000 a day'), findsWidgets);
    await _tapStart(tester);

    final stored = store.months.last;
    expect(stored.firstBudgetedDay, d(2026, 12, 12));
    final result = computeMonth(store.inputFor(stored.id, d(2026, 12, 12)));
    expect(budgetPaise(result), List.filled(24, 100000));
    expect(result.dayOn(d(2026, 12, 11)).status, DayStatus.notBudgeted);
    expect(result.totals.saved, p(0));
  });

  testWidgets('TC-008-31 pasted amounts are normalised or rejected', (
    tester,
  ) async {
    await _openOnStartDay(tester);
    for (final text in ['₹40,000', '40,000.00', ' 40000 ']) {
      await typeAmount(tester, 'Monthly salary', text);
      expect(
        findCopy('₹40,000 − ₹0 fixed = ₹40,000'),
        findsOneWidget,
        reason: '"$text"',
      );
    }
    for (final text in ['40k', '4O000']) {
      await typeAmount(tester, 'Monthly salary', text);
      await _tapStart(tester);
      expect(
        findCopy('Use numbers only, with up to 2 decimals'),
        findsOneWidget,
        reason: '"$text"',
      );
    }
  });

  testWidgets('TC-008-32 leading zeros and decimal comma are handled', (
    tester,
  ) async {
    await _openOnStartDay(tester);
    for (final (text, line) in [
      ('040000', '₹40,000 − ₹0 fixed = ₹40,000'),
      ('0.01', '₹0 − ₹0 fixed = ₹0'),
      ('.5', '₹0 − ₹0 fixed = ₹0'),
      ('40000.', '₹40,000 − ₹0 fixed = ₹40,000'),
    ]) {
      await typeAmount(tester, 'Monthly salary', text);
      expect(findCopy(line), findsOneWidget, reason: '"$text"');
    }
    await typeAmount(tester, 'Monthly salary', '99,50');
    await _tapStart(tester);
    expect(findCopy('Use numbers only, with up to 2 decimals'), findsOneWidget);
  });

  testWidgets('TC-008-34 fixed cost name and amount limits', (tester) async {
    final store = await _openOnStartDay(tester);
    await typeAmount(tester, 'Monthly salary', '40000');

    // The limit counts characters as the user sees them: a Hindi syllable
    // of two code points, an emoji of two code units and a family emoji of
    // eight code points each count once.
    for (final unit in ['a', 'कि', '😀', '👨‍👩‍👧']) {
      await tester.enterText(itemNameFields.at(0), unit * 40);
      await tester.pump();
      expect(typed(tester, itemNameFields.at(0)), unit * 40, reason: unit);
      await tester.enterText(itemNameFields.at(0), unit * 41);
      await tester.pump();
      expect(
        typed(tester, itemNameFields.at(0)),
        unit * 40,
        reason: 'the 41st character of "$unit" is not accepted',
      );
    }

    await tester.enterText(itemNameFields.at(0), 'EMI');
    await tester.enterText(itemNameFields.at(1), 'EMI');
    await tester.enterText(itemAmountFields.at(2), '100000000.01');
    await tester.pump();
    await _tapStart(tester);
    expect(
      findCopy("That's more than ₹10 crore. Please check the amount."),
      findsOneWidget,
    );
    expect(store.months, isEmpty);

    await tester.enterText(itemAmountFields.at(2), '100');
    await tester.pump();
    await _tapStart(tester);
    expect(
      [
        for (final c in (_savedValues(store) as FullMonthValues).fixedCosts)
          c.name,
      ],
      ['EMI', 'EMI', 'Subscriptions'],
      reason: 'duplicate names are allowed',
    );
  });

  testWidgets('TC-008-37 typed values survive rotation and backgrounding', (
    tester,
  ) async {
    await _openOnStartDay(tester);
    await enterE2(tester);
    await tester.enterText(itemNameFields.at(1), 'Home loan');
    await tester.pump();

    tester.view.physicalSize = kSmallLandscape * 3;
    await tester.pumpAndSettle();
    expect(typed(tester, amountInput('Monthly salary')), '40000');
    expect(typed(tester, itemNameFields.at(1)), 'Home loan');
    expect(typed(tester, itemAmountFields.at(0)), '10000');

    sendToBackground(tester);
    await tester.pump();
    bringToForeground(tester);
    await tester.pumpAndSettle();
    expect(typed(tester, amountInput('Monthly salary')), '40000');
    expect(findCopy('Discard changes?'), findsNothing);
    expect(findCopy('₹830 a day'), findsWidgets);

    tester.view.physicalSize = kSmallPhone * 3;
    await tester.pumpAndSettle();
    expect(typed(tester, itemNameFields.at(1)), 'Home loan');
  });

  testWidgets('TC-008-39 confirm after midnight saves the month containing '
      'today', (tester) async {
    final store = FakeMoneyStore();
    final clock = MovableClock(d(2026, 12, 4));
    await _openFirstSetup(tester, money: store, clock: clock);
    await pickSalaryDay(tester, 5);
    expect(findCopy('Money left now'), findsOneWidget);

    clock.moveTo(d(2026, 12, 5));
    sendToBackground(tester);
    bringToForeground(tester);
    await tester.pump();
    expect(findCopy('5 Dec – 4 Jan · 31 days'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(findCopy('Monthly salary'), findsOneWidget);

    await enterE2(tester);
    await _tapStart(tester);
    final stored = store.months.single;
    expect(stored.month.start, d(2026, 12, 5));
    expect(stored.month.end, d(2027, 1, 4));
    expect(stored.firstBudgetedDay, d(2026, 12, 5));
  });
}
