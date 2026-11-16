import 'package:daily_budget/core/copy/transactions_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
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
  static const ValueKey<String> lineKey = ValueKey('today-line');

  /// The decorative mark before the result (●, ○, ◆).
  static const ValueKey<String> markKey = ValueKey('today-mark');

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
                  _Line(line: line),
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
    result: switch (line.kind) {
      TodayResultKind.leftToday =>
        '${formatRupeesForSpeech(line.amount)} '
            '${TransactionsCopy.leftTodayWord}',
      TodayResultKind.leftUnderRupee =>
        '${TransactionsCopy.lessThanOneRupee} '
            '${TransactionsCopy.leftTodayWord}',
      TodayResultKind.onBudget => TransactionsCopy.onBudgetWord,
      TodayResultKind.overspentUnderRupee =>
        '${TransactionsCopy.overspentWord} '
            '${TransactionsCopy.lessThanOneRupee}',
      TodayResultKind.overspent =>
        '${TransactionsCopy.overspentWord} '
            '${formatRupeesForSpeech(line.amount)}',
    },
    shortfall: line.hasShortfall ? formatRupeesForSpeech(line.shortfall) : null,
  );
}

class _Line extends StatelessWidget {
  const new({required this.line});

  final TodayLine line;

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
      key: TodayLineView.lineKey,
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
            Text(mark, key: TodayLineView.markKey, style: resultStyle),
            const SizedBox(width: BudgetSpacing.space1),
            Flexible(child: result()),
          ],
        ),
      ],
    );
  }
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
