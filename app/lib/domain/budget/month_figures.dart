import 'package:daily_budget/domain/budget/calendar_date.dart';
import 'package:daily_budget/domain/budget/month_result.dart';
import 'package:daily_budget/domain/budget/paise.dart';

/// The day with the highest net spend among the ended days (F-013 AC-8,
/// AC-10): the earliest date wins a tie and `moreDays` counts the others.
typedef HighestDay = ({CalendarDate date, Paise amount, int moreDays});

/// How the ended days turned out (F-013 AC-8, AC-9). `covered` counts ended
/// days with any cover above ₹0, full or partial (D-080 (3)).
typedef DayCounts = ({int saved, int onBudget, int overspent, int covered});

/// The figures of "This month in numbers" (F-013 T-382). Only ended days
/// count: budgeted days with the status saved, on budget or overspent. Today
/// (live), the days to come and the days before a mid-month start are left
/// out (D-039, D-080 (1)).
final class MonthFigures {
  const new({
    required this.endedDays,
    required this.highest,
    required this.average,
    required this.counts,
    required this.strip,
  });

  /// How many days have ended.
  final int endedDays;

  /// Null when no ended day has a net spend above ₹0 (all ₹0, or only
  /// refund days): the card says `No spends yet` (D-080 (2)).
  final HighestDay? highest;

  /// The ended days' net spend divided by [endedDays], in whole paise rounded
  /// toward zero (D-046). Null when no day has ended.
  final Paise? average;

  final DayCounts counts;

  /// The status of every ended day in date order (the decorative strip).
  final List<DayStatus> strip;

  /// Whether the first day is not over yet: the card shows one sentence.
  bool get noEndedDays => endedDays == 0;
}

/// The figures of [result] over its ended days.
MonthFigures monthFigures(MonthResult result) {
  final strip = <DayStatus>[];
  var sum = 0;
  var saved = 0;
  var onBudget = 0;
  var overspent = 0;
  var covered = 0;
  CalendarDate? highestDate;
  var highestValue = 0;
  var ties = 0;
  for (final day in result.days) {
    switch (day.status) {
      case DayStatus.saved:
        saved++;
      case DayStatus.onBudget:
        onBudget++;
      case DayStatus.overspent:
        overspent++;
      case DayStatus.notBudgeted || DayStatus.upcoming || DayStatus.live:
        continue;
    }
    strip.add(day.status);
    final net = day.netSpent.value;
    sum += net;
    if (day.covered.isPositive) covered++;
    if (net > highestValue) {
      highestValue = net;
      highestDate = day.date;
      ties = 0;
    } else if (net == highestValue) {
      // Only counts when a highest day exists: a bigger day resets it, and
      // `highestDate` stays null while every net is 0 or below.
      ties++;
    }
  }
  final ended = strip.length;
  return MonthFigures(
    endedDays: ended,
    highest: highestDate == null
        ? null
        : (date: highestDate, amount: Paise(highestValue), moreDays: ties),
    average: ended == 0 ? null : Paise(sum ~/ ended),
    counts: (
      saved: saved,
      onBudget: onBudget,
      overspent: overspent,
      covered: covered,
    ),
    strip: List.unmodifiable(strip),
  );
}
