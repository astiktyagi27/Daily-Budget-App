import 'dart:io';

import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/data/repositories/repository_setup.dart';
import '../test/domain/budget/fixtures.dart';
import '../test/support/find_copy.dart';
import 'real_app.dart';

/// Pumps real frames until [done]; fails after five seconds.
Future<void> _until(
  WidgetTester tester,
  Stopwatch watch,
  bool Function() done,
) async {
  while (!done()) {
    if (watch.elapsedMilliseconds > 5000) {
      fail('The final figures did not appear within 5 s.');
    }
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TC-010-43 home shows final figures within a second with 500 '
      'spends', (tester) async {
    final folder = Directory.systemTemp.createTempSync('tc010_43');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/budget.sqlite');

    // E2 and 500 spends over 5 - 13 Nov (nine days), 1,000 + i paise each:
    // 5,00,000 + 1,24,750 = 6,24,750 paise in all.
    final seed = Repos(openOnFile(file));
    final month = await seed.months.confirmMonth(e2NewMonth());
    await seed.db.batch((batch) {
      batch.insertAll(seed.db.transactions, [
        for (var i = 0; i < 500; i++)
          TransactionsCompanion.insert(
            monthId: month.id,
            day: d(2026, 11, 5).addDays(i % 9),
            amountPaise: Paise(1000 + i),
            note: Value('spend $i'),
            createdAt: at(d(2026, 11, 13), 8) + i,
            editedAt: at(d(2026, 11, 13), 8) + i,
          ),
      ]);
    });
    await seed.db.close();

    // Left = 24,90,000 - 6,24,750 = 18,65,250 paise, shown as ₹18,652;
    // Spent so far shows ₹6,247.
    //
    // D-094 / D-098: the clock starts before `pumpWidget` (app start and
    // database open are inside the time) and stops, in 16 ms frames and with
    // no closing `pumpAndSettle`, when both figures are on screen. Profile
    // mode, from `app/`: `flutter drive --profile -d emulator-5554
    // --driver=test_driver/integration_test.dart
    // --target=integration_test/home_500_test.dart`
    final store = await onboardedPreferences();
    var worst = 0;
    for (var run = 0; run < 5; run++) {
      final watch = Stopwatch()..start();
      await launchOnFile(
        tester,
        file,
        store,
        DateTime(2026, 11, 13, 10),
        settle: false,
      );
      await _until(
        tester,
        watch,
        () =>
            find.text('₹18,652').evaluate().isNotEmpty &&
            find.text('₹6,247').evaluate().isNotEmpty,
      );
      final shown = watch.elapsedMilliseconds;
      // The Today card may still be loading when the two figures show; it is
      // not part of the timed figures, so wait for it outside the clock.
      await pumpUntil(
        tester,
        () => findCopy('Today · Fri, 13 Nov').evaluate().isNotEmpty,
        reason: 'the Today card',
      );
      debugPrint('TC-010-43 run $run: final figures after $shown ms');
      if (shown > worst) worst = shown;
      expect(findCopy('Today · Fri, 13 Nov'), findsOneWidget);
      expect(find.text('₹6,247'), findsOneWidget);
    }
    debugPrint('TC-010-43 worst of 5: $worst ms (limit 1000)');
    expect(worst, lessThan(1000));
  });
}
