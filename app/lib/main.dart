import 'package:daily_budget/app.dart';
import 'package:daily_budget/core/providers/preferences_providers.dart';
import 'package:daily_budget/core/theme/font_licenses.dart';
import 'package:daily_budget/data/preferences/shared_preferences_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  // Opened before the first frame, so the saved theme is used from frame one.
  // Falls back to an in-memory store if the device store cannot be opened.
  final store = await openPreferencesStore();
  runApp(
    ProviderScope(
      overrides: [preferencesStoreProvider.overrideWithValue(store)],
      child: const DailyBudgetApp(),
    ),
  );
}
