import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/budget_sheet.dart';
import 'package:flutter/material.dart';

/// One choice on a decision sheet: a full-width button, an optional caption
/// under it and the value the sheet returns when it is tapped.
class DecisionOption<T> {
  const new({
    required this.value,
    required this.label,
    this.caption,
    this.hint,
    this.variant = BudgetButtonVariant.secondary,
  });

  /// The recommended first button.
  const new primary({
    required this.value,
    required this.label,
    this.caption,
    this.hint,
  }) : variant = BudgetButtonVariant.primary;

  /// A first button that removes data (Delete).
  const new destructive({
    required this.value,
    required this.label,
    this.caption,
    this.hint,
  }) : variant = BudgetButtonVariant.destructive;

  final T value;
  final String label;

  /// A line in `textSecondary` under the button explaining what it does.
  final String? caption;

  /// Read after the label by screen readers, e.g. `Go back to your changes`.
  final String? hint;
  final BudgetButtonVariant variant;
}

/// The app's only confirmation pattern (design system §7.8), built on
/// [showBudgetSheet] (D-031): a title, the body as one or more paragraphs,
/// then full-width buttons stacked vertically.
///
/// **The first option is the one we recommend**: the safe choice when the
/// sheet interrupts the user (shortfall: Fix my numbers; discard: Keep
/// editing), the confirmed action when the user asked for it with a
/// deliberate tap (Delete). Give it [BudgetButtonVariant.primary], or
/// destructive when it removes data.
///
/// A tap on the scrim, a swipe down and back all return [dismissValue], the
/// safe, non-saving choice. The buttons are the sheet's own visible close
/// choice. A second tap on a button while the sheet closes is ignored.
Future<T> showDecisionSheet<T>({
  required BuildContext context,
  required String title,
  required List<String> paragraphs,
  required List<DecisionOption<T>> options,
  required T dismissValue,
}) async {
  assert(options.isNotEmpty, 'a decision sheet needs at least one option');
  final chosen = await showBudgetSheet<T>(
    context: context,
    builder: (context) => DecisionSheet<T>(
      title: title,
      paragraphs: paragraphs,
      options: options,
    ),
  );
  return chosen ?? dismissValue;
}

/// The content of a decision sheet; open it with [showDecisionSheet].
class DecisionSheet<T> extends StatefulWidget {
  const new({
    required this.title,
    required this.paragraphs,
    required this.options,
    super.key,
  });

  final String title;
  final List<String> paragraphs;
  final List<DecisionOption<T>> options;

  @override
  State<DecisionSheet<T>> createState() => _DecisionSheetState<T>();
}

class _DecisionSheetState<T> extends State<DecisionSheet<T>> {
  bool _closing = false;

  void _choose(T value) {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        // The buttons are pinned under the text and scroll on their own only
        // when text this large would leave the text no room (design system
        // 7.8: the sheet scrolls inside, up to 90 % of the screen).
        final actionsMaxHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight * _maxActionsShare
            : double.infinity;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  BudgetSpacing.space5,
                  BudgetSpacing.space6,
                  BudgetSpacing.space5,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        widget.title,
                        style: context.budgetText.title.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: BudgetSpacing.space3),
                    for (final (index, paragraph)
                        in widget.paragraphs.indexed) ...[
                      if (index > 0)
                        const SizedBox(height: BudgetSpacing.space3),
                      Text(
                        paragraph,
                        style: BudgetTypeScale.bodyLarge.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: actionsMaxHeight),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  BudgetSpacing.space5,
                  BudgetSpacing.space5,
                  BudgetSpacing.space5,
                  BudgetSpacing.space5 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (index, option) in widget.options.indexed) ...[
                      if (index > 0)
                        const SizedBox(height: BudgetSpacing.space3),
                      _OptionButton<T>(
                        option: option,
                        onChosen: () => _choose(option.value),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// The most of the sheet the buttons may take before they scroll.
  static const double _maxActionsShare = 0.6;
}

class _OptionButton<T> extends StatelessWidget {
  const new({required this.option, required this.onChosen});

  final DecisionOption<T> option;
  final VoidCallback onChosen;

  @override
  Widget build(BuildContext context) {
    final button = switch (option.variant) {
      BudgetButtonVariant.primary => BudgetButton.primary(
        label: option.label,
        onPressed: onChosen,
        semanticsHint: option.hint,
      ),
      BudgetButtonVariant.destructive => BudgetButton.destructive(
        label: option.label,
        onPressed: onChosen,
        semanticsHint: option.hint,
      ),
      BudgetButtonVariant.secondary => BudgetButton.secondary(
        label: option.label,
        onPressed: onChosen,
        semanticsHint: option.hint,
      ),
      BudgetButtonVariant.text => BudgetButton.text(
        label: option.label,
        onPressed: onChosen,
        semanticsHint: option.hint,
      ),
    };
    final caption = option.caption;
    if (caption == null) return button;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        button,
        const SizedBox(height: BudgetSpacing.space1),
        Text(
          caption,
          style: BudgetTypeScale.body.copyWith(
            color: context.budgetColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
