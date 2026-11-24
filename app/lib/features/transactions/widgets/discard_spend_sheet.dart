import 'package:daily_budget/core/copy/money_back_copy.dart';
import 'package:daily_budget/core/copy/transactions_copy.dart';
import 'package:daily_budget/core/widgets/decision_sheet.dart';
import 'package:flutter/widgets.dart';

/// `Discard this spend?` / `Discard changes?` (`transactions.md` §9.3), or
/// `Discard this money back?` when [isMoneyBack] adds one (F-016 §5; Edit
/// stays `Discard changes?`). Returns true only for Discard; Keep editing is
/// first and the scrim and back mean Keep editing.
Future<bool> showDiscardSpendSheet(
  BuildContext context, {
  required bool isEdit,
  bool isMoneyBack = false,
}) => showDecisionSheet<bool>(
  context: context,
  title: isEdit
      ? TransactionsCopy.discardEditTitle
      : isMoneyBack
      ? MoneyBackCopy.discardTitle
      : TransactionsCopy.discardAddTitle,
  paragraphs: [
    if (isEdit)
      TransactionsCopy.discardEditBody
    else if (isMoneyBack)
      MoneyBackCopy.discardBody
    else
      TransactionsCopy.discardAddBody,
  ],
  options: const [
    DecisionOption.primary(
      value: false,
      label: TransactionsCopy.keepEditing,
      hint: TransactionsCopy.keepEditingHint,
    ),
    DecisionOption.destructive(
      value: true,
      label: TransactionsCopy.discard,
      hint: TransactionsCopy.discardHint,
    ),
  ],
  dismissValue: false,
);
