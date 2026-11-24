import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/statement/month_statement_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the month statement (F-014) for the stored month [monthId]. With
/// [scrollToPeriodStart] the statement opens at the period that starts on
/// that day (Day details, F-012).
typedef MonthStatementLauncher = void Function(
  BuildContext context,
  int monthId, {
  CalendarDate? scrollToPeriodStart,
});

/// The one way into the statement for Home (F-010), the Dashboard (F-013)
/// and Day details (F-012), the same seam as `monthSetupLauncherProvider`
/// (F-009). The default pushes the real screen (T-402); tests override it to
/// see which month was asked for.
final monthStatementLauncherProvider = Provider<MonthStatementLauncher>(
  (ref) => MonthStatementScreen.open,
);

/// Opens the month statement through [monthStatementLauncherProvider].
void openMonthStatement(
  BuildContext context,
  int monthId, {
  CalendarDate? scrollToPeriodStart,
}) {
  ProviderScope.containerOf(context).read(monthStatementLauncherProvider)(
    context,
    monthId,
    scrollToPeriodStart: scrollToPeriodStart,
  );
}
