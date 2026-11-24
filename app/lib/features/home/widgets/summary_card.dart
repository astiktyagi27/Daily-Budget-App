import 'package:daily_budget/core/copy/home_copy.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/home/home_state.dart';
import 'package:daily_budget/features/home/widgets/budget_changed_line.dart';
import 'package:daily_budget/features/home/widgets/notice_panel.dart';
import 'package:daily_budget/features/home/widgets/safe_to_spend_strip.dart';
import 'package:daily_budget/features/home/widgets/summary_hero.dart';
import 'package:daily_budget/features/home/widgets/summary_ledger.dart';
import 'package:flutter/material.dart';

/// Home's summary card (F-010 §2.2, `home-summary.md` §4), in the order of
/// the design (H-2): hero, progress rule, day line, Safe to spend strip,
/// panels and the budget-changed line, ledger, `Month statement`.
class SummaryCard extends StatelessWidget {
  const new({
    required this.home,
    required this.onEdit,
    required this.onOpenStatement,
    super.key,
  });

  final ActiveHome home;

  /// Null when the month cannot be edited today.
  final VoidCallback? onEdit;

  final VoidCallback onOpenStatement;

  @override
  Widget build(BuildContext context) {
    final summary = home.summary;
    final changed = summary.latestChangeDay;
    return BudgetCard(
      padding: const EdgeInsets.all(BudgetSpacing.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SummaryHero(summary: summary, onEdit: onEdit),
          if (home.safeToSpend case final value
              when value is! SafeToSpendUnavailable) ...[
            const SizedBox(height: BudgetSpacing.space3),
            SafeToSpendStrip(value: value),
          ],
          if (summary.hasShortfall) ...[
            const SizedBox(height: BudgetSpacing.space3),
            HomeNoticePanel.shortfall(shortfall: summary.shortfall),
          ] else if (summary.zeroSpendable) ...[
            const SizedBox(height: BudgetSpacing.space3),
            const HomeNoticePanel.zero(),
          ],
          if (changed != null) ...[
            const SizedBox(height: BudgetSpacing.space3),
            BudgetChangedLine(day: changed, onSeeStatement: onOpenStatement),
          ],
          const SizedBox(height: BudgetSpacing.space3),
          const Divider(),
          SummaryLedger(summary: summary),
          const Divider(),
          _StatementRow(onTap: onOpenStatement),
        ],
      ),
    );
  }
}

class _StatementRow extends StatelessWidget {
  const new({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Semantics(
      container: true,
      button: true,
      label: HomeCopy.monthStatement,
      hint: HomeCopy.monthStatementHint,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: BudgetSpacing.touchTarget,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  HomeCopy.monthStatement,
                  style: BudgetTypeScale.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 24, color: colors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
