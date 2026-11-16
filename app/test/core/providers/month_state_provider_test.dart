import 'package:daily_budget/core/providers/month_state_provider.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/setup_harness.dart';

/// A container on [store] with the phone date at [today], listened to so the
/// streams stay open. The caller disposes it inside the test (a pending
/// midnight timer fails a test that has already finished).
ProviderContainer _container(
  FakeMoneyStore store,
  CalendarDate today,
  MovableClock clock,
) {
  clock.moveTo(today);
  return containerOn(store, clock)
    ..listen(currentMonthStateProvider, (_, _) {});
}

Future<AppMonthState> _state(ProviderContainer container) async {
  await pumpEventQueue();
  return container.read(currentMonthStateProvider).requireValue;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TC-008-01 no stored month is no month set up', () async {
    final container = _container(
      FakeMoneyStore(),
      d(2026, 11, 5),
      MovableClock(d(2026, 11, 5)),
    );
    expect(container.read(currentMonthStateProvider).isLoading, isTrue);
    expect(await _state(container), isA<NoMonthSetUp>());
    container.dispose();
  });

  test('TC-008-02 a month containing today is the active month', () async {
    final store = storeWithMonth();
    final container = _container(
      store,
      d(2026, 11, 9),
      MovableClock(d(2026, 11, 9)),
    );
    final state = await _state(container);
    expect(state, isA<ActiveMonth>());
    final active = state as ActiveMonth;
    expect(active.stored.month.start, d(2026, 11, 5));
    expect(active.result.dayOn(d(2026, 11, 9)).budget, p(83000));
    container.dispose();
  });

  test('TC-008-03 on or after the next start the new month is due', () async {
    for (final today in [d(2026, 12, 5), d(2026, 12, 20)]) {
      final container = _container(
        storeWithMonth(),
        today,
        MovableClock(today),
      );
      final due = await _state(container) as NewMonthDue;
      expect(due.month.start, d(2026, 12, 5), reason: today.iso);
      expect(due.missedMonths, 0, reason: today.iso);
      expect(due.lastMonth.month.start, d(2026, 11, 5), reason: today.iso);
      container.dispose();
    }
    // The last day of the month is still the current month.
    final container = _container(
      storeWithMonth(),
      d(2026, 12, 4),
      MovableClock(d(2026, 12, 4)),
    );
    expect(await _state(container), isA<ActiveMonth>());
    container.dispose();
  });

  test(
    'TC-008-41 after missed months setup is for the month of today',
    () async {
      final store = storeWithMonth(month: oct2026);
      final container = _container(
        store,
        d(2026, 12, 20),
        MovableClock(d(2026, 12, 20)),
      );
      final due = await _state(container) as NewMonthDue;
      expect(due.month.start, d(2026, 12, 5));
      expect(due.month.end, d(2027, 1, 4));
      expect(due.missedMonths, 1);
      expect(store.months, hasLength(1), reason: 'no Nov month is created');
      container.dispose();
    },
  );

  test('TC-008-02 the state follows a new month being confirmed', () async {
    final store = storeWithMonth();
    final clock = MovableClock(d(2026, 12, 5));
    final container = _container(store, d(2026, 12, 5), clock);
    expect(await _state(container), isA<NewMonthDue>());

    addMonth(store, month: nov2026.next);
    store.notify();
    expect(await _state(container), isA<ActiveMonth>());
    container.dispose();
  });

  test('TC-008-39 the state follows the phone date past midnight', () async {
    final store = storeWithMonth();
    final clock = MovableClock(d(2026, 12, 4));
    final container = _container(store, d(2026, 12, 4), clock);
    expect(await _state(container), isA<ActiveMonth>());

    clock.moveTo(d(2026, 12, 5));
    container.read(todayProvider.notifier).refresh();
    expect(await _state(container), isA<NewMonthDue>());
    container.dispose();
  });

  test('TC-008-52 a failed read is an error, never "no month"', () async {
    final store = storeWithMonth()..readFails = true;
    final container = _container(
      store,
      d(2026, 11, 9),
      MovableClock(d(2026, 11, 9)),
    );
    await pumpEventQueue();
    final state = container.read(currentMonthStateProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<StorageException>());
    container.dispose();
  });
}
