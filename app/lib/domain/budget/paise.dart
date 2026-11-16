/// An amount of money in integer paise: ₹1,333.33 is `Paise(133333)`
/// (STANDARDS §4).
///
/// At run time it is a plain `int`, so it costs nothing and is stored as an
/// `INTEGER`; the type still stops a day count being passed as money. There
/// is no division operator: [spreadOver] is the only way to split money.
extension type const Paise(int value) {
  /// The sum of [amounts], [zero] when there are none.
  factory sum(Iterable<Paise> amounts) {
    var total = 0;
    for (final amount in amounts) {
      total += amount.value;
    }
    return Paise(total);
  }

  static const zero = Paise(0);

  Paise operator +(Paise other) => Paise(value + other.value);

  Paise operator -(Paise other) => Paise(value - other.value);

  Paise operator -() => Paise(-value);

  bool operator >(Paise other) => value > other.value;

  bool get isNegative => value < 0;

  bool get isZero => value == 0;

  bool get isPositive => value > 0;

  /// This amount, or [zero] when it is negative.
  Paise get orZero => value < 0 ? zero : this;

  /// The smaller of this amount and [other].
  Paise atMost(Paise other) => value <= other.value ? this : other;

  /// This amount spread over [days] days, adding up exactly to it (D-035).
  ///
  /// Every day gets the amount divided by [days], rounded down; the leftover
  /// paise go one each to the first days. Throws an [ArgumentError] for fewer
  /// than 1 day or a negative amount (D-048).
  List<Paise> spreadOver(int days) {
    if (days < 1) {
      throw ArgumentError.value(days, 'days', 'must be at least 1');
    }
    if (value < 0) {
      throw ArgumentError.value(value, 'amount', 'must not be negative');
    }
    final base = value ~/ days;
    final extra = value % days;
    return List.unmodifiable(
      List.generate(days, (i) => Paise(i < extra ? base + 1 : base)),
    );
  }
}
