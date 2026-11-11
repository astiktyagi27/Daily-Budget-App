import 'package:daily_budget/core/theme/budget_colors.dart';
import 'package:daily_budget/core/theme/budget_elevation.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_theme.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/contrast.dart';

const Map<String, BudgetColors> _themes = {
  'Light': BudgetColors.light,
  'Dark': BudgetColors.dark,
  'Dim': BudgetColors.dim,
};

/// Read a token by its design-system name.
Color _token(BudgetColors c, String name) => switch (name) {
  'bg' => c.bg,
  'surface' => c.surface,
  'sunken' => c.sunken,
  'textPrimary' => c.textPrimary,
  'textSecondary' => c.textSecondary,
  'accent' => c.accent,
  'onAccent' => c.onAccent,
  'accentSoft' => c.accentSoft,
  'saved' => c.saved,
  'savedSoft' => c.savedSoft,
  'overspent' => c.overspent,
  'overspentSoft' => c.overspentSoft,
  'neutral' => c.neutral,
  'neutralSoft' => c.neutralSoft,
  'border' => c.border,
  'borderStrong' => c.borderStrong,
  'focus' => c.focus,
  'inverseSurface' => c.inverseSurface,
  'onInverseSurface' => c.onInverseSurface,
  'inverseAccent' => c.inverseAccent,
  'scrim' => c.scrim,
  'onError' => c.onError,
  _ => throw ArgumentError(name),
};

void main() {
  test('TC-002-16 token values match the design system', () {
    // Literals copied from docs/design/design-system.md §2 (Light, Dark, Dim),
    // never read from the app's constants.
    const expected = <String, List<int>>{
      'bg': [0xFFF6F3ED, 0xFF0E0E12, 0xFF2A2825],
      'surface': [0xFFFFFDF8, 0xFF17171D, 0xFF34312D],
      'sunken': [0xFFEEEAE2, 0xFF0A0A0D, 0xFF24221F],
      'textPrimary': [0xFF1C1B22, 0xFFF2F0EA, 0xFFEEE9E0],
      'textSecondary': [0xFF5C5864, 0xFFA8A5B1, 0xFFBEB7AB],
      'accent': [0xFF3A3DB0, 0xFF9C9FFF, 0xFFABACF6],
      'onAccent': [0xFFFFFFFF, 0xFF14143D, 0xFF1B1B3D],
      'accentSoft': [0xFFE7E6F6, 0xFF25264A, 0xFF3E3D55],
      'saved': [0xFF1A7044, 0xFF52C98B, 0xFF80D3A1],
      'savedSoft': [0xFFDDEFE3, 0xFF16301F, 0xFF2F3F33],
      'overspent': [0xFFB4372F, 0xFFFF7B6F, 0xFFFF9C8E],
      'overspentSoft': [0xFFF6E0DC, 0xFF3A1A17, 0xFF4A3230],
      'neutral': [0xFF68646E, 0xFF9F9CA7, 0xFFB6AFA4],
      'neutralSoft': [0xFFEAE6DF, 0xFF24242B, 0xFF3D3A35],
      'border': [0xFFDED8CD, 0xFF2A2A33, 0xFF48453F],
      'borderStrong': [0xFF8A8377, 0xFF6A6876, 0xFF878073],
      'focus': [0xFF3A3DB0, 0xFFBDBFFF, 0xFFC6C7FF],
      'inverseSurface': [0xFF1C1B22, 0xFFEEE9E0, 0xFFEEE9E0],
      'onInverseSurface': [0xFFF2F0EA, 0xFF1C1B22, 0xFF1C1B22],
      'inverseAccent': [0xFFABACF6, 0xFF3A3DB0, 0xFF3A3DB0],
      // §3 note: text on a filled red.
      'onError': [0xFFFFFFFF, 0xFF1C1B22, 0xFF1C1B22],
    };
    final themes = _themes.entries.toList();
    for (final MapEntry(key: token, value: hexes) in expected.entries) {
      for (var i = 0; i < 3; i++) {
        expect(
          _token(themes[i].value, token).toARGB32(),
          hexes[i],
          reason: '$token in ${themes[i].key}',
        );
      }
    }

    // scrim: #1C1B22 at 40 %, #000000 at 60 %, #000000 at 50 %.
    const scrims = [(0x1C1B22, 0.40), (0x000000, 0.60), (0x000000, 0.50)];
    for (var i = 0; i < 3; i++) {
      final scrim = themes[i].value.scrim;
      final (rgb, alpha) = scrims[i];
      expect(
        scrim.toARGB32() & 0xFFFFFF,
        rgb,
        reason: 'scrim ${themes[i].key}',
      );
      expect(
        scrim.a,
        closeTo(alpha, 1 / 255),
        reason: 'scrim ${themes[i].key}',
      );
    }
  });

  test('TC-002-16 token extensions copy and lerp between themes', () {
    const light = BudgetColors.light;
    const dim = BudgetColors.dim;

    expect(light.copyWith().bg, light.bg);
    expect(light.copyWith(accent: dim.accent).accent, dim.accent);
    expect(light.copyWith(accent: dim.accent).bg, light.bg);
    expect(light.lerp(dim, 0).bg, light.bg);
    expect(light.lerp(dim, 1).bg, dim.bg);
    expect(light.lerp(dim, 1).scrim, dim.scrim);
    expect(light.lerp(null, 0.5), same(light));
    final halfway = light.lerp(dim, 0.5).bg;
    expect(halfway, isNot(light.bg));
    expect(halfway, isNot(dim.bg));

    const text = BudgetText.standard;
    expect(text.lerp(text, 0.5).moneyHero.fontSize, 40);
    expect(text.copyWith(title: text.headline).title, text.headline);

    expect(BudgetElevation.light.lerp(BudgetElevation.flat, 1).sheet, isEmpty);
    expect(BudgetElevation.flat.copyWith().float, isEmpty);
  });

  test('TC-002-16 spacing radius elevation and motion tokens match the design '
      'system', () {
    expect(
      [
        BudgetSpacing.space1,
        BudgetSpacing.space2,
        BudgetSpacing.space3,
        BudgetSpacing.space4,
        BudgetSpacing.space5,
        BudgetSpacing.space6,
        BudgetSpacing.space7,
        BudgetSpacing.space8,
        BudgetSpacing.space9,
        BudgetSpacing.touchTarget,
      ],
      [4, 8, 12, 16, 20, 24, 32, 40, 56, 48],
    );
    expect(
      [
        BudgetRadii.xs,
        BudgetRadii.sm,
        BudgetRadii.md,
        BudgetRadii.lg,
        BudgetRadii.xl,
        BudgetRadii.full,
      ],
      [6, 10, 14, 20, 28, 999],
    );

    const motion = BudgetMotion.full;
    expect(
      [
        motion.fast,
        motion.base,
        motion.emphasis,
        motion.emphasisExit,
        motion.count,
      ].map((d) => d.inMilliseconds),
      [120, 200, 320, 240, 600],
    );
    expect(BudgetMotion.standard, const Cubic(0.2, 0, 0, 1));
    expect(BudgetMotion.decelerate, const Cubic(0.05, 0.7, 0.1, 1));
    expect(BudgetMotion.accelerate, const Cubic(0.3, 0, 0.8, 0.15));

    final float = BudgetElevation.light.float.single;
    expect(float.offset, const Offset(0, 4));
    expect(float.blurRadius, 16);
    expect(float.color.toARGB32() & 0xFFFFFF, 0x1C1B22);
    expect(float.color.a, closeTo(0.08, 1 / 255));
    final sheet = BudgetElevation.light.sheet.single;
    expect(sheet.offset, const Offset(0, -8));
    expect(sheet.blurRadius, 32);
    expect(sheet.color.a, closeTo(0.12, 1 / 255));
    expect(BudgetElevation.flat.float, isEmpty);
    expect(BudgetElevation.flat.sheet, isEmpty);
  });

  testWidgets('TC-002-16 motion durations are zero when animations are '
      'removed', (tester) async {
    late BudgetMotion normal;
    late BudgetMotion reduced;
    await tester.pumpWidget(
      Column(
        children: [
          Builder(
            builder: (context) {
              normal = BudgetMotion.of(context);
              return const SizedBox();
            },
          ),
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                reduced = BudgetMotion.of(context);
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );

    expect(normal.base, const Duration(milliseconds: 200));
    expect([
      reduced.fast,
      reduced.base,
      reduced.emphasis,
      reduced.emphasisExit,
      reduced.count,
    ], everyElement(Duration.zero));
  });

  test('TC-002-17 accent is not green or red', () {
    bool isGreen(double hue) => hue >= 75 && hue <= 165;
    bool isRed(double hue) => hue >= 345 || hue <= 20;
    for (final MapEntry(key: name, value: c) in _themes.entries) {
      final saved = HSLColor.fromColor(c.saved).hue;
      final overspent = HSLColor.fromColor(c.overspent).hue;
      final accent = HSLColor.fromColor(c.accent).hue;
      expect(isGreen(saved), isTrue, reason: '$name saved hue $saved');
      expect(
        isRed(overspent),
        isTrue,
        reason: '$name overspent hue $overspent',
      );
      expect(isGreen(accent), isFalse, reason: '$name accent hue $accent');
      expect(isRed(accent), isFalse, reason: '$name accent hue $accent');
    }
  });

  test('TC-002-21 every token pair meets wcag aa', () {
    // design-system.md §3: foreground, background, Light, Dark, Dim, needed.
    const pairs = <(String, String, double, double, double, double)>[
      ('textPrimary', 'bg', 15.43, 16.90, 12.16, 4.5),
      ('textPrimary', 'surface', 16.81, 15.66, 10.70, 4.5),
      ('textPrimary', 'sunken', 14.24, 17.35, 13.12, 4.5),
      ('textSecondary', 'bg', 6.25, 7.96, 7.39, 4.5),
      ('textSecondary', 'surface', 6.81, 7.38, 6.50, 4.5),
      ('textSecondary', 'sunken', 5.77, 8.17, 7.97, 4.5),
      ('accent', 'bg', 7.66, 8.09, 6.97, 4.5),
      ('accent', 'surface', 8.35, 7.49, 6.14, 4.5),
      ('onAccent', 'accent', 8.49, 7.36, 7.84, 4.5),
      ('accent', 'accentSoft', 6.89, 6.06, 4.97, 4.5),
      ('textPrimary', 'accentSoft', 13.87, 12.67, 8.67, 4.5),
      ('saved', 'surface', 6.00, 8.57, 7.24, 4.5),
      ('saved', 'bg', 5.50, 9.25, 8.22, 4.5),
      ('saved', 'savedSoft', 5.09, 6.83, 6.25, 4.5),
      ('textPrimary', 'savedSoft', 14.26, 12.48, 9.24, 4.5),
      ('overspent', 'surface', 5.86, 7.07, 6.41, 4.5),
      ('overspent', 'bg', 5.37, 7.63, 7.28, 4.5),
      ('overspent', 'overspentSoft', 4.71, 6.20, 5.81, 4.5),
      ('textPrimary', 'overspentSoft', 13.52, 13.75, 9.70, 4.5),
      ('neutral', 'surface', 5.68, 6.62, 5.95, 4.5),
      ('neutral', 'bg', 5.21, 7.14, 6.76, 4.5),
      ('neutral', 'neutralSoft', 4.64, 5.72, 5.21, 4.5),
      ('textPrimary', 'neutralSoft', 13.73, 13.53, 9.36, 4.5),
      ('onInverseSurface', 'inverseSurface', 14.99, 14.13, 14.13, 4.5),
      ('inverseAccent', 'inverseSurface', 8.11, 7.02, 7.02, 4.5),
      ('borderStrong', 'surface', 3.69, 3.28, 3.31, 3.0),
      ('focus', 'surface', 8.35, 10.25, 8.02, 3.0),
      ('focus', 'bg', 7.66, 11.06, 9.11, 3.0),
      ('textSecondary', 'neutralSoft', 5.56, 6.37, 5.69, 4.5),
      ('textSecondary', 'accentSoft', 5.62, 5.97, 5.27, 3.0),
      ('borderStrong', 'bg', 3.39, 3.54, 3.76, 3.0),
    ];
    expect(pairs, hasLength(31));

    final themes = _themes.entries.toList();
    for (final (fg, bg, light, dark, dim, needed) in pairs) {
      final documented = [light, dark, dim];
      for (var i = 0; i < 3; i++) {
        final colors = themes[i].value;
        final ratio = contrastRatio(_token(colors, fg), _token(colors, bg));
        final where =
            '$fg on $bg in ${themes[i].key}: '
            '${ratio.toStringAsFixed(2)}';
        expect(ratio, greaterThanOrEqualTo(needed), reason: where);
        expect(ratio, closeTo(documented[i], 0.01), reason: where);
      }
    }

    // Error text on a filled red (§3 note): 5.95 / 6.76 / 8.46.
    const onErrorRatios = [5.95, 6.76, 8.46];
    for (var i = 0; i < 3; i++) {
      final colors = themes[i].value;
      expect(
        contrastRatio(colors.onError, colors.overspent),
        closeTo(onErrorRatios[i], 0.01),
        reason: 'onError on overspent in ${themes[i].key}',
      );
    }
  });

  testWidgets('TC-002-41 money styles use plex with tabular figures', (
    tester,
  ) async {
    const text = BudgetText.standard;
    final styles = {
      'moneyHero': (text.moneyHero, 40.0, FontWeight.w600),
      'moneyLarge': (text.moneyLarge, 28.0, FontWeight.w600),
      'moneyMedium': (text.moneyMedium, 18.0, FontWeight.w500),
      'moneySmall': (text.moneySmall, 12.0, FontWeight.w500),
    };
    for (final MapEntry(key: name, value: (style, size, weight))
        in styles.entries) {
      expect(style.fontFamily, 'Plex', reason: name);
      expect(style.fontSize, size, reason: name);
      expect(style.fontWeight, weight, reason: name);
      expect(
        style.fontFeatures,
        contains(const FontFeature.tabularFigures()),
        reason: name,
      );
    }

    // Fixed strings (no money formatter in Phase 1); U+2212 minus sign.
    const strings = ['₹1,33,333', '₹830', '−₹467'];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            for (final (style, _, _) in styles.values)
              for (final s in strings) Text(s, style: style),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('₹1,33,333'), findsNWidgets(4));
  });

  test('TC-002-29 heading styles use bricolage and body styles use plex', () {
    const headings = {
      'displayHeadline': (BudgetTypeScale.displayHeadline, 32.0, 38.0),
      'headline': (BudgetTypeScale.headline, 26.0, 32.0),
      'title': (BudgetTypeScale.title, 20.0, 26.0),
    };
    for (final MapEntry(key: name, value: (style, size, line))
        in headings.entries) {
      expect(style.fontFamily, 'Bricolage', reason: name);
      expect(style.fontSize, size, reason: name);
      expect(style.height! * size, closeTo(line, 0.001), reason: name);
    }
    expect(BudgetText.standard.headline, BudgetTypeScale.headline);

    const body = {
      'bodyLarge': (BudgetTypeScale.bodyLarge, 16.0, 24.0, FontWeight.w400),
      'body': (BudgetTypeScale.body, 14.0, 20.0, FontWeight.w400),
      'label': (BudgetTypeScale.label, 14.0, 20.0, FontWeight.w500),
      'button': (BudgetTypeScale.button, 15.0, 20.0, FontWeight.w600),
      'caption': (BudgetTypeScale.caption, 12.0, 16.0, FontWeight.w400),
    };
    for (final MapEntry(key: name, value: (style, size, line, weight))
        in body.entries) {
      expect(style.fontFamily, 'Plex', reason: name);
      expect(style.fontSize, size, reason: name);
      expect(style.height! * size, closeTo(line, 0.001), reason: name);
      expect(style.fontWeight, weight, reason: name);
    }
  });

  test('TC-002-46 on error colour matches the design system per theme', () {
    // design-system.md §2, §3 note and §8.2: theme, built theme, onError,
    // ratio of onError on overspent (= error).
    final cases = <(String, BudgetColors, ThemeData, int, double)>[
      ('Light', BudgetColors.light, budgetLightTheme, 0xFFFFFFFF, 5.95),
      ('Dark', BudgetColors.dark, budgetDarkTheme, 0xFF1C1B22, 6.76),
      ('Dim', BudgetColors.dim, budgetDimTheme, 0xFF1C1B22, 8.46),
    ];
    for (final (name, colors, theme, onError, ratio) in cases) {
      expect(colors.onError.toARGB32(), onError, reason: '$name onError');
      expect(
        theme.colorScheme.onError.toARGB32(),
        onError,
        reason: '$name ColorScheme.onError',
      );
      expect(
        theme.colorScheme.error,
        colors.overspent,
        reason: '$name ColorScheme.error is overspent',
      );
      final actual = contrastRatio(colors.onError, colors.overspent);
      expect(actual, greaterThanOrEqualTo(4.5), reason: '$name AA');
      expect(actual, closeTo(ratio, 0.01), reason: '$name design §3');
    }
  });
}
