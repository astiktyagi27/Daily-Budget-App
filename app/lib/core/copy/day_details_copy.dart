import 'package:daily_budget/core/help/help_info.dart';

/// Every Day details string (F-012 §5, `docs/design/screens/day-details.md`
/// §14), word for word. Amounts and dates arrive already formatted; this file
/// only puts the words around them, so no screen formats money itself.
abstract final class DayDetailsCopy {
  // Top bar.
  static const back = 'Back';
  static const backHint = 'Go back';

  // Status line and Day result words.
  static String saved(String amount) => 'Saved $amount';
  static const savedLessThanRupee = 'Saved less than ₹1';
  static const onBudget = 'On budget';
  static String overspent(String amount) => 'Overspent $amount';
  static const overspentLessThanRupee = 'Overspent less than ₹1';
  static const upcoming = 'Upcoming';

  /// `₹410 left` after `Today · `.
  static String left(String amount) => '$amount left';
  static const leftLessThanRupee = 'less than ₹1 left';
  static const todayOnBudget = 'on budget';
  static String todayOverspent(String amount) => 'overspent $amount';
  static const todayOverspentLessThanRupee = 'overspent less than ₹1';
  static String today(String words) => 'Today · $words';

  // Screen-reader header.
  static String headerSpeech(String date, String words) => '$date, $words';
  static String todayHeaderSpeech(String date, String words) =>
      'Today, $date, $words';

  // Figures.
  static const budget = 'Budget';
  static const HelpInfo budgetInfo = (
    title: budget,
    body: 'What you could spend on this day.',
  );
  static const spent = 'Spent';
  static const HelpInfo spentInfo = (
    title: spent,
    body: 'Everything you spent on this day.',
  );
  static const refunds = 'Refunds';
  static const HelpInfo refundsInfo = (
    title: refunds,
    body: 'Money paid back to you on this day. It lowers what you spent.',
  );
  static const netSpent = 'Net spent';
  static const HelpInfo netSpentInfo = (
    title: netSpent,
    body: 'What you spent minus refunds.',
  );
  static const covered = 'Covered from savings';
  static const HelpInfo coveredInfo = (
    title: covered,
    body: 'Money you moved from your savings pot to this day.',
  );
  static const dayResult = 'Day result';
  static const HelpInfo dayResultInfo = (
    title: dayResult,
    body:
        "The day's budget minus what you spent, after any cover from "
        'savings. Green ● saved, grey ○ on budget, red ◆ overspent.',
  );
  static const remove = 'Remove';
  static const removeHint = 'Remove the cover on this day';

  // Notices.
  static String budgetChanged(String what) =>
      'Budget changed on this day: $what';
  static const changeSeparator = ' · ';

  /// `salary ₹40,000 → ₹35,000`.
  static String changedValue(String name, String before, String after) =>
      '$name $before → $after';
  static const budgetChangedHint = 'Open the month statement';
  static const pastMonth =
      "This month has ended, so its days can't be changed.";
  static String notBudgeted(String date) =>
      'Not budgeted: you started on $date.';
  static const notYetHappened = "This day hasn't happened yet.";

  // Cover card.
  static const savingsPot = 'Savings pot';
  static const HelpInfo savingsPotInfo = (
    title: savingsPot,
    body: 'The money you saved, minus what you used to cover days.',
  );
  static const coverSentence =
      'Use money from your savings pot to cover this day.';
  static const todayCoverLine =
      'Spending more today will make it overspent again.';
  static const coverButton = 'Cover with savings';
  static const coverButtonHint = 'Cover this day from your savings pot';
  static const potEmpty = 'Your savings pot is empty.';
  static const HelpInfo potEmptyInfo = (
    title: potEmpty,
    body: 'Your pot fills up on days you spend less than your budget.',
  );
  static String fullyCovered(String amount) => 'Covered $amount from savings.';

  // Cover sheet.
  static String coverTitle(String day) => 'Cover $day';
  static String coverLine(String overspend, String pot) =>
      'Overspent $overspend · Savings pot $pot';
  static String coverLineUnderRupee(String pot) =>
      'Overspent less than ₹1 · Savings pot $pot';
  static const coverAmountLabel = 'Amount';
  static const wholeOverspend = 'This covers the whole overspend.';
  static const wholePot = 'This uses your whole savings pot.';
  static const coverConfirm = 'Cover';
  static const coverConfirmHint = 'Move this amount from your savings pot';
  static const coverCancel = 'Cancel';
  static const coverCancelHint = 'Close without covering';
  static const amountMissing = 'Enter an amount more than ₹0';
  static String exceedsPot(String pot) =>
      "That's more than your savings pot ($pot).";
  static String exceedsOverspend(String overspend) =>
      "That's more than this day's overspend ($overspend).";

  // Snackbars.
  static String coverSnackbar(String amount) =>
      '$amount covered from your savings';
  static const undo = 'Undo';
  static const coverUndone = 'Cover undone';
  static const coverRemoved = 'Cover removed';

  // Remove sheet.
  static const removeTitle = 'Remove this cover?';
  static String removeBody(String amount, String day) =>
      '$amount goes back to your savings pot, and $day is overspent $amount '
      'again.';
  static const removeConfirm = 'Remove cover';
  static const removeConfirmHint = 'Give this money back to your savings pot';
  static const keepIt = 'Keep it';
  static const keepItHint = 'Close';

  // Spends.
  static const spendsHeading = 'Spends';
  static const spendsAndRefundsHeading = 'Spends and refunds';
  static const nothingSpent = 'Nothing spent this day';
  static const nothingSpentToday = 'Nothing spent yet today';
  static const refund = 'Refund';
  static const datedInTheFuture = 'Dated in the future';
  static const addSpend = 'Add spend';
  static const addSpendHint = 'Add a spend on this day';

  // States.
  static const loadingSemantics = 'Loading this day';
}
