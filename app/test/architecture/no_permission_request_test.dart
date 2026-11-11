import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Phase 1 asks for no permission at all (F-005 AC-7…AC-9, plan F-005 §1
/// step 6). Real requests come with their own package decision in Phase 4
/// (SMS) and Phase 5 (notifications); this guard is then updated on purpose.

/// Packages that request SMS or notification permissions.
const _permissionPackages = [
  'permission_handler',
  'flutter_local_notifications',
  'telephony',
  'another_telephony',
  'sms_advanced',
  'readsms',
];

/// Strings that only appear when Dart code asks for a permission.
const _permissionApis = [
  'requestPermission',
  'Permission.',
  'permission_handler',
  'flutter_local_notifications',
  'telephony',
  'POST_NOTIFICATIONS',
  'READ_SMS',
  'RECEIVE_SMS',
];

const _manifestPermissions = ['READ_SMS', 'RECEIVE_SMS', 'POST_NOTIFICATIONS'];

/// Package names listed as keys in a pubspec or lock file: a line that is
/// only `name:` at two or four spaces of indentation.
Set<String> _packageNames(String yaml) => RegExp(
  r'^ {2,4}([a-z0-9_]+):\s*(?:\S.*)?$',
  multiLine: true,
).allMatches(yaml).map((m) => m.group(1)!).toSet();

bool _isPermissionPackage(String name) => _permissionPackages.any(
  (banned) => name == banned || name.startsWith('${banned}_'),
);

void main() {
  test('TC-005-11 no code requests a permission', () {
    final lib = Directory('lib');
    expect(lib.existsSync(), isTrue, reason: 'run from app/');
    final findings = <String>[];
    final files = lib
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final api in _permissionApis) {
          if (lines[i].contains(api)) {
            findings.add('${file.path}:${i + 1} contains "$api"');
          }
        }
      }
    }
    expect(findings, isEmpty, reason: findings.join('\n'));
  });

  test('TC-005-11 no permission package in pubspec or lock file', () {
    for (final path in ['pubspec.yaml', 'pubspec.lock']) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      final names = _packageNames(file.readAsStringSync());
      expect(names, isNotEmpty, reason: '$path: no packages parsed');
      expect(
        names.where(_isPermissionPackage),
        isEmpty,
        reason: '$path lists a permission package',
      );
    }
    // The parser does find real packages, so the check can fail.
    expect(
      _packageNames(File('pubspec.lock').readAsStringSync()),
      contains('shared_preferences'),
    );
    expect(_isPermissionPackage('permission_handler_android'), isTrue);
    expect(_isPermissionPackage('shared_preferences'), isFalse);
  });

  test('TC-005-12 manifests declare no sms or notification permission', () {
    final manifests = Directory('android/app/src')
        .listSync()
        .whereType<Directory>()
        .map((dir) => File('${dir.path}/AndroidManifest.xml'))
        .where((file) => file.existsSync())
        .toList();
    expect(
      manifests.map((f) => f.uri.pathSegments.reversed.skip(1).first),
      contains('main'),
      reason: 'the main manifest is checked',
    );
    final findings = <String>[];
    for (final manifest in manifests) {
      final source = manifest.readAsStringSync();
      for (final permission in _manifestPermissions) {
        if (source.contains(permission)) {
          findings.add('${manifest.path} declares $permission');
        }
      }
    }
    expect(findings, isEmpty, reason: findings.join('\n'));
  });
}
