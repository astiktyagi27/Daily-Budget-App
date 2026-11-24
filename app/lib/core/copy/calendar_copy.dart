import 'package:daily_budget/core/copy/help_copy.dart';

/// Copy of the calendar (F-011 §5, `docs/design/screens/calendar.md`), word
/// for word. Amounts and dates arrive already formatted; the sentences that
/// carry them are functions of that text.
abstract final class CalendarCopy {
  // Month switcher.
  static const ended = 'Ended';
  static const thisMonth = 'This month';
  static const thisMonthHint = 'Go back to the current month';
  static const previousMonth = 'Previous month';
  static const nextMonth = 'Next month';
  static const noEarlierMonths = 'No earlier months';
  static const thisIsTheCurrentMonth = 'This is the current month';
  static const thisIsTheLatestMonth = 'This is the latest month';

  /// `Last month · 5 Oct – 4 Nov`: the new month is not set up yet.
  static String lastMonth(String range) => 'Last month · $range';

  // Legend.
  static const legendSaved = 'Saved';
  static const legendOnBudget = 'On budget';
  static const legendOverspent = 'Overspent';
  static const legendChanged = 'Budget changed';
  static const legendInfoTitle = 'Calendar';
  static const legendInfoBody =
      'Each day shows what you spent. Green ● means you spent less than the '
      "day's budget, grey ○ exactly the budget, red ◆ more. A small indigo "
      'line at the top of a day means your budget changed that day. '
      '${HelpCopy.hintCalendar}';
  static const legendSemantics = 'Saved, on budget, overspent';

  // Cells.
  static const cellHint = 'See this day';

  /// `Days before 10 Nov aren't budgeted. You started on 10 Nov.`
  static String notBudgetedCaption(String day) =>
      "Days before $day aren't budgeted. You started on $day.";

  /// Late setup (D-057): `This month was set up on 12 Dec.`
  static String notBudgetedLateCaption(String day) =>
      "Days before $day aren't budgeted. This month was set up on $day.";

  // Loading and error.
  static const loadingSemantics = 'Loading your calendar';
  static const loadError = "Couldn't load this month.";
  static const tryAgain = 'Try again';
  static const tryAgainHint = 'Try to load this month again';

  // Screen-reader sentences of a day (F-011 §5). [date] is `Thursday 5
  // November`; amounts come from `formatRupeesForSpeech`.
  static String today(String date, String rest) => 'Today, $date, $rest';

  static String upcoming(String date) => '$date, upcoming';

  static String notBudgeted(String date) =>
      '$date, not budgeted, before you started';

  static String notBudgetedLate(String date) =>
      "$date, not budgeted, before this month's setup";

  static String spent(String amount) => 'spent $amount';
  static String spentSoFar(String amount) => 'spent $amount so far';
  static String netAfterRefunds(String amount) => 'net $amount after refunds';
  static const nothingSpent = 'nothing spent';
  static String saved(String amount) => 'saved $amount';
  static const savedLessThanRupee = 'saved less than ₹1';
  static const onBudget = 'on budget';
  static String overspent(String amount) => 'overspent $amount';
  static const overspentLessThanRupee = 'overspent less than ₹1';
  static String left(String amount) => '$amount left';
  static const leftLessThanRupee = 'less than ₹1 left';
  static String coveredFromSavings(String amount) =>
      '$amount covered from savings';
  static String afterFromSavings(String amount) => 'after $amount from savings';
  static const budgetChangedThisDay = 'budget changed this day';
}
