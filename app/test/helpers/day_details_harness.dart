import 'dart:async';

import 'package:daily_budget/core/widgets/ledger_row.dart';
import 'package:daily_budget/data/repositories/savings_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/day_details/day_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'fake_money_store.dart';
import 'phase3_data.dart';
import 'phase3_fixtures.dart';
import 'setup_harness.dart';
import 'theme_cases.dart';

/// What [openDay] leaves the test holding.
typedef OpenedDay = ({FakeMoneyStore store, MovableClock clock, int monthId});

/// Pumps the real app on [fixture] and pushes day details for [date], the way
/// a calendar tap does (F-012 test cases §0). [monthIndex] picks the stored
/// month (0 is the oldest, as in OCT-NOV); the default is the latest.
Future<OpenedDay> openDay(
  WidgetTester tester,
  Phase3Fixture fixture,
  CalendarDate date, {
  FakeMoneyStore? store,
  MovableClock? clock,
  int? monthIndex,
  ThemeCase theme = ThemeCase.light,
  Size? size = const Size(360, 640),
  double textScale = 1,
  List<Override> overrides = const [],
  SavingsRepository? savings,
}) async {
  final money = store ?? storeFor(fixture);
  final deviceClock = clock ?? clockFor(fixture);
  await pumpHome(
    tester,
    money: money,
    clock: deviceClock,
    theme: theme,
    size: size,
    textScale: textScale,
    overrides: overrides,
    savings: savings,
  );
  final monthId = money.months[monthIndex ?? money.months.length - 1].id;
  unawaited(
    DayDetailsScreen.open(
      tester.element(find.byType(Scaffold).first),
      monthId: monthId,
      date: date,
    ),
  );
  await tester.pumpAndSettle();
  return (store: money, clock: deviceClock, monthId: monthId);
}

/// The amount text of the ledger row [label] (`Budget`, `Spent`, ...), or
/// null when the day has no such row.
String? figure(WidgetTester tester, String label) {
  final rows = find.byWidgetPredicate(
    (w) => w is LedgerRow && w.label == label,
  );
  return rows.evaluate().isEmpty
      ? null
      : tester.widget<LedgerRow>(rows).amount.replaceAll('⁠', '');
}

CalendarDate nov(int day) => CalendarDate(2026, 11, day);
