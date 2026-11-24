// F-014 TC-014-26 and TC-014-49: the statement states in every theme, at text
// 1.0 and 2.0 on the small phone, and in landscape, with the F-002 checks.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/bundled_fonts.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/statement_harness.dart';
import '../../helpers/theme_cases.dart';

/// The T states of tests/F-014 section 0 that this screen can show without
/// month switching (loading and error are in the screen test).
final _states = <String, Phase3Fixture>{
  'M20 so far': fixtureM20,
  'M-full finished (refunds)': fixtureMFull,
  'single period (A)': fixtureA,
  'shortfall (S)': fixtureS,
  'shortfall by a change (C4)': c4,
  'mid-month first (F)': fixtureF,
  'rounding note (Mx)': mx,
  'three periods (E2c)': e2c,
  'same day changes (E2s)': e2s,
};

void main() {
  setUpAll(loadBundledFonts);

  testWidgets('TC-014-26 statement states pass the theme and text scale '
      'sweep', (tester) async {
    for (final MapEntry(key: name, value: fixture) in _states.entries) {
      for (final theme in ThemeCase.values) {
        for (final scale in const [1.0, 2.0]) {
          await pumpStatement(tester, fixture, theme: theme, textScale: scale);
          await expectAccessible(
            tester,
            reason: '$name / ${theme.name} / x$scale',
          );
        }
      }
    }
  });

  testWidgets('TC-014-49 statement in landscape keeps a 600 dp column', (
    tester,
  ) async {
    for (final theme in [ThemeCase.light, ThemeCase.dim]) {
      for (final scale in const [1.0, 2.0]) {
        await pumpStatement(
          tester,
          fixtureM20,
          theme: theme,
          textScale: scale,
          size: kSmallLandscape,
        );
        await expectAccessible(
          tester,
          reason: 'landscape / ${theme.name} / x$scale',
        );
        final width = tester.getSize(find.byType(Column).first).width;
        expect(width, lessThanOrEqualTo(600));
      }
    }
  });
}
