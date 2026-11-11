import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Transparent system bars with icons that contrast with the theme
/// (F-002 AC-18): dark icons on Light, light icons on Dark and Dim.
SystemUiOverlayStyle systemBarsStyleFor(Brightness themeBrightness) {
  final icons = themeBrightness == Brightness.light
      ? Brightness.dark
      : Brightness.light;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: icons,
    // iOS reads the bar's own brightness, the opposite of the icons.
    statusBarBrightness: themeBrightness,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: icons,
    systemNavigationBarContrastEnforced: false,
  );
}

/// Applies [systemBarsStyleFor] the active theme to everything below it.
/// `MaterialApp.builder` wraps every route in it, so screens without an
/// `AppBar` (onboarding) get legible bars too.
class SystemBarsStyle extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemBarsStyleFor(Theme.of(context).brightness),
      child: child,
    );
  }
}
