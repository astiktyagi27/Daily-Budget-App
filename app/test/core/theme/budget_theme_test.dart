import 'package:daily_budget/core/theme/budget_colors.dart';
import 'package:daily_budget/core/theme/budget_elevation.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_theme.dart';
import 'package:daily_budget/core/theme/system_bars.dart';
import 'package:daily_budget/domain/preferences/theme_choice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final Map<String, (ThemeData, BudgetColors, Brightness)> _built = {
  'Light': (budgetLightTheme, BudgetColors.light, Brightness.light),
  'Dark': (budgetDarkTheme, BudgetColors.dark, Brightness.dark),
  'Dim': (budgetDimTheme, BudgetColors.dim, Brightness.dark),
};

void main() {
  test('TC-002-16 color scheme maps the tokens per design system', () {
    for (final MapEntry(key: name, value: (theme, c, brightness))
        in _built.entries) {
      final s = theme.colorScheme;
      expect(s.brightness, brightness, reason: '$name brightness');
      final expected = <String, (Color, Color)>{
        'primary': (s.primary, c.accent),
        'onPrimary': (s.onPrimary, c.onAccent),
        'primaryContainer': (s.primaryContainer, c.accentSoft),
        'onPrimaryContainer': (s.onPrimaryContainer, c.textPrimary),
        'secondaryContainer': (s.secondaryContainer, c.accentSoft),
        'onSecondaryContainer': (s.onSecondaryContainer, c.textPrimary),
        'error': (s.error, c.overspent),
        'onError': (s.onError, c.onError),
        'errorContainer': (s.errorContainer, c.overspentSoft),
        'onErrorContainer': (s.onErrorContainer, c.textPrimary),
        'surface': (s.surface, c.surface),
        'onSurface': (s.onSurface, c.textPrimary),
        'onSurfaceVariant': (s.onSurfaceVariant, c.textSecondary),
        'surfaceContainerLowest': (s.surfaceContainerLowest, c.surface),
        'surfaceContainerLow': (s.surfaceContainerLow, c.bg),
        'surfaceContainer': (s.surfaceContainer, c.bg),
        'surfaceContainerHigh': (s.surfaceContainerHigh, c.sunken),
        'surfaceContainerHighest': (s.surfaceContainerHighest, c.sunken),
        'outline': (s.outline, c.borderStrong),
        'outlineVariant': (s.outlineVariant, c.border),
        'inverseSurface': (s.inverseSurface, c.inverseSurface),
        'onInverseSurface': (s.onInverseSurface, c.onInverseSurface),
        'inversePrimary': (s.inversePrimary, c.inverseAccent),
        'scrim': (s.scrim, c.scrim),
        'surfaceTint': (s.surfaceTint, Colors.transparent),
      };
      for (final MapEntry(key: field, value: (actual, token))
          in expected.entries) {
        expect(actual, token, reason: '$name colorScheme.$field');
      }
      expect(
        s.shadow.toARGB32(),
        name == 'Light' ? 0xFF1C1B22 : 0xFF000000,
        reason: '$name shadow',
      );
    }
  });

  test('TC-002-17 secondary and tertiary scheme colours are the accent', () {
    for (final MapEntry(key: name, value: (theme, c, _)) in _built.entries) {
      final s = theme.colorScheme;
      expect(s.secondary, c.accent, reason: '$name secondary');
      expect(s.onSecondary, c.onAccent, reason: '$name onSecondary');
      expect(s.tertiary, c.accent, reason: '$name tertiary');
      expect(s.onTertiary, c.onAccent, reason: '$name onTertiary');
    }
  });

  test('TC-002-02 built themes carry their own tokens and settings', () {
    for (final MapEntry(key: name, value: (theme, c, brightness))
        in _built.entries) {
      expect(theme.useMaterial3, isTrue, reason: name);
      expect(theme.brightness, brightness, reason: name);
      expect(theme.scaffoldBackgroundColor, c.bg, reason: name);
      expect(theme.extension<BudgetColors>(), same(c), reason: name);
      expect(theme.extension<BudgetText>(), BudgetText.standard, reason: name);
      expect(
        theme.extension<BudgetElevation>(),
        name == 'Light' ? BudgetElevation.light : BudgetElevation.flat,
        reason: name,
      );
      expect(theme.splashFactory, InkRipple.splashFactory, reason: name);
      expect(
        theme.pageTransitionsTheme.builders[TargetPlatform.android],
        isA<FadeForwardsPageTransitionsBuilder>(),
        reason: name,
      );
      expect(theme.cardTheme.elevation, 0, reason: name);
      expect(theme.cardTheme.surfaceTintColor, Colors.transparent);
      expect(theme.appBarTheme.backgroundColor, c.bg, reason: name);
      expect(theme.appBarTheme.scrolledUnderElevation, 0, reason: name);
      expect(theme.bottomSheetTheme.showDragHandle, isTrue, reason: name);
      expect(theme.bottomSheetTheme.backgroundColor, c.surface, reason: name);
      expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
      expect(theme.snackBarTheme.backgroundColor, c.inverseSurface);
      expect(theme.dividerTheme.color, c.border, reason: name);
    }
    final backgrounds = {
      for (final (theme, _, _) in _built.values) theme.scaffoldBackgroundColor,
    };
    expect(backgrounds, hasLength(3));
  });

  test('TC-002-29 theme text styles use plex and headings use bricolage', () {
    for (final MapEntry(key: name, value: (theme, c, _)) in _built.entries) {
      final t = theme.textTheme;
      final headings = {
        'displaySmall': (t.displaySmall!, 32.0),
        'headlineSmall': (t.headlineSmall!, 26.0),
        'titleLarge': (t.titleLarge!, 20.0),
      };
      for (final MapEntry(key: slot, value: (style, size))
          in headings.entries) {
        expect(style.fontFamily, 'Bricolage', reason: '$name $slot');
        expect(style.fontSize, size, reason: '$name $slot');
        expect(style.color, c.textPrimary, reason: '$name $slot');
      }
      final body = {
        'bodyLarge': (t.bodyLarge!, 16.0),
        'bodyMedium': (t.bodyMedium!, 14.0),
        'bodySmall': (t.bodySmall!, 12.0),
        'labelLarge': (t.labelLarge!, 15.0),
        'labelMedium': (t.labelMedium!, 14.0),
      };
      for (final MapEntry(key: slot, value: (style, size)) in body.entries) {
        expect(style.fontFamily, 'Plex', reason: '$name $slot');
        expect(style.fontSize, size, reason: '$name $slot');
        expect(style.color, c.textPrimary, reason: '$name $slot');
      }
      // Slots the design does not name still use the bundled body family.
      for (final style in [
        t.displayLarge!,
        t.headlineMedium!,
        t.titleMedium!,
        t.titleSmall!,
        t.labelSmall!,
      ]) {
        expect(style.fontFamily, 'Plex', reason: '$name other slots');
      }
    }
  });

  test('TC-002-04 theme mapping never resolves auto to dim', () {
    final expected = {
      ThemeChoice.auto: (ThemeMode.system, budgetDarkTheme),
      ThemeChoice.light: (ThemeMode.light, budgetDarkTheme),
      ThemeChoice.dark: (ThemeMode.dark, budgetDarkTheme),
      ThemeChoice.dim: (ThemeMode.dark, budgetDimTheme),
    };
    for (final MapEntry(key: choice, value: (mode, dark)) in expected.entries) {
      final config = themeConfigFor(choice);
      expect(config.mode, mode, reason: choice.name);
      expect(config.light, same(budgetLightTheme), reason: choice.name);
      expect(config.dark, same(dark), reason: choice.name);
    }
  });

  testWidgets('TC-002-31 system bars style follows theme brightness', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    // Light, Dark, Dim, Auto + system light, Auto + system dark.
    final cases = [
      (ThemeChoice.light, Brightness.light, Brightness.dark),
      (ThemeChoice.dark, Brightness.light, Brightness.light),
      (ThemeChoice.dim, Brightness.light, Brightness.light),
      (ThemeChoice.auto, Brightness.light, Brightness.dark),
      (ThemeChoice.auto, Brightness.dark, Brightness.light),
    ];
    for (final (choice, system, icons) in cases) {
      tester.platformDispatcher.platformBrightnessTestValue = system;
      final config = themeConfigFor(choice);
      await tester.pumpWidget(
        MaterialApp(
          themeMode: config.mode,
          theme: config.light,
          darkTheme: config.dark,
          builder: (context, child) => SystemBarsStyle(child: child!),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      // Let MaterialApp's theme cross-fade from the previous case finish.
      await tester.pumpAndSettle();
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
      );
      final where = '${choice.name} under system ${system.name}';
      expect(region.value.statusBarIconBrightness, icons, reason: where);
      expect(
        region.value.systemNavigationBarIconBrightness,
        icons,
        reason: where,
      );
      expect(region.value.statusBarColor, Colors.transparent, reason: where);
      expect(
        region.value.systemNavigationBarColor,
        Colors.transparent,
        reason: where,
      );
    }
    expect(
      budgetDimTheme.appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
      Brightness.light,
    );
    expect(
      budgetLightTheme.appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
      Brightness.dark,
    );
  });
}
