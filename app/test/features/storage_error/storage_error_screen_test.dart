import 'package:daily_budget/core/copy/storage_copy.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/features/shell/app_shell.dart';
import 'package:daily_budget/features/storage_error/storage_error_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/failing_preferences_store.dart';
import '../../helpers/fake_app_database.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/theme_cases.dart';

void main() {
  testWidgets(
    'TC-007-16 open failure shows the storage error and recovers on try again',
    (tester) async {
      var failing = true;
      var opens = 0;
      await pumpBudgetApp(
        tester,
        openDatabase: () async {
          opens++;
          if (failing) throw const StorageException(StorageFailureKind.open);
          return FakeAppDatabase();
        },
      );

      expect(find.text(StorageCopy.openErrorTitle), findsOneWidget);
      expect(find.text(StorageCopy.openErrorDescription), findsOneWidget);
      expect(find.text(StorageCopy.tryAgain), findsOneWidget);
      expect(find.byType(StorageErrorScreen), findsOneWidget);
      // No bottom navigation and no tabs behind it.
      expect(find.byType(AppShell), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
      // Exact copy (F-007 section 5).
      expect(StorageCopy.openErrorTitle, "We couldn't open your data");
      expect(
        StorageCopy.openErrorDescription,
        'Your budget data is still on this phone. Try again, and if this '
        'keeps happening, restart your phone.',
      );
      final semantics = tester.getSemantics(find.text(StorageCopy.tryAgain));
      expect(semantics.hint, 'Try to open your data again');
      // A failed open is not retried by itself.
      await tester.pump(const Duration(seconds: 5));
      expect(opens, 1);

      failing = false;
      await tester.tap(find.text(StorageCopy.tryAgain));
      await tester.pumpAndSettle();
      expect(opens, 2);
      expect(find.byType(StorageErrorScreen), findsNothing);
      expect(find.byType(AppShell), findsOneWidget);
    },
  );

  testWidgets(
    'TC-007-15 newer database version shows the error and is left untouched',
    (tester) async {
      await pumpBudgetApp(
        tester,
        openDatabase: () async =>
            throw const StorageException(StorageFailureKind.tooNew),
      );
      expect(find.text(StorageCopy.openErrorTitle), findsOneWidget);
      expect(find.text(StorageCopy.tryAgain), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('TC-007-34 preferences and money storage fail independently', (
    tester,
  ) async {
    // (a) The preferences store fails to read, the database is fine:
    // the shell shows, in the Auto theme (system light).
    await pumpBudgetApp(
      tester,
      store: FailingPreferencesStore(readFails: true),
      seedTheme: false,
    );
    expect(find.byType(StorageErrorScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());

    // (b) The database fails, the preferences are fine (Dim): the storage
    // error shows in Dim.
    final store = InMemoryPreferencesStore.allowing(PreferenceKeys.allowList);
    await pumpBudgetApp(
      tester,
      store: store,
      theme: ThemeCase.dim,
      openDatabase: () async =>
          throw const StorageException(StorageFailureKind.corrupt),
    );
    final colors = tester.element(find.byType(StorageErrorScreen)).budgetColors;
    expect(colors, ThemeCase.dim.colors);
    expect(find.text(StorageCopy.openErrorTitle), findsOneWidget);
  });

  testWidgets(
    'TC-007-45 storage errors do not show file paths or sqlite messages',
    (tester) async {
      await pumpBudgetApp(
        tester,
        openDatabase: () async => throw StorageException.from(
          StateError(r'unable to open C:\data\budget.sqlite: SQLITE_CORRUPT'),
          kind: StorageFailureKind.open,
        ),
      );
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join('\n');
      for (final leaked in [
        'budget.sqlite',
        'SQLITE',
        r'C:\',
        'unable to open',
      ]) {
        expect(texts.contains(leaked), isFalse, reason: leaked);
      }
      expect(texts, contains(StorageCopy.openErrorTitle));
    },
  );
}
