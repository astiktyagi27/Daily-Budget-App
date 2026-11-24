/// The budget engine (F-006): pure Dart, integer paise and calendar dates.
/// "Today" is always passed in, never read from the device.
///
/// One library per file; this barrel is the only import callers need (D-059).
library;

export 'package:daily_budget/domain/budget/amount_input.dart';
export 'package:daily_budget/domain/budget/budget_engine.dart';
export 'package:daily_budget/domain/budget/budget_month.dart';
export 'package:daily_budget/domain/budget/budget_period.dart';
export 'package:daily_budget/domain/budget/calendar_date.dart';
export 'package:daily_budget/domain/budget/calendar_grid.dart';
export 'package:daily_budget/domain/budget/category_breakdown.dart';
export 'package:daily_budget/domain/budget/cover.dart';
export 'package:daily_budget/domain/budget/cover_draft.dart';
export 'package:daily_budget/domain/budget/day_summary.dart';
export 'package:daily_budget/domain/budget/fixed_cost.dart';
export 'package:daily_budget/domain/budget/home_summary.dart';
export 'package:daily_budget/domain/budget/month_figures.dart';
export 'package:daily_budget/domain/budget/month_input.dart';
export 'package:daily_budget/domain/budget/month_result.dart';
export 'package:daily_budget/domain/budget/month_statement.dart';
export 'package:daily_budget/domain/budget/paise.dart';
export 'package:daily_budget/domain/budget/safe_to_spend.dart';
export 'package:daily_budget/domain/budget/setup_draft.dart';
export 'package:daily_budget/domain/budget/spend.dart';
export 'package:daily_budget/domain/budget/spend_category.dart';
export 'package:daily_budget/domain/budget/spend_draft.dart';
export 'package:daily_budget/domain/budget/spend_groups.dart';
export 'package:daily_budget/domain/budget/spread_outcome.dart';
export 'package:daily_budget/domain/budget/today_line.dart';
export 'package:daily_budget/domain/budget/transaction_search.dart';
export 'package:daily_budget/domain/budget/whole_rupees.dart';
