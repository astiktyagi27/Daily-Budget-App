import 'dart:io';

import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/data/database/converters.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

// Set by tool/tz_matrix.ps1 (and the TC-007-08 command): the offset the
// process must really have, and the name of the zone.
const _hasExpectedOffset = bool.hasEnvironment('EXPECT_TZ_OFFSET_MIN');
const _expectedOffset = int.fromEnvironment('EXPECT_TZ_OFFSET_MIN');
const _zoneName = String.fromEnvironment('TZ_NAME');

void main() {
  test(
    'TC-007-08 transaction date reads back the same day in every time zone',
    () async {
      if (_hasExpectedOffset) {
        // The sentinel: the zone change was real, not silently ignored.
        expect(
          DateTime(2026, 11, 9).timeZoneOffset.inMinutes,
          _expectedOffset,
          reason: 'TZ=$_zoneName',
        );
      }
      final nov9 = CalendarDate(2026, 11, 9);
      // Written under the zone of this process and read back in it.
      final db = openTestDatabase();
      addTearDown(db.close);
      final month = await db.customInsert(
        'INSERT INTO budget_months (start_day, end_day, salary_day, '
        'first_budgeted_day, confirmed_at) VALUES (?, ?, 5, ?, 0)',
        variables: [
          Variable<int>(nov9.dayNumber - 4),
          Variable<int>(nov9.dayNumber + 25),
          Variable<int>(nov9.dayNumber - 4),
        ],
      );
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              monthId: month,
              day: nov9,
              amountPaise: const Paise(25000),
              createdAt: 0,
              editedAt: 0,
            ),
          );
      final read = (await db.select(db.transactions).getSingle()).day;
      expect(read, nov9);
      expect(read.iso, '2026-11-09');
      await db.close();

      // A file written by the first zone of the matrix run and read by the
      // next ones (tool/tz_matrix.ps1 empties build/tz first): the same stored
      // number reads as 9 Nov in every zone.
      if (_zoneName.isNotEmpty) {
        await _writeThenReadFile(nov9);
      }

      // Negative control, proving the test can fail: a local-midnight
      // timestamp read as UTC lands on 8 Nov in a zone ahead of UTC.
      final localMidnightMs = DateTime(2026, 11, 9).millisecondsSinceEpoch;
      final asUtc = DateTime.fromMillisecondsSinceEpoch(
        localMidnightMs,
        isUtc: true,
      );
      final offset = DateTime(2026, 11, 9).timeZoneOffset.inMinutes;
      expect(asUtc.day, offset > 0 ? 8 : 9);
    },
  );
}

Future<void> _writeThenReadFile(CalendarDate nov9) async {
  final file = File('build/tz/f007.sqlite');
  if (!file.existsSync()) {
    file.createSync(recursive: true);
    final writer = AppDatabase(NativeDatabase(file));
    final writerMonth = await writer.customInsert(
      'INSERT INTO budget_months (start_day, end_day, salary_day, '
      'first_budgeted_day, confirmed_at) VALUES (?, ?, 5, ?, 0)',
      variables: [
        Variable<int>(nov9.dayNumber - 4),
        Variable<int>(nov9.dayNumber + 25),
        Variable<int>(nov9.dayNumber - 4),
      ],
    );
    await writer
        .into(writer.transactions)
        .insert(
          TransactionsCompanion.insert(
            monthId: writerMonth,
            day: nov9,
            amountPaise: const Paise(25000),
            createdAt: 0,
            editedAt: 0,
          ),
        );
    await writer.close();
  }
  final reader = AppDatabase(NativeDatabase(file));
  addTearDown(reader.close);
  final stored = await reader.select(reader.transactions).getSingle();
  expect(stored.day, nov9);
  expect(const CalendarDateConverter().toSql(stored.day), 20766);
}
