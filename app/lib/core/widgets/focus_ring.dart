import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Draws the 2 dp `focus` ring (design system §7.1) over [child] while
/// [focusNode] has the primary focus and focus is moved with a keyboard or
/// D-pad (Flutter's traditional highlight mode). Touch users never see it:
/// focus moved back to a control after a sheet closes stays invisible, and
/// TalkBack draws its own focus box.
///
/// Primary focus only, so a row does not light up while the (i) inside it
/// has the focus. The ring never changes the child's size or hit area.
class FocusRing extends StatefulWidget {
  const new({
    required this.focusNode,
    required this.child,
    this.radius = BudgetRadii.md,
    this.inside = false,
    super.key,
  });

  final FocusNode focusNode;
  final Widget child;

  /// The corner radius of the box the ring follows.
  final double radius;

  /// Draws the ring 2 dp inside the box instead of 2 dp outside it, for
  /// full-width list rows whose card would clip an outer ring.
  final bool inside;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_changed);
    FocusManager.instance.addHighlightModeListener(_modeChanged);
  }

  @override
  void didUpdateWidget(FocusRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_changed);
      widget.focusNode.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_changed);
    FocusManager.instance.removeHighlightModeListener(_modeChanged);
    super.dispose();
  }

  void _modeChanged(FocusHighlightMode _) => _changed();

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final visible =
        widget.focusNode.hasPrimaryFocus &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (visible)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: FocusRingPainter(
                  color: context.budgetColors.focus,
                  radius: widget.radius,
                  inside: widget.inside,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Paints the focus ring around its box: [strokeWidth] wide, [gap] away
/// from the box's edge (outside, or inside with [inside]). Public so tests
/// can check it.
class FocusRingPainter extends CustomPainter {
  new({required this.color, this.radius = BudgetRadii.md, this.inside = false});

  static const double gap = 2;
  static const double strokeWidth = 2;

  final Color color;
  final double radius;
  final bool inside;

  @override
  void paint(Canvas canvas, Size size) {
    final outset = (gap + strokeWidth / 2) * (inside ? -1 : 1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).inflate(outset),
        Radius.circular(radius + outset < 0 ? 0 : radius + outset),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(FocusRingPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.inside != inside;
}
