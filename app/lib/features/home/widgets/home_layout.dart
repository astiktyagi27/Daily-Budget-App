import 'package:flutter/widgets.dart';

/// Above this text scale the ledger rows stack and the pinned row is not
/// built (`home-summary.md` §6, §10).
const double kLargeTextScale = 1.3;

/// The widest the Home content grows, in landscape (`home-summary.md` §10).
const double kHomeContentMaxWidth = 600;

/// Whether the phone's text size is above [kLargeTextScale].
bool isLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) > kLargeTextScale;

/// [text] with every space kept together, so a line wraps only where the
/// caller leaves a normal space (the dots between the parts of a line).
String unbreakable(String text) => text.replaceAll(' ', '\u00A0');

/// A line made of [chunks] that wraps only between chunks (`home-summary.md`
/// §10: breaks only at the designed points, never inside a word or an
/// amount). Each chunk is written with normal spaces; it is kept whole (its
/// spaces made non-breaking) while it fits on a line by itself. A chunk wider
/// than the line, as at text 2.0 on a 360 dp phone, falls back to breaking
/// between its words, so a word is still never split.
///
/// Chunks are joined by one normal space, the only designed break.
class ChunkedText extends StatelessWidget {
  const new({required this.chunks, required this.style, super.key});

  /// The unbreakable parts, each a [TextSpan] tree of plain text.
  final List<TextSpan> chunks;

  /// The base style of the whole line.
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final spans = <InlineSpan>[];
        for (final chunk in chunks) {
          if (spans.isNotEmpty) spans.add(const TextSpan(text: ' '));
          final glued = _glue(chunk);
          final painter = TextPainter(
            text: TextSpan(style: style, children: [glued]),
            textScaler: scaler,
            textDirection: direction,
          )..layout();
          final fits = painter.width <= constraints.maxWidth;
          painter.dispose();
          spans.add(fits ? glued : chunk);
        }
        return Text.rich(TextSpan(style: style, children: spans));
      },
    );
  }
}

TextSpan _glue(TextSpan span) => TextSpan(
  text: span.text == null ? null : unbreakable(span.text!),
  style: span.style,
  children: [
    for (final child in span.children ?? const <InlineSpan>[])
      if (child is TextSpan) _glue(child) else child,
  ],
);
