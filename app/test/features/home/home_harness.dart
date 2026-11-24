// Shared helpers of the Home tests (F-010, F-017): open a Phase 3 fixture on
// Home, change the store the way the F-009 / F-012 flows do, and read what
// is on screen.

import 'package:daily_budget/core/theme/budget_colors.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/setup_harness.dart';
import '../../helpers/theme_cases.dart';
import '../../support/find_copy.dart';

/// Pumps Home on [fixture] (its own device date) and returns the store.
Future<FakeMoneyStore> openFixture(
  WidgetTester tester,
  Phase3Fixture fixture, {
  ThemeCase theme = ThemeCase.light,
  Size? size = kSmallPhone,
  double textScale = 1,
  bool hintsSeen = true,
  List<Override> overrides = const [],
  MovableClock? clock,
}) async {
  final store = storeFor(fixture);
  await pumpHome(
    tester,
    money: store,
    clock: clock ?? clockFor(fixture),
    theme: theme,
    size: size,
    textScale: textScale,
    hintsSeen: hintsSeen,
    overrides: overrides,
  );
  return store;
}

/// Changes [store] through [mutate] and lets Home pick it up.
Future<void> change(
  WidgetTester tester,
  FakeMoneyStore store,
  void Function() mutate,
) async {
  mutate();
  store.notify();
  await tester.pumpAndSettle();
}

/// A stored month with one period of [values] from [first] (the month start
/// by default).
Phase3Fixture customFixture({
  required String name,
  required CalendarDate today,
  required PeriodValues values,
  BudgetMonth? month,
  CalendarDate? first,
  bool continued = false,
  List<BudgetPeriod>? periods,
  List<FixtureEntry> entries = const [],
}) {
  final budgetMonth = month ?? nov2026;
  final start = first ?? budgetMonth.start;
  return Phase3Fixture(
    name: name,
    today: today,
    months: [
      FixtureMonth(
        month: budgetMonth,
        firstBudgetedDay: start,
        periods:
            periods ??
            [
              period(
                start,
                values,
                changedAt: at(start.addDays(-1), 0),
                continued: continued,
              ),
            ],
        entries: entries,
      ),
    ],
  );
}

/// The ledger row `label, amount` as one semantics node.
Finder ledgerRow(String label, String amount) =>
    find.bySemanticsLabel('$label, $amount');

/// The colour of the first `Text` found by [finder].
Color? colorOf(WidgetTester tester, Finder finder) {
  final text = tester.widget<Text>(finder.first);
  return text.style?.color ??
      (text.textSpan is TextSpan
          ? (text.textSpan! as TextSpan).style?.color
          : null);
}

/// The top edge of the first widget found by [finder].
double topOf(WidgetTester tester, Finder finder) =>
    tester.getTopLeft(finder.first).dy;

/// The token set of [ThemeCase.light].
const BudgetColors lightColors = BudgetColors.light;

/// The text of Home's Today line: its parts joined by a space, marks left
/// out: `budget ₹830 · spent ₹420 · ₹410 left today`.
String todayCardText() {
  final texts = find.descendant(
    of: find.byKey(const ValueKey('today-line')),
    matching: find.byType(Text),
  );
  return [
    for (final element in texts.evaluate())
      if ((element.widget as Text).key != const ValueKey('today-mark'))
        plainCopy(
          (element.widget as Text).data ??
              (element.widget as Text).textSpan!.toPlainText(),
        ),
  ].join(' ');
}

/// Whether the `Save changes` button of the setup screen is enabled.
bool saveEnabled(WidgetTester tester) => tester
    .widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Save changes'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    )
    .enabled;
