import 'package:daily_budget/core/copy/dashboard_copy.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// The `Month statement` row under the cards (F-013 section 2.4, design
/// section 6): a 56 dp full-width row that is a link, not a card.
class StatementLinkRow extends StatelessWidget {
  const new({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Semantics(
      container: true,
      button: true,
      label: DashboardCopy.statementLink,
      hint: DashboardCopy.statementHint,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BudgetRadii.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: BudgetSpacing.space9),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  DashboardCopy.statementLink,
                  style: BudgetTypeScale.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 24, color: colors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
