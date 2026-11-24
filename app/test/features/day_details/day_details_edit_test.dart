import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/transactions/spend_editor_screen.dart';
import 'package:daily_budget/features/transactions/spend_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/bundled_fonts.dart';
import '../../helpers/day_details_harness.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/transactions_harness.dart'
    show addMoneyInTo, amountInput, tapLabel;
import '../../support/find_copy.dart';

// F-012 §2.4: add, edit and delete from the day, cover reductions.

/// The row whose amount reads [amount] (the figures card repeats it).
Finder _row(String amount) =>
    find.descendant(of: find.byType(SpendRow), matching: find.text(amount));

Future<void> _editRow(WidgetTester tester, Finder row, String amount) async {
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
  await tester.enterText(amountInput, amount);
  await tester.pump();
  await tapLabel(tester, 'Save changes');
}

Future<void> _addSpend(WidgetTester tester, String amount) async {
  await tester.ensureVisible(find.text('Add spend'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add spend'));
  await tester.pumpAndSettle();
  await tester.enterText(amountInput, amount);
  await tester.pump();
  await tapLabel(tester, 'Save');
}

Future<void> _pickDay(WidgetTester tester, String day) async {
  await tester.ensureVisible(find.byIcon(Icons.calendar_today_outlined));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.calendar_today_outlined));
  await tester.pumpAndSettle();
  await tester.tap(find.text(day));
  await tester.pump();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

List<Cover> _covers(FakeMoneyStore store) =>
    store.coversByMonth[store.months.last.id] ?? <Cover>[];

Future<void> _deleteOpenRow(WidgetTester tester, String note) async {
  await tester.tap(find.text(note));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Delete'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete').last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadBundledFonts);

  testWidgets('TC-012-18 add spend from a day presets its date', (
    tester,
  ) async {
    final opened = await openDay(tester, a13, nov(8));
    await tester.ensureVisible(find.text('Add spend'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add spend'));
    await tester.pumpAndSettle();
    expect(find.text('Sun, 8 Nov'), findsOneWidget);
    await tester.enterText(amountInput, '100');
    await tester.pump();
    await tapLabel(tester, 'Save');
    final spends = opened.store.spendsByMonth[opened.monthId]!;
    expect(
      spends
          .where((s) => s.spend.date == nov(8))
          .map((s) => s.spend.amount.value),
      containsAll([10000, 20000]),
    );
    expect(figure(tester, 'Spent'), '₹300');
    expect(find.text('● Saved ₹530'), findsWidgets);
    expect(find.text('Spend added'), findsOneWidget);
  });

  testWidgets('TC-012-61 double tap on add spend opens one editor', (
    tester,
  ) async {
    await openDay(tester, a13, nov(8));
    await tester.ensureVisible(find.text('Add spend'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add spend'));
    await tester.pump(const Duration(milliseconds: 30));
    await tester.tap(find.text('Add spend'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(SpendEditorScreen), findsOneWidget);
  });

  testWidgets('TC-012-20 editing a spend updates the day', (tester) async {
    await openDay(tester, a13, nov(9));
    await _editRow(tester, find.text('No note'), '470');
    expect(find.text('Spend updated'), findsOneWidget);
    expect(figure(tester, 'Spent'), '₹720');
    expect(find.text('● Saved ₹110'), findsWidgets);
  });

  testWidgets('TC-012-21 deleting a spend updates the day', (tester) async {
    final opened = await openDay(tester, a13, nov(9));
    await _deleteOpenRow(tester, 'Lunch');
    expect(find.text('Spend deleted'), findsOneWidget);
    expect(figure(tester, 'Spent'), '₹370');
    expect(find.text('Lunch'), findsNothing);
    expect(
      opened.store.spendsByMonth[opened.monthId]!.where(
        (s) => s.spend.date == nov(9),
      ),
      hasLength(1),
    );
  });

  testWidgets(
    'TC-012-22 moving a spend leaves the day and says where it went',
    (tester) async {
      await openDay(tester, a13, nov(9));
      await tester.tap(find.text('Lunch'));
      await tester.pumpAndSettle();
      await _pickDay(tester, '8');
      await tapLabel(tester, 'Save changes');
      expect(find.text('Spend moved to Sun, 8 Nov'), findsOneWidget);
      expect(find.text('Lunch'), findsNothing);
      expect(find.text('Mon, 9 Nov'), findsOneWidget, reason: 'its own day');
      expect(figure(tester, 'Spent'), '₹370');
    },
  );

  testWidgets('TC-012-23 a cover taken back is explained once', (tester) async {
    final store = storeFor(w3);
    await openDay(tester, w3, nov(5), store: store);
    await _editRow(tester, _row('₹500'), '830');
    expect(find.text('Savings pot updated'), findsOneWidget);
    expect(
      findCopy(
        'Your savings pot went down, so the ₹170 that covered Fri, 6 Nov was '
        'taken back. 6 Nov is overspent again.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Savings pot updated'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await openDay(tester, w3, nov(6), store: store);
    expect(find.text('◆ Overspent ₹170'), findsWidgets);
    expect(figure(tester, 'Covered from savings'), isNull);
  });

  testWidgets('TC-012-24 over covered edit returns the extra without a note', (
    tester,
  ) async {
    final store = storeFor(w3);
    await openDay(tester, w3, nov(6), store: store);
    await _editRow(tester, _row('₹1,000'), '900');
    expect(find.text('Savings pot updated'), findsNothing);
    expect(find.text('Spend updated'), findsOneWidget);
    expect(find.text('○ On budget'), findsWidgets);
    expect(figure(tester, 'Covered from savings'), '₹70');
    expect(_covers(store).single.amount, const Paise(7000));
  });

  testWidgets('TC-012-59 raising a cut spend does not restore the old cover', (
    tester,
  ) async {
    final store = storeFor(w3);
    await openDay(tester, w3, nov(6), store: store);
    await _editRow(tester, _row('₹1,000'), '900');
    await tester.pumpAndSettle(const Duration(seconds: 5));
    await _editRow(tester, _row('₹900'), '1000');
    expect(find.text('◆ Overspent ₹100'), findsWidgets);
    expect(figure(tester, 'Covered from savings'), '₹70');
    expect(find.text('Cover with savings'), findsOneWidget);
    await tester.ensureVisible(find.text('Cover with savings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cover with savings'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '100',
    );
  });

  testWidgets('TC-012-49 deleting the last spend returns the cover', (
    tester,
  ) async {
    final store = storeFor(a13c300);
    await openDay(tester, a13c300, nov(11), store: store);
    await _deleteOpenRow(tester, 'Phone bill');
    expect(find.text('Nothing spent this day'), findsOneWidget);
    expect(find.text('● Saved ₹830'), findsWidgets);
    expect(figure(tester, 'Covered from savings'), isNull);
    expect(find.text('Remove'), findsNothing);
    expect(find.text('Savings pot updated'), findsNothing);
    expect(_covers(store).single.amount, Paise.zero);
  });

  testWidgets('TC-012-50 a refund on a covered day returns the cover', (
    tester,
  ) async {
    final store = storeFor(a13c300);
    await openDay(tester, a13c300, nov(11), store: store);
    addMoneyInTo(store, nov(11), 50000, note: 'Return');
    store
      ..reconcile(store.months.last.id, nov(13))
      ..notify();
    await tester.pumpAndSettle();
    expect(figure(tester, 'Net spent'), '₹630');
    expect(find.text('● Saved ₹200'), findsWidgets);
    expect(_covers(store).single.amount, Paise.zero);
    expect(find.text('Remove'), findsNothing);
  });

  testWidgets('TC-012-58 refund rows open the Edit money back editor', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final opened = await openDay(tester, r16, nov(16));
    final node = tester.getSemantics(
      find.bySemanticsLabel('Refund, ₹500, Amazon return'),
    );
    expect(node.hint, 'Edit');
    expect(node.label, 'Refund, ₹500, Amazon return');

    // F-016 is built: the row opens the Money back editor, values filled.
    await tester.tap(find.text('Amazon return'));
    await tester.pumpAndSettle();
    expect(find.text('Edit money back'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.text('500'), findsOneWidget);
    await tester.enterText(amountInput, '300');
    await tester.pump();
    await tapLabel(tester, 'Save changes');
    expect(find.text('Money back updated'), findsOneWidget);
    final refund = opened.store.spendsByMonth[opened.monthId]!.firstWhere(
      (s) => s.spend.direction == SpendDirection.moneyIn,
    );
    expect(refund.spend.amount, const Paise(30000));
    expect(figure(tester, 'Refunds'), '−₹300');
    handle.dispose();
  });

  testWidgets('TC-012-60 covers that still fit give no note', (tester) async {
    final store = storeFor(a13c300);
    await openDay(tester, a13c300, nov(12), store: store);
    await _addSpend(tester, '830');
    await tester.pumpWidget(const SizedBox());
    await openDay(tester, a13c300, nov(5), store: store);
    await _editRow(tester, _row('₹500'), '830');
    expect(find.text('Savings pot updated'), findsNothing);
    expect(_covers(store).single.amount, const Paise(30000));
  });
}
