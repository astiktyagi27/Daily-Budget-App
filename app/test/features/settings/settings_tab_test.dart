import 'package:daily_budget/core/widgets/budget_list_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/shell.dart';
import '../../helpers/theme_cases.dart';

// Exact copy from F-003 §5, as literals. The Theme row (F-002 §5) comes first.
const _rows = [
  ('Notifications', 'Budget warnings and an end-of-day summary'),
  ('Bank account', 'The one bank account the app tracks'),
  ('Salary date', 'The day your budget month starts'),
  ('Categories', 'How your spends are grouped, like Food or Travel'),
  (
    'Privacy & data',
    'Your data stays on this phone. Manage or delete it here.',
  ),
  ('How this app works', 'A short guide to daily budgets and saving'),
  ('Disclaimer', "What the app can and can't track"),
];
const _headers = ['General', 'Money', 'Privacy & help'];

Finder _row(String label) => find.widgetWithText(BudgetListRow, label);

Future<void> _openSettings(
  WidgetTester tester, {
  ThemeCase theme = ThemeCase.light,
  Size? size = kSmallPhone,
  double textScale = 1,
  bool seedTheme = true,
}) async {
  await pumpShell(
    tester,
    theme: theme,
    size: size,
    textScale: textScale,
    seedTheme: seedTheme,
  );
  await tapTab(tester, 'Settings');
}

void main() {
  testWidgets('TC-003-06 settings lists theme then seven coming soon rows', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    // A fresh store: nothing saved for the theme.
    await _openSettings(
      tester,
      theme: ThemeCase.autoSystemLight,
      seedTheme: false,
    );

    final tops = [
      tester.getTopLeft(_row('Theme')).dy,
      for (final (label, _) in _rows) tester.getTopLeft(_row(label)).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()), reason: 'row order');
    // Theme: the current choice on a fresh store, no tag, the shared row.
    expect(_row('Theme'), findsOneWidget);
    expect(
      find.descendant(
        of: _row('Theme'),
        matching: find.text('Auto (follows your phone)'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _row('Theme'), matching: find.text('Coming soon')),
      findsNothing,
    );
    for (final (label, description) in _rows) {
      expect(_row(label), findsOneWidget, reason: label);
      expect(
        find.descendant(of: _row(label), matching: find.text(description)),
        findsOneWidget,
        reason: label,
      );
      expect(
        find.descendant(of: _row(label), matching: find.text('Coming soon')),
        findsOneWidget,
        reason: label,
      );
    }
    expect(find.text('Coming soon'), findsNWidgets(7));

    // Group headers sit between the rows and are headings.
    final headerTops = [
      for (final h in _headers) tester.getTopLeft(find.text(h)).dy,
    ];
    expect(headerTops[0], lessThan(tops[0]));
    expect(headerTops[1], allOf(greaterThan(tops[1]), lessThan(tops[2])));
    expect(headerTops[2], allOf(greaterThan(tops[4]), lessThan(tops[5])));
    for (final header in _headers) {
      expect(
        tester.getSemantics(find.text(header)),
        isSemantics(label: header, isHeader: true),
        reason: header,
      );
    }
    semantics.dispose();
  });

  testWidgets('TC-003-07 coming soon rows are inert and theme row opens '
      'picker', (tester) async {
    final semantics = tester.ensureSemantics();
    final logged = <String?>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) => logged.add(message);

    await _openSettings(tester);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));

    for (final (label, description) in _rows) {
      await tester.ensureVisible(_row(label));
      await tester.pumpAndSettle();
      final textsBefore = find.byType(Text).evaluate().length;
      await tester.tap(_row(label));
      await tester.pumpAndSettle();

      expect(navigator.canPop(), isFalse, reason: '$label: no new route');
      for (final type in [Dialog, AlertDialog, BottomSheet, SnackBar]) {
        expect(find.byType(type), findsNothing, reason: '$label: $type');
      }
      expect(find.byType(Text).evaluate().length, textsBefore, reason: label);
      expect(tester.takeException(), isNull, reason: label);

      // One disabled item with the exact F-003 §5 text (review C2).
      expect(
        tester.getSemantics(_row(label)),
        isSemantics(
          label: '$label, coming soon, not available yet. $description',
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
          isButton: false,
        ),
        reason: label,
      );
    }
    // Restored inside the test: the binding checks it before tear-down.
    debugPrint = originalDebugPrint;
    expect(logged, isEmpty, reason: 'nothing is logged');

    // The one row that works: Theme opens the picker.
    await tester.ensureVisible(_row('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: _row('Theme'),
        matching: find.byIcon(Icons.chevron_right),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Choose a theme'), findsOneWidget);
    expect(navigator.canPop(), isTrue);
    semantics.dispose();
  });

  testWidgets(
    'TC-003-12 tab scroll position is kept and retap scrolls to top',
    (tester) async {
      await _openSettings(tester, textScale: 2);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      final offset = visiblePagePosition(tester).pixels;
      expect(offset, greaterThan(0));

      await tapTab(tester, 'Home');
      await tapTab(tester, 'Settings');
      expect(visiblePagePosition(tester).pixels, closeTo(offset, 0.5));

      await tapTab(tester, 'Settings');
      expect(visiblePagePosition(tester).pixels, 0);

      // Home is not scrolled: a re-tap changes nothing.
      await tapTab(tester, 'Home');
      await tapTab(tester, 'Home');
      expect(visiblePagePosition(tester).pixels, 0);
      expect(tester.takeException(), isNull);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
      );
    },
  );

  testWidgets('TC-003-16 settings list fits and wraps at text scale 2', (
    tester,
  ) async {
    for (final theme in ThemeCase.values) {
      final where = theme.name;
      await _openSettings(tester, theme: theme, textScale: 2);
      expectNoOverflow(tester, reason: where);

      await tester.scrollUntilVisible(
        _row('Disclaimer'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
      final disclaimer = tester.getRect(_row('Disclaimer'));
      expect(
        disclaimer.bottom,
        lessThanOrEqualTo(tester.getRect(navBar).top),
        reason: '$where: Disclaimer fully visible',
      );
      expect(_row('Disclaimer').hitTestable(), findsOneWidget, reason: where);

      final longest = tester.renderObject<RenderParagraph>(
        find.text('How this app works'),
      );
      expect(longest.didExceedMaxLines, isFalse, reason: where);
      expect(longest.size.height, greaterThan(40), reason: '$where: wraps');

      for (final (label, _) in _rows) {
        final row = tester.getRect(_row(label));
        final tag = tester.getRect(
          find.descendant(of: _row(label), matching: find.text('Coming soon')),
        );
        expect(
          row.contains(tag.topLeft) && row.contains(tag.bottomRight),
          isTrue,
          reason: '$where: $label tag inside its row',
        );
      }
      expectNoOverflow(tester, reason: where);
      await expectAccessible(tester, reason: where);
    }
  });

  testWidgets('TC-003-29 shell survives text scale 3 on a small screen', (
    tester,
  ) async {
    await pumpShell(tester, size: kNarrowShortPhone, textScale: 3);
    for (final tab in ['Home', 'Dashboard', 'Transactions', 'Settings']) {
      await tapTab(tester, tab);
      expectNoOverflow(tester, reason: tab);
    }
    await tester.scrollUntilVisible(
      _row('Disclaimer'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expectNoOverflow(tester, reason: 'end of Settings');
  });
}
