import 'package:daily_budget/domain/budget/calendar_date.dart';
import 'package:daily_budget/domain/budget/fixed_cost.dart';
import 'package:daily_budget/domain/budget/paise.dart';

/// Which value of a period changed (F-006 §2.7 "what changed").
enum PeriodField { salary, target, moneyLeft, fixedCost, fixedCostStillToPay }

/// One difference between two periods. `name` is the fixed cost's name (null
/// for salary, target and money left); `before` is null for a value that was
/// added and `after` is null for one that was removed.
typedef PeriodChange = ({
  PeriodField field,
  String? name,
  Paise? before,
  Paise? after,
});

typedef _EntryKey = (PeriodField, String?, int);

/// The values in force for a budget period (F-006 §2.2, §2.6).
sealed class PeriodValues {
  const new();

  /// The money to spread over the month before any day is budgeted.
  Paise get spendable;

  /// The sum of the fixed costs (for a mid-month start: still to pay).
  Paise get fixedCostsTotal;

  /// Throws an [ArgumentError] for a value the screens never send (§2.9).
  void validate();

  /// Every value, keyed so that the same value matches between periods, in
  /// screen order.
  List<(_EntryKey, Paise)> get _entries;

  /// What changed from [previous] to these values: added and changed values
  /// first, in screen order, then the removed ones. Derived, never stored
  /// (D-048).
  List<PeriodChange> changesFrom(PeriodValues previous) {
    final before = {for (final (key, amount) in previous._entries) key: amount};
    final after = {for (final (key, amount) in _entries) key: amount};
    final changes = <PeriodChange>[];
    for (final MapEntry(:key, value: amount) in after.entries) {
      final old = before[key];
      if (old != amount) {
        changes.add((field: key.$1, name: key.$2, before: old, after: amount));
      }
    }
    for (final MapEntry(:key, value: amount) in before.entries) {
      if (!after.containsKey(key)) {
        changes.add((field: key.$1, name: key.$2, before: amount, after: null));
      }
    }
    return List.unmodifiable(changes);
  }

  static Paise _sumOf(List<FixedCost> costs) =>
      Paise.sum(costs.map((cost) => cost.amount));

  static void _checkNotNegative(Paise amount, String name) {
    if (amount.isNegative) {
      throw ArgumentError.value(amount.value, name, 'must not be negative');
    }
  }

  static void _checkCosts(List<FixedCost> costs, String name) {
    for (final cost in costs) {
      _checkNotNegative(cost.amount, name);
    }
  }

  /// Keys for a list of costs. A name used twice gets index 0, then 1.
  static List<(_EntryKey, Paise)> _costEntries(
    PeriodField field,
    List<FixedCost> costs,
  ) {
    final seen = <String, int>{};
    return [
      for (final cost in costs)
        (
          (
            field,
            cost.name,
            seen.update(cost.name, (n) => n + 1, ifAbsent: () => 0),
          ),
          cost.amount,
        ),
    ];
  }
}

/// A normal month: salary, an optional lower target and fixed costs (§2.2).
final class FullMonthValues extends PeriodValues {
  const new({required this.salary, this.target, this.fixedCosts = const []});

  final Paise salary;

  /// A lower monthly target, or null to use the [salary].
  final Paise? target;

  final List<FixedCost> fixedCosts;

  /// The target, or the salary when none is set.
  Paise get monthlyTarget => target ?? salary;

  @override
  Paise get fixedCostsTotal => PeriodValues._sumOf(fixedCosts);

  /// Target − fixed costs; below ₹0 when the costs are bigger (D-036).
  @override
  Paise get spendable => monthlyTarget - fixedCostsTotal;

  @override
  void validate() {
    PeriodValues._checkNotNegative(salary, 'salary');
    final target = this.target;
    if (target != null) {
      PeriodValues._checkNotNegative(target, 'target');
      if (target > salary) {
        throw ArgumentError.value(target.value, 'target', 'is above salary');
      }
    }
    PeriodValues._checkCosts(fixedCosts, 'fixedCosts');
  }

  @override
  List<(_EntryKey, Paise)> get _entries => [
    ((PeriodField.salary, null, 0), salary),
    if (target case final target?) ((PeriodField.target, null, 0), target),
    ...PeriodValues._costEntries(PeriodField.fixedCost, fixedCosts),
  ];
}

/// The first month set up after its start day: the money left now and the
/// fixed costs still to pay, spread from that day (D-034, D-042, D-057).
final class MidMonthStartValues extends PeriodValues {
  const new({required this.moneyLeft, this.fixedCostsStillToPay = const []});

  /// The money on the first budgeted day, also after a later edit (D-048).
  final Paise moneyLeft;

  final List<FixedCost> fixedCostsStillToPay;

  @override
  Paise get fixedCostsTotal => PeriodValues._sumOf(fixedCostsStillToPay);

  @override
  Paise get spendable => moneyLeft - fixedCostsTotal;

  @override
  void validate() {
    PeriodValues._checkNotNegative(moneyLeft, 'moneyLeft');
    PeriodValues._checkCosts(fixedCostsStillToPay, 'fixedCostsStillToPay');
  }

  @override
  List<(_EntryKey, Paise)> get _entries => [
    ((PeriodField.moneyLeft, null, 0), moneyLeft),
    ...PeriodValues._costEntries(
      PeriodField.fixedCostStillToPay,
      fixedCostsStillToPay,
    ),
  ];
}

/// One dated period of a month (D-037). A change creates a new period
/// starting on the day it was made; periods are never overwritten.
final class BudgetPeriod {
  const new({
    required this.start,
    required this.changedAt,
    required this.values,
    this.continuedWithShortfall = false,
  });

  /// The first day the values apply.
  final CalendarDate start;

  /// When the change was saved (UTC milliseconds since 1970, from the
  /// caller). Used only to order several changes made on the same day.
  final int changedAt;

  final PeriodValues values;

  /// True when the user chose "Continue anyway" for a shortfall (D-036) or a
  /// ₹0 spendable (D-043). Such a period budgets ₹0 a day.
  final bool continuedWithShortfall;

  /// What changed from [previous]; empty for the first period.
  List<PeriodChange> diff(BudgetPeriod? previous) =>
      previous == null ? const [] : values.changesFrom(previous.values);
}
