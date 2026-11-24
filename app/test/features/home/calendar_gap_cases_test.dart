import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/home/calendar/calendar_marks.dart';
import 'package:daily_budget/features/home/calendar/day_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/bundled_fonts.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/setup_harness.dart';
import '../../support/find_copy.dart';

// F-011 cases that had no test carrying their ID (Tester 1, Step 8):
// TC-011-11, -15, -35, -42, -43, -47, -48. TC-011-35 reads the real
// semantics traversal order; the others read the cells of the real Home.

Future<void> _pump(
  WidgetTester tester,
  Phase3Fixture fixture, {
  FakeMoneyStore? store,
  MovableClock? clock,
}) => pumpHome(
  tester,
  money: store ?? storeFor(fixture),
  clock: clock ?? clockFor(fixture),
);

Finder _cell(CalendarDate date) =>
    find.byWidgetPredicate((w) => w is DayCell && w.cell.date == date);

CalendarCell _model(WidgetTester tester, CalendarDate date) =>
    tester.widget<DayCell>(_cell(date)).cell;

CalendarMark? _markIn(WidgetTester tester, CalendarDate date) {
  final paint = find.descendant(
    of: _cell(date),
    matching: find.byType(CalendarMarkPaint),
  );
  return paint.evaluate().isEmpty
      ? null
      : tester.widget<CalendarMarkPaint>(paint).mark;
}

String _amountIn(WidgetTester tester, CalendarDate date) {
  final texts = find.descendant(of: _cell(date), matching: find.byType(Text));
  return [for (final e in texts.evaluate()) (e.widget as Text).data ?? '']
      .join('|');
}

Future<void> _scrollToCalendar(WidgetTester tester) async {
  await tester.dragUntilVisible(
    _cell(d(2026, 11, 5)),
    find.byType(CustomScrollView),
    const Offset(0, -200),
  );
  await tester.pumpAndSettle();
}

String _hint(WidgetTester tester, String label) =>
    tester.getSemantics(find.bySemanticsLabel(label)).getSemanticsData().hint;

/// Semantic labels of the calendar in screen-reader order, from the range
/// heading to the last day cell (the rest of Home is left out).
List<({String label, bool button})> _readerOrder(
  WidgetTester tester,
  String firstLabel,
) {
  final all = [
    for (final node in tester.semantics.simulatedAccessibilityTraversal())
      (
        label: node.getSemanticsData().label,
        button: node.getSemanticsData().flagsCollection.isButton,
      ),
  ];
  final start = all.indexWhere((n) => n.label == firstLabel);
  expect(start, isNonNegative, reason: 'the range heading is read');
  final end = all.lastIndexWhere(
    (n) => RegExp(r'^(Today, )?\w+day \d+ \w+,').hasMatch(n.label),
  );
  return all.sublist(start, end + 1);
}

Future<List<int>> _pixels(WidgetTester tester, CalendarMark mark) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: key,
          // One colour for every mark, and a grey-scale filter over it:
          // only the shape is left to tell the marks apart.
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.2126, 0.7152, 0.0722, 0, 0, //
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0, 0, 0, 1, 0,
            ]),
            child: ColoredBox(
              color: const Color(0xFFFFFFFF),
              child: CalendarMarkPaint(
                mark: mark,
                color: const Color(0xFF000000),
                size: 24,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData();
    return data!.buffer.asUint8List().toList();
  });
  return bytes!;
}

void main() {
  setUpAll(loadBundledFonts);

  testWidgets('TC-011-11 marks tell the days apart without colour', (
    tester,
  ) async {
    // The marks themselves: drawn in ONE colour under a grey-scale filter,
    // the three shapes (disc, ring, diamond) still differ pixel for pixel.
    final saved = await _pixels(tester, CalendarMark.saved);
    final onBudget = await _pixels(tester, CalendarMark.onBudget);
    final overspent = await _pixels(tester, CalendarMark.overspent);
    expect(saved, isNot(onBudget));
    expect(saved, isNot(overspent));
    expect(onBudget, isNot(overspent));
    // Dark pixel = alpha-composited luminance well below the white ground.
    bool dark(List<int> px, int x, int y) => px[(y * 24 + x) * 4] < 128;
    // Centre: disc and diamond are solid, the ring is hollow.
    expect(dark(saved, 12, 12), isTrue);
    expect(dark(onBudget, 12, 12), isFalse, reason: 'a ring is hollow');
    expect(dark(overspent, 12, 12), isTrue);
    // Near a corner: the disc reaches it, the diamond does not.
    expect(dark(saved, 5, 5), isTrue);
    expect(dark(overspent, 5, 5), isFalse, reason: 'a diamond has corners');
    expect(dark(overspent, 12, 2), isTrue, reason: 'the diamond top point');
    // The real cells of 5, 6 and 7 Nov carry the three different shapes and
    // words, so nothing depends on the colour.
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, a13);
    await _scrollToCalendar(tester);
    expect(_markIn(tester, d(2026, 11, 5)), CalendarMark.saved);
    expect(_markIn(tester, d(2026, 11, 6)), CalendarMark.overspent);
    expect(_markIn(tester, d(2026, 11, 7)), CalendarMark.onBudget);
    final handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp('^Thursday 5 November.*saved')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('^Friday 6 November.*overspent')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('^Saturday 7 November.*on budget')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('TC-011-15 a cover taken back turns the cell red again', (
    tester,
  ) async {
    final store = storeFor(w3);
    await _pump(tester, w3, store: store);
    await _scrollToCalendar(tester);
    final nov6 = d(2026, 11, 6);
    final handle = tester.ensureSemantics();
    // Before: on budget thanks to the 17,000 cover.
    expect(_markIn(tester, nov6), CalendarMark.onBudget);
    expect(_amountIn(tester, nov6), contains('₹1,000'));
    expect(
      find.bySemanticsLabel(
        'Friday 6 November, spent ₹1,000, on budget, '
        '₹170 covered from savings',
      ),
      findsOneWidget,
    );
    // Edit 5 Nov to 83,000: the pot falls to 0 and the cover is cut to 0.
    final monthId = store.months.single.id;
    final list = store.spendsByMonth[monthId]!;
    final index = list.indexWhere((s) => s.spend.date == d(2026, 11, 5));
    final old = list[index];
    list[index] = StoredSpend(
      spend: Spend(
        id: old.spend.id,
        date: old.spend.date,
        amount: const Paise(83000),
        createdAt: old.spend.createdAt,
      ),
      note: old.note,
    );
    store
      ..reconcile(monthId, w3.today)
      ..notify();
    await tester.pumpAndSettle();
    expect(_markIn(tester, nov6), CalendarMark.overspent);
    expect(_amountIn(tester, nov6), contains('₹1,000'));
    expect(
      find.bySemanticsLabel('Friday 6 November, spent ₹1,000, overspent ₹170'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('TC-011-35 screen reader walks the calendar in order', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, octNov);
    await _scrollToCalendar(tester);
    final order = _readerOrder(tester, '5 Nov – 4 Dec 2026');
    final head = order.take(5).map((n) => n.label.toLowerCase()).toList();
    expect(head, [
      '5 nov – 4 dec 2026',
      'previous month',
      'next month',
      'saved, on budget, overspent',
      'more about calendar',
    ]);
    // Every budget day in date order, 5 Nov to 4 Dec, each a button with its
    // sentence; outside cells are skipped; today and upcoming are included.
    final days = order.skip(5).toList();
    expect(days, hasLength(30));
    expect(days.every((n) => n.button), isTrue);
    expect(days.first.label, 'Thursday 5 November, spent ₹500, saved ₹330');
    expect(
      days[8].label,
      'Today, Friday 13 November, spent ₹420 so far, ₹410 left',
    );
    expect(days[9].label, 'Saturday 14 November, upcoming');
    expect(days.last.label, 'Friday 4 December, upcoming');
    expect(
      days.any((n) => n.label.contains('Monday 2 November')),
      isFalse,
      reason: 'outside cells are skipped',
    );
    // A not budgeted day (F12) is read but is not a button.
    await _pump(tester, f12);
    await _scrollToCalendar(tester);
    final f = _readerOrder(tester, '5 Nov – 4 Dec 2026');
    final notBudgeted = f.firstWhere(
      (n) => n.label.startsWith('Thursday 5 November, not budgeted'),
    );
    expect(notBudgeted.button, isFalse);
    expect(
      f.firstWhere((n) => n.label.contains('Tuesday 10 November,')).button,
      isTrue,
    );
    handle.dispose();
  });

  testWidgets('TC-011-35 screen reader order on a past month', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, octNov);
    await _scrollToCalendar(tester);
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    // D-095: `Ended` and the range are one heading node (one sentence), then
    // the two main controls as on the current month, and the `This month`
    // shortcut last.
    final order = _readerOrder(tester, 'Ended, 5 Oct – 4 Nov 2026');
    expect(order.take(4).map((n) => n.label).toList(), [
      'Ended, 5 Oct – 4 Nov 2026',
      'Previous month',
      'Next month',
      'This month',
    ]);
    handle.dispose();
  });

  testWidgets('TC-011-42 the last day and the day after', (tester) async {
    final lastDay = a13.copyWith(name: 'A4Dec', today: d(2026, 12, 4));
    final clock = clockFor(lastDay);
    await _pump(tester, lastDay, clock: clock);
    await _scrollToCalendar(tester);
    final handle = tester.ensureSemantics();
    // 4 Dec: the ring is on 4 Dec, 13 Nov to 3 Dec are final, › is disabled.
    expect(_model(tester, d(2026, 12, 4)).kind, CellKind.today);
    var kinds = {
      for (
        var day = d(2026, 11, 13);
        day.compareTo(d(2026, 12, 3)) <= 0;
        day = day.addDays(1)
      )
        _model(tester, day).kind,
    };
    expect(kinds, isNot(contains(CellKind.today)));
    expect(kinds, isNot(contains(CellKind.upcoming)));
    expect(_hint(tester, 'Next month'), 'This is the current month');
    expect(find.text('Last month · 5 Nov – 4 Dec 2026'), findsNothing);
    // 00:01 on 5 Dec: the month is last month, 4 Dec is final.
    clock.moveTo(d(2026, 12, 5));
    ProviderScope.containerOf(tester.element(find.byType(DayCell).first))
        .read(todayProvider.notifier)
        .refresh();
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Last month · 5 Nov – 4 Dec 2026'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    expect(find.text('Last month · 5 Nov – 4 Dec 2026'), findsOneWidget);
    kinds = {
      for (final w in tester.widgetList<DayCell>(find.byType(DayCell)))
        w.cell.kind,
    };
    expect(kinds, isNot(contains(CellKind.today)));
    expect(kinds, isNot(contains(CellKind.upcoming)));
    expect(_model(tester, d(2026, 12, 4)).kind, isNot(CellKind.outside));
    expect(_hint(tester, 'Next month'), 'This is the latest month');
    handle.dispose();
  });

  testWidgets('TC-011-43 previous month skips months that were never set up', (
    tester,
  ) async {
    FixtureMonth month(BudgetMonth m) => FixtureMonth(
      month: m,
      firstBudgetedDay: m.start,
      periods: [
        period(m.start, e2Values(), changedAt: at(m.start.addDays(-1), 0)),
      ],
    );
    final gap = Phase3Fixture(
      name: 'SEP-DEC',
      today: d(2026, 12, 10),
      months: [
        month(BudgetMonth.startIn(5, 2026, 9)),
        month(BudgetMonth.startIn(5, 2026, 12)),
      ],
    );
    await _pump(tester, gap);
    await tester.dragUntilVisible(
      find.byTooltip('Previous month'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(findCopy('5 Dec 2026 – 4 Jan 2027'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    // Real dates: October and November do not exist, so it jumps to Sep.
    expect(findCopy('5 Sep – 4 Oct 2026'), findsOneWidget);
    final handle = tester.ensureSemantics();
    expect(_hint(tester, 'Previous month'), 'No earlier months');
    handle.dispose();
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(findCopy('5 Dec 2026 – 4 Jan 2027'), findsOneWidget);
  });

  testWidgets('TC-011-47 many spends on a day show their total', (
    tester,
  ) async {
    final many = a13.copyWith(
      name: 'A-55',
      entries: [
        for (final e in a13.current.entries)
          if (e.date != d(2026, 11, 9)) e,
        for (var i = 0; i < 55; i++)
          fixtureSpend(d(2026, 11, 9), 101, hour: 10, minute: i),
      ],
    );
    await _pump(tester, many);
    await _scrollToCalendar(tester);
    final nov9 = d(2026, 11, 9);
    // 55 x 1.01 = 55.55: the cell shows ₹55 (rounded down), one cell, no list.
    expect(_amountIn(tester, nov9), contains('₹55'));
    expect(_amountIn(tester, nov9), isNot(contains('₹55.')));
    expect(_markIn(tester, nov9), CalendarMark.saved);
    expect(_cell(nov9), findsOneWidget);
    final handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel('Monday 9 November, spent ₹55, saved ₹774'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('TC-011-48 forty paise shows zero in the cell', (tester) async {
    final tiny = a13.plus(
      name: 'A+40',
      entries: [fixtureSpend(d(2026, 11, 12), 40)],
    );
    await _pump(tester, tiny);
    await _scrollToCalendar(tester);
    final nov12 = d(2026, 11, 12);
    expect(_amountIn(tester, nov12), contains('₹0'));
    expect(_markIn(tester, nov12), CalendarMark.saved);
    final handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel('Thursday 12 November, spent ₹0, saved ₹829'),
      findsOneWidget,
    );
    handle.dispose();
  });
}
