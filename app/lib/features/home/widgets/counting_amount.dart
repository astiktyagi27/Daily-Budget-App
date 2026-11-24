import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// An amount that counts to its new value when it changes (design system
/// §5.4, `home-summary.md` §8). The first build shows the amount at once;
/// with "Remove animations" on the change is instant too.
class CountingAmount extends StatelessWidget {
  const new({required this.amount, required this.style, super.key});

  final Paise amount;

  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(end: amount.value),
      duration: BudgetMotion.of(context).count,
      builder: (context, value, _) =>
          Text(formatRupees(Paise(value)), style: style),
    );
  }
}
