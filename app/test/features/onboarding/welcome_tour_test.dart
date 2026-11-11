import 'package:daily_budget/core/help/first_time_hint.dart';
import 'package:daily_budget/core/help/nav_tooltip.dart';
import 'package:daily_budget/core/theme/budget_colors.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:daily_budget/features/onboarding/tour/page_indicator.dart';
import 'package:daily_budget/features/onboarding/tour/tour_slide.dart';
import 'package:daily_budget/features/onboarding/tour/tour_visuals.dart';
import 'package:daily_budget/features/shell/budget_navigation_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/shell.dart';
import '../../helpers/theme_cases.dart';
import 'onboarding_host.dart';

// Every expected string is a literal from F-005 §5 (house rule: never compare
// the app's copy with itself). − is U+2212.
const List<String> _bodies = [_body1, _body2, _body3, _body4];
const _body1 =
    'Daily Budget App turns your monthly money into one simple number: what '
    'you can spend today.';
const _body2 =
    'Salary ₹40,000 − rent ₹10,000 − EMI ₹5,000 − subscription ₹100 = '
    "₹24,900 to spend. Over a 30-day month, that's ₹830 a day.";
const _body3 =
    'Spend less than your daily budget and the rest goes into your savings '
    'pot. Overspent? You choose whether to cover it from savings.';
const _body4 =
    'Your bank SMS are read on this phone and never leave it. No login, and '
    'nothing is uploaded.';

const _figures = ['₹40,000', '₹10,000', '₹5,000', '₹100', '₹24,900', '₹830'];

/// The slide on screen, by its title (0-based).
int _slideOnScreen(WidgetTester tester) {
  final shown = [
    for (var i = 0; i < slideTitles.length; i++)
      if (find.text(slideTitles[i]).evaluate().isNotEmpty) i,
  ];
  expect(shown, hasLength(1), reason: 'exactly one slide title on screen');
  return shown.single;
}

String _indicatorLabel(WidgetTester tester) =>
    tester.getSemantics(find.byType(PageIndicator)).getSemanticsData().label;

/// Taps Next, then waits out the double-tap interval, so the next tap is
/// a new tap even with Remove animations on.
Future<void> _tapNext(WidgetTester tester) async {
  await tapButton(tester, 'Next');
  await tester.pump(kDoubleTapTimeout);
}

Future<void> _goToSlide(WidgetTester tester, int index) async {
  for (var i = 0; i < index; i++) {
    await _tapNext(tester);
  }
  expect(_slideOnScreen(tester), index);
}

void main() {
  testWidgets('TC-005-02 tour slides show exact copy and a visual', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpOnboarding(tester);
    for (var i = 0; i < 4; i++) {
      if (i > 0) await _tapNext(tester);
      expect(find.text(slideTitles[i]), findsOneWidget, reason: 'slide $i');
      expect(find.text(_bodies[i]), findsOneWidget, reason: 'slide $i');
      // The decorative card is there and adds nothing to semantics.
      final card = find.byType(TourVisualCard);
      expect(card, findsOneWidget, reason: 'slide $i visual');
      expect(
        find.descendant(
          of: find.descendant(
            of: card,
            matching: find.byType(ExcludeSemantics),
          ),
          matching: find.byType(BudgetCard),
        ),
        findsOneWidget,
        reason: 'slide $i visual is wrapped in ExcludeSemantics',
      );
      final cardTexts = tester
          .widgetList<Text>(
            find.descendant(of: card, matching: find.byType(Text)),
          )
          .map((t) => t.data!)
          .toList();
      expect(cardTexts, isNotEmpty, reason: 'slide $i visual has content');
      for (final text in cardTexts) {
        expect(
          find.bySemanticsLabel(text),
          findsNothing,
          reason: 'visual text "$text" must not be read',
        );
      }
      // The title is a heading.
      expect(
        tester.getSemantics(find.text(slideTitles[i])),
        isSemantics(isHeader: true, label: slideTitles[i]),
      );
    }
    semantics.dispose();
  });

  testWidgets('TC-005-03 tour moves forward and back with the right buttons', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    void expectButtonsFor(int slide) {
      final last = slide == 3;
      expect(find.text('Next'), last ? findsNothing : findsOneWidget);
      expect(find.text('Skip'), last ? findsNothing : findsOneWidget);
      expect(find.text('Get started'), last ? findsOneWidget : findsNothing);
    }

    // 1. Next ×3.
    await pumpOnboarding(tester);
    expect(_slideOnScreen(tester), 0);
    expect(_indicatorLabel(tester), 'Slide 1 of 4');
    expectButtonsFor(0);
    for (var i = 1; i < 4; i++) {
      await _tapNext(tester);
      expect(_slideOnScreen(tester), i);
      expect(_indicatorLabel(tester), 'Slide ${i + 1} of 4');
      expectButtonsFor(i);
    }

    // 2. From slide 1 again: swipe left ×3.
    await tester.pumpWidget(const SizedBox());
    await pumpOnboarding(tester);
    for (var i = 1; i < 4; i++) {
      await swipeTour(tester, forward: true);
      expect(_slideOnScreen(tester), i);
      expect(_indicatorLabel(tester), 'Slide ${i + 1} of 4');
      expectButtonsFor(i);
    }

    // 3. Swipe right on slide 4 → slide 3.
    await swipeTour(tester, forward: false);
    expect(_slideOnScreen(tester), 2);
    expect(_indicatorLabel(tester), 'Slide 3 of 4');

    // 4. Back to 4, then Android back → slide 3.
    await swipeTour(tester, forward: true);
    expect(_slideOnScreen(tester), 3);
    await pressBack(tester);
    expect(_slideOnScreen(tester), 2);
    expect(_indicatorLabel(tester), 'Slide 3 of 4');
    expectButtonsFor(2);

    // The current tick is the long one.
    final ticks = tester
        .renderObjectList<RenderBox>(
          find.descendant(
            of: find.byType(PageIndicator),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .map((box) => box.size.width)
        .toList();
    expect(ticks, [8, 8, 24, 8]);
    semantics.dispose();
  });

  testWidgets('TC-005-03 next and skip carry their tooltip and hint', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpOnboarding(tester);
    final tooltips = {
      for (final t in tester.widgetList<NavTooltip>(find.byType(NavTooltip)))
        t.message,
    };
    expect(tooltips, {
      'Go to the next slide',
      'Skip the tour and continue setup',
    });
    expect(
      tester.getSemantics(find.text('Next')),
      isSemantics(label: 'Next', hint: 'Go to the next slide', isButton: true),
    );
    expect(
      tester.getSemantics(find.text('Skip')),
      isSemantics(
        label: 'Skip',
        hint: 'Skip the tour and continue setup',
        isButton: true,
      ),
    );
    await _goToSlide(tester, 3);
    expect(
      tester.getSemantics(find.text('Get started')),
      isSemantics(
        label: 'Get started',
        hint: 'Finish the tour and continue setup',
        isButton: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('TC-005-04 get started reports the tour once (screen level)', (
    tester,
  ) async {
    final actions = await pumpOnboarding(tester);
    await _goToSlide(tester, 3);
    expect(actions.completeTourCalls, 0, reason: 'moving saves nothing');
    await tapButton(tester, 'Get started');
    expect(titled(smsTitle), findsOneWidget);
    expect(actions.completeTourCalls, 1);
    expect(actions.finishCalls, 0);
  });

  testWidgets(
    'TC-005-05 skip on any slide reports the tour once (screen level)',
    (tester) async {
      for (var slide = 0; slide < 3; slide++) {
        await tester.pumpWidget(const SizedBox());
        final actions = await pumpOnboarding(tester);
        await _goToSlide(tester, slide);
        await tapButton(tester, 'Skip');
        expect(titled(smsTitle), findsOneWidget, reason: 'skip on $slide');
        expect(find.byType(BudgetNavigationBar), findsNothing);
        expect(actions.completeTourCalls, 1, reason: 'skip on $slide');
        expect(actions.finishCalls, 0);
      }
    },
  );

  testWidgets('TC-005-06 back on the tour reports nothing (screen level)', (
    tester,
  ) async {
    final pops = recordSystemPops(tester);
    final actions = await pumpOnboarding(tester);
    await pressBack(tester);
    expect(pops(), 1, reason: 'back on slide 1 leaves the app');
    expect(tester.takeException(), isNull);
    expect(_slideOnScreen(tester), 0);
    expect(actions.completeTourCalls, 0);

    // Back on later slides goes one slide back and never leaves.
    await _goToSlide(tester, 2);
    await pressBack(tester);
    expect(_slideOnScreen(tester), 1);
    await pressBack(tester);
    expect(_slideOnScreen(tester), 0);
    expect(pops(), 1);
    expect(actions.completeTourCalls, 0);
  });

  testWidgets('TC-005-18 double tap advances exactly one screen', (
    tester,
  ) async {
    final pops = recordSystemPops(tester);
    // Two taps 50 ms apart on the same spot, whatever is there by then.
    Future<void> doubleTap(String label) async {
      final at = tester.getCenter(find.text(label));
      await tester.tapAt(at);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(at);
      await tester.pumpAndSettle();
    }

    for (final animationsOff in [false, true]) {
      final why = animationsOff ? 'remove animations' : 'animations on';
      // Next: one slide, then back to slide 1.
      await tester.pumpWidget(const SizedBox());
      var actions = await pumpOnboarding(
        tester,
        disableAnimations: animationsOff,
      );
      await doubleTap('Next');
      expect(_slideOnScreen(tester), 1, reason: why);
      await pressBack(tester);
      expect(_slideOnScreen(tester), 0, reason: why);

      // Next on slide 3 must not also press Get started.
      await _goToSlide(tester, 2);
      await doubleTap('Next');
      expect(_slideOnScreen(tester), 3, reason: why);
      expect(actions.completeTourCalls, 0, reason: why);

      // Get started: the SMS explainer once; back leaves the app.
      final popsBefore = pops();
      await tester.pump(kDoubleTapTimeout);
      await doubleTap('Get started');
      expect(titled(smsTitle), findsOneWidget, reason: why);
      expect(actions.completeTourCalls, 1, reason: why);
      await pressBack(tester);
      expect(pops(), popsBefore + 1, reason: why);

      // Skip: the SMS explainer once.
      await tester.pumpWidget(const SizedBox());
      actions = await pumpOnboarding(tester, disableAnimations: animationsOff);
      await doubleTap('Skip');
      expect(titled(smsTitle), findsOneWidget, reason: why);
      expect(actions.completeTourCalls, 1, reason: why);
      await pressBack(tester);
      expect(pops(), popsBefore + 2, reason: why);
    }
  });

  testWidgets('TC-005-23 swiping past the ends does nothing', (tester) async {
    final actions = await pumpOnboarding(tester);
    await swipeTour(tester, forward: false);
    expect(_slideOnScreen(tester), 0);
    await _goToSlide(tester, 3);
    await swipeTour(tester, forward: true);
    expect(_slideOnScreen(tester), 3);
    expect(titled(smsTitle), findsNothing);
    expect(actions.completeTourCalls, 0);
    // Clamping: no sideways glow or stretch that hints at more pages.
    bool horizontal(AxisDirection d) =>
        axisDirectionToAxis(d) == Axis.horizontal;
    expect(
      tester
          .widgetList<StretchingOverscrollIndicator>(
            find.byType(StretchingOverscrollIndicator),
          )
          .where((w) => horizontal(w.axisDirection)),
      isEmpty,
    );
    expect(
      tester
          .widgetList<GlowingOverscrollIndicator>(
            find.byType(GlowingOverscrollIndicator),
          )
          .where((w) => horizontal(w.axisDirection)),
      isEmpty,
    );
  });

  testWidgets('TC-005-24 swipe plus skip opens sms explainer once', (
    tester,
  ) async {
    final routes = RouteCounter();
    final actions = await pumpOnboarding(tester, routes: routes);
    final before = routes.count;
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Skip'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(titled(smsTitle), findsOneWidget);
    expect(actions.completeTourCalls, 1);
    // The gate swaps the root page; nothing is pushed.
    expect(routes.count, before);
  });

  testWidgets('TC-005-25 theme change keeps the current slide', (tester) async {
    await pumpOnboarding(tester, theme: ThemeCase.autoSystemLight);
    await _goToSlide(tester, 2);
    expect(pageBackground(tester), BudgetColors.light.bg.toARGB32());
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(_slideOnScreen(tester), 2);
    expect(_indicatorLabel(tester), 'Slide 3 of 4');
    expect(pageBackground(tester), BudgetColors.dark.bg.toARGB32());
    expect(pageBackground(tester), 0xFF0E0E12);
  });

  for (final size in [kSmallPhone, const Size(320, 640)]) {
    testWidgets('TC-005-26 slide 2 figures never split across lines '
        '(${size.width.toInt()} dp)', (tester) async {
      await pumpOnboarding(tester, size: size, textScale: 2);
      await _goToSlide(tester, 1);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(_bodies[1]),
      );
      final text = paragraph.text.toPlainText();
      final lineTops = paragraph
          .getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: text.length),
          )
          .map((box) => box.top)
          .toSet();
      expect(lineTops.length, greaterThan(1), reason: 'the body wraps');
      for (final figure in _figures) {
        var start = text.indexOf(figure);
        expect(start, isNonNegative, reason: figure);
        while (start >= 0) {
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(
              baseOffset: start,
              extentOffset: start + figure.length,
            ),
          );
          expect(
            boxes.map((box) => box.top).toSet(),
            hasLength(1),
            reason: '$figure at $start is on one line',
          );
          start = text.indexOf(figure, start + 1);
        }
      }
    });
  }

  testWidgets('TC-005-19 onboarding screens fit at text scale 2', (
    tester,
  ) async {
    await pumpOnboarding(tester, size: kSmallPhone, textScale: 2);
    for (var i = 0; i < 4; i++) {
      if (i > 0) await _tapNext(tester);
      expectNoOverflow(tester, reason: 'slide $i');
      // Scrolled to the end, the whole body is in view; the button stays
      // pinned.
      final slideScroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(TourSlide),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      slideScroll.position.jumpTo(slideScroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      final page = tester.getRect(find.byType(PageView));
      final body = tester.getRect(find.text(_bodies[i]));
      expect(body.bottom, lessThanOrEqualTo(page.bottom + 0.5));
      final button = find.text(i == 3 ? 'Get started' : 'Next');
      expect(button.hitTestable(), findsOneWidget, reason: 'slide $i');
      if (i < 3) {
        expect(find.text('Skip').hitTestable(), findsOneWidget);
      }
      // The visual card shrinks to at most 160 dp.
      expect(
        tester.getSize(find.byType(TourVisualCard)).height,
        lessThanOrEqualTo(160),
      );
    }
  });

  for (final theme in ThemeCase.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('TC-005-19 tour slides pass the accessibility checks '
          '(${theme.name}, $scale)', (tester) async {
        await pumpOnboarding(
          tester,
          theme: theme,
          size: kSmallPhone,
          textScale: scale,
        );
        for (var i = 0; i < 4; i++) {
          if (i > 0) await _tapNext(tester);
          await expectAccessible(tester, reason: 'slide $i');
          expect(pageBackground(tester), theme.colors.bg.toARGB32());
        }
      });
    }
  }

  testWidgets('TC-005-20 onboarding reading order is title body position '
      'buttons', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpOnboarding(tester);
    for (var i = 0; i < 4; i++) {
      if (i > 0) await _tapNext(tester);
      final read = tester.semantics
          .simulatedAccessibilityTraversal()
          .map((node) => node.getSemanticsData().label)
          .where((label) => label.isNotEmpty)
          .toList();
      expect(read, [
        slideTitles[i],
        _bodies[i],
        'Slide ${i + 1} of 4',
        if (i < 3) ...['Next', 'Skip'] else 'Get started',
      ], reason: 'slide $i');
    }
    semantics.dispose();
  });

  testWidgets('TC-005-01 onboarding screens show no bottom navigation', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    for (var i = 0; i < 4; i++) {
      if (i > 0) await _tapNext(tester);
      expect(find.byType(BudgetNavigationBar), findsNothing, reason: '$i');
      // No first-time hint during onboarding (F-004 AC-11).
      expect(find.byType(FirstTimeHint), findsNothing, reason: '$i');
    }
    await tapButton(tester, 'Get started');
    for (final (title, button) in [
      (smsTitle, 'Not now'),
      (notificationsTitle, 'Not now'),
      (disclaimerTitle, null),
    ]) {
      expect(titled(title), findsOneWidget);
      expect(find.byType(BudgetNavigationBar), findsNothing, reason: title);
      expect(find.byType(FirstTimeHint), findsNothing, reason: title);
      if (button != null) await tapButton(tester, button);
    }
  });
}
