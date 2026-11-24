import 'package:daily_budget/domain/budget/calendar_date.dart';
import 'package:daily_budget/domain/budget/day_summary.dart';
import 'package:daily_budget/domain/budget/month_result.dart';
import 'package:daily_budget/domain/budget/paise.dart';

/// What a calendar cell is (F-011 §2.2), from the engine's [DayStatus].
enum CellKind {
  /// In the grid's first or last week but not in the budget month:
  /// decorative.
  outside,

  /// Before the first budgeted day (D-034): readable, not tappable.
  notBudgeted,

  /// After today: the day's budget only.
  upcoming,

  /// Today's live day.
  today,

  saved,
  onBudget,
  overspent,
}

/// The fill of today's cell: the sign of the result so far, or plain
/// `surface` when nothing has been spent (F-011 §2.2).
enum TodayFill { nothingSpent, saved, onBudget, overspent }

/// One cell of the month grid. Money fields are null for the kinds that
/// show none (outside, not budgeted, upcoming).
final class CalendarCell {
  const new({
    required this.kind,
    required this.date,
    this.isMonthFirstDay = false,
    this.netSpent,
    this.result,
    this.covered = Paise.zero,
    this.resultKind,
    this.todayFill,
    this.isChangeDay = false,
    this.hasRefunds = false,
  });

  final CellKind kind;

  final CalendarDate date;

  /// The number reads `1 Dec`: the 1st of a calendar month that begins
  /// inside the budget month. A budget month that starts on the 1st shows a
  /// plain `1` (D-075).
  final bool isMonthFirstDay;

  /// The day's net spend (spends minus refunds), the amount in the cell.
  final Paise? netSpent;

  /// Budget − net spent + covered; for today, what is left so far.
  final Paise? result;

  /// What savings covers on this day.
  final Paise covered;

  final DayResultKind? resultKind;

  /// Only for [CellKind.today].
  final TodayFill? todayFill;

  /// The start of a later (non-superseded) period: the ink tick (AC-8).
  final bool isChangeDay;

  /// The day has money in, so the label says `net … after refunds`.
  final bool hasRefunds;

  /// Whether a tap opens day details (F-011 §2.8).
  bool get isTappable => switch (kind) {
    CellKind.outside || CellKind.notBudgeted => false,
    _ => true,
  };
}

/// The month as a Monday-to-Sunday grid of [CalendarCell]s (F-011 §2.1):
/// from the Monday of the first day's week to the Sunday of the last day's
/// week, 4 to 6 rows. It adds no money rule: every figure is the engine's.
final class CalendarGrid {
  const new _(this.weeks);

  factory of(MonthResult result) {
    final month = result.month;
    final gridStart = month.start.addDays(-month.start.weekdayIndex);
    final gridEnd = month.end.addDays(6 - month.end.weekdayIndex);
    final changeDays = {
      for (final period in result.periods.where((p) => !p.superseded).skip(1))
        period.start,
    };
    final cells = <CalendarCell>[];
    for (var day = gridStart; !day.isAfter(gridEnd); day = day.addDays(1)) {
      cells.add(
        month.contains(day)
            ? _cellOf(result, day, changeDays, month.start)
            : CalendarCell(kind: CellKind.outside, date: day),
      );
    }
    return CalendarGrid._([
      for (var i = 0; i < cells.length; i += 7)
        List.unmodifiable(cells.sublist(i, i + 7)),
    ]);
  }

  /// The rows, Monday first.
  final List<List<CalendarCell>> weeks;

  Iterable<CalendarCell> get cells => weeks.expand((week) => week);

  /// Whether the grid shows not-budgeted days, so the caption is shown.
  bool get hasNotBudgeted => cells.any((c) => c.kind == CellKind.notBudgeted);

  /// Whether the month has a change day, so the legend adds `Budget changed`.
  bool get hasChangeDay => cells.any((c) => c.isChangeDay);
}

CalendarCell _cellOf(
  MonthResult result,
  CalendarDate date,
  Set<CalendarDate> changeDays,
  CalendarDate monthStart,
) {
  final day = result.dayOn(date);
  final isMonthFirstDay = date.day == 1 && date != monthStart;
  final dayResult = day.result;
  final kind = switch (day.status) {
    DayStatus.notBudgeted => CellKind.notBudgeted,
    DayStatus.upcoming => CellKind.upcoming,
    DayStatus.live => CellKind.today,
    DayStatus.saved => CellKind.saved,
    DayStatus.onBudget => CellKind.onBudget,
    DayStatus.overspent => CellKind.overspent,
  };
  final hasAmount = dayResult != null;
  return CalendarCell(
    kind: kind,
    date: date,
    isMonthFirstDay: isMonthFirstDay,
    netSpent: hasAmount ? day.netSpent : null,
    result: dayResult,
    covered: day.covered,
    resultKind: dayResult == null ? null : dayResultKind(dayResult),
    todayFill: kind != CellKind.today
        ? null
        : day.spent.isZero && day.moneyIn.isZero
        ? TodayFill.nothingSpent
        : switch (dayResultKind(dayResult!)) {
            DayResultKind.saved ||
            DayResultKind.savedUnderRupee => TodayFill.saved,
            DayResultKind.onBudget => TodayFill.onBudget,
            DayResultKind.overspent ||
            DayResultKind.overspentUnderRupee => TodayFill.overspent,
          },
    isChangeDay: changeDays.contains(date),
    hasRefunds: day.moneyIn.isPositive,
  );
}
