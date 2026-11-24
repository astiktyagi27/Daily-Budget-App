import 'package:daily_budget/core/copy/home_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// The panel under the Safe to spend strip in a shortfall month (D-036,
/// `◆ −₹1,000 this month` + the note) or a zero spendable month (D-043,
/// `○ ₹0 left for daily spending`). One sentence for a screen reader.
class HomeNoticePanel extends StatelessWidget {
  const new shortfall({required Paise this.shortfall, super.key});

  const new zero({super.key}) : shortfall = null;

  /// The month's shortfall, or null for the zero spendable panel.
  final Paise? shortfall;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final amount = shortfall;
    final accent = amount != null ? colors.overspent : colors.neutral;
    final status = BudgetTypeScale.label.copyWith(
      fontWeight: FontWeight.w600,
      color: accent,
    );
    return Semantics(
      container: true,
      label: amount != null
          ? HomeCopy.shortfallSpeech(formatRupeesForSpeech(amount))
          : HomeCopy.zeroLeft,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: amount != null ? colors.overspentSoft : colors.neutralSoft,
            borderRadius: const BorderRadius.all(
              Radius.circular(BudgetRadii.md),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(BudgetSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(amount != null ? '◆' : '○', style: status),
                    const SizedBox(width: BudgetSpacing.space1),
                    Expanded(
                      child: Text(
                        amount != null
                            ? HomeCopy.shortfallThisMonth(formatRupees(-amount))
                            : HomeCopy.zeroLeft,
                        style: status,
                      ),
                    ),
                  ],
                ),
                if (amount != null) ...[
                  const SizedBox(height: BudgetSpacing.space1),
                  Text(
                    HomeCopy.shortfallNote,
                    style: BudgetTypeScale.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
