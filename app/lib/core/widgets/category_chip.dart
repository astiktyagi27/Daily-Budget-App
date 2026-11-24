import 'package:daily_budget/core/help/nav_tooltip.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/focus_ring.dart';
import 'package:flutter/material.dart';

/// The small category tag on a list row (design system §7.15,
/// `transactions-search.md` T-4): a `neutralSoft` pill with the category's
/// name, no icon. Tapping it changes the category.
///
/// The visible tag is about 24 dp; its tap target is [targetHeight] (48 dp)
/// and reaches up and down into the row. It reads as its own stop
/// (`Category Food, change`) and has the tooltip `Change category`.
class CategoryChip extends StatefulWidget {
  const new({
    required this.name,
    required this.semanticsLabel,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final String name;

  /// `Category Food, change`.
  final String semanticsLabel;

  /// `Change category`.
  final String tooltip;
  final VoidCallback onPressed;

  static const double targetHeight = BudgetSpacing.touchTarget;

  @override
  State<CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<CategoryChip> {
  final _focusNode = FocusNode(debugLabel: 'CategoryChip');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    const shape = BorderRadius.all(Radius.circular(BudgetRadii.full));
    return Tooltip(
      message: widget.tooltip,
      showDuration: NavTooltip.showDuration,
      excludeFromSemantics: true,
      child: Semantics(
        container: true,
        button: true,
        label: widget.semanticsLabel,
        excludeSemantics: true,
        onTap: widget.onPressed,
        child: FocusRing(
          focusNode: _focusNode,
          radius: BudgetRadii.full,
          child: InkWell(
            focusNode: _focusNode,
            onTap: widget.onPressed,
            borderRadius: shape,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: CategoryChip.targetHeight,
                minWidth: BudgetSpacing.touchTarget,
              ),
              child: Center(
                widthFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.neutralSoft,
                    borderRadius: shape,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BudgetSpacing.space2,
                      vertical: BudgetSpacing.space1,
                    ),
                    child: Text(
                      widget.name,
                      style: BudgetTypeScale.caption.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
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
