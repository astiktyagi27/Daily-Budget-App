import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;

/// What day details shows for one day (F-012 plan §1.8): the engine's
/// [result] of the month, the [summary] of the day and its [rows], newest
/// added first.
final class DayDetailsView {
  const new({
    required this.monthId,
    required this.result,
    required this.summary,
    required this.rows,
  });

  final int monthId;

  final MonthResult result;

  final DaySummary summary;

  /// The spends and money in dated this day, newest added first.
  final List<StoredSpend> rows;
}

/// The day (month id, date), live. Loading shows placeholders, never `₹0`; a
/// failed read is an error with **Try again**.
final ProviderFamily<AsyncValue<DayDetailsView>, (int, CalendarDate)>
dayDetailsProvider =
    Provider.family<AsyncValue<DayDetailsView>, (int, CalendarDate)>((
      ref,
      key,
    ) {
      final (monthId, date) = key;
      final result = ref.watch(monthResultProvider(monthId));
      final spends = ref.watch(monthSpendsProvider(monthId));
      if (result case AsyncError(:final error, :final stackTrace)) {
        return AsyncError(error, stackTrace);
      }
      if (spends case AsyncError(:final error, :final stackTrace)) {
        return AsyncError(error, stackTrace);
      }
      final month = result.value;
      final stored = spends.value;
      if (month == null || stored == null) return const AsyncLoading();
      final byId = {for (final s in stored) s.spend.id: s};
      return AsyncData(
        DayDetailsView(
          monthId: monthId,
          result: month,
          summary: DaySummary.of(month, date),
          rows: [
            for (final spend in spendsOnDay([
              for (final s in stored) s.spend,
            ], date))
              byId[spend.id]!,
          ],
        ),
      );
    });
