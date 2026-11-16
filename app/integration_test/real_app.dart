import 'dart:io';

import 'package:daily_budget/app.dart';
import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/preferences_providers.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/data/database/database_connection.dart';
import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/data/preferences/preferences_store.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/helpers/pump_app.dart';

/// The real `drift_flutter` opener (background isolate, platform plugins)
/// pointed at [file].
AppDatabase openOnFile(File file) => openAppDatabase(
  executor: openDatabaseConnection(
    databasePath: () async => file.path,
    tempDirectoryPath: () async => file.parent.path,
  ),
);

/// A preferences store with onboarding finished and every first-time tip
/// dismissed, so a flow starts on Home without cards in the way.
Future<PreferencesStore> onboardedPreferences() async {
  final preferences = InMemoryPreferencesStore.allowing(
    PreferenceKeys.allowList,
  );
  for (final id in HintId.values) {
    await preferences.writeBool(PreferenceKeys.hintSeen(id), value: true);
  }
  return OnboardedStore(preferences);
}

/// The whole app on the real database [file], as after a process restart: a
/// new tree and a new `ProviderScope`, only the file (and [store], when it
/// is the real device store) survives. Today is [now].
Future<void> launchOnFile(
  WidgetTester tester,
  File file,
  PreferencesStore store,
  DateTime now,
) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesStoreProvider.overrideWithValue(store),
        databaseOpenerProvider.overrideWithValue(() => openOnFile(file)),
        clockProvider.overrideWithValue(() => now),
      ],
      child: const DailyBudgetApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps real frames until [done] is true (a database answer arrives between
/// frames), or fails after [limit].
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  required String reason,
  Duration limit = const Duration(seconds: 8),
}) async {
  final watch = Stopwatch()..start();
  while (!done()) {
    if (watch.elapsed > limit) fail('Timed out waiting for: $reason');
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}
