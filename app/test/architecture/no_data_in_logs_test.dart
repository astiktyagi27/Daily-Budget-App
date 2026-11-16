import 'dart:io';

import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/data/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import '../data/repositories/repository_setup.dart';
import '../domain/budget/fixtures.dart';

// F-007 AC-11 (T-210): no log record holds an amount, a note or a date.

final _logCall = RegExp(r'\b(_?log|_?logger|Logger\([^)]*\))\.\w+\(');

/// Every `file:line: text` of a logging call in [source] that interpolates a
/// value (a dollar sign in the line).
List<String> _interpolatingLogCalls(String name, String source) {
  final lines = source.split('\n');
  return [
    for (var i = 0; i < lines.length; i++)
      if (_logCall.hasMatch(lines[i]) && lines[i].contains(r'$'))
        '$name:${i + 1}: ${lines[i].trim()}',
  ];
}

void main() {
  test('TC-007-21 no log record contains an amount note or date', () async {
    final records = <LogRecord>[];
    Logger.root.level = Level.ALL;
    final subscription = Logger.root.onRecord.listen(records.add);
    addTearDown(subscription.cancel);

    // The real open path through the provider, then a repository run with
    // distinctive values.
    final file = File('${tempFolder('tc007_21').path}/budget.sqlite');
    final container = ProviderContainer(
      overrides: [
        databaseOpenerProvider.overrideWithValue(
          () => AppDatabase(NativeDatabase(file)),
        ),
      ],
    );
    addTearDown(container.dispose);
    final db = await container.read(appDatabaseProvider.future);
    final repos = Repos(db);
    final month = await repos.months.confirmMonth(e2NewMonth());
    await repos.spends.add(
      month.id,
      fields(d(2026, 11, 9), 25000, 'Lunch रिक्शा'),
      today: d(2026, 11, 10),
      now: at(d(2026, 11, 10), 8),
    );
    await repos.months.addPeriod(
      month.id,
      period(d(2026, 11, 20), e2Values(rent: 1300000)),
    );

    expect(records, isNotEmpty, reason: 'the open is logged');
    final text = records.map((r) => '${r.message} ${r.error}').join('\n');
    for (final value in [
      '25000',
      '250',
      '₹',
      'Lunch',
      'रिक्शा',
      '2026-11-09',
      '9 Nov',
      '20766',
      '1300000',
      '4000000',
      'Rent',
    ]) {
      expect(text.contains(value), isFalse, reason: value);
    }
  });

  test('TC-007-21 no logging call interpolates a value', () {
    final offenders = <String>[
      for (final folder in ['lib/data', 'lib/core', 'lib/features'])
        for (final entity in Directory(folder).listSync(recursive: true))
          if (entity is File && entity.path.endsWith('.dart'))
            ..._interpolatingLogCalls(entity.path, entity.readAsStringSync()),
    ];
    // The one allowed interpolation is the failure kind (an enum name).
    expect(offenders.where((o) => !o.contains('failure.kind.name')), isEmpty);
    // The guard itself can fail.
    expect(
      _interpolatingLogCalls('bad.dart', r"_log.info('saved $amount');"),
      hasLength(1),
    );
  });
}
