import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// The category's Material outlined icon in a 40 dp `neutralSoft` circle
/// (`transactions-search.md` section 5.4). Decorative: the name next to it
/// says the same, so it is left out of the semantics tree.
class CategoryIcon extends StatelessWidget {
  const new({required this.category, super.key});

  final SpendCategory category;

  static const double size = 40;

  static IconData iconOf(SpendCategory category) => switch (category) {
    SpendCategory.food => Icons.restaurant_outlined,
    SpendCategory.groceries => Icons.local_grocery_store_outlined,
    SpendCategory.shopping => Icons.shopping_bag_outlined,
    SpendCategory.travel => Icons.commute_outlined,
    SpendCategory.billsRecharge => Icons.request_quote_outlined,
    SpendCategory.entertainment => Icons.movie_outlined,
    SpendCategory.health => Icons.medical_services_outlined,
    SpendCategory.friendsPeople => Icons.group_outlined,
    SpendCategory.other => Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.neutralSoft,
          shape: BoxShape.circle,
        ),
        child: Icon(iconOf(category), size: 20, color: colors.neutral),
      ),
    );
  }
}
