import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phase3_fixtures.dart';
import 'fixtures.dart';

// F-012 plan §1.2: the cover form check, in the engine's refusal order.

final CalendarDate _nov6 = d(2026, 11, 6);
final CalendarDate _nov11 = d(2026, 11, 11);

CoverProblem? _problem(CoverCheck check) => switch (check) {
  CoverOk() => null,
  CoverNotOk(:final problem) => problem,
};

CoverProblem? _check(Phase3Fixture fixture, CalendarDate day, String text) =>
    _problem(validateCover(fixture.result, day, CoverDraft(text)));

void main() {
  test('TC-012-12 invalid cover amounts name their problem (a to f)', () {
    // (a)-(c), (e), (f) on P250: 11 Nov overspent 30,000, pot 25,000.
    final cases = <String, CoverProblem>{
      '': CoverProblem.missing,
      '  ': CoverProblem.missing,
      '0': CoverProblem.notPositive,
      '0.00': CoverProblem.notPositive,
      '260': CoverProblem.exceedsPot,
      '12.345': CoverProblem.badFormat,
      'abc': CoverProblem.badFormat,
      '-5': CoverProblem.badFormat,
      '99999999999999999': CoverProblem.tooLarge,
      '100000001': CoverProblem.tooLarge,
    };
    for (final MapEntry(key: text, value: problem) in cases.entries) {
      expect(_check(p250, _nov11, text), problem, reason: '"$text"');
    }
    // (d) on A13: pot 2,00,000 so only the overspend is exceeded.
    expect(_check(fixtureA, _nov11, '300.01'), CoverProblem.exceedsOverspend);
  });

  test('TC-012-13 overspend message comes before the pot message', () {
    // P250: overspent 300, pot 250. 400 exceeds both: the overspend wins.
    expect(_check(p250, _nov11, '400'), CoverProblem.exceedsOverspend);
    expect(_check(p250, _nov11, '300.01'), CoverProblem.exceedsOverspend);
    expect(_check(p250, _nov11, '260'), CoverProblem.exceedsPot);
  });

  test('TC-012-13 the engine refusal order, one case per pair', () {
    // not positive before everything: even for a day that is not offered.
    expect(_check(fixtureA, d(2026, 11, 14), '0'), CoverProblem.notPositive);
    // Not offered: outside the month, not budgeted, upcoming, not overspent.
    final notOffered = <(Phase3Fixture, CalendarDate)>[
      (f12, d(2026, 11, 7)), // before the first budgeted day
      (fixtureA, d(2026, 11, 14)), // upcoming
      (fixtureA, d(2026, 11, 12)), // not overspent
    ];
    for (final (fixture, day) in notOffered) {
      expect(
        _check(fixture, day, '10'),
        CoverProblem.notOffered,
        reason: '${fixture.name} ${day.iso}',
      );
    }
    // Outside the month: the engine refuses before the day is read.
    final outside = validateCover(
      fixtureA.result,
      d(2026, 12, 20),
      const CoverDraft('10'),
    );
    expect(_problem(outside), CoverProblem.notOffered);
    // Not offered comes before the overspend and pot limits.
    expect(
      _check(fixtureA, d(2026, 11, 12), '9999999'),
      CoverProblem.notOffered,
    );
  });

  test('TC-012-05 a valid cover is the exact paise the engine allows', () {
    for (final (text, paise) in <(String, int?)>[
      ('300', 30000),
      ('100', 10000),
      ('0.40', 40),
      ('300.00', 30000),
      ('₹ 1,00', null),
    ]) {
      final check = validateCover(fixtureA.result, _nov11, CoverDraft(text));
      if (paise == null) {
        expect(_problem(check), CoverProblem.badFormat, reason: text);
      } else {
        expect(check, isA<CoverOk>(), reason: text);
        expect((check as CoverOk).amount, p(paise), reason: text);
      }
    }
    final partly = validateCover(
      fixtureA.result,
      _nov6,
      const CoverDraft('170'),
    );
    expect((partly as CoverOk).amount, p(17000));
  });

  test('TC-012-57 max cover is the lesser of pot and overspend', () {
    final pairs = <(int, int, int?)>[
      (200000, 30000, 30000),
      (25000, 30000, 25000),
      (181336, 4778, 4778),
      (0, 20000, null),
      (30000, 30000, 30000),
      (40, 40, 40),
      (200000, 0, null),
    ];
    for (final (pot, overspend, expected) in pairs) {
      expect(
        maxCover(pot: p(pot), overspend: p(overspend))?.value,
        expected,
        reason: '$pot / $overspend',
      );
    }
  });

  test('TC-012-57 the caption follows the typed amount', () {
    CoverCaption? caption(
      String text, {
      int overspend = 30000,
      int pot = 25000,
    }) => coverCaption(amountText: text, overspend: p(overspend), pot: p(pot));
    expect(caption('300', pot: 200000), CoverCaption.wholeOverspend);
    expect(caption('250'), CoverCaption.wholePot);
    // Equal limits: the overspend caption wins.
    expect(caption('300', pot: 30000), CoverCaption.wholeOverspend);
    expect(caption('100'), isNull);
    expect(caption(''), isNull);
    expect(caption('abc'), isNull);
  });
}
