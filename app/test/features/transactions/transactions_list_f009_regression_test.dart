// F-015 TC-015-02: the F-009 add, edit and delete flows still work on the
// new list (rows with a category chip, search and chips above). The whole
// F-009 test files are re-run with this one by `flutter test`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/transactions_harness.dart';
import '../../support/find_copy.dart';

void main() {
  testWidgets('TC-015-02 f009 flows still work in the new list', (
    tester,
  ) async {
    final store = storeFor(fixtureA);
    await pumpTransactions(
      tester,
      money: store,
      clock: TestClock(fixtureA.now),
      size: const Size(400, 1800),
    );
    expect(todayLineText(tester), 'budget ₹830 · spent ₹420 · ₹410 left today');

    // Add.
    await tester.tap(addSpendButton);
    await tester.pumpAndSettle();
    await typeInto(tester, amountInput, '100');
    await typeInto(tester, noteInput, 'Tea');
    await tapLabel(tester, 'Save');
    expect(find.text('Spend added'), findsOneWidget);
    expect(find.text('Tea'), findsOneWidget);
    expect(todayLineText(tester), 'budget ₹830 · spent ₹520 · ₹310 left today');

    // Edit.
    await tester.tap(find.text('Tea'));
    await tester.pumpAndSettle();
    expect(find.text('Edit spend'), findsOneWidget);
    await typeInto(tester, amountInput, '150');
    await tapLabel(tester, 'Save changes');
    expect(find.text('Spend updated'), findsOneWidget);
    expect(todayLineText(tester), 'budget ₹830 · spent ₹570 · ₹260 left today');
    expect(findCopy('₹570'), findsWidgets, reason: 'the day total');

    // Delete, after the question.
    await tester.tap(find.text('Tea'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this spend?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('Spend deleted'), findsOneWidget);
    expect(find.text('Tea'), findsNothing);
    expect(todayLineText(tester), 'budget ₹830 · spent ₹420 · ₹410 left today');
    expect(storedSpends(store), hasLength(9));
  });
}
