import 'package:daily_budget/core/copy/safe_to_spend_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// The Safe to spend guide strip inside Home's summary card (F-017,
/// `home-summary.md` H-1): a `sunken` inset with its own label and (i), the
/// amount in ink, never green or red, so it is not mistaken for today's
/// budget. It only draws a [SafeToSpend]; the figure is worked out in the
/// domain layer. [SafeToSpendUnavailable] draws nothing.
///
/// A screen reader gets one sentence (`Safe to spend, ₹899 a day, 22 days
/// left`); the (i) is its own stop.
class SafeToSpendStrip extends StatelessWidget {
  const new({required this.value, super.key});

  final SafeToSpend value;

  /// Names the value line so tests can read its text.
  static const ValueKey<String> valueKey = ValueKey('safe-to-spend-value');

  @override
  Widget build(BuildContext context) {
    final speech = switch (value) {
      SafeToSpendAmount(:final perDay, :final daysLeft) =>
        SafeToSpendCopy.speech(formatRupeesForSpeech(perDay), daysLeft),
      SafeToSpendUnderRupee(:final daysLeft) =>
        SafeToSpendCopy.underRupeeSpeech(daysLeft),
      SafeToSpendNothingLeft() => SafeToSpendCopy.nothingLeftSpeech,
      SafeToSpendUnavailable() => null,
    };
    if (speech == null) return const SizedBox.shrink();

    final colors = context.budgetColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.sunken,
        borderRadius: const BorderRadius.all(Radius.circular(BudgetRadii.md)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BudgetSpacing.space4,
          vertical: BudgetSpacing.space2,
        ),
        child: Semantics(
          container: true,
          label: speech,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Flexible(
                    child: ExcludeSemantics(
                      child: Text(
                        SafeToSpendCopy.label,
                        style: BudgetTypeScale.label.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const InfoButton(
                    label: SafeToSpendCopy.label,
                    info: (
                      title: SafeToSpendCopy.label,
                      body: SafeToSpendCopy.infoBody,
                    ),
                  ),
                ],
              ),
              ExcludeSemantics(child: _Value(value: value)),
              const SizedBox(height: BudgetSpacing.space2),
            ],
          ),
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const new({required this.value});

  final SafeToSpend value;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final amountStyle = BudgetTypeScale.moneyMedium.copyWith(
      color: colors.textPrimary,
    );
    final wordsStyle = BudgetTypeScale.body.copyWith(
      color: colors.textSecondary,
    );
    // Non-breaking spaces keep `₹899 a day` and `22 days left` whole, so a
    // long line wraps only at the dot between them.
    String whole(String text) => text.replaceAll(' ', '\u00A0');
    InlineSpan daysLeftSpan(int days) => TextSpan(
      text:
          '\u00A0${SafeToSpendCopy.separator.trim()} '
          '${whole(SafeToSpendCopy.daysLeft(days))}',
      style: wordsStyle,
    );

    return switch (value) {
      SafeToSpendAmount(:final perDay, daysLeft: final days) => Text.rich(
        key: SafeToSpendStrip.valueKey,
        TextSpan(
          children: [
            TextSpan(
              text: whole(SafeToSpendCopy.aDay(formatRupees(perDay))),
              style: amountStyle,
            ),
            daysLeftSpan(days),
          ],
        ),
      ),
      SafeToSpendUnderRupee(daysLeft: final days) => Text.rich(
        key: SafeToSpendStrip.valueKey,
        TextSpan(
          children: [
            TextSpan(
              text: whole(SafeToSpendCopy.underRupeeADay),
              style: amountStyle,
            ),
            daysLeftSpan(days),
          ],
        ),
      ),
      SafeToSpendNothingLeft() => Text(
        SafeToSpendCopy.nothingLeft,
        key: SafeToSpendStrip.valueKey,
        style: BudgetTypeScale.body.copyWith(color: colors.textPrimary),
      ),
      SafeToSpendUnavailable() => const SizedBox.shrink(),
    };
  }
}
