import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/month_state_provider.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the Dashboard's "Where your money went" card covers (F-013 AC-6).
enum DashboardRange { month, day }

/// What the user chose on the Dashboard (F-013 AC-6, AC-13, design B-9).
///
/// Kept while the app is open, also when the user leaves the tab and comes
/// back, and gone after a restart (nothing is saved). `monthId` is null while
/// the Dashboard follows the current month. `pickedDay` is null until the
/// user picks one; the shown day then defaults to today (or the last day of a
/// month that has ended).
typedef DashboardSelection = ({
  DashboardRange range,
  int? monthId,
  CalendarDate? pickedDay,
});

class DashboardSelectionNotifier extends Notifier<DashboardSelection> {
  @override
  DashboardSelection build() =>
      (range: DashboardRange.month, monthId: null, pickedDay: null);

  void selectRange(DashboardRange range) => state = (
    range: range,
    monthId: state.monthId,
    pickedDay: state.pickedDay,
  );

  void pickDay(CalendarDate day) =>
      state = (range: state.range, monthId: state.monthId, pickedDay: day);

  /// Shows another stored month. Only the day is reset (to that month's
  /// default); `One day` stays selected (design B-9).
  void selectMonth(int monthId) =>
      state = (range: state.range, monthId: monthId, pickedDay: null);

  /// Back to following the current month (`This month` button of the
  /// switcher).
  void followCurrentMonth() =>
      state = (range: state.range, monthId: null, pickedDay: null);
}

final dashboardSelectionProvider =
    NotifierProvider<DashboardSelectionNotifier, DashboardSelection>(
      DashboardSelectionNotifier.new,
    );

/// What the Dashboard shows: one value per tab state, so the widget is an
/// exhaustive `switch`.
sealed class DashboardView {
  const new();
}

/// No month was ever set up (design section 8).
final class NoMonthDashboard extends DashboardView {
  const new();
}

/// A stored month with everything the cards show, worked out by the pure
/// statistics in `domain/budget/` (nothing is calculated in a widget).
final class MonthDashboard extends DashboardView {
  const new({
    required this.stored,
    required this.today,
    required this.ended,
    required this.notSetUp,
    required this.range,
    required this.day,
    required this.limits,
    required this.breakdown,
    required this.figures,
  });

  final StoredMonth stored;

  final CalendarDate today;

  /// Whether the month is over (today is after its last day).
  final bool ended;

  /// Today is in a month that was not set up: [stored] is the last month
  /// shown as a past month (`Last month · ...`, F-013 AC-13).
  final bool notSetUp;

  final DashboardRange range;

  /// The day of `One day` (always inside [limits]).
  final CalendarDate day;

  /// The days `One day` can pick: first budgeted day to today, never past the
  /// month's end.
  final SpendDateLimits limits;

  /// The categories of the chosen range.
  final CategoryBreakdown breakdown;

  /// The figures of "This month in numbers": always the whole month.
  final MonthFigures figures;

  int get monthId => stored.id;

  bool get isOneDay => range == DashboardRange.day;

  /// The first budgeted day: the header starts here (`10 Nov – 4 Dec 2026`
  /// for a month first used on the 10th).
  CalendarDate get headerStart => limits.first;

  CalendarDate get headerEnd => stored.month.end;
}

/// The state of the Dashboard tab, built on `currentMonthStateProvider`, the
/// month's spends and result, and the user's choice. A failed read is an
/// [AsyncError] (the tab's load error, F-007 section 5).
final Provider<AsyncValue<DashboardView>> dashboardViewProvider =
    Provider<AsyncValue<DashboardView>>((ref) {
      final selection = ref.watch(dashboardSelectionProvider);
      final today = ref.watch(todayProvider);
      final month = ref.watch(currentMonthStateProvider);
      if (month case AsyncError(:final error, :final stackTrace)) {
        return AsyncError(error, stackTrace);
      }
      final state = month.value;
      if (state == null) return const AsyncLoading();
      if (state is NoMonthSetUp) return const AsyncData(NoMonthDashboard());

      final current = switch (state) {
        NewMonthDue(:final lastMonth) => lastMonth,
        ActiveMonth(:final stored) => stored,
        NoMonthSetUp() => throw StateError('handled above'),
      };
      final notSetUp = state is NewMonthDue;

      // Another stored month, when the user browsed to one.
      final StoredMonth stored;
      final chosen = selection.monthId;
      if (chosen == null || chosen == current.id) {
        stored = current;
      } else {
        final other = ref.watch(storedMonthProvider(chosen));
        if (other case AsyncError(:final error, :final stackTrace)) {
          return AsyncError(error, stackTrace);
        }
        final value = other.value;
        if (value == null) return const AsyncLoading();
        stored = value;
      }

      final spends = ref.watch(monthSpendsProvider(stored.id));
      if (spends case AsyncError(:final error, :final stackTrace)) {
        return AsyncError(error, stackTrace);
      }
      final spendList = spends.value;
      if (spendList == null) return const AsyncLoading();
      final resultState = ref.watch(monthResultProvider(stored.id));
      if (resultState case AsyncError(:final error, :final stackTrace)) {
        return AsyncError(error, stackTrace);
      }
      final result = resultState.value;
      if (result == null) return const AsyncLoading();

      final ended = today.isAfter(stored.month.end);
      final limits = spendDateLimits(
        month: stored.month,
        firstBudgetedDay: stored.firstBudgetedDay,
        today: today,
      );
      final wanted = selection.pickedDay ?? (ended ? stored.month.end : today);
      final day = wanted.isBefore(limits.first)
          ? limits.first
          : wanted.isAfter(limits.last)
          ? limits.last
          : wanted;
      final oneDay = selection.range == DashboardRange.day;

      return AsyncData(
        MonthDashboard(
          stored: stored,
          today: today,
          ended: ended,
          notSetUp: notSetUp && stored.id == current.id,
          range: selection.range,
          day: day,
          limits: limits,
          breakdown: categoryBreakdown(
            [for (final entry in spendList) entry.spend],
            oneDay ? day : limits.first,
            oneDay ? day : limits.last,
          ),
          figures: monthFigures(result),
        ),
      );
    });
