import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/transactions_harness.dart';
import '../../support/find_copy.dart';

Future<void> _openDelete(WidgetTester tester, String rowText) async {
  await tester.tap(find.text(rowText));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Delete'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TC-009-12 deleting asks first and then removes the spend', (
    tester,
  ) async {
    final store = e2Store();
    addSpendTo(store, d(2026, 11, 9), 25000, note: 'Lunch');
    await pumpTransactions(tester, money: store);
    await _openDelete(tester, 'Lunch');
    expect(find.text('Delete this spend?'), findsOneWidget);
    expect(
      find.text("₹250 on Mon, 9 Nov. This can't be undone."),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this spend?'), findsNothing);
    expect(storedSpends(store), hasLength(1));
    expect(find.text('Edit spend'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(storedSpends(store), isEmpty);
    expect(find.text('Lunch'), findsNothing);
    expect(find.text('Spend deleted'), findsOneWidget);
    expect(todayLineText(tester), 'budget ₹830 · spent ₹0 · ₹830 left today');
  });

  testWidgets('TC-009-36 deleting the last spend of a day removes its '
      'heading', (tester) async {
    final store = e2Store();
    addSpendTo(store, d(2026, 11, 8), 25000, note: 'Dinner');
    addSpendTo(store, d(2026, 11, 9), 10000, note: 'Tea');
    await pumpTransactions(tester, money: store);
    expect(find.text('Yesterday'), findsOneWidget);
    await _openDelete(tester, 'Dinner');
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('Yesterday'), findsNothing);
    expect(findCopy('₹100'), findsNWidgets(2));
  });

  testWidgets('TC-009-37 back on the delete dialog keeps the spend', (
    tester,
  ) async {
    final store = e2Store();
    addSpendTo(store, d(2026, 11, 9), 25000, note: 'Lunch');
    await pumpTransactions(tester, money: store);
    await _openDelete(tester, 'Lunch');
    expect(find.text('Delete this spend?'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Delete this spend?'), findsNothing);
    expect(storedSpends(store), hasLength(1));
    expect(find.byType(TextField), findsWidgets, reason: 'still editing');
  });
}
