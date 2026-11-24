import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/focus_ring.dart';
import 'package:flutter/material.dart';

enum BudgetButtonVariant { primary, secondary, text, destructive }

/// The app's button (design system §7.1). Its look comes from the theme's
/// button themes; this widget adds the focus ring, the loading state, the
/// destructive variant and full width.
///
/// Disabled when [onPressed] is null. Labels are sentence case, verb first.
class BudgetButton extends StatefulWidget {
  /// Accent fill. At most one per screen.
  const new primary({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expand = true,
    this.focusNode,
    this.semanticsHint,
    super.key,
  }) : variant = BudgetButtonVariant.primary,
       icon = null;

  /// Surface fill with a `borderStrong` outline, optionally with a leading
  /// [icon] (Add spend).
  const new secondary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.focusNode,
    this.semanticsHint,
    super.key,
  }) : variant = BudgetButtonVariant.secondary;

  /// Accent text, no fill.
  const new text({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expand = false,
    this.focusNode,
    this.semanticsHint,
    super.key,
  }) : variant = BudgetButtonVariant.text,
       icon = null;

  /// Secondary style with `overspent` text and a leading icon. Always followed
  /// by a confirm sheet (design system §7.1).
  const new destructive({
    required this.label,
    required this.onPressed,
    this.icon = Icons.delete_outline,
    this.loading = false,
    this.expand = true,
    this.focusNode,
    this.semanticsHint,
    super.key,
  }) : variant = BudgetButtonVariant.destructive;

  final String label;
  final VoidCallback? onPressed;
  final BudgetButtonVariant variant;
  final IconData? icon;

  /// Shows a progress ring in place of the label; the width stays the same
  /// and taps are ignored.
  final bool loading;

  /// Takes the full available width (primary and secondary on mobile).
  final bool expand;
  final FocusNode? focusNode;

  /// Read after the label by screen readers, e.g. `Close this explanation`.
  final String? semanticsHint;

  @override
  State<BudgetButton> createState() => _BudgetButtonState();
}

class _BudgetButtonState extends State<BudgetButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final enabled = widget.onPressed != null;
    final onPressed = widget.loading ? () {} : widget.onPressed;
    final labelColor = !enabled
        ? colors.textSecondary
        : switch (widget.variant) {
            BudgetButtonVariant.primary => colors.onAccent,
            BudgetButtonVariant.secondary => colors.textPrimary,
            BudgetButtonVariant.text => colors.accent,
            BudgetButtonVariant.destructive => colors.overspent,
          };

    Widget content = Text(widget.label);
    if (widget.icon case final icon?) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: BudgetSpacing.space2),
          Flexible(child: content),
        ],
      );
    }
    if (widget.loading) {
      content = Stack(
        alignment: Alignment.center,
        children: [
          Visibility.maintain(visible: false, child: content),
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: labelColor),
          ),
        ],
      );
    }

    final button = switch (widget.variant) {
      BudgetButtonVariant.primary => FilledButton(
        onPressed: onPressed,
        focusNode: widget.focusNode,
        child: content,
      ),
      BudgetButtonVariant.secondary => OutlinedButton(
        onPressed: onPressed,
        focusNode: widget.focusNode,
        child: content,
      ),
      BudgetButtonVariant.destructive => OutlinedButton(
        onPressed: onPressed,
        focusNode: widget.focusNode,
        style: OutlinedButton.styleFrom(foregroundColor: colors.overspent),
        child: content,
      ),
      BudgetButtonVariant.text => TextButton(
        onPressed: onPressed,
        focusNode: widget.focusNode,
        child: content,
      ),
    };

    final result = Semantics(
      label: widget.loading ? 'Loading' : null,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (widget.expand)
              SizedBox(width: double.infinity, child: button)
            else
              button,
            if (_focused) const Positioned.fill(child: _FocusRing()),
          ],
        ),
      ),
    );
    final hint = widget.semanticsHint;
    if (hint == null) return result;
    // Merged so the hint lands on the button's own node.
    return MergeSemantics(
      child: Semantics(hint: hint, child: result),
    );
  }
}

/// The 2 dp `focus` ring, drawn 2 dp outside the button without changing its
/// size (design system §7.1).
class _FocusRing extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: FocusRingPainter(color: context.budgetColors.focus),
      ),
    );
  }
}
