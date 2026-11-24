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

/// The amount as a calendar cell writes it (F-011 AC-11, design system §7.5,
/// D-073): below ₹10,000 the full [formatRupees] text; from ₹10,000 thousands
/// (`₹12k`), lakh (`₹1.5L`, `₹12L`) and crore (`₹1.5Cr`, `₹12Cr`), cut and
/// never rounded up, a trailing `.0` dropped. The amount alone decides. The
/// sign is kept; `−₹0` never appears.
String formatRupeesShort(Paise amount) {
  final rupees = _wholeRupees(amount);
  if (rupees < 10000) return formatRupees(amount);
  final text = switch (rupees) {
    < 100000 => '${rupees ~/ 1000}k',
    < 1000000 => _oneDecimal(rupees ~/ 10000, 'L'),
    < 10000000 => '${rupees ~/ 100000}L',
    < 100000000 => _oneDecimal(rupees ~/ 1000000, 'Cr'),
    _ => '${rupees ~/ 10000000}Cr',
  };
  return amount.isNegative ? '$_minus$_wordJoiner₹$text' : '₹$text';
}

/// [tenths] tenths of a unit: `15` and `L` give `1.5L`, `10` gives `1L`.
String _oneDecimal(int tenths, String unit) {
  final whole = tenths ~/ 10;
  final decimal = tenths % 10;
  return decimal == 0 ? '$whole$unit' : '$whole.$decimal$unit';
}

/// Whole rupees of [amount] without its sign, rounded down.
int _wholeRupees(Paise amount) => amount.wholeRupees.abs();

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

/// The amount in words for a long sentence read by a screen reader:
/// `35,000 rupees`, `minus 1,000 rupees`, `1 rupee` (F-014 AC-16).
String formatRupeesSpoken(Paise amount) {
  final rupees = _wholeRupees(amount);
  final unit = rupees == 1 ? 'rupee' : 'rupees';
  final text = '${_groupIndian(rupees)} $unit';
  return amount.isNegative && rupees > 0 ? 'minus $text' : text;
}
