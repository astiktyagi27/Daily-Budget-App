import 'package:daily_budget/core/copy/month_setup_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// The Home card of a set-up month (F-008 §2.1, `month-setup.md` §10.2):
/// the dates and today's daily budget, a shortfall panel when the month was
/// started with **Continue anyway**, and **Edit this month**.
///
/// [onEdit] is null when the month cannot be edited today (the device date
/// is outside it); the button is then left out.
class ThisMonthCard extends StatelessWidget {
  const new({
    required this.result,
    required this.today,
    required this.onEdit,
    super.key,
  });

  final MonthResult result;
  final CalendarDate today;
  final VoidCallback? onEdit;

  /// Today's budget; before the first budgeted day, the one the current
  /// period starts with.
  Paise get _dailyBudget {
    if (result.month.contains(today)) {
      final budget = result.dayOn(today).budget;
      if (budget != null) return budget;
    }
    return result.currentPeriod.budgets.first;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final month = result.month;
    final shortfall = result.totals.shortfall;
    final hasShortfall = shortfall.isPositive;
    final daily = _dailyBudget;
    final base = BudgetTypeScale.bodyLarge.copyWith(color: colors.textPrimary);
    final speech = [
      MonthSetupCopy.homeCardSpeech(
        _spokenDate(month.start),
        _spokenDate(month.end),
        formatRupeesForSpeech(daily),
      ),
      if (hasShortfall)
        MonthSetupCopy.homeShortfallSpeech(formatRupeesForSpeech(shortfall)),
    ].join(' ');
    return BudgetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label: speech,
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    MonthSetupCopy.homeThisMonth,
                    style: context.budgetText.title.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: BudgetSpacing.space3),
                  Text.rich(
                    TextSpan(
                      style: base,
                      children: [
                        TextSpan(
                          text: '${formatRange(month.start, month.end)} · ',
                        ),
                        TextSpan(
                          text: MonthSetupCopy.aDay(formatRupees(daily)),
                          style: BudgetTypeScale.moneyMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasShortfall) ...[
                    const SizedBox(height: BudgetSpacing.space3),
                    _ShortfallPanel(shortfall: shortfall),
                  ],
                ],
              ),
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(height: BudgetSpacing.space4),
            BudgetButton.secondary(
              label: MonthSetupCopy.titleEdit,
              semanticsHint: MonthSetupCopy.homeEditHint,
              onPressed: onEdit,
            ),
          ],
        ],
      ),
    );
  }

  /// `5 November`, for the screen reader.
  static String _spokenDate(CalendarDate date) =>
      formatFullDate(date).split(' ').skip(1).join(' ');
}

class _ShortfallPanel extends StatelessWidget {
  const new({required this.shortfall});

  final Paise shortfall;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final status = BudgetTypeScale.label.copyWith(
      fontWeight: FontWeight.w600,
      color: colors.overspent,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.overspentSoft,
        borderRadius: const BorderRadius.all(Radius.circular(BudgetRadii.md)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BudgetSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('◆', style: status),
                const SizedBox(width: BudgetSpacing.space1),
                Expanded(
                  child: Text(
                    MonthSetupCopy.homeShortfall(formatRupees(-shortfall)),
                    style: status,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BudgetSpacing.space1),
            Text(
              MonthSetupCopy.homeShortfallNote,
              style: BudgetTypeScale.body.copyWith(color: colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Home card of a new month that has started and is not set up yet
/// (`month-setup.md` §10.3). It replaces the This month card until the new
/// month is confirmed.
class NewMonthCard extends StatelessWidget {
  const new({required this.onSetUp, super.key});

  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return BudgetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label:
                '${MonthSetupCopy.homeNewMonthTitle}. '
                '${MonthSetupCopy.homeNewMonthDescription}',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    MonthSetupCopy.homeNewMonthTitle,
                    style: context.budgetText.title.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: BudgetSpacing.space2),
                  Text(
                    MonthSetupCopy.homeNewMonthDescription,
                    style: BudgetTypeScale.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: BudgetSpacing.space4),
          BudgetButton.primary(
            label: MonthSetupCopy.titleNew,
            semanticsHint: MonthSetupCopy.homeNewMonthHint,
            onPressed: onSetUp,
          ),
        ],
      ),
    );
  }
}
