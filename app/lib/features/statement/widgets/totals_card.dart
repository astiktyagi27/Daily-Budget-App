import 'package:daily_budget/core/copy/dashboard_copy.dart';
import 'package:daily_budget/core/copy/statement_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:daily_budget/core/widgets/ledger_row.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// The month totals card (design §4): `So far` or `Month total`, the ledger
/// rows with their (i), a hairline and **Left**, which equals Home's.
class TotalsCard extends StatelessWidget {
  const new({required this.statement, super.key});

  final MonthStatement statement;

  static LedgerStatus? _status(Paise amount, LedgerStatus status) =>
      amount.wholeRupees > 0 ? status : null;

  @override
  Widget build(BuildContext context) {
    final t = statement.totals;
    final colors = context.budgetColors;
    LedgerRow row(
      String label,
      String info,
      Paise amount, {
      LedgerStatus? status,
      String? text,
      String? speech,
    }) => LedgerRow(
      label: label,
      info: (title: label, body: info),
      amount: text ?? formatRupees(amount),
      amountSpeech: speech ?? formatRupeesForSpeech(amount),
      status: status,
    );

    final shortWhole = t.shortfall.wholeRupees > 0;
    return BudgetCard(
      padding: const EdgeInsets.all(BudgetSpacing.space5),
      title: statement.soFarTo == null
          ? StatementCopy.monthTotal
          : StatementCopy.soFar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(
            StatementCopy.moneyForMonth,
            StatementCopy.moneyForMonthInfo,
            t.moneyForMonth,
          ),
          row(StatementCopy.spent, StatementCopy.spentInfo, t.spent),
          if (t.hasRefunds) ...[
            row(StatementCopy.refunds, DashboardCopy.refundsInfo, -t.refunds),
            row(StatementCopy.netSpent, DashboardCopy.netSpentInfo, t.netSpent),
          ],
          row(
            StatementCopy.saved,
            StatementCopy.savedInfo,
            t.saved,
            status: _status(t.saved, LedgerStatus.saved),
          ),
          row(StatementCopy.covered, StatementCopy.coveredInfo, t.covered),
          row(
            StatementCopy.overspent,
            StatementCopy.overspentInfo,
            t.overspent,
            status: _status(t.overspent, LedgerStatus.overspent),
          ),
          row(StatementCopy.pot, StatementCopy.potInfo, t.pot),
          if (t.shortfall.isPositive)
            row(
              StatementCopy.shortThisMonth,
              StatementCopy.shortThisMonthInfo,
              -t.shortfall,
              status: LedgerStatus.overspent,
              text: shortWhole
                  ? formatRupees(-t.shortfall)
                  : StatementCopy.lessThanRupeeShort,
              speech: shortWhole
                  ? formatRupeesForSpeech(-t.shortfall)
                  : StatementCopy.lessThanRupeeShort,
            ),
          Divider(height: BudgetSpacing.space4, color: colors.border),
          _LeftRow(left: t.left),
        ],
      ),
    );
  }
}

class _LeftRow extends StatelessWidget {
  const new({required this.left});

  final Paise left;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final negative = left.wholeRupees < 0;
    final color = negative ? colors.overspent : colors.textPrimary;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: BudgetSpacing.touchTarget),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                container: true,
                label: '${StatementCopy.left}, ${formatRupeesForSpeech(left)}',
                child: ExcludeSemantics(
                  child: Text(
                    StatementCopy.left,
                    style: BudgetTypeScale.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              const InfoButton(
                label: StatementCopy.left,
                info: (title: StatementCopy.left, body: StatementCopy.leftInfo),
              ),
            ],
          ),
          ExcludeSemantics(
            child: Text(
              negative
                  ? '${StatementCopy.overspentMark} ${formatRupees(left)}'
                  : formatRupees(left),
              style: context.budgetText.moneyLarge.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
