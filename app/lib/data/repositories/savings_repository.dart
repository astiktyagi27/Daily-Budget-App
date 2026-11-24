import 'package:daily_budget/domain/budget/budget.dart';

/// What `SavingsRepository.cover` did: the engine's `decision` and, only when
/// the cover was stored, the id of the new row (Undo deletes exactly it,
/// F-012 AC-21).
typedef CoverResult = ({CoverDecision decision, int? coverId});

/// "Cover with savings" moves (F-007 plan 2, F-012).
abstract interface class SavingsRepository {
  /// The month's covers, oldest first. A reduced cover stays in the list with
  /// its lowered amount (0 means taken back, D-048).
  Stream<List<Cover>> watchCovers(int monthId);

  /// Moves [amount] from the pot to the overspent [day] when the engine
  /// allows it. The move is stored only for [CoverAllowed], and its id is in
  /// the result; a [CoverRefused] stores nothing and has no id. [now] is UTC
  /// milliseconds since 1970.
  Future<CoverResult> cover(
    int monthId,
    CalendarDate day,
    Paise amount, {
    required CalendarDate today,
    required int now,
  });

  /// Deletes the covers [coverIds] of month [monthId] in one transaction
  /// (Undo and Remove cover, F-012 D-056). Ids that do not exist, or belong to
  /// another month, are ignored, so a late Undo after a Remove does nothing.
  /// A write failure throws `StorageException(write)` and deletes nothing.
  Future<void> removeCovers(int monthId, Set<int> coverIds);
}
