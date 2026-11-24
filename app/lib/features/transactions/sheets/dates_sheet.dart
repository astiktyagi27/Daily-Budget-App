import 'package:daily_budget/core/copy/search_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/widgets/budget_sheet.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/transactions/sheets/sheet_parts.dart';
import 'package:flutter/material.dart';

/// What the Dates sheet returns: a month, or a custom range still to pick.
enum DatesPick { thisMonth, lastMonth, custom }

/// The Dates sheet (`transactions-search.md` §5.1): `This month`, `Last
/// month` and `Custom range`, picking a month applies it and closes. With
/// the new month not set up, `This month` is disabled with `Set up your
/// month first` and `Last month` (the latest stored month) is the selected
/// row (D-083 (3)). Null when closed without a choice.
Future<DatesPick?> showDatesSheet(
  BuildContext context, {
  required DatesFilter current,
  required List<IndexedMonth> months,
  required CalendarDate today,
}) => showBudgetSheet<DatesPick>(
  context: context,
  builder: (context) =>
      DatesSheet(current: current, months: months, today: today),
);

class DatesSheet extends StatelessWidget {
  const new({
    required this.current,
    required this.months,
    required this.today,
    super.key,
  });

  final DatesFilter current;
  final List<IndexedMonth> months;
  final CalendarDate today;

  @override
  Widget build(BuildContext context) {
    final thisIndex = currentMonthIndex(months, today);
    final thisAvailable = thisIndex != null;
    final last = lastMonthOf(months, today);
    final (thisSelected, lastSelected, customSelected) = switch (current) {
      CustomDates() => (false, false, true),
      LastMonthDates() => (false, true, false),
      ThisMonthDates() => (thisAvailable, !thisAvailable, false),
    };

    Widget row({
      required String label,
      required String description,
      required String spoken,
      required bool selected,
      required bool available,
      required DatesPick pick,
    }) => ChoiceRow(
      label: label,
      description: description,
      selected: selected,
      enabled: available,
      onTap: () => Navigator.of(context).pop(pick),
      semanticsLabel: SearchCopy.radioSemantics(
        label,
        spoken,
        available: available,
      ),
    );

    return SheetScaffold(
      title: SearchCopy.datesTitle,
      body: Column(
        children: [
          row(
            label: SearchCopy.thisMonth,
            description: thisIndex == null
                ? SearchCopy.thisMonthNotReady
                : _range(months[thisIndex].month),
            spoken: thisIndex == null
                ? SearchCopy.thisMonthNotReady
                : _spokenRange(months[thisIndex].month),
            selected: thisSelected,
            available: thisAvailable,
            pick: DatesPick.thisMonth,
          ),
          row(
            label: SearchCopy.lastMonth,
            description: last == null
                ? SearchCopy.lastMonthNone
                : _range(last.month),
            spoken: last == null
                ? SearchCopy.lastMonthNone
                : _spokenRange(last.month),
            selected: lastSelected,
            available: last != null,
            pick: DatesPick.lastMonth,
          ),
          row(
            label: SearchCopy.customRange,
            description: SearchCopy.customRangeDescription,
            spoken: SearchCopy.customRangeDescription,
            selected: customSelected,
            available: true,
            pick: DatesPick.custom,
          ),
        ],
      ),
    );
  }

  static String _range(BudgetMonth month) =>
      formatRange(month.start, month.end);

  /// `5 November to 4 December`.
  static String _spokenRange(BudgetMonth month) =>
      '${month.start.day} ${formatMonthName(month.start)} to '
      '${month.end.day} ${formatMonthName(month.end)}';
}
