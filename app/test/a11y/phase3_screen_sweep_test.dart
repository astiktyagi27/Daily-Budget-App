// The shared Phase 3 screen sweep (F-010 TC-010-40, F-011 TC-011-34, F-012
// TC-012-30, F-013 TC-013-28, F-014 TC-014-26, F-015 TC-015-35, F-017
// TC-017-25), skeleton of plan T-308. Each track adds its states to
// `P3Screen` and its sweep test here; `sweep` runs a list of states through
// the themes at text scale 1 and 2 on the small phone with the F-002 checks.

import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/budget/fixtures.dart';
import '../features/home/home_harness.dart';
import '../helpers/accessibility.dart';
import '../helpers/phase3_fixtures.dart';
import '../helpers/pump_app.dart';
import '../helpers/theme_cases.dart';
import '../support/find_copy.dart';
import '../support/p3_screens.dart';

/// The Home states of F-010 TC-010-40 that exist today (the calendar hint
/// state waits for `HintId.calendar`, F-011 T-325).
final Iterable<P3Screen> _homeStates = P3Screen.values.where(
  (screen) => screen.name.startsWith('home'),
);

/// Opens every state of [screens] in every theme at text scales 1 and 2 on
/// the small phone and runs the accessibility checks on each.
Future<void> sweep(WidgetTester tester, Iterable<P3Screen> screens) async {
  for (final screen in screens) {
    for (final theme in ThemeCase.values) {
      for (final scale in const [1.0, 2.0]) {
        await screen.open(
          tester,
          theme: theme,
          size: kSmallPhone,
          textScale: scale,
        );
        await expectAccessible(
          tester,
          reason: '${screen.description} / ${theme.name} / x$scale',
        );
      }
    }
  }
}

void main() {
  testWidgets('TC-010-40 p3 driver opens a Home state per fixture', (
    tester,
  ) async {
    final opened = await P3Screen.homeA13.open(tester, size: kSmallPhone);
    expect(opened.store.months, hasLength(1));
    expect(opened.heldRead, isNull);
    expect(find.byType(CustomScrollView), findsOneWidget);

    final none = await P3Screen.homeNoMonth.open(tester, size: kSmallPhone);
    expect(none.store.months, isEmpty);

    final failing = await P3Screen.homeLoadError.open(tester);
    expect(failing.store.readFails, isTrue);
  });

  testWidgets('TC-010-40 p3 driver holds the read of the loading state', (
    tester,
  ) async {
    final opened = await P3Screen.homeLoading.open(tester, size: kSmallPhone);
    expect(opened.heldRead, isNotNull);
    expect(opened.heldRead!.isCompleted, isFalse);
    expect(opened.store.readDelay, same(opened.heldRead));

    opened.heldRead!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-010-40 home states pass the theme and text scale sweep', (
    tester,
  ) async {
    await sweep(tester, _homeStates);
  });

  testWidgets('TC-008-62 home states are swept by the phase 3 sweep', (
    tester,
  ) async {
    // Same body as TC-010-40 on the states that replace the F-008 Home ones
    // (the month card, the shortfall line, the new-month notice), with the
    // ⋮ menu reached at X2.
    await sweep(tester, [
      P3Screen.homeA13,
      P3Screen.homeS8,
      P3Screen.homeNewMonthNotSetUp,
    ]);
    await P3Screen.homeA13.open(tester, size: kSmallPhone, textScale: 2);
    final more = find.byTooltip('More');
    expect(more, findsOneWidget);
    expect(tester.getSize(more).shortestSide, greaterThanOrEqualTo(48));
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.text('Edit this month'), findsOneWidget);
  });

  testWidgets('TC-010-40 home states survive landscape in Light and Dim', (
    tester,
  ) async {
    for (final screen in _homeStates) {
      for (final theme in [ThemeCase.light, ThemeCase.dim]) {
        for (final scale in const [1.0, 2.0]) {
          await screen.open(
            tester,
            theme: theme,
            size: kSmallLandscape,
            textScale: scale,
          );
          await expectAccessible(
            tester,
            reason: '${screen.description} / ${theme.name} / x$scale / land',
          );
        }
      }
    }
  });

  testWidgets('TC-017-25 safe to spend line passes the theme and text scale '
      'sweep', (tester) async {
    // A13, A14, F12, M20, S8 (nothing left), less than one rupee, ten crore.
    final fixtures = <Phase3Fixture>[
      a13,
      a14,
      f12,
      m20,
      s8,
      e2Last.plus(
        name: 'under a rupee',
        entries: [fixtureSpend(d(2026, 11, 5), 2489950)],
      ),
      customFixture(
        name: 'ten crore',
        today: d(2026, 11, 13),
        values: const FullMonthValues(salary: Paise(10000000000)),
      ),
    ];
    for (final fixture in fixtures) {
      for (final theme in ThemeCase.values) {
        for (final scale in const [1.0, 2.0]) {
          await tester.pumpWidget(const SizedBox());
          await openFixture(tester, fixture, theme: theme, textScale: scale);
          expect(findCopy('Safe to spend'), findsOneWidget);
          await expectAccessible(
            tester,
            reason: '${fixture.name} / ${theme.name} / x$scale',
          );
        }
      }
    }
    for (final theme in [ThemeCase.light, ThemeCase.dim]) {
      for (final scale in const [1.0, 2.0]) {
        await tester.pumpWidget(const SizedBox());
        await openFixture(
          tester,
          a13,
          theme: theme,
          size: kSmallLandscape,
          textScale: scale,
        );
        await expectAccessible(tester, reason: 'A13 / ${theme.name} / land');
      }
    }
  });
}
