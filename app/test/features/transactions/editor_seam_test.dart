import 'dart:async';

import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/transactions/spend_editor_flow.dart';
import 'package:daily_budget/features/transactions/transactions_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/transactions_harness.dart';

// The F-012 seam of the F-009 editor (T-342): the cases TC-012-18 and
// TC-012-22 are closed by the day-details tests; these prove the seam alone.

/// Calls `openSpendEditor` the way day details will: from a widget's own
/// context and ref (a `ConsumerWidget` element is its own `WidgetRef`).
Future<void> _open(
  WidgetTester tester, {
  StoredSpend? edit,
  CalendarDate? date,
  CalendarDate? fromDay,
}) async {
  final element = tester.element(find.byType(TransactionsTab));
  unawaited(
    openSpendEditor(
      element,
      element as WidgetRef,
      edit: edit,
      date: date,
      fromDay: fromDay,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pickDay(WidgetTester tester, String day) async {
  await tester.ensureVisible(find.byIcon(Icons.calendar_today_outlined));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.calendar_today_outlined));
  await tester.pumpAndSettle();
  await tester.tap(find.text(day));
  await tester.pump();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TC-012-18 the editor opens on the day it is given', (
    tester,
  ) async {
    final store = e2Store();
    await pumpTransactions(tester, money: store);
    await _open(tester, date: d(2026, 11, 8), fromDay: d(2026, 11, 8));
    expect(find.text('Add spend'), findsOneWidget);
    expect(find.text('Yesterday · Sun, 8 Nov'), findsOneWidget);

    await typeInto(tester, amountInput, '100');
    await tapLabel(tester, 'Save');
    expect(storedSpends(store).single.spend.date, d(2026, 11, 8));
    expect(find.text('Spend added'), findsOneWidget);
  });

  testWidgets('TC-012-22 an edit saved on another day says where it moved', (
    tester,
  ) async {
    final store = e2Store();
    addSpendTo(store, d(2026, 11, 9), 47000, note: 'Dinner');
    await pumpTransactions(tester, money: store);
    await _open(
      tester,
      edit: storedSpends(store).single,
      fromDay: d(2026, 11, 9),
    );
    await _pickDay(tester, '8');
    await tapLabel(tester, 'Save changes');
    expect(find.text('Spend moved to Sun, 8 Nov'), findsOneWidget);
    expect(find.text('Spend updated'), findsNothing);
    expect(storedSpends(store).single.spend.date, d(2026, 11, 8));
  });

  testWidgets('TC-012-22 an edit saved on the same day says Spend updated', (
    tester,
  ) async {
    final store = e2Store();
    addSpendTo(store, d(2026, 11, 9), 47000, note: 'Dinner');
    await pumpTransactions(tester, money: store);
    await _open(
      tester,
      edit: storedSpends(store).single,
      fromDay: d(2026, 11, 9),
    );
    await typeInto(tester, amountInput, '480');
    await tapLabel(tester, 'Save changes');
    expect(find.text('Spend updated'), findsOneWidget);
    expect(find.textContaining('moved'), findsNothing);
  });

  testWidgets('TC-012-22 without a day the moved line is never used', (
    tester,
  ) async {
    final store = e2Store();
    addSpendTo(store, d(2026, 11, 9), 47000, note: 'Dinner');
    await pumpTransactions(tester, money: store);
    await _open(tester, edit: storedSpends(store).single);
    await _pickDay(tester, '8');
    await tapLabel(tester, 'Save changes');
    expect(find.text('Spend updated'), findsOneWidget);
  });
}
