import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/theme_cases.dart';
import '../../helpers/transactions_harness.dart';

const _sweepTimeout = Timeout(Duration(minutes: 15));

/// A state of the Money back editor or its sheets (F-016 test cases §0
/// "Editor states"), opened on [theme] at [scale] on [size].
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
}) => pumpTransactions(
  tester,
  money: store,
  theme: theme,
  textScale: scale,
  size: size,
  clock: clock,
);

Future<void> _openAdd(WidgetTester tester) async {
  await tester.tap(addSpendButton);
  await tester.pumpAndSettle();
}

Future<void> _toggle(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Money back / refund'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Money back / refund'));
  await tester.pumpAndSettle();
}

Future<void> _openRow(WidgetTester tester, String text) async {
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

Future<void> _tap(WidgetTester tester, String label) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final finder = find.text(label);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first, warnIfMissed: false);
  await tester.pumpAndSettle();
}

FakeMoneyStore _ar() => storeFor(fixtureAPlusRefund);

final Map<String, _Open> _states = {
  'add spend (switch off)': (t, th, s, z) async {
    await _pump(t, _ar(), th, s, z);
    await _openAdd(t);
  },
  'add money back (switch on)': (t, th, s, z) async {
    await _pump(t, _ar(), th, s, z);
    await _openAdd(t);
    await _toggle(t);
  },
  'add money back with an error': (t, th, s, z) async {
    await _pump(t, _ar(), th, s, z);
    await _openAdd(t);
    await _toggle(t);
    await t.enterText(amountInput, '12.345');
    await t.pump();
    await _tap(t, 'Save');
  },
  'add money back note 95 of 100': (t, th, s, z) async {
    await _pump(t, _ar(), th, s, z);
    await _openAdd(t);
    await _toggle(t);
    await t.enterText(amountInput, '500');
    await t.enterText(noteInput, 'a' * 95);
    await t.pump();
  },
  'edit money back': (t, th, s, z) async {
    await _pump(t, _ar(), th, s, z);
    await _openRow(t, 'Amazon return');
  },
  'edit money back, switch turned off': (t, th, s, z) async {
    await _pump(t, _ar(), th, s, z);
    await _openRow(t, 'Amazon return');
    await _toggle(t);
  },
  'delete money back sheet': (t, th, s, z) async {
    await _pump(t, _ar(), th, s, z);
    await _openRow(t, 'Amazon return');
    await _tap(t, 'Delete');
  },
  'discard this money back sheet': (t, th, s, z) async {
    await _pump(t, _ar(), th, s, z);
    await _openAdd(t);
    await _toggle(t);
    await t.enterText(amountInput, '500');
    await t.pump();
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
  },
  'discard changes sheet': (t, th, s, z) async {
    await _pump(t, _ar(), th, s, z);
    await _openRow(t, 'Amazon return');
    await _toggle(t);
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
  },
  'save failure snackbar': (t, th, s, z) async {
    final store = _ar();
    await _pump(t, store, th, s, z);
    await _openAdd(t);
    await _toggle(t);
    await t.enterText(amountInput, '500');
    await t.pump();
    store.failNextWrite = true;
    await _tap(t, 'Save');
    await t.drag(find.byType(SingleChildScrollView).last, const Offset(0, 600));
    await t.pumpAndSettle();
  },
  'savings pot updated sheet': (t, th, s, z) async {
    await _pump(t, storeFor(p1), th, s, z);
    await _openRow(t, 'Refund');
    await _tap(t, 'Delete');
    await t.tap(find.text('Delete').last);
    await t.pumpAndSettle();
  },
  'new month not set up': (t, th, s, z) async {
    await _pump(
      t,
      _ar(),
      th,
      s,
      z,
      clock: TestClock(DateTime(2026, 12, 5, 10)),
    );
    await _openAdd(t);
  },
};

void main() {
  testWidgets(
    'TC-016-33 money back states pass the theme and text scale sweep',
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

  testWidgets('TC-016-35 money back states survive landscape and the switch '
      'row stacks at large text', (tester) async {
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

    // At 2.0x the switch sits under its texts, right aligned.
    await _states['add money back (switch on)']!(
      tester,
      ThemeCase.light,
      2,
      kSmallPhone,
    );
    final description2 = tester.getRect(
      find.textContaining('Turn on for money paid back'),
    );
    final toggle = tester.getRect(find.byType(Switch));
    final screen = tester.getSize(find.byType(Scaffold).last);
    expect(
      toggle.top,
      greaterThanOrEqualTo(description2.bottom - 1),
      reason: 'stacked under the description',
    );
    expect(toggle.right, greaterThan(screen.width / 2));
    // At 1.0x it is on the same line.
    await tester.pumpWidget(const SizedBox());
    // `setUpScreen` never undoes a text scale.
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await _states['add money back (switch on)']!(
      tester,
      ThemeCase.light,
      1,
      kSmallPhone,
    );
    final label1 = tester.getRect(find.text('Money back / refund'));
    final toggle1 = tester.getRect(find.byType(Switch));
    final description = tester.getRect(
      find.textContaining('Turn on for money paid back'),
    );
    expect(toggle1.center.dy, greaterThan(label1.top), reason: 'same row');
    expect(toggle1.center.dy, lessThan(description.bottom), reason: 'row');
    expect(toggle1.left, greaterThan(description.right - 1));
  }, timeout: _sweepTimeout);
}
