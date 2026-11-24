import 'package:daily_budget/core/copy/dashboard_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/ledger_row.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// The `Refunds` and `Net spent` lines under the categories (F-013 AC-7):
/// a hairline, then two ledger rows. Shown only when the range has a refund.
class RefundLines extends StatelessWidget {
  const new({required this.breakdown, super.key});

  final CategoryBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final refunds = -breakdown.refunds;
    final net = breakdown.netSpent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, thickness: 1, color: context.budgetColors.border),
        const SizedBox(height: BudgetSpacing.space2),
        LedgerRow(
          label: DashboardCopy.refunds,
          info: (title: DashboardCopy.refunds, body: DashboardCopy.refundsInfo),
          amount: formatRupees(refunds),
          amountSpeech: formatRupeesForSpeech(refunds),
        ),
        LedgerRow(
          label: DashboardCopy.netSpent,
          info: (
            title: DashboardCopy.netSpent,
            body: DashboardCopy.netSpentInfo,
          ),
          amount: formatRupees(net),
          amountSpeech: formatRupeesForSpeech(net),
        ),
      ],
    );
  }
}
