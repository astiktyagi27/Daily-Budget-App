import 'dart:io';

import 'package:daily_budget/data/repositories/savings_repository.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/fake_savings_repository.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import 'repository_setup.dart';

// F-007 additions of D-078 (cover id, removeCovers) and F-012 TC-012-09 / -43.
// Each body runs on real Drift (memory) and on the fake.

/// The A13 data in real Drift repositories. Returns the month id.
Future<int> _seedA13(Repos repos) async {
  final month = await repos.months.confirmMonth(e2NewMonth());
  for (final entry in fixtureA.current.entries) {
    await repos.spends.add(
      month.id,
      fields(entry.date, entry.paise, entry.note),
      today: fixtureA.today,
      now: entry.createdAt,
    );
  }
  return month.id;
}

typedef _Subject = ({SavingsRepository repository, int monthId});

Future<_Subject> _drift() async {
  final repos = openMemoryRepos();
  return (repository: repos.savings, monthId: await _seedA13(repos));
}

Future<_Subject> _fake() async {
  final store = storeFor(fixtureA);
  return (
    repository: FakeSavingsRepository(store),
    monthId: store.months.single.id,
  );
}

Future<List<(int, CalendarDate, int)>> _rows(_Subject s) async => [
  for (final c in await s.repository.watchCovers(s.monthId).first)
    (c.id, c.day, c.amount.value),
];

Future<List<int>> _amounts(Repos repos) async {
  final rows = await repos.db
      .customSelect('SELECT amount_paise FROM savings_moves ORDER BY id')
      .get();
  return [for (final row in rows) row.read<int>('amount_paise')];
}

void main() {
  final nov6 = d(2026, 11, 6);
  final nov11 = d(2026, 11, 11);
  final nov13 = d(2026, 11, 13);

  Future<CoverResult> coverOn(
    _Subject s,
    CalendarDate day,
    int paise, {
    int hour = 9,
  }) => s.repository.cover(
    s.monthId,
    day,
    Paise(paise),
    today: nov13,
    now: at(nov13, hour),
  );

  final implementations = <String, Future<_Subject> Function()>{
    'Drift': _drift,
    'fake': _fake,
  };

  for (final MapEntry(key: name, value: open) in implementations.entries) {
    test('TC-007-49 cover returns the stored id ($name)', () async {
      final s = await open();
      final first = await coverOn(s, nov11, 10000);
      final second = await coverOn(s, nov11, 20000, hour: 10);
      expect(first.decision, isA<CoverAllowed>());
      expect(second.decision, isA<CoverAllowed>());
      expect(first.coverId, isNotNull);
      expect(second.coverId, greaterThan(first.coverId!));
      expect(await _rows(s), [
        (first.coverId, nov11, 10000),
        (second.coverId, nov11, 20000),
      ]);
      final refused = await coverOn(s, nov6, 17001);
      expect(refused.coverId, isNull);
      expect(
        (refused.decision as CoverRefused).reason,
        CoverRefusal.exceedsOverspend,
      );
      expect(await _rows(s), hasLength(2));
    });

    test('TC-007-51 remove covers ignores unknown ids ($name)', () async {
      final s = await open();
      final id = (await coverOn(s, nov11, 30000)).coverId!;
      final listener = Collected(s.repository.watchCovers(s.monthId));
      await pumpEventQueue();
      expect(listener.values, hasLength(1));
      await s.repository.removeCovers(s.monthId, {id});
      await pumpEventQueue();
      expect(await _rows(s), isEmpty);
      expect(listener.values, hasLength(2));
      await s.repository.removeCovers(s.monthId, {id});
      await s.repository.removeCovers(s.monthId, {9999});
      await s.repository.removeCovers(9999, {id});
      await s.repository.removeCovers(s.monthId, {});
      await pumpEventQueue();
      expect(listener.values, hasLength(2));
      expect(listener.errors, isEmpty);
    });

    test(
      'TC-007-52 savings listeners update after remove covers ($name)',
      () async {
        final s = await open();
        final a = (await coverOn(s, nov11, 10000)).coverId!;
        final b = (await coverOn(s, nov11, 20000, hour: 10)).coverId!;
        final listener = Collected(s.repository.watchCovers(s.monthId));
        await pumpEventQueue();
        await s.repository.removeCovers(s.monthId, {a});
        await pumpEventQueue();
        await s.repository.removeCovers(s.monthId, {b});
        await pumpEventQueue();
        expect(
          [
            for (final emitted in listener.values)
              [for (final c in emitted) c.id],
          ],
          [
            [a, b],
            [b],
            <int>[],
          ],
        );
      },
    );
  }

  test('TC-007-50 fake remove covers fails all or nothing', () async {
    final store = storeFor(fixtureA);
    final s = (
      repository: FakeSavingsRepository(store),
      monthId: store.months.single.id,
    );
    final id = (await coverOn(s, nov11, 30000)).coverId!;
    store.failNextWrite = true;
    await expectLater(
      s.repository.removeCovers(s.monthId, {id}),
      throwsA(isA<StorageException>()),
    );
    expect(await _rows(s), hasLength(1));
  });

  test('TC-012-43 deleting a days covers is atomic', () async {
    final repos = openMemoryRepos();
    final month = await _seedA13(repos);
    Future<int> cover(CalendarDate day, int paise, int hour) async =>
        (await repos.savings.cover(
          month,
          day,
          Paise(paise),
          today: nov13,
          now: at(nov13, hour),
        )).coverId!;
    final a = await cover(nov11, 10000, 9);
    final b = await cover(nov11, 20000, 10);
    final c = await cover(nov6, 17000, 11);
    Future<MonthResult> recompute() async {
      final stored = (await repos.months.watchMonth(month).first)!;
      return computeMonth(
        MonthInput(
          month: stored.month,
          firstBudgetedDay: stored.firstBudgetedDay,
          periods: stored.periods,
          today: nov13,
          spends: [
            for (final s in await repos.spends.watchMonthSpends(month).first)
              s.spend,
          ],
          covers: await repos.savings.watchCovers(month).first,
        ),
      );
    }

    expect((await recompute()).totals.pot, p(200000 - 30000 - 17000));

    // A failure on the second row: both stay.
    await repos.db.customStatement(
      'CREATE TRIGGER fail_second_delete BEFORE DELETE ON savings_moves '
      "WHEN old.id = $b BEGIN SELECT RAISE(ABORT, 'forced failure'); END",
    );
    await expectLater(
      repos.savings.removeCovers(month, {a, b}),
      throwsA(isA<StorageException>()),
    );
    expect(await _amounts(repos), [10000, 20000, 17000]);
    await repos.db.customStatement('DROP TRIGGER fail_second_delete');

    // Another month's id deletes nothing.
    await repos.savings.removeCovers(month + 1, {a, b, c});
    expect(await _amounts(repos), [10000, 20000, 17000]);

    // Only the two 11 Nov moves go.
    await repos.savings.removeCovers(month, {a, b});
    expect(await _amounts(repos), [17000]);
    final after = await recompute();
    expect(after.dayOn(nov11).result, p(-30000));
    expect(after.dayOn(nov6).result, Paise.zero);
    expect(after.totals.pot, p(200000 - 17000));
  });

  test('TC-012-09 one cover row is stored with the exact paise', () async {
    final path = '${tempFolder('tc012_09').path}/budget.sqlite';
    var repos = openFileRepos(File(path));
    final month = await _seedA13(repos);
    final result = await repos.savings.cover(
      month,
      nov11,
      const Paise(30000),
      today: nov13,
      now: at(nov13, 9),
    );
    expect(result.decision, isA<CoverAllowed>());
    final rows = await repos.db
        .customSelect(
          'SELECT id, month_id, covered_day, amount_paise FROM savings_moves',
        )
        .get();
    expect(rows, hasLength(1));
    expect(rows.single.read<int>('id'), result.coverId);
    expect(rows.single.read<int>('month_id'), month);
    expect(rows.single.read<int>('covered_day'), nov11.dayNumber);
    expect(rows.single.read<int>('amount_paise'), 30000);

    await repos.db.close();
    repos = openFileRepos(File(path));
    final stored = (await repos.months.watchMonth(month).first)!;
    final again = computeMonth(
      MonthInput(
        month: stored.month,
        firstBudgetedDay: stored.firstBudgetedDay,
        periods: stored.periods,
        today: nov13,
        spends: [
          for (final s in await repos.spends.watchMonthSpends(month).first)
            s.spend,
        ],
        covers: await repos.savings.watchCovers(month).first,
      ),
    );
    expect(again.dayOn(nov11).result, Paise.zero);
    expect(again.totals.pot, p(170000));
    expect(await _amounts(repos), [30000]);
  });
}
