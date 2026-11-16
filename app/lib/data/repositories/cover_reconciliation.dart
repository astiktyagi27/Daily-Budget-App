import 'package:daily_budget/domain/budget/budget.dart';

/// What a spend edit does to the stored savings covers (D-040, D-048).
typedef CoverReconciliation = ({
  /// The covers whose stored amount must be lowered to [EffectiveCover.amount],
  /// in the same transaction as the edit.
  List<EffectiveCover> toStore,

  /// The covers reduced because the pot shrank, newest first, for the note
  /// the screen shows (D-040). Over-cover clamps are not listed.
  List<CoverReduction> reductions,
});

/// Runs the engine on [input] (the month after the edit) and works out which
/// stored covers differ from what the engine says they really move.
///
/// A stored amount is only ever lowered, and stays lowered: a later edit that
/// grows the pot never brings it back (D-048). Both the Drift repository and
/// the in-memory fakes use this one function, so they cannot disagree.
CoverReconciliation reconcileCovers(MonthInput input) {
  final result = computeMonth(input);
  final stored = {for (final cover in input.covers) cover.id: cover.amount};
  return (
    toStore: [
      for (final effective in result.effectiveCovers)
        if (effective.amount != stored[effective.coverId]) effective,
    ],
    reductions: result.reductions,
  );
}
