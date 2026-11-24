import 'package:daily_budget/domain/budget/budget.dart';

/// Copy of the Transactions search, filters and category screens (F-015 §5,
/// `docs/design/screens/transactions-search.md` §15), word for word. Amounts
/// are formatted by the screens with `formatRupees`; sentences that carry one
/// are functions of the text already formatted.
abstract final class SearchCopy {
  // Search field.
  static const searchPlaceholder = 'Search notes or amounts';
  static const searchHint = 'Type a note or an amount, like lunch or 250';
  static const clearSearchTooltip = 'Clear search';
  static const clearSearchHint = 'Clear the search';
  static const searchSemantics = 'Search notes or amounts, edit box';

  // Filter chips.
  static const datesWord = 'Dates';
  static const categoryWord = 'Category';
  static const typeWord = 'Type';
  static const thisMonth = 'This month';
  static const lastMonth = 'Last month';
  static const all = 'All';

  /// `Dates: This month`.
  static String chipText(String word, String value) => '$word: $value';

  /// `Category: 2 categories`.
  static String categoriesValue(int count) => '$count categories';

  /// `Dates, This month, filter, button` / `..., filter on, button`.
  static String chipSemantics(String word, String value, {bool on = false}) =>
      '$word, $value, filter${on ? ' on' : ''}, button';

  // Dates sheet.
  static const datesTitle = 'Show spends from';
  static const customRange = 'Custom range';
  static const customRangeDescription = 'Pick the first and last day';
  static const thisMonthNotReady = 'Set up your month first';
  static const lastMonthNone = 'No earlier month yet';
  static const rangePickerHelp = 'Pick the first and last day';

  /// What a screen reader reads for a radio row of a sheet; the radio role
  /// and its state come from the semantics flags.
  static String radioSemantics(
    String label,
    String description, {
    required bool available,
  }) => available
      ? '$label, $description'
      : '$label, not available, $description';

  // Category filter sheet.
  static const categoryFilterTitle = 'Show categories';
  static const categoryFilterDescription =
      'Spends without a category count as Other.';
  static const show = 'Show';
  static const showHint = 'Show these categories';
  static const clear = 'Clear';
  static const clearHint = 'Show all categories';

  // Type sheet.
  static const typeTitle = 'Show';
  static const typeDescription =
      'Refunds are money paid back to you. They lower what you spent that day.';
  static const typeSpends = 'Spends';
  static const typeRefunds = 'Refunds';

  static String typeName(TypeFilter type) => switch (type) {
    TypeFilter.all => all,
    TypeFilter.spends => typeSpends,
    TypeFilter.refunds => typeRefunds,
  };

  // Results line.
  static const clearAll = 'Clear all';
  static const clearAllHint = 'Clear the search and all filters';
  static const refundWord = 'refunds';
  static const spentWord = 'spent';

  static String resultsCount(int count) =>
      count == 1 ? '1 result' : '$count results';

  /// The sentence a screen reader gets: `2 results, spent ₹670, refunds ₹500`.
  static String resultsSpoken(int count, {String? spent, String? refunds}) => [
    resultsCount(count),
    if (spent != null) '$spentWord $spent',
    if (refunds != null) '$refundWord $refunds',
  ].join(', ');

  // No results.
  static String noMatchQuery(String query) => 'No spends match "$query".';
  static const noMatchBoth = 'No spends match your search and filters.';
  static const noMatchFilters = 'No spends match your filters.';
  static const clearSearch = 'Clear search';

  // Day header and separators.
  static String dayShown(String amount) => '$amount shown';

  /// `Monday 9 November, total shown ₹250`.
  static String dayShownSemantics(String heading, String amount) =>
      '$heading, total shown $amount';

  /// `October · 5 Oct – 4 Nov`.
  static String monthSeparator(String month, String range) => '$month · $range';

  // Rows.
  static const refundWordRow = 'Refund';
  static const changeCategoryTooltip = 'Change category';

  /// `Category Food, change`.
  static String chipRowSemantics(String name) => 'Category $name, change';

  /// A spend row with its category: `₹250, Lunch, Food, Monday 9 November`.
  static String rowSemantics(
    String amount,
    String note,
    String category,
    String date,
  ) => '$amount, $note, $category, $date';

  /// `Refund, ₹500, Amazon return, Friday 13 November`.
  static String refundRowSemantics(String amount, String note, String date) =>
      'Refund, $amount, $note, $date';

  // Category sheet.
  static const sheetLine =
      'Only this spend changes. Automatic categories come later.';
  static const done = 'Done';
  static const doneHint = 'Close';
  static const editorSheetTitle = 'Category';

  /// `Category for ₹250 · Lunch`.
  static String rowSheetTitle(String amount, String note) =>
      'Category for $amount · $note';

  /// `Food, category, selected`.
  static String categoryRowSemantics(String name, {required bool selected}) =>
      '$name, category${selected ? ', selected' : ''}';

  static String moved(String name) => 'Moved to $name';
  static const undo = 'Undo';
  static const undoHint = 'Put the category back';

  // Editor Category row.
  static const categoryLabel = 'Category';
  static const categoryDescription =
      'What kind of spend this is. Automatic categories come later.';
  static const categoryHint = 'Choose a category';

  /// `Category, Other, button`.
  static String categoryFieldSemantics(String name) =>
      'Category, $name, button';
}
