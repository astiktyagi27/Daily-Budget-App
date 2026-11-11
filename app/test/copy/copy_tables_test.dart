import 'dart:io';

import 'package:daily_budget/core/copy/help_copy.dart';
import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:flutter_test/flutter_test.dart';

// Every expected string is a literal copied from the §5 tables of F-002,
// F-003, F-004 and F-005, and for the decorative tour cards from
// welcome-tour.md §2.2 (house rule: never compare the app's copy with
// itself).
void main() {
  test('TC-004-06 help and screen copy match the feature docs', () {
    final help = <String, (String, String)>{
      // F-004 §5.
      'moreAbout': (HelpCopy.moreAbout('Theme'), 'More about Theme'),
      'closeExplanationHint': (
        HelpCopy.closeExplanationHint,
        'Close this explanation',
      ),
      // F-002 §5.
      'themeInfoBody': (
        HelpCopy.themeInfoBody,
        'Choose how the app looks. Auto switches between Light and Dark with '
            "your phone's setting. Dim is a softer, warm grey theme that's "
            'easy on the eyes at any time of day.',
      ),
      'themeRowHint': (HelpCopy.themeRowHint, 'Opens theme options'),
      'themeAutoDescription': (
        HelpCopy.themeAutoDescription,
        'Auto (follows your phone)',
      ),
      'themeOptionAutoDescription': (
        HelpCopy.themeOptionAutoDescription,
        "Matches your phone's light or dark setting",
      ),
      'themeOptionLightDescription': (
        HelpCopy.themeOptionLightDescription,
        'Bright and clean',
      ),
      'themeOptionDarkDescription': (
        HelpCopy.themeOptionDarkDescription,
        'True dark, best at night',
      ),
      'themeOptionDimDescription': (
        HelpCopy.themeOptionDimDescription,
        'Soft warm grey, easy on the eyes',
      ),
      'themePickerDoneHint': (
        HelpCopy.themePickerDoneHint,
        'Close theme options',
      ),
      'themeChanged': (HelpCopy.themeChanged('Dim'), 'Theme changed to Dim'),
      // F-004 §5: first-time hints.
      'hintHome': (
        HelpCopy.hintHome,
        "Use the tabs at the bottom to move around. Home is where you'll "
            "check today's budget each day.",
      ),
      'hintDashboard': (
        HelpCopy.hintDashboard,
        "Check back after a week of spending. That's when your patterns "
            'start to show.',
      ),
      'hintTransactions': (
        HelpCopy.hintTransactions,
        "Spotted a wrong amount or category later? You'll be able to fix it "
            'right here.',
      ),
      'hintSettings': (
        HelpCopy.hintSettings,
        'Change the theme and other options here. Tap (i) next to a setting '
            'to learn what it does.',
      ),
      'hintGotItHint': (
        HelpCopy.hintGotItHint,
        "Dismiss this tip. It won't show again.",
      ),
      'hintDismissTooltip': (HelpCopy.hintDismissTooltip, 'Dismiss tip'),
      // F-003 §5.
      'navHomeHint': (HelpCopy.navHomeHint, "Today's budget and your calendar"),
      'navDashboardHint': (HelpCopy.navDashboardHint, 'Where your money goes'),
      'navTransactionsHint': (
        HelpCopy.navTransactionsHint,
        'Every spend and credit',
      ),
      'navSettingsHint': (HelpCopy.navSettingsHint, 'Theme and app options'),
      'notificationsDescription': (
        HelpCopy.notificationsDescription,
        'Budget warnings and an end-of-day summary',
      ),
      'bankAccountDescription': (
        HelpCopy.bankAccountDescription,
        'The one bank account the app tracks',
      ),
      'salaryDateDescription': (
        HelpCopy.salaryDateDescription,
        'The day your budget month starts',
      ),
      'categoriesDescription': (
        HelpCopy.categoriesDescription,
        'How your spends are grouped, like Food or Travel',
      ),
      'privacyDescription': (
        HelpCopy.privacyDescription,
        'Your data stays on this phone. Manage or delete it here.',
      ),
      'howItWorksDescription': (
        HelpCopy.howItWorksDescription,
        'A short guide to daily budgets and saving',
      ),
      'disclaimerDescription': (
        HelpCopy.disclaimerDescription,
        "What the app can and can't track",
      ),
      'comingSoon': (
        HelpCopy.comingSoon(
          'Notifications',
          'Budget warnings and an end-of-day summary',
        ),
        'Notifications, coming soon, not available yet. '
            'Budget warnings and an end-of-day summary',
      ),
      // F-005 §5: tour and explainer help.
      'nextHint': (HelpCopy.nextHint, 'Go to the next slide'),
      'skipHint': (HelpCopy.skipHint, 'Skip the tour and continue setup'),
      'getStartedHint': (
        HelpCopy.getStartedHint,
        'Finish the tour and continue setup',
      ),
      'allowSmsDescription': (
        HelpCopy.allowSmsDescription,
        'You can still add spends yourself if you say no.',
      ),
      'smsNotNowHint': (
        HelpCopy.smsNotNowHint,
        'Continue without SMS access for now',
      ),
      'turnOnNotificationsDescription': (
        HelpCopy.turnOnNotificationsDescription,
        'Notifications are created on your phone. Nothing is sent anywhere.',
      ),
      'notificationsNotNowHint': (
        HelpCopy.notificationsNotNowHint,
        'Continue without notifications',
      ),
      'iUnderstandHint': (
        HelpCopy.iUnderstandHint,
        'Finish setup and open the app',
      ),
    };
    final screen = <String, (String, String)>{
      'appName': (ScreenCopy.appName, 'Daily Budget App'),
      'gotIt': (ScreenCopy.gotIt, 'Got it'),
      'themeLabel': (ScreenCopy.themeLabel, 'Theme'),
      'themePickerTitle': (ScreenCopy.themePickerTitle, 'Choose a theme'),
      'themeAuto': (ScreenCopy.themeAuto, 'Auto'),
      'themeLight': (ScreenCopy.themeLight, 'Light'),
      'themeDark': (ScreenCopy.themeDark, 'Dark'),
      'themeDim': (ScreenCopy.themeDim, 'Dim'),
      'done': (ScreenCopy.done, 'Done'),
      'hintOverline': (ScreenCopy.hintOverline, 'Tip'),
      'tabHome': (ScreenCopy.tabHome, 'Home'),
      'tabDashboard': (ScreenCopy.tabDashboard, 'Dashboard'),
      'tabTransactions': (ScreenCopy.tabTransactions, 'Transactions'),
      'tabSettings': (ScreenCopy.tabSettings, 'Settings'),
      'tabPosition': (
        ScreenCopy.tabPosition('Dashboard', 2, 4),
        'Dashboard, tab 2 of 4',
      ),
      'homeEmptyTitle': (
        ScreenCopy.homeEmptyTitle,
        'Your daily budget lives here',
      ),
      'homeEmptyDescription': (
        ScreenCopy.homeEmptyDescription,
        "Once you set up your month, you'll see what you can spend today, "
            "what you've spent and your calendar.",
      ),
      'dashboardEmptyTitle': (
        ScreenCopy.dashboardEmptyTitle,
        'Insights are on their way',
      ),
      'dashboardEmptyDescription': (
        ScreenCopy.dashboardEmptyDescription,
        "After a few days of spending, you'll see where your money goes and "
            'how many days you saved.',
      ),
      'transactionsEmptyTitle': (
        ScreenCopy.transactionsEmptyTitle,
        'No transactions yet',
      ),
      'transactionsEmptyDescription': (
        ScreenCopy.transactionsEmptyDescription,
        "Spends from your bank SMS will show up here. You'll also be able to "
            'add them yourself.',
      ),
      'groupGeneral': (ScreenCopy.groupGeneral, 'General'),
      'groupMoney': (ScreenCopy.groupMoney, 'Money'),
      'groupPrivacyHelp': (ScreenCopy.groupPrivacyHelp, 'Privacy & help'),
      'notificationsLabel': (ScreenCopy.notificationsLabel, 'Notifications'),
      'bankAccountLabel': (ScreenCopy.bankAccountLabel, 'Bank account'),
      'salaryDateLabel': (ScreenCopy.salaryDateLabel, 'Salary date'),
      'categoriesLabel': (ScreenCopy.categoriesLabel, 'Categories'),
      'privacyLabel': (ScreenCopy.privacyLabel, 'Privacy & data'),
      'howItWorksLabel': (ScreenCopy.howItWorksLabel, 'How this app works'),
      'disclaimerLabel': (ScreenCopy.disclaimerLabel, 'Disclaimer'),
      'comingSoonTag': (ScreenCopy.comingSoonTag, 'Coming soon'),
      // F-005 §5: tour slides and controls.
      'slide1Title': (ScreenCopy.slide1Title, 'Spend a little each day'),
      'slide1Body': (
        ScreenCopy.slide1Body,
        'Daily Budget App turns your monthly money into one simple number: '
            'what you can spend today.',
      ),
      'slide2Title': (ScreenCopy.slide2Title, 'Your daily budget, worked out'),
      'slide2Body': (
        ScreenCopy.slide2Body,
        'Salary ₹40,000 − rent ₹10,000 − EMI ₹5,000 − subscription ₹100 = '
            "₹24,900 to spend. Over a 30-day month, that's ₹830 a day.",
      ),
      'slide3Title': (ScreenCopy.slide3Title, 'Saved days add up'),
      'slide3Body': (
        ScreenCopy.slide3Body,
        'Spend less than your daily budget and the rest goes into your '
            'savings pot. Overspent? You choose whether to cover it from '
            'savings.',
      ),
      'slide4Title': (ScreenCopy.slide4Title, 'Private by design'),
      'slide4Body': (
        ScreenCopy.slide4Body,
        'Your bank SMS are read on this phone and never leave it. No login, '
            'and nothing is uploaded.',
      ),
      'slidePosition': (ScreenCopy.slidePosition(2, 4), 'Slide 2 of 4'),
      'next': (ScreenCopy.next, 'Next'),
      'skip': (ScreenCopy.skip, 'Skip'),
      'getStarted': (ScreenCopy.getStarted, 'Get started'),
      // welcome-tour.md §2.2: decorative cards.
      'visualTodayOverline': (
        ScreenCopy.visualTodayOverline,
        'Today you can spend',
      ),
      'visualTodayAmount': (ScreenCopy.visualTodayAmount, '₹830'),
      'visualSalary': (ScreenCopy.visualSalary, 'Salary'),
      'visualSalaryAmount': (ScreenCopy.visualSalaryAmount, '₹40,000'),
      'visualRent': (ScreenCopy.visualRent, 'Rent'),
      'visualRentAmount': (ScreenCopy.visualRentAmount, '−₹10,000'),
      'visualEmi': (ScreenCopy.visualEmi, 'EMI'),
      'visualEmiAmount': (ScreenCopy.visualEmiAmount, '−₹5,000'),
      'visualSubscription': (ScreenCopy.visualSubscription, 'Subscription'),
      'visualSubscriptionAmount': (
        ScreenCopy.visualSubscriptionAmount,
        '−₹100',
      ),
      'visualToSpend': (ScreenCopy.visualToSpend, 'To spend'),
      'visualToSpendAmount': (ScreenCopy.visualToSpendAmount, '₹24,900'),
      'visualDays': (ScreenCopy.visualDays, '÷ 30 days'),
      'visualPerDay': (ScreenCopy.visualPerDay, '₹830 a day'),
      'visualSavedDay': (ScreenCopy.visualSavedDay, '9'),
      'visualSavedAmount': (ScreenCopy.visualSavedAmount, '₹620'),
      'visualSavedLabel': (ScreenCopy.visualSavedLabel, 'saved'),
      'visualOnBudgetDay': (ScreenCopy.visualOnBudgetDay, '10'),
      'visualOnBudgetAmount': (ScreenCopy.visualOnBudgetAmount, '₹830'),
      'visualOnBudgetLabel': (ScreenCopy.visualOnBudgetLabel, 'on budget'),
      'visualOverspentDay': (ScreenCopy.visualOverspentDay, '11'),
      'visualOverspentAmount': (ScreenCopy.visualOverspentAmount, '₹1,130'),
      'visualOverspentLabel': (ScreenCopy.visualOverspentLabel, 'overspent'),
      'visualSavingsPot': (ScreenCopy.visualSavingsPot, 'Savings pot'),
      'visualSavingsPotAmount': (ScreenCopy.visualSavingsPotAmount, '₹210'),
      'visualStaysOnPhone': (
        ScreenCopy.visualStaysOnPhone,
        'Stays on this phone',
      ),
      'visualNoLogin': (ScreenCopy.visualNoLogin, 'No login'),
      'visualNothingUploaded': (
        ScreenCopy.visualNothingUploaded,
        'Nothing uploaded',
      ),
      // F-005 §5: SMS explainer.
      'smsTitle': (ScreenCopy.smsTitle, 'Read your bank SMS'),
      'smsPointWhy': (
        ScreenCopy.smsPointWhy,
        'To track spends for you, the app reads the SMS your bank sends when '
            'money moves.',
      ),
      'smsPointOnlyBank': (
        ScreenCopy.smsPointOnlyBank,
        "Only your bank's messages are read. OTPs, personal chats and other "
            'senders are ignored.',
      ),
      'smsPointStays': (
        ScreenCopy.smsPointStays,
        'Everything stays on this phone. Nothing is uploaded or shared.',
      ),
      'allowSms': (ScreenCopy.allowSms, 'Allow SMS access'),
      'notNow': (ScreenCopy.notNow, 'Not now'),
      // F-005 §5: notifications explainer.
      'notificationsTitle': (
        ScreenCopy.notificationsTitle,
        'Get gentle nudges',
      ),
      'notificationsPointWarning': (
        ScreenCopy.notificationsPointWarning,
        "A heads-up when you've used 80% of today's budget.",
      ),
      'notificationsPointOver': (
        ScreenCopy.notificationsPointOver,
        'An alert if you go over.',
      ),
      'notificationsPointSummary': (
        ScreenCopy.notificationsPointSummary,
        'An end-of-day summary of what you saved or overspent.',
      ),
      'notificationsPointOptional': (
        ScreenCopy.notificationsPointOptional,
        'Optional. You can change this anytime in Settings.',
      ),
      'turnOnNotifications': (
        ScreenCopy.turnOnNotifications,
        'Turn on notifications',
      ),
      // F-005 §5: disclaimer.
      'disclaimerTitle': (ScreenCopy.disclaimerTitle, 'Before you start'),
      'disclaimerPointOneAccount': (
        ScreenCopy.disclaimerPointOneAccount,
        'The app tracks one bank account.',
      ),
      'disclaimerPointNoCards': (
        ScreenCopy.disclaimerPointNoCards,
        'Credit card spends are not included.',
      ),
      'disclaimerPointDetection': (
        ScreenCopy.disclaimerPointDetection,
        'Automatic detection can get things wrong sometimes. You can edit any '
            'transaction or category.',
      ),
      'iUnderstand': (ScreenCopy.iUnderstand, 'I understand'),
    };
    for (final MapEntry(key: name, value: (actual, expected)) in {
      ...help,
      ...screen,
    }.entries) {
      expect(actual, expected, reason: name);
    }

    // Complete: every string in the two copy files is checked above.
    for (final (path, checked) in [
      ('lib/core/copy/help_copy.dart', help.keys.toSet()),
      ('lib/core/copy/screen_copy.dart', screen.keys.toSet()),
    ]) {
      final declared = RegExp(r'static (?:const|String) (\w+)')
          .allMatches(File(path).readAsStringSync())
          .map((m) => m.group(1)!)
          .toSet();
      expect(declared, isNotEmpty, reason: path);
      expect(
        declared.difference(checked),
        isEmpty,
        reason: '$path: strings without a literal in this test',
      );
    }
  });
}
