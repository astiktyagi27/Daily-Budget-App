import 'package:daily_budget/domain/budget/budget.dart';

/// A spend or money in as stored: the engine's [Spend] plus the note.
final class StoredSpend {
  const new({required this.spend, this.note});

  final Spend spend;

  /// The note, or null when there is none (an empty note reads back null).
  final String? note;

  /// The spend with its note, the shape the pure search works on (F-015).
  NotedSpend get noted => (spend: spend, note: note);
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

  /// Adds a transaction. [today] is the device date the engine needs. The
  /// direction (spend or money back) and the category are in [fields].
  Future<SpendWriteOutcome> add(
    int monthId,
    SpendFields fields, {
    required CalendarDate today,
    required int now,
  });

  /// Changes the amount, date, note, direction and category of transaction
  /// [id]. Turning a spend into money back (or back) is an ordinary update;
  /// the cover rules run as for any edit (D-084 (3)).
  Future<SpendWriteOutcome> update(
    int id,
    SpendFields fields, {
    required CalendarDate today,
    required int now,
  });

  /// Changes only the category of transaction [id] (and its `edited_at`).
  /// A category is not money (F-015 AC-13), so the engine and the covers are
  /// not touched, and the row may be of any month (AC-14). [category] null
  /// clears it. Throws an [ArgumentError] for money in: a refund has no
  /// category, and for an unknown [id].
  Future<void> updateCategory(
    int id,
    SpendCategory? category, {
    required int now,
  });

  /// Removes transaction [id] for good (no trash in Phase 2).
  Future<SpendWriteOutcome> delete(int id, {required CalendarDate today});
}
