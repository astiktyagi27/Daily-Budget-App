import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Widgets and calls that screens must not use directly: help UI and shared
/// controls come from `lib/core/` (F-004 AC-6, plan F-004 §10 point 3).
/// `\b` keeps the shared wrappers allowed (`NavTooltip(` is not `Tooltip(`).
/// `Icons.info` is deliberately not listed: the Disclaimer row uses it.
final _forbidden = {
  'Tooltip( (use NavTooltip)': RegExp(r'\bTooltip\('),
  'showModalBottomSheet( (use showBudgetSheet)': RegExp(
    r'\bshowModalBottomSheet\(',
  ),
  'showBottomSheet( (use showBudgetSheet)': RegExp(r'\bshowBottomSheet\('),
  'showDialog(': RegExp(r'\bshowDialog\('),
  'ListTile( (use BudgetListRow)': RegExp(r'\bListTile\('),
  'IconButton( (use InfoButton or a core control)': RegExp(r'\bIconButton\('),
};

const _helpCopyPath = 'lib/core/copy/help_copy.dart';

List<File> _dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

/// The source without whole-line comments, with adjacent string literals
/// joined and quotes unescaped, so a string split over several lines can be
/// searched as one piece (and a doc comment quoting it does not count).
String _joined(String source) => source
    .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '')
    .replaceAll(RegExp(r'''['"]\s+['"]'''), '')
    .replaceAll(r"\'", "'")
    .replaceAll(r'\"', '"');

String _normalPath(File f) => f.path.replaceAll(r'\', '/');

void main() {
  test('TC-004-08 features use the shared help components', () {
    final files = _dartFiles('lib/features');
    expect(files, isNotEmpty, reason: 'no Dart files under lib/features/');

    final findings = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final MapEntry(key: name, value: pattern) in _forbidden.entries) {
          if (pattern.hasMatch(lines[i])) {
            findings.add('${_normalPath(file)}:${i + 1} uses $name');
          }
        }
      }
    }
    expect(findings, isEmpty, reason: findings.join('\n'));
  });

  test('TC-004-08 help copy lives in one core file', () {
    // Every constant help string, read from the help-copy file itself.
    final helpSource = _joined(File(_helpCopyPath).readAsStringSync());
    final strings = {
      for (final m in RegExp(
        r'''static const (\w+) =\s*(?:'([^']*)'|"([^"]*)");''',
      ).allMatches(helpSource))
        m.group(1)!: m.group(2) ?? m.group(3)!,
    };
    // The fixed parts of the three help-string templates.
    final templates = {
      'moreAbout': 'More about ',
      'comingSoon': ', coming soon, not available yet. ',
      'themeChanged': 'Theme changed to ',
    };
    // A sanity floor (F-002…F-005 help rows), so a broken parse cannot pass.
    expect(strings.length, greaterThanOrEqualTo(30));
    expect(strings['hintHome'], startsWith('Use the tabs at the bottom'));

    final sources = {
      for (final file in _dartFiles('lib'))
        _normalPath(file): _joined(file.readAsStringSync()),
    };
    for (final MapEntry(key: name, value: text) in {
      ...strings,
      ...templates,
    }.entries) {
      final holders = [
        for (final MapEntry(key: path, value: source) in sources.entries)
          if (source.contains(text)) path,
      ];
      expect(holders, [_helpCopyPath], reason: '$name ("$text")');
    }
  });
}
