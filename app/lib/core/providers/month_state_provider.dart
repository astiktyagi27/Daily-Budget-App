import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the user stands with budget months today (F-008 §2.1, §2.11),
/// shared by Home, month setup and Transactions. The engine's own
/// [MonthState] says which month is meant; this adds the stored facts a
/// screen needs.
sealed class AppMonthState {
  const new();
}

/// No month was ever set up.
final class NoMonthSetUp extends AppMonthState {
  const new();
}

/// Today is after the last set-up month. [month] contains today; whole
/// months in between are skipped, never created (D-057).
final class NewMonthDue extends AppMonthState {
  const new({
    required this.lastMonth,
    required this.month,
    required this.missedMonths,
  });

  final StoredMonth lastMonth;

  /// The month setup is for: the one containing today.
  final BudgetMonth month;

  final int missedMonths;
}

/// Today is in the last set-up month (or before it, if the device date moved
/// back). [result] is the engine's output for it, live.
final class ActiveMonth extends AppMonthState {
  const new({required this.stored, required this.result});

  final StoredMonth stored;

  final MonthResult result;
}

Duration? _noRetry(int retryCount, Object error) => null;

/// The month with the latest start, live. A failed read is an error state on
/// the screen with **Try again**, never retried silently (F-007 §2.6).
final StreamProvider<StoredMonth?> latestMonthProvider =
    StreamProvider<StoredMonth?>(
      (ref) => ref.watch(monthRepositoryProvider).watchLatestMonth(),
      retry: _noRetry,
    );

/// The current month state, from the repositories and today (one
/// `todayProvider` value, so Home and setup never disagree about the day).
///
/// Loading until the stores answer; an error carries the `StorageException`.
final Provider<AsyncValue<AppMonthState>> currentMonthStateProvider =
    Provider<AsyncValue<AppMonthState>>((ref) {
      final today = ref.watch(todayProvider);
      final latest = ref.watch(latestMonthProvider);
      if (latest case AsyncError(:final error, :final stackTrace)) {
        return AsyncError(error, stackTrace);
      }
      if (!latest.hasValue) return const AsyncLoading();
      final stored = latest.requireValue;
      if (stored == null) return const AsyncData(NoMonthSetUp());
      return switch (monthStateFor(
        salaryDay: stored.month.salaryDay,
        lastMonth: stored.month,
        today: today,
      )) {
        NoMonthYet() => const AsyncData(NoMonthSetUp()),
        NewMonthStarted(:final month, :final missedMonths) => AsyncData(
          NewMonthDue(
            lastMonth: stored,
            month: month,
            missedMonths: missedMonths,
          ),
        ),
        CurrentMonth() => switch (ref.watch(monthResultProvider(stored.id))) {
          AsyncError(:final error, :final stackTrace) => AsyncError(
            error,
            stackTrace,
          ),
          AsyncData(value: final result?) => AsyncData(
            ActiveMonth(stored: stored, result: result),
          ),
          _ => const AsyncLoading(),
        },
      };
    });
