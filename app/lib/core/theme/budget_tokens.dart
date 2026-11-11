import 'package:flutter/widgets.dart';

/// Spacing scale in dp, base 4 (design system §5.1).
abstract final class BudgetSpacing {
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;

  /// Screen side gutter.
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space7 = 32;
  static const double space8 = 40;
  static const double space9 = 56;

  /// Minimum touch target, even when the visible element is smaller.
  static const double touchTarget = 48;
}

/// Corner radii in dp (design system §5.2).
abstract final class BudgetRadii {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double full = 999;
}

/// Motion durations and curves (design system §5.4).
///
/// Use [BudgetMotion.of] in widgets: it returns [BudgetMotion.off] (every
/// duration zero) when the phone has "Remove animations" on.
@immutable
class BudgetMotion {
  const new({
    required this.fast,
    required this.base,
    required this.emphasis,
    required this.emphasisExit,
    required this.count,
  });

  static const full = BudgetMotion(
    fast: Duration(milliseconds: 120),
    base: Duration(milliseconds: 200),
    emphasis: Duration(milliseconds: 320),
    emphasisExit: Duration(milliseconds: 240),
    count: Duration(milliseconds: 600),
  );

  static const off = BudgetMotion(
    fast: Duration.zero,
    base: Duration.zero,
    emphasis: Duration.zero,
    emphasisExit: Duration.zero,
    count: Duration.zero,
  );

  static const Curve standard = Cubic(0.2, 0, 0, 1);
  static const Curve decelerate = Cubic(0.05, 0.7, 0.1, 1);
  static const Curve accelerate = Cubic(0.3, 0, 0.8, 0.15);

  /// The durations to use under [context]'s accessibility settings.
  static BudgetMotion of(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? off : full;

  final Duration fast;
  final Duration base;
  final Duration emphasis;
  final Duration emphasisExit;
  final Duration count;
}
