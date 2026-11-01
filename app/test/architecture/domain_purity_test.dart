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
}
