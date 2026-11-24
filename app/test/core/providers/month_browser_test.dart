import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/month_browser.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/fake_month_repository.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/setup_harness.dart';

// D-074: the month index, the pure browse position and one browser per
// consumer.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TC-011-65 browse limits and the gap jump come from the index', () {
    // Three stored months, newest first: ids 3 (Nov), 2 (Sep), 1 (Jun).
    const ids = [3, 2, 1];
    final latest = MonthBrowse.of(ids, null);
    expect(latest.viewedId, 3);
    expect(latest.isLatest, isTrue);
    expect(latest.canGoForward, isFalse);
    expect(latest.canGoBack, isTrue);
    expect(latest.previousId, 2, reason: 'Oct was never set up: Nov to Sep');
    final middle = MonthBrowse.of(ids, 2);
    expect((middle.canGoBack, middle.canGoForward), (true, true));
    expect((middle.previousId, middle.nextId), (1, 3));
    final first = MonthBrowse.of(ids, 1);
    expect((first.canGoBack, first.canGoForward), (false, true));
    // An id that is not stored means the latest month.
    expect(MonthBrowse.of(ids, 99).viewedId, 3);
    expect(MonthBrowse.of(const [7], null).canGoBack, isFalse);
  });

  test(
    'TC-011-66 each consumer keeps its own month and resets at midnight',
    () async {
      final store = storeFor(octNov);
      final clock = clockFor(octNov);
      final container = ProviderContainer(
        overrides: [
          monthRepositoryProvider.overrideWithValue(FakeMonthRepository(store)),
          clockProvider.overrideWithValue(clock.read),
        ],
      );
      addTearDown(container.dispose);
      final october = store.months.first.id;
      final november = store.months.last.id;
      // Listen so the streams stay alive.
      for (final key in ['calendar', 'dashboard']) {
        container.listen(monthBrowseProvider(key), (_, _) {});
      }
      await pumpEventQueue();
      int viewed(String key) =>
          container.read(monthBrowseProvider(key)).requireValue!.viewedId;
      expect(viewed('calendar'), november);
      expect(viewed('dashboard'), november);

      container.read(monthBrowserProvider('calendar').notifier).view(october);
      await pumpEventQueue();
      expect(viewed('calendar'), october);
      expect(viewed('dashboard'), november, reason: 'a separate instance');

      // The day changes: every consumer is back on the latest month.
      clock.moveTo(d(2026, 11, 14));
      container.read(todayProvider.notifier).refresh();
      await pumpEventQueue();
      expect(viewed('calendar'), november);
    },
  );

  test('TC-011-65 no stored month gives no browse position', () async {
    final container = ProviderContainer(
      overrides: [
        monthRepositoryProvider.overrideWithValue(
          FakeMonthRepository(storeWithMonth()..months.clear()),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(monthBrowseProvider('calendar'), (_, _) {});
    await pumpEventQueue();
    expect(container.read(monthBrowseProvider('calendar')).value, isNull);
  });
}
