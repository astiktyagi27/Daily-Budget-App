import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/tap_cooldown.dart';
import 'package:flutter/material.dart';

/// One point of an explainer: a neutral line icon and its text.
typedef ExplainerPoint = ({IconData icon, String text});

/// A button of an explainer. `description` is shown under the button and
/// read as its hint; `hint` is a screen-reader hint with nothing shown.
typedef ExplainerAction = ({
  String label,
  String? description,
  String? hint,
  VoidCallback onPressed,
});

/// The shared layout of the SMS explainer, the notifications explainer and
/// the disclaimer (welcome-tour §3.1): icon circle, title, points, then the
/// button block. At text up to 1.3× the block is pinned at the bottom; above
/// that it moves to the end of the scrolling content (welcome-tour §9).
///
/// One step per tap (F-005 AC-13): a button fires only while its screen is
/// the top route, and not in the first double-tap interval after the screen
/// appears. A new screen takes taps while it slides in, so without the
/// second rule the second tap of a double tap on the previous screen would
/// land on this screen's button in the same place.
class ExplainerScaffold extends StatefulWidget {
  const new({
    required this.icon,
    required this.title,
    required this.points,
    required this.primary,
    this.secondary,
    super.key,
  });

  final IconData icon;
  final String title;
  final List<ExplainerPoint> points;
  final ExplainerAction primary;
  final ExplainerAction? secondary;

  /// Above this text scale the buttons scroll with the content.
  static const double pinnedMaxTextScale = 1.3;

  @override
  State<ExplainerScaffold> createState() => _ExplainerScaffoldState();
}

class _ExplainerScaffoldState extends State<ExplainerScaffold> {
  final _settling = TapCooldown();

  @override
  void initState() {
    super.initState();
    _settling.start();
  }

  @override
  void dispose() {
    _settling.dispose();
    super.dispose();
  }

  VoidCallback _guarded(VoidCallback action) => () {
    if (_settling.isActive) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    action();
  };

  @override
  Widget build(BuildContext context) {
    final pinned =
        MediaQuery.textScalerOf(context).scale(1) <=
        ExplainerScaffold.pinnedMaxTextScale;
    final content = _Content(
      icon: widget.icon,
      title: widget.title,
      points: widget.points,
    );
    final buttons = _ButtonBlock(
      primary: widget.primary,
      secondary: widget.secondary,
      guard: _guarded,
    );
    return Scaffold(
      body: SafeArea(
        child: pinned
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: SingleChildScrollView(child: content)),
                  buttons,
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [content, buttons],
                ),
              ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const new({required this.icon, required this.title, required this.points});

  final IconData icon;
  final String title;
  final List<ExplainerPoint> points;

  static const double circleSize = 56;
  static const double circleIconSize = 28;
  static const double pointIconSize = 20;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final pointStyle = BudgetTypeScale.bodyLarge.copyWith(
      color: colors.textPrimary,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BudgetSpacing.space5,
        BudgetSpacing.space9,
        BudgetSpacing.space5,
        BudgetSpacing.space5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: colors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: circleIconSize, color: colors.accent),
            ),
          ),
          const SizedBox(height: BudgetSpacing.space5),
          Semantics(
            header: true,
            child: Text(
              title,
              style: context.budgetText.displayHeadline.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          for (final (index, point) in points.indexed)
            Padding(
              padding: EdgeInsets.only(
                top: index == 0 ? BudgetSpacing.space5 : BudgetSpacing.space4,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    // Centres the icon on the first 24 dp line at 1.0.
                    padding: const EdgeInsets.only(top: 2),
                    child: ExcludeSemantics(
                      child: Icon(
                        point.icon,
                        size: pointIconSize,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: BudgetSpacing.space3),
                  Expanded(child: Text(point.text, style: pointStyle)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ButtonBlock extends StatelessWidget {
  const new({
    required this.primary,
    required this.secondary,
    required this.guard,
  });

  final ExplainerAction primary;
  final ExplainerAction? secondary;

  /// Wraps a button's action in the one-step-per-tap rule.
  final VoidCallback Function(VoidCallback action) guard;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final description = primary.description;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BudgetSpacing.space5,
        BudgetSpacing.space2,
        BudgetSpacing.space5,
        BudgetSpacing.space5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          BudgetButton.primary(
            label: primary.label,
            semanticsHint: description ?? primary.hint,
            onPressed: guard(primary.onPressed),
          ),
          if (description != null) ...[
            const SizedBox(height: BudgetSpacing.space2),
            // Read once, as the button's hint.
            ExcludeSemantics(
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: BudgetTypeScale.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
          if (secondary case final secondary?) ...[
            const SizedBox(height: BudgetSpacing.space3),
            BudgetButton.secondary(
              label: secondary.label,
              semanticsHint: secondary.description ?? secondary.hint,
              onPressed: guard(secondary.onPressed),
            ),
          ],
        ],
      ),
    );
  }
}
