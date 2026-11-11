import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/shell.dart';
import '../../helpers/theme_cases.dart';
import '../../support/p1_screens.dart';

// F-002 screen sweeps (T-138): every Phase 1 screen state (`P1Screen`, 18
// states through the real app) in every theme (T5), for AC-2 and AC-12 to
// AC-14. Titles are the Tester's, from tests/F-002-design-system-themes.md.

const _sweepTimeout = Timeout(Duration(minutes: 10));

/// The last thing on each screen, which the user must be able to reach.
Finder _lastElement(P1Screen screen) => switch (screen) {
  P1Screen.home ||
  P1Screen.homeWithHint => find.text(ScreenCopy.homeEmptyDescription),
  P1Screen.dashboard ||
  P1Screen.dashboardWithHint => find.text(ScreenCopy.dashboardEmptyDescription),
  P1Screen.transactions || P1Screen.transactionsWithHint => find.text(
    ScreenCopy.transactionsEmptyDescription,
  ),
  P1Screen.settings ||
  P1Screen.settingsEnd ||
  P1Screen.settingsWithHint => find.text('Disclaimer'),
  P1Screen.themePicker => find.text('Done'),
  P1Screen.themeExplanation => find.text('Got it'),
  P1Screen.slide1 || P1Screen.slide2 || P1Screen.slide3 => find.text('Next'),
  P1Screen.slide4 => find.text('Get started'),
  P1Screen.smsExplainer ||
  P1Screen.notificationsExplainer => find.text('Not now'),
  P1Screen.disclaimer => find.text('I understand'),
};

/// Scrolls to the screen's last element and checks a tap would land on it.
Future<void> _expectLastElementReachable(
  WidgetTester tester,
  P1Screen screen,
  String where,
) async {
  final last = _lastElement(screen);
  if (last.evaluate().isEmpty) {
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(last, 200, scrollable: scrollables.first);
    }
  }
  expect(last, findsOneWidget, reason: '$where: last element exists');
  await tester.ensureVisible(last);
  await tester.pumpAndSettle();
  // An element taller than the viewport (large text, landscape) is reached
  // by scrolling to the end of its scrollable.
  final scrollable = find.ancestor(of: last, matching: find.byType(Scrollable));
  final viewport = scrollable.evaluate().isEmpty
      ? Offset.zero & (tester.view.physicalSize / tester.view.devicePixelRatio)
      : tester.getRect(scrollable.first);
  if (tester.getRect(last).bottom > viewport.bottom + 0.5 &&
      scrollable.evaluate().isNotEmpty) {
    final position = tester.state<ScrollableState>(scrollable.first).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
  }
  final rect = tester.getRect(last);
  expect(
    rect.bottom,
    lessThanOrEqualTo(viewport.bottom + 0.5),
    reason: '$where: the end of the last element is on screen',
  );
  final visible = rect.intersect(viewport);
  expect(visible.isEmpty, isFalse, reason: '$where: last element visible');
  final hit = tester.hitTestOnBinding(visible.center);
  final target = last.evaluate().single.renderObject;
  expect(
    hit.path.any((entry) => entry.target == target),
    isTrue,
    reason: '$where: a tap lands on the last element',
  );
}

/// Bottom-nav labels follow app-shell §3.2: scale capped at 1.3×, one line.
void _expectNavLabelsCapped(WidgetTester tester, String where) {
  for (final label in const ['Home', 'Dashboard', 'Transactions', 'Settings']) {
    final text = tester.widget<Text>(
      find.descendant(of: navBar, matching: find.text(label)),
    );
    expect(text.maxLines, 1, reason: '$where: $label on one line');
    expect(
      text.textScaler!.scale(12),
      lessThanOrEqualTo(12 * 1.3 + 0.01),
      reason: '$where: $label scale capped at 1.3',
    );
  }
}

Future<void> _expectGuidelines(
  WidgetTester tester,
  List<AccessibilityGuideline> guidelines,
  String where,
) async {
  final semantics = tester.ensureSemantics();
  try {
    for (final guideline in guidelines) {
      await expectLater(tester, meetsGuideline(guideline), reason: where);
    }
  } finally {
    semantics.dispose();
  }
}

/// Every font family drawn by text on screen, with an example of its text.
/// Icon glyphs (Material Icons) are not text and are skipped.
Map<String, String> _fontFamiliesOnScreen(WidgetTester tester) {
  final found = <String, String>{};
  for (final paragraph
      in tester.allRenderObjects.whereType<RenderParagraph>()) {
    void visit(InlineSpan span, String? inherited) {
      final family = span.style?.fontFamily ?? inherited;
      if (span is TextSpan) {
        final text = span.text;
        if (text != null && text.isNotEmpty && family != 'MaterialIcons') {
          found.putIfAbsent(family ?? 'none (default)', () => text);
        }
        for (final child in span.children ?? const <InlineSpan>[]) {
          visit(child, family);
        }
      }
    }

    visit(paragraph.text, null);
  }
  return found;
}

void main() {
  testWidgets('TC-002-03 every phase 1 screen renders in every theme', (
    tester,
  ) async {
    for (final screen in P1Screen.values) {
      for (final theme in ThemeCase.values) {
        final where = '${screen.description} / ${theme.name}';
        await screen.open(tester, theme: theme);
        expect(tester.takeException(), isNull, reason: where);
        expect(
          pageBackground(tester),
          theme.colors.bg.toARGB32(),
          reason: '$where: page background',
        );
        if (screen.isSheet) {
          expect(
            sheetDecoration(tester).color,
            theme.colors.surface,
            reason: '$where: sheet fill',
          );
        }
      }
    }
  }, timeout: _sweepTimeout);

  testWidgets('TC-002-22 every phase 1 screen meets text contrast guideline', (
    tester,
  ) async {
    for (final screen in P1Screen.values) {
      for (final theme in ThemeCase.values) {
        await screen.open(tester, theme: theme);
        await _expectGuidelines(tester, [
          textContrastGuideline,
        ], '${screen.description} / ${theme.name}');
      }
    }
  }, timeout: _sweepTimeout);

  testWidgets('TC-002-23 every phase 1 screen meets tap target guidelines', (
    tester,
  ) async {
    for (final screen in P1Screen.values) {
      for (final theme in ThemeCase.values) {
        for (final (scale, size) in <(double, Size?)>[
          (1, null),
          (2, kSmallPhone),
        ]) {
          await screen.open(tester, theme: theme, size: size, textScale: scale);
          await _expectGuidelines(tester, [
            androidTapTargetGuideline,
            labeledTapTargetGuideline,
          ], '${screen.description} / ${theme.name} / X$scale');
        }
      }
    }
  }, timeout: _sweepTimeout);

  testWidgets(
    'TC-002-24 every phase 1 screen fits at text scale 2 on a small phone',
    (tester) async {
      for (final screen in P1Screen.values) {
        for (final theme in ThemeCase.values) {
          final where = '${screen.description} / ${theme.name}';
          await screen.open(
            tester,
            theme: theme,
            size: kSmallPhone,
            textScale: 2,
          );
          expectNoOverflow(tester, reason: where);
          if (!screen.isOnboarding) _expectNavLabelsCapped(tester, where);
          await _expectLastElementReachable(tester, screen, where);
          expectNoOverflow(tester, reason: '$where: after scrolling');
        }
      }
    },
    timeout: _sweepTimeout,
  );

  testWidgets('TC-002-38 phase 1 screens survive a 320 dp wide screen', (
    tester,
  ) async {
    for (final screen in P1Screen.values) {
      for (final theme in ThemeCase.values) {
        final where = '${screen.description} / ${theme.name}';
        await screen.open(tester, theme: theme, size: kNarrowPhone);
        expectNoOverflow(tester, reason: '$where / X1');
        await screen.open(
          tester,
          theme: theme,
          size: kNarrowShortPhone,
          textScale: 2,
        );
        expect(tester.takeException(), isNull, reason: '$where / X2');
        await _expectLastElementReachable(tester, screen, '$where / X2');
      }
    }
  }, timeout: _sweepTimeout);

  testWidgets('TC-002-39 phase 1 screens survive landscape on a small phone', (
    tester,
  ) async {
    for (final screen in P1Screen.values) {
      for (final theme in [ThemeCase.light, ThemeCase.dim]) {
        final where = '${screen.description} / ${theme.name}';
        await screen.open(tester, theme: theme, size: kSmallLandscape);
        expectNoOverflow(tester, reason: '$where / X1');
        await screen.open(
          tester,
          theme: theme,
          size: kSmallLandscape,
          textScale: 2,
        );
        expect(tester.takeException(), isNull, reason: '$where / X2');
        await _expectLastElementReachable(tester, screen, '$where / X2');
      }
    }
  }, timeout: _sweepTimeout);

  testWidgets('TC-002-40 bold text setting does not break layouts', (
    tester,
  ) async {
    for (final screen in P1Screen.values) {
      for (final theme in [ThemeCase.light, ThemeCase.dim]) {
        for (final scale in [1.0, 2.0]) {
          await screen.open(
            tester,
            theme: theme,
            size: kSmallPhone,
            textScale: scale,
            boldText: true,
            highContrast: true,
          );
          expectNoOverflow(
            tester,
            reason: '${screen.description} / ${theme.name} / X$scale',
          );
        }
      }
    }
  }, timeout: _sweepTimeout);

  testWidgets('TC-002-29 every screen uses the bundled font families', (
    tester,
  ) async {
    for (final screen in P1Screen.values) {
      for (final theme in ThemeCase.values) {
        await screen.open(tester, theme: theme);
        final families = _fontFamiliesOnScreen(tester);
        expect(families, isNotEmpty, reason: '${screen.description} has text');
        expect(
          families.keys.toSet().difference({kFontHeading, kFontBody}),
          isEmpty,
          reason:
              '${screen.description} / ${theme.name}: only Bricolage Grotesque '
              'and IBM Plex Sans; found $families',
        );
      }
    }
  }, timeout: _sweepTimeout);
}
