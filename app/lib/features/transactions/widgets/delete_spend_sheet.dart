import 'package:daily_budget/core/copy/transactions_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/widgets/decision_sheet.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/widgets.dart';

/// `Delete this spend?` (`transactions.md` §9.1). Returns true only when the
/// user chose Delete; the scrim and back mean Cancel.
Future<bool> showDeleteSpendSheet(
  BuildContext context, {
  required Paise amount,
  required CalendarDate date,
}) => showDecisionSheet<bool>(
  context: context,
  title: TransactionsCopy.deleteTitle,
  paragraphs: [
    TransactionsCopy.deleteBody(
      formatRupees(amount),
      formatWeekdayDayMonth(date),
    ),
  ],
  options: const [
    DecisionOption.destructive(
      value: true,
      label: TransactionsCopy.delete,
      hint: TransactionsCopy.deleteHint,
    ),
    DecisionOption(
      value: false,
      label: TransactionsCopy.deleteCancel,
      hint: TransactionsCopy.deleteCancelHint,
    ),
  ],
  dismissValue: false,
);
