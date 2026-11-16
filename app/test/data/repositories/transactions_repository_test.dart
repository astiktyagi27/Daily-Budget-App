import 'dart:io';

import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import 'repository_setup.dart';

void main() {
  final today = d(2026, 11, 10);
  final nov9 = d(2026, 11, 9);

  Future<(Repos, int)> seeded() async {
    final repos = openMemoryRepos();
    final month = await repos.months.confirmMonth(e2NewMonth());
    return (repos, month.id);
  }

  Matcher storageFailure(StorageFailureKind kind) =>
      throwsA(isA<StorageException>().having((e) => e.kind, 'kind', kind));

  test(
    'TC-007-11 transaction listeners update on add edit and delete',
    () async {
      final (repos, month) = await seeded();
      final list = Collected(repos.spends.watchMonthSpends(month));
      await pumpEventQueue();

      final added = await repos.spends.add(
        month,
        fields(nov9, 25000, 'Lunch'),
        today: today,
        now: at(today, 8),
      );
      await pumpEventQueue();
      await repos.spends.update(
        added.id,
        fields(nov9, 27000, 'Lunch'),
        today: today,
        now: at(today, 9),
      );
      await pumpEventQueue();
      await repos.spends.delete(added.id, today: today);
      await pumpEventQueue();

      expect(
        [for (final l in list.values) l.map((s) => s.spend.amount.value)],
        [
          <int>[],
          [25000],
          [27000],
          <int>[],
        ],
      );
    },
  );

  test('TC-007-29 long hindi and emoji notes round trip exactly', () async {
    final (repos, month) = await seeded();
    final notes = <String?>[
      'a' * 100,
      ('चाय ☕ ' * 20).substring(0, 100),
      '👨‍👩‍👧',
      'रिक्शा 🛺 से घर',
    ];
    for (final (i, note) in notes.indexed) {
      await repos.spends.add(
        month,
        fields(nov9, 100 + i, note),
        today: today,
        now: at(today, 8, i),
      );
    }
    // An empty note reads back as "no note".
    await repos.spends.add(
      month,
      fields(nov9, 999, ''),
      today: today,
      now: at(today, 9),
    );
    final stored = await repos.spends.watchMonthSpends(month).first;
    // Newest created first within the day: the empty-note spend, then the rest
    // in reverse.
    expect(stored.first.note, isNull);
    expect(stored.skip(1).map((s) => s.note), notes.reversed);
    expect(stored.skip(1).last.note!.length, 100);
    // 401 code points breaks the CHECK backstop: a storage failure, nothing
    // stored.
    await expectLater(
      repos.spends.add(
        month,
        fields(nov9, 5, 'x' * 401),
        today: today,
        now: at(today, 10),
      ),
      storageFailure(StorageFailureKind.write),
    );
    expect(await countRows(repos.db, 'transactions'), 5);
  });

  test('TC-007-30 identical manual spends are both kept', () async {
    final (repos, month) = await seeded();
    for (var i = 0; i < 2; i++) {
      await repos.spends.add(
        month,
        fields(nov9, 25000, 'Tea'),
        today: today,
        now: at(today, 8, i),
      );
    }
    final stored = await repos.spends.watchMonthSpends(month).first;
    expect(stored, hasLength(2));
    expect({for (final s in stored) s.spend.id}, hasLength(2));
  });

  test('TC-007-31 deleting a spend removes it from every read', () async {
    final (repos, month) = await seeded();
    final ids = <int>[];
    for (final (i, date) in [
      d(2026, 11, 9),
      d(2026, 11, 9),
      d(2026, 11, 8),
      d(2026, 11, 6),
      d(2026, 11, 5),
    ].indexed) {
      final outcome = await repos.spends.add(
        month,
        fields(date, 1000 + i),
        today: today,
        now: at(today, 8, i),
      );
      ids.add(outcome.id);
    }
    await repos.spends.delete(ids[2], today: today);
    expect(await countRows(repos.db, 'transactions'), 4);
    final stored = await repos.spends.watchMonthSpends(month).first;
    expect(stored.map((s) => s.spend.id), isNot(contains(ids[2])));
    // Deleting an id that is not stored is a caller error.
    expect(
      () => repos.spends.delete(ids[2], today: today),
      throwsArgumentError,
    );
  });

  test('TC-007-32 failed write leaves stored data intact', () async {
    final (repos, month) = await seeded();
    for (final (i, date) in [nov9, d(2026, 11, 8)].indexed) {
      await repos.spends.add(
        month,
        fields(date, 1000 + i, 'n$i'),
        today: today,
        now: at(today, 8, i),
      );
    }
    final before = await rowSnapshot(repos.db, 'transactions');
    final listBefore = await repos.spends.watchMonthSpends(month).first;
    // A forced "disk full": SQLite aborts the next insert.
    await repos.db.customStatement(
      'CREATE TRIGGER disk_full BEFORE INSERT ON transactions '
      "BEGIN SELECT RAISE(FAIL, 'database or disk is full'); END",
    );
    await expectLater(
      repos.spends.add(
        month,
        fields(nov9, 5000, 'new'),
        today: today,
        now: at(today, 9),
      ),
      storageFailure(StorageFailureKind.write),
    );
    expect(await rowSnapshot(repos.db, 'transactions'), before);
    expect(await repos.spends.watchMonthSpends(month).first, hasLength(2));
    expect(
      (await repos.spends.watchMonthSpends(month).first).map(
        (s) => s.spend.amount,
      ),
      listBefore.map((s) => s.spend.amount),
    );
    expect(await countRows(repos.db, 'budget_months'), 1);
  });

  test(
    'TC-007-18 write failure surfaces as a storage exception only',
    () async {
      final (repos, month) = await seeded();
      await repos.db.customStatement(
        'CREATE TRIGGER no_edits BEFORE UPDATE ON transactions '
        "BEGIN SELECT RAISE(ABORT, 'forced'); END",
      );
      final added = await repos.spends.add(
        month,
        fields(nov9, 1000),
        today: today,
        now: at(today, 8),
      );
      Object? caught;
      try {
        await repos.spends.update(
          added.id,
          fields(nov9, 2000),
          today: today,
          now: at(today, 9),
        );
      } on Object catch (error) {
        caught = error;
      }
      expect(caught, isA<StorageException>());
      expect(caught.toString(), 'StorageException(write)');
      // The amount is still the old one: nothing was half saved.
      final stored = await repos.spends.watchMonthSpends(month).first;
      expect(stored.single.spend.amount, const Paise(1000));
    },
  );

  test('TC-007-39 spends within a day keep created time order', () async {
    final (repos, month) = await seeded();
    final first = await repos.spends.add(
      month,
      fields(nov9, 1000, 'ten'),
      today: today,
      now: at(nov9, 10),
    );
    await repos.spends.add(
      month,
      fields(nov9, 2000, 'twelve'),
      today: today,
      now: at(nov9, 12),
    );
    expect(
      (await repos.spends.watchMonthSpends(month).first).map((s) => s.note),
      ['twelve', 'ten'],
    );
    // Editing the 10:00 one at 13:00, even to another amount, does not move it.
    await repos.spends.update(
      first.id,
      fields(nov9, 1500, 'ten'),
      today: today,
      now: at(nov9, 13),
    );
    final stored = await repos.spends.watchMonthSpends(month).first;
    expect(stored.map((s) => s.note), ['twelve', 'ten']);
    final raw = await repos.db
        .customSelect(
          'SELECT created_at, edited_at FROM transactions WHERE id = ?',
          variables: [Variable<int>(first.id)],
        )
        .getSingle();
    expect(raw.read<int>('created_at'), at(nov9, 10));
    expect(raw.read<int>('edited_at'), at(nov9, 13));
    // Two spends created at the same instant order by id, highest first.
    final a = await repos.spends.add(
      month,
      fields(d(2026, 11, 8), 1, 'a'),
      today: today,
      now: at(nov9, 14),
    );
    final b = await repos.spends.add(
      month,
      fields(d(2026, 11, 8), 2, 'b'),
      today: today,
      now: at(nov9, 14),
    );
    final eighth = (await repos.spends.watchMonthSpends(month).first).where(
      (s) => s.spend.date == d(2026, 11, 8),
    );
    expect(eighth.map((s) => s.spend.id), [b.id, a.id]);
  });

  test('TC-007-42 repositories refuse non positive spend amounts', () async {
    final (repos, month) = await seeded();
    for (final amount in [0, -1]) {
      expect(
        () => repos.spends.add(
          month,
          fields(nov9, amount),
          today: today,
          now: at(today, 8),
        ),
        throwsArgumentError,
      );
    }
    final ok = await repos.spends.add(
      month,
      fields(nov9, 1),
      today: today,
      now: at(today, 8),
    );
    expect(
      () => repos.spends.update(
        ok.id,
        fields(nov9, 0),
        today: today,
        now: at(today, 9),
      ),
      throwsArgumentError,
    );
    expect(await countRows(repos.db, 'transactions'), 1);
  });

  test(
    'TC-007-44 five thousand spends insert and read back in order',
    () async {
      final path = '${tempFolder('tc007_44').path}/budget.sqlite';
      var repos = openFileRepos(File(path));
      final month = await repos.months.confirmMonth(e2NewMonth());
      await repos.db.batch((batch) {
        batch.insertAll(repos.db.transactions, [
          for (var i = 0; i < 5000; i++)
            TransactionsCompanion.insert(
              monthId: month.id,
              day: d(2026, 11, 5).addDays(i % 30),
              amountPaise: Paise(100 + i),
              createdAt: at(today, 8) + i,
              editedAt: at(today, 8) + i,
            ),
        ]);
      });
      await repos.db.close();
      repos = openFileRepos(File(path));
      final watch = Stopwatch()..start();
      final stored = await repos.spends.watchMonthSpends(month.id).first;
      watch.stop();
      debugPrint(
        'TC-007-44 read of 5000 rows took ${watch.elapsedMilliseconds} ms',
      );
      expect(stored, hasLength(5000));
      for (var i = 1; i < stored.length; i++) {
        final (a, b) = (stored[i - 1].spend, stored[i].spend);
        expect(
          a.date.dayNumber > b.date.dayNumber ||
              (a.date == b.date && a.createdAt >= b.createdAt),
          isTrue,
          reason: 'row $i out of order',
        );
      }
    },
  );

  test('TC-007-47 money in rows keep their direction', () async {
    final path = '${tempFolder('tc007_47').path}/budget.sqlite';
    var repos = openFileRepos(File(path));
    final month = await repos.months.confirmMonth(e2NewMonth());
    final nov12 = d(2026, 11, 12);
    await repos.spends.add(
      month.id,
      fields(nov12, 50000, 'Refund'),
      today: nov12,
      now: at(nov12, 8),
      direction: SpendDirection.moneyIn,
    );
    await repos.spends.add(
      month.id,
      fields(nov12, 30000, 'Lunch'),
      today: nov12,
      now: at(nov12, 9),
    );
    await repos.db.close();

    repos = openFileRepos(File(path));
    final stored = await repos.spends.watchMonthSpends(month.id).first;
    expect(
      [
        for (final s in stored)
          (s.spend.direction, s.spend.amount.value, s.spend.date.iso),
      ],
      [
        (SpendDirection.spend, 30000, '2026-11-12'),
        (SpendDirection.moneyIn, 50000, '2026-11-12'),
      ],
    );
    final stored2 = (await repos.months.watchMonth(month.id).first)!;
    final result = computeMonth(
      MonthInput(
        month: stored2.month,
        firstBudgetedDay: stored2.firstBudgetedDay,
        periods: stored2.periods,
        today: d(2026, 11, 13),
        spends: [for (final s in stored) s.spend],
      ),
    );
    final day = result.dayOn(nov12);
    expect(day.moneyIn, const Paise(50000));
    expect(day.netSpent, const Paise(-20000));
    // The column only allows the two directions.
    await expectLater(
      repos.db.customStatement(
        'INSERT INTO transactions (month_id, day, amount_paise, direction, '
        "created_at, edited_at) VALUES (${month.id}, 20766, 5, 'refund', 0, 0)",
      ),
      throwsA(isA<Exception>()),
    );
  });
}
