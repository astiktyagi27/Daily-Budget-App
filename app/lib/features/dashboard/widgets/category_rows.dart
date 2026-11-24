import 'package:daily_budget/core/copy/category_copy.dart';
import 'package:daily_budget/core/copy/dashboard_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/share_bar_row.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// The ranked share rows of the several-categories state (F-013 AC-4),
/// never truncated, with the rounding note when the shown percents add up
/// to less than 100.
class CategoryRows extends StatelessWidget {
  const new({required this.breakdown, super.key});

  final CategoryBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, row) in breakdown.rows.indexed) ...[
          if (index > 0) const SizedBox(height: BudgetSpacing.space4),
          ShareBarRow(
            name: CategoryCopy.nameOf(row.category),
            amount: formatRupees(row.amount),
            share: DashboardCopy.percent(
              row.percent,
              underOne: row.underOnePercent,
            ),
            barPermille: row.barPermille,
            semanticsLabel: DashboardCopy.rowSemantics(
              CategoryCopy.nameOf(row.category),
              formatRupeesForSpeech(row.amount),
              row.percent,
              underOne: row.underOnePercent,
            ),
          ),
        ],
        if (breakdown.roundingNoteNeeded) ...[
          const SizedBox(height: BudgetSpacing.space3),
          Text(
            DashboardCopy.roundingNote,
            style: BudgetTypeScale.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
