import 'package:daily_budget/core/copy/dashboard_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/focus_ring.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// The outlined date chip of `One day` (design system 7.15 idle chip, F-013
/// AC-6): a calendar icon, the date, a trailing arrow. A tap opens the date
/// picker limited to [limits] (this month's budgeted days up to today; all of
/// a past month's).
class DayChip extends StatefulWidget {
  const new({
    required this.day,
    required this.limits,
    required this.onPicked,
    super.key,
  });

  final CalendarDate day;

  final SpendDateLimits limits;

  final ValueChanged<CalendarDate> onPicked;

  @override
  State<DayChip> createState() => _DayChipState();
}

class _DayChipState extends State<DayChip> {
  final _focusNode = FocusNode(debugLabel: 'DayChip');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    DateTime asLocal(CalendarDate d) => DateTime(d.year, d.month, d.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: asLocal(widget.day),
      firstDate: asLocal(widget.limits.first),
      lastDate: asLocal(widget.limits.last),
      helpText: DashboardCopy.datePickerHelp,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked == null || !mounted) return;
    widget.onPicked(CalendarDate.fromDateTime(picked));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final radius = BorderRadius.circular(BudgetRadii.sm);
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        container: true,
        button: true,
        label: DashboardCopy.dateChipSemantics(formatFullDate(widget.day)),
        hint: DashboardCopy.dateChipHint,
        excludeSemantics: true,
        onTap: _pick,
        child: FocusRing(
          focusNode: _focusNode,
          radius: BudgetRadii.sm,
          child: Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: colors.borderStrong),
            ),
            child: InkWell(
              focusNode: _focusNode,
              onTap: _pick,
              borderRadius: radius,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: BudgetSpacing.touchTarget,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BudgetSpacing.space3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: colors.textPrimary,
                      ),
                      const SizedBox(width: BudgetSpacing.space2),
                      Flexible(
                        child: Text(
                          formatWeekdayDayMonth(widget.day),
                          style: BudgetTypeScale.label.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: BudgetSpacing.space1),
                      Icon(
                        Icons.expand_more,
                        size: 18,
                        color: colors.textPrimary,
                      ),
                    ],
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
