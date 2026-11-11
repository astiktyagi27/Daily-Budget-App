import 'package:flutter/material.dart';

/// Shadows for the few things that really float (design system §5.3).
/// Dark and Dim have none: depth there comes from tone and hairlines.
@immutable
class BudgetElevation extends ThemeExtension<BudgetElevation> {
  const new({required this.float, required this.sheet});

  static const light = BudgetElevation(
    // 0 4 16, #1C1B22 at 8 %.
    float: [
      BoxShadow(color: Color(0x141C1B22), offset: Offset(0, 4), blurRadius: 16),
    ],
    // 0 -8 32, #1C1B22 at 12 %.
    sheet: [
      BoxShadow(
        color: Color(0x1F1C1B22),
        offset: Offset(0, -8),
        blurRadius: 32,
      ),
    ],
  );

  static const flat = BudgetElevation(float: [], sheet: []);

  /// Snackbar, tooltip.
  final List<BoxShadow> float;

  /// Bottom sheet.
  final List<BoxShadow> sheet;

  @override
  BudgetElevation copyWith({List<BoxShadow>? float, List<BoxShadow>? sheet}) {
    return BudgetElevation(
      float: float ?? this.float,
      sheet: sheet ?? this.sheet,
    );
  }

  @override
  BudgetElevation lerp(covariant BudgetElevation? other, double t) {
    if (other == null || t <= 0) return this;
    // lerpList towards an empty list ends in a transparent shadow, not an
    // empty list; the end of a theme change must be exactly the new theme.
    if (t >= 1) return other;
    return BudgetElevation(
      float: BoxShadow.lerpList(float, other.float, t) ?? const [],
      sheet: BoxShadow.lerpList(sheet, other.sheet, t) ?? const [],
    );
  }
}
