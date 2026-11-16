import 'package:daily_budget/core/copy/transactions_copy.dart';
import 'package:daily_budget/core/help/label_description.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The optional note (`transactions.md` §8.1 row 5): up to 100 characters as
/// the user sees them (Flutter counts grapheme clusters, so Hindi and emoji
/// count once each), growing to 3 lines. A `<n>/100` counter shows from 80
/// characters on and stays neutral at the limit: it is blocked, not an error.
class NoteField extends StatelessWidget {
  const new({required this.controller, this.onChanged, super.key});

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  /// The counter appears from this many characters.
  static const int counterFrom = 80;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const LabelDescription(
          label: TransactionsCopy.noteLabel,
          description: TransactionsCopy.noteDescription,
          announce: false,
        ),
        const SizedBox(height: BudgetSpacing.space2),
        Semantics(
          label: TransactionsCopy.noteLabel,
          hint: TransactionsCopy.noteDescription,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            minLines: 1,
            maxLines: 3,
            maxLength: maxNoteLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.sentences,
            style: BudgetTypeScale.bodyLarge.copyWith(
              color: colors.textPrimary,
            ),
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  required maxLength,
                }) => currentLength < counterFrom
                ? const SizedBox.shrink()
                : Text(
                    '$currentLength/$maxLength',
                    style: BudgetTypeScale.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
