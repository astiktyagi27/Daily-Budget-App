import 'package:daily_budget/core/copy/money_back_copy.dart';
import 'package:flutter_test/flutter_test.dart';

// Every expected string is a literal copied from F-016 section 5 and
// `transactions-search.md` section 15 (never compare the app's copy with
// itself).
void main() {
  test('TC-016-22 money back copy matches the feature doc', () {
    final copy = <String, (String, String)>{
      'switchLabel': (MoneyBackCopy.switchLabel, 'Money back / refund'),
      'switchDescription': (
        MoneyBackCopy.switchDescription,
        'Turn on for money paid back to you, like a refund or a friend paying '
            'you back. It lowers what you spent that day. Not for your salary.',
      ),
      'addTitle': (MoneyBackCopy.addTitle, 'Add money back'),
      'editTitle': (MoneyBackCopy.editTitle, 'Edit money back'),
      'amountLabel': (MoneyBackCopy.amountLabel, 'Amount back'),
      'amountDescription': (
        MoneyBackCopy.amountDescription,
        'How much you got back.',
      ),
      'amountPrefix': (MoneyBackCopy.amountPrefix, '+₹'),
      'noteDescription': (
        MoneyBackCopy.noteDescription,
        'For example, "Amazon return" or "Riya paid me back".',
      ),
      'saveHint': (MoneyBackCopy.saveHint, 'Save this money back'),
      'added': (MoneyBackCopy.added, 'Money back added'),
      'updated': (MoneyBackCopy.updated, 'Money back updated'),
      'deleted': (MoneyBackCopy.deleted, 'Money back deleted'),
      'deleteTitle': (MoneyBackCopy.deleteTitle, 'Delete this money back?'),
      'deleteHint': (MoneyBackCopy.deleteHint, 'Delete this money back'),
      'deleteCancelHint': (
        MoneyBackCopy.deleteCancelHint,
        'Keep this money back',
      ),
      'deleteBody': (
        MoneyBackCopy.deleteBody('₹500', 'Fri, 13 Nov'),
        "₹500 back on Fri, 13 Nov. This can't be undone.",
      ),
      'discardTitle': (MoneyBackCopy.discardTitle, 'Discard this money back?'),
      'discardBody': (
        MoneyBackCopy.discardBody,
        "What you've typed won't be saved.",
      ),
    };
    for (final MapEntry(key: name, value: (actual, expected)) in copy.entries) {
      expect(actual, expected, reason: name);
    }
  });
}
