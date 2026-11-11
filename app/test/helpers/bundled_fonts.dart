import 'package:flutter/services.dart';

/// Loads the bundled `Plex` and `Bricolage` families into the test engine.
///
/// Widget tests otherwise draw every family with the square test font, in
/// which all weights have the same width. Tests whose result depends on real
/// glyph widths (the Bold text setting, review M1) load the real fonts first.
Future<void> loadBundledFonts() async {
  final plex = FontLoader('Plex')
    ..addFont(rootBundle.load('assets/fonts/IBMPlexSans-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/IBMPlexSans-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/IBMPlexSans-SemiBold.ttf'));
  final bricolage = FontLoader('Bricolage')
    ..addFont(rootBundle.load('assets/fonts/BricolageGrotesque-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/BricolageGrotesque-Bold.ttf'));
  await Future.wait([plex.load(), bricolage.load()]);
}
