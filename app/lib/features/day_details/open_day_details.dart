import 'dart:async';

import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/day_details/day_details_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the day details screen (F-012) for [date] of the stored month
/// [monthId].
typedef DayDetailsLauncher = void Function(
  BuildContext context, {
  required int monthId,
  required CalendarDate date,
});

/// The one way into Day details for the Dashboard (F-013), the same seam as
/// `monthStatementLauncherProvider` (F-014) and `monthSetupLauncherProvider`
/// (F-009). The default does nothing, so the Dashboard can be built and
/// tested before the Day details screen exists; F-012 T-345 replaced it with
/// the route (the default now pushes the screen). Tests override it to see
/// which day was asked for.
final dayDetailsLauncherProvider = Provider<DayDetailsLauncher>(
  (ref) =>
      (context, {required monthId, required date}) => unawaited(
        DayDetailsScreen.open(context, monthId: monthId, date: date),
      ),
);

/// Opens Day details through [dayDetailsLauncherProvider].
void openDayDetails(
  BuildContext context, {
  required int monthId,
  required CalendarDate date,
}) {
  ProviderScope.containerOf(context)
      .read(dayDetailsLauncherProvider)(context, monthId: monthId, date: date);
}
