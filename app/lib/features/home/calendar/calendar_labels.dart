import 'package:daily_budget/core/copy/calendar_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/domain/budget/budget.dart';

/// The screen-reader sentence of one calendar cell (F-011 §5, `calendar.md`
/// §4): the full date, the full amounts (never a short form, never `lakh`)
/// and the result in words. Pure, so every row of the F-011 §2.3 table is a
/// unit test.
///
/// [lateSetup] picks the not-budgeted words: `before you started` for the
/// first month, `before this month's setup` for a month set up late (D-057).
/// Outside cells have no sentence (null): they are not in the reading order.
String? calendarCellLabel(CalendarCell cell, {bool lateSetup = false}) {
  final date = formatFullDate(cell.date);
  final net = cell.netSpent;
  final result = cell.result;
  final kind = cell.resultKind;
  if (cell.kind == CellKind.outside) return null;
  if (cell.kind == CellKind.upcoming) return CalendarCopy.upcoming(date);
  if (cell.kind == CellKind.notBudgeted) {
    return lateSetup
        ? CalendarCopy.notBudgetedLate(date)
        : CalendarCopy.notBudgeted(date);
  }
  // Every cell below has a result.
  final isToday = cell.kind == CellKind.today;
  final nothingSpent = net == Paise.zero && !cell.hasRefunds;
  final spent = formatRupeesForSpeech(net!);
  final amountPart = nothingSpent && !isToday
      ? CalendarCopy.nothingSpent
      : cell.hasRefunds
      ? CalendarCopy.netAfterRefunds(spent)
      : isToday
      ? CalendarCopy.spentSoFar(spent)
      : CalendarCopy.spent(spent);
  final amount = formatRupeesForSpeech(result!.value < 0 ? -result : result);
  final covered = cell.covered.isPositive
      ? formatRupeesForSpeech(cell.covered)
      : null;
  final resultPart = switch (kind!) {
    DayResultKind.saved =>
      isToday ? CalendarCopy.left(amount) : CalendarCopy.saved(amount),
    DayResultKind.savedUnderRupee =>
      isToday
          ? CalendarCopy.leftLessThanRupee
          : CalendarCopy.savedLessThanRupee,
    DayResultKind.onBudget => CalendarCopy.onBudget,
    DayResultKind.overspent => CalendarCopy.overspent(amount),
    DayResultKind.overspentUnderRupee => CalendarCopy.overspentLessThanRupee,
  };
  final coverPart = switch ((covered, kind)) {
    (null, _) => null,
    (final c?, DayResultKind.onBudget) => CalendarCopy.coveredFromSavings(c),
    (final c?, _) => CalendarCopy.afterFromSavings(c),
  };
  final isOverspentKind =
      kind == DayResultKind.overspent ||
      kind == DayResultKind.overspentUnderRupee;
  final sentence = [
    amountPart,
    if (coverPart != null && isOverspentKind)
      '$resultPart $coverPart'
    else ...[
      resultPart,
      ?coverPart,
    ],
    if (cell.isChangeDay) CalendarCopy.budgetChangedThisDay,
  ].join(', ');
  return isToday ? CalendarCopy.today(date, sentence) : '$date, $sentence';
}
