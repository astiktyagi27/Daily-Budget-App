import 'package:daily_budget/core/copy/money_back_copy.dart';
import 'package:daily_budget/core/copy/transactions_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/widgets/decision_sheet.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/widgets.dart';

/// `Delete this spend?` (`transactions.md` §9.1) or, for [isMoneyBack],
/// `Delete this money back?` (F-016 §5). Returns true only when the user
/// chose Delete; the scrim and back mean Cancel.
Future<bool> showDeleteSpendSheet(
  BuildContext context, {
  required Paise amount,
  required CalendarDate date,
  bool isMoneyBack = false,
}) => showDecisionSheet<bool>(
  context: context,
  title: isMoneyBack ? MoneyBackCopy.deleteTitle : TransactionsCopy.deleteTitle,
  paragraphs: [
    (isMoneyBack ? MoneyBackCopy.deleteBody : TransactionsCopy.deleteBody)(
      formatRupees(amount),
      formatWeekdayDayMonth(date),
    ),
  ],
  options: [
    DecisionOption.destructive(
      value: true,
      label: TransactionsCopy.delete,
      hint: isMoneyBack
          ? MoneyBackCopy.deleteHint
          : TransactionsCopy.deleteHint,
    ),
    DecisionOption(
      value: false,
      label: TransactionsCopy.deleteCancel,
      hint: isMoneyBack
          ? MoneyBackCopy.deleteCancelHint
          : TransactionsCopy.deleteCancelHint,
    ),
  ],
  dismissValue: false,
);
