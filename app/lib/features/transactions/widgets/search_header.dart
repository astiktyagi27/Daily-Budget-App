import 'dart:async';

import 'package:daily_budget/core/copy/category_copy.dart';
import 'package:daily_budget/core/copy/search_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/widgets/filter_chip.dart';
import 'package:daily_budget/core/widgets/search_field.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/transactions/sheets/category_filter_sheet.dart';
import 'package:daily_budget/features/transactions/sheets/dates_sheet.dart';
import 'package:daily_budget/features/transactions/sheets/type_sheet.dart';
import 'package:daily_budget/features/transactions/transactions_filter_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The search field and the three filter chips of the Transactions tab
/// (`transactions-search.md` §4, §5). The chips sit in a row that scrolls
/// sideways, so it never wraps or clips at large text.
class SearchHeader extends ConsumerWidget {
  const new({required this.controller, super.key});

  /// The search text. The tab owns it, so it survives rebuilds and `Clear
  /// all` can empty it.
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionsFilterProvider);
    final months = ref.watch(storedMonthsProvider);
    final today = ref.watch(todayProvider);
    final notifier = ref.read(transactionsFilterProvider.notifier);

    final datesValue = switch (filter.dates) {
      ThisMonthDates() =>
        thisMonthAvailable(months, today)
            ? SearchCopy.thisMonth
            : SearchCopy.lastMonth,
      LastMonthDates() => SearchCopy.lastMonth,
      CustomDates(:final first, :final last) =>
        first == last ? formatDayMonth(first) : formatRange(first, last),
    };
    final categories = filter.categories;
    final categoryValue = switch (categories.length) {
      0 => SearchCopy.all,
      1 => CategoryCopy.nameOf(categories.single),
      final count => SearchCopy.categoriesValue(count),
    };
    final typeValue = SearchCopy.typeName(filter.type);

    Future<void> pickDates() async {
      final pick = await showDatesSheet(
        context,
        current: filter.dates,
        months: months,
        today: today,
      );
      if (pick == null || !context.mounted) return;
      switch (pick) {
        case DatesPick.thisMonth:
        case DatesPick.lastMonth:
          notifier.setDates(
            normalizeDates(
              pick == DatesPick.thisMonth
                  ? DatesFilter.thisMonth
                  : DatesFilter.lastMonth,
              thisAvailable: thisMonthAvailable(months, today),
            ),
          );
        case DatesPick.custom:
          final limits = customRangeLimits(months, today);
          if (limits == null) return;
          DateTime asLocal(CalendarDate d) => DateTime(d.year, d.month, d.day);
          final current = filter.dates;
          final picked = await showDateRangePicker(
            context: context,
            firstDate: asLocal(limits.first),
            lastDate: asLocal(limits.last),
            helpText: SearchCopy.rangePickerHelp,
            initialEntryMode: DatePickerEntryMode.calendarOnly,
            initialDateRange: current is CustomDates
                ? DateTimeRange(
                    start: asLocal(current.first),
                    end: asLocal(current.last),
                  )
                : null,
          );
          if (picked == null) return;
          notifier.setDates(
            DatesFilter.custom(
              CalendarDate.fromDateTime(picked.start),
              CalendarDate.fromDateTime(picked.end),
            ),
          );
      }
    }

    Future<void> pickCategories() async {
      final picked = await showCategoryFilterSheet(
        context,
        current: filter.categories,
      );
      if (picked != null) notifier.setCategories(picked);
    }

    Future<void> pickType() async {
      final picked = await showTypeSheet(context, current: filter.type);
      if (picked != null) notifier.setType(picked);
    }

    final datesActive = filter.dates is! ThisMonthDates;
    final categoryActive = categories.isNotEmpty;
    final typeActive = filter.type != TypeFilter.all;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BudgetSpacing.space5,
            BudgetSpacing.space4,
            BudgetSpacing.space5,
            BudgetSpacing.space3,
          ),
          child: SearchField(
            controller: controller,
            placeholder: SearchCopy.searchPlaceholder,
            hint: SearchCopy.searchHint,
            clearTooltip: SearchCopy.clearSearchTooltip,
            clearHint: SearchCopy.clearSearchHint,
            onChanged: notifier.typeQuery,
            onClear: () {
              controller.clear();
              notifier.clearSearch();
            },
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: BudgetSpacing.space5),
          child: Row(
            children: [
              BudgetFilterChip(
                label: SearchCopy.chipText(SearchCopy.datesWord, datesValue),
                active: datesActive,
                semanticsLabel: SearchCopy.chipSemantics(
                  SearchCopy.datesWord,
                  datesValue,
                  on: datesActive,
                ),
                onPressed: () => unawaited(pickDates()),
              ),
              const SizedBox(width: BudgetSpacing.space2),
              BudgetFilterChip(
                label: SearchCopy.chipText(
                  SearchCopy.categoryWord,
                  categoryValue,
                ),
                active: categoryActive,
                semanticsLabel: SearchCopy.chipSemantics(
                  SearchCopy.categoryWord,
                  categoryValue,
                  on: categoryActive,
                ),
                onPressed: () => unawaited(pickCategories()),
              ),
              const SizedBox(width: BudgetSpacing.space2),
              BudgetFilterChip(
                label: SearchCopy.chipText(SearchCopy.typeWord, typeValue),
                active: typeActive,
                semanticsLabel: SearchCopy.chipSemantics(
                  SearchCopy.typeWord,
                  typeValue,
                  on: typeActive,
                ),
                onPressed: () => unawaited(pickType()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
