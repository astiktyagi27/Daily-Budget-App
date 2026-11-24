// F-015 test cases for the search text and amount queries, the debounce,
// the help copy and semantics, a thousand entries, and the empty tab states
// (tests/F-015 TC-015-04, -05, -08, -29, -36 to -38, -41 to -43, -45, -50,
// -58, -61, -62, -65, -66). The first search cases are in
// `transactions_search_test.dart`.

import 'package:daily_budget/features/transactions/sheets/category_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/accessibility.dart';
import '../../helpers/bundled_fonts.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/transactions_harness.dart';
import '../../support/find_copy.dart';

Future<TestClock> _open(
  WidgetTester tester,
  Phase3Fixture fixture, {
  double textScale = 1,
  Size size = const Size(400, 1800),
  bool hintsSeen = true,
  FakeMoneyStore? store,
}) async {
  final clock = TestClock(fixture.now);
  await pumpTransactions(
    tester,
    money: store ?? storeFor(fixture),
    clock: clock,
    size: size,
    textScale: textScale,
    hintsSeen: hintsSeen,
  );
  return clock;
}

Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).first, text);
  await tester.pump(const Duration(milliseconds: 260));
  await tester.pumpAndSettle();
}

Future<void> _tapChip(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Indian grouping of whole rupees, written here so the expected text never
/// comes from the app (`1234567` -> `12,34,567`).
String _rupees(int paise) {
  final digits = '${paise ~/ 100}';
  if (digits.length <= 3) return '₹$digits';
  final head = digits.substring(0, digits.length - 3);
  final tail = digits.substring(digits.length - 3);
  final groups = <String>[];
  for (var i = head.length; i > 0; i -= 2) {
    groups.insert(0, head.substring(i - 2 < 0 ? 0 : i - 2, i));
  }
  return '₹${groups.join(',')},$tail';
}

String _hintOf(WidgetTester tester, Finder finder) =>
    tester.getSemantics(finder).getSemanticsData().hint;

void main() {
  // Real glyph widths: the placeholder wraps as it does on a phone.
  setUpAll(loadBundledFonts);

  testWidgets('TC-015-04 hindi and emoji notes are searchable', (tester) async {
    await _open(tester, fixtureA3);
    await _search(tester, 'चाय');
    expect(findCopy('1 result · spent ₹20'), findsOneWidget);
    expect(findCopy('चाय'), findsOneWidget);
    for (final query in ['☕', '☕ chai']) {
      await _search(tester, query);
      expect(findCopy('1 result · spent ₹30'), findsOneWidget, reason: query);
      expect(findCopy('☕ chai'), findsOneWidget);
    }
    await _search(tester, '👨‍👩‍👧');
    expect(findCopy('1 result · spent ₹40'), findsOneWidget);
    expect(findCopy('👨‍👩‍👧 dinner'), findsOneWidget);
  });

  testWidgets('TC-015-05 amount search matches shown and exact amounts', (
    tester,
  ) async {
    await _open(tester, fixtureA2);
    const cases = {
      '830': '2 results · spent ₹1,660',
      '₹1,130': '1 result · spent ₹1,130',
      '250': '2 results · spent ₹340',
      '300': '1 result · spent ₹300',
      '300.50': '1 result · spent ₹300',
      '300.5': '1 result · spent ₹300',
    };
    for (final MapEntry(key: query, value: line) in cases.entries) {
      await _search(tester, query);
      expect(findCopy(line), findsOneWidget, reason: query);
    }
    await _search(tester, '250');
    expect(find.text('250g paneer'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    await _search(tester, '300');
    expect(find.text('Snacks'), findsOneWidget);
    expect(findCopy('₹300'), findsWidgets, reason: 'shown whole rupees');
  });

  testWidgets('TC-015-65 a number finds a refund by amount', (tester) async {
    await _open(tester, fixtureAPlusRefund);
    await _search(tester, '500');
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Amazon return'), findsOneWidget);
    expect(findCopy('2 results · spent ₹500 · refunds ₹500'), findsOneWidget);
    expect(findCopy('+₹500'), findsOneWidget);
  });

  testWidgets('TC-015-66 refunds only with a search', (tester) async {
    await _open(tester, fixtureAPlusRefund);
    await _tapChip(tester, 'Type: All');
    await tester.tap(find.text('Refunds').last);
    await tester.pumpAndSettle();
    expect(find.text('Type: Refunds'), findsOneWidget);

    await _search(tester, 'amazon');
    expect(findCopy('1 result · refunds ₹500'), findsOneWidget);
    expect(find.text('Amazon return'), findsOneWidget);
    expect(find.text('Lunch'), findsNothing);

    await _search(tester, 'lunch');
    expect(
      find.text('No spends match your search and filters.'),
      findsOneWidget,
    );
    expect(find.text('Clear all'), findsWidgets);
    expect(find.text('Lunch'), findsNothing);
    expect(find.text('Amazon return'), findsNothing);
    expect(findCopy('0 results'), findsOneWidget);
  });

  testWidgets('TC-015-08 search respects the date filter', (tester) async {
    final fixture = fixtureO1.plus(
      name: 'AR + O1',
      entries: [fixtureMoneyIn(d(2026, 11, 13), 50000, note: 'Amazon return')],
    );
    await _open(tester, fixture);
    await _search(tester, 'amazon');
    expect(find.text('Amazon return'), findsOneWidget);
    await _search(tester, '1,400');
    expect(find.text('No spends match "1,400".'), findsOneWidget);
    await _tapChip(tester, 'Dates: This month');
    await tester.tap(find.text('Last month'));
    await tester.pumpAndSettle();
    expect(findCopy('1 result · spent ₹1,400'), findsOneWidget);
    expect(find.text('Sat, 10 Oct'), findsOneWidget);
    await _search(tester, 'amazon');
    expect(
      find.text('No spends match your search and filters.'),
      findsOneWidget,
    );
  });

  testWidgets('TC-015-29 search waits for the last keystroke', (tester) async {
    await _open(tester, fixtureA);
    final field = find.byType(TextField).first;
    for (final text in ['l', 'lu', 'lun']) {
      await tester.enterText(field, text);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('result'), findsNothing, reason: text);
    }
    await tester.pump(const Duration(milliseconds: 149));
    expect(find.textContaining('result'), findsNothing);
    expect(find.text('Phone bill'), findsOneWidget, reason: 'not yet');
    await tester.pump(const Duration(milliseconds: 1));
    expect(findCopy('2 results · spent ₹670'), findsOneWidget);
    expect(find.text('Phone bill'), findsNothing);
  });

  testWidgets('TC-015-36 search and filter controls have help copy', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, fixtureAPlusRefund);
    expect(
      _hintOf(tester, find.text('Search notes or amounts')),
      'Type a note or an amount, like lunch or 250',
    );
    await _search(tester, 'lunch');
    expect(find.byTooltip('Clear search'), findsOneWidget);
    expect(find.byTooltip('Change category'), findsWidgets);
    expect(
      _hintOf(tester, find.text('Clear all')),
      'Clear the search and all filters',
    );
    for (final chip in [
      'Dates, This month, filter, button',
      'Category, All, filter, button',
      'Type, All, filter, button',
    ]) {
      expect(find.bySemanticsLabel(chip), findsOneWidget);
    }
    await _tapChip(tester, 'Category: All');
    expect(_hintOf(tester, find.text('Show')), 'Show these categories');
    expect(_hintOf(tester, find.text('Clear')), 'Show all categories');
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    // The editor Category row.
    await tester.tap(addSpendButton);
    await tester.pumpAndSettle();
    expect(
      find.text('What kind of spend this is. Automatic categories come later.'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Category, Other, button')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('TC-015-37 transactions semantics read as full sentences', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, fixtureAPlusRefund);
    expect(
      find.bySemanticsLabel('₹250, Lunch, Other, Monday 9 November'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Category Other, change'), findsWidgets);
    expect(
      find.bySemanticsLabel('Refund, ₹500, Amazon return, Friday 13 November'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('Refund.*Other')), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('Search notes or amounts')),
      findsWidgets,
      reason: 'the search field is labelled',
    );
    expect(
      tester.getSemantics(find.text('Lunch').last).getSemanticsData().hint,
      'Edit',
    );
    // Active chip and the live results line.
    await _tapChip(tester, 'Category: All');
    await tester.tap(
      find.descendant(
        of: find.byType(CategoryFilterSheet),
        matching: find.text('Other'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Category, Other, filter on, button'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('9 results, spent ₹5,530'), findsOneWidget);
    final live = tester.getSemantics(
      find.bySemanticsLabel('9 results, spent ₹5,530'),
    );
    expect(live.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
    semantics.dispose();
  });

  testWidgets('TC-015-38 a thousand entries list and search in the widget '
      'layer', (tester) async {
    await _open(tester, fixtureL1000);
    final current = fixtureL1000.current.entries;
    final all = [for (final entry in current) entry];
    expect(all, hasLength(500));
    final lunch = all.where((e) => e.note!.toLowerCase().contains('lunch'));
    final lunchSum = lunch.fold<int>(0, (sum, e) => sum + e.paise);
    await _search(tester, 'lunch');
    expect(
      findCopy('${lunch.length} results · spent ${_rupees(lunchSum)}'),
      findsOneWidget,
    );
    final food = all.where((e) => e.categoryKey == 'food');
    final foodSum = food.fold<int>(0, (sum, e) => sum + e.paise);
    await _search(tester, '');
    await _tapChip(tester, 'Category: All');
    await tester.tap(
      find.descendant(
        of: find.byType(CategoryFilterSheet),
        matching: find.text('Food'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(
      findCopy('${food.length} results · spent ${_rupees(foodSum)}'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-015-41 zero matches paise only amounts and notes with a '
      'zero', (tester) async {
    final fixture = fixtureA2.plus(
      name: 'A2 + tip',
      entries: [fixtureSpend(d(2026, 11, 12), 40, note: 'Tip')],
    );
    await _open(tester, fixture);
    for (final query in ['0', '₹0']) {
      await _search(tester, query);
      expect(findCopy('2 results · spent ₹90'), findsOneWidget, reason: query);
      expect(find.text('Tip'), findsOneWidget);
      expect(find.text('250g paneer'), findsOneWidget);
    }
  });

  testWidgets('TC-015-42 a very long query is accepted', (tester) async {
    await _open(tester, fixtureA, textScale: 2, size: const Size(360, 2400));
    final query = List.filled(15, 'taxi ride').join(' ');
    expect(query.length, greaterThan(100));
    await _search(tester, query);
    expect(find.textContaining('No spends match "taxi ride'), findsOneWidget);
    expectNoOverflow(tester);
    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No spends match'), findsNothing);
    expect(find.text('Clear all'), findsNothing);
  });

  testWidgets('TC-015-43 letters make it text and a comma is grouping', (
    tester,
  ) async {
    final fixture = fixtureA.plus(
      name: 'A + 250rs',
      entries: [fixtureSpend(d(2026, 11, 12), 10000, note: '250rs')],
    );
    await _open(tester, fixture);
    await _search(tester, '250rs');
    expect(findCopy('1 result · spent ₹100'), findsOneWidget);
    expect(findCopy('250rs'), findsOneWidget);
    expect(find.text('Lunch'), findsNothing);
    await _search(tester, '99,50');
    expect(find.text('No spends match "99,50".'), findsOneWidget);
  });

  testWidgets('TC-015-45 a spend that stops matching leaves the results', (
    tester,
  ) async {
    await _open(tester, fixtureA);
    await _search(tester, 'lunch');
    expect(findCopy('2 results · spent ₹670'), findsOneWidget);
    await tester.tap(find.text('Lunch').last);
    await tester.pumpAndSettle();
    await tester.enterText(noteInput, 'Snack');
    await tester.pump();
    await tapLabel(tester, 'Save changes');
    expect(findCopy('1 result · spent ₹420'), findsOneWidget);
    expect(find.text('Mon, 9 Nov'), findsNothing);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Snack'), findsOneWidget);
    expect(find.text('Mon, 9 Nov'), findsOneWidget);
  });

  testWidgets('TC-015-50 empty tab states keep the search rules', (
    tester,
  ) async {
    // (a) no month: no search field and no chips.
    await pumpTransactions(
      tester,
      money: FakeMoneyStore(),
      size: const Size(400, 1800),
    );
    expect(find.text('Set up your month first'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('Dates:'), findsNothing);
    await tester.pumpWidget(const SizedBox());

    // (b) a month with no spends but October stored.
    final fixture = fixtureO1.copyWith(name: 'O1 empty', entries: const []);
    await _open(tester, fixture);
    expect(find.text('Search notes or amounts'), findsOneWidget);
    expect(find.text('Dates: This month'), findsOneWidget);
    expect(find.text('No spends yet this month'), findsOneWidget);
    expect(find.textContaining('budget'), findsWidgets, reason: 'Today card');
    await _tapChip(tester, 'Dates: This month');
    await tester.tap(find.text('Last month'));
    await tester.pumpAndSettle();
    expect(findCopy('3 results · spent ₹2,250'), findsOneWidget);
  });

  testWidgets('TC-015-58 transactions hint has the new wording', (
    tester,
  ) async {
    await _open(tester, fixtureA, hintsSeen: false);
    expect(find.text('Tip'), findsOneWidget);
    expect(
      find.text('Tap a spend to fix it, or tap its category to change it.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Dismiss tip'));
    await tester.pumpAndSettle();
    expect(find.text('Tip'), findsNothing);
  });

  testWidgets('TC-015-61 the no note placeholder is not searchable', (
    tester,
  ) async {
    await _open(tester, fixtureA);
    await _search(tester, 'no note');
    expect(find.text('No spends match "no note".'), findsOneWidget);
    expect(find.text('₹370'), findsNothing);
  });

  testWidgets('TC-015-62 today card and add spend ignore the search', (
    tester,
  ) async {
    await _open(tester, fixtureA);
    await _search(tester, 'lunch');
    expect(todayLineText(tester), 'budget ₹830 · spent ₹420 · ₹410 left today');
    await tester.tap(addSpendButton);
    await tester.pumpAndSettle();
    expect(find.text('Add spend'), findsOneWidget);
    expect(find.textContaining('Today · Fri, 13 Nov'), findsOneWidget);
  });
}
