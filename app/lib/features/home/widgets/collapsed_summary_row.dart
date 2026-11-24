import 'package:daily_budget/core/copy/home_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// The 56 dp row pinned under the status bar once the summary card has
/// scrolled away (F-010 AC-15, `home-summary.md` §6): `₹19,370 left ·
/// ₹830/day`, or `◆ ₹1,200 over this month · ₹0/day`. Tapping it scrolls
/// Home to the top. Safe to spend is not in it.
class CollapsedSummaryRow extends StatelessWidget {
  const new({required this.summary, required this.onTap, super.key});

  final HomeSummary summary;

  final VoidCallback onTap;

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final over = summary.isOver;
    final money = BudgetTypeScale.moneyMedium.copyWith(
      color: over ? colors.overspent : colors.textPrimary,
    );
    final plainMoney = BudgetTypeScale.moneyMedium.copyWith(
      color: colors.textPrimary,
    );
    final words = BudgetTypeScale.body.copyWith(color: colors.textSecondary);
    final daily = formatRupees(summary.dailyBudget);
    final speech = over
        ? HomeCopy.collapsedOverSpeech(
            formatRupeesForSpeech(-summary.left),
            formatRupeesForSpeech(summary.dailyBudget),
          )
        : HomeCopy.collapsedSpeech(
            formatRupeesForSpeech(summary.left),
            formatRupeesForSpeech(summary.dailyBudget),
          );
    return Semantics(
      container: true,
      button: true,
      label: speech,
      hint: HomeCopy.collapsedHint,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: colors.surface,
        shape: Border(bottom: BorderSide(color: colors.border)),
        child: InkWell(
          onTap: onTap,
          excludeFromSemantics: true,
          child: SizedBox(
            height: height + MediaQuery.paddingOf(context).top,
            width: double.infinity,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                BudgetSpacing.space5,
                MediaQuery.paddingOf(context).top,
                BudgetSpacing.space5,
                0,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                // Scaled down rather than cut when the figures are wide.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (over) TextSpan(text: '◆ ', style: money),
                        TextSpan(
                          text: formatRupees(
                            over ? -summary.left : summary.left,
                          ),
                          style: money,
                        ),
                        TextSpan(
                          text: over
                              ? HomeCopy.overThisMonth
                              : HomeCopy.leftWord,
                          style: words,
                        ),
                        TextSpan(text: ' · ', style: words),
                        TextSpan(text: daily, style: plainMoney),
                        TextSpan(text: '/day', style: words),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
