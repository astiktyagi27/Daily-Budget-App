import 'package:daily_budget/domain/budget/calendar_date.dart';
import 'package:daily_budget/domain/budget/paise.dart';
import 'package:daily_budget/domain/budget/spend.dart';

/// How a day heading is written: `Today`, `Yesterday` or the date.
enum DayLabel { today, yesterday, other }

/// The spends of one day, for the Transactions list (F-009 §2.1). `total` is
/// the net spend: spends minus any money in. `spends` are newest added
/// first.
typedef DayGroup = ({
  CalendarDate date,
  DayLabel label,
  Paise total,
  List<Spend> spends,
});

/// Groups [spends] by day, the newest day first, and within a day the newest
/// added first (by `createdAt`, then by id). Editing a spend never moves it
/// (D-048). A spend dated after [today] (the device date was set back) keeps
/// its own date heading.
List<DayGroup> groupSpendsByDay(List<Spend> spends, CalendarDate today) {
  final sorted = [...spends]
    ..sort((a, b) {
      final byDay = b.date.compareTo(a.date);
      if (byDay != 0) return byDay;
      final byTime = b.createdAt.compareTo(a.createdAt);
      return byTime != 0 ? byTime : b.id.compareTo(a.id);
    });
  final groups = <DayGroup>[];
  var i = 0;
  while (i < sorted.length) {
    final date = sorted[i].date;
    final inDay = <Spend>[];
    while (i < sorted.length && sorted[i].date == date) {
      inDay.add(sorted[i]);
      i++;
    }
    groups.add((
      date: date,
      label: switch (date.daysUntil(today)) {
        0 => DayLabel.today,
        1 => DayLabel.yesterday,
        _ => DayLabel.other,
      },
      total: Paise.sum([
        for (final spend in inDay)
          switch (spend.direction) {
            SpendDirection.spend => spend.amount,
            SpendDirection.moneyIn => -spend.amount,
          },
      ]),
      spends: List.unmodifiable(inDay),
    ));
  }
  return List.unmodifiable(groups);
}
