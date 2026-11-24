import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// A ranked row for "where the money went" (design system section 7.16).
///
/// Line 1: the [name] on the left, the [amount] and the [share] text on the
/// right (the share in a fixed 40 dp column). Line 2: a 6 dp bar whose length
/// is the exact share of the total, [barPermille] thousandths of the track
/// (at least 2 dp when above 0), in ink on a `neutralSoft` track. Never green,
/// red or accent: a share is neither good nor bad.
///
/// Above 1.3x text the first line stacks: the name alone, then the amount and
/// the share; the bar stays full width. The bar is decorative and left out of
/// the semantics tree; the row reads as [semanticsLabel].
class ShareBarRow extends StatelessWidget {
  const new({
    required this.name,
    required this.amount,
    required this.share,
    required this.barPermille,
    required this.semanticsLabel,
    super.key,
  });

  final String name;

  /// The amount already formatted (`₹1,000`).
  final String amount;

  /// The share text: `18%` or `<1%`.
  final String share;

  /// The bar length in thousandths of the track, 0 to 1000.
  final int barPermille;

  final String semanticsLabel;

  /// Tests find the bar by this key.
  static const barKey = Key('shareBar');

  static const double barHeight = 6;
  static const double minBarWidth = 2;
  static const double _shareColumn = 40;
  static const double _stackAbove = 1.3;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final text = context.budgetText;
    final stacked = MediaQuery.textScalerOf(context).scale(1) > _stackAbove;

    final nameText = Text(
      name,
      style: BudgetTypeScale.label.copyWith(color: colors.textPrimary),
    );
    final amountText = Text(
      amount,
      style: text.moneyMedium.copyWith(color: colors.textPrimary),
    );
    final shareText = SizedBox(
      width: _shareColumn,
      child: Text(
        share,
        textAlign: TextAlign.right,
        style: BudgetTypeScale.caption.copyWith(
          fontWeight: FontWeight.w500,
          color: colors.textSecondary,
        ),
      ),
    );

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stacked) ...[
              nameText,
              const SizedBox(height: BudgetSpacing.space1),
              Row(
                children: [
                  Expanded(child: amountText),
                  const SizedBox(width: BudgetSpacing.space2),
                  shareText,
                ],
              ),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(child: nameText),
                  const SizedBox(width: BudgetSpacing.space2),
                  amountText,
                  const SizedBox(width: BudgetSpacing.space2),
                  shareText,
                ],
              ),
            const SizedBox(height: BudgetSpacing.space2),
            _Bar(permille: barPermille),
          ],
        ),
      ),
    );
  }
}

/// The bar: grows from 0 to its length over `motionBase` (at once with
/// Remove animations).
class _Bar extends StatelessWidget {
  const new({required this.permille});

  final int permille;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final motion = BudgetMotion.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final track = constraints.maxWidth;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.neutralSoft,
            borderRadius: BorderRadius.circular(BudgetRadii.full),
          ),
          child: SizedBox(
            height: ShareBarRow.barHeight,
            width: double.infinity,
            child: Align(
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: _length(track)),
                duration: motion.base,
                curve: BudgetMotion.standard,
                builder: (context, width, _) => Container(
                  key: ShareBarRow.barKey,
                  width: width,
                  height: ShareBarRow.barHeight,
                  decoration: BoxDecoration(
                    color: colors.textPrimary,
                    borderRadius: BorderRadius.circular(BudgetRadii.full),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Layout only: a fraction of the track from integer thousandths. Never
  /// shown as money.
  double _length(double track) {
    if (permille <= 0) return 0;
    final width = track * permille / 1000;
    return width < ShareBarRow.minBarWidth ? ShareBarRow.minBarWidth : width;
  }
}
