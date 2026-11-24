import 'package:daily_budget/core/widgets/action_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/setup_harness.dart';

// Month setup with the keyboard open (`month-setup.md` §6 and §13, T-248,
// built in T-250): the dock line follows the keyboard, the action key is
// Next (Done on the last field), Back closes the keyboard first, and above
// 1.3x text or in landscape the page has no dock.

/// How the form is opened.
enum _Open { first, newMonth, edit }

Future<void> _open(
  WidgetTester tester,
  _Open how, {
  Size size = kSmallPhone,
  double textScale = 1,
}) async {
  switch (how) {
    case _Open.first:
      await pumpHome(
        tester,
        money: FakeMoneyStore(),
        clock: MovableClock(d(2026, 11, 5)),
        size: size,
        textScale: textScale,
      );
      await tapText(tester, 'Set up your month');
      await pickSalaryDay(tester, 5);
      await enterE2(tester);
    case _Open.newMonth:
      await pumpHome(
        tester,
        money: storeWithMonth(values: e2Values(target: 2000000)),
        clock: MovableClock(d(2026, 12, 5)),
        size: size,
        textScale: textScale,
      );
      await tapText(tester, 'Set up this month');
    case _Open.edit:
      await pumpHome(
        tester,
        money: storeWithMonth(),
        clock: MovableClock(d(2026, 11, 20)),
        size: size,
        textScale: textScale,
      );
      await tapEditThisMonth(tester);
  }
}

/// Opens a keyboard of [dp] on the current screen, as the engine reports it.
Future<void> _openKeyboard(WidgetTester tester, double dp) async {
  tester.view.viewInsets = FakeViewPadding(bottom: dp * 3);
  addTearDown(tester.view.resetViewInsets);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _closeKeyboard(WidgetTester tester) async {
  tester.view.resetViewInsets();
  await tester.pumpAndSettle();
}

Finder _inDock(Finder matching) =>
    find.descendant(of: find.byType(ActionDock), matching: matching);

/// The text field that has focus, or null.
TextField? _focused(WidgetTester tester) {
  for (final element in find.byType(TextField).evaluate()) {
    final field = element.widget as TextField;
    if (field.focusNode?.hasFocus ?? false) return field;
  }
  return null;
}

/// Taps [field] (scrolled into view first), which focuses it.
Future<void> _tapField(WidgetTester tester, Finder field) async {
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
  await tester.pump();
}

Future<void> _next(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.next);
  await tester.pumpAndSettle();
}

void main() {
  const keyboard = 300.0;

  for (final (how, label) in [
    (_Open.first, 'Daily budget'),
    (_Open.newMonth, 'Daily budget'),
    (_Open.edit, 'From today'),
  ]) {
    testWidgets(
      'TC-008-27 with the keyboard open the dock line sits directly above it '
      'and Confirm is hidden (${how.name})',
      (tester) async {
        await _open(tester, how);
        await _tapField(tester, amountInput('Monthly salary'));
        await _openKeyboard(tester, keyboard);

        final line = _inDock(find.text(label));
        expect(line, findsOneWidget);
        expect(line.hitTestable(), findsOneWidget);
        final dock = tester.getRect(find.byType(ActionDock));
        expect(dock.bottom, closeTo(640 - keyboard, 0.5));
        expect(
          find.text(how == _Open.edit ? 'Save changes' : 'Start my month'),
          findsNothing,
        );
      },
    );
  }

  testWidgets('TC-008-27 Next walks every field and Done closes the keyboard '
      'on a first setup', (tester) async {
    await _open(tester, _Open.first);
    final names = itemNameFields;
    final amounts = itemAmountFields;
    final order = [
      amountInput('Monthly salary'),
      for (var i = 0; i < 3; i++) ...[names.at(i), amounts.at(i)],
    ];
    for (final field in order.take(order.length - 1)) {
      expect(
        tester.widget<TextField>(field).textInputAction,
        TextInputAction.next,
      );
    }
    expect(
      tester.widget<TextField>(order.last).textInputAction,
      TextInputAction.done,
    );

    await _tapField(tester, order.first);
    await _openKeyboard(tester, keyboard);
    for (final field in order.skip(1)) {
      await _next(tester);
      expect(_focused(tester), same(tester.widget<TextField>(field)));
    }

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_focused(tester), isNull);
    expect(tester.testTextInput.isVisible, isFalse);

    await _closeKeyboard(tester);
    expect(_inDock(find.text('Start my month')), findsOneWidget);
    expect(_inDock(find.text('Daily budget')), findsOneWidget);
  });

  testWidgets('TC-008-27 Next goes from salary to the target and on to the '
      'first item in a new month', (tester) async {
    await _open(tester, _Open.newMonth);
    await _tapField(tester, amountInput('Monthly salary'));
    await _openKeyboard(tester, keyboard);

    await _next(tester);
    expect(
      _focused(tester),
      same(tester.widget<TextField>(amountInput('Spending target'))),
    );
    await _next(tester);
    expect(
      _focused(tester),
      same(tester.widget<TextField>(itemNameFields.at(0))),
    );
  });

  testWidgets('TC-008-27 Done on the last amount of an edit brings Save '
      'changes back', (tester) async {
    await _open(tester, _Open.edit);
    await tester.enterText(itemAmountFields.last, '120');
    await _openKeyboard(tester, keyboard);
    expect(find.text('Save changes'), findsNothing);
    expect(
      tester.widget<TextField>(itemAmountFields.last).textInputAction,
      TextInputAction.done,
    );

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await _closeKeyboard(tester);

    expect(_inDock(find.text('Save changes')), findsOneWidget);
    expect(_inDock(find.text('From today')), findsOneWidget);
  });

  testWidgets('TC-008-27 Next skips the remove buttons between the rows', (
    tester,
  ) async {
    await _open(tester, _Open.edit);
    await _tapField(tester, itemAmountFields.at(0));
    await _openKeyboard(tester, keyboard);
    await _next(tester);
    expect(
      _focused(tester),
      same(tester.widget<TextField>(itemNameFields.at(1))),
    );
  });

  testWidgets('TC-008-27 Back with the keyboard open only closes it', (
    tester,
  ) async {
    await _open(tester, _Open.first);
    await tester.enterText(amountInput('Monthly salary'), '40001');
    await _openKeyboard(tester, keyboard);

    for (final viaButton in [false, true]) {
      await _tapField(tester, amountInput('Monthly salary'));
      await tester.pump();
      expect(_focused(tester), isNotNull);
      if (viaButton) {
        await tester.ensureVisible(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Back'));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(_focused(tester), isNull);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(find.text('Set up your month'), findsWidgets);
      expect(typed(tester, amountInput('Monthly salary')), '40001');
    }

    // The keyboard is gone now: the next Back leaves (and asks, as before).
    await _closeKeyboard(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
  });

  for (final (name, size, scale, kb) in [
    ('2.0x text', kSmallPhone, 2.0, 300.0),
    ('landscape', kSmallLandscape, 1.0, 180.0),
  ]) {
    testWidgets(
      'TC-008-27 at $name there is no dock and Start my month is reached by '
      'scrolling with the keyboard open',
      (tester) async {
        await _open(tester, _Open.first, size: size, textScale: scale);
        await _tapField(tester, amountInput('Monthly salary'));
        await _openKeyboard(tester, kb);

        expect(find.byType(ActionDock), findsNothing);
        await tester.scrollUntilVisible(
          find.text('Start my month'),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        final start = find.text('Start my month');
        expect(start.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(start).bottom,
          lessThanOrEqualTo(size.height - kb),
        );
      },
    );
  }
}
