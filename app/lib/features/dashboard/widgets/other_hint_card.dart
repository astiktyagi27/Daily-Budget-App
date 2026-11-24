import 'package:daily_budget/core/copy/dashboard_copy.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:flutter/material.dart';

/// The tip under the card when every spend is in Other (F-013 AC-2, design
/// B-3): the look of the first-time hint (`accentSoft`, lightbulb, `Tip`)
/// but with no close button. It goes away by itself once a second category
/// exists, so nothing is stored.
class OtherHintCard extends StatelessWidget {
  const new({required this.onGoToTransactions, super.key});

  final VoidCallback onGoToTransactions;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(BudgetRadii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BudgetSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(width: BudgetSpacing.space2),
                Text(
                  DashboardCopy.tipLabel,
                  style: BudgetTypeScale.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BudgetSpacing.space2),
            Text(
              DashboardCopy.otherTip,
              style: BudgetTypeScale.body.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: BudgetSpacing.space1),
            Align(
              alignment: Alignment.centerRight,
              child: BudgetButton.text(
                label: DashboardCopy.goToTransactions,
                semanticsHint: DashboardCopy.goToTransactionsHint,
                onPressed: onGoToTransactions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
