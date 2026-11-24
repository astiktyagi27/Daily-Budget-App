import 'package:daily_budget/domain/budget/budget.dart';

/// The display names of the nine categories (README section 3.4 spelling),
/// shared by the Dashboard (F-013) and the category screens of F-015.
abstract final class CategoryCopy {
  static String nameOf(SpendCategory category) => switch (category) {
    SpendCategory.food => 'Food',
    SpendCategory.groceries => 'Groceries',
    SpendCategory.shopping => 'Shopping',
    SpendCategory.travel => 'Travel',
    SpendCategory.billsRecharge => 'Bills & Recharge',
    SpendCategory.entertainment => 'Entertainment',
    SpendCategory.health => 'Health',
    SpendCategory.friendsPeople => 'Friends & People',
    SpendCategory.other => 'Other',
  };
}
