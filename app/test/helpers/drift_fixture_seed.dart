import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';

import '../data/repositories/repository_setup.dart';
import '../domain/budget/fixtures.dart' show at;
import 'phase3_fixtures.dart';

/// The month ids and stored entry ids of a fixture put into Drift.
final class DriftSeed {
  const new({required this.monthIds, required this.entryIds});

  /// The month ids in the fixture's month order (oldest stored first).
  final List<int> monthIds;

  /// The transaction id of every fixture entry, per month, in entry order.
  final List<List<int>> entryIds;

  int get currentMonthId => monthIds.last;
}

/// Stores [fixture] through the real repositories: months, periods, every
/// entry with its category and direction (created at the entry's time) and
/// the covers as rows with the spec's made time (as `seedW2`). Spends go in
/// before the covers, so no cover is reduced on the way in.
Future<DriftSeed> seedDriftFixture(Repos repos, Phase3Fixture fixture) async {
  final monthIds = <int>[];
  final entryIds = <List<int>>[];
  for (final month in fixture.months) {
    final stored = await repos.months.confirmMonth(
      NewMonth(
        month: month.month,
        firstBudgetedDay: month.firstBudgetedDay,
        firstPeriod: month.periods.first,
        confirmedAt: at(month.firstBudgetedDay, 8),
      ),
    );
    for (final period in month.periods.skip(1)) {
      await repos.months.addPeriod(stored.id, period);
    }
    monthIds.add(stored.id);
    final ids = <int>[];
    for (final entry in month.entries) {
      final written = await repos.spends.add(
        stored.id,
        (
          amount: Paise(entry.paise),
          date: entry.date,
          note: entry.note,
          category: entry.categoryKey == null
              ? null
              : SpendCategory.fromKey(entry.categoryKey),
          direction: entry.moneyIn
              ? SpendDirection.moneyIn
              : SpendDirection.spend,
        ),
        today: fixture.today,
        now: entry.createdAt,
      );
      ids.add(written.id);
    }
    entryIds.add(ids);
    for (final cover in month.covers) {
      await repos.db
          .into(repos.db.savingsMoves)
          .insert(
            SavingsMovesCompanion.insert(
              monthId: stored.id,
              coveredDay: cover.day,
              amountPaise: Paise(cover.paise),
              madeAt: cover.madeAt,
            ),
          );
    }
  }
  return DriftSeed(monthIds: monthIds, entryIds: entryIds);
}

/// The engine's result for month [monthId] as stored, on [today].
Future<MonthResult> storedResult(
  Repos repos,
  int monthId,
  CalendarDate today,
) async {
  final month = (await repos.months.watchMonth(monthId).first)!;
  final spends = await repos.spends.watchMonthSpends(monthId).first;
  final covers = await repos.savings.watchCovers(monthId).first;
  return computeMonth(
    MonthInput(
      month: month.month,
      firstBudgetedDay: month.firstBudgetedDay,
      periods: month.periods,
      today: today,
      spends: [for (final s in spends) s.spend],
      covers: covers,
    ),
  );
}
