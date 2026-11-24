import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/fake_month_repository.dart';
import '../../helpers/fake_transaction_repository.dart';
import 'repository_setup.dart';

/// One repository pair under test: the Drift one on a memory database, or the
/// in-memory fake (TC-011-63: one shared body, two setups).
typedef _Setup = ({
  MonthRepository months,
  Future<void> Function(int monthId) addSpend,
});

_Setup _drift() {
  final repos = openMemoryRepos();
  return (
    months: repos.months,
    addSpend: (monthId) => repos.spends.add(
      monthId,
      fields(d(2026, 11, 6), 1000),
      today: d(2026, 11, 13),
      now: at(d(2026, 11, 13), 9),
    ),
  );
}

_Setup _fake([FakeMoneyStore? store]) {
  final money = store ?? FakeMoneyStore();
  return (
    months: FakeMonthRepository(money),
    addSpend: (monthId) async {
      await FakeTransactionRepository(money).add(
        monthId,
        fields(d(2026, 11, 6), 1000),
        today: d(2026, 11, 13),
        now: at(d(2026, 11, 13), 9),
      );
    },
  );
}

NewMonth _newMonth(BudgetMonth month, [CalendarDate? first]) {
  final start = first ?? month.start;
  return NewMonth(
    month: month,
    firstBudgetedDay: start,
    firstPeriod: period(start, e2Values()),
    confirmedAt: at(start, 8),
  );
}

final _jun = BudgetMonth.startIn(5, 2026, 6);
final _sep = BudgetMonth.startIn(5, 2026, 9);
final _dec = BudgetMonth.startIn(5, 2026, 12);

/// Jun (first used 10 Jun), Sep and Nov, stored oldest first.
Future<List<StoredMonth>> _storeThree(MonthRepository months) async => [
  await months.confirmMonth(_newMonth(_jun, d(2026, 6, 10))),
  await months.confirmMonth(_newMonth(_sep)),
  await months.confirmMonth(_newMonth(nov2026)),
];

/// What the tests compare: the fields of a `MonthRef`, as plain values.
List<(int, String, String, int, String)> _project(List<MonthRef> index) => [
  for (final ref in index)
    (
      ref.id,
      ref.month.start.iso,
      ref.month.end.iso,
      ref.month.salaryDay,
      ref.firstBudgetedDay.iso,
    ),
];

void main() {
  for (final (label, make) in [('memory drift', _drift), ('fake', _fake)]) {
    group(label, () {
      test('TC-011-59 month index is newest first with ids and first budgeted '
          'days ($label)', () async {
        final setup = make();
        final stored = await _storeThree(setup.months);

        final index = await setup.months.watchMonthIndex().first;

        expect(_project(index), [
          (stored[2].id, '2026-11-05', '2026-12-04', 5, '2026-11-05'),
          (stored[1].id, '2026-09-05', '2026-10-04', 5, '2026-09-05'),
          (stored[0].id, '2026-06-05', '2026-07-04', 5, '2026-06-10'),
        ]);
        expect({for (final ref in index) ref.id}, hasLength(3));
      });

      test('TC-011-59 month index is newest first when stored in another order '
          '($label)', () async {
        final setup = make();
        await setup.months.confirmMonth(_newMonth(nov2026));
        await setup.months.confirmMonth(_newMonth(_jun, d(2026, 6, 10)));
        await setup.months.confirmMonth(_newMonth(_sep));

        final index = await setup.months.watchMonthIndex().first;

        expect(
          [for (final ref in index) ref.month.start.iso],
          ['2026-11-05', '2026-09-05', '2026-06-05'],
        );
      });

      test(
        'TC-011-60 month index lists only stored months so gaps stay visible '
        '($label)',
        () async {
          final setup = make();
          await _storeThree(setup.months);

          final index = await setup.months.watchMonthIndex().first;

          expect(index, hasLength(3));
          // Sep ends 4 Oct and Nov starts 5 Nov: the month between is missing.
          expect(index[1].month.end, d(2026, 10, 4));
          expect(index[0].month.start, d(2026, 11, 5));
        },
      );

      test('TC-011-61 month index is empty with no months ($label)', () async {
        final setup = make();
        final emissions = <List<MonthRef>>[];
        final errors = <Object>[];
        final sub = setup.months.watchMonthIndex().listen(
          emissions.add,
          onError: errors.add,
        );
        addTearDown(sub.cancel);

        await pumpEventQueue();

        expect(emissions, hasLength(1));
        expect(emissions.single, isEmpty);
        expect(errors, isEmpty);
        expect(sub.isPaused, isFalse, reason: 'the stream stays open');
      });

      test('TC-011-62 month index updates when a month is added and not for '
          'other changes ($label)', () async {
        final setup = make();
        final november = await setup.months.confirmMonth(_newMonth(nov2026));
        final emissions = <List<MonthRef>>[];
        final sub = setup.months.watchMonthIndex().listen(emissions.add);
        await pumpEventQueue();
        expect(emissions.last, hasLength(1));

        await setup.months.confirmMonth(_newMonth(_dec));
        await pumpEventQueue();
        expect(
          [for (final ref in emissions.last) ref.month.start.iso],
          ['2026-12-05', '2026-11-05'],
        );
        final idsAfterAdd = [for (final ref in emissions.last) ref.id];
        final emittedBefore = emissions.length;

        // (b) a new period of November and (c) a spend in November.
        await setup.months.addPeriod(
          november.id,
          period(d(2026, 11, 13), e2Values(salary: 3500000)),
        );
        await setup.addSpend(november.id);
        await pumpEventQueue();
        for (final emission in emissions.skip(emittedBefore)) {
          expect(emission, hasLength(2), reason: 'no duplicate');
          expect([for (final ref in emission) ref.id], idsAfterAdd);
          expect(emission.last.firstBudgetedDay, d(2026, 11, 5));
        }

        await sub.cancel();
        final count = emissions.length;
        await setup.months.confirmMonth(
          _newMonth(BudgetMonth.startIn(5, 2027, 1)),
        );
        await pumpEventQueue();
        expect(emissions, hasLength(count), reason: 'cancelled');
      });
    });
  }

  test('TC-011-63 month index fake and memory drift agree', () async {
    final results = <String, List<Object>>{};
    for (final (label, make) in [('drift', _drift), ('fake', _fake)]) {
      final setup = make();
      final seen = <Object>[];
      final empty = await setup.months.watchMonthIndex().first;
      seen.add(empty.length);
      await _storeThree(setup.months);
      seen.add(_project(await setup.months.watchMonthIndex().first));
      final live = <List<MonthRef>>[];
      final sub = setup.months.watchMonthIndex().listen(live.add);
      await pumpEventQueue();
      await setup.months.confirmMonth(_newMonth(_dec));
      await pumpEventQueue();
      seen.add(_project(live.last));
      await sub.cancel();
      results[label] = seen;
    }
    expect(results['fake'], results['drift']);
  });

  test(
    'TC-011-64 month index read failure is an error not an empty list (fake)',
    () async {
      final store = FakeMoneyStore();
      final setup = _fake(store);
      await _storeThree(setup.months);
      store.readFails = true;

      await expectLater(
        setup.months.watchMonthIndex(),
        emitsError(isA<StorageException>()),
      );

      store.readFails = false;
      expect(await setup.months.watchMonthIndex().first, hasLength(3));
    },
  );

  test('TC-011-64 month index read failure is an error not an empty list '
      '(memory drift)', () async {
    final repos = openMemoryRepos();
    await repos.db.customStatement('PRAGMA foreign_keys = OFF');
    await repos.db.customStatement('DROP TABLE budget_months');

    await expectLater(
      repos.months.watchMonthIndex(),
      emitsError(isA<StorageException>()),
    );
  });
}
