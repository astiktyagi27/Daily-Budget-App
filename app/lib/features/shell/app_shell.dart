import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/widgets/root_page.dart';
import 'package:daily_budget/features/dashboard/dashboard_tab.dart';
import 'package:daily_budget/features/home/home_tab.dart';
import 'package:daily_budget/features/settings/settings_tab.dart';
import 'package:daily_budget/features/shell/app_tab.dart';
import 'package:daily_budget/features/shell/budget_navigation_bar.dart';
import 'package:daily_budget/features/transactions/add_spend_button.dart';
import 'package:daily_budget/features/transactions/transactions_tab.dart';
import 'package:flutter/material.dart';

/// The app's frame: the four tabs and the bottom bar (F-003).
///
/// The selected tab is session-only state: the app always opens on Home
/// (AC-7). An [IndexedStack] keeps every tab alive, so each keeps its scroll
/// position while the app runs (AC-9).
class AppShell extends StatefulWidget {
  const new({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  AppTab _tab = AppTab.home;
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
    final motion = BudgetMotion.of(context);
    if (tab == _tab) {
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
    setState(() => _tab = tab);
    _fade
      ..duration = motion.base
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
    return RootPopScope(
      // Back on another tab goes Home; back on Home leaves the app (AC-8).
      canPop: _tab == AppTab.home,
      onBack: () => _select(AppTab.home),
      child: Scaffold(
        body: IndexedStack(
          index: _tab.index,
          children: [
            for (final tab in AppTab.values)
              // Offstage tabs keep their state but run no animations.
              TickerMode(
                enabled: tab == _tab,
                child: FadeTransition(
                  opacity: tab == _tab ? _fade : kAlwaysCompleteAnimation,
                  child: _page(tab),
                ),
              ),
          ],
        ),
        floatingActionButton: _tab == AppTab.transactions
            ? const AddSpendButton()
            : null,
        bottomNavigationBar: BudgetNavigationBar(
          selected: _tab,
          onSelect: _select,
        ),
      ),
    );
  }
}
