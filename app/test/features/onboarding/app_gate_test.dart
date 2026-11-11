import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/shell.dart';
import 'onboarding_host.dart';

// Review N9 (T-121): during the 200 ms swap the outgoing root page is still
// in the tree. It must not be read by screen readers, take taps or focus,
// or answer Back: Back belongs to the incoming page.

/// A node in the semantics tree (what TalkBack reads) mentions [text].
FinderBase<SemanticsNode> _read(String text) =>
    find.semantics.byLabel(RegExp(RegExp.escape(text)));

/// The 200 ms swap is under way: both pages are in the tree.
Future<void> _midSwap(WidgetTester tester, String outgoing) async {
  await tester.pump(); // the swap starts
  await tester.pump(const Duration(milliseconds: 80));
  expect(find.text(outgoing), findsOneWidget, reason: 'still fading out');
  expect(find.text(smsTitle), findsOneWidget, reason: 'fading in');
}

void main() {
  testWidgets('TC-005-32 outgoing screen is hidden and ignores back during '
      'the swap', (tester) async {
    final pops = recordSystemPops(tester);
    final semantics = tester.ensureSemantics();
    await pumpBudgetApp(tester, onboarded: false, size: kSmallPhone);

    // Slide 2, where the tour's own Back goes one slide back.
    await tapButton(tester, 'Next');
    expect(find.text(slideTitles[1]), findsOneWidget);
    await tester.pump(kDoubleTapTimeout);

    await tester.tap(find.text('Skip'));
    await _midSwap(tester, slideTitles[1]);

    // Screen readers see only the incoming SMS explainer.
    expect(_read(slideTitles[1]), findsNothing);
    expect(_read(smsTitle), findsOneWidget);
    // The outgoing tour takes no pointers and no focus.
    final tourButton = find.text('Next');
    expect(
      find.ancestor(
        of: tourButton,
        matching: find.byWidgetPredicate(
          (w) => w is IgnorePointer && w.ignoring,
        ),
      ),
      findsWidgets,
    );
    expect(
      find.ancestor(
        of: tourButton,
        matching: find.byWidgetPredicate(
          (w) => w is ExcludeFocus && w.excluding,
        ),
      ),
      findsWidgets,
    );

    // Back now is Back on the SMS explainer, a root: it leaves the app.
    // The fading tour does not go back to slide 1 and does not hold it.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(pops(), 1, reason: 'Back left the app');
    expect(find.text(smsTitle), findsOneWidget);
    expect(find.text(slideTitles[0]), findsNothing);
    expect(find.text(slideTitles[1]), findsNothing);

    // After the swap the SMS explainer is read as usual.
    expect(_read(smsTitle), findsOneWidget);
    semantics.dispose();
  });
}
