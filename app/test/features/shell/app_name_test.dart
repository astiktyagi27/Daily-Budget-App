import 'dart:io';

import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/shell.dart';

const _appName = 'Daily Budget App';

List<File> _dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

void main() {
  testWidgets('TC-003-13 app title is daily budget app', (tester) async {
    await pumpShell(tester);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      _appName,
    );
    expect(pageTitle(_appName), findsOneWidget);

    // The Android launcher label (AC-10); tests run from app/.
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    final labels = RegExp('android:label="([^"]*)"')
        .allMatches(manifest)
        .map((m) => m.group(1))
        .toList();
    expect(labels, [_appName]);
  });

  test('TC-003-15 phase 0 placeholder is gone from the source', () {
    // Built from pieces so this file does not match itself.
    const screen = 'Screen';
    const soon = 'Your daily budget will appear here soon.';
    const patterns = ['Placeholder$screen', 'Setting things up. $soon'];
    final hits = [
      for (final file in [..._dartFiles('lib'), ..._dartFiles('test')])
        for (final pattern in patterns)
          if (file.readAsStringSync().contains(pattern))
            '${file.path}: $pattern',
    ];
    expect(hits, isEmpty, reason: hits.join('\n'));
    expect(Directory('lib/features/placeholder').existsSync(), isFalse);
    expect(Directory('test/features/placeholder').existsSync(), isFalse);
  });

  testWidgets('TC-003-08 app always reopens on home', (tester) async {
    final store = InMemoryPreferencesStore();
    await pumpShell(tester, store: store, size: kSmallPhone, textScale: 2);
    await tapTab(tester, 'Settings');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(visiblePagePosition(tester).pixels, greaterThan(0));

    // Restart (sim): a new app on a new store sharing only the saved values.
    await tester.pumpWidget(const SizedBox());
    await pumpBudgetApp(
      tester,
      store: InMemoryPreferencesStore(store.values),
      seedTheme: false,
      size: kSmallPhone,
      textScale: 2,
    );
    expect(pageTitle(_appName), findsOneWidget);
    expect(
      tester
          .getSemantics(navItem('Home'))
          .flagsCollection
          .isSelected
          .toBoolOrNull(),
      isTrue,
    );
    expect(visiblePagePosition(tester).pixels, 0);

    await tapTab(tester, 'Settings');
    expect(visiblePagePosition(tester).pixels, 0, reason: 'not restored');
  });

  testWidgets('TC-003-17 reading order is top bar body then navigation', (
    tester,
  ) async {
    const nav = [
      'Home, tab 1 of 4',
      'Dashboard, tab 2 of 4',
      'Transactions, tab 3 of 4',
      'Settings, tab 4 of 4',
    ];
    // F-003 §5 copy; Coming soon rows read `<Label>, coming soon, not
    // available yet. <Description>`.
    String soon(String label, String description) =>
        '$label, coming soon, not available yet. $description';
    const homeText =
        'Your daily budget lives here. Tell us your salary and fixed costs, '
        "and we'll work out what you can spend each day.";
    const dashboardText =
        'Set up your month first. Your spends need a budget month. It takes a '
        'minute.';
    const transactionsText =
        'Set up your month first. Your spends need a budget month. It takes a '
        'minute.';
    final bodies = {
      'Home': ['Daily Budget App', homeText, 'Set up your month'],
      'Dashboard': ['Dashboard', dashboardText, 'Set up your month'],
      'Transactions': ['Transactions', transactionsText, 'Set up your month'],
      'Settings': [
        'Settings',
        'General',
        'Theme. Light',
        'More about Theme',
        soon('Notifications', 'Budget warnings and an end-of-day summary'),
        'Money',
        soon('Bank account', 'The one bank account the app tracks'),
        soon('Salary date', 'The day your budget month starts'),
        soon('Categories', 'How your spends are grouped, like Food or Travel'),
        'Privacy & help',
        soon(
          'Privacy & data',
          'Your data stays on this phone. Manage or delete it here.',
        ),
        soon('How this app works', 'A short guide to daily budgets and saving'),
        soon('Disclaimer', "What the app can and can't track"),
      ],
    };
    final semantics = tester.ensureSemantics();
    // Tall enough that the whole Settings list is on screen.
    await pumpShell(tester, size: const Size(400, 1800));
    for (final MapEntry(key: tab, value: body) in bodies.entries) {
      await tapTab(tester, tab);
      final expected = [...body, ...nav];
      final read = tester.semantics
          .simulatedAccessibilityTraversal()
          .map((node) => node.getSemanticsData().label)
          .where(expected.contains)
          .toList();
      expect(read, expected, reason: tab);
    }
    semantics.dispose();
  });
}
