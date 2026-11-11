import 'dart:math' as math;

import 'package:daily_budget/core/help/help_info.dart';
import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// A label with a short description under it (F-004 AC-1, help-pattern
/// §2.1): label in the `label` style, description in `body` `textSecondary`,
/// `space1` apart. Both wrap freely and are never cut off with "…".
///
/// A screen reader reads it as one item, `<label>. <description>`. With
/// [info], an (i) button follows the label's last word; it stays a separate
/// item (`More about <label>`).
class LabelDescription extends StatelessWidget {
  const new({
    required this.label,
    this.description,
    this.enabled = true,
    this.info,
    this.below,
    this.announce = true,
    super.key,
  });

  final String label;
  final String? description;

  /// A disabled label stays readable in `textSecondary` (≥ 4.5 : 1).
  final bool enabled;

  /// Adds an (i) button after the label that opens this explanation.
  final HelpInfo? info;

  /// Shown under the description, e.g. a tag that no longer fits beside the
  /// text. Decorative: it is not read out.
  final Widget? below;

  /// False when a parent (a list row) already reads the texts out as part of
  /// its own node.
  final bool announce;

  /// Gap between the label's last word and the (i) icon (help-pattern §3.1).
  static const double _infoGap = BudgetSpacing.space1;

  /// Room kept free after the label for the (i): gap + half the icon + half
  /// the 48 dp target, so the target never sticks out of the text column.
  static const double _infoReserve =
      _infoGap + InfoButton.iconSize / 2 + BudgetSpacing.touchTarget / 2;

  /// What a screen reader reads for [label] and [description].
  static String semanticsText(String label, String? description) =>
      description == null ? label : '$label. $description';

  /// Space added above and below the text when an (i) is shown, so its
  /// 48 dp target, centred on a label line, stays inside this widget. A
  /// list row takes it off its own padding.
  static double infoInset(TextScaler scaler) {
    final lineHeight =
        scaler.scale(BudgetTypeScale.label.fontSize!) *
        BudgetTypeScale.label.height!;
    return math.max(0, (BudgetSpacing.touchTarget - lineHeight) / 2);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final labelStyle = BudgetTypeScale.label.copyWith(
      color: enabled ? colors.textPrimary : colors.textSecondary,
    );

    Widget column({required Widget labelText}) => ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          labelText,
          if (description case final description?) ...[
            const SizedBox(height: BudgetSpacing.space1),
            Text(
              description,
              style: BudgetTypeScale.body.copyWith(color: colors.textSecondary),
            ),
          ],
          if (below case final below?) ...[
            const SizedBox(height: BudgetSpacing.space2),
            below,
          ],
        ],
      ),
    );

    final content = switch (info) {
      null => column(labelText: Text(label, style: labelStyle)),
      final info => _withInfo(context, info, labelStyle, column),
    };
    if (!announce) return content;
    return Semantics(
      container: true,
      label: semanticsText(label, description),
      child: content,
    );
  }

  /// Lays the texts out with room after the label, then places the (i)
  /// right after the label's last line, measured with the same style.
  Widget _withInfo(
    BuildContext context,
    HelpInfo info,
    TextStyle labelStyle,
    Widget Function({required Widget labelText}) column,
  ) {
    final scaler = MediaQuery.textScalerOf(context);
    final inset = infoInset(scaler);
    // Resolve the style exactly as `Text` does, including the phone's Bold
    // text setting, so the measured label wraps like the real one (review M1).
    final defaults = DefaultTextStyle.of(context);
    var style = defaults.style.merge(labelStyle);
    if (MediaQuery.boldTextOf(context)) {
      style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidth = math.max<double>(
          0,
          constraints.maxWidth - _infoReserve,
        );
        final painter = TextPainter(
          text: TextSpan(text: label, style: style),
          textDirection: Directionality.of(context),
          textScaler: scaler,
          textWidthBasis: defaults.textWidthBasis,
          textHeightBehavior:
              defaults.textHeightBehavior ??
              DefaultTextHeightBehavior.maybeOf(context),
        )..layout(maxWidth: labelWidth);
        final lines = painter.computeLineMetrics();
        painter.dispose();
        final last = lines.last;
        final lastTop = lines
            .take(lines.length - 1)
            .fold<double>(0, (top, line) => top + line.height);
        final iconCentre = Offset(
          last.left + last.width + _infoGap + InfoButton.iconSize / 2,
          inset + lastTop + last.height / 2,
        );
        const half = BudgetSpacing.touchTarget / 2;
        return ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: BudgetSpacing.touchTarget,
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: inset),
                child: column(
                  labelText: Padding(
                    padding: const EdgeInsets.only(right: _infoReserve),
                    child: Text(label, style: labelStyle),
                  ),
                ),
              ),
              Positioned(
                left: iconCentre.dx - half,
                top: iconCentre.dy - half,
                child: InfoButton(label: label, info: info),
              ),
            ],
          ),
        );
      },
    );
  }
}
