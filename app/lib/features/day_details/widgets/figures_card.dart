import 'package:daily_budget/core/copy/day_details_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:daily_budget/core/widgets/ledger_row.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/day_details/day_status.dart';
import 'package:flutter/material.dart';

/// The day's ledger (`day-details.md` §3 item 5): Budget, Spent, Refunds and
/// Net spent when the day has refunds, Covered from savings with its
/// **Remove**, a hairline and the **Day result**. An upcoming day has only
/// the Budget and its sentence.
class FiguresCard extends StatelessWidget {
  const new({required this.day, required this.onRemove, super.key});

  final DaySummary day;

  /// Called by **Remove**; null when the day has no cover to take away.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final budget = day.budget!;
    final rows = <Widget>[
      LedgerRow(
        label: DayDetailsCopy.budget,
        info: DayDetailsCopy.budgetInfo,
        amount: formatRupees(budget),
        amountSpeech: formatRupeesForSpeech(budget),
      ),
    ];
    if (day.isUpcoming) {
      return BudgetCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...rows,
            const SizedBox(height: BudgetSpacing.space2),
            Text(
              DayDetailsCopy.notYetHappened,
              style: BudgetTypeScale.body.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      );
    }
    rows.add(
      LedgerRow(
        label: DayDetailsCopy.spent,
        info: DayDetailsCopy.spentInfo,
        amount: formatRupees(day.spent),
        amountSpeech: formatRupeesForSpeech(day.spent),
      ),
    );
    if (day.hasRefunds) {
      rows
        ..add(
          LedgerRow(
            label: DayDetailsCopy.refunds,
            info: DayDetailsCopy.refundsInfo,
            amount: formatRupees(-day.moneyIn),
            amountSpeech: formatRupeesForSpeech(-day.moneyIn),
          ),
        )
        ..add(
          LedgerRow(
            label: DayDetailsCopy.netSpent,
            info: DayDetailsCopy.netSpentInfo,
            amount: formatRupees(day.netSpent),
            amountSpeech: formatRupeesForSpeech(day.netSpent),
          ),
        );
    }
    if (day.hasCover) {
      rows.add(
        LedgerRow(
          label: DayDetailsCopy.covered,
          info: DayDetailsCopy.coveredInfo,
          amount: formatRupees(day.covered),
          amountSpeech: formatRupeesForSpeech(day.covered),
        ),
      );
      if (onRemove != null) {
        rows.add(
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: BudgetButton.text(
              label: DayDetailsCopy.remove,
              semanticsHint: DayDetailsCopy.removeHint,
              onPressed: onRemove,
            ),
          ),
        );
      }
    }
    final status = dayStatusOf(day);
    return BudgetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...rows,
          Divider(color: colors.border, height: BudgetSpacing.space4),
          _DayResultRow(status: status),
        ],
      ),
    );
  }
}

/// `Day result (i)` and the status words with their mark, in the status
/// colour (`label` 600 on the left, Plex 600 on the right).
class _DayResultRow extends StatelessWidget {
  const new({required this.status});

  final DayStatusText status;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final label = Row(
      mainAxisSize: stacked ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Flexible(
          child: Semantics(
            container: true,
            label: '${DayDetailsCopy.dayResult}, ${status.speech}',
            child: ExcludeSemantics(
              child: Text(
                DayDetailsCopy.dayResult,
                style: BudgetTypeScale.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        const InfoButton(
          label: DayDetailsCopy.dayResult,
          info: DayDetailsCopy.dayResultInfo,
        ),
      ],
    );
    final value = ExcludeSemantics(
      child: Text(
        '${status.mark} ${status.resultWords}',
        textAlign: TextAlign.end,
        style: BudgetTypeScale.moneyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: status.tone.color(colors),
        ),
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: BudgetSpacing.touchTarget),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [label, value],
            )
          : Row(
              children: [
                Expanded(
                  child: Align(alignment: Alignment.centerLeft, child: label),
                ),
                const SizedBox(width: BudgetSpacing.space2),
                value,
              ],
            ),
    );
  }
}
