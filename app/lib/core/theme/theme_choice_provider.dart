import 'package:daily_budget/core/providers/preferences_providers.dart';
import 'package:daily_budget/domain/preferences/theme_choice.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current theme choice. Read synchronously from the store opened before
/// `runApp`, so the first frame is already in the saved theme (F-002 AC-7).
final themeChoiceProvider = NotifierProvider<ThemeChoiceNotifier, ThemeChoice>(
  ThemeChoiceNotifier.new,
);

class ThemeChoiceNotifier extends Notifier<ThemeChoice> {
  /// Saves run one after another, so the last choice is also the last value
  /// written, however fast the user taps (TC-002-33).
  Future<bool> _lastSave = Future.value(true);

  @override
  ThemeChoice build() => ref.watch(themePreferenceRepositoryProvider).read();

  /// Applies [choice] at once, then saves it. The returned future completes
  /// with `false` if the save failed; the choice still holds for the session
  /// (AC-5, AC-8).
  Future<bool> select(ThemeChoice choice) {
    state = choice;
    final repository = ref.read(themePreferenceRepositoryProvider);
    return _lastSave = _lastSave.then((_) => repository.write(choice));
  }
}
