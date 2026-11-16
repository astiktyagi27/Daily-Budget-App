import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sends the app to the background the way the engine does, one valid step
/// at a time (`AppLifecycleListener` rejects `resumed` straight to `paused`).
void sendToBackground(WidgetTester tester) {
  [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ].forEach(tester.binding.handleAppLifecycleStateChanged);
}

/// Brings the app back to the foreground from [sendToBackground].
void bringToForeground(WidgetTester tester) {
  [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ].forEach(tester.binding.handleAppLifecycleStateChanged);
}
