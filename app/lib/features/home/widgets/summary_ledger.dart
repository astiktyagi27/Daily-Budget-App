import 'package:daily_budget/core/copy/home_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/home/widgets/home_layout.dart';
import 'package:daily_budget/features/home/widgets/home_ledger_row.dart';
import 'package:flutter/material.dart';

/// The ledger of the summary card (F-010 §2.2): Salary (or Money left at
/// start), Spending target, Fixed costs, Spent so far, Saved this month with
/// its savings-pot sub-line, Overspent.
class SummaryLedger extends StatelessWidget {
  const new({required this.summary, super.key});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final stacked = isLargeText(context);
    final rows = <Widget>[
      if (summary.salary case final salary?)
        HomeLedgerRow(
          label: HomeCopy.salary,
          info: HomeCopy.salaryInfo,
          amount: salary,
        ),
      if (summary.target case final target?)
        HomeLedgerRow(
          label: HomeCopy.spendingTarget,
          info: HomeCopy.spendingTargetInfo,
          amount: target,
        ),
      if (summary.moneyLeftAtStart case final start?)
        HomeLedgerRow(
          label: HomeCopy.moneyLeftAtStart,
          info: HomeCopy.moneyLeftAtStartInfo,
          amount: start,
        ),
      HomeLedgerRow(
        label: HomeCopy.fixedCosts,
        info: HomeCopy.fixedCostsInfo,
        amount: summary.fixedCosts,
      ),
      HomeLedgerRow(
        label: HomeCopy.spentSoFar,
        info: HomeCopy.spentSoFarInfo,
        amount: summary.spentSoFar,
      ),
      HomeLedgerRow(
        label: HomeCopy.savedThisMonth,
        info: HomeCopy.savedInfo,
        amount: summary.saved,
        mark: summary.savedHasMark ? LedgerMark.saved : LedgerMark.zero,
      ),
      if (summary.hasCover) _PotSubLine(summary: summary),
      HomeLedgerRow(
        label: HomeCopy.overspent,
        info: HomeCopy.overspentInfo,
        amount: summary.overspent,
        mark: summary.overspentHasMark ? LedgerMark.overspent : LedgerMark.zero,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, row) in rows.indexed) ...[
          if (stacked && i > 0) const Divider(),
          row,
        ],
      ],
    );
  }
}

class _PotSubLine extends StatelessWidget {
  const new({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final words = BudgetTypeScale.body.copyWith(color: colors.textSecondary);
    final amount = words.copyWith(
      fontWeight: FontWeight.w600,
      color: colors.textPrimary,
    );
    return Padding(
      padding: const EdgeInsets.only(
        left: BudgetSpacing.space4,
        bottom: BudgetSpacing.space2,
      ),
      child: Semantics(
        container: true,
        label: HomeCopy.potSubLine(
          formatRupeesForSpeech(summary.pot),
          formatRupeesForSpeech(summary.covered),
        ),
        child: ExcludeSemantics(
          child: ChunkedText(
            style: words,
            chunks: [
              TextSpan(
                children: [
                  TextSpan(text: formatRupees(summary.pot), style: amount),
                  const TextSpan(text: '${HomeCopy.inYourSavingsPot} ·'),
                ],
              ),
              TextSpan(
                children: [
                  TextSpan(text: formatRupees(summary.covered), style: amount),
                  const TextSpan(text: HomeCopy.usedToCoverDays),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
