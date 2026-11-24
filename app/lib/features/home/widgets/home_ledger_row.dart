import 'package:daily_budget/core/copy/home_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/help/help_info.dart';
import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/home/widgets/counting_amount.dart';
import 'package:daily_budget/features/home/widgets/home_layout.dart';
import 'package:flutter/material.dart';

/// Whether a ledger amount carries a mark and a colour (design H-3).
enum LedgerMark {
  /// Plain ink: Salary, Fixed costs, Spent so far.
  none,

  /// `●` in `saved`, for money saved.
  saved,

  /// `◆` in `overspent`, for money overspent.
  overspent,

  /// An amount of ₹0 in Saved or Overspent: `neutral`, no mark.
  zero,
}

/// One ledger line of the summary card (F-010 §2.2): the label and its (i)
/// on the left, the amount on the right. Above 1.3x text the amount stacks
/// under the label. A screen reader gets `Overspent, ₹470` as one node; the
/// (i) stays its own.
class HomeLedgerRow extends StatelessWidget {
  const new({
    required this.label,
    required this.info,
    required this.amount,
    this.mark = LedgerMark.none,
    super.key,
  });

  final String label;

  final HelpInfo info;

  final Paise amount;

  final LedgerMark mark;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final color = switch (mark) {
      LedgerMark.none => colors.textPrimary,
      LedgerMark.saved => colors.saved,
      LedgerMark.overspent => colors.overspent,
      LedgerMark.zero => colors.neutral,
    };
    final glyph = switch (mark) {
      LedgerMark.saved => '●',
      LedgerMark.overspent => '◆',
      LedgerMark.none || LedgerMark.zero => null,
    };
    final amountStyle = BudgetTypeScale.moneyMedium.copyWith(color: color);

    final labelRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ExcludeSemantics(
            child: Text(
              label,
              style: BudgetTypeScale.body.copyWith(color: colors.textSecondary),
            ),
          ),
        ),
        InfoButton(label: label, info: info),
      ],
    );
    final amountRow = ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[
            Text(glyph, style: amountStyle),
            const SizedBox(width: BudgetSpacing.space1),
          ],
          Flexible(
            child: CountingAmount(amount: amount, style: amountStyle),
          ),
        ],
      ),
    );

    return Semantics(
      container: true,
      label: HomeCopy.rowSpeech(label, formatRupeesForSpeech(amount)),
      child: isLargeText(context)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelRow,
                Padding(
                  padding: const EdgeInsets.only(bottom: BudgetSpacing.space2),
                  child: amountRow,
                ),
              ],
            )
          // The amount drops under the label when the two do not fit one
          // line (a very large amount), instead of overflowing.
          : Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: BudgetSpacing.space2,
              children: [labelRow, amountRow],
            ),
    );
  }
}
