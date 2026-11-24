import 'dart:async';

import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/month_browser.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long the search waits after the last keystroke before the list
/// changes (`transactions-search.md` §4; F-015 AC-16 allows 300 ms).
const Duration searchDebounce = Duration(milliseconds: 250);

/// The search text and the three filters of the Transactions tab (F-015
/// AC-15). Not auto-disposed: it survives switching tabs, and it is gone
/// when the app restarts because it is never stored.
final NotifierProvider<TransactionsFilterNotifier, EntryFilter>
transactionsFilterProvider =
    NotifierProvider<TransactionsFilterNotifier, EntryFilter>(
      TransactionsFilterNotifier.new,
    );

class TransactionsFilterNotifier extends Notifier<EntryFilter> {
  Timer? _pending;

  @override
  EntryFilter build() {
    ref.onDispose(() => _pending?.cancel());
    return const EntryFilter();
  }

  /// The user typed [text]: the field shows it at once, the list changes
  /// [searchDebounce] after the last keystroke.
  void typeQuery(String text) {
    _pending?.cancel();
    _pending = Timer(searchDebounce, () => state = state.copyWith(query: text));
  }

  /// Clears the search now (the × button, `Clear search`).
  void clearSearch() {
    _pending?.cancel();
    state = state.copyWith(query: '');
  }

  void setDates(DatesFilter dates) => state = state.copyWith(dates: dates);

  void setCategories(Set<SpendCategory> categories) =>
      state = state.copyWith(categories: categories);

  void setType(TypeFilter type) => state = state.copyWith(type: type);

  /// The search and all three filters back to their defaults.
  void clearAll() {
    _pending?.cancel();
    state = const EntryFilter();
  }
}

/// What the list shows for the current search and filters.
final class TransactionsListModel {
  const new({
    required this.sections,
    required this.summary,
    required this.filter,
  });

  /// Matching entries, month by month, newest first.
  final List<MonthSection> sections;

  /// Count, gross spent and refunds of the matches.
  final ResultsSummary summary;

  final EntryFilter filter;

  bool get isEmpty => sections.isEmpty;
}

/// The stored months as the Dates filter reads them, newest first. Empty
/// while the index loads or before the first setup.
final Provider<List<IndexedMonth>> storedMonthsProvider =
    Provider<List<IndexedMonth>>(
      (ref) => [
        for (final MonthRef(:id, :month)
            in ref.watch(monthIndexProvider).value ?? const <MonthRef>[])
          (id: id, month: month),
      ],
    );

/// The list of the tab: the months the Dates filter reaches, filtered and
/// grouped by the pure code in `transaction_search.dart`. A stream that has
/// not answered yet is [AsyncLoading] (the tab keeps the old results on
/// screen meanwhile); a failed one is an [AsyncError] with its own retry.
final Provider<AsyncValue<TransactionsListModel>> transactionsListProvider =
    Provider<AsyncValue<TransactionsListModel>>((ref) {
      final filter = ref.watch(transactionsFilterProvider);
      final today = ref.watch(todayProvider);
      final index = ref.watch(monthIndexProvider);
      if (index case AsyncError(:final error, :final stackTrace)) {
        return AsyncError(error, stackTrace);
      }
      if (!index.hasValue) return const AsyncLoading();
      final months = ref.watch(storedMonthsProvider);
      final range = resolveDates(filter.dates, months, today);
      final touched = monthsTouching(months, range);

      final perMonth = <MonthEntries>[];
      for (final month in touched) {
        final spends = ref.watch(monthSpendsProvider(month.id));
        if (spends case AsyncError(:final error, :final stackTrace)) {
          return AsyncError(error, stackTrace);
        }
        final stored = spends.value;
        if (stored == null) return const AsyncLoading();
        perMonth.add((
          id: month.id,
          month: month.month,
          entries: filterEntries(
            [for (final s in stored) s.noted],
            filter,
            range,
          ),
        ));
      }
      return AsyncData(
        TransactionsListModel(
          sections: groupEntries(perMonth, today),
          summary: resultsSummary([for (final m in perMonth) ...m.entries]),
          filter: filter,
        ),
      );
    });

/// Whether any entry exists in any stored month: the search and the chips
/// show only then (`transactions-search.md` §3). The latest month is read
/// first; the older ones only when it is empty.
final Provider<AsyncValue<bool>> hasAnyEntriesProvider =
    Provider<AsyncValue<bool>>((ref) {
      final months = ref.watch(storedMonthsProvider);
      for (final month in months) {
        final spends = ref.watch(monthSpendsProvider(month.id));
        if (spends case AsyncError(:final error, :final stackTrace)) {
          return AsyncError(error, stackTrace);
        }
        final stored = spends.value;
        if (stored == null) return const AsyncLoading();
        if (stored.isNotEmpty) return const AsyncData(true);
      }
      return const AsyncData(false);
    });
