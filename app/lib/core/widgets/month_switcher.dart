import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/budget_icon_button.dart';
import 'package:flutter/material.dart';

/// The month row of the calendar, the Dashboard and the month statement
/// (design system §7.14): the range as a heading on the left, ‹ and › on the
/// right, and on a past month a **This month** button under the range.
///
/// It only draws and calls back; the month index and the viewed month live in
/// `MonthBrowser`. A null [onPrevious] or [onNext] is a disabled button whose
/// hint says why.
class MonthSwitcher extends StatelessWidget {
  const new({
    required this.range,
    required this.onPrevious,
    required this.onNext,
    required this.previousLabel,
    required this.nextLabel,
    required this.previousDisabledHint,
    required this.nextDisabledHint,
    this.tag,
    this.suffix,
    this.thisMonthLabel,
    this.thisMonthHint,
    this.onThisMonth,
    super.key,
  });

  /// `5 Nov – 4 Dec 2026`.
  final String range;

  /// A word before the range in the heading's sentence, such as `Ended`.
  final String? tag;

  /// Text after the range in `body` `textSecondary`, such as ` · so far`.
  final String? suffix;

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final String previousLabel;
  final String nextLabel;
  final String previousDisabledHint;
  final String nextDisabledHint;

  /// The **This month** button, shown on a past month only (null hides it).
  final VoidCallback? onThisMonth;
  final String? thisMonthLabel;
  final String? thisMonthHint;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final heading = Semantics(
      header: true,
      label: [if (tag != null) tag, range].join(', '),
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: range),
              if (suffix != null)
                TextSpan(
                  text: suffix,
                  style: BudgetTypeScale.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
            ],
          ),
          style: context.budgetText.title.copyWith(color: colors.textPrimary),
        ),
      ),
    );
    final tagText = tag == null
        ? null
        : ExcludeSemantics(
            child: Text(
              tag!,
              style: BudgetTypeScale.caption.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [?tagText, heading],
              ),
            ),
            BudgetIconButton(
              icon: Icons.chevron_left,
              tooltip: previousLabel,
              hint: onPrevious == null ? previousDisabledHint : null,
              onPressed: onPrevious,
            ),
            BudgetIconButton(
              icon: Icons.chevron_right,
              tooltip: nextLabel,
              hint: onNext == null ? nextDisabledHint : null,
              onPressed: onNext,
            ),
          ],
        ),
        if (onThisMonth != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: BudgetButton.text(
              label: thisMonthLabel!,
              semanticsHint: thisMonthHint,
              onPressed: onThisMonth,
            ),
          ),
      ],
    );
  }
}
