import 'package:daily_budget/core/help/label_description.dart';
import 'package:daily_budget/core/help/nav_tooltip.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/theme_cases.dart';

// Literals from F-004 TC-004-01 / F-003 §5, never the app's own constants.
const _label = 'Notifications';
const _description = 'Budget warnings and an end-of-day summary';

const _long =
    'This description is deliberately long so that it needs several lines '
    'on a small phone. It explains a setting in plain words, the way later '
    'phases will explain money terms, and it must wrap onto as many lines as '
    'it needs instead of being cut off with an ellipsis at the end.';

TextStyle _styleOf(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style!;

void main() {
  testWidgets('TC-004-01 label and description render and read as one item', (
    tester,
  ) async {
    for (final theme in ThemeCase.values) {
      final where = theme.name;
      final semantics = tester.ensureSemantics();
      await pumpBudgetWidget(
        tester,
        theme: theme,
        const LabelDescription(label: _label, description: _description),
      );

      final label = _styleOf(tester, _label);
      expect(label.fontFamily, 'Plex', reason: where);
      expect(label.fontSize, 14, reason: where);
      expect(label.fontWeight, FontWeight.w500, reason: where);
      expect(label.color, theme.colors.textPrimary, reason: where);
      final description = _styleOf(tester, _description);
      expect(description.fontSize, 14, reason: where);
      expect(description.fontWeight, FontWeight.w400, reason: where);
      expect(description.color, theme.colors.textSecondary, reason: where);

      // One node with "<label>. <description>"; the texts are not read again.
      final node = tester.getSemantics(find.byType(LabelDescription));
      expect(node.label, '$_label. $_description', reason: where);
      expect(node.childrenCount, 0, reason: where);
      expect(find.bySemanticsLabel(_label), findsNothing, reason: where);
      expect(find.bySemanticsLabel(_description), findsNothing, reason: where);
      semantics.dispose();
    }

    // A long description wraps on a small phone at 1.0 and 2.0, never "…".
    for (final scale in [1.0, 2.0]) {
      await pumpBudgetWidget(
        tester,
        size: kSmallPhone,
        textScale: scale,
        const SingleChildScrollView(
          child: LabelDescription(label: _label, description: _long),
        ),
      );
      final paragraph = tester.renderObject<RenderParagraph>(find.text(_long));
      expect(paragraph.didExceedMaxLines, isFalse, reason: 'scale $scale');
      expect(
        paragraph.size.height,
        greaterThan(3 * 20 * scale),
        reason: 'wraps onto 4+ lines at $scale',
      );
      expectNoOverflow(tester, reason: 'scale $scale');
    }
  });

  testWidgets('TC-004-06 nav tooltip gives a long-press tooltip and a hint', (
    tester,
  ) async {
    var pressed = 0;
    final semantics = tester.ensureSemantics();
    await pumpBudgetWidget(
      tester,
      NavTooltip(
        message: 'Go to the next slide',
        child: BudgetButton.text(label: 'Next', onPressed: () => pressed++),
      ),
    );

    // Label and hint are one node with the control's tap action.
    expect(
      tester.getSemantics(find.byType(BudgetButton)),
      matchesSemantics(
        label: 'Next',
        hint: 'Go to the next slide',
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );

    await tester.longPress(find.text('Next'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Go to the next slide'), findsOneWidget);
    expect(pressed, 0, reason: 'a long-press does not press the button');

    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Go to the next slide'), findsNothing);
    semantics.dispose();
  });
}
