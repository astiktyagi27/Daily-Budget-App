import 'package:daily_budget/core/widgets/budget_list_row.dart';
import 'package:daily_budget/core/widgets/budget_sheet.dart';
import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/data/preferences/preferences_store.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:daily_budget/features/settings/theme/theme_picker_sheet.dart';
import 'package:daily_budget/features/shell/budget_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';
import 'theme_cases.dart';

/// Pumps the whole app, which opens on the shell (F-003), in [theme], on
/// [store] (a fresh in-memory store by default).
///
/// The four first-time hints are saved as dismissed first, unless
/// [hintsSeen] is false (F-003 test cases §0: the shell cases run without
/// hints; F-004 tests the hints).
Future<void> pumpShell(
  WidgetTester tester, {
  ThemeCase theme = ThemeCase.light,
  Size? size,
  double textScale = 1,
  PreferencesStore? store,
  bool seedTheme = true,
  bool hintsSeen = true,
}) async {
  final preferences =
      store ?? InMemoryPreferencesStore.allowing(PreferenceKeys.allowList);
  if (hintsSeen) {
    for (final id in HintId.values) {
      await preferences.writeBool(PreferenceKeys.hintSeen(id), value: true);
    }
  }
  await pumpBudgetApp(
    tester,
    theme: theme,
    size: size,
    textScale: textScale,
    store: preferences,
    seedTheme: seedTheme,
  );
}

/// The bottom bar.
Finder get navBar => find.byType(BudgetNavigationBar);

/// The tappable slot of the tab labelled [label] in the bottom bar.
Finder navItem(String label) => find
    .ancestor(
      of: find.descendant(of: navBar, matching: find.text(label)),
      matching: find.byType(InkWell),
    )
    .first;

/// Taps a tab in the bottom bar and waits for the switch to finish.
Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(navItem(label));
  await tester.pumpAndSettle();
}

/// The title header of the tab on screen.
Finder pageTitle(String title) => find.descendant(
  of: find.byType(CustomScrollView),
  matching: find.text(title),
);

/// The scroll position of the visible tab page.
ScrollPosition visiblePagePosition(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position;

/// Records `SystemNavigator.pop` calls (test cases F-003 §0 "Back").
/// Returns a getter for the count; the mock is removed after the test.
int Function() recordSystemPops(WidgetTester tester) {
  var pops = 0;
  final messenger = tester.binding.defaultBinaryMessenger
    ..setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemNavigator.pop') pops++;
      return null;
    });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return () => pops;
}

/// The page background on screen (the shell `Scaffold`'s own Material).
int pageBackground(WidgetTester tester) => tester
    .widgetList<Material>(
      find.descendant(
        of: find.byType(Scaffold),
        matching: find.byType(Material),
      ),
    )
    .first
    .color!
    .toARGB32();

/// The fill of the bottom bar.
Color navBarFill(WidgetTester tester) => tester
    .widget<Material>(
      find.descendant(of: navBar, matching: find.byType(Material)).first,
    )
    .color!;

/// Settings → Theme.
Finder get themeRow => find.widgetWithText(BudgetListRow, 'Theme');

/// The theme picker sheet.
Finder get themePicker => find.byType(ThemePickerSheet);

/// The option labelled [label] (`Auto`, `Light`, `Dark`, `Dim`) in the
/// open picker.
Finder pickerOption(String label) =>
    find.descendant(of: themePicker, matching: find.text(label));

/// Opens the picker from the Settings tab on screen by tapping the Theme
/// row (its chevron, well away from the (i)).
Future<void> openThemePicker(WidgetTester tester) async {
  // Below a first-time hint at large text the row starts off screen.
  await tester.scrollUntilVisible(
    themeRow,
    200,
    scrollable: find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.ensureVisible(themeRow);
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: themeRow, matching: find.byIcon(Icons.chevron_right)),
  );
  await tester.pumpAndSettle();
}

/// Taps the option [label] in the open picker and waits for the theme to
/// settle. The picker stays open.
Future<void> pickTheme(WidgetTester tester, String label) async {
  await tester.tap(pickerOption(label));
  await tester.pumpAndSettle();
}

/// Closes the open picker with its Done button.
Future<void> closeThemePicker(WidgetTester tester) async {
  await tester.tap(
    find.descendant(of: themePicker, matching: find.text('Done')),
  );
  await tester.pumpAndSettle();
}

/// The decoration the open sheet draws (fill, corners, shadow).
BoxDecoration sheetDecoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(BudgetSheetFrame),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

/// The tab on screen, by its bar label.
String selectedTab(WidgetTester tester) => const [
  'Home',
  'Dashboard',
  'Transactions',
  'Settings',
][tester.widget<IndexedStack>(find.byType(IndexedStack)).index!];
