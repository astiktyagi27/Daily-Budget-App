import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// The frame of the Transactions sheets (`transactions-search.md` §5, §8): a
/// title, an optional description, the rows (they scroll at large text) and
/// the buttons pinned under them. Open it with `showBudgetSheet`.
class SheetScaffold extends StatelessWidget {
  const new({
    required this.title,
    required this.body,
    this.description,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String? description;

  /// The rows; they sit in a scrollable, so the buttons stay reachable.
  final Widget body;

  /// Full-width buttons pinned under the rows, top to bottom.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BudgetSpacing.space5,
            BudgetSpacing.space6,
            BudgetSpacing.space5,
            BudgetSpacing.space2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: context.budgetText.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (description case final description?) ...[
                const SizedBox(height: BudgetSpacing.space2),
                Text(
                  description,
                  style: BudgetTypeScale.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        Flexible(child: SingleChildScrollView(child: body)),
        Padding(
          padding: EdgeInsets.fromLTRB(
            BudgetSpacing.space5,
            BudgetSpacing.space4,
            BudgetSpacing.space5,
            BudgetSpacing.space5 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, action) in actions.indexed) ...[
                if (index > 0) const SizedBox(height: BudgetSpacing.space3),
                action,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// How a [ChoiceRow] draws its selector.
enum ChoiceKind { radio, checkbox }

/// One row of a choice sheet (design system §7.4): a radio or a checkbox, a
/// label and an optional description; 56 dp at least. A **disabled** row is
/// drawn greyed (`neutralSoft` selector, no outline) and does nothing when
/// tapped, but keeps both lines. The selected state shows as the filled
/// selector and a heavier label, never by colour alone.
class ChoiceRow extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.semanticsLabel,
    this.description,
    this.kind = ChoiceKind.radio,
    this.enabled = true,
    this.leading,
    super.key,
  });

  final String label;
  final String? description;
  final bool selected;
  final VoidCallback onTap;
  final ChoiceKind kind;
  final bool enabled;

  /// What a screen reader reads; the selector's role and state are flags.
  final String semanticsLabel;

  /// A decorative widget before the label (the category icon).
  final Widget? leading;

  static const double _selector = 24;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final textColor = enabled ? colors.textPrimary : colors.textSecondary;
    final selector = ExcludeSemantics(
      child: switch (kind) {
        ChoiceKind.radio => _Radio(selected: selected, enabled: enabled),
        ChoiceKind.checkbox => _Checkbox(selected: selected),
      },
    );
    return MergeSemantics(
      child: Semantics(
        label: semanticsLabel,
        enabled: enabled,
        checked: kind == ChoiceKind.checkbox ? selected : null,
        selected: kind == ChoiceKind.radio ? selected : null,
        inMutuallyExclusiveGroup: kind == ChoiceKind.radio,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled ? onTap : null,
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
                    if (kind == ChoiceKind.radio) ...[
                      selector,
                      const SizedBox(width: BudgetSpacing.space4),
                    ],
                    if (leading case final leading?) ...[
                      leading,
                      const SizedBox(width: BudgetSpacing.space4),
                    ],
                    Expanded(
                      child: ExcludeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: BudgetTypeScale.label.copyWith(
                                color: textColor,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                            if (description case final description?) ...[
                              const SizedBox(height: BudgetSpacing.space1),
                              Text(
                                description,
                                style: BudgetTypeScale.body.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (kind == ChoiceKind.checkbox) ...[
                      const SizedBox(width: BudgetSpacing.space3),
                      selector,
                    ],
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

class _Radio extends StatelessWidget {
  const new({required this.selected, required this.enabled});

  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final ringColor = selected ? colors.accent : colors.borderStrong;
    return Container(
      width: ChoiceRow._selector,
      height: ChoiceRow._selector,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: enabled ? null : colors.neutralSoft,
        border: enabled ? Border.all(color: ringColor, width: 2) : null,
      ),
      alignment: Alignment.center,
      child: selected && enabled
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colors.accent,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

class _Checkbox extends StatelessWidget {
  const new({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Container(
      width: ChoiceRow._selector,
      height: ChoiceRow._selector,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(BudgetRadii.xs)),
        color: selected ? colors.accent : null,
        border: selected
            ? null
            : Border.all(color: colors.borderStrong, width: 2),
      ),
      alignment: Alignment.center,
      child: selected
          ? Icon(Icons.check, size: 18, color: colors.onAccent)
          : null,
    );
  }
}
