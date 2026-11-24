import 'package:daily_budget/core/copy/search_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// The line under the chips while searching or filtering
/// (`transactions-search.md` §6): `2 results · spent ₹670`, with
/// ` · refunds ₹500` when refunds match, and `Clear all` on the right. At
/// large text `Clear all` moves under the count. A polite live region, so a
/// screen reader hears the new count when the list changes.
class ResultsLine extends StatelessWidget {
  const new({required this.summary, required this.onClearAll, super.key});

  final ResultsSummary summary;
  final VoidCallback onClearAll;

  /// Above this text size `Clear all` sits under the count.
  static const double stackAbove = 1.3;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final spent = summary.spent;
    final refunds = summary.refunds;
    final plain = BudgetTypeScale.body.copyWith(color: colors.textSecondary);
    final money = BudgetTypeScale.moneySmall.copyWith(
      color: colors.textPrimary,
    );
    InlineSpan amountPart(String word, Paise amount) => TextSpan(
      children: [
        TextSpan(text: ' · $word '),
        TextSpan(text: formatRupees(amount), style: money),
      ],
    );
    final count = Semantics(
      liveRegion: true,
      label: SearchCopy.resultsSpoken(
        summary.count,
        spent: spent == null ? null : formatRupeesForSpeech(spent),
        refunds: refunds == null ? null : formatRupeesForSpeech(refunds),
      ),
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            style: plain,
            children: [
              TextSpan(text: SearchCopy.resultsCount(summary.count)),
              if (spent != null) amountPart(SearchCopy.spentWord, spent),
              if (refunds != null) amountPart(SearchCopy.refundWord, refunds),
            ],
          ),
        ),
      ),
    );
    final clear = BudgetButton.text(
      label: SearchCopy.clearAll,
      semanticsHint: SearchCopy.clearAllHint,
      onPressed: onClearAll,
    );
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) > ResultsLine.stackAbove;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BudgetSpacing.space5,
        BudgetSpacing.space3,
        BudgetSpacing.space5,
        0,
      ),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [count, clear],
            )
          : Row(
              children: [
                Expanded(child: count),
                const SizedBox(width: BudgetSpacing.space3),
                clear,
              ],
            ),
    );
  }
}
