import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/core/widgets/budget_list_row.dart';
import 'package:daily_budget/core/widgets/focus_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/theme_cases.dart';

// Design system §7.1: focus = 2 dp `focus` ring, offset 2 dp (review N4).

final Finder _ring = find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter is FocusRingPainter,
);

FocusRingPainter _painter(WidgetTester tester) =>
    tester.widget<CustomPaint>(_ring).painter! as FocusRingPainter;

/// The focus node of the control that holds [inside].
FocusNode _nodeOf(WidgetTester tester, Finder inside) =>
    Focus.of(tester.element(inside));

Finder get _infoIcon => find.byIcon(Icons.info_outline);
Finder get _rowIcon => find.byIcon(Icons.contrast);
Finder get _infoRow => find.widgetWithText(BudgetListRow, 'Theme');

Future<void> _pump(WidgetTester tester, ThemeCase theme) => pumpBudgetWidget(
  tester,
  theme: theme,
  ListView(
    children: [
      BudgetListRow(
        label: 'Theme',
        description: 'Auto (follows your phone)',
        leadingIcon: Icons.contrast,
        trailing: const BudgetRowChevron(),
        onTap: () {},
        info: (title: 'Theme', body: 'Choose how the app looks.'),
      ),
      BudgetListRow(label: 'Plain row', onTap: () {}),
    ],
  ),
);

/// A key press puts Flutter in keyboard (traditional) highlight mode.
Future<void> _useKeyboard(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
  expect(FocusManager.instance.highlightMode, FocusHighlightMode.traditional);
}

/// A touch puts it back in touch mode, on an empty spot below the rows.
Future<void> _useTouch(WidgetTester tester) async {
  await tester.tapAt(
    tester.getBottomLeft(find.byType(ListView)) + const Offset(4, -4),
  );
  await tester.pump();
  expect(FocusManager.instance.highlightMode, FocusHighlightMode.touch);
}

void main() {
  testWidgets('TC-004-05 info button shows the focus ring when keyboard '
      'focused', (tester) async {
    for (final theme in ThemeCase.values) {
      final where = theme.name;
      await _pump(tester, theme);
      await _useKeyboard(tester);

      _nodeOf(tester, _infoIcon).requestFocus();
      await tester.pump();
      expect(_ring, findsOneWidget, reason: '$where: one ring, on the (i)');
      expect(
        find.descendant(of: find.byType(InfoButton), matching: _ring),
        findsOneWidget,
        reason: '$where: the row around it shows no ring',
      );
      final painter = _painter(tester);
      expect(painter.color, theme.colors.focus, reason: where);
      expect(painter.inside, isFalse, reason: '$where: 2 dp outside');
      expect(painter.radius, 24, reason: '$where: round, around the target');
      expect(FocusRingPainter.strokeWidth, 2);
      expect(FocusRingPainter.gap, 2);
      expect(tester.getSize(_ring), const Size.square(48), reason: where);

      // Touch: focus stays, the ring goes.
      await _useTouch(tester);
      expect(_nodeOf(tester, _infoIcon).hasPrimaryFocus, isTrue);
      expect(_ring, findsNothing, reason: '$where: no ring for touch');
    }
  });

  testWidgets('TC-002-19 list row shows the focus ring when keyboard '
      'focused', (tester) async {
    for (final theme in ThemeCase.values) {
      final where = theme.name;
      await _pump(tester, theme);

      // Touch mode: a focused row shows nothing.
      _nodeOf(tester, _rowIcon).requestFocus();
      await tester.pump();
      expect(_ring, findsNothing, reason: '$where: touch mode');

      await _useKeyboard(tester);
      _nodeOf(tester, _rowIcon).requestFocus();
      await tester.pump();
      expect(_ring, findsOneWidget, reason: where);
      expect(
        find.descendant(of: _infoRow, matching: _ring),
        findsOneWidget,
        reason: where,
      );
      expect(
        find.descendant(of: find.byType(InfoButton), matching: _ring),
        findsNothing,
        reason: '$where: the (i) is not focused',
      );
      final painter = _painter(tester);
      expect(painter.color, theme.colors.focus, reason: where);
      expect(painter.inside, isTrue, reason: '$where: inside the card');
      expect(tester.getRect(_ring), tester.getRect(_infoRow), reason: where);

      // Keyboard traversal moves the ring from row to row.
      _nodeOf(
        tester,
        find.descendant(
          of: find.widgetWithText(BudgetListRow, 'Plain row'),
          matching: find.text('Plain row'),
        ),
      ).requestFocus();
      await tester.pump();
      expect(_ring, findsOneWidget, reason: where);
      expect(
        find.descendant(
          of: find.widgetWithText(BudgetListRow, 'Plain row'),
          matching: _ring,
        ),
        findsOneWidget,
        reason: where,
      );

      await _useTouch(tester);
      expect(_ring, findsNothing, reason: '$where: no ring for touch');
    }
  });
}
