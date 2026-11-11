import 'package:flutter/material.dart';

/// The colour tokens of the "Neel Khata" design system (design system §2).
///
/// Token names are the same in every theme; only the set changes. Widgets
/// read them with `context.budgetColors` and never use raw colours.
@immutable
class BudgetColors extends ThemeExtension<BudgetColors> {
  const new({
    required this.bg,
    required this.surface,
    required this.sunken,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.saved,
    required this.savedSoft,
    required this.overspent,
    required this.overspentSoft,
    required this.neutral,
    required this.neutralSoft,
    required this.border,
    required this.borderStrong,
    required this.focus,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.inverseAccent,
    required this.scrim,
    required this.onError,
  });

  /// Light, "Paper".
  static const light = BudgetColors(
    bg: Color(0xFFF6F3ED),
    surface: Color(0xFFFFFDF8),
    sunken: Color(0xFFEEEAE2),
    textPrimary: Color(0xFF1C1B22),
    textSecondary: Color(0xFF5C5864),
    accent: Color(0xFF3A3DB0),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFE7E6F6),
    saved: Color(0xFF1A7044),
    savedSoft: Color(0xFFDDEFE3),
    overspent: Color(0xFFB4372F),
    overspentSoft: Color(0xFFF6E0DC),
    neutral: Color(0xFF68646E),
    neutralSoft: Color(0xFFEAE6DF),
    border: Color(0xFFDED8CD),
    borderStrong: Color(0xFF8A8377),
    focus: Color(0xFF3A3DB0),
    inverseSurface: Color(0xFF1C1B22),
    onInverseSurface: Color(0xFFF2F0EA),
    inverseAccent: Color(0xFFABACF6),
    // #1C1B22 at 40 %.
    scrim: Color(0x661C1B22),
    onError: Color(0xFFFFFFFF),
  );

  /// Dark, "Ink".
  static const dark = BudgetColors(
    bg: Color(0xFF0E0E12),
    surface: Color(0xFF17171D),
    sunken: Color(0xFF0A0A0D),
    textPrimary: Color(0xFFF2F0EA),
    textSecondary: Color(0xFFA8A5B1),
    accent: Color(0xFF9C9FFF),
    onAccent: Color(0xFF14143D),
    accentSoft: Color(0xFF25264A),
    saved: Color(0xFF52C98B),
    savedSoft: Color(0xFF16301F),
    overspent: Color(0xFFFF7B6F),
    overspentSoft: Color(0xFF3A1A17),
    neutral: Color(0xFF9F9CA7),
    neutralSoft: Color(0xFF24242B),
    border: Color(0xFF2A2A33),
    borderStrong: Color(0xFF6A6876),
    focus: Color(0xFFBDBFFF),
    inverseSurface: Color(0xFFEEE9E0),
    onInverseSurface: Color(0xFF1C1B22),
    inverseAccent: Color(0xFF3A3DB0),
    // #000000 at 60 %.
    scrim: Color(0x99000000),
    onError: Color(0xFF1C1B22),
  );

  /// Dim, "Slate".
  static const dim = BudgetColors(
    bg: Color(0xFF2A2825),
    surface: Color(0xFF34312D),
    sunken: Color(0xFF24221F),
    textPrimary: Color(0xFFEEE9E0),
    textSecondary: Color(0xFFBEB7AB),
    accent: Color(0xFFABACF6),
    onAccent: Color(0xFF1B1B3D),
    accentSoft: Color(0xFF3E3D55),
    saved: Color(0xFF80D3A1),
    savedSoft: Color(0xFF2F3F33),
    overspent: Color(0xFFFF9C8E),
    overspentSoft: Color(0xFF4A3230),
    neutral: Color(0xFFB6AFA4),
    neutralSoft: Color(0xFF3D3A35),
    border: Color(0xFF48453F),
    borderStrong: Color(0xFF878073),
    focus: Color(0xFFC6C7FF),
    inverseSurface: Color(0xFFEEE9E0),
    onInverseSurface: Color(0xFF1C1B22),
    inverseAccent: Color(0xFF3A3DB0),
    // #000000 at 50 %.
    scrim: Color(0x80000000),
    onError: Color(0xFF1C1B22),
  );

  final Color bg;
  final Color surface;
  final Color sunken;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color saved;
  final Color savedSoft;
  final Color overspent;
  final Color overspentSoft;
  final Color neutral;
  final Color neutralSoft;
  final Color border;
  final Color borderStrong;
  final Color focus;
  final Color inverseSurface;
  final Color onInverseSurface;
  final Color inverseAccent;
  final Color scrim;

  /// Text on a filled `overspent` (error) background (design system §3 note).
  final Color onError;

  @override
  BudgetColors copyWith({
    Color? bg,
    Color? surface,
    Color? sunken,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? saved,
    Color? savedSoft,
    Color? overspent,
    Color? overspentSoft,
    Color? neutral,
    Color? neutralSoft,
    Color? border,
    Color? borderStrong,
    Color? focus,
    Color? inverseSurface,
    Color? onInverseSurface,
    Color? inverseAccent,
    Color? scrim,
    Color? onError,
  }) {
    return BudgetColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      sunken: sunken ?? this.sunken,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentSoft: accentSoft ?? this.accentSoft,
      saved: saved ?? this.saved,
      savedSoft: savedSoft ?? this.savedSoft,
      overspent: overspent ?? this.overspent,
      overspentSoft: overspentSoft ?? this.overspentSoft,
      neutral: neutral ?? this.neutral,
      neutralSoft: neutralSoft ?? this.neutralSoft,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      focus: focus ?? this.focus,
      inverseSurface: inverseSurface ?? this.inverseSurface,
      onInverseSurface: onInverseSurface ?? this.onInverseSurface,
      inverseAccent: inverseAccent ?? this.inverseAccent,
      scrim: scrim ?? this.scrim,
      onError: onError ?? this.onError,
    );
  }

  @override
  BudgetColors lerp(covariant BudgetColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return BudgetColors(
      bg: mix(bg, other.bg),
      surface: mix(surface, other.surface),
      sunken: mix(sunken, other.sunken),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      accentSoft: mix(accentSoft, other.accentSoft),
      saved: mix(saved, other.saved),
      savedSoft: mix(savedSoft, other.savedSoft),
      overspent: mix(overspent, other.overspent),
      overspentSoft: mix(overspentSoft, other.overspentSoft),
      neutral: mix(neutral, other.neutral),
      neutralSoft: mix(neutralSoft, other.neutralSoft),
      border: mix(border, other.border),
      borderStrong: mix(borderStrong, other.borderStrong),
      focus: mix(focus, other.focus),
      inverseSurface: mix(inverseSurface, other.inverseSurface),
      onInverseSurface: mix(onInverseSurface, other.onInverseSurface),
      inverseAccent: mix(inverseAccent, other.inverseAccent),
      scrim: mix(scrim, other.scrim),
      onError: mix(onError, other.onError),
    );
  }
}
