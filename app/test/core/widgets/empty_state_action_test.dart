import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/theme_cases.dart';

// The Primary button of an empty state (design system §7.10 Phase 2
// allowance): Home and Transactions `Set up your month`, `Try again`.

const _title = 'Your daily budget lives here';
const _description =
    "Tell us your salary and fixed costs, and we'll work out what you can "
    'spend each day.';

Widget _state({required Widget? action}) => EmptyState(
  icon: Icons.today_outlined,
  title: _title,
  description: _description,
  action: action,
);

Widget _setUp({VoidCallback? onPressed}) => BudgetButton.primary(
  label: 'Set up your month',
  semanticsHint: 'Open month setup',
  onPressed: onPressed ?? () {},
);

Finder get _button => find.widgetWithText(FilledButton, 'Set up your month');

void main() {
  testWidgets('TC-008-01 an empty state can offer a Primary button', (
    tester,
  ) async {
    var taps = 0;
    await pumpBudgetWidget(
      tester,
      _state(action: _setUp(onPressed: () => taps++)),
    );

    expect(_button, findsOneWidget);
    await tester.tap(find.text('Set up your month'));
    expect(taps, 1);
  });

  testWidgets('TC-008-01 the button is as wide as the text, at most 320 dp', (
    tester,
  ) async {
    await pumpBudgetWidget(
      tester,
      size: const Size(600, 800),
      _state(action: _setUp()),
    );
    expect(tester.getSize(_button).width, 320);

    await tester.pumpWidget(const SizedBox());
    // 360 less the 20 dp gutter on each side.
    await pumpBudgetWidget(
      tester,
      size: const Size(360, 640),
      _state(action: _setUp()),
    );
    expect(tester.getSize(_button).width, 320);
  });

  testWidgets('TC-008-01 text is read as one item and the button on its own', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpBudgetWidget(tester, _state(action: _setUp()));

    expect(find.bySemanticsLabel('$_title. $_description'), findsOneWidget);
    expect(tester.getSemantics(_button).hint, 'Open month setup');
    semantics.dispose();
  });

  testWidgets('TC-008-24 the empty state with a button passes the sweep', (
    tester,
  ) async {
    for (final theme in ThemeCase.values) {
      for (final scale in [1.0, 2.0]) {
        await tester.pumpWidget(const SizedBox());
        await pumpBudgetWidget(
          tester,
          theme: theme,
          size: const Size(360, 640),
          textScale: scale,
          SingleChildScrollView(child: _state(action: _setUp())),
        );
        await expectAccessible(tester, reason: '${theme.name} x$scale');
      }
    }
  });

  testWidgets('TC-003-04 an empty state without a button is unchanged', (
    tester,
  ) async {
    await pumpBudgetWidget(tester, _state(action: null));
    expect(find.byType(BudgetButton), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });
}
