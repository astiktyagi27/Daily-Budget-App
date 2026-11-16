import 'package:daily_budget/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test(
    'TC-007-26 raw update or delete of a period or item is refused',
    () async {
      final month = await db.customInsert(
        'INSERT INTO budget_months (start_day, end_day, salary_day, '
        'first_budgeted_day, confirmed_at) VALUES (20766, 20795, 5, 20766, 0)',
      );
      final period = await db.customInsert(
        'INSERT INTO budget_periods (month_id, start_day, changed_at, kind, '
        "salary_paise) VALUES ($month, 20766, 0, 'full', 4000000)",
      );
      await db.customInsert(
        'INSERT INTO period_fixed_costs (period_id, position, name, '
        "amount_paise) VALUES ($period, 0, 'Rent', 1000000)",
      );
      Future<List<Map<String, Object?>>> snapshot(String table) async {
        final rows = await db
            .customSelect('SELECT * FROM $table ORDER BY id')
            .get();
        return [for (final row in rows) row.data];
      }

      final periodsBefore = await snapshot('budget_periods');
      final itemsBefore = await snapshot('period_fixed_costs');

      final attempts = <String>[
        'UPDATE budget_periods SET salary_paise = 1',
        'UPDATE budget_periods SET changed_at = 5 WHERE id = $period',
        'DELETE FROM budget_periods',
        'UPDATE period_fixed_costs SET amount_paise = 1',
        "UPDATE period_fixed_costs SET name = 'x'",
        'DELETE FROM period_fixed_costs',
      ];
      for (final sql in attempts) {
        await expectLater(
          db.customStatement(sql),
          throwsA(predicate((e) => e.toString().contains('append-only'))),
          reason: sql,
        );
      }
      expect(await snapshot('budget_periods'), periodsBefore);
      expect(await snapshot('period_fixed_costs'), itemsBefore);

      // Adding is still allowed: history only grows.
      final second = await db.customInsert(
        'INSERT INTO budget_periods (month_id, start_day, changed_at, kind, '
        "salary_paise) VALUES ($month, 20781, 1, 'full', 4000000)",
      );
      await db.customInsert(
        'INSERT INTO period_fixed_costs (period_id, position, name, '
        "amount_paise) VALUES ($second, 0, 'Rent', 1300000)",
      );
      expect((await snapshot('budget_periods')).length, 2);
      expect((await snapshot('period_fixed_costs')).length, 2);
      // The triggers are part of the schema, so a reopened file keeps them.
      final triggers = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'trigger'")
          .get();
      expect(triggers.map((r) => r.read<String>('name')).toSet(), {
        'budget_periods_no_update',
        'budget_periods_no_delete',
        'period_fixed_costs_no_update',
        'period_fixed_costs_no_delete',
      });
      // Transactions and savings moves stay editable (D-048, real delete).
      final spend = await db.customInsert(
        'INSERT INTO transactions (month_id, day, amount_paise, created_at, '
        'edited_at) VALUES ($month, 20766, 100, 0, 0)',
      );
      await db.customStatement('UPDATE transactions SET amount_paise = 200');
      await db.customStatement('DELETE FROM transactions WHERE id = $spend');
    },
  );
}
