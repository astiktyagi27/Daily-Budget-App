import 'package:daily_budget/domain/budget/calendar_date.dart';
import 'package:daily_budget/domain/budget/paise.dart';
import 'package:daily_budget/domain/budget/spend_category.dart';

/// Whether a transaction is a spend or money in, such as a refund (D-047).
enum SpendDirection { spend, moneyIn }

/// One spend or money in on a calendar date. The [amount] is always more
/// than ₹0; the [direction] gives the sign.
final class Spend {
  const new({
    required this.id,
    required this.date,
    required this.amount,
    required this.createdAt,
    this.direction = SpendDirection.spend,
    this.category,
  });

  final int id;

  final CalendarDate date;

  final Paise amount;

  /// When it was added (UTC milliseconds since 1970). Only for ordering.
  final int createdAt;

  final SpendDirection direction;

  /// The category, or null when none was stored (it reads as Other). The
  /// engine never reads it: no money rule depends on a category (F-013).
  final SpendCategory? category;
}
