import 'package:daily_budget/domain/budget/paise.dart';

/// The one rounding rule of every money figure on screen (D-038, D-046):
/// whole rupees, rounded toward zero. `formatRupees` and the month
/// statement's rounding note (F-014 AC-12) both use it, so the note compares
/// exactly what the screen shows.
extension WholeRupees on Paise {
  /// The whole rupees of this amount, toward zero: `66667` paise is 666,
  /// `-66667` is -666.
  int get wholeRupees => value ~/ 100;
}
