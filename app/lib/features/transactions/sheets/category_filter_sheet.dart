import 'package:daily_budget/core/copy/category_copy.dart';
import 'package:daily_budget/core/copy/search_copy.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/budget_sheet.dart';
import 'package:daily_budget/core/widgets/category_icon.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/transactions/sheets/sheet_parts.dart';
import 'package:flutter/material.dart';

/// The Category filter sheet (`transactions-search.md` §5.2): nine checkbox
/// rows; `Show` applies the ticked ones, `Clear` applies none (all
/// categories). Closing with the scrim or back changes nothing: null.
Future<Set<SpendCategory>?> showCategoryFilterSheet(
  BuildContext context, {
  required Set<SpendCategory> current,
}) => showBudgetSheet<Set<SpendCategory>>(
  context: context,
  builder: (context) => CategoryFilterSheet(current: current),
);

class CategoryFilterSheet extends StatefulWidget {
  const new({required this.current, super.key});

  final Set<SpendCategory> current;

  @override
  State<CategoryFilterSheet> createState() => _CategoryFilterSheetState();
}

class _CategoryFilterSheetState extends State<CategoryFilterSheet> {
  late final Set<SpendCategory> _ticked = {...widget.current};

  void _toggle(SpendCategory category) => setState(() {
    if (!_ticked.remove(category)) _ticked.add(category);
  });

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: SearchCopy.categoryFilterTitle,
      description: SearchCopy.categoryFilterDescription,
      body: Column(
        children: [
          for (final category in SpendCategory.values)
            ChoiceRow(
              kind: ChoiceKind.checkbox,
              label: CategoryCopy.nameOf(category),
              leading: CategoryIcon(category: category),
              selected: _ticked.contains(category),
              onTap: () => _toggle(category),
              semanticsLabel: CategoryCopy.nameOf(category),
            ),
        ],
      ),
      actions: [
        BudgetButton.primary(
          label: SearchCopy.show,
          semanticsHint: SearchCopy.showHint,
          onPressed: () => Navigator.of(context).pop({..._ticked}),
        ),
        BudgetButton.secondary(
          label: SearchCopy.clear,
          semanticsHint: SearchCopy.clearHint,
          onPressed: () => Navigator.of(context).pop(<SpendCategory>{}),
        ),
      ],
    );
  }
}
