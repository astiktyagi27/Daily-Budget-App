import 'dart:math' as math;

import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:flutter/material.dart';

/// The decorative card at the top of a tour slide (welcome-tour §2.1, §9):
/// built from design-system parts, about 200 dp tall, at most 160 dp above
/// 1.3× text. Its own text is capped at 1.3× and the content shrinks to fit,
/// because the slide body repeats every fact. Excluded from semantics.
class TourVisualCard extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  static const double height = 200;
  static const double largeTextHeight = 160;
  static const double maxTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > maxTextScale;
    return ExcludeSemantics(
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: maxTextScale,
        child: SizedBox(
          height: largeText ? largeTextHeight : height,
          child: BudgetCard(
            padding: const EdgeInsets.all(BudgetSpacing.space5),
            child: LayoutBuilder(
              builder: (context, constraints) => FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(width: constraints.maxWidth, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Slide 1: a today card with ₹830 and an empty progress rule.
class TodayVisual extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          ScreenCopy.visualTodayOverline,
          style: BudgetTypeScale.label.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: BudgetSpacing.space2),
        Text(
          ScreenCopy.visualTodayAmount,
          style: context.budgetText.moneyHero.copyWith(
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: BudgetSpacing.space4),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: colors.neutralSoft,
            borderRadius: BorderRadius.circular(BudgetRadii.full),
          ),
        ),
      ],
    );
  }
}

/// Slide 2: the worked example as a ledger.
class LedgerVisual extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _LedgerLine(
          ScreenCopy.visualSalary,
          ScreenCopy.visualSalaryAmount,
        ),
        const _LedgerLine(ScreenCopy.visualRent, ScreenCopy.visualRentAmount),
        const _LedgerLine(ScreenCopy.visualEmi, ScreenCopy.visualEmiAmount),
        const _LedgerLine(
          ScreenCopy.visualSubscription,
          ScreenCopy.visualSubscriptionAmount,
        ),
        Divider(
          height: BudgetSpacing.space3,
          thickness: 1,
          color: colors.border,
        ),
        const _LedgerLine(
          ScreenCopy.visualToSpend,
          ScreenCopy.visualToSpendAmount,
        ),
        const _LedgerLine(ScreenCopy.visualDays, null),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            ScreenCopy.visualPerDay,
            style: context.budgetText.moneyLarge.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _LedgerLine extends StatelessWidget {
  const new(this.label, this.amount);

  final String label;
  final String? amount;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BudgetSpacing.space1 / 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: BudgetTypeScale.body.copyWith(color: colors.textSecondary),
            ),
          ),
          if (amount case final amount?)
            Text(
              amount,
              style: context.budgetText.moneyMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Slide 3: three calendar day cells (saved, on budget, overspent) and the
/// savings pot. Green and red only for their meanings, each with its mark.
class SavingsVisual extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _DayCell(
                day: ScreenCopy.visualSavedDay,
                amount: ScreenCopy.visualSavedAmount,
                label: ScreenCopy.visualSavedLabel,
                mark: _DayMark.saved,
              ),
            ),
            SizedBox(width: BudgetSpacing.space3),
            Expanded(
              child: _DayCell(
                day: ScreenCopy.visualOnBudgetDay,
                amount: ScreenCopy.visualOnBudgetAmount,
                label: ScreenCopy.visualOnBudgetLabel,
                mark: _DayMark.onBudget,
              ),
            ),
            SizedBox(width: BudgetSpacing.space3),
            Expanded(
              child: _DayCell(
                day: ScreenCopy.visualOverspentDay,
                amount: ScreenCopy.visualOverspentAmount,
                label: ScreenCopy.visualOverspentLabel,
                mark: _DayMark.overspent,
              ),
            ),
          ],
        ),
        Divider(
          height: BudgetSpacing.space5,
          thickness: 1,
          color: colors.border,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                ScreenCopy.visualSavingsPot,
                style: BudgetTypeScale.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            const _MarkShape(_DayMark.saved),
            const SizedBox(width: BudgetSpacing.space2),
            Text(
              ScreenCopy.visualSavingsPotAmount,
              style: context.budgetText.moneyMedium.copyWith(
                color: colors.saved,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _DayMark { saved, onBudget, overspent }

/// A day cell as in design system §7.5: square, at most [maxSize] wide.
/// Its texts shrink rather than overflow, since the card is decorative.
class _DayCell extends StatelessWidget {
  const new({
    required this.day,
    required this.amount,
    required this.label,
    required this.mark,
  });

  final String day;
  final String amount;
  final String label;
  final _DayMark mark;

  static const double maxSize = 72;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final (fill, ink) = switch (mark) {
      _DayMark.saved => (colors.savedSoft, colors.saved),
      _DayMark.onBudget => (colors.neutralSoft, colors.neutral),
      _DayMark.overspent => (colors.overspentSoft, colors.overspent),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxSize),
          child: AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(BudgetRadii.xs),
              ),
              child: Padding(
                padding: const EdgeInsets.all(BudgetSpacing.space2 - 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.topLeft,
                            child: Text(
                              day,
                              style: BudgetTypeScale.caption.copyWith(
                                fontWeight: FontWeight.w500,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        _MarkShape(mark),
                      ],
                    ),
                    const Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomRight,
                      child: Text(
                        amount,
                        style: context.budgetText.moneySmall.copyWith(
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: BudgetSpacing.space1),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: BudgetTypeScale.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// The 6 dp day mark: ● saved, ○ on budget (1.5 dp ring), ◆ overspent.
class _MarkShape extends StatelessWidget {
  const new(this.mark);

  final _DayMark mark;

  static const double size = 6;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return switch (mark) {
      _DayMark.saved => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: colors.saved, shape: BoxShape.circle),
      ),
      _DayMark.onBudget => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.neutral, width: 1.5),
        ),
      ),
      _DayMark.overspent => Transform.rotate(
        angle: math.pi / 4,
        child: Container(
          width: size * math.sqrt1_2,
          height: size * math.sqrt1_2,
          color: colors.overspent,
        ),
      ),
    };
  }
}

/// Slide 4: a phone and three privacy facts, each with a check.
class PrivacyVisual extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.smartphone_outlined, size: 40, color: colors.accent),
        const SizedBox(height: BudgetSpacing.space3),
        for (final fact in const [
          ScreenCopy.visualStaysOnPhone,
          ScreenCopy.visualNoLogin,
          ScreenCopy.visualNothingUploaded,
        ])
          Padding(
            padding: const EdgeInsets.only(top: BudgetSpacing.space1),
            child: Row(
              children: [
                Icon(Icons.check, size: 20, color: colors.accent),
                const SizedBox(width: BudgetSpacing.space3),
                Expanded(
                  child: Text(
                    fact,
                    style: BudgetTypeScale.bodyLarge.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
