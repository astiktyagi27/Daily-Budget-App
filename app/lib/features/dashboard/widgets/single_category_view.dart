import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/category_icon.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// The single-category state (F-013 AC-2, AC-3, design B-2): a 40 dp icon
/// circle and one sentence, no chart. In [sentence] the [amount] and the
/// [categoryName] are set in weight 600.
class SingleCategoryView extends StatelessWidget {
  const new({
    required this.category,
    required this.sentence,
    required this.amount,
    required this.categoryName,
    super.key,
  });

  final SpendCategory category;

  final String sentence;

  final String amount;

  final String categoryName;

  static const _strong = TextStyle(fontWeight: FontWeight.w600);

  /// [sentence] as spans, the first [amount] and the last [categoryName]
  /// emphasised.
  List<InlineSpan> _spans() {
    final amountAt = sentence.indexOf(amount);
    final nameAt = sentence.lastIndexOf(categoryName);
    if (amountAt < 0 || nameAt < amountAt + amount.length) {
      return [TextSpan(text: sentence)];
    }
    return [
      TextSpan(text: sentence.substring(0, amountAt)),
      TextSpan(text: amount, style: _strong),
      TextSpan(text: sentence.substring(amountAt + amount.length, nameAt)),
      TextSpan(text: categoryName, style: _strong),
      TextSpan(text: sentence.substring(nameAt + categoryName.length)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Row(
      children: [
        CategoryIcon(category: category),
        const SizedBox(width: BudgetSpacing.space3),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: BudgetTypeScale.bodyLarge.copyWith(
                color: colors.textPrimary,
              ),
              children: _spans(),
            ),
          ),
        ),
      ],
    );
  }
}
