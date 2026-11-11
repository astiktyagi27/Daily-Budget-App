import 'package:daily_budget/core/theme/budget_colors.dart';
import 'package:daily_budget/core/theme/budget_elevation.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:flutter/material.dart';

/// Short access to the design-system extensions of the current theme.
/// Every theme built by `buildBudgetTheme` carries all three.
extension BudgetThemeContext on BuildContext {
  BudgetColors get budgetColors => Theme.of(this).extension<BudgetColors>()!;

  BudgetText get budgetText => Theme.of(this).extension<BudgetText>()!;

  BudgetElevation get budgetElevation =>
      Theme.of(this).extension<BudgetElevation>()!;
}
