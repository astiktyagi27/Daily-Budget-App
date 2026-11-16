import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/accessibility.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/setup_harness.dart';
import '../../helpers/theme_cases.dart';

const _sweepTimeout = Timeout(Duration(minutes: 10));

/// The F-008 screens as test states (test cases F-008 §0 "P2 setup states"),
/// driven through the real app.
enum _State {
  firstEmpty('first setup, empty'),
  firstE2('first setup with the E2 entry'),
  tenCostsWithError('10 fixed costs and a salary error'),
  targetOn('target switch on'),
  shortfallCard('shortfall card'),
  shortfallSheet('shortfall dialog'),
  equalCard('equal-case card'),
  midMonth('mid-month setup'),
  prefilled('pre-filled new month'),
  edit('edit this month'),
  discardSheet('discard dialog'),
  homeNoMonth('Home: no month'),
  homeCard('Home: This month card'),
  homeNewMonth('Home: new month notice'),
  homeShortfall('Home: shortfall line'),
  homeLoadError('Home: load error');

  new(this.description);

  final String description;

  bool get isHome => name.startsWith('home');

  /// The button that ends the screen, reached by scrolling.
  String? get confirm => switch (this) {
    firstEmpty ||
    firstE2 ||
    tenCostsWithError ||
    targetOn ||
    shortfallCard ||
    equalCard ||
    midMonth ||
    prefilled => 'Start my month',
    edit => 'Save changes',
    _ => null,
  };

  Future<void> open(
    WidgetTester tester, {
    required ThemeCase theme,
    required double textScale,
    Size size = kSmallPhone,
  }) async {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.pumpWidget(const SizedBox());
    final clock = MovableClock(switch (this) {
      midMonth => d(2026, 11, 10),
      prefilled || homeNewMonth => d(2026, 12, 5),
      edit => d(2026, 11, 20),
      homeCard || homeShortfall || homeLoadError => d(2026, 11, 9),
      _ => d(2026, 11, 5),
    });
    final money = switch (this) {
      prefilled || edit || homeCard || homeNewMonth => storeWithMonth(),
      homeLoadError => storeWithMonth()..readFails = true,
      homeShortfall => storeWithMonth(
        periods: [
          period(
            d(2026, 11, 5),
            s1Values(),
            changedAt: at(d(2026, 11, 4), 0),
            continued: true,
          ),
        ],
      ),
      _ => FakeMoneyStore(),
    };
    await pumpHome(
      tester,
      money: money,
      clock: clock,
      theme: theme,
      size: size,
      textScale: textScale,
    );
    switch (this) {
      case homeNoMonth || homeCard || homeNewMonth || homeShortfall:
      case homeLoadError:
        return;
      case prefilled:
        await tapText(tester, 'Set up this month');
      case edit:
        await tapText(tester, 'Edit this month');
        await tester.enterText(itemAmountFields.first, '13000');
        await tester.pump();
      case firstEmpty ||
          firstE2 ||
          tenCostsWithError ||
          targetOn ||
          shortfallCard ||
          shortfallSheet ||
          equalCard ||
          midMonth ||
          discardSheet:
        await tapText(tester, 'Set up your month');
    }
    switch (this) {
      case firstEmpty || prefilled || edit:
        break;
      case firstE2:
        await pickSalaryDay(tester, 5);
        await enterE2(tester);
      case tenCostsWithError:
        await pickSalaryDay(tester, 5);
        for (var i = 0; i < 7; i++) {
          await tapText(tester, '+ Add item');
        }
        await tester.enterText(amountInput('Monthly salary'), '0');
        await tapText(tester, 'Start my month');
      case targetOn:
        await pickSalaryDay(tester, 5);
        await typeAmount(tester, 'Monthly salary', '40000');
        await tapVisible(tester, find.byType(Switch));
        await tester.pumpAndSettle();
        await typeAmount(tester, 'Spending target', '20000');
      case shortfallCard || shortfallSheet:
        await pickSalaryDay(tester, 5);
        await typeAmount(tester, 'Monthly salary', '20000');
        await tester.enterText(itemAmountFields.at(0), '15000');
        await tester.enterText(itemAmountFields.at(1), '6000');
        await tester.pump();
        if (this == shortfallSheet) await tapText(tester, 'Start my month');
      case equalCard:
        await pickSalaryDay(tester, 5);
        await typeAmount(tester, 'Monthly salary', '20000');
        await tester.enterText(itemAmountFields.at(0), '15000');
        await tester.enterText(itemAmountFields.at(1), '5000');
        await tester.pump();
      case midMonth:
        await pickSalaryDay(tester, 5);
        await typeAmount(tester, 'Money left now', '24900');
      case discardSheet:
        await pickSalaryDay(tester, 5);
        await tester.binding.handlePopRoute();
      case homeNoMonth ||
          homeCard ||
          homeNewMonth ||
          homeShortfall ||
          homeLoadError:
        break;
    }
    await tester.pumpAndSettle();
  }
}

Future<void> _check(WidgetTester tester, _State state, String where) async {
  await expectAccessible(tester, reason: where);
  final confirm = state.confirm;
  if (confirm != null) {
    // Confirm is on screen or can be scrolled to; the end of the form too.
    final button = find.text(confirm);
    await tester.ensureVisible(button.first);
    await tester.pumpAndSettle();
    expect(button, findsWidgets, reason: where);
    expect(tester.takeException(), isNull, reason: where);
  }
}

void main() {
  testWidgets(
    'TC-008-24 phase 2 setup and home states pass the theme and text scale '
    'sweep',
    (tester) async {
      for (final state in _State.values) {
        for (final theme in ThemeCase.values) {
          for (final scale in [1.0, 2.0]) {
            final where = '${state.description}, ${theme.name}, $scale';
            await state.open(tester, theme: theme, textScale: scale);
            await _check(tester, state, where);
          }
        }
      }
    },
    timeout: _sweepTimeout,
  );

  testWidgets('TC-008-24 setup states survive landscape on a small phone', (
    tester,
  ) async {
    for (final state in _State.values) {
      if (state.isHome) continue;
      for (final theme in [ThemeCase.light, ThemeCase.dim]) {
        for (final scale in [1.0, 2.0]) {
          final where =
              '${state.description}, landscape, ${theme.name}, '
              '$scale';
          await state.open(
            tester,
            theme: theme,
            textScale: scale,
            size: kSmallLandscape,
          );
          await _check(tester, state, where);
        }
      }
    }
  }, timeout: _sweepTimeout);
}
