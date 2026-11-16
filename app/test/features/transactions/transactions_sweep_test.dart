import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/accessibility.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/theme_cases.dart';
import '../../helpers/transactions_harness.dart';

const _sweepTimeout = Timeout(Duration(minutes: 10));

/// A state of the Transactions tab or its editor and sheets (F-009 test
/// cases §0 "P2 transaction states"), opened on [theme] at [scale] on [size].
typedef _Open = Future<void> Function(
  WidgetTester tester,
  ThemeCase theme,
  double scale,
  Size size,
);

Future<void> _pump(
  WidgetTester tester,
  FakeMoneyStore store,
  ThemeCase theme,
  double scale,
  Size size, {
  TestClock? clock,
  bool hintsSeen = true,
}) => pumpTransactions(
  tester,
  money: store,
  theme: theme,
  textScale: scale,
  size: size,
  clock: clock,
  hintsSeen: hintsSeen,
);

FakeMoneyStore _six() {
  final store = e2Store();
  addSpendTo(store, d(2026, 11, 7), 78000, note: 'Dinner with Riya');
  addSpendTo(store, d(2026, 11, 7), 4000);
  addSpendTo(store, d(2026, 11, 8), 31000, note: 'Petrol');
  addSpendTo(store, d(2026, 11, 9), 40000, note: 'Groceries');
  addSpendTo(store, d(2026, 11, 9), 25000, note: 'Lunch');
  addSpendTo(store, d(2026, 11, 9), 5050);
  return store;
}

Future<void> _openRow(WidgetTester tester, String text) async {
  // Rows are built as they scroll in (large text pushes them below).
  await tester.scrollUntilVisible(
    find.text(text),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> _openAddScreen(WidgetTester tester) async {
  await tester.tap(addSpendButton);
  await tester.pumpAndSettle();
}

final Map<String, _Open> _states = {
  'no month': (t, th, s, z) => _pump(t, FakeMoneyStore(), th, s, z),
  'no month with hint': (t, th, s, z) =>
      _pump(t, FakeMoneyStore(), th, s, z, hintsSeen: false),
  'no spends': (t, th, s, z) => _pump(t, e2Store(), th, s, z),
  'six spends': (t, th, s, z) => _pump(t, _six(), th, s, z),
  'fifty spends on one day': (t, th, s, z) {
    final store = e2Store();
    for (var i = 0; i < 50; i++) {
      addSpendTo(store, d(2026, 11, 9), 100, note: 'Item $i');
    }
    return _pump(t, store, th, s, z);
  },
  'overspent': (t, th, s, z) {
    final store = e2Store();
    addSpendTo(store, d(2026, 11, 9), 10000000000, note: 'Car');
    return _pump(t, store, th, s, z);
  },
  'shortfall month': (t, th, s, z) {
    final store = e2Store(
      periods: [period(d(2026, 11, 5), s1Values(), continued: true)],
    );
    addSpendTo(store, d(2026, 11, 6), 20000, note: 'Tea');
    return _pump(
      t,
      store,
      th,
      s,
      z,
      clock: TestClock(DateTime(2026, 11, 6, 10)),
    );
  },
  'new month not set up': (t, th, s, z) {
    final store = e2Store();
    addSpendTo(store, d(2026, 11, 20), 52000, note: 'Groceries');
    return _pump(
      t,
      store,
      th,
      s,
      z,
      clock: TestClock(DateTime(2026, 12, 5, 10)),
    );
  },
  'new month sheet': (t, th, s, z) async {
    await _pump(
      t,
      e2Store(),
      th,
      s,
      z,
      clock: TestClock(DateTime(2026, 12, 5, 10)),
    );
    await _openAddScreen(t);
  },
  'load error': (t, th, s, z) =>
      _pump(t, e2Store()..readFails = true, th, s, z),
  'add spend empty': (t, th, s, z) async {
    await _pump(t, e2Store(), th, s, z);
    await _openAddScreen(t);
  },
  'add spend with errors and counter': (t, th, s, z) async {
    await _pump(t, e2Store(), th, s, z);
    await _openAddScreen(t);
    await t.enterText(amountInput, '12.345');
    await t.enterText(noteInput, 'a' * 95);
    await t.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
    final save = find.text('Save');
    await t.ensureVisible(save);
    await t.pumpAndSettle();
    await t.tap(save);
    await t.pumpAndSettle();
  },
  'edit spend': (t, th, s, z) async {
    await _pump(t, _six(), th, s, z);
    await _openRow(t, 'Lunch');
  },
  'delete sheet': (t, th, s, z) async {
    await _pump(t, _six(), th, s, z);
    await _openRow(t, 'Lunch');
    await t.ensureVisible(find.text('Delete'));
    await t.pumpAndSettle();
    await t.tap(find.text('Delete'));
    await t.pumpAndSettle();
  },
  'discard sheet (add)': (t, th, s, z) async {
    await _pump(t, e2Store(), th, s, z);
    await _openAddScreen(t);
    await t.enterText(amountInput, '250');
    await t.pump();
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
  },
  'cover taken back sheet': (t, th, s, z) async {
    final store = e2Store();
    addSpendTo(store, d(2026, 11, 5), 50000, note: 'Quiet day');
    addSpendTo(store, d(2026, 11, 6), 100000);
    addSpendTo(store, d(2026, 11, 7), 83000);
    addCoverTo(store, d(2026, 11, 6), 17000);
    await _pump(
      t,
      store,
      th,
      s,
      z,
      clock: TestClock(DateTime(2026, 11, 8, 10)),
    );
    await _openRow(t, 'Quiet day');
    await t.enterText(amountInput, '830');
    await t.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
    final save = find.text('Save changes');
    await t.ensureVisible(save);
    await t.pumpAndSettle();
    await t.tap(save);
    await t.pumpAndSettle();
  },
};

void main() {
  testWidgets(
    'TC-009-20 transaction states pass the theme and text scale sweep',
    (tester) async {
      for (final MapEntry(key: name, value: open) in _states.entries) {
        for (final theme in ThemeCase.values) {
          for (final scale in [1.0, 2.0]) {
            final where = '$name, ${theme.name}, x$scale';
            await open(tester, theme, scale, kSmallPhone);
            await expectAccessible(tester, reason: where);
            await tester.pumpWidget(const SizedBox());
          }
        }
      }
    },
    timeout: _sweepTimeout,
  );

  testWidgets('TC-009-20 transaction states survive landscape', (tester) async {
    for (final MapEntry(key: name, value: open) in _states.entries) {
      for (final theme in [ThemeCase.light, ThemeCase.dim]) {
        for (final scale in [1.0, 2.0]) {
          final where = '$name, ${theme.name}, x$scale, landscape';
          await open(tester, theme, scale, kSmallLandscape);
          expectNoOverflow(tester, reason: where);
          await tester.pumpWidget(const SizedBox());
        }
      }
    }
  }, timeout: _sweepTimeout);

  testWidgets('TC-009-46 the last row is clear of the add button', (
    tester,
  ) async {
    for (final scale in [1.0, 2.0]) {
      await _pump(tester, _six(), ThemeCase.light, scale, kSmallPhone);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
      await tester.pumpAndSettle();
      final lastRow = tester.getRect(find.text('Dinner with Riya'));
      final button = tester.getRect(addSpendButton);
      expect(
        lastRow.bottom <= button.top || lastRow.right <= button.left,
        isTrue,
        reason: 'scale $scale: $lastRow vs $button',
      );
      await tester.pumpWidget(const SizedBox());
    }
  });
}
