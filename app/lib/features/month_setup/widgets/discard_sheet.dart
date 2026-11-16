import 'package:daily_budget/core/copy/month_setup_copy.dart';
import 'package:daily_budget/core/widgets/decision_sheet.dart';
import 'package:flutter/widgets.dart';

/// `Discard changes?` (`month-setup.md` §9): **Keep editing** is first and
/// the safe choice, also for scrim, swipe and back. Returns true to discard.
Future<bool> showDiscardSheet(BuildContext context) => showDecisionSheet<bool>(
  context: context,
  title: MonthSetupCopy.discardTitle,
  paragraphs: const [MonthSetupCopy.discardBody],
  options: const [
    DecisionOption.primary(
      value: false,
      label: MonthSetupCopy.keepEditing,
      hint: MonthSetupCopy.keepEditingHint,
    ),
    DecisionOption.destructive(
      value: true,
      label: MonthSetupCopy.discard,
      hint: MonthSetupCopy.discardHint,
    ),
  ],
  dismissValue: false,
);
