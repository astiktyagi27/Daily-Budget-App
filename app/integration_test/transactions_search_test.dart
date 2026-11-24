import 'dart:io';

import 'package:daily_budget/app.dart';
import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/preferences_providers.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/data/database/database_connection.dart';
import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:daily_budget/features/transactions/transactions_filter_state.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show kProfileMode;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/data/repositories/repository_setup.dart';
import '../test/domain/budget/fixtures.dart';
import '../test/helpers/phase3_fixtures.dart';
import '../test/helpers/pump_app.dart';
import '../test/support/find_copy.dart';
import 'real_app.dart' show speedLimitMs;

/// F-015 AC-16, TC-015-27 and TC-015-28: the 1,000-entry database (L1000:
/// 250 + 250 + 500 spends over three budget months, nine categories) on the
/// real database file.
///
/// Run in profile mode on emulator-5554 (D-083 (1)), from `app/`:
/// `flutter drive --profile -d emulator-5554
///  --driver=test_driver/integration_test.dart
///  --target=integration_test/transactions_search_test.dart`
/// In debug mode the frame clause is not meaningful: the limits are asserted
/// in profile mode only (D-100); debug logs the figures and keeps a 3,000 ms
/// guard.

AppDatabase _open(File file) => openAppDatabase(
  executor: openDatabaseConnection(
    databasePath: () async => file.path,
    tempDirectoryPath: () async => file.parent.path,
  ),
);

/// The whole app on the real database file, as after a restart. Today is
/// 4 Dec 2026, the last day of the current month.
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
        clockProvider.overrideWithValue(() => DateTime(2026, 12, 4, 14)),
      ],
      child: const DailyBudgetApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Indian grouping of whole rupees, written here so the expected text never
/// comes from the app.
String _rupees(int paise) {
  final digits = '${paise ~/ 100}';
  if (digits.length <= 3) return '₹$digits';
  final head = digits.substring(0, digits.length - 3);
  final tail = digits.substring(digits.length - 3);
  final groups = <String>[];
  for (var i = head.length; i > 0; i -= 2) {
    groups.insert(0, head.substring(i - 2 < 0 ? 0 : i - 2, i));
  }
  return '₹${groups.join(',')},$tail';
}

/// `<n> results · spent <x>` for [entries].
String _line(Iterable<FixtureEntry> entries) {
  final list = entries.toList();
  final sum = list.fold<int>(0, (total, e) => total + e.paise);
  return '${list.length} result${list.length == 1 ? '' : 's'} · spent '
      '${_rupees(sum)}';
}

/// Pumps real frames until [done] or [limit]; returns the milliseconds.
Future<int> _until(
  WidgetTester tester,
  bool Function() done, {
  int limit = 5000,
}) async {
  final watch = Stopwatch()..start();
  while (!done() && watch.elapsedMilliseconds < limit) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  return watch.elapsedMilliseconds;
}

/// Stores L1000 in [file] (months, then each month's spends in one batch).
Future<List<FixtureMonth>> _seed(File file) async {
  final seed = Repos(_open(file));
  final months = <FixtureMonth>[...fixtureL1000.months];
  for (final month in months) {
    final stored = await seed.months.confirmMonth(
      NewMonth(
        month: month.month,
        firstBudgetedDay: month.firstBudgetedDay,
        firstPeriod: month.periods.first,
        confirmedAt: at(month.firstBudgetedDay, 8),
      ),
    );
    await seed.db.batch((batch) {
      batch.insertAll(seed.db.transactions, [
        for (final entry in month.entries)
          TransactionsCompanion.insert(
            monthId: stored.id,
            day: entry.date,
            amountPaise: Paise(entry.paise),
            note: Value(entry.note!),
            category: Value(entry.categoryKey),
            createdAt: entry.createdAt,
            editedAt: entry.createdAt,
          ),
      ]);
    });
  }
  await seed.db.close();
  return months;
}

void _showAllThreeMonths(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(DailyBudgetApp)),
  );
  container
      .read(transactionsFilterProvider.notifier)
      .setDates(DatesFilter.custom(d(2026, 9, 5), d(2026, 12, 4)));
}

/// Delivers [text] to the search field the way the keyboard does: the field
/// shows it and calls `onChanged`. (`tester.enterText` does not reach the
/// field through the emulator's real keyboard connection.)
Future<void> _type(WidgetTester tester, Finder field, String text) async {
  final widget = tester.widget<TextField>(field);
  widget.controller!.text = text;
  widget.onChanged!(text);
  await tester.pump();
}

int _max(int a, int b) => a > b ? a : b;

/// The texts on screen that match [pattern] (for a failure message).
List<String> _texts(RegExp pattern) {
  final found = <String>[];
  for (final element in find.byType(Text).evaluate()) {
    final text = element.widget as Text;
    final plain = text.data ?? text.textSpan?.toPlainText() ?? '';
    if (pattern.hasMatch(plain)) found.add(plain);
  }
  return found;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'TC-015-27 one thousand entries open quickly and scroll smoothly',
    (tester) async {
      final folder = Directory.systemTemp.createTempSync('tc015_27');
      addTearDown(() => folder.deleteSync(recursive: true));
      final file = File('${folder.path}/budget.sqlite');
      final months = await _seed(file);
      final all = [for (final month in months) ...month.entries];
      expect(all, hasLength(1000));

      // Open time: worst of 5 restarts.
      var worstOpen = 0;
      for (var run = 0; run < 5; run++) {
        await _launch(tester, file);
        final watch = Stopwatch()..start();
        await tester.tap(find.text('Transactions').last);
        while (find.text('Today').evaluate().length < 2 &&
            watch.elapsedMilliseconds < 5000) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        final shown = watch.elapsedMilliseconds;
        debugPrint('TC-015-27 open run $run: first rows after $shown ms');
        expect(find.text('Today'), findsWidgets);
        if (shown > worstOpen) worstOpen = shown;
      }
      // D-100: the AC limits apply in profile mode; debug logs the figures
      // and keeps a loose guard.
      final openLimit = speedLimitMs(1000);
      debugPrint('TC-015-27 open worst of 5: $worstOpen ms (limit $openLimit)');
      expect(worstOpen, lessThan(openLimit));

      // All three months: a custom range over the whole seed.
      _showAllThreeMonths(tester);
      await _until(tester, () => findCopy(_line(all)).evaluate().isNotEmpty);
      expect(findCopy(_line(all)), findsOneWidget);

      // D-083 (1): one warm-up and 3 timed scrolls from the newest to the
      // oldest day; UI-thread build time of every frame <= 32 ms; raster time
      // recorded, not gated.
      final timings = <FrameTiming>[];
      void record(List<FrameTiming> batch) => timings.addAll(batch);
      SchedulerBinding.instance.addTimingsCallback(record);
      addTearDown(
        () => SchedulerBinding.instance.removeTimingsCallback(record),
      );
      final scrollable = find.byType(Scrollable).first;
      final position = tester.state<ScrollableState>(scrollable).position;
      var timedRuns = 0;
      for (var run = 0; run < 4; run++) {
        position.jumpTo(0);
        await tester.pump(const Duration(milliseconds: 500));
        await Future<void>.delayed(const Duration(seconds: 1));
        timings.clear();
        // One real frame per step, 100 logical pixels a frame (about
        // 6,000 px/s, a hard fling), until the oldest day is on screen.
        while (position.pixels < position.maxScrollExtent - 1) {
          position.jumpTo(
            (position.pixels + 100).clamp(0, position.maxScrollExtent),
          );
          await tester.pump(const Duration(milliseconds: 16));
        }
        await tester.pump(const Duration(seconds: 2));
        await Future<void>.delayed(const Duration(seconds: 1));
        await tester.pump();
        final builds = [
          for (final t in timings) t.buildDuration.inMicroseconds,
        ];
        final rasters = [
          for (final t in timings) t.rasterDuration.inMicroseconds,
        ];
        final worstBuild = builds.isEmpty ? 0 : builds.reduce(_max);
        final worstRaster = rasters.isEmpty ? 0 : rasters.reduce(_max);
        debugPrint(
          'TC-015-27 scroll ${run == 0 ? 'warm-up' : 'timed $run'}: '
          '${timings.length} frames, worst build '
          '${(worstBuild / 1000).toStringAsFixed(1)} ms, worst raster '
          '${(worstRaster / 1000).toStringAsFixed(1)} ms',
        );
        if (run > 0) {
          timedRuns++;
          expect(timings, isNotEmpty);
          // A debug build's frames say nothing about a user's (D-083 (1)):
          // the 32 ms limit is asserted in profile mode, logged otherwise.
          if (kProfileMode) {
            expect(
              worstBuild,
              lessThanOrEqualTo(32000),
              reason: 'timed scroll $run: worst UI build time in microseconds',
            );
          }
        }
      }
      expect(timedRuns, 3);

      // The oldest day is reached and its total is the seed's sum.
      expect(find.text('Sat, 5 Sep'), findsOneWidget);
      final oldest = all.where((e) => e.date == d(2026, 9, 5));
      final oldestSum = oldest.fold<int>(0, (total, e) => total + e.paise);
      debugPrint(
        'TC-015-27 oldest day: expected ${_rupees(oldestSum)}, on screen '
        '${_texts(RegExp('^₹'))}',
      );
      // A date range is a filter, so the day header says `shown` (AC-10).
      expect(findCopy('${_rupees(oldestSum)} shown'), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );

  testWidgets(
    'TC-015-28 search and filters update within three hundred milliseconds',
    (tester) async {
      final folder = Directory.systemTemp.createTempSync('tc015_28');
      addTearDown(() => folder.deleteSync(recursive: true));
      final file = File('${folder.path}/budget.sqlite');
      final months = await _seed(file);
      final all = [for (final month in months) ...month.entries];

      await _launch(tester, file);
      await tester.tap(find.text('Transactions').last);
      await tester.pumpAndSettle();
      _showAllThreeMonths(tester);
      await tester.pumpAndSettle();

      // Search: type char by char, measure from the last keystroke.
      final lunch = all.where((e) => e.note!.toLowerCase().contains('lunch'));
      final field = find.byType(TextField).first;
      var worst = 0;
      for (var run = 0; run < 5; run++) {
        await _type(tester, field, '');
        await _until(tester, () => findCopy(_line(all)).evaluate().isNotEmpty);
        expect(findCopy(_line(all)), findsOneWidget);
        for (final prefix in ['l', 'lu', 'lun', 'lunc']) {
          await _type(tester, field, prefix);
          await tester.pump(const Duration(milliseconds: 60));
        }
        await _type(tester, field, 'lunch');
        final took = await _until(
          tester,
          () => findCopy(_line(lunch)).evaluate().isNotEmpty,
        );
        debugPrint(
          'TC-015-28 search run $run: $took ms, want ${_line(lunch)}, '
          'results lines ${_texts(RegExp('result'))}',
        );
        expect(findCopy(_line(lunch)), findsOneWidget);
        if (took > worst) worst = took;
      }
      final limit = speedLimitMs(300);
      debugPrint('TC-015-28 search worst of 5: $worst ms (limit $limit)');
      expect(worst, lessThan(limit));
      await _type(tester, field, '');
      await _until(tester, () => findCopy(_line(all)).evaluate().isNotEmpty);

      // Category: Food.
      final food = all.where((e) => e.categoryKey == 'food');
      var worstCategory = 0;
      for (var run = 0; run < 5; run++) {
        await tester.tap(find.text('Category: All'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Food').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Show'));
        final took = await _until(
          tester,
          () => findCopy(_line(food)).evaluate().isNotEmpty,
        );
        debugPrint('TC-015-28 category run $run: $took ms');
        expect(findCopy(_line(food)), findsOneWidget);
        if (took > worstCategory) worstCategory = took;
        await tester.pumpAndSettle();
        await tester.tap(find.text('Category: Food'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();
      }
      debugPrint(
        'TC-015-28 category worst of 5: $worstCategory ms (limit $limit)',
      );
      expect(worstCategory, lessThan(limit));

      // Dates: Last month (October).
      final october = months[1].entries;
      var worstDates = 0;
      for (var run = 0; run < 5; run++) {
        _showAllThreeMonths(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Dates: '));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Last month'));
        final took = await _until(
          tester,
          () => findCopy(_line(october)).evaluate().isNotEmpty,
        );
        debugPrint('TC-015-28 dates run $run: $took ms');
        expect(findCopy(_line(october)), findsOneWidget);
        if (took > worstDates) worstDates = took;
      }
      debugPrint('TC-015-28 dates worst of 5: $worstDates ms (limit $limit)');
      expect(worstDates, lessThan(limit));
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
