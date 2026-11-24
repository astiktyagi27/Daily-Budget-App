import 'package:daily_budget/core/help/help_info.dart';
import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/core/theme/budget_colors.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// A label with its (i) on the left and an amount on the right (F-013
/// Refunds and Net spent lines, reused by the month statement, F-014). The
/// label is `body` `textSecondary`, the amount `moneyMedium` `textPrimary`.
/// A plain fact is never red or green; the optional `status` adds the mark
/// and colour of a Saved or Overspent amount (the month statement's totals).
///
/// Above 1.3x text the label stacks over the amount. A screen reader reads
/// `<label>, <amountSpeech>` as one item; the (i) stays its own item.
class LedgerRow extends StatelessWidget {
  const new({
    required this.label,
    required this.info,
    required this.amount,
    required this.amountSpeech,
    this.status,
    super.key,
  });

  final String label;

  final HelpInfo info;

  /// The amount already formatted (`−₹500`).
  final String amount;

  /// The amount as a screen reader says it (`minus ₹500`).
  final String amountSpeech;

  /// A status the amount carries (the month statement's Saved and Overspent
  /// rows): its mark before the amount and its colour. Null for a plain fact.
  /// Decorative: the caller's [amountSpeech] says it in words.
  final LedgerStatus? status;

  static const double _stackAbove = 1.3;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final text = context.budgetText;
    final stacked = MediaQuery.textScalerOf(context).scale(1) > _stackAbove;

    final labelAndInfo = Row(
      mainAxisSize: stacked ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Flexible(
          child: Semantics(
            container: true,
            label: '$label, $amountSpeech',
            child: ExcludeSemantics(
              child: Text(
                label,
                style: BudgetTypeScale.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        InfoButton(label: label, info: info),
      ],
    );
    final status = this.status;
    final amountStyle = text.moneyMedium.copyWith(
      color: status == null ? colors.textPrimary : status.color(colors),
    );
    final amountText = ExcludeSemantics(
      child: status == null
          ? Text(amount, style: amountStyle)
          : Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${status.mark} ',
                    style: BudgetTypeScale.label.copyWith(
                      color: status.color(colors),
                    ),
                  ),
                  TextSpan(text: amount),
                ],
              ),
              style: amountStyle,
            ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: BudgetSpacing.touchTarget),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [labelAndInfo, amountText],
            )
          : Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: labelAndInfo,
                  ),
                ),
                const SizedBox(width: BudgetSpacing.space2),
                amountText,
              ],
            ),
    );
  }
}

/// The status a [LedgerRow] amount can carry: green for saved, red for
/// overspent (colours carry meaning only, and never alone: the mark too).
enum LedgerStatus {
  saved('●'),
  overspent('◆');

  new(this.mark);

  final String mark;

  Color color(BudgetColors colors) => switch (this) {
    saved => colors.saved,
    overspent => colors.overspent,
  };
}
