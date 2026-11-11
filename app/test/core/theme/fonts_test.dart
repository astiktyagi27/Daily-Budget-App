import 'dart:io';

import 'package:crypto/crypto.dart' show sha256;
import 'package:daily_budget/core/theme/font_licenses.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/font_tables.dart';

const _plexFiles = [
  'assets/fonts/IBMPlexSans-Regular.ttf',
  'assets/fonts/IBMPlexSans-Medium.ttf',
  'assets/fonts/IBMPlexSans-SemiBold.ttf',
];

const _bricolageFiles = [
  'assets/fonts/BricolageGrotesque-SemiBold.ttf',
  'assets/fonts/BricolageGrotesque-Bold.ttf',
];

void main() {
  test('TC-002-42 plex fonts contain rupee sign and tabular figures', () {
    for (final path in _plexFiles) {
      final font = FontTables(File(path).readAsBytesSync());

      expect(font.hasGlyph(0x20B9), isTrue, reason: '$path has no ₹ glyph');
      // Tabular figures, either switchable (`tnum` in GSUB) or already the
      // default: IBM Plex Sans 1.1.0 has no `tnum` feature because all ten
      // default digits share one advance width (plan F-002 §11, T-103).
      final digitWidths = {
        for (var digit = 0x30; digit <= 0x39; digit++) font.advanceWidth(digit),
      };
      expect(
        font.gsubFeatures.contains('tnum') || digitWidths.length == 1,
        isTrue,
        reason: '$path: digits are not tabular (widths $digitWidths)',
      );
      // The reader must also say "no" when a glyph is absent: Plex Sans has
      // no Devanagari (that is a separate family).
      expect(font.hasGlyph(0x41), isTrue, reason: '$path: Latin A');
      expect(font.hasGlyph(0x0915), isFalse, reason: '$path: Devanagari KA');
    }

    // The width check can also say "no": Bricolage's default digits are
    // proportional (it is used for words only, design system §4.1).
    final bricolage = FontTables(File(_bricolageFiles.first).readAsBytesSync());
    final bricolageWidths = {
      for (var digit = 0x30; digit <= 0x39; digit++)
        bricolage.advanceWidth(digit),
    };
    expect(bricolageWidths.length, greaterThan(1));
  });

  test(
    'TC-002-26 declared font files are bundled and nothing downloads fonts',
    () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final declared = RegExp(r'- asset: (assets/fonts/\S+\.ttf)')
          .allMatches(pubspec)
          .map((m) => m.group(1))
          .toSet();

      expect(declared, {..._plexFiles, ..._bricolageFiles});
      expect(pubspec, contains('- family: Bricolage'));
      expect(pubspec, contains('- family: Plex'));
      for (final path in [
        ...declared.nonNulls,
        'assets/fonts/OFL-BricolageGrotesque.txt',
        'assets/fonts/OFL-IBMPlexSans.txt',
        'assets/fonts/SOURCES.md',
      ]) {
        expect(File(path).existsSync(), isTrue, reason: '$path is missing');
      }

      final lock = File('pubspec.lock').readAsStringSync();
      for (final package in ['google_fonts', 'http', 'dio']) {
        expect(
          RegExp('^  $package:', multiLine: true).hasMatch(lock),
          isFalse,
          reason: '$package must not be a dependency',
        );
      }
    },
  );

  test('TC-002-26 sources list a sha-256 for every bundled font file', () {
    final sources = File('assets/fonts/SOURCES.md').readAsStringSync();
    for (final path in [
      ..._plexFiles,
      ..._bricolageFiles,
      'assets/fonts/OFL-BricolageGrotesque.txt',
      'assets/fonts/OFL-IBMPlexSans.txt',
    ]) {
      final name = path.split('/').last;
      final row = sources
          .split('\n')
          .firstWhere((l) => l.startsWith('| `$name`'), orElse: () => '');
      expect(
        RegExp('`[0-9a-f]{64}`').hasMatch(row),
        isTrue,
        reason: '$name has no SHA-256 row in SOURCES.md',
      );
    }
  });

  test(
    'TC-002-47 font sources list the true sha-256 of every bundled file',
    () {
      // package:crypto on the FIPS 180-2 examples (sanity check).
      expect(
        sha256.convert(const <int>[]).toString(),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
      expect(
        sha256.convert('abc'.codeUnits).toString(),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      expect(
        sha256
            .convert(
              'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'
                  .codeUnits,
            )
            .toString(),
        '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
      );

      // Every file in the folder except SOURCES.md itself: 5 fonts, 2 licences.
      final bundled =
          Directory('assets/fonts')
              .listSync()
              .whereType<File>()
              .map((f) => f.uri.pathSegments.last)
              .where((name) => name != 'SOURCES.md')
              .toList()
            ..sort();
      expect(bundled, hasLength(7));
      expect(bundled.where((n) => n.endsWith('.ttf')), hasLength(5));
      expect(bundled.where((n) => n.startsWith('OFL-')), hasLength(2));

      final rows = File('assets/fonts/SOURCES.md')
          .readAsLinesSync()
          .where((l) => RegExp(r'^\| `[^`]+` \|').hasMatch(l))
          .toList();
      expect(rows, hasLength(7), reason: 'one row per bundled file');
      for (final name in bundled) {
        final matching = rows.where((l) => l.startsWith('| `$name` |'));
        expect(matching, hasLength(1), reason: '$name: exactly one row');
        final cells = matching.single.split('|').map((c) => c.trim()).toList();
        // | file | upstream | release / commit | sha-256 |
        expect(cells, hasLength(6), reason: name);
        expect(
          cells[2],
          anyOf(contains('https://'), contains('same zip')),
          reason: '$name: source URL',
        );
        expect(cells[3], isNotEmpty, reason: '$name: release or commit');
        final hash = RegExp(r'^`([0-9a-f]{64})`$').firstMatch(cells[4]);
        expect(hash, isNotNull, reason: '$name: 64-hex SHA-256');
        expect(
          sha256
              .convert(File('assets/fonts/$name').readAsBytesSync())
              .toString(),
          hash!.group(1),
          reason: '$name: SHA-256 in SOURCES.md is not the file hash',
        );
      }
    },
  );

  test('TC-002-29 bundled font files load with the font loader', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final plex = FontLoader('Plex');
    for (final path in _plexFiles) {
      plex.addFont(rootBundle.load(path));
    }
    final bricolage = FontLoader('Bricolage');
    for (final path in _bricolageFiles) {
      bricolage.addFont(rootBundle.load(path));
    }

    await expectLater(plex.load(), completes);
    await expectLater(bricolage.load(), completes);
  });

  test('TC-002-30 font licences are registered', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    addTearDown(LicenseRegistry.reset);
    registerFontLicenses();

    final entries = await LicenseRegistry.licenses.toList();
    for (final name in ['Bricolage Grotesque', 'IBM Plex Sans']) {
      final matching = entries.where((e) => e.packages.contains(name));
      expect(matching, hasLength(1), reason: 'licence entry for $name');
      final text = matching.single.paragraphs.map((p) => p.text).join('\n');
      expect(text, contains('SIL OPEN FONT LICENSE'), reason: name);
      expect(text, contains('Version 1.1'), reason: name);
    }
  });
}
