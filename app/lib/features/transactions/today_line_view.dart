import 'package:daily_budget/core/copy/transactions_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:daily_budget/core/widgets/today_result_line.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// The Today card (`transactions.md` §4, F-009 §2.2): `budget ₹830 · spent
/// ₹250 · ₹580 left today`, worked out by [TodayLine] so nothing here does
/// money arithmetic.
///
/// The result is coloured **and** marked, and its words carry the meaning
/// alone. The line wraps only between its parts, and a screen reader gets one
/// sentence. Its (i) is a separate stop.
class TodayLineView extends StatelessWidget {
  const new({required this.line, super.key});

  final TodayLine line;

  /// Names the line so tests can read its text (marks left out).
  static const ValueKey<String> lineKey = TodayResultLine.lineKey;

  /// The decorative mark before the result (●, ○, ◆).
  static const ValueKey<String> markKey = TodayResultLine.markKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final hasShortfall = line.hasShortfall;
    return BudgetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(
                    TransactionsCopy.todayTitle,
                    style: context.budgetText.title.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              const InfoButton(
                label: TransactionsCopy.todayTitle,
                info: (
                  title: TransactionsCopy.todayTitle,
                  body: TransactionsCopy.todayInfoBody,
                ),
              ),
            ],
          ),
          Semantics(
            container: true,
            label: _sentence(),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TodayResultLine(line: line),
                  if (hasShortfall) ...[
                    const SizedBox(height: BudgetSpacing.space3),
                    _ShortfallPanel(shortfall: line.shortfall),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _sentence() => TransactionsCopy.todaySemantics(
    budget: formatRupeesForSpeech(line.budget),
    spent: formatRupeesForSpeech(line.netSpent),
    result: TodayResultLine.resultSpeech(line),
    shortfall: line.hasShortfall ? formatRupeesForSpeech(line.shortfall) : null,
  );
}

class _ShortfallPanel extends StatelessWidget {
  const new({required this.shortfall});

  final Paise shortfall;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final style = BudgetTypeScale.label.copyWith(
      fontWeight: FontWeight.w600,
      color: colors.overspent,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.overspentSoft,
        borderRadius: const BorderRadius.all(Radius.circular(BudgetRadii.md)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BudgetSpacing.space3,
          vertical: BudgetSpacing.space2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('◆', style: style),
            const SizedBox(width: BudgetSpacing.space2),
            Flexible(
              child: Text(
                TransactionsCopy.shortfallThisMonth(formatRupees(-shortfall)),
                style: style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
