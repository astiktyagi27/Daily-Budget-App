import 'package:daily_budget/core/help/first_time_hint.dart';
import 'package:daily_budget/core/help/help_sheet.dart';
import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/data/preferences/preferences_store.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:daily_budget/features/settings/theme/theme_setting_row.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/failing_preferences_store.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/shell.dart';
import '../../helpers/theme_cases.dart';
import '../../support/p1_screens.dart';

// Literals from F-004 §5 and plan F-004 §3 (never the app's own constants).
const Map<String, String> _hints = {
  'Home':
      "Use the tabs at the bottom to move around. Home is where you'll check "
      "today's budget each day.",
  'Dashboard':
      "Check back after a week of spending. That's when your patterns start "
      'to show.',
  'Transactions':
      "Spotted a wrong amount or category later? You'll be able to fix it "
      'right here.',
  'Settings':
      'Change the theme and other options here. Tap (i) next to a setting to '
      'learn what it does.',
};
const Map<String, String> _keys = {
  'Home': 'hint.home.v1.seen',
  'Dashboard': 'hint.dashboard.v1.seen',
  'Transactions': 'hint.transactions.v1.seen',
  'Settings': 'hint.settings.v1.seen',
};

/// The hint card of the tab on screen (offstage tabs are not found).
Finder get _card => find.byType(FirstTimeHintCard);
Finder get _gotIt => find.descendant(of: _card, matching: find.text('Got it'));
Finder get _close =>
    find.descendant(of: _card, matching: find.byIcon(Icons.close));

/// Test cases F-004 §0 "Onboarded": no hint flags saved.
InMemoryPreferencesStore _onboarded([Map<String, Object> values = const {}]) =>
    InMemoryPreferencesStore.allowing(PreferenceKeys.allowList, values);

Future<void> _pump(
  WidgetTester tester,
  PreferencesStore store, {
  ThemeCase theme = ThemeCase.light,
  Size? size,
  double textScale = 1,
  bool disableAnimations = false,
}) => pumpBudgetApp(
  tester,
  store: store,
  theme: theme,
  size: size,
  textScale: textScale,
  disableAnimations: disableAnimations,
);

void _expectHint(WidgetTester tester, String tab, [String? reason]) {
  expect(_card, findsOneWidget, reason: reason ?? tab);
  expect(
    find.descendant(of: _card, matching: find.text(_hints[tab]!)),
    findsOneWidget,
    reason: reason ?? tab,
  );
}

void _expectNoErrorUi(WidgetTester tester, String reason) {
  expect(tester.takeException(), isNull, reason: reason);
  for (final type in [ErrorWidget, AlertDialog, SnackBar, MaterialBanner]) {
    expect(find.byType(type), findsNothing, reason: '$reason: $type');
  }
}

/// A store that counts writes of hint flags.
final class _CountingStore implements PreferencesStore {
  final InMemoryPreferencesStore inner = _onboarded();
  int hintWrites = 0;

  @override
  String? readString(String key) => inner.readString(key);

  @override
  bool? readBool(String key) => inner.readBool(key);

  @override
  Future<bool> writeString(String key, String value) =>
      inner.writeString(key, value);

  @override
  Future<bool> writeBool(String key, {required bool value}) {
    if (key.startsWith('hint.')) hintWrites++;
    return inner.writeBool(key, value: value);
  }

  @override
  Future<bool> remove(String key) => inner.remove(key);
}

void main() {
  testWidgets('TC-004-09 each tab shows its own first-time hint', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _onboarded());
    for (final tab in _hints.keys) {
      await tapTab(tester, tab);
      _expectHint(tester, tab);
      expect(
        find.descendant(of: _card, matching: find.text('Tip')),
        findsOneWidget,
        reason: tab,
      );
      expect(_gotIt, findsOneWidget, reason: tab);
      expect(_close, findsOneWidget, reason: tab);
      // The card reads as one item, then its two buttons.
      expect(
        find.bySemanticsLabel('Tip. ${_hints[tab]}'),
        findsOneWidget,
        reason: tab,
      );
      expect(
        tester.getSemantics(_gotIt),
        isSemantics(
          label: 'Got it',
          hint: "Dismiss this tip. It won't show again.",
          isButton: true,
          hasTapAction: true,
        ),
        reason: tab,
      );
      expect(
        tester.getSemantics(_close),
        isSemantics(label: 'Dismiss tip', isButton: true, hasTapAction: true),
        reason: tab,
      );
      // Long-press shows the × tooltip.
      await tester.longPress(_close);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Dismiss tip'), findsOneWidget, reason: tab);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }
    semantics.dispose();
  });

  testWidgets('TC-004-10 dismissed hint stays gone and others still show', (
    tester,
  ) async {
    final store = _onboarded();
    await _pump(tester, store);

    await tester.tap(_gotIt);
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pumpAndSettle();
    expect(_card, findsNothing, reason: 'Home: gone at once');
    expect(store.values[_keys['Home']], isTrue);

    await tapTab(tester, 'Dashboard');
    await tester.tap(_close);
    await tester.pumpAndSettle();
    expect(_card, findsNothing, reason: 'Dashboard');
    expect(store.values[_keys['Dashboard']], isTrue);

    void expectState(String step) {
      expect(store.values[_keys['Transactions']], isNull, reason: step);
      expect(store.values[_keys['Settings']], isNull, reason: step);
    }

    Future<void> walk(String step) async {
      for (final tab in _hints.keys) {
        await tapTab(tester, tab);
        if (tab == 'Home' || tab == 'Dashboard') {
          expect(_card, findsNothing, reason: '$step: $tab');
        } else {
          _expectHint(tester, tab);
        }
      }
      expectState(step);
    }

    await walk('after switching tabs');
    await restartApp(tester, _onboarded(store.values), settle: true);
    await walk('after restart');
  });

  testWidgets('TC-004-12 undismissed hint shows again', (tester) async {
    final store = _onboarded();
    await _pump(tester, store);
    await tapTab(tester, 'Dashboard');
    _expectHint(tester, 'Dashboard');
    await tapTab(tester, 'Home');
    await tapTab(tester, 'Dashboard');
    _expectHint(tester, 'Dashboard');

    await restartApp(tester, _onboarded(store.values), settle: true);
    await tapTab(tester, 'Dashboard');
    _expectHint(tester, 'Dashboard');
    for (final key in _keys.values) {
      expect(store.values[key], isNull, reason: 'viewing is not dismissing');
    }
  });

  testWidgets('TC-004-13 hint does not block the screen', (tester) async {
    final store = _onboarded();
    await _pump(tester, store, size: kSmallPhone, textScale: 2);
    await tapTab(tester, 'Settings');
    _expectHint(tester, 'Settings');
    expect(
      find.descendant(of: _card, matching: find.byType(ModalBarrier)),
      findsNothing,
    );

    // 1. The Theme row still works (the list scrolls past the hint).
    await openThemePicker(tester);
    expect(themePicker, findsOneWidget);
    await closeThemePicker(tester);

    // 2. The list still scrolls.
    final before = visiblePagePosition(tester).pixels;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(visiblePagePosition(tester).pixels, isNot(before));

    // 3. The bar still works.
    await tapTab(tester, 'Home');
    expect(selectedTab(tester), 'Home');
    expect(store.values[_keys['Settings']], isNull, reason: 'still not seen');
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-004-14 no hints during onboarding', (tester) async {
    final store = InMemoryPreferencesStore.allowing(PreferenceKeys.allowList);
    await pumpBudgetApp(tester, store: store, onboarded: false);

    void expectNoHint(String screen) {
      expect(_card, findsNothing, reason: screen);
      for (final text in _hints.values) {
        expect(find.text(text), findsNothing, reason: '$screen: "$text"');
      }
    }

    // The four slides, the SMS and notifications explainers, the disclaimer.
    const steps = [
      ('Spend a little each day', 'Next'),
      ('Your daily budget, worked out', 'Next'),
      ('Saved days add up', 'Next'),
      ('Private by design', 'Get started'),
      ('Read your bank SMS', 'Not now'),
      ('Get gentle nudges', 'Not now'),
      ('Before you start', 'I understand'),
    ];
    for (final (title, button) in steps) {
      expect(find.text(title), findsOneWidget, reason: title);
      expectNoHint(title);
      await tapOnboardingButton(tester, button);
    }

    // Home shows its hint right after I understand.
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 'Home');
    _expectHint(tester, 'Home');
    for (final key in _keys.values) {
      expect(store.values[key], isNull, reason: '$key: nothing marked seen');
    }
  });

  testWidgets('TC-004-15 hint storage failure never crashes', (tester) async {
    // (a) Nothing can be read: every tab shows its hint.
    await _pump(
      tester,
      FailingPreferencesStore(readFails: true),
      theme: ThemeCase.autoSystemLight,
    );
    for (final tab in _hints.keys) {
      await tapTab(tester, tab);
      _expectHint(tester, tab);
      _expectNoErrorUi(tester, 'readFails on $tab');
    }

    // (b) Nothing can be saved: hidden for the session, back after restart.
    await tester.pumpWidget(const SizedBox());
    final store = FailingPreferencesStore(writeFails: true);
    await pumpBudgetApp(
      tester,
      store: store,
      theme: ThemeCase.autoSystemLight,
      seedTheme: false,
    );
    await tester.tap(_gotIt);
    await tester.pumpAndSettle();
    expect(_card, findsNothing);
    await tapTab(tester, 'Dashboard');
    await tapTab(tester, 'Home');
    expect(_card, findsNothing, reason: 'hidden for the session');
    _expectNoErrorUi(tester, 'writeFails');

    await restartApp(
      tester,
      FailingPreferencesStore(values: store.values),
      system: ThemeCase.autoSystemLight,
      settle: true,
    );
    _expectHint(tester, 'Home');
    _expectNoErrorUi(tester, 'after restart');
  });

  testWidgets('TC-004-16 hint cards fit at text scale 2 on every tab', (
    tester,
  ) async {
    for (final theme in ThemeCase.values) {
      for (final scale in [1.0, 2.0]) {
        final where = '${theme.name} at $scale';
        await tester.pumpWidget(const SizedBox());
        await _pump(
          tester,
          _onboarded(),
          theme: theme,
          size: kSmallPhone,
          textScale: scale,
        );
        for (final tab in _hints.keys) {
          await tapTab(tester, tab);
          _expectHint(tester, tab, '$where on $tab');
          expectNoOverflow(tester, reason: '$where on $tab');
          await expectAccessible(tester, reason: '$where on $tab');

          // The body below the hint can be scrolled to its end.
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -5000),
          );
          await tester.pumpAndSettle();
          final position = visiblePagePosition(tester);
          expect(
            position.pixels,
            position.maxScrollExtent,
            reason: '$where on $tab',
          );
          expectNoOverflow(tester, reason: '$where on $tab, scrolled');
          await tapTab(tester, tab); // back to the top
        }
      }
    }
  });

  testWidgets('TC-004-18 closing an explanation does not dismiss the hint', (
    tester,
  ) async {
    final store = _onboarded();
    // Tall enough that the hint and the Theme row are both on screen.
    await _pump(tester, store, size: const Size(400, 1200));
    await tapTab(tester, 'Settings');
    _expectHint(tester, 'Settings');

    await tester.tap(find.byType(InfoButton));
    await tester.pumpAndSettle();
    expect(find.byType(HelpSheet), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(HelpSheet),
        matching: find.text('Got it'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HelpSheet), findsNothing);
    _expectHint(tester, 'Settings');
    expect(store.values[_keys['Settings']], isNull);
  });

  test('TC-004-21 each hint has its own id and key', () {
    expect(HintId.values, hasLength(4));
    expect(HintId.values.map((id) => id.storageSuffix).toSet(), {
      'home.v1',
      'dashboard.v1',
      'transactions.v1',
      'settings.v1',
    });
    final keys = HintId.values.map(PreferenceKeys.hintSeen).toSet();
    expect(keys, _keys.values.toSet());
    // Registered, so the device store accepts them.
    expect(PreferenceKeys.allowList, containsAll(keys));
  });

  testWidgets('TC-004-22 hint is read right after the top bar', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _onboarded(), size: const Size(400, 1200));
    const emptyState =
        "Your daily budget lives here. Once you set up your month, you'll see "
        "what you can spend today, what you've spent and your calendar.";
    // Labelled stops only; the label includes merged children.
    final nodes = tester.semantics
        .simulatedAccessibilityTraversal()
        .where((node) => node.getSemanticsData().label.isNotEmpty)
        .toList();
    final read = nodes.map((node) => node.getSemanticsData().label).toList();
    int at(String label) => read.indexOf(label);
    expect(at('Daily Budget App'), 0, reason: 'top bar first');
    expect(at('Tip. ${_hints['Home']}'), 1, reason: 'then the hint text');
    expect(
      {read[2], read[3]},
      {'Got it', 'Dismiss tip'},
      reason: 'then its two buttons',
    );
    expect(read[4], emptyState, reason: 'then the empty state');
    expect(at('Home, tab 1 of 4'), greaterThan(4), reason: 'nav last');
    final gotIt = nodes[at('Got it')];
    expect(
      gotIt,
      isSemantics(isFocusable: true, hasTapAction: true, isButton: true),
    );
    semantics.dispose();
  });

  testWidgets('TC-004-22 dismissing a hint moves focus to the next item', (
    tester,
  ) async {
    // Help-pattern §4.3: after Got it, focus lands on the first item after
    // the card (on Settings, the Theme row); a finger tap moves nothing.
    bool focusOnThemeRow() =>
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<ThemeSettingRow>() !=
        null;
    Future<void> openSettings() async {
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, _onboarded());
      await tapTab(tester, 'Settings');
      _expectHint(tester, 'Settings');
    }

    // Keyboard: Got it focused, Enter.
    await openSettings();
    Focus.of(tester.element(_gotIt)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_card, findsNothing, reason: 'keyboard');
    expect(focusOnThemeRow(), isTrue, reason: 'keyboard: next item');

    // Screen reader on: the tap moves focus too.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await openSettings();
    await tester.tap(_gotIt);
    await tester.pumpAndSettle();
    expect(_card, findsNothing, reason: 'screen reader');
    expect(focusOnThemeRow(), isTrue, reason: 'screen reader: next item');
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    // A plain finger tap leaves focus alone.
    await openSettings();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(_gotIt);
    await tester.pumpAndSettle();
    expect(_card, findsNothing, reason: 'touch');
    expect(focusOnThemeRow(), isFalse, reason: 'touch: focus not moved');
  });

  testWidgets('TC-004-23 double tap on hint got it is safe', (tester) async {
    final store = _CountingStore();
    await _pump(tester, store);

    await tester.tap(_gotIt);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(_gotIt, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_card, findsNothing);
    expect(store.hintWrites, 1, reason: 'one write');
    expect(store.inner.values[_keys['Home']], isTrue);
    for (final tab in ['Dashboard', 'Transactions', 'Settings']) {
      expect(store.inner.values[_keys[tab]], isNull, reason: tab);
    }
  });

  testWidgets('TC-004-24 corrupt hint flag shows the hint', (tester) async {
    for (final value in <Object>['yes', 3, '']) {
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, _onboarded({_keys['Home']!: value}));
      _expectHint(tester, 'Home', 'Home with $value');
      _expectNoErrorUi(tester, 'Home with $value');
    }
  });

  testWidgets('TC-002-45 remove animations makes the hint collapse instant', (
    tester,
  ) async {
    await _pump(tester, _onboarded(), disableAnimations: true);
    _expectHint(tester, 'Home');
    await tester.tap(_gotIt);
    await tester.pump();
    await tester.pump();
    expect(_card, findsNothing, reason: 'no collapse animation');
  });
}
