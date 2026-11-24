import 'package:daily_budget/core/copy/calendar_copy.dart';
import 'package:daily_budget/core/copy/dashboard_copy.dart';
import 'package:daily_budget/core/copy/storage_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/help/first_time_hint.dart';
import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/month_browser.dart';
import 'package:daily_budget/core/providers/month_state_provider.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:daily_budget/core/widgets/empty_state.dart';
import 'package:daily_budget/core/widgets/month_switcher.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:daily_budget/features/dashboard/dashboard_state.dart';
import 'package:daily_budget/features/dashboard/widgets/numbers_card.dart';
import 'package:daily_budget/features/dashboard/widgets/other_hint_card.dart';
import 'package:daily_budget/features/dashboard/widgets/statement_link_row.dart';
import 'package:daily_budget/features/dashboard/widgets/where_money_went_card.dart';
import 'package:daily_budget/features/day_details/open_day_details.dart';
import 'package:daily_budget/features/month_setup/month_setup_controller.dart';
import 'package:daily_budget/features/shell/app_tab.dart';
import 'package:daily_budget/features/shell/selected_tab_provider.dart';
import 'package:daily_budget/features/shell/tab_page.dart';
import 'package:daily_budget/features/statement/open_month_statement.dart';
import 'package:daily_budget/features/transactions/month_setup_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Dashboard tab (F-013): where the money went, by category, and a few
/// honest numbers over the days that have ended. It only displays numbers
/// the engine and the pure statistics in `domain/budget/` worked out.
class DashboardTab extends ConsumerStatefulWidget {
  const new({required this.controller, super.key});

  final ScrollController controller;

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  /// The last month that was ready. It stays on screen while the next month
  /// loads, so changing month never flashes the placeholders; they are only
  /// for the very first load (design section 8, as `CalendarSection._shown`).
  MonthDashboard? _shown;

  @override
  Widget build(BuildContext context) {
    const hint = FirstTimeHint(id: HintId.dashboard);
    final title = AppTab.dashboard.title;

    Widget page(Widget body) => TabPage(
      title: title,
      controller: widget.controller,
      hint: hint,
      body: body,
    );

    final view = ref.watch(dashboardViewProvider);
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
    if (value is MonthDashboard) {
      _shown = value;
    } else if (value != null) {
      _shown = null;
    }
    if (value == null) {
      final shown = _shown;
      return page(
        shown == null ? const _LoadingView() : _MonthBody(view: shown),
      );
    }

    switch (value) {
      case NoMonthDashboard():
        final launchSetup = ref.read(monthSetupLauncherProvider);
        return page(
          EmptyState(
            icon: Icons.insights_outlined,
            title: DashboardCopy.noMonthTitle,
            description: DashboardCopy.noMonthDescription,
            action: BudgetButton.primary(
              label: DashboardCopy.noMonthButton,
              semanticsHint: DashboardCopy.noMonthHint,
              onPressed: () => launchSetup(context, const FirstSetupMode()),
            ),
          ),
        );
      case MonthDashboard():
        return page(_MonthBody(view: value));
    }
  }
}

class _MonthBody extends ConsumerWidget {
  const new({required this.view});

  final MonthDashboard view;

  /// The content column stays at most this wide in landscape (design 11).
  static const double _maxWidth = 600;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.read(dashboardSelectionProvider.notifier);
    final showTip =
        view.breakdown.kind == BreakdownKind.single &&
        view.breakdown.singleCategory!.isOther;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BudgetSpacing.space5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MonthHeader(view: view),
              const SizedBox(height: BudgetSpacing.space3),
              WhereMoneyWentCard(
                view: view,
                onRange: selection.selectRange,
                onDay: selection.pickDay,
              ),
              if (showTip) ...[
                const SizedBox(height: BudgetSpacing.space3),
                OtherHintCard(
                  onGoToTransactions: () => ref
                      .read(selectedTabProvider.notifier)
                      .select(AppTab.transactions),
                ),
              ],
              const SizedBox(height: BudgetSpacing.space4),
              NumbersCard(
                figures: view.figures,
                ended: view.ended,
                onOpenDay: (date) =>
                    openDayDetails(context, monthId: view.monthId, date: date),
              ),
              const SizedBox(height: BudgetSpacing.space4),
              StatementLinkRow(
                onTap: () => openMonthStatement(context, view.monthId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The month being shown, in the shared `MonthSwitcher` (design system 7.14):
/// `5 Nov – 4 Dec 2026 · so far`, or `Last month · 5 Nov – 4 Dec 2026` when a
/// new month is not set up yet; ‹ and › move between the stored months (D-074)
/// and a past month carries an `Ended` tag and a `This month` button.
class _MonthHeader extends ConsumerWidget {
  const new({required this.view});

  final MonthDashboard view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = [
      for (final m in ref.watch(monthIndexProvider).value ?? const <MonthRef>[])
        m.id,
    ];
    final browse = ids.isEmpty ? null : MonthBrowse.of(ids, view.monthId);
    final selection = ref.read(dashboardSelectionProvider.notifier);
    void move(int id) => id == ids.first
        ? selection.followCurrentMonth()
        : selection.selectMonth(id);

    final range = _rangeText(view.headerStart, view.headerEnd);
    final isPast = browse != null && !browse.isLatest;
    return MonthSwitcher(
      range: view.notSetUp ? DashboardCopy.lastMonth(range) : range,
      tag: isPast ? CalendarCopy.ended : null,
      suffix: view.ended ? null : DashboardCopy.soFar,
      onPrevious: browse != null && browse.canGoBack
          ? () => move(browse.previousId)
          : null,
      onNext: browse != null && browse.canGoForward
          ? () => move(browse.nextId)
          : null,
      previousLabel: CalendarCopy.previousMonth,
      nextLabel: CalendarCopy.nextMonth,
      previousDisabledHint: CalendarCopy.noEarlierMonths,
      nextDisabledHint: view.notSetUp
          ? CalendarCopy.thisIsTheLatestMonth
          : CalendarCopy.thisIsTheCurrentMonth,
      onThisMonth: isPast ? selection.followCurrentMonth : null,
      thisMonthLabel: CalendarCopy.thisMonth,
      thisMonthHint: CalendarCopy.thisMonthHint,
    );
  }
}

/// `5 Nov – 4 Dec 2026`, or `1 – 30 Nov 2026` inside one month (the calendar
/// design's form).
String _rangeText(CalendarDate start, CalendarDate end) {
  final endText = '${formatDayMonth(end)} ${end.year}';
  final sameMonth = start.month == end.month && start.year == end.year;
  return sameMonth
      ? '${start.day} – $endText'
      : '${formatDayMonth(start)} – $endText';
}

/// The cards drawn with static placeholders while the stores answer: never a
/// `₹0` or `0%` (design section 8, loading).
class _LoadingView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: DashboardCopy.loading,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BudgetSpacing.space5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BudgetCard(
                title: DashboardCopy.sectionTitle,
                child: Column(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(height: BudgetSpacing.space4),
                      const _PlaceholderBar(widthFactor: 1),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: BudgetSpacing.space4),
              const BudgetCard(
                title: DashboardCopy.numbersTitle,
                child: Column(
                  children: [
                    _PlaceholderBar(widthFactor: 0.6),
                    SizedBox(height: BudgetSpacing.space4),
                    _PlaceholderBar(widthFactor: 0.4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderBar extends StatelessWidget {
  const new({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: context.budgetColors.neutralSoft,
          borderRadius: BorderRadius.circular(BudgetRadii.full),
        ),
      ),
    );
  }
}
