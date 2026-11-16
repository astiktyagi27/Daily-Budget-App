import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/setup_harness.dart';
import '../test/helpers/shell.dart';
import '../test/support/find_copy.dart';
import '../test/support/p1_screens.dart';
import 'real_app.dart';
import 'real_preferences.dart';

/// 5 Nov 2026, the first day of month E2 (salary day 5th).
final _fifthNov = DateTime(2026, 11, 5, 10);

const _e2Home = '5 Nov – 4 Dec · ₹830 a day';

Future<void> _enterE2AndStart(WidgetTester tester) async {
  await pumpUntil(
    tester,
    () => find.text('Set up your month').evaluate().isNotEmpty,
    reason: 'Home offers Set up your month',
  );
  await tapText(tester, 'Set up your month');
  await pickSalaryDay(tester, 5);
  await enterE2(tester);
  // Done on the keyboard: it closes and Start my month comes back in the dock
  // (month-setup §6).
  FocusManager.instance.primaryFocus?.unfocus();
  await pumpUntil(
    tester,
    () => find.text('Start my month').evaluate().isNotEmpty,
    reason: 'Start my month is back once the keyboard is closed',
  );
  await tapText(tester, 'Start my month');
  await pumpUntil(
    tester,
    () => findCopy(_e2Home).evaluate().isNotEmpty,
    reason: 'Home shows $_e2Home',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TC-008-54 month setup flow from a fresh install', (
    tester,
  ) async {
    await clearRealPreferences();
    addTearDown(clearRealPreferences);
    final folder = Directory.systemTemp.createTempSync('tc008_54');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/budget.sqlite');

    // A fresh install: the tour, then the two explainers, then Home.
    final store = await openRealStore();
    await launchOnFile(tester, file, store, _fifthNov);
    await tapOnboardingButton(tester, 'Skip');
    await tapOnboardingButton(tester, 'Not now');
    await tapOnboardingButton(tester, 'Not now');
    await tapOnboardingButton(tester, 'I understand');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(navBar, findsOneWidget);

    await _enterE2AndStart(tester);
    expect(findCopy(_e2Home), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('TC-008-18 confirmed month is shown again after restart', (
    tester,
  ) async {
    final folder = Directory.systemTemp.createTempSync('tc008_18');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/budget.sqlite');

    await launchOnFile(tester, file, await onboardedPreferences(), _fifthNov);
    await _enterE2AndStart(tester);

    // Recreate the app on the same database: only the file survives.
    await launchOnFile(tester, file, await onboardedPreferences(), _fifthNov);
    await pumpUntil(
      tester,
      () => findCopy(_e2Home).evaluate().isNotEmpty,
      reason: 'Home shows $_e2Home after the restart',
    );

    await tapText(tester, 'Edit this month');
    expect(typed(tester, amountInput('Monthly salary')), '40000');
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
  }, timeout: const Timeout(Duration(minutes: 5)));
}
