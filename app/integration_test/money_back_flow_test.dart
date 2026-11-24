import 'dart:io';

import 'package:daily_budget/features/transactions/today_line_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/data/repositories/repository_setup.dart';
import '../test/helpers/drift_fixture_seed.dart';
import '../test/helpers/phase3_fixtures.dart';
import '../test/helpers/shell.dart';
import '../test/helpers/transactions_harness.dart';
import 'real_app.dart';

Future<void> _expectLine(WidgetTester tester, String expected) async {
  String? line() => find.byKey(TodayLineView.lineKey).evaluate().isEmpty
      ? null
      : todayLineText(tester);

  // After opening a row the list is scrolled down and the Today line is not
  // built; the app returns to the same scroll position (B-003: the line was
  // there all along, the script looked at the wrong place).
  await tester.pumpAndSettle();
  if (line() == null) {
    await tester.scrollUntilVisible(
      find.byKey(TodayLineView.lineKey),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }
  await pumpUntil(
    tester,
    () => line() == expected,
    reason: 'Today line "$expected" (now "${line()}")',
  );
  expect(todayLineText(tester), expected);
}

/// The database answers a moment after the app starts, so the tab bar may
/// not be built yet when `launchOnFile` returns: wait for it, then switch.
Future<void> _openTransactions(WidgetTester tester) async {
  await pumpUntil(
    tester,
    () => navBar.evaluate().isNotEmpty,
    reason: 'the bottom navigation bar',
  );
  await tapTab(tester, 'Transactions');
}

Future<void> _toggle(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Money back / refund'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Money back / refund'));
  await tester.pumpAndSettle();
}

Future<void> _openRow(WidgetTester tester, String note) async {
  await tester.scrollUntilVisible(
    find.text(note),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(note).first);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TC-016-34 add edit and delete money back on the device', (
    tester,
  ) async {
    final folder = Directory.systemTemp.createTempSync('tc016_34');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/budget.sqlite');

    // Example A (13 Nov 2026) is stored through the repositories.
    final seed = Repos(openOnFile(file));
    await seedDriftFixture(seed, fixtureA);
    await seed.db.close();
    final now = fixtureA.now;
    await launchOnFile(tester, file, await onboardedPreferences(), now);
    await _openTransactions(tester);
    await _expectLine(tester, 'budget ₹830 · spent ₹420 · ₹410 left today');

    // Add ₹500 "Amazon return" as money back.
    await tester.tap(addSpendButton);
    await tester.pumpAndSettle();
    await typeInto(tester, amountInput, '500');
    await typeInto(tester, noteInput, 'Amazon return');
    await _toggle(tester);
    await tapLabel(tester, 'Save');
    await _expectLine(tester, 'budget ₹830 · spent −₹80 · ₹910 left today');

    // The refund survives a restart.
    await launchOnFile(tester, file, await onboardedPreferences(), now);
    await _openTransactions(tester);
    await _expectLine(tester, 'budget ₹830 · spent −₹80 · ₹910 left today');

    // Edit to ₹300.
    await _openRow(tester, 'Amazon return');
    expect(find.text('Edit money back'), findsOneWidget);
    await typeInto(tester, amountInput, '300');
    await tapLabel(tester, 'Save changes');
    await _expectLine(tester, 'budget ₹830 · spent ₹120 · ₹710 left today');

    // Convert to a spend, then back.
    await _openRow(tester, 'Amazon return');
    await _toggle(tester);
    await tapLabel(tester, 'Save changes');
    await _expectLine(tester, 'budget ₹830 · spent ₹720 · ₹110 left today');
    await _openRow(tester, 'Amazon return');
    await _toggle(tester);
    await tapLabel(tester, 'Save changes');
    await _expectLine(tester, 'budget ₹830 · spent ₹120 · ₹710 left today');

    // Delete it.
    await _openRow(tester, 'Amazon return');
    await tester.ensureVisible(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this money back?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    await _expectLine(tester, 'budget ₹830 · spent ₹420 · ₹410 left today');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
