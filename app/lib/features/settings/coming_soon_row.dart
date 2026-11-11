import 'package:daily_budget/core/copy/help_copy.dart';
import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/core/widgets/budget_list_row.dart';
import 'package:flutter/material.dart';

/// A Settings row for an option that arrives in a later phase
/// (settings.md §2.3): label and description, a "Coming soon" tag, no
/// chevron, and no tap action at all (F-003 AC-6).
///
/// A screen reader reads it as one disabled item:
/// `<Label>, coming soon, not available yet. <Description>`.
class ComingSoonRow extends StatelessWidget {
  const new({
    required this.label,
    required this.description,
    required this.icon,
    super.key,
  });

  final String label;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return BudgetListRow(
      label: label,
      description: description,
      leadingIcon: icon,
      tag: ScreenCopy.comingSoonTag,
      enabled: false,
      semanticsLabel: HelpCopy.comingSoon(label, description),
    );
  }
}
