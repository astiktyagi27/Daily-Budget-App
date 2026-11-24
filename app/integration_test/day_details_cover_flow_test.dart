import 'dart:io';

import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/home/calendar/day_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/data/repositories/repository_setup.dart';
import '../test/helpers/phase3_fixtures.dart';
import 'real_app.dart';

/// F-012 TC-012-08, -37, -39 on the real Drift file: cover 11 Nov, Undo,
/// cover again, Remove, restart. Runs on the emulator (`flutter test
/// integration_test/day_details_cover_flow_test.dart -d DEVICE`).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TC-012-08 cover undo and remove survive a restart', (
    tester,
  ) async {
    final folder = Directory.systemTemp.createTempSync('tc012_flow');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/budget.sqlite');

    // A13: the E2 month with the example A spends, today Fri 13 Nov.
    final seed = Repos(openOnFile(file));
    final month = await seed.months.confirmMonth(e2NewMonth());
    for (final entry in fixtureA.current.entries) {
      await seed.spends.add(
        month.id,
        fields(entry.date, entry.paise, entry.note),
        today: fixtureA.today,
        now: entry.createdAt,
      );
    }
    await seed.db.close();

    final store = await onboardedPreferences();
    final now = DateTime(2026, 11, 13, 14);
    await launchOnFile(tester, file, store, now);

    Future<void> openEleventh() async {
      final cell = find.byWidgetPredicate(
        (w) => w is DayCell && w.cell.date == CalendarDate(2026, 11, 11),
      );
      await tester.ensureVisible(cell);
      await tester.pumpAndSettle();
      await tester.tap(cell);
      await tester.pumpAndSettle();
    }

    Future<int> storedCovers() async {
      final repos = Repos(openOnFile(file));
      final rows = await repos.db
          .customSelect('SELECT amount_paise FROM savings_moves')
          .get();
      await repos.db.close();
      return rows.length;
    }

    await openEleventh();
    expect(find.text('Wed, 11 Nov'), findsOneWidget);
    await tester.ensureVisible(find.text('Cover with savings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cover with savings'));
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.tap(find.text('Cover'));
    await tester.pumpAndSettle();
    expect(find.text('₹300 covered from your savings'), findsOneWidget);
    expect(find.text('○ On budget'), findsWidgets);

    // Undo within the snackbar's time.
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Cover undone'), findsOneWidget);
    expect(find.text('◆ Overspent ₹300'), findsWidgets);

    // Cover again, then restart the app: the cover is still there.
    await tester.ensureVisible(find.text('Cover with savings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cover with savings'));
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.tap(find.text('Cover'));
    await tester.pumpAndSettle();
    await launchOnFile(tester, file, store, now);
    await openEleventh();
    expect(find.text('○ On budget'), findsWidgets);
    expect(find.text('Covered ₹300 from savings.'), findsOneWidget);

    // Remove: the cover is gone from the file.
    await tester.ensureVisible(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove cover'));
    await tester.pumpAndSettle();
    expect(find.text('◆ Overspent ₹300'), findsWidgets);
    expect(await storedCovers(), 0);
  });
}
