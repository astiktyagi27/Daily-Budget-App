import 'dart:convert';

import 'package:daily_budget/domain/budget/amount_input.dart';
import 'package:daily_budget/domain/budget/budget_month.dart';
import 'package:daily_budget/domain/budget/calendar_date.dart';
import 'package:daily_budget/domain/budget/paise.dart';
import 'package:daily_budget/domain/budget/spend.dart';

/// The longest note. The text field enforces it, counting characters the
/// way the user sees them (emoji, Hindi), which pure Dart cannot; the draft
/// does not count.
const maxNoteLength = 100;

/// The first and last day a spend may be dated (F-009 AC-4).
typedef SpendDateLimits = ({CalendarDate first, CalendarDate last});

/// The days the date picker allows: from the first budgeted day (D-034) to
/// [today], never after the month's end.
///
/// When editing a spend dated after today (the device date was set back),
/// pass its date as [editedSpendDate]: the last day is then that date, so
/// the spend stays valid (D-048).
SpendDateLimits spendDateLimits({
  required BudgetMonth month,
  required CalendarDate firstBudgetedDay,
  required CalendarDate today,
  CalendarDate? editedSpendDate,
}) {
  var last = today;
  if (editedSpendDate != null && editedSpendDate.isAfter(last)) {
    last = editedSpendDate;
  }
  if (last.isAfter(month.end)) last = month.end;
  final first = firstBudgetedDay.isBefore(month.start)
      ? month.start
      : firstBudgetedDay;
  return (first: first, last: last);
}

/// A field of the spend editor, in screen order.
enum SpendField { amount, date }

/// What is wrong with a spend field. The screen maps each to its F-009 §5
/// error text.
enum SpendProblem {
  missing,
  badFormat,
  notPositive,
  tooLarge,
  beforeFirstDay,
  afterLastDay,
}

typedef SpendError = ({SpendField field, SpendProblem problem});

/// The checked fields of a spend, ready to store. The note is trimmed and
/// null when empty. The repository adds the id and the times.
typedef SpendFields = ({Paise amount, CalendarDate date, String? note});

/// The Add/Edit spend form as typed, in pure Dart (F-009 plan §1.3).
final class SpendDraft {
  const new({required this.date, this.amountText = '', this.note = ''});

  /// A new spend, dated [today].
  factory forToday(CalendarDate today) => SpendDraft(date: today);

  /// An existing [spend] to edit. The engine's [Spend] has no note, so the
  /// stored [note] is passed in.
  factory forEdit(Spend spend, {String? note}) => SpendDraft(
    date: spend.date,
    amountText: amountInputText(spend.amount),
    note: note ?? '',
  );

  final String amountText;

  final CalendarDate date;

  final String note;

  SpendDraft copyWith({String? amountText, CalendarDate? date, String? note}) =>
      SpendDraft(
        amountText: amountText ?? this.amountText,
        date: date ?? this.date,
        note: note ?? this.note,
      );

  /// Every problem, in screen order. Empty when the spend can be saved.
  List<SpendError> validate(SpendDateLimits limits) {
    final errors = <SpendError>[];
    final amount = switch (positiveAmountProblem(parseAmount(amountText))) {
      null => null,
      AmountProblem.missing => SpendProblem.missing,
      AmountProblem.badFormat => SpendProblem.badFormat,
      AmountProblem.notPositive => SpendProblem.notPositive,
      AmountProblem.tooLarge => SpendProblem.tooLarge,
    };
    if (amount != null) {
      errors.add((field: SpendField.amount, problem: amount));
    }
    if (date.isBefore(limits.first)) {
      errors.add((
        field: SpendField.date,
        problem: SpendProblem.beforeFirstDay,
      ));
    } else if (date.isAfter(limits.last)) {
      errors.add((field: SpendField.date, problem: SpendProblem.afterLastDay));
    }
    return List.unmodifiable(errors);
  }

  /// The checked fields. Throws a [StateError] when [validate] finds a
  /// problem: nothing is ever fixed silently.
  SpendFields toFields(SpendDateLimits limits) {
    if (parseAmount(amountText) case AmountValue(:final paise)
        when validate(limits).isEmpty) {
      final trimmed = note.trim();
      return (
        amount: paise,
        date: date,
        note: trimmed.isEmpty ? null : trimmed,
      );
    }
    throw StateError('The draft has problems; call validate() first.');
  }

  /// Whether the typed values differ from [initial] (Save changes and the
  /// discard guard). `300.5` and `300.50` are the same amount.
  bool isChangedFrom(SpendDraft initial) =>
      _signature() != initial._signature();

  String _signature() => jsonEncode([
    switch (parseAmount(amountText)) {
      AmountValue(:final paise) => '${paise.value}',
      AmountEmpty() => '',
      _ => 'text:${amountText.trim()}',
    },
    date.dayNumber,
    note.trim(),
  ]);
}
