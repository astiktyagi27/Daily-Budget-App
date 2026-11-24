/// Copy of the Transactions tab and the Add / Edit spend screen (F-009 §5,
/// `docs/design/screens/transactions.md`), word for word. Amounts are
/// formatted by the screens with `formatRupees`; the sentences that carry an
/// amount are functions of the text already formatted.
abstract final class TransactionsCopy {
  // Tab states.
  static const noMonthTitle = 'Set up your month first';
  static const noMonthDescription =
      'Your spends need a budget month. It takes a minute.';
  static const noMonthButton = 'Set up your month';
  static const noMonthHint = 'Open month setup';

  static const noSpendsTitle = 'No spends yet this month';
  static const noSpendsDescription =
      "Add what you spend and we'll keep your daily budget up to date.";

  static const newMonthTitle = 'Set up your new month first';
  static const newMonthDescription =
      "Your last budget month has ended. Confirm this month's numbers to "
      'keep adding spends.';
  static const newMonthButton = 'Set up this month';
  static const newMonthHint = 'Set up your new budget month';
  static const newMonthNotNow = 'Not now';
  static const closeHint = 'Close';

  /// `Last month · 5 Oct – 4 Nov`.
  static String lastMonthLabel(String range) => 'Last month · $range';

  // Add spend button.
  static const addSpend = 'Add spend';
  static const addSpendTooltip = 'Add a spend by hand';

  // Today card.
  static const todayTitle = 'Today';
  static const todayInfoBody =
      "Today's budget minus what you've spent today. Whatever is left at "
      'midnight goes to your savings pot.';
  static const budgetWord = 'budget';
  static const spentWord = 'spent';
  static const leftTodayWord = 'left today';
  static const onBudgetWord = 'on budget';
  static const overspentWord = 'overspent';
  static const lessThanOneRupee = 'less than ₹1';

  /// `−₹1,000 this month` (the amount already formatted).
  static String shortfallThisMonth(String amount) => '$amount this month';

  // Day list.
  static const yesterday = 'Yesterday';
  static const noNote = 'No note';
  static const editHint = 'Edit';

  // Editor.
  static const addTitle = 'Add spend';
  static const editTitle = 'Edit spend';
  static const closeTooltip = 'Close';
  static const closeScreenHint = 'Leave without saving';
  static const amountLabel = 'Amount';
  static const amountDescription = 'How much you spent.';
  static const amountMissing = 'Enter an amount';
  static const amountNotPositive = 'Amount must be more than ₹0';
  static const amountTooLarge =
      "That's more than ₹10 crore. Please check the amount.";
  static const amountBadFormat = 'Use numbers only, with up to 2 decimals';
  static const dateLabel = 'Date';
  static const dateDescription =
      'When you spent it. You can pick any day this month up to today.';
  static const dateOutOfRange = 'Pick a day this month, up to today.';
  static const datePickerHelp = 'Pick the day you spent it';
  static const noteLabel = 'Note (optional)';
  static const noteDescription = 'For example, "Lunch with Riya" or "Petrol".';
  static const save = 'Save';
  static const saveHint = 'Save this spend';
  static const saveChanges = 'Save changes';
  static const saveChangesHint = 'Save your changes';
  static const delete = 'Delete';
  static const deleteHint = 'Delete this spend';

  // Snackbars.
  static const spendAdded = 'Spend added';
  static const spendUpdated = 'Spend updated';
  static const spendDeleted = 'Spend deleted';

  /// `Spend moved to Sun, 8 Nov` (a saved edit changed the day, F-012 AC-13).
  static String spendMoved(String date) => 'Spend moved to $date';

  // Delete sheet.
  static const deleteTitle = 'Delete this spend?';
  static const deleteCancel = 'Cancel';
  static const deleteCancelHint = 'Keep this spend';

  /// `₹250 on Mon, 9 Nov. This can't be undone.`
  static String deleteBody(String amount, String date) =>
      "$amount on $date. This can't be undone.";

  // Discard sheet.
  static const discardAddTitle = 'Discard this spend?';
  static const discardEditTitle = 'Discard changes?';
  static const discardAddBody = "What you've typed won't be saved.";
  static const discardEditBody = "Your changes to this spend won't be saved.";
  static const keepEditing = 'Keep editing';
  static const keepEditingHint = 'Go back to your spend';
  static const discard = 'Discard';
  static const discardHint = 'Leave without saving';

  // Cover taken back sheet (D-040).
  static const coverTitle = 'Savings pot updated';
  static const ok = 'OK';

  /// A whole cover was taken back.
  static String coverTakenBack(String amount, String day, String dayShort) =>
      'Your savings pot went down, so the $amount that covered $day was '
      'taken back. $dayShort is overspent again.';

  /// Part of a cover was taken back.
  static String coverPartlyTakenBack(String amount, String day) =>
      'Your savings pot went down, so $amount of the cover on $day was '
      'taken back.';

  // Screen readers.
  static String dayHeaderSemantics(String heading, String total) =>
      '$heading, total $total';

  static String rowSemantics(String amount, String note, String date) =>
      '$amount, $note, $date';

  /// A money-in row in day details: `Refund, ₹500, Amazon return`.
  static String refundRowSemantics(String amount, String note) =>
      'Refund, $amount, $note';

  static String todaySemantics({
    required String budget,
    required String spent,
    required String result,
    String? shortfall,
  }) =>
      'Today: budget $budget, spent $spent, $result.'
      '${shortfall == null ? '' : ' Minus $shortfall this month.'}';

  /// The Date field read out: `Date, today, Monday 9 November`.
  static String dateSemantics(String when) => 'Date, $when';
}
