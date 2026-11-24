// Checks that every shared Phase 3 fixture, run through the real engine, gives
// the paise literals the Tester's files state for it (plan T-389). A wrong
// seed fails here instead of inside eight feature test files. The expected
// numbers are copied from tests/F-010 .. F-017 section 0, never computed.

import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/budget/fixtures.dart';
import '../helpers/phase3_fixtures.dart';

typedef _Figures = ({
  int saved,
  int overspent,
  int covered,
  int pot,
  int left,
  int spent,
});

void _expectTotals(MonthResult result, _Figures want, {String? reason}) {
  final t = result.totals;
  expect(
    (
      saved: t.saved.value,
      overspent: t.overspent.value,
      covered: t.covered.value,
      pot: t.pot.value,
      left: t.left.value,
      spent: t.spentSoFar.value,
    ),
    want,
    reason: reason,
  );
}

CalendarDate _nov(int day) => d(2026, 11, day);

void main() {
  test('TC-010-05 fixture A matches worked example A', () {
    _expectTotals(fixtureA.result, (
      saved: 200000,
      overspent: 47000,
      covered: 0,
      pot: 200000,
      left: 1937000,
      spent: 553000,
    ));
    final result = fixtureA.result;
    expect(result.dayOn(_nov(13)).status, DayStatus.live);
    expect(result.dayOn(_nov(6)).result, const Paise(-17000));
    expect(result.dayOn(_nov(11)).result, const Paise(-30000));
    expect(result.dayOn(_nov(12)).result, const Paise(83000));
    // The 9 Nov Lunch was created before the no-note spend.
    final nineNov = fixtureA.current.entries.where((e) => e.date == _nov(9));
    expect(
      [for (final e in nineNov) (e.paise, e.note)],
      [(25000, 'Lunch'), (37000, null)],
    );
    expect(identical(a13, fixtureA), isTrue);
  });

  test('TC-010-06 fixture A+cover has the 30,000 cover on 11 Nov', () {
    _expectTotals(fixtureAPlusCover.result, (
      saved: 200000,
      overspent: 17000,
      covered: 30000,
      pot: 170000,
      left: 1937000,
      spent: 553000,
    ));
  });

  test('TC-013-10 fixture A+refund nets the refund against today', () {
    final result = fixtureAPlusRefund.result;
    expect(result.dayOn(_nov(13)).netSpent, const Paise(-8000));
    expect(result.totals.spentSoFar, const Paise(503000));
    expect(result.totals.left, const Paise(1987000));
    expect(fixtureAPlusRefund.current.entries.last.moneyIn, isTrue);
  });

  test('TC-012-01 variants of A: A13o, A14, A13 +410', () {
    final overspentToday = a13o.result.dayOn(_nov(13));
    expect(overspentToday.netSpent, const Paise(100000));
    expect(overspentToday.result, const Paise(-17000));
    expect(a13o.result.totals.pot, const Paise(200000));

    expect(a14.result.totals.left, const Paise(1937000));
    expect(a14.result.dayOn(_nov(14)).netSpent, Paise.zero);
    expect(a14.today, _nov(14));

    expect(a13Plus410.result.dayOn(_nov(13)).netSpent, const Paise(83000));
    expect(a13Plus410.result.totals.left, const Paise(1896000));
  });

  test('TC-013-06 fixture B puts 3,91,000 in Other', () {
    final entries = fixtureB.current.entries;
    int sumOf(bool Function(FixtureEntry e) test) =>
        entries.where(test).fold(0, (sum, e) => sum + e.paise);
    expect(sumOf((e) => e.categoryKey == null), 391000);
    expect(sumOf((e) => e.categoryKey == 'shopping'), 100000);
    expect(sumOf((e) => e.categoryKey == 'food'), 62000);
    // The money does not depend on the category.
    expect(fixtureB.result.totals.left, fixtureA.result.totals.left);
    expect(
      fixtureAF.current.entries.where((e) => e.categoryKey == 'food'),
      hasLength(2),
    );
  });

  test('TC-015-05 fixture A2 adds the 12 Nov notes', () {
    expect(fixtureA.current.entries, hasLength(9));
    final a2 = fixtureA2.current.entries.where((e) => e.date == _nov(12));
    expect(
      [for (final e in a2) (e.paise, e.note)],
      [(30050, 'Snacks'), (9000, '250g paneer')],
    );
    expect(fixtureA2.result.totals.spentSoFar, const Paise(592050));
  });

  test('TC-015-04 fixture A3 adds the Hindi, coffee and emoji notes', () {
    final a3 = fixtureA3.current.entries.where((e) => e.date == _nov(12));
    expect([for (final e in a3) e.paise], [2000, 3000, 4000]);
  });

  test('TC-010-14 fixture S and S+150 follow D-060', () {
    _expectTotals(fixtureS.result, (
      saved: 0,
      overspent: 20000,
      covered: 0,
      pot: 0,
      left: -120000,
      spent: 20000,
    ));
    _expectTotals(s8Plus150.result, (
      saved: 0,
      overspent: 35000,
      covered: 0,
      pot: 0,
      left: -135000,
      spent: 35000,
    ));
    expect(identical(s8, fixtureS), isTrue);
  });

  test('TC-017-31 fixture S8-refund leaves 1,80,000', () {
    final result = s8Refund.result;
    expect(result.totals.left, const Paise(180000));
    expect(result.dayOn(_nov(7)).result, const Paise(300000));
  });

  test('TC-010-20 fixture F12 is example F', () {
    _expectTotals(f12.result, (
      saved: 19600,
      overspent: 10400,
      covered: 0,
      pot: 19600,
      left: 2300000,
      spent: 190000,
    ));
    final first = f12.result.dayOn(_nov(10));
    expect(first.budget, const Paise(99600));
    expect(f12.result.dayOn(_nov(9)).status, DayStatus.notBudgeted);
  });

  test('TC-016-25 fixture F has 99,600 a day for 25 days', () {
    final days = fixtureF.result.days.where((day) => day.budget != null);
    expect(days, hasLength(25));
    expect(days.every((day) => day.budget == const Paise(99600)), isTrue);
    expect(fixtureF.result.totals.spentSoFar, const Paise(200000));
  });

  test('TC-010-18 fixtures M20 and M20nc match the engine', () {
    final result = fixtureM20.result;
    _expectTotals(result, (
      saved: 211558,
      overspent: 53778,
      covered: 20000,
      pot: 191558,
      left: 690000,
      spent: 1300000,
    ));
    expect(result.periods, hasLength(2));
    expect(result.periods[1].budgets.first, const Paise(55223));
    expect(result.periods[1].saved, const Paise(71558));
    expect(result.dayOn(_nov(20)).result, const Paise(-29778));
    expect(identical(m20, fixtureM20), isTrue);
    expect(identical(m20c, fixtureM20), isTrue);
    // M20nc: the same month without its cover.
    _expectTotals(m20nc.result, (
      saved: 211558,
      overspent: 73778,
      covered: 0,
      pot: 211558,
      left: 690000,
      spent: 1300000,
    ));
    expect(m20nc.current.covers, isEmpty);
  });

  test('TC-014-53 fixture M-full matches example M finished', () {
    final result = fixtureMFull.result;
    _expectTotals(result, (
      saved: 214078,
      overspent: 54078,
      covered: 20000,
      pot: 194078,
      // The engine's spent so far is net of refunds: 19,00,000 - 50,000.
      left: 140000,
      spent: 1850000,
    ));
    final first = result.periods[0];
    expect(Paise.sum(first.budgets), const Paise(996000));
    expect(first.saved, const Paise(140000));
    expect(first.overspent, const Paise(24000));
    expect(first.covered, const Paise(20000));
    final second = result.periods[1];
    expect(Paise.sum(second.budgets), const Paise(994000));
    expect(second.saved, const Paise(74078));
    expect(second.overspent, const Paise(30078));
    expect(second.covered, Paise.zero);
    expect(second.moneyIn, const Paise(50000));
    expect(result.totals.moneyIn, const Paise(50000));
  });

  test('TC-013-21 fixture O1 stores October beside A', () {
    expect(fixtureO1.months, hasLength(2));
    final october = fixtureO1.months.first.result(fixtureO1.today);
    expect(october.dayOn(d(2026, 10, 10)).budget, const Paise(100000));
    expect(october.dayOn(d(2026, 10, 10)).result, const Paise(-40000));
    _expectTotals(october, (
      saved: 2915000,
      overspent: 40000,
      covered: 0,
      pot: 2915000,
      left: 2875000,
      spent: 225000,
    ));
    expect(fixtureO1.result.totals.left, const Paise(1937000));
  });

  test('TC-011-25 fixture OCT-NOV has the F-011 October', () {
    final october = octNov.months.first.result(octNov.today);
    expect(october.month.start, d(2026, 10, 5));
    expect(october.dayOn(d(2026, 10, 5)).result, const Paise(30323));
    expect(october.dayOn(d(2026, 10, 6)).result, const Paise(-19677));
    expect(october.days.first.budget, const Paise(80323));
    expect(october.days.last.budget, const Paise(80322));
    expect(octNov.result.totals.left, const Paise(1937000));
  });

  test('TC-013-33 fixture N nets to minus 30,000', () {
    final result = fixtureN.result;
    expect(result.totals.spentSoFar, const Paise(-30000));
    expect(result.totals.moneyIn, const Paise(50000));
  });

  test('TC-012-11 fixture P250 has a pot of 25,000', () {
    final result = p250.result;
    expect(result.totals.pot, const Paise(25000));
    expect(result.dayOn(_nov(11)).result, const Paise(-30000));
  });

  test('TC-012-23 fixture W3 covers 6 Nov with 17,000', () {
    final result = w3.result;
    expect(result.dayOn(_nov(5)).result, const Paise(33000));
    expect(result.totals.pot, const Paise(16000));
    expect(result.dayOn(_nov(6)).status, DayStatus.onBudget);
    expect(result.dayOn(_nov(6)).covered, const Paise(17000));
  });

  test('TC-012-25 fixture R16 nets 20,000 on 16 Nov', () {
    final day = r16.result.dayOn(_nov(16));
    expect(day.netSpent, const Paise(20000));
    expect(day.moneyIn, const Paise(50000));
    expect(day.result, const Paise(63000));
  });

  test('TC-016-16 fixture P1 has a pot of 1,00,000 after 2,50,000 covers', () {
    _expectTotals(p1.result, (
      saved: 350000,
      overspent: 0,
      covered: 250000,
      pot: 100000,
      left: p1.result.totals.left.value,
      spent: p1.result.totals.spentSoFar.value,
    ));
    expect(p1.result.dayOn(_nov(12)).result, const Paise(150000));
  });

  test('TC-016-18 fixture P1b has the same pot with a 3,16,000 refund', () {
    final result = p1b.result;
    expect(result.totals.saved, const Paise(350000));
    expect(result.totals.covered, const Paise(250000));
    expect(result.totals.pot, const Paise(100000));
    expect(result.dayOn(_nov(12)).result, const Paise(316000));
    expect(result.dayOn(_nov(5)).result, Paise.zero);
  });

  test('TC-017-09 fixtures E2 day 1, E2 last and OV5 for safe to spend', () {
    expect(e2Day1.result.totals.left, const Paise(2490000));
    expect(e2Last.result.totals.left, const Paise(2490000));
    expect(e2Last.result.totals.saved, const Paise(2407000));
    expect(ov5.result.totals.left, const Paise(2307000));
    expect(ov5.result.totals.overspent, const Paise(100000));
  });

  test('TC-014-11 fixture E2c has three periods and 22,90,000', () {
    final result = e2c.result;
    expect(result.periods, hasLength(3));
    expect(result.totals.budgeted, const Paise(2290000));
    expect(result.periods[1].budgets.first, const Paise(63000));
    expect(result.periods[2].budgets.first, const Paise(77286));
    expect(result.periods[2].budgets.last, const Paise(77285));
  });

  test('TC-014-10 fixture E2s keeps both same-day changes', () {
    final result = e2s.result;
    expect(result.periods.last.budgets.first, const Paise(76334));
    expect(result.periods.last.budgets.last, const Paise(76333));
    expect(result.periods.where((p) => p.superseded), hasLength(1));
  });

  test('TC-014-14 fixture C4 has a shortfall of 2,55,000', () {
    expect(c4.result.periods.last.shortfall, const Paise(255000));
  });

  test('TC-014-18 fixture Mx has the two 4,50,060 spends', () {
    final result = mx.result;
    expect(result.totals.spentSoFar, const Paise(900120));
    expect(result.periods, hasLength(2));
  });
}
