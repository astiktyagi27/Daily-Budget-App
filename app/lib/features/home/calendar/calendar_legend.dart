import 'package:daily_budget/core/copy/calendar_copy.dart';
import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/features/home/calendar/calendar_marks.dart';
import 'package:flutter/material.dart';

/// `● Saved  ○ On budget  ◆ Overspent` (and `▬ Budget changed` in a month
/// with a change) with its (i) (`calendar.md` §3 item 2). It wraps between
/// items at large text; the (i) stays after the last item.
class CalendarLegend extends StatelessWidget {
  const new({required this.showChange, super.key});

  final bool showChange;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final style = BudgetTypeScale.caption.copyWith(color: colors.textSecondary);
    Widget item(Widget mark, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: BudgetSpacing.space1),
        Flexible(child: Text(text, style: style)),
      ],
    );
    final items = Wrap(
      spacing: BudgetSpacing.space3,
      runSpacing: BudgetSpacing.space1,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        item(
          CalendarMarkPaint(mark: CalendarMark.saved, color: colors.saved),
          CalendarCopy.legendSaved,
        ),
        item(
          CalendarMarkPaint(mark: CalendarMark.onBudget, color: colors.neutral),
          CalendarCopy.legendOnBudget,
        ),
        item(
          CalendarMarkPaint(
            mark: CalendarMark.overspent,
            color: colors.overspent,
          ),
          CalendarCopy.legendOverspent,
        ),
        if (showChange)
          item(
            CalendarChangeTick(color: colors.accent),
            CalendarCopy.legendChanged,
          ),
      ],
    );
    return Row(
      children: [
        Expanded(
          child: Semantics(
            container: true,
            label: [
              CalendarCopy.legendSemantics,
              if (showChange) CalendarCopy.legendChanged,
            ].join(', '),
            child: ExcludeSemantics(child: items),
          ),
        ),
        _info(),
      ],
    );
  }

  Widget _info() => const InfoButton(
    label: CalendarCopy.legendInfoTitle,
    info: (
      title: CalendarCopy.legendInfoTitle,
      body: CalendarCopy.legendInfoBody,
    ),
  );
}
