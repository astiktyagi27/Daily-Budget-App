/// A calendar date with no time of day and no time zone (look-ahead #7).
///
/// It is the number of days since 1970-01-01, so date arithmetic is integer
/// arithmetic and can never be moved by a time zone or a daylight-saving
/// change. The same number is what the database stores (F-007).
extension type const CalendarDate.fromDayNumber(int dayNumber) {
  /// The date [year]-[month]-[day]. Throws an [ArgumentError] for a date that
  /// does not exist (month outside 1 to 12, or day outside the month).
  factory(int year, int month, int day) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'must be 1 to 12');
    }
    if (day < 1 || day > daysInMonth(year, month)) {
      throw ArgumentError.value(day, 'day', 'is not a day of $year-$month');
    }
    return CalendarDate.fromDayNumber(
      DateTime.utc(year, month, day).millisecondsSinceEpoch ~/
          Duration.millisecondsPerDay,
    );
  }

  /// The year, month and day of [dateTime] as the caller already has it.
  /// Its time of day and zone are ignored: the engine never reads the
  /// current time or the time zone.
  factory fromDateTime(DateTime dateTime) =>
      CalendarDate(dateTime.year, dateTime.month, dateTime.day);

  /// The number of days in [month] of [year] (28 to 31).
  static int daysInMonth(int year, int month) =>
      DateTime.utc(year, month + 1, 0).day;

  DateTime get _utcMidnight => DateTime.fromMillisecondsSinceEpoch(
    dayNumber * Duration.millisecondsPerDay,
    isUtc: true,
  );

  int get year => _utcMidnight.year;

  int get month => _utcMidnight.month;

  int get day => _utcMidnight.day;

  /// The date [days] days later (earlier when negative).
  CalendarDate addDays(int days) =>
      CalendarDate.fromDayNumber(dayNumber + days);

  /// The number of days from this date to [other]; negative when [other] is
  /// earlier.
  int daysUntil(CalendarDate other) => other.dayNumber - dayNumber;

  int compareTo(CalendarDate other) => dayNumber.compareTo(other.dayNumber);

  bool isBefore(CalendarDate other) => dayNumber < other.dayNumber;

  bool isAfter(CalendarDate other) => dayNumber > other.dayNumber;

  /// The date as `yyyy-mm-dd`, for logs and test messages.
  String get iso =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
