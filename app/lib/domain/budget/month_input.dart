import 'package:daily_budget/domain/budget/budget_month.dart';
import 'package:daily_budget/domain/budget/budget_period.dart';
import 'package:daily_budget/domain/budget/calendar_date.dart';
import 'package:daily_budget/domain/budget/cover.dart';
import 'package:daily_budget/domain/budget/spend.dart';

/// Every stored fact of one budget month, plus the "today" the caller passes
/// in. Nothing derived is stored, so the result can never go stale.
final class MonthInput {
  const new({
    required this.month,
    required this.firstBudgetedDay,
    required this.periods,
    required this.today,
    this.spends = const [],
    this.covers = const [],
  });

  final BudgetMonth month;

  /// The month's start, or the setup day of a mid-month start (D-034, D-057).
  final CalendarDate firstBudgetedDay;

  /// Every period ever saved for the month, in any order (D-037).
  final List<BudgetPeriod> periods;

  final CalendarDate today;

  final List<Spend> spends;

  final List<Cover> covers;
}
