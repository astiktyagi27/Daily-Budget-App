import 'package:daily_budget/core/copy/home_copy.dart';
import 'package:daily_budget/core/copy/safe_to_spend_copy.dart';
import 'package:flutter_test/flutter_test.dart';

// Every expected string is a literal copied from the §5 tables of F-010 and
// F-017 and `home-summary.md` §12 (never compare the app's copy with itself).
void main() {
  test('TC-010-39 home copy matches the feature doc', () {
    final copy = <String, (String, String)>{
      'leftThisMonth': (HomeCopy.leftThisMonth, 'Left this month'),
      'leftInfo': (
        HomeCopy.leftInfo.body,
        "What's budgeted for this month minus what you've spent so far.",
      ),
      'overCaption': (
        HomeCopy.overCaption('₹1,200'),
        "You're ₹1,200 over for this month.",
      ),
      'dayLineTail': (
        HomeCopy.dayLineTail('5 Nov – 4 Dec'),
        '/day · 5 Nov – 4 Dec',
      ),
      'startedOn': (
        HomeCopy.startedOn('10 Nov'),
        "This month's budget started on 10 Nov.",
      ),
      'salary': (HomeCopy.salary, 'Salary'),
      'salaryInfo': (
        HomeCopy.salaryInfo.body,
        'The salary you entered for this month. If you changed it, this is '
            'the latest amount.',
      ),
      'spendingTarget': (HomeCopy.spendingTarget, 'Spending target'),
      'spendingTargetInfo': (
        HomeCopy.spendingTargetInfo.body,
        'The amount you chose to spend this month, including fixed costs.',
      ),
      'moneyLeftAtStart': (HomeCopy.moneyLeftAtStart, 'Money left at start'),
      'moneyLeftAtStartInfo': (
        HomeCopy.moneyLeftAtStartInfo.body,
        'How much you had when you started using the app partway through '
            'the month.',
      ),
      'fixedCosts': (HomeCopy.fixedCosts, 'Fixed costs'),
      'fixedCostsInfo': (
        HomeCopy.fixedCostsInfo.body,
        "Rent, EMIs and other monthly bills. They're taken out before your "
            'daily budget is worked out.',
      ),
      'spentSoFar': (HomeCopy.spentSoFar, 'Spent so far'),
      'spentSoFarInfo': (
        HomeCopy.spentSoFarInfo.body,
        "Everything you've spent this month up to now, after refunds.",
      ),
      'savedThisMonth': (HomeCopy.savedThisMonth, 'Saved this month'),
      'savedInfo': (
        HomeCopy.savedInfo.body,
        "Money left over on days that have ended. Today's leftover joins at "
            'midnight.',
      ),
      'overspent': (HomeCopy.overspent, 'Overspent'),
      'overspentInfo': (
        HomeCopy.overspentInfo.body,
        "How much you went over on days that aren't covered from savings "
            'yet.',
      ),
      'potSubLine': (
        HomeCopy.potSubLine('₹1,700', '₹300'),
        '₹1,700 in your savings pot · ₹300 used to cover days',
      ),
      'shortfallThisMonth': (
        HomeCopy.shortfallThisMonth('−₹1,000'),
        '−₹1,000 this month',
      ),
      'shortfallNote': (
        HomeCopy.shortfallNote,
        'Every spend this month counts as overspent.',
      ),
      'zeroLeft': (HomeCopy.zeroLeft, '₹0 left for daily spending'),
      'budgetChanged': (
        HomeCopy.budgetChanged('13 Nov'),
        'Budget changed on 13 Nov',
      ),
      'seeMonthStatement': (HomeCopy.seeMonthStatement, 'See month statement'),
      'seeMonthStatementHint': (
        HomeCopy.seeMonthStatementHint,
        'Open the month statement',
      ),
      'monthStatement': (HomeCopy.monthStatement, 'Month statement'),
      'monthStatementHint': (
        HomeCopy.monthStatementHint,
        "See how this month's budget was worked out",
      ),
      'more': (HomeCopy.more, 'More'),
      'editThisMonthHint': (
        HomeCopy.editThisMonthHint,
        "Change this month's salary, target or fixed costs",
      ),
      'todayHeader': (
        HomeCopy.todayHeader('Fri, 13 Nov'),
        'Today · Fri, 13 Nov',
      ),
      'todayHint': (HomeCopy.todayHint, "See today's details"),
      'refundsLine': (
        HomeCopy.refundsLine('₹500'),
        'Includes ₹500 back from refunds',
      ),
      'collapsedHint': (HomeCopy.collapsedHint, 'Scroll to the top'),
      'loading': (HomeCopy.loading, 'Loading your month'),
      'summarySpeech': (
        HomeCopy.summarySpeech('₹19,370', '₹830', '5 November', '4 December'),
        'Left this month, ₹19,370. ₹830 a day, 5 November to 4 December.',
      ),
      'overSpeech': (
        HomeCopy.overSpeech('minus ₹1,200', '₹1,200'),
        "Left this month, minus ₹1,200. You're ₹1,200 over for this month.",
      ),
      'shortfallSpeech': (
        HomeCopy.shortfallSpeech('₹1,000'),
        'Minus ₹1,000 this month. Every spend this month counts as '
            'overspent.',
      ),
      'rowSpeech': (HomeCopy.rowSpeech('Overspent', '₹470'), 'Overspent, ₹470'),
      'collapsedSpeech': (
        HomeCopy.collapsedSpeech('₹19,370', '₹830'),
        '₹19,370 left this month, ₹830 a day',
      ),
      'collapsedOverSpeech': (
        HomeCopy.collapsedOverSpeech('₹1,200', '₹0'),
        '₹1,200 over this month, ₹0 a day',
      ),
      'todaySpeech': (
        HomeCopy.todaySpeech(
          date: 'Friday 13 November',
          budget: '₹830',
          spent: '₹420',
          result: '₹410 left today',
        ),
        'Today, Friday 13 November: budget ₹830, spent ₹420, ₹410 left '
            'today.',
      ),
    };
    for (final MapEntry(key: name, value: (actual, expected)) in copy.entries) {
      expect(actual, expected, reason: name);
    }
  });

  test('TC-017-24 safe to spend copy matches the feature doc', () {
    final copy = <String, (String, String)>{
      'label': (SafeToSpendCopy.label, 'Safe to spend'),
      'infoBody': (
        SafeToSpendCopy.infoBody,
        'Everything left this month, including your savings pot, spread '
            'evenly over the days left (today included). '
            "It's a guide: your daily budget doesn't change, and it stays "
            'the same all day.',
      ),
      'aDay': (SafeToSpendCopy.aDay('₹899'), '₹899 a day'),
      'underRupee': (SafeToSpendCopy.underRupeeADay, 'less than ₹1 a day'),
      'daysLeft': (SafeToSpendCopy.daysLeft(22), '22 days left'),
      'oneDayLeft': (SafeToSpendCopy.daysLeft(1), '1 day left'),
      'nothingLeft': (
        SafeToSpendCopy.nothingLeft,
        'Nothing left to spread over the rest of the month.',
      ),
      'speech': (
        SafeToSpendCopy.speech('₹899', 22),
        'Safe to spend, ₹899 a day, 22 days left',
      ),
      'underRupeeSpeech': (
        SafeToSpendCopy.underRupeeSpeech(1),
        'Safe to spend, less than ₹1 a day, 1 day left',
      ),
      'nothingLeftSpeech': (
        SafeToSpendCopy.nothingLeftSpeech,
        'Safe to spend, nothing left to spread over the rest of the month',
      ),
    };
    for (final MapEntry(key: name, value: (actual, expected)) in copy.entries) {
      expect(actual, expected, reason: name);
    }
  });
}
