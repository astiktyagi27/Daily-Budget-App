import 'package:daily_budget/core/copy/home_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// `Budget changed on 13 Nov · See month statement` (F-010 AC-8), shown when
/// the month has more than one period (D-037).
class BudgetChangedLine extends StatelessWidget {
  const new({required this.day, required this.onSeeStatement, super.key});

  final CalendarDate day;

  final VoidCallback onSeeStatement;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final words = BudgetTypeScale.body.copyWith(color: colors.textSecondary);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 16, color: colors.textSecondary),
            const SizedBox(width: BudgetSpacing.space1),
            Flexible(
              child: Text(
                HomeCopy.budgetChanged(formatDayMonth(day)),
                style: words,
              ),
            ),
            const SizedBox(width: BudgetSpacing.space1),
            // The dot between the sentence and the button is decoration.
            ExcludeSemantics(child: Text('·', style: words)),
          ],
        ),
        BudgetButton.text(
          label: HomeCopy.seeMonthStatement,
          semanticsHint: HomeCopy.seeMonthStatementHint,
          onPressed: onSeeStatement,
        ),
      ],
    );
  }
}
