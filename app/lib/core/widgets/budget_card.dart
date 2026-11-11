import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// A flat card: `surface` fill, hairline edge, `radiusLg`, no shadow
/// (design system §7.2; the shape comes from the theme's `cardTheme`).
/// Cards never stack inside cards.
class BudgetCard extends StatelessWidget {
  const new({
    required this.child,
    this.title,
    this.padding = const EdgeInsets.all(BudgetSpacing.space4),
    super.key,
  });

  final Widget child;

  /// Optional header in the `title` style.
  final String? title;

  /// `space4` by default; 0 for a group of list rows.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: title == null
            ? child
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title!,
                      style: context.budgetText.title.copyWith(
                        color: context.budgetColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: BudgetSpacing.space3),
                  child,
                ],
              ),
      ),
    );
  }
}
