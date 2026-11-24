import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_icon_button.dart';
import 'package:flutter/material.dart';

/// The search box of a list (`transactions-search.md` §4): 48 dp tall, a
/// leading search icon, the placeholder, and a close button with the tooltip
/// [clearTooltip] while it holds text. The text lives in [controller], which
/// the screen owns, so the field keeps focus and the keyboard while the
/// results behind it change.
class SearchField extends StatelessWidget {
  const new({
    required this.controller,
    required this.placeholder,
    required this.hint,
    required this.clearTooltip,
    required this.clearHint,
    required this.onChanged,
    required this.onClear,
    this.focusNode,
    super.key,
  });

  final TextEditingController controller;
  final String placeholder;

  /// What a screen reader adds after the label: `Type a note or an amount`.
  final String hint;
  final String clearTooltip;
  final String clearHint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Semantics(
      label: placeholder,
      hint: hint,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          keyboardType: TextInputType.text,
          style: BudgetTypeScale.bodyLarge.copyWith(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: placeholder,
            // Wraps at large text instead of being cut (design §13).
            hintMaxLines: 3,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: BudgetSpacing.space2,
              vertical: BudgetSpacing.space3,
            ),
            prefixIcon: ExcludeSemantics(
              child: Icon(Icons.search, size: 20, color: colors.textSecondary),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: BudgetSpacing.touchTarget - BudgetSpacing.space2,
              minHeight: BudgetSpacing.touchTarget,
            ),
            suffixIcon: value.text.isEmpty
                ? null
                : BudgetIconButton(
                    icon: Icons.close,
                    iconSize: 20,
                    tooltip: clearTooltip,
                    hint: clearHint,
                    onPressed: onClear,
                  ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: BudgetSpacing.touchTarget,
              minHeight: BudgetSpacing.touchTarget,
            ),
          ),
        ),
      ),
    );
  }
}
