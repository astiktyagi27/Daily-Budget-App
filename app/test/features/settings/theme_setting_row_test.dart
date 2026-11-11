import 'package:daily_budget/core/help/help_sheet.dart';
import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/features/settings/theme/theme_setting_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/shell.dart';
import '../../helpers/theme_cases.dart';

// The Settings-level steps of TC-004-02/-03/-05 on the real Theme row
// (review F4-7); the component-level steps are in
// test/core/help/help_sheet_test.dart. Literals from F-002 §5 / F-004 §5.
const _body =
    'Choose how the app looks. Auto switches between Light and Dark with your '
    "phone's setting. Dim is a softer, warm grey theme that's easy on the "
    'eyes at any time of day.';
const Map<ThemeCase, String> _rowDescription = {
  ThemeCase.light: 'Light',
  ThemeCase.dark: 'Dark',
  ThemeCase.dim: 'Dim',
  ThemeCase.autoSystemLight: 'Auto (follows your phone)',
  ThemeCase.autoSystemDark: 'Auto (follows your phone)',
};

Finder get _info =>
    find.descendant(of: themeRow, matching: find.byType(InfoButton));
Finder get _helpSheet => find.byType(HelpSheet);
Finder _inSheet(String text) =>
    find.descendant(of: _helpSheet, matching: find.text(text));

bool _canPop(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator)).canPop();

Future<void> _settings(
  WidgetTester tester, {
  ThemeCase theme = ThemeCase.light,
  Size? size,
  double textScale = 1,
}) async {
  await pumpShell(tester, theme: theme, size: size, textScale: textScale);
  await tapTab(tester, 'Settings');
}

void main() {
  testWidgets('TC-004-02 info button opens explanation without row action', (
    tester,
  ) async {
    await _settings(tester);
    await tester.tap(_info);
    await tester.pumpAndSettle();

    expect(_helpSheet, findsOneWidget);
    expect(_inSheet('Theme'), findsOneWidget);
    expect(_inSheet(_body), findsOneWidget);
    expect(_inSheet('Got it'), findsOneWidget);
    expect(find.text('Choose a theme'), findsNothing, reason: 'no picker');
    expect(themePicker, findsNothing);
  });

  testWidgets('TC-004-03 explanation closes four ways and returns focus', (
    tester,
  ) async {
    await _settings(tester, size: kSmallPhone, textScale: 2);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(_info.hitTestable(), findsOneWidget);
    final offset = visiblePagePosition(tester).pixels;
    expect(offset, greaterThan(0));
    final background = pageBackground(tester);

    final ways = <String, Future<void> Function()>{
      'got it': () => tester.tap(_inSheet('Got it')),
      'scrim': () => tester.tapAt(const Offset(10, 10)),
      'swipe down': () =>
          tester.fling(_inSheet('Theme'), const Offset(0, 500), 1500),
      'back': () async {
        await tester.binding.handlePopRoute();
      },
    };
    for (final MapEntry(key: way, value: close) in ways.entries) {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.tap(_info);
      await tester.pumpAndSettle();
      expect(_helpSheet, findsOneWidget, reason: way);
      expect(_canPop(tester), isTrue, reason: way);

      await close();
      await tester.pumpAndSettle();
      expect(_helpSheet, findsNothing, reason: way);
      expect(themePicker, findsNothing, reason: '$way: picker not open');
      expect(_canPop(tester), isFalse, reason: '$way: route count back');
      expect(pageTitle('Settings').hitTestable(), findsOneWidget, reason: way);
      expect(visiblePagePosition(tester).pixels, offset, reason: way);
      expect(pageBackground(tester), background, reason: '$way: same theme');
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<InfoButton>(),
        isNotNull,
        reason: '$way: focus back on the (i)',
      );
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
        await _settings(tester, theme: theme, textScale: scale);

        // Every (i) on Settings: in Phase 1 only the Theme (i).
        expect(find.byType(InfoButton), findsOneWidget, reason: where);
        final size = tester.getSize(_info);
        expect(size.width, greaterThanOrEqualTo(48), reason: where);
        expect(size.height, greaterThanOrEqualTo(48), reason: where);
        expect(
          find.descendant(of: _info, matching: find.byIcon(Icons.info_outline)),
          findsOneWidget,
          reason: where,
        );

        // Review C2 on the real row: the (i) is its own button node…
        final info = tester.getSemantics(_info);
        expect(
          info,
          isSemantics(
            label: 'More about Theme',
            isButton: true,
            hasTapAction: true,
          ),
          reason: where,
        );
        // …and the row reads `Theme. <choice>`, button, with its hint.
        final row = tester.getSemantics(find.byType(ThemeSettingRow));
        expect(row.id, isNot(info.id), reason: where);
        expect(
          row,
          isSemantics(
            label: 'Theme. ${_rowDescription[theme]}',
            hint: 'Opens theme options',
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
}
