import 'package:daily_budget/core/widgets/action_dock.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/theme_cases.dart';

// The action dock of design system §7.13 (month setup §6, transactions §8.1).

Widget _dock({bool line = true, bool action = true}) => ActionDock(
  line: line
      ? const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('Budget'), Text('₹830')],
        )
      : null,
  action: action
      ? BudgetButton.primary(label: 'Start', onPressed: () {})
      : null,
);

/// Pumps [dock] as a screen's bottom bar, then opens a [keyboard] of that
/// many dp, as the engine reports it.
Future<void> _pump(
  WidgetTester tester,
  Widget dock, {
  double keyboard = 0,
  Size size = const Size(360, 640),
  double textScale = 1,
  ThemeCase theme = ThemeCase.light,
}) async {
  await pumpBudgetWidget(
    tester,
    theme: theme,
    size: size,
    textScale: textScale,
    scaffold: false,
    Scaffold(body: const SizedBox(), bottomNavigationBar: dock),
  );
  if (keyboard > 0) {
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 3);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
  }
}

void main() {
  testWidgets('TC-008-24 the dock shows the line above the button', (
    tester,
  ) async {
    await _pump(tester, _dock());

    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('₹830'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.text('Budget')).dy,
      lessThan(tester.getTopLeft(find.text('Start')).dy),
    );
    // About 124 dp tall at normal text (month-setup §6).
    final height = tester.getSize(find.byType(ActionDock)).height;
    expect(height, inInclusiveRange(116, 132));
  });

  testWidgets('TC-008-24 the dock is on the surface with a hairline on top', (
    tester,
  ) async {
    for (final theme in ThemeCase.values) {
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, _dock(), theme: theme);

      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(ActionDock),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, theme.colors.surface, reason: theme.name);
      expect(
        (decoration.border! as Border).top,
        BorderSide(color: theme.colors.border),
        reason: theme.name,
      );
      expect(decoration.boxShadow, isNull, reason: theme.name);
    }
  });

  testWidgets('TC-008-24 the dock line is not read, the button is', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _dock());

    expect(find.bySemanticsLabel('Budget'), findsNothing);
    expect(find.bySemanticsLabel('₹830'), findsNothing);
    expect(find.bySemanticsLabel('Start'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-008-24 with the keyboard open the line stays, Confirm goes', (
    tester,
  ) async {
    await _pump(tester, _dock(), keyboard: 300);

    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Start'), findsNothing);
    // 44 dp (month-setup §6): 16 above, a 20 dp line, 16 below.
    expect(tester.getSize(find.byType(ActionDock)).height, closeTo(52, 1));
  });

  testWidgets(
    'TC-009-20 with the keyboard open a button-only dock keeps Save',
    (tester) async {
      await _pump(tester, _dock(line: false), keyboard: 300);

      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Budget'), findsNothing);
    },
  );

  testWidgets('TC-008-24 the dock sits above the phone bottom inset', (
    tester,
  ) async {
    await _pump(tester, _dock(line: false));
    final plain = tester.getSize(find.byType(ActionDock)).height;

    tester.view.padding = const FakeViewPadding(bottom: 24 * 3);
    addTearDown(tester.view.resetPadding);
    await tester.pump();

    expect(tester.getSize(find.byType(ActionDock)).height - plain, 24);
  });

  testWidgets('TC-008-24 the dock fits portrait up to 1.3 times text only', (
    tester,
  ) async {
    var fits = <bool>[];
    Widget probe() => Builder(
      builder: (context) {
        fits.add(ActionDock.fits(context));
        return const SizedBox();
      },
    );

    for (final (size, scale, expected) in [
      (const Size(360, 640), 1.0, true),
      (const Size(360, 640), 1.3, true),
      (const Size(360, 640), 1.31, false),
      (const Size(360, 640), 2.0, false),
      (const Size(640, 360), 1.0, false),
      (const Size(640, 360), 2.0, false),
    ]) {
      await tester.pumpWidget(const SizedBox());
      fits = [];
      await _pump(tester, probe(), size: size, textScale: scale);
      expect(fits.last, expected, reason: '$size x$scale');
    }
  });

  testWidgets('TC-008-24 a dock without a line or a button is refused', (
    tester,
  ) async {
    expect(ActionDock.new, throwsAssertionError);
  });

  testWidgets('TC-008-24 the dock does not overflow on a narrow phone', (
    tester,
  ) async {
    await _pump(tester, _dock(), size: const Size(320, 568));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ActionDock)).width, 320);
  });
}
