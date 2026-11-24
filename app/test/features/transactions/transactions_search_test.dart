import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_money_store.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/transactions_harness.dart';
import '../../support/find_copy.dart';

Future<void> _open(
  WidgetTester tester,
  Phase3Fixture fixture, {
  FakeMoneyStore? store,
}) async {
  await pumpTransactions(
    tester,
    money: store ?? storeFor(fixture),
    clock: TestClock(fixture.now),
    size: const Size(400, 1800),
  );
}

Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).first, text);
  // 250 ms debounce, then the list settles.
  await tester.pump(const Duration(milliseconds: 260));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TC-015-01 transactions tab shows search chips and category '
      'chips', (tester) async {
    await _open(tester, fixtureA);
    expect(find.text('Search notes or amounts'), findsOneWidget);
    for (final chip in ['Dates: This month', 'Category: All', 'Type: All']) {
      expect(find.text(chip), findsOneWidget);
    }
    expect(find.text('Clear all'), findsNothing);
    expect(find.text('Other'), findsWidgets);
    expect(find.text('Thu, 5 Nov'), findsOneWidget);
    expect(find.text('Thu, 12 Nov'), findsNothing);
  });

  testWidgets('TC-015-03 text search finds lunch in any case', (tester) async {
    await _open(tester, fixtureA);
    for (final query in ['lunch', 'LUNCH', 'lun']) {
      await _search(tester, query);
      expect(findCopy('2 results · spent ₹670'), findsOneWidget, reason: query);
      expect(find.text('Lunch'), findsNWidgets(2));
      expect(find.text('Phone bill'), findsNothing);
    }
  });

  testWidgets('TC-015-19 filtered day totals add only the shown entries', (
    tester,
  ) async {
    await _open(tester, fixtureA);
    await _search(tester, 'lunch');
    expect(findCopy('₹250 shown'), findsOneWidget);
    expect(findCopy('₹420 shown'), findsOneWidget);
    await _search(tester, '');
    expect(find.textContaining('shown'), findsNothing);
    expect(findCopy('₹620'), findsOneWidget);
  });

  testWidgets('TC-015-09 no results offers clear search', (tester) async {
    await _open(tester, fixtureA);
    await _search(tester, 'taxi');
    expect(find.text('0 results'), findsOneWidget);
    expect(find.text('No spends match "taxi".'), findsOneWidget);
    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('No spends match "taxi".'), findsNothing);
    expect(find.text('Clear all'), findsNothing);
    expect(find.text('Phone bill'), findsOneWidget);
  });

  testWidgets('TC-015-40 spaces only is an empty search', (tester) async {
    await _open(tester, fixtureA);
    await _search(tester, '   ');
    expect(find.text('Clear all'), findsNothing);
    expect(find.text('Phone bill'), findsOneWidget);
  });
}
