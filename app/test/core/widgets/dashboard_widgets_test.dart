import 'package:daily_budget/core/widgets/ledger_row.dart';
import 'package:daily_budget/core/widgets/segmented_control.dart';
import 'package:daily_budget/core/widgets/share_bar_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/theme_cases.dart';

// The shared Dashboard widgets (F-013 T-383): segmented control (design
// system 7.15), share bar row (7.16) and ledger row.

const _segments = <Segment>[
  (label: 'This month', hint: 'Show spending for the month', semantics: 'a'),
  (label: 'One day', hint: 'Show spending for one day', semantics: 'b'),
];

Widget _row({int permille = 700, String share = '70%', double width = 300}) =>
    SizedBox(
      width: width,
      child: ShareBarRow(
        name: 'Other',
        amount: '₹3,910',
        share: share,
        barPermille: permille,
        semanticsLabel: 'Other, ₹3,910, 70 percent',
      ),
    );

double _barWidth(WidgetTester tester) =>
    tester.getSize(find.byKey(ShareBarRow.barKey)).width;

void main() {
  testWidgets('TC-013-06 a share bar is its exact share of the track', (
    tester,
  ) async {
    await pumpBudgetWidget(tester, _row());
    await tester.pumpAndSettle();
    expect(_barWidth(tester), closeTo(300 * 0.7, 0.01));

    await pumpBudgetWidget(tester, _row(permille: 180));
    await tester.pumpAndSettle();
    expect(_barWidth(tester), closeTo(54, 0.01));
  });

  testWidgets('TC-013-08 a tiny share still draws a 2 dp bar', (tester) async {
    await pumpBudgetWidget(tester, _row(permille: 5, share: '<1%'));
    await tester.pumpAndSettle();
    expect(_barWidth(tester), 2);
    expect(find.text('<1%'), findsOneWidget);
  });

  testWidgets('TC-013-30 a share row reads as one sentence without the bar', (
    tester,
  ) async {
    await pumpBudgetWidget(tester, _row());
    expect(find.bySemanticsLabel('Other, ₹3,910, 70 percent'), findsOneWidget);
    expect(find.bySemanticsLabel('70%'), findsNothing);
  });

  testWidgets('TC-013-28 a share row stacks above 1.3x text', (tester) async {
    await pumpBudgetWidget(tester, _row());
    final flat = tester.getTopLeft(find.text('₹3,910')).dy;
    final flatName = tester.getTopLeft(find.text('Other')).dy;
    expect((flat - flatName).abs(), lessThan(8));

    await pumpBudgetWidget(tester, _row(), textScale: 2);
    expect(
      tester.getTopLeft(find.text('₹3,910')).dy,
      greaterThan(tester.getTopLeft(find.text('Other')).dy + 10),
    );
    expectNoOverflow(tester);
  });

  testWidgets('TC-013-09 the segmented control selects and reports', (
    tester,
  ) async {
    var selected = 0;
    await pumpBudgetWidget(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SegmentedControl(
          segments: _segments,
          selectedIndex: selected,
          onChanged: (index) => setState(() => selected = index),
        ),
      ),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.tap(find.text('One day'));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(
      tester.getSemantics(find.text('One day')).hint,
      'Show spending for one day',
    );
  });

  testWidgets('TC-013-28 segment labels wrap at 2.0x and stay 48 dp', (
    tester,
  ) async {
    for (final theme in ThemeCase.values) {
      await pumpBudgetWidget(
        tester,
        SegmentedControl(
          segments: _segments,
          selectedIndex: 0,
          onChanged: (_) {},
        ),
        theme: theme,
        textScale: 2,
      );
      await expectAccessible(tester, reason: theme.name);
      expect(
        tester.getSize(find.byType(SegmentedControl)).height,
        greaterThanOrEqualTo(48),
      );
    }
  });

  testWidgets('TC-013-57 segmented control keeps 48 dp at normal text', (
    tester,
  ) async {
    for (final theme in [ThemeCase.light, ThemeCase.dim]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        await pumpBudgetWidget(
          tester,
          SegmentedControl(
            segments: _segments,
            selectedIndex: 0,
            onChanged: (_) {},
          ),
          theme: theme,
          textScale: scale,
        );
        final reason = '${theme.name} x$scale';
        expect(
          tester.getSize(find.byType(SegmentedControl)).height,
          greaterThanOrEqualTo(48),
          reason: reason,
        );
        final segments = find.descendant(
          of: find.byType(SegmentedControl),
          matching: find.byType(Expanded),
        );
        expect(segments, findsNWidgets(2), reason: reason);
        for (final segment in segments.evaluate()) {
          expect(
            tester.getSize(find.byElementPredicate((e) => e == segment)).height,
            greaterThanOrEqualTo(48),
            reason: reason,
          );
        }
        await expectAccessible(tester, reason: reason);
      }
    }
  });

  testWidgets('TC-013-58 share bars are ink in every theme', (tester) async {
    for (final theme in ThemeCase.values) {
      await pumpBudgetWidget(tester, _row(), theme: theme);
      final colors = theme.colors;
      final bar = tester.widget<Container>(find.byKey(ShareBarRow.barKey));
      final barColor = (bar.decoration! as BoxDecoration).color;
      expect(barColor, colors.textPrimary, reason: theme.name);
      expect(barColor, isNot(colors.saved), reason: theme.name);
      expect(barColor, isNot(colors.overspent), reason: theme.name);
      expect(barColor, isNot(colors.accent), reason: theme.name);
      final track = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.byKey(ShareBarRow.barKey),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (track.decoration as BoxDecoration).color,
        colors.neutralSoft,
        reason: theme.name,
      );
    }
  });

  testWidgets('TC-013-59 ledger amount colour', (tester) async {
    Color? colorOf(Finder amount) => tester.widget<Text>(amount).style?.color;
    for (final theme in ThemeCase.values) {
      final colors = theme.colors;
      await pumpBudgetWidget(
        tester,
        Column(
          children: [
            for (final status in <LedgerStatus?>[
              null,
              LedgerStatus.saved,
              LedgerStatus.overspent,
            ])
              LedgerRow(
                label: 'Row ${status?.name}',
                info: (title: 'Row', body: 'Body.'),
                amount: '₹${status?.name}',
                amountSpeech: 'rupees ${status?.name}',
                status: status,
              ),
          ],
        ),
        theme: theme,
      );
      final reason = theme.name;
      final plain = find.text('₹null');
      expect(colorOf(plain), colors.textPrimary, reason: reason);
      expect(colorOf(plain), isNot(colors.saved), reason: reason);
      expect(colorOf(plain), isNot(colors.overspent), reason: reason);
      expect(colorOf(plain), isNot(colors.textSecondary), reason: reason);
      expect(
        find.bySemanticsLabel('Row null, rupees null'),
        findsOneWidget,
        reason: reason,
      );
      for (final (status, expected) in [
        (LedgerStatus.saved, colors.saved),
        (LedgerStatus.overspent, colors.overspent),
      ]) {
        final rich = find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.textSpan?.toPlainText() == '${status.mark} ₹${status.name}',
        );
        expect(rich, findsOneWidget, reason: reason);
        final text = tester.widget<Text>(rich);
        expect(text.style?.color, expected, reason: reason);
        expect(text.style?.color, isNot(colors.textPrimary), reason: reason);
        final mark = (text.textSpan! as TextSpan).children!.first as TextSpan;
        expect(mark.style?.color, expected, reason: reason);
      }
    }
  });

  testWidgets('TC-013-10 a ledger row reads label and amount together', (
    tester,
  ) async {
    await pumpBudgetWidget(
      tester,
      const LedgerRow(
        label: 'Refunds',
        info: (title: 'Refunds', body: 'Money paid back to you.'),
        amount: '−₹500',
        amountSpeech: 'minus ₹500',
      ),
    );
    expect(find.bySemanticsLabel('Refunds, minus ₹500'), findsOneWidget);
    expect(find.bySemanticsLabel('More about Refunds'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('More about Refunds'));
    await tester.pumpAndSettle();
    expect(find.text('Money paid back to you.'), findsOneWidget);
  });

  testWidgets('TC-013-28 a ledger row stacks at 2.0x without overflow', (
    tester,
  ) async {
    await pumpBudgetWidget(
      tester,
      const LedgerRow(
        label: 'Net spent',
        info: (title: 'Net spent', body: 'Spends minus refunds.'),
        amount: '−₹1,300',
        amountSpeech: 'minus ₹1,300',
      ),
      textScale: 2,
    );
    await expectAccessible(tester);
    expect(
      tester.getTopLeft(find.text('−₹1,300')).dy,
      greaterThan(tester.getTopLeft(find.text('Net spent')).dy),
    );
  });
}
