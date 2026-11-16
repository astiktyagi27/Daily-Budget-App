// Drift column checks refer to the column being defined (`check(x.isIn(...))`),
// which the analyzer reads as a recursive getter.
// ignore_for_file: recursive_getters

import 'package:daily_budget/data/database/converters.dart';
import 'package:drift/drift.dart';

// Schema v1 (F-007 plan section 3). Money is INTEGER paise, calendar dates are
// INTEGER day numbers, and every `*_at` column is INTEGER UTC milliseconds
// used only for ordering. There is no `dateTime()` column.

/// One confirmed budget month.
@DataClassName('MonthRow')
class BudgetMonths extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get startDay =>
      integer().map(const CalendarDateConverter()).unique()();

  IntColumn get endDay => integer().map(const CalendarDateConverter())();

  IntColumn get salaryDay =>
      integer().check(salaryDay.isBetweenValues(1, 31))();

  IntColumn get firstBudgetedDay =>
      integer().map(const CalendarDateConverter())();

  IntColumn get confirmedAt => integer()();
}

/// One dated period of a month. Append-only: triggers refuse any update or
/// delete (D-037, F-007 AC-16).
@DataClassName('PeriodRow')
@TableIndex(
  name: 'idx_periods_month',
  columns: {#monthId, #startDay, #changedAt},
)
class BudgetPeriods extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get monthId =>
      integer().references(BudgetMonths, #id, onDelete: KeyAction.restrict)();

  IntColumn get startDay => integer().map(const CalendarDateConverter())();

  IntColumn get changedAt => integer()();

  /// `full` or `midMonthStart`.
  TextColumn get kind => text().check(kind.isIn(['full', 'midMonthStart']))();

  IntColumn get salaryPaise =>
      integer().map(const PaiseConverter()).nullable()();

  IntColumn get targetPaise =>
      integer().map(const PaiseConverter()).nullable()();

  IntColumn get moneyLeftPaise =>
      integer().map(const PaiseConverter()).nullable()();

  BoolColumn get continuedWithShortfall =>
      boolean().withDefault(const Constant(false))();

  IntColumn get shortfallPaise => integer()
      .map(const PaiseConverter())
      .withDefault(const Constant(0))
      .check(shortfallPaise.isBiggerOrEqualValue(0))();

  @override
  List<String> get customConstraints => [
    "CHECK (kind <> 'full' OR salary_paise IS NOT NULL)",
    "CHECK (kind <> 'midMonthStart' OR money_left_paise IS NOT NULL)",
  ];
}

/// One fixed-cost item of one period (for a mid-month start: a cost still to
/// pay). Each period has its own copy. Append-only, like its period.
@DataClassName('FixedCostRow')
class PeriodFixedCosts extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get periodId =>
      integer().references(BudgetPeriods, #id, onDelete: KeyAction.restrict)();

  IntColumn get position => integer()();

  /// The screen limits a name to 40 characters as the user sees them; the
  /// CHECK counts code points, so 160 is only a backstop.
  TextColumn get name => text().check(name.length.isBetweenValues(1, 160))();

  IntColumn get amountPaise => integer()
      .map(const PaiseConverter())
      .check(amountPaise.isBiggerOrEqualValue(0))();
}

/// A manual spend (Phase 2) or, from Phase 4, an SMS one.
@DataClassName('TransactionRow')
@TableIndex(name: 'idx_transactions_month_day', columns: {#monthId, #day})
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get monthId =>
      integer().references(BudgetMonths, #id, onDelete: KeyAction.restrict)();

  IntColumn get day => integer().map(const CalendarDateConverter())();

  IntColumn get amountPaise => integer()
      .map(const PaiseConverter())
      .check(amountPaise.isBiggerThanValue(0))();

  /// `spend` or `money_in` (D-047).
  TextColumn get direction => text()
      .withDefault(const Constant('spend'))
      .check(direction.isIn(['spend', 'money_in']))();

  /// The note is limited to 100 characters by the screen. The CHECK counts
  /// code points, so 400 is only a backstop.
  TextColumn get note => text()
      .withDefault(const Constant(''))
      .check(note.length.isSmallerOrEqualValue(400))();

  /// `manual` now; Phase 4 adds `sms` by migration.
  TextColumn get source => text()
      .withDefault(const Constant('manual'))
      .check(source.isIn(['manual']))();

  TextColumn get category => text().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get editedAt => integer()();
}

/// A "Cover with savings" move. Updated in place only when an edit reduces or
/// clamps it, in the same transaction as that edit (D-048); 0 is kept as
/// history ("taken back").
@DataClassName('SavingsMoveRow')
class SavingsMoves extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get monthId =>
      integer().references(BudgetMonths, #id, onDelete: KeyAction.restrict)();

  IntColumn get coveredDay => integer().map(const CalendarDateConverter())();

  IntColumn get amountPaise => integer()
      .map(const PaiseConverter())
      .check(amountPaise.isBiggerOrEqualValue(0))();

  IntColumn get madeAt => integer()();
}
