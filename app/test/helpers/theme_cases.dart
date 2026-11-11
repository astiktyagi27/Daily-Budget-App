import 'package:daily_budget/core/theme/budget_colors.dart';
import 'package:daily_budget/domain/preferences/theme_choice.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// "All four themes" as F-002 defines it (test cases §0, T5): Light, Dark,
/// Dim, and Auto under system light and under system dark. Light, Dark and
/// Dim run under system light, so they also prove the choice beats the phone.
enum ThemeCase {
  light(ThemeChoice.light, Brightness.light, BudgetColors.light),
  dark(ThemeChoice.dark, Brightness.light, BudgetColors.dark),
  dim(ThemeChoice.dim, Brightness.light, BudgetColors.dim),
  autoSystemLight(ThemeChoice.auto, Brightness.light, BudgetColors.light),
  autoSystemDark(ThemeChoice.auto, Brightness.dark, BudgetColors.dark);

  new(this.choice, this.systemBrightness, this.colors);

  final ThemeChoice choice;
  final Brightness systemBrightness;

  /// The token set the screen must show in this case.
  final BudgetColors colors;

  /// Sets the phone's light/dark setting for this case; reset after the test.
  void applyTo(WidgetTester tester) {
    tester.platformDispatcher.platformBrightnessTestValue = systemBrightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  }
}
