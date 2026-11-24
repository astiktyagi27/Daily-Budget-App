import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/bundled_fonts.dart';
import '../../helpers/day_details_harness.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/transactions_harness.dart' show addCoverTo;
import '../../support/find_copy.dart';

// F-012 §2.5, AC-22: Remove a cover.

List<Cover> _covers(FakeMoneyStore store, [int index = -1]) =>
    store.coversByMonth[store
        .months[index < 0 ? store.months.length - 1 : index]
        .id] ??
    <Cover>[];

FakeMoneyStore _twoMoves() {
  final store = storeFor(a13);
  addCoverTo(store, nov(11), 10000);
  addCoverTo(store, nov(11), 20000);
  return store;
}

Future<void> _openRemove(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Remove'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Remove'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadBundledFonts);

  testWidgets('TC-012-39 remove cover deletes every move of the day', (
    tester,
  ) async {
    final store = _twoMoves();
    await openDay(tester, a13, nov(11), store: store);
    expect(figure(tester, 'Covered from savings'), '₹300');
    await _openRemove(tester);
    expect(find.text('Remove this cover?'), findsOneWidget);
    expect(
      findCopy(
        '₹300 goes back to your savings pot, and Wed, 11 Nov is overspent '
        '₹300 again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Remove cover'), findsOneWidget);
    expect(find.text('Keep it'), findsOneWidget);
    // The destructive button comes first.
    expect(
      tester.getTopLeft(find.text('Remove cover')).dy,
      lessThan(tester.getTopLeft(find.text('Keep it')).dy),
    );
    await tester.tap(find.text('Remove cover'));
    await tester.pumpAndSettle();
    expect(_covers(store), isEmpty);
    expect(find.text('◆ Overspent ₹300'), findsWidgets);
    expect(find.text('Cover removed'), findsOneWidget);
    expect(find.text('Savings pot updated'), findsNothing);
    expect(find.textContaining('₹2,000'), findsWidgets, reason: 'the pot');
  });

  testWidgets('TC-012-40 keep it back and scrim leave the cover', (
    tester,
  ) async {
    final store = _twoMoves();
    await openDay(tester, a13, nov(11), store: store);
    await _openRemove(tester);
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(find.text('Remove this cover?'), findsNothing);
    await _openRemove(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Remove this cover?'), findsNothing);
    await _openRemove(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tapAt(const Offset(180, 20));
    await tester.pumpAndSettle();
    expect(find.text('Remove this cover?'), findsNothing);
    expect(_covers(store), hasLength(2));
    expect(figure(tester, 'Covered from savings'), '₹300');
  });

  testWidgets('TC-012-41 remove is hidden on past months and zero covers', (
    tester,
  ) async {
    // (a) A cover on an October day of OCT-NOV.
    final store = storeFor(octNov);
    addCoverTo(store, CalendarDate(2026, 10, 6), 10000);
    await openDay(
      tester,
      octNov,
      CalendarDate(2026, 10, 6),
      store: store,
      monthIndex: 0,
    );
    expect(find.text('Remove'), findsNothing);
    expect(find.text('Cover with savings'), findsNothing);
    // (b) W3: the 5 Nov spend raised so the cover on 6 Nov is cut to zero.
    await tester.pumpWidget(const SizedBox());
    final w3Store = storeFor(w3);
    final month = w3Store.months.last.id;
    final list = w3Store.spendsByMonth[month]!;
    final index = list.indexWhere((s) => s.spend.date == nov(5));
    final old = list[index];
    list[index] = StoredSpend(
      spend: Spend(
        id: old.spend.id,
        date: old.spend.date,
        amount: const Paise(83000),
        createdAt: old.spend.createdAt,
      ),
    );
    w3Store.reconcile(month, nov(8));
    await openDay(tester, w3, nov(6), store: w3Store);
    expect(figure(tester, 'Covered from savings'), isNull);
    expect(find.text('Remove'), findsNothing);
    expect(find.text('◆ Overspent ₹170'), findsWidgets);
  });

  testWidgets('TC-012-42 failed remove keeps both moves', (tester) async {
    final store = _twoMoves();
    await openDay(tester, a13, nov(11), store: store);
    await _openRemove(tester);
    store.failNextWrite = true;
    await tester.tap(find.text('Remove cover'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't save. Please try again."), findsOneWidget);
    expect(_covers(store), hasLength(2));
    expect(figure(tester, 'Covered from savings'), '₹300');
  });
}
