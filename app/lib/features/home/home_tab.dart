import 'dart:async';

import 'package:daily_budget/core/copy/month_setup_copy.dart';
import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/core/copy/storage_copy.dart';
import 'package:daily_budget/core/help/first_time_hint.dart';
import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/month_state_provider.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/empty_state.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:daily_budget/features/home/this_month_card.dart';
import 'package:daily_budget/features/month_setup/month_setup_controller.dart';
import 'package:daily_budget/features/month_setup/month_setup_screen.dart';
import 'package:daily_budget/features/shell/app_tab.dart';
import 'package:daily_budget/features/shell/tab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Home tab. Phase 2 (F-008): the month states. No month yet offers
/// **Set up your month**, a started new month offers **Set up this month**,
/// a set-up month shows the **This month** card, and a failed read shows
/// **Try again** (never the set-up invitation, F-008 AC-11). The full Home
/// summary is Phase 3.
class HomeTab extends ConsumerStatefulWidget {
  const new({required this.controller, super.key});

  final ScrollController controller;

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  /// True from a tap on a setup button until its screen is closed, so a
  /// double tap opens one screen (F-008 AC-1, TC-008-49).
  bool _opening = false;

  Future<void> _open(SetupMode mode) async {
    if (_opening) return;
    _opening = true;
    try {
      await MonthSetupScreen.open(context, mode);
    } finally {
      _opening = false;
    }
  }

  void _reload() {
    ref
      ..invalidate(latestMonthProvider)
      ..invalidate(storedMonthProvider)
      ..invalidate(monthSpendsProvider)
      ..invalidate(monthCoversProvider);
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    return TabPage(
      title: AppTab.home.title,
      controller: widget.controller,
      hint: const FirstTimeHint(id: HintId.home),
      body: switch (ref.watch(currentMonthStateProvider)) {
        AsyncError() => EmptyState(
          icon: Icons.error_outline,
          title: StorageCopy.loadErrorTitle,
          description: StorageCopy.loadErrorDescription,
          action: BudgetButton.primary(
            label: StorageCopy.tryAgain,
            semanticsHint: StorageCopy.loadErrorHint,
            onPressed: _reload,
          ),
        ),
        AsyncData(:final value) => switch (value) {
          NoMonthSetUp() => EmptyState(
            icon: Icons.today_outlined,
            title: ScreenCopy.homeEmptyTitle,
            description: ScreenCopy.homeEmptyDescription,
            action: BudgetButton.primary(
              label: MonthSetupCopy.titleFirst,
              semanticsHint: MonthSetupCopy.homeSetUpHint,
              onPressed: () => unawaited(_open(const FirstSetupMode())),
            ),
          ),
          NewMonthDue(:final lastMonth) => _Padded(
            child: NewMonthCard(
              onSetUp: () => unawaited(_open(NewMonthMode(lastMonth))),
            ),
          ),
          ActiveMonth(:final stored, :final result) => _Padded(
            child: ThisMonthCard(
              result: result,
              today: today,
              // An edit needs today inside the month (a phone date set back
              // would leave nothing to recalculate).
              onEdit:
                  stored.month.contains(today) &&
                      !today.isBefore(stored.firstBudgetedDay)
                  ? () => unawaited(_open(EditMonthMode(stored)))
                  : null,
            ),
          ),
        },
        // The first read takes a few milliseconds; nothing to show yet.
        _ => const SizedBox(width: double.infinity),
      },
    );
  }
}

class _Padded extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: BudgetSpacing.space5),
    child: child,
  );
}
