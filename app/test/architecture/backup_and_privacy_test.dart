import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// F-007 AC-11 and AC-12 (plan T-210): nothing leaves the phone through the
// cloud, phone-to-phone transfer keeps the data (D-045, D-049), and no
// encryption package is a direct dependency (D-041).

const _manifestPath = 'android/app/src/main/AndroidManifest.xml';
const _rulesPath = 'android/app/src/main/res/xml/data_extraction_rules.xml';
const _oldRulesPath = 'android/app/src/main/res/xml/backup_rules.xml';

String _read(String path) => File(path).readAsStringSync();

String _block(String xml, String tag) {
  final match = RegExp('<$tag[^>]*>([\\s\\S]*?)</$tag>').firstMatch(xml);
  expect(match, isNotNull, reason: '<$tag> is missing');
  return match!.group(1)!;
}

Set<String> _domains(String block, String element) => {
  for (final m in RegExp('<$element\\s+domain="([a-z_]+)"').allMatches(block))
    m.group(1)!,
};

/// The `allowBackup` and rule attributes of the `<application>` element.
void _expectBackupAttributes(String manifest) {
  expect(manifest, contains('android:allowBackup="false"'));
  expect(
    manifest,
    contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
  );
  expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
}

const _everyDomain = ['root', 'file', 'database', 'sharedpref', 'external'];

void main() {
  test(
    'TC-007-19 cloud backup is off and device transfer includes the data',
    () {
      _expectBackupAttributes(_read(_manifestPath));

      final rules = _read(_rulesPath);
      final cloud = _block(rules, 'cloud-backup');
      expect(_domains(cloud, 'exclude'), containsAll(_everyDomain));
      expect(_domains(cloud, 'include'), isEmpty);

      final transfer = _block(rules, 'device-transfer');
      expect(_domains(transfer, 'include'), {'database', 'sharedpref'});
      expect(_domains(transfer, 'exclude'), isEmpty);

      // Android 11 and older: nothing is backed up (D-049).
      final old = _read(_oldRulesPath);
      expect(_domains(old, 'exclude'), containsAll(_everyDomain));
      expect(_domains(old, 'include'), isEmpty);
    },
  );

  test(
    'TC-007-19 the merged manifest of the last build has the same flags',
    () {
      // Only after `flutter build apk --debug` (merged manifest output exists).
      final source = File(_manifestPath).lastModifiedSync();
      final merged = Directory('build/app/intermediates/merged_manifests');
      if (!merged.existsSync()) return;
      final files = merged
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('AndroidManifest.xml'))
          // A build older than the source manifest says nothing about it.
          .where((f) => !f.lastModifiedSync().isBefore(source));
      for (final file in files) {
        _expectBackupAttributes(file.readAsStringSync());
      }
    },
  );

  test('TC-007-22 no encryption package is a direct dependency', () {
    final pubspec = _read('pubspec.yaml');
    final direct = pubspec.split(RegExp('^flutter:', multiLine: true)).first;
    for (final name in [
      'sqlcipher_flutter_libs',
      'sqlite3_flutter_libs',
      'sqflite_sqlcipher',
      'flutter_secure_storage',
      'encrypt',
      'pointycastle',
      'sqlite3mc',
    ]) {
      expect(
        RegExp('^\\s+$name:', multiLine: true).hasMatch(direct),
        isFalse,
        reason: name,
      );
    }
    // No build hook switches SQLite to an encrypted build.
    expect(pubspec.contains('user_defines'), isFalse);
    // If the two end-of-life stubs are in the lock, only as `+eol` versions.
    final lock = _read('pubspec.lock');
    for (final name in ['sqlite3_flutter_libs', 'sqlcipher_flutter_libs']) {
      final match = RegExp(
        '^  $name:\\n(?:    .*\\n)+?    version: "([^"]+)"',
        multiLine: true,
      ).firstMatch(lock);
      if (match != null) {
        expect(match.group(1), endsWith('+eol'), reason: name);
      }
    }
  });
}
