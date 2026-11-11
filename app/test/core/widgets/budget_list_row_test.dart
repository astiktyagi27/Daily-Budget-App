import 'package:daily_budget/core/widgets/budget_list_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/theme_cases.dart';

// settings.md §7: the tag moves below the text when the text column beside
// it would be narrower than 160 dp. Review N2: the tag is measured, not
// estimated at 120 dp.

const _tag = 'Coming soon';
const _label = 'Notifications';

// Row padding 20 + 20, leading icon 40 + gap 16, gap before the tag 12.
const double _fixed = 20 + 20 + 40 + 16 + 12;

Finder get _tagBox => find.byType(BudgetTag);

Future<void> _pumpRow(
  WidgetTester tester, {
  required double width,
  double textScale = 2,
  bool boldText = false,
  ThemeCase theme = ThemeCase.light,
}) => pumpBudgetWidget(
  tester,
  theme: theme,
  size: Size(width, 640),
  textScale: textScale,
  boldText: boldText,
  ListView(
    children: const [
      BudgetListRow(
        label: _label,
        description: 'Budget warnings and an end-of-day summary',
        leadingIcon: Icons.notifications_none,
        tag: _tag,
        enabled: false,
      ),
    ],
  ),
);

/// The tag sits below the label instead of beside it.
bool _tagBelow(WidgetTester tester) =>
    tester.getTopLeft(_tagBox).dy >= tester.getBottomLeft(find.text(_label)).dy;

void main() {
  testWidgets('TC-003-16 coming soon tag reflows from its measured width at '
      'text scale 2', (tester) async {
    // The measurement matches the tag as drawn, also with bold text.
    for (final (scale, bold) in [(1.0, false), (2.0, false), (2.0, true)]) {
      await _pumpRow(tester, width: 600, textScale: scale, boldText: bold);
      final measured = BudgetTag.widthOf(tester.element(_tagBox), _tag);
      expect(
        measured,
        moreOrLessEquals(tester.getSize(_tagBox).width, epsilon: 1),
        reason: 'scale $scale, bold $bold',
      );
    }

    // At 2.0 the tag is wider than the old 120 dp guess (12 dp gap + tag).
    await _pumpRow(tester, width: 600);
    final tagWidth = tester.getSize(_tagBox).width;
    expect(12 + tagWidth, greaterThan(120));

    var oldRuleWrong = 0;
    for (var width = 320.0; width <= 520; width += 8) {
      for (final theme in [ThemeCase.light, ThemeCase.dim]) {
        final where = '${theme.name} at $width dp';
        await _pumpRow(tester, width: width, theme: theme);
        expect(tester.takeException(), isNull, reason: where);
        final textColumn = width - _fixed - tagWidth;
        final expectBelow = textColumn < 160;
        expect(_tagBelow(tester), expectBelow, reason: where);
        // Never clipped: the tag stays inside its row.
        final row = tester.getRect(find.byType(BudgetListRow));
        final tag = tester.getRect(_tagBox);
        expect(row.contains(tag.topLeft), isTrue, reason: where);
        expect(row.contains(tag.bottomRight - const Offset(1, 1)), isTrue);
        if (!expectBelow) {
          // Beside the tag, the label column really is 160 dp or more.
          final column = tester.getRect(find.text(_label));
          expect(tag.left - 12 - column.left, greaterThanOrEqualTo(160));
        }
        final oldBelow = width - (_fixed - 12) - 120 < 160;
        if (oldBelow != expectBelow) oldRuleWrong++;
      }
    }
    // The sweep covers widths where the 120 dp guess got it wrong.
    expect(oldRuleWrong, greaterThan(0));
  });
}
