/// The user's theme choice in Settings → Theme (F-002). Auto is the default.
enum ThemeChoice {
  auto('auto'),
  light('light'),
  dark('dark'),
  dim('dim');

  new(this.storageValue);

  /// The value saved in the preferences store.
  final String storageValue;

  /// The choice saved as [value], or [auto] when it is missing or unknown
  /// (F-002 AC-8). Matching is exact: `"DIM "` or `"Dim"` are unknown.
  static ThemeChoice fromStorage(String? value) {
    for (final choice in values) {
      if (choice.storageValue == value) return choice;
    }
    return auto;
  }
}
