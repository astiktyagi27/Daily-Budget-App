import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// The tour's page indicator (welcome-tour §2.1): one ink tick per slide.
/// The current tick is long and `accent`, the others short and
/// `borderStrong`, so the position shows by length as well as colour.
/// A screen reader reads `Slide <n> of <count>`.
class PageIndicator extends StatelessWidget {
  const new({required this.index, required this.count, super.key});

  /// Zero-based current slide.
  final int index;
  final int count;

  static const double tickHeight = 4;
  static const double tickGap = 6;
  static const double currentWidth = 24;
  static const double otherWidth = 8;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final duration = BudgetMotion.of(context).base;
    return Semantics(
      container: true,
      label: ScreenCopy.slidePosition(index + 1, count),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(width: tickGap),
              AnimatedContainer(
                duration: duration,
                curve: BudgetMotion.standard,
                width: i == index ? currentWidth : otherWidth,
                height: tickHeight,
                decoration: BoxDecoration(
                  color: i == index ? colors.accent : colors.borderStrong,
                  borderRadius: BorderRadius.circular(BudgetRadii.full),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
