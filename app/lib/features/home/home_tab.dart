import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/core/help/first_time_hint.dart';
import 'package:daily_budget/core/widgets/empty_state.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:daily_budget/features/shell/app_tab.dart';
import 'package:daily_budget/features/shell/tab_page.dart';
import 'package:flutter/material.dart';

/// The Home tab. Phase 1: an empty state until month setup exists (F-003 AC-4).
class HomeTab extends StatelessWidget {
  const new({required this.controller, super.key});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return TabPage(
      title: AppTab.home.title,
      controller: controller,
      hint: const FirstTimeHint(id: HintId.home),
      body: const EmptyState(
        icon: Icons.today_outlined,
        title: ScreenCopy.homeEmptyTitle,
        description: ScreenCopy.homeEmptyDescription,
      ),
    );
  }
}
