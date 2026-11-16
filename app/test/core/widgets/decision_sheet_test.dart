import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/budget_sheet.dart';
import 'package:daily_budget/core/widgets/decision_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/theme_cases.dart';
import '../../support/find_copy.dart';

// The decision sheet of design system §7.8 as F-008 (shortfall, discard) and
// F-009 (delete, cover taken back) use it. There is no Material dialog.

enum _Choice { fix, continueAnyway, dismissed }

const _title = "Your numbers don't add up";
const _body = 'Your fixed costs are ₹1,000 more than your salary.';

/// A page with one button that opens the sheet; the list fills in when the
/// sheet closes.
Future<List<_Choice>> _pumpPage(
  WidgetTester tester, {
  ThemeCase theme = ThemeCase.light,
  Size? size,
  double textScale = 1,
  List<String> paragraphs = const [_body],
}) async {
  final results = <_Choice>[];
  await pumpBudgetWidget(
    tester,
    theme: theme,
    size: size,
    textScale: textScale,
    Builder(
      builder: (context) => Center(
        child: BudgetButton.primary(
          label: 'Open',
          onPressed: () async {
            results.add(
              await showDecisionSheet<_Choice>(
                context: context,
                title: _title,
                paragraphs: paragraphs,
                dismissValue: _Choice.dismissed,
                options: const [
                  DecisionOption.primary(
                    value: _Choice.fix,
                    label: 'Fix my numbers',
                    caption:
                        'Recommended. Change your costs or target so the '
                        'month adds up.',
                    hint: 'Go back and change your numbers',
                  ),
                  DecisionOption(
                    value: _Choice.continueAnyway,
                    label: 'Continue anyway',
                    caption:
                        'Start with ₹0 a day. Every spend this month will '
                        'count as overspent.',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
  return results;
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TC-008-12 the sheet shows title, body, buttons and captions', (
    tester,
  ) async {
    await _pumpPage(tester);
    await _open(tester);

    expect(find.text(_title), findsOneWidget);
    expect(findCopy(_body), findsOneWidget);
    expect(find.text('Fix my numbers'), findsOneWidget);
    expect(find.text('Continue anyway'), findsOneWidget);
    expect(
      find.text(
        'Recommended. Change your costs or target so the month adds up.',
      ),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('TC-008-12 button 1 is the Primary one and sits above button 2', (
    tester,
  ) async {
    await _pumpPage(tester);
    await _open(tester);

    expect(find.byType(FilledButton), findsNWidgets(2)); // Open + Fix
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Fix my numbers')).dy,
      lessThan(tester.getTopLeft(find.text('Continue anyway')).dy),
    );
    // Full width inside the sheet padding.
    final width = tester.getSize(
      find.widgetWithText(FilledButton, 'Fix my numbers'),
    );
    expect(
      width.width,
      tester.view.physicalSize.width / tester.view.devicePixelRatio - 40,
    );
  });

  testWidgets('TC-008-12 a button returns its value and closes the sheet', (
    tester,
  ) async {
    final results = await _pumpPage(tester);
    await _open(tester);

    await tester.tap(find.text('Continue anyway'));
    await tester.pumpAndSettle();

    expect(results, [_Choice.continueAnyway]);
    expect(find.text(_title), findsNothing);
  });

  testWidgets('TC-008-12 Fix my numbers returns the recommended choice', (
    tester,
  ) async {
    final results = await _pumpPage(tester);
    await _open(tester);

    await tester.tap(find.text('Fix my numbers'));
    await tester.pumpAndSettle();

    expect(results, [_Choice.fix]);
  });

  testWidgets('TC-008-53 back on the sheet is the safe choice', (tester) async {
    final results = await _pumpPage(tester);
    await _open(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(results, [_Choice.dismissed]);
    expect(find.text(_title), findsNothing);
  });

  testWidgets('TC-008-22 a tap on the scrim after opening is the safe choice', (
    tester,
  ) async {
    final results = await _pumpPage(tester);
    await _open(tester);
    // The scrim ignores taps until a double-tap interval has passed (D-031).
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(results, [_Choice.dismissed]);
  });

  testWidgets('TC-008-16 a second tap while the sheet closes is ignored', (
    tester,
  ) async {
    final results = await _pumpPage(tester);
    await _open(tester);

    await tester.tap(find.text('Fix my numbers'));
    await tester.tap(find.text('Fix my numbers'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(results, [_Choice.fix]);
  });

  testWidgets('TC-009-28 several paragraphs are separate texts, in order', (
    tester,
  ) async {
    await _pumpPage(tester, paragraphs: ['First cover.', 'Second cover.']);
    await _open(tester);

    expect(find.text('First cover.'), findsOneWidget);
    expect(find.text('Second cover.'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('First cover.')).dy,
      lessThan(tester.getTopLeft(find.text('Second cover.')).dy),
    );
  });

  testWidgets('TC-008-26 buttons read in order with their hints', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpPage(tester);
    await _open(tester);

    expect(
      tester
          .getSemantics(find.widgetWithText(FilledButton, 'Fix my numbers'))
          .hint,
      'Go back and change your numbers',
    );
    expect(find.bySemanticsLabel(_title), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('TC-008-24 the sheet passes the sweep in all themes and sizes', (
    tester,
  ) async {
    for (final theme in ThemeCase.values) {
      for (final scale in [1.0, 2.0]) {
        await tester.pumpWidget(const SizedBox());
        await _pumpPage(
          tester,
          theme: theme,
          textScale: scale,
          size: const Size(360, 640),
        );
        await _open(tester);
        await expectAccessible(tester, reason: '${theme.name} x$scale');
        // Both buttons stay reachable at the largest text.
        expect(find.text('Fix my numbers'), findsOneWidget);
        expect(find.text('Continue anyway'), findsOneWidget);
      }
    }
  });

  testWidgets(
    'TC-008-24 the sheet fits a landscape phone and scrolls its body',
    (tester) async {
      await _pumpPage(
        tester,
        size: const Size(640, 360),
        textScale: 2,
        paragraphs: List.filled(6, _body),
      );
      await _open(tester);

      expect(tester.takeException(), isNull);
      // The sheet stays within 90 % of the screen: the text scrolls, the
      // buttons are pinned, and at this size they scroll on their own.
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(
        tester.getSize(find.byType(BudgetSheetFrame)).height,
        lessThanOrEqualTo(screen.height * 0.9 + 0.5),
      );
      expect(find.byType(SingleChildScrollView), findsNWidgets(2));
      await tester.ensureVisible(find.text('Continue anyway'));
      await tester.pump();
      await tester.tap(find.text('Continue anyway'));
      await tester.pumpAndSettle();
      expect(find.text(_title), findsNothing);
    },
  );
}
