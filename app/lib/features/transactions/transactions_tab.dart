import 'package:daily_budget/core/copy/storage_copy.dart';
import 'package:daily_budget/core/copy/transactions_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/help/first_time_hint.dart';
import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/month_state_provider.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/empty_state.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:daily_budget/features/month_setup/month_setup_controller.dart';
import 'package:daily_budget/features/shell/app_tab.dart';
import 'package:daily_budget/features/shell/tab_page.dart';
import 'package:daily_budget/features/transactions/month_setup_launcher.dart';
import 'package:daily_budget/features/transactions/spend_editor_flow.dart';
import 'package:daily_budget/features/transactions/spend_list.dart';
import 'package:daily_budget/features/transactions/today_line_view.dart';
import 'package:daily_budget/features/transactions/transactions_state.dart';
import 'package:daily_budget/features/transactions/widgets/new_month_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Transactions tab (F-009 §2.1, `transactions.md` §3, §6): the Today
/// card and this month's spends by day, or the state that explains why not.
/// The floating Add spend button belongs to the shell (`AddSpendButton`).
class TransactionsTab extends ConsumerWidget {
  const new({required this.controller, super.key});

  final ScrollController controller;

  /// Room under the list so the last row scrolls clear of the button.
  static const double _buttonClearance = 88;

  /// Above this text size the first-time tip sits under the Today card, so
  /// the Add spend button never covers the Today line (`transactions.md`
  /// §3.1).
  static const double _tipBelowTodayAbove = 1.3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const hint = FirstTimeHint(id: HintId.transactions);
    final title = AppTab.transactions.title;
    final launchSetup = ref.read(monthSetupLauncherProvider);

    Widget page(Widget body) =>
        TabPage(title: title, controller: controller, hint: hint, body: body);

    final view = ref.watch(transactionsViewProvider);
    if (view.hasError) {
      return page(
        EmptyState(
          icon: Icons.error_outline,
          title: StorageCopy.loadErrorTitle,
          description: StorageCopy.loadErrorDescription,
          action: BudgetButton.primary(
            label: StorageCopy.tryAgain,
            semanticsHint: StorageCopy.loadErrorHint,
            onPressed: () {
              ref
                ..invalidate(latestMonthProvider)
                ..invalidate(monthSpendsProvider)
                ..invalidate(storedMonthProvider)
                ..invalidate(monthCoversProvider);
            },
          ),
        ),
      );
    }
    final value = view.value;
    if (value == null) return page(const SizedBox.shrink());

    switch (value) {
      case NoMonthView():
        return page(
          EmptyState(
            icon: Icons.event_outlined,
            title: TransactionsCopy.noMonthTitle,
            description: TransactionsCopy.noMonthDescription,
            action: BudgetButton.primary(
              label: TransactionsCopy.noMonthButton,
              semanticsHint: TransactionsCopy.noMonthHint,
              onPressed: () => launchSetup(context, const FirstSetupMode()),
            ),
          ),
        );
      case CurrentMonthView(:final line, :final spends, :final today):
        final tipBelowToday =
            line != null &&
            MediaQuery.textScalerOf(context).scale(1) > _tipBelowTodayAbove;
        return TabPage.slivers(
          title: title,
          controller: controller,
          hint: tipBelowToday ? null : hint,
          bodySlivers: [
            if (line != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BudgetSpacing.space5,
                  ),
                  child: TodayLineView(line: line),
                ),
              ),
            if (tipBelowToday) const SliverToBoxAdapter(child: hint),
            if (spends.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: TransactionsCopy.noSpendsTitle,
                  description: TransactionsCopy.noSpendsDescription,
                ),
              )
            else
              SpendListSliver(
                spends: spends,
                today: today,
                onOpen: line == null
                    ? null
                    : (spend) => openSpendEditor(context, ref, edit: spend),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: _buttonClearance)),
          ],
        );
      case NewMonthView(:final lastMonth, :final spends, :final today):
        return TabPage.slivers(
          title: title,
          controller: controller,
          hint: hint,
          bodySlivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BudgetSpacing.space5,
                ),
                child: NewMonthCard(
                  onSetUp: () => launchSetup(context, NewMonthMode(lastMonth)),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  BudgetSpacing.space5,
                  BudgetSpacing.space6,
                  BudgetSpacing.space5,
                  0,
                ),
                child: Semantics(
                  header: true,
                  child: Text(
                    TransactionsCopy.lastMonthLabel(
                      formatRange(lastMonth.month.start, lastMonth.month.end),
                    ),
                    style: BudgetTypeScale.caption.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.budgetColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            SpendListSliver(spends: spends, today: today, onOpen: null),
            const SliverToBoxAdapter(child: SizedBox(height: _buttonClearance)),
          ],
        );
    }
  }
}
