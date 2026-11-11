import 'package:daily_budget/core/copy/help_copy.dart';
import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/domain/preferences/theme_choice.dart';

/// The copy for each theme choice (F-002 §5, settings.md §2.2, §3).
extension ThemeChoiceCopy on ThemeChoice {
  /// The option label in the picker: `Auto`, `Light`, `Dark`, `Dim`.
  String get label => switch (this) {
    ThemeChoice.auto => ScreenCopy.themeAuto,
    ThemeChoice.light => ScreenCopy.themeLight,
    ThemeChoice.dark => ScreenCopy.themeDark,
    ThemeChoice.dim => ScreenCopy.themeDim,
  };

  /// The option description in the picker.
  String get optionDescription => switch (this) {
    ThemeChoice.auto => HelpCopy.themeOptionAutoDescription,
    ThemeChoice.light => HelpCopy.themeOptionLightDescription,
    ThemeChoice.dark => HelpCopy.themeOptionDarkDescription,
    ThemeChoice.dim => HelpCopy.themeOptionDimDescription,
  };

  /// The Theme row's description: the current choice.
  String get rowDescription => switch (this) {
    ThemeChoice.auto => HelpCopy.themeAutoDescription,
    _ => label,
  };
}
