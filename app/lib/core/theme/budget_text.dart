import 'package:flutter/material.dart';

/// Font family for headings (bundled, design system §4.1).
const kFontHeading = 'Bricolage';

/// Font family for everything else, including all money (design system §4.1).
const kFontBody = 'Plex';

const _tabular = [FontFeature.tabularFigures()];

/// The type scale of design system §4.2. Sizes are in sp; `height` is the
/// line height divided by the size. No colours: text takes its colour from
/// the theme.
abstract final class BudgetTypeScale {
  static const displayHeadline = TextStyle(
    fontFamily: kFontHeading,
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 38 / 32,
    letterSpacing: -0.5,
  );
  static const headline = TextStyle(
    fontFamily: kFontHeading,
    fontWeight: FontWeight.w700,
    fontSize: 26,
    height: 32 / 26,
    letterSpacing: -0.3,
  );
  static const title = TextStyle(
    fontFamily: kFontHeading,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 26 / 20,
    letterSpacing: -0.2,
  );
  static const moneyHero = TextStyle(
    fontFamily: kFontBody,
    fontWeight: FontWeight.w600,
    fontSize: 40,
    height: 46 / 40,
    letterSpacing: -0.8,
    fontFeatures: _tabular,
  );
  static const moneyLarge = TextStyle(
    fontFamily: kFontBody,
    fontWeight: FontWeight.w600,
    fontSize: 28,
    height: 34 / 28,
    letterSpacing: -0.4,
    fontFeatures: _tabular,
  );
  static const moneyMedium = TextStyle(
    fontFamily: kFontBody,
    fontWeight: FontWeight.w500,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: 0,
    fontFeatures: _tabular,
  );
  static const moneySmall = TextStyle(
    fontFamily: kFontBody,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0,
    fontFeatures: _tabular,
  );
  static const bodyLarge = TextStyle(
    fontFamily: kFontBody,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 0,
  );
  static const body = TextStyle(
    fontFamily: kFontBody,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0.1,
  );
  static const label = TextStyle(
    fontFamily: kFontBody,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0.1,
  );
  static const button = TextStyle(
    fontFamily: kFontBody,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 20 / 15,
    letterSpacing: 0.2,
  );
  static const caption = TextStyle(
    fontFamily: kFontBody,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.2,
  );
}

/// The text styles `TextTheme` cannot hold: money and headings
/// (design system §8.4). Read with `context.budgetText`.
@immutable
class BudgetText extends ThemeExtension<BudgetText> {
  const new({
    required this.moneyHero,
    required this.moneyLarge,
    required this.moneyMedium,
    required this.moneySmall,
    required this.displayHeadline,
    required this.headline,
    required this.title,
  });

  /// The same styles in every theme.
  static const standard = BudgetText(
    moneyHero: BudgetTypeScale.moneyHero,
    moneyLarge: BudgetTypeScale.moneyLarge,
    moneyMedium: BudgetTypeScale.moneyMedium,
    moneySmall: BudgetTypeScale.moneySmall,
    displayHeadline: BudgetTypeScale.displayHeadline,
    headline: BudgetTypeScale.headline,
    title: BudgetTypeScale.title,
  );

  final TextStyle moneyHero;
  final TextStyle moneyLarge;
  final TextStyle moneyMedium;
  final TextStyle moneySmall;
  final TextStyle displayHeadline;
  final TextStyle headline;
  final TextStyle title;

  @override
  BudgetText copyWith({
    TextStyle? moneyHero,
    TextStyle? moneyLarge,
    TextStyle? moneyMedium,
    TextStyle? moneySmall,
    TextStyle? displayHeadline,
    TextStyle? headline,
    TextStyle? title,
  }) {
    return BudgetText(
      moneyHero: moneyHero ?? this.moneyHero,
      moneyLarge: moneyLarge ?? this.moneyLarge,
      moneyMedium: moneyMedium ?? this.moneyMedium,
      moneySmall: moneySmall ?? this.moneySmall,
      displayHeadline: displayHeadline ?? this.displayHeadline,
      headline: headline ?? this.headline,
      title: title ?? this.title,
    );
  }

  @override
  BudgetText lerp(covariant BudgetText? other, double t) {
    if (other == null) return this;
    TextStyle mix(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return BudgetText(
      moneyHero: mix(moneyHero, other.moneyHero),
      moneyLarge: mix(moneyLarge, other.moneyLarge),
      moneyMedium: mix(moneyMedium, other.moneyMedium),
      moneySmall: mix(moneySmall, other.moneySmall),
      displayHeadline: mix(displayHeadline, other.displayHeadline),
      headline: mix(headline, other.headline),
      title: mix(title, other.title),
    );
  }
}
