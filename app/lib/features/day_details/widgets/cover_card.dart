import 'package:daily_budget/core/copy/day_details_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// The Cover card of an overspent budgeted day (`day-details.md` §5): the
/// pot, one sentence and **Cover with savings**; with an empty pot the card
/// says so and has no button. A fully covered day shows the inline note
/// instead (see [CoveredNote]).
class CoverCard extends StatelessWidget {
  const new({required this.day, required this.onCover, super.key});

  final DaySummary day;

  final VoidCallback onCover;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final empty = day.coverOffer is CoverPotEmpty;
    final pot = day.pot;
    return BudgetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Semantics(
                  container: true,
                  label:
                      '${DayDetailsCopy.savingsPot}, '
                      '${formatRupeesForSpeech(pot)}',
                  child: ExcludeSemantics(
                    child: Text(
                      DayDetailsCopy.savingsPot,
                      style: BudgetTypeScale.label.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const InfoButton(
                label: DayDetailsCopy.savingsPot,
                info: DayDetailsCopy.savingsPotInfo,
              ),
              const Spacer(),
              ExcludeSemantics(
                child: Text(
                  formatRupees(pot),
                  style: context.budgetText.moneyMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BudgetSpacing.space1),
          if (empty)
            Row(
              children: [
                Flexible(
                  child: Text(
                    DayDetailsCopy.potEmpty,
                    style: BudgetTypeScale.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const InfoButton(
                  label: DayDetailsCopy.potEmpty,
                  info: DayDetailsCopy.potEmptyInfo,
                ),
              ],
            )
          else ...[
            Text(
              DayDetailsCopy.coverSentence,
              style: BudgetTypeScale.body.copyWith(color: colors.textSecondary),
            ),
            if (day.isLive) ...[
              const SizedBox(height: BudgetSpacing.space1),
              Text(
                DayDetailsCopy.todayCoverLine,
                style: BudgetTypeScale.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: BudgetSpacing.space4),
            BudgetButton.primary(
              label: DayDetailsCopy.coverButton,
              semanticsHint: DayDetailsCopy.coverButtonHint,
              onPressed: onCover,
            ),
          ],
        ],
      ),
    );
  }
}

/// `Covered ₹300 from savings.` once the day is fully covered (design §5).
class CoveredNote extends StatelessWidget {
  const new({required this.covered, super.key});

  final Paise covered;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Row(
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.savings_outlined,
            size: 16,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(width: BudgetSpacing.space2),
        Flexible(
          child: Text(
            DayDetailsCopy.fullyCovered(formatRupees(covered)),
            style: BudgetTypeScale.body.copyWith(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }
}
