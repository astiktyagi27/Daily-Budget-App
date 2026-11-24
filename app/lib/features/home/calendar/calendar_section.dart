import 'package:daily_budget/core/copy/calendar_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/help/first_time_hint.dart';
import 'package:daily_budget/core/help/hint_seen_provider.dart';
import 'package:daily_budget/core/providers/calendar_providers.dart';
import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/month_browser.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/month_switcher.dart';
import 'package:daily_budget/core/widgets/tap_cooldown.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:daily_budget/features/day_details/open_day_details.dart';
import 'package:daily_budget/features/home/calendar/calendar_grid_view.dart';
import 'package:daily_budget/features/home/calendar/calendar_legend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Home calendar (F-011): month switcher, legend, weekday strip, the grid
/// and the not-budgeted caption. It owns its horizontal padding because the
/// grid is 6 dp wider on each side than the page text (design C-6).
///
/// The old grid stays on screen while the next month loads (AC-18); a swipe
/// goes to the next or previous month like the ‹ › buttons.
class CalendarSection extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends ConsumerState<CalendarSection> {
  /// The last month that finished loading, kept while the next one loads.
  CalendarView? _shown;

  /// +1 when the user moved to a newer month, -1 to an older one: the way the
  /// content slides in.
  int _direction = 0;

  final TapCooldown _tapCooldown = TapCooldown();

  @override
  void dispose() {
    _tapCooldown.dispose();
    super.dispose();
  }

  MonthBrowser get _browser =>
      ref.read(monthBrowserProvider(kCalendarBrowserKey).notifier);

  void _previous(MonthBrowse browse) {
    setState(() => _direction = -1);
    _browser.view(browse.previousId);
  }

  void _next(MonthBrowse browse) {
    setState(() => _direction = 1);
    // The latest month follows new months as they start.
    _browser.view(browse.nextId == browse.ids.first ? null : browse.nextId);
  }

  void _thisMonth() {
    setState(() => _direction = 1);
    _browser.view(null);
  }

  void _swiped(DragEndDetails details, MonthBrowse browse) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -kCalendarSwipeVelocity && browse.canGoForward) {
      _next(browse);
    } else if (velocity > kCalendarSwipeVelocity && browse.canGoBack) {
      _previous(browse);
    }
  }

  void _openDay(CalendarView view, CalendarCell cell) {
    if (_tapCooldown.isActive) return;
    _tapCooldown.start();
    openDayDetails(context, monthId: view.monthId, date: cell.date);
  }

  void _retry() {
    ref
      ..invalidate(monthIndexProvider)
      ..invalidate(storedMonthProvider)
      ..invalidate(monthSpendsProvider)
      ..invalidate(monthCoversProvider);
  }

  @override
  Widget build(BuildContext context) {
    final browseValue = ref.watch(monthBrowseProvider(kCalendarBrowserKey));
    final browse = browseValue.value;
    if (browse == null) return const SizedBox.shrink();
    final today = ref.watch(todayProvider);
    final months = ref.watch(monthIndexProvider).value ?? const <MonthRef>[];
    final viewed = months.where((m) => m.id == browse.viewedId).firstOrNull;
    final view = ref.watch(calendarViewProvider);
    if (view case AsyncData(:final value?)) _shown = value;
    final shown = _shown;
    final failed = view is AsyncError;

    final month = viewed?.month ?? shown?.result.month;
    final header = month == null
        ? CalendarHeader.current
        : !today.isAfter(month.end)
        ? CalendarHeader.current
        : browse.isLatest
        ? CalendarHeader.lastMonth
        : CalendarHeader.ended;
    final range = month == null
        ? ''
        : _rangeText(month, lastMonth: header == CalendarHeader.lastMonth);

    final homeHintGone = ref.watch(hintSeenProvider(HintId.home));
    final colors = context.budgetColors;
    final grid = shown?.grid;
    final body = failed
        ? _LoadError(onRetry: _retry)
        : shown == null
        ? const CalendarGridPlaceholder()
        : CalendarGridView(
            key: ValueKey(shown.monthId),
            grid: grid!,
            lateSetup: shown.lateSetup,
            onTap: (cell) => _openDay(shown, cell),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (homeHintGone) const FirstTimeHint(id: HintId.calendar),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BudgetSpacing.space5),
          child: MonthSwitcher(
            range: range,
            tag: header == CalendarHeader.ended ? CalendarCopy.ended : null,
            onPrevious: browse.canGoBack ? () => _previous(browse) : null,
            onNext: browse.canGoForward ? () => _next(browse) : null,
            previousLabel: CalendarCopy.previousMonth,
            nextLabel: CalendarCopy.nextMonth,
            previousDisabledHint: CalendarCopy.noEarlierMonths,
            nextDisabledHint: header == CalendarHeader.lastMonth
                ? CalendarCopy.thisIsTheLatestMonth
                : CalendarCopy.thisIsTheCurrentMonth,
            onThisMonth: header == CalendarHeader.ended ? _thisMonth : null,
            thisMonthLabel: CalendarCopy.thisMonth,
            thisMonthHint: CalendarCopy.thisMonthHint,
          ),
        ),
        const SizedBox(height: BudgetSpacing.space2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BudgetSpacing.space5),
          child: CalendarLegend(showChange: grid?.hasChangeDay ?? false),
        ),
        const SizedBox(height: BudgetSpacing.space3),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) => _swiped(details, browse),
          child: AnimatedSwitcher(
            duration: BudgetMotion.of(context).base,
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: Offset(_direction * 16 / 360, 0),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            child: KeyedSubtree(
              key: ValueKey(failed ? -1 : shown?.monthId ?? 0),
              child: body,
            ),
          ),
        ),
        if (grid != null && grid.hasNotBudgeted && !failed)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BudgetSpacing.space5,
              BudgetSpacing.space3,
              BudgetSpacing.space5,
              0,
            ),
            child: Text(
              _caption(shown!),
              style: BudgetTypeScale.body.copyWith(color: colors.textSecondary),
            ),
          ),
        const SizedBox(height: BudgetSpacing.space6),
      ],
    );
  }

  String _caption(CalendarView view) {
    final day = formatDayMonth(view.result.firstBudgetedDay);
    return view.lateSetup
        ? CalendarCopy.notBudgetedLateCaption(day)
        : CalendarCopy.notBudgetedCaption(day);
  }
}

/// `5 Nov – 4 Dec 2026`, or `25 Dec 2026 – 24 Jan 2027` across a year; a past
/// month's own range, and `Last month · …` when the new month is not set up.
String _rangeText(BudgetMonth month, {required bool lastMonth}) {
  final start = month.start;
  final end = month.end;
  final text = start.year == end.year
      ? '${formatRange(start, end)} ${end.year}'
      : '${formatDayMonth(start)} ${start.year} – '
            '${formatDayMonth(end)} ${end.year}';
  return lastMonth ? CalendarCopy.lastMonth(text) : text;
}

/// A past month that cannot be read: a neutral line and **Try again**
/// (`calendar.md` §8).
class _LoadError extends StatelessWidget {
  const new({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BudgetSpacing.space5,
        vertical: BudgetSpacing.space6,
      ),
      child: Column(
        children: [
          Text(
            CalendarCopy.loadError,
            textAlign: TextAlign.center,
            style: BudgetTypeScale.body.copyWith(
              color: context.budgetColors.textSecondary,
            ),
          ),
          const SizedBox(height: BudgetSpacing.space3),
          BudgetButton.secondary(
            label: CalendarCopy.tryAgain,
            semanticsHint: CalendarCopy.tryAgainHint,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
