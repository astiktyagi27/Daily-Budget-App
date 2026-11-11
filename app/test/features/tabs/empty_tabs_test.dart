import 'dart:math' as math;

import 'package:daily_budget/core/widgets/empty_state.dart';
import 'package:daily_budget/features/shell/tab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/shell.dart';
import '../../helpers/theme_cases.dart';

// Exact copy from F-003 §5, written as literals.
const _tabs = {
  'Home': (
    'Your daily budget lives here',
    "Once you set up your month, you'll see what you can spend today, what "
        "you've spent and your calendar.",
  ),
  'Dashboard': (
    'Insights are on their way',
    "After a few days of spending, you'll see where your money goes and how "
        'many days you saved.',
  ),
  'Transactions': (
    'No transactions yet',
    "Spends from your bank SMS will show up here. You'll also be able to add "
        'them yourself.',
  ),
};

Finder get _page => find.byType(TabPage);

void main() {
  testWidgets('TC-003-05 placeholder empty states show exact copy only', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpShell(tester);
    for (final MapEntry(key: tab, value: (title, description))
        in _tabs.entries) {
      await tapTab(tester, tab);
      expect(_page, findsOneWidget, reason: tab);
      Finder inPage(Finder f) => find.descendant(of: _page, matching: f);

      expect(inPage(find.text(title)), findsOneWidget, reason: tab);
      expect(inPage(find.text(description)), findsOneWidget, reason: tab);
      expect(inPage(find.byType(EmptyState)), findsOneWidget, reason: tab);
      expect(
        inPage(
          find.descendant(
            of: find.byType(EmptyState),
            matching: find.byType(Icon),
          ),
        ),
        findsOneWidget,
        reason: '$tab has an icon',
      );

      // Title header + empty state only: no amounts, digits or controls.
      final texts = tester
          .widgetList<Text>(inPage(find.byType(Text)))
          .map((t) => t.data!)
          .toList();
      expect(texts, hasLength(3), reason: '$tab: $texts');
      for (final text in texts) {
        expect(text, isNot(contains('₹')), reason: tab);
        expect(text, isNot(contains(RegExp(r'\d'))), reason: tab);
      }
      for (final type in [
        ButtonStyleButton,
        IconButton,
        InkWell,
        GestureDetector,
      ]) {
        expect(inPage(find.byType(type)), findsNothing, reason: '$tab $type');
      }
      // The only tappable items on screen are the four tabs.
      expect(
        find.semantics.byAction(SemanticsAction.tap),
        findsNWidgets(4),
        reason: '$tab has nothing to tap',
      );

      // Read as one item, title then description.
      expect(
        find.bySemanticsLabel('$title. $description'),
        findsOneWidget,
        reason: tab,
      );
    }
    semantics.dispose();
  });

  testWidgets('TC-003-26 empty tabs are accessible in every theme', (
    tester,
  ) async {
    for (final theme in ThemeCase.values) {
      for (final scale in [1.0, 2.0]) {
        await pumpShell(
          tester,
          theme: theme,
          size: kSmallPhone,
          textScale: scale,
        );
        for (final tab in _tabs.keys) {
          final where = '$tab, ${theme.name}, $scale';
          await tapTab(tester, tab);
          await expectAccessible(tester, reason: where);
          // The end of the description can be scrolled to (it may be
          // taller than the screen at 2.0).
          final description = find.text(_tabs[tab]!.$2);
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -3000),
          );
          await tester.pumpAndSettle();
          final rect = tester.getRect(description);
          final bar = tester.getRect(navBar);
          expect(rect.bottom, lessThanOrEqualTo(bar.top), reason: where);
        }
      }
    }
  });

  testWidgets('TC-003-31 empty states are left aligned on the page gutter', (
    tester,
  ) async {
    const titles = {
      'Home': 'Daily Budget App',
      'Dashboard': 'Dashboard',
      'Transactions': 'Transactions',
    };
    const gutter = 20.0; // space5
    await pumpShell(tester, size: kSmallPhone);
    for (final MapEntry(key: tab, value: (title, description))
        in _tabs.entries) {
      await tapTab(tester, tab);
      Finder inEmptyState(Finder f) =>
          find.descendant(of: find.byType(EmptyState), matching: f);

      // Where the glyphs really start, not the paragraph box: a centred
      // line in a full-width box would still have its box on the gutter.
      double textLeft(Finder text) {
        final paragraph = tester.renderObject<RenderParagraph>(text);
        final length = paragraph.text.toPlainText().length;
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: length),
        );
        final left = boxes.map((b) => b.left).reduce(math.min);
        return paragraph.localToGlobal(Offset(left, 0)).dx;
      }

      final circle = find
          .ancestor(
            of: inEmptyState(find.byType(Icon)),
            matching: find.byType(Container),
          )
          .first;
      expect(tester.getSize(circle), const Size(88, 88), reason: tab);
      final lefts = {
        'page title': textLeft(pageTitle(titles[tab]!)),
        'icon circle': tester.getTopLeft(circle).dx,
        'title': textLeft(inEmptyState(find.text(title))),
        'description': textLeft(inEmptyState(find.text(description))),
      };
      for (final MapEntry(key: part, value: left) in lefts.entries) {
        expect(left, closeTo(gutter, 0.5), reason: '$tab: $part');
      }
      // Not centred: the circle's centre is well left of the screen's.
      expect(
        tester.getCenter(circle).dx,
        lessThan(kSmallPhone.width / 2 - 50),
        reason: tab,
      );
    }
  });
}
