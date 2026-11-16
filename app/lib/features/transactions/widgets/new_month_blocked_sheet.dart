import 'package:daily_budget/core/copy/transactions_copy.dart';
import 'package:daily_budget/core/widgets/decision_sheet.dart';
import 'package:flutter/widgets.dart';

/// The sheet Add spend opens when the new month is not set up yet
/// (`transactions.md` §6.4). Returns true for Set up this month.
Future<bool> showNewMonthBlockedSheet(BuildContext context) =>
    showDecisionSheet<bool>(
      context: context,
      title: TransactionsCopy.newMonthTitle,
      paragraphs: const [TransactionsCopy.newMonthDescription],
      options: const [
        DecisionOption.primary(
          value: true,
          label: TransactionsCopy.newMonthButton,
          hint: TransactionsCopy.newMonthHint,
        ),
        DecisionOption(
          value: false,
          label: TransactionsCopy.newMonthNotNow,
          hint: TransactionsCopy.closeHint,
        ),
      ],
      dismissValue: false,
    );
