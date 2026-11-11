import 'dart:async';

import 'package:daily_budget/core/copy/help_copy.dart';
import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_choice_provider.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/budget_sheet.dart';
import 'package:daily_budget/domain/preferences/theme_choice.dart';
import 'package:daily_budget/features/settings/theme/theme_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the theme picker (settings.md §3). Completes when it is closed.
Future<void> showThemePicker(BuildContext context) => showBudgetSheet<void>(
  context: context,
  builder: (context) => const ThemePickerSheet(),
);

/// The theme picker: title, the four options and a pinned **Done**.
///
/// Picking an option applies and saves it at once and keeps the sheet open,
/// so the user sees the new theme and can try another (F-002 AC-5).
class ThemePickerSheet extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.budgetColors;
    final current = ref.watch(themeChoiceProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    void pick(ThemeChoice? choice) {
      if (choice == null || choice == ref.read(themeChoiceProvider)) return;
      unawaited(ref.read(themeChoiceProvider.notifier).select(choice));
      unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          HelpCopy.themeChanged(choice.label),
          Directionality.of(context),
        ),
      );
    }

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
          child: Semantics(
            header: true,
            child: Text(
              ScreenCopy.themePickerTitle,
              style: context.budgetText.title.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
        // At large text the options scroll; Done stays pinned (settings.md §7).
        Flexible(
          child: SingleChildScrollView(
            child: RadioGroup<ThemeChoice>(
              groupValue: current,
              onChanged: pick,
              child: Column(
                children: [
                  for (final choice in ThemeChoice.values)
                    _ThemeOption(
                      choice: choice,
                      selected: choice == current,
                      onTap: () => pick(choice),
                    ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            BudgetSpacing.space5,
            BudgetSpacing.space4,
            BudgetSpacing.space5,
            BudgetSpacing.space5 + bottomInset,
          ),
          child: BudgetButton.secondary(
            label: ScreenCopy.done,
            semanticsHint: HelpCopy.themePickerDoneHint,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

/// One option row: radio, label + description, and a check when selected.
/// The selected state shows as the radio dot, the check and the heavier
/// label, never by colour alone (F-002 AC-1).
class _ThemeOption extends StatelessWidget {
  const new({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final ThemeChoice choice;
  final bool selected;
  final VoidCallback onTap;

  static const double _minHeight = 64;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    // One screen-reader item: `Auto. Matches your phone's light or dark
    // setting`, with the radio's checked state and tap action merged in.
    return MergeSemantics(
      child: Semantics(
        label: '${choice.label}. ${choice.optionDescription}',
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            // The radio is the keyboard focus stop of the row.
            canRequestFocus: false,
            overlayColor: WidgetStateProperty.fromMap({
              WidgetState.pressed: colors.sunken,
              // No hover or focus fill: the radio shows focus.
              WidgetState.any: colors.sunken.withValues(alpha: 0),
            }),
            splashFactory: NoSplash.splashFactory,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  BudgetSpacing.space2,
                  BudgetSpacing.space2,
                  BudgetSpacing.space5,
                  BudgetSpacing.space2,
                ),
                child: Row(
                  children: [
                    Radio<ThemeChoice>(
                      value: choice,
                      fillColor: WidgetStateProperty.fromMap({
                        WidgetState.selected: colors.accent,
                        WidgetState.any: colors.borderStrong,
                      }),
                      innerRadius: const WidgetStatePropertyAll(5),
                    ),
                    const SizedBox(width: BudgetSpacing.space2),
                    Expanded(
                      child: ExcludeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              choice.label,
                              style: BudgetTypeScale.label.copyWith(
                                color: colors.textPrimary,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: BudgetSpacing.space1),
                            Text(
                              choice.optionDescription,
                              style: BudgetTypeScale.body.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Keeps its width, so the texts never jump.
                    SizedBox(
                      width: BudgetSpacing.space6,
                      child: selected
                          ? Icon(Icons.check, size: 20, color: colors.accent)
                          : null,
                    ),
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
