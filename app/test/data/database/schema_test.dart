import 'dart:io';

import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

/// Every money column of schema v1, as `table.column` (F-007 plan section 3).
const _moneyColumns = <String>{
  'budget_periods.salary_paise',
  'budget_periods.target_paise',
  'budget_periods.money_left_paise',
  'budget_periods.shortfall_paise',
  'period_fixed_costs.amount_paise',
  'transactions.amount_paise',
  'savings_moves.amount_paise',
};

/// Every calendar-date column of schema v1.
const _dateColumns = <String>{
  'budget_months.start_day',
  'budget_months.end_day',
  'budget_months.first_budgeted_day',
  'budget_periods.start_day',
  'transactions.day',
  'savings_moves.covered_day',
};

Future<Map<String, String>> _declaredTypes(AppDatabase db) async {
  final tables = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%'",
      )
      .get();
  final types = <String, String>{};
  for (final table in tables) {
    final name = table.read<String>('name');
    final columns = await db.customSelect('PRAGMA table_info($name)').get();
    for (final column in columns) {
      types['$name.${column.read<String>('name')}'] = column
          .read<String>('type')
          .toUpperCase();
    }
  }
  return types;
}

Future<int> _addMonth(AppDatabase db, {int startDay = 20766}) =>
    db.customInsert(
      'INSERT INTO budget_months (start_day, end_day, salary_day, '
      'first_budgeted_day, confirmed_at) VALUES (?, ?, 5, ?, 0)',
      variables: [
        Variable<int>(startDay),
        Variable<int>(startDay + 29),
        Variable<int>(startDay),
      ],
    );

Future<int> _addFullPeriod(
  AppDatabase db,
  int monthId, {
  int salary = 4000000,
  int? target,
  int shortfall = 0,
}) => db.customInsert(
  'INSERT INTO budget_periods (month_id, start_day, changed_at, kind, '
  'salary_paise, target_paise, shortfall_paise) '
  "VALUES (?, 20766, 0, 'full', ?, ?, ?)",
  variables: [
    Variable<int>(monthId),
    Variable<int>(salary),
    Variable<int>(target),
    Variable<int>(shortfall),
  ],
);

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('TC-007-04 every money column is an integer column', () async {
    final types = await _declaredTypes(db);
    for (final column in _moneyColumns) {
      expect(types[column], 'INTEGER', reason: column);
    }
    // No money column was forgotten in the literal list above.
    final paiseColumns = types.keys.where((c) => c.endsWith('_paise')).toSet();
    expect(paiseColumns, _moneyColumns);
    // No column of any table is floating point.
    const floating = ['REAL', 'DOUBLE', 'FLOAT', 'NUMERIC', 'DECIMAL'];
    for (final MapEntry(:key, :value) in types.entries) {
      expect(floating.any(value.contains), isFalse, reason: '$key is $value');
    }
  });

  test('TC-007-05 money values round trip exactly in every column', () async {
    const amounts = [1, 133333, 2490000, 100000000000];
    final month = await _addMonth(db);
    for (final amount in amounts) {
      final period = await db.customInsert(
        'INSERT INTO budget_periods (month_id, start_day, changed_at, kind, '
        'salary_paise, target_paise, money_left_paise, shortfall_paise) '
        "VALUES (?, 20766, 0, 'full', ?, ?, ?, ?)",
        variables: [
          Variable<int>(month),
          Variable<int>(amount),
          Variable<int>(amount),
          Variable<int>(amount),
          Variable<int>(amount),
        ],
      );
      await db.customInsert(
        'INSERT INTO period_fixed_costs (period_id, position, name, '
        'amount_paise) VALUES (?, 0, ?, ?)',
        variables: [
          Variable<int>(period),
          const Variable<String>('Rent'),
          Variable<int>(amount),
        ],
      );
      await db.customInsert(
        'INSERT INTO transactions (month_id, day, amount_paise, created_at, '
        'edited_at) VALUES (?, 20766, ?, 0, 0)',
        variables: [Variable<int>(month), Variable<int>(amount)],
      );
      await db.customInsert(
        'INSERT INTO savings_moves (month_id, covered_day, amount_paise, '
        'made_at) VALUES (?, 20766, ?, 0)',
        variables: [Variable<int>(month), Variable<int>(amount)],
      );
    }
    // Read through the typed API: the converter hands back the same Paise.
    final periods = await db.select(db.budgetPeriods).get();
    expect(periods.map((r) => r.salaryPaise).toList(), [
      for (final a in amounts) Paise(a),
    ]);
    expect(periods.map((r) => r.targetPaise!.value), amounts);
    expect(periods.map((r) => r.moneyLeftPaise!.value), amounts);
    expect(periods.map((r) => r.shortfallPaise.value), amounts);
    final costs = await db.select(db.periodFixedCosts).get();
    expect(costs.map((r) => r.amountPaise.value), amounts);
    final spends = await db.select(db.transactions).get();
    expect(spends.map((r) => r.amountPaise.value), amounts);
    final moves = await db.select(db.savingsMoves).get();
    expect(moves.map((r) => r.amountPaise.value), amounts);
    // And SQLite itself stores an integer, never a real.
    for (final column in _moneyColumns) {
      final (table, name) = (column.split('.')[0], column.split('.')[1]);
      final rows = await db
          .customSelect(
            'SELECT DISTINCT typeof($name) AS t FROM $table '
            'WHERE $name IS NOT NULL',
          )
          .get();
      expect(rows.map((r) => r.read<String>('t')), ['integer'], reason: column);
    }
  });

  test('TC-007-07 calendar date columns store integer day numbers', () async {
    final types = await _declaredTypes(db);
    for (final column in _dateColumns) {
      expect(types[column], 'INTEGER', reason: column);
    }
    final nov9 = CalendarDate(2026, 11, 9).dayNumber;
    expect(nov9, 20766);
    final month = await _addMonth(db, startDay: nov9);
    final row = await db
        .customSelect(
          'SELECT start_day, typeof(start_day) AS t FROM budget_months '
          'WHERE id = ?',
          variables: [Variable<int>(month)],
        )
        .getSingle();
    expect(row.read<int>('start_day'), nov9);
    expect(row.read<String>('t'), 'integer');
    // No DateTime column: the schema source has no `dateTime()`.
    final tables = File('lib/data/database/tables.dart')
        .readAsLinesSync()
        .where((line) => !line.trimLeft().startsWith('//'))
        .join(' ');
    expect(tables.contains('dateTime()'), isFalse);
  });

  test('TC-007-35 foreign keys are on and enforced', () async {
    final pragma = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(pragma.read<int>('foreign_keys'), 1);
    await expectLater(
      db.customInsert(
        'INSERT INTO period_fixed_costs (period_id, position, name, '
        "amount_paise) VALUES (9999, 0, 'Rent', 100)",
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      db.customInsert(
        'INSERT INTO savings_moves (month_id, covered_day, amount_paise, '
        'made_at) VALUES (9999, 20766, 100, 0)',
      ),
      throwsA(isA<Exception>()),
    );
    // A month with rows cannot be removed (ON DELETE RESTRICT).
    final month = await _addMonth(db);
    await _addFullPeriod(db, month);
    await expectLater(
      db.customStatement('DELETE FROM budget_months WHERE id = $month'),
      throwsA(isA<Exception>()),
    );
  });

  test('TC-007-47 direction column only allows spend or money in', () async {
    final month = await _addMonth(db);
    Future<int> insert(String direction) => db.customInsert(
      'INSERT INTO transactions (month_id, day, amount_paise, direction, '
      'created_at, edited_at) VALUES (?, 20766, 100, ?, 0, 0)',
      variables: [Variable<int>(month), Variable<String>(direction)],
    );
    await insert('spend');
    await insert('money_in');
    await expectLater(insert('refund'), throwsA(isA<Exception>()));
    final rows = await db.select(db.transactions).get();
    expect(rows.map((r) => r.direction), ['spend', 'money_in']);
    // The default is spend.
    await db.customInsert(
      'INSERT INTO transactions (month_id, day, amount_paise, created_at, '
      'edited_at) VALUES (?, 20766, 100, 0, 0)',
      variables: [Variable<int>(month)],
    );
    expect((await db.select(db.transactions).get()).last.direction, 'spend');
  });

  test('TC-007-42 the schema refuses amounts the app never stores', () async {
    final month = await _addMonth(db);
    final period = await _addFullPeriod(db, month);
    Future<void> spend(int amount) => db.customStatement(
      'INSERT INTO transactions (month_id, day, amount_paise, created_at, '
      'edited_at) VALUES ($month, 20766, $amount, 0, 0)',
    );
    await expectLater(spend(0), throwsA(isA<Exception>()));
    await expectLater(spend(-1), throwsA(isA<Exception>()));
    await spend(1);
    // A fixed cost of 0 is allowed, -1 is not.
    Future<void> cost(int amount) => db.customStatement(
      'INSERT INTO period_fixed_costs (period_id, position, name, '
      "amount_paise) VALUES ($period, 0, 'Gift', $amount)",
    );
    await cost(0);
    await expectLater(cost(-1), throwsA(isA<Exception>()));
    // Names of 1 to 160 code points only (the screen allows 40).
    await expectLater(
      db.customStatement(
        'INSERT INTO period_fixed_costs (period_id, position, name, '
        "amount_paise) VALUES ($period, 1, '', 5)",
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      db.customStatement(
        'INSERT INTO period_fixed_costs (period_id, position, name, '
        "amount_paise) VALUES ($period, 1, '${'a' * 161}', 5)",
      ),
      throwsA(isA<Exception>()),
    );
    // Salary day 1 to 31, kind and the kind's required value.
    await expectLater(
      db.customStatement(
        'INSERT INTO budget_months (start_day, end_day, salary_day, '
        'first_budgeted_day, confirmed_at) VALUES (1, 30, 32, 1, 0)',
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      db.customStatement(
        'INSERT INTO budget_periods (month_id, start_day, changed_at, kind, '
        "salary_paise) VALUES ($month, 20766, 0, 'weekly', 5)",
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      db.customStatement(
        'INSERT INTO budget_periods (month_id, start_day, changed_at, kind) '
        "VALUES ($month, 20766, 0, 'full')",
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      db.customStatement(
        'INSERT INTO budget_periods (month_id, start_day, changed_at, kind) '
        "VALUES ($month, 20766, 0, 'midMonthStart')",
      ),
      throwsA(isA<Exception>()),
    );
    // A negative shortfall and a second month with the same start day.
    await expectLater(
      _addFullPeriod(db, month, shortfall: -1),
      throwsA(isA<Exception>()),
    );
    await expectLater(_addMonth(db), throwsA(isA<Exception>()));
  });
}
