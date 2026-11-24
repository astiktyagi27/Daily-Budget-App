import 'package:daily_budget/features/shell/app_shell.dart';
import 'package:daily_budget/features/shell/app_tab.dart';
import 'package:daily_budget/features/shell/selected_tab_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/shell.dart';

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(AppShell)));

void main() {
  testWidgets('TC-013-04 selected tab starts on Home and follows the bar', (
    tester,
  ) async {
    await pumpShell(tester);
    final container = _container(tester);
    expect(container.read(selectedTabProvider), AppTab.home);

    await tapTab(tester, 'Dashboard');
    expect(container.read(selectedTabProvider), AppTab.dashboard);
    await tapTab(tester, 'Settings');
    expect(container.read(selectedTabProvider), AppTab.settings);
  });

  testWidgets(
    'TC-013-04 writing the selected tab switches the shell without a route',
    (tester) async {
      await pumpShell(tester, size: kSmallPhone);
      final container = _container(tester);
      final navigator = Navigator.of(tester.element(find.byType(AppShell)));

      container.read(selectedTabProvider.notifier).select(AppTab.transactions);
      await tester.pumpAndSettle();

      expect(pageTitle('Transactions'), findsOneWidget);
      expect(pageTitle('Daily Budget App'), findsNothing);
      expect(navigator.canPop(), isFalse, reason: 'no new route');

      // Back on another tab goes Home through the same provider (AC-8).
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(container.read(selectedTabProvider), AppTab.home);
      expect(pageTitle('Daily Budget App'), findsOneWidget);
    },
  );

  testWidgets('TC-013-04 a new session opens on Home again', (tester) async {
    await pumpShell(tester);
    _container(tester)
        .read(selectedTabProvider.notifier)
        .select(AppTab.settings);
    await tester.pumpAndSettle();

    // A new app (new ProviderScope) is a new session (F-003 AC-7).
    await tester.pumpWidget(const SizedBox());
    await pumpShell(tester);
    expect(_container(tester).read(selectedTabProvider), AppTab.home);
    expect(pageTitle('Daily Budget App'), findsOneWidget);
  });
}
