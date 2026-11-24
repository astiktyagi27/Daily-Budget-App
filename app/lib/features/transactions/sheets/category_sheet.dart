import 'package:daily_budget/core/copy/category_copy.dart';
import 'package:daily_budget/core/copy/search_copy.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/budget_sheet.dart';
import 'package:daily_budget/core/widgets/category_icon.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/transactions/sheets/sheet_parts.dart';
import 'package:flutter/material.dart';

/// The category picker (`transactions-search.md` §8): the nine categories
/// with the current one ticked, the line `Only this spend changes.
/// Automatic categories come later.` and a pinned **Done**.
///
/// One sheet for both uses: from a list row (the title is `Category for
/// ₹250 · Lunch`, the pick is saved at once by the caller) and from the
/// editor (the title is `Category`, the pick only changes the field). It
/// closes on the first pick and returns it; the already ticked row, **Done**,
/// the scrim and back return null.
Future<SpendCategory?> showCategorySheet(
  BuildContext context, {
  required String title,
  required SpendCategory current,
}) => showBudgetSheet<SpendCategory>(
  context: context,
  builder: (context) => CategorySheet(title: title, current: current),
);

class CategorySheet extends StatefulWidget {
  const new({required this.title, required this.current, super.key});

  final String title;
  final SpendCategory current;

  @override
  State<CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<CategorySheet> {
  bool _closing = false;

  void _pick(SpendCategory category) {
    if (_closing) return;
    _closing = true;
    // The ticked row is not a change: it closes like Done.
    Navigator.of(context).pop(category == widget.current ? null : category);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return SheetScaffold(
      title: widget.title,
      description: SearchCopy.sheetLine,
      body: Column(
        children: [
          for (final category in SpendCategory.values)
            _CategoryRow(
              category: category,
              selected: category == widget.current,
              onTap: () => _pick(category),
              color: colors.accent,
            ),
        ],
      ),
      actions: [
        BudgetButton.secondary(
          label: SearchCopy.done,
          semanticsHint: SearchCopy.doneHint,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const new({
    required this.category,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  final SpendCategory category;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final name = CategoryCopy.nameOf(category);
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        label: SearchCopy.categoryRowSemantics(name, selected: selected),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            overlayColor: WidgetStateProperty.fromMap({
              WidgetState.pressed: colors.sunken,
              WidgetState.any: colors.sunken.withValues(alpha: 0),
            }),
            splashFactory: NoSplash.splashFactory,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BudgetSpacing.space5,
                  vertical: BudgetSpacing.space2,
                ),
                child: Row(
                  children: [
                    CategoryIcon(category: category),
                    const SizedBox(width: BudgetSpacing.space4),
                    Expanded(
                      child: ExcludeSemantics(
                        child: Text(
                          name,
                          style: BudgetTypeScale.label.copyWith(
                            color: colors.textPrimary,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: BudgetSpacing.space6,
                      child: selected
                          ? ExcludeSemantics(
                              child: Icon(Icons.check, size: 20, color: color),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
