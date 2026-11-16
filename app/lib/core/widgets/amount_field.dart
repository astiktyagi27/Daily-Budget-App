import 'package:daily_budget/core/help/help_info.dart';
import 'package:daily_budget/core/widgets/budget_text_field.dart';
import 'package:flutter/material.dart';

/// The amount input shared by month setup (F-008) and the spend editor
/// (F-009), design system §7.3: label with an optional (i), a description,
/// a fixed `₹` prefix, the money type style, the number keypad with a
/// decimal point, and an error under the field.
///
/// The field holds the raw text the user typed. Turning it into paise is
/// `parseAmount` (domain), and the wording of a problem is the screen's:
/// pass it as [errorText]. Pre-filled values come from `amountInputText`.
class AmountField extends StatelessWidget {
  const new({
    required this.label,
    required this.controller,
    this.description,
    this.info,
    this.focusNode,
    this.errorText,
    this.hintText,
    this.enabled = true,
    this.large = false,
    this.textInputAction,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    super.key,
  });

  /// The fixed currency prefix of every amount field, also used by the
  /// compact fields of a list row.
  static const prefix = '₹';

  final String label;
  final TextEditingController controller;
  final String? description;
  final HelpInfo? info;
  final FocusNode? focusNode;

  /// How to fix the problem, e.g. "Enter your salary".
  final String? errorText;
  final String? hintText;
  final bool enabled;

  /// The 64 dp field with the value in `moneyLarge` (Add spend).
  final bool large;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return BudgetTextField(
      label: label,
      description: description,
      info: info,
      controller: controller,
      focusNode: focusNode,
      errorText: errorText,
      hintText: hintText,
      enabled: enabled,
      isAmount: true,
      large: large,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
    );
  }
}
