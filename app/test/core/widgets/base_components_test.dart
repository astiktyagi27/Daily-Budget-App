import 'package:daily_budget/core/theme/budget_colors.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:daily_budget/core/widgets/budget_list_row.dart';
import 'package:daily_budget/core/widgets/budget_text_field.dart';
import 'package:daily_budget/core/widgets/focus_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/contrast.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/theme_cases.dart';

Material _materialOf(WidgetTester tester, Finder button) => tester
    .widgetList<Material>(
      find.descendant(of: button, matching: find.byType(Material)),
    )
    .first;

Color? _textColor(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style?.color;

RoundedRectangleBorder _shape(Material material) =>
    material.shape! as RoundedRectangleBorder;

final Finder _focusRing = find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter is FocusRingPainter,
);

/// Every base component once, for the sweep tests.
Widget _gallery() => ListView(
  padding: const EdgeInsets.all(20),
  children: [
    BudgetButton.primary(label: 'Continue', onPressed: () {}),
    const SizedBox(height: 8),
    const BudgetButton.primary(label: 'Save', onPressed: null),
    const SizedBox(height: 8),
    BudgetButton.secondary(label: 'Skip tour', onPressed: () {}),
    const SizedBox(height: 8),
    BudgetButton.text(label: 'Got it', onPressed: () {}),
    const SizedBox(height: 8),
    BudgetButton.destructive(label: 'Delete', onPressed: () {}),
    const SizedBox(height: 8),
    const BudgetCard(
      title: 'Card title',
      child: Text('Card body that wraps over more than one line at large text'),
    ),
    const SizedBox(height: 8),
    BudgetCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          BudgetListRow(
            label: 'Theme',
            description: 'Auto (follows your phone)',
            leadingIcon: Icons.contrast,
            trailing: const BudgetRowChevron(),
            onTap: () {},
          ),
          const BudgetListRow(
            label: 'Notifications',
            description: 'Budget warnings and an end-of-day summary',
            leadingIcon: Icons.notifications_none,
            tag: 'Coming soon',
            enabled: false,
          ),
          BudgetListRow(
            label: 'Tips',
            trailing: Switch(value: true, onChanged: (_) {}),
            onTap: () {},
          ),
        ],
      ),
    ),
    const SizedBox(height: 8),
    const BudgetTextField(
      label: 'Salary',
      description: 'Your take-home pay each month',
      isAmount: true,
    ),
    const SizedBox(height: 8),
    const BudgetTextField(
      label: 'Fixed costs',
      errorText: 'Enter an amount above ₹0',
      isAmount: true,
    ),
    const SizedBox(height: 8),
    const BudgetTextField(label: 'Note', enabled: false),
  ],
);

void main() {
  testWidgets('TC-002-18 buttons render all states in all themes', (
    tester,
  ) async {
    for (final theme in ThemeCase.values) {
      // Start each theme from an empty tree, so no cross-fade from the
      // previous theme is still running (the spinner stops pumpAndSettle).
      await tester.pumpWidget(const SizedBox());
      final c = theme.colors;
      final where = theme.name;
      final focus = {
        for (final name in ['primary', 'secondary', 'text', 'destructive'])
          name: FocusNode(),
      };
      addTearDown(() {
        for (final node in focus.values) {
          node.dispose();
        }
      });
      var taps = 0;
      await pumpBudgetWidget(
        tester,
        theme: theme,
        settle: false,
        ListView(
          padding: const EdgeInsets.all(20),
          children: [
            BudgetButton.primary(
              label: 'Continue',
              onPressed: () => taps++,
              focusNode: focus['primary'],
            ),
            BudgetButton.secondary(
              label: 'Not now',
              onPressed: () {},
              focusNode: focus['secondary'],
            ),
            BudgetButton.text(
              label: 'Got it',
              onPressed: () {},
              focusNode: focus['text'],
            ),
            BudgetButton.destructive(
              label: 'Delete',
              onPressed: () {},
              focusNode: focus['destructive'],
            ),
            const BudgetButton.primary(label: 'Save', onPressed: null),
            const BudgetButton.secondary(label: 'Skip', onPressed: null),
            Row(
              children: [
                BudgetButton.primary(
                  label: 'Send',
                  onPressed: () {},
                  expand: false,
                ),
                BudgetButton.primary(
                  label: 'Send',
                  onPressed: () => taps++,
                  loading: true,
                  expand: false,
                ),
              ],
            ),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: where);

      // Primary: 52 dp high, radius 14, accent fill, onAccent label,
      // sentence case (shown exactly as given, never ALL CAPS).
      final primary = find.byType(FilledButton).first;
      expect(tester.getSize(primary).height, 52, reason: where);
      final primaryMaterial = _materialOf(tester, primary);
      expect(primaryMaterial.color, c.accent, reason: where);
      expect(
        _shape(primaryMaterial).borderRadius,
        BorderRadius.circular(14),
        reason: where,
      );
      expect(_textColor(tester, 'Continue'), c.onAccent, reason: where);
      expect(find.text('CONTINUE'), findsNothing, reason: where);

      // Secondary: surface fill, 1 dp borderStrong outline, textPrimary.
      final secondary = find.widgetWithText(OutlinedButton, 'Not now');
      expect(tester.getSize(secondary).height, 52, reason: where);
      final secondaryMaterial = _materialOf(tester, secondary);
      expect(secondaryMaterial.color, c.surface, reason: where);
      expect(
        _shape(secondaryMaterial).side,
        BorderSide(color: c.borderStrong),
        reason: where,
      );
      expect(_textColor(tester, 'Not now'), c.textPrimary, reason: where);

      // Text: accent label, at least 48 × 48 dp.
      final text = find.byType(TextButton);
      expect(_textColor(tester, 'Got it'), c.accent, reason: where);
      expect(tester.getSize(text).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(text).height, greaterThanOrEqualTo(48));

      // Destructive: secondary look, overspent label, leading icon.
      expect(_textColor(tester, 'Delete'), c.overspent, reason: where);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      // Disabled: neutralSoft fill, textSecondary label (≥ 4.5 : 1).
      for (final label in ['Save', 'Skip']) {
        final button = find.ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        );
        expect(
          _materialOf(tester, button).color,
          c.neutralSoft,
          reason: '$where $label',
        );
        expect(_textColor(tester, label), c.textSecondary, reason: where);
      }
      expect(
        contrastRatio(c.textSecondary, c.neutralSoft),
        greaterThanOrEqualTo(4.5),
        reason: where,
      );

      // Loading: progress ring, same width, taps ignored.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final sendButtons = find.widgetWithText(FilledButton, 'Send');
      expect(
        tester.getSize(sendButtons.last).width,
        tester.getSize(sendButtons.first).width,
        reason: where,
      );
      await tester.tap(find.byType(FilledButton).last);
      expect(taps, 0, reason: where);

      // Pressed: held gesture, 8 % textPrimary (Light) / 10 % white overlay.
      final gesture = await tester.startGesture(tester.getCenter(primary));
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.takeException(), isNull, reason: where);
      final context = tester.element(primary);
      final pressed = Theme.of(context).filledButtonTheme.style!.overlayColor!
          .resolve({WidgetState.pressed});
      expect(
        pressed,
        c == BudgetColors.light
            ? c.textPrimary.withValues(alpha: 0.08)
            : const Color(0xFFFFFFFF).withValues(alpha: 0.10),
        reason: where,
      );
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 300));
      expect(taps, 1, reason: where);

      // Focused: 2 dp focus ring, one at a time.
      expect(_focusRing, findsNothing, reason: where);
      for (final MapEntry(key: name, value: node) in focus.entries) {
        node.requestFocus();
        await tester.pump(const Duration(milliseconds: 300));
        expect(_focusRing, findsOneWidget, reason: '$where $name focused');
        final painter =
            tester.widget<CustomPaint>(_focusRing).painter! as FocusRingPainter;
        expect(painter.color, c.focus, reason: where);
        expect(FocusRingPainter.strokeWidth, 2);
      }
      focus['destructive']!.unfocus();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_focusRing, findsNothing, reason: where);
    }
  });

  testWidgets('TC-002-19 card and list row match the design system', (
    tester,
  ) async {
    for (final theme in ThemeCase.values) {
      final c = theme.colors;
      final where = theme.name;
      var rowTaps = 0;
      var switchOn = false;
      await pumpBudgetWidget(
        tester,
        theme: theme,
        ListView(
          children: [
            const BudgetCard(child: Text('Card body')),
            BudgetListRow(label: 'Plain row', onTap: () => rowTaps++),
            BudgetListRow(
              label: 'Theme',
              description: 'Auto (follows your phone)',
              leadingIcon: Icons.contrast,
              trailing: const BudgetRowChevron(),
              onTap: () => rowTaps++,
            ),
            StatefulBuilder(
              builder: (context, setState) => BudgetListRow(
                label: 'Tips',
                trailing: Switch(
                  value: switchOn,
                  onChanged: (v) => setState(() => switchOn = v),
                ),
              ),
            ),
            const BudgetListRow(
              label: 'Bank account',
              description: 'The account your salary arrives in',
              tag: 'Coming soon',
              enabled: false,
            ),
          ],
        ),
      );
      expect(tester.takeException(), isNull, reason: where);

      // Card: radius 20, elevation 0, 1 dp border edge, surface fill.
      final card = _materialOf(tester, find.byType(BudgetCard));
      expect(card.color, c.surface, reason: where);
      expect(card.elevation, 0, reason: where);
      expect(
        _shape(card).borderRadius,
        BorderRadius.circular(20),
        reason: where,
      );
      expect(_shape(card).side, BorderSide(color: c.border), reason: where);

      // Rows: min height 56 (72 with a description).
      final plain = find.widgetWithText(BudgetListRow, 'Plain row');
      final described = find.widgetWithText(BudgetListRow, 'Theme');
      expect(tester.getSize(plain).height, greaterThanOrEqualTo(56));
      expect(tester.getSize(plain).height, lessThan(72), reason: where);
      expect(tester.getSize(described).height, greaterThanOrEqualTo(72));

      // Title in the label style, description in body / textSecondary.
      final title = tester
          .renderObject<RenderParagraph>(find.text('Theme'))
          .text
          .style!;
      expect(title.fontSize, 14, reason: where);
      expect(title.fontWeight, FontWeight.w500, reason: where);
      expect(title.color, c.textPrimary, reason: where);
      final description = tester
          .renderObject<RenderParagraph>(find.text('Auto (follows your phone)'))
          .text
          .style!;
      expect(description.fontSize, 14, reason: where);
      expect(description.fontWeight, FontWeight.w400, reason: where);
      expect(description.color, c.textSecondary, reason: where);

      // The whole row is one tap target: tapping the description, the
      // leading icon or the chevron all open the row.
      await tester.tap(find.text('Auto (follows your phone)'));
      await tester.tap(find.byIcon(Icons.contrast));
      await tester.tap(find.byIcon(Icons.chevron_right));
      expect(rowTaps, 3, reason: where);

      // Switch row toggles; Coming soon row: tag, readable grey label.
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(switchOn, isTrue, reason: where);
      switchOn = false;
      expect(find.text('Coming soon'), findsOneWidget);
      expect(_textColor(tester, 'Bank account'), c.textSecondary);
      expect(_textColor(tester, 'Coming soon'), c.textSecondary);
      final tag = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text('Coming soon'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((tag.decoration as BoxDecoration).color, c.neutralSoft);

      // One semantics node per row, with its label and description.
      final semantics = tester.ensureSemantics();
      expect(
        tester.getSemantics(described),
        matchesSemantics(
          label: 'Theme. Auto (follows your phone)',
          isButton: true,
          hasTapAction: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      semantics.dispose();
    }
  });

  testWidgets('TC-002-20 text input renders all states in all themes', (
    tester,
  ) async {
    for (final theme in ThemeCase.values) {
      final c = theme.colors;
      final where = theme.name;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await pumpBudgetWidget(
        tester,
        theme: theme,
        ListView(
          padding: const EdgeInsets.all(20),
          children: [
            BudgetTextField(
              label: 'Salary',
              description: 'Your take-home pay each month',
              isAmount: true,
              focusNode: focusNode,
            ),
            const BudgetTextField(
              label: 'Fixed costs',
              errorText: 'Enter an amount above ₹0',
              isAmount: true,
            ),
            const BudgetTextField(label: 'Note', enabled: false),
          ],
        ),
      );
      expect(tester.takeException(), isNull, reason: where);

      InputDecorator decorator(String label) => tester.widget<InputDecorator>(
        find.descendant(
          of: find.widgetWithText(BudgetTextField, label),
          matching: find.byType(InputDecorator),
        ),
      );
      Finder field(String label) => find.descendant(
        of: find.widgetWithText(BudgetTextField, label),
        matching: find.byType(TextField),
      );

      // Enabled: 56 dp, sunken fill, 1 dp borderStrong outline, ₹ prefix,
      // label above the field (never inside it).
      final salary = decorator('Salary');
      expect(tester.getSize(field('Salary')).height, 56, reason: where);
      expect(salary.decoration.filled, isTrue, reason: where);
      expect(salary.decoration.fillColor, c.sunken, reason: where);
      expect(
        salary.decoration.enabledBorder!.borderSide,
        BorderSide(color: c.borderStrong),
        reason: where,
      );
      expect(salary.decoration.prefixText, '₹', reason: where);
      expect(salary.decoration.labelText, isNull, reason: where);
      expect(
        tester.getBottomLeft(find.text('Salary')).dy,
        lessThan(tester.getTopLeft(field('Salary')).dy),
        reason: where,
      );
      expect(_textColor(tester, 'Salary'), c.textPrimary, reason: where);
      expect(
        _textColor(tester, 'Your take-home pay each month'),
        c.textSecondary,
        reason: where,
      );

      // Focused: 2 dp accent outline.
      focusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(decorator('Salary').isFocused, isTrue, reason: where);
      expect(
        decorator('Salary').decoration.focusedBorder!.borderSide,
        BorderSide(color: c.accent, width: 2),
        reason: where,
      );
      expect(find.text('Salary'), findsOneWidget, reason: 'label stays');
      focusNode.unfocus();
      await tester.pumpAndSettle();

      // Error: 2 dp overspent outline + error icon + message.
      final error = decorator('Fixed costs');
      expect(
        error.decoration.errorBorder!.borderSide,
        BorderSide(color: c.overspent, width: 2),
        reason: where,
      );
      expect(error.decoration.error, isNotNull, reason: where);
      expect(find.byIcon(Icons.error_outline), findsOneWidget, reason: where);
      expect(
        _textColor(tester, 'Enter an amount above ₹0'),
        c.overspent,
        reason: where,
      );
      final semantics = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel('Error: Enter an amount above ₹0'),
        findsOne,
      );
      semantics.dispose();

      // Disabled: neutralSoft fill, no typing.
      final note = decorator('Note');
      expect(note.decoration.enabled, isFalse, reason: where);
      expect(note.decoration.fillColor, c.neutralSoft, reason: where);
      expect(tester.getSize(field('Note')).height, 56, reason: where);
    }
  });

  testWidgets('TC-002-23 base components meet tap target and contrast '
      'guidelines', (tester) async {
    for (final theme in ThemeCase.values) {
      await pumpBudgetWidget(
        tester,
        theme: theme,
        size: kSmallPhone,
        _gallery(),
      );
      await expectAccessible(tester, reason: theme.name);
    }
  });

  testWidgets(
    'TC-002-24 base components fit at text scale 2 on a small phone',
    (tester) async {
      for (final theme in ThemeCase.values) {
        for (final size in [kSmallPhone, kNarrowPhone, kSmallLandscape]) {
          await pumpBudgetWidget(
            tester,
            theme: theme,
            size: size,
            textScale: 2,
            boldText: true,
            _gallery(),
          );
          final where = '${theme.name} at $size';
          expectNoOverflow(tester, reason: where);
          // The last component can be scrolled to.
          await tester.scrollUntilVisible(
            find.text('Note'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(
            find.text('Note').hitTestable(),
            findsOneWidget,
            reason: where,
          );
        }
      }
    },
  );

  testWidgets('TC-002-43 missing glyphs fall back without crash', (
    tester,
  ) async {
    await pumpBudgetWidget(
      tester,
      Builder(
        builder: (context) =>
            Text('नमस्ते ₹100', style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('नमस्ते ₹100'), findsOneWidget);
  });
}
