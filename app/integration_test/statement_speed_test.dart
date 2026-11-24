import 'dart:io';

import 'package:daily_budget/app.dart';
import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/preferences_providers.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/data/database/database_connection.dart';
import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:daily_budget/features/statement/month_statement_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/data/repositories/repository_setup.dart';
import '../test/domain/budget/fixtures.dart';
import '../test/helpers/pump_app.dart';
import 'real_app.dart' show speedLimitMs;

/// The real `drift_flutter` opener pointed at [file].
AppDatabase _open(File file) => openAppDatabase(
  executor: openDatabaseConnection(
    databasePath: () async => file.path,
    tempDirectoryPath: () async => file.parent.path,
  ),
);

/// The whole app on the real database file, as after a process restart.
/// Today is 5 Dec 2026, after the month ended.
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
        clockProvider.overrideWithValue(() => DateTime(2026, 12, 5, 10)),
      ],
      child: const DailyBudgetApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps real frames until [done] or five seconds; returns the milliseconds.
Future<int> _until(WidgetTester tester, bool Function() done) async {
  final watch = Stopwatch()..start();
  while (!done() && watch.elapsedMilliseconds < 5000) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  return watch.elapsedMilliseconds;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'TC-014-30 statement with ten periods and five hundred spends is fast',
    (tester) async {
      final folder = Directory.systemTemp.createTempSync('tc014_30');
      addTearDown(() => folder.deleteSync(recursive: true));
      final file = File('${folder.path}/budget.sqlite');

      // E2 (5 Nov - 4 Dec) with nine salary changes: ten periods.
      final seed = Repos(_open(file));
      final month = await seed.months.confirmMonth(e2NewMonth());
      for (var i = 1; i <= 9; i++) {
        await seed.months.addPeriod(
          month.id,
          period(
            d(2026, 11, 5).addDays(i * 3),
            e2Values(salary: 4000000 + i * 10000),
            changedAt: at(d(2026, 11, 5).addDays(i * 3), 9),
          ),
        );
      }
      await seed.db.batch((batch) {
        batch.insertAll(seed.db.transactions, [
          for (var i = 0; i < 500; i++)
            TransactionsCompanion.insert(
              monthId: month.id,
              day: d(2026, 11, 5).addDays(i % 30),
              amountPaise: Paise(1000 + i),
              note: Value('spend $i'),
              createdAt: at(d(2026, 12, 4), 8) + i,
              editedAt: at(d(2026, 12, 4), 8) + i,
            ),
        ]);
      });
      await seed.db.close();

      var worst = 0;
      for (var run = 0; run < 5; run++) {
        await _launch(tester, file);
        final host = tester.element(find.byType(Scaffold).first);
        final watch = Stopwatch()..start();
        // ignore: unawaited_futures, the route is pushed and awaited by pumps
        MonthStatementScreen.open(host, month.id);
        final shown = await _until(
          tester,
          () => find.text('Period 10 of 10').evaluate().isNotEmpty,
        );
        watch.stop();
        debugPrint('TC-014-30 run $run: all periods built after $shown ms');
        if (shown > worst) worst = shown;
      }
      // D-100: the 1,000 ms limit applies in profile mode only.
      final limit = speedLimitMs(1000);
      debugPrint('TC-014-30 worst of 5: $worst ms (limit $limit)');
      expect(worst, lessThan(limit));
      expect(find.text('Period 1 of 10'), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
