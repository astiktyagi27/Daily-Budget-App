import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Extends TC-001-06 (domain_purity_test.dart) without changing it (plan F-006
// §2): the layer direction, no clock and integers only for money.

const _clockPatterns = <String>[
  r'DateTime\.now',
  r'DateTime\.timestamp',
  r'\bClock\b',
  r'\bclock\.',
  'Stopwatch',
  r'\.toLocal\(',
  'timeZoneOffset',
];

const _forbiddenImports = <String>[
  'package:flutter',
  'dart:ui',
  'dart:io',
  'package:daily_budget/data/',
  'package:daily_budget/features/',
  '../data/',
  '../features/',
  'package:drift',
  'package:sqlite3',
  'package:shared_preferences',
];

const _floatPatterns = <String>[
  r'\bdouble\b',
  r'\bnum\b',
  r'toDouble\(',
  'toStringAsFixed',
  r'\.round\(',
  r'\.floor\(',
  r'\.ceil\(',
  // The `/` division operator: only `~/` and `%` are allowed. `//` comments
  // do not match (same pattern as tests/F-006 §1.1, TC-006-30).
  '[^~/]/[^/=*]',
];

final _importLine = RegExp(r'''^\s*(import|export|part)\s+['"]([^'"]+)['"]''');

Iterable<File> _dartFiles(String folder) =>
    Directory(folder)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

final _directiveLine = RegExp(r'^\s*(import|export|part|library)\b');
final _lineComment = RegExp('//.*');
final _stringLiteral = RegExp(r'''\'[^\']*\'|"[^"]*"''');

/// [line] as the money guard sees it: no directive, no string, no comment.
String _code(String line) => _directiveLine.hasMatch(line)
    ? ''
    : line.replaceAll(_stringLiteral, "''").replaceAll(_lineComment, '');

/// Every `file:line: text` in [source] that matches one of [patterns].
/// With [codeOnly], directive lines, strings and `//` comments are skipped
/// (M1, Gate 3): the integer-only guard looks at code only.
List<String> _matches(
  String name,
  String source,
  List<String> patterns, {
  bool codeOnly = false,
}) {
  final regexes = patterns.map(RegExp.new).toList();
  final lines = source.split('\n');
  return [
    for (var i = 0; i < lines.length; i++)
      if (regexes.any(
        (regex) => regex.hasMatch(codeOnly ? _code(lines[i]) : lines[i]),
      ))
        '$name:${i + 1}: ${lines[i].trim()}',
  ];
}

/// Every import, export or part line in [source] that points at a forbidden
/// layer or package.
List<String> _badImports(String name, String source) => [
  for (final match in _importLine.allMatches(source))
    if (_forbiddenImports.any(match.group(2)!.contains))
      '$name: ${match.group(0)!.trim()}',
];

void main() {
  test('TC-006-28 domain code never reads the clock', () {
    final offenders = [
      for (final file in _dartFiles('lib/domain'))
        ..._matches(file.path, file.readAsStringSync(), _clockPatterns),
    ];
    expect(offenders, isEmpty, reason: 'domain/ gets "today" passed in.');

    // The guard itself can fail.
    expect(
      _matches('bad.dart', 'final t = DateTime.now();', _clockPatterns),
      hasLength(1),
    );
  });

  test(
    'TC-006-29 domain does not import data features or database packages',
    () {
      final files = _dartFiles('lib/domain').toList();
      expect(files, isNotEmpty);
      final offenders = [
        for (final file in files)
          ..._badImports(file.path, file.readAsStringSync()),
      ];
      expect(
        offenders,
        isEmpty,
        reason:
            'domain/ is pure Dart: no Flutter, dart:io, data, features or '
            'database imports (STANDARDS §3).',
      );

      // The guard itself can fail, for each kind of forbidden import.
      for (final bad in _forbiddenImports) {
        expect(
          _badImports('bad.dart', "import '${bad}x.dart';"),
          hasLength(1),
          reason: bad,
        );
      }
      expect(
        _badImports('ok.dart', "import 'package:daily_budget/domain/x.dart';"),
        isEmpty,
      );
    },
  );

  test('TC-006-30 engine uses integers only for money', () {
    final files = _dartFiles('lib/domain/budget').toList();
    expect(files, isNotEmpty, reason: 'lib/domain/budget/ must exist.');
    final offenders = [
      for (final file in files)
        ..._matches(
          file.path,
          file.readAsStringSync(),
          _floatPatterns,
          codeOnly: true,
        ),
    ];
    expect(
      offenders,
      isEmpty,
      reason: 'Money is integer paise: no double, num, rounding or `/`.',
    );

    // The guard itself can fail on each pattern, and `~/` and `//` pass.
    const bad = [
      'double a;',
      'num b;',
      'x.toDouble();',
      'x.toStringAsFixed(2);',
      'x.round();',
      'x.floor();',
      'x.ceil();',
      'final c = a / b;',
    ];
    for (final line in bad) {
      expect(
        _matches('bad.dart', line, _floatPatterns, codeOnly: true),
        hasLength(1),
        reason: line,
      );
    }
    const ok = [
      'final c = a ~/ b; // note',
      "import 'package:daily_budget/domain/budget/paise.dart';",
      "export 'package:daily_budget/domain/budget/paise.dart';",
      '// spends and/or refunds',
      "final s = 'a / b';",
    ];
    for (final line in ok) {
      expect(
        _matches('ok.dart', line, _floatPatterns, codeOnly: true),
        isEmpty,
        reason: line,
      );
    }
    expect(
      _matches(
        'bad.dart',
        'final c = a / b; // x',
        _floatPatterns,
        codeOnly: true,
      ),
      hasLength(1),
    );
  });

  test('TC-013-24 statistics code has no floating point', () {
    // The generic guard above scans every file; this one names the two
    // Dashboard statistics files so a rename or move cannot drop them.
    for (final name in ['category_breakdown.dart', 'month_figures.dart']) {
      final file = File('lib/domain/budget/$name');
      expect(file.existsSync(), isTrue, reason: name);
      expect(
        _matches(name, file.readAsStringSync(), _floatPatterns, codeOnly: true),
        isEmpty,
        reason: '$name: integer paise only, ~/ for shares and the average.',
      );
    }
  });
}
