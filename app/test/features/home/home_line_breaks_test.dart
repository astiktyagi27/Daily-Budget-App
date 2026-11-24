import 'package:daily_budget/features/home/widgets/home_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/bundled_fonts.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../support/find_copy.dart';
import 'home_harness.dart';

// B-006: at text 2.0 on a 360 dp phone no word or amount of the savings-pot
// sub-line or the Today heading is split (home-summary.md section 10). The
// real fonts are loaded: the square test font hides this. Each case is also
// proven able to fail: with `ChunkedText` replaced by the old all-glued text
// the sub-line breaks inside `days` and the heading starts a line with `·`.

/// The text of each rendered line of the paragraph under [finder].
List<String> _lines(WidgetTester tester, Finder finder) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: finder, matching: find.byType(RichText)).first,
  );
  final text = paragraph.text.toPlainText();
  final lines = <String>[];
  var line = StringBuffer();
  double? top;
  for (var i = 0; i < text.length; i++) {
    final y = paragraph
        .getOffsetForCaret(TextPosition(offset: i), Rect.zero)
        .dy;
    if (top != null && (y - top).abs() > 2) {
      lines.add(line.toString());
      line = StringBuffer();
    }
    top = y;
    line.write(text[i]);
  }
  if (line.isNotEmpty) lines.add(line.toString());
  return lines;
}

void main() {
  setUpAll(loadBundledFonts);

  testWidgets('TC-010-60 savings pot sub-line keeps its words whole at text '
      '2.0', (tester) async {
    await openFixture(tester, a13c300, textScale: 2);
    final line = findCopy(
      '₹1,700 in your savings pot · ₹300 used to cover days',
    );
    await tester.ensureVisible(line);
    final lines = _lines(tester, line);

    expect(lines.length, greaterThan(1), reason: 'wide enough to wrap');
    for (final each in lines) {
      // Every line break is at a space: no line ends inside a word.
      expect(
        RegExp(r'[\s\u00A0]$').hasMatch(each) || each == lines.last,
        isTrue,
        reason: 'line "$each" ends inside a word',
      );
    }
    final plain = plainCopy(lines.join());
    for (final word in ['savings', 'cover', 'days', '₹1,700', '₹300']) {
      expect(
        lines.any((l) => plainCopy(l).contains(word)),
        isTrue,
        reason: '$word is on one line',
      );
    }
    expect(plain, contains('used to cover days'));
  });

  testWidgets('TC-010-60 today heading wraps after the dot and keeps the '
      'date whole', (tester) async {
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(const SizedBox());
      await openFixture(tester, a13, textScale: scale);
      final heading = findCopy('Today · Fri, 13 Nov');
      final lines = _lines(tester, heading).map(plainCopy).toList();

      expect(
        lines.where((l) => l.trimLeft().startsWith('·')),
        isEmpty,
        reason: 'x$scale: a line starts with the dot: $lines',
      );
      if (lines.length > 1) {
        expect(lines.first.trim(), 'Today ·', reason: 'x$scale: $lines');
      }
      expect(
        lines.any((l) => l.contains('Fri, 13 Nov')),
        isTrue,
        reason: 'x$scale: the date is on one line: $lines',
      );
    }
  });

  testWidgets(
    'TC-010-60 chunked text keeps a chunk whole while it fits and breaks '
    'between its words when it cannot',
    (tester) async {
      Future<List<String>> lay(double width) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: const ChunkedText(
                  style: TextStyle(fontSize: 20),
                  chunks: [
                    TextSpan(text: 'aaaa bbbb ·'),
                    TextSpan(text: 'cccc dddd'),
                  ],
                ),
              ),
            ),
          ),
        );
        return _lines(tester, find.byType(ChunkedText));
      }

      // The square test font is 20 dp wide: "aaaa bbbb ·" is 220 dp.
      expect((await lay(1000)).length, 1);
      expect((await lay(300)).map((l) => plainCopy(l).trim()), [
        'aaaa bbbb ·',
        'cccc dddd',
      ]);
      final narrow = (await lay(150)).map((l) => plainCopy(l).trim()).toList();
      expect(narrow.join(' '), 'aaaa bbbb · cccc dddd');
      expect(narrow.every((l) => !l.startsWith('·')), isTrue);
    },
  );
}
