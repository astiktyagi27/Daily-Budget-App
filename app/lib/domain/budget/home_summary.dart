import 'package:daily_budget/domain/budget/budget_period.dart';
import 'package:daily_budget/domain/budget/calendar_date.dart';
import 'package:daily_budget/domain/budget/month_result.dart';
import 'package:daily_budget/domain/budget/paise.dart';

/// What Home's summary card shows (F-010 §2), taken straight from a finished
/// [MonthResult] so no screen does money arithmetic. Every amount is exact
/// paise; the screen rounds toward zero when it formats them (D-038).
///
/// Phase 3 only displays the engine's numbers: nothing here is a money rule.
/// The one derived value, [progressPermille], is for drawing the progress
/// rule and is never shown as a number.
final class HomeSummary {
  const new({
    required this.left,
    required this.dailyBudget,
    required this.rangeStart,
    required this.rangeEnd,
    required this.salary,
    required this.target,
    required this.moneyLeftAtStart,
    required this.fixedCosts,
    required this.spentSoFar,
    required this.saved,
    required this.overspent,
    required this.pot,
    required this.covered,
    required this.progressPermille,
    required this.shortfall,
    required this.zeroSpendable,
    required this.startedLate,
    required this.latestChangeDay,
  });

  /// The card's view of [result] for its own `today`.
  factory from(MonthResult result) {
    final totals = result.totals;
    final period = result.currentPeriod;
    final values = period.period.values;
    final salary = totals.salary;
    final target = totals.target;
    final inForce = [
      for (final p in result.periods)
        if (!p.superseded) p,
    ];
    return HomeSummary(
      left: totals.left,
      dailyBudget: _dailyBudget(result),
      rangeStart: result.firstBudgetedDay,
      rangeEnd: result.month.end,
      salary: salary,
      // The engine reports the salary as the target when none was set, so a
      // target is only worth a row when it is lower (F-010 AC-10).
      target: salary != null && target != null && salary > target
          ? target
          : null,
      moneyLeftAtStart: switch (values) {
        MidMonthStartValues(:final moneyLeft) => moneyLeft,
        FullMonthValues() => null,
      },
      fixedCosts: totals.fixedCosts,
      spentSoFar: totals.spentSoFar,
      saved: totals.saved,
      overspent: totals.overspent,
      pot: totals.pot,
      covered: totals.covered,
      progressPermille: _progressPermille(totals.spentSoFar, totals.budgeted),
      shortfall: period.shortfall,
      zeroSpendable: period.zeroSpendable,
      startedLate: result.firstBudgetedDay != result.month.start,
      latestChangeDay: inForce.length > 1 ? inForce.last.start : null,
    );
  }

  /// What is left this month: budgeted minus spent so far minus the
  /// shortfall. Below ₹0 when over.
  final Paise left;

  /// Today's budget, or the current period's first daily budget when today
  /// is outside the budgeted days (a phone date set back).
  final Paise dailyBudget;

  /// The first budgeted day: the month's start, or the setup day of a
  /// mid-month first month (D-034, D-057).
  final CalendarDate rangeStart;

  /// The month's last day.
  final CalendarDate rangeEnd;

  /// The current period's salary; null for a mid-month start.
  final Paise? salary;

  /// The spending target, only when it is lower than [salary].
  final Paise? target;

  /// The money on the first budgeted day, shown instead of the salary for a
  /// mid-month start; null for a normal month.
  final Paise? moneyLeftAtStart;

  final Paise fixedCosts;

  /// Net of money in (D-047); negative when refunds beat the spends.
  final Paise spentSoFar;

  final Paise saved;

  /// Includes today's live overspend (D-060).
  final Paise overspent;

  final Paise pot;

  /// What covers have moved out of the pot.
  final Paise covered;

  /// How far along the progress rule is, 0 to 1000 (integer, never a
  /// fraction): spent so far over the month's budgeted money, rounded down.
  /// Full when nothing is budgeted or at least all of it is spent, empty
  /// when spent so far is ₹0 or less.
  final int progressPermille;

  /// The current period's shortfall (D-036); ₹0 if none.
  final Paise shortfall;

  /// The current period's spendable money is exactly ₹0 (D-043).
  final bool zeroSpendable;

  /// The month's first budgeted day is after its start (D-034, D-057).
  final bool startedLate;

  /// The start of the latest budget change, when the month has more than one
  /// period (D-037); null otherwise.
  final CalendarDate? latestChangeDay;

  /// Whole rupees of [left] are below zero: the card says it is over.
  /// Less than ₹1 below zero still reads `₹0` (no `−₹0`, D-050).
  bool get isOver => left.value <= -100;

  bool get hasShortfall => shortfall.isPositive;

  /// A cover exists, so the pot sub-line is shown under Saved.
  bool get hasCover => covered.isPositive;

  /// Saved is at least ₹1, so it gets its ● and colour (design H-3).
  bool get savedHasMark => saved.value >= 100;

  /// Overspent is at least ₹1, so it gets its ◆ and colour (design H-3).
  bool get overspentHasMark => overspent.value >= 100;

  /// More than one budget period is in force this month.
  bool get hasChanged => latestChangeDay != null;

  static Paise _dailyBudget(MonthResult result) {
    if (result.month.contains(result.today)) {
      final budget = result.dayOn(result.today).budget;
      if (budget != null) return budget;
    }
    return result.currentPeriod.budgets.first;
  }

  static int _progressPermille(Paise spent, Paise budgeted) {
    if (!budgeted.isPositive || spent.value >= budgeted.value) return 1000;
    if (!spent.isPositive) return 0;
    return spent.value * 1000 ~/ budgeted.value;
  }
}
