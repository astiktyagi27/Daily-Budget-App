import 'package:daily_budget/features/statement/statement_text.dart';
import 'package:flutter/material.dart';

/// An amount as `formatRupees` writes it, with an optional `/day` after it.
final _amount = RegExp('(?:\u2212\u2060)?₹[0-9,]+(?:/day)?');

/// [text] as spans: the base style, with every amount in Plex 600 tabular
/// (design `month-statement.md` §3, S-3).
///
/// With [speech] the first span reads it as the whole sentence and the others
/// read nothing, so a screen reader says one sentence, not pieces.
List<InlineSpan> moneySpans(String text, TextStyle base, {String? speech}) {
  final amountStyle = base.copyWith(
    fontWeight: FontWeight.w600,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  final spans = <InlineSpan>[];
  String? label() {
    if (speech == null) return null;
    return spans.isEmpty ? speech : '';
  }

  var from = 0;
  for (final match in _amount.allMatches(text)) {
    if (match.start > from) {
      spans.add(
        TextSpan(
          text: text.substring(from, match.start),
          semanticsLabel: label(),
        ),
      );
    }
    spans.add(
      TextSpan(text: match[0], style: amountStyle, semanticsLabel: label()),
    );
    from = match.end;
  }
  if (from < text.length) {
    spans.add(TextSpan(text: text.substring(from), semanticsLabel: label()));
  }
  return spans;
}

/// True when some chunk, kept in one piece, is wider than [width]: the line
/// then wraps at spaces instead of only between chunks.
bool chunksTooWide(
  BuildContext context,
  Chunks chunks,
  TextStyle style,
  double width,
) {
  final scaler = MediaQuery.textScalerOf(context);
  for (final chunk in chunks) {
    final painter = TextPainter(
      text: TextSpan(text: joinChunks([chunk], relaxed: false), style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final wide = painter.width > width;
    painter.dispose();
    if (wide) return true;
  }
  return false;
}
