import 'package:daily_budget/features/shell/app_tab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The tab on screen (F-003). Session-only state: the app always opens on
/// Home (AC-7), so nothing is saved. The shell reads and writes it; a screen
/// that only needs to send the user to another tab ("Go to Transactions",
/// F-013 AC-2) writes it too, without a route.
final selectedTabProvider = NotifierProvider<SelectedTabNotifier, AppTab>(
  SelectedTabNotifier.new,
);

class SelectedTabNotifier extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.home;

  // ignore: use_setters_to_change_properties, a Notifier method, not a setter.
  void select(AppTab tab) => state = tab;
}
