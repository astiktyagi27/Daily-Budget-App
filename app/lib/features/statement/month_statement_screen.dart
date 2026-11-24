import 'package:daily_budget/core/copy/calendar_copy.dart';
import 'package:daily_budget/core/copy/statement_copy.dart';
import 'package:daily_budget/core/copy/storage_copy.dart';
import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/month_browser.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:daily_budget/core/widgets/budget_icon_button.dart';
import 'package:daily_budget/core/widgets/empty_state.dart';
import 'package:daily_budget/core/widgets/month_switcher.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/statement/statement_state.dart';
import 'package:daily_budget/features/statement/statement_text.dart';
import 'package:daily_budget/features/statement/widgets/period_card.dart';
import 'package:daily_budget/features/statement/widgets/totals_card.dart';
import 'package:daily_budget/features/statement/widgets/what_changed_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The month statement (F-014, `docs/design/screens/month-statement.md`): a
/// read-only, pushed full screen that shows how a month's budget was worked
/// out. It shows what the engine worked out and never calculates money.
///
/// With [scrollToPeriodStart] it opens at the period that starts that day
/// (Day details, AC-1).
class MonthStatementScreen extends ConsumerStatefulWidget {
  const new({required this.monthId, this.scrollToPeriodStart, super.key});

  final int monthId;

  final CalendarDate? scrollToPeriodStart;

  /// Pushes the screen over the tabs.
  static Future<void> open(
    BuildContext context,
    int monthId, {
    CalendarDate? scrollToPeriodStart,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => MonthStatementScreen(
        monthId: monthId,
        scrollToPeriodStart: scrollToPeriodStart,
      ),
    ),
  );

  @override
  ConsumerState<MonthStatementScreen> createState() =>
      _MonthStatementScreenState();
}

class _MonthStatementScreenState extends ConsumerState<MonthStatementScreen> {
  final _periodKeys = <CalendarDate, GlobalKey>{};
  bool _scrolled = false;

  /// The month shown: the one asked for, then wherever ‹ › moved to.
  late int _monthId = widget.monthId;

  /// The last statement that was ready, kept while the next month loads
  /// (design section 9: changing month keeps the old content).
  MonthStatement? _last;

  void _reload() {
    final id = _monthId;
    ref
      ..invalidate(storedMonthProvider(id))
      ..invalidate(monthSpendsProvider(id))
      ..invalidate(monthCoversProvider(id));
  }

  /// Brings the card of `scrollToPeriodStart` to the top once, after the
  /// first frame that has the statement.
  void _scrollToArrival(MonthStatement statement) {
    final start = widget.scrollToPeriodStart;
    if (start == null || _scrolled) return;
    final card = statement.periodStartingOn(start);
    if (card == null) return;
    _scrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _periodKeys[card.start]?.currentContext;
      if (context == null || !mounted) return;
      Scrollable.ensureVisible(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(monthStatementProvider(_monthId));
    final fresh = state.value;
    if (fresh != null) {
      _last = fresh;
      if (_monthId == widget.monthId) _scrollToArrival(fresh);
    }
    final statement = fresh ?? (state.isLoading ? _last : null);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _TopBar(),
                  _Gutter(
                    child: _Title(
                      statement: statement,
                      monthId: _monthId,
                      onMonth: (id) => setState(() => _monthId = id),
                    ),
                  ),
                  const SizedBox(height: BudgetSpacing.space4),
                  switch (state) {
                    AsyncError() || AsyncData(value: null) => EmptyState(
                      icon: Icons.error_outline,
                      title: StorageCopy.loadErrorTitle,
                      description: StorageCopy.loadErrorDescription,
                      action: BudgetButton.primary(
                        label: StorageCopy.tryAgain,
                        semanticsHint: StorageCopy.loadErrorHint,
                        onPressed: _reload,
                      ),
                    ),
                    _ when statement != null => _Body(
                      statement: statement,
                      keys: _periodKeys,
                      arrival: _monthId == widget.monthId
                          ? widget.scrollToPeriodStart
                          : null,
                    ),
                    _ => const _Loading(),
                  },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Gutter extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: BudgetSpacing.space5),
    child: child,
  );
}

class _TopBar extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: BudgetSpacing.space2),
        child: BudgetIconButton(
          icon: Icons.arrow_back,
          tooltip: StatementCopy.back,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
    ),
  );
}

/// The title and the shared month switcher (design system 7.14): the range,
/// ‹ and › over the stored months (D-074), `Ended` and **This month** on a
/// past month.
class _Title extends ConsumerWidget {
  const new({
    required this.statement,
    required this.monthId,
    required this.onMonth,
  });

  final MonthStatement? statement;

  final int monthId;

  final ValueChanged<int> onMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.budgetColors;
    final statement = this.statement;
    final ids = [
      for (final m in ref.watch(monthIndexProvider).value ?? const <MonthRef>[])
        m.id,
    ];
    final browse = ids.isEmpty ? null : MonthBrowse.of(ids, monthId);
    final isPast = browse != null && !browse.isLatest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            StatementCopy.title,
            style: context.budgetText.headline.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
        if (statement != null) ...[
          const SizedBox(height: BudgetSpacing.space2),
          MonthSwitcher(
            range: monthRangeText(statement),
            tag: isPast ? CalendarCopy.ended : null,
            suffix: soFarSuffixText(statement),
            onPrevious: browse != null && browse.canGoBack
                ? () => onMonth(browse.previousId)
                : null,
            onNext: browse != null && browse.canGoForward
                ? () => onMonth(browse.nextId)
                : null,
            previousLabel: CalendarCopy.previousMonth,
            nextLabel: CalendarCopy.nextMonth,
            previousDisabledHint: CalendarCopy.noEarlierMonths,
            nextDisabledHint: statement.soFarTo != null
                ? CalendarCopy.thisIsTheCurrentMonth
                : CalendarCopy.thisIsTheLatestMonth,
            onThisMonth: isPast ? () => onMonth(ids.first) : null,
            thisMonthLabel: CalendarCopy.thisMonth,
            thisMonthHint: CalendarCopy.thisMonthHint,
          ),
        ],
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const new({
    required this.statement,
    required this.keys,
    required this.arrival,
  });

  final MonthStatement statement;

  final Map<CalendarDate, GlobalKey> keys;

  final CalendarDate? arrival;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final notBudgeted = notBudgetedText(statement);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (notBudgeted != null)
          _Gutter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: BudgetSpacing.space3),
              child: Text(
                notBudgeted,
                style: BudgetTypeScale.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        _Gutter(child: TotalsCard(statement: statement)),
        if (roundingNoteNeeded(statement))
          _Gutter(
            child: Padding(
              padding: const EdgeInsets.only(top: BudgetSpacing.space3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: BudgetSpacing.space2),
                  Expanded(
                    child: Text(
                      StatementCopy.roundingNote,
                      style: BudgetTypeScale.body.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: BudgetSpacing.space4),
        _Gutter(child: WhatChangedCard(statement: statement)),
        for (final period in statement.periods) ...[
          const SizedBox(height: BudgetSpacing.space4),
          _Gutter(
            child: KeyedSubtree(
              key: keys.putIfAbsent(period.start, GlobalKey.new),
              child: PeriodCard(
                period: period,
                arrival: arrival != null && arrival == period.start,
              ),
            ),
          ),
        ],
        _Gutter(
          child: Padding(
            padding: const EdgeInsets.only(
              top: BudgetSpacing.space6,
              bottom: BudgetSpacing.space8,
            ),
            child: Text(
              StatementCopy.footnote,
              style: BudgetTypeScale.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Cards with their headers and static grey bars, never `₹0` (design §9).
class _Loading extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    Widget bar(double width) => Container(
      width: width,
      height: 16,
      margin: const EdgeInsets.only(bottom: BudgetSpacing.space3),
      decoration: BoxDecoration(
        color: colors.neutralSoft,
        borderRadius: const BorderRadius.all(Radius.circular(BudgetRadii.xs)),
      ),
    );
    return Semantics(
      container: true,
      label: StatementCopy.loading,
      child: ExcludeSemantics(
        child: _Gutter(
          child: Column(
            children: [
              BudgetCard(
                title: StatementCopy.soFar,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [bar(200), bar(160), bar(180)],
                ),
              ),
              const SizedBox(height: BudgetSpacing.space4),
              BudgetCard(
                title: StatementCopy.whatChanged,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [bar(220), bar(140)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
