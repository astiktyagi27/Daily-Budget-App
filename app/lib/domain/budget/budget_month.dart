import 'package:daily_budget/domain/budget/calendar_date.dart';

/// One budget month: from a salary date to the day before the next one
/// (F-006 §2.1).
///
/// It keeps the user's [salaryDay] (1 to 31), not the clamped start day, so a
/// salary day of 31 starts on 31 Mar again after a short February
/// (look-ahead #13b).
final class BudgetMonth {
  const new _(this.salaryDay, this.start, this.end);

  /// The budget month that starts in calendar [month] of [year]: on
  /// [salaryDay], or on that month's last day when it is shorter.
  factory startIn(int salaryDay, int year, int month) {
    _checkSalaryDay(salaryDay);
    final start = _startDateIn(salaryDay, year, month);
    final next = _startDateIn(salaryDay, year, month + 1);
    return BudgetMonth._(salaryDay, start, next.addDays(-1));
  }

  /// The budget month that contains [date].
  factory containing(int salaryDay, CalendarDate date) {
    _checkSalaryDay(salaryDay);
    final startThisMonth = _startDateIn(salaryDay, date.year, date.month);
    return date.isBefore(startThisMonth)
        ? BudgetMonth.startIn(salaryDay, date.year, date.month - 1)
        : BudgetMonth.startIn(salaryDay, date.year, date.month);
  }

  final int salaryDay;

  /// The first day of the month.
  final CalendarDate start;

  /// The last day of the month (the day before the next start).
  final CalendarDate end;

  /// The number of days, 28 to 31.
  int get length => start.daysUntil(end) + 1;

  /// Every day of the month, in order.
  List<CalendarDate> get days =>
      List.unmodifiable(List.generate(length, start.addDays));

  bool contains(CalendarDate date) =>
      !date.isBefore(start) && !date.isAfter(end);

  /// The budget month that starts the day after this one ends.
  BudgetMonth get next =>
      BudgetMonth.startIn(salaryDay, start.year, start.month + 1);

  /// The budget month that ends the day before this one starts.
  BudgetMonth get previous =>
      BudgetMonth.startIn(salaryDay, start.year, start.month - 1);

  static void _checkSalaryDay(int salaryDay) {
    if (salaryDay < 1 || salaryDay > 31) {
      throw ArgumentError.value(salaryDay, 'salaryDay', 'must be 1 to 31');
    }
  }

  // `month` may be 0 or 13: DateTime.utc rolls it into the next or previous
  // year, so only the normalised year and month are used.
  static CalendarDate _startDateIn(int salaryDay, int year, int month) {
    final first = DateTime.utc(year, month);
    final lastDay = CalendarDate.daysInMonth(first.year, first.month);
    return CalendarDate(
      first.year,
      first.month,
      salaryDay < lastDay ? salaryDay : lastDay,
    );
  }
}
