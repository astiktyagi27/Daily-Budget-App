import 'dart:async';

import 'package:daily_budget/app.dart';
import 'package:daily_budget/core/theme/budget_colors.dart';
import 'package:daily_budget/core/theme/theme_choice_provider.dart';
import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preferences_store.dart';
import 'package:daily_budget/domain/preferences/theme_choice.dart';
import 'package:daily_budget/features/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/failing_preferences_store.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/shell.dart';
import '../../helpers/theme_cases.dart';
import '../../support/app_lifecycle.dart';

// Backgrounds and text colours as literals from design-system.md §2.
const _lightBg = 0xFFF6F3ED;
const _darkBg = 0xFF0E0E12;
const _dimBg = 0xFF2A2825;
const _key = 'theme.choice';

/// The page background on screen right now (the Scaffold's own Material).
int _bg(WidgetTester tester) => tester
    .widgetList<Material>(
      find.descendant(
        of: find.byType(Scaffold),
        matching: find.byType(Material),
      ),
    )
    .first
    .color!
    .toARGB32();

ThemeChoiceNotifier _notifier(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(DailyBudgetApp)))
        .read(themeChoiceProvider.notifier);

ThemeChoice _choice(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(DailyBudgetApp)))
        .read(themeChoiceProvider);

/// Test cases §0 "Restart (sim)": dispose the whole tree, then pump a new
/// app on a new store that shares only the old backing map. Stops after the
/// first frame.
Future<void> _restart(
  WidgetTester tester,
  PreferencesStore store, {
  required ThemeCase system,
}) async {
  await tester.pumpWidget(const SizedBox());
  await pumpBudgetApp(
    tester,
    store: store,
    theme: system,
    seedTheme: false,
    settle: false,
  );
}

/// The choice the open theme picker shows as selected.
ThemeChoice? _pickerSelection(WidgetTester tester) => tester
    .widget<RadioGroup<ThemeChoice>>(find.byType(RadioGroup<ThemeChoice>))
    .groupValue;

/// Settings → Theme → [label]; the picker is left open.
Future<void> _pickInSettings(WidgetTester tester, String label) async {
  await tapTab(tester, 'Settings');
  await openThemePicker(tester);
  await pickTheme(tester, label);
}

const Map<ThemeChoice, String> _labels = {
  ThemeChoice.auto: 'Auto',
  ThemeChoice.light: 'Light',
  ThemeChoice.dark: 'Dark',
  ThemeChoice.dim: 'Dim',
};

/// AC-4 "within 1 second": frames over exactly one second (a single long
/// pump is only one frame, the frame on which the switch starts).
Future<void> _pumpOneSecond(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Test cases §0 "No-error UI".
void _expectNoErrorUi(WidgetTester tester, String reason) {
  expect(tester.takeException(), isNull, reason: reason);
  for (final type in [ErrorWidget, AlertDialog, SnackBar, MaterialBanner]) {
    expect(find.byType(type), findsNothing, reason: '$reason: $type');
  }
}

/// A store whose saves only finish when the test says so.
final class _SlowStore implements PreferencesStore {
  final _inner = InMemoryPreferencesStore();
  final saves = <Completer<void>>[];

  Map<String, Object> get values => _inner.values;

  @override
  String? readString(String key) => _inner.readString(key);

  @override
  bool? readBool(String key) => _inner.readBool(key);

  @override
  Future<bool> writeString(String key, String value) async {
    final done = Completer<void>();
    saves.add(done);
    await done.future;
    return await _inner.writeString(key, value);
  }

  @override
  Future<bool> writeBool(String key, {required bool value}) =>
      _inner.writeBool(key, value: value);

  @override
  Future<bool> remove(String key) => _inner.remove(key);
}

void main() {
  testWidgets('TC-002-04 auto follows system and never shows dim', (
    tester,
  ) async {
    await pumpBudgetApp(tester, theme: ThemeCase.autoSystemLight);
    expect(_bg(tester), _lightBg);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );

    await tester.pumpWidget(const SizedBox());
    await pumpBudgetApp(tester, theme: ThemeCase.autoSystemDark);
    expect(_bg(tester), _darkBg);
    expect(_bg(tester), isNot(_dimBg));
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );
  });

  testWidgets('TC-002-02 light dark and dim render their own tokens', (
    tester,
  ) async {
    const expected = {
      ThemeCase.light: (_lightBg, 0xFF1C1B22),
      ThemeCase.dark: (_darkBg, 0xFFF2F0EA),
      ThemeCase.dim: (_dimBg, 0xFFEEE9E0),
    };
    final seen = <int>{};
    for (final MapEntry(key: theme, value: (bg, text)) in expected.entries) {
      await pumpBudgetApp(tester, theme: theme);
      for (final (tab, title) in [
        ('Home', 'Daily Budget App'),
        ('Settings', 'Settings'),
      ]) {
        final where = '${theme.name} on $tab';
        await tapTab(tester, tab);
        expect(_bg(tester), bg, reason: where);
        final heading = tester.renderObject<RenderParagraph>(pageTitle(title));
        expect(heading.text.style!.color!.toARGB32(), text, reason: where);
        final context = tester.element(pageTitle(title));
        expect(
          Theme.of(context).extension<BudgetColors>(),
          same(theme.colors),
          reason: where,
        );
      }
      seen.add(bg);
    }
    expect(seen, hasLength(3), reason: 'backgrounds must differ');
  });

  testWidgets('TC-002-05 auto switches live and keeps tab and scroll', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpBudgetApp(
      tester,
      theme: ThemeCase.autoSystemLight,
      size: kSmallPhone,
      textScale: 2,
    );
    await tapTab(tester, 'Settings');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    final offset = visiblePagePosition(tester).pixels;
    expect(offset, greaterThan(0));
    final shell = tester.element(find.byType(AppShell));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));

    void expectKept(String step, int bg) {
      expect(_bg(tester), bg, reason: step);
      expect(
        tester
            .getSemantics(navItem('Settings'))
            .flagsCollection
            .isSelected
            .toBoolOrNull(),
        isTrue,
        reason: '$step: Settings still selected',
      );
      expect(
        visiblePagePosition(tester).pixels,
        closeTo(offset, 0.5),
        reason: step,
      );
      expect(tester.element(find.byType(AppShell)), same(shell), reason: step);
      expect(navigator.canPop(), isFalse, reason: '$step: no new route');
      expect(tester.takeException(), isNull, reason: step);
    }

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await _pumpOneSecond(tester);
    expectKept('to dark', _darkBg);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await _pumpOneSecond(tester);
    expectKept('back to light', _lightBg);

    // Switched while the app was in the background.
    sendToBackground(tester);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    bringToForeground(tester);
    await _pumpOneSecond(tester);
    expectKept('in the background', _darkBg);
    semantics.dispose();
  });

  testWidgets('TC-002-07 theme change applies before the save finishes', (
    tester,
  ) async {
    final store = _SlowStore();
    await pumpBudgetApp(tester, store: store, seedTheme: false);
    final screen = tester.element(find.byType(AppShell));

    final saved = _notifier(tester).select(ThemeChoice.dim);
    await tester.pumpAndSettle();
    expect(_choice(tester), ThemeChoice.dim);
    expect(_bg(tester), _dimBg, reason: 'applied while the save is pending');
    expect(store.values, isEmpty);
    expect(tester.element(find.byType(AppShell)), same(screen));

    store.saves.single.complete();
    expect(await saved, isTrue);
    expect(store.values, {_key: 'dim'});
  });

  testWidgets('TC-002-09 fresh install starts in auto', (tester) async {
    final store = InMemoryPreferencesStore();
    await pumpBudgetApp(tester, store: store, seedTheme: false);

    expect(_choice(tester), ThemeChoice.auto);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );
    expect(store.values, isEmpty, reason: 'starting writes nothing');
  });

  testWidgets('TC-002-10 theme choice survives restart from the first frame', (
    tester,
  ) async {
    final cases = [
      (ThemeChoice.dim, ThemeCase.light, _dimBg),
      (ThemeChoice.light, ThemeCase.autoSystemDark, _lightBg),
      (ThemeChoice.dark, ThemeCase.light, _darkBg),
      (ThemeChoice.auto, ThemeCase.autoSystemDark, _darkBg),
    ];
    for (final (choice, system, bg) in cases) {
      await tester.pumpWidget(const SizedBox());
      final store = InMemoryPreferencesStore();
      // Start from a different theme, so the first frame cannot be right by
      // accident.
      await pumpBudgetApp(
        tester,
        store: store,
        theme: choice == ThemeChoice.dim ? ThemeCase.light : ThemeCase.dim,
      );
      await _pickInSettings(tester, _labels[choice]!);
      expect(store.values, {_key: choice.storageValue}, reason: choice.name);

      await _restart(
        tester,
        InMemoryPreferencesStore(store.values),
        system: system,
      );
      expect(_bg(tester), bg, reason: '${choice.name}: first frame');
      expect(_choice(tester), choice, reason: choice.name);

      await tester.pumpAndSettle();
      await tapTab(tester, 'Settings');
      await openThemePicker(tester);
      expect(_pickerSelection(tester), choice, reason: choice.name);
    }
  });

  testWidgets('TC-002-13 corrupt or missing theme value falls back to auto', (
    tester,
  ) async {
    final values = <Object?>[null, 'blue', '', 'DIM ', 42, true, 'x' * 10000];
    for (final value in values) {
      for (final (system, bg) in [
        (ThemeCase.autoSystemLight, _lightBg),
        (ThemeCase.autoSystemDark, _darkBg),
      ]) {
        final where = '${'$value'.trim()} under ${system.name}';
        await tester.pumpWidget(const SizedBox());
        final store = InMemoryPreferencesStore({_key: ?value});
        await pumpBudgetApp(
          tester,
          store: store,
          theme: system,
          seedTheme: false,
        );
        expect(_bg(tester), bg, reason: where);
        expect(_choice(tester), ThemeChoice.auto, reason: where);
        _expectNoErrorUi(tester, where);

        await tapTab(tester, 'Settings');
        await openThemePicker(tester);
        expect(_pickerSelection(tester), ThemeChoice.auto, reason: where);
        _expectNoErrorUi(tester, '$where, picker open');
        await pickTheme(tester, 'Light');
        expect(store.values[_key], 'light', reason: where);
      }
    }
  });

  testWidgets('TC-002-14 unreadable store falls back to auto without crash', (
    tester,
  ) async {
    final store = FailingPreferencesStore(
      readFails: true,
      values: {_key: 'dim'},
    );
    await pumpBudgetApp(
      tester,
      store: store,
      theme: ThemeCase.autoSystemLight,
      seedTheme: false,
    );
    expect(_choice(tester), ThemeChoice.auto);
    expect(_bg(tester), _lightBg);
    _expectNoErrorUi(tester, 'start');

    await tapTab(tester, 'Settings');
    await openThemePicker(tester);
    expect(_pickerSelection(tester), ThemeChoice.auto);
    await pickTheme(tester, 'Dim');
    expect(_bg(tester), _dimBg);
    _expectNoErrorUi(tester, 'after picking dim');
  });

  testWidgets('TC-002-33 rapid theme changes keep the last choice', (
    tester,
  ) async {
    final store = InMemoryPreferencesStore();
    await pumpBudgetApp(tester, store: store, seedTheme: false);

    final notifier = _notifier(tester);
    for (final choice in [ThemeChoice.light, ThemeChoice.dark]) {
      unawaited(notifier.select(choice));
      await tester.pump(const Duration(milliseconds: 50));
    }
    unawaited(notifier.select(ThemeChoice.dim));
    await tester.pumpAndSettle();
    expect(_bg(tester), _dimBg);
    expect(store.values, {_key: 'dim'});
    expect(tester.takeException(), isNull);

    await _restart(
      tester,
      InMemoryPreferencesStore(store.values),
      system: ThemeCase.light,
    );
    expect(_bg(tester), _dimBg);
  });

  testWidgets('TC-002-36 failed theme save still applies for the session', (
    tester,
  ) async {
    final store = FailingPreferencesStore(writeFails: true);
    await pumpBudgetApp(
      tester,
      store: store,
      theme: ThemeCase.autoSystemLight,
      seedTheme: false,
    );

    await _pickInSettings(tester, 'Dim');
    expect(_bg(tester), _dimBg);
    expect(store.values, isEmpty, reason: 'nothing was saved');
    _expectNoErrorUi(tester, 'after the failed save');

    await _restart(
      tester,
      FailingPreferencesStore(values: store.values),
      system: ThemeCase.autoSystemLight,
    );
    expect(_choice(tester), ThemeChoice.auto);
    expect(_bg(tester), _lightBg);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-002-31 system bar icons contrast with each theme', (
    tester,
  ) async {
    for (final theme in ThemeCase.values) {
      await pumpBudgetApp(tester, theme: theme);
      final icons = theme.colors == BudgetColors.light
          ? Brightness.dark
          : Brightness.light;
      for (final tab in ['Home', 'Dashboard', 'Transactions', 'Settings']) {
        final where = '${theme.name} on $tab';
        await tapTab(tester, tab);
        final style = tester
            .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
              find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
            )
            .value;
        expect(style.statusBarIconBrightness, icons, reason: where);
        expect(style.systemNavigationBarIconBrightness, icons, reason: where);
      }
    }
  });

  testWidgets('TC-002-45 remove animations makes the theme switch instant', (
    tester,
  ) async {
    await pumpBudgetApp(tester);
    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app().themeAnimationDuration, const Duration(milliseconds: 200));

    // With animations on, the first frame after a change still shows the old
    // theme (the cross-fade has just started).
    unawaited(_notifier(tester).select(ThemeChoice.dark));
    await tester.pump();
    expect(_bg(tester), _lightBg);
    await tester.pumpAndSettle();
    expect(_bg(tester), _darkBg);

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    expect(app().themeAnimationDuration, Duration.zero);

    unawaited(_notifier(tester).select(ThemeChoice.dim));
    await tester.pump();
    expect(_bg(tester), _dimBg, reason: 'no cross-fade');
  });
}
