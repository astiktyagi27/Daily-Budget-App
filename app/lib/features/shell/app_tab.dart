import 'package:daily_budget/core/copy/help_copy.dart';
import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:flutter/material.dart';

/// The four main tabs, in bar order (F-003 AC-1, app-shell §3).
enum AppTab {
  home(
    label: ScreenCopy.tabHome,
    title: ScreenCopy.appName,
    hint: HelpCopy.navHomeHint,
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  dashboard(
    label: ScreenCopy.tabDashboard,
    title: ScreenCopy.tabDashboard,
    hint: HelpCopy.navDashboardHint,
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
  ),
  transactions(
    label: ScreenCopy.tabTransactions,
    title: ScreenCopy.tabTransactions,
    hint: HelpCopy.navTransactionsHint,
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
  ),
  settings(
    label: ScreenCopy.tabSettings,
    title: ScreenCopy.tabSettings,
    hint: HelpCopy.navSettingsHint,
    icon: Icons.tune_outlined,
    selectedIcon: Icons.tune,
  );

  new({
    required this.label,
    required this.title,
    required this.hint,
    required this.icon,
    required this.selectedIcon,
  });

  /// Bar label.
  final String label;

  /// Title header of the tab page (Home shows the app name).
  final String title;

  /// Long-press tooltip and screen-reader hint.
  final String hint;

  /// Outlined icon; [selectedIcon] is the filled one.
  final IconData icon;
  final IconData selectedIcon;

  /// `Home, tab 1 of 4`.
  String get semanticsLabel =>
      ScreenCopy.tabPosition(label, index + 1, values.length);
}
