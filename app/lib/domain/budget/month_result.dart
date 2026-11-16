import 'package:daily_budget/domain/budget/budget_month.dart';
import 'package:daily_budget/domain/budget/budget_period.dart';
import 'package:daily_budget/domain/budget/calendar_date.dart';
import 'package:daily_budget/domain/budget/paise.dart';
import 'package:daily_budget/domain/budget/spend.dart';

/// The state of one day of the month (F-006 §2.3).
enum DayStatus {
  /// Before the first budgeted day of a mid-month start: no budget, no
  /// result, in no total.
  notBudgeted,

  /// After today: no result yet.
  upcoming,

  /// Today: the result so far is what is left today (D-039).
  live,

  saved,
  onBudget,
  overspent,
}

/// One day of the month. `budget` is null for a not-budgeted day; `result`
/// (budget − net spend + covered) is null for not-budgeted and upcoming days.
/// `spent` is the GROSS sum of the spends, `moneyIn` the sum of the money in
/// and `netSpent` is `spent - moneyIn`, the figure the screens show (D-047).
typedef DayResult = ({
  CalendarDate date,
  DayStatus status,
  Paise? budget,
  Paise spent,
  Paise netSpent,
  Paise moneyIn,
  Paise covered,
  Paise? result,
});

/// One period of the month's history with its own totals (F-006 §2.7).
///
/// A `superseded` period was replaced by a later change on the same day: it
/// is kept for the history, with no days (`end` is the day before `start`).
/// The money totals count the period's days up to today, like the month's.
/// `netSpent` is the spends minus the money in.
typedef PeriodResult = ({
  BudgetPeriod period,
  bool superseded,
  CalendarDate start,
  CalendarDate end,
  int days,
  List<PeriodChange> changes,
  Paise amountToSpread,
  List<Paise> budgets,
  Paise shortfall,
  bool zeroSpendable,
  Paise netSpent,
  Paise moneyIn,
  Paise saved,
  Paise overspent,
  Paise covered,
});

/// The month's top summary (F-006 §2.5). `salary` and `target` are null for
/// a mid-month start. `spentSoFar` is net of money in. `shortfall` is the
/// current period's (D-048). `left` can be below ₹0.
typedef MonthTotals = ({
  Paise? salary,
  Paise? target,
  Paise fixedCosts,
  Paise budgeted,
  Paise spentSoFar,
  Paise moneyIn,
  Paise saved,
  Paise covered,
  Paise overspent,
  Paise pot,
  Paise shortfall,
  Paise left,
});

/// The amount a cover really moves after the clamp and any D-040 reduction.
/// The repository stores it when it differs from the saved amount (D-048).
typedef EffectiveCover = ({int coverId, CalendarDate day, Paise amount});

/// A cover reduced because the pot shrank below what was covered (D-040).
typedef CoverReduction = ({
  int coverId,
  CalendarDate day,
  Paise oldAmount,
  Paise newAmount,
});

/// What a [CoverReduction] took back, for the "Savings pot updated" note.
extension CoverReductionCut on CoverReduction {
  /// How much of the cover was taken back: `oldAmount - newAmount`.
  Paise get cut => oldAmount - newAmount;

  /// Whether the cut is under ₹1 (D-055: the note says `less than ₹1`).
  bool get cutIsUnderRupee => cut.value < 100;
}

/// Everything the engine works out for one month.
final class MonthResult {
  const new({
    required this.month,
    required this.firstBudgetedDay,
    required this.today,
    required this.days,
    required this.periods,
    required this.totals,
    required this.effectiveCovers,
    required this.reductions,
    required this.ignoredSpends,
    required this.currentPeriodIndex,
  });

  final BudgetMonth month;

  final CalendarDate firstBudgetedDay;

  final CalendarDate today;

  /// Every day of the month, in order.
  final List<DayResult> days;

  /// Every period in history order, superseded ones included.
  final List<PeriodResult> periods;

  final MonthTotals totals;

  /// One entry per input cover, in input order.
  final List<EffectiveCover> effectiveCovers;

  /// The covers reduced by D-040, newest first. Over-cover clamps are not
  /// listed here (they need no note, F-006 §4).
  final List<CoverReduction> reductions;

  /// Spends outside the month or before the first budgeted day, left out of
  /// every total (F-006 §4).
  final List<Spend> ignoredSpends;

  /// The index in [periods] of [currentPeriod].
  final int currentPeriodIndex;

  /// The result of [date]. Throws an [ArgumentError] for a date outside the
  /// month.
  DayResult dayOn(CalendarDate date) {
    if (!month.contains(date)) {
      throw ArgumentError.value(date.iso, 'date', 'is not in the month');
    }
    return days[month.start.daysUntil(date)];
  }

  /// The period in force today: the first one before the month, the last one
  /// after it. Superseded periods are never current.
  PeriodResult get currentPeriod => periods[currentPeriodIndex];
}
