import 'package:daily_budget/core/copy/day_details_copy.dart';
import 'package:daily_budget/core/copy/statement_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/domain/budget/budget.dart';

/// What changed on a period's first day, for the `Budget changed on this day`
/// line (design `day-details.md` §3.1, D-090): the month statement's phrase
/// for each difference, joined with ` · `. Only the fixed words are lower
/// case, a fixed cost keeps the name as typed. Amounts are formatted here and
/// no arithmetic is done. [changes] that net to nothing read `changed and
/// changed back`, so the line never ends empty.
String budgetChangeText(List<PeriodChange> changes) {
  final deltas = statementDeltasOf(changes);
  if (deltas.isEmpty) return _lowerFirst(StatementCopy.changedAndBack);
  return deltas.map(_phrase).join(DayDetailsCopy.changeSeparator);
}

String _phrase(StatementDelta delta) => switch (delta) {
  ValueDelta(before: null, :final after) => _lowerFirst(
    StatementCopy.targetSet(formatRupees(after!)),
  ),
  ValueDelta(after: null) => _lowerFirst(StatementCopy.targetRemoved),
  ValueDelta(:final before, :final after) => DayDetailsCopy.changedValue(
    _valueName(delta),
    formatRupees(before!),
    formatRupees(after!),
  ),
  CostAdded(:final name, :final amount) => _lowerFirst(
    StatementCopy.fixedCostAdded(name, formatRupees(amount)),
  ),
  CostRemoved(:final name, :final amount) => _lowerFirst(
    StatementCopy.fixedCostRemoved(name, formatRupees(amount)),
  ),
  CostRenamed(:final from, :final to) => StatementCopy.fixedCostRenamed(
    from,
    to,
  ),
};

String _valueName(ValueDelta delta) => switch (delta.field) {
  PeriodField.salary => _lowerFirst(StatementCopy.salary),
  PeriodField.target => _lowerFirst(StatementCopy.spendingTarget),
  PeriodField.moneyLeft => _lowerFirst(StatementCopy.moneyLeft),
  PeriodField.fixedCost || PeriodField.fixedCostStillToPay => delta.name!,
};

String _lowerFirst(String text) =>
    '${text[0].toLowerCase()}${text.substring(1)}';
