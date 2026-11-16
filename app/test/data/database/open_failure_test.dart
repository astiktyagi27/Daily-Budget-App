import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/data/database/database_connection.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

const _fixtures = 'test/fixtures/db';

String _sha256(File file) => sha256.convert(file.readAsBytesSync()).toString();

/// A database that records every migration Drift starts.
class _SpyDatabase extends AppDatabase {
  new(super.e, this.upgrades);

  final List<(int, int)> upgrades;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async => upgrades.add((from, to)),
  );
}

void main() {
  late Directory folder;

  setUp(() => folder = Directory.systemTemp.createTempSync('tc007_open'));
  tearDown(() => folder.deleteSync(recursive: true));

  File copyOf(String fixture) =>
      File('$_fixtures/$fixture').copySync('${folder.path}/budget.sqlite');

  // The same opener the app uses (a background isolate), pointed at a file.
  AppDatabase Function() openerFor(File file) =>
      () => openAppDatabase(
        executor: openDatabaseConnection(
          databasePath: () async => file.path,
          tempDirectoryPath: () async => folder.path,
        ),
      );

  ProviderContainer containerFor(File file) {
    final container = ProviderContainer(
      overrides: [databaseOpenerProvider.overrideWithValue(openerFor(file))],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('TC-007-14 the known schema version matches the database', () {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, knownSchemaVersion);
  });

  test(
    'TC-007-15 newer database version shows the error and is left untouched',
    () async {
      final file = copyOf('v99_newer.db.fixture');
      final before = _sha256(file);

      // Straight on the file: the guard throws before Drift migrates.
      final upgrades = <(int, int)>[];
      final spy = _SpyDatabase(
        NativeDatabase(file, setup: guardAgainstNewerDatabase),
        upgrades,
      );
      addTearDown(spy.close);
      await expectLater(
        spy.customSelect('SELECT count(*) FROM budget_months').get(),
        throwsA(isA<DatabaseTooNewException>()),
      );
      expect(upgrades, isEmpty, reason: 'no migration step may run');
      await spy.close();
      expect(_sha256(file), before);

      // Through the app's real opener (background isolate) and provider.
      final container = containerFor(file);
      await expectLater(
        container.read(appDatabaseProvider.future),
        throwsA(
          isA<StorageException>().having(
            (e) => e.kind,
            'kind',
            StorageFailureKind.tooNew,
          ),
        ),
      );
      expect(_sha256(file), before);
      expect(
        folder.listSync().map((e) => e.path.split(Platform.pathSeparator).last),
        ['budget.sqlite'],
        reason: 'no journal or backup file was left behind',
      );
    },
  );

  test('TC-007-16 corrupt database is reported and never replaced', () async {
    final file = copyOf('corrupt.db.fixture');
    final before = _sha256(file);
    final size = file.lengthSync();
    final container = containerFor(file);

    await expectLater(
      container.read(appDatabaseProvider.future),
      throwsA(
        isA<StorageException>().having(
          (e) => e.kind,
          'kind',
          StorageFailureKind.corrupt,
        ),
      ),
    );
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), size);
    expect(_sha256(file), before);

    // Remove the failure and tap Try again: the provider opens normally.
    File('$_fixtures/v1_sample.db.fixture').copySync(file.path);
    container.invalidate(appDatabaseProvider);
    final database = await container.read(appDatabaseProvider.future);
    final months = await database.select(database.budgetMonths).get();
    expect(months, hasLength(1));
    await database.close();
  });

  test(
    'TC-007-45 storage errors do not show file paths or sqlite messages',
    () async {
      final file = copyOf('corrupt.db.fixture');
      final records = <LogRecord>[];
      Logger.root.level = Level.ALL;
      final subscription = Logger.root.onRecord.listen(records.add);
      addTearDown(subscription.cancel);

      final container = containerFor(file);
      Object? failure;
      try {
        await container.read(appDatabaseProvider.future);
      } on Object catch (error) {
        failure = error;
      }
      expect(failure, isA<StorageException>());
      // The error and the log carry only the kind.
      expect(failure.toString(), 'StorageException(corrupt)');
      final logged = records.map((r) => '${r.message} ${r.error}').join('\n');
      expect(logged, contains('database open failed: corrupt'));
      for (final leaked in [folder.path, 'budget.sqlite', 'malformed', 'SQL']) {
        expect(logged.contains(leaked), isFalse, reason: leaked);
        expect(failure.toString().contains(leaked), isFalse, reason: leaked);
      }
    },
  );

  test('TC-007-16 open errors are classified by cause', () {
    StorageFailureKind kindOf(Object error) =>
        StorageException.from(error, kind: StorageFailureKind.open).kind;
    expect(
      kindOf(const DatabaseTooNewException(found: 9, known: 1)),
      StorageFailureKind.tooNew,
    );
    expect(kindOf(StateError('anything')), StorageFailureKind.open);
    const existing = StorageException(StorageFailureKind.write);
    expect(
      StorageException.from(existing, kind: StorageFailureKind.read),
      existing,
    );
  });
}
