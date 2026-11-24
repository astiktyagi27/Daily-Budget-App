import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/bundled_fonts.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../support/find_copy.dart';
import 'home_harness.dart';

// The Home day line at 2.0x text (F-010 T-302, review Gate 3). A separate
// file because the real fonts are loaded: with the square test font the
// widths are not those of the phone.

final CalendarDate _nov5 = d(2026, 11, 5);

void main() {
  setUpAll(loadBundledFonts);

  testWidgets('TC-010-41 day line breaks only at the dot at 2.0x', (
    tester,
  ) async {
    final huge = customFixture(
      name: 'ten crore',
      today: _nov5,
      values: const FullMonthValues(salary: Paise(10000000000)),
    );
    for (final (fixture, first, second) in [
      (a13, '₹830/day ·', '5 Nov – 4 Dec'),
      (huge, '₹33,33,333/day ·', '5 Nov – 4 Dec'),
    ]) {
      await tester.pumpWidget(const SizedBox());
      await openFixture(tester, fixture, textScale: 2);
      final line = find.descendant(
        of: findCopy('$first $second'),
        matching: find.byType(RichText),
      );
      final paragraph = tester.renderObject<RenderParagraph>(line.first);
      final text = plainCopy(paragraph.text.toPlainText());
      final tops = [
        for (var i = 0; i < text.length; i++)
          paragraph
              .getBoxesForSelection(
                TextSelection(baseOffset: i, extentOffset: i + 1),
              )
              .first
              .top,
      ];
      final end = tops.indexWhere((top) => top > tops.first);
      expect(tops.toSet(), hasLength(2), reason: '$first: two lines');
      expect(text.substring(0, end).trim(), first);
      expect(text.substring(end).trim(), second);
    }
  });
}
