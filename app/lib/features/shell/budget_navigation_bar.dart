import 'package:daily_budget/core/help/nav_tooltip.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/features/shell/app_tab.dart';
import 'package:flutter/material.dart';

/// The custom bottom bar (design system §7.7, app-shell §3): four labelled
/// slots, the selected one marked by the ink tick, a filled icon and a
/// heavier label, so it never relies on colour alone (F-003 AC-2).
///
/// Material's `NavigationBar` is not used: its pill indicator is what the
/// design replaces (plan F-003 §1.3).
class BudgetNavigationBar extends StatelessWidget {
  const new({required this.selected, required this.onSelect, super.key});

  final AppTab selected;
  final ValueChanged<AppTab> onSelect;

  /// Nav labels follow the system text scale up to this factor only
  /// (app-shell §3.2); the icon never scales.
  static const double maxLabelScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final motion = BudgetMotion.of(context);
    // The fill runs under the system navigation area (edge-to-edge); the
    // items sit above it.
    return Material(
      color: colors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom,
          ),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final tab in AppTab.values)
                    Expanded(
                      child: _NavSlot(
                        tab: tab,
                        selected: tab == selected,
                        onTap: () => onSelect(tab),
                      ),
                    ),
                ],
              ),
              // One tick that slides to the selected slot.
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedAlign(
                    duration: motion.base,
                    curve: BudgetMotion.standard,
                    alignment: Alignment(
                      -1 + 2 * selected.index / (AppTab.values.length - 1),
                      -1,
                    ),
                    child: const FractionallySizedBox(
                      widthFactor: 1 / 4,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: BudgetNavTick(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The 4 × 16 dp `accent` ink tick above the selected tab's icon.
class BudgetNavTick extends StatelessWidget {
  const new({super.key});

  static const double width = 16;
  static const double height = 4;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: BudgetSpacing.space1),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.budgetColors.accent,
          borderRadius: const BorderRadius.all(
            Radius.circular(BudgetRadii.full),
          ),
        ),
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const new({required this.tab, required this.selected, required this.onTap});

  final AppTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final color = selected ? colors.accent : colors.neutral;
    final labelScaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: BudgetNavigationBar.maxLabelScale);
    return NavTooltip(
      message: tab.hint,
      child: Semantics(
        button: true,
        selected: selected,
        label: tab.semanticsLabel,
        child: InkWell(
          onTap: onTap,
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                BudgetSpacing.space1,
                // Room for the tick (4 dp from the top, 4 dp tall) + 8 dp.
                BudgetSpacing.space1 +
                    BudgetNavTick.height +
                    BudgetSpacing.space2,
                BudgetSpacing.space1,
                BudgetSpacing.space1,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? tab.selectedIcon : tab.icon,
                    size: 24,
                    color: color,
                  ),
                  const SizedBox(height: BudgetSpacing.space1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tab.label,
                      maxLines: 1,
                      softWrap: false,
                      textScaler: labelScaler,
                      style: BudgetTypeScale.label.copyWith(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
