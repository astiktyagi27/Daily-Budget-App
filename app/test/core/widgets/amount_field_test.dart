import 'package:daily_budget/core/help/help_info.dart';
import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/widgets/amount_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/theme_cases.dart';

// The shared amount input of F-008 (salary, target, fixed costs, money left)
// and F-009 (Add spend); design system §7.3, month-setup §4.2.

const _label = 'Monthly salary';
const _description =
    'What you receive in your bank account each month, after tax.';
const HelpInfo _help = (
  title: 'Monthly salary',
  body: 'Your salary after tax, as it reaches your bank.',
);

Future<TextEditingController> _pump(
  WidgetTester tester, {
  ThemeCase theme = ThemeCase.light,
  bool large = false,
  bool withInfo = true,
  String? errorText,
  double textScale = 1,
  Size? size,
  ValueChanged<String>? onChanged,
  ValueChanged<String>? onSubmitted,
}) async {
  final controller = TextEditingController();
  addTearDown(controller.dispose);
  await pumpBudgetWidget(
    tester,
    theme: theme,
    size: size,
    textScale: textScale,
    ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AmountField(
          label: _label,
          description: _description,
          info: withInfo ? _help : null,
          controller: controller,
          large: large,
          errorText: errorText,
          textInputAction: TextInputAction.next,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
        ),
      ],
    ),
  );
  return controller;
}

TextField _textField(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));

void main() {
  testWidgets('TC-008-25 amount field has label, description and an (i)', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text(_label), findsOneWidget);
    expect(find.text(_description), findsOneWidget);
    // The (i) is its own control with the F-004 label.
    expect(find.byType(InfoButton), findsOneWidget);
    expect(find.bySemanticsLabel('More about $_label'), findsOneWidget);

    await tester.tap(find.byType(InfoButton));
    await tester.pumpAndSettle();
    expect(find.text(_help.body), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text(_help.body), findsNothing);
  });

  testWidgets('TC-008-25 the field reads as label, description, edit box', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    final node = tester.getSemantics(find.byType(TextField));
    expect(node.label, _label);
    expect(node.hint, _description);
    expect(node.flagsCollection.isTextField, isTrue);
    // The description is not read a second time as separate text.
    expect(find.bySemanticsLabel(_description), findsNothing);
    semantics.dispose();
  });

  testWidgets(
    'TC-008-04 amount field has the rupee prefix and a decimal keypad',
    (tester) async {
      await _pump(tester);

      final decorator = tester.widget<InputDecorator>(
        find.byType(InputDecorator),
      );
      expect(decorator.decoration.prefixText, '₹');
      expect(
        _textField(tester).keyboardType,
        const TextInputType.numberWithOptions(decimal: true),
      );
      expect(_textField(tester).textInputAction, TextInputAction.next);
      expect(tester.getSize(find.byType(TextField)).height, 56);
      expect(_textField(tester).style!.fontFamily, kFontBody);
      expect(_textField(tester).style!.fontSize, 18);
    },
  );

  testWidgets(
    'TC-009-21 large amount field is 64 dp with the money large style',
    (tester) async {
      await _pump(tester, large: true, withInfo: false);

      expect(tester.getSize(find.byType(TextField)).height, 64);
      expect(_textField(tester).style!.fontSize, 28);
      expect(find.byType(InfoButton), findsNothing);
      final decorator = tester.widget<InputDecorator>(
        find.byType(InputDecorator),
      );
      expect(decorator.decoration.prefixStyle!.fontSize, 28);
    },
  );

  testWidgets('TC-008-31 typed and pasted text is kept exactly as entered', (
    tester,
  ) async {
    final changes = <String>[];
    final controller = await _pump(tester, onChanged: changes.add);

    for (final text in ['₹40,000', '40,000.00', ' 40000 ', '40k', '4O000']) {
      await tester.enterText(find.byType(TextField), text);
      expect(controller.text, text, reason: text);
    }
    expect(changes, ['₹40,000', '40,000.00', ' 40000 ', '40k', '4O000']);
  });

  testWidgets('TC-008-05 the error shows with an icon and is announced', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, errorText: 'Enter your salary');

    expect(find.text('Enter your salary'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.bySemanticsLabel('Error: Enter your salary'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-008-04 submitting from the keyboard reaches the screen', (
    tester,
  ) async {
    final submitted = <String>[];
    await _pump(tester, onSubmitted: submitted.add);

    await tester.enterText(find.byType(TextField), '40000');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    expect(submitted, ['40000']);
  });

  testWidgets(
    'TC-008-24 amount field passes the sweep in all themes and sizes',
    (tester) async {
      for (final theme in ThemeCase.values) {
        for (final scale in [1.0, 2.0]) {
          await tester.pumpWidget(const SizedBox());
          await _pump(
            tester,
            theme: theme,
            textScale: scale,
            size: const Size(360, 640),
            errorText: 'Enter your salary',
          );
          await expectAccessible(tester, reason: '${theme.name} x$scale');
        }
      }
    },
  );

  testWidgets('TC-008-24 the (i) stays beside the label at the largest text', (
    tester,
  ) async {
    await _pump(tester, textScale: 2, size: const Size(360, 640), large: true);

    final label = tester.getRect(find.text(_label));
    final info = tester.getRect(find.byType(InfoButton));
    expect(info.left, greaterThanOrEqualTo(label.left));
    expect(info.width, 48);
    expect(info.height, 48);
    expect(tester.takeException(), isNull);
  });
}
