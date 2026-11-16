import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What the one money formatter may not use: floating point or rounding
/// helpers (integers only, STANDARDS §4, F-008 AC-19).
final _formatterForbidden = {
  'double': RegExp(r'\bdouble\b'),
  'num': RegExp(r'\bnum\b'),
  'toStringAsFixed': RegExp('toStringAsFixed'),
  'NumberFormat.currency': RegExp(r'NumberFormat\.currency'),
  'division with /': RegExp('[^~/]/[^/=*]'),
};

/// What screens may not do: all money text comes from `formatRupees`.
final _screensForbidden = {
  'NumberFormat': RegExp('NumberFormat'),
  'toStringAsFixed': RegExp('toStringAsFixed'),
  '~/ 100': RegExp(r'~/\s*100'),
  'a string starting with ₹': RegExp('[\'"]₹'),
};

List<File> _dartFiles(String path) {
  final directory = Directory(path);
  expect(directory.existsSync(), isTrue, reason: '$path is missing');
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();
}

List<String> _scan(List<File> files, Map<String, RegExp> forbidden) {
  final findings = <String>[];
  for (final file in files) {
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final code = line.trimLeft();
      // Comments and imports carry slashes that are not arithmetic.
      if (code.startsWith('//') ||
          code.startsWith('import ') ||
          code.startsWith('export ')) {
        continue;
      }
      for (final MapEntry(key: name, value: pattern) in forbidden.entries) {
        if (pattern.hasMatch(line)) {
          findings.add('${file.path}:${i + 1} uses $name');
        }
      }
    }
  }
  return findings;
}

void main() {
  test('TC-008-30 screens format money only through the shared formatter', () {
    final formatter = _dartFiles('lib/core/format');
    expect(
      formatter.map((f) => f.path.replaceAll(r'\', '/')),
      contains('lib/core/format/money_format.dart'),
    );
    expect(
      _scan(formatter, _formatterForbidden),
      isEmpty,
      reason: 'lib/core/format must use integer arithmetic only',
    );

    final screens = _dartFiles('lib/features');
    expect(screens, isNotEmpty);
    expect(
      _scan(screens, _screensForbidden),
      isEmpty,
      reason: 'money text in lib/features must come from formatRupees',
    );
  });

  test('TC-008-30 the guard catches what it should', () {
    // One probe per pattern, so a pattern that silently stopped matching
    // fails here instead of letting a bad file through.
    final formatter = _formatterForbidden;
    expect(formatter['double']!.hasMatch('final double x = 1;'), isTrue);
    expect(formatter['num']!.hasMatch('num value = 1;'), isTrue);
    expect(
      formatter['toStringAsFixed']!.hasMatch('x.toStringAsFixed(2)'),
      isTrue,
    );
    expect(
      formatter['division with /']!.hasMatch('final a = b / 100;'),
      isTrue,
    );
    expect(
      formatter['division with /']!.hasMatch('final a = b ~/ 100;'),
      isFalse,
    );
    expect(
      formatter['NumberFormat.currency']!.hasMatch('NumberFormat.currency()'),
      isTrue,
    );

    final screens = _screensForbidden;
    expect(
      screens['NumberFormat']!.hasMatch('NumberFormat.decimalPattern()'),
      isTrue,
    );
    expect(screens['~/ 100']!.hasMatch('paise ~/ 100'), isTrue);
    expect(
      screens['a string starting with ₹']!.hasMatch(r"Text('₹$amount')"),
      isTrue,
    );
    expect(screens['a string starting with ₹']!.hasMatch('Text("₹5")'), isTrue);
    expect(
      screens['a string starting with ₹']!.hasMatch('Text(formatRupees(a))'),
      isFalse,
    );
  });
}
