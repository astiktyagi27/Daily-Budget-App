import 'package:daily_budget/domain/budget/month_result.dart';
import 'package:daily_budget/domain/budget/paise.dart';

/// What the Safe to spend line on Home's summary card says (F-017, D-058):
/// everything left this month, savings pot included, spread evenly over the
/// days left with today counted. A guide only: it never feeds back into a
/// budget, a result, the pot or a total (AC-10).
sealed class SafeToSpend {
  const new();
}

/// `₹899 a day · 22 days left`: [perDay] is at least ₹1, rounded down.
final class SafeToSpendAmount extends SafeToSpend {
  const new(this.perDay, this.daysLeft);

  final Paise perDay;

  final int daysLeft;
}

/// Some money is left but less than ₹1 a day: `less than ₹1 a day` (D-050).
/// Classified by the amount to spread, not by the rounded daily figure.
final class SafeToSpendUnderRupee extends SafeToSpend {
  const new(this.daysLeft);

  final int daysLeft;
}

/// Nothing to spread: the amount is ₹0 or below.
final class SafeToSpendNothingLeft extends SafeToSpend {
  const new();
}

/// Today is not a budgeted day (the device date was set back or is past the
/// month's end), so there is no count of days left and the line is hidden
/// (D-076 (1)).
final class SafeToSpendUnavailable extends SafeToSpend {
  const new();
}

/// The pure core of Safe to spend (D-076 (4)): [left] plus [todayNetSpend]
/// (both exact paise) spread over [daysLeft] days, rounded down. A
/// [daysLeft] below 1 counts as 1, so it never divides by zero.
///
/// The line never returns [SafeToSpendUnavailable]; only
/// [safeToSpendPerDay] does.
SafeToSpend safeToSpendFrom({
  required Paise left,
  required Paise todayNetSpend,
  required int daysLeft,
}) {
  final days = daysLeft < 1 ? 1 : daysLeft;
  final toSpread = left + todayNetSpend;
  if (!toSpread.isPositive) return const SafeToSpendNothingLeft();
  final perDay = Paise(toSpread.value ~/ days);
  if (perDay.value < 100) return SafeToSpendUnderRupee(days);
  return SafeToSpendAmount(perDay, days);
}

/// Safe to spend for [result] on its own `today`.
///
/// Reads `totals.left`, today's net spend (refunds already taken off,
/// D-047) and the days from today to the month's last day, today included.
/// Spending today lowers `left` and raises today's net spend by the same
/// amount, so the figure stays the same all day (AC-2); covers change
/// neither (AC-3).
SafeToSpend safeToSpendPerDay(MonthResult result) {
  final today = result.today;
  if (!result.month.contains(today) ||
      today.isBefore(result.firstBudgetedDay)) {
    return const SafeToSpendUnavailable();
  }
  return safeToSpendFrom(
    left: result.totals.left,
    todayNetSpend: result.dayOn(today).netSpent,
    daysLeft: today.daysUntil(result.month.end) + 1,
  );
}
