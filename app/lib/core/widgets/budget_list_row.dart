import 'dart:math' as math;

import 'package:daily_budget/core/help/help_info.dart';
import 'package:daily_budget/core/help/label_description.dart';
import 'package:daily_budget/core/theme/budget_colors.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/focus_ring.dart';
import 'package:flutter/material.dart';

/// A list row (design system §7.4, settings.md §2.1): optional leading icon in
/// a `neutralSoft` circle · label with an optional description below ·
/// optional trailing widget and/or tag. The whole row is one tap target.
///
/// With [info], an (i) button follows the label (F-004). It is a separate
/// tap target and a separate screen-reader item, and never runs [onTap].
///
/// With a keyboard or D-pad, the focused row shows the 2 dp `focus` ring,
/// drawn 2 dp inside its edge so the card does not clip it (design system
/// §7.1).
class BudgetListRow extends StatefulWidget {
  const new({
    required this.label,
    this.description,
    this.leadingIcon,
    this.trailing,
    this.tag,
    this.onTap,
    this.enabled = true,
    this.semanticsLabel,
    this.semanticsHint,
    this.info,
    this.focusNode,
    super.key,
  });

  final String label;

  /// Wraps freely, never truncated (design system §7.11a).
  final String? description;
  final IconData? leadingIcon;

  /// Value, chevron ([BudgetRowChevron]), switch…
  final Widget? trailing;

  /// A pill such as "Coming soon" ([BudgetTag]). It moves below the text when
  /// the text column beside the measured tag would be narrower than 160 dp
  /// (settings.md §7).
  final String? tag;
  final VoidCallback? onTap;

  /// A disabled row keeps a readable label (`textSecondary`, ≥ 4.5 : 1).
  final bool enabled;

  /// Replaces the label + description read by screen readers.
  final String? semanticsLabel;
  final String? semanticsHint;

  /// Adds the (i) explanation after the label. A row with an (i) only takes
  /// a decorative [trailing] (a chevron or a value), because the (i) has to
  /// stay a node of its own instead of being merged into the row.
  final HelpInfo? info;

  /// The row's keyboard focus, e.g. to move focus back to the row after
  /// the sheet it opened closes.
  final FocusNode? focusNode;

  static const double _minHeight = 56;
  static const double _minHeightWithDescription = 72;
  static const double _leadingSize = 40;
  static const double _minTextWidth = 160;

  /// What a [trailing] widget next to a tag is allowed (a chevron or a
  /// switch); only the tag is measured.
  static const double _trailingAllowance = BudgetSpacing.touchTarget;

  @override
  State<BudgetListRow> createState() => _BudgetListRowState();
}

class _BudgetListRowState extends State<BudgetListRow> {
  FocusNode? _ownFocusNode;

  FocusNode get _focusNode =>
      widget.focusNode ??
      (_ownFocusNode ??= FocusNode(debugLabel: 'BudgetListRow'));

  @override
  void dispose() {
    _ownFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BudgetListRow(
      :label,
      :description,
      :leadingIcon,
      :trailing,
      :tag,
      :onTap,
      :enabled,
      :semanticsLabel,
      :semanticsHint,
      :info,
    ) = widget;
    final colors = context.budgetColors;

    // The row reads the texts out through its own node.
    Widget text({required bool tagBelow}) => LabelDescription(
      label: label,
      description: description,
      enabled: enabled,
      info: info,
      below: tagBelow && tag != null ? BudgetTag(tag) : null,
      announce: false,
    );

    final row = LayoutBuilder(
      builder: (context, constraints) {
        // The text column if the tag stays beside it, with the tag
        // measured at the current text size (review N2).
        final leadingWidth = leadingIcon == null
            ? 0.0
            : BudgetListRow._leadingSize + BudgetSpacing.space4;
        final tagWidth = tag == null
            ? 0.0
            : BudgetSpacing.space3 +
                  BudgetTag.widthOf(context, tag) +
                  (trailing == null
                      ? 0.0
                      : BudgetSpacing.space3 +
                            BudgetListRow._trailingAllowance);
        final textWidth =
            constraints.maxWidth -
            2 * BudgetSpacing.space5 -
            leadingWidth -
            tagWidth;
        final tagBelow = tag != null && textWidth < BudgetListRow._minTextWidth;
        // The (i)'s 48 dp target adds space around the text; take it off
        // the row's own padding so the row keeps its height.
        final vertical = info == null
            ? BudgetSpacing.space3
            : math.max<double>(
                0,
                BudgetSpacing.space3 -
                    LabelDescription.infoInset(
                      MediaQuery.textScalerOf(context),
                    ),
              );

        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: description == null
                ? BudgetListRow._minHeight
                : BudgetListRow._minHeightWithDescription,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: BudgetSpacing.space5,
              vertical: vertical,
            ),
            child: Row(
              children: [
                if (leadingIcon case final icon?) ...[
                  ExcludeSemantics(
                    child: Container(
                      width: BudgetListRow._leadingSize,
                      height: BudgetListRow._leadingSize,
                      decoration: BoxDecoration(
                        color: colors.neutralSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 24, color: colors.neutral),
                    ),
                  ),
                  const SizedBox(width: BudgetSpacing.space4),
                ],
                // The visible texts are read once, through the row's label.
                Expanded(child: text(tagBelow: tagBelow)),
                if (tag != null && !tagBelow) ...[
                  const SizedBox(width: BudgetSpacing.space3),
                  ExcludeSemantics(child: BudgetTag(tag)),
                ],
                if (trailing case final trailing?) ...[
                  const SizedBox(width: BudgetSpacing.space3),
                  if (info == null)
                    trailing
                  else
                    ExcludeSemantics(child: trailing),
                ],
              ],
            ),
          ),
        );
      },
    );

    final semanticsText =
        semanticsLabel ?? [label, ?tag, ?description].join('. ');
    final tappable = Material(
      type: MaterialType.transparency,
      child: FocusRing(
        focusNode: _focusNode,
        inside: true,
        child: InkWell(
          focusNode: _focusNode,
          onTap: enabled ? onTap : null,
          overlayColor: WidgetStateProperty.fromMap({
            WidgetState.pressed: colors.sunken,
            WidgetState.any: Colors.transparent,
          }),
          splashFactory: NoSplash.splashFactory,
          child: row,
        ),
      ),
    );
    if (info != null) {
      // The row's own node; the (i) inside is a container node of its own,
      // so it becomes a child item instead of being merged in (review C2).
      return Semantics(
        container: true,
        button: onTap != null,
        enabled: enabled,
        label: semanticsText,
        hint: semanticsHint,
        child: tappable,
      );
    }
    // One node for the whole row, so a trailing switch is part of the
    // labelled row target instead of an unlabelled target of its own.
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        enabled: enabled,
        label: semanticsText,
        hint: semanticsHint,
        child: tappable,
      ),
    );
  }
}

/// The trailing chevron of a row that opens something: 20 dp, `textSecondary`.
class BudgetRowChevron extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Icon(
        Icons.chevron_right,
        size: 20,
        color: context.budgetColors.textSecondary,
      ),
    );
  }
}

/// A small pill such as "Coming soon": `neutralSoft` fill, `caption` 500 in
/// `textSecondary`, `radiusFull`, padding 8 × 4 dp (settings.md §2.3).
class BudgetTag extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: BudgetSpacing.space2,
    vertical: BudgetSpacing.space1,
  );

  static TextStyle _style(BudgetColors colors) => BudgetTypeScale.caption
      .copyWith(fontWeight: FontWeight.w500, color: colors.textSecondary);

  /// The width a tag showing [text] takes here, at the current text size
  /// and bold-text setting: the same style, scaler and padding as [build].
  static double widthOf(BuildContext context, String text) {
    var style = DefaultTextStyle.of(context).style
        .merge(_style(context.budgetColors));
    if (MediaQuery.boldTextOf(context)) {
      style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      textHeightBehavior: DefaultTextHeightBehavior.maybeOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width.ceilToDouble() + _padding.horizontal;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.neutralSoft,
        borderRadius: const BorderRadius.all(Radius.circular(BudgetRadii.full)),
      ),
      child: Padding(
        padding: _padding,
        child: Text(text, style: _style(colors)),
      ),
    );
  }
}
