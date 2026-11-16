import 'dart:io';

import 'package:daily_budget/features/transactions/today_line_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/data/repositories/repository_setup.dart';
import '../test/helpers/shell.dart';
import '../test/helpers/transactions_harness.dart';
import 'real_app.dart';

/// Mon 9 Nov 2026, the F-009 worked example's day.
final _ninthNov = DateTime(2026, 11, 9, 10);

Future<void> _expectLine(WidgetTester tester, String expected) async {
  String? line() => find.byKey(TodayLineView.lineKey).evaluate().isEmpty
      ? null
      : todayLineText(tester);

  await pumpUntil(
    tester,
    () => line() == expected,
    reason: 'Today line "$expected" (now "${line()}")',
  );
  expect(todayLineText(tester), expected);
}

Future<void> _addSpend(
  WidgetTester tester,
  String amount, [
  String? note,
]) async {
  await tester.tap(addSpendButton);
  await tester.pumpAndSettle();
  await typeInto(tester, amountInput, amount);
  if (note != null) await typeInto(tester, noteInput, note);
  await tapLabel(tester, 'Save');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TC-009-45 add edit and delete spends on the device', (
    tester,
  ) async {
    final folder = Directory.systemTemp.createTempSync('tc009_45');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/budget.sqlite');

    // E2 confirmed on 5 Nov (F-008), then the app opens on 9 Nov.
    final seed = Repos(openOnFile(file));
    await seed.months.confirmMonth(e2NewMonth());
    await seed.db.close();
    await launchOnFile(tester, file, await onboardedPreferences(), _ninthNov);
    await tapTab(tester, 'Transactions');

    await _expectLine(tester, 'budget ₹830 · spent ₹0 · ₹830 left today');
    await _addSpend(tester, '250', 'Lunch');
    await _expectLine(tester, 'budget ₹830 · spent ₹250 · ₹580 left today');
    await _addSpend(tester, '400', 'Groceries');
    await _expectLine(tester, 'budget ₹830 · spent ₹650 · ₹180 left today');
    await _addSpend(tester, '300.50');
    await _expectLine(tester, 'budget ₹830 · spent ₹950 · overspent ₹120');

    // Step 4: edit Groceries from ₹400 to ₹270.
    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();
    await typeInto(tester, amountInput, '270');
    await tapLabel(tester, 'Save changes');
    await _expectLine(tester, 'budget ₹830 · spent ₹820 · ₹9 left today');

    // Step 5: delete the ₹300.50 spend (it has no note).
    await tester.tap(find.text('No note'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this spend?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    await _expectLine(tester, 'budget ₹830 · spent ₹520 · ₹310 left today');

    // After a restart on the same file the line is the same.
    await launchOnFile(tester, file, await onboardedPreferences(), _ninthNov);
    await tapTab(tester, 'Transactions');
    await _expectLine(tester, 'budget ₹830 · spent ₹520 · ₹310 left today');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
