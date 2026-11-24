import 'package:daily_budget/features/home/widgets/collapsed_summary_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phase3_fixtures.dart';
import '../../helpers/pump_app.dart';
import 'home_harness.dart';

// The pinned summary row (F-010 AC-15, plan T-304).

Future<void> _scroll(WidgetTester tester, double by) async {
  // One drag cannot leave the screen, so move in steps.
  for (var moved = 0.0; moved < by; moved += 300) {
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('TC-010-33 summary collapses to one pinned row on scroll', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openFixture(tester, a13);
    expect(find.byType(CollapsedSummaryRow), findsNothing);

    await _scroll(tester, 700);
    final row = find.byType(CollapsedSummaryRow);
    expect(row, findsOneWidget);
    expect(tester.getSize(row).height, 56);
    expect(
      find.descendant(
        of: row,
        matching: find.textContaining('₹19,370', findRichText: true),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: row,
        matching: find.textContaining('₹830', findRichText: true),
      ),
      findsOneWidget,
    );
    final node = find.bySemanticsLabel('₹19,370 left this month, ₹830 a day');
    expect(node, findsOneWidget);
    expect(tester.getSemantics(node).hint, 'Scroll to the top');
    expect(
      find.descendant(
        of: row,
        matching: find.textContaining('Safe', findRichText: true),
      ),
      findsNothing,
    );

    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(CollapsedSummaryRow), findsNothing);
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      0,
    );
    semantics.dispose();
  });

  testWidgets('TC-010-34 collapsed row for negative left and its large text '
      'rule', (tester) async {
    final semantics = tester.ensureSemantics();
    // (a) S8+150 at X1.
    await openFixture(tester, s8Plus150);
    await _scroll(tester, 1200);
    final row = find.byType(CollapsedSummaryRow);
    expect(row, findsOneWidget);
    expect(
      find.descendant(
        of: row,
        matching: find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().replaceAll(' ', ' ') ==
                  '◆ ₹1,350 over this month · ₹0/day',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('₹1,350 over this month, ₹0 a day'),
      findsOneWidget,
    );

    // (b) A13 at X2 and (c) A13 in landscape: no pinned row.
    await tester.pumpWidget(const SizedBox());
    await openFixture(tester, a13, textScale: 2);
    await _scroll(tester, 900);
    expect(find.byType(CollapsedSummaryRow), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await openFixture(tester, a13, size: kSmallLandscape);
    await _scroll(tester, 700);
    expect(find.byType(CollapsedSummaryRow), findsNothing);
    semantics.dispose();
  });
}
