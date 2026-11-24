import 'package:flutter/widgets.dart';

/// The three ledger marks (design system §5): ● saved, ○ on budget,
/// ◆ overspent. Drawn, not typed, so they are the same size in every font.
enum CalendarMark { saved, onBudget, overspent }

/// A [size] square holding one [CalendarMark] in [color].
class CalendarMarkPaint extends StatelessWidget {
  const new({
    required this.mark,
    required this.color,
    this.size = 6,
    super.key,
  });

  final CalendarMark mark;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(mark, color),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  const new(this.mark, this.color);

  final CalendarMark mark;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    final center = size.center(Offset.zero);
    final half = size.width / 2;
    switch (mark) {
      case CalendarMark.saved:
        canvas.drawCircle(center, half, paint);
      case CalendarMark.onBudget:
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(center, half - 0.75, paint);
      case CalendarMark.overspent:
        final path = Path()
          ..moveTo(center.dx, 0)
          ..lineTo(size.width, center.dy)
          ..lineTo(center.dx, size.height)
          ..lineTo(0, center.dy)
          ..close();
        canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) =>
      oldDelegate.mark != mark || oldDelegate.color != color;
}

/// The change-day tick: 12 × 3 dp, `radiusFull` (design system §7.5).
class CalendarChangeTick extends StatelessWidget {
  const new({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 12,
      height: 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(999)),
        ),
      ),
    ),
  );
}
