import 'package:daily_budget/core/copy/statement_copy.dart';
import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/statement/statement_text.dart';
import 'package:daily_budget/features/statement/widgets/rich_money.dart';
import 'package:flutter/material.dart';

/// The working line in its own `sunken` strip (design S-3): the sum, then
/// `→ ₹552/day (i)`. It wraps only between chunks (` = `, `, minus `,
/// ` → `); when a chunk is wider than the strip it relaxes to wrapping at
/// spaces, still never inside an amount. A shortfall or zero period shows
/// its panel under the line.
class WorkingStrip extends StatelessWidget {
  const new({required this.working, super.key});

  final StatementWorking working;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final line = workingLineText(working);
    final help = dailyHelpText(working);
    final panel = panelText(working);
    final style = BudgetTypeScale.bodyLarge.copyWith(color: colors.textPrimary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.sunken,
            borderRadius: const BorderRadius.all(
              Radius.circular(BudgetRadii.md),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BudgetSpacing.space4,
              vertical: BudgetSpacing.space3,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final relaxed = chunksTooWide(
                  context,
                  line.chunks,
                  style,
                  constraints.maxWidth,
                );
                final text = joinChunks(line.chunks, relaxed: relaxed);
                return Semantics(
                  container: true,
                  explicitChildNodes: true,
                  child: Text.rich(
                    TextSpan(
                      style: style,
                      children: [
                        ...moneySpans(text, style, speech: line.speech),
                        if (help != null) ...[
                          const TextSpan(text: '\u2060', semanticsLabel: ''),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: InfoButton(
                              label: StatementCopy.dailyBudgetLabel,
                              info: (
                                title: StatementCopy.dailyBudgetTitle,
                                body: help,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (panel != null) ...[
          const SizedBox(height: BudgetSpacing.space2),
          _Panel(
            text: panel.text,
            speech: panel.speech,
            zero: working is ZeroWorking,
          ),
        ],
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const new({required this.text, required this.speech, required this.zero});

  final String text;
  final String speech;
  final bool zero;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final color = zero ? colors.neutral : colors.overspent;
    final style = BudgetTypeScale.label.copyWith(
      fontWeight: FontWeight.w600,
      color: color,
    );
    return Semantics(
      container: true,
      label: speech,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: zero ? colors.neutralSoft : colors.overspentSoft,
            borderRadius: const BorderRadius.all(
              Radius.circular(BudgetRadii.md),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(BudgetSpacing.space3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zero ? '○' : '◆', style: style),
                const SizedBox(width: BudgetSpacing.space1),
                Expanded(child: Text(text, style: style)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
