import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/core/help/first_time_hint.dart';
import 'package:daily_budget/core/widgets/empty_state.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:daily_budget/features/shell/app_tab.dart';
import 'package:daily_budget/features/shell/tab_page.dart';
import 'package:flutter/material.dart';

/// The Dashboard tab. Phase 1: an empty state (F-003 AC-4).
class DashboardTab extends StatelessWidget {
  const new({required this.controller, super.key});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return TabPage(
      title: AppTab.dashboard.title,
      controller: controller,
      hint: const FirstTimeHint(id: HintId.dashboard),
      body: const EmptyState(
        icon: Icons.insights_outlined,
        title: ScreenCopy.dashboardEmptyTitle,
        description: ScreenCopy.dashboardEmptyDescription,
      ),
    );
  }
}
