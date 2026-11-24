import 'dart:async';

import 'package:daily_budget/core/copy/month_setup_copy.dart';
import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/core/copy/storage_copy.dart';
import 'package:daily_budget/core/help/first_time_hint.dart';
import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/month_state_provider.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/empty_state.dart';
import 'package:daily_budget/core/widgets/tap_cooldown.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:daily_budget/features/day_details/open_day_details.dart';
import 'package:daily_budget/features/home/calendar/calendar_section.dart';
import 'package:daily_budget/features/home/home_state.dart';
import 'package:daily_budget/features/home/widgets/collapsed_summary_row.dart';
import 'package:daily_budget/features/home/widgets/home_layout.dart';
import 'package:daily_budget/features/home/widgets/home_loading.dart';
import 'package:daily_budget/features/home/widgets/home_today_card.dart';
import 'package:daily_budget/features/home/widgets/new_month_card.dart';
import 'package:daily_budget/features/home/widgets/summary_card.dart';
import 'package:daily_budget/features/month_setup/month_setup_controller.dart';
import 'package:daily_budget/features/month_setup/month_setup_screen.dart';
import 'package:daily_budget/features/shell/app_tab.dart';
import 'package:daily_budget/features/shell/tab_page.dart';
import 'package:daily_budget/features/statement/open_month_statement.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Home tab (F-010): the summary card, the Today card and, under them,
/// the calendar (F-011). No month yet offers **Set up your month**, a started
/// new month offers **Set up this month**, a failed read shows **Try again**
/// (never the set-up invitation, F-008 AC-11) and a slow read shows grey
/// placeholders, never a `₹0`.
///
/// Once the summary card has scrolled out of view a pinned row takes its
/// place (AC-15); it is not built above 1.3x text or in landscape.
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

  /// Ignores the second tap of a double tap on the Today card and the
  /// statement links (TC-010-53).
  final TapCooldown _tapCooldown = TapCooldown();

  final GlobalKey _cardKey = GlobalKey();

  /// Whether the summary card's bottom edge is above the top of the page.
  /// Only the pinned row listens, so scrolling rebuilds nothing else.
  final _collapsed = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    _collapsed.dispose();
    _tapCooldown.dispose();
    super.dispose();
  }

  /// True while a measure is queued, so a burst of scroll updates measures
  /// once per frame.
  bool _measureQueued = false;

  /// The scroll position changes before the page is laid out again, so the
  /// card is measured after the frame, with its new place.
  void _onScroll() {
    if (_measureQueued) return;
    _measureQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureQueued = false;
      if (mounted) _measure();
    });
  }

  /// The row shows once the scroll position is past the summary card's
  /// bottom edge. Measured in scroll offsets, not on screen, so the page
  /// moving down when the row appears cannot make it flicker.
  void _measure() {
    final box = _cardKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !widget.controller.hasClients) {
      _collapsed.value = false;
      return;
    }
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return;
    final cardTop = viewport.getOffsetToReveal(box, 0).offset;
    _collapsed.value =
        widget.controller.position.pixels > cardTop + box.size.height;
  }

  Future<void> _open(SetupMode mode) async {
    if (_opening) return;
    _opening = true;
    try {
      await MonthSetupScreen.open(context, mode);
    } finally {
      _opening = false;
    }
  }

  void _once(VoidCallback action) {
    if (_tapCooldown.isActive) return;
    _tapCooldown.start();
    action();
  }

  void _reload() {
    ref
      ..invalidate(latestMonthProvider)
      ..invalidate(storedMonthProvider)
      ..invalidate(monthSpendsProvider)
      ..invalidate(monthCoversProvider);
  }

  Widget _content(HomeView view) {
    switch (view) {
      case NoMonthHome():
        return EmptyState(
          icon: Icons.today_outlined,
          title: ScreenCopy.homeEmptyTitle,
          description: ScreenCopy.homeEmptyDescription,
          action: BudgetButton.primary(
            label: MonthSetupCopy.titleFirst,
            semanticsHint: MonthSetupCopy.homeSetUpHint,
            onPressed: () => unawaited(_open(const FirstSetupMode())),
          ),
        );
      case NewMonthHome(:final lastMonth):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Padded(
              child: NewMonthCard(
                onSetUp: () => unawaited(_open(NewMonthMode(lastMonth))),
              ),
            ),
            const SizedBox(height: BudgetSpacing.space6),
            const CalendarSection(),
          ],
        );
      case final ActiveHome home:
        final line = home.line;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Padded(child: _activeCards(home, line)),
            const SizedBox(height: BudgetSpacing.space6),
            const CalendarSection(),
          ],
        );
    }
  }

  /// The summary card and, on a budgeted day, the Today card.
  Widget _activeCards(ActiveHome home, TodayLine? line) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SummaryCard(
          key: _cardKey,
          home: home,
          onEdit: home.canEdit
              ? () => unawaited(_open(EditMonthMode(home.stored)))
              : null,
          onOpenStatement: () =>
              _once(() => openMonthStatement(context, home.stored.id)),
        ),
        if (line != null) ...[
          const SizedBox(height: BudgetSpacing.space4),
          HomeTodayCard(
            line: line,
            date: home.today,
            onTap: () => _once(
              () => openDayDetails(
                context,
                monthId: home.stored.id,
                date: home.today,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(homeViewProvider);
    final body = switch (view) {
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
      AsyncData(:final value) => _content(value),
      _ => const _Padded(child: HomeLoading()),
    };
    final home = view.value;
    final pinned =
        home is ActiveHome &&
        !isLargeText(context) &&
        MediaQuery.orientationOf(context) == Orientation.portrait;
    final page = TabPage.slivers(
      title: AppTab.home.title,
      controller: widget.controller,
      hint: const FirstTimeHint(id: HintId.home),
      bodySlivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kHomeContentMaxWidth),
              child: body,
            ),
          ),
        ),
      ],
    );
    if (!pinned) return page;
    final summary = home.summary;
    // The pinned row takes its own space above the page, so a row scrolled
    // into view (by a screen reader, say) is never hidden under it. While it
    // shows it also covers the status bar, so the page drops its top inset.
    return ValueListenableBuilder<bool>(
      valueListenable: _collapsed,
      builder: (context, collapsed, _) => Column(
        children: [
          AnimatedSize(
            duration: BudgetMotion.of(context).fast,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: BudgetMotion.of(context).fast,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, -0.15),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: collapsed
                  ? CollapsedSummaryRow(
                      key: const ValueKey('collapsed-row'),
                      summary: summary,
                      onTap: () => widget.controller.animateTo(
                        0,
                        duration: BudgetMotion.of(context).emphasis,
                        curve: BudgetMotion.standard,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: collapsed,
              child: page,
            ),
          ),
        ],
      ),
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
