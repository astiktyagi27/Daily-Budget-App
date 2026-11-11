import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// A text or amount input (design system §7.3, §7.12): label above, optional
/// description, then the 56 dp field. The label never moves into the field.
///
/// An error is shown as a 2 dp `overspent` outline **plus** an error icon
/// **plus** the message, never by colour alone. Built for Phase 2; no Phase 1
/// screen uses it.
class BudgetTextField extends StatelessWidget {
  const new({
    required this.label,
    this.description,
    this.controller,
    this.focusNode,
    this.hintText,
    this.errorText,
    this.enabled = true,
    this.isAmount = false,
    this.onChanged,
    super.key,
  });

  final String label;
  final String? description;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;

  /// How to fix the problem, e.g. "Enter an amount above ₹0".
  final String? errorText;
  final bool enabled;

  /// A fixed "₹" prefix, the money style and the number keypad. Indian
  /// grouping while typing arrives with the Phase 2 money formatter.
  final bool isAmount;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final valueStyle =
        (isAmount ? BudgetTypeScale.moneyMedium : BudgetTypeScale.bodyLarge)
            .copyWith(
              color: enabled ? colors.textPrimary : colors.textSecondary,
            );
    final error = errorText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: BudgetTypeScale.label.copyWith(color: colors.textPrimary),
          ),
        ),
        if (description case final description?) ...[
          const SizedBox(height: BudgetSpacing.space1),
          ExcludeSemantics(
            child: Text(
              description,
              style: BudgetTypeScale.body.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
        const SizedBox(height: BudgetSpacing.space2),
        Semantics(
          label: label,
          hint: description,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            onChanged: onChanged,
            style: valueStyle,
            keyboardType: isAmount ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hintText,
              prefixText: isAmount ? '₹' : null,
              fillColor: enabled ? null : colors.neutralSoft,
              error: error == null ? null : _ErrorMessage(error),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const new(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = context.budgetColors.overspent;
    return Semantics(
      liveRegion: true,
      label: 'Error: $message',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 16, color: color),
          const SizedBox(width: BudgetSpacing.space1),
          Expanded(
            child: Text(
              message,
              style: BudgetTypeScale.body.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
