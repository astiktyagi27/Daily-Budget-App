import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// [text] as a person reads it: a non-breaking space (U+00A0) is a space and
/// the word joiner (U+2060) is not there. Money text keeps both on screen
/// (design system §4.3); screen text is compared through this (test cases
/// F-008 §0).
String plainCopy(String text) =>
    text.replaceAll('\u00A0', ' ').replaceAll('\u2060', '');

/// Finds a `Text` whose copy equals [text] once both are made plain.
Finder findCopy(String text, {bool skipOffstage = true}) {
  final wanted = plainCopy(text);
  return find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        plainCopy(widget.data ?? widget.textSpan?.toPlainText() ?? '') ==
            wanted,
    description: 'Text "$wanted" (invisible characters ignored)',
    skipOffstage: skipOffstage,
  );
}
