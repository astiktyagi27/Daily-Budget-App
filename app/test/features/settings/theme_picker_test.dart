import 'package:daily_budget/core/theme/budget_colors.dart';
import 'package:daily_budget/core/widgets/budget_sheet.dart';
import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/domain/preferences/theme_choice.dart';
import 'package:daily_budget/features/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/shell.dart';
import '../../helpers/theme_cases.dart';

// Literals from F-002 §5 and design-system.md §2 / §5.3 (never the app's own
// constants).
const _options = [
  ('Auto', "Matches your phone's light or dark setting"),
  ('Light', 'Bright and clean'),
  ('Dark', 'True dark, best at night'),
  ('Dim', 'Soft warm grey, easy on the eyes'),
];
const _rowDescriptions = {
  'Auto': 'Auto (follows your phone)',
  'Light': 'Light',
  'Dark': 'Dark',
  'Dim': 'Dim',
};
const _key = 'theme.choice';
const _darkBg = 0xFF0E0E12;
const _dimBg = 0xFF2A2825;
const _lightSheetShadow = [
  BoxShadow(color: Color(0x1F1C1B22), offset: Offset(0, -8), blurRadius: 32),
];

/// Which theme case shows each option's tokens (under system light).
const Map<String, ThemeCase> _caseFor = {
  'Auto': ThemeCase.autoSystemLight,
  'Light': ThemeCase.light,
  'Dark': ThemeCase.dark,
  'Dim': ThemeCase.dim,
};

/// Opens Settings on a fresh store or in [theme], then the picker.
Future<InMemoryPreferencesStore> _openPicker(
  WidgetTester tester, {
  ThemeCase? theme,
  Size? size,
  double textScale = 1,
}) async {
  final store = InMemoryPreferencesStore();
  await pumpBudgetApp(
    tester,
    store: store,
    theme: theme ?? ThemeCase.autoSystemLight,
    seedTheme: theme != null,
    size: size,
    textScale: textScale,
  );
  await tapTab(tester, 'Settings');
  await openThemePicker(tester);
  return store;
}

/// The option's merged semantics node (label, description, radio state).
SemanticsNode _optionNode(WidgetTester tester, String label) =>
    tester.getSemantics(pickerOption(label));

void _expectSelected(WidgetTester tester, String selected, String where) {
  for (final (label, description) in _options) {
    expect(
      _optionNode(tester, label),
      isSemantics(
        label: '$label. $description',
        hasCheckedState: true,
        isChecked: label == selected,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
      reason: '$where: $label',
    );
  }
}

String _rowDescription(WidgetTester tester) {
  for (final description in _rowDescriptions.values.toSet()) {
    final found = find.descendant(
      of: themeRow,
      matching: find.text(description),
    );
    if (found.evaluate().isNotEmpty) return description;
  }
  return '';
}

void main() {
  testWidgets('TC-002-01 theme picker lists four options in order', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _openPicker(tester);

    expect(
      find.descendant(of: themePicker, matching: find.text('Choose a theme')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: themePicker,
        matching: find.byType(Radio<ThemeChoice>),
      ),
      findsNWidgets(4),
    );
    final tops = <double>[];
    for (final (label, description) in _options) {
      expect(pickerOption(label), findsOneWidget, reason: label);
      expect(
        find.descendant(of: themePicker, matching: find.text(description)),
        findsOneWidget,
        reason: label,
      );
      tops.add(tester.getTopLeft(pickerOption(label)).dy);
    }
    expect(tops, orderedEquals([...tops]..sort()), reason: 'option order');

    // Exactly one option selected: Auto, by semantics…
    _expectSelected(tester, 'Auto', 'fresh install');
    // …and by shape and weight, not only by colour: one check icon, on the
    // Auto row, and a heavier label.
    final checks = find.descendant(
      of: themePicker,
      matching: find.byIcon(Icons.check),
    );
    expect(checks, findsOneWidget);
    final autoRow = tester.getRect(pickerOption('Auto'));
    expect(
      tester.getCenter(checks).dy,
      closeTo(autoRow.center.dy, 24),
      reason: 'the check sits on the Auto row',
    );
    FontWeight weight(String label) => tester
        .renderObject<RenderParagraph>(pickerOption(label))
        .text
        .style!
        .fontWeight!;
    expect(weight('Auto'), FontWeight.w600);
    for (final label in ['Light', 'Dark', 'Dim']) {
      expect(weight(label), FontWeight.w500, reason: label);
    }
    semantics.dispose();
  });

  testWidgets('TC-002-07 picking a theme applies it at once', (tester) async {
    for (final (from, _) in _options) {
      for (final (to, _) in _options) {
        if (from == to) continue;
        final where = '$from to $to';
        await tester.pumpWidget(const SizedBox());
        await _openPicker(tester, theme: _caseFor[from]);
        final shell = tester.state(find.byType(AppShell));
        final offset = visiblePagePosition(tester).pixels;

        await pickTheme(tester, to);
        final expected = _caseFor[to]!.colors;
        expect(themePicker, findsOneWidget, reason: '$where: stays open');
        expect(pageBackground(tester), expected.bg.toARGB32(), reason: where);
        expect(navBarFill(tester), expected.surface, reason: where);
        expect(_rowDescription(tester), _rowDescriptions[to], reason: where);
        final label = tester.renderObject<RenderParagraph>(
          find.descendant(of: themeRow, matching: find.text('Theme')),
        );
        expect(label.text.style!.color, expected.textPrimary, reason: where);

        await closeThemePicker(tester);
        expect(themePicker, findsNothing, reason: where);
        expect(pageBackground(tester), expected.bg.toARGB32(), reason: where);
        expect(selectedTab(tester), 'Settings', reason: where);
        expect(visiblePagePosition(tester).pixels, offset, reason: where);
        expect(
          tester.state(find.byType(AppShell)),
          same(shell),
          reason: '$where: no restart',
        );
        expect(tester.takeException(), isNull, reason: where);
      }
    }
  });

  testWidgets('TC-002-08 theme change is announced', (tester) async {
    await _openPicker(tester, theme: ThemeCase.light);
    tester.takeAnnouncements();

    for (final name in ['Dim', 'Light', 'Dark', 'Auto']) {
      await pickTheme(tester, name);
      final announcements = tester.takeAnnouncements();
      expect(announcements, hasLength(1), reason: name);
      expect(
        announcements.single,
        isAccessibilityAnnouncement('Theme changed to $name'),
        reason: name,
      );
    }
    // Tapping the option that is already selected changes nothing.
    await pickTheme(tester, 'Auto');
    expect(tester.takeAnnouncements(), isEmpty);
  });

  testWidgets('TC-002-09 fresh install defaults to auto', (tester) async {
    final semantics = tester.ensureSemantics();
    final store = InMemoryPreferencesStore();
    await pumpBudgetApp(tester, store: store, seedTheme: false);
    await tapTab(tester, 'Settings');

    expect(_rowDescription(tester), 'Auto (follows your phone)');
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );
    await openThemePicker(tester);
    _expectSelected(tester, 'Auto', 'fresh install');
    expect(store.values[_key], isNull, reason: 'opening saves nothing');
    semantics.dispose();
  });

  testWidgets('TC-002-33 rapid theme taps keep the last choice', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final store = await _openPicker(tester);

    await tester.tap(pickerOption('Light'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(pickerOption('Dark'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(pickerOption('Dim'));
    await tester.pumpAndSettle();
    expect(pageBackground(tester), _dimBg);
    expect(store.values[_key], 'dim');
    _expectSelected(tester, 'Dim', 'after the taps');
    expect(tester.takeException(), isNull);

    await restartApp(tester, InMemoryPreferencesStore(store.values));
    expect(pageBackground(tester), _dimBg, reason: 'first frame after restart');
    await tester.pumpAndSettle();
    await tapTab(tester, 'Settings');
    await openThemePicker(tester);
    _expectSelected(tester, 'Dim', 'after restart');
    semantics.dispose();
  });

  testWidgets('TC-002-34 double tap on theme row opens one picker', (
    tester,
  ) async {
    await pumpBudgetApp(tester);
    await tapTab(tester, 'Settings');
    final chevron = find.descendant(
      of: themeRow,
      matching: find.byIcon(Icons.chevron_right),
    );

    await tester.tap(chevron);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(chevron, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Choose a theme'), findsOneWidget);
    expect(themePicker, findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(themePicker, findsNothing);
    expect(selectedTab(tester), 'Settings');
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
  });

  testWidgets('TC-002-35 back closes the theme picker only', (tester) async {
    final store = InMemoryPreferencesStore();
    await pumpBudgetApp(
      tester,
      store: store,
      theme: ThemeCase.dark,
      size: kSmallPhone,
      textScale: 2,
    );
    await tapTab(tester, 'Settings');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -40));
    await tester.pumpAndSettle();
    await openThemePicker(tester);
    final offset = visiblePagePosition(tester).pixels;
    expect(offset, greaterThan(0));
    final saved = Map.of(store.values);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(themePicker, findsNothing);
    expect(selectedTab(tester), 'Settings');
    expect(
      find.descendant(of: themeRow, matching: find.text('Dark')),
      findsOneWidget,
      reason: 'theme unchanged',
    );
    expect(pageBackground(tester), _darkBg);
    expect(visiblePagePosition(tester).pixels, offset);
    expect(store.values, saved, reason: 'store unchanged');
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
  });

  testWidgets('TC-002-37 picker re-themes while open', (tester) async {
    final semantics = tester.ensureSemantics();
    await _openPicker(tester, theme: ThemeCase.autoSystemLight);
    expect(sheetDecoration(tester).color, const Color(0xFFFFFDF8));
    // Review C1: the sheet shadow in Light…
    expect(sheetDecoration(tester).boxShadow, _lightSheetShadow);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(themePicker, findsOneWidget);
    expect(sheetDecoration(tester).color, const Color(0xFF17171D));
    // …and none in Dark.
    expect(sheetDecoration(tester).boxShadow ?? const [], isEmpty);
    expect(pageBackground(tester), _darkBg);
    _expectSelected(tester, 'Auto', 'after the switch');
    semantics.dispose();
  });

  testWidgets(
    'TC-002-23 theme picker meets tap target and contrast guidelines in '
    'every theme',
    (tester) async {
      for (final theme in ThemeCase.values) {
        for (final scale in [1.0, 2.0]) {
          final where = '${theme.name} at $scale';
          await tester.pumpWidget(const SizedBox());
          await _openPicker(
            tester,
            theme: theme,
            size: kSmallPhone,
            textScale: scale,
          );
          await expectAccessible(tester, reason: where);

          // Review C1: the sheet shadow in Light only; the fill is surface.
          final decoration = sheetDecoration(tester);
          expect(decoration.color, theme.colors.surface, reason: where);
          expect(
            decoration.boxShadow ?? const <BoxShadow>[],
            theme.colors == BudgetColors.light ? _lightSheetShadow : isEmpty,
            reason: where,
          );

          // At most 90 % of the screen; the options scroll, Done stays put.
          final sheet = tester.getRect(find.byType(BudgetSheetFrame));
          expect(sheet.height, lessThanOrEqualTo(640 * 0.9 + 0.5));
          await tester.scrollUntilVisible(
            pickerOption('Dim'),
            100,
            scrollable: find
                .descendant(of: themePicker, matching: find.byType(Scrollable))
                .first,
          );
          expect(pickerOption('Dim').hitTestable(), findsOneWidget);
          expect(
            find
                .descendant(of: themePicker, matching: find.text('Done'))
                .hitTestable(),
            findsOneWidget,
            reason: where,
          );
          expectNoOverflow(tester, reason: where);
        }
      }
    },
  );
}
