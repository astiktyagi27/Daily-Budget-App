import 'package:daily_budget/core/copy/statement_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/statement/statement_text.dart';
import 'package:daily_budget/features/statement/widgets/rich_money.dart';
import 'package:flutter/material.dart';

/// What changed (design §6): one dated line per stored period record, oldest
/// first. A single period adds `No changes this month.`
class WhatChangedCard extends StatelessWidget {
  const new({required this.statement, super.key});

  final MonthStatement statement;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final changes = statement.changes;
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
                    StatementCopy.whatChanged,
                    style: context.budgetText.title.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              const InfoButton(
                label: StatementCopy.whatChanged,
                info: (
                  title: StatementCopy.whatChanged,
                  body: StatementCopy.whatChangedInfo,
                ),
              ),
            ],
          ),
          for (final (i, change) in changes.indexed) ...[
            if (i > 0)
              Divider(height: BudgetSpacing.space4, color: colors.border),
            _ChangeLine(change: change),
          ],
          if (changes.length == 1) ...[
            const SizedBox(height: BudgetSpacing.space2),
            Text(
              StatementCopy.noChanges,
              style: BudgetTypeScale.body.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChangeLine extends StatelessWidget {
  const new({required this.change});

  final StatementChange change;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final line = changeLineText(change);
    final color = change.replacedSameDay
        ? colors.textSecondary
        : colors.textPrimary;
    final body = BudgetTypeScale.body.copyWith(color: color);
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;

    final date = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatDayMonth(change.date),
          style: BudgetTypeScale.label.copyWith(color: colors.textPrimary),
        ),
        if (change.showTime)
          Text(
            formatClockTime(change.changedAt),
            style: BudgetTypeScale.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
      ],
    );
    final text = LayoutBuilder(
      builder: (context, constraints) {
        final relaxed = chunksTooWide(
          context,
          line.chunks,
          body,
          constraints.maxWidth,
        );
        return Text.rich(
          TextSpan(
            style: body,
            children: moneySpans(
              joinChunks(line.chunks, relaxed: relaxed),
              body,
            ),
          ),
        );
      },
    );
    return Semantics(
      container: true,
      label: line.speech,
      child: ExcludeSemantics(
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  date,
                  const SizedBox(height: BudgetSpacing.space1),
                  text,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 64, child: date),
                  Expanded(child: text),
                ],
              ),
      ),
    );
  }
}
