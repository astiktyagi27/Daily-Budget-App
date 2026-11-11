import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The F-002 accessibility checks for whatever is on screen: text contrast,
/// 48 dp tap targets, labelled tap targets, and the overflow check.
Future<void> expectAccessible(WidgetTester tester, {String? reason}) async {
  final semantics = tester.ensureSemantics();
  try {
    await expectLater(
      tester,
      meetsGuideline(textContrastGuideline),
      reason: reason,
    );
    await expectLater(
      tester,
      meetsGuideline(androidTapTargetGuideline),
      reason: reason,
    );
    await expectLater(
      tester,
      meetsGuideline(labeledTapTargetGuideline),
      reason: reason,
    );
  } finally {
    semantics.dispose();
  }
  expectNoOverflow(tester, reason: reason);
}

/// Test cases §0 "Overflow check": no exception (overflow errors are
/// reported as exceptions in tests) and no text cut off by `maxLines`.
void expectNoOverflow(WidgetTester tester, {String? reason}) {
  expect(tester.takeException(), isNull, reason: reason);
  final clipped = tester.allRenderObjects
      .whereType<RenderParagraph>()
      .where((p) => p.didExceedMaxLines)
      .map((p) => p.text.toPlainText());
  expect(clipped, isEmpty, reason: reason);
}
