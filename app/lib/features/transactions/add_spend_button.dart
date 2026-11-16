import 'package:daily_budget/core/copy/transactions_copy.dart';
import 'package:daily_budget/core/help/nav_tooltip.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/features/transactions/spend_editor_flow.dart';
import 'package:daily_budget/features/transactions/transactions_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The floating **Add spend** button of the Transactions tab
/// (`transactions.md` §7). The shell shows it on that tab only, so the
/// Scaffold keeps it clear of the bottom bar and lifts it over snackbars. It
/// is there whenever a month is set up (or has ended, where it opens the
/// new-month sheet) and nowhere else.
class AddSpendButton extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = switch (ref.watch(transactionsViewProvider).value) {
      CurrentMonthView(:final canAdd) => canAdd,
      NewMonthView() => true,
      _ => false,
    };
    if (!shown) return const SizedBox.shrink();
    final colors = context.budgetColors;
    const radius = BorderRadius.all(Radius.circular(BudgetRadii.md));
    return Padding(
      // The Scaffold keeps 16 dp from the edge; the design asks for 20.
      padding: const EdgeInsets.only(right: BudgetSpacing.space1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: context.budgetElevation.float,
        ),
        child: NavTooltip(
          message: TransactionsCopy.addSpendTooltip,
          child: FloatingActionButton.extended(
            onPressed: () => openSpendEditor(context, ref),
            icon: const Icon(Icons.add),
            label: const Text(TransactionsCopy.addSpend),
            backgroundColor: colors.accent,
            foregroundColor: colors.onAccent,
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: radius),
            extendedTextStyle: BudgetTypeScale.button,
          ),
        ),
      ),
    );
  }
}
