import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// What a screen shows before it has content (design system §7.10,
/// app-shell §4): left-aligned, an 88 dp `neutralSoft` circle with a 40 dp
/// line icon, a title and a description that wraps freely; optionally one
/// button (not used in Phase 1).
///
/// A screen reader reads the title and description as one item.
class EmptyState extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.description,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;

  /// An optional Secondary button under the text.
  final Widget? action;

  static const double circleSize = 88;
  static const double iconSize = 40;
  static const double _maxTextWidth = 320;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BudgetSpacing.space5,
        BudgetSpacing.space8,
        BudgetSpacing.space5,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            container: true,
            label: '$title. $description',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      color: colors.neutralSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: iconSize, color: colors.neutral),
                  ),
                  const SizedBox(height: BudgetSpacing.space5),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxTextWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.budgetText.title.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: BudgetSpacing.space2),
                        Text(
                          description,
                          style: BudgetTypeScale.bodyLarge.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (action case final action?) ...[
            const SizedBox(height: BudgetSpacing.space5),
            action,
          ],
        ],
      ),
    );
  }
}
