import 'package:daily_budget/domain/budget/month_result.dart';
import 'package:daily_budget/domain/budget/paise.dart';

/// Which words the Today line uses for its result (F-009 §2.2, D-050). The
/// word follows the exact paise; the screen formats the amount.
enum TodayResultKind {
  /// `₹x left today`.
  leftToday,

  /// Something is left, but less than ₹1: `less than ₹1 left today`.
  leftUnderRupee,

  /// Exactly ₹0: `on budget`.
  onBudget,

  /// Overspent by less than ₹1: `overspent less than ₹1`.
  overspentUnderRupee,

  /// `overspent ₹x`.
  overspent,
}

/// The numbers of the Transactions tab's Today line (F-009 §2.2), worked out
/// from the engine's result so no screen does money arithmetic.
final class TodayLine {
  const new({
    required this.budget,
    required this.netSpent,
    required this.result,
    required this.shortfall,
    this.moneyIn = Paise.zero,
  });

  /// The Today line of [result] for its own `today`. Throws an
  /// [ArgumentError] when today is not a budgeted day of the month (the tab
  /// shows the new-month card then).
  factory from(MonthResult result) {
    final today = result.today;
    if (!result.month.contains(today) ||
        today.isBefore(result.firstBudgetedDay)) {
      throw ArgumentError.value(today.iso, 'today', 'is not a budgeted day');
    }
    final day = result.dayOn(today);
    return TodayLine(
      budget: day.budget!,
      netSpent: day.netSpent,
      result: day.result!,
      shortfall: result.totals.shortfall,
      moneyIn: day.moneyIn,
    );
  }

  /// Today's budget from the period in force (D-037); ₹0 in a shortfall
  /// month (D-036).
  final Paise budget;

  /// What was spent today, net of money in (D-047).
  final Paise netSpent;

  /// What is left today (below ₹0 when overspent): the budget minus the net
  /// spend plus what was covered. Not in the savings pot until midnight
  /// (D-039).
  final Paise result;

  /// The month's shortfall (D-036), shown as `−₹x this month`; ₹0 if none.
  final Paise shortfall;

  /// The money in (refunds, D-047) received today, already inside
  /// [netSpent]: Home says `Includes ₹500 back from refunds`. ₹0 if none.
  final Paise moneyIn;

  /// The amount after the result word: `result` without its sign.
  Paise get amount => result.isNegative ? -result : result;

  TodayResultKind get kind {
    final underRupee = amount.value < 100;
    if (result.isZero) return TodayResultKind.onBudget;
    if (result.isNegative) {
      return underRupee
          ? TodayResultKind.overspentUnderRupee
          : TodayResultKind.overspent;
    }
    return underRupee
        ? TodayResultKind.leftUnderRupee
        : TodayResultKind.leftToday;
  }

  /// Whether to show the month's shortfall line.
  bool get hasShortfall => shortfall.isPositive;

  /// Whether today has money in, so Home adds the refunds line (AC-11).
  bool get hasRefunds => moneyIn.isPositive;
}
