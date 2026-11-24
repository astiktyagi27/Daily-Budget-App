import 'package:daily_budget/domain/budget/amount_input.dart';
import 'package:daily_budget/domain/budget/budget_month.dart';
import 'package:daily_budget/domain/budget/calendar_date.dart';
import 'package:daily_budget/domain/budget/paise.dart';
import 'package:daily_budget/domain/budget/spend.dart';
import 'package:daily_budget/domain/budget/spend_category.dart';
import 'package:daily_budget/domain/budget/spend_groups.dart';

/// A spend with its note: the engine's [Spend] has none, and the search
/// reads it. The domain cannot import the stored type, which lives in
/// `data/` (F-015 plan 1).
typedef NotedSpend = ({Spend spend, String? note});

/// Which entries the Type filter lets through (D-047).
enum TypeFilter { all, spends, refunds }

/// The days the list covers (F-015 §2.3). Resolved against the stored months
/// by [resolveDates].
sealed class DatesFilter {
  const new();

  /// The current budget month; the latest stored month when the new month
  /// is not set up yet (D-083 (3)).
  static const DatesFilter thisMonth = ThisMonthDates();

  /// The stored month before the current one; the latest stored month when
  /// the new month is not set up yet.
  static const DatesFilter lastMonth = LastMonthDates();

  static DatesFilter custom(CalendarDate first, CalendarDate last) =>
      CustomDates(first, last);
}

final class ThisMonthDates extends DatesFilter {
  const new();
}

final class LastMonthDates extends DatesFilter {
  const new();
}

/// Every day from [first] to [last], both included.
final class CustomDates extends DatesFilter {
  const new(this.first, this.last);

  final CalendarDate first;

  final CalendarDate last;
}

/// The search text and the three filters. All parts combine with AND;
/// categories inside the set combine with OR (F-015 §2.3).
final class EntryFilter {
  const new({
    this.query = '',
    this.dates = DatesFilter.thisMonth,
    this.categories = const {},
    this.type = TypeFilter.all,
  });

  /// What the user typed, untouched; [parseSearchQuery] reads it.
  final String query;

  final DatesFilter dates;

  /// The categories to show; empty means all of them.
  final Set<SpendCategory> categories;

  final TypeFilter type;

  /// Whether the text, a category or the type narrows the list, or the dates
  /// are not the default. `Clear all` shows while this is true.
  bool get isActive =>
      parseSearchQuery(query) is! EmptyQuery ||
      dates is! ThisMonthDates ||
      categories.isNotEmpty ||
      type != TypeFilter.all;

  EntryFilter copyWith({
    String? query,
    DatesFilter? dates,
    Set<SpendCategory>? categories,
    TypeFilter? type,
  }) => EntryFilter(
    query: query ?? this.query,
    dates: dates ?? this.dates,
    categories: categories ?? this.categories,
    type: type ?? this.type,
  );
}

/// What the search field's text means (F-015 §2.2).
sealed class SearchQuery {
  const new();
}

/// Nothing, spaces only, or `₹` alone: the list is not searched.
final class EmptyQuery extends SearchQuery {
  const new();
}

/// Letters or anything that is not an amount: notes containing [text],
/// ignoring case.
final class TextQuery extends SearchQuery {
  const new(this.text);

  /// Trimmed.
  final String text;
}

/// An amount such as `250`, `₹1,130` or `300.50`. It finds entries of that
/// amount and notes containing the typed digits.
final class NumberQuery extends SearchQuery {
  const new({
    required this.paise,
    required this.hasDecimals,
    required this.digits,
  });

  /// The amount, exactly.
  final Paise paise;

  /// A decimal point with digits was typed: the amount must match exactly.
  /// Without it only the shown whole rupees must match (D-038).
  final bool hasDecimals;

  /// The text without `₹` and spaces, as typed (grouping commas kept).
  final String digits;
}

final _skipped = RegExp(r'[\s₹]');

/// Reads the search [text]: an amount when [parseAmount] accepts it, empty
/// for spaces and `₹` alone, text otherwise (`250rs`, `99,50`).
SearchQuery parseSearchQuery(String text) {
  final trimmed = text.trim();
  return switch (parseAmount(trimmed)) {
    AmountEmpty() => const EmptyQuery(),
    AmountValue(:final paise) => NumberQuery(
      paise: paise,
      hasDecimals: RegExp(r'\.\d').hasMatch(trimmed),
      digits: trimmed.replaceAll(_skipped, ''),
    ),
    _ => TextQuery(trimmed),
  };
}

bool _noteContains(String? note, String needle) =>
    note != null && note.toLowerCase().contains(needle.toLowerCase());

bool _matchesQuery(NotedSpend entry, SearchQuery query) => switch (query) {
  EmptyQuery() => true,
  TextQuery(:final text) => _noteContains(entry.note, text),
  NumberQuery(:final paise, :final hasDecimals, :final digits) =>
    (hasDecimals
            ? entry.spend.amount.value == paise.value
            : entry.spend.amount.value ~/ 100 == paise.value ~/ 100) ||
        _noteContains(entry.note, digits) ||
        _noteContains(entry.note, digits.replaceAll(',', '')),
};

bool _matchesType(Spend spend, TypeFilter type) => switch (type) {
  TypeFilter.all => true,
  TypeFilter.spends => spend.direction == SpendDirection.spend,
  TypeFilter.refunds => spend.direction == SpendDirection.moneyIn,
};

/// A refund has no category, so any category filter leaves refunds out.
bool _matchesCategory(Spend spend, Set<SpendCategory> categories) =>
    categories.isEmpty ||
    (spend.direction == SpendDirection.spend &&
        categories.contains(spend.category ?? SpendCategory.other));

/// The first and last day of a range, both included.
typedef DateRange = ({CalendarDate first, CalendarDate last});

/// The entries of [entries] that match [filter] inside [range], in their
/// order. [range] is the resolved Dates filter ([resolveDates]); a null
/// [range] (no such month) shows nothing.
List<NotedSpend> filterEntries(
  Iterable<NotedSpend> entries,
  EntryFilter filter,
  DateRange? range,
) {
  if (range == null) return const [];
  final query = parseSearchQuery(filter.query);
  return [
    for (final entry in entries)
      if (!entry.spend.date.isBefore(range.first) &&
          !entry.spend.date.isAfter(range.last) &&
          _matchesType(entry.spend, filter.type) &&
          _matchesCategory(entry.spend, filter.categories) &&
          _matchesQuery(entry, query))
        entry,
  ];
}

/// A stored month as the month index lists it.
typedef IndexedMonth = ({int id, BudgetMonth month});

/// The position of the month that contains [today] in [months] (newest
/// first), or null when the new month is not set up (or today is in a month
/// that was never set up).
int? currentMonthIndex(List<IndexedMonth> months, CalendarDate today) {
  final index = months.indexWhere((m) => m.month.contains(today));
  return index < 0 ? null : index;
}

/// Whether `This month` can be picked: the current month is set up.
bool thisMonthAvailable(List<IndexedMonth> months, CalendarDate today) =>
    currentMonthIndex(months, today) != null;

/// The stored month `Last month` means, or null when there is none (`No
/// earlier month yet`). When the new month is not set up it is the latest
/// stored month (D-083 (3)).
IndexedMonth? lastMonthOf(List<IndexedMonth> months, CalendarDate today) {
  if (months.isEmpty) return null;
  final current = currentMonthIndex(months, today);
  if (current == null) return months.first;
  return current + 1 < months.length ? months[current + 1] : null;
}

/// [months] (newest first) read as [dates]: the days to show, or null when
/// there is nothing to show (`Last month` with no earlier month, or no month
/// at all).
DateRange? resolveDates(
  DatesFilter dates,
  List<IndexedMonth> months,
  CalendarDate today,
) {
  if (months.isEmpty) return null;
  DateRange of(IndexedMonth m) => (first: m.month.start, last: m.month.end);
  return switch (dates) {
    ThisMonthDates() => of(months[currentMonthIndex(months, today) ?? 0]),
    LastMonthDates() => switch (lastMonthOf(months, today)) {
      null => null,
      final month => of(month),
    },
    CustomDates(:final first, :final last) => (first: first, last: last),
  };
}

/// The stored months that a [range] touches, newest first: the ones whose
/// spends must be read.
List<IndexedMonth> monthsTouching(
  List<IndexedMonth> months,
  DateRange? range,
) => range == null
    ? const []
    : [
        for (final m in months)
          if (!m.month.end.isBefore(range.first) &&
              !m.month.start.isAfter(range.last))
            m,
      ];

/// The days the custom range picker allows: from the first stored month's
/// start to [today]. Null when no month is stored.
DateRange? customRangeLimits(List<IndexedMonth> months, CalendarDate today) =>
    months.isEmpty ? null : (first: months.last.month.start, last: today);

/// What the Dates filter becomes when the user picks [picked]: with the new
/// month not set up, `Last month` is what the default already shows, so it
/// stays the default.
DatesFilter normalizeDates(DatesFilter picked, {required bool thisAvailable}) =>
    picked is LastMonthDates && !thisAvailable ? DatesFilter.thisMonth : picked;

/// How many entries match and what they add up to (F-015 §2.1 item 4).
/// `spent` is the gross of the matching spends (refunds are not taken off)
/// and null when no spend matches; `refunds` is null when no refund matches
/// (D-082 (8)).
typedef ResultsSummary = ({int count, Paise? spent, Paise? refunds});

ResultsSummary resultsSummary(List<NotedSpend> matches) {
  final spends = <Paise>[];
  final refunds = <Paise>[];
  for (final entry in matches) {
    (entry.spend.direction == SpendDirection.spend ? spends : refunds).add(
      entry.spend.amount,
    );
  }
  return (
    count: matches.length,
    spent: spends.isEmpty ? null : Paise.sum(spends),
    refunds: refunds.isEmpty ? null : Paise.sum(refunds),
  );
}

/// The matching entries of one stored month.
typedef MonthEntries = ({int id, BudgetMonth month, List<NotedSpend> entries});

/// One day of the list: F-009's day group (heading, net total of the shown
/// entries, order) and the entries with their notes in the same order.
typedef NotedDay = ({DayGroup group, List<NotedSpend> entries});

/// One budget month of the list.
typedef MonthSection = ({int monthId, BudgetMonth month, List<NotedDay> days});

/// Groups [months] (newest first, matching entries only) into sections of
/// day groups. A month without entries has no section (AC-6, TC-015-47). The
/// days reuse [groupSpendsByDay], so order, headings and net totals are
/// F-009's (D-048 (8)).
List<MonthSection> groupEntries(List<MonthEntries> months, CalendarDate today) {
  final sections = <MonthSection>[];
  for (final month in months) {
    if (month.entries.isEmpty) continue;
    final byId = {for (final e in month.entries) e.spend.id: e};
    final groups = groupSpendsByDay([
      for (final e in month.entries) e.spend,
    ], today);
    sections.add((
      monthId: month.id,
      month: month.month,
      days: [
        for (final group in groups)
          (
            group: group,
            entries: [for (final spend in group.spends) byId[spend.id]!],
          ),
      ],
    ));
  }
  return List.unmodifiable(sections);
}
