import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// The bar pinned to the bottom of a full-screen form (design system §7.13):
/// the screen's Primary button, and optionally one live summary line above
/// it. `surface` fill, a 1 dp `border` rule on top, no shadow.
///
/// It is for portrait at text up to 1.3 only: check [fits], and above that
/// or in landscape put [line] and [action] inline at the end of the form
/// instead, because a pinned bar would take too much of the screen.
///
/// With the keyboard open the dock keeps one part: the [line] when there is
/// one (month setup hides Confirm until the keyboard closes), otherwise the
/// [action] (Add spend keeps only Save). The [line] is decorative for screen
/// readers; the form's own preview is the readable source.
class ActionDock extends StatelessWidget {
  const new({this.line, this.action, super.key})
    : assert(line != null || action != null, 'a dock needs a line or action');

  /// The summary line, e.g. `Daily budget` on the left and `₹830 a day` on
  /// the right.
  final Widget? line;

  /// The Primary button.
  final Widget? action;

  /// The largest text scale at which the dock is pinned.
  static const double maxTextScale = 1.3;

  /// Whether the dock fits [context]: portrait, text at most 1.3.
  static bool fits(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.portrait &&
      MediaQuery.textScalerOf(context).scale(1) <= maxTextScale;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final line = this.line;
    final action = keyboardOpen && line != null ? null : this.action;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          BudgetSpacing.space5,
          BudgetSpacing.space4,
          BudgetSpacing.space5,
          // The phone's bottom padding is already 0 while the keyboard is up.
          BudgetSpacing.space4 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (line != null) ExcludeSemantics(child: line),
            if (line != null && action != null)
              const SizedBox(height: BudgetSpacing.space3),
            ?action,
          ],
        ),
      ),
    );
  }
}
