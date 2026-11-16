import 'package:daily_budget/core/copy/transactions_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/widgets/decision_sheet.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/widgets.dart';

/// The paragraph for one reduced cover (`transactions.md` §9.2): the whole
/// cover taken back, or part of it. A cut under ₹1 reads `less than ₹1`.
String coverReductionText(CoverReduction reduction) {
  final cut = reduction.cut;
  final day = formatWeekdayDayMonth(reduction.day);
  if (reduction.newAmount.isZero && !reduction.cutIsUnderRupee) {
    return TransactionsCopy.coverTakenBack(
      formatRupees(cut),
      day,
      formatDayMonth(reduction.day),
    );
  }
  return TransactionsCopy.coverPartlyTakenBack(
    reduction.cutIsUnderRupee
        ? TransactionsCopy.lessThanOneRupee
        : formatRupees(cut),
    day,
  );
}

/// `Savings pot updated`: one paragraph per reduced cover, newest first
/// (the repository returns them in that order). Shown once, after a save
/// that reduced a cover (D-040, AC-19).
Future<void> showCoverTakenBackSheet(
  BuildContext context,
  List<CoverReduction> reductions,
) => showDecisionSheet<void>(
  context: context,
  title: TransactionsCopy.coverTitle,
  paragraphs: [for (final r in reductions) coverReductionText(r)],
  options: const [
    DecisionOption.primary(
      value: null,
      label: TransactionsCopy.ok,
      hint: TransactionsCopy.closeHint,
    ),
  ],
  dismissValue: null,
);
