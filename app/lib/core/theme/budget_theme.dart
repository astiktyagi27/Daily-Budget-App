import 'package:daily_budget/core/theme/budget_colors.dart';
import 'package:daily_budget/core/theme/budget_elevation.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/system_bars.dart';
import 'package:daily_budget/domain/preferences/theme_choice.dart';
import 'package:flutter/material.dart';

/// The three built themes (design system §8).
final ThemeData budgetLightTheme = buildBudgetTheme(
  BudgetColors.light,
  Brightness.light,
);
final ThemeData budgetDarkTheme = buildBudgetTheme(
  BudgetColors.dark,
  Brightness.dark,
);
final ThemeData budgetDimTheme = buildBudgetTheme(
  BudgetColors.dim,
  Brightness.dark,
);

/// What `MaterialApp` gets for a [ThemeChoice] (design system §8.1). Both
/// themes are always filled; only the mode and the dark theme change, so
/// Auto can never resolve to Dim.
({ThemeMode mode, ThemeData light, ThemeData dark}) themeConfigFor(
  ThemeChoice choice,
) => switch (choice) {
  ThemeChoice.auto => (
    mode: ThemeMode.system,
    light: budgetLightTheme,
    dark: budgetDarkTheme,
  ),
  ThemeChoice.light => (
    mode: ThemeMode.light,
    light: budgetLightTheme,
    dark: budgetDarkTheme,
  ),
  ThemeChoice.dark => (
    mode: ThemeMode.dark,
    light: budgetLightTheme,
    dark: budgetDarkTheme,
  ),
  ThemeChoice.dim => (
    mode: ThemeMode.dark,
    light: budgetLightTheme,
    dark: budgetDimTheme,
  ),
};

/// Builds a full [ThemeData] from one token set (design system §8.2, §8.3).
ThemeData buildBudgetTheme(BudgetColors c, Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    primaryContainer: c.accentSoft,
    onPrimaryContainer: c.textPrimary,
    secondary: c.accent,
    onSecondary: c.onAccent,
    secondaryContainer: c.accentSoft,
    onSecondaryContainer: c.textPrimary,
    tertiary: c.accent,
    onTertiary: c.onAccent,
    tertiaryContainer: c.accentSoft,
    onTertiaryContainer: c.textPrimary,
    error: c.overspent,
    onError: c.onError,
    errorContainer: c.overspentSoft,
    onErrorContainer: c.textPrimary,
    surface: c.surface,
    onSurface: c.textPrimary,
    onSurfaceVariant: c.textSecondary,
    surfaceContainerLowest: c.surface,
    surfaceContainerLow: c.bg,
    surfaceContainer: c.bg,
    surfaceContainerHigh: c.sunken,
    surfaceContainerHighest: c.sunken,
    outline: c.borderStrong,
    outlineVariant: c.border,
    inverseSurface: c.inverseSurface,
    onInverseSurface: c.onInverseSurface,
    inversePrimary: c.inverseAccent,
    scrim: c.scrim,
    shadow: isLight ? const Color(0xFF1C1B22) : const Color(0xFF000000),
    surfaceTint: Colors.transparent,
  );

  // Passing fontFamily to ThemeData applies Plex to every text style; the
  // heading slots are then set to Bricolage below via copyWith, which does
  // not re-apply the family.
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: kFontBody,
  );
  TextStyle slot(TextStyle? material, TextStyle ours) =>
      (material ?? const TextStyle()).merge(ours);
  final textTheme = base.textTheme
      .copyWith(
        displaySmall: slot(
          base.textTheme.displaySmall,
          BudgetTypeScale.displayHeadline,
        ),
        headlineSmall: slot(
          base.textTheme.headlineSmall,
          BudgetTypeScale.headline,
        ),
        titleLarge: slot(base.textTheme.titleLarge, BudgetTypeScale.title),
        bodyLarge: slot(base.textTheme.bodyLarge, BudgetTypeScale.bodyLarge),
        bodyMedium: slot(base.textTheme.bodyMedium, BudgetTypeScale.body),
        bodySmall: slot(base.textTheme.bodySmall, BudgetTypeScale.caption),
        labelLarge: slot(base.textTheme.labelLarge, BudgetTypeScale.button),
        labelMedium: slot(base.textTheme.labelMedium, BudgetTypeScale.label),
      )
      .apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);

  final pressedOverlay = isLight
      ? c.textPrimary.withValues(alpha: 0.08)
      : const Color(0xFFFFFFFF).withValues(alpha: 0.10);
  final overlay = WidgetStateProperty<Color?>.fromMap({
    WidgetState.pressed: pressedOverlay,
    WidgetState.any: Colors.transparent,
  });
  const buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(BudgetRadii.md)),
  );
  const fieldRadius = BorderRadius.all(Radius.circular(BudgetRadii.md));
  final systemBars = systemBarsStyleFor(brightness);

  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    textTheme: textTheme,
    splashFactory: InkRipple.splashFactory,
    dividerColor: c.border,
    extensions: [
      c,
      BudgetText.standard,
      if (isLight) BudgetElevation.light else BudgetElevation.flat,
    ],
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(
          backgroundColor: c.bg,
        ),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: BudgetTypeScale.headline.copyWith(color: c.textPrimary),
      systemOverlayStyle: systemBars,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.fromMap({
          WidgetState.disabled: c.neutralSoft,
          WidgetState.any: c.accent,
        }),
        foregroundColor: WidgetStateProperty.fromMap({
          WidgetState.disabled: c.textSecondary,
          WidgetState.any: c.onAccent,
        }),
        overlayColor: overlay,
        textStyle: const WidgetStatePropertyAll(BudgetTypeScale.button),
        minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: BudgetSpacing.space5),
        ),
        shape: const WidgetStatePropertyAll(buttonShape),
        elevation: const WidgetStatePropertyAll(0),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.fromMap({
          WidgetState.disabled: c.neutralSoft,
          WidgetState.any: c.surface,
        }),
        foregroundColor: WidgetStateProperty.fromMap({
          WidgetState.disabled: c.textSecondary,
          WidgetState.any: c.textPrimary,
        }),
        side: WidgetStateProperty.fromMap({
          WidgetState.disabled: BorderSide.none,
          WidgetState.any: BorderSide(color: c.borderStrong),
        }),
        overlayColor: overlay,
        textStyle: const WidgetStatePropertyAll(BudgetTypeScale.button),
        minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: BudgetSpacing.space5),
        ),
        shape: const WidgetStatePropertyAll(buttonShape),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.fromMap({
          WidgetState.disabled: c.textSecondary,
          WidgetState.any: c.accent,
        }),
        overlayColor: overlay,
        textStyle: const WidgetStatePropertyAll(BudgetTypeScale.button),
        minimumSize: const WidgetStatePropertyAll(
          Size(BudgetSpacing.touchTarget, BudgetSpacing.touchTarget),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: BudgetSpacing.space3),
        ),
        shape: const WidgetStatePropertyAll(buttonShape),
      ),
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(BudgetRadii.lg)),
        side: BorderSide(color: c.border),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: c.sunken,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: BudgetSpacing.space4,
        vertical: BudgetSpacing.space4,
      ),
      hintStyle: BudgetTypeScale.bodyLarge.copyWith(color: c.textSecondary),
      prefixStyle: BudgetTypeScale.moneyMedium.copyWith(color: c.textSecondary),
      errorStyle: BudgetTypeScale.body.copyWith(color: c.overspent),
      border: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: BorderSide(color: c.borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: BorderSide(color: c.borderStrong),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: BorderSide(color: c.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: BorderSide(color: c.overspent, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: BorderSide(color: c.overspent, width: 2),
      ),
    ),
    listTileTheme: ListTileThemeData(
      textColor: c.textPrimary,
      iconColor: c.neutral,
      titleTextStyle: BudgetTypeScale.label.copyWith(color: c.textPrimary),
      subtitleTextStyle: BudgetTypeScale.body.copyWith(color: c.textSecondary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: BudgetSpacing.space5,
      ),
      minTileHeight: 56,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      modalBackgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: c.scrim,
      elevation: 0,
      modalElevation: 0,
      showDragHandle: true,
      dragHandleColor: c.borderStrong,
      dragHandleSize: const Size(32, 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BudgetRadii.xl),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.inverseSurface,
      contentTextStyle: BudgetTypeScale.body.copyWith(
        color: c.onInverseSurface,
      ),
      actionTextColor: c.inverseAccent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(BudgetRadii.sm)),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: c.inverseSurface,
        borderRadius: const BorderRadius.all(Radius.circular(BudgetRadii.sm)),
        boxShadow: isLight
            ? BudgetElevation.light.float
            : BudgetElevation.flat.float,
      ),
      textStyle: BudgetTypeScale.body.copyWith(color: c.onInverseSurface),
      constraints: const BoxConstraints(maxWidth: 280),
    ),
    dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: c.surface,
      headerForegroundColor: c.textPrimary,
      headerHeadlineStyle: BudgetTypeScale.title.copyWith(color: c.textPrimary),
      headerHelpStyle: BudgetTypeScale.label.copyWith(color: c.textSecondary),
      dayForegroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? c.onAccent
            : states.contains(WidgetState.disabled)
            ? c.textSecondary.withValues(alpha: 0.5)
            : c.textPrimary,
      ),
      dayBackgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? c.accent : null,
      ),
      todayForegroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? c.onAccent : c.textPrimary,
      ),
      todayBorder: BorderSide(color: c.accent),
      weekdayStyle: BudgetTypeScale.caption.copyWith(color: c.textSecondary),
      cancelButtonStyle: TextButton.styleFrom(foregroundColor: c.accent),
      confirmButtonStyle: TextButton.styleFrom(foregroundColor: c.accent),
    ),
  );
}
