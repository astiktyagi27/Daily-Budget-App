import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/shell.dart';
import '../../helpers/theme_cases.dart';
import 'onboarding_host.dart';

// Every expected string is a literal from F-005 §5 (house rule: never compare
// the app's copy with itself).
const _smsWhy =
    'To track spends for you, the app reads the SMS your bank sends when money '
    'moves.';
const _smsOnlyBank =
    "Only your bank's messages are read. OTPs, personal chats and other "
    'senders are ignored.';
const List<String> _smsPoints = [
  _smsWhy,
  _smsOnlyBank,
  'Everything stays on this phone. Nothing is uploaded or shared.',
];
const List<String> _notificationPoints = [
  "A heads-up when you've used 80% of today's budget.",
  'An alert if you go over.',
  'An end-of-day summary of what you saved or overspent.',
  'Optional. You can change this anytime in Settings.',
];
const _detection =
    'Automatic detection can get things wrong sometimes. You can edit any '
    'transaction or category.';
const List<String> _disclaimerPoints = [
  'The app tracks one bank account.',
  'Credit card spends are not included.',
  _detection,
];

/// One explainer screen as the tests walk it.
typedef _Screen = ({
  String title,
  List<String> points,
  List<(String label, String hint)> buttons,
  String? description,
});

const List<_Screen> _screens = [
  (
    title: smsTitle,
    points: _smsPoints,
    buttons: [
      ('Allow SMS access', 'You can still add spends yourself if you say no.'),
      ('Not now', 'Continue without SMS access for now'),
    ],
    description: 'You can still add spends yourself if you say no.',
  ),
  (
    title: notificationsTitle,
    points: _notificationPoints,
    buttons: [
      (
        'Turn on notifications',
        'Notifications are created on your phone. Nothing is sent anywhere.',
      ),
      ('Not now', 'Continue without notifications'),
    ],
    description:
        'Notifications are created on your phone. Nothing is sent anywhere.',
  ),
  (
    title: disclaimerTitle,
    points: _disclaimerPoints,
    buttons: [('I understand', 'Finish setup and open the app')],
    description: null,
  ),
];

/// Pumps the flow on the SMS explainer and walks forward to screen [index]
/// (0 SMS, 1 notifications, 2 disclaimer) with Not now.
Future<FakeOnboardingActions> _pumpAt(
  WidgetTester tester,
  int index, {
  ThemeCase theme = ThemeCase.light,
  Size? size,
  double textScale = 1,
  RouteCounter? routes,
}) async {
  final actions = await pumpOnboarding(
    tester,
    stage: FakeStage.explainers,
    theme: theme,
    size: size,
    textScale: textScale,
    routes: routes,
  );
  for (var i = 0; i < index; i++) {
    await tapButton(tester, 'Not now');
  }
  expect(titled(_screens[index].title), findsOneWidget);
  return actions;
}

/// The channels a widget test's framework may use on its own.
bool _frameworkMessage((String, String?) message) {
  final (channel, method) = message;
  if (channel == SystemChannels.platform.name) {
    return method != null &&
        (method.startsWith('HapticFeedback.') ||
            method.startsWith('SystemSound.') ||
            method.startsWith('SystemChrome.'));
  }
  return const {
    'flutter/navigation',
    'flutter/accessibility',
    'flutter/mousecursor',
    'flutter/restoration',
    'flutter/textinput',
    'flutter/keyevent',
  }.contains(channel);
}

void main() {
  testWidgets('TC-005-08 sms explainer buttons go to notifications explainer', (
    tester,
  ) async {
    for (final button in ['Allow SMS access', 'Not now']) {
      await tester.pumpWidget(const SizedBox());
      await _pumpAt(tester, 0);
      final messages = recordPlatformMessages(tester);
      await tapButton(tester, button);
      expect(titled(notificationsTitle), findsOneWidget, reason: button);
      expect(messages.where((m) => !_frameworkMessage(m)), isEmpty);
    }
  });

  testWidgets('TC-005-10 notifications explainer buttons go to disclaimer', (
    tester,
  ) async {
    for (final button in ['Turn on notifications', 'Not now']) {
      await tester.pumpWidget(const SizedBox());
      await _pumpAt(tester, 1);
      final messages = recordPlatformMessages(tester);
      await tapButton(tester, button);
      expect(titled(disclaimerTitle), findsOneWidget, reason: button);
      expect(messages.where((m) => !_frameworkMessage(m)), isEmpty);
    }
  });

  testWidgets('TC-005-31 explainer buttons send no platform requests', (
    tester,
  ) async {
    for (final (screen, button) in [
      (0, 'Allow SMS access'),
      (0, 'Not now'),
      (1, 'Turn on notifications'),
      (1, 'Not now'),
    ]) {
      await tester.pumpWidget(const SizedBox());
      await _pumpAt(tester, screen);
      final messages = recordPlatformMessages(tester);
      await tapButton(tester, button);
      final unexpected = messages.where((m) => !_frameworkMessage(m));
      expect(unexpected, isEmpty, reason: '$button: $unexpected');
      // Nothing that asks for a permission or opens system settings.
      expect(
        messages.where(
          (m) =>
              (m.$2 ?? '').toLowerCase().contains('permission') ||
              m.$1.toLowerCase().contains('permission'),
        ),
        isEmpty,
        reason: button,
      );
    }
  });

  testWidgets('TC-005-13 i understand reports finish once (screen level)', (
    tester,
  ) async {
    final actions = await _pumpAt(tester, 2);
    // Exactly one button and no Skip.
    expect(find.byType(BudgetButton), findsOneWidget);
    expect(find.text('I understand'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    expect(actions.finishCalls, 0);
    await tapButton(tester, 'I understand');
    expect(find.byKey(homeStandIn), findsOneWidget);
    expect(titled(disclaimerTitle), findsNothing);
    expect(actions.finishCalls, 1);
    // Every onboarding route is gone: Home is the root.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse);
  });

  testWidgets('TC-005-14 back walks the explainers (screen level)', (
    tester,
  ) async {
    final pops = recordSystemPops(tester);
    final actions = await _pumpAt(tester, 2);
    await pressBack(tester);
    expect(titled(notificationsTitle), findsOneWidget);
    await pressBack(tester);
    expect(titled(smsTitle), findsOneWidget);
    expect(pops(), 0);
    await pressBack(tester);
    expect(pops(), 1, reason: 'back on the SMS explainer leaves the app');
    expect(actions.finishCalls, 0);
    expect(actions.completeTourCalls, 0);
  });

  testWidgets('TC-005-18 double tap advances exactly one screen', (
    tester,
  ) async {
    final pops = recordSystemPops(tester);
    // Two taps 50 ms apart on the same spot, whatever is there by then.
    Future<void> doubleTap(String label) async {
      await tester.pump(kDoubleTapTimeout);
      final at = tester.getCenter(find.text(label));
      await tester.tapAt(at);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(at);
      await tester.pumpAndSettle();
    }

    for (final (screen, button, next) in [
      (0, 'Allow SMS access', notificationsTitle),
      (0, 'Not now', notificationsTitle),
      (1, 'Turn on notifications', disclaimerTitle),
      (1, 'Not now', disclaimerTitle),
    ]) {
      await tester.pumpWidget(const SizedBox());
      final routes = RouteCounter();
      await _pumpAt(tester, screen, routes: routes);
      final before = routes.count;
      await doubleTap(button);
      expect(titled(next), findsOneWidget, reason: button);
      expect(routes.count, before + 1, reason: '$button: one screen');
      await pressBack(tester);
      expect(titled(_screens[screen].title), findsOneWidget, reason: button);
    }

    // I understand: Home once; back from Home leaves the app.
    await tester.pumpWidget(const SizedBox());
    final actions = await _pumpAt(tester, 2);
    await doubleTap('I understand');
    expect(find.byKey(homeStandIn), findsOneWidget);
    expect(actions.finishCalls, 1);
    final popsBefore = pops();
    await pressBack(tester);
    expect(pops(), popsBefore + 1);
  });

  testWidgets('TC-005-20 onboarding reading order is title body position '
      'buttons', (tester) async {
    final semantics = tester.ensureSemantics();
    for (final (index, screen) in _screens.indexed) {
      await tester.pumpWidget(const SizedBox());
      await _pumpAt(tester, index, size: const Size(400, 1000));
      final nodes = tester.semantics
          .simulatedAccessibilityTraversal()
          .where((node) => node.getSemanticsData().label.isNotEmpty)
          .toList();
      expect(nodes.map((node) => node.getSemanticsData().label).toList(), [
        screen.title,
        ...screen.points,
        ...screen.buttons.map((b) => b.$1),
      ], reason: screen.title);
      // Each button carries its description or hint.
      for (final (label, hint) in screen.buttons) {
        expect(
          nodes.firstWhere((n) => n.getSemanticsData().label == label),
          isSemantics(label: label, hint: hint, isButton: true),
          reason: label,
        );
      }
      // The title is a heading.
      expect(nodes.first, isSemantics(isHeader: true, label: screen.title));
    }
    semantics.dispose();
  });

  testWidgets('TC-004-06 explainer copy matches F-005 §5', (tester) async {
    for (final (index, screen) in _screens.indexed) {
      await tester.pumpWidget(const SizedBox());
      await _pumpAt(tester, index);
      for (final point in screen.points) {
        expect(find.text(point), findsOneWidget, reason: point);
      }
      for (final (label, _) in screen.buttons) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      if (screen.description case final description?) {
        expect(find.text(description), findsOneWidget);
      }
    }
  });

  testWidgets('TC-005-19 onboarding screens fit at text scale 2', (
    tester,
  ) async {
    // 1.0 first: a text scale set in a test stays until the test ends.
    for (final scale in [1.0, 2.0]) {
      for (final (index, screen) in _screens.indexed) {
        final where = '${screen.title} at $scale';
        await tester.pumpWidget(const SizedBox());
        await _pumpAt(tester, index, size: kSmallPhone, textScale: scale);
        expectNoOverflow(tester, reason: where);
        final scroll = find.byType(SingleChildScrollView);
        final buttonsScroll = find.descendant(
          of: scroll,
          matching: find.text(screen.buttons.first.$1),
        );
        if (scale == 1) {
          // Up to 1.3× the button block is pinned below the scroll view.
          expect(buttonsScroll, findsNothing, reason: where);
          expect(
            find.text(screen.buttons.first.$1).hitTestable(),
            findsOneWidget,
            reason: where,
          );
        } else {
          // Above 1.3× it ends the scrolling content, which opens at the top.
          expect(buttonsScroll, findsOneWidget, reason: where);
          expect(
            tester.getTopLeft(find.text(screen.title)).dy,
            lessThan(kSmallPhone.height / 2),
            reason: where,
          );
        }
        // All text and every button can be scrolled into view and tapped.
        for (final text in [
          screen.title,
          ...screen.points,
          ?screen.description,
        ]) {
          await tester.ensureVisible(find.text(text));
          await tester.pumpAndSettle();
          expect(find.text(text).hitTestable(), findsOneWidget, reason: text);
        }
        for (final (label, _) in screen.buttons) {
          await tester.ensureVisible(find.text(label));
          await tester.pumpAndSettle();
          expect(find.text(label).hitTestable(), findsOneWidget, reason: label);
        }
      }
    }
  });

  for (final theme in ThemeCase.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('TC-005-19 explainers pass the accessibility checks '
          '(${theme.name}, $scale)', (tester) async {
        for (final (index, screen) in _screens.indexed) {
          await tester.pumpWidget(const SizedBox());
          await _pumpAt(
            tester,
            index,
            theme: theme,
            size: kSmallPhone,
            textScale: scale,
          );
          await expectAccessible(tester, reason: screen.title);
          expect(pageBackground(tester), theme.colors.bg.toARGB32());
        }
      });
    }
  }
}
