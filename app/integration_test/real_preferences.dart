import 'package:daily_budget/app.dart';
import 'package:daily_budget/core/providers/preferences_providers.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/data/preferences/preferences_store.dart';
import 'package:daily_budget/data/preferences/shared_preferences_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Removes every key the app stores from the real device store, so a test
/// starts as a fresh install and leaves nothing behind.
Future<void> clearRealPreferences() =>
    SharedPreferencesAsync().clear(allowList: PreferenceKeys.allowList);

/// A new store instance on the real plugin, as after a process restart.
Future<PreferencesStore> openRealStore() => SharedPreferencesStore.open();

/// Disposes the whole app, then pumps a new one on a store freshly opened
/// from the real plugin (the same steps as `main()`); only the device store
/// survives. Returns after the first frame; pass [settle] to wait for
/// animations as well.
Future<PreferencesStore> restartOnRealStore(
  WidgetTester tester, {
  bool settle = false,
}) async {
  await tester.pumpWidget(const SizedBox());
  final store = await openRealStore();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [preferencesStoreProvider.overrideWithValue(store)],
      child: const DailyBudgetApp(),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return store;
}

/// Waits until a read of a freshly opened real store returns [expected]
/// (writes are asynchronous), or fails after about 5 seconds.
Future<void> expectSavedString(String key, String expected) async {
  for (var i = 0; i < 50; i++) {
    final store = await openRealStore();
    if (store.readString(key) == expected) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  fail('$key was not saved as $expected');
}

/// As [expectSavedString] for a bool flag.
Future<void> expectSavedBool(String key, {required bool expected}) async {
  for (var i = 0; i < 50; i++) {
    final store = await openRealStore();
    if (store.readBool(key) == expected) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  fail('$key was not saved as $expected');
}
