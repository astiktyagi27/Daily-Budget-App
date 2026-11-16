import 'package:daily_budget/core/help/nav_tooltip.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/focus_ring.dart';
import 'package:flutter/material.dart';

/// An icon-only control (design system §7.1, F-004 §2.3): a 48 × 48 dp
/// target around a [iconSize] icon, a long-press tooltip and the same text as
/// its screen-reader label. Screens use this instead of a bare `IconButton`
/// (the help-rule architecture test).
///
/// [hint] is read after the label, e.g. `Back` · `Leave this screen`.
class BudgetIconButton extends StatefulWidget {
  const new({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.hint,
    this.iconSize = 24,
    super.key,
  });

  final IconData icon;

  /// The long-press tooltip and the screen-reader label.
  final String tooltip;
  final String? hint;
  final VoidCallback? onPressed;
  final double iconSize;

  @override
  State<BudgetIconButton> createState() => _BudgetIconButtonState();
}

class _BudgetIconButtonState extends State<BudgetIconButton> {
  final _focusNode = FocusNode(debugLabel: 'BudgetIconButton');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final enabled = widget.onPressed != null;
    return Tooltip(
      message: widget.tooltip,
      showDuration: NavTooltip.showDuration,
      // The label below already carries the text for screen readers.
      excludeFromSemantics: true,
      child: Semantics(
        container: true,
        button: true,
        enabled: enabled,
        label: widget.tooltip,
        hint: widget.hint,
        child: FocusRing(
          focusNode: _focusNode,
          radius: BudgetSpacing.touchTarget / 2,
          child: InkResponse(
            focusNode: _focusNode,
            onTap: widget.onPressed,
            radius: 24,
            child: SizedBox.square(
              dimension: BudgetSpacing.touchTarget,
              child: Center(
                child: Icon(
                  widget.icon,
                  size: widget.iconSize,
                  color: enabled ? colors.textPrimary : colors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
