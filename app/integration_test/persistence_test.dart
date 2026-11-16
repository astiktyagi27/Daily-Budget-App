import 'dart:io';

import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/data/database/database_connection.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/data/repositories/repository_setup.dart';
import '../test/domain/budget/fixtures.dart';

/// The real `drift_flutter` opener (background isolate, platform plugins)
/// pointed at [file]. [file] lives in the app's private temp folder.
Repos openOnDevice(File file) {
  final db = openAppDatabase(
    executor: openDatabaseConnection(
      databasePath: () async => file.path,
      tempDirectoryPath: () async => file.parent.path,
    ),
  );
  addTearDown(db.close);
  return Repos(db);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final today = d(2026, 11, 10);

  testWidgets('TC-007-03 database round trip on the device', (tester) async {
    // The app's own database lives in the app's private data folder.
    final real = openAppDatabase();
    addTearDown(real.close);
    final list = await real.customSelect('PRAGMA database_list').get();
    final path = list.first.read<String>('file');
    expect(
      path.startsWith('/data/user/0/com.dailybudget.app/') ||
          path.startsWith('/data/data/com.dailybudget.app/'),
      isTrue,
      reason: 'database must be in private storage',
    );
    expect(path.endsWith('budget.sqlite'), isTrue);
    expect(path.contains('/sdcard') || path.contains('/storage/'), isFalse);
    await real.close();

    // Seed E2 + T5 + one move, close, reopen, read (the same data and checks
    // as TC-007-01, on Android).
    final folder = Directory.systemTemp.createTempSync('tc007_03');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/budget.sqlite');
    var repos = openOnDevice(file);
    final month = await repos.months.confirmMonth(e2NewMonth());
    final adds = <(CalendarDate, int, String?)>[
      (d(2026, 11, 9), 25000, 'Lunch'),
      (d(2026, 11, 9), 40000, 'Groceries'),
      (d(2026, 11, 8), 31000, null),
      (d(2026, 11, 6), 100000, 'रिक्शा 🛺'),
      (d(2026, 11, 5), 1, 'Tea'),
    ];
    for (final (i, (date, amount, note)) in adds.indexed) {
      await repos.spends.add(
        month.id,
        fields(date, amount, note),
        today: today,
        now: at(today, 8, i),
      );
    }
    await repos.savings.cover(
      month.id,
      d(2026, 11, 6),
      const Paise(17000),
      today: today,
      now: at(today, 9),
    );
    await repos.db.close();
    expect(file.existsSync(), isTrue);

    repos = openOnDevice(file);
    final stored = (await repos.months.latestConfirmedMonth())!;
    expect(stored.month.start, d(2026, 11, 5));
    final values = stored.periods.single.values as FullMonthValues;
    expect(values.salary, const Paise(4000000));
    expect(
      [for (final c in values.fixedCosts) c.amount.value],
      [1000000, 500000, 10000],
    );
    final spends = await repos.spends.watchMonthSpends(month.id).first;
    expect(
      [
        for (final s in spends)
          (s.spend.date.iso, s.spend.amount.value, s.note),
      ],
      [
        ('2026-11-09', 40000, 'Groceries'),
        ('2026-11-09', 25000, 'Lunch'),
        ('2026-11-08', 31000, null),
        ('2026-11-06', 100000, 'रिक्शा 🛺'),
        ('2026-11-05', 1, 'Tea'),
      ],
    );
    final covers = await repos.savings.watchCovers(month.id).first;
    expect(covers.single.amount, const Paise(17000));
  });

  testWidgets('TC-007-24 five hundred spends list and save within the limits', (
    tester,
  ) async {
    final folder = Directory.systemTemp.createTempSync('tc007_24');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/budget.sqlite');
    var repos = openOnDevice(file);
    final month = await repos.months.confirmMonth(e2NewMonth());
    await repos.db.batch((batch) {
      batch.insertAll(repos.db.transactions, [
        for (var i = 0; i < 500; i++)
          TransactionsCompanion.insert(
            monthId: month.id,
            day: d(2026, 11, 5).addDays(i % 30),
            amountPaise: Paise(100 + i),
            note: Value('spend $i'),
            createdAt: at(today, 8) + i,
            editedAt: at(today, 8) + i,
          ),
      ]);
    });
    await repos.db.close();

    var worstList = 0;
    var worstWrite = 0;
    for (var run = 0; run < 5; run++) {
      repos = openOnDevice(file);
      final watch = Stopwatch()..start();
      final list = await repos.spends.watchMonthSpends(month.id).first;
      worstList = worstList > watch.elapsedMilliseconds
          ? worstList
          : watch.elapsedMilliseconds;
      expect(list, hasLength(500));

      Future<int> timed(Future<Object?> Function() action) async {
        final w = Stopwatch()..start();
        await action();
        return w.elapsedMilliseconds;
      }

      final added = await repos.spends.add(
        month.id,
        fields(today, 777, 'added'),
        today: today,
        now: at(today, 12, run),
      );
      final addMs = await timed(
        () => repos.spends.add(
          month.id,
          fields(today, 777, 'added'),
          today: today,
          now: at(today, 13, run),
        ),
      );
      final editMs = await timed(
        () => repos.spends.update(
          added.id,
          fields(today, 888, 'edited'),
          today: today,
          now: at(today, 14, run),
        ),
      );
      final deleteMs = await timed(
        () => repos.spends.delete(added.id, today: today),
      );
      for (final ms in [addMs, editMs, deleteMs]) {
        worstWrite = worstWrite > ms ? worstWrite : ms;
      }
      // Remove what this run added, so each run starts with 500 rows.
      await repos.db.customStatement(
        "DELETE FROM transactions WHERE note IN ('added', 'edited')",
      );
      await repos.db.close();
    }
    debugPrint(
      'TC-007-24 worst of 5 runs: list $worstList ms, '
      'single write $worstWrite ms',
    );
    expect(worstList, lessThan(1000));
    expect(worstWrite, lessThan(500));
  });
}
