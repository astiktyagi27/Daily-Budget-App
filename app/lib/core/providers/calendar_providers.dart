import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/month_browser.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The `MonthBrowser` key of the Home calendar (D-074: one per consumer).
const String kCalendarBrowserKey = 'calendar';

/// How the calendar header describes the viewed month (F-011 §2.7).
enum CalendarHeader {
  /// The month that contains today.
  current,

  /// An earlier month: the `Ended` tag and **This month**.
  ended,

  /// The latest month, over, with no new month set up: `Last month · …`.
  lastMonth,
}

/// What the calendar shows for the viewed month (F-011 plan §1.3).
final class CalendarView {
  const new({
    required this.monthId,
    required this.result,
    required this.grid,
    required this.browse,
    required this.header,
  });

  final int monthId;

  final MonthResult result;

  final CalendarGrid grid;

  final MonthBrowse browse;

  final CalendarHeader header;

  /// The latest month is the one shown (no `This month` button).
  bool get isLatest => browse.isLatest;

  bool get canGoBack => browse.canGoBack;

  bool get canGoForward => browse.canGoForward;

  /// The month is over, so its days are read-only (F-012 §2.6).
  bool get isEnded => header != CalendarHeader.current;

  /// The first stored month: its not-budgeted days read `before you started`;
  /// a later month's read `before this month's setup` (D-057).
  bool get lateSetup => browse.canGoBack;
}

/// The viewed month's calendar. Null while no month is stored. A month that
/// is still loading is an [AsyncLoading]; the section keeps the previous grid
/// on screen meanwhile (AC-18).
final Provider<AsyncValue<CalendarView?>> calendarViewProvider =
    Provider<AsyncValue<CalendarView?>>((ref) {
      final browse = ref.watch(monthBrowseProvider(kCalendarBrowserKey));
      if (browse case AsyncError(:final error, :final stackTrace)) {
        return AsyncError(error, stackTrace);
      }
      if (!browse.hasValue) return const AsyncLoading();
      final position = browse.requireValue;
      if (position == null) return const AsyncData(null);
      final result = ref.watch(monthResultProvider(position.viewedId));
      if (result case AsyncError(:final error, :final stackTrace)) {
        return AsyncError(error, stackTrace);
      }
      final month = result.value;
      if (month == null) return const AsyncLoading();
      final ended = month.today.isAfter(month.month.end);
      return AsyncData(
        CalendarView(
          monthId: position.viewedId,
          result: month,
          grid: CalendarGrid.of(month),
          browse: position,
          header: !ended
              ? CalendarHeader.current
              : position.isLatest
              ? CalendarHeader.lastMonth
              : CalendarHeader.ended,
        ),
      );
    });
