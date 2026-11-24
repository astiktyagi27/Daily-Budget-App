import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// One ledger mark per ended day in date order (F-013 design B-4): ● saved,
/// ○ on budget, ◆ overspent, 10 dp, wrapping. Decorative: the counts above it
/// say the same in words, so it is left out of the semantics tree.
class DayStrip extends StatelessWidget {
  const new({required this.statuses, super.key});

  final List<DayStatus> statuses;

  /// Tests read the marks from this key.
  static const stripKey = Key('dayStrip');

  static const _gap = ' ';

  static String markOf(DayStatus status) => switch (status) {
    DayStatus.saved => '●',
    DayStatus.overspent => '◆',
    DayStatus.onBudget ||
    DayStatus.notBudgeted ||
    DayStatus.upcoming ||
    DayStatus.live => '○',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return ExcludeSemantics(
      child: Text.rich(
        key: stripKey,
        TextSpan(
          style: const TextStyle(fontSize: 10, height: 1.6),
          children: [
            for (final (index, status) in statuses.indexed)
              TextSpan(
                text: index == 0 ? markOf(status) : '$_gap${markOf(status)}',
                style: TextStyle(
                  color: switch (status) {
                    DayStatus.saved => colors.saved,
                    DayStatus.overspent => colors.overspent,
                    _ => colors.neutral,
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
