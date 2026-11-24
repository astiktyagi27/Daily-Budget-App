import 'package:daily_budget/domain/budget/calendar_date.dart';
import 'package:daily_budget/domain/budget/paise.dart';
import 'package:daily_budget/domain/budget/spend.dart';
import 'package:daily_budget/domain/budget/spend_category.dart';

/// What the "Where your money went" card shows (F-013 AC-2 to AC-5).
enum BreakdownKind {
  /// No spend in the range: `Nothing spent ...`.
  empty,

  /// Every spend is in one category: one sentence, no bar (AC-2, AC-3).
  single,

  /// Two or more categories: ranked rows (AC-4).
  several,
}

/// One category of the breakdown. `percent` is the share of the gross spent,
/// in whole percent rounded down; `underOnePercent` marks a share above 0 and
/// below 1 percent (shown as `<1%`); `barPermille` is the same share in
/// thousandths (the bar length, F-013 AC-4, design B-7).
typedef CategoryRow = ({
  SpendCategory category,
  Paise amount,
  int percent,
  bool underOnePercent,
  int barPermille,
});

/// The spends of a date range grouped by category (F-013 T-382).
///
/// `spent` is the gross sum of the spends, `refunds` the money in and
/// `netSpent` their difference, which equals the engine's `spentSoFar` when
/// the range is the engine's counted range (AC-7).
final class CategoryBreakdown {
  const new({
    required this.rows,
    required this.spent,
    required this.refunds,
    required this.kind,
  });

  /// The categories with a spend, biggest first; ties in README order.
  final List<CategoryRow> rows;

  final Paise spent;

  final Paise refunds;

  final BreakdownKind kind;

  Paise get netSpent => spent - refunds;

  bool get hasRefunds => refunds.isPositive;

  /// The category of the [BreakdownKind.single] state, else null.
  SpendCategory? get singleCategory =>
      kind == BreakdownKind.single ? rows.first.category : null;

  /// Whether the shown whole percents add up to 100 (`<1%` counts as 0).
  bool get percentsAddUpTo100 {
    var sum = 0;
    for (final row in rows) {
      sum += row.percent;
    }
    return sum == 100;
  }

  /// Whether the card says `Percentages are rounded down ...` (AC-4): only
  /// with several categories whose shown percents do not add up to 100.
  bool get roundingNoteNeeded =>
      kind == BreakdownKind.several && !percentsAddUpTo100;
}

/// Groups the [spends] dated from [from] to [to] (both included) by category.
/// Spends without a category count as Other. The caller passes the range the
/// engine counts (first budgeted day to today, never past the month's end).
///
/// Integer paise only: a share is `amount * 100 ~/ spent`, a bar is
/// `amount * 1000 ~/ spent`. The largest case, ₹10 crore for 31 days, is
/// 3.1 x 10^11 paise; times 1000 it is far below 2^53, so it is exact.
CategoryBreakdown categoryBreakdown(
  Iterable<Spend> spends,
  CalendarDate from,
  CalendarDate to,
) {
  final byCategory = <SpendCategory, int>{};
  var gross = 0;
  var back = 0;
  for (final spend in spends) {
    if (spend.date.isBefore(from) || spend.date.isAfter(to)) continue;
    switch (spend.direction) {
      case SpendDirection.spend:
        final category = spend.category ?? SpendCategory.other;
        byCategory[category] = (byCategory[category] ?? 0) + spend.amount.value;
        gross += spend.amount.value;
      case SpendDirection.moneyIn:
        back += spend.amount.value;
    }
  }

  final ranked = byCategory.entries.toList()
    ..sort((a, b) {
      final byAmount = b.value.compareTo(a.value);
      return byAmount != 0 ? byAmount : a.key.index.compareTo(b.key.index);
    });
  final rows = <CategoryRow>[
    for (final entry in ranked)
      (
        category: entry.key,
        amount: Paise(entry.value),
        percent: entry.value * 100 ~/ gross,
        underOnePercent: entry.value * 100 ~/ gross == 0,
        barPermille: entry.value * 1000 ~/ gross,
      ),
  ];
  return CategoryBreakdown(
    rows: List.unmodifiable(rows),
    spent: Paise(gross),
    refunds: Paise(back),
    kind: switch (rows.length) {
      0 => BreakdownKind.empty,
      1 => BreakdownKind.single,
      _ => BreakdownKind.several,
    },
  );
}
