import 'package:flutter/material.dart';

/// Help for a standard navigation control (F-004 §2.3, help-pattern §5): a
/// long-press tooltip plus the same text as the control's screen-reader
/// hint. Features use this instead of a bare `Tooltip`.
///
/// The hint is merged into [child]'s own node, so it is read with the
/// control's label and not as a separate item.
class NavTooltip extends StatelessWidget {
  const new({required this.message, required this.child, this.hint, super.key});

  final String message;
  final Widget child;

  /// The screen-reader hint when it differs from [message], e.g. a close
  /// button whose tooltip is `Close` and whose hint says what closing does.
  final String? hint;

  /// How long the tooltip stays after the finger is lifted (help-pattern §5).
  static const showDuration = Duration(milliseconds: 1500);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      showDuration: showDuration,
      // The hint below already carries the text for screen readers.
      excludeFromSemantics: true,
      child: MergeSemantics(
        child: Semantics(hint: hint ?? message, child: child),
      ),
    );
  }
}
