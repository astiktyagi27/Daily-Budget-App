import 'package:daily_budget/domain/budget/budget.dart';

const _shortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _longMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Monday first, as `DateTime.weekday` numbers them.
const _shortWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _longWeekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

// Date labels for screens (F-008 §5, F-009 §5). English with day first, as
// `en_IN` writes them, built from the calendar date's numbers so no time
// zone or locale data is involved and the same date always reads the same.

/// `5 Nov`.
String formatDayMonth(CalendarDate date) =>
    '${date.day} ${_shortMonths[date.month - 1]}';

/// `5 Nov – 4 Dec` (an en dash with a space on each side).
String formatRange(CalendarDate start, CalendarDate end) =>
    '${formatDayMonth(start)} \u2013 ${formatDayMonth(end)}';

/// `1 – 30 Nov` inside one month, else `5 Nov – 4 Dec` (Home's day line,
/// design system §7.6).
String formatCompactRange(CalendarDate start, CalendarDate end) =>
    start.month == end.month && start.year == end.year
    ? '${start.day} – ${formatDayMonth(end)}'
    : formatRange(start, end);

/// `Mon, 9 Nov`.
String formatWeekdayDayMonth(CalendarDate date) =>
    '${_shortWeekdays[date.weekdayIndex]}, ${formatDayMonth(date)}';

/// `Monday 9 November`, for screen readers.
String formatFullDate(CalendarDate date) =>
    '${_longWeekdays[date.weekdayIndex]} ${date.day} '
    '${_longMonths[date.month - 1]}';

/// `November`: the full name of [date]'s calendar month (month separators of
/// the Transactions list, F-015).
String formatMonthName(CalendarDate date) => _longMonths[date.month - 1];

/// `1st`, `2nd`, `3rd`, `4th`, `11th`, `12th`, `13th`, `21st`, `22nd`,
/// `23rd`, `31st`.
String formatOrdinal(int day) {
  final teen = day % 100 >= 11 && day % 100 <= 13;
  final suffix = teen
      ? 'th'
      : switch (day % 10) {
          1 => 'st',
          2 => 'nd',
          3 => 'rd',
          _ => 'th',
        };
  return '$day$suffix';
}

/// `1 day`, `31 days`.
String formatDayCount(int days) => days == 1 ? '1 day' : '$days days';

/// `10:00`, `18:05`: the time of day of [utcMillis] (UTC milliseconds since
/// 1970, as stored) on this phone, 24 hours (F-014 same-day changes).
///
/// The conversion to local time is made here, never in `domain/`
/// (`domain_layering_test` keeps the engine free of the clock and time zone).
String formatClockTime(int utcMillis) {
  final local = DateTime.fromMillisecondsSinceEpoch(
    utcMillis,
    isUtc: true,
  ).toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
