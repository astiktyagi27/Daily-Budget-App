import 'package:daily_budget/core/copy/transactions_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// The Today result line (`transactions.md` §4, F-009 §2.2): `budget ₹830 ·
/// spent ₹420 · ● ₹410 left today`, shared by the Transactions tab's Today
/// card and Home's (F-010 plan §1 item 4), so the words, marks, colours and
/// count-up exist once.
///
/// The result is coloured **and** marked, and its words carry the meaning
/// alone. The line wraps only between its parts. It has no semantics of its
/// own: the card around it gives a screen reader one sentence.
class TodayResultLine extends StatelessWidget {
  const new({required this.line, super.key});

  final TodayLine line;

  /// Names the line so tests can read its text (marks left out).
  static const ValueKey<String> lineKey = ValueKey('today-line');

  /// The decorative mark before the result (●, ○, ◆).
  static const ValueKey<String> markKey = ValueKey('today-mark');

  /// The result as a screen reader says it: `₹410 left today`, `on budget`,
  /// `overspent ₹120`, `less than ₹1 left today`.
  static String resultSpeech(TodayLine line) => switch (line.kind) {
    TodayResultKind.leftToday =>
      '${formatRupeesForSpeech(line.amount)} ${TransactionsCopy.leftTodayWord}',
    TodayResultKind.leftUnderRupee =>
      '${TransactionsCopy.lessThanOneRupee} ${TransactionsCopy.leftTodayWord}',
    TodayResultKind.onBudget => TransactionsCopy.onBudgetWord,
    TodayResultKind.overspentUnderRupee =>
      '${TransactionsCopy.overspentWord} ${TransactionsCopy.lessThanOneRupee}',
    TodayResultKind.overspent =>
      '${TransactionsCopy.overspentWord} '
          '${formatRupeesForSpeech(line.amount)}',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final base = BudgetTypeScale.bodyLarge.copyWith(color: colors.textPrimary);
    final amountStyle = base.copyWith(
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    InlineSpan amount(String text, [TextStyle? style]) =>
        TextSpan(text: text, style: style ?? amountStyle);

    final resultColor = switch (line.kind) {
      TodayResultKind.leftToday ||
      TodayResultKind.leftUnderRupee => colors.saved,
      TodayResultKind.onBudget => colors.neutral,
      TodayResultKind.overspentUnderRupee ||
      TodayResultKind.overspent => colors.overspent,
    };
    final mark = switch (line.kind) {
      TodayResultKind.leftToday || TodayResultKind.leftUnderRupee => '●',
      TodayResultKind.onBudget => '○',
      TodayResultKind.overspentUnderRupee || TodayResultKind.overspent => '◆',
    };
    final resultStyle = base.copyWith(color: resultColor);
    final resultAmountStyle = amountStyle.copyWith(color: resultColor);
    final motion = BudgetMotion.of(context);

    // The result's amount counts up to its new value; the words change at
    // once (design review point 10).
    Widget result() {
      Text words(List<InlineSpan> spans) =>
          Text.rich(TextSpan(style: resultStyle, children: spans));
      switch (line.kind) {
        case TodayResultKind.leftToday:
          return TweenAnimationBuilder<int>(
            tween: IntTween(end: line.amount.value),
            duration: motion.count,
            builder: (context, value, _) => words([
              amount(formatRupees(Paise(value)), resultAmountStyle),
              const TextSpan(text: ' ${TransactionsCopy.leftTodayWord}'),
            ]),
          );
        case TodayResultKind.overspent:
          return TweenAnimationBuilder<int>(
            tween: IntTween(end: line.amount.value),
            duration: motion.count,
            builder: (context, value, _) => words([
              const TextSpan(text: '${TransactionsCopy.overspentWord} '),
              amount(formatRupees(Paise(value)), resultAmountStyle),
            ]),
          );
        case TodayResultKind.leftUnderRupee:
          return words(const [
            TextSpan(
              text:
                  '${TransactionsCopy.lessThanOneRupee} '
                  '${TransactionsCopy.leftTodayWord}',
            ),
          ]);
        case TodayResultKind.onBudget:
          return words(const [TextSpan(text: TransactionsCopy.onBudgetWord)]);
        case TodayResultKind.overspentUnderRupee:
          return words(const [
            TextSpan(
              text:
                  '${TransactionsCopy.overspentWord} '
                  '${TransactionsCopy.lessThanOneRupee}',
            ),
          ]);
      }
    }

    return Wrap(
      key: lineKey,
      spacing: BudgetSpacing.space2,
      children: [
        Text.rich(
          TextSpan(
            style: base,
            children: [
              const TextSpan(text: '${TransactionsCopy.budgetWord} '),
              amount(formatRupees(line.budget)),
              const TextSpan(text: ' ·'),
            ],
          ),
        ),
        Text.rich(
          TextSpan(
            style: base,
            children: [
              const TextSpan(text: '${TransactionsCopy.spentWord} '),
              amount(formatRupees(line.netSpent)),
              const TextSpan(text: ' ·'),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mark, key: markKey, style: resultStyle),
            const SizedBox(width: BudgetSpacing.space1),
            Flexible(child: result()),
          ],
        ),
      ],
    );
  }
}
