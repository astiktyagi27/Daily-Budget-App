import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/widgets/root_page.dart';
import 'package:daily_budget/features/dashboard/dashboard_tab.dart';
import 'package:daily_budget/features/home/home_tab.dart';
import 'package:daily_budget/features/settings/settings_tab.dart';
import 'package:daily_budget/features/shell/app_tab.dart';
import 'package:daily_budget/features/shell/budget_navigation_bar.dart';
import 'package:daily_budget/features/shell/selected_tab_provider.dart';
import 'package:daily_budget/features/transactions/add_spend_button.dart';
import 'package:daily_budget/features/transactions/transactions_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's frame: the four tabs and the bottom bar (F-003).
///
/// The selected tab is session-only state in [selectedTabProvider]: the app
/// always opens on Home (AC-7). An [IndexedStack] keeps every tab alive, so
/// each keeps its scroll position while the app runs (AC-9).
class AppShell extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {
  final Map<AppTab, ScrollController> _controllers = {
    for (final tab in AppTab.values) tab: ScrollController(),
  };

  /// Fades the newly selected tab in (app-shell §3.4).
  late final _fade = AnimationController(vsync: this, value: 1);

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _fade.dispose();
    super.dispose();
  }

  void _select(AppTab tab) {
    if (tab == ref.read(selectedTabProvider)) {
      final motion = BudgetMotion.of(context);
      // Re-tap: back to the top if scrolled, otherwise nothing.
      final controller = _controllers[tab]!;
      if (!controller.hasClients || controller.offset <= 0) return;
      if (motion.emphasis == Duration.zero) {
        controller.jumpTo(0);
      } else {
        controller.animateTo(
          0,
          duration: motion.emphasis,
          curve: BudgetMotion.decelerate,
        );
      }
      return;
    }
    ref.read(selectedTabProvider.notifier).select(tab);
  }

  /// Fades the new tab in, however the change came (bar, Back, or a screen
  /// that sends the user to another tab).
  void _onTabChanged(AppTab? previous, AppTab next) {
    if (previous == next) return;
    _fade
      ..duration = BudgetMotion.of(context).base
      ..forward(from: 0);
  }

  Widget _page(AppTab tab) {
    final controller = _controllers[tab]!;
    return switch (tab) {
      AppTab.home => HomeTab(controller: controller),
      AppTab.dashboard => DashboardTab(controller: controller),
      AppTab.transactions => TransactionsTab(controller: controller),
      AppTab.settings => SettingsTab(controller: controller),
    };
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedTabProvider);
    ref.listen(selectedTabProvider, _onTabChanged);
    return RootPopScope(
      // Back on another tab goes Home; back on Home leaves the app (AC-8).
      canPop: selected == AppTab.home,
      onBack: () => _select(AppTab.home),
      child: Scaffold(
        body: IndexedStack(
          index: selected.index,
          children: [
            for (final tab in AppTab.values)
              // Offstage tabs keep their state but run no animations.
              TickerMode(
                enabled: tab == selected,
                child: FadeTransition(
                  opacity: tab == selected ? _fade : kAlwaysCompleteAnimation,
                  child: _page(tab),
                ),
              ),
          ],
        ),
        floatingActionButton: selected == AppTab.transactions
            ? const AddSpendButton()
            : null,
        bottomNavigationBar: BudgetNavigationBar(
          selected: selected,
          onSelect: _select,
        ),
      ),
    );
  }
}
