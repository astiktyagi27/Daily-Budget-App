import 'dart:math';

import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

final CalendarDate _nov6 = d(2026, 11, 6);
final CalendarDate _nov7 = d(2026, 11, 7);
final CalendarDate _nov8 = d(2026, 11, 8);
final CalendarDate _nov10 = d(2026, 11, 10);

/// W1 on 8 Nov with [covers].
MonthResult _w1({List<Cover> covers = const [], List<Spend>? spends}) =>
    e2Month(today: _nov8, spends: spends ?? w1Spends(), covers: covers);

/// A cover of 6 Nov made on 8 Nov at [hour].
Cover _nov6Cover(int id, int amount, [int hour = 10]) =>
    cover(id, _nov6, amount, at(_nov8, hour));

Matcher _refused(CoverRefusal reason) =>
    isA<CoverRefused>().having((r) => r.reason, 'reason', reason);

void main() {
  _cutTests();

  test('TC-006-11 todays leftover joins the pot at midnight', () {
    final onNov8 = _w1();
    expect(onNov8.totals.pot, p(33000));
    expect(onNov8.totals.saved, p(33000));
    final nov8 = onNov8.dayOn(_nov8);
    expect((nov8.status, nov8.result), (DayStatus.live, p(63000)));

    final onNov9 = e2Month(today: d(2026, 11, 9), spends: w1Spends());
    expect(onNov9.totals.pot, p(96000));
    final nov8Final = onNov9.dayOn(_nov8);
    expect((nov8Final.status, nov8Final.result), (DayStatus.saved, p(63000)));
    // 6 Nov's overspend does not lower the pot (pot = saved − covered).
    expect(onNov9.dayOn(_nov6).result, p(-17000));
    expect(onNov9.totals.overspent, p(17000));
  });

  test('TC-006-12 cover with savings moves pot money to an overspent day', () {
    final w1 = _w1();
    // (a) Full cover.
    expect(checkCover(w1, _nov6, p(17000)), isA<CoverAllowed>());
    final full = _w1(covers: [_nov6Cover(1, 17000)]);
    expect(full.totals.pot, p(16000));
    final nov6 = full.dayOn(_nov6);
    expect(
      (nov6.result, nov6.status, nov6.covered),
      (Paise.zero, DayStatus.onBudget, p(17000)),
    );
    expect(full.totals.overspent, Paise.zero);
    expect(full.totals.covered, p(17000));

    // (b) Partial cover.
    expect(checkCover(w1, _nov6, p(10000)), isA<CoverAllowed>());
    final partial = _w1(covers: [_nov6Cover(1, 10000)]);
    final partDay = partial.dayOn(_nov6);
    expect(
      (partDay.result, partDay.status, partDay.covered),
      (p(-7000), DayStatus.overspent, p(10000)),
    );
    expect(partial.totals.pot, p(23000));
    expect(partial.totals.overspent, p(7000));
  });

  test('TC-006-13 invalid covers are refused with distinct reasons '
      'and change nothing', () {
    final w1 = _w1();
    final before = dump(w1);
    final afterTenRupees = _w1(covers: [_nov6Cover(1, 10000)]);
    final midMonth = computeMonth(
      MonthInput(
        month: nov2026,
        firstBudgetedDay: _nov10,
        periods: [period(_nov10, MidMonthStartValues(moneyLeft: p(2490000)))],
        today: d(2026, 11, 12),
      ),
    );
    expect(midMonth.totals.pot, p(199200));
    final potOnly = _w1(spends: w1Spends(nov5: 80000));
    expect(potOnly.totals.pot, p(3000));

    final cases = <String, (MonthResult, CalendarDate, int, CoverRefusal)>{
      'a': (w1, _nov6, 20000, CoverRefusal.exceedsOverspend),
      'b': (afterTenRupees, _nov6, 40000, CoverRefusal.exceedsOverspend),
      'c': (w1, d(2026, 11, 5), 100, CoverRefusal.notOverspent),
      'd': (w1, _nov7, 100, CoverRefusal.notOverspent),
      'e': (w1, d(2026, 11, 9), 100, CoverRefusal.upcoming),
      'f1': (w1, d(2026, 12, 5), 100, CoverRefusal.outsideMonth),
      'f2': (w1, d(2026, 11, 4), 100, CoverRefusal.outsideMonth),
      'g1': (w1, _nov6, 0, CoverRefusal.notPositive),
      'g2': (w1, _nov6, -100, CoverRefusal.notPositive),
      'h': (midMonth, d(2026, 11, 5), 100, CoverRefusal.notBudgeted),
      'j': (potOnly, _nov6, 5000, CoverRefusal.exceedsPot),
    };
    for (final MapEntry(key: name, value: (result, day, amount, reason))
        in cases.entries) {
      final snapshot = dump(result);
      expect(
        checkCover(result, day, p(amount)),
        _refused(reason),
        reason: name,
      );
      expect(dump(result), snapshot, reason: name);
    }
    expect({
      for (final (_, _, _, reason) in cases.values) reason,
    }, hasLength(7));

    // Nothing changed: the same input gives the same full output.
    expect(dump(_w1()), before);
    expect(dump(e2Month(today: _nov8, spends: w1Spends())), before);
  });

  test('TC-006-14 shrinking pot reduces newest covers first', () {
    final w2 = e2Month(today: _nov10, spends: w2Spends(), covers: w2Covers());
    expect(w2.totals.saved, p(96000));
    expect(w2.totals.pot, p(62000));

    // 1. 5 Nov and 8 Nov raised to ₹830: saved falls to ₹0.
    final edited = e2Month(
      today: _nov10,
      spends: w2Spends(nov5: 83000, nov8: 83000),
      covers: w2Covers(),
    );
    expect(edited.totals.saved, Paise.zero);
    expect(edited.totals.pot, Paise.zero);
    expect(edited.reductions, [
      (coverId: 2, day: _nov7, oldAmount: p(17000), newAmount: Paise.zero),
      (coverId: 1, day: _nov6, oldAmount: p(17000), newAmount: Paise.zero),
    ]);
    for (final day in [_nov6, _nov7]) {
      final result = edited.dayOn(day);
      expect((result.status, result.result), (DayStatus.overspent, p(-17000)));
    }
    expect(
      [for (final c in edited.effectiveCovers) c.amount],
      [Paise.zero, Paise.zero],
    );

    // Stored again as ₹0 (D-048): nothing more is reduced or listed.
    final stored = e2Month(
      today: _nov10,
      spends: w2Spends(nov5: 83000, nov8: 83000),
      covers: [
        cover(1, _nov6, 0, at(_nov8, 21)),
        cover(2, _nov7, 0, at(d(2026, 11, 9), 21)),
      ],
    );
    expect(stored.reductions, isEmpty);
    expect(stored.totals.pot, Paise.zero);
    // A newer cover already at ₹0 is skipped; the older one is cut.
    final skipped = e2Month(
      today: _nov10,
      spends: w2Spends(nov5: 83000, nov8: 83000),
      covers: [
        ...w2Covers().take(1),
        cover(3, _nov7, 0, at(d(2026, 11, 9), 22)),
      ],
    );
    expect(skipped.reductions, [
      (coverId: 1, day: _nov6, oldAmount: p(17000), newAmount: Paise.zero),
    ]);

    // 2. Only 5 Nov raised: saved ₹630 still pays for both covers.
    final onlyNov5 = e2Month(
      today: _nov10,
      spends: w2Spends(nov5: 83000),
      covers: w2Covers(),
    );
    expect(onlyNov5.totals.saved, p(63000));
    expect(onlyNov5.totals.covered, p(34000));
    expect(onlyNov5.totals.pot, p(29000));
    expect(onlyNov5.reductions, isEmpty);
  });

  test('TC-006-44 a day can be covered twice until its overspend is zero', () {
    final w1 = _w1();
    expect(checkCover(w1, _nov6, p(10000)), isA<CoverAllowed>());
    final once = _w1(covers: [_nov6Cover(1, 10000)]);
    expect(checkCover(once, _nov6, p(7000)), isA<CoverAllowed>());
    final twice = _w1(covers: [_nov6Cover(1, 10000), _nov6Cover(2, 7000, 11)]);
    expect(twice.dayOn(_nov6).result, Paise.zero);
    expect(twice.dayOn(_nov6).covered, p(17000));
    expect(twice.totals.pot, p(16000));
    expect(checkCover(twice, _nov6, p(1)), _refused(CoverRefusal.notOverspent));
  });

  test('TC-006-45 cover above a reduced overspend returns to the pot', () {
    final covered = _w1(covers: [_nov6Cover(1, 17000)]);
    expect(covered.totals.pot, p(16000));
    final edited = _w1(
      covers: [_nov6Cover(1, 17000)],
      spends: w1Spends(nov6: 90000),
    );
    final nov6 = edited.dayOn(_nov6);
    expect(
      (nov6.covered, nov6.result, nov6.status),
      (p(7000), Paise.zero, DayStatus.onBudget),
    );
    expect(edited.effectiveCovers, [(coverId: 1, day: _nov6, amount: p(7000))]);
    expect(edited.totals.pot, p(26000));
    // A clamp needs no note: it is not a D-040 reduction.
    expect(edited.reductions, isEmpty);

    // Two covers on the day: the newer one gives back first.
    final two = _w1(
      covers: [_nov6Cover(1, 5000), _nov6Cover(2, 12000, 11)],
      spends: w1Spends(nov6: 90000),
    );
    expect([for (final c in two.effectiveCovers) c.amount], [p(5000), p(2000)]);
  });

  test('TC-006-46 pot shortfall of ten rupees cuts only the newest cover', () {
    final result = e2Month(
      today: _nov10,
      spends: w2Spends(nov8: 83000),
      covers: w2Covers(),
    );
    expect(result.totals.saved, p(33000));
    expect(result.totals.pot, Paise.zero);
    expect(result.reductions, [
      (coverId: 2, day: _nov7, oldAmount: p(17000), newAmount: p(16000)),
    ]);
    expect(result.dayOn(_nov6).covered, p(17000));
    expect(result.dayOn(_nov7).result, p(-1000));
  });

  test(
    'TC-006-53 engine output ignores input order but respects cover time',
    () {
      final expected = e2Month(
        today: _nov10,
        spends: w2Spends(nov5: 83000, nov8: 83000),
        covers: w2Covers(),
      );
      final random = Random(propertySeed);
      for (var shuffle = 0; shuffle < 5; shuffle++) {
        final result = e2Month(
          today: _nov10,
          spends: w2Spends(nov5: 83000, nov8: 83000)..shuffle(random),
          covers: w2Covers().reversed.toList(),
        );
        final why = 'seed $propertySeed, shuffle $shuffle';
        expect(result.days, expected.days, reason: why);
        expect(result.totals, expected.totals, reason: why);
        expect(result.reductions, expected.reductions, reason: why);
        expect(result.reductions.first.day, _nov7, reason: why);
        expect(
          [...result.effectiveCovers]
            ..sort((a, b) => a.coverId.compareTo(b.coverId)),
          expected.effectiveCovers,
          reason: why,
        );
      }
    },
  );

  test('TC-006-57 todays overspend can be covered', () {
    final spends = w1Spends(nov8: 100000);
    final before = e2Month(today: _nov8, spends: spends);
    final today = before.dayOn(_nov8);
    expect((today.status, today.result), (DayStatus.live, p(-17000)));
    expect(before.totals.pot, p(33000));
    expect(checkCover(before, _nov8, p(17000)), isA<CoverAllowed>());

    final after = e2Month(
      today: _nov8,
      spends: spends,
      covers: [cover(1, _nov8, 17000, at(_nov8, 20))],
    );
    final covered = after.dayOn(_nov8);
    expect((covered.status, covered.result), (DayStatus.live, Paise.zero));
    expect(after.totals.pot, p(16000));
  });
}

void _cutTests() {
  CoverReduction reduction(int oldPaise, int newPaise) => (
    coverId: 1,
    day: d(2026, 11, 6),
    oldAmount: p(oldPaise),
    newAmount: p(newPaise),
  );

  test('TC-009-25 a whole cover taken back: the cut is the old amount', () {
    final whole = reduction(17000, 0);
    expect(whole.cut, p(17000));
    expect(whole.cutIsUnderRupee, isFalse);
    // Exactly ₹1 is not under ₹1.
    expect(reduction(100, 0).cutIsUnderRupee, isFalse);
  });

  test('TC-009-27 a partial cut is old minus new; under ₹1 is flagged', () {
    final partial = reduction(17000, 16000);
    expect(partial.cut, p(1000));
    expect(partial.cutIsUnderRupee, isFalse);
    final tiny = reduction(17000, 16950);
    expect(tiny.cut, p(50));
    expect(tiny.cutIsUnderRupee, isTrue);
    expect(reduction(100, 1).cutIsUnderRupee, isTrue, reason: '99 paise');
  });
}
