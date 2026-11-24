import 'dart:io';

import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/home/calendar/day_cell.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/data/repositories/repository_setup.dart';
import '../test/domain/budget/fixtures.dart';
import 'real_app.dart';

/// F-011 TC-011-37 (AC-18): 500 spends over October and November; the grid
/// with its final cells appears within 500 ms of launch, and so does a month
/// change with ‹. The worst of 5 counts. Runs on the emulator.
///
/// D-094: the clock starts before `pumpWidget` (app start and database open
/// are inside the time) and stops, in 16 ms frames and with no closing
/// `pumpAndSettle`, when the 30 final cells are on screen with the amounts of
/// the seed. Measured in profile mode, from `app/`:
/// `flutter drive --profile -d emulator-5554
///  --driver=test_driver/integration_test.dart
///  --target=integration_test/calendar_500_test.dart`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TC-011-37 five hundred spends: grid and month change within '
      '500 ms', (tester) async {
    final folder = Directory.systemTemp.createTempSync('tc011_37');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/budget.sqlite');

    final seed = Repos(openOnFile(file));
    final october = await seed.months.confirmMonth(
      NewMonth(
        month: oct2026,
        firstBudgetedDay: d(2026, 10, 5),
        firstPeriod: period(d(2026, 10, 5), e2Values()),
        confirmedAt: at(d(2026, 10, 5), 8),
      ),
    );
    final november = await seed.months.confirmMonth(e2NewMonth());
    for (final (month, first) in [
      (october.id, d(2026, 10, 5)),
      (november.id, d(2026, 11, 5)),
    ]) {
      await seed.db.batch((batch) {
        batch.insertAll(seed.db.transactions, [
          for (var i = 0; i < 250; i++)
            TransactionsCompanion.insert(
              monthId: month,
              day: first.addDays(i % 30),
              amountPaise: Paise(100 + i),
              note: Value('spend $i'),
              createdAt: at(first, 8) + i,
              editedAt: at(first, 8) + i,
            ),
        ]);
      });
    }
    await seed.db.close();

    // Today is 13 Nov: the cells of 5 - 13 Nov show what was spent. Spend i of
    // November falls on day i % 30 (0 = 5 Nov) and costs 100 + i paise; the
    // cell shows whole rupees. Written here so the expected text never comes
    // from the app.
    int daySum(int day) =>
        [for (var i = day; i < 250; i += 30) 100 + i].reduce((a, b) => a + b);
    final seedSums = <CalendarDate, String>{
      for (var day = 0; day < 9; day++)
        d(2026, 11, 5).addDays(day): '₹${daySum(day) ~/ 100}',
    };
    bool finalCellsShown() {
      final budgetCells = find
          .byType(DayCell)
          .evaluate()
          .where((e) => (e.widget as DayCell).cell.kind != CellKind.outside);
      if (budgetCells.length != 30) return false;
      return seedSums.entries.every(
        (e) => find
            .descendant(
              of: find.byKey(ValueKey(e.key.dayNumber)),
              matching: find.text(e.value),
            )
            .evaluate()
            .isNotEmpty,
      );
    }

    final store = await onboardedPreferences();
    var worstGrid = 0;
    var worstChange = 0;
    for (var run = 0; run < 5; run++) {
      final launched = Stopwatch()..start();
      await launchOnFile(
        tester,
        file,
        store,
        DateTime(2026, 11, 13, 10),
        settle: false,
      );
      while (!finalCellsShown()) {
        if (launched.elapsedMilliseconds > 5000) {
          fail('The 30 final cells did not appear within 5 s (run $run).');
        }
        await tester.pump(const Duration(milliseconds: 16));
      }
      final grid = launched.elapsedMilliseconds;
      debugPrint(
        'TC-011-37 run $run: grid after $grid ms (16 ms frames, '
        'from launch)',
      );
      if (grid > worstGrid) worstGrid = grid;
      await tester.pumpAndSettle();

      final changed = Stopwatch()..start();
      // Scroll the switcher to the upper third of the screen. A plain
      // ensureVisible stops at the screen edge, where the bottom navigation
      // bar covers the button and the tap would hit a tab instead.
      await Scrollable.ensureVisible(
        tester.element(find.byTooltip('Previous month')),
        alignment: 0.2,
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Previous month'));
      while (find.textContaining('5 Oct').evaluate().isEmpty &&
          changed.elapsedMilliseconds < 5000) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final change = changed.elapsedMilliseconds;
      debugPrint('TC-011-37 run $run: month change after $change ms');
      if (change > worstChange) worstChange = change;
    }
    debugPrint('TC-011-37 worst grid $worstGrid ms, change $worstChange ms');
    expect(worstChange, lessThan(500));
    expect(worstGrid, lessThan(500));
  });
}
