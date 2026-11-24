import 'package:daily_budget/core/help/help_info.dart';

/// Every Home summary string (F-010 §5, `docs/design/screens/home-summary.md`
/// §12), word for word. Amounts arrive already formatted by `formatRupees`
/// (or `formatRupeesForSpeech` for the reading sentences); this file only
/// puts the words around them, so no screen formats money itself (AC-12).
abstract final class HomeCopy {
  // Summary card.
  static const leftThisMonth = 'Left this month';
  static const HelpInfo leftInfo = (
    title: leftThisMonth,
    body: "What's budgeted for this month minus what you've spent so far.",
  );

  /// `You're ₹1,200 over for this month.`
  static String overCaption(String amount) =>
      "You're $amount over for this month.";

  /// The part of the day line after the amount: `/day · 5 Nov – 4 Dec`.
  static String dayLineTail(String range) => '/day · $range';

  /// `This month's budget started on 10 Nov.`
  static String startedOn(String date) =>
      "This month's budget started on $date.";

  // Ledger.
  static const salary = 'Salary';
  static const HelpInfo salaryInfo = (
    title: salary,
    body:
        'The salary you entered for this month. If you changed it, this is '
        'the latest amount.',
  );
  static const spendingTarget = 'Spending target';
  static const HelpInfo spendingTargetInfo = (
    title: spendingTarget,
    body: 'The amount you chose to spend this month, including fixed costs.',
  );
  static const moneyLeftAtStart = 'Money left at start';
  static const HelpInfo moneyLeftAtStartInfo = (
    title: moneyLeftAtStart,
    body:
        'How much you had when you started using the app partway through '
        'the month.',
  );
  static const fixedCosts = 'Fixed costs';
  static const HelpInfo fixedCostsInfo = (
    title: fixedCosts,
    body:
        "Rent, EMIs and other monthly bills. They're taken out before your "
        'daily budget is worked out.',
  );
  static const spentSoFar = 'Spent so far';
  static const HelpInfo spentSoFarInfo = (
    title: spentSoFar,
    body: "Everything you've spent this month up to now, after refunds.",
  );
  static const savedThisMonth = 'Saved this month';
  static const HelpInfo savedInfo = (
    title: savedThisMonth,
    body:
        "Money left over on days that have ended. Today's leftover joins at "
        'midnight.',
  );
  static const overspent = 'Overspent';
  static const HelpInfo overspentInfo = (
    title: overspent,
    body:
        "How much you went over on days that aren't covered from savings yet.",
  );

  /// The savings-pot sub-line is built from these parts so the screen can
  /// set the amounts in the money style: `₹1,700` ` in your savings pot` ` · `
  /// `₹300` ` used to cover days`.
  static const inYourSavingsPot = ' in your savings pot';
  static const usedToCoverDays = ' used to cover days';
  static const potSeparator = ' · ';

  static String potSubLine(String pot, String covered) =>
      '$pot$inYourSavingsPot$potSeparator$covered$usedToCoverDays';

  // Panels.
  /// `−₹1,000 this month`.
  static String shortfallThisMonth(String amount) => '$amount this month';
  static const shortfallNote = 'Every spend this month counts as overspent.';
  static const zeroLeft = '₹0 left for daily spending';

  // Budget changed.
  static String budgetChanged(String date) => 'Budget changed on $date';
  static const seeMonthStatement = 'See month statement';
  static const seeMonthStatementHint = 'Open the month statement';

  // Month statement row.
  static const monthStatement = 'Month statement';
  static const monthStatementHint =
      "See how this month's budget was worked out";

  // Overflow menu.
  static const more = 'More';
  static const editThisMonthHint =
      "Change this month's salary, target or fixed costs";

  // Today card.
  /// `Today · Fri, 13 Nov`.
  static String todayHeader(String date) => '$todayHeaderLead $date';

  /// The part of the header before the date; the screen keeps it whole.
  static const todayHeaderLead = 'Today ·';

  static const todayHint = "See today's details";

  /// `Includes ₹500 back from refunds`.
  static String refundsLine(String amount) =>
      'Includes $amount back from refunds';

  // Collapsed row.
  /// `₹19,370 left` (the amount is set in the money style by the screen).
  static const leftWord = ' left';

  /// ` over this month` after the amount of a negative Left.
  static const overThisMonth = ' over this month';
  static const collapsedHint = 'Scroll to the top';

  // Loading.
  static const loading = 'Loading your month';

  // Screen readers.
  /// `Left this month, ₹19,370. ₹830 a day, 5 November to 4 December.`
  static String summarySpeech(
    String left,
    String daily,
    String start,
    String end,
  ) => '$leftThisMonth, $left. ${daySpeech(daily, start, end)}';

  /// `₹830 a day, 5 November to 4 December.`
  static String daySpeech(String daily, String start, String end) =>
      '$daily a day, $start to $end.';

  /// `Left this month, minus ₹1,200. You're ₹1,200 over for this month.`
  static String overSpeech(String leftSpeech, String overAmountSpeech) =>
      '$leftThisMonth, $leftSpeech. ${overCaption(overAmountSpeech)}';

  /// `Minus ₹1,000 this month. Every spend this month counts as overspent.`
  static String shortfallSpeech(String amountSpeech) =>
      'Minus $amountSpeech this month. $shortfallNote';

  /// `Overspent, ₹470`.
  static String rowSpeech(String label, String amountSpeech) =>
      '$label, $amountSpeech';

  /// `₹19,370 left this month, ₹830 a day`.
  static String collapsedSpeech(String left, String daily) =>
      '$left left this month, $daily a day';

  /// `₹1,200 over this month, ₹0 a day`.
  static String collapsedOverSpeech(String over, String daily) =>
      '$over over this month, $daily a day';

  /// `Today, Friday 13 November: budget ₹830, spent ₹420, ₹410 left today.`
  static String todaySpeech({
    required String date,
    required String budget,
    required String spent,
    required String result,
    String? refunds,
  }) =>
      'Today, $date: budget $budget, spent $spent, $result.'
      '${refunds == null ? '' : ' Includes $refunds back from refunds.'}';
}
