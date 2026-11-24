/// Screen copy that is not help text: app name, titles, labels, empty
/// states and group headers (plan F-003 §1, F-004 §1.1). Copied word for
/// word from the §5 tables of the feature docs. Help strings live in
/// `help_copy.dart`.
abstract final class ScreenCopy {
  static const appName = 'Daily Budget App';

  /// Help sheet and hint button (F-004 §5).
  static const gotIt = 'Got it';

  // F-002: Theme row and picker.
  static const themeLabel = 'Theme';
  static const themePickerTitle = 'Choose a theme';
  static const themeAuto = 'Auto';
  static const themeLight = 'Light';
  static const themeDark = 'Dark';
  static const themeDim = 'Dim';
  static const done = 'Done';

  /// Overline of the first-time hint card (F-004 §5).
  static const hintOverline = 'Tip';

  // F-003: bottom tabs.
  static const tabHome = 'Home';
  static const tabDashboard = 'Dashboard';
  static const tabTransactions = 'Transactions';
  static const tabSettings = 'Settings';

  /// Screen-reader label of a bottom tab: `Home, tab 1 of 4`.
  static String tabPosition(String label, int position, int count) =>
      '$label, tab $position of $count';

  // F-003: empty states.
  static const homeEmptyTitle = 'Your daily budget lives here';
  static const homeEmptyDescription =
      "Tell us your salary and fixed costs, and we'll work out what you can "
      'spend each day.';

  // F-003: Settings list.
  static const groupGeneral = 'General';
  static const groupMoney = 'Money';
  static const groupPrivacyHelp = 'Privacy & help';
  static const notificationsLabel = 'Notifications';
  static const bankAccountLabel = 'Bank account';
  static const salaryDateLabel = 'Salary date';
  static const categoriesLabel = 'Categories';
  static const privacyLabel = 'Privacy & data';
  static const howItWorksLabel = 'How this app works';
  static const disclaimerLabel = 'Disclaimer';
  static const comingSoonTag = 'Coming soon';

  // F-005: tour slides. Amounts use Indian grouping and U+2212 (`−`).
  static const slide1Title = 'Spend a little each day';
  static const slide1Body =
      'Daily Budget App turns your monthly money into one simple number: '
      'what you can spend today.';
  static const slide2Title = 'Your daily budget, worked out';
  static const slide2Body =
      'Salary ₹40,000 − rent ₹10,000 − EMI ₹5,000 − subscription ₹100 = '
      "₹24,900 to spend. Over a 30-day month, that's ₹830 a day.";
  static const slide3Title = 'Saved days add up';
  static const slide3Body =
      'Spend less than your daily budget and the rest goes into your savings '
      'pot. Overspent? You choose whether to cover it from savings.';
  static const slide4Title = 'Private by design';
  static const slide4Body =
      'Your bank SMS are read on this phone and never leave it. No login, and '
      'nothing is uploaded.';

  /// Screen-reader position of the page indicator: `Slide 2 of 4`.
  static String slidePosition(int position, int count) =>
      'Slide $position of $count';

  // F-005: tour controls (help in `HelpCopy`).
  static const next = 'Next';
  static const skip = 'Skip';
  static const getStarted = 'Get started';

  // F-005: decorative visual cards (welcome-tour §2.2). Excluded from
  // semantics: the slide body carries the same facts for screen readers.

  static const visualTodayOverline = 'Today you can spend';
  static const visualTodayAmount = '₹830';
  static const visualSalary = 'Salary';
  static const visualSalaryAmount = '₹40,000';
  static const visualRent = 'Rent';
  static const visualRentAmount = '−₹10,000';
  static const visualEmi = 'EMI';
  static const visualEmiAmount = '−₹5,000';
  static const visualSubscription = 'Subscription';
  static const visualSubscriptionAmount = '−₹100';
  static const visualToSpend = 'To spend';
  static const visualToSpendAmount = '₹24,900';
  static const visualDays = '÷ 30 days';
  static const visualPerDay = '₹830 a day';
  static const visualSavedDay = '9';
  static const visualSavedAmount = '₹620';
  static const visualSavedLabel = 'saved';
  static const visualOnBudgetDay = '10';
  static const visualOnBudgetAmount = '₹830';
  static const visualOnBudgetLabel = 'on budget';
  static const visualOverspentDay = '11';
  static const visualOverspentAmount = '₹1,130';
  static const visualOverspentLabel = 'overspent';
  static const visualSavingsPot = 'Savings pot';
  static const visualSavingsPotAmount = '₹210';
  static const visualStaysOnPhone = 'Stays on this phone';
  static const visualNoLogin = 'No login';
  static const visualNothingUploaded = 'Nothing uploaded';

  // F-005: SMS explainer.
  static const smsTitle = 'Read your bank SMS';
  static const smsPointWhy =
      'To track spends for you, the app reads the SMS your bank sends when '
      'money moves.';
  static const smsPointOnlyBank =
      "Only your bank's messages are read. OTPs, personal chats and other "
      'senders are ignored.';
  static const smsPointStays =
      'Everything stays on this phone. Nothing is uploaded or shared.';
  static const allowSms = 'Allow SMS access';
  static const notNow = 'Not now';

  // F-005: notifications explainer.
  static const notificationsTitle = 'Get gentle nudges';
  static const notificationsPointWarning =
      "A heads-up when you've used 80% of today's budget.";
  static const notificationsPointOver = 'An alert if you go over.';
  static const notificationsPointSummary =
      'An end-of-day summary of what you saved or overspent.';
  static const notificationsPointOptional =
      'Optional. You can change this anytime in Settings.';
  static const turnOnNotifications = 'Turn on notifications';

  // F-005: disclaimer.
  static const disclaimerTitle = 'Before you start';
  static const disclaimerPointOneAccount = 'The app tracks one bank account.';
  static const disclaimerPointNoCards = 'Credit card spends are not included.';
  static const disclaimerPointDetection =
      'Automatic detection can get things wrong sometimes. You can edit any '
      'transaction or category.';
  static const iUnderstand = 'I understand';
}
