import 'dart:async';

import 'package:daily_budget/core/copy/storage_copy.dart';
import 'package:daily_budget/core/copy/transactions_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/help/first_time_hint.dart';
import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/month_browser.dart';
import 'package:daily_budget/core/providers/month_state_provider.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/empty_state.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:daily_budget/features/month_setup/month_setup_controller.dart';
import 'package:daily_budget/features/shell/app_tab.dart';
import 'package:daily_budget/features/shell/tab_page.dart';
import 'package:daily_budget/features/transactions/category_change_flow.dart';
import 'package:daily_budget/features/transactions/month_setup_launcher.dart';
import 'package:daily_budget/features/transactions/spend_editor_flow.dart';
import 'package:daily_budget/features/transactions/spend_list.dart';
import 'package:daily_budget/features/transactions/today_line_view.dart';
import 'package:daily_budget/features/transactions/transactions_filter_state.dart';
import 'package:daily_budget/features/transactions/transactions_state.dart';
import 'package:daily_budget/features/transactions/widgets/new_month_card.dart';
import 'package:daily_budget/features/transactions/widgets/results_line.dart';
import 'package:daily_budget/features/transactions/widgets/search_empty_state.dart';
import 'package:daily_budget/features/transactions/widgets/search_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Transactions tab (F-009 §2.1, F-015 §2.1, `transactions.md` §3, §6,
/// `transactions-search.md` §3): the Today card, the search and filters, and
/// the spends by day, or the state that explains why not. The floating Add
/// spend button belongs to the shell (`AddSpendButton`).
///
/// A stateful widget so the search text and the list that is on screen live
/// as long as the tab does (the shell keeps the tab alive between visits).
class TransactionsTab extends ConsumerStatefulWidget {
  const new({required this.controller, super.key});

  final ScrollController controller;

  /// Room under the list so the last row scrolls clear of the button.
  static const double buttonClearance = 88;

  /// Above this text size the first-time tip sits under the Today card, so
  /// the Add spend button never covers the Today line (`transactions.md`
  /// §3.1).
  static const double tipBelowTodayAbove = 1.3;

  @override
  ConsumerState<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends ConsumerState<TransactionsTab> {
  late final TextEditingController _search;

  /// The results that are on screen while a changed search or filter loads:
  /// the list keeps the old rows until the new ones are ready.
  TransactionsListModel? _shown;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(transactionsFilterProvider).query,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `Clear all` and `Clear search` empty the field from the provider.
    ref.listen(transactionsFilterProvider.select((f) => f.query), (_, next) {
      if (next != _search.text) _search.text = next;
    });
    const hint = FirstTimeHint(id: HintId.transactions);
    final title = AppTab.transactions.title;
    final launchSetup = ref.read(monthSetupLauncherProvider);

    Widget page(Widget body) => TabPage(
      title: title,
      controller: widget.controller,
      hint: hint,
      body: body,
    );

    final view = ref.watch(transactionsViewProvider);
    final list = ref.watch(transactionsListProvider);
    if (list.value case final model?) _shown = model;
    if (view.hasError || list.hasError) {
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
                ..invalidate(monthIndexProvider)
                ..invalidate(monthSpendsProvider)
                ..invalidate(storedMonthProvider)
                ..invalidate(monthCoversProvider);
            },
          ),
        ),
      );
    }
    final value = view.value;
    if (value == null) return page(const SizedBox.shrink());

    switch (value) {
      case NoMonthView():
        return page(
          EmptyState(
            icon: Icons.event_outlined,
            title: TransactionsCopy.noMonthTitle,
            description: TransactionsCopy.noMonthDescription,
            action: BudgetButton.primary(
              label: TransactionsCopy.noMonthButton,
              semanticsHint: TransactionsCopy.noMonthHint,
              onPressed: () => launchSetup(context, const FirstSetupMode()),
            ),
          ),
        );
      case CurrentMonthView(:final line, :final stored):
        final tipBelowToday =
            line != null &&
            MediaQuery.textScalerOf(context).scale(1) >
                TransactionsTab.tipBelowTodayAbove;
        return TabPage.slivers(
          title: title,
          controller: widget.controller,
          hint: tipBelowToday ? null : hint,
          bodySlivers: [
            if (line != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BudgetSpacing.space5,
                  ),
                  child: TodayLineView(line: line),
                ),
              ),
            if (tipBelowToday) const SliverToBoxAdapter(child: hint),
            ..._listSlivers(editableMonthId: line == null ? null : stored.id),
            const SliverToBoxAdapter(
              child: SizedBox(height: TransactionsTab.buttonClearance),
            ),
          ],
        );
      case NewMonthView(:final lastMonth):
        final showCaption =
            ref.watch(transactionsFilterProvider).dates is ThisMonthDates;
        return TabPage.slivers(
          title: title,
          controller: widget.controller,
          hint: hint,
          bodySlivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BudgetSpacing.space5,
                ),
                child: NewMonthCard(
                  onSetUp: () => launchSetup(context, NewMonthMode(lastMonth)),
                ),
              ),
            ),
            if (showCaption)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BudgetSpacing.space5,
                    BudgetSpacing.space6,
                    BudgetSpacing.space5,
                    0,
                  ),
                  child: Semantics(
                    header: true,
                    child: Text(
                      TransactionsCopy.lastMonthLabel(
                        formatRange(lastMonth.month.start, lastMonth.month.end),
                      ),
                      style: BudgetTypeScale.caption.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.budgetColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ..._listSlivers(editableMonthId: null),
            const SliverToBoxAdapter(
              child: SizedBox(height: TransactionsTab.buttonClearance),
            ),
          ],
        );
    }
  }

  /// The search and filters, the results line and the list, or the state
  /// that says why there is none. The search and the chips show only when an
  /// entry exists in some stored month.
  List<Widget> _listSlivers({required int? editableMonthId}) {
    final model = _shown;
    final hasEntries = ref.watch(hasAnyEntriesProvider).value ?? false;
    final filter = ref.watch(transactionsFilterProvider);
    final notifier = ref.read(transactionsFilterProvider.notifier);
    if (model == null) return const [];
    if (!hasEntries) {
      return const [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.receipt_long_outlined,
            title: TransactionsCopy.noSpendsTitle,
            description: TransactionsCopy.noSpendsDescription,
          ),
        ),
      ];
    }
    final active = filter.isActive;
    return [
      SliverToBoxAdapter(child: SearchHeader(controller: _search)),
      if (active)
        SliverToBoxAdapter(
          child: ResultsLine(
            summary: model.summary,
            onClearAll: () {
              _search.clear();
              notifier.clearAll();
            },
          ),
        ),
      if (model.isEmpty && !active)
        const SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.receipt_long_outlined,
            title: TransactionsCopy.noSpendsTitle,
            description: TransactionsCopy.noSpendsDescription,
          ),
        )
      else if (model.isEmpty)
        SliverToBoxAdapter(
          child: SearchEmptyState(
            kind: _noResultsKind(filter),
            query: filter.query,
            onClear: () {
              _search.clear();
              if (_noResultsKind(filter) == NoResultsKind.search) {
                notifier.clearSearch();
              } else {
                notifier.clearAll();
              }
            },
          ),
        )
      else
        TransactionListSliver(
          sections: model.sections,
          filtering: active,
          editableMonthId: editableMonthId,
          onOpen: (spend) =>
              unawaited(openSpendEditor(context, ref, edit: spend)),
          onCategory: (spend) => unawaited(changeCategory(context, ref, spend)),
        ),
    ];
  }

  NoResultsKind _noResultsKind(EntryFilter filter) {
    final searching = parseSearchQuery(filter.query) is! EmptyQuery;
    final filtering =
        filter.dates is! ThisMonthDates ||
        filter.categories.isNotEmpty ||
        filter.type != TypeFilter.all;
    return switch ((searching, filtering)) {
      (true, false) => NoResultsKind.search,
      (true, true) => NoResultsKind.searchAndFilters,
      _ => NoResultsKind.filters,
    };
  }
}
