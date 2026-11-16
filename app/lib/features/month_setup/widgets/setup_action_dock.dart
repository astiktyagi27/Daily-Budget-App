import 'package:daily_budget/core/copy/month_setup_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// The one-line summary pinned above Confirm (`month-setup.md` §6), for the
/// `line` of an `ActionDock`: `Daily budget` · `₹830 a day`, in edit mode
/// `From today` · `₹630 a day`, `◆ ₹1,000 short` for a shortfall,
/// `○ ₹0 a day` for exactly ₹0 and `—` while there is nothing to show.
class SetupDockLine extends StatelessWidget {
  const new({
    required this.preview,
    required this.draft,
    required this.isEdit,
    super.key,
  });

  final SetupPreview preview;
  final SetupDraft draft;
  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final preview = this.preview;
    var label = isEdit
        ? MonthSetupCopy.dockFromToday
        : MonthSetupCopy.dockDaily;
    var value = MonthSetupCopy.dockNone;
    var valueColor = colors.textSecondary;
    if (preview is PreviewReady) {
      final outcome = preview.outcome;
      if (outcome is Shortfall) {
        value = MonthSetupCopy.dockShort(formatRupees(outcome.amount));
        valueColor = colors.overspent;
      } else if (outcome is ZeroSpendable) {
        value = MonthSetupCopy.dockZero;
        valueColor = colors.neutral;
      } else {
        value = MonthSetupCopy.aDay(formatRupees(preview.dailyBudget));
        valueColor = colors.textPrimary;
      }
    } else if (!isEdit) {
      label = draft.kind == SetupKind.midMonth
          ? MonthSetupCopy.moneyLeftMissing
          : MonthSetupCopy.dockEnterSalary;
    }
    // Both parts may wrap: a ₹3,00,00,00,000 shortfall is wider than a
    // phone at the larger money size.
    return Row(
      children: [
        Flexible(
          child: Text(
            label,
            style: BudgetTypeScale.body.copyWith(color: colors.textSecondary),
          ),
        ),
        const SizedBox(width: BudgetSpacing.space3),
        Flexible(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: BudgetTypeScale.moneyMedium.copyWith(color: valueColor),
          ),
        ),
      ],
    );
  }
}
