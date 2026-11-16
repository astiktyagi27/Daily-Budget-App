import 'package:daily_budget/domain/budget/budget_month.dart';
import 'package:daily_budget/domain/budget/budget_period.dart';
import 'package:daily_budget/domain/budget/calendar_date.dart';
import 'package:daily_budget/domain/budget/cover.dart';
import 'package:daily_budget/domain/budget/month_input.dart';
import 'package:daily_budget/domain/budget/month_result.dart';
import 'package:daily_budget/domain/budget/paise.dart';
import 'package:daily_budget/domain/budget/spend.dart';
import 'package:daily_budget/domain/budget/spread_outcome.dart';

/// Works out every number of one budget month from its stored facts and the
/// "today" passed in (F-006 §2). Pure: the same input always gives the same
/// result. Throws an [ArgumentError] for input the screens never send
/// (§2.9, D-048).
MonthResult computeMonth(MonthInput input) {
  final month = input.month;
  final first = input.firstBudgetedDay;
  if (!month.contains(first)) {
    throw ArgumentError.value(first.iso, 'firstBudgetedDay', 'not in month');
  }
  final coverIds = <int>{};
  for (final cover in input.covers) {
    if (!coverIds.add(cover.id)) {
      throw ArgumentError.value(cover.id, 'covers', 'has a duplicate id');
    }
  }
  final plans = _planPeriods(month, first, input.periods);
  final budgets = <Paise>[
    for (final plan in plans) ...plan.outcome.budgets.take(plan.days),
  ];
  final dayCount = budgets.length;
  // Budgeted days before this index are final; this one is live (D-039).
  final todayIndex = first.daysUntil(input.today);

  final spent = List.filled(dayCount, Paise.zero);
  final moneyIn = List.filled(dayCount, Paise.zero);
  final ignored = <Spend>[];
  for (final spend in input.spends) {
    if (!spend.amount.isPositive) {
      throw ArgumentError.value(spend.amount.value, 'spend', 'must be above 0');
    }
    final i = first.daysUntil(spend.date);
    if (i < 0 || i >= dayCount) {
      ignored.add(spend);
      continue;
    }
    switch (spend.direction) {
      case SpendDirection.spend:
        spent[i] += spend.amount;
      case SpendDirection.moneyIn:
        moneyIn[i] += spend.amount;
    }
  }
  final uncoveredResult = [
    for (var i = 0; i < dayCount; i++) budgets[i] - spent[i] + moneyIn[i],
  ];

  final covers = _effectiveCovers(input.covers, first, uncoveredResult);
  final savedBeforeCovers = Paise.sum([
    for (var i = 0; i < dayCount && i < todayIndex; i++)
      uncoveredResult[i].orZero,
  ]);
  final reductions = _reduceNewestFirst(
    covers,
    savedBeforeCovers,
    (cover) => first.daysUntil(cover.day) <= todayIndex,
  );
  final covered = List.filled(dayCount, Paise.zero);
  final amountOf = Map<Cover, Paise>.identity();
  for (final cover in covers) {
    covered[first.daysUntil(cover.day)] += cover.amount;
    amountOf[cover.source] = cover.amount;
  }

  final days = <DayResult>[
    for (final date in month.days)
      _dayResult(
        date,
        first.daysUntil(date),
        todayIndex,
        budgets,
        spent,
        moneyIn,
        covered,
      ),
  ];
  final budgetedResults = days.skip(month.start.daysUntil(first)).toList();
  _Sums sumOf(int from, int count) =>
      _Sums.of(budgetedResults.skip(from).take(count), from, todayIndex);

  var from = 0;
  final periods = <PeriodResult>[];
  for (final plan in plans) {
    final sums = sumOf(from, plan.days);
    periods.add((
      period: plan.period,
      superseded: plan.superseded,
      start: plan.period.start,
      end: plan.period.start.addDays(plan.days - 1),
      days: plan.days,
      changes: plan.changes,
      amountToSpread: plan.outcome.amountToSpread,
      budgets: List.unmodifiable(budgets.skip(from).take(plan.days)),
      shortfall: _shortfallOf(plan.outcome),
      zeroSpendable: plan.outcome is ZeroSpendable,
      netSpent: sums.netSpent,
      moneyIn: sums.moneyIn,
      saved: sums.saved,
      overspent: sums.overspent,
      covered: sums.covered,
    ));
    from += plan.days;
  }

  final current = _currentPlan(plans, todayIndex);
  final whole = sumOf(0, dayCount);
  final (salary, target) = switch (current.period.values) {
    FullMonthValues(salary: final full, :final monthlyTarget) => (
      full,
      monthlyTarget,
    ),
    MidMonthStartValues() => (null, null),
  };
  final budgeted = Paise.sum(budgets);
  final shortfall = _shortfallOf(current.outcome);
  return MonthResult(
    month: month,
    firstBudgetedDay: first,
    today: input.today,
    days: List.unmodifiable(days),
    periods: List.unmodifiable(periods),
    totals: (
      salary: salary,
      target: target,
      fixedCosts: current.period.values.fixedCostsTotal,
      budgeted: budgeted,
      spentSoFar: whole.netSpent,
      moneyIn: whole.moneyIn,
      saved: whole.saved,
      covered: whole.covered,
      overspent: whole.overspent,
      pot: whole.saved - whole.covered,
      shortfall: shortfall,
      left: budgeted - whole.netSpent - shortfall,
    ),
    effectiveCovers: List.unmodifiable([
      for (final cover in input.covers)
        (coverId: cover.id, day: cover.day, amount: amountOf[cover]!),
    ]),
    reductions: List.unmodifiable(reductions),
    ignoredSpends: List.unmodifiable(ignored),
    currentPeriodIndex: plans.indexOf(current),
  );
}

/// Why a cover is refused, in the order the rules are checked (D-048).
enum CoverRefusal {
  notPositive,
  outsideMonth,
  notBudgeted,
  upcoming,
  notOverspent,
  exceedsOverspend,
  exceedsPot,
}

/// Whether a "Cover with savings" move may be made (F-006 §2.4).
sealed class CoverDecision {
  const new();
}

final class CoverAllowed extends CoverDecision {
  const new();
}

final class CoverRefused extends CoverDecision {
  const new(this.reason);

  final CoverRefusal reason;
}

/// Checks a cover of [amount] for [day] against [result]. Changes nothing;
/// the caller stores an allowed cover and computes the month again.
/// Today's live day may be covered (D-048).
CoverDecision checkCover(MonthResult result, CalendarDate day, Paise amount) {
  final reason = _refusalFor(result, day, amount);
  return reason == null ? const CoverAllowed() : CoverRefused(reason);
}

CoverRefusal? _refusalFor(MonthResult result, CalendarDate day, Paise amount) {
  if (!amount.isPositive) return CoverRefusal.notPositive;
  if (!result.month.contains(day)) return CoverRefusal.outsideMonth;
  if (day.isBefore(result.firstBudgetedDay)) return CoverRefusal.notBudgeted;
  if (day.isAfter(result.today)) return CoverRefusal.upcoming;
  final uncovered = (-result.dayOn(day).result!).orZero;
  if (uncovered.isZero) return CoverRefusal.notOverspent;
  if (amount > uncovered) return CoverRefusal.exceedsOverspend;
  if (amount > result.totals.pot) return CoverRefusal.exceedsPot;
  return null;
}

/// Which month month setup works on (F-008 §2.11).
sealed class MonthState {
  const new(this.month);

  final BudgetMonth month;
}

/// No month was ever set up; [month] contains today.
final class NoMonthYet extends MonthState {
  const new(super.month);
}

/// Today is in the last set-up month (or before it, if the device date
/// moved back).
final class CurrentMonth extends MonthState {
  const new(super.month);
}

/// Today is after the last set-up month. [month] contains today; whole
/// months in between are skipped, never created.
final class NewMonthStarted extends MonthState {
  const new(super.month, {required this.missedMonths});

  final int missedMonths;
}

/// The month state for [today], given the last set-up month (null if none).
MonthState monthStateFor({
  required int salaryDay,
  required BudgetMonth? lastMonth,
  required CalendarDate today,
}) {
  final containing = BudgetMonth.containing(salaryDay, today);
  if (lastMonth == null) return NoMonthYet(containing);
  if (lastMonth.salaryDay != salaryDay) {
    throw ArgumentError.value(salaryDay, 'salaryDay', 'differs from month');
  }
  if (!today.isAfter(lastMonth.end)) return CurrentMonth(lastMonth);
  var missed = 0;
  for (var m = lastMonth.next; m.end.isBefore(today); m = m.next) {
    missed++;
  }
  return NewMonthStarted(containing, missedMonths: missed);
}

typedef _PeriodPlan = ({
  BudgetPeriod period,
  bool superseded,
  int days,
  SpreadOutcome outcome,
  List<PeriodChange> changes,
});

/// Orders the periods by start day and change time (AC-22) and plans each
/// one; only the last change of a day is in force from that day.
List<_PeriodPlan> _planPeriods(
  BudgetMonth month,
  CalendarDate first,
  List<BudgetPeriod> periods,
) {
  if (periods.isEmpty) {
    throw ArgumentError.value(periods, 'periods', 'must not be empty');
  }
  final sorted = [...periods.indexed]
    ..sort((a, b) {
      final byStart = a.$2.start.compareTo(b.$2.start);
      if (byStart != 0) return byStart;
      final byTime = a.$2.changedAt.compareTo(b.$2.changedAt);
      return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
    });
  final ordered = [for (final (_, period) in sorted) period];
  if (ordered.first.start != first) {
    throw ArgumentError.value(
      ordered.first.start.iso,
      'periods',
      'the first period must start on the first budgeted day ${first.iso}',
    );
  }
  final plans = <_PeriodPlan>[];
  final earlier = <Paise>[];
  for (var j = 0; j < ordered.length; j++) {
    final period = ordered[j];
    final outcome = planPeriod(
      month: month,
      firstBudgetedDay: first,
      earlierBudgets: earlier,
      values: period.values,
      from: period.start,
    );
    final next = ordered.skip(j + 1).firstOrNull;
    final superseded = next != null && next.start == period.start;
    if (!superseded && outcome is! Spread && !period.continuedWithShortfall) {
      throw ArgumentError.value(
        period.start.iso,
        'periods',
        'a shortfall or ₹0 period must be continued with a shortfall',
      );
    }
    final days = superseded
        ? 0
        : period.start.daysUntil(next?.start ?? month.end.addDays(1));
    earlier.addAll(outcome.budgets.take(days));
    plans.add((
      period: period,
      superseded: superseded,
      days: days,
      outcome: outcome,
      changes: period.diff(j == 0 ? null : ordered[j - 1]),
    ));
  }
  return plans;
}

/// The period in force today: the first one before the month, the last one
/// after it.
_PeriodPlan _currentPlan(List<_PeriodPlan> plans, int todayIndex) {
  final effective = plans.where((plan) => !plan.superseded).toList();
  var start = 0;
  for (final plan in effective) {
    if (todayIndex < start + plan.days) return plan;
    start += plan.days;
  }
  return effective.last;
}

Paise _shortfallOf(SpreadOutcome outcome) => switch (outcome) {
  Shortfall(:final amount) => amount,
  Spread() || ZeroSpendable() => Paise.zero,
};

/// A cover with the amount it really moves.
final class _Effective {
  new(this.source) : day = source.day, amount = source.amount;

  final Cover source;

  final CalendarDate day;

  Paise amount;
}

/// Limits each cover to its day's overspend, oldest first, so an edit that
/// lowers the overspend returns the newest cover's excess to the pot. No
/// note is needed for this (F-006 §4). Covers come back oldest first.
List<_Effective> _effectiveCovers(
  List<Cover> covers,
  CalendarDate first,
  List<Paise> uncoveredResult,
) {
  final ordered = [...covers]..sort(_oldestFirst);
  final room = <int, Paise>{};
  return [
    for (final cover in ordered) _clamp(cover, first, uncoveredResult, room),
  ];
}

_Effective _clamp(
  Cover cover,
  CalendarDate first,
  List<Paise> uncoveredResult,
  Map<int, Paise> room,
) {
  final i = first.daysUntil(cover.day);
  if (i < 0 || i >= uncoveredResult.length) {
    throw ArgumentError.value(cover.day.iso, 'cover', 'not a budgeted day');
  }
  if (cover.amount.isNegative) {
    throw ArgumentError.value(cover.amount.value, 'cover', 'is negative');
  }
  final left = room[i] ?? (-uncoveredResult[i]).orZero;
  final effective = _Effective(cover)..amount = cover.amount.atMost(left);
  room[i] = left - effective.amount;
  return effective;
}

int _oldestFirst(Cover a, Cover b) {
  final byTime = a.madeAt.compareTo(b.madeAt);
  return byTime != 0 ? byTime : a.id.compareTo(b.id);
}

/// While the counted covers are more than the money saved, reduces them,
/// newest first, so the pot never goes below ₹0 (D-040). Covers of days
/// after today are not counted yet and are never reduced.
List<CoverReduction> _reduceNewestFirst(
  List<_Effective> oldestFirst,
  Paise saved,
  bool Function(Cover) isCounted,
) {
  final counted = oldestFirst.where((c) => isCounted(c.source)).toList();
  var excess = Paise.sum(counted.map((c) => c.amount)) - saved;
  final reductions = <CoverReduction>[];
  for (final cover in counted.reversed) {
    if (!excess.isPositive) break;
    if (cover.amount.isZero) continue;
    final cut = cover.amount.atMost(excess);
    reductions.add((
      coverId: cover.source.id,
      day: cover.day,
      oldAmount: cover.amount,
      newAmount: cover.amount - cut,
    ));
    cover.amount -= cut;
    excess -= cut;
  }
  return reductions;
}

DayResult _dayResult(
  CalendarDate date,
  int i,
  int todayIndex,
  List<Paise> budgets,
  List<Paise> spent,
  List<Paise> moneyIn,
  List<Paise> covered,
) {
  if (i < 0) {
    return (
      date: date,
      status: DayStatus.notBudgeted,
      budget: null,
      spent: Paise.zero,
      netSpent: Paise.zero,
      moneyIn: Paise.zero,
      covered: Paise.zero,
      result: null,
    );
  }
  final result = budgets[i] - spent[i] + moneyIn[i] + covered[i];
  final status = i > todayIndex
      ? DayStatus.upcoming
      : i == todayIndex
      ? DayStatus.live
      : result.isPositive
      ? DayStatus.saved
      : result.isZero
      ? DayStatus.onBudget
      : DayStatus.overspent;
  return (
    date: date,
    status: status,
    budget: budgets[i],
    spent: spent[i],
    netSpent: spent[i] - moneyIn[i],
    moneyIn: moneyIn[i],
    covered: covered[i],
    result: status == DayStatus.upcoming ? null : result,
  );
}

/// The money totals of a run of budgeted days (F-006 §2.5): spends up to and
/// including today, savings only of the days before today (D-039).
final class _Sums {
  new of(Iterable<DayResult> days, int firstIndex, int todayIndex) {
    var i = firstIndex;
    for (final day in days) {
      if (i <= todayIndex) {
        final result = day.result!;
        netSpent += day.netSpent;
        moneyIn += day.moneyIn;
        covered += day.covered;
        overspent += (-result).orZero;
        if (i < todayIndex) saved += result.orZero;
      }
      i++;
    }
  }

  Paise netSpent = Paise.zero;
  Paise moneyIn = Paise.zero;
  Paise saved = Paise.zero;
  Paise overspent = Paise.zero;
  Paise covered = Paise.zero;
}
