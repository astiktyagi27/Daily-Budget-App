import 'package:daily_budget/domain/budget/calendar_date.dart';
import 'package:daily_budget/domain/budget/paise.dart';

/// One "Cover with savings" move: [amount] from the savings pot to an
/// overspent [day] (D-005).
final class Cover {
  const new({
    required this.id,
    required this.day,
    required this.amount,
    required this.madeAt,
  });

  final int id;

  final CalendarDate day;

  /// The stored amount. It can be ₹0 after a D-040 reduction was saved.
  final Paise amount;

  /// When the cover was made (UTC milliseconds since 1970). The newest
  /// covers are reduced first (D-040).
  final int madeAt;
}
