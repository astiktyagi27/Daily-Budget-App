/// The Safe to spend strip's words (F-017 §5, `home-summary.md` §12), word
/// for word. Amounts arrive already formatted by `formatRupees`; this file
/// only puts the words around them.
abstract final class SafeToSpendCopy {
  static const label = 'Safe to spend';

  static const infoBody =
      'Everything left this month, including your savings pot, spread '
      'evenly over the days left (today included). '
      "It's a guide: your daily budget doesn't change, and it stays the "
      'same all day.';

  /// `₹899 a day`.
  static String aDay(String amount) => '$amount a day';

  static const underRupeeADay = 'less than ₹1 a day';

  /// `22 days left`, `1 day left`.
  static String daysLeft(int days) =>
      days == 1 ? '1 day left' : '$days days left';

  /// The separator between the amount and the days left; the value wraps
  /// only here.
  static const separator = ' · ';

  static const nothingLeft =
      'Nothing left to spread over the rest of the month.';

  /// What a screen reader says for an amount: `Safe to spend, ₹899 a day,
  /// 22 days left`.
  static String speech(String amountSpeech, int days) =>
      '$label, ${aDay(amountSpeech)}, ${daysLeft(days)}';

  static String underRupeeSpeech(int days) =>
      '$label, $underRupeeADay, ${daysLeft(days)}';

  /// The nothing-left sentence without its final full stop.
  static const nothingLeftSpeech =
      '$label, nothing left to spread over the rest of the month';
}
