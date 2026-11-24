/// Month statement copy (F-014 §5, `docs/design/screens/month-statement.md`
/// §13), copied word for word. Sentences that hold an amount are functions of
/// amounts the caller already formatted with `formatRupees`.
abstract final class StatementCopy {
  static const title = 'Month statement';
  static const back = 'Back';

  /// Header of the totals card.
  static const soFar = 'So far';
  static const monthTotal = 'Month total';

  /// The month line's suffix for the current month:
  /// ` · so far (to Fri, 20 Nov)`.
  static String soFarTo(String weekdayDayMonth) =>
      ' · so far (to $weekdayDayMonth)';

  /// `5 Nov – 9 Nov: not budgeted (before you started).` (a range or a day).
  static String notBudgeted(String range) =>
      '$range: not budgeted (before you started).';

  // Totals card rows and their (i) texts.
  static const moneyForMonth = 'Money for the month';
  static const moneyForMonthInfo =
      'All the daily budgets of this month added together.';
  static const spent = 'Spent';
  static const spentInfo = 'Everything you spent, before any refunds.';
  static const refunds = 'Refunds';
  static const netSpent = 'Net spent';
  static const saved = 'Saved';
  static const savedInfo =
      "Money left over on days that have ended. Today's leftover joins at "
      'midnight.';
  static const covered = 'Covered from savings';
  static const coveredInfo =
      'Money you moved from your savings pot to a day you overspent.';
  static const overspent = 'Overspent';
  static const overspentInfo =
      "How much you went over on days that aren't covered from savings yet.";
  static const pot = 'Savings pot';
  static const potInfo =
      'The money you saved, minus what you used to cover days.';
  static const shortThisMonth = 'Short this month';
  static const shortThisMonthInfo =
      'Your fixed costs are more than the money you can spend. Every spend '
      'this month counts as overspent.';
  static const left = 'Left';
  static const leftInfo =
      "What's budgeted for this month minus what you've spent so far.";

  /// The mark next to a status amount, for people who cannot tell the
  /// colours apart; the row label already says Saved or Overspent.
  static const savedMark = '●';
  static const overspentMark = '◆';

  /// `less than ₹1 short` for the shortfall row (D-050).
  static const lessThanRupeeShort = 'less than ₹1 short';

  // The rounding note (D-053, D-062) and the footnote.
  static const roundingNote =
      'Totals use exact amounts, so they can differ by a few rupees from the '
      'parts.';
  static const footnote =
      'Amounts are in whole rupees. Calculations use exact amounts.';

  // What changed.
  static const whatChanged = 'What changed';
  static const whatChangedInfo =
      'Every time you changed your salary, target or fixed costs. Days '
      'before a change keep their budget.';
  static const noChanges = 'No changes this month.';
  static const replacedSameDay = '(replaced the same day)';

  static const monthStarted = 'Month started';
  static const monthStartedPartway = 'Month started partway';
  static const changedAndBack = 'Changed and changed back';

  /// `Month started: salary ₹40,000, fixed costs ₹15,100`.
  static String startedLine(String salary, String fixed) =>
      'Month started: salary $salary, fixed costs $fixed';

  /// `Month started partway: money left ₹24,900, still to pay ₹0`.
  static String startedPartwayLine(String moneyLeft, String stillToPay) =>
      'Month started partway: money left $moneyLeft, still to pay $stillToPay';

  /// `₹830/day`.
  static String perDay(String amount) => '$amount/day';

  /// `for the 18 days left`.
  static String daysLeft(int days) =>
      days == 1 ? 'for the 1 day left' : 'for the $days days left';

  // Value changes in a What changed line.
  static const salary = 'Salary';
  static const spendingTarget = 'Spending target';
  static const moneyLeft = 'Money left';
  static String targetSet(String amount) => 'Spending target set to $amount';
  static const targetRemoved = 'Spending target removed';
  static String fixedCostAdded(String name, String amount) =>
      'Fixed cost added: $name $amount';
  static String fixedCostRemoved(String name, String amount) =>
      'Fixed cost removed: $name $amount';
  static String fixedCostRenamed(String from, String to) =>
      '$from renamed to $to';

  // Reasons on a period card (`Rent changed`, ...).
  static const salaryChanged = 'Salary changed';
  static const targetChanged = 'Target changed';
  static const moneyLeftChanged = 'Money left changed';
  static String costChanged(String name) => '$name changed';

  // Period cards.
  static String overline(int index, int of) => 'Period $index of $of';
  static const inProgress = 'in progress';
  static const forTheseDays = 'For these days';
  static const budget = 'Budget';
  static const salaryRow = 'Salary';
  static const targetRow = 'Spending target';
  static const fixedCosts = 'Fixed costs';
  static const stillToPayRow = 'Still to pay';
  static const moneyLeftRow = 'Money left';
  static const showFixedCostsHint = 'Show the fixed costs in this period';
  static const hideFixedCostsHint = 'Hide the fixed costs';

  // The working line.
  static const dailyBudgetLabel = 'daily budget';
  static const dailyBudgetTitle = 'Daily budget';

  /// `₹9,940 doesn't divide evenly by 18 days, so the first 4 days get 1
  /// paisa more. That's why you see ₹552 every day.`
  static String dailyUneven(
    String amount,
    String days,
    int extraDays,
    String daily,
  ) {
    final first = extraDays == 1
        ? 'the first day gets'
        : 'the first $extraDays days get';
    return "$amount doesn't divide evenly by $days, so $first 1 paisa more. "
        "That's why you see $daily every day.";
  }

  /// `₹24,900 divides evenly over 30 days.`
  static String dailyEven(String amount, String days) =>
      '$amount divides evenly over $days.';

  // Shortfall and zero panels.
  static String shortfall(String amount) =>
      '$amount short · ₹0/day (continued anyway)';
  static const shortfallUnderRupee =
      'less than ₹1 short · ₹0/day (continued anyway)';
  static const zeroLeft = '₹0 left for daily spending · ₹0/day';

  // Screen states.
  static const loading = 'Loading the statement';
}
