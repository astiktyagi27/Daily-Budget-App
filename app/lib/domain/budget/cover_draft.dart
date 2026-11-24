import 'package:daily_budget/domain/budget/amount_input.dart';
import 'package:daily_budget/domain/budget/budget_engine.dart';
import 'package:daily_budget/domain/budget/calendar_date.dart';
import 'package:daily_budget/domain/budget/month_result.dart';
import 'package:daily_budget/domain/budget/paise.dart';

/// The most one cover may move: the lesser of the savings [pot] and the day's
/// uncovered [overspend], in exact paise (F-012 §2.3). Null when nothing can
/// be covered (no pot, or no overspend): the cover button is not offered.
Paise? maxCover({required Paise pot, required Paise overspend}) {
  if (!pot.isPositive || !overspend.isPositive) return null;
  return pot.atMost(overspend);
}

/// What the line under the cover amount says (F-012 §2.3).
enum CoverCaption {
  /// `This covers the whole overspend.`
  wholeOverspend,

  /// `This uses your whole savings pot.`
  wholePot,
}

/// The caption for a typed `amount`, or null for a smaller custom amount or
/// one the text does not hold. When the pot and the overspend are equal the
/// overspend caption wins.
CoverCaption? coverCaption({
  required String amountText,
  required Paise overspend,
  required Paise pot,
}) {
  if (parseAmount(amountText) case AmountValue(:final paise)) {
    if (paise == overspend) return CoverCaption.wholeOverspend;
    if (paise == pot) return CoverCaption.wholePot;
  }
  return null;
}

/// The cover form as typed, in pure Dart (F-012 plan §1.2).
final class CoverDraft {
  const new(this.amountText);

  final String amountText;
}

/// What is wrong with a typed cover. The sheet maps each to its F-012 §5
/// message; the order of the checks is the engine's refusal order (D-048
/// (1)), so a cover over both limits gets [exceedsOverspend].
enum CoverProblem {
  /// Nothing typed.
  missing,

  /// `0`, or less.
  notPositive,

  /// Letters, a comma for the decimal point, more than 2 decimals.
  badFormat,

  /// Far above ₹10 crore: never a number.
  tooLarge,

  /// More than the day's uncovered overspend.
  exceedsOverspend,

  /// More than the savings pot.
  exceedsPot,

  /// The engine refuses the day itself (not overspent, upcoming, outside the
  /// month, not budgeted): the sheet should not be open.
  notOffered,
}

/// The answer of [validateCover].
sealed class CoverCheck {
  const new();
}

/// The amount can be covered.
final class CoverOk extends CoverCheck {
  const new(this.amount);

  final Paise amount;
}

/// The amount cannot be covered, and why.
final class CoverNotOk extends CoverCheck {
  const new(this.problem);

  final CoverProblem problem;
}

/// Reads [draft] and asks the engine whether [day] may be covered by it
/// (`checkCover`). Never changes anything.
CoverCheck validateCover(
  MonthResult result,
  CalendarDate day,
  CoverDraft draft,
) => switch (parseAmount(draft.amountText)) {
  AmountEmpty() => const CoverNotOk(CoverProblem.missing),
  AmountBadFormat() ||
  AmountTooManyDecimals() => const CoverNotOk(CoverProblem.badFormat),
  AmountTooLarge() => const CoverNotOk(CoverProblem.tooLarge),
  AmountValue(:final paise) when paise > maxAmount => const CoverNotOk(
    CoverProblem.tooLarge,
  ),
  AmountValue(:final paise) => _engineSays(result, day, paise),
};

CoverCheck _engineSays(MonthResult result, CalendarDate day, Paise amount) =>
    switch (checkCover(result, day, amount)) {
      CoverAllowed() => CoverOk(amount),
      CoverRefused(:final reason) => CoverNotOk(switch (reason) {
        CoverRefusal.notPositive => CoverProblem.notPositive,
        CoverRefusal.exceedsOverspend => CoverProblem.exceedsOverspend,
        CoverRefusal.exceedsPot => CoverProblem.exceedsPot,
        CoverRefusal.outsideMonth ||
        CoverRefusal.notBudgeted ||
        CoverRefusal.upcoming ||
        CoverRefusal.notOverspent => CoverProblem.notOffered,
      }),
    };
