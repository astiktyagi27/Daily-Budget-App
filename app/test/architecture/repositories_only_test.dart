import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// F-007 AC-6 (plan section 2): screens and the domain reach the database only
// through repositories and providers. Imports of Drift, sqlite3 or anything
// under `data/database/` are allowed only in `lib/data/`, plus the provider
// file that opens the database.

final _importLine = RegExp(r'''^\s*(import|export|part)\s+['"]([^'"]+)['"]''');

const _forbidden = <String>[
  'package:drift/',
  'package:drift_flutter/',
  'package:sqlite3/',
  'package:daily_budget/data/database/',
  'data/database/',
];

/// Every directive line in [source] that imports a database package or file.
List<String> _databaseImports(String name, String source) => [
  for (final line in source.split('\n'))
    if (_importLine.firstMatch(line) case final match?)
      if (_forbidden.any(match.group(2)!.contains)) '$name: ${line.trim()}',
];

List<String> _offenders(String folder) => [
  for (final file in Directory(folder).listSync(recursive: true))
    if (file is File && file.path.endsWith('.dart'))
      ..._databaseImports(file.path, file.readAsStringSync()),
];

void main() {
  test('TC-007-13 features and domain never import the database', () {
    expect(Directory('lib/features').existsSync(), isTrue);
    expect(Directory('lib/domain').existsSync(), isTrue);
    expect(_offenders('lib/features'), isEmpty);
    expect(_offenders('lib/domain'), isEmpty);

    // The guard itself can fail.
    expect(
      _databaseImports('bad.dart', "import 'package:drift/drift.dart';"),
      hasLength(1),
    );
    expect(
      _databaseImports(
        'bad.dart',
        "import 'package:daily_budget/data/database/app_database.dart';",
      ),
      hasLength(1),
    );
    expect(
      _databaseImports('bad.dart', "import 'package:sqlite3/sqlite3.dart';"),
      hasLength(1),
    );
    expect(
      _databaseImports(
        'ok.dart',
        "import 'package:daily_budget/data/repositories/month_repository.dart';",
      ),
      isEmpty,
    );
  });

  test('TC-007-13 only the provider file outside data opens the database', () {
    // `lib/core` may import the database layer in one place: the providers
    // that open it and hand out repositories.
    final inCore = _offenders('lib/core');
    expect(
      inCore.every((line) => line.contains('database_providers.dart')),
      isTrue,
      reason: inCore.join('\n'),
    );
    // `lib/app.dart` and `lib/main.dart` do not touch it directly.
    for (final path in ['lib/app.dart', 'lib/main.dart']) {
      expect(
        _databaseImports(path, File(path).readAsStringSync()),
        isEmpty,
        reason: path,
      );
    }
  });
}
