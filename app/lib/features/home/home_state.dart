import 'package:daily_budget/core/providers/month_state_provider.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the Home tab shows (F-010 §2, `home-summary.md` §7). One value per
/// state, so the widget is an exhaustive `switch` and nothing on screen does
/// money arithmetic. Loading and a failed read stay `AsyncValue` states.
sealed class HomeView {
  const new();
}

/// No month was ever set up: the empty state (F-008).
final class NoMonthHome extends HomeView {
  const new();
}

/// Today is after the last set-up month: the new-month card.
final class NewMonthHome extends HomeView {
  const new({required this.lastMonth});

  final StoredMonth lastMonth;
}

/// Today is in the last set-up month: the summary card and the Today card.
///
/// [line] and [safeToSpend] are left out ([line] null, [safeToSpend] an
/// unavailable value) when today is not a budgeted day, a device date set
/// back (D-077 (4), TC-010-59): the summary still shows what the engine
/// gives, and nothing is added to any total (F-006 AC-13).
final class ActiveHome extends HomeView {
  const new({
    required this.stored,
    required this.today,
    required this.summary,
    required this.line,
    required this.safeToSpend,
    required this.canEdit,
  });

  final StoredMonth stored;

  /// The device's calendar day, the one the Today card names.
  final CalendarDate today;

  final HomeSummary summary;

  final TodayLine? line;

  final SafeToSpend safeToSpend;

  /// An edit needs today inside the budgeted days (a phone date set back
  /// would leave nothing to recalculate, F-008).
  final bool canEdit;
}

/// The state of the Home tab, built on `currentMonthStateProvider`
/// (F-008 T-213). A failed read is an [AsyncError] (the tab's load error,
/// F-007 §5); loading never produces a figure.
final Provider<AsyncValue<HomeView>> homeViewProvider =
    Provider<AsyncValue<HomeView>>((ref) {
      return switch (ref.watch(currentMonthStateProvider)) {
        AsyncError(:final error, :final stackTrace) => AsyncError(
          error,
          stackTrace,
        ),
        AsyncData(value: NoMonthSetUp()) => const AsyncData(NoMonthHome()),
        AsyncData(value: NewMonthDue(:final lastMonth)) => AsyncData(
          NewMonthHome(lastMonth: lastMonth),
        ),
        AsyncData(value: ActiveMonth(:final stored, :final result)) =>
          AsyncData(_active(stored, result)),
        _ => const AsyncLoading(),
      };
    });

ActiveHome _active(StoredMonth stored, MonthResult result) {
  final today = result.today;
  // Checked first: `TodayLine.from` throws on a day that is not budgeted.
  final budgeted =
      result.month.contains(today) && !today.isBefore(result.firstBudgetedDay);
  return ActiveHome(
    stored: stored,
    today: today,
    summary: HomeSummary.from(result),
    line: budgeted ? TodayLine.from(result) : null,
    safeToSpend: safeToSpendPerDay(result),
    canEdit: budgeted,
  );
}
