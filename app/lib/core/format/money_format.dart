import 'package:daily_budget/domain/budget/budget.dart';

/// U+2212, the true minus sign (design system §4.3).
const _minus = '\u2212';

/// U+2060, kept between the minus and the rupee sign so a line never breaks
/// after the sign.
const _wordJoiner = '\u2060';

/// The one way money is written on screen (F-008 AC-19, D-038, design
/// system §4.3): whole rupees, rounded toward zero, Indian grouping.
///
/// `₹666.67` shows as `₹666`, `₹1,33,334` stays whole, and a negative amount
/// is `−` + U+2060 + the rupees (`−₹1,000`). When the whole rupees are 0 there
/// is no sign (`−₹0` never appears, D-050). Paise are shown only inside input
/// fields. Integers only: no floating point is ever involved.
String formatRupees(Paise amount) {
  final rupees = _wholeRupees(amount);
  final text = '₹${_groupIndian(rupees)}';
  return amount.isNegative && rupees > 0 ? '$_minus$_wordJoiner$text' : text;
}

/// The same amount for a screen reader: `minus ₹1,000`, with no invisible
/// characters (TalkBack does not read U+2212 consistently).
String formatRupeesForSpeech(Paise amount) {
  final rupees = _wholeRupees(amount);
  final text = '₹${_groupIndian(rupees)}';
  return amount.isNegative && rupees > 0 ? 'minus $text' : text;
}

/// Whole rupees of [amount] without its sign, rounded down.
int _wholeRupees(Paise amount) => amount.value.abs() ~/ 100;

/// `1234567` becomes `12,34,567`: the last three digits, then pairs.
String _groupIndian(int rupees) {
  final digits = rupees.toString();
  if (digits.length <= 3) return digits;
  final head = digits.substring(0, digits.length - 3);
  final tail = digits.substring(digits.length - 3);
  final groups = <String>[];
  for (var end = head.length; end > 0; end -= 2) {
    final start = end - 2 < 0 ? 0 : end - 2;
    groups.add(head.substring(start, end));
  }
  return '${groups.reversed.join(',')},$tail';
}
