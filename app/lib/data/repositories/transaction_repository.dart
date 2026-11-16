import 'package:daily_budget/domain/budget/budget.dart';

/// A spend or money in as stored: the engine's [Spend] plus the note.
final class StoredSpend {
  const new({required this.spend, this.note});

  final Spend spend;

  /// The note, or null when there is none (an empty note reads back null).
  final String? note;
}

/// What a spend write did to the savings covers (D-040, D-048).
final class SpendWriteOutcome {
  const new({required this.id, this.reductions = const []});

  /// The id of the spend that was added, changed or deleted.
  final int id;

  /// The covers the write reduced because the pot shrank, newest first, for
  /// the note the screen shows. The reduced amounts are already stored.
  final List<CoverReduction> reductions;
}

/// Spends and money in of a month (F-007 plan 2).
///
/// After every write, in the same transaction, the month is recomputed and
/// any cover the engine now moves less is lowered in the database too.
abstract interface class TransactionRepository {
  /// The month's transactions: newest day first, then newest created first,
  /// then highest id (an edit never moves an entry within its day, D-048).
  /// Emits again after every add, edit and delete.
  Stream<List<StoredSpend>> watchMonthSpends(int monthId);

  /// Adds a transaction. [today] is the device date the engine needs.
  /// [direction] is [SpendDirection.spend] for every Phase 2 screen.
  Future<SpendWriteOutcome> add(
    int monthId,
    SpendFields fields, {
    required CalendarDate today,
    required int now,
    SpendDirection direction = SpendDirection.spend,
  });

  /// Changes the amount, date and note of transaction [id].
  Future<SpendWriteOutcome> update(
    int id,
    SpendFields fields, {
    required CalendarDate today,
    required int now,
  });

  /// Removes transaction [id] for good (no trash in Phase 2).
  Future<SpendWriteOutcome> delete(int id, {required CalendarDate today});
}
