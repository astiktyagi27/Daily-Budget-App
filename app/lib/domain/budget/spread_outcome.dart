import 'package:daily_budget/domain/budget/budget_month.dart';
import 'package:daily_budget/domain/budget/budget_period.dart';
import 'package:daily_budget/domain/budget/calendar_date.dart';
import 'package:daily_budget/domain/budget/paise.dart';

/// The day budgets a period would get (F-006 §2.2, §2.7, §2.8). The month
/// setup preview, the shortfall warning and the saved month all use this, so
/// they can never disagree.
sealed class SpreadOutcome {
  const new(this.amountToSpread, this.budgets);

  /// The period's spendable minus the budgets of the days before it; below
  /// ₹0 for a shortfall.
  final Paise amountToSpread;

  /// One budget per day from the period's first day to the month's end; ₹0
  /// a day for [Shortfall] and [ZeroSpendable], never below ₹0.
  final List<Paise> budgets;
}

/// A positive amount, spread with the extra paise on the first days (D-035).
final class Spread extends SpreadOutcome {
  const new(super.amountToSpread, super.budgets);
}

/// Exactly ₹0 to spread: no shortfall, but every day is ₹0 and the user gets
/// the same choice as for a shortfall (D-043).
final class ZeroSpendable extends SpreadOutcome {
  const new(super.amountToSpread, super.budgets);
}

/// Less than ₹0 to spread (D-036). Every day is ₹0 if the user continues.
final class Shortfall extends SpreadOutcome {
  const new(super.amountToSpread, super.budgets);

  /// How much is missing, in positive paise.
  Paise get amount => -amountToSpread;
}

/// Plans a period that starts [from] in [month] with [values] (§2.7).
///
/// [earlierBudgets] are the budgets of the budgeted days before [from], from
/// [firstBudgetedDay] on. The amount to spread is the spendable minus their
/// sum; it is spread from [from] to the month's end. Throws an
/// [ArgumentError] for dates outside the month, a wrong number of earlier
/// budgets or invalid values (D-048).
SpreadOutcome planPeriod({
  required BudgetMonth month,
  required CalendarDate firstBudgetedDay,
  required List<Paise> earlierBudgets,
  required PeriodValues values,
  required CalendarDate from,
}) {
  if (!month.contains(firstBudgetedDay)) {
    throw ArgumentError.value(firstBudgetedDay.iso, 'firstBudgetedDay');
  }
  if (!month.contains(from) || from.isBefore(firstBudgetedDay)) {
    throw ArgumentError.value(from.iso, 'from', 'is not a budgeted day');
  }
  if (earlierBudgets.length != firstBudgetedDay.daysUntil(from)) {
    throw ArgumentError.value(
      earlierBudgets.length,
      'earlierBudgets',
      'must have one budget per day before ${from.iso}',
    );
  }
  values.validate();
  final amount = values.spendable - Paise.sum(earlierBudgets);
  final days = from.daysUntil(month.end) + 1;
  if (amount.isPositive) return Spread(amount, amount.spreadOver(days));
  final zeros = List<Paise>.unmodifiable(List.filled(days, Paise.zero));
  return amount.isZero
      ? ZeroSpendable(amount, zeros)
      : Shortfall(amount, zeros);
}
