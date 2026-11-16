import 'package:daily_budget/domain/budget/budget.dart';

/// "Cover with savings" moves (F-007 plan 2). Phase 3 adds the screen; in
/// Phase 2 the repository exists and its tests drive it.
abstract interface class SavingsRepository {
  /// The month's covers, oldest first. A reduced cover stays in the list with
  /// its lowered amount (0 means taken back, D-048).
  Stream<List<Cover>> watchCovers(int monthId);

  /// Moves [amount] from the pot to the overspent [day] when the engine
  /// allows it. The move is stored only for [CoverAllowed]; a [CoverRefused]
  /// stores nothing. [now] is UTC milliseconds since 1970.
  Future<CoverDecision> cover(
    int monthId,
    CalendarDate day,
    Paise amount, {
    required CalendarDate today,
    required int now,
  });
}
