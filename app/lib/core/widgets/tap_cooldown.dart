import 'dart:async';

import 'package:flutter/gestures.dart';

/// A double-tap window (`kDoubleTapTimeout`, 300 ms) during which the second
/// tap of a double tap is ignored (F-004 help-pattern §3.2, F-005 AC-13).
/// One place for the four guards: the sheet scrim, the tour's Next, the
/// explainer buttons and the gate's guard on Home (D-031, D-044).
///
/// The owner calls [dispose] when it goes away, so no timer outlives it.
class TapCooldown {
  Timer? _timer;

  /// True from [start] until the window has passed.
  bool get isActive => _timer?.isActive ?? false;

  /// Opens a new window; [onEnd] runs when it has passed (not on [dispose]).
  void start({void Function()? onEnd}) {
    _timer?.cancel();
    _timer = Timer(kDoubleTapTimeout, () => onEnd?.call());
  }

  void dispose() => _timer?.cancel();
}
