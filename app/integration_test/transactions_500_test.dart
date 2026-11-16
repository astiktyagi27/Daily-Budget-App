import 'dart:io';

import 'package:daily_budget/app.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/preferences_providers.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/data/database/database_connection.dart';
import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/data/repositories/repository_setup.dart';
import '../test/domain/budget/fixtures.dart';
import '../test/helpers/pump_app.dart';
import '../test/support/find_copy.dart';

/// The real `drift_flutter` opener (background isolate, platform plugins)
/// pointed at [file].
AppDatabase _open(File file) => openAppDatabase(
  executor: openDatabaseConnection(
    databasePath: () async => file.path,
    tempDirectoryPath: () async => file.parent.path,
  ),
);

/// The whole app on the real database file, as after a process restart: a
/// new tree, a new `ProviderScope`, only the file survives. Today is
/// 4 Dec 2026, the last day of E2.
Future<void> _launch(WidgetTester tester, File file) async {
  await tester.pumpWidget(const SizedBox());
  final preferences = InMemoryPreferencesStore.allowing(
    PreferenceKeys.allowList,
  );
  for (final id in HintId.values) {
    await preferences.writeBool(PreferenceKeys.hintSeen(id), value: true);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesStoreProvider.overrideWithValue(OnboardedStore(preferences)),
        databaseOpenerProvider.overrideWithValue(() => _open(file)),
        clockProvider.overrideWithValue(() => DateTime(2026, 12, 4, 10)),
      ],
      child: const DailyBudgetApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'TC-009-19 five hundred spends are listed quickly after restart',
    (tester) async {
      final folder = Directory.systemTemp.createTempSync('tc009_19');
      addTearDown(() => folder.deleteSync(recursive: true));
      final file = File('${folder.path}/budget.sqlite');

      // Seed E2 and 500 spends over 5 Nov - 4 Dec, then close the file.
      final seed = Repos(_open(file));
      final month = await seed.months.confirmMonth(e2NewMonth());
      final expectedDayTotals = <int, int>{};
      await seed.db.batch((batch) {
        batch.insertAll(seed.db.transactions, [
          for (var i = 0; i < 500; i++)
            TransactionsCompanion.insert(
              monthId: month.id,
              day: d(2026, 11, 5).addDays(i % 30),
              amountPaise: Paise(100 + i),
              note: Value('spend $i'),
              createdAt: at(d(2026, 12, 4), 8) + i,
              editedAt: at(d(2026, 12, 4), 8) + i,
            ),
        ]);
      });
      for (var i = 0; i < 500; i++) {
        expectedDayTotals.update(
          i % 30,
          (total) => total + 100 + i,
          ifAbsent: () => 100 + i,
        );
      }
      await seed.db.close();

      var worstMilliseconds = 0;
      for (var run = 0; run < 5; run++) {
        await _launch(tester, file);
        final watch = Stopwatch()..start();
        await tester.tap(find.text('Transactions').last);
        // Real frames until the first day with its rows is on screen.
        while (find.text('Today').evaluate().length < 2 &&
            watch.elapsedMilliseconds < 5000) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        final shown = watch.elapsedMilliseconds;
        debugPrint('TC-009-19 run $run: first rows after $shown ms');
        expect(find.text('Today'), findsWidgets);
        if (shown > worstMilliseconds) worstMilliseconds = shown;
      }
      debugPrint('TC-009-19 worst of 5: $worstMilliseconds ms (limit 1000)');
      expect(worstMilliseconds, lessThan(1000));

      // Scroll to the oldest day: every one of the 500 rows is reached.
      final seen = <String>{};
      final scrollable = find.byType(Scrollable).first;
      final position = tester.state<ScrollableState>(scrollable).position;
      void collect() {
        for (final element in find.textContaining('spend ').evaluate()) {
          seen.add((element.widget as Text).data!);
        }
      }

      collect();
      var steps = 0;
      while (position.pixels < position.maxScrollExtent && steps++ < 400) {
        await tester.drag(scrollable, const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 50));
        collect();
      }
      await tester.pumpAndSettle();
      collect();
      expect(find.text('Thu, 5 Nov'), findsOneWidget);
      expect(seen, hasLength(500));
      // The oldest day's total is the exact sum of its rows, in whole rupees.
      expect(
        findCopy(formatRupees(Paise(expectedDayTotals[0]!))),
        findsWidgets,
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
