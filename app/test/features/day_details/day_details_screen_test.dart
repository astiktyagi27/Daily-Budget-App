import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/home/calendar/day_cell.dart';
import 'package:daily_budget/features/home/widgets/home_today_card.dart';
import 'package:daily_budget/features/statement/open_month_statement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/bundled_fonts.dart';
import '../../helpers/day_details_harness.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/setup_harness.dart';
import '../../support/find_copy.dart';

// F-012: the day details screen (figures, rows, notices, help, sentences).

Finder _text(String text) => find.text(text);

void main() {
  setUpAll(loadBundledFonts);

  testWidgets(
    'TC-012-01 day details opens from the calendar and the today card',
    (tester) async {
      await pumpHome(tester, money: storeFor(a13), clock: clockFor(a13));
      // The Today card.
      await tester.ensureVisible(find.byType(HomeTodayCard));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(HomeTodayCard));
      await tester.pumpAndSettle();
      expect(_text('Fri, 13 Nov'), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      // A calendar cell.
      final cell = find.byWidgetPredicate(
        (w) => w is DayCell && w.cell.date == nov(11),
      );
      await tester.ensureVisible(cell);
      await tester.pumpAndSettle();
      await tester.tap(cell);
      await tester.pumpAndSettle();
      expect(_text('Wed, 11 Nov'), findsOneWidget);
      expect(_text('◆ Overspent ₹300'), findsWidgets);
    },
  );

  testWidgets('TC-012-02 back keeps the home scroll position', (tester) async {
    await pumpHome(tester, money: storeFor(a13), clock: clockFor(a13));
    final cell = find.byWidgetPredicate(
      (w) => w is DayCell && w.cell.date == nov(9),
    );
    await tester.ensureVisible(cell);
    await tester.pumpAndSettle();
    double offset() => tester
        .widget<CustomScrollView>(find.byType(CustomScrollView))
        .controller!
        .offset;
    final before = offset();
    expect(before, greaterThan(0));
    await tester.tap(cell);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(offset(), before);
  });

  testWidgets('TC-012-03 each day of example A reads as the worked table', (
    tester,
  ) async {
    Future<void> check(
      int day, {
      required String header,
      required String? budget,
      required String? spent,
      bool cover = false,
      String? result,
    }) async {
      await tester.pumpWidget(const SizedBox());
      await openDay(tester, a13, nov(day));
      expect(_text(header), findsWidgets, reason: '$day Nov');
      expect(figure(tester, 'Budget'), budget, reason: '$day Nov');
      expect(figure(tester, 'Spent'), spent, reason: '$day Nov');
      expect(
        find.text('Cover with savings'),
        cover ? findsOneWidget : findsNothing,
        reason: '$day Nov',
      );
      if (result != null) {
        expect(_text(result), findsOneWidget, reason: '$day Nov day result');
      }
    }

    await check(5, header: '● Saved ₹330', budget: '₹830', spent: '₹500');
    await check(
      6,
      header: '◆ Overspent ₹170',
      budget: '₹830',
      spent: '₹1,000',
      cover: true,
    );
    await check(
      11,
      header: '◆ Overspent ₹300',
      budget: '₹830',
      spent: '₹1,130',
      cover: true,
    );
    await check(12, header: '● Saved ₹830', budget: '₹830', spent: '₹0');
    expect(_text('Nothing spent this day'), findsOneWidget);
    await check(
      13,
      header: '● Today · ₹410 left',
      budget: '₹830',
      spent: '₹420',
      result: '● ₹410 left',
    );
    await check(14, header: 'Upcoming', budget: '₹830', spent: null);
    expect(_text("This day hasn't happened yet."), findsOneWidget);
    expect(find.text('Add spend'), findsNothing);
    expect(find.text('Day result'), findsNothing);
  });

  testWidgets('TC-012-05 entries are listed newest added first', (
    tester,
  ) async {
    await openDay(tester, a13, nov(9));
    final lunch = tester.getTopLeft(_text('Lunch')).dy;
    final noNote = tester.getTopLeft(_text('No note')).dy;
    expect(noNote, lessThan(lunch), reason: '₹370 was added second');
    expect(figure(tester, 'Spent'), '₹620');
  });

  testWidgets('TC-012-25 refund day shows spent refunds and net', (
    tester,
  ) async {
    await openDay(tester, r16, nov(16));
    expect(figure(tester, 'Spent'), '₹700');
    expect(figure(tester, 'Refunds'), '−₹500');
    expect(figure(tester, 'Net spent'), '₹200');
    expect(_text('● Saved ₹630'), findsWidgets);
    expect(_text('Spends and refunds'), findsOneWidget);
    expect(_text('Refund'), findsOneWidget);
    expect(_text('+₹500'), findsOneWidget);
    expect(_text('Amazon return'), findsOneWidget);
    expect(_text('Shoes'), findsOneWidget);
    // A day without refunds has neither line.
    await tester.pumpWidget(const SizedBox());
    await openDay(tester, a13, nov(9));
    expect(figure(tester, 'Refunds'), isNull);
    expect(figure(tester, 'Net spent'), isNull);
    expect(_text('Spends'), findsOneWidget);
  });

  testWidgets('TC-012-26 refund larger than spend gives negative net', (
    tester,
  ) async {
    final big = r16.mapEntries(
      'R16-150',
      (e) => e.moneyIn ? e.copyWith(paise: 150000) : e,
    );
    await openDay(tester, big, nov(16));
    expect(figure(tester, 'Net spent'), '−₹800');
    expect(_text('● Saved ₹1,630'), findsWidgets);
  });

  testWidgets('TC-012-27 period start day shows what changed', (tester) async {
    final launches = <(int, CalendarDate?)>[];
    await openDay(
      tester,
      m20,
      nov(13),
      overrides: [
        monthStatementLauncherProvider.overrideWithValue(
          (context, monthId, {scrollToPeriodStart}) =>
              launches.add((monthId, scrollToPeriodStart)),
        ),
      ],
    );
    expect(figure(tester, 'Budget'), '₹552');
    final notice = findCopy(
      'Budget changed on this day: salary ₹40,000 → ₹35,000',
    );
    expect(notice, findsOneWidget);
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp('^Budget changed on'))),
      isSemantics(
        label: 'Budget changed on this day: salary ₹40,000 → ₹35,000',
        hint: 'Open the month statement',
        isButton: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
    await tester.tap(notice);
    await tester.pump();
    expect(launches.single.$2, nov(13));
    // The next day has no notice; example S shows its shortfall day.
    await tester.pumpWidget(const SizedBox());
    await openDay(tester, m20, nov(14));
    expect(find.textContaining('Budget changed on this day'), findsNothing);
    expect(figure(tester, 'Budget'), '₹552');
    await tester.pumpWidget(const SizedBox());
    await openDay(tester, s8, nov(6));
    expect(figure(tester, 'Budget'), '₹0');
    expect(_text('◆ Overspent ₹200'), findsWidgets);
  });

  testWidgets('TC-012-31 day details controls have help and hints', (
    tester,
  ) async {
    await openDay(tester, a13c300, nov(11));
    final handle = tester.ensureSemantics();
    for (final (label, body) in [
      ('Budget', 'What you could spend on this day.'),
      ('Spent', 'Everything you spent on this day.'),
      (
        'Covered from savings',
        'Money you moved from your savings pot to this day.',
      ),
      (
        'Day result',
        "The day's budget minus what you spent, after any cover from "
            'savings. Green ● saved, grey ○ on budget, red ◆ overspent.',
      ),
    ]) {
      await tester.tap(find.bySemanticsLabel('More about $label'));
      await tester.pumpAndSettle();
      expect(findCopy(body), findsOneWidget, reason: label);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
    }
    expect(find.bySemanticsLabel('Remove'), findsOneWidget);
    handle.dispose();
    await tester.pumpWidget(const SizedBox());
    await openDay(tester, r16, nov(16));
    final h2 = tester.ensureSemantics();
    for (final (label, body) in [
      (
        'Refunds',
        'Money paid back to you on this day. It lowers what you spent.',
      ),
      ('Net spent', 'What you spent minus refunds.'),
    ]) {
      await tester.tap(find.bySemanticsLabel('More about $label'));
      await tester.pumpAndSettle();
      expect(findCopy(body), findsOneWidget, reason: label);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
    }
    h2.dispose();
  });

  testWidgets('TC-012-32 day details reads as sentences in order', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await openDay(tester, a13, nov(11));
    expect(
      find.bySemanticsLabel('Wednesday 11 November, overspent ₹300'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Budget, ₹830'), findsOneWidget);
    expect(find.bySemanticsLabel('Spent, ₹1,130'), findsOneWidget);
    expect(
      find.bySemanticsLabel('₹1,130, Phone bill, Wednesday 11 November'),
      findsOneWidget,
    );
    final order = [
      'Wednesday 11 November, overspent ₹300',
      'Budget, ₹830',
      'Day result, overspent ₹300',
      'Savings pot, ₹2,000',
      '₹1,130, Phone bill, Wednesday 11 November',
    ];
    var last = -1.0;
    for (final label in order) {
      final top = tester.getTopLeft(find.bySemanticsLabel(label)).dy;
      expect(top, greaterThanOrEqualTo(last), reason: label);
      last = top;
    }
    await tester.pumpWidget(const SizedBox());
    await openDay(tester, a13, nov(13));
    expect(
      find.bySemanticsLabel('Today, Friday 13 November, ₹410 left'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await openDay(tester, r16, nov(16));
    expect(find.bySemanticsLabel('Refunds, minus ₹500'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Refund, ₹500, Amazon return'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('TC-012-52 leap day opens with its title', (tester) async {
    final leap = Phase3Fixture(
      name: 'leap',
      today: CalendarDate(2028, 3, 1),
      months: [
        FixtureMonth(
          month: BudgetMonth.startIn(30, 2028, 2),
          firstBudgetedDay: CalendarDate(2028, 2, 29),
          periods: [period(CalendarDate(2028, 2, 29), e2Values())],
        ),
      ],
    );
    final handle = tester.ensureSemantics();
    await openDay(tester, leap, CalendarDate(2028, 2, 29));
    expect(_text('Tue, 29 Feb'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('^Tuesday 29 February, ')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('TC-012-53 fifty five spends in a day list and add up', (
    tester,
  ) async {
    final many = a13.plus(
      name: 'A+55',
      entries: [
        for (var i = 0; i < 55; i++)
          fixtureSpend(nov(12), 101, note: 'Item $i', hour: 8, minute: i),
      ],
    );
    await openDay(tester, many, nov(12));
    expect(figure(tester, 'Spent'), '₹55');
    expect(_text('● Saved ₹774'), findsWidgets);
    await tester.dragUntilVisible(
      _text('Item 0'),
      find.byType(SingleChildScrollView).first,
      const Offset(0, -300),
    );
    expect(_text('Item 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
