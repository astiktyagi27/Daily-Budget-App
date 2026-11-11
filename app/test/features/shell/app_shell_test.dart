import 'package:daily_budget/core/help/first_time_hint.dart';
import 'package:daily_budget/core/help/help_sheet.dart';
import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/features/shell/budget_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/shell.dart';
import '../../helpers/theme_cases.dart';

// Literals from F-003 §5 and app-shell §3 (never the app's own constants).
const _labels = ['Home', 'Dashboard', 'Transactions', 'Settings'];
const _titles = {
  'Home': 'Daily Budget App',
  'Dashboard': 'Dashboard',
  'Transactions': 'Transactions',
  'Settings': 'Settings',
};
const _hints = {
  'Home': "Today's budget and your calendar",
  'Dashboard': 'Where your money goes',
  'Transactions': 'Every spend and credit',
  'Settings': 'Theme and app options',
};
const List<IconData> _outlined = [
  Icons.home_outlined,
  Icons.bar_chart_outlined,
  Icons.receipt_long_outlined,
  Icons.tune_outlined,
];
const List<IconData> _filled = [
  Icons.home,
  Icons.bar_chart,
  Icons.receipt_long,
  Icons.tune,
];

Finder _navText(String label) =>
    find.descendant(of: navBar, matching: find.text(label));

Finder get _tick => find.byType(BudgetNavTick);

/// Asserts that only [label]'s page is on screen, its title showing.
void _expectOnTab(WidgetTester tester, String label, {String? reason}) {
  final title = _titles[label]!;
  expect(pageTitle(title), findsOneWidget, reason: reason);
  for (final other in _titles.values.where((t) => t != title)) {
    expect(pageTitle(other), findsNothing, reason: reason);
  }
  final node = tester.getSemantics(navItem(label));
  expect(
    node.flagsCollection.isSelected.toBoolOrNull(),
    isTrue,
    reason: reason,
  );
  // Tabs are not pushed routes.
  final navigator = tester.state<NavigatorState>(find.byType(Navigator));
  expect(navigator.canPop(), isFalse, reason: reason);
}

void main() {
  testWidgets('TC-003-01 shell shows four labelled tabs with home selected', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpShell(tester);

    expect(navBar, findsOneWidget);
    final xs = [for (final l in _labels) tester.getCenter(_navText(l)).dx];
    expect(xs, orderedEquals([...xs]..sort()), reason: 'left to right');
    for (final (i, label) in _labels.indexed) {
      expect(_navText(label), findsOneWidget, reason: label);
      expect(
        find.descendant(
          of: navBar,
          matching: find.byIcon(i == 0 ? _filled[i] : _outlined[i]),
        ),
        findsOneWidget,
        reason: label,
      );
    }
    _expectOnTab(tester, 'Home');
    semantics.dispose();
  });

  testWidgets('TC-003-02 selected tab has shape cue and selected semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpShell(tester);
    for (final (selected, label) in _labels.indexed) {
      await tapTab(tester, label);

      // The one tick sits over the selected slot.
      expect(_tick, findsOneWidget);
      expect(
        tester.getSize(
          find.descendant(of: _tick, matching: find.byType(Container)),
        ),
        const Size(16, 4),
      );
      final slot = tester.getRect(navItem(label));
      expect(tester.getCenter(_tick).dx, closeTo(slot.center.dx, 0.5));
      expect(tester.getRect(_tick).top, greaterThanOrEqualTo(slot.top));

      for (final (i, other) in _labels.indexed) {
        final isSelected = i == selected;
        final icon = isSelected ? _filled[i] : _outlined[i];
        expect(
          find.descendant(of: navItem(other), matching: find.byIcon(icon)),
          findsOneWidget,
          reason: '$other when $label is selected',
        );
        final text = tester.renderObject<RenderParagraph>(_navText(other));
        expect(
          text.text.style!.fontWeight,
          isSelected ? FontWeight.w600 : FontWeight.w500,
        );
        expect(
          tester.getSemantics(navItem(other)),
          isSemantics(
            label: '$other, tab ${i + 1} of 4',
            isButton: true,
            hasTapAction: true,
            isSelected: isSelected,
          ),
          reason: '$other when $label is selected',
        );
      }
    }
    semantics.dispose();
  });

  testWidgets('TC-003-04 every tab switch shows the right body', (
    tester,
  ) async {
    await pumpShell(tester);
    for (final from in _labels) {
      for (final to in _labels.where((l) => l != from)) {
        await tapTab(tester, from);
        await tapTab(tester, to);
        _expectOnTab(tester, to, reason: '$from → $to');
      }
    }
  });

  testWidgets('TC-003-10 back goes home then leaves the app', (tester) async {
    final pops = recordSystemPops(tester);
    await pumpShell(tester);
    for (final label in _labels.skip(1)) {
      await tapTab(tester, label);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      _expectOnTab(tester, 'Home', reason: 'back from $label');
      expect(pops(), 0, reason: 'back from $label stays in the app');
    }

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(pops(), 1);
    expect(tester.takeException(), isNull);
    _expectOnTab(tester, 'Home');
  });

  testWidgets('TC-003-21 back closes overlays before leaving the tab', (
    tester,
  ) async {
    final pops = recordSystemPops(tester);
    final info = find.descendant(
      of: themeRow,
      matching: find.byType(InfoButton),
    );
    // (a) the theme picker, (b) the Theme (i) explanation.
    final overlays = <String, (Future<void> Function(), Finder)>{
      'picker': (() => openThemePicker(tester), themePicker),
      'explanation': (
        () async {
          await tester.tap(info);
          await tester.pumpAndSettle();
        },
        find.byType(HelpSheet),
      ),
    };
    for (final MapEntry(key: name, value: (open, overlay))
        in overlays.entries) {
      await tester.pumpWidget(const SizedBox());
      await pumpShell(tester, size: kSmallPhone, textScale: 2);
      await tapTab(tester, 'Settings');
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -60));
      await tester.pumpAndSettle();
      await open();
      expect(overlay, findsOneWidget, reason: name);
      final offset = visiblePagePosition(tester).pixels;
      expect(offset, greaterThan(0), reason: name);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(overlay, findsNothing, reason: '$name: first back closes it');
      // The title may be scrolled out of view, so check the bar and routes.
      expect(selectedTab(tester), 'Settings', reason: name);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
        reason: '$name: no route left',
      );
      expect(visiblePagePosition(tester).pixels, offset, reason: name);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      _expectOnTab(tester, 'Home', reason: '$name: second back');
      expect(pops(), 0, reason: name);
    }

    // (c) the Settings first-time hint is page content, not an overlay.
    await tester.pumpWidget(const SizedBox());
    final store = InMemoryPreferencesStore.allowing(PreferenceKeys.allowList);
    await pumpShell(tester, store: store, hintsSeen: false);
    await tapTab(tester, 'Settings');
    final hint = find.byType(FirstTimeHintCard);
    expect(hint, findsOneWidget);
    final saved = Map.of(store.values);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    _expectOnTab(tester, 'Home', reason: 'back with the hint visible');
    expect(pops(), 0);
    expect(store.values, saved, reason: 'the hint is not saved as seen');

    await tapTab(tester, 'Settings');
    expect(hint, findsOneWidget, reason: 'the hint is still shown');
    expect(
      find.descendant(
        of: hint,
        matching: find.text(
          'Change the theme and other options here. Tap (i) next to a '
          'setting to learn what it does.',
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-003-19 nav tabs show tooltip and hint on long press', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpShell(tester);
    for (final label in _labels) {
      expect(
        tester.getSemantics(navItem(label)),
        isSemantics(hint: _hints[label]),
        reason: label,
      );
      await tester.longPress(navItem(label));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(_hints[label]!), findsOneWidget, reason: label);
      _expectOnTab(tester, 'Home', reason: 'long-press does not switch');
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
    semantics.dispose();
  });

  testWidgets('TC-003-20 rapid tab taps show the last tab', (tester) async {
    final pops = recordSystemPops(tester);
    await pumpShell(tester);
    for (final label in [
      'Dashboard',
      'Settings',
      'Transactions',
      'Home',
      'Settings',
    ]) {
      await tester.tap(navItem(label));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    _expectOnTab(tester, 'Settings');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    _expectOnTab(tester, 'Home');
    expect(pops(), 0);
  });

  testWidgets('TC-003-23 bottom bar respects the system navigation area', (
    tester,
  ) async {
    for (final inset in [48.0, 24.0]) {
      tester.view.padding = FakeViewPadding(bottom: inset * 3);
      tester.view.viewPadding = FakeViewPadding(bottom: inset * 3);
      addTearDown(tester.view.reset);
      await pumpShell(tester, size: kSmallPhone);

      for (final label in _labels) {
        final rect = tester.getRect(navItem(label));
        expect(
          rect.bottom,
          lessThanOrEqualTo(640 - inset + 0.5),
          reason: '$label above a $inset dp inset',
        );
        expect(navItem(label).hitTestable(), findsOneWidget, reason: label);
      }
      // The bar's fill still reaches the bottom edge (edge-to-edge).
      expect(tester.getRect(navBar).bottom, 640);
    }
  });

  testWidgets('TC-003-25 shell survives a wide screen', (tester) async {
    for (final theme in [ThemeCase.light, ThemeCase.dim]) {
      await pumpShell(tester, theme: theme, size: const Size(1280, 800));
      for (final label in _labels) {
        await tapTab(tester, label);
        expectNoOverflow(tester, reason: '${theme.name} $label');
      }
    }
  });

  testWidgets('TC-003-26 navigation bar uses theme tokens in every theme', (
    tester,
  ) async {
    for (final theme in ThemeCase.values) {
      final c = theme.colors;
      await pumpShell(tester, theme: theme);
      for (final (selected, label) in _labels.indexed) {
        final where = '${theme.name} on $label';
        await tapTab(tester, label);
        expect(tester.takeException(), isNull, reason: where);
        final bar = tester.widget<Material>(
          find.descendant(of: navBar, matching: find.byType(Material)).first,
        );
        expect(bar.color, c.surface, reason: where);
        for (final (i, other) in _labels.indexed) {
          final expected = i == selected ? c.accent : c.neutral;
          final text = tester.renderObject<RenderParagraph>(_navText(other));
          expect(text.text.style!.color, expected, reason: '$where: $other');
          final icon = tester.widget<Icon>(
            find.descendant(of: navItem(other), matching: find.byType(Icon)),
          );
          expect(icon.color, expected, reason: '$where: $other icon');
        }
        final tick = tester.widget<Container>(
          find.descendant(of: _tick, matching: find.byType(Container)),
        );
        expect(
          (tick.decoration! as BoxDecoration).color,
          c.accent,
          reason: where,
        );
      }
    }
  });

  testWidgets('TC-003-30 nav labels are capped and fitted at large text', (
    tester,
  ) async {
    for (final width in [360.0, 320.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        final where = '$width dp at $scale';
        await pumpShell(tester, size: Size(width, 640), textScale: scale);
        expectNoOverflow(tester, reason: where);
        for (final label in _labels) {
          final text = tester.renderObject<RenderParagraph>(_navText(label));
          expect(text.text.toPlainText(), label, reason: where);
          expect(text.didExceedMaxLines, isFalse, reason: where);
          expect(
            text.textScaler.scale(12),
            lessThanOrEqualTo(12 * 1.3 + 0.01),
            reason: '$where: scale capped at 1.3',
          );
          final slot = tester.getRect(navItem(label));
          final rect = tester.getRect(_navText(label));
          expect(
            rect.left >= slot.left - 0.5 && rect.right <= slot.right + 0.5,
            isTrue,
            reason: '$where: $label inside its slot',
          );
          final icon = find.descendant(
            of: navItem(label),
            matching: find.byType(Icon),
          );
          expect(tester.getSize(icon), const Size(24, 24), reason: where);
        }
      }
    }
  });
}
