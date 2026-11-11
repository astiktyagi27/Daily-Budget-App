import 'package:daily_budget/core/help/help_sheet.dart';
import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/core/theme/budget_colors.dart';
import 'package:daily_budget/core/widgets/budget_list_row.dart';
import 'package:daily_budget/core/widgets/budget_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/bundled_fonts.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/theme_cases.dart';

// Literals from F-002 §5 / F-004 §5 (never the app's own constants).
const _label = 'Theme';
const _description = 'Auto (follows your phone)';
const _body =
    'Choose how the app looks. Auto switches between Light and Dark with your '
    "phone's setting. Dim is a softer, warm grey theme that's easy on the "
    'eyes at any time of day.';

// Design system §5.3: Light sheet shadow 0 −8 32, #1C1B22 at 12 %.
const _lightSheetShadow = [
  BoxShadow(color: Color(0x1F1C1B22), offset: Offset(0, -8), blurRadius: 32),
];

/// Counts the routes on the navigator (test cases F-003 §0 "Route count").
class _Routes extends NavigatorObserver {
  int count = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => count++;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => count--;
}

/// A scrollable list whose first row has an (i) and its own tap action.
class _Host {
  final routes = _Routes();
  final scroll = ScrollController();
  int rowTaps = 0;

  Future<void> pump(
    WidgetTester tester, {
    ThemeCase theme = ThemeCase.light,
    Size? size,
    double textScale = 1,
    bool disableAnimations = false,
  }) async {
    addTearDown(scroll.dispose);
    await pumpBudgetWidget(
      tester,
      theme: theme,
      size: size,
      textScale: textScale,
      disableAnimations: disableAnimations,
      navigatorObservers: [routes],
      ListView(
        controller: scroll,
        children: [
          const SizedBox(height: 120),
          BudgetListRow(
            label: _label,
            description: _description,
            leadingIcon: Icons.contrast,
            trailing: const BudgetRowChevron(),
            onTap: () => rowTaps++,
            info: (title: _label, body: _body),
          ),
          for (var i = 0; i < 20; i++)
            BudgetListRow(label: 'Filler $i', onTap: () {}),
        ],
      ),
    );
  }
}

Finder get _sheet => find.byType(HelpSheet);
Finder _inSheet(String text) =>
    find.descendant(of: _sheet, matching: find.text(text));

Future<void> _openInfo(WidgetTester tester) async {
  await tester.tap(find.byType(InfoButton));
  await tester.pumpAndSettle();
}

BoxDecoration _frameDecoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(BudgetSheetFrame),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

/// Keyboard focus is on the (i) (proxy for TalkBack focus, TC-004-03).
bool _focusOnInfo() =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<InfoButton>() !=
    null;

void main() {
  testWidgets('TC-004-02 info button opens explanation without row action', (
    tester,
  ) async {
    final host = _Host();
    await host.pump(tester);
    await _openInfo(tester);

    expect(_sheet, findsOneWidget);
    expect(_inSheet(_label), findsOneWidget);
    expect(_inSheet(_body), findsOneWidget);
    expect(_inSheet('Got it'), findsOneWidget);
    expect(host.rowTaps, 0, reason: 'the row action must not run');

    await tester.tap(_inSheet('Got it'));
    await tester.pumpAndSettle();
    // The rest of the row still runs its own action.
    await tester.tap(find.text(_description));
    expect(host.rowTaps, 1);
  });

  testWidgets('TC-004-03 explanation closes four ways and returns focus', (
    tester,
  ) async {
    final host = _Host();
    await host.pump(tester, size: kSmallPhone, textScale: 2);
    host.scroll.jumpTo(100);
    await tester.pumpAndSettle();
    final routesBefore = host.routes.count;

    final ways = <String, Future<void> Function()>{
      'got it': () => tester.tap(_inSheet('Got it')),
      'scrim': () => tester.tapAt(const Offset(10, 10)),
      'swipe down': () =>
          tester.fling(_inSheet(_label), const Offset(0, 500), 1500),
      'back': () async {
        await tester.binding.handlePopRoute();
      },
    };
    for (final MapEntry(key: way, value: close) in ways.entries) {
      FocusManager.instance.primaryFocus?.unfocus();
      await _openInfo(tester);
      expect(_sheet, findsOneWidget, reason: way);
      expect(host.routes.count, routesBefore + 1, reason: way);

      await close();
      await tester.pumpAndSettle();
      expect(_sheet, findsNothing, reason: way);
      expect(host.routes.count, routesBefore, reason: way);
      expect(host.scroll.offset, 100, reason: '$way: screen unchanged');
      expect(host.rowTaps, 0, reason: way);
      expect(_focusOnInfo(), isTrue, reason: '$way: focus back on the (i)');
      expect(tester.takeException(), isNull, reason: way);
    }
  });

  testWidgets('TC-004-05 info buttons are 48 dp with more about label', (
    tester,
  ) async {
    for (final theme in ThemeCase.values) {
      for (final scale in [1.0, 2.0]) {
        final where = '${theme.name} at $scale';
        final semantics = tester.ensureSemantics();
        await _Host().pump(tester, theme: theme, textScale: scale);

        final size = tester.getSize(find.byType(InfoButton));
        expect(size.width, greaterThanOrEqualTo(48), reason: where);
        expect(size.height, greaterThanOrEqualTo(48), reason: where);
        expect(find.byIcon(Icons.info_outline), findsOneWidget, reason: where);

        // The (i) sits 4 dp after the label's last word.
        final labelRight = tester.getRect(find.text(_label)).right;
        final icon = tester.getRect(find.byIcon(Icons.info_outline));
        final iconInk = icon.center.dx - 9;
        expect(iconInk - labelRight, closeTo(4, 1.5), reason: where);

        // Its own node, a button with the "More about" label (review C2)…
        final info = tester.getSemantics(find.byType(InfoButton));
        expect(
          info,
          isSemantics(
            label: 'More about Theme',
            isButton: true,
            hasTapAction: true,
          ),
          reason: where,
        );
        // …separate from the row, which keeps its own label and action.
        final row = tester.getSemantics(
          find.widgetWithText(BudgetListRow, _label),
        );
        expect(row.id, isNot(info.id), reason: where);
        expect(
          row,
          isSemantics(
            label: 'Theme. Auto (follows your phone)',
            isButton: true,
            hasTapAction: true,
          ),
          reason: where,
        );
        expect(row.label, isNot(contains('More about')), reason: where);
        semantics.dispose();
      }
    }
  });

  testWidgets('TC-004-05 info button follows the last word with bold text on', (
    tester,
  ) async {
    // Real glyph widths: in the square test font every weight is as wide,
    // so the Bold text setting would change nothing (review M1).
    await tester.runAsync(loadBundledFonts);
    const label = 'How this app works';
    for (final bold in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        final where = 'bold $bold at $scale';
        await pumpBudgetWidget(
          tester,
          textScale: scale,
          boldText: bold,
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 240,
              child: BudgetListRow(
                label: label,
                description: _description,
                onTap: () {},
                info: (title: label, body: _body),
              ),
            ),
          ),
        );

        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(label),
        );
        final boxes = paragraph.getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: label.length),
        );
        final lastLine = boxes.reduce((a, b) => b.bottom > a.bottom ? b : a);
        final lastRight = boxes
            .where((box) => box.bottom == lastLine.bottom)
            .map((box) => box.right)
            .reduce((a, b) => a > b ? a : b);
        final lineEnd = paragraph.localToGlobal(Offset(lastRight, 0)).dx;
        final lineTop = paragraph.localToGlobal(Offset(0, lastLine.top)).dy;
        final lineBottom = paragraph
            .localToGlobal(Offset(0, lastLine.bottom))
            .dy;

        final icon = tester.getRect(find.byIcon(Icons.info_outline));
        expect(icon.left - lineEnd, closeTo(4, 1.5), reason: where);
        expect(icon.center.dy, inInclusiveRange(lineTop, lineBottom));
        if (scale == 2) {
          expect(
            boxes.map((box) => box.bottom).toSet().length,
            greaterThan(1),
            reason: '$where: the label must wrap for this check',
          );
        }
        expectNoOverflow(tester, reason: where);
      }
    }
  });

  testWidgets('TC-004-16 explanation and hints fit at text scale 2', (
    tester,
  ) async {
    for (final theme in ThemeCase.values) {
      final where = theme.name;
      await _Host().pump(tester, theme: theme, size: kSmallPhone, textScale: 2);
      await _openInfo(tester);
      expectNoOverflow(tester, reason: where);

      // At most 90 % of the screen; the body scrolls to its last line.
      final sheetRect = tester.getRect(find.byType(BudgetSheetFrame));
      expect(sheetRect.height, lessThanOrEqualTo(640 * 0.9 + 0.5));
      final scroller = find.descendant(
        of: _sheet,
        matching: find.byType(SingleChildScrollView),
      );
      await tester.drag(scroller, const Offset(0, -2000));
      await tester.pumpAndSettle();
      final body = tester.getRect(_inSheet(_body));
      final viewport = tester.getRect(scroller);
      expect(body.bottom, lessThanOrEqualTo(viewport.bottom + 0.5));
      expect(_inSheet('Got it').hitTestable(), findsOneWidget, reason: where);
      expectNoOverflow(tester, reason: where);

      // Review C1: the sheet shadow in Light only, none in Dark or Dim.
      final light = theme.colors == BudgetColors.light;
      expect(
        _frameDecoration(tester).boxShadow ?? const <BoxShadow>[],
        light ? _lightSheetShadow : isEmpty,
        reason: where,
      );
      expect(
        _frameDecoration(tester).color,
        theme.colors.surface,
        reason: where,
      );

      await tester.tap(_inSheet('Got it'));
      await tester.pumpAndSettle();
      await expectAccessible(tester, reason: '$where, after closing');
    }
  });

  testWidgets('TC-004-17 double tap on info opens one explanation', (
    tester,
  ) async {
    final host = _Host();
    await host.pump(tester);
    final before = host.routes.count;

    await tester.tap(find.byType(InfoButton));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(InfoButton), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(_sheet, findsOneWidget);
    expect(_inSheet(_label), findsOneWidget);
    expect(host.routes.count, before + 1);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_sheet, findsNothing);
    expect(host.routes.count, before);
    expect(find.byType(InfoButton), findsOneWidget);
  });

  testWidgets(
    'TC-004-17 double tap with remove animations opens one explanation',
    (tester) async {
      // With Remove animations the sheet is fully open in the frame it is
      // pushed, so only the time guard stops the second tap (review M2).
      final host = _Host();
      await host.pump(tester, disableAnimations: true);
      final before = host.routes.count;

      await tester.tap(find.byType(InfoButton));
      await tester.pump(const Duration(milliseconds: 50));
      // The second tap lands where the (i) was: now on the scrim.
      await tester.tap(find.byType(InfoButton), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(_sheet, findsOneWidget);
      expect(_inSheet(_label), findsOneWidget);
      expect(host.routes.count, before + 1);

      // The guard is only a double-tap long: the scrim works after it.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(_sheet, findsNothing);
      expect(host.routes.count, before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('TC-004-19 explanation re-themes while open', (tester) async {
    await _Host().pump(tester, theme: ThemeCase.autoSystemLight);
    await _openInfo(tester);
    expect(_frameDecoration(tester).color, BudgetColors.light.surface);
    expect(_frameDecoration(tester).boxShadow, _lightSheetShadow);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(_sheet, findsOneWidget);
    expect(_frameDecoration(tester).color, BudgetColors.dark.surface);
    expect(_frameDecoration(tester).boxShadow ?? const [], isEmpty);
    final body = tester.renderObject<RenderParagraph>(_inSheet(_body));
    expect(body.text.style!.color, BudgetColors.dark.textPrimary);
  });

  testWidgets('TC-004-20 explanation survives background and rotation', (
    tester,
  ) async {
    await _Host().pump(tester, size: kSmallPhone);
    await _openInfo(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(_sheet.evaluate().length, lessThanOrEqualTo(1));
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = kSmallLandscape * 3;
    await tester.pumpAndSettle();
    expect(_sheet.evaluate().length, lessThanOrEqualTo(1));
    expectNoOverflow(tester, reason: 'landscape');

    tester.view.physicalSize = kSmallPhone * 3;
    await tester.pumpAndSettle();
    expect(_sheet.evaluate().length, lessThanOrEqualTo(1));
    expectNoOverflow(tester, reason: 'back to portrait');
  });
}
