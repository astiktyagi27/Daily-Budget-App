import 'dart:io';

import 'package:daily_budget/features/home/widgets/collapsed_summary_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/home/home_harness.dart';
import '../helpers/phase3_fixtures.dart';
import '../helpers/shell.dart';
import '../support/find_copy.dart';

// F-017 AC-10: the figure is a guide on Home's summary card only.

List<File> _dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

String _path(File f) => f.path.replaceAll(r'\', '/');

void main() {
  test('TC-017-23 the figure is referenced only by the home summary files', () {
    // The only files that may name the function or the strip.
    const allowed = {
      'lib/domain/budget/safe_to_spend.dart',
      'lib/domain/budget/budget.dart',
      'lib/features/home/home_state.dart',
      'lib/features/home/widgets/safe_to_spend_strip.dart',
      'lib/features/home/widgets/summary_card.dart',
    };
    final names = RegExp(
      'safeToSpendPerDay|safeToSpendFrom|SafeToSpendStrip|SafeToSpendAmount',
    );
    final offenders = [
      for (final file in _dartFiles('lib'))
        if (names.hasMatch(file.readAsStringSync()) &&
            !allowed.contains(_path(file)))
          _path(file),
    ];
    expect(offenders, isEmpty);
    // The guard can fail: the home state is one of the files it allows.
    expect(
      File('lib/features/home/home_state.dart')
          .readAsStringSync()
          .contains('safeToSpendPerDay'),
      isTrue,
    );
  });

  testWidgets('TC-017-23 safe to spend appears only on the home summary card', (
    tester,
  ) async {
    await openFixture(tester, a13);
    expect(findCopy('Safe to spend'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('today-line')),
        matching: find.textContaining('Safe to spend'),
      ),
      findsNothing,
    );

    // Scrolled: the pinned row does not carry it.
    for (var step = 0; step < 4; step++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    expect(find.byType(CollapsedSummaryRow), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CollapsedSummaryRow),
        matching: find.textContaining('Safe', findRichText: true),
      ),
      findsNothing,
    );

    // Other tabs.
    for (final tab in ['Transactions', 'Dashboard']) {
      await tapTab(tester, tab);
      expect(findCopy('Safe to spend'), findsNothing, reason: tab);
    }
    await tapTab(tester, 'Home');
    expect(findCopy('Safe to spend'), findsOneWidget);
  });
}
