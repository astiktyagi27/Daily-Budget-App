/// Every help string of the app in one place (F-004 AC-6, plan F-004 §1.1):
/// row descriptions, (i) bodies, screen-reader hints, long-press tooltips
/// and hint texts. Copied word for word from the §5 tables of the feature
/// docs; the Designer edits wording here only.
///
/// Screen copy that is not help (titles, labels, empty states) lives in
/// `screen_copy.dart`.
abstract final class HelpCopy {
  // F-004: the help pattern itself.

  /// Screen-reader label of an (i) button.
  static String moreAbout(String label) => 'More about $label';

  /// Screen-reader hint of the help sheet's Got it button.
  static const closeExplanationHint = 'Close this explanation';

  // F-002: Theme row, (i) and picker.

  static const themeInfoBody =
      'Choose how the app looks. Auto switches between Light and Dark with '
      "your phone's setting. Dim is a softer, warm grey theme that's easy on "
      'the eyes at any time of day.';
  static const themeRowHint = 'Opens theme options';
  static const themeAutoDescription = 'Auto (follows your phone)';
  static const themeOptionAutoDescription =
      "Matches your phone's light or dark setting";
  static const themeOptionLightDescription = 'Bright and clean';
  static const themeOptionDarkDescription = 'True dark, best at night';
  static const themeOptionDimDescription = 'Soft warm grey, easy on the eyes';
  static const themePickerDoneHint = 'Close theme options';

  /// Screen-reader announcement after a theme is picked: `Theme changed to
  /// Dim`.
  static String themeChanged(String themeName) => 'Theme changed to $themeName';

  // F-004: first-time hints, one per tab.

  static const hintHome =
      "Use the tabs at the bottom to move around. Home is where you'll check "
      "today's budget each day.";
  static const hintDashboard =
      "Check back after a week of spending. That's when your patterns start "
      'to show.';
  static const hintTransactions =
      "Spotted a wrong amount or category later? You'll be able to fix it "
      'right here.';
  static const hintSettings =
      'Change the theme and other options here. Tap (i) next to a setting to '
      'learn what it does.';

  /// Screen-reader hint of the hint card's Got it button.
  static const hintGotItHint = "Dismiss this tip. It won't show again.";

  /// Long-press tooltip and screen-reader label of the hint card's ×.
  static const hintDismissTooltip = 'Dismiss tip';

  // F-003: bottom tabs (long-press tooltip and screen-reader hint).

  static const navHomeHint = "Today's budget and your calendar";
  static const navDashboardHint = 'Where your money goes';
  static const navTransactionsHint = 'Every spend and credit';
  static const navSettingsHint = 'Theme and app options';

  // F-003: Settings row descriptions.

  static const notificationsDescription =
      'Budget warnings and an end-of-day summary';
  static const bankAccountDescription = 'The one bank account the app tracks';
  static const salaryDateDescription = 'The day your budget month starts';
  static const categoriesDescription =
      'How your spends are grouped, like Food or Travel';
  static const privacyDescription =
      'Your data stays on this phone. Manage or delete it here.';
  static const howItWorksDescription =
      'A short guide to daily budgets and saving';
  static const disclaimerDescription = "What the app can and can't track";

  /// The one disabled screen-reader item of a "Coming soon" row (F-003 §5).
  static String comingSoon(String label, String description) =>
      '$label, coming soon, not available yet. $description';

  // F-005: tour and explainer controls (tooltips, hints, descriptions).
  static const nextHint = 'Go to the next slide';
  static const skipHint = 'Skip the tour and continue setup';
  static const getStartedHint = 'Finish the tour and continue setup';
  static const allowSmsDescription =
      'You can still add spends yourself if you say no.';
  static const smsNotNowHint = 'Continue without SMS access for now';
  static const turnOnNotificationsDescription =
      'Notifications are created on your phone. Nothing is sent anywhere.';
  static const notificationsNotNowHint = 'Continue without notifications';
  static const iUnderstandHint = 'Finish setup and open the app';
}
