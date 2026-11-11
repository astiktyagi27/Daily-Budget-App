import 'package:daily_budget/core/copy/help_copy.dart';
import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/core/help/help_info.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/budget_sheet.dart';
import 'package:flutter/material.dart';

/// Opens the help sheet for an (i) button (help-pattern §3.2). Completes
/// when the sheet is closed, whichever of the four ways was used.
Future<void> showHelpSheet(BuildContext context, HelpInfo info) =>
    showBudgetSheet<void>(
      context: context,
      builder: (context) => HelpSheet(info: info),
    );

/// Title, a body that scrolls when long, and a **Got it** button pinned to
/// the bottom so it stays reachable at any text size (F-004 AC-13).
class HelpSheet extends StatelessWidget {
  const new({required this.info, super.key});

  final HelpInfo info;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BudgetSpacing.space5,
            BudgetSpacing.space6,
            BudgetSpacing.space5,
            0,
          ),
          child: Semantics(
            header: true,
            child: Text(
              info.title,
              style: context.budgetText.title.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              BudgetSpacing.space5,
              BudgetSpacing.space3,
              BudgetSpacing.space5,
              0,
            ),
            child: Text(
              info.body,
              style: BudgetTypeScale.bodyLarge.copyWith(
                color: colors.textPrimary,
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
            label: ScreenCopy.gotIt,
            semanticsHint: HelpCopy.closeExplanationHint,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}
