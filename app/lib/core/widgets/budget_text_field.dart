import 'package:daily_budget/core/help/help_info.dart';
import 'package:daily_budget/core/help/label_description.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// A text or amount input (design system §7.3, §7.12): label above, optional
/// description, then the 56 dp field. The label never moves into the field.
///
/// An error is shown as a 2 dp `overspent` outline **plus** an error icon
/// **plus** the message, never by colour alone. Built for Phase 2; no Phase 1
/// screen uses it. Money fields use the `AmountField` wrapper.
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
    this.large = false,
    this.info,
    this.textInputAction,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
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

  /// A fixed "₹" prefix, the money style and the number keypad with a
  /// decimal point.
  final bool isAmount;

  /// The big amount field (design system §7.3, Add spend): the value in
  /// `moneyLarge`, 64 dp tall. Only with [isAmount].
  final bool large;

  /// Adds an (i) after the label that opens this explanation (F-004).
  final HelpInfo? info;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  /// Replaces the keyboard action's default (Next moves to the traversal
  /// successor, Done closes the keyboard), for forms with their own order.
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final moneyStyle = large
        ? BudgetTypeScale.moneyLarge
        : BudgetTypeScale.moneyMedium;
    final valueStyle = (isAmount ? moneyStyle : BudgetTypeScale.bodyLarge)
        .copyWith(color: enabled ? colors.textPrimary : colors.textSecondary);
    final error = errorText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The text field's own node reads label and description; only the
        // (i) stays a separate item.
        LabelDescription(
          label: label,
          description: description,
          info: info,
          announce: false,
        ),
        const SizedBox(height: BudgetSpacing.space2),
        Semantics(
          label: label,
          hint: description,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            onChanged: onChanged,
            onEditingComplete: onEditingComplete,
            onSubmitted: onSubmitted,
            textInputAction: textInputAction,
            style: valueStyle,
            keyboardType: isAmount
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            decoration: InputDecoration(
              hintText: hintText,
              prefixText: isAmount ? '₹' : null,
              prefixStyle: large
                  ? moneyStyle.copyWith(color: colors.textSecondary)
                  : null,
              // 16 dp above and below a 24 dp line is 56 dp; a 34 dp line
              // needs 15 dp for 64 dp.
              contentPadding: large
                  ? const EdgeInsets.symmetric(
                      horizontal: BudgetSpacing.space4,
                      vertical: 15,
                    )
                  : null,
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
