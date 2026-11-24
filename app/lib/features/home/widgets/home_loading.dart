import 'package:daily_budget/core/copy/home_copy.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:flutter/material.dart';

/// Home while the month is read (`home-summary.md` §7): card outlines with
/// static grey bars where the figures go. Labels are shown; no figure and
/// never a `₹0`. No shimmer. One screen-reader node, `Loading your month`.
class HomeLoading extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    Widget bar(double width) => DecoratedBox(
      decoration: BoxDecoration(
        color: colors.neutralSoft,
        borderRadius: const BorderRadius.all(Radius.circular(BudgetRadii.xs)),
      ),
      child: SizedBox(width: width, height: 12),
    );
    Widget row(String label) => Padding(
      padding: const EdgeInsets.symmetric(vertical: BudgetSpacing.space3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: BudgetTypeScale.body.copyWith(color: colors.textSecondary),
            ),
          ),
          bar(64),
        ],
      ),
    );
    return Semantics(
      container: true,
      label: HomeCopy.loading,
      child: ExcludeSemantics(
        child: BudgetCard(
          padding: const EdgeInsets.all(BudgetSpacing.space5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                HomeCopy.leftThisMonth,
                style: BudgetTypeScale.label.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: BudgetSpacing.space3),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: bar(160),
              ),
              const SizedBox(height: BudgetSpacing.space3),
              const Divider(),
              row(HomeCopy.salary),
              row(HomeCopy.fixedCosts),
              row(HomeCopy.spentSoFar),
            ],
          ),
        ),
      ),
    );
  }
}
