import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/p1_screens.dart';

// F-004 AC-5: every control has a label plus a description, an (i) or a
// tooltip/hint. Expected controls are test cases F-004 §1.2, written as
// literals from the §5 tables of F-002…F-005 (never the app's own copy).

/// One expected tap target: its screen-reader label and hint.
typedef _Control = ({String label, String hint});

const List<_Control> _nav = [
  (label: 'Home, tab 1 of 4', hint: "Today's budget and your calendar"),
  (label: 'Dashboard, tab 2 of 4', hint: 'Where your money goes'),
  (label: 'Transactions, tab 3 of 4', hint: 'Every spend and credit'),
  (label: 'Settings, tab 4 of 4', hint: 'Theme and app options'),
];
const List<_Control> _hint = [
  (label: 'Got it', hint: "Dismiss this tip. It won't show again."),
  (label: 'Dismiss tip', hint: ''),
];
// The (i) has no hint: its label `More about Theme` is the help (§1.2).
const List<_Control> _settingsRows = [
  (label: 'Theme. Light', hint: 'Opens theme options'),
  (label: 'More about Theme', hint: ''),
];
const List<_Control> _slides123 = [
  (label: 'Next', hint: 'Go to the next slide'),
  (label: 'Skip', hint: 'Skip the tour and continue setup'),
];

/// The modal route's own dismiss node over the scrim (label `Close` since
/// T-233, tap hint `Close Bottom Sheet`, review F4-2): allowed once on the
/// two sheets, nowhere else.
const _scrimLabel = 'Close';

const Map<P1Screen, List<_Control>> _expected = {
  P1Screen.home: _nav,
  P1Screen.dashboard: _nav,
  P1Screen.transactions: _nav,
  P1Screen.settings: [..._settingsRows, ..._nav],
  P1Screen.settingsEnd: [..._settingsRows, ..._nav],
  P1Screen.themePicker: [
    (label: "Auto. Matches your phone's light or dark setting", hint: ''),
    (label: 'Light. Bright and clean', hint: ''),
    (label: 'Dark. True dark, best at night', hint: ''),
    (label: 'Dim. Soft warm grey, easy on the eyes', hint: ''),
    (label: 'Done', hint: 'Close theme options'),
  ],
  P1Screen.themeExplanation: [
    (label: 'Got it', hint: 'Close this explanation'),
  ],
  P1Screen.homeWithHint: [..._hint, ..._nav],
  P1Screen.dashboardWithHint: [..._hint, ..._nav],
  P1Screen.transactionsWithHint: [..._hint, ..._nav],
  P1Screen.settingsWithHint: [..._hint, ..._settingsRows, ..._nav],
  P1Screen.slide1: _slides123,
  P1Screen.slide2: _slides123,
  P1Screen.slide3: _slides123,
  P1Screen.slide4: [
    (label: 'Get started', hint: 'Finish the tour and continue setup'),
  ],
  P1Screen.smsExplainer: [
    (
      label: 'Allow SMS access',
      hint: 'You can still add spends yourself if you say no.',
    ),
    (label: 'Not now', hint: 'Continue without SMS access for now'),
  ],
  P1Screen.notificationsExplainer: [
    (
      label: 'Turn on notifications',
      hint:
          'Notifications are created on your phone. Nothing is sent anywhere.',
    ),
    (label: 'Not now', hint: 'Continue without notifications'),
  ],
  P1Screen.disclaimer: [
    (label: 'I understand', hint: 'Finish setup and open the app'),
  ],
};

/// Descriptions that §1.2 says are visible next to their control.
const Map<P1Screen, List<String>> _visibleDescriptions = {
  P1Screen.smsExplainer: ['You can still add spends yourself if you say no.'],
  P1Screen.notificationsExplainer: [
    'Notifications are created on your phone. Nothing is sent anywhere.',
  ],
};

/// The seven Settings placeholder rows: one disabled item each, no tap.
const _comingSoon = {
  'Notifications': 'Budget warnings and an end-of-day summary',
  'Bank account': 'The one bank account the app tracks',
  'Salary date': 'The day your budget month starts',
  'Categories': 'How your spends are grouped, like Food or Travel',
  'Privacy & data': 'Your data stays on this phone. Manage or delete it here.',
  'How this app works': 'A short guide to daily budgets and saving',
  'Disclaimer': "What the app can and can't track",
};

/// Icon-only controls and the bottom tabs also need a long-press tooltip
/// (F-004 §2.3, plan §10 point 4).
const _navTooltips = [
  "Today's budget and your calendar",
  'Where your money goes',
  'Every spend and credit',
  'Theme and app options',
];

void main() {
  testWidgets('TC-004-06 every control has a label plus description or '
      'tooltip', (tester) async {
    final semantics = tester.ensureSemantics();
    for (final screen in P1Screen.values) {
      final where = screen.description;
      // Tall enough that every control of a screen is on it at once, so the
      // traversal lists them all (Light, X1).
      await screen.open(tester, size: const Size(400, 1400));
      final nodes = tester.semantics
          .simulatedAccessibilityTraversal()
          .map((node) => node.getSemanticsData())
          .toList();

      // Every node with a tap action, matched 1-to-1 with §1.2.
      final tappable = nodes.where((d) => d.hasAction(SemanticsAction.tap));
      final found = <_Control>[];
      var scrims = 0;
      for (final data in tappable) {
        expect(data.label, isNotEmpty, reason: '$where: unlabelled control');
        if (data.label == _scrimLabel) {
          scrims++;
          continue;
        }
        found.add((label: data.label, hint: data.hint));
      }
      expect(
        found,
        unorderedEquals(_expected[screen]!),
        reason: '$where: controls (an extra or missing one fails)',
      );
      expect(scrims, screen.isSheet ? 1 : 0, reason: '$where: scrim');
      // A control with no hint must carry its help in its label: the
      // description (`Theme. Light`, picker options) or `More about …`, or
      // be the hint card's × (label = its tooltip, checked below).
      for (final control in found.where((c) => c.hint.isEmpty)) {
        expect(
          control.label.contains('. ') ||
              control.label.startsWith('More about ') ||
              control.label == 'Dismiss tip',
          isTrue,
          reason: '$where: ${control.label} has no description or hint',
        );
      }

      for (final text in _visibleDescriptions[screen] ?? const <String>[]) {
        expect(find.text(text), findsOneWidget, reason: '$where: "$text"');
      }

      // Long-press tooltips on the tabs and the hint card's ×.
      if (!screen.isOnboarding && !screen.isSheet) {
        for (final message in _navTooltips) {
          expect(
            find.byTooltip(message),
            findsOneWidget,
            reason: '$where: tab tooltip "$message"',
          );
        }
      }
      if (_expected[screen]!.any((c) => c.label == 'Dismiss tip')) {
        expect(find.byTooltip('Dismiss tip'), findsOneWidget, reason: where);
      }

      // Settings: the seven disabled Coming soon rows are listed too.
      if (screen == P1Screen.settings || screen == P1Screen.settingsWithHint) {
        for (final MapEntry(key: label, value: description)
            in _comingSoon.entries) {
          final row = nodes.where(
            (d) =>
                d.label ==
                '$label, coming soon, not available yet. $description',
          );
          expect(row, hasLength(1), reason: '$where: $label');
          expect(
            row.single.flagsCollection.isEnabled.toBoolOrNull(),
            isFalse,
            reason: '$where: $label disabled',
          );
        }
      }
    }
    semantics.dispose();
  });
}
