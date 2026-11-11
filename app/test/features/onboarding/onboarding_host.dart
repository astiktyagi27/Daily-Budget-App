import 'package:daily_budget/core/theme/budget_theme.dart';
import 'package:daily_budget/core/theme/system_bars.dart';
import 'package:daily_budget/features/onboarding/explainers/sms_explainer_screen.dart';
import 'package:daily_budget/features/onboarding/onboarding_actions.dart';
import 'package:daily_budget/features/onboarding/onboarding_provider.dart';
import 'package:daily_budget/features/onboarding/tour/tour_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/theme_cases.dart';

/// Screen identity (test cases §0): each onboarding screen by its title.
const slideTitles = [
  'Spend a little each day',
  'Your daily budget, worked out',
  'Saved days add up',
  'Private by design',
];
const smsTitle = 'Read your bank SMS';
const notificationsTitle = 'Get gentle nudges';
const disclaimerTitle = 'Before you start';

/// Stands in for Home until the real gate is wired in (T-121).
const homeStandIn = Key('home-stand-in');

/// Where the fake gate starts.
enum FakeStage { tour, explainers, finished }

/// Records what the screens report. Deliberately not idempotent, so the
/// tests can count every call the screens make.
class FakeOnboardingActions extends ChangeNotifier
    implements OnboardingActions {
  new(this.stage);

  FakeStage stage;
  int completeTourCalls = 0;
  int finishCalls = 0;

  @override
  void completeTour() {
    completeTourCalls++;
    stage = FakeStage.explainers;
    notifyListeners();
  }

  @override
  void finish() {
    finishCalls++;
    stage = FakeStage.finished;
    notifyListeners();
  }
}

/// The plan's `AppGate` (F-005 §1 step 3) in miniature: the root page
/// follows the stage, so Skip / Get started replace the tour and
/// I understand ends on "Home".
class FakeGate extends StatelessWidget {
  const new({required this.actions, super.key});

  final FakeOnboardingActions actions;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: actions,
      builder: (context, _) => switch (actions.stage) {
        FakeStage.tour => const TourScreen(),
        FakeStage.explainers => const SmsExplainerScreen(),
        FakeStage.finished => const Scaffold(
          key: homeStandIn,
          body: SizedBox.expand(),
        ),
      },
    );
  }
}

/// Counts the routes on the root navigator.
class RouteCounter extends NavigatorObserver {
  int count = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => count++;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => count--;

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      count--;
}

/// Pumps the onboarding flow behind [FakeGate], starting at [stage], on a
/// small phone unless [size] says otherwise. Returns the fake, to read the
/// reported calls.
///
/// Like `pumpBudgetWidget`, but the fake is provided above `MaterialApp`, as
/// the app's own `ProviderScope` is, so pushed explainer routes see it too.
Future<FakeOnboardingActions> pumpOnboarding(
  WidgetTester tester, {
  FakeStage stage = FakeStage.tour,
  ThemeCase theme = ThemeCase.light,
  Size? size,
  double textScale = 1,
  bool disableAnimations = false,
  RouteCounter? routes,
}) async {
  final actions = FakeOnboardingActions(stage);
  addTearDown(actions.dispose);
  theme.applyTo(tester);
  setUpScreen(
    tester,
    size: size ?? kSmallPhone,
    textScale: textScale,
    disableAnimations: disableAnimations,
  );
  final config = themeConfigFor(theme.choice);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [onboardingActionsProvider.overrideWithValue(actions)],
      child: MaterialApp(
        themeMode: config.mode,
        theme: config.light,
        darkTheme: config.dark,
        builder: (context, child) => SystemBarsStyle(child: child!),
        navigatorObservers: [?routes],
        home: FakeGate(actions: actions),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return actions;
}

/// The title on screen is [title] (the screen identity check).
Finder titled(String title) => find.text(title);

/// Taps the button labelled [label] and settles. Waits a double-tap
/// interval first: a screen ignores taps that soon after it appears.
Future<void> tapButton(WidgetTester tester, String label) async {
  await tester.pump(kDoubleTapTimeout);
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Android back, then settle.
Future<void> pressBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

/// Swipe left / right on the tour (test cases §0), then settle.
Future<void> swipeTour(WidgetTester tester, {required bool forward}) async {
  await tester.drag(find.byType(PageView), Offset(forward ? -300 : 300, 0));
  await tester.pumpAndSettle();
}

/// Records every platform message sent while it is on. Returns the
/// recorded (channel, method) pairs; non-method messages have a null method.
List<(String, String?)> recordPlatformMessages(WidgetTester tester) {
  final messenger = tester.binding.defaultBinaryMessenger;
  final recorded = <(String, String?)>[];
  messenger.allMessagesHandler = (channel, handler, message) {
    String? method;
    if (message != null) {
      try {
        method = const StandardMethodCodec().decodeMethodCall(message).method;
      } on Object {
        try {
          method = const JSONMethodCodec().decodeMethodCall(message).method;
        } on Object {
          method = null;
        }
      }
    }
    recorded.add((channel, method));
    return handler != null
        ? handler(message)
        : messenger.delegate.send(channel, message);
  };
  addTearDown(() => messenger.allMessagesHandler = null);
  return recorded;
}
