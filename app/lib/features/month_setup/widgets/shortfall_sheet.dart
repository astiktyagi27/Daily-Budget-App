import 'package:daily_budget/core/copy/month_setup_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/widgets/decision_sheet.dart';
import 'package:daily_budget/features/month_setup/month_setup_controller.dart';
import 'package:flutter/widgets.dart';

/// What the user chose on the shortfall sheet.
enum ShortfallChoice {
  /// **Fix my numbers**: nothing is saved; focus goes to the fixed costs.
  fix,

  /// **Continue anyway**: save with ₹0 a day.
  continueAnyway,

  /// Scrim, swipe or back: nothing is saved; focus returns to Confirm.
  dismissed,
}

/// The decision sheet for a shortfall or an exactly-₹0 month (D-036, D-043,
/// `month-setup.md` §8). **Fix my numbers** comes first and is recommended.
Future<ShortfallChoice> showShortfallSheet(
  BuildContext context,
  SubmitNeedsChoice need,
) {
  final amount = formatRupees(need.shortfall);
  final (title, body) = switch (need.kind) {
    ShortfallKind.zero => (
      MonthSetupCopy.zeroTitle,
      MonthSetupCopy.zeroBody(need.basis),
    ),
    ShortfallKind.shortfall => (
      MonthSetupCopy.shortfallTitle,
      need.isEdit
          ? MonthSetupCopy.editShortfall(amount)
          : MonthSetupCopy.shortfallBody(amount, need.basis),
    ),
  };
  return showDecisionSheet<ShortfallChoice>(
    context: context,
    title: title,
    paragraphs: [body],
    options: const [
      DecisionOption.primary(
        value: ShortfallChoice.fix,
        label: MonthSetupCopy.fixNumbers,
        caption: MonthSetupCopy.fixNumbersCaption,
      ),
      DecisionOption(
        value: ShortfallChoice.continueAnyway,
        label: MonthSetupCopy.continueAnyway,
        caption: MonthSetupCopy.continueAnywayCaption,
      ),
    ],
    dismissValue: ShortfallChoice.dismissed,
  );
}
