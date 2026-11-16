import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/data/preferences/preferences_store.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/failing_preferences_store.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/shell.dart';
import 'onboarding_host.dart';

// The whole app on a store, as `main()` starts it (test cases §0
// "FakeStore", "Restart (sim)"). Literals from F-005 §5, F-003 and F-004 §5.

const _tourSeen = 'onboarding.tour_seen';
const _finished = 'onboarding.finished';

const _tabContent = [
  'Daily Budget App',
  'Dashboard',
  'Transactions',
  'Settings',
  'Your daily budget lives here',
  'Insights are on their way',
  'Set up your month first',
];

const _homeHint =
    "Use the tabs at the bottom to move around. Home is where you'll check "
    "today's budget each day.";

InMemoryPreferencesStore _store([Map<String, Object> values = const {}]) =>
    InMemoryPreferencesStore.allowing(PreferenceKeys.allowList, values);

/// Pumps the app on [store] with onboarding as saved there (not seeded).
Future<void> _pump(
  WidgetTester tester,
  PreferencesStore store, {
  bool settle = true,
  bool disableAnimations = false,
}) => pumpBudgetApp(
  tester,
  store: store,
  seedTheme: false,
  onboarded: false,
  size: kSmallPhone,
  disableAnimations: disableAnimations,
  settle: settle,
);

/// Restart (sim): a new app on a new store sharing [store]'s values.
Future<void> _restart(WidgetTester tester, InMemoryPreferencesStore store) =>
    restartApp(tester, _store(store.values), onboarded: false, settle: true);

void _expectHome(WidgetTester tester, {String? reason}) {
  expect(navBar, findsOneWidget, reason: reason);
  expect(selectedTab(tester), 'Home', reason: reason);
  for (final title in [...slideTitles, smsTitle, notificationsTitle]) {
    expect(find.text(title), findsNothing, reason: reason);
  }
  expect(find.text(disclaimerTitle), findsNothing, reason: reason);
}

void _expectSlide1(WidgetTester tester, {String? reason}) {
  expect(find.text(slideTitles.first), findsOneWidget, reason: reason);
  expect(navBar, findsNothing, reason: reason);
}

void _expectSms(WidgetTester tester, {String? reason}) {
  expect(find.text(smsTitle), findsOneWidget, reason: reason);
  expect(find.text(slideTitles.first), findsNothing, reason: reason);
  expect(navBar, findsNothing, reason: reason);
}

void _expectNoErrorUi(WidgetTester tester, String reason) {
  expect(tester.takeException(), isNull, reason: reason);
  for (final type in [ErrorWidget, AlertDialog, SnackBar, MaterialBanner]) {
    expect(find.byType(type), findsNothing, reason: '$reason: $type');
  }
}

Future<void> _next(WidgetTester tester) async {
  await tapButton(tester, 'Next');
  await tester.pump(kDoubleTapTimeout);
}

/// Taps through to the disclaimer from slide 1 with Skip, Not now, Not now.
Future<void> _toDisclaimer(WidgetTester tester) async {
  await tapButton(tester, 'Skip');
  await tapButton(tester, 'Not now');
  await tapButton(tester, 'Not now');
  expect(find.text(disclaimerTitle), findsOneWidget);
}

/// Counts writes of the onboarding flags.
final class _CountingStore implements PreferencesStore {
  final InMemoryPreferencesStore inner = _store();
  final writes = <String, int>{};

  @override
  bool? readBool(String key) => inner.readBool(key);

  @override
  String? readString(String key) => inner.readString(key);

  @override
  Future<bool> writeBool(String key, {required bool value}) {
    writes.update(key, (n) => n + 1, ifAbsent: () => 1);
    return inner.writeBool(key, value: value);
  }

  @override
  Future<bool> writeString(String key, String value) =>
      inner.writeString(key, value);

  @override
  Future<bool> remove(String key) => inner.remove(key);
}

void main() {
  testWidgets('TC-005-01 fresh install opens the tour without tabs', (
    tester,
  ) async {
    await _pump(tester, _store(), settle: false);
    // 1. The very first frame.
    _expectSlide1(tester, reason: 'first frame');
    for (final text in _tabContent) {
      expect(find.text(text), findsNothing, reason: 'first frame: $text');
    }
    // 2. Settled.
    await tester.pumpAndSettle();
    _expectSlide1(tester, reason: 'settled');
    for (final text in _tabContent) {
      expect(find.text(text), findsNothing, reason: 'settled: $text');
    }
    // 3. No bottom navigation on any of the 7 onboarding screens.
    for (var i = 1; i < 4; i++) {
      await _next(tester);
      expect(find.text(slideTitles[i]), findsOneWidget);
      expect(navBar, findsNothing, reason: slideTitles[i]);
    }
    await tapButton(tester, 'Get started');
    for (final (title, button) in [
      (smsTitle, 'Not now'),
      (notificationsTitle, 'Not now'),
      (disclaimerTitle, null),
    ]) {
      expect(find.text(title), findsOneWidget);
      expect(navBar, findsNothing, reason: title);
      if (button != null) await tapButton(tester, button);
    }
  });

  testWidgets('TC-005-04 get started saves tour seen and opens sms explainer', (
    tester,
  ) async {
    final store = _store();
    await _pump(tester, store);
    for (var i = 0; i < 3; i++) {
      await _next(tester);
    }
    expect(store.values, isEmpty, reason: 'moving through saves nothing');
    await tapButton(tester, 'Get started');
    _expectSms(tester);
    expect(store.values[_tourSeen], isTrue);
    expect(store.values.containsKey(_finished), isFalse);
  });

  testWidgets('TC-005-05 skip on any slide opens sms explainer', (
    tester,
  ) async {
    for (var slide = 0; slide < 3; slide++) {
      await tester.pumpWidget(const SizedBox());
      final store = _store();
      await _pump(tester, store);
      for (var i = 0; i < slide; i++) {
        await _next(tester);
      }
      await tapButton(tester, 'Skip');
      _expectSms(tester, reason: 'skip on slide ${slide + 1}');
      expect(store.values[_tourSeen], isTrue, reason: '${slide + 1}');
      expect(store.values.containsKey(_finished), isFalse);
    }
  });

  testWidgets('TC-005-06 leaving the tour early saves nothing', (tester) async {
    final pops = recordSystemPops(tester);
    // 1. Back on slide 1 leaves the app.
    final store = _store();
    await _pump(tester, store);
    await pressBack(tester);
    expect(pops(), 1);
    expect(tester.takeException(), isNull);
    expect(store.values, isEmpty);
    // 2. Restart: slide 1.
    await _restart(tester, store);
    _expectSlide1(tester, reason: 'after back');
    // 3. Stopped on slides 2, 3 and 4: slide 1 again.
    for (var slide = 1; slide < 4; slide++) {
      await tester.pumpWidget(const SizedBox());
      final run = _store();
      await _pump(tester, run);
      for (var i = 0; i < slide; i++) {
        await _next(tester);
      }
      expect(find.text(slideTitles[slide]), findsOneWidget);
      await _restart(tester, run);
      _expectSlide1(tester, reason: 'stopped on slide ${slide + 1}');
      expect(run.values, isEmpty);
    }
  });

  testWidgets('TC-005-13 i understand finishes onboarding and opens home', (
    tester,
  ) async {
    final store = _store();
    await _pump(tester, store);
    await _toDisclaimer(tester);
    // 1. Exactly one button; no Skip.
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.text('I understand'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    expect(store.values.containsKey(_finished), isFalse);
    // 2. Home with the bottom navigation and its hint.
    await tapButton(tester, 'I understand');
    _expectHome(tester);
    expect(find.text(_homeHint), findsOneWidget);
    expect(store.values[_finished], isTrue);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator).first).canPop(),
      isFalse,
      reason: 'Home is the root',
    );
  });

  testWidgets('TC-005-14 back walks the explainers then resumes at sms', (
    tester,
  ) async {
    final pops = recordSystemPops(tester);
    final store = _store();
    await _pump(tester, store);
    await _toDisclaimer(tester);
    await pressBack(tester);
    expect(find.text(notificationsTitle), findsOneWidget);
    await pressBack(tester);
    _expectSms(tester);
    expect(pops(), 0);
    await pressBack(tester);
    expect(pops(), 1);
    await _restart(tester, store);
    _expectSms(tester, reason: 'after restart: SMS explainer, not the tour');
  });

  testWidgets('TC-005-15 app opens on the right screen for each saved state', (
    tester,
  ) async {
    await _pump(tester, _store());
    _expectSlide1(tester);

    await tester.pumpWidget(const SizedBox());
    await _pump(tester, _store({_tourSeen: true}));
    _expectSms(tester);

    final finished = _store({_tourSeen: true, _finished: true});
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, finished);
    _expectHome(tester, reason: 'launch');
    for (var i = 1; i <= 3; i++) {
      await _restart(tester, finished);
      _expectHome(tester, reason: 'restart $i');
    }
  });

  testWidgets('TC-005-18 double tap advances exactly one screen', (
    tester,
  ) async {
    // I understand → Home with the real Home (condition C4, D-044): the
    // second tap must not land on the bottom bar.
    final pops = recordSystemPops(tester);
    for (final animationsOff in [false, true]) {
      final why = animationsOff ? 'remove animations' : 'animations on';
      await tester.pumpWidget(const SizedBox());
      final store = _CountingStore();
      await _pump(tester, store, disableAnimations: animationsOff);
      await _toDisclaimer(tester);
      await tester.pump(kDoubleTapTimeout);
      final at = tester.getCenter(find.text('I understand'));
      await tester.tapAt(at);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(at);
      await tester.pumpAndSettle();
      _expectHome(tester, reason: why);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator).first).canPop(),
        isFalse,
        reason: '$why: no route pushed',
      );
      expect(store.writes[_finished], 1, reason: '$why: saved once');
      // The second tap fell where the bar is now.
      expect(tester.getRect(navBar).contains(at), isTrue, reason: why);

      // One back from Home leaves the app.
      final before = pops();
      await pressBack(tester);
      expect(pops(), before + 1, reason: why);

      // After the guard, a tab tap works.
      await tester.pump(kDoubleTapTimeout);
      await tapTab(tester, 'Dashboard');
      expect(selectedTab(tester), 'Dashboard', reason: why);
    }
  });

  testWidgets('TC-005-22 onboarding storage failure is safe', (tester) async {
    // (a) Nothing can be saved: Home this session, a known screen next time.
    final store = FailingPreferencesStore(writeFails: true);
    await _pump(tester, store);
    await _toDisclaimer(tester);
    await tapButton(tester, 'I understand');
    _expectHome(tester, reason: 'writeFails');
    _expectNoErrorUi(tester, 'writeFails');
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, FailingPreferencesStore(values: store.values));
    _expectSlide1(tester, reason: 'after restart');
    _expectNoErrorUi(tester, 'after restart');

    // (b) Nothing can be read: slide 1.
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, FailingPreferencesStore(readFails: true));
    _expectSlide1(tester, reason: 'readFails');
    _expectNoErrorUi(tester, 'readFails');
  });

  testWidgets('TC-005-27 corrupt onboarding flags open a valid screen', (
    tester,
  ) async {
    final cases = <(Map<String, Object>, String)>[
      ({_tourSeen: 'maybe'}, 'slide 1'),
      ({_tourSeen: 7}, 'slide 1'),
      ({_tourSeen: true, _finished: 'true'}, 'sms'),
      ({_tourSeen: true, _finished: ''}, 'sms'),
      ({_finished: 'true'}, 'slide 1'),
      ({_finished: true}, 'home'),
    ];
    for (final (values, expected) in cases) {
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, _store(values));
      final why = '$values';
      _expectNoErrorUi(tester, why);
      switch (expected) {
        case 'slide 1':
          _expectSlide1(tester, reason: why);
        case 'sms':
          _expectSms(tester, reason: why);
        default:
          _expectHome(tester, reason: why);
      }
    }
  });
}
