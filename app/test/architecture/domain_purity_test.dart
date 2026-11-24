import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TC-001-06 domain contains no Flutter or dart:ui imports', () {
    // `flutter test` runs with the package root as the working directory.
    final domain = Directory('lib/domain');
    expect(
      domain.existsSync(),
      isTrue,
      reason: 'lib/domain/ must exist (STANDARDS §3).',
    );

    final offenders = <String>[];
    final dartFiles = domain
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      if (source.contains('package:flutter') || source.contains('dart:ui')) {
        offenders.add(file.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'domain/ must be pure Dart: no package:flutter or dart:ui.',
    );
  });

  test('TC-017-20 safe to spend is pure integer maths in the domain layer', () {
    final file = File('lib/domain/budget/safe_to_spend.dart');
    expect(file.existsSync(), isTrue, reason: 'the F-017 function is missing');

    // Only `~/` and `%` divide; comments and imports are not code.
    final forbidden = {
      'double': RegExp(r'\bdouble\b'),
      'num': RegExp(r'\bnum\b'),
      '.round': RegExp(r'\.round\('),
      '.floor': RegExp(r'\.floor\('),
      '.ceil': RegExp(r'\.ceil\('),
      '.toDouble': RegExp(r'\.toDouble\('),
      'toStringAsFixed': RegExp('toStringAsFixed'),
      'division with /': RegExp('[^~/]/[^/=*]'),
      'dart:io, dart:ui or the clock': RegExp(
        r'dart:io|dart:ui|DateTime\.now|package:flutter|package:drift',
      ),
    };
    List<String> offences(String source) => [
      for (final line in source.split('\n'))
        if (!line.trimLeft().startsWith('//') &&
            !line.trimLeft().startsWith('import ') &&
            !line.trimLeft().startsWith('export '))
          for (final MapEntry(:key, :value) in forbidden.entries)
            if (value.hasMatch(line)) '$key: $line',
    ];
    expect(offences(file.readAsStringSync()), isEmpty);

    // It imports only the domain.
    final imports = RegExp(
      "^import '([^']+)';",
      multiLine: true,
    ).allMatches(file.readAsStringSync()).map((m) => m.group(1)!);
    expect(imports, isNotEmpty);
    for (final import in imports) {
      expect(import, startsWith('package:daily_budget/domain/'));
    }

    // The guard can fail on each pattern.
    for (final bad in [
      'final double x = 1;',
      'num y = 2;',
      'a.round();',
      'a.floor();',
      'a.ceil();',
      'a.toDouble();',
      'a.toStringAsFixed(2);',
      'final c = a / b;',
      'DateTime.now();',
    ]) {
      expect(offences(bad), hasLength(1), reason: bad);
    }
    expect(offences('final c = a ~/ b; final d = a % b;'), isEmpty);
    expect(offences('// a / b is a comment'), isEmpty);
  });
}
