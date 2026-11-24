import 'dart:async';

import 'package:daily_budget/core/copy/help_copy.dart';
import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/core/help/hint_seen_provider.dart';
import 'package:daily_budget/core/help/nav_tooltip.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The first-time hint of one tab (F-004 AC-7…AC-10), for the `hint` slot of
/// a tab page: the card until it is dismissed, then nothing. The card sits
/// inside the page, so it never blocks anything (help-pattern §4).
class FirstTimeHint extends ConsumerStatefulWidget {
  const new({required this.id, super.key});

  final HintId id;

  /// The tip for each tab (F-004 §5).
  static String textFor(HintId id) => switch (id) {
    HintId.home => HelpCopy.hintHome,
    HintId.dashboard => HelpCopy.hintDashboard,
    HintId.transactions => HelpCopy.hintTransactions,
    HintId.settings => HelpCopy.hintSettings,
    HintId.calendar => HelpCopy.hintCalendar,
  };

  @override
  ConsumerState<FirstTimeHint> createState() => _FirstTimeHintState();
}

class _FirstTimeHintState extends ConsumerState<FirstTimeHint> {
  /// Groups the card's two buttons; never focused itself.
  final _cardFocus = FocusNode(
    debugLabel: 'FirstTimeHint',
    skipTraversal: true,
    canRequestFocus: false,
  );

  @override
  void dispose() {
    _cardFocus.dispose();
    super.dispose();
  }

  void _dismiss() {
    _moveFocusPastCard();
    unawaited(ref.read(hintSeenProvider(widget.id).notifier).dismiss());
  }

  /// Help-pattern §4.3: after a dismissal, keyboard and screen-reader focus
  /// move to the first item after where the card was. Only when focus is in
  /// the card (keyboard) or a screen reader is on; a finger tap moves
  /// nothing.
  void _moveFocusPastCard() {
    final inCard = _cardFocus.traversalDescendants.toList();
    if (inCard.isEmpty) return;
    if (!_cardFocus.hasFocus && !MediaQuery.accessibleNavigationOf(context)) {
      return;
    }
    final manager = FocusManager.instance;
    var node = _cardFocus.hasFocus ? manager.primaryFocus! : inCard.first;
    // Step through the card's own buttons until focus leaves it.
    for (var i = 0; i <= inCard.length; i++) {
      if (!node.nextFocus()) return;
      manager.applyFocusChangesIfNeeded();
      final next = manager.primaryFocus;
      if (next == null || identical(next, node)) return;
      if (!inCard.contains(next)) {
        next.context?.findRenderObject()?.sendSemanticsEvent(
          const FocusSemanticEvent(),
        );
        return;
      }
      node = next;
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.id;
    final seen = ref.watch(hintSeenProvider(id));
    // Collapses (height to 0 and fade) over motionEmphasis; instant with
    // Remove animations (help-pattern §4.3).
    return AnimatedSwitcher(
      duration: BudgetMotion.of(context).emphasis,
      switchInCurve: BudgetMotion.decelerate,
      switchOutCurve: BudgetMotion.decelerate,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: Alignment.topCenter,
        child: FadeTransition(opacity: animation, child: child),
      ),
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.passthrough,
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      child: seen
          ? const SizedBox(width: double.infinity)
          : Focus(
              key: ValueKey(id),
              focusNode: _cardFocus,
              includeSemantics: false,
              child: FirstTimeHintCard(
                text: FirstTimeHint.textFor(id),
                onDismiss: _dismiss,
              ),
            ),
    );
  }
}

/// The hint card (help-pattern §4.1): `accentSoft`, a lightbulb and the
/// `Tip` overline, a × in the corner, the tip, and a **Got it** text button.
///
/// A screen reader reads the card as one item, `Tip. <text>`, followed by
/// its two buttons.
class FirstTimeHintCard extends StatelessWidget {
  const new({required this.text, required this.onDismiss, super.key});

  final String text;
  final VoidCallback onDismiss;

  /// The × target's offset from the card's top-right corner: its icon is
  /// centred on the `Tip` line (16 dp padding + half the 20 dp line).
  static const double _closeInset = 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BudgetSpacing.space5,
        0,
        BudgetSpacing.space5,
        BudgetSpacing.space4,
      ),
      // One container for the card; inside it the tip reads as one item,
      // followed by its two buttons.
      child: Semantics(
        container: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.accentSoft,
            borderRadius: const BorderRadius.all(
              Radius.circular(BudgetRadii.md),
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(BudgetSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      container: true,
                      label: '${ScreenCopy.hintOverline}. $text',
                      child: ExcludeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              // Keeps the overline clear of the × target.
                              padding: const EdgeInsets.only(
                                right: BudgetSpacing.touchTarget - _closeInset,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    size: 20,
                                    color: colors.accent,
                                  ),
                                  const SizedBox(width: BudgetSpacing.space2),
                                  Flexible(
                                    child: Text(
                                      ScreenCopy.hintOverline,
                                      style: BudgetTypeScale.label.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colors.accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: BudgetSpacing.space2),
                            Text(
                              text,
                              style: BudgetTypeScale.body.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: BudgetSpacing.space2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: BudgetButton.text(
                        label: ScreenCopy.gotIt,
                        semanticsHint: HelpCopy.hintGotItHint,
                        onPressed: onDismiss,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: _closeInset,
                right: _closeInset,
                child: _CloseButton(onPressed: onDismiss),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The ×: a 20 dp `close` icon in a 48 dp target, with the long-press
/// tooltip and screen-reader label `Dismiss tip`.
class _CloseButton extends StatelessWidget {
  const new({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: HelpCopy.hintDismissTooltip,
      showDuration: NavTooltip.showDuration,
      // The label below already carries the text for screen readers.
      excludeFromSemantics: true,
      child: Semantics(
        container: true,
        button: true,
        label: HelpCopy.hintDismissTooltip,
        child: InkResponse(
          onTap: onPressed,
          radius: 20,
          child: SizedBox.square(
            dimension: BudgetSpacing.touchTarget,
            child: Center(
              child: Icon(
                Icons.close,
                size: 20,
                color: context.budgetColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
