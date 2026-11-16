import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/month_state_provider.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the Transactions tab shows (F-009 §2.1, `transactions.md` §6). One
/// value per tab state, so the widget is an exhaustive `switch` and the Today
/// line is only worked out where it exists (review G1: `TodayLine.from`
/// throws when today is not a budgeted day).
sealed class TransactionsView {
  const new();
}

/// No month was ever set up (§6.1).
final class NoMonthView extends TransactionsView {
  const new();
}

/// Today is after the last set-up month (§6.4): its spends, read-only.
final class NewMonthView extends TransactionsView {
  const new({
    required this.lastMonth,
    required this.today,
    required this.spends,
  });

  final StoredMonth lastMonth;
  final CalendarDate today;
  final List<StoredSpend> spends;
}

/// Today is in the last set-up month (§6.2, §6.3). [line] is null when the
/// device date was set back to before the first budgeted day: the spends are
/// listed, but there is no budget for today and nothing can be added.
final class CurrentMonthView extends TransactionsView {
  const new({
    required this.stored,
    required this.today,
    required this.spends,
    required this.line,
  });

  final StoredMonth stored;
  final CalendarDate today;
  final List<StoredSpend> spends;
  final TodayLine? line;

  bool get canAdd => line != null;
}

/// The state of the Transactions tab, built on `currentMonthStateProvider`
/// (F-008 T-213) and the month's spends. A failed read is an [AsyncError]
/// (the tab's load error, F-007 §5).
final Provider<AsyncValue<TransactionsView>> transactionsViewProvider =
    Provider<AsyncValue<TransactionsView>>((ref) {
      final month = ref.watch(currentMonthStateProvider);
      if (month case AsyncError(:final error, :final stackTrace)) {
        return AsyncError(error, stackTrace);
      }
      final state = month.value;
      if (state == null) return const AsyncLoading();
      if (state is NoMonthSetUp) return const AsyncData(NoMonthView());

      final stored = switch (state) {
        NewMonthDue(:final lastMonth) => lastMonth,
        ActiveMonth(:final stored) => stored,
        NoMonthSetUp() => throw StateError('handled above'),
      };
      final spends = ref.watch(monthSpendsProvider(stored.id));
      if (spends case AsyncError(:final error, :final stackTrace)) {
        return AsyncError(error, stackTrace);
      }
      final spendList = spends.value;
      if (spendList == null) return const AsyncLoading();

      return AsyncData(switch (state) {
        NewMonthDue(:final lastMonth) => NewMonthView(
          lastMonth: lastMonth,
          today: _todayOf(ref),
          spends: spendList,
        ),
        ActiveMonth(:final result) => CurrentMonthView(
          stored: stored,
          today: result.today,
          spends: spendList,
          // Checked first: `TodayLine.from` throws on an unbudgeted day.
          line:
              !result.today.isBefore(result.firstBudgetedDay) &&
                  result.month.contains(result.today)
              ? TodayLine.from(result)
              : null,
        ),
        NoMonthSetUp() => const NoMonthView(),
      });
    });

CalendarDate _todayOf(Ref ref) => ref.watch(todayProvider);
