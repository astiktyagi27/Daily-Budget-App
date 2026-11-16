import 'package:daily_budget/domain/budget/paise.dart';

/// One fixed cost of a month, e.g. Rent ₹10,000. The engine only adds the
/// amounts; the name is kept for "what changed" between periods.
final class FixedCost {
  const new({required this.name, required this.amount});

  final String name;

  final Paise amount;
}
