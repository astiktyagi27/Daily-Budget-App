// F-015 TC-015-35 and TC-015-59: every state of the search, filter and
// category screens through the four themes, text scale 1 and 2, the small
// phone and landscape. Kept beside the other Transactions sweep; the shared
// Phase 3 sweep file is owned by the other tracks.

import 'package:daily_budget/core/widgets/category_chip.dart';
import 'package:daily_budget/core/widgets/filter_chip.dart';
import 'package:daily_budget/features/transactions/sheets/category_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/bundled_fonts.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/theme_cases.dart';
import '../../helpers/transactions_harness.dart';

const _sweepTimeout = Timeout(Duration(minutes: 15));

typedef _Open = Future<void> Function(
  WidgetTester tester,
  ThemeCase theme,
  double scale,
  Size size,
);

Future<void> _pump(
  WidgetTester tester,
  Phase3Fixture fixture,
  ThemeCase theme,
  double scale,
  Size size, {
  FakeMoneyStore? store,
  bool hintsSeen = true,
}) => pumpTransactions(
  tester,
  money: store ?? storeFor(fixture),
  clock: TestClock(fixture.now),
  theme: theme,
  textScale: scale,
  size: size,
  hintsSeen: hintsSeen,
);

/// Scrolls the tab down until [finder] is built and on screen (the Today
/// card is tall at large text, so the search is not always built).
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable).first;
  for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
    await tester.drag(scrollable, const Offset(0, -150));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _search(WidgetTester tester, String text) async {
  await _reveal(tester, find.byType(TextField));
  await tester.enterText(find.byType(TextField).first, text);
  await tester.pump(const Duration(milliseconds: 260));
  await tester.pumpAndSettle();
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await _reveal(tester, find.text(text));
  await tester.ensureVisible(find.text(text).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

Future<void> _pickRange(WidgetTester tester) async {
  await _tapText(tester, 'Dates: This month');
  await _tapText(tester, 'Custom range');
  await tester.pumpAndSettle();
  await tester.tap(find.text('1').last);
  await tester.pump();
  await tester.tap(find.text('13').last);
  await tester.pump();
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

final Map<String, _Open> _states = {
  'list with category chips': (t, th, s, z) => _pump(t, fixtureAF, th, s, z),
  'search with results': (t, th, s, z) async {
    await _pump(t, fixtureA, th, s, z);
    await _search(t, 'lunch');
  },
  'search with no results': (t, th, s, z) async {
    await _pump(t, fixtureA, th, s, z);
    await _search(t, 'taxi');
  },
  'filters active': (t, th, s, z) async {
    await _pump(t, fixtureAF, th, s, z);
    await _tapText(t, 'Category: All');
    await t.tap(
      find.descendant(
        of: find.byType(CategoryFilterSheet),
        matching: find.text('Food'),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Show'));
    await t.pumpAndSettle();
    await _tapText(t, 'Type: All');
    await t.tap(find.text('Spends'));
    await t.pumpAndSettle();
  },
  'results line with refunds': (t, th, s, z) async {
    await _pump(t, fixtureAPlusRefund, th, s, z);
    await _search(t, 'a');
  },
  'refunds only': (t, th, s, z) async {
    await _pump(t, fixtureAPlusRefund, th, s, z);
    await _tapText(t, 'Type: All');
    await t.tap(find.text('Refunds'));
    await t.pumpAndSettle();
  },
  'month separators': (t, th, s, z) async {
    await _pump(t, fixtureO1, th, s, z);
    await _pickRange(t);
  },
  'filtered day totals': (t, th, s, z) async {
    await _pump(t, fixtureA, th, s, z);
    await _search(t, 'lunch');
    await t.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await t.pumpAndSettle();
  },
  'dates sheet': (t, th, s, z) async {
    await _pump(t, fixtureO1, th, s, z);
    await _tapText(t, 'Dates: This month');
  },
  'category filter sheet': (t, th, s, z) async {
    await _pump(t, fixtureAF, th, s, z);
    await _tapText(t, 'Category: All');
  },
  'type sheet': (t, th, s, z) async {
    await _pump(t, fixtureAPlusRefund, th, s, z);
    await _tapText(t, 'Type: All');
  },
  'row category sheet': (t, th, s, z) async {
    await _pump(t, fixtureA, th, s, z);
    await _reveal(t, find.text('Other'));
    await t.tap(find.text('Other').first);
    await t.pumpAndSettle();
  },
  'editor with category row': (t, th, s, z) async {
    await _pump(t, fixtureA, th, s, z);
    await t.tap(addSpendButton);
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Category').first);
    await t.pumpAndSettle();
  },
  'editor category sheet': (t, th, s, z) async {
    await _pump(t, fixtureA, th, s, z);
    await t.tap(addSpendButton);
    await t.pumpAndSettle();
    final row = find.descendant(
      of: find.byType(InkWell),
      matching: find.text('Other'),
    );
    await t.ensureVisible(row.first);
    await t.pumpAndSettle();
    await t.tap(row.first);
    await t.pumpAndSettle();
  },
  'first time hint': (t, th, s, z) =>
      _pump(t, fixtureA, th, s, z, hintsSeen: false),
  'new month not set up': (t, th, s, z) =>
      _pump(t, fixtureA.copyWith(today: fixtureA.today.addDays(22)), th, s, z),
  'load error': (t, th, s, z) =>
      _pump(t, fixtureA, th, s, z, store: storeFor(fixtureA)..readFails = true),
};

void main() {
  setUpAll(loadBundledFonts);

  testWidgets(
    'TC-015-35 transactions search states pass the theme and text scale '
    'sweep',
    (tester) async {
      for (final MapEntry(key: name, value: open) in _states.entries) {
        for (final theme in ThemeCase.values) {
          for (final scale in [1.0, 2.0]) {
            final where = '$name, ${theme.name}, x$scale';
            await tester.pumpWidget(const SizedBox());
            await open(tester, theme, scale, kSmallPhone);
            await expectAccessible(tester, reason: where);
          }
        }
      }
    },
    timeout: _sweepTimeout,
  );

  testWidgets('TC-015-59 transactions search states survive landscape', (
    tester,
  ) async {
    for (final MapEntry(key: name, value: open) in _states.entries) {
      for (final theme in [ThemeCase.light, ThemeCase.dim]) {
        for (final scale in [1.0, 2.0]) {
          final where = '$name, ${theme.name}, x$scale, landscape';
          await tester.pumpWidget(const SizedBox());
          await open(tester, theme, scale, kSmallLandscape);
          expectNoOverflow(tester, reason: where);
        }
      }
    }
  }, timeout: _sweepTimeout);

  testWidgets('TC-015-35 filter chips and category chips are 48 dp targets', (
    tester,
  ) async {
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, fixtureAF, ThemeCase.light, scale, kSmallPhone);
      await _reveal(tester, find.byType(BudgetFilterChip));
      for (final chip in find.byType(BudgetFilterChip).evaluate()) {
        expect(
          tester.getSize(find.byWidget(chip.widget)).height,
          greaterThanOrEqualTo(48),
          reason: 'filter chip at x$scale',
        );
      }
      await _reveal(tester, find.byType(CategoryChip));
      expect(
        tester.getSize(find.byType(CategoryChip).first).height,
        greaterThanOrEqualTo(48),
        reason: 'category chip at x$scale',
      );
    }
  });
}
