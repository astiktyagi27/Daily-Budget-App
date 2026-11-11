import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';
import '../helpers/shell.dart';
import '../helpers/theme_cases.dart';

/// The Phase 1 screens as test states (test cases F-002 §0 "P1 screens"),
/// each driven through the real app (`DailyBudgetApp` → `AppGate`).
///
/// Tabs open with every first-time hint dismissed; the `…WithHint` states
/// open on a fresh hint store. Onboarding states start from a fresh install
/// and tap through the real flow.
enum P1Screen {
  home('Home'),
  dashboard('Dashboard'),
  transactions('Transactions'),
  settings('Settings'),
  settingsEnd('Settings scrolled to the end'),
  themePicker('Theme picker open'),
  themeExplanation('Theme (i) explanation open'),
  homeWithHint('Home with its hint'),
  dashboardWithHint('Dashboard with its hint'),
  transactionsWithHint('Transactions with its hint'),
  settingsWithHint('Settings with its hint'),
  slide1('Tour slide 1'),
  slide2('Tour slide 2'),
  slide3('Tour slide 3'),
  slide4('Tour slide 4'),
  smsExplainer('SMS explainer'),
  notificationsExplainer('Notifications explainer'),
  disclaimer('Disclaimer');

  new(this.description);

  final String description;

  bool get isOnboarding => index >= P1Screen.slide1.index;

  bool get isSheet => this == themePicker || this == themeExplanation;

  /// Pumps a fresh app and drives it into this state, settled.
  Future<void> open(
    WidgetTester tester, {
    ThemeCase theme = ThemeCase.light,
    Size? size,
    double textScale = 1,
    bool boldText = false,
    bool highContrast = false,
  }) async {
    // `setUpScreen` only sets what differs from the default and never undoes
    // it, so a sweep that opens many states in one test must start each from
    // the defaults (800x600, scale 1, no accessibility flags).
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    if (boldText || highContrast) {
      setUpScreen(tester, boldText: boldText, highContrast: highContrast);
    }
    await tester.pumpWidget(const SizedBox());
    if (isOnboarding) {
      await pumpBudgetApp(
        tester,
        store: InMemoryPreferencesStore.allowing(PreferenceKeys.allowList),
        theme: theme,
        onboarded: false,
        size: size,
        textScale: textScale,
      );
      final steps = switch (this) {
        slide1 => const <String>[],
        slide2 => const ['Next'],
        slide3 => const ['Next', 'Next'],
        slide4 => const ['Next', 'Next', 'Next'],
        smsExplainer => const ['Skip'],
        notificationsExplainer => const ['Skip', 'Not now'],
        _ => const ['Skip', 'Not now', 'Not now'],
      };
      for (final label in steps) {
        await tapOnboardingButton(tester, label);
      }
      // Past the screens' own double-tap guards.
      await tester.pump(kDoubleTapTimeout);
      await tester.pumpAndSettle();
      return;
    }

    final withHint = switch (this) {
      homeWithHint ||
      dashboardWithHint ||
      transactionsWithHint ||
      settingsWithHint => true,
      _ => false,
    };
    await pumpShell(
      tester,
      theme: theme,
      size: size,
      textScale: textScale,
      hintsSeen: !withHint,
    );
    final tab = switch (this) {
      home || homeWithHint => 'Home',
      dashboard || dashboardWithHint => 'Dashboard',
      transactions || transactionsWithHint => 'Transactions',
      _ => 'Settings',
    };
    if (tab != 'Home') await tapTab(tester, tab);
    if (this == settingsEnd) {
      await tester.scrollUntilVisible(
        find.text('Disclaimer'),
        200,
        scrollable: _pageScrollable,
      );
      await tester.drag(_pageScrollable, const Offset(0, -2000));
      await tester.pumpAndSettle();
    } else if (this == themePicker) {
      await openThemePicker(tester);
    } else if (this == themeExplanation) {
      final info = find.descendant(
        of: themeRow,
        matching: find.byType(InfoButton),
      );
      await tester.ensureVisible(info);
      await tester.pumpAndSettle();
      await tester.tap(info);
      await tester.pumpAndSettle();
    }
  }
}

Finder get _pageScrollable => find
    .descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    )
    .first;

/// Taps an onboarding button by its label, after the screen's double-tap
/// guard has passed, and settles.
Future<void> tapOnboardingButton(WidgetTester tester, String label) async {
  await tester.pump(kDoubleTapTimeout);
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}
