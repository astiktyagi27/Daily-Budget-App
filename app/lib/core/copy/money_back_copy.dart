/// Copy of Money back, the refund switch of the Add / Edit spend screen
/// (F-016 §5, `docs/design/screens/transactions-search.md` §9, §15), word for
/// word. Amounts are formatted by the screens with `formatRupees`.
abstract final class MoneyBackCopy {
  // The switch row.
  static const switchLabel = 'Money back / refund';
  static const switchDescription =
      'Turn on for money paid back to you, like a refund or a friend paying '
      'you back. It lowers what you spent that day. Not for your salary.';

  // Titles.
  static const addTitle = 'Add money back';
  static const editTitle = 'Edit money back';

  // Amount while the switch is on.
  static const amountLabel = 'Amount back';
  static const amountDescription = 'How much you got back.';

  /// The prefix of the amount while the switch is on (design T-6): `+₹`.
  static const amountPrefix = '+₹';

  // Note while the switch is on.
  static const noteDescription =
      'For example, "Amazon return" or "Riya paid me back".';

  // Save.
  static const saveHint = 'Save this money back';

  // Snackbars.
  static const added = 'Money back added';
  static const updated = 'Money back updated';
  static const deleted = 'Money back deleted';

  // Delete sheet.
  static const deleteTitle = 'Delete this money back?';
  static const deleteHint = 'Delete this money back';
  static const deleteCancelHint = 'Keep this money back';

  /// `₹500 back on Fri, 13 Nov. This can't be undone.`
  static String deleteBody(String amount, String date) =>
      "$amount back on $date. This can't be undone.";

  // Discard sheet (add only; Edit stays `Discard changes?`).
  static const discardTitle = 'Discard this money back?';
  static const discardBody = "What you've typed won't be saved.";
}
