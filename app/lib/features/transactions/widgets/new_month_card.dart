import 'package:daily_budget/core/copy/transactions_copy.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:flutter/material.dart';

/// The card in place of the Today card when the new month is not set up
/// (`transactions.md` §6.4).
class NewMonthCard extends StatelessWidget {
  const new({required this.onSetUp, super.key});

  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    return BudgetCard(
      title: TransactionsCopy.newMonthTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            TransactionsCopy.newMonthDescription,
            style: BudgetTypeScale.body.copyWith(
              color: context.budgetColors.textSecondary,
            ),
          ),
          const SizedBox(height: BudgetSpacing.space4),
          BudgetButton.primary(
            label: TransactionsCopy.newMonthButton,
            semanticsHint: TransactionsCopy.newMonthHint,
            onPressed: onSetUp,
          ),
        ],
      ),
    );
  }
}
