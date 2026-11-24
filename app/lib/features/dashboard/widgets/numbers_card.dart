import 'package:daily_budget/core/copy/dashboard_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/help/label_description.dart';
import 'package:daily_budget/core/theme/budget_colors.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/dashboard/widgets/day_strip.dart';
import 'package:flutter/material.dart';

/// The `This month in numbers` card (F-013 section 2.3, design section 5):
/// the highest-spending day, the average and how the days turned out, over
/// the days that have ended, or one sentence when the first day is not over.
class NumbersCard extends StatelessWidget {
  const new({
    required this.figures,
    required this.ended,
    required this.onOpenDay,
    super.key,
  });

  final MonthFigures figures;

  /// Whether the month is over (the caption then says `all`).
  final bool ended;

  final ValueChanged<CalendarDate> onOpenDay;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final hairline = Divider(height: 1, thickness: 1, color: colors.border);

    if (figures.noEndedDays) {
      return BudgetCard(
        title: DashboardCopy.numbersTitle,
        child: Text(
          DashboardCopy.firstDay,
          style: BudgetTypeScale.bodyLarge.copyWith(
            color: colors.textSecondary,
          ),
        ),
      );
    }

    final average = figures.average!;
    return BudgetCard(
      title: DashboardCopy.numbersTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HighestDayRow(highest: figures.highest, onOpen: onOpenDay),
          hairline,
          _Figure(
            label: DashboardCopy.averageDay,
            info: (
              title: DashboardCopy.averageDay,
              body: DashboardCopy.averageDayInfo,
            ),
            semantics:
                '${DashboardCopy.averageDay}, '
                '${DashboardCopy.perDay(formatRupeesForSpeech(average))}',
            value: Text(
              DashboardCopy.perDay(formatRupees(average)),
              style: context.budgetText.moneyMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          hairline,
          _DaysFigure(figures: figures),
          const SizedBox(height: BudgetSpacing.space3),
          Text(
            ended
                ? DashboardCopy.basedOnAll(figures.endedDays)
                : DashboardCopy.basedOnEnded(figures.endedDays),
            style: BudgetTypeScale.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A figure: its label with an (i), then the [value] under it. One screen
/// reader item reading [semantics].
class _Figure extends StatelessWidget {
  const new({
    required this.label,
    required this.info,
    required this.semantics,
    required this.value,
    this.extra,
  });

  final String label;
  final ({String title, String body}) info;
  final String semantics;
  final Widget value;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BudgetSpacing.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabelDescription(label: label, info: info, announce: false),
          Semantics(
            container: true,
            label: semantics,
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [value, ?extra],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighestDayRow extends StatelessWidget {
  const new({required this.highest, required this.onOpen});

  final HighestDay? highest;

  final ValueChanged<CalendarDate> onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final money = context.budgetText.moneyMedium.copyWith(
      color: colors.textPrimary,
    );
    const info = (
      title: DashboardCopy.highestDay,
      body: DashboardCopy.highestDayInfo,
    );
    final best = highest;
    if (best == null) {
      return _Figure(
        label: DashboardCopy.highestDay,
        info: info,
        semantics: DashboardCopy.highestSemanticsNone,
        value: Text(DashboardCopy.noSpendsYet, style: money),
      );
    }
    final amount = formatRupees(best.amount);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BudgetSpacing.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LabelDescription(
            label: DashboardCopy.highestDay,
            info: info,
            announce: false,
          ),
          Semantics(
            container: true,
            button: true,
            label: DashboardCopy.highestSemantics(
              formatFullDate(best.date),
              formatRupeesForSpeech(best.amount),
              moreDays: best.moreDays,
            ),
            hint: DashboardCopy.highestDayHint,
            excludeSemantics: true,
            onTap: () => onOpen(best.date),
            child: InkWell(
              onTap: () => onOpen(best.date),
              borderRadius: BorderRadius.circular(BudgetRadii.sm),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: BudgetSpacing.touchTarget,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: formatWeekdayDayMonth(best.date),
                              style: BudgetTypeScale.label.copyWith(
                                fontWeight: FontWeight.w500,
                                color: colors.textPrimary,
                              ),
                            ),
                            TextSpan(text: ' · $amount', style: money),
                            if (best.moreDays > 0)
                              TextSpan(
                                text:
                                    ' ${DashboardCopy.moreDays(best.moreDays)}',
                                style: BudgetTypeScale.body.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 24,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DaysFigure extends StatelessWidget {
  const new({required this.figures});

  final MonthFigures figures;

  /// The mark and its number in [color]; a count of 0 keeps its mark but in
  /// `neutral` (no green for nothing, design H-3).
  InlineSpan _count(
    BudgetColors colors, {
    required String mark,
    required Color color,
    required int count,
    required String words,
  }) {
    return TextSpan(
      children: [
        TextSpan(
          text: '$mark $count',
          style: TextStyle(color: count == 0 ? colors.neutral : color),
        ),
        TextSpan(text: ' $words'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final counts = figures.counts;
    return _Figure(
      label: DashboardCopy.days,
      info: (title: DashboardCopy.days, body: DashboardCopy.daysInfo),
      semantics: DashboardCopy.daysSemantics(
        saved: counts.saved,
        onBudget: counts.onBudget,
        overspent: counts.overspent,
        covered: counts.covered,
      ),
      value: Text.rich(
        TextSpan(
          style: BudgetTypeScale.label.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
          children: [
            _count(
              colors,
              mark: '●',
              color: colors.saved,
              count: counts.saved,
              words: 'saved',
            ),
            const TextSpan(text: ' · '),
            _count(
              colors,
              mark: '○',
              color: colors.neutral,
              count: counts.onBudget,
              words: 'on budget',
            ),
            const TextSpan(text: ' · '),
            _count(
              colors,
              mark: '◆',
              color: colors.overspent,
              count: counts.overspent,
              words: 'overspent',
            ),
          ],
        ),
      ),
      extra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (counts.covered > 0) ...[
            const SizedBox(height: BudgetSpacing.space1),
            Text(
              DashboardCopy.covered(counts.covered),
              style: BudgetTypeScale.body.copyWith(color: colors.textSecondary),
            ),
          ],
          const SizedBox(height: BudgetSpacing.space2),
          DayStrip(statuses: figures.strip),
        ],
      ),
    );
  }
}
