import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/focus_ring.dart';
import 'package:flutter/material.dart';

/// A filter chip (design system §7.15): idle is a `surface` pill with a
/// `borderStrong` outline; **active** (not at its default) is filled
/// `accentSoft` with a leading check, so the state never rests on colour
/// alone. It opens a sheet, so a small arrow trails the label.
///
/// 48 dp tall target; the label never wraps or truncates (the chips row
/// scrolls sideways instead). Named `BudgetFilterChip` so it does not clash
/// with Material's `FilterChip`.
class BudgetFilterChip extends StatefulWidget {
  const new({
    required this.label,
    required this.active,
    required this.onPressed,
    required this.semanticsLabel,
    this.semanticsHint,
    super.key,
  });

  final String label;

  /// Filled with a leading check.
  final bool active;
  final VoidCallback onPressed;

  /// `Dates, This month, filter, button` (the screen reader's sentence).
  final String semanticsLabel;
  final String? semanticsHint;

  @override
  State<BudgetFilterChip> createState() => _BudgetFilterChipState();
}

class _BudgetFilterChipState extends State<BudgetFilterChip> {
  final _focusNode = FocusNode(debugLabel: 'BudgetFilterChip');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    const shape = BorderRadius.all(Radius.circular(BudgetRadii.full));
    final label = Text(
      widget.label,
      maxLines: 1,
      softWrap: false,
      style: BudgetTypeScale.label.copyWith(color: colors.textPrimary),
    );
    return Semantics(
      container: true,
      button: true,
      label: widget.semanticsLabel,
      hint: widget.semanticsHint,
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: FocusRing(
        focusNode: _focusNode,
        radius: BudgetSpacing.touchTarget / 2,
        child: InkWell(
          focusNode: _focusNode,
          onTap: widget.onPressed,
          borderRadius: shape,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: BudgetSpacing.touchTarget,
            ),
            child: Center(
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.active ? colors.accentSoft : colors.surface,
                  borderRadius: shape,
                  border: widget.active
                      ? null
                      : Border.all(color: colors.borderStrong),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BudgetSpacing.space3,
                    vertical: BudgetSpacing.space2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.active) ...[
                        Icon(Icons.check, size: 18, color: colors.accent),
                        const SizedBox(width: BudgetSpacing.space1),
                      ],
                      label,
                      const SizedBox(width: BudgetSpacing.space1),
                      Icon(
                        Icons.expand_more,
                        size: 18,
                        color: colors.textSecondary,
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
