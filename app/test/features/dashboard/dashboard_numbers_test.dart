import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/dashboard/widgets/day_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/dashboard_harness.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/transactions_harness.dart';
import '../../support/app_lifecycle.dart';
import '../../support/find_copy.dart';

CalendarDate _nov(int day) => d(2026, 11, day);

const _first = "Your first day isn't over yet. Check back tomorrow.";

String _caption(int days) =>
    "Based on the $days days that have ended. Today isn't counted until "
    'midnight.';

/// The marks of the day strip as a person reads them: `● ◆ ○`.
String _strip(WidgetTester tester) => plainCopy(
  tester
      .widget<Text>(find.byKey(DayStrip.stripKey))
      .textSpan!
      .toPlainText()
      .replaceAll(' ', ' '),
);

/// E2, Today(13 Nov), with the given spends.
Phase3Fixture _spends(
  List<(int, int)> entries, {
  List<FixtureEntry> extra = const [],
  CalendarDate? today,
}) => fixtureA.copyWith(
  name: 'custom',
  today: today ?? _nov(13),
  entries: [
    for (final (day, paise) in entries) fixtureSpend(_nov(day), paise),
    ...extra,
  ],
);

void main() {
  testWidgets('TC-013-12 numbers match worked example a', (tester) async {
    await pumpDashboard(tester, fixture: fixtureA);
    expect(findCopy('Wed, 11 Nov · ₹1,130'), findsOneWidget);
    expect(findCopy('₹638 a day'), findsOneWidget);
    expect(
      findCopy('● 4 saved · ○ 2 on budget · ◆ 2 overspent'),
      findsOneWidget,
    );
    expect(findCopy('incl. 1 covered from savings'), findsNothing);
    expect(findCopy(_caption(8)), findsOneWidget);
    expect(_strip(tester), '● ◆ ○ ● ● ○ ◆ ●');
  });

  testWidgets('TC-013-14 highest day row opens day details for that day', (
    tester,
  ) async {
    final calls = await pumpDashboard(
      tester,
      fixture: fixtureA,
      size: const Size(360, 1400),
    );
    final row = find.bySemanticsLabel(
      'Highest-spending day, Wednesday 11 November, ₹1,130',
    );
    expect(
      tester
          .getSize(
            find
                .ancestor(
                  of: findCopy('Wed, 11 Nov · ₹1,130'),
                  matching: find.byType(InkWell),
                )
                .first,
          )
          .height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(calls.days, hasLength(1));
    expect(calls.days.single.date, _nov(11));
    expect(calls.days.single.monthId, 1);
    expect(find.bySemanticsLabel('This month, selected, 1 of 2'), findsOne);
  });

  testWidgets('TC-013-15 a cover changes only the day counts', (tester) async {
    await pumpDashboard(tester, fixture: fixtureAPlusCover);
    expect(
      findCopy('● 4 saved · ○ 3 on budget · ◆ 1 overspent'),
      findsOneWidget,
    );
    expect(findCopy('incl. 1 covered from savings'), findsOneWidget);
    expect(findCopy('Wed, 11 Nov · ₹1,130'), findsOneWidget);
    expect(findCopy('₹638 a day'), findsOneWidget);
    expect(_strip(tester), '● ◆ ○ ● ● ○ ○ ●');
  });

  testWidgets('TC-013-16 a tie shows the earliest day and plus one more day', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      fixture: fixtureA.mapEntries(
        'A tie',
        (e) => e.date == _nov(6) ? e.copyWith(paise: 113000) : e,
      ),
    );
    expect(findCopy('Fri, 6 Nov · ₹1,130 +1 more day'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Highest-spending day.*plus 1 more day')),
      findsOneWidget,
    );
  });

  testWidgets('TC-013-17 first day shows the first day line', (tester) async {
    await pumpDashboard(tester, fixture: _spends([(5, 42000)], today: _nov(5)));
    expect(findCopy('All ₹420 so far is in Other.'), findsOneWidget);
    expect(findCopy(_first), findsOneWidget);
    expect(find.textContaining('Based on'), findsNothing);
    expect(find.textContaining('Highest-spending'), findsNothing);
    expect(find.byKey(DayStrip.stripKey), findsNothing);
  });

  testWidgets('TC-013-18 first day of a mid month start shows the first day '
      'line', (tester) async {
    await pumpDashboard(
      tester,
      fixture: fixtureF.copyWith(
        today: _nov(10),
        entries: [fixtureSpend(_nov(10), 30000)],
      ),
    );
    expect(findCopy('10 Nov – 4 Dec 2026 · so far'), findsOneWidget);
    expect(findCopy(_first), findsOneWidget);
    expect(find.textContaining('5 Nov'), findsNothing);
  });

  testWidgets('TC-013-19 shortfall month figures match example s', (
    tester,
  ) async {
    await pumpDashboard(tester, fixture: fixtureS);
    expect(findCopy('All ₹200 so far is in Other.'), findsOneWidget);
    expect(findCopy('Fri, 6 Nov · ₹200'), findsOneWidget);
    expect(findCopy('₹66 a day'), findsOneWidget);
    expect(
      findCopy('● 0 saved · ○ 2 on budget · ◆ 1 overspent'),
      findsOneWidget,
    );
    expect(_strip(tester), '○ ◆ ○');
    // A count of 0 keeps its mark but in the neutral colour.
    final days = tester.widget<Text>(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            plainCopy(w.textSpan?.toPlainText() ?? '').startsWith('● 0 saved'),
      ),
    );
    final zero = (days.textSpan! as TextSpan).children!.first as TextSpan;
    final saved = (zero.children!.first as TextSpan).style!.color;
    const neutral = Color(0xFF68646E);
    expect(saved, neutral);
  });

  testWidgets('TC-013-20 a mid month start counts only budgeted days', (
    tester,
  ) async {
    await pumpDashboard(tester, fixture: fixtureF);
    expect(findCopy('10 Nov – 4 Dec 2026 · so far'), findsOneWidget);
    expect(findCopy(_caption(2)), findsOneWidget);
    expect(findCopy('Tue, 10 Nov · ₹1,500'), findsOneWidget);
    expect(findCopy('₹1,000 a day'), findsOneWidget);
    expect(
      findCopy('● 1 saved · ○ 0 on budget · ◆ 1 overspent'),
      findsOneWidget,
    );
  });

  testWidgets('TC-013-33 negative net spend shows a negative average', (
    tester,
  ) async {
    await pumpDashboard(tester, fixture: fixtureN);
    expect(findCopy('All ₹200 so far is in Other.'), findsOneWidget);
    expect(findCopy('−₹500'), findsOneWidget);
    expect(findCopy('−₹300'), findsOneWidget);
    expect(findCopy('Thu, 5 Nov · ₹200'), findsOneWidget);
    expect(findCopy('−₹37 a day'), findsOneWidget);
    expect(
      findCopy('● 8 saved · ○ 0 on budget · ◆ 0 overspent'),
      findsOneWidget,
    );
  });

  testWidgets('TC-013-34 a month with no spends has calm numbers', (
    tester,
  ) async {
    await pumpDashboard(tester, fixture: _spends([]));
    expect(findCopy('Nothing spent yet this month.'), findsOneWidget);
    expect(findCopy('No spends yet'), findsOneWidget);
    expect(findCopy('₹0 a day'), findsOneWidget);
    expect(
      findCopy('● 8 saved · ○ 0 on budget · ◆ 0 overspent'),
      findsOneWidget,
    );
    // Not a button.
    expect(
      find.bySemanticsLabel('Highest-spending day, No spends yet'),
      findsOneWidget,
    );
    final node = tester.getSemantics(
      find.bySemanticsLabel('Highest-spending day, No spends yet'),
    );
    expect(node.flagsCollection.isButton, isFalse);
  });

  testWidgets('TC-013-38 future dated spends are not counted', (tester) async {
    await pumpDashboard(
      tester,
      fixture: fixtureA.plus(
        name: 'A future',
        entries: [fixtureSpend(_nov(15), 40000)],
      ),
    );
    expect(findCopy('All ₹5,530 so far is in Other.'), findsOneWidget);
    expect(findCopy('₹638 a day'), findsOneWidget);
    expect(
      findCopy('● 4 saved · ○ 2 on budget · ◆ 2 overspent'),
      findsOneWidget,
    );
    await tester.tap(find.text('One day'));
    await tester.pumpAndSettle();
    await tester.tap(findCopy('Fri, 13 Nov'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
          .lastDate,
      DateTime(2026, 11, 13),
    );
  });

  testWidgets('TC-013-40 today joins the numbers at midnight', (tester) async {
    final clock = TestClock(DateTime(2026, 11, 13, 14));
    await pumpDashboard(tester, fixture: fixtureA, clock: clock);
    expect(findCopy('₹638 a day'), findsOneWidget);
    clock.now = DateTime(2026, 11, 14, 0, 1);
    sendToBackground(tester);
    bringToForeground(tester);
    await tester.pumpAndSettle();
    expect(findCopy('₹614 a day'), findsOneWidget);
    expect(findCopy('Wed, 11 Nov · ₹1,130'), findsOneWidget);
    expect(
      findCopy('● 5 saved · ○ 2 on budget · ◆ 2 overspent'),
      findsOneWidget,
    );
    expect(findCopy(_caption(9)), findsOneWidget);
  });

  testWidgets('TC-013-40 a big spend today moves only the categories', (
    tester,
  ) async {
    final big = fixtureA.plus(
      name: 'A big',
      entries: [fixtureSpend(_nov(13), 1000000)],
    );
    final clock = TestClock(DateTime(2026, 11, 13, 14));
    await pumpDashboard(tester, fixture: big, clock: clock);
    expect(findCopy('All ₹15,530 so far is in Other.'), findsOneWidget);
    expect(findCopy('₹638 a day'), findsOneWidget);
    expect(
      findCopy('● 4 saved · ○ 2 on budget · ◆ 2 overspent'),
      findsOneWidget,
    );
    clock.now = DateTime(2026, 11, 14, 0, 1);
    sendToBackground(tester);
    bringToForeground(tester);
    await tester.pumpAndSettle();
    expect(findCopy('₹1,725 a day'), findsOneWidget);
    expect(findCopy('Fri, 13 Nov · ₹10,420'), findsOneWidget);
    expect(
      findCopy('● 4 saved · ○ 2 on budget · ◆ 3 overspent'),
      findsOneWidget,
    );
  });

  testWidgets('TC-013-41 a mid month change needs no special display', (
    tester,
  ) async {
    await pumpDashboard(tester, fixture: fixtureM20);
    expect(findCopy('1 – 30 Nov 2026 · so far'), findsOneWidget);
    expect(findCopy(_caption(19)), findsOneWidget);
    expect(findCopy('₹639 a day'), findsOneWidget);
    expect(findCopy('Fri, 6 Nov · ₹1,270'), findsOneWidget);
    expect(
      findCopy('● 12 saved · ○ 6 on budget · ◆ 1 overspent'),
      findsOneWidget,
    );
    expect(findCopy('incl. 1 covered from savings'), findsOneWidget);
  });
}
