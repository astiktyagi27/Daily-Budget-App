import 'package:daily_budget/domain/budget/budget_period.dart';
import 'package:daily_budget/domain/budget/calendar_date.dart';
import 'package:daily_budget/domain/budget/cover_draft.dart';
import 'package:daily_budget/domain/budget/month_result.dart';
import 'package:daily_budget/domain/budget/paise.dart';

/// Which words a day's result uses (F-011 §2.1, F-012 §2.1, D-050, D-055).
/// The word follows the exact paise; the screen formats the amount. For
/// today's live day the "saved" words read "left" (`₹410 left`).
enum DayResultKind {
  /// `Saved ₹x` (today: `₹x left`).
  saved,

  /// Saved, but less than ₹1 (today: `less than ₹1 left`).
  savedUnderRupee,

  /// Exactly ₹0: `On budget`.
  onBudget,

  /// Overspent by less than ₹1: `Overspent less than ₹1`.
  overspentUnderRupee,

  /// `Overspent ₹x`.
  overspent,
}

/// The words for a day [result] (budget − net spent + covered), by its exact
/// paise: under ₹1 is under 100 paise.
DayResultKind dayResultKind(Paise result) {
  if (result.isZero) return DayResultKind.onBudget;
  final underRupee = result.value.abs() < 100;
  if (result.isNegative) {
    return underRupee
        ? DayResultKind.overspentUnderRupee
        : DayResultKind.overspent;
  }
  return underRupee ? DayResultKind.savedUnderRupee : DayResultKind.saved;
}

/// Whether and how much a day may be covered from savings (F-012 §2.3).
sealed class CoverOffer {
  const new();
}

/// No cover card: the day is not an overspent budgeted day of a month that
/// is still running.
final class CoverNone extends CoverOffer {
  const new();
}

/// The day is overspent but the savings pot is ₹0: the card says so and has
/// no button (AC-10).
final class CoverPotEmpty extends CoverOffer {
  const new();
}

/// The day can be covered by up to [max] (the lesser of the pot and the
/// uncovered overspend). [limitedByPot] is true when the pot is the smaller
/// limit, so the caption reads `This uses your whole savings pot.`.
final class CoverAvailable extends CoverOffer {
  const new({required this.max, required this.limitedByPot});

  final Paise max;

  final bool limitedByPot;
}

/// Everything day details shows for one day, as exact paise and flags, so no
/// widget does money arithmetic (F-012 plan §1.1). It adds no money rule: the
/// figures are the engine's, the cover limit is `maxCover` of the engine's
/// pot and uncovered overspend.
final class DaySummary {
  const new _({
    required this.date,
    required this.status,
    required this.resultKind,
    required this.budget,
    required this.spent,
    required this.moneyIn,
    required this.netSpent,
    required this.covered,
    required this.result,
    required this.pot,
    required this.firstBudgetedDay,
    required this.isEnded,
    required this.coverOffer,
    required this.coverIds,
    required this.isChangeDay,
    required this.changes,
  });

  /// The summary of [date] in [result]'s month. Throws an [ArgumentError]
  /// for a date outside the month.
  factory of(MonthResult result, CalendarDate date) {
    final day = result.dayOn(date);
    final dayResult = day.result;
    final isEnded = result.today.isAfter(result.month.end);
    final pot = result.totals.pot;
    final overspend = dayResult == null ? Paise.zero : (-dayResult).orZero;
    final offerable =
        !isEnded &&
        (day.status == DayStatus.overspent ||
            (day.status == DayStatus.live && overspend.isPositive));
    final max = maxCover(pot: pot, overspend: overspend);
    final kept = result.periods.where((p) => !p.superseded).toList();
    // The net difference from the period before, so a same-day double change
    // reads as the statement does (D-081 (6)); empty when it nets to nothing.
    final changeIndex = kept.indexWhere((p) => p.start == date);
    final isChangeDay = changeIndex > 0;
    return DaySummary._(
      date: date,
      status: day.status,
      resultKind: dayResult == null ? null : dayResultKind(dayResult),
      budget: day.budget,
      spent: day.spent,
      moneyIn: day.moneyIn,
      netSpent: day.netSpent,
      covered: day.covered,
      result: dayResult,
      pot: pot,
      firstBudgetedDay: result.firstBudgetedDay,
      isEnded: isEnded,
      coverOffer: !offerable
          ? const CoverNone()
          : max == null
          ? const CoverPotEmpty()
          : CoverAvailable(max: max, limitedByPot: overspend > pot),
      coverIds: Set.unmodifiable({
        for (final cover in result.effectiveCovers)
          if (cover.day == date) cover.coverId,
      }),
      isChangeDay: isChangeDay,
      changes: isChangeDay
          ? List.unmodifiable(
              kept[changeIndex].period.values.changesFrom(
                kept[changeIndex - 1].period.values,
              ),
            )
          : const [],
    );
  }

  final CalendarDate date;

  final DayStatus status;

  /// The words of the result; null for a not-budgeted or upcoming day.
  final DayResultKind? resultKind;

  /// The day's budget; null for a not-budgeted day.
  final Paise? budget;

  /// The gross spends of the day.
  final Paise spent;

  /// The money in (refunds) of the day.
  final Paise moneyIn;

  /// `spent - moneyIn`; below ₹0 when the refunds are larger (D-047).
  final Paise netSpent;

  /// What savings covers on this day, after the clamp and any D-040 cut.
  final Paise covered;

  /// Budget − net spent + covered; null for a not-budgeted or upcoming day.
  final Paise? result;

  /// The month's savings pot.
  final Paise pot;

  final CalendarDate firstBudgetedDay;

  /// The month is over (today is after its last day): the day is read-only
  /// (F-012 §2.6).
  final bool isEnded;

  final CoverOffer coverOffer;

  /// The ids of every cover stored for this day, including ones cut to ₹0:
  /// Remove deletes them all.
  final Set<int> coverIds;

  /// A later period starts on this day (the `Budget changed on this day`
  /// line). Its [changes] are empty when same-day changes net to nothing.
  final bool isChangeDay;

  /// What changed on this day, net, when [isChangeDay]; empty on every other
  /// day.
  final List<PeriodChange> changes;

  /// Today's live day: the result so far is what is left (D-039).
  bool get isLive => status == DayStatus.live;

  bool get isUpcoming => status == DayStatus.upcoming;

  bool get isBudgeted => status != DayStatus.notBudgeted;

  /// The day's uncovered overspend: `Overspent ₹300` after any cover; ₹0
  /// when it is not overspent.
  Paise get overspend {
    final result = this.result;
    return result == null ? Paise.zero : (-result).orZero;
  }

  /// The uncovered overspend is above ₹0 but under ₹1 (under 100 paise,
  /// D-050, D-055): the cover sheet then says `Overspent less than ₹1`.
  bool get overspendUnderRupee =>
      dayResultKind(-overspend) == DayResultKind.overspentUnderRupee;

  /// Whether the figures add a Refunds and a Net spent line (AC-16).
  bool get hasRefunds => moneyIn.isPositive;

  /// Whether the figures add `Covered from savings` (any cover above ₹0).
  bool get hasCover => covered.isPositive;

  /// Remove is offered on a covered day of a month that is still running; a
  /// cover cut to ₹0 by D-040 has nothing to remove (AC-22).
  bool get canRemoveCover => hasCover && !isEnded;

  /// The inline note `Covered ₹300 from savings.` replaces the cover card
  /// once the day is fully covered (design §5).
  bool get isFullyCovered => canRemoveCover && result == Paise.zero;

  /// Add spend is offered on a budgeted day up to today in a running month
  /// (AC-12).
  bool get canAddSpend => !isEnded && isBudgeted && !isUpcoming;
}
