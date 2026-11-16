// Shared fixtures for the F-006 engine tests (tests/F-006 §0). Expected values
// in the tests are paise literals copied from the spec, never computed here.

import 'dart:math';

import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

/// The calendar date [year]-[month]-[day].
CalendarDate d(int year, int month, int day) => CalendarDate(year, month, day);

/// [value] paise.
Paise p(int value) => Paise(value);

/// The seed of every property test: 2026 (tests/F-006 §0), or the value of
/// `--dart-define=PROPERTY_SEED=<n>` to replay another run.
const propertySeed = int.fromEnvironment('PROPERTY_SEED', defaultValue: 2026);

/// Expands runs of `(count, paise)` into one list, e.g. `[(10, 133334),
/// (20, 133333)]` for E1.
List<Paise> runs(List<(int, int)> runs) => [
  for (final (count, value) in runs) ...List.filled(count, Paise(value)),
];

/// A uniform random integer from 0 to [maxInclusive] (which may be above the
/// 2^32 limit of [Random.nextInt]).
int uniformUpTo(Random random, int maxInclusive) {
  const chunk = 1 << 30;
  final high = random.nextInt(maxInclusive ~/ chunk + 1);
  final low = random.nextInt(chunk);
  final value = high * chunk + low;
  return value > maxInclusive ? value % (maxInclusive + 1) : value;
}

/// Checks [budgets] against the D-035 rule for [amount] over [days] days.
void expectFairSpread(List<Paise> budgets, int amount, int days, String why) {
  expect(budgets, hasLength(days), reason: why);
  final base = amount ~/ days;
  final extra = amount % days;
  var sum = 0;
  for (var i = 0; i < days; i++) {
    final value = budgets[i].value;
    if (value != (i < extra ? base + 1 : base)) {
      fail('$why: day ${i + 1} is $value');
    }
    sum += value;
  }
  expect(sum, amount, reason: why);
}

/// The F-006 example months: 5 Oct – 4 Nov 2026 (31 days) and 5 Nov –
/// 4 Dec 2026 (30 days), salary day 5.
final oct2026 = BudgetMonth.startIn(5, 2026, 10);
final nov2026 = BudgetMonth.startIn(5, 2026, 11);

/// An ordering time: [day] at [hour]:[minute] UTC, in milliseconds.
int at(CalendarDate day, int hour, [int minute = 0]) =>
    day.dayNumber * Duration.millisecondsPerDay +
    hour * Duration.millisecondsPerHour +
    minute * Duration.millisecondsPerMinute;

/// The E2 fixed costs: Rent 10,00,000, EMI 5,00,000, Subscriptions 10,000.
List<FixedCost> e2Costs({
  int rent = 1000000,
  int emi = 500000,
  int subscriptions = 10000,
}) => [
  FixedCost(name: 'Rent', amount: Paise(rent)),
  FixedCost(name: 'EMI', amount: Paise(emi)),
  FixedCost(name: 'Subscriptions', amount: Paise(subscriptions)),
];

/// E2: salary 40,00,000, no target, the E2 costs (spendable 24,90,000).
FullMonthValues e2Values({
  int salary = 4000000,
  int? target,
  int rent = 1000000,
  int emi = 500000,
}) => FullMonthValues(
  salary: Paise(salary),
  target: target == null ? null : Paise(target),
  fixedCosts: e2Costs(rent: rent, emi: emi),
);

/// S1: salary 20,00,000, Rent 15,00,000 + EMI 6,00,000 (shortfall 1,00,000).
FullMonthValues s1Values({int emi = 600000}) => FullMonthValues(
  salary: const Paise(2000000),
  fixedCosts: [
    const FixedCost(name: 'Rent', amount: Paise(1500000)),
    FixedCost(name: 'EMI', amount: Paise(emi)),
  ],
);

/// A period from [start], saved at [changedAt] (default: [start] 09:00).
BudgetPeriod period(
  CalendarDate start,
  PeriodValues values, {
  int? changedAt,
  bool continued = false,
}) => BudgetPeriod(
  start: start,
  changedAt: changedAt ?? at(start, 9),
  values: values,
  continuedWithShortfall: continued,
);

/// A spend of [amount] paise on [date] (money in when [moneyIn]).
Spend spend(
  CalendarDate date,
  int amount, {
  int id = 0,
  bool moneyIn = false,
}) => Spend(
  id: id,
  date: date,
  amount: Paise(amount),
  createdAt: at(date, 12),
  direction: moneyIn ? SpendDirection.moneyIn : SpendDirection.spend,
);

/// A cover of [amount] paise for [day], made at [madeAt].
Cover cover(int id, CalendarDate day, int amount, int madeAt) =>
    Cover(id: id, day: day, amount: Paise(amount), madeAt: madeAt);

/// The E2 month with [spends], [covers] and [periods] (default: E2 from
/// 5 Nov), computed for [today].
MonthResult e2Month({
  required CalendarDate today,
  List<Spend> spends = const [],
  List<Cover> covers = const [],
  List<BudgetPeriod>? periods,
  CalendarDate? firstBudgetedDay,
}) => computeMonth(
  MonthInput(
    month: nov2026,
    firstBudgetedDay: firstBudgetedDay ?? d(2026, 11, 5),
    periods: periods ?? [period(d(2026, 11, 5), e2Values())],
    today: today,
    spends: spends,
    covers: covers,
  ),
);

/// W1: the F-006 §2.5 worked spends (today is passed in, 8 Nov in the spec).
List<Spend> w1Spends({int nov5 = 50000, int nov6 = 100000, int nov8 = 20000}) =>
    [
      spend(d(2026, 11, 5), nov5, id: 1),
      spend(d(2026, 11, 6), nov6, id: 2),
      spend(d(2026, 11, 7), 83000, id: 3),
      spend(d(2026, 11, 8), nov8, id: 4),
    ];

/// W2: the AC-12 spends (today 10 Nov).
List<Spend> w2Spends({int nov5 = 50000, int nov8 = 20000}) => [
  spend(d(2026, 11, 5), nov5, id: 1),
  spend(d(2026, 11, 6), 100000, id: 2),
  spend(d(2026, 11, 7), 100000, id: 3),
  spend(d(2026, 11, 8), nov8, id: 4),
  spend(d(2026, 11, 9), 83000, id: 5),
];

/// W2's covers: 6 Nov 17,000 made 8 Nov 21:00, 7 Nov 17,000 made 9 Nov 21:00.
List<Cover> w2Covers() => [
  cover(1, d(2026, 11, 6), 17000, at(d(2026, 11, 8), 21)),
  cover(2, d(2026, 11, 7), 17000, at(d(2026, 11, 9), 21)),
];

/// The day budgets of [result] from [from] to [to], inclusive.
List<Paise?> budgetsOf(
  MonthResult result,
  CalendarDate from,
  CalendarDate to,
) => [
  for (var day = from; !day.isAfter(to); day = day.addDays(1))
    result.dayOn(day).budget,
];

/// The budgets of every budgeted day of [result].
List<Paise> allBudgets(MonthResult result) => [
  for (final day in result.days) ?day.budget,
];

/// A canonical text of everything [result] reports, for deep equality and the
/// time-zone dumps (TC-006-13, TC-006-27).
String dump(MonthResult result) {
  final out = StringBuffer()
    ..writeln(
      'month ${result.month.start.iso} ${result.month.end.iso} '
      'first ${result.firstBudgetedDay.iso} today ${result.today.iso}',
    );
  for (final day in result.days) {
    out.writeln(
      '${day.date.iso} ${day.status.name} budget ${day.budget?.value} '
      'spent ${day.spent.value} net ${day.netSpent.value} '
      'in ${day.moneyIn.value} '
      'covered ${day.covered.value} result ${day.result?.value}',
    );
  }
  for (final p in result.periods) {
    final changes = [
      for (final c in p.changes)
        '${c.field.name} ${c.name} ${c.before?.value} ${c.after?.value}',
    ];
    out.writeln(
      'period ${p.start.iso} to ${p.end.iso} (${p.days} days) '
      'changedAt ${p.period.changedAt} superseded ${p.superseded} '
      'changes $changes amount ${p.amountToSpread.value} '
      'budgets ${[for (final b in p.budgets) b.value]} '
      'shortfall ${p.shortfall.value} zero ${p.zeroSpendable} '
      'netSpent ${p.netSpent.value} in ${p.moneyIn.value} '
      'saved ${p.saved.value} '
      'overspent ${p.overspent.value} covered ${p.covered.value}',
    );
  }
  out.writeln('totals ${result.totals}');
  for (final c in result.effectiveCovers) {
    out.writeln('cover ${c.coverId} ${c.day.iso} ${c.amount.value}');
  }
  for (final r in result.reductions) {
    out.writeln(
      'reduced ${r.coverId} ${r.day.iso} ${r.oldAmount.value} '
      '${r.newAmount.value}',
    );
  }
  for (final s in result.ignoredSpends) {
    out.writeln('ignored ${s.id} ${s.date.iso} ${s.amount.value}');
  }
  return out.toString();
}

/// Every date from [from] to [to], inclusive.
List<CalendarDate> dates(CalendarDate from, CalendarDate to) => [
  for (var day = from; !day.isAfter(to); day = day.addDays(1)) day,
];

/// The dates whose budget is [paise].
List<CalendarDate> datesWithBudget(MonthResult result, int paise) => [
  for (final day in result.days)
    if (day.budget == Paise(paise)) day.date,
];

/// Checks that the periods' totals add up exactly to the month totals.
void expectPeriodsAddUp(MonthResult result) {
  Paise sum(Paise Function(PeriodResult) of) =>
      Paise.sum(result.periods.map(of));
  final totals = result.totals;
  expect(sum((p) => p.netSpent), totals.spentSoFar, reason: 'spent');
  expect(sum((p) => p.moneyIn), totals.moneyIn, reason: 'money in');
  expect(sum((p) => p.saved), totals.saved, reason: 'saved');
  expect(sum((p) => p.overspent), totals.overspent, reason: 'overspent');
  expect(sum((p) => p.covered), totals.covered, reason: 'covered');
  expect(
    Paise.sum([for (final p in result.periods) ...p.budgets]),
    totals.budgeted,
    reason: 'budgets',
  );
  expect(
    result.periods.fold(0, (days, p) => days + p.days),
    result.firstBudgetedDay.daysUntil(result.month.end) + 1,
    reason: 'days',
  );
}
