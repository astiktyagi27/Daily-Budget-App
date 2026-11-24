/// Copy of the Dashboard tab (F-013 section 5, `docs/design/screens/
/// dashboard.md` section 13), word for word. Amounts are formatted by the
/// screen with `formatRupees`; the sentences that carry an amount or a date
/// are functions of the text already formatted.
abstract final class DashboardCopy {
  // Range control.
  static const thisMonth = 'This month';
  static const oneDay = 'One day';
  static const thisMonthHint = 'Show spending for the month';
  static const oneDayHint = 'Show spending for one day';
  static const datePickerHelp = 'Pick a day';
  static const dateChipHint = 'Pick a day';

  /// `Date, Friday 13 November` (the chip, for a screen reader).
  static String dateChipSemantics(String fullDate) => 'Date, $fullDate';

  /// `This month, selected, 1 of 2`.
  static String segmentSemantics(
    String label, {
    required bool selected,
    required int index,
    required int count,
  }) => '$label, ${selected ? 'selected, ' : ''}${index + 1} of $count';

  // Where your money went.
  static const sectionTitle = 'Where your money went';
  static const sectionInfo =
      'Your spends grouped by category. Spends without a category count as '
      'Other.';

  /// `All ₹5,530 so far is in Other.`
  static String singleThisMonth(String amount, String category) =>
      'All $amount so far is in $category.';

  /// `All ₹18,500 is in Other.` (a month that has ended).
  static String singlePastMonth(String amount, String category) =>
      'All $amount is in $category.';

  /// `All ₹1,130 on Wed, 11 Nov is in Other.`
  static String singleOneDay(String amount, String date, String category) =>
      'All $amount on $date is in $category.';

  static const emptyThisMonth = 'Nothing spent yet this month.';

  /// `Nothing spent on Thu, 12 Nov.`
  static String emptyOneDay(String date) => 'Nothing spent on $date.';

  static const roundingNote =
      'Percentages are rounded down, so they may add up to less than 100%.';

  /// `70%`, and `<1%` for a share above 0 and under 1 percent.
  static String percent(int percent, {required bool underOne}) =>
      underOne ? '<1%' : '$percent%';

  /// `Shopping, ₹1,000, 18 percent` for a screen reader.
  static String rowSemantics(
    String category,
    String amount,
    int percent, {
    required bool underOne,
  }) => underOne
      ? '$category, $amount, less than 1 percent'
      : '$category, $amount, $percent percent';

  // Refunds.
  static const refunds = 'Refunds';
  static const refundsInfo =
      'Money paid back to you. It lowers what you spent.';
  static const netSpent = 'Net spent';
  static const netSpentInfo =
      'Spends minus refunds. This matches "Spent so far" on Home.';

  // The Other tip.
  static const tipLabel = 'Tip';
  static const otherTip =
      'Spends without a category go into Other. Pick one when you add a '
      'spend, or change it in Transactions. Later, spends from your bank SMS '
      'will be sorted for you.';
  static const goToTransactions = 'Go to Transactions';
  static const goToTransactionsHint = 'Open Transactions to set categories';

  // This month in numbers.
  static const numbersTitle = 'This month in numbers';
  static const firstDay = "Your first day isn't over yet. Check back tomorrow.";
  static const highestDay = 'Highest-spending day';
  static const highestDayInfo =
      'The day you spent the most. If two days tie, the earlier one is '
      'shown.';
  static const highestDayHint = 'See this day';
  static const noSpendsYet = 'No spends yet';
  static const averageDay = 'Average daily spend';
  static const averageDayInfo =
      'What you spent on the days that have ended, divided by the number of '
      'those days.';
  static const days = 'Days';
  static const daysInfo =
      'How the days that have ended turned out. A day fully covered from '
      'savings counts as on budget.';

  /// `₹638 a day`
  static String perDay(String amount) => '$amount a day';

  /// ` +1 more day` / ` +30 more days`.
  static String moreDays(int count) =>
      '+$count more ${count == 1 ? 'day' : 'days'}';

  static String savedCount(int count) => '$count saved';
  static String onBudgetCount(int count) => '$count on budget';
  static String overspentCount(int count) => '$count overspent';

  /// `incl. 1 covered from savings`
  static String covered(int count) => 'incl. $count covered from savings';

  /// `Days, 4 saved, 2 on budget, 2 overspent, including 1 covered from
  /// savings`.
  static String daysSemantics({
    required int saved,
    required int onBudget,
    required int overspent,
    required int covered,
  }) =>
      'Days, $saved saved, $onBudget on budget, $overspent overspent'
      '${covered > 0 ? ', including $covered covered from savings' : ''}';

  /// `Highest-spending day, Wednesday 11 November, ₹1,130`
  static String highestSemantics(
    String fullDate,
    String amount, {
    required int moreDays,
  }) {
    final more = switch (moreDays) {
      0 => '',
      1 => ', plus 1 more day',
      _ => ', plus $moreDays more days',
    };
    return '$highestDay, $fullDate, $amount$more';
  }

  static const highestSemanticsNone = 'Highest-spending day, No spends yet';

  /// `Based on the 8 days that have ended. Today isn't counted until
  /// midnight.` and `Based on all 31 days.`
  static String basedOnEnded(int days) =>
      "Based on the $days ${days == 1 ? 'day' : 'days'} that "
      "${days == 1 ? 'has' : 'have'} ended. Today isn't counted until "
      'midnight.';

  static String basedOnAll(int days) =>
      'Based on all $days ${days == 1 ? 'day' : 'days'}.';

  // Month statement link.
  static const statementLink = 'Month statement';
  static const statementHint = "See how this month's budget was worked out";

  // Month header.
  static const soFar = ' · so far';

  /// `Last month · 5 Nov – 4 Dec 2026` (a new month is not set up yet).
  static String lastMonth(String range) => 'Last month · $range';

  // States.
  static const loading = 'Loading your dashboard';
  static const noMonthTitle = 'Set up your month first';
  static const noMonthDescription =
      'Your spends need a budget month. It takes a minute.';
  static const noMonthButton = 'Set up your month';
  static const noMonthHint = 'Open month setup';
}
