import 'package:daily_budget/core/copy/home_copy.dart';
import 'package:daily_budget/core/copy/transactions_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:daily_budget/core/widgets/today_result_line.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/home/widgets/home_layout.dart';
import 'package:flutter/material.dart';

/// Home's Today card (F-010 AC-5, `home-summary.md` §5): the shared Today
/// result line under a `Today · Fri, 13 Nov` header, a refunds line when
/// today has money in, and the whole card is one button to today's details.
///
/// A screen reader gets one sentence; the (i) is its own stop. When [date]
/// changes (midnight) the card cross-fades to the new day.
class HomeTodayCard extends StatelessWidget {
  const new({
    required this.line,
    required this.date,
    required this.onTap,
    super.key,
  });

  final TodayLine line;

  final CalendarDate date;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: BudgetMotion.of(context).base,
      child: _Card(
        key: ValueKey(date.dayNumber),
        line: line,
        date: date,
        onTap: onTap,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const new({
    required this.line,
    required this.date,
    required this.onTap,
    super.key,
  });

  final TodayLine line;
  final CalendarDate date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final speech = HomeCopy.todaySpeech(
      date: formatFullDate(date),
      budget: formatRupeesForSpeech(line.budget),
      spent: formatRupeesForSpeech(line.netSpent),
      result: TodayResultLine.resultSpeech(line),
      refunds: line.hasRefunds ? formatRupeesForSpeech(line.moneyIn) : null,
    );
    return BudgetCard(
      padding: EdgeInsets.zero,
      child: Semantics(
        container: true,
        button: true,
        label: speech,
        hint: HomeCopy.todayHint,
        onTap: onTap,
        child: InkWell(
          onTap: onTap,
          excludeFromSemantics: true,
          highlightColor: colors.sunken,
          child: Padding(
            padding: const EdgeInsets.all(BudgetSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // The heading and the (i) take all the room the chevron
                    // leaves (a Spacer here halved the heading's width: B-006).
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: ExcludeSemantics(
                              // `Today ·` and the date are unbreakable:
                              // a narrow line breaks only after the dot
                              // (B-006).
                              child: ChunkedText(
                                style: context.budgetText.title.copyWith(
                                  color: colors.textPrimary,
                                ),
                                chunks: [
                                  const TextSpan(
                                    text: HomeCopy.todayHeaderLead,
                                  ),
                                  TextSpan(text: formatWeekdayDayMonth(date)),
                                ],
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
                    ),
                    ExcludeSemantics(
                      child: Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                ExcludeSemantics(child: TodayResultLine(line: line)),
                if (line.hasRefunds)
                  Padding(
                    padding: const EdgeInsets.only(top: BudgetSpacing.space1),
                    child: ExcludeSemantics(
                      child: Text(
                        HomeCopy.refundsLine(formatRupees(line.moneyIn)),
                        style: BudgetTypeScale.body.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
