import 'package:daily_budget/core/copy/category_copy.dart';
import 'package:daily_budget/core/copy/dashboard_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:daily_budget/core/widgets/segmented_control.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/dashboard/dashboard_state.dart';
import 'package:daily_budget/features/dashboard/widgets/category_rows.dart';
import 'package:daily_budget/features/dashboard/widgets/day_chip.dart';
import 'package:daily_budget/features/dashboard/widgets/refund_lines.dart';
import 'package:daily_budget/features/dashboard/widgets/single_category_view.dart';
import 'package:flutter/material.dart';

/// The `Where your money went` card (F-013 section 2.2, design section 4):
/// the heading with its (i), the This month / One day control, the date chip
/// for One day, then the categories as rows, one sentence or `Nothing
/// spent`, and the refund lines when there are refunds.
class WhereMoneyWentCard extends StatelessWidget {
  const new({
    required this.view,
    required this.onRange,
    required this.onDay,
    super.key,
  });

  final MonthDashboard view;

  final ValueChanged<DashboardRange> onRange;

  final ValueChanged<CalendarDate> onDay;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final breakdown = view.breakdown;
    final dayText = formatWeekdayDayMonth(view.day);

    final content = switch (breakdown.kind) {
      BreakdownKind.empty => Text(
        view.isOneDay
            ? DashboardCopy.emptyOneDay(dayText)
            : DashboardCopy.emptyThisMonth,
        style: BudgetTypeScale.bodyLarge.copyWith(color: colors.textSecondary),
      ),
      BreakdownKind.single => _single(breakdown, dayText),
      BreakdownKind.several => CategoryRows(breakdown: breakdown),
    };

    return BudgetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    DashboardCopy.sectionTitle,
                    style: context.budgetText.title.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              const InfoButton(
                label: DashboardCopy.sectionTitle,
                info: (
                  title: DashboardCopy.sectionTitle,
                  body: DashboardCopy.sectionInfo,
                ),
              ),
            ],
          ),
          const SizedBox(height: BudgetSpacing.space1),
          SegmentedControl(
            segments: [
              for (final (index, range) in DashboardRange.values.indexed)
                (
                  label: range == DashboardRange.month
                      ? DashboardCopy.thisMonth
                      : DashboardCopy.oneDay,
                  hint: range == DashboardRange.month
                      ? DashboardCopy.thisMonthHint
                      : DashboardCopy.oneDayHint,
                  semantics: DashboardCopy.segmentSemantics(
                    range == DashboardRange.month
                        ? DashboardCopy.thisMonth
                        : DashboardCopy.oneDay,
                    selected: range == view.range,
                    index: index,
                    count: DashboardRange.values.length,
                  ),
                ),
            ],
            selectedIndex: view.range.index,
            onChanged: (index) => onRange(DashboardRange.values[index]),
          ),
          if (view.isOneDay) ...[
            const SizedBox(height: BudgetSpacing.space3),
            DayChip(day: view.day, limits: view.limits, onPicked: onDay),
          ],
          const SizedBox(height: BudgetSpacing.space4),
          AnimatedSwitcher(
            duration: BudgetMotion.of(context).base,
            child: KeyedSubtree(
              key: ValueKey((view.range, view.day, view.monthId)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  content,
                  if (breakdown.hasRefunds) ...[
                    const SizedBox(height: BudgetSpacing.space4),
                    RefundLines(breakdown: breakdown),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _single(CategoryBreakdown breakdown, String dayText) {
    final category = breakdown.singleCategory!;
    final amount = formatRupees(breakdown.spent);
    final name = CategoryCopy.nameOf(category);
    final sentence = view.isOneDay
        ? DashboardCopy.singleOneDay(amount, dayText, name)
        : view.ended
        ? DashboardCopy.singlePastMonth(amount, name)
        : DashboardCopy.singleThisMonth(amount, name);
    return SingleCategoryView(
      category: category,
      sentence: sentence,
      amount: amount,
      categoryName: name,
    );
  }
}
