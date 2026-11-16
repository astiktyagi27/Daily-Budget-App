import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/help/help_info.dart';
import 'package:daily_budget/domain/budget/budget.dart';

/// Every F-008 string (feature doc §5, `docs/design/screens/month-setup.md`),
/// copied word for word. Amounts arrive already formatted by `formatRupees`;
/// this file only puts the words around them, so no screen formats money
/// itself (AC-19). Amounts that the copy fixes (₹0, ₹10 crore) are literals.
abstract final class MonthSetupCopy {
  // Titles (first, new month, edit).
  static const titleFirst = 'Set up your month';
  static const titleNew = 'Set up this month';
  static const titleEdit = 'Edit this month';

  // Screen frame.
  static const back = 'Back';
  static const backHint = 'Leave this screen';
  static const prefillNotice =
      "We've filled in last month's numbers. Check them and confirm.";

  // Salary day.
  static const salaryDayLabel = 'Salary day';
  static const salaryDayDescription =
      'The day your salary usually arrives. Your budget month runs from this '
      'day to the day before the next one.';
  static const HelpInfo salaryDayInfo = (
    title: 'Salary day',
    body:
        'If your salary day is the 29th, 30th or 31st, short months start on '
        'their last day instead.',
  );
  static const salaryDayPlaceholder = 'Choose a day';
  static const salaryDayError = 'Choose your salary day';
  static const salaryDayFixedNote = 'Set in your first month.';
  static String salaryDayFixed(int day) => 'Salary day: ${formatOrdinal(day)}';
  static const salaryDaySheetTitle = 'Salary day';
  static const salaryDaySheetDescription =
      'The day your salary usually arrives.';
  static const salaryDaySheetFootnote =
      '* In shorter months, the month starts on its last day.';
  static const salaryDaySheetDoneHint = 'Close salary day options';
  static const salaryDayOpenHint = 'Choose your salary day';
  static String salaryDayChip(int day, {required bool selected}) =>
      '${formatOrdinal(day)}, salary day${selected ? ', selected' : ''}';

  // Monthly salary and target.
  static const salaryLabel = 'Monthly salary';
  static const salaryDescription =
      'What you receive in your bank account each month, after tax.';
  static const salaryMissing = 'Enter your salary';
  static const salaryNotPositive = 'Salary must be more than ₹0';
  static const tooLarge =
      "That's more than ₹10 crore. Please check the amount.";
  static const badFormat = 'Use numbers only, with up to 2 decimals';
  static const targetSwitchLabel = 'Spend less than my salary';
  static const targetSwitchDescription =
      'Set a smaller amount to budget and keep the rest aside.';
  static const targetLabel = 'Spending target';
  static const targetDescription =
      'The amount you want to spend this month, including fixed costs.';
  static const targetMissing = 'Enter a target';
  static const targetAboveSalary = "Target can't be more than your salary";
  static const targetNotPositive = 'Target must be more than ₹0';

  // Mid-month and late start.
  static const moneyLeftLabel = 'Money left now';
  static const moneyLeftDescription =
      'How much you have to spend until your next salary.';
  static const moneyLeftMissing = 'Enter how much you have left';
  static const moneyLeftNotPositive = 'Amount must be more than ₹0';
  static String moneyLeftEditLabel(CalendarDate firstDay) =>
      'Money left on ${formatDayMonth(firstDay)}';
  static String moneyLeftEditDescription(CalendarDate firstDay) =>
      'What you had to spend when you started on ${formatDayMonth(firstDay)}. '
      'Change it if it was wrong. Days before today keep their budget.';
  static String midMonthNotice(int days) => days == 1
      ? "You're starting on the last day of this budget month, so all the "
            'money you have left is for today.'
      : "You're starting partway through the month, so we'll spread the "
            'money you have left over the $days days until your next salary.';

  // Fixed costs.
  static const fixedCostsHeader = 'Fixed costs';
  static const fixedCostsDescription =
      "Bills you pay every month, like rent or EMIs. They're taken out "
      'before your daily budget is worked out.';
  static const stillToPayHeader = 'Fixed costs still to pay this month';
  static const stillToPayDescription =
      "Bills you haven't paid yet before your next salary, like rent due "
      'next week.';
  static const itemName = 'Name';
  static const itemAmount = 'Amount';
  static const itemAmountHelp =
      "Leave empty or 0 if there's nothing to pay this month.";
  static const itemNameMissing = 'Give this cost a name';
  static const addItem = '+ Add item';
  static const addItemHint = 'Add another monthly cost.';
  static const itemLimit = 'You can add up to 30 costs.';
  static const totalFixedCosts = 'Total fixed costs';
  static String removeTooltip(String name) =>
      name.trim().isEmpty ? 'Remove item' : 'Remove ${name.trim()}';
  static String removedMessage(String name) =>
      name.trim().isEmpty ? 'Item removed' : '${name.trim()} removed';
  static const undo = 'Undo';
  static String itemNameSemantics(int position, int count) =>
      'Name, item $position of $count';
  static String itemAmountSemantics(String name, int position) =>
      name.trim().isEmpty
      ? 'Amount for item $position'
      : 'Amount for ${name.trim()}';

  // Preview card.
  static const previewTitle = 'Your daily budget';
  static const previewMonthLabel = 'Budget month';
  static const previewNeedsSalaryDay =
      'Choose your salary day to see your budget month';
  static const previewSpendableLabel = 'Spendable this month';
  static const HelpInfo spendableInfo = (
    title: 'Spendable this month',
    body: 'Your monthly target minus your fixed costs.',
  );
  static const previewDailyLabel = 'Daily budget';
  static const HelpInfo dailyInfo = (
    title: 'Daily budget',
    body:
        'What you can spend each day: your spendable money divided by the '
        'days left in your budget month.',
  );
  static const previewNeedsSalary =
      'Enter your salary to see your daily budget';
  static const previewNeedsMoneyLeft =
      'Enter the money you have left to see your daily budget';
  static String previewMonth(
    BudgetMonth month,
    int days, {
    required bool partial,
  }) {
    if (!partial) {
      return '${formatRange(month.start, month.end)} · ${formatDayCount(days)}';
    }
    // One day left: just the date, no range.
    return days == 1
        ? '${formatDayMonth(month.end)} · 1 day left'
        : '${formatRange(month.end.addDays(1 - days), month.end)} · '
              '$days days left';
  }

  /// `₹40,000 − ₹15,100 fixed = ₹24,900`, with a word joiner kept inside
  /// each amount by the formatter.
  static String spendableLine(String base, String fixed, String spendable) =>
      '$base − $fixed fixed = $spendable';

  /// `₹830 a day`; the spaces before `a day` do not break.
  static String aDay(String amount) => '$amount a day';

  static String aDaySpeech(String amountSpeech) => '$amountSpeech a day';
  static const shortfallZeroDay = '₹0 a day';
  static String short(String amount) => '$amount short';
  static String shortfallReason(String amount, PreviewBasis basis) =>
      'Your fixed costs are $amount more than ${switch (basis) {
        PreviewBasis.salary => 'your salary',
        PreviewBasis.target => 'your spending target',
        PreviewBasis.moneyLeft => 'the money you have left',
      }}.';
  static String editShortfall(String amount) =>
      'This change leaves you $amount short for the rest of the month.';
  static const zeroLeft = '₹0 left for daily spending';
  static String zeroReason(PreviewBasis basis) =>
      'Your fixed costs take up all of your ${switch (basis) {
        PreviewBasis.salary => 'salary',
        PreviewBasis.target => 'spending target',
        PreviewBasis.moneyLeft => 'money left',
      }}.';
  static const editLineTail = ' Days before today keep their budget.';

  /// The edit line in three parts, so the screen can set the amount in the
  /// money style: [editLine] is their concatenation.
  static ({String before, String amount, String after}) editLineParts(
    String date,
    String amount,
    int days,
  ) => days == 1
      ? (
          before: 'From today ($date): ',
          amount: amount,
          after: ' for today, the last day of this budget month.$editLineTail',
        )
      : (
          before: 'From today ($date): ',
          amount: aDay(amount),
          after: ' for the $days days left.$editLineTail',
        );

  static String editLine(String date, String amount, int days) {
    final parts = editLineParts(date, amount, days);
    return '${parts.before}${parts.amount}${parts.after}';
  }

  /// Screen-reader form of the spendable line (no U+2212, no joiners).
  static String spendableSpeech(String base, String fixed, String spendable) =>
      '$base minus $fixed fixed equals $spendable';

  // Action dock.
  static const dockDaily = 'Daily budget';
  static const dockFromToday = 'From today';
  static const dockEnterSalary = 'Enter your salary';
  static const dockNone = '—';
  static String dockShort(String amount) => '◆ $amount short';
  static const dockZero = '○ ₹0 a day';

  // Confirm.
  static const confirmNew = 'Start my month';
  static const confirmNewHint = 'Save and start this budget month';
  static const confirmEdit = 'Save changes';
  static const confirmEditHint = 'Save the changes to this month';

  // Shortfall sheets (D-036, D-043).
  static const shortfallTitle = "Your numbers don't add up";
  static String shortfallBody(String amount, PreviewBasis basis) =>
      'Your fixed costs are $amount more than ${switch (basis) {
        PreviewBasis.salary => 'your salary',
        PreviewBasis.target => 'your spending target',
        PreviewBasis.moneyLeft => 'your money left',
      }}.';
  static const zeroTitle = 'Nothing left for daily spending';
  static String zeroBody(PreviewBasis basis) =>
      "Your fixed costs take up all of your ${switch (basis) {
        PreviewBasis.salary => 'salary',
        PreviewBasis.target => 'spending target',
        PreviewBasis.moneyLeft => 'money left',
      }}, so there's ₹0 a day to spend.";
  static const fixNumbers = 'Fix my numbers';
  static const fixNumbersCaption =
      'Recommended. Change your costs or target so the month adds up.';
  static const continueAnyway = 'Continue anyway';
  static const continueAnywayCaption =
      'Start with ₹0 a day. Every spend this month will count as overspent.';

  // Discard sheet.
  static const discardTitle = 'Discard changes?';
  static const discardBody = "Your changes to this month won't be saved.";
  static const keepEditing = 'Keep editing';
  static const keepEditingHint = 'Go back to your changes';
  static const discard = 'Discard';
  static const discardHint = 'Leave without saving';

  // Home.
  static const homeSetUpHint = 'Open month setup';
  static const homeNewMonthTitle = 'Your new month has started';
  static const homeNewMonthDescription =
      "Check last month's numbers and confirm.";
  static const homeNewMonthHint = 'Set up your new budget month';
  static const homeThisMonth = 'This month';
  static const homeEditHint =
      "Change this month's salary, target or fixed costs";
  static String homeShortfall(String amount) => '$amount this month';
  static const homeShortfallNote =
      'Every spend this month counts as overspent.';
  static String homeCardSpeech(String start, String end, String amount) =>
      'This month, $start to $end, $amount a day.';
  static String homeShortfallSpeech(String amount) =>
      'Minus $amount this month. $homeShortfallNote';
}
