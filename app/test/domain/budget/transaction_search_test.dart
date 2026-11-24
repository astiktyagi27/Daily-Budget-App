import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phase3_fixtures.dart';
import 'fixtures.dart';

/// The entries of [fixture]'s month [monthIndex] as the search reads them,
/// with the ids 1, 2, ... in entry order plus [idBase].
List<NotedSpend> _entries(
  Phase3Fixture fixture, {
  int monthIndex = -1,
  int idBase = 0,
}) {
  final month = monthIndex < 0 ? fixture.current : fixture.months[monthIndex];
  return [
    for (final (i, e) in month.entries.indexed)
      (spend: e.toSpend(idBase + i + 1), note: e.note),
  ];
}

/// The month index of [fixture], newest first, ids 1 (oldest) upward.
List<IndexedMonth> _index(Phase3Fixture fixture) => [
  for (final (i, m) in fixture.months.indexed.toList().reversed)
    (id: i + 1, month: m.month),
];

final CalendarDate _nov13 = d(2026, 11, 13);
final DateRange _novRange = (first: d(2026, 11, 5), last: d(2026, 12, 4));

List<NotedSpend> _find(
  List<NotedSpend> entries,
  String query, {
  TypeFilter type = TypeFilter.all,
  Set<SpendCategory> categories = const {},
}) => filterEntries(
  entries,
  EntryFilter(query: query, type: type, categories: categories),
  _novRange,
);

/// The whole rupees of every match, smallest first (the filter keeps the
/// order it is given; the day grouping sorts).
List<int> _rupees(List<NotedSpend> entries) =>
    [for (final e in entries) e.spend.amount.value ~/ 100]..sort();

String _summary(List<NotedSpend> matches) {
  final s = resultsSummary(matches);
  return '${s.count} ${s.spent?.value} ${s.refunds?.value}';
}

void main() {
  final a = _entries(fixtureA);

  group('parseSearchQuery', () {
    test('TC-015-06 search text becomes a text or number query', () {
      NumberQuery number(String text) => parseSearchQuery(text) as NumberQuery;
      for (final text in ['250', '₹250', '₹ 250', ' 250 ', '250.']) {
        expect(number(text).paise, const Paise(25000), reason: text);
        expect(number(text).hasDecimals, isFalse, reason: text);
      }
      expect(number('1,130').paise, const Paise(113000));
      expect(number('1130').paise, const Paise(113000));
      expect(number('1,00,000').paise, const Paise(10000000));
      expect(number('300.50').paise, const Paise(30050));
      expect(number('300.5').paise, const Paise(30050));
      expect(number('300.50').hasDecimals, isTrue);
      expect(number('₹ 1,130').digits, '1,130');
      // Letters make it text; a decimal comma is not an amount either.
      expect((parseSearchQuery('250rs') as TextQuery).text, '250rs');
      expect((parseSearchQuery('99,50') as TextQuery).text, '99,50');
      expect((parseSearchQuery('  Lunch ') as TextQuery).text, 'Lunch');
      // Nothing to search for.
      for (final text in ['', '   ', '₹', ' ₹ ']) {
        expect(parseSearchQuery(text), isA<EmptyQuery>(), reason: text);
      }
    });
  });

  group('filterEntries', () {
    test('TC-015-03 note search contains ignoring case', () {
      for (final query in ['lunch', 'LUNCH', 'lun', ' Lun ']) {
        expect(_rupees(_find(a, query)), [250, 420], reason: query);
        expect(_summary(_find(a, query)), '2 67000 null');
      }
      expect(_find(a, 'taxi'), isEmpty);
    });

    test('TC-015-04 matching works on code points not letters only', () {
      final a3 = _entries(fixtureA3);
      expect(_rupees(_find(a3, 'चाय')), [20]);
      expect(_rupees(_find(a3, '☕')), [30]);
      expect(_rupees(_find(a3, '☕ chai')), [30]);
      expect(_rupees(_find(a3, '👨‍👩‍👧')), [40]);
      expect(_summary(_find(a3, 'चाय')), '1 2000 null');
    });

    test('TC-015-05 amount queries compare whole rupees or exact paise', () {
      final a2 = _entries(fixtureA2);
      expect(_rupees(_find(a2, '830')), [830, 830]);
      expect(_summary(_find(a2, '830')), '2 166000 null');
      expect(_rupees(_find(a2, '₹1,130')), [1130]);
      // 250 finds the 9 Nov Lunch and, by its digits, `250g paneer`.
      expect(_rupees(_find(a2, '250')), [90, 250]);
      expect(_summary(_find(a2, '250')), '2 34000 null');
      // 300 finds the ₹300.50 spend by its shown whole rupees.
      expect(_find(a2, '300').single.spend.amount, const Paise(30050));
      expect(_find(a2, '300.50').single.spend.amount, const Paise(30050));
      expect(_find(a2, '300.5').single.spend.amount, const Paise(30050));
      // A decimal point means exact paise.
      expect(_find(a2, '300.00'), isEmpty);
      expect(_find(a2, '830.50'), isEmpty);
    });

    test('TC-015-07 a number also matches notes containing the digits', () {
      final a2 = _entries(fixtureA2);
      expect(_rupees(_find(a2, '250')), contains(90));
      expect(_rupees(_find(a2, '90')), [90]);
      // The note digits are tried with and without grouping commas.
      final noted = [
        (spend: a2.first.spend, note: 'Rent 1,500 paid'),
        (spend: a2.last.spend, note: 'Rent 1500 paid'),
      ];
      expect(_find(noted, '1,500'), hasLength(2));
    });

    test('TC-015-41 zero rupees matches amounts shown as zero', () {
      final a2 = _entries(fixtureA2);
      final tip = (
        spend: Spend(
          id: 99,
          date: d(2026, 11, 13),
          amount: const Paise(40),
          createdAt: 1,
        ),
        note: 'Tip',
      );
      final all = [...a2, tip];
      expect(_rupees(_find(all, '0')), [0, 90]);
      expect(_rupees(_find(all, '₹0')), [0, 90]);
      expect(_summary(_find(all, '0')), '2 9040 null');
    });

    test('TC-015-43 letters make it text and a comma is grouping', () {
      final withRs = [
        ...a,
        (
          spend: Spend(
            id: 98,
            date: d(2026, 11, 12),
            amount: const Paise(10000),
            createdAt: 2,
          ),
          note: '250rs',
        ),
      ];
      expect(_rupees(_find(withRs, '250rs')), [100]);
      expect(_find(withRs, '99,50'), isEmpty);
    });

    test('TC-015-61 the no note placeholder is not a note', () {
      expect(_find(a, 'no note'), isEmpty);
      expect(a.any((e) => e.note == null), isTrue);
    });

    test('TC-015-14 other includes entries without a category', () {
      final af = _entries(fixtureAF);
      expect(_rupees(_find(af, '', categories: {SpendCategory.food})), [
        250,
        420,
      ]);
      final other = _find(af, '', categories: {SpendCategory.other});
      expect(_summary(other), '7 486000 null');
      expect(
        _find(af, '', categories: {SpendCategory.food, SpendCategory.other}),
        hasLength(9),
      );
      // A stored `other` counts as Other, a different category does not.
      final stored = [
        (
          spend: Spend(
            id: 1,
            date: d(2026, 11, 6),
            amount: const Paise(100),
            createdAt: 1,
            category: SpendCategory.other,
          ),
          note: null,
        ),
        (
          spend: Spend(
            id: 2,
            date: d(2026, 11, 6),
            amount: const Paise(200),
            createdAt: 2,
            category: SpendCategory.travel,
          ),
          note: null,
        ),
      ];
      expect(
        _find(stored, '', categories: {SpendCategory.other}).single.spend.id,
        1,
      );
      expect(
        _find(stored, '', categories: {SpendCategory.travel}).single.spend.id,
        2,
      );
    });

    test('TC-015-16 results line sums spends and refunds apart', () {
      final ar = _entries(fixtureAPlusRefund);
      final refunds = _find(ar, '', type: TypeFilter.refunds);
      expect(refunds.single.note, 'Amazon return');
      expect(_summary(refunds), '1 null 50000');
      final spends = _find(ar, '', type: TypeFilter.spends);
      expect(_summary(spends), '9 553000 null');
      // A search finds the refund through the All type.
      expect(_summary(_find(ar, 'amazon')), '1 null 50000');
      // A number query finds a refund by its amount.
      expect(_find(ar, '500', type: TypeFilter.refunds), hasLength(1));
      // Both kinds together: the spend part is the gross of the spends.
      expect(_summary(_find(ar, 'a')), '2 20000 50000');
      // Any category filter leaves refunds out: a refund has no category.
      expect(_find(ar, '', categories: {SpendCategory.other}), hasLength(9));
      expect(_summary(const []), '0 null null');
    });

    test('TC-015-44 a one day range is one day, both ends included', () {
      final one = filterEntries(a, const EntryFilter(), (
        first: d(2026, 11, 9),
        last: d(2026, 11, 9),
      ));
      expect(_rupees(one), [250, 370]);
      expect(
        filterEntries(a, const EntryFilter(), null),
        isEmpty,
        reason: 'no range, nothing to show',
      );
    });

    test('TC-015-09 the filters combine with AND', () {
      final af = _entries(fixtureAF);
      expect(_find(af, 'lunch', categories: {SpendCategory.travel}), isEmpty);
      expect(
        _find(af, 'lunch', categories: {SpendCategory.food}),
        hasLength(2),
      );
    });
  });

  group('the Dates filter', () {
    final months = _index(octNov);

    test('TC-015-11 this month and last month follow the month index', () {
      expect(resolveDates(DatesFilter.thisMonth, months, _nov13), (
        first: d(2026, 11, 5),
        last: d(2026, 12, 4),
      ));
      expect(resolveDates(DatesFilter.lastMonth, months, _nov13), (
        first: d(2026, 10, 5),
        last: d(2026, 11, 4),
      ));
      expect(thisMonthAvailable(months, _nov13), isTrue);
      expect(lastMonthOf(months, _nov13)!.id, 1);
      // Viewed from October (the clock set back) there is no earlier month.
      expect(lastMonthOf(months, d(2026, 10, 20)), isNull);
      expect(
        resolveDates(DatesFilter.lastMonth, months, d(2026, 10, 20)),
        null,
      );
      expect(resolveDates(DatesFilter.thisMonth, months, d(2026, 10, 20)), (
        first: d(2026, 10, 5),
        last: d(2026, 11, 4),
      ));
    });

    test('TC-015-63 a new month that is not set up means the latest month', () {
      final today = d(2026, 12, 5);
      expect(thisMonthAvailable(months, today), isFalse);
      expect(lastMonthOf(months, today)!.id, 2);
      final latest = (first: d(2026, 11, 5), last: d(2026, 12, 4));
      expect(resolveDates(DatesFilter.thisMonth, months, today), latest);
      expect(resolveDates(DatesFilter.lastMonth, months, today), latest);
      // Picking Last month there stays the default.
      expect(
        normalizeDates(DatesFilter.lastMonth, thisAvailable: false),
        DatesFilter.thisMonth,
      );
      expect(
        normalizeDates(DatesFilter.lastMonth, thisAvailable: true),
        DatesFilter.lastMonth,
      );
      final custom = DatesFilter.custom(d(2026, 11, 1), d(2026, 11, 3));
      expect(normalizeDates(custom, thisAvailable: false), custom);
    });

    test('TC-015-12 a custom range reads the stored months it touches', () {
      final range = resolveDates(
        DatesFilter.custom(d(2026, 11, 1), _nov13),
        months,
        _nov13,
      );
      expect(range, (first: d(2026, 11, 1), last: _nov13));
      expect([for (final m in monthsTouching(months, range)) m.id], [2, 1]);
      // 1 - 3 Nov is October's: November is not read.
      final early = resolveDates(
        DatesFilter.custom(d(2026, 11, 1), d(2026, 11, 3)),
        months,
        _nov13,
      );
      expect([for (final m in monthsTouching(months, early)) m.id], [1]);
      expect(monthsTouching(months, null), isEmpty);
    });

    test('TC-015-13 the custom range picker stops at the first month', () {
      expect(customRangeLimits(months, _nov13), (
        first: d(2026, 10, 5),
        last: _nov13,
      ));
      expect(customRangeLimits(const [], _nov13), isNull);
      expect(resolveDates(DatesFilter.thisMonth, const [], _nov13), isNull);
      expect(lastMonthOf(const [], _nov13), isNull);
    });

    test('TC-015-47 a missed month has no section', () {
      final aug = BudgetMonth.startIn(5, 2026, 8);
      final oct = BudgetMonth.startIn(5, 2026, 10);
      final months = [(id: 2, month: oct), (id: 1, month: aug)];
      final range = (first: d(2026, 8, 20), last: d(2026, 10, 10));
      // September has no stored month: only August and October are read.
      expect([for (final m in monthsTouching(months, range)) m.id], [2, 1]);
      final sections = groupEntries([
        (id: 2, month: oct, entries: <NotedSpend>[]),
        (
          id: 1,
          month: aug,
          entries: [
            (
              spend: Spend(
                id: 1,
                date: d(2026, 8, 25),
                amount: const Paise(100),
                createdAt: 1,
              ),
              note: null,
            ),
          ],
        ),
      ], d(2026, 10, 12));
      expect([for (final s in sections) s.monthId], [1]);
    });
  });

  group('EntryFilter', () {
    test('TC-015-18 clear all is offered for any search or filter', () {
      expect(const EntryFilter().isActive, isFalse);
      expect(const EntryFilter(query: '   ').isActive, isFalse);
      expect(const EntryFilter(query: '₹').isActive, isFalse);
      expect(const EntryFilter(query: 'x').isActive, isTrue);
      expect(const EntryFilter(type: TypeFilter.refunds).isActive, isTrue);
      expect(
        const EntryFilter(categories: {SpendCategory.food}).isActive,
        isTrue,
      );
      expect(const EntryFilter(dates: DatesFilter.lastMonth).isActive, isTrue);
      expect(
        EntryFilter(dates: DatesFilter.custom(_nov13, _nov13)).isActive,
        isTrue,
      );
    });

    test('TC-015-18 copyWith changes one part and keeps the rest', () {
      const base = EntryFilter(
        query: 'a',
        dates: DatesFilter.lastMonth,
        categories: {SpendCategory.food},
        type: TypeFilter.spends,
      );
      expect(base.copyWith().query, 'a');
      expect(base.copyWith(query: 'b').dates, DatesFilter.lastMonth);
      expect(
        base.copyWith(dates: DatesFilter.thisMonth).type,
        TypeFilter.spends,
      );
      expect(base.copyWith(categories: {}).query, 'a');
      expect(base.copyWith(type: TypeFilter.all).categories, {
        SpendCategory.food,
      });
      final custom = DatesFilter.custom(_nov13, d(2026, 11, 14)) as CustomDates;
      expect((custom.first, custom.last), (_nov13, d(2026, 11, 14)));
    });
  });

  group('groupEntries', () {
    test('TC-015-19 shown total of a day adds only the shown entries', () {
      final lunch = _find(a, 'lunch');
      final sections = groupEntries([
        (id: 1, month: nov2026, entries: lunch),
      ], _nov13);
      final days = sections.single.days;
      expect(
        [for (final day in days) (day.group.date.iso, day.group.total.value)],
        [('2026-11-13', 42000), ('2026-11-09', 25000)],
      );
      expect(
        [for (final day in days) day.group.label],
        [DayLabel.today, DayLabel.other],
      );
      // Unfiltered, 9 Nov adds up to ₹620 and carries both entries' notes.
      final full = groupEntries([
        (id: 1, month: nov2026, entries: a),
      ], _nov13).single.days;
      final nov9 = full.firstWhere((day) => day.group.date == d(2026, 11, 9));
      expect(nov9.group.total.value, 62000);
      expect([for (final e in nov9.entries) e.note], [null, 'Lunch']);
    });

    test('TC-015-17 a refund lowers the day total of the unfiltered list', () {
      final ar = _entries(fixtureAPlusRefund);
      final today = groupEntries([
        (id: 1, month: nov2026, entries: ar),
      ], _nov13).single.days.first;
      expect(today.group.total.value, -8000);
    });

    test('TC-015-12 sections run newest month first, one per month', () {
      final o1 = _entries(fixtureO1, monthIndex: 0, idBase: 100);
      final nov = _entries(fixtureO1, monthIndex: 1);
      final sections = groupEntries([
        (id: 2, month: nov2026, entries: nov),
        (id: 1, month: oct2026, entries: o1),
      ], _nov13);
      expect([for (final s in sections) s.monthId], [2, 1]);
      expect(
        [for (final day in sections.last.days) day.group.date.iso],
        ['2026-11-04', '2026-10-20', '2026-10-10'],
      );
    });
  });
}
