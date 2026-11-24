import 'dart:async';

import 'package:daily_budget/core/providers/calendar_providers.dart';
import 'package:daily_budget/core/providers/month_browser.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/day_details/open_day_details.dart';
import 'package:daily_budget/features/home/calendar/calendar_legend.dart';
import 'package:daily_budget/features/home/calendar/calendar_marks.dart';
import 'package:daily_budget/features/home/calendar/day_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/bundled_fonts.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/pump_app.dart' show kNarrowPhone;
import '../../helpers/setup_harness.dart';
import '../../helpers/shell.dart';
import '../../helpers/transactions_harness.dart';
import '../../support/find_copy.dart';

// F-011: the calendar section on Home, through the real app on the fakes.

typedef _Launch = ({int monthId, CalendarDate date});

Future<List<_Launch>> _pump(
  WidgetTester tester,
  Phase3Fixture fixture, {
  FakeMoneyStore? store,
  MovableClock? clock,
  double textScale = 1,
  bool hintsSeen = true,
}) async {
  final launches = <_Launch>[];
  await pumpHome(
    tester,
    money: store ?? storeFor(fixture),
    clock: clock ?? clockFor(fixture),
    textScale: textScale,
    hintsSeen: hintsSeen,
    overrides: [
      dayDetailsLauncherProvider.overrideWithValue(
        (context, {required monthId, required date}) =>
            launches.add((monthId: monthId, date: date)),
      ),
    ],
  );
  return launches;
}

Finder _cell(CalendarDate date) =>
    find.byWidgetPredicate((w) => w is DayCell && w.cell.date == date);

CalendarCell _model(WidgetTester tester, CalendarDate date) =>
    tester.widget<DayCell>(_cell(date)).cell;

Future<void> _scrollToCalendar(WidgetTester tester) async {
  await tester.dragUntilVisible(
    _cell(d(2026, 11, 5)),
    find.byType(CustomScrollView),
    const Offset(0, -200),
  );
  await tester.pumpAndSettle();
}

String _amountIn(WidgetTester tester, CalendarDate date) {
  final texts = find.descendant(of: _cell(date), matching: find.byType(Text));
  return [for (final e in texts.evaluate()) (e.widget as Text).data ?? '']
      .join('|');
}

void main() {
  // Real glyph widths: the amount fit rule measures them.
  setUpAll(loadBundledFonts);

  testWidgets('TC-011-01 header grid outside cells and 1 Dec', (tester) async {
    await _pump(tester, a13);
    await _scrollToCalendar(tester);
    expect(findCopy('5 Nov – 4 Dec 2026'), findsOneWidget);
    expect(find.byType(DayCell), findsNWidgets(35));
    expect(_model(tester, d(2026, 11, 2)).kind, CellKind.outside);
    expect(_model(tester, d(2026, 12, 6)).kind, CellKind.outside);
    expect(find.text('1 Dec'), findsOneWidget);
    // Outside cells are not in the screen-reader order and not tappable.
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp('Monday 2 November')), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('Thursday 5 November, spent')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('TC-011-08 cells of example A show their amounts and marks', (
    tester,
  ) async {
    await _pump(tester, a13);
    await _scrollToCalendar(tester);
    const amounts = {
      5: '₹500',
      6: '₹1,000',
      7: '₹830',
      9: '₹620',
      11: '₹1,130',
      12: '₹0',
      13: '₹420',
    };
    for (final MapEntry(key: day, value: amount) in amounts.entries) {
      expect(_amountIn(tester, d(2026, 11, day)), contains(amount));
    }
    CalendarMark? mark(int day) {
      final paint = find.descendant(
        of: _cell(d(2026, 11, day)),
        matching: find.byType(CalendarMarkPaint),
      );
      return paint.evaluate().isEmpty
          ? null
          : tester.widget<CalendarMarkPaint>(paint).mark;
    }

    expect(mark(5), CalendarMark.saved);
    expect(mark(6), CalendarMark.overspent);
    expect(mark(7), CalendarMark.onBudget);
    expect(mark(12), CalendarMark.saved);
    expect(mark(13), CalendarMark.saved, reason: 'today, saved so far');
    // TC-011-09: upcoming days have no amount and no mark.
    for (final day in [14, 20, 30]) {
      expect(mark(day), isNull);
      expect(_amountIn(tester, d(2026, 11, day)), '$day');
    }
    expect(_model(tester, d(2026, 11, 13)).kind, CellKind.today);
    final handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(
        'Today, Friday 13 November, spent ₹420 so far, ₹410 left',
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('TC-011-23 short forms on the cells', (tester) async {
    const forms = {
      9999: '₹9,999',
      10000: '₹10k',
      12999: '₹12k',
      159999: '₹1.5L',
      100000000: '₹10Cr',
    };
    for (final MapEntry(key: rupees, value: expected) in forms.entries) {
      await tester.pumpWidget(const SizedBox());
      final big = a13.plus(
        name: 'big$rupees',
        entries: [fixtureSpend(d(2026, 11, 12), rupees * 100)],
      );
      await _pump(tester, big);
      await _scrollToCalendar(tester);
      expect(_amountIn(tester, d(2026, 11, 12)), contains(expected));
    }
  });

  testWidgets('TC-011-25 previous and next month', (tester) async {
    await _pump(tester, octNov);
    await _scrollToCalendar(tester);
    expect(findCopy('5 Nov – 4 Dec 2026'), findsOneWidget);
    expect(find.text('Ended'), findsNothing);
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(findCopy('5 Oct – 4 Nov 2026'), findsOneWidget);
    expect(find.text('Ended'), findsOneWidget);
    // Every day is final: no ring and no upcoming box.
    final kinds = {
      for (final w in tester.widgetList<DayCell>(find.byType(DayCell)))
        w.cell.kind,
    };
    expect(kinds, isNot(contains(CellKind.today)));
    expect(kinds, isNot(contains(CellKind.upcoming)));
    final handle = tester.ensureSemantics();
    // ‹ is disabled on the first stored month with its hint.
    expect(
      tester.getSemantics(find.bySemanticsLabel('Previous month')),
      isSemantics(
        label: 'Previous month',
        hint: 'No earlier months',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(findCopy('5 Nov – 4 Dec 2026'), findsOneWidget);
    final handle2 = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Next month')),
      isSemantics(
        label: 'Next month',
        hint: 'This is the current month',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle2.dispose();
  });

  testWidgets('TC-011-26 This month goes back to the current month', (
    tester,
  ) async {
    await _pump(tester, octNov);
    await _scrollToCalendar(tester);
    expect(find.text('This month'), findsNothing);
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('This month'));
    await tester.pumpAndSettle();
    expect(findCopy('5 Nov – 4 Dec 2026'), findsOneWidget);
    expect(find.text('This month'), findsNothing);
  });

  testWidgets('TC-011-27 swiping does the same as the buttons', (tester) async {
    await _pump(tester, octNov);
    await _scrollToCalendar(tester);
    // Swipe right: the previous month.
    await tester.fling(_cell(d(2026, 11, 9)), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(findCopy('5 Oct – 4 Nov 2026'), findsOneWidget);
    // Swipe right at the first month: nothing.
    await tester.fling(_cell(d(2026, 10, 9)), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(findCopy('5 Oct – 4 Nov 2026'), findsOneWidget);
    // Swipe left: the next month.
    await tester.fling(_cell(d(2026, 10, 9)), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(findCopy('5 Nov – 4 Dec 2026'), findsOneWidget);
    // Swipe left on the current month: nothing.
    await tester.fling(_cell(d(2026, 11, 9)), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(findCopy('5 Nov – 4 Dec 2026'), findsOneWidget);
  });

  testWidgets('TC-011-28 tap opens day details for tappable cells only', (
    tester,
  ) async {
    final store = storeFor(a13);
    final launches = await _pump(tester, a13, store: store);
    await _scrollToCalendar(tester);
    final month = store.months.single.id;
    for (final day in [6, 13, 20]) {
      await tester.tap(_cell(d(2026, 11, day)));
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(launches.map((l) => l.date.day), [6, 13, 20]);
    expect(launches.every((l) => l.monthId == month), isTrue);
    // Outside cells do nothing.
    await tester.tap(_cell(d(2026, 11, 3)), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    expect(launches, hasLength(3));
  });

  testWidgets('TC-011-52 double tap on a day opens one screen', (tester) async {
    final launches = await _pump(tester, a13);
    await _scrollToCalendar(tester);
    await tester.tap(_cell(d(2026, 11, 6)));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(_cell(d(2026, 11, 6)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(launches, hasLength(1));
  });

  testWidgets('TC-011-20 not budgeted days cannot be tapped', (tester) async {
    final launches = await _pump(tester, f12);
    await _scrollToCalendar(tester);
    expect(_model(tester, d(2026, 11, 7)).kind, CellKind.notBudgeted);
    await tester.tap(_cell(d(2026, 11, 7)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(launches, isEmpty);
    // TC-011-21: the caption names the range.
    expect(
      findCopy("Days before 10 Nov aren't budgeted. You started on 10 Nov."),
      findsOneWidget,
    );
    final handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(
        'Saturday 7 November, not budgeted, before you started',
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('TC-011-18 the change tick is on 13 Nov only', (tester) async {
    await _pump(tester, m20);
    await _scrollToCalendar(tester);
    expect(
      find.byType(CalendarChangeTick),
      findsNWidgets(2),
      reason:
          'one in '
          'the legend, one in the grid',
    );
    expect(
      find.descendant(
        of: _cell(d(2026, 11, 13)),
        matching: find.byType(CalendarChangeTick),
      ),
      findsOneWidget,
    );
    expect(findCopy('Budget changed'), findsOneWidget);
    // A month without a change has no legend item.
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, a13);
    await _scrollToCalendar(tester);
    expect(find.byType(CalendarChangeTick), findsNothing);
  });

  testWidgets('TC-011-29 new month not set up shows last month', (
    tester,
  ) async {
    await _pump(tester, a13.copyWith(today: d(2026, 12, 5)));
    await tester.dragUntilVisible(
      find.text('Last month · 5 Nov – 4 Dec 2026'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    expect(find.text('Last month · 5 Nov – 4 Dec 2026'), findsOneWidget);
    expect(find.text('Ended'), findsNothing);
    final kinds = {
      for (final w in tester.widgetList<DayCell>(find.byType(DayCell)))
        w.cell.kind,
    };
    expect(kinds, isNot(contains(CellKind.upcoming)));
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Next month')),
      isSemantics(
        label: 'Next month',
        hint: 'This is the latest month',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('TC-011-30 a past day edit updates its cell live', (
    tester,
  ) async {
    final store = storeFor(a13);
    await _pump(tester, a13, store: store);
    await _scrollToCalendar(tester);
    expect(_amountIn(tester, d(2026, 11, 7)), contains('₹830'));
    expect(_model(tester, d(2026, 11, 7)).kind, CellKind.onBudget);
    addSpendTo(store, d(2026, 11, 7), 10000);
    store.notify();
    await tester.pumpAndSettle();
    expect(_amountIn(tester, d(2026, 11, 7)), contains('₹930'));
    expect(_model(tester, d(2026, 11, 7)).kind, CellKind.overspent);
  });

  testWidgets('TC-011-13 the ring moves at midnight', (tester) async {
    final clock = MovableClock(d(2026, 11, 13));
    await _pump(tester, a13, clock: clock);
    await _scrollToCalendar(tester);
    expect(_model(tester, d(2026, 11, 13)).kind, CellKind.today);
    clock.moveTo(d(2026, 11, 14));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DayCell).first),
    );
    container.read(todayProvider.notifier).refresh();
    await tester.pumpAndSettle();
    expect(_model(tester, d(2026, 11, 13)).kind, CellKind.saved);
    expect(_amountIn(tester, d(2026, 11, 13)), contains('₹420'));
    expect(_model(tester, d(2026, 11, 14)).kind, CellKind.today);
  });

  testWidgets('TC-011-31 large text hides the amounts, labels keep them', (
    tester,
  ) async {
    await _pump(tester, a13, textScale: 1.3);
    await _scrollToCalendar(tester);
    expect(_amountIn(tester, d(2026, 11, 11)), contains('₹1,130'));
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, a13, textScale: 2);
    await _scrollToCalendar(tester);
    expect(_amountIn(tester, d(2026, 11, 11)), '11');
    final handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp('Wednesday 11 November, spent ₹1,130')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('TC-011-23 an amount that would shrink under 9 sp is hidden', (
    tester,
  ) async {
    // A day with ₹9,999 of refunds: net −₹9,999 (design system §7.5).
    final refunds = a13.plus(
      name: 'A-refund-9999',
      entries: [fixtureMoneyIn(d(2026, 11, 12), 999900)],
    );
    // On a 360 dp phone it fits at 9.2 sp and is shown.
    await _pump(tester, refunds);
    await _scrollToCalendar(tester);
    expect(_amountIn(tester, d(2026, 11, 12)), contains('9,999'));
    // On a 320 dp phone it would need 8.8 sp, so the cell hides it; the
    // label keeps the full amount.
    await tester.pumpWidget(const SizedBox());
    await pumpHome(
      tester,
      money: storeFor(refunds),
      clock: clockFor(refunds),
      size: kNarrowPhone,
    );
    await tester.ensureVisible(_cell(d(2026, 11, 12)));
    await tester.pumpAndSettle();
    expect(_amountIn(tester, d(2026, 11, 12)), '12');
    final handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp('net minus ₹9,999 after refunds')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('TC-011-49 loading draws boxes and never a rupee amount', (
    tester,
  ) async {
    final store = storeFor(a13);
    final held = store.readDelay = Completer<void>();
    await pumpHome(tester, money: store, clock: clockFor(a13));
    expect(find.byType(DayCell), findsNothing);
    held.complete();
    await tester.pumpAndSettle();
    expect(find.byType(DayCell), findsNWidgets(35));
  });

  testWidgets('TC-011-50 a past month that fails shows Try again', (
    tester,
  ) async {
    final store = storeFor(octNov);
    await _pump(tester, octNov, store: store);
    await _scrollToCalendar(tester);
    final october = store.months.first.id;
    store.readFailsFor(october);
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load this month."), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    store.readFailsFor(october, fails: false);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load this month."), findsNothing);
    expect(findCopy('5 Oct – 4 Nov 2026'), findsOneWidget);
  });

  testWidgets('TC-011-51 the viewed month is kept across tabs', (tester) async {
    await _pump(tester, octNov);
    await _scrollToCalendar(tester);
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    await tapTab(tester, 'Transactions');
    await tapTab(tester, 'Home');
    await _scrollToCalendar(tester);
    expect(findCopy('5 Oct – 4 Nov 2026'), findsOneWidget);
  });

  testWidgets('TC-011-53 the calendar tip waits for the home tip', (
    tester,
  ) async {
    await _pump(tester, a13, hintsSeen: false);
    expect(find.text('Tap a day to see its spends.'), findsNothing);
    expect(
      find.textContaining('Use the tabs at the bottom to move around'),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Tap a day to see its spends.'), findsOneWidget);
  });

  testWidgets('TC-011-54 the legend and its help', (tester) async {
    await _pump(tester, a13);
    await _scrollToCalendar(tester);
    Finder inLegend(String text) => find.descendant(
      of: find.byType(CalendarLegend),
      matching: find.text(text),
    );
    expect(inLegend('Saved'), findsOneWidget);
    expect(inLegend('On budget'), findsOneWidget);
    expect(inLegend('Overspent'), findsOneWidget);
    expect(inLegend('Budget changed'), findsNothing);
    await tester.tap(find.bySemanticsLabel('More about Calendar'));
    await tester.pumpAndSettle();
    expect(
      findCopy(
        'Each day shows what you spent. Green ● means you spent less than '
        "the day's budget, grey ○ exactly the budget, red ◆ more. A small "
        'indigo line at the top of a day means your budget changed that day. '
        'Tap a day to see its spends.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('TC-011-65 browse position comes from the month index', (
    tester,
  ) async {
    final store = storeFor(octNov);
    await _pump(tester, octNov, store: store);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DayCell).first),
    );
    final browse = container
        .read(monthBrowseProvider(kCalendarBrowserKey))
        .requireValue!;
    expect(browse.isLatest, isTrue);
    expect(browse.canGoBack, isTrue);
    expect(browse.canGoForward, isFalse);
    expect(browse.previousId, store.months.first.id);
  });
}
