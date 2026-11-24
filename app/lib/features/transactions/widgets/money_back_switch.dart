import 'package:daily_budget/core/copy/money_back_copy.dart';
import 'package:daily_budget/core/help/label_description.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/focus_ring.dart';
import 'package:flutter/material.dart';

/// The `Money back / refund` row under the amount (F-016 §2, design §9 row
/// 4): the label and its description, and a switch. The whole row toggles it.
/// One screen-reader node reads `Money back / refund, switch, off` and then
/// the description. At large text the switch moves under the texts, right
/// aligned.
class MoneyBackSwitch extends StatefulWidget {
  const new({required this.value, required this.onChanged, super.key});

  final bool value;
  final ValueChanged<bool> onChanged;

  /// Above this text size the switch sits under the label and description.
  static const double stackAbove = 1.3;

  @override
  State<MoneyBackSwitch> createState() => _MoneyBackSwitchState();
}

class _MoneyBackSwitchState extends State<MoneyBackSwitch> {
  final _focusNode = FocusNode(debugLabel: 'MoneyBackSwitch');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _toggle() => widget.onChanged(!widget.value);

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) > MoneyBackSwitch.stackAbove;
    final toggle = ExcludeSemantics(
      child: Switch(value: widget.value, onChanged: widget.onChanged),
    );
    const texts = LabelDescription(
      label: MoneyBackCopy.switchLabel,
      description: MoneyBackCopy.switchDescription,
      announce: false,
    );
    return Semantics(
      container: true,
      toggled: widget.value,
      label: MoneyBackCopy.switchLabel,
      hint: MoneyBackCopy.switchDescription,
      excludeSemantics: true,
      onTap: _toggle,
      child: FocusRing(
        focusNode: _focusNode,
        child: InkWell(
          focusNode: _focusNode,
          onTap: _toggle,
          borderRadius: const BorderRadius.all(Radius.circular(BudgetRadii.md)),
          overlayColor: WidgetStateProperty.fromMap({
            WidgetState.pressed: colors.sunken,
            WidgetState.any: colors.sunken.withValues(alpha: 0),
          }),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      texts,
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: toggle,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Expanded(child: texts),
                      const SizedBox(width: BudgetSpacing.space3),
                      toggle,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
