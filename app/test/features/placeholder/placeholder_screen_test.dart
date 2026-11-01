import 'package:daily_budget/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

// Expected copy from the feature doc §5, written as literals on purpose:
// comparing against the screen's own constants would let a typo pass.
const _title = 'Daily Budget App';
const _status = 'Setting things up. Your daily budget will appear here soon.';

void main() {
  testWidgets('TC-001-14 placeholder shows title and status text', (
    tester,
  ) async {
    await tester.pumpWidget(const DailyBudgetApp());
    await tester.pumpAndSettle();

    expect(find.text(_title), findsOneWidget);
    expect(find.text(_status), findsOneWidget);
    expect(find.byType(Text), findsNWidgets(2));
  });

  testWidgets('TC-001-15 placeholder has no buttons or text fields', (
    tester,
  ) async {
    await tester.pumpWidget(const DailyBudgetApp());
    await tester.pumpAndSettle();

    for (final type in const [
      ButtonStyleButton,
      IconButton,
      FloatingActionButton,
      TextField,
      TextFormField,
      EditableText,
      BottomNavigationBar,
      NavigationBar,
      Drawer,
    ]) {
      expect(find.byType(type), findsNothing, reason: '$type found');
    }

    // Type-independent guard: an InkWell, GestureDetector, Checkbox or any
    // other tappable widget exposes a tap action in the semantics tree.
    final semantics = tester.ensureSemantics();
    await tester.pump();
    expect(
      find.semantics.byAction(SemanticsAction.tap),
      findsNothing,
      reason: 'something on screen is tappable',
    );
    semantics.dispose();
  });

  testWidgets('TC-001-16 placeholder renders without exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(const DailyBudgetApp());
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-001-43 placeholder fits at text scale 3.0 on small screen', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const DailyBudgetApp());
    await tester.pumpAndSettle();

    expect(find.text(_title), findsOneWidget);
    expect(find.text(_status), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
