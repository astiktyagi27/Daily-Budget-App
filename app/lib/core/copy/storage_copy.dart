/// Storage messages (F-007 section 5), copied word for word. One source for
/// the storage error screen and the save and load errors F-008 and F-009 show.
abstract final class StorageCopy {
  /// Storage error screen, shown instead of the tabs when the database cannot
  /// be opened (AC-8, AC-9).
  static const openErrorTitle = "We couldn't open your data";
  static const openErrorDescription =
      'Your budget data is still on this phone. Try again, and if this keeps '
      'happening, restart your phone.';
  static const tryAgain = 'Try again';
  static const openErrorHint = 'Try to open your data again';

  /// Snackbar or inline message when a save fails; the input stays (AC-10).
  static const saveError = "Couldn't save. Please try again.";

  /// A screen's error state when a read fails.
  static const loadErrorTitle = "Couldn't load your data";
  static const loadErrorDescription = 'Tap Try again. Nothing has been lost.';
  static const loadErrorHint = 'Try to load your data again';
}
