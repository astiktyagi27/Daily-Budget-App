import 'package:daily_budget/core/copy/category_copy.dart';
import 'package:daily_budget/core/copy/help_copy.dart';
import 'package:daily_budget/core/copy/search_copy.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

// Every expected string is a literal copied from F-015 section 5 and
// `docs/design/screens/transactions-search.md` section 15, never read back
// from the app (house rule: never compare the app's copy with itself).
void main() {
  test('TC-015-36 search copy matches the feature doc and the design', () {
    final copy = <String, (String, String)>{
      'searchPlaceholder': (
        SearchCopy.searchPlaceholder,
        'Search notes or amounts',
      ),
      'searchHint': (
        SearchCopy.searchHint,
        'Type a note or an amount, like lunch or 250',
      ),
      'clearSearchTooltip': (SearchCopy.clearSearchTooltip, 'Clear search'),
      'clearSearchHint': (SearchCopy.clearSearchHint, 'Clear the search'),
      'chip dates': (
        SearchCopy.chipText(SearchCopy.datesWord, SearchCopy.thisMonth),
        'Dates: This month',
      ),
      'chip category': (
        SearchCopy.chipText(SearchCopy.categoryWord, SearchCopy.all),
        'Category: All',
      ),
      'chip type': (
        SearchCopy.chipText(SearchCopy.typeWord, SearchCopy.typeRefunds),
        'Type: Refunds',
      ),
      'chip two categories': (SearchCopy.categoriesValue(2), '2 categories'),
      'chip sentence': (
        SearchCopy.chipSemantics('Dates', 'This month'),
        'Dates, This month, filter, button',
      ),
      'chip sentence on': (
        SearchCopy.chipSemantics('Category', 'Food', on: true),
        'Category, Food, filter on, button',
      ),
      'datesTitle': (SearchCopy.datesTitle, 'Show spends from'),
      'customRange': (SearchCopy.customRange, 'Custom range'),
      'customRangeDescription': (
        SearchCopy.customRangeDescription,
        'Pick the first and last day',
      ),
      'rangePickerHelp': (
        SearchCopy.rangePickerHelp,
        'Pick the first and last day',
      ),
      'thisMonthNotReady': (
        SearchCopy.thisMonthNotReady,
        'Set up your month first',
      ),
      'lastMonthNone': (SearchCopy.lastMonthNone, 'No earlier month yet'),
      'categoryFilterTitle': (
        SearchCopy.categoryFilterTitle,
        'Show categories',
      ),
      'categoryFilterDescription': (
        SearchCopy.categoryFilterDescription,
        'Spends without a category count as Other.',
      ),
      'show': (SearchCopy.show, 'Show'),
      'showHint': (SearchCopy.showHint, 'Show these categories'),
      'clear': (SearchCopy.clear, 'Clear'),
      'clearHint': (SearchCopy.clearHint, 'Show all categories'),
      'typeTitle': (SearchCopy.typeTitle, 'Show'),
      'typeDescription': (
        SearchCopy.typeDescription,
        'Refunds are money paid back to you. They lower what you spent that '
            'day.',
      ),
      'type all': (SearchCopy.typeName(TypeFilter.all), 'All'),
      'type spends': (SearchCopy.typeName(TypeFilter.spends), 'Spends'),
      'type refunds': (SearchCopy.typeName(TypeFilter.refunds), 'Refunds'),
      'clearAll': (SearchCopy.clearAll, 'Clear all'),
      'clearAllHint': (
        SearchCopy.clearAllHint,
        'Clear the search and all filters',
      ),
      'results one': (SearchCopy.resultsCount(1), '1 result'),
      'results many': (SearchCopy.resultsCount(2), '2 results'),
      'results spoken': (
        SearchCopy.resultsSpoken(2, spent: '₹670', refunds: '₹500'),
        '2 results, spent ₹670, refunds ₹500',
      ),
      'no match query': (
        SearchCopy.noMatchQuery('taxi'),
        'No spends match "taxi".',
      ),
      'noMatchBoth': (
        SearchCopy.noMatchBoth,
        'No spends match your search and filters.',
      ),
      'noMatchFilters': (
        SearchCopy.noMatchFilters,
        'No spends match your filters.',
      ),
      'clearSearch': (SearchCopy.clearSearch, 'Clear search'),
      'dayShown': (SearchCopy.dayShown('₹250'), '₹250 shown'),
      'dayShownSemantics': (
        SearchCopy.dayShownSemantics('Monday 9 November', '₹250'),
        'Monday 9 November, total shown ₹250',
      ),
      'monthSeparator': (
        SearchCopy.monthSeparator('October', '5 Oct – 4 Nov'),
        'October · 5 Oct – 4 Nov',
      ),
      'refundWordRow': (SearchCopy.refundWordRow, 'Refund'),
      'changeCategoryTooltip': (
        SearchCopy.changeCategoryTooltip,
        'Change category',
      ),
      'chipRowSemantics': (
        SearchCopy.chipRowSemantics('Food'),
        'Category Food, change',
      ),
      'rowSemantics': (
        SearchCopy.rowSemantics('₹250', 'Lunch', 'Food', 'Monday 9 November'),
        '₹250, Lunch, Food, Monday 9 November',
      ),
      'refundRowSemantics': (
        SearchCopy.refundRowSemantics(
          '₹500',
          'Amazon return',
          'Friday 13 November',
        ),
        'Refund, ₹500, Amazon return, Friday 13 November',
      ),
      'sheetLine': (
        SearchCopy.sheetLine,
        'Only this spend changes. Automatic categories come later.',
      ),
      'done': (SearchCopy.done, 'Done'),
      'doneHint': (SearchCopy.doneHint, 'Close'),
      'editorSheetTitle': (SearchCopy.editorSheetTitle, 'Category'),
      'rowSheetTitle': (
        SearchCopy.rowSheetTitle('₹250', 'Lunch'),
        'Category for ₹250 · Lunch',
      ),
      'categoryRowSemantics': (
        SearchCopy.categoryRowSemantics('Other', selected: true),
        'Other, category, selected',
      ),
      'moved': (SearchCopy.moved('Food'), 'Moved to Food'),
      'undo': (SearchCopy.undo, 'Undo'),
      'categoryLabel': (SearchCopy.categoryLabel, 'Category'),
      'categoryDescription': (
        SearchCopy.categoryDescription,
        'What kind of spend this is. Automatic categories come later.',
      ),
      'categoryHint': (SearchCopy.categoryHint, 'Choose a category'),
      'categoryFieldSemantics': (
        SearchCopy.categoryFieldSemantics('Other'),
        'Category, Other, button',
      ),
      'radio available': (
        SearchCopy.radioSemantics(
          'Last month',
          '5 October to 4 November',
          available: true,
        ),
        'Last month, 5 October to 4 November',
      ),
      'radio not available': (
        SearchCopy.radioSemantics(
          'This month',
          'Set up your month first',
          available: false,
        ),
        'This month, not available, Set up your month first',
      ),
    };
    for (final MapEntry(key: name, value: (actual, expected)) in copy.entries) {
      expect(actual, expected, reason: name);
    }
  });

  test('TC-015-36 category names match the feature doc in README order', () {
    expect(
      [for (final c in SpendCategory.values) CategoryCopy.nameOf(c)],
      [
        'Food',
        'Groceries',
        'Shopping',
        'Travel',
        'Bills & Recharge',
        'Entertainment',
        'Health',
        'Friends & People',
        'Other',
      ],
    );
  });

  test('TC-015-58 transactions hint has the new wording', () {
    expect(
      HelpCopy.hintTransactions,
      'Tap a spend to fix it, or tap its category to change it.',
    );
  });
}
