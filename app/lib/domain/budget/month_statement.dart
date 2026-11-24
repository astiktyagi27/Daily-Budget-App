import 'package:daily_budget/domain/budget/budget_month.dart';
import 'package:daily_budget/domain/budget/budget_period.dart';
import 'package:daily_budget/domain/budget/calendar_date.dart';
import 'package:daily_budget/domain/budget/fixed_cost.dart';
import 'package:daily_budget/domain/budget/month_result.dart';
import 'package:daily_budget/domain/budget/paise.dart';
import 'package:daily_budget/domain/budget/whole_rupees.dart';

// The month statement (F-014): a pure function of the engine's MonthResult.
// It adds no money rule. It returns typed data, never strings; the screen
// builds the words (`statement_text.dart`), so the visible text and the
// screen-reader sentence cannot drift apart.

/// One difference between two period records, in the words the statement
/// uses (a renamed fixed cost is one delta, not a removal plus an addition).
sealed class StatementDelta {
  const new();
}

/// Salary, spending target, money left, or the amount of a fixed cost that
/// kept its name. `before` is null for a target that was set, `after` is null
/// for a target that was removed.
final class ValueDelta extends StatementDelta {
  const new({
    required this.field,
    required this.name,
    required this.before,
    required this.after,
  });

  final PeriodField field;

  /// The fixed cost's name; null for salary, target and money left.
  final String? name;

  final Paise? before;

  final Paise? after;
}

final class CostAdded extends StatementDelta {
  const new({required this.name, required this.amount});

  final String name;

  final Paise amount;
}

final class CostRemoved extends StatementDelta {
  const new({required this.name, required this.amount});

  final String name;

  final Paise amount;
}

/// The same amount under a new name and nothing else changed.
final class CostRenamed extends StatementDelta {
  const new({required this.from, required this.to});

  final String from;

  final String to;
}

/// Why a period card exists (F-014 §2.3).
sealed class StatementReason {
  const new();
}

/// The first card: `Month started`, or `Month started partway` for a first
/// month set up after its start day.
final class StartedReason extends StatementReason {
  const new({required this.partway});

  final bool partway;
}

/// Same-day changes that net to nothing (D-081 (6)).
final class ChangedBackReason extends StatementReason {
  const new();
}

final class ChangedReason extends StatementReason {
  const new(this.delta);

  final StatementDelta delta;
}

enum StatementChangeKind { started, startedPartway, later }

/// One line of What changed: one per stored period record, oldest first,
/// each compared with the previous stored record (D-081 (5)).
final class StatementChange {
  const new({
    required this.date,
    required this.changedAt,
    required this.kind,
    required this.values,
    required this.deltas,
    required this.replacedSameDay,
    required this.showTime,
    required this.dailyAfter,
    required this.daysLeft,
  });

  final CalendarDate date;

  /// When the change was saved (UTC milliseconds); the screen shows its
  /// local `hh:mm` when [showTime].
  final int changedAt;

  final StatementChangeKind kind;

  /// The values of this record (for a `Month started` line).
  final PeriodValues values;

  /// What changed against the previous stored record; empty for the first.
  final List<StatementDelta> deltas;

  /// A later change on the same day replaced this record.
  final bool replacedSameDay;

  /// More than one record was saved on [date]: the line shows the time.
  final bool showTime;

  /// The daily budget this record gave; null when [replacedSameDay].
  final Paise? dailyAfter;

  /// The days from [date] to the month's end, the span the money is spread
  /// over.
  final int daysLeft;
}

/// The working line of a period card, as numbers (F-014 §1.2).
///
/// `base` is the amount the engine spreads from (the spending target when one
/// is set, else the salary; money left for a mid-month start), `fixed` the
/// fixed costs (still to pay for a mid-month start), `spendable` the
/// difference, `alreadyBudgeted` the budgets of the days before the period
/// and `amountToSpread` what is left to spread (below ₹0 for a shortfall).
sealed class StatementWorking {
  const new({
    required this.base,
    required this.fixed,
    required this.stillToPay,
    required this.spendable,
    required this.alreadyBudgeted,
    required this.amountToSpread,
    required this.spreadDays,
  });

  final Paise base;

  final Paise fixed;

  /// The fixed term reads `still to pay` (mid-month start) instead of
  /// `fixed`.
  final bool stillToPay;

  final Paise spendable;

  /// Left out of the line when ₹0 (D-081 (3)).
  final Paise alreadyBudgeted;

  final Paise amountToSpread;

  /// The days the amount is spread over: from the period's first day to the
  /// month's end, not the period's own length.
  final int spreadDays;
}

/// A positive amount spread over the days: `→ ₹552/day`.
final class SpreadWorking extends StatementWorking {
  const new({
    required super.base,
    required super.fixed,
    required super.stillToPay,
    required super.spendable,
    required super.alreadyBudgeted,
    required super.amountToSpread,
    required super.spreadDays,
    required this.daily,
    required this.extraPaiseDays,
  });

  /// The first day's budget, the one shown (whole rupees).
  final Paise daily;

  /// How many of the first days get 1 paisa more; 0 when it divides evenly.
  final int extraPaiseDays;
}

/// Less than ₹0 to spread: `◆ ₹1,000 short · ₹0/day (continued anyway)`.
final class ShortfallWorking extends StatementWorking {
  const new({
    required super.base,
    required super.fixed,
    required super.stillToPay,
    required super.spendable,
    required super.alreadyBudgeted,
    required super.amountToSpread,
    required super.spreadDays,
    required this.shortfall,
  });

  /// How much is missing, in positive paise.
  final Paise shortfall;

  /// Less than ₹1 short: the screen says `less than ₹1 short` (D-050).
  bool get underRupee => shortfall.value < 100;
}

/// Exactly ₹0 to spread (D-043): `○ ₹0 left for daily spending`.
final class ZeroWorking extends StatementWorking {
  const new({
    required super.base,
    required super.fixed,
    required super.stillToPay,
    required super.spendable,
    required super.alreadyBudgeted,
    required super.amountToSpread,
    required super.spreadDays,
  });
}

/// A period's totals "for these days" (F-014 §2.3). `spent` is the gross sum
/// of the spends, `refunds` the money in and `netSpent` their difference.
final class StatementPeriodTotals {
  const new({
    required this.budget,
    required this.spent,
    required this.refunds,
    required this.netSpent,
    required this.saved,
    required this.overspent,
    required this.covered,
  });

  /// The whole period's budget, also for a period in progress (D-060).
  final Paise budget;

  final Paise spent;

  final Paise refunds;

  final Paise netSpent;

  final Paise saved;

  final Paise overspent;

  final Paise covered;

  bool get hasRefunds => refunds.isPositive;
}

/// One period card: a stored record that was not replaced the same day.
final class StatementPeriod {
  const new({
    required this.index,
    required this.of,
    required this.start,
    required this.end,
    required this.days,
    required this.inProgress,
    required this.reasons,
    required this.values,
    required this.working,
    required this.totals,
  });

  /// 1-based position and the number of cards.
  final int index;

  final int of;

  final CalendarDate start;

  final CalendarDate end;

  final int days;

  /// Today is in this period and in the month.
  final bool inProgress;

  final List<StatementReason> reasons;

  /// The values in force then, never rewritten (AC-8).
  final PeriodValues values;

  final StatementWorking working;

  final StatementPeriodTotals totals;
}

/// The month totals card (F-014 §2.4).
final class StatementTotals {
  const new({
    required this.moneyForMonth,
    required this.spent,
    required this.refunds,
    required this.netSpent,
    required this.saved,
    required this.covered,
    required this.overspent,
    required this.pot,
    required this.shortfall,
    required this.left,
  });

  final Paise moneyForMonth;

  /// The gross spends: net spent plus the refunds.
  final Paise spent;

  final Paise refunds;

  final Paise netSpent;

  final Paise saved;

  final Paise covered;

  final Paise overspent;

  final Paise pot;

  /// The current period's shortfall (D-048); the row shows only when above
  /// ₹0.
  final Paise shortfall;

  /// Computed from exact paise, rounded once on screen (TC-014-55).
  final Paise left;

  bool get hasRefunds => refunds.isPositive;
}

/// Everything the statement screen shows for one month.
final class MonthStatement {
  const new({
    required this.month,
    required this.soFarTo,
    required this.notBudgeted,
    required this.totals,
    required this.changes,
    required this.periods,
  });

  final BudgetMonth month;

  /// Today, when it is inside the month (`so far (to Fri, 20 Nov)`); null
  /// for a past or future month.
  final CalendarDate? soFarTo;

  /// The days before the first budgeted day, or null (`5 – 9 Nov: not
  /// budgeted`).
  final ({CalendarDate start, CalendarDate end})? notBudgeted;

  final StatementTotals totals;

  final List<StatementChange> changes;

  final List<StatementPeriod> periods;

  /// The card whose first day is [start], or null.
  StatementPeriod? periodStartingOn(CalendarDate start) =>
      periods.where((period) => period.start == start).firstOrNull;
}

/// Builds the statement of [result]: pure, no money rule.
MonthStatement buildStatement(MonthResult result) {
  final month = result.month;
  final records = result.periods;
  final sameDayCount = <CalendarDate, int>{};
  for (final record in records) {
    sameDayCount.update(record.start, (n) => n + 1, ifAbsent: () => 1);
  }
  final changes = [
    for (final (i, record) in records.indexed)
      _changeOf(month, i, record, showTime: sameDayCount[record.start]! > 1),
  ];

  final cards = [
    for (final (i, record) in records.indexed)
      if (!record.superseded) (i, record),
  ];
  final periods = <StatementPeriod>[];
  for (final (position, (i, record)) in cards.indexed) {
    final previous = position == 0 ? null : cards[position - 1].$2;
    periods.add(
      StatementPeriod(
        index: position + 1,
        of: cards.length,
        start: record.start,
        end: record.end,
        days: record.days,
        inProgress:
            month.contains(result.today) && i == result.currentPeriodIndex,
        reasons: _reasonsOf(record, previous),
        values: record.period.values,
        working: _workingOf(month, record),
        totals: _periodTotals(record),
      ),
    );
  }

  final totals = result.totals;
  final first = result.firstBudgetedDay;
  return MonthStatement(
    month: month,
    soFarTo: month.contains(result.today) ? result.today : null,
    notBudgeted: first == month.start
        ? null
        : (start: month.start, end: first.addDays(-1)),
    totals: StatementTotals(
      moneyForMonth: totals.budgeted,
      spent: totals.spentSoFar + totals.moneyIn,
      refunds: totals.moneyIn,
      netSpent: totals.spentSoFar,
      saved: totals.saved,
      covered: totals.covered,
      overspent: totals.overspent,
      pot: totals.pot,
      shortfall: totals.shortfall,
      left: totals.left,
    ),
    changes: changes,
    periods: periods,
  );
}

StatementChange _changeOf(
  BudgetMonth month,
  int index,
  PeriodResult record, {
  required bool showTime,
}) {
  final values = record.period.values;
  return StatementChange(
    date: record.start,
    changedAt: record.period.changedAt,
    kind: index > 0
        ? StatementChangeKind.later
        : values is MidMonthStartValues
        ? StatementChangeKind.startedPartway
        : StatementChangeKind.started,
    values: values,
    deltas: statementDeltasOf(record.changes),
    replacedSameDay: record.superseded,
    showTime: showTime,
    dailyAfter: record.superseded ? null : record.budgets.first,
    daysLeft: record.start.daysUntil(month.end) + 1,
  );
}

bool _isCost(PeriodField field) =>
    field == PeriodField.fixedCost || field == PeriodField.fixedCostStillToPay;

/// The engine's differences in the statement's words: added and removed
/// fixed costs, and a rename (one removed and one added cost with the same
/// amount and nothing else changed).
List<StatementDelta> statementDeltasOf(List<PeriodChange> changes) {
  final deltas = <StatementDelta>[
    for (final change in changes)
      if (_isCost(change.field) && change.before == null)
        CostAdded(name: change.name!, amount: change.after!)
      else if (_isCost(change.field) && change.after == null)
        CostRemoved(name: change.name!, amount: change.before!)
      else
        ValueDelta(
          field: change.field,
          name: change.name,
          before: change.before,
          after: change.after,
        ),
  ];
  if (deltas.length == 2) {
    final removed = deltas.whereType<CostRemoved>().firstOrNull;
    final added = deltas.whereType<CostAdded>().firstOrNull;
    if (removed != null && added != null && removed.amount == added.amount) {
      return [CostRenamed(from: removed.name, to: added.name)];
    }
  }
  return deltas;
}

/// Why [record] starts a card: compared with the previous card, so a same-day
/// double change names the net change (F-014 §2.8).
List<StatementReason> _reasonsOf(PeriodResult record, PeriodResult? previous) {
  if (previous == null) {
    return [
      StartedReason(partway: record.period.values is MidMonthStartValues),
    ];
  }
  final deltas = statementDeltasOf(
    record.period.values.changesFrom(previous.period.values),
  );
  if (deltas.isEmpty) return const [ChangedBackReason()];
  return [for (final delta in deltas) ChangedReason(delta)];
}

StatementWorking _workingOf(BudgetMonth month, PeriodResult record) {
  final values = record.period.values;
  final spendable = values.spendable;
  final amount = record.amountToSpread;
  final base = switch (values) {
    FullMonthValues(:final monthlyTarget) => monthlyTarget,
    MidMonthStartValues(:final moneyLeft) => moneyLeft,
  };
  final spreadDays = record.start.daysUntil(month.end) + 1;
  final fixed = values.fixedCostsTotal;
  final stillToPay = values is MidMonthStartValues;
  // The engine defines amountToSpread = spendable - the earlier budgets.
  final already = spendable - amount;
  if (record.zeroSpendable) {
    return ZeroWorking(
      base: base,
      fixed: fixed,
      stillToPay: stillToPay,
      spendable: spendable,
      alreadyBudgeted: already,
      amountToSpread: amount,
      spreadDays: spreadDays,
    );
  }
  if (record.shortfall.isPositive) {
    return ShortfallWorking(
      base: base,
      fixed: fixed,
      stillToPay: stillToPay,
      spendable: spendable,
      alreadyBudgeted: already,
      amountToSpread: amount,
      spreadDays: spreadDays,
      shortfall: record.shortfall,
    );
  }
  return SpreadWorking(
    base: base,
    fixed: fixed,
    stillToPay: stillToPay,
    spendable: spendable,
    alreadyBudgeted: already,
    amountToSpread: amount,
    spreadDays: spreadDays,
    daily: record.budgets.first,
    extraPaiseDays: amount.value % spreadDays,
  );
}

StatementPeriodTotals _periodTotals(PeriodResult record) =>
    StatementPeriodTotals(
      budget: Paise.sum(record.budgets),
      spent: record.netSpent + record.moneyIn,
      refunds: record.moneyIn,
      netSpent: record.netSpent,
      saved: record.saved,
      overspent: record.overspent,
      covered: record.covered,
    );

/// Whether the statement shows the rounding note (D-053, D-062, AC-12): some
/// month line differs from the sum of its period lines **as shown**, in whole
/// rupees rounded toward zero (the rule of `formatRupees`).
bool roundingNoteNeeded(MonthStatement statement) {
  final totals = statement.totals;
  final periods = statement.periods;
  final lines = <(Paise, Paise Function(StatementPeriodTotals))>[
    (totals.moneyForMonth, (p) => p.budget),
    (totals.spent, (p) => p.spent),
    (totals.refunds, (p) => p.refunds),
    (totals.netSpent, (p) => p.netSpent),
    (totals.saved, (p) => p.saved),
    (totals.overspent, (p) => p.overspent),
    (totals.covered, (p) => p.covered),
  ];
  return lines.any((line) {
    final (month, of) = line;
    final shown = periods.fold(0, (sum, p) => sum + of(p.totals).wholeRupees);
    return month.wholeRupees != shown;
  });
}

/// The fixed cost names of [values], for a card's expander.
List<FixedCost> fixedCostsOf(PeriodValues values) => switch (values) {
  FullMonthValues(:final fixedCosts) => fixedCosts,
  MidMonthStartValues(:final fixedCostsStillToPay) => fixedCostsStillToPay,
};
