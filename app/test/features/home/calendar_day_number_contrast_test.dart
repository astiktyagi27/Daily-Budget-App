// F-011 TC-011-34 (T-475 item 3): the calendar day number is left out of the
// semantics tree, so the sweeps' `textContrastGuideline` cannot see its
// colour. This test reads the colour of the number and the fill of the cell
// from the widget and holds them to 4.5 to 1 in every cell kind and theme,
// and to the colour the design system names (textPrimary on a filled cell,
// accent today, textSecondary on upcoming and not budgeted days).

import 'package:daily_budget/core/theme/budget_colors.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/home/calendar/day_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/bundled_fonts.dart';
import '../../helpers/contrast.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/theme_cases.dart';

/// The cell kinds that draw their own day number (not `outside`).
List<(String, CalendarCell)> _cells() {
  CalendarCell cell(
    CellKind kind, {
    DayResultKind? resultKind,
    TodayFill? todayFill,
    int day = 12,
  }) => CalendarCell(
    kind: kind,
    date: d(2026, 11, day),
    netSpent: const Paise(50000),
    result: const Paise(33000),
    resultKind: resultKind,
    todayFill: todayFill,
  );
  return [
    ('saved', cell(CellKind.saved, resultKind: DayResultKind.saved)),
    ('on budget', cell(CellKind.onBudget, resultKind: DayResultKind.onBudget)),
    (
      'overspent',
      cell(CellKind.overspent, resultKind: DayResultKind.overspent),
    ),
    for (final fill in TodayFill.values)
      (
        'today ${fill.name}',
        cell(CellKind.today, resultKind: DayResultKind.saved, todayFill: fill),
      ),
    ('upcoming', cell(CellKind.upcoming)),
    ('not budgeted', cell(CellKind.notBudgeted)),
  ];
}

/// The colour of the day number by kind (design system section 6, F-011
/// section 2.2).
Color _expectedNumber(BudgetColors colors, CellKind kind) => switch (kind) {
  CellKind.today => colors.accent,
  CellKind.upcoming || CellKind.notBudgeted => colors.textSecondary,
  _ => colors.textPrimary,
};

/// The fill of the cell box (the decorated box with the cell's corner).
Color _fillOf(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(DayCell),
          matching: find.byWidgetPredicate(
            (w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).borderRadius ==
                    const BorderRadius.all(Radius.circular(BudgetRadii.xs)),
          ),
        )
        .first,
  );
  return (box.decoration as BoxDecoration).color!;
}

void main() {
  setUpAll(loadBundledFonts);

  testWidgets('TC-011-34 calendar day numbers keep 4.5 to 1 on their cell', (
    tester,
  ) async {
    for (final theme in ThemeCase.values) {
      for (final (name, cell) in _cells()) {
        await pumpBudgetWidget(
          tester,
          Center(
            child: DayCell(cell: cell, width: 48, onTap: () {}),
          ),
          theme: theme,
        );
        final reason = '$name in ${theme.name}';
        final number = tester.widget<Text>(find.text('12').first);
        final color = number.style!.color!;
        expect(color.a, 1, reason: '$reason: opaque number');
        expect(
          color,
          _expectedNumber(theme.colors, cell.kind),
          reason: '$reason: design colour',
        );
        final fill = _fillOf(tester);
        // A cell with no fill (upcoming, not budgeted) sits on the card or
        // the page: hold the number to both.
        final backgrounds = fill.a == 0
            ? [theme.colors.surface, theme.colors.bg]
            : [fill];
        for (final background in backgrounds) {
          expect(
            contrastRatio(color, background),
            greaterThanOrEqualTo(4.5),
            reason: reason,
          );
        }
      }
    }
  });
}
