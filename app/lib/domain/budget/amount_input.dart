import 'package:daily_budget/domain/budget/paise.dart';

/// The largest amount any field accepts: ₹10 crore (F-008 §2, F-009 §3).
const maxAmount = Paise(10000000000);

/// What [parseAmount] made of the text in an amount field (F-008 plan §1.3).
/// The range rules (above ₹0, at most [maxAmount], target at most salary) are
/// the caller's; this only reads the text.
sealed class AmountParse {
  const new();
}

/// Nothing but spaces and `₹` was typed.
final class AmountEmpty extends AmountParse {
  const new();
}

/// Letters, a decimal comma, misplaced grouping commas, a sign or a second
/// decimal point.
final class AmountBadFormat extends AmountParse {
  const new();
}

/// More than 2 digits after the decimal point.
final class AmountTooManyDecimals extends AmountParse {
  const new();
}

/// So many digits that the amount is far above [maxAmount]; never turned
/// into a number, so it cannot overflow.
final class AmountTooLarge extends AmountParse {
  const new();
}

/// A valid amount, exactly in paise.
final class AmountValue extends AmountParse {
  const new(this.paise);

  final Paise paise;
}

// Grouping: the Western 1,234,567 or the Indian 12,34,567, never 99,50.
final _western = RegExp(r'^\d{1,3}(,\d{3})+$');
final _indian = RegExp(r'^\d{1,2}(,\d{2})*,\d{3}$');
final _digits = RegExp(r'^\d+$');
final _skipped = RegExp(r'[\s₹]');
final _leadingZeros = RegExp('^0+');

/// More whole-rupee digits than this are far above [maxAmount].
const _maxIntegerDigits = 12;

/// Reads [text] typed or pasted into an amount field, exactly and without any
/// floating point (F-008 plan §1.3).
///
/// Spaces and `₹` are ignored. Grouping commas may be Indian or Western.
/// Leading zeros, `.5` (50 paise) and `40000.` are accepted; at most 2
/// decimals.
AmountParse parseAmount(String text) {
  final cleaned = text.replaceAll(_skipped, '');
  if (cleaned.isEmpty) return const AmountEmpty();
  final parts = cleaned.split('.');
  if (parts.length > 2) return const AmountBadFormat();
  final whole = parts[0];
  final fraction = parts.length == 2 ? parts[1] : '';
  if (whole.isEmpty && fraction.isEmpty) return const AmountBadFormat();
  final integerDigits = whole.replaceAll(',', '');
  final groupingOk =
      whole.isEmpty ||
      _digits.hasMatch(whole) ||
      _western.hasMatch(whole) ||
      _indian.hasMatch(whole);
  if (!groupingOk || (fraction.isNotEmpty && !_digits.hasMatch(fraction))) {
    return const AmountBadFormat();
  }
  if (fraction.length > 2) return const AmountTooManyDecimals();
  final significant = integerDigits.replaceFirst(_leadingZeros, '');
  if (significant.length > _maxIntegerDigits) return const AmountTooLarge();
  final rupees = significant.isEmpty ? 0 : int.parse(significant);
  final paise = fraction.isEmpty ? 0 : int.parse(fraction.padRight(2, '0'));
  return AmountValue(Paise(rupees * 100 + paise));
}

/// [amount] as the text the field shows when a saved value is edited: whole
/// rupees as `250`, otherwise with 2 decimals as `300.50` (F-009 §4).
String amountInputText(Paise amount) {
  final value = amount.value;
  final rupees = value ~/ 100;
  final paise = value % 100;
  return paise == 0 ? '$rupees' : '$rupees.${paise.toString().padLeft(2, '0')}';
}

/// What is wrong with an amount that must be more than ₹0 and at most
/// [maxAmount].
enum AmountProblem { missing, badFormat, notPositive, tooLarge }

/// The problem of [parse] as a "more than ₹0, at most ₹10 crore" amount, or
/// null when it is fine.
AmountProblem? positiveAmountProblem(AmountParse parse) => switch (parse) {
  AmountEmpty() => AmountProblem.missing,
  AmountBadFormat() || AmountTooManyDecimals() => AmountProblem.badFormat,
  AmountTooLarge() => AmountProblem.tooLarge,
  AmountValue(:final paise) when !paise.isPositive => AmountProblem.notPositive,
  AmountValue(:final paise) when paise > maxAmount => AmountProblem.tooLarge,
  AmountValue() => null,
};
