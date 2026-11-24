import 'package:daily_budget/core/copy/month_setup_copy.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:flutter/material.dart';

/// The Home card of a new month that has started and is not set up yet
/// (`month-setup.md` §10.3). It replaces the This month card until the new
/// month is confirmed.
class NewMonthCard extends StatelessWidget {
  const new({required this.onSetUp, super.key});

  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return BudgetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label:
                '${MonthSetupCopy.homeNewMonthTitle}. '
                '${MonthSetupCopy.homeNewMonthDescription}',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    MonthSetupCopy.homeNewMonthTitle,
                    style: context.budgetText.title.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: BudgetSpacing.space2),
                  Text(
                    MonthSetupCopy.homeNewMonthDescription,
                    style: BudgetTypeScale.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: BudgetSpacing.space4),
          BudgetButton.primary(
            label: MonthSetupCopy.titleNew,
            semanticsHint: MonthSetupCopy.homeNewMonthHint,
            onPressed: onSetUp,
          ),
        ],
      ),
    );
  }
}
