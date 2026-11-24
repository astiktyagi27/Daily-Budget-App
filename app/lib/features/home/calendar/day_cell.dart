import 'dart:math' as math;

import 'package:daily_budget/core/copy/calendar_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/theme/budget_colors.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/focus_ring.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/home/calendar/calendar_labels.dart';
import 'package:daily_budget/features/home/calendar/calendar_marks.dart';
import 'package:flutter/material.dart';

/// Above this text scale the cell hides its amount and keeps number and mark
/// (F-011 AC-16, design system §4.2).
const double kCalendarAmountMaxScale = 1.3;

/// The smallest the amount may shrink to before it is hidden instead
/// (design system §7.5).
const double kCalendarAmountFloor = 9;

/// One day of the grid (design system §7.5). It draws the cell kinds of
/// F-011 §2.2 and reads as one sentence ([calendarCellLabel]); the touch
/// target is the cell plus half of each gap around it.
class DayCell extends StatefulWidget {
  const new({
    required this.cell,
    required this.width,
    required this.onTap,
    this.lateSetup = false,
    super.key,
  });

  final CalendarCell cell;

  /// The visible cell width; the hit area adds 2 dp on every side.
  final double width;

  /// Called for a tappable cell.
  final VoidCallback onTap;

  final bool lateSetup;

  @override
  State<DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<DayCell> {
  final _focusNode = FocusNode(debugLabel: 'DayCell');
  bool _pressed = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  CalendarMark? _mark(CalendarCell cell) => switch (cell.kind) {
    CellKind.saved => CalendarMark.saved,
    CellKind.onBudget => CalendarMark.onBudget,
    CellKind.overspent => CalendarMark.overspent,
    CellKind.today => switch (cell.todayFill!) {
      TodayFill.saved => CalendarMark.saved,
      TodayFill.onBudget => CalendarMark.onBudget,
      TodayFill.overspent => CalendarMark.overspent,
      TodayFill.nothingSpent => null,
    },
    _ => null,
  };

  Color _fill(BudgetColors colors, CalendarCell cell) => switch (cell.kind) {
    CellKind.saved => colors.savedSoft,
    CellKind.onBudget => colors.neutralSoft,
    CellKind.overspent => colors.overspentSoft,
    CellKind.today => switch (cell.todayFill!) {
      TodayFill.saved => colors.savedSoft,
      TodayFill.onBudget => colors.neutralSoft,
      TodayFill.overspent => colors.overspentSoft,
      TodayFill.nothingSpent => colors.surface,
    },
    _ => colors.bg.withValues(alpha: 0),
  };

  Color _markColor(BudgetColors colors, CalendarMark mark) => switch (mark) {
    CalendarMark.saved => colors.saved,
    CalendarMark.onBudget => colors.neutral,
    CalendarMark.overspent => colors.overspent,
  };

  @override
  Widget build(BuildContext context) {
    final cell = widget.cell;
    if (cell.kind == CellKind.outside) return _outside(context);
    final colors = context.budgetColors;
    final label = calendarCellLabel(cell, lateSetup: widget.lateSetup)!;
    final visual = _visual(context, colors, cell);
    final sized = SizedBox(width: widget.width + 4, child: visual);
    if (!cell.isTappable) {
      // Not budgeted: plain text for a screen reader, no press effect.
      return Semantics(
        container: true,
        label: label,
        excludeSemantics: true,
        child: sized,
      );
    }
    return Semantics(
      button: true,
      label: label,
      hint: CalendarCopy.cellHint,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: BudgetMotion.of(context).fast,
        child: sized,
      ),
    );
  }

  Widget _outside(BuildContext context) {
    final colors = context.budgetColors;
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.width + 4,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
            child: Align(
              alignment: Alignment.topLeft,
              child: _number(
                context,
                widget.cell,
                colors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _number(BuildContext context, CalendarCell cell, Color color) {
    final text = cell.isMonthFirstDay
        ? formatDayMonth(cell.date)
        : '${cell.date.day}';
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: kCalendarAmountMaxScale,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          style: BudgetTypeScale.caption.copyWith(
            color: color,
            fontWeight: cell.kind == CellKind.today
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _visual(BuildContext context, BudgetColors colors, CalendarCell cell) {
    final numberColor = switch (cell.kind) {
      CellKind.today => colors.accent,
      CellKind.upcoming || CellKind.notBudgeted => colors.textSecondary,
      _ => colors.textPrimary,
    };
    final mark = _mark(cell);
    final amount = cell.netSpent == null
        ? null
        : formatRupeesShort(cell.netSpent!);
    final amountColor = switch (cell.kind) {
      CellKind.saved => colors.saved,
      CellKind.onBudget => colors.neutral,
      CellKind.overspent => colors.overspent,
      _ => colors.textPrimary,
    };
    final inner = widget.width - 8;
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: _fill(colors, cell),
        borderRadius: const BorderRadius.all(Radius.circular(BudgetRadii.xs)),
        border: switch (cell.kind) {
          CellKind.upcoming => Border.all(color: colors.border),
          CellKind.today => Border.all(color: colors.accent, width: 2),
          _ => null,
        },
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: widget.width),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: _number(context, cell, numberColor)),
                      if (mark != null)
                        CalendarMarkPaint(
                          mark: mark,
                          color: _markColor(colors, mark),
                        ),
                    ],
                  ),
                  if (amount != null && _amountFits(context, amount, inner))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: MediaQuery.withClampedTextScaling(
                        maxScaleFactor: kCalendarAmountMaxScale,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            amount,
                            maxLines: 1,
                            style: context.budgetText.moneySmall.copyWith(
                              color: amountColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (cell.isChangeDay)
              Positioned(
                top: 4,
                left: 0,
                right: 0,
                child: Center(child: CalendarChangeTick(color: colors.accent)),
              ),
          ],
        ),
      ),
    );
    final padded = Padding(padding: const EdgeInsets.all(2), child: box);
    if (!cell.isTappable) return padded;
    return FocusRing(
      focusNode: _focusNode,
      child: InkWell(
        focusNode: _focusNode,
        onTap: widget.onTap,
        onHighlightChanged: (value) => setState(() => _pressed = value),
        overlayColor: WidgetStateProperty.fromMap({
          WidgetState.pressed: colors.sunken.withValues(alpha: 0.6),
          WidgetState.any: colors.sunken.withValues(alpha: 0),
        }),
        splashFactory: NoSplash.splashFactory,
        borderRadius: const BorderRadius.all(Radius.circular(BudgetRadii.xs)),
        child: padded,
      ),
    );
  }

  /// Whether the amount is shown: not above 1.3x text, and not so wide that
  /// fitting it would take it under the 9 sp floor (design system §7.5).
  bool _amountFits(BuildContext context, String amount, double inner) {
    final scaler = MediaQuery.textScalerOf(context);
    if (scaler.scale(1) > kCalendarAmountMaxScale) return false;
    const style = BudgetTypeScale.moneySmall;
    final painter = TextPainter(
      text: TextSpan(text: amount, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final natural = scaler.scale(style.fontSize!);
    final fitted = math.min(natural, natural * inner / painter.width);
    painter.dispose();
    return fitted >= kCalendarAmountFloor;
  }
}
