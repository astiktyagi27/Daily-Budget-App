// Shared Phase 3 fixtures (plan T-389, D-085). One owner, so the eight Phase 3
// test files use the same data. Every amount is a paise literal copied from
// the Tester's section 0 / 2 of tests/F-010 .. F-017, never computed here, and
// every fixture is checked against the real engine in
// test/fixtures/phase3_fixtures_test.dart. Extend this file only by adding
// fixtures.
//
// Pure data on top of `test/domain/budget/fixtures.dart`: no Flutter, no fake
// store. `phase3_data.dart` puts a fixture into a `FakeMoneyStore`.
//
// Name collisions in the Tester's files (kept apart, to be confirmed by the
// Tester, T-387):
//  * Canonical M20 (orchestrator ruling): F-013 / F-014's seed, `fixtureM20`,
//    also named `m20` and `m20c` (it already holds the 20,000 cover); `m20nc`
//    is the same month without its cover (F-010 M20nc, TC-010-17 and -18).
//  * `f12` is F-010's example F (spends 80,000 and 1,10,000); `fixtureF` is
//    F-013 / F-016's F (spends 1,50,000 and 50,000).
//  * `octNov` is F-011's October (E2 values); `fixtureO1` is F-013's October
//    (Rent 9,00,000).
//
// Categories: a fixture entry may carry a category storage key (`B`, `AF`).
// Since F-013 T-380 `Spend.category` is read (null and unknown keys read as
// Other), so a seeded store carries it; F-015 T-420 adds the write side.

import 'package:daily_budget/domain/budget/budget.dart';

import '../domain/budget/fixtures.dart';

/// One transaction of a fixture: a spend, or money in (a refund).
final class FixtureEntry {
  const new({
    required this.date,
    required this.paise,
    required this.createdAt,
    this.note,
    this.categoryKey,
    this.moneyIn = false,
  });

  final CalendarDate date;

  final int paise;

  /// Orders entries of one day (UTC milliseconds, as `at`).
  final int createdAt;

  final String? note;

  /// The storage key of the category (`food`, `shopping`), or null (Other).
  final String? categoryKey;

  final bool moneyIn;

  Spend toSpend(int id) => Spend(
    id: id,
    date: date,
    amount: Paise(paise),
    createdAt: createdAt,
    direction: moneyIn ? SpendDirection.moneyIn : SpendDirection.spend,
    category: categoryKey == null ? null : SpendCategory.fromKey(categoryKey),
  );

  FixtureEntry copyWith({int? paise, String? categoryKey}) => FixtureEntry(
    date: date,
    paise: paise ?? this.paise,
    createdAt: createdAt,
    note: note,
    categoryKey: categoryKey ?? this.categoryKey,
    moneyIn: moneyIn,
  );
}

/// A spend of [paise] on [date], created at [hour]:[minute].
FixtureEntry fixtureSpend(
  CalendarDate date,
  int paise, {
  String? note,
  int hour = 12,
  int minute = 0,
  String? category,
}) => FixtureEntry(
  date: date,
  paise: paise,
  createdAt: at(date, hour, minute),
  note: note,
  categoryKey: category,
);

/// Money in (a refund) of [paise] on [date], created at [hour]:[minute].
FixtureEntry fixtureMoneyIn(
  CalendarDate date,
  int paise, {
  String? note,
  int hour = 12,
  int minute = 0,
}) => FixtureEntry(
  date: date,
  paise: paise,
  createdAt: at(date, hour, minute),
  note: note,
  moneyIn: true,
);

/// A savings move of [paise] covering [day], made at [madeAt].
final class FixtureCover {
  const new({required this.day, required this.paise, required this.madeAt});

  final CalendarDate day;

  final int paise;

  final int madeAt;
}

/// One stored month of a fixture: its periods and what was entered in it.
final class FixtureMonth {
  const new({
    required this.month,
    required this.firstBudgetedDay,
    required this.periods,
    this.entries = const [],
    this.covers = const [],
  });

  final BudgetMonth month;

  final CalendarDate firstBudgetedDay;

  final List<BudgetPeriod> periods;

  final List<FixtureEntry> entries;

  final List<FixtureCover> covers;

  /// The engine's input for [today]: entries and covers get the ids 1, 2, ...
  /// in list order.
  MonthInput input(CalendarDate today) => MonthInput(
    month: month,
    firstBudgetedDay: firstBudgetedDay,
    periods: periods,
    today: today,
    spends: [
      for (final (index, entry) in entries.indexed) entry.toSpend(index + 1),
    ],
    covers: [
      for (final (index, cover) in covers.indexed)
        Cover(
          id: index + 1,
          day: cover.day,
          amount: Paise(cover.paise),
          madeAt: cover.madeAt,
        ),
    ],
  );

  MonthResult result(CalendarDate today) => computeMonth(input(today));

  FixtureMonth copyWith({
    List<BudgetPeriod>? periods,
    List<FixtureEntry>? entries,
    List<FixtureCover>? covers,
  }) => FixtureMonth(
    month: month,
    firstBudgetedDay: firstBudgetedDay,
    periods: periods ?? this.periods,
    entries: entries ?? this.entries,
    covers: covers ?? this.covers,
  );
}

/// A data set of the Phase 3 test cases: the stored months (oldest first, as
/// they are stored) and the device date.
final class Phase3Fixture {
  const new({required this.name, required this.months, required this.today});

  final String name;

  final List<FixtureMonth> months;

  final CalendarDate today;

  /// The newest stored month, the one the screens open on.
  FixtureMonth get current => months.last;

  /// The engine's result for [current] on [today].
  MonthResult get result => current.result(today);

  /// The device clock for [today], 14:00 (the "Today(Fri 13 Nov 2026, 14:00)"
  /// of the test cases).
  DateTime get now => DateTime(today.year, today.month, today.day, 14);

  Phase3Fixture copyWith({
    String? name,
    CalendarDate? today,
    List<BudgetPeriod>? periods,
    List<FixtureEntry>? entries,
    List<FixtureCover>? covers,
  }) => Phase3Fixture(
    name: name ?? this.name,
    today: today ?? this.today,
    months: [
      ...months.take(months.length - 1),
      current.copyWith(periods: periods, entries: entries, covers: covers),
    ],
  );

  /// This fixture with [entries] and [covers] added to [current].
  Phase3Fixture plus({
    required String name,
    List<FixtureEntry> entries = const [],
    List<FixtureCover> covers = const [],
    CalendarDate? today,
  }) => copyWith(
    name: name,
    today: today,
    entries: [...current.entries, ...entries],
    covers: [...current.covers, ...covers],
  );

  /// This fixture with every entry of [current] mapped through [change].
  Phase3Fixture mapEntries(
    String name,
    FixtureEntry Function(FixtureEntry entry) change,
  ) => copyWith(name: name, entries: current.entries.map(change).toList());
}

CalendarDate _nov(int day) => d(2026, 11, day);

/// A stored month with one period from [first], saved the day before it (as
/// `addMonth` in `setup_harness.dart`, so a change on that day orders after).
FixtureMonth _month({
  required BudgetMonth month,
  required PeriodValues values,
  CalendarDate? first,
  bool continued = false,
  List<BudgetPeriod>? periods,
  List<FixtureEntry> entries = const [],
  List<FixtureCover> covers = const [],
}) {
  final start = first ?? month.start;
  return FixtureMonth(
    month: month,
    firstBudgetedDay: start,
    periods:
        periods ??
        [
          period(
            start,
            values,
            changedAt: at(start.addDays(-1), 0),
            continued: continued,
          ),
        ],
    entries: entries,
    covers: covers,
  );
}

/// The E2 month (5 Nov - 4 Dec 2026, 83,000 a day) with [entries].
FixtureMonth _e2Month({
  List<FixtureEntry> entries = const [],
  List<FixtureCover> covers = const [],
}) => _month(
  month: nov2026,
  values: e2Values(),
  entries: entries,
  covers: covers,
);

/// The month of October 2026 of F-011's OCT-NOV (E2 values, 5 Oct - 4 Nov).
FixtureMonth _octoberE2() => _month(
  month: oct2026,
  values: e2Values(),
  entries: [
    fixtureSpend(d(2026, 10, 5), 50000),
    fixtureSpend(d(2026, 10, 6), 100000),
  ],
);

// ---------------------------------------------------------------------------
// Example A (F-010 section 2.4): the E2 month on Fri 13 Nov 2026.
// ---------------------------------------------------------------------------

/// A (also F-010's A13): spends 5 - 13 Nov, 5,53,000 in all. Saved 2,00,000 ·
/// overspent 47,000 · pot 2,00,000 · Left 19,37,000. The notes are those of
/// F-013 / F-015; the 9 Nov Lunch is created before the no-note spend.
final Phase3Fixture fixtureA = Phase3Fixture(
  name: 'A',
  today: _nov(13),
  months: [
    _e2Month(
      entries: [
        fixtureSpend(_nov(5), 50000, note: 'Groceries'),
        fixtureSpend(_nov(6), 100000, note: 'Shoes'),
        fixtureSpend(_nov(7), 83000, note: 'Dinner out'),
        fixtureSpend(_nov(8), 20000, note: 'Chai and snacks'),
        fixtureSpend(_nov(9), 25000, note: 'Lunch', hour: 13),
        fixtureSpend(_nov(9), 37000, hour: 20),
        fixtureSpend(_nov(10), 83000, note: 'Petrol'),
        fixtureSpend(_nov(11), 113000, note: 'Phone bill'),
        fixtureSpend(_nov(13), 42000, note: 'Lunch'),
      ],
    ),
  ],
);

/// F-010's name for A.
final Phase3Fixture a13 = fixtureA;

/// A with a 30,000 cover for 11 Nov, made 13 Nov 09:00 (F-010 A13c300).
/// Pot 1,70,000 · overspent 17,000 · Left 19,37,000.
final Phase3Fixture fixtureAPlusCover = fixtureA.plus(
  name: 'A+cover',
  covers: [FixtureCover(day: _nov(11), paise: 30000, madeAt: at(_nov(13), 9))],
);

/// F-010's name for A+cover.
final Phase3Fixture a13c300 = fixtureAPlusCover;

/// A with a 50,000 refund on 13 Nov, note `Amazon return` (F-013 A+refund and
/// F-015 AR). Today's net −8,000 · spent so far 5,03,000 · Left 19,87,000.
final Phase3Fixture fixtureAPlusRefund = fixtureA.plus(
  name: 'A+refund',
  entries: [fixtureMoneyIn(_nov(13), 50000, note: 'Amazon return')],
);

/// A13o (F-012): the 13 Nov spend raised to 1,00,000 (today overspent 17,000).
final Phase3Fixture a13o = fixtureA.mapEntries(
  'A13o',
  (entry) => entry.date == _nov(13) ? entry.copyWith(paise: 100000) : entry,
);

/// A14 (F-017): A with the clock at 14 Nov, nothing spent on 14 Nov. Left
/// 19,37,000 · 21 days left.
final Phase3Fixture a14 = fixtureA.copyWith(name: 'A14', today: _nov(14));

/// A13 +410 (F-017): A plus 41,000 on 13 Nov (today's spend 83,000, Left
/// 18,96,000).
final Phase3Fixture a13Plus410 = fixtureA.plus(
  name: 'A13 +410',
  entries: [fixtureSpend(_nov(13), 41000, hour: 13)],
);

/// B (F-013): A with 6 Nov `Shoes` in `shopping` and both 9 Nov spends in
/// `food`. Other 3,91,000 · Shopping 1,00,000 · Food 62,000.
final Phase3Fixture fixtureB = fixtureA.mapEntries('B', (entry) {
  if (entry.date == _nov(6)) return entry.copyWith(categoryKey: 'shopping');
  if (entry.date == _nov(9)) return entry.copyWith(categoryKey: 'food');
  return entry;
});

/// AF (F-015): A with both `Lunch` spends (13 Nov and 9 Nov) in `food`.
final Phase3Fixture fixtureAF = fixtureA.mapEntries(
  'AF',
  (entry) =>
      entry.note == 'Lunch' ? entry.copyWith(categoryKey: 'food') : entry,
);

/// A2 (F-015): A plus 30,050 `Snacks` and 9,000 `250g paneer` on 12 Nov.
final Phase3Fixture fixtureA2 = fixtureA.plus(
  name: 'A2',
  entries: [
    fixtureSpend(_nov(12), 30050, note: 'Snacks', hour: 10),
    fixtureSpend(_nov(12), 9000, note: '250g paneer', hour: 11),
  ],
);

/// A3 (F-015): A plus a Hindi, a coffee and a family-emoji note on 12 Nov.
final Phase3Fixture fixtureA3 = fixtureA.plus(
  name: 'A3',
  entries: [
    fixtureSpend(_nov(12), 2000, note: 'चाय', hour: 9),
    fixtureSpend(_nov(12), 3000, note: '☕ chai', hour: 10),
    fixtureSpend(_nov(12), 4000, note: '👨‍👩‍👧 dinner', hour: 11),
  ],
);

// ---------------------------------------------------------------------------
// Example S (F-010 section 2.5): a shortfall month, every day budget 0.
// ---------------------------------------------------------------------------

/// S (F-010's S8): S1 values continued anyway, one spend of 20,000 on 6 Nov,
/// Today(Sun 8 Nov). Left −1,20,000 · spent 20,000 · saved 0 · overspent
/// 20,000 · pot 0.
final Phase3Fixture fixtureS = Phase3Fixture(
  name: 'S',
  today: _nov(8),
  months: [
    _month(
      month: nov2026,
      values: s1Values(),
      continued: true,
      entries: [fixtureSpend(_nov(6), 20000)],
    ),
  ],
);

/// F-010's name for S.
final Phase3Fixture s8 = fixtureS;

/// S8+150 (F-010): S8 plus 15,000 on 8 Nov (today). Left −1,35,000 ·
/// overspent 35,000 (D-060).
final Phase3Fixture s8Plus150 = fixtureS.plus(
  name: 'S8+150',
  entries: [fixtureSpend(_nov(8), 15000)],
);

/// S8-refund (F-017): S8 plus money in of 3,00,000 on 7 Nov. Left 1,80,000 ·
/// 27 days left when Today(8 Nov) and nothing is spent today.
final Phase3Fixture s8Refund = fixtureS.plus(
  name: 'S8-refund',
  entries: [fixtureMoneyIn(_nov(7), 300000)],
);

// ---------------------------------------------------------------------------
// Example F (F-010 section 2.7): the first month used mid-month.
// ---------------------------------------------------------------------------

FixtureMonth _firstUsedOn10Nov(List<FixtureEntry> entries) => _month(
  month: nov2026,
  first: _nov(10),
  values: const MidMonthStartValues(moneyLeft: Paise(2490000)),
  entries: entries,
);

/// F12 (F-010): first use 10 Nov, money left 24,90,000, nothing still to pay,
/// 25 days at 99,600. Spends 10 Nov 80,000 · 11 Nov 1,10,000, Today(12 Nov).
/// Spent so far 1,90,000 · Left 23,00,000 · saved 19,600 · overspent 10,400.
final Phase3Fixture f12 = Phase3Fixture(
  name: 'F12',
  today: _nov(12),
  months: [
    _firstUsedOn10Nov([
      fixtureSpend(_nov(10), 80000),
      fixtureSpend(_nov(11), 110000),
    ]),
  ],
);

/// F (F-013 / F-016): the same month with spends 10 Nov 1,50,000 · 11 Nov
/// 50,000, Today(Thu 12 Nov).
final Phase3Fixture fixtureF = Phase3Fixture(
  name: 'F',
  today: _nov(12),
  months: [
    _firstUsedOn10Nov([
      fixtureSpend(_nov(10), 150000),
      fixtureSpend(_nov(11), 50000),
    ]),
  ],
);

// ---------------------------------------------------------------------------
// Example M: salary changed on 13 Nov, salary day 1, month 1 - 30 Nov 2026.
// ---------------------------------------------------------------------------

final _november1 = BudgetMonth.startIn(1, 2026, 11);

/// Two periods: E2 values from 1 Nov (83,000 a day) and salary 35,00,000 from
/// 13 Nov (13 - 16 Nov 55,223 · 17 - 30 Nov 55,222).
List<BudgetPeriod> _salaryChangedOn13Nov() => [
  period(_nov(1), e2Values(), changedAt: at(d(2026, 10, 31), 0)),
  period(_nov(13), e2Values(salary: 3500000)),
];

FixtureMonth _exampleM(List<FixtureEntry> entries, List<FixtureCover> covers) =>
    FixtureMonth(
      month: _november1,
      firstBudgetedDay: _nov(1),
      periods: _salaryChangedOn13Nov(),
      entries: entries,
      covers: covers,
    );

/// Period 1 spends of M-full and M20 (F-013 section 0): 1 Nov 33,000 · 2 Nov
/// 53,000 · 3 Nov 53,000 · 4 Nov 63,000 · 5 Nov 73,000 · 6 Nov 1,27,000 ·
/// 7 - 12 Nov 83,000 each (9,00,000), and the 20,000 cover for 6 Nov made
/// 7 Nov 21:00.
List<FixtureEntry> _mPeriodOneSpends() => [
  for (final (index, paise) in const [
    33000,
    53000,
    53000,
    63000,
    73000,
    127000,
    83000,
    83000,
    83000,
    83000,
    83000,
    83000,
  ].indexed)
    fixtureSpend(_nov(index + 1), paise),
];

List<FixtureCover> _mCover() => [
  FixtureCover(day: _nov(6), paise: 20000, madeAt: at(_nov(7), 21)),
];

/// M-full (F-013 / F-014), viewed Today(Tue 1 Dec): P2 spends 13 - 19 Nov and
/// 21 Nov 54,000 · 20 Nov 85,300 · 22 - 24 and 26 - 30 Nov 53,500 · 25 Nov
/// 54,700 and a refund of 50,000 on 25 Nov. Month: saved 2,14,078 · overspent
/// 54,078 · covered 20,000 · pot 1,94,078 · Left 1,40,000.
final Phase3Fixture fixtureMFull = Phase3Fixture(
  name: 'M-full',
  today: d(2026, 12, 1),
  months: [
    _exampleM([
      ..._mPeriodOneSpends(),
      for (var day = 13; day <= 30; day++)
        if (day == 20)
          fixtureSpend(_nov(day), 85300)
        else if (day == 25) ...[
          fixtureSpend(_nov(day), 54700),
          fixtureMoneyIn(_nov(day), 50000),
        ] else if (day <= 19 || day == 21)
          fixtureSpend(_nov(day), 54000)
        else
          fixtureSpend(_nov(day), 53500),
    ], _mCover()),
  ],
);

/// M20 of F-013 section 0, Today(Fri 20 Nov): P1 as M-full; P2 spends 13 -
/// 19 Nov 45,000 each, 20 Nov 85,000. Saved 2,11,558 · overspent 53,778 ·
/// covered 20,000 · pot 1,91,558 · Left 6,90,000.
final Phase3Fixture fixtureM20 = Phase3Fixture(
  name: 'M20 (F-013)',
  today: _nov(20),
  months: [
    _exampleM([
      ..._mPeriodOneSpends(),
      for (var day = 13; day <= 19; day++) fixtureSpend(_nov(day), 45000),
      fixtureSpend(_nov(20), 85000),
    ], _mCover()),
  ],
);

/// The canonical M20 (and M20c): Home reads Saved ₹2,115, Overspent ₹537,
/// pot ₹1,915, Left ₹6,900.
final Phase3Fixture m20 = fixtureM20;
final Phase3Fixture m20c = fixtureM20;

/// M20nc (F-010 section 0): the canonical M20 without its cover. Saved
/// 2,11,558 · covered 0 · pot 2,11,558 · overspent 73,778 · Left 6,90,000.
final Phase3Fixture m20nc = fixtureM20.copyWith(
  name: 'M20nc',
  covers: const [],
);

// ---------------------------------------------------------------------------
// Past months.
// ---------------------------------------------------------------------------

/// OCT-NOV (F-011, F-012): October (E2 values, 5 Oct - 4 Nov, spends 5 Oct
/// 50,000 and 6 Oct 1,00,000), stored first, then November = A. Today(13
/// Nov). Months are `months[0]` (Oct) and `months[1]` (Nov).
final Phase3Fixture octNov = Phase3Fixture(
  name: 'OCT-NOV',
  today: _nov(13),
  months: [_octoberE2(), fixtureA.current],
);

/// O1 (F-013, F-015): October 2026 with Rent 9,00,000 (spendable 31,00,000,
/// 1,00,000 a day), spends Sat 10 Oct 1,40,000 · Tue 20 Oct 60,000 · Wed 4
/// Nov 25,000, stored beside A. Today(13 Nov).
final Phase3Fixture fixtureO1 = Phase3Fixture(
  name: 'O1',
  today: _nov(13),
  months: [
    _month(
      month: oct2026,
      values: const FullMonthValues(
        salary: Paise(4000000),
        fixedCosts: [FixedCost(name: 'Rent', amount: Paise(900000))],
      ),
      entries: [
        fixtureSpend(d(2026, 10, 10), 140000),
        fixtureSpend(d(2026, 10, 20), 60000),
        fixtureSpend(_nov(4), 25000),
      ],
    ),
    fixtureA.current,
  ],
);

// ---------------------------------------------------------------------------
// Other worked data sets.
// ---------------------------------------------------------------------------

/// N (F-013): E2 month, Today(13 Nov): a spend of 20,000 on 5 Nov and a
/// refund of 50,000 on 6 Nov. Month net spent −30,000.
final Phase3Fixture fixtureN = Phase3Fixture(
  name: 'N',
  today: _nov(13),
  months: [
    _e2Month(
      entries: [fixtureSpend(_nov(5), 20000), fixtureMoneyIn(_nov(6), 50000)],
    ),
  ],
);

/// P250 (F-012): spends 5 Nov 58,000 · 6 - 10 Nov 83,000 each · 11 Nov
/// 1,13,000 · 12 Nov 83,000, Today(13 Nov). Pot 25,000 (only 5 Nov saved),
/// 11 Nov overspent 30,000.
final Phase3Fixture p250 = Phase3Fixture(
  name: 'P250',
  today: _nov(13),
  months: [
    _e2Month(
      entries: [
        fixtureSpend(_nov(5), 58000),
        for (var day = 6; day <= 10; day++) fixtureSpend(_nov(day), 83000),
        fixtureSpend(_nov(11), 113000),
        fixtureSpend(_nov(12), 83000),
      ],
    ),
  ],
);

/// W3 (F-012, F-009 AC-19 data): spends 5 Nov 50,000 · 6 Nov 1,00,000 · 7 Nov
/// 83,000; cover 17,000 on 6 Nov; Today(8 Nov). 5 Nov saved 33,000 · pot
/// 16,000 · 6 Nov on budget (covered).
final Phase3Fixture w3 = Phase3Fixture(
  name: 'W3',
  today: _nov(8),
  months: [
    _e2Month(
      entries: [
        fixtureSpend(_nov(5), 50000),
        fixtureSpend(_nov(6), 100000),
        fixtureSpend(_nov(7), 83000),
      ],
      covers: [
        FixtureCover(day: _nov(6), paise: 17000, madeAt: at(_nov(8), 9)),
      ],
    ),
  ],
);

/// R16 (F-012): Mon 16 Nov a spend of 70,000 `Shoes` and money in of 50,000
/// `Amazon return`, Today(18 Nov). Net 20,000 · 16 Nov saved 63,000.
final Phase3Fixture r16 = Phase3Fixture(
  name: 'R16',
  today: _nov(18),
  months: [
    _e2Month(
      entries: [
        fixtureSpend(_nov(16), 70000, note: 'Shoes', hour: 10),
        fixtureMoneyIn(_nov(16), 50000, note: 'Amazon return', hour: 11),
      ],
    ),
  ],
);

/// The covers of P1 and P1b (F-016 AC-10): 8 Nov 50,000 (made 9 Nov 21:00),
/// 9 Nov 1,00,000 (made 10 Nov 21:00), 10 Nov 1,00,000 (made 13 Nov 09:00).
List<FixtureCover> _p1Covers() => [
  FixtureCover(day: _nov(8), paise: 50000, madeAt: at(_nov(9), 21)),
  FixtureCover(day: _nov(9), paise: 100000, madeAt: at(_nov(10), 21)),
  FixtureCover(day: _nov(10), paise: 100000, madeAt: at(_nov(13), 9)),
];

/// P1 (F-016, the Tester's seed for AC-10): spends 7 Nov 49,000 · 8 Nov
/// 1,33,000 · 9 and 10 Nov 1,83,000 · 11 Nov 83,000 · 12 Nov 83,000 and a
/// refund of 1,50,000 (day saved 1,50,000); the three covers above; Today(13
/// Nov). Saved 3,50,000 · covers 2,50,000 · pot 1,00,000.
final Phase3Fixture p1 = Phase3Fixture(
  name: 'P1',
  today: _nov(13),
  months: [
    _e2Month(
      entries: [
        fixtureSpend(_nov(7), 49000),
        fixtureSpend(_nov(8), 133000),
        fixtureSpend(_nov(9), 183000),
        fixtureSpend(_nov(10), 183000),
        fixtureSpend(_nov(11), 83000),
        fixtureSpend(_nov(12), 83000, hour: 10),
        fixtureMoneyIn(_nov(12), 150000, hour: 11),
      ],
      covers: _p1Covers(),
    ),
  ],
);

/// P1b (F-016): P1 with 5 and 6 Nov spends of 83,000 (on budget) and the
/// 12 Nov refund 3,16,000 (day saved 3,16,000). Saved 3,50,000, same covers,
/// pot 1,00,000.
final Phase3Fixture p1b = Phase3Fixture(
  name: 'P1b',
  today: _nov(13),
  months: [
    _e2Month(
      entries: [
        fixtureSpend(_nov(5), 83000),
        fixtureSpend(_nov(6), 83000),
        fixtureSpend(_nov(7), 49000),
        fixtureSpend(_nov(8), 133000),
        fixtureSpend(_nov(9), 183000),
        fixtureSpend(_nov(10), 183000),
        fixtureSpend(_nov(11), 83000),
        fixtureSpend(_nov(12), 83000, hour: 10),
        fixtureMoneyIn(_nov(12), 316000, hour: 11),
      ],
      covers: _p1Covers(),
    ),
  ],
);

/// E2 day 1 (F-017): Today(5 Nov), no spends. Left 24,90,000 · 30 days left.
final Phase3Fixture e2Day1 = Phase3Fixture(
  name: 'E2 day 1',
  today: _nov(5),
  months: [_e2Month()],
);

/// E2 last (F-017): Today(4 Dec), no spends. Saved 24,07,000 · Left
/// 24,90,000 · 1 day left.
final Phase3Fixture e2Last = Phase3Fixture(
  name: 'E2 last',
  today: d(2026, 12, 4),
  months: [_e2Month()],
);

/// OV5 (F-017): 5 Nov spent 1,83,000 (overspent 1,00,000), Today(6 Nov),
/// nothing today. Left 23,07,000 · 29 days left.
final Phase3Fixture ov5 = Phase3Fixture(
  name: 'OV5',
  today: _nov(6),
  months: [
    _e2Month(entries: [fixtureSpend(_nov(5), 183000)]),
  ],
);

// ---------------------------------------------------------------------------
// F-014 period histories (tests/F-014 section 0).
// ---------------------------------------------------------------------------

/// E2c: E2 with rent -> 13,00,000 on 20 Nov (P2 20 - 27 Nov, 63,000 a day)
/// and EMI -> 4,00,000 on 28 Nov (P3 28 Nov - 4 Dec, 77,286 x 5 then 77,285 x
/// 2). Money for the month 22,90,000. No spends.
final Phase3Fixture e2c = Phase3Fixture(
  name: 'E2c',
  today: d(2026, 12, 5),
  months: [
    _e2Month().copyWith(
      periods: [
        period(_nov(5), e2Values(), changedAt: at(_nov(4), 0)),
        period(_nov(20), e2Values(rent: 1300000)),
        period(_nov(28), e2Values(rent: 1300000, emi: 400000)),
      ],
    ),
  ],
);

/// E2s: E2 with rent -> 13,00,000 at 10:00 and rent -> 11,00,000 at 18:00 on
/// 20 Nov (F-006 AC-22). P2 shows 76,334 on its first 5 days (11,45,000 / 15).
final Phase3Fixture e2s = Phase3Fixture(
  name: 'E2s',
  today: d(2026, 12, 5),
  months: [
    _e2Month().copyWith(
      periods: [
        period(_nov(5), e2Values(), changedAt: at(_nov(4), 0)),
        period(_nov(20), e2Values(rent: 1300000), changedAt: at(_nov(20), 10)),
        period(_nov(20), e2Values(rent: 1100000), changedAt: at(_nov(20), 18)),
      ],
    ),
  ],
);

/// C4: E2 with a spending target of 25,00,000 saved on 20 Nov, continued
/// anyway (F-006 C4). P2 shortfall 2,55,000.
final Phase3Fixture c4 = Phase3Fixture(
  name: 'C4',
  today: d(2026, 12, 5),
  months: [
    _e2Month().copyWith(
      periods: [
        period(_nov(5), e2Values(), changedAt: at(_nov(4), 0)),
        period(_nov(20), e2Values(target: 2500000), continued: true),
      ],
    ),
  ],
);

/// Mx: salary day 1, 1 - 30 Nov, E2 values, salary -> 35,00,000 on 13 Nov;
/// one spend of 4,50,060 on 3 Nov and one on 15 Nov; Today(1 Dec). The
/// rounding-note data of TC-014-18.
final Phase3Fixture mx = Phase3Fixture(
  name: 'Mx',
  today: d(2026, 12, 1),
  months: [
    _exampleM([
      fixtureSpend(_nov(3), 450060),
      fixtureSpend(_nov(15), 450060),
    ], const []),
  ],
);

// ---------------------------------------------------------------------------
// Load data (F-013 AC-17, F-015 AC-16).
// ---------------------------------------------------------------------------

const _loadNotes = [
  'Lunch',
  'Auto ride',
  'Groceries',
  'Phone bill',
  'Coffee',
  'Movie night',
  'Medicine',
  'Dinner with friends',
  'Petrol',
  'Snacks',
];

/// The nine storage keys in README order (the same list every category test
/// uses).
const loadCategoryKeys = [
  'food',
  'groceries',
  'shopping',
  'travel',
  'bills_recharge',
  'entertainment',
  'health',
  'friends_people',
  'other',
];

/// [count] spends over the days of [month], spread evenly by index, nine
/// categories in turn, notes from a fixed list, amounts 10.00 to 99.99 rupees
/// from a fixed formula. No random numbers: the same data on every run.
FixtureMonth _loadMonth(BudgetMonth month, int count) {
  final days = month.start.daysUntil(month.end) + 1;
  return _month(
    month: month,
    values: e2Values(),
    entries: [
      for (var i = 0; i < count; i++)
        fixtureSpend(
          month.start.addDays(i % days),
          1000 + (i * 37) % 9000,
          note: _loadNotes[i % _loadNotes.length],
          hour: 8 + i % 12,
          minute: i % 60,
          category: loadCategoryKeys[i % loadCategoryKeys.length],
        ),
    ],
  );
}

/// L1000 (F-013 T-385, F-015): 1,000 spends over three budget months, 250 in
/// Sep and 250 in Oct and 500 in the current Nov (5 Nov - 4 Dec 2026), all
/// nine categories used. Today(Fri 4 Dec), the last day of the current month.
final Phase3Fixture fixtureL1000 = Phase3Fixture(
  name: 'L1000',
  today: d(2026, 12, 4),
  months: [
    _loadMonth(BudgetMonth.startIn(5, 2026, 9), 250),
    _loadMonth(oct2026, 250),
    _loadMonth(nov2026, 500),
  ],
);

/// F-015's name for it.
final Phase3Fixture l1000 = fixtureL1000;
