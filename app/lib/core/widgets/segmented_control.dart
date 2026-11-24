import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/focus_ring.dart';
import 'package:flutter/material.dart';

/// One segment of a [SegmentedControl]: its visible `label`, the `hint` a
/// screen reader adds, and the `semantics` sentence it reads.
typedef Segment = ({String label, String hint, String semantics});

/// A two-or-more segment choice (design system section 7.15, Dashboard):
/// a `sunken` track with a hairline edge, equal-width segments; the selected
/// one has a `surface` fill, a `borderStrong` edge, a leading check and
/// weight 600 (the check and the weight are the cues besides colour).
///
/// Labels wrap at large text and the control grows in height; they are
/// never clipped.
class SegmentedControl extends StatelessWidget {
  const new({
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  final List<Segment> segments;

  final int selectedIndex;

  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.sunken,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(BudgetRadii.md),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, segment) in segments.indexed)
              Expanded(
                child: _SegmentButton(
                  segment: segment,
                  selected: index == selectedIndex,
                  onTap: () => onChanged(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatefulWidget {
  const new({
    required this.segment,
    required this.selected,
    required this.onTap,
  });

  final Segment segment;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SegmentButton> createState() => _SegmentButtonState();
}

class _SegmentButtonState extends State<_SegmentButton> {
  final _focusNode = FocusNode(debugLabel: 'SegmentedControl');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final motion = BudgetMotion.of(context);
    final selected = widget.selected;
    final radius = BorderRadius.circular(BudgetRadii.md);
    return Semantics(
      container: true,
      button: true,
      inMutuallyExclusiveGroup: true,
      label: widget.segment.semantics,
      hint: widget.segment.hint,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: FocusRing(
        focusNode: _focusNode,
        child: AnimatedContainer(
          duration: motion.base,
          curve: BudgetMotion.standard,
          decoration: BoxDecoration(
            color: selected ? colors.surface : Colors.transparent,
            border: Border.all(
              color: selected ? colors.borderStrong : Colors.transparent,
            ),
            borderRadius: radius,
          ),
          child: InkWell(
            focusNode: _focusNode,
            onTap: widget.onTap,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: BudgetSpacing.touchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BudgetSpacing.space2,
                  vertical: BudgetSpacing.space2,
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        Icon(Icons.check, size: 16, color: colors.textPrimary),
                        const SizedBox(width: BudgetSpacing.space1),
                      ],
                      Flexible(
                        child: Text(
                          widget.segment.label,
                          textAlign: TextAlign.center,
                          style: BudgetTypeScale.label.copyWith(
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: selected
                                ? colors.textPrimary
                                : colors.textSecondary,
                          ),
                        ),
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
