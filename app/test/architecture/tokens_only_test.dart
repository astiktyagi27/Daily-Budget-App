import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Raw styling that screens must not use: everything comes from the theme
/// and the tokens in `lib/core/` (F-002 AC-9, plan F-002 §1 step 6).
final _forbidden = {
  'Color(…)': RegExp(r'\bColor\('),
  'Color.fromARGB': RegExp(r'\bColor\.fromARGB\b'),
  'Color.fromRGBO': RegExp(r'\bColor\.fromRGBO\b'),
  'Colors.': RegExp(r'\bColors\.'),
  'fontFamily:': RegExp(r'\bfontFamily\s*:'),
  'GoogleFonts': RegExp(r'\bGoogleFonts\b'),
  'hex colour literal': RegExp(r'\b0x[0-9A-Fa-f]{6,8}\b'),
};

void main() {
  test('TC-002-15 features use no raw colours or font families', () {
    final features = Directory('lib/features');
    expect(features.existsSync(), isTrue, reason: 'lib/features/ is missing');

    final files = features
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    expect(files, isNotEmpty, reason: 'no Dart files under lib/features/');

    final findings = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final MapEntry(key: name, value: pattern) in _forbidden.entries) {
          if (pattern.hasMatch(lines[i])) {
            findings.add('${file.path}:${i + 1} uses $name');
          }
        }
      }
    }
    expect(findings, isEmpty, reason: findings.join('\n'));
  });
}
