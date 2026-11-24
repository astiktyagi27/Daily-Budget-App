import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/home/calendar/day_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/bundled_fonts.dart';
import '../../helpers/day_details_harness.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/transactions_harness.dart' show addSpendTo;
import '../../support/find_copy.dart';

// F-012 §2.3, §2.5: cover with savings, Undo, today's cover and later edits.

Finder get _coverButton => find.text('Cover with savings');
Finder get _sheetField => find.byType(TextField);

String _fieldText(WidgetTester tester) =>
    tester.widget<TextField>(_sheetField).controller!.text;

Future<void> _openSheet(WidgetTester tester) async {
  await tester.ensureVisible(_coverButton);
  await tester.pumpAndSettle();
  await tester.tap(_coverButton);
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(_sheetField, text);
  await tester.pump();
}

Future<void> _confirm(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.tap(find.text('Cover'));
  await tester.pumpAndSettle();
}

List<Cover> _covers(FakeMoneyStore store) =>
    store.coversByMonth[store.months.last.id] ?? <Cover>[];

void main() {
  setUpAll(loadBundledFonts);

  testWidgets(
    'TC-012-06 cover is offered only on overspent days of this month',
    (tester) async {
      for (final day in [5, 6, 7, 11, 12, 13, 14]) {
        await tester.pumpWidget(const SizedBox());
        await openDay(tester, a13, nov(day));
        final offered = day == 6 || day == 11;
        expect(
          _coverButton,
          offered ? findsOneWidget : findsNothing,
          reason: '$day Nov',
        );
        expect(
          find.text('Savings pot'),
          offered ? findsOneWidget : findsNothing,
          reason: '$day Nov',
        );
      }
      // An overspent day of last month.
      await tester.pumpWidget(const SizedBox());
      await openDay(tester, octNov, CalendarDate(2026, 10, 6), monthIndex: 0);
      expect(find.text('◆ Overspent ₹196'), findsWidgets);
      expect(_coverButton, findsNothing);
    },
  );

  testWidgets('TC-012-07 todays overspend can be covered and says so', (
    tester,
  ) async {
    await openDay(tester, a13o, nov(13));
    expect(find.text('◆ Today · overspent ₹170'), findsOneWidget);
    expect(_coverButton, findsOneWidget);
    expect(
      find.text('Spending more today will make it overspent again.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await openDay(tester, a13, nov(13));
    expect(_coverButton, findsNothing);
    expect(
      find.text('Spending more today will make it overspent again.'),
      findsNothing,
    );
  });

  testWidgets('TC-012-08 covering the whole overspend of 11 november', (
    tester,
  ) async {
    final opened = await openDay(tester, a13, nov(11));
    await _openSheet(tester);
    expect(find.text('Cover Wed, 11 Nov'), findsOneWidget);
    expect(findCopy('Overspent ₹300 · Savings pot ₹2,000'), findsOneWidget);
    expect(_fieldText(tester), '300');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
      reason: 'not focused on open',
    );
    expect(find.text('This covers the whole overspend.'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    await _confirm(tester);

    expect(_covers(opened.store).single.amount, const Paise(30000));
    expect(_covers(opened.store).single.day, nov(11));
    expect(find.text('₹300 covered from your savings'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('○ On budget'), findsWidgets);
    expect(figure(tester, 'Covered from savings'), '₹300');
    expect(find.text('Remove'), findsOneWidget);
    expect(find.text('Covered ₹300 from savings.'), findsOneWidget);
    expect(_coverButton, findsNothing);
    // Home: the calendar cell is on budget, Overspent is ₹170.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    final cell = tester.widget<DayCell>(
      find.byWidgetPredicate((w) => w is DayCell && w.cell.date == nov(11)),
    );
    expect(cell.cell.kind, CellKind.onBudget);
    expect(find.textContaining('₹1,700'), findsWidgets);
  });

  testWidgets('TC-012-10 partial cover leaves the rest coverable', (
    tester,
  ) async {
    final opened = await openDay(tester, a13, nov(11));
    await _openSheet(tester);
    await _type(tester, '100');
    await _confirm(tester);
    expect(_covers(opened.store).single.amount, const Paise(10000));
    expect(find.text('◆ Overspent ₹200'), findsWidgets);
    expect(figure(tester, 'Covered from savings'), '₹100');
    expect(find.textContaining('₹1,900'), findsWidgets, reason: 'the pot');
    await tester.pumpAndSettle(const Duration(seconds: 7));
    await _openSheet(tester);
    expect(_fieldText(tester), '200');
  });

  testWidgets('TC-012-44 two covers on one day add up', (tester) async {
    final opened = await openDay(tester, a13, nov(11));
    await _openSheet(tester);
    await _type(tester, '100');
    await _confirm(tester);
    await _openSheet(tester);
    expect(_fieldText(tester), '200');
    await _confirm(tester);
    expect(
      [for (final c in _covers(opened.store)) c.amount.value],
      [10000, 20000],
    );
    expect(find.text('○ On budget'), findsWidgets);
    expect(figure(tester, 'Covered from savings'), '₹300');
    expect(_coverButton, findsNothing);
  });

  testWidgets('TC-012-11 a small pot is covered in full and then empty', (
    tester,
  ) async {
    final opened = await openDay(tester, p250, nov(11));
    await _openSheet(tester);
    expect(_fieldText(tester), '250');
    expect(find.text('This uses your whole savings pot.'), findsOneWidget);
    await _confirm(tester);
    expect(_covers(opened.store).single.amount, const Paise(25000));
    expect(find.text('◆ Overspent ₹50'), findsWidgets);
    expect(find.text('Your savings pot is empty.'), findsOneWidget);
    expect(_coverButton, findsNothing);
  });

  testWidgets('TC-012-15 empty pot shows no cover button', (tester) async {
    await openDay(tester, s8, nov(6));
    expect(figure(tester, 'Budget'), '₹0');
    expect(figure(tester, 'Spent'), '₹200');
    expect(find.text('◆ Overspent ₹200'), findsWidgets);
    expect(_coverButton, findsNothing);
    expect(find.text('Your savings pot is empty.'), findsOneWidget);
    final handle = tester.ensureSemantics();
    await tester.tap(
      find.bySemanticsLabel('More about Your savings pot is empty.'),
    );
    await tester.pumpAndSettle();
    expect(
      findCopy('Your pot fills up on days you spend less than your budget.'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('TC-012-35 todays overspend can be covered and spent again', (
    tester,
  ) async {
    final opened = await openDay(tester, a13o, nov(13));
    await _openSheet(tester);
    expect(_fieldText(tester), '170');
    await _confirm(tester);
    expect(find.text('○ Today · on budget'), findsOneWidget);
    expect(figure(tester, 'Covered from savings'), '₹170');
    expect(
      find.textContaining('₹1,830'),
      findsNothing,
      reason: 'the cover note replaces the card',
    );
    addSpendTo(opened.store, nov(13), 10000);
    opened.store.notify();
    await tester.pumpAndSettle();
    expect(find.text('◆ Today · overspent ₹100'), findsOneWidget);
    expect(figure(tester, 'Covered from savings'), '₹170');
  });

  testWidgets('TC-012-37 undo takes the cover back', (tester) async {
    final opened = await openDay(tester, a13, nov(11));
    await _openSheet(tester);
    await _confirm(tester);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(_covers(opened.store), isEmpty);
    expect(find.text('◆ Overspent ₹300'), findsWidgets);
    expect(find.text('Cover undone'), findsOneWidget);
    expect(figure(tester, 'Covered from savings'), isNull);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    final cell = tester.widget<DayCell>(
      find.byWidgetPredicate((w) => w is DayCell && w.cell.date == nov(11)),
    );
    expect(cell.cell.kind, CellKind.overspent);
  });

  testWidgets('TC-012-38 undo expires after six seconds', (tester) async {
    await openDay(tester, a13, nov(11));
    await _openSheet(tester);
    await _confirm(tester);
    expect(find.text('Undo'), findsOneWidget);
    // Flutter starts the timer after the 250 ms slide in, so 5.75 s here is
    // six seconds on screen (AC-21); six seconds here would be 6.25.
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).duration,
      const Duration(milliseconds: 5750),
    );
    await tester.pump(const Duration(seconds: 6, milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsNothing);
    expect(find.text('₹300 covered from your savings'), findsNothing);
    expect(figure(tester, 'Covered from savings'), '₹300');
  });

  testWidgets('TC-012-38 undo stays while a screen reader is on', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await openDay(tester, a13, nov(11));
    await _openSheet(tester);
    await _confirm(tester);
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('TC-012-55 undo takes back one cover only', (tester) async {
    final opened = await openDay(tester, a13, nov(11));
    await _openSheet(tester);
    await _type(tester, '100');
    await _confirm(tester);
    await _openSheet(tester);
    await _confirm(tester);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect([for (final c in _covers(opened.store)) c.amount.value], [10000]);
    expect(figure(tester, 'Covered from savings'), '₹100');
    expect(find.text('◆ Overspent ₹200'), findsWidgets);
  });

  testWidgets('TC-012-36 a cut cover stays cut', (tester) async {
    final store = storeFor(a13o);
    final month = store.months.last.id;
    store.coversByMonth[month] = [
      Cover(
        id: 90,
        day: nov(13),
        amount: const Paise(17000),
        madeAt: DateTime(2026, 11, 13, 9).millisecondsSinceEpoch,
      ),
    ];
    await openDay(tester, a13o, nov(13), store: store);
    expect(find.text('○ Today · on budget'), findsOneWidget);

    void setSpend(int paise) {
      final list = store.spendsByMonth[month]!;
      final index = list.indexWhere((s) => s.spend.date == nov(13));
      final old = list[index];
      list[index] = StoredSpend(
        spend: Spend(
          id: old.spend.id,
          date: old.spend.date,
          amount: Paise(paise),
          createdAt: old.spend.createdAt,
        ),
        note: old.note,
      );
      store
        ..reconcile(month, nov(13))
        ..notify();
    }

    // Lower today's spend: the cover is cut to ₹70 and stored.
    setSpend(90000);
    await tester.pumpAndSettle();
    expect(find.text('○ Today · on budget'), findsOneWidget);
    expect(figure(tester, 'Covered from savings'), '₹70');
    expect(_covers(store).single.amount, const Paise(7000));
    // Raising it again leaves the cover at ₹70.
    setSpend(100000);
    await tester.pumpAndSettle();
    expect(find.text('◆ Today · overspent ₹100'), findsOneWidget);
    expect(figure(tester, 'Covered from savings'), '₹70');
    expect(_coverButton, findsOneWidget);
  });
}
