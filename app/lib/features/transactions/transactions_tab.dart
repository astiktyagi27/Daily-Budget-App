import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/core/help/first_time_hint.dart';
import 'package:daily_budget/core/widgets/empty_state.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:daily_budget/features/shell/app_tab.dart';
import 'package:daily_budget/features/shell/tab_page.dart';
import 'package:flutter/material.dart';

/// The Transactions tab. Phase 1: an empty state (F-003 AC-4).
class TransactionsTab extends StatelessWidget {
  const new({required this.controller, super.key});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return TabPage(
      title: AppTab.transactions.title,
      controller: controller,
      hint: const FirstTimeHint(id: HintId.transactions),
      body: const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: ScreenCopy.transactionsEmptyTitle,
        description: ScreenCopy.transactionsEmptyDescription,
      ),
    );
  }
}
