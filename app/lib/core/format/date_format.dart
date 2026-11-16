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

/// `Mon, 9 Nov`.
String formatWeekdayDayMonth(CalendarDate date) =>
    '${_shortWeekdays[_weekdayIndex(date)]}, ${formatDayMonth(date)}';

/// `Monday 9 November`, for screen readers.
String formatFullDate(CalendarDate date) =>
    '${_longWeekdays[_weekdayIndex(date)]} ${date.day} '
    '${_longMonths[date.month - 1]}';

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

/// 0 is Monday. 1 January 1970 (day number 0) was a Thursday.
int _weekdayIndex(CalendarDate date) => (date.dayNumber + 3) % 7;
