import 'dart:async';

import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/tap_cooldown.dart';
import 'package:flutter/material.dart';

/// Opens a modal bottom sheet in the app's style (design system §7.8): the
/// only way features open a sheet (help sheet, theme picker).
///
/// Natural height up to 90 % of the screen, over the theme's scrim. It
/// closes on swipe down, a tap on the scrim and back, as every modal route
/// does; [builder]'s content must add its own visible close button (D-031).
/// The scrim ignores taps until the sheet has opened and a double-tap
/// interval has passed.
Future<T?> showBudgetSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final motion = BudgetMotion.of(context);
  final navigator = Navigator.of(context);
  final localizations = MaterialLocalizations.of(context);
  return navigator.push(
    _BudgetSheetRoute<T>(
      builder: (context) => BudgetSheetFrame(child: builder(context)),
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      isScrollControlled: true,
      // Plain-language action, not the stock "Scrim" (design system §7.8).
      barrierLabel: 'Close',
      barrierOnTapHint: localizations.scrimOnTapHint(
        localizations.bottomSheetLabel,
      ),
      modalBarrierColor: Theme.of(context).bottomSheetTheme.modalBarrierColor,
      // BudgetSheetFrame draws the fill, the corners, the shadow and the drag
      // handle itself; the route's own Material stays invisible.
      backgroundColor: Colors.transparent,
      elevation: 0,
      showDragHandle: false,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      sheetAnimationStyle: motion.emphasis == Duration.zero
          ? AnimationStyle.noAnimation
          : AnimationStyle(
              duration: motion.emphasis,
              reverseDuration: motion.emphasisExit,
              curve: BudgetMotion.decelerate,
              reverseCurve: BudgetMotion.accelerate,
            ),
    ),
  );
}

class _BudgetSheetRoute<T> extends ModalBottomSheetRoute<T> {
  new({
    required super.builder,
    required super.capturedThemes,
    required super.isScrollControlled,
    required super.barrierLabel,
    required super.barrierOnTapHint,
    required super.modalBarrierColor,
    required super.backgroundColor,
    required super.elevation,
    required super.showDragHandle,
    required super.constraints,
    required super.sheetAnimationStyle,
  });

  /// Set once a double-tap interval has passed since the push.
  bool _doubleTapWindowOver = false;
  final _cooldown = TapCooldown();

  /// The scrim only closes a sheet that has finished opening **and** has
  /// been open for longer than a double tap, so the second tap of a double
  /// tap cannot close the sheet the first tap opened (help-pattern §3.2,
  /// D-031). The time part matters with Remove animations, where the sheet
  /// is fully open in the frame it is pushed. Got it and Back always close.
  @override
  bool get barrierDismissible =>
      _doubleTapWindowOver && (animation?.isCompleted ?? false);

  @override
  void install() {
    super.install();
    animation!.addStatusListener(_rebuildBarrier);
  }

  @override
  TickerFuture didPush() {
    _cooldown.start(
      onEnd: () {
        _doubleTapWindowOver = true;
        if (isActive) changedInternalState();
      },
    );
    return super.didPush();
  }

  @override
  void dispose() {
    _cooldown.dispose();
    animation?.removeStatusListener(_rebuildBarrier);
    super.dispose();
  }

  /// Rebuilds the scrim once [barrierDismissible] changes.
  void _rebuildBarrier(AnimationStatus status) {
    if (isActive) changedInternalState();
  }
}

/// The visible sheet: `surface` fill with `radiusXl` top corners, the
/// `BudgetElevation.sheet` shadow (Light only; Dark and Dim have none) and a
/// 32 × 4 dp drag handle 8 dp from the top.
class BudgetSheetFrame extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  static const radius = BorderRadius.vertical(
    top: Radius.circular(BudgetRadii.xl),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        boxShadow: context.budgetElevation.sheet,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: BudgetSpacing.space2),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderStrong,
                borderRadius: const BorderRadius.all(
                  Radius.circular(BudgetRadii.full),
                ),
              ),
            ),
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}
