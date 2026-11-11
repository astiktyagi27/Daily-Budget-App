import 'package:flutter/widgets.dart';

/// Tells a root page whether it is the current one. `AppGate` marks the
/// page that is fading out during a stage swap as not current (review N9).
class RootPageScope extends InheritedWidget {
  const new({required this.current, required super.child, super.key});

  final bool current;

  /// True unless an outgoing root page is above [context]. Pages outside
  /// `AppGate` (tests, pushed routes) count as current.
  static bool isCurrent(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RootPageScope>()?.current ??
      true;

  @override
  bool updateShouldNotify(RootPageScope oldWidget) =>
      current != oldWidget.current;
}

/// A [PopScope] for a root page: Back runs [onBack] instead of leaving the
/// app while [canPop] is false. An outgoing root page lets Back through
/// and ignores it, so only the incoming page decides (review N9).
class RootPopScope extends StatelessWidget {
  const new({
    required this.canPop,
    required this.onBack,
    required this.child,
    super.key,
  });

  final bool canPop;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final current = RootPageScope.isCurrent(context);
    return PopScope(
      canPop: canPop || !current,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && current) onBack();
      },
      child: child,
    );
  }
}
