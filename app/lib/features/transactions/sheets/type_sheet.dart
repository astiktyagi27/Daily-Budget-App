import 'package:daily_budget/core/copy/search_copy.dart';
import 'package:daily_budget/core/widgets/budget_sheet.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/transactions/sheets/sheet_parts.dart';
import 'package:flutter/material.dart';

/// The Type sheet (`transactions-search.md` §5.3): `All`, `Spends`,
/// `Refunds`; picking applies and closes. Null when closed without a choice.
Future<TypeFilter?> showTypeSheet(
  BuildContext context, {
  required TypeFilter current,
}) => showBudgetSheet<TypeFilter>(
  context: context,
  builder: (context) => TypeSheet(current: current),
);

class TypeSheet extends StatelessWidget {
  const new({required this.current, super.key});

  final TypeFilter current;

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: SearchCopy.typeTitle,
      description: SearchCopy.typeDescription,
      body: Column(
        children: [
          for (final type in TypeFilter.values)
            ChoiceRow(
              label: SearchCopy.typeName(type),
              selected: type == current,
              onTap: () => Navigator.of(context).pop(type),
              semanticsLabel: SearchCopy.typeName(type),
            ),
        ],
      ),
    );
  }
}
