// F-014 AC-12: the rounding note compares what the screen shows (whole
// rupees, toward zero). Expected values are literals of tests/F-014.

import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phase3_fixtures.dart';
import 'fixtures.dart';

MonthStatement _of(Phase3Fixture fixture) => buildStatement(fixture.result);

/// [statement] with some month totals replaced, to prove each figure is
/// compared on its own.
MonthStatement _withTotals(
  MonthStatement statement, {
  Paise? moneyForMonth,
  Paise? spent,
  Paise? refunds,
  Paise? netSpent,
  Paise? saved,
  Paise? overspent,
  Paise? covered,
}) {
  final t = statement.totals;
  return MonthStatement(
    month: statement.month,
    soFarTo: statement.soFarTo,
    notBudgeted: statement.notBudgeted,
    changes: statement.changes,
    periods: statement.periods,
    totals: StatementTotals(
      moneyForMonth: moneyForMonth ?? t.moneyForMonth,
      spent: spent ?? t.spent,
      refunds: refunds ?? t.refunds,
      netSpent: netSpent ?? t.netSpent,
      saved: saved ?? t.saved,
      covered: covered ?? t.covered,
      overspent: overspent ?? t.overspent,
      pot: t.pot,
      shortfall: t.shortfall,
      left: t.left,
    ),
  );
}

void main() {
  test('TC-014-18 shown parts are compared on whole rupees', () {
    final s = _of(mx);

    final [p1, p2] = s.periods;
    // Period 1 has the spend of 3 Nov, period 2 the one of 15 Nov.
    expect(p1.totals.spent, p(450060));
    expect(p2.totals.spent, p(450060));
    expect(p1.totals.spent.wholeRupees, 4500);
    expect(p2.totals.spent.wholeRupees, 4500);
    expect(s.totals.spent, p(900120));
    expect(s.totals.spent.wholeRupees, 9001);
    expect(s.totals.netSpent.wholeRupees, 9001);
    expect(roundingNoteNeeded(s), isTrue);
  });

  test('TC-014-19 no rounding note when the lines add up', () {
    expect(roundingNoteNeeded(_of(fixtureMFull)), isFalse);
    expect(roundingNoteNeeded(_of(fixtureM20)), isFalse);
    expect(roundingNoteNeeded(_of(fixtureA)), isFalse);
    expect(roundingNoteNeeded(_of(fixtureS)), isFalse);
    expect(roundingNoteNeeded(_of(e2c)), isFalse);
    expect(roundingNoteNeeded(_of(fixtureF)), isFalse);
  });

  test('TC-014-18 every figure of the month is compared with its period '
      'lines', () {
    final s = _of(fixtureMFull);
    expect(roundingNoteNeeded(s), isFalse);

    // One whole rupee more on one month line is enough, whichever it is.
    Paise plusRupee(Paise v) => v + p(100);
    final bumped = {
      'money for the month': _withTotals(
        s,
        moneyForMonth: plusRupee(s.totals.moneyForMonth),
      ),
      'spent': _withTotals(s, spent: plusRupee(s.totals.spent)),
      'refunds': _withTotals(s, refunds: plusRupee(s.totals.refunds)),
      'net spent': _withTotals(s, netSpent: plusRupee(s.totals.netSpent)),
      'saved': _withTotals(s, saved: plusRupee(s.totals.saved)),
      'overspent': _withTotals(s, overspent: plusRupee(s.totals.overspent)),
      'covered': _withTotals(s, covered: plusRupee(s.totals.covered)),
    };
    for (final MapEntry(:key, :value) in bumped.entries) {
      expect(roundingNoteNeeded(value), isTrue, reason: key);
    }
    // A few paise more, still under the next whole rupee, change nothing.
    expect(
      roundingNoteNeeded(_withTotals(s, saved: s.totals.saved + p(20))),
      isFalse,
    );
  });

  test('TC-014-20 three periods of one hundred rupees ninety show a two '
      'rupee gap', () {
    final fixture = e2c.copyWith(
      entries: [
        fixtureSpend(d(2026, 11, 6), 10090),
        fixtureSpend(d(2026, 11, 22), 10090),
        fixtureSpend(d(2026, 11, 30), 10090),
      ],
    );
    final s = _of(fixture);

    expect(s.periods.map((x) => x.totals.spent.wholeRupees), [100, 100, 100]);
    expect(s.totals.spent, p(30270));
    expect(s.totals.spent.wholeRupees, 302);
    expect(roundingNoteNeeded(s), isTrue);
  });

  test('TC-014-55 left is computed from exact amounts', () {
    final s = _of(mx);

    // 19,90,000 - 9,00,120 = 10,89,880 paise: ₹10,898. Subtracting the shown
    // lines (19,900 - 9,001) would give 10,899.
    expect(s.totals.left, p(1089880));
    expect(s.totals.left, mx.result.totals.left);
    expect(s.totals.left.wholeRupees, 10898);
    expect(
      s.totals.moneyForMonth.wholeRupees - s.totals.netSpent.wholeRupees,
      10899,
    );
  });

  test('TC-014-18 whole rupees round toward zero', () {
    expect(p(66667).wholeRupees, 666);
    expect(p(-66667).wholeRupees, -666);
    expect(p(99).wholeRupees, 0);
    expect(p(-99).wholeRupees, 0);
    expect(p(100).wholeRupees, 1);
    expect(p(0).wholeRupees, 0);
  });
}
