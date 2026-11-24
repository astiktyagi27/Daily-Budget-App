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

int _newestAddedFirst(Spend a, Spend b) {
  final byTime = b.createdAt.compareTo(a.createdAt);
  return byTime != 0 ? byTime : b.id.compareTo(a.id);
}

/// The spends and money in dated [date], newest added first (by `createdAt`,
/// then by id). Editing never moves one (D-048 (8)). Day details lists these
/// (F-012 AC-3).
List<Spend> spendsOnDay(List<Spend> spends, CalendarDate date) =>
    List.unmodifiable(
      <Spend>[
        for (final spend in spends)
          if (spend.date == date) spend,
      ]..sort(_newestAddedFirst),
    );

/// Groups [spends] by day, the newest day first, and within a day the newest
/// added first (by `createdAt`, then by id). Editing a spend never moves it
/// (D-048). A spend dated after [today] (the device date was set back) keeps
/// its own date heading.
List<DayGroup> groupSpendsByDay(List<Spend> spends, CalendarDate today) {
  final sorted = [...spends]
    ..sort((a, b) {
      final byDay = b.date.compareTo(a.date);
      return byDay != 0 ? byDay : _newestAddedFirst(a, b);
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
