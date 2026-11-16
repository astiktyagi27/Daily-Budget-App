import 'dart:io';

import 'package:daily_budget/core/copy/month_setup_copy.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

const _noticePartway =
    "You're starting partway through the month, so we'll spread the money "
    'you have left over the 25 days until your next salary.';
const _noticeLastDay =
    "You're starting on the last day of this budget month, so all the money "
    'you have left is for today.';
const _editLineMany =
    'From today (20 Nov): ₹630 a day for the 15 days left. Days '
    'before today keep their budget.';
const _editLineOne =
    'From today (4 Dec): ₹1,830 for today, the last day of this budget '
    'month. Days before today keep their budget.';

// Every expected string is a literal copied from the §5 tables of F-008 and
// from `docs/design/screens/month-setup.md` (house rule: never compare the
// app's copy with itself). Amounts passed in are already formatted.
void main() {
  test('TC-008-25 month setup copy matches the feature doc', () {
    const basis = PreviewBasis.salary;
    final nov10 = CalendarDate(2026, 11, 10);
    final copy = <String, (Object?, Object?)>{
      'titleFirst': (MonthSetupCopy.titleFirst, 'Set up your month'),
      'titleNew': (MonthSetupCopy.titleNew, 'Set up this month'),
      'titleEdit': (MonthSetupCopy.titleEdit, 'Edit this month'),
      'back': (MonthSetupCopy.back, 'Back'),
      'backHint': (MonthSetupCopy.backHint, 'Leave this screen'),
      'prefillNotice': (
        MonthSetupCopy.prefillNotice,
        "We've filled in last month's numbers. Check them and confirm.",
      ),
      'salaryDayLabel': (MonthSetupCopy.salaryDayLabel, 'Salary day'),
      'salaryDayDescription': (
        MonthSetupCopy.salaryDayDescription,
        'The day your salary usually arrives. Your budget month runs from '
            'this day to the day before the next one.',
      ),
      'salaryDayInfo': (
        MonthSetupCopy.salaryDayInfo,
        (
          title: 'Salary day',
          body:
              'If your salary day is the 29th, 30th or 31st, short months '
              'start on their last day instead.',
        ),
      ),
      'salaryDayPlaceholder': (
        MonthSetupCopy.salaryDayPlaceholder,
        'Choose a day',
      ),
      'salaryDayError': (
        MonthSetupCopy.salaryDayError,
        'Choose your salary day',
      ),
      'salaryDayFixedNote': (
        MonthSetupCopy.salaryDayFixedNote,
        'Set in your first month.',
      ),
      'salaryDayFixed': (MonthSetupCopy.salaryDayFixed(5), 'Salary day: 5th'),
      'salaryDaySheetTitle': (MonthSetupCopy.salaryDaySheetTitle, 'Salary day'),
      'salaryDaySheetDescription': (
        MonthSetupCopy.salaryDaySheetDescription,
        'The day your salary usually arrives.',
      ),
      'salaryDaySheetFootnote': (
        MonthSetupCopy.salaryDaySheetFootnote,
        '* In shorter months, the month starts on its last day.',
      ),
      'salaryDaySheetDoneHint': (
        MonthSetupCopy.salaryDaySheetDoneHint,
        'Close salary day options',
      ),
      'salaryDayOpenHint': (
        MonthSetupCopy.salaryDayOpenHint,
        'Choose your salary day',
      ),
      'salaryDayChip': (
        [
          MonthSetupCopy.salaryDayChip(5, selected: true),
          MonthSetupCopy.salaryDayChip(12, selected: false),
        ],
        ['5th, salary day, selected', '12th, salary day'],
      ),
      'salaryLabel': (MonthSetupCopy.salaryLabel, 'Monthly salary'),
      'salaryDescription': (
        MonthSetupCopy.salaryDescription,
        'What you receive in your bank account each month, after tax.',
      ),
      'salaryMissing': (MonthSetupCopy.salaryMissing, 'Enter your salary'),
      'salaryNotPositive': (
        MonthSetupCopy.salaryNotPositive,
        'Salary must be more than ₹0',
      ),
      'tooLarge': (
        MonthSetupCopy.tooLarge,
        "That's more than ₹10 crore. Please check the amount.",
      ),
      'badFormat': (
        MonthSetupCopy.badFormat,
        'Use numbers only, with up to 2 decimals',
      ),
      'targetSwitchLabel': (
        MonthSetupCopy.targetSwitchLabel,
        'Spend less than my salary',
      ),
      'targetSwitchDescription': (
        MonthSetupCopy.targetSwitchDescription,
        'Set a smaller amount to budget and keep the rest aside.',
      ),
      'targetLabel': (MonthSetupCopy.targetLabel, 'Spending target'),
      'targetDescription': (
        MonthSetupCopy.targetDescription,
        'The amount you want to spend this month, including fixed costs.',
      ),
      'targetMissing': (MonthSetupCopy.targetMissing, 'Enter a target'),
      'targetAboveSalary': (
        MonthSetupCopy.targetAboveSalary,
        "Target can't be more than your salary",
      ),
      'targetNotPositive': (
        MonthSetupCopy.targetNotPositive,
        'Target must be more than ₹0',
      ),
      'moneyLeftLabel': (MonthSetupCopy.moneyLeftLabel, 'Money left now'),
      'moneyLeftDescription': (
        MonthSetupCopy.moneyLeftDescription,
        'How much you have to spend until your next salary.',
      ),
      'moneyLeftMissing': (
        MonthSetupCopy.moneyLeftMissing,
        'Enter how much you have left',
      ),
      'moneyLeftNotPositive': (
        MonthSetupCopy.moneyLeftNotPositive,
        'Amount must be more than ₹0',
      ),
      'moneyLeftEditLabel': (
        MonthSetupCopy.moneyLeftEditLabel(nov10),
        'Money left on 10 Nov',
      ),
      'moneyLeftEditDescription': (
        MonthSetupCopy.moneyLeftEditDescription(nov10),
        'What you had to spend when you started on 10 Nov. Change it if it '
            'was wrong. Days before today keep their budget.',
      ),
      'midMonthNotice': (
        [MonthSetupCopy.midMonthNotice(25), MonthSetupCopy.midMonthNotice(1)],
        [_noticePartway, _noticeLastDay],
      ),
      'fixedCostsHeader': (MonthSetupCopy.fixedCostsHeader, 'Fixed costs'),
      'fixedCostsDescription': (
        MonthSetupCopy.fixedCostsDescription,
        "Bills you pay every month, like rent or EMIs. They're taken out "
            'before your daily budget is worked out.',
      ),
      'stillToPayHeader': (
        MonthSetupCopy.stillToPayHeader,
        'Fixed costs still to pay this month',
      ),
      'stillToPayDescription': (
        MonthSetupCopy.stillToPayDescription,
        "Bills you haven't paid yet before your next salary, like rent due "
            'next week.',
      ),
      'itemName': (MonthSetupCopy.itemName, 'Name'),
      'itemAmount': (MonthSetupCopy.itemAmount, 'Amount'),
      'itemAmountHelp': (
        MonthSetupCopy.itemAmountHelp,
        "Leave empty or 0 if there's nothing to pay this month.",
      ),
      'itemNameMissing': (
        MonthSetupCopy.itemNameMissing,
        'Give this cost a name',
      ),
      'addItem': (MonthSetupCopy.addItem, '+ Add item'),
      'addItemHint': (MonthSetupCopy.addItemHint, 'Add another monthly cost.'),
      'itemLimit': (MonthSetupCopy.itemLimit, 'You can add up to 30 costs.'),
      'totalFixedCosts': (MonthSetupCopy.totalFixedCosts, 'Total fixed costs'),
      'removeTooltip': (
        [
          MonthSetupCopy.removeTooltip('Rent'),
          MonthSetupCopy.removeTooltip(''),
        ],
        ['Remove Rent', 'Remove item'],
      ),
      'removedMessage': (
        [
          MonthSetupCopy.removedMessage('EMI'),
          MonthSetupCopy.removedMessage(' '),
        ],
        ['EMI removed', 'Item removed'],
      ),
      'undo': (MonthSetupCopy.undo, 'Undo'),
      'itemNameSemantics': (
        MonthSetupCopy.itemNameSemantics(1, 3),
        'Name, item 1 of 3',
      ),
      'itemAmountSemantics': (
        [
          MonthSetupCopy.itemAmountSemantics('Rent', 1),
          MonthSetupCopy.itemAmountSemantics('', 2),
        ],
        ['Amount for Rent', 'Amount for item 2'],
      ),
      'previewTitle': (MonthSetupCopy.previewTitle, 'Your daily budget'),
      'previewMonthLabel': (MonthSetupCopy.previewMonthLabel, 'Budget month'),
      'previewNeedsSalaryDay': (
        MonthSetupCopy.previewNeedsSalaryDay,
        'Choose your salary day to see your budget month',
      ),
      'previewSpendableLabel': (
        MonthSetupCopy.previewSpendableLabel,
        'Spendable this month',
      ),
      'spendableInfo': (
        MonthSetupCopy.spendableInfo,
        (
          title: 'Spendable this month',
          body: 'Your monthly target minus your fixed costs.',
        ),
      ),
      'previewDailyLabel': (MonthSetupCopy.previewDailyLabel, 'Daily budget'),
      'dailyInfo': (
        MonthSetupCopy.dailyInfo,
        (
          title: 'Daily budget',
          body:
              'What you can spend each day: your spendable money divided by '
              'the days left in your budget month.',
        ),
      ),
      'previewNeedsSalary': (
        MonthSetupCopy.previewNeedsSalary,
        'Enter your salary to see your daily budget',
      ),
      'previewNeedsMoneyLeft': (
        MonthSetupCopy.previewNeedsMoneyLeft,
        'Enter the money you have left to see your daily budget',
      ),
      'previewMonth': (
        [
          MonthSetupCopy.previewMonth(
            BudgetMonth.startIn(5, 2026, 11),
            30,
            partial: false,
          ),
          MonthSetupCopy.previewMonth(
            BudgetMonth.startIn(5, 2026, 11),
            25,
            partial: true,
          ),
          MonthSetupCopy.previewMonth(
            BudgetMonth.startIn(5, 2026, 11),
            1,
            partial: true,
          ),
        ],
        [
          '5 Nov – 4 Dec · 30 days',
          '10 Nov – 4 Dec · 25 days left',
          '4 Dec · 1 day left',
        ],
      ),
      'spendableLine': (
        MonthSetupCopy.spendableLine('₹40,000', '₹15,100', '₹24,900'),
        '₹40,000 − ₹15,100 fixed = ₹24,900',
      ),
      'aDay': (MonthSetupCopy.aDay('₹830'), '₹830 a day'),
      'aDaySpeech': (MonthSetupCopy.aDaySpeech('₹830'), '₹830 a day'),
      'shortfallZeroDay': (MonthSetupCopy.shortfallZeroDay, '₹0 a day'),
      'short': (MonthSetupCopy.short('₹1,000'), '₹1,000 short'),
      'shortfallReason': (
        [
          MonthSetupCopy.shortfallReason('₹1,000', PreviewBasis.salary),
          MonthSetupCopy.shortfallReason('₹1,000', PreviewBasis.target),
          MonthSetupCopy.shortfallReason('₹1,000', PreviewBasis.moneyLeft),
        ],
        [
          'Your fixed costs are ₹1,000 more than your salary.',
          'Your fixed costs are ₹1,000 more than your spending target.',
          'Your fixed costs are ₹1,000 more than the money you have left.',
        ],
      ),
      'editShortfall': (
        MonthSetupCopy.editShortfall('₹2,550'),
        'This change leaves you ₹2,550 short for the rest of the month.',
      ),
      'zeroLeft': (MonthSetupCopy.zeroLeft, '₹0 left for daily spending'),
      'zeroReason': (
        [
          MonthSetupCopy.zeroReason(PreviewBasis.salary),
          MonthSetupCopy.zeroReason(PreviewBasis.target),
          MonthSetupCopy.zeroReason(PreviewBasis.moneyLeft),
        ],
        [
          'Your fixed costs take up all of your salary.',
          'Your fixed costs take up all of your spending target.',
          'Your fixed costs take up all of your money left.',
        ],
      ),
      'editLineTail': (
        MonthSetupCopy.editLineTail,
        ' Days before today keep their budget.',
      ),
      'editLineParts': (
        MonthSetupCopy.editLineParts('20 Nov', '₹630', 15),
        (
          before: 'From today (20 Nov): ',
          amount: '₹630 a day',
          after: ' for the 15 days left. Days before today keep their budget.',
        ),
      ),
      'editLine': (
        [
          MonthSetupCopy.editLine('20 Nov', '₹630', 15),
          MonthSetupCopy.editLine('4 Dec', '₹1,830', 1),
        ],
        [_editLineMany, _editLineOne],
      ),
      'spendableSpeech': (
        MonthSetupCopy.spendableSpeech('₹20,000', '₹21,000', 'minus ₹1,000'),
        '₹20,000 minus ₹21,000 fixed equals minus ₹1,000',
      ),
      'dockDaily': (MonthSetupCopy.dockDaily, 'Daily budget'),
      'dockFromToday': (MonthSetupCopy.dockFromToday, 'From today'),
      'dockEnterSalary': (MonthSetupCopy.dockEnterSalary, 'Enter your salary'),
      'dockNone': (MonthSetupCopy.dockNone, '—'),
      'dockShort': (MonthSetupCopy.dockShort('₹1,000'), '◆ ₹1,000 short'),
      'dockZero': (MonthSetupCopy.dockZero, '○ ₹0 a day'),
      'confirmNew': (MonthSetupCopy.confirmNew, 'Start my month'),
      'confirmNewHint': (
        MonthSetupCopy.confirmNewHint,
        'Save and start this budget month',
      ),
      'confirmEdit': (MonthSetupCopy.confirmEdit, 'Save changes'),
      'confirmEditHint': (
        MonthSetupCopy.confirmEditHint,
        'Save the changes to this month',
      ),
      'shortfallTitle': (
        MonthSetupCopy.shortfallTitle,
        "Your numbers don't add up",
      ),
      'shortfallBody': (
        [
          MonthSetupCopy.shortfallBody('₹1,000', PreviewBasis.salary),
          MonthSetupCopy.shortfallBody('₹1,000', PreviewBasis.target),
          MonthSetupCopy.shortfallBody('₹1,000', PreviewBasis.moneyLeft),
        ],
        [
          'Your fixed costs are ₹1,000 more than your salary.',
          'Your fixed costs are ₹1,000 more than your spending target.',
          'Your fixed costs are ₹1,000 more than your money left.',
        ],
      ),
      'zeroTitle': (
        MonthSetupCopy.zeroTitle,
        'Nothing left for daily spending',
      ),
      'zeroBody': (
        MonthSetupCopy.zeroBody(basis),
        "Your fixed costs take up all of your salary, so there's ₹0 a day to "
            'spend.',
      ),
      'fixNumbers': (MonthSetupCopy.fixNumbers, 'Fix my numbers'),
      'fixNumbersCaption': (
        MonthSetupCopy.fixNumbersCaption,
        'Recommended. Change your costs or target so the month adds up.',
      ),
      'continueAnyway': (MonthSetupCopy.continueAnyway, 'Continue anyway'),
      'continueAnywayCaption': (
        MonthSetupCopy.continueAnywayCaption,
        'Start with ₹0 a day. Every spend this month will count as '
            'overspent.',
      ),
      'discardTitle': (MonthSetupCopy.discardTitle, 'Discard changes?'),
      'discardBody': (
        MonthSetupCopy.discardBody,
        "Your changes to this month won't be saved.",
      ),
      'keepEditing': (MonthSetupCopy.keepEditing, 'Keep editing'),
      'keepEditingHint': (
        MonthSetupCopy.keepEditingHint,
        'Go back to your changes',
      ),
      'discard': (MonthSetupCopy.discard, 'Discard'),
      'discardHint': (MonthSetupCopy.discardHint, 'Leave without saving'),
      'homeSetUpHint': (MonthSetupCopy.homeSetUpHint, 'Open month setup'),
      'homeNewMonthTitle': (
        MonthSetupCopy.homeNewMonthTitle,
        'Your new month has started',
      ),
      'homeNewMonthDescription': (
        MonthSetupCopy.homeNewMonthDescription,
        "Check last month's numbers and confirm.",
      ),
      'homeNewMonthHint': (
        MonthSetupCopy.homeNewMonthHint,
        'Set up your new budget month',
      ),
      'homeThisMonth': (MonthSetupCopy.homeThisMonth, 'This month'),
      'homeEditHint': (
        MonthSetupCopy.homeEditHint,
        "Change this month's salary, target or fixed costs",
      ),
      'homeShortfall': (
        MonthSetupCopy.homeShortfall('−₹1,000'),
        '−₹1,000 this month',
      ),
      'homeShortfallNote': (
        MonthSetupCopy.homeShortfallNote,
        'Every spend this month counts as overspent.',
      ),
      'homeCardSpeech': (
        MonthSetupCopy.homeCardSpeech('5 November', '4 December', '₹830'),
        'This month, 5 November to 4 December, ₹830 a day.',
      ),
      'homeShortfallSpeech': (
        MonthSetupCopy.homeShortfallSpeech('₹1,000'),
        'Minus ₹1,000 this month. Every spend this month counts as '
            'overspent.',
      ),
    };
    for (final MapEntry(key: name, value: (actual, expected)) in copy.entries) {
      expect(actual, expected, reason: name);
    }
    final declared =
        RegExp(r'static (?:const|String|\(|HelpInfo)[^=(]*?(\w+)\s*[=(]')
            .allMatches(
              File('lib/core/copy/month_setup_copy.dart').readAsStringSync(),
            )
            .map((m) => m.group(1)!)
            .toSet();
    expect(declared, isNotEmpty);
    expect(
      declared.difference(copy.keys.toSet()),
      isEmpty,
      reason: 'strings without a literal in this test',
    );
  });
}
