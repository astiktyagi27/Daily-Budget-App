import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/home/calendar/day_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/bundled_fonts.dart';
import '../../helpers/day_details_harness.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/setup_harness.dart' hide amountInput;
import '../../helpers/shell.dart';
import '../../helpers/statement_harness.dart';
import '../../helpers/transactions_harness.dart';
import '../../support/app_lifecycle.dart';
import '../../support/find_copy.dart';

// F-016 T-441 / T-443: what a money back entered in the editor does on the
// other screens (Transactions Today card, Home, calendar, day details,
// Dashboard, Month statement), all on the fake repositories.

const _tall = Size(400, 2400);

Future<FakeMoneyStore> _open(
  WidgetTester tester,
  Phase3Fixture fixture, {
  TestClock? clock,
  Size size = _tall,
  double textScale = 1,
}) async {
  final store = storeFor(fixture);
  await pumpTransactions(
    tester,
    money: store,
    clock: clock ?? TestClock(fixture.now),
    size: size,
    textScale: textScale,
  );
  return store;
}

/// Adds money back from the Transactions tab's Add spend.
Future<void> _addMoneyBack(
  WidgetTester tester,
  String amount, [
  String? note,
]) async {
  await tester.tap(addSpendButton);
  await tester.pumpAndSettle();
  await typeInto(tester, amountInput, amount);
  if (note != null) await typeInto(tester, noteInput, note);
  await tester.tap(find.text('Money back / refund'));
  await tester.pumpAndSettle();
  await tapLabel(tester, 'Save');
}

String _homeToday() {
  final texts = find.descendant(
    of: find.byKey(const ValueKey('today-line')),
    matching: find.byType(Text),
  );
  return [
    for (final element in texts.evaluate())
      if ((element.widget as Text).key != const ValueKey('today-mark'))
        plainCopy(
          (element.widget as Text).data ??
              (element.widget as Text).textSpan!.toPlainText(),
        ),
  ].join(' ');
}

Finder _ledger(String label, String amount) =>
    find.bySemanticsLabel('$label, $amount');

void main() {
  // Day details lines depend on real glyph widths.
  setUpAll(loadBundledFonts);

  testWidgets('TC-016-04 refund lowers today and the month figures', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, fixtureA);
    await _addMoneyBack(tester, '500', 'Amazon return');
    expect(find.text('Money back added'), findsOneWidget);
    // The Transactions card keeps the F-009 layout (D-084 (1)).
    await scrollToTop(tester);
    expect(todayLineText(tester), 'budget ₹830 · spent −₹80 · ₹910 left today');
    expect(find.textContaining('back from refunds'), findsNothing);
    expect(findCopy('Refund'), findsWidgets);
    expect(findCopy('+₹500'), findsOneWidget);

    await tapTab(tester, 'Home');
    expect(_homeToday(), 'budget ₹830 · spent −₹80 · ₹910 left today');
    expect(findCopy('Includes ₹500 back from refunds'), findsOneWidget);
    expect(_ledger('Spent so far', '₹5,030'), findsOneWidget);
    expect(findCopy('₹19,870'), findsOneWidget, reason: 'Left this month');
    semantics.dispose();
  });

  testWidgets('TC-016-06 a refund larger than the day makes it saved by more '
      'than its budget', (tester) async {
    final semantics = tester.ensureSemantics();
    final store = storeFor(fixtureA);
    await openDay(tester, fixtureA, nov(12), store: store, size: _tall);
    expect(find.text('● Saved ₹830'), findsWidgets);
    await tester.tap(find.text('Add spend'));
    await tester.pumpAndSettle();
    await typeInto(tester, amountInput, '1500');
    await tester.tap(find.text('Money back / refund'));
    await tester.pumpAndSettle();
    await tapLabel(tester, 'Save');
    expect(find.text('Money back added'), findsOneWidget);
    // Day details (F-012): status, ledger and the Refund row.
    expect(find.text('● Saved ₹2,330'), findsWidgets);
    expect(figure(tester, 'Refunds'), '−₹1,500');
    expect(figure(tester, 'Net spent'), '−₹1,500');
    expect(findCopy('Spends and refunds'), findsOneWidget);
    expect(findCopy('+₹1,500'), findsOneWidget);

    // Back on Home: the calendar cell and Saved this month.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(_ledger('Saved this month', '₹3,500'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Thursday 12 November, net minus ₹1,500 after refunds, saved ₹2,330',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is DayCell && w.cell.netSpent == const Paise(-150000),
      ),
      findsOneWidget,
      reason: 'the cell shows the net spent',
    );
    semantics.dispose();
  });

  testWidgets('TC-016-15 covered day money back shows no note', (tester) async {
    final store = storeFor(fixtureAPlusCover);
    await openDay(
      tester,
      fixtureAPlusCover,
      nov(11),
      store: store,
      size: _tall,
    );
    await tester.tap(find.text('Add spend'));
    await tester.pumpAndSettle();
    await typeInto(tester, amountInput, '200');
    await tester.tap(find.text('Money back / refund'));
    await tester.pumpAndSettle();
    await tapLabel(tester, 'Save');
    expect(find.text('Savings pot updated'), findsNothing);
    expect(find.text('Money back added'), findsOneWidget);
    expect(find.text('○ On budget'), findsWidgets);
    expect(findCopy('Covered from savings'), findsWidgets);
    expect(figure(tester, 'Covered from savings'), '₹100');

    // Delete the refund: the cut cover does not come back.
    await tester.tap(find.text('Refund').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('Savings pot updated'), findsNothing);
    expect(find.text('◆ Overspent ₹200'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(findCopy('₹370'), findsWidgets, reason: 'Home Overspent');
  });

  testWidgets('TC-016-18 several covers are cut in one sheet newest first', (
    tester,
  ) async {
    await _open(tester, p1b);
    await tapRow(tester, 'Refund');
    await tester.ensureVisible(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('Savings pot updated'), findsOneWidget);
    const ten =
        'Your savings pot went down, so the ₹1,000 that covered Tue, 10 Nov '
        'was taken back. 10 Nov is overspent again.';
    const nine =
        'Your savings pot went down, so the ₹1,000 that covered Mon, 9 Nov '
        'was taken back. 9 Nov is overspent again.';
    const eight =
        'Your savings pot went down, so ₹160 of the cover on Sun, 8 Nov was '
        'taken back.';
    for (final text in [ten, nine, eight]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(
      tester.getTopLeft(find.text(ten)).dy,
      lessThan(tester.getTopLeft(find.text(nine)).dy),
    );
    expect(
      tester.getTopLeft(find.text(nine)).dy,
      lessThan(tester.getTopLeft(find.text(eight)).dy),
    );
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('TC-016-26 refund larger than all spends makes spent negative', (
    tester,
  ) async {
    final empty = fixtureA.copyWith(name: 'A no spends', entries: const []);
    await _open(tester, empty);
    await _addMoneyBack(tester, '300');
    await tapTab(tester, 'Home');
    expect(_homeToday(), 'budget ₹830 · spent −₹300 · ₹1,130 left today');
    expect(findCopy('Includes ₹300 back from refunds'), findsOneWidget);
    expect(findCopy('−₹300'), findsWidgets);
    expect(findCopy('₹25,200'), findsOneWidget);
  });

  testWidgets('TC-016-28 forty paise back turns an exact day into saved by '
      'less than a rupee', (tester) async {
    final fixture = fixtureA.copyWith(
      name: 'A one spend',
      entries: [fixtureSpend(d(2026, 11, 7), 83000)],
    );
    final store = storeFor(fixture);
    await openDay(tester, fixture, nov(7), store: store, size: _tall);
    expect(find.text('○ On budget'), findsWidgets);
    await tester.tap(find.text('Add spend'));
    await tester.pumpAndSettle();
    await typeInto(tester, amountInput, '0.40');
    await tester.tap(find.text('Money back / refund'));
    await tester.pumpAndSettle();
    await tapLabel(tester, 'Save');
    expect(find.text('Money back added'), findsOneWidget);
    expect(findCopy('+₹0'), findsOneWidget, reason: 'listed in whole rupees');
    expect(find.text('● Saved less than ₹1'), findsWidgets);
  });

  testWidgets('TC-016-31 ten crore money back shows without breaking layout', (
    tester,
  ) async {
    for (final scale in [1.0, 2.0]) {
      await _open(tester, fixtureA, textScale: scale);
      await _addMoneyBack(tester, '100000000');
      await scrollToTop(tester);
      expect(tester.takeException(), isNull, reason: 'x$scale');
      expect(
        todayLineText(tester),
        'budget ₹830 · spent −₹9,99,99,580 · ₹10,00,00,410 left today',
      );
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('TC-016-37 a refund day joins the pot at midnight', (
    tester,
  ) async {
    final store = storeFor(fixtureAPlusRefund);
    final clock = MovableClock(d(2026, 11, 13))
      ..now = DateTime(2026, 11, 13, 23, 59);
    await pumpHome(tester, money: store, clock: clock);
    expect(_homeToday(), 'budget ₹830 · spent −₹80 · ₹910 left today');
    expect(_ledger('Saved this month', '₹2,000'), findsOneWidget);

    clock.now = DateTime(2026, 11, 14, 0, 1);
    sendToBackground(tester);
    bringToForeground(tester);
    await tester.pumpAndSettle();
    expect(_ledger('Saved this month', '₹2,910'), findsOneWidget);
    expect(_homeToday(), 'budget ₹830 · spent ₹0 · ₹830 left today');
  });

  testWidgets('TC-016-39 a past month refund cannot be edited', (tester) async {
    final october = fixtureO1.months.first.copyWith(
      entries: [
        ...fixtureO1.months.first.entries,
        fixtureMoneyIn(d(2026, 10, 12), 50000, note: 'Old return'),
      ],
    );
    final fixture = Phase3Fixture(
      name: 'O1 refund',
      today: fixtureO1.today,
      months: [october, fixtureO1.months.last],
    );
    await _open(tester, fixture);
    await tester.tap(find.text('Dates: This month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last month'));
    await tester.pumpAndSettle();
    await tapRow(tester, 'Old return');
    expect(find.text('Edit money back'), findsNothing);
    expect(find.text('Edit spend'), findsNothing);
    expect(find.text('Refund'), findsWidgets);
  });

  testWidgets('TC-016-40 a refund shows on the dashboard statement and list', (
    tester,
  ) async {
    final store = await _open(tester, fixtureA);
    await _addMoneyBack(tester, '500', 'Amazon return');
    await tester.ensureVisible(find.text('Type: All'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Type: All'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refunds'));
    await tester.pumpAndSettle();
    expect(findCopy('1 result · refunds ₹500'), findsOneWidget);

    await tapTab(tester, 'Dashboard');
    expect(find.bySemanticsLabel('Refunds, minus ₹500'), findsOneWidget);
    expect(findCopy('₹5,030'), findsWidgets, reason: 'Net spent');

    await pumpStatement(tester, fixtureA, store: store, size: _tall);
    expect(findCopy('Refunds'), findsWidgets);
    expect(findCopy('−₹500'), findsWidgets);
  });

  testWidgets('TC-016-45 pot sheet is the shared f009 sheet', (tester) async {
    final fixture = p1.copyWith(
      name: 'P1 with a noted 7 Nov',
      entries: [
        fixtureSpend(d(2026, 11, 7), 49000, note: 'Cab'),
        ...p1.current.entries.skip(1),
      ],
    );
    await _open(tester, fixture);
    // The refund delete: the newest cover is cut.
    await tapRow(tester, 'Refund');
    await tester.ensureVisible(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('Savings pot updated'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Raising a spend cuts the next cover: its own single sheet.
    await tapRow(tester, 'Cab');
    await typeInto(tester, amountInput, '830');
    await tapLabel(tester, 'Save changes');
    expect(find.text('Savings pot updated'), findsOneWidget);
    expect(
      find.text(
        'Your savings pot went down, so ₹340 of the cover on Tue, 10 Nov '
        'was taken back.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Savings pot updated'), findsNothing);
  });
}
