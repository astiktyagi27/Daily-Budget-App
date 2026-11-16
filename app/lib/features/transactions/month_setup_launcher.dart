import 'dart:async';

import 'package:daily_budget/features/month_setup/month_setup_controller.dart';
import 'package:daily_budget/features/month_setup/month_setup_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the month setup screen (F-008) in [mode]: `FirstSetupMode` when no
/// month exists, `NewMonthMode(lastMonth)` for a new month. The Transactions
/// tab only needs to start it.
typedef MonthSetupLauncher = void Function(
  BuildContext context,
  SetupMode mode,
);

/// Opens F-008's setup screen, the same one Home opens. It ignores a second
/// tap until the screen is closed, so a double tap opens one screen
/// (F-008 AC-1, TC-008-49). Tests override it to see the button was pressed.
final monthSetupLauncherProvider = Provider<MonthSetupLauncher>((ref) {
  var opening = false;
  return (context, mode) {
    if (opening) return;
    opening = true;
    unawaited(
      MonthSetupScreen.open(context, mode).whenComplete(() => opening = false),
    );
  };
});
