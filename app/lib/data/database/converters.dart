import 'package:daily_budget/domain/budget/budget.dart';
import 'package:drift/drift.dart';

/// Stores a [CalendarDate] as its integer day number (days since 1970-01-01).
///
/// A calendar date is never a `DateTime` column: a `DateTime` read back under
/// another time zone can land on another day (look-ahead #7, F-007 AC-3). The
/// number is the same in every zone because no zone is ever involved.
class CalendarDateConverter extends TypeConverter<CalendarDate, int> {
  const new();

  @override
  CalendarDate fromSql(int fromDb) => CalendarDate.fromDayNumber(fromDb);

  @override
  int toSql(CalendarDate value) => value.dayNumber;
}

/// Stores [Paise] as an `INTEGER` number of paise (F-007 AC-2). There is no
/// `REAL` money column anywhere.
class PaiseConverter extends TypeConverter<Paise, int> {
  const new();

  @override
  Paise fromSql(int fromDb) => Paise(fromDb);

  @override
  int toSql(Paise value) => value.value;
}
