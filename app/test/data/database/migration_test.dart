import 'dart:convert';
import 'dart:io';

import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

const _fixture = 'test/fixtures/db/v1_sample.db.fixture';
const _snapshot = 'drift_schemas/app_database/drift_schema_v1.json';

void main() {
  test('TC-007-14 schema is version 1 and its snapshot is committed', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    expect(db.schemaVersion, 1);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 1);

    // The committed snapshot lists exactly the entities a new database has.
    // (tool/check.ps1 also compares it with a fresh `drift_dev schema dump`.)
    final json =
        jsonDecode(File(_snapshot).readAsStringSync()) as Map<String, Object?>;
    final entities = (json['entities']! as List).cast<Map<String, Object?>>();
    final inSnapshot = <String>{
      for (final entity in entities)
        if (entity['type'] case 'table' || 'index' || 'trigger')
          (entity['data']! as Map<String, Object?>)['name']! as String,
    };
    final inDatabase =
        (await db
                .customSelect(
                  'SELECT name FROM sqlite_master WHERE type IN '
                  "('table', 'index', 'trigger') AND name NOT LIKE 'sqlite_%'",
                )
                .get())
            .map((row) => row.read<String>('name'))
            .toSet();
    expect(inSnapshot, inDatabase);
    expect(inSnapshot, containsAll(['budget_months', 'transactions']));
  });

  test('TC-007-14 v1 sample database opens intact with current code', () async {
    final folder = Directory.systemTemp.createTempSync('tc007_14');
    addTearDown(() => folder.deleteSync(recursive: true));
    final copy = File('${folder.path}/budget.sqlite');
    File(_fixture).copySync(copy.path);

    final db = AppDatabase(NativeDatabase(copy));
    addTearDown(db.close);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 1);

    final months = await db.select(db.budgetMonths).get();
    expect(months, hasLength(1));
    expect(months.single.startDay, CalendarDate(2026, 11, 5));
    expect(months.single.endDay, CalendarDate(2026, 12, 4));
    expect(months.single.salaryDay, 5);
    expect(months.single.firstBudgetedDay, CalendarDate(2026, 11, 5));

    final periods = await (db.select(
      db.budgetPeriods,
    )..orderBy([(p) => OrderingTerm.asc(p.id)])).get();
    expect(periods.map((p) => p.startDay.iso), [
      '2026-11-05',
      '2026-11-20',
      '2026-11-28',
    ]);
    expect(periods.every((p) => p.kind == 'full'), isTrue);
    expect(periods.every((p) => p.salaryPaise == const Paise(4000000)), isTrue);
    final costs =
        await (db.select(db.periodFixedCosts)..orderBy([
              (c) => OrderingTerm.asc(c.periodId),
              (c) => OrderingTerm.asc(c.position),
            ]))
            .get();
    expect(
      [for (final c in costs) '${c.periodId}:${c.name}:${c.amountPaise.value}'],
      [
        '1:Rent:1000000',
        '1:EMI:500000',
        '1:Subscriptions:10000',
        '2:Rent:1300000',
        '2:EMI:500000',
        '2:Subscriptions:10000',
        '3:Rent:1300000',
        '3:EMI:400000',
        '3:Subscriptions:10000',
      ],
    );

    final spends = await (db.select(
      db.transactions,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    expect(
      [for (final t in spends) (t.day.iso, t.amountPaise.value, t.note)],
      [
        ('2026-11-09', 25000, 'Lunch'),
        ('2026-11-09', 40000, 'Groceries'),
        ('2026-11-08', 31000, ''),
        ('2026-11-06', 100000, 'रिक्शा 🛺'),
        ('2026-11-05', 1, 'Tea'),
      ],
    );
    final moves = await db.select(db.savingsMoves).get();
    expect(moves.single.coveredDay, CalendarDate(2026, 11, 6));
    expect(moves.single.amountPaise, const Paise(17000));
    // Opening did not run a migration and the triggers are still there.
    final triggers = await db
        .customSelect(
          "SELECT count(*) AS n FROM sqlite_master WHERE type = 'trigger'",
        )
        .getSingle();
    expect(triggers.read<int>('n'), 4);
  });
}
