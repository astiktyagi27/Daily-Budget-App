import 'dart:math' as math;

import 'package:daily_budget/core/copy/calendar_copy.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/home/calendar/day_cell.dart';
import 'package:flutter/material.dart';

/// The side gutter of the weekday strip and the grid (design C-6, D-075): 14
/// dp, so the touch pitch is (width − 24) ÷ 7, exactly 48 dp on a 360 dp
/// phone. It is not a spacing-scale step.
const double calendarGridGutter = 14;

/// The widest a cell's pitch grows: a 56 dp cell plus its 4 dp gap.
const double kCalendarMaxPitch = 60;

/// The fastest a horizontal drag may end and still count as a swipe.
const double kCalendarSwipeVelocity = 300;

const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// The distance between the left edges of two neighbouring cells for a grid
/// area of [width]: the cell plus its 4 dp gap, capped for landscape.
double calendarPitch(double width) =>
    math.min(kCalendarMaxPitch, (width - 2 * (calendarGridGutter - 2)) / 7);

/// The weekday strip and the weeks of [grid] (design system §7.5). Rows take
/// the height of their tallest cell, so large text grows the cells instead of
/// clipping them.
class CalendarGridView extends StatelessWidget {
  const new({
    required this.grid,
    required this.onTap,
    this.lateSetup = false,
    super.key,
  });

  final CalendarGrid grid;

  final void Function(CalendarCell cell) onTap;

  final bool lateSetup;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pitch = calendarPitch(constraints.maxWidth);
        final cellWidth = pitch - 4;
        return Center(
          child: SizedBox(
            width: pitch * 7,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WeekdayStrip(pitch: pitch),
                const SizedBox(height: BudgetSpacing.space2),
                for (final week in grid.weeks)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final cell in week)
                          DayCell(
                            key: ValueKey(cell.date.dayNumber),
                            cell: cell,
                            width: cellWidth,
                            lateSetup: lateSetup,
                            onTap: () => onTap(cell),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// `M T W T F S S` on a `sunken` strip, columns aligned with the cells.
class _WeekdayStrip extends StatelessWidget {
  const new({required this.pitch});

  final double pitch;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.sunken,
          borderRadius: const BorderRadius.all(Radius.circular(BudgetRadii.xs)),
        ),
        child: SizedBox(
          height: 28,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: kCalendarAmountMaxScale,
            child: Row(
              children: [
                for (final letter in _weekdayLetters)
                  SizedBox(
                    width: pitch,
                    child: Center(
                      child: Text(
                        letter,
                        style: BudgetTypeScale.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The grid while a month loads: hairline boxes, no fills, marks or amounts,
/// never a `₹0` (`calendar.md` §8). One node for a screen reader.
class CalendarGridPlaceholder extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colors = context.budgetColors;
        final pitch = calendarPitch(constraints.maxWidth);
        return Semantics(
          container: true,
          label: CalendarCopy.loadingSemantics,
          excludeSemantics: true,
          child: Center(
            child: SizedBox(
              width: pitch * 7,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _WeekdayStrip(pitch: pitch),
                  const SizedBox(height: BudgetSpacing.space2),
                  for (var row = 0; row < 5; row++)
                    Row(
                      children: [
                        for (var column = 0; column < 7; column++)
                          Padding(
                            padding: const EdgeInsets.all(2),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(color: colors.border),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(BudgetRadii.xs),
                                ),
                              ),
                              child: SizedBox.square(dimension: pitch - 4),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
