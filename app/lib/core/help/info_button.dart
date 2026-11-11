import 'package:daily_budget/core/copy/help_copy.dart';
import 'package:daily_budget/core/help/help_info.dart';
import 'package:daily_budget/core/help/help_sheet.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/focus_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// The (i) button (F-004 AC-2…AC-4, help-pattern §3.1): an 18 dp info icon
/// in a 48 × 48 dp target that opens the help sheet for [info].
///
/// It is always its own screen-reader item, `More about <label>`, button,
/// even inside a list row, and its tap never reaches the row.
class InfoButton extends StatefulWidget {
  const new({required this.label, required this.info, super.key});

  /// The label the (i) explains; read as `More about <label>`.
  final String label;
  final HelpInfo info;

  static const double iconSize = 18;

  @override
  State<InfoButton> createState() => _InfoButtonState();
}

class _InfoButtonState extends State<InfoButton> {
  final _focusNode = FocusNode(debugLabel: 'InfoButton');

  /// Ignores a second tap while the sheet is open, so sheets never stack.
  bool _open = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _show() async {
    if (_open) return;
    _open = true;
    try {
      await showHelpSheet(context, widget.info);
    } finally {
      _open = false;
    }
    if (!mounted) return;
    // Back to where the user was: keyboard focus, and TalkBack focus
    // through the semantics event (F-004 AC-3).
    _focusNode.requestFocus();
    context.findRenderObject()?.sendSemanticsEvent(const FocusSemanticEvent());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Semantics(
      container: true,
      button: true,
      label: HelpCopy.moreAbout(widget.label),
      // A round 2 dp ring 2 dp outside the 48 dp target when focused with
      // a keyboard (design system §7.1).
      child: FocusRing(
        focusNode: _focusNode,
        radius: BudgetSpacing.touchTarget / 2,
        child: InkResponse(
          focusNode: _focusNode,
          onTap: _show,
          radius: 20,
          child: SizedBox.square(
            dimension: BudgetSpacing.touchTarget,
            child: Center(
              child: Icon(
                Icons.info_outline,
                size: InfoButton.iconSize,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
