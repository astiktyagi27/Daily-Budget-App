import 'package:daily_budget/core/copy/category_copy.dart';
import 'package:daily_budget/core/copy/search_copy.dart';
import 'package:daily_budget/core/help/label_description.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/category_icon.dart';
import 'package:daily_budget/core/widgets/focus_ring.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/transactions/sheets/category_sheet.dart';
import 'package:flutter/material.dart';

/// The Category row of the Add / Edit spend screen (F-015 §2.4a, design §9
/// row 7): label, description, and a field-styled row with the category's
/// icon, its name and an arrow. Tapping it opens the category sheet in
/// editor mode: a pick only changes the field, nothing is saved until Save.
class CategoryField extends StatefulWidget {
  const new({required this.category, required this.onPicked, super.key});

  /// The category shown: the effective one (none reads `Other`).
  final SpendCategory category;

  /// Called with a category other than the shown one.
  final ValueChanged<SpendCategory> onPicked;

  @override
  State<CategoryField> createState() => _CategoryFieldState();
}

class _CategoryFieldState extends State<CategoryField> {
  final _focusNode = FocusNode(debugLabel: 'SpendCategory');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final picked = await showCategorySheet(
      context,
      title: SearchCopy.editorSheetTitle,
      current: widget.category,
    );
    if (picked != null) widget.onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final name = CategoryCopy.nameOf(widget.category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const LabelDescription(
          label: SearchCopy.categoryLabel,
          description: SearchCopy.categoryDescription,
          announce: false,
        ),
        const SizedBox(height: BudgetSpacing.space2),
        Semantics(
          button: true,
          label: SearchCopy.categoryFieldSemantics(name),
          hint: SearchCopy.categoryHint,
          excludeSemantics: true,
          onTap: _open,
          child: FocusRing(
            focusNode: _focusNode,
            child: InkWell(
              focusNode: _focusNode,
              onTap: _open,
              borderRadius: const BorderRadius.all(
                Radius.circular(BudgetRadii.md),
              ),
              child: InputDecorator(
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    CategoryIcon.iconOf(widget.category),
                    size: 20,
                    color: colors.neutral,
                  ),
                  suffixIcon: Icon(
                    Icons.expand_more,
                    color: colors.textSecondary,
                  ),
                ),
                child: Text(
                  name,
                  style: BudgetTypeScale.bodyLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
