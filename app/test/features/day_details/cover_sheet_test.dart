import 'dart:io';

import 'package:daily_budget/data/repositories/savings_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/bundled_fonts.dart';
import '../../helpers/day_details_harness.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/fake_savings_repository.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../support/find_copy.dart';

// F-012 §2.3, design §6: the cover sheet (pre-fill, caption, errors).

Finder get _coverButton => find.text('Cover with savings');
Finder get _field => find.byType(TextField);

String _fieldText(WidgetTester tester) =>
    tester.widget<TextField>(_field).controller!.text;

Future<void> _openSheet(WidgetTester tester) async {
  await tester.ensureVisible(_coverButton);
  await tester.pumpAndSettle();
  await tester.tap(_coverButton);
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(_field, text);
  await tester.pump();
}

Future<void> _tapCover(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.tap(find.text('Cover'));
  await tester.pumpAndSettle();
}

List<Cover> _covers(FakeMoneyStore store) =>
    store.coversByMonth[store.months.last.id] ?? <Cover>[];

/// Counts the cover writes that reach the repository.
final class _CountingSavings implements SavingsRepository {
  new(this.inner);

  final SavingsRepository inner;
  int coverCalls = 0;

  /// Answers like the engine refusing at the last moment (the month moved).
  bool refuse = false;

  @override
  Stream<List<Cover>> watchCovers(int monthId) => inner.watchCovers(monthId);

  @override
  Future<CoverResult> cover(
    int monthId,
    CalendarDate day,
    Paise amount, {
    required CalendarDate today,
    required int now,
  }) async {
    coverCalls++;
    if (refuse) {
      return (
        decision: const CoverRefused(CoverRefusal.exceedsPot),
        coverId: null,
      );
    }
    // A slow write, so the second tap lands while the first is in flight.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return await inner.cover(monthId, day, amount, today: today, now: now);
  }

  @override
  Future<void> removeCovers(int monthId, Set<int> coverIds) =>
      inner.removeCovers(monthId, coverIds);
}

void main() {
  setUpAll(loadBundledFonts);

  testWidgets('TC-012-12 invalid cover amounts show their message and store '
      'nothing', (tester) async {
    final cases = <(Phase3Fixture, String, String)>[
      (p250, '', 'Enter an amount more than ₹0'),
      (p250, '0', 'Enter an amount more than ₹0'),
      (p250, '260', "That's more than your savings pot (₹250)."),
      (a13, '300.01', "That's more than this day's overspend (₹300)."),
      (p250, '12.345', 'Use numbers only, with up to 2 decimals'),
      (p250, 'abc', 'Use numbers only, with up to 2 decimals'),
    ];
    for (final (fixture, text, message) in cases) {
      await tester.pumpWidget(const SizedBox());
      final opened = await openDay(tester, fixture, nov(11));
      await _openSheet(tester);
      await _type(tester, text);
      await _tapCover(tester);
      expect(findCopy(message), findsOneWidget, reason: '"$text"');
      expect(find.text('Cancel'), findsOneWidget, reason: 'still open');
      expect(_covers(opened.store), isEmpty, reason: '"$text"');
    }
  });

  testWidgets('TC-012-13 overspend message comes before the pot message', (
    tester,
  ) async {
    await openDay(tester, p250, nov(11));
    await _openSheet(tester);
    await _type(tester, '400');
    await _tapCover(tester);
    expect(
      findCopy("That's more than this day's overspend (₹300)."),
      findsOneWidget,
    );
    expect(find.textContaining('savings pot (₹250)'), findsNothing);
    // Once shown the error is checked again as the user types.
    await _type(tester, '260');
    expect(
      findCopy("That's more than your savings pot (₹250)."),
      findsOneWidget,
    );
    await _type(tester, '100');
    expect(find.textContaining("That's more than"), findsNothing);
  });

  testWidgets('TC-012-14 cover pre-fills the exact paise and brings the day to '
      'zero', (tester) async {
    final m20x = m20.mapEntries(
      'M20-18',
      (e) => e.date == nov(18) ? e.copyWith(paise: 60000) : e,
    );
    final opened = await openDay(tester, m20x, nov(18));
    await _openSheet(tester);
    expect(findCopy('Overspent ₹47 · Savings pot ₹1,813'), findsOneWidget);
    expect(_fieldText(tester), '47.78');
    expect(find.text('This covers the whole overspend.'), findsOneWidget);
    await _tapCover(tester);
    expect(_covers(opened.store).last.amount, const Paise(4778));
    expect(find.text('○ On budget'), findsWidgets);
  });

  testWidgets('TC-012-16 double tap on cover stores one move', (tester) async {
    final store = storeFor(a13);
    final counting = _CountingSavings(FakeSavingsRepository(store));
    final opened = await openDay(
      tester,
      a13,
      nov(11),
      store: store,
      savings: counting,
    );
    await _openSheet(tester);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final button = find.text('Cover');
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 20));
    await tester.tap(button, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(counting.coverCalls, 1, reason: 'the second tap does nothing');
    expect(_covers(opened.store), hasLength(1));
    expect(find.text('₹300 covered from your savings'), findsOneWidget);
  });

  testWidgets('TC-012-17 failed cover keeps the sheet open', (tester) async {
    final opened = await openDay(tester, a13, nov(11));
    await _openSheet(tester);
    await _type(tester, '150');
    opened.store.failNextWrite = true;
    await _tapCover(tester);
    expect(find.text("Couldn't save. Please try again."), findsOneWidget);
    expect(_fieldText(tester), '150');
    expect(_covers(opened.store), isEmpty);
    expect(find.text('Cancel'), findsOneWidget);
    // The day behind is unchanged.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('◆ Overspent ₹300'), findsWidgets);
  });

  testWidgets('TC-012-33 keyboard never hides the cover field or button', (
    tester,
  ) async {
    for (final size in [const Size(360, 640), const Size(640, 360)]) {
      await tester.pumpWidget(const SizedBox());
      await openDay(tester, p250, nov(11), textScale: 2, size: size);
      await _openSheet(tester);
      final keyboard = size.height > size.width ? 300.0 : 160.0;
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 3);
      addTearDown(tester.view.resetViewInsets);
      // Focusing the field scrolls it into view, above the pinned Cover.
      await tester.showKeyboard(_field);
      await tester.pumpAndSettle();
      final visibleBottom = size.height - keyboard;
      expect(
        tester.getRect(_field).bottom,
        lessThanOrEqualTo(visibleBottom + 0.5),
        reason: 'field at $size',
      );
      expect(tester.getRect(_field).top, greaterThanOrEqualTo(0));
      final cover = tester.getRect(find.text('Cover'));
      expect(cover.bottom, lessThanOrEqualTo(visibleBottom + 0.5));
      expect(cover.top, greaterThanOrEqualTo(0));
      tester.view.resetViewInsets();
    }
  });

  testWidgets('TC-012-45 a stale cover amount is refused with the matching '
      'message', (tester) async {
    final opened = await openDay(tester, a13, nov(11));
    await _openSheet(tester);
    expect(_fieldText(tester), '300');
    // The pot falls to ₹250 while the sheet is open.
    final replacement = storeFor(p250);
    final month = opened.store.months.last.id;
    opened.store.spendsByMonth[month] =
        replacement.spendsByMonth[replacement.months.last.id]!;
    opened.store.notify();
    await tester.pumpAndSettle();
    await _tapCover(tester);
    expect(
      findCopy("That's more than your savings pot (₹250)."),
      findsOneWidget,
    );
    expect(_covers(opened.store), isEmpty);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('TC-012-45 a cover the engine refuses after all keeps the sheet '
      'open', (tester) async {
    final store = storeFor(a13);
    final refusing = _CountingSavings(FakeSavingsRepository(store))
      ..refuse = true;
    await openDay(tester, a13, nov(11), store: store, savings: refusing);
    await _openSheet(tester);
    await _tapCover(tester);
    expect(refusing.coverCalls, 1);
    expect(find.text('Cancel'), findsOneWidget, reason: 'the sheet stays');
    expect(find.textContaining('covered from your savings'), findsNothing);
    expect(_covers(store), isEmpty);
    // Cover can be tapped again: the button is not stuck loading.
    await _tapCover(tester);
    expect(refusing.coverCalls, 2);
  });

  testWidgets('TC-012-47 less than one rupee overspend can be covered to the '
      'paisa', (tester) async {
    final tiny = a13.plus(
      name: 'A+40',
      entries: [fixtureSpend(nov(12), 83040)],
    );
    final opened = await openDay(tester, tiny, nov(12));
    expect(find.text('◆ Overspent less than ₹1'), findsWidgets);
    await _openSheet(tester);
    expect(
      findCopy('Overspent less than ₹1 · Savings pot ₹1,170'),
      findsOneWidget,
    );
    expect(_fieldText(tester), '0.40');
    await _tapCover(tester);
    expect(_covers(opened.store).single.amount, const Paise(40));
    expect(find.text('○ On budget'), findsWidgets);
  });

  testWidgets('TC-012-72 sheet line reads the under one rupee flag at 99 and '
      '100 paise', (tester) async {
    Future<void> sheetFor(int paise) async {
      await tester.pumpWidget(const SizedBox());
      final f = a13.plus(
        name: 'A+$paise',
        entries: [fixtureSpend(nov(12), 83000 + paise)],
      );
      await openDay(tester, f, nov(12));
      await _openSheet(tester);
    }

    await sheetFor(99);
    expect(
      findCopy('Overspent less than ₹1 · Savings pot ₹1,170'),
      findsOneWidget,
    );
    await sheetFor(100);
    expect(findCopy('Overspent ₹1 · Savings pot ₹1,170'), findsOneWidget);
    expect(find.textContaining('less than'), findsNothing);
    // No widget compares the overspend with 100: the sheet reads the flag.
    final source = File('lib/features/day_details/widgets/cover_sheet.dart')
        .readAsStringSync();
    expect(source, isNot(matches(RegExp(r'<\s*100'))));
    expect(source, contains('overspendUnderRupee'));
  });

  testWidgets('TC-012-54 closing the cover sheet cancels', (tester) async {
    final opened = await openDay(tester, a13, nov(11));
    // Cancel.
    await _openSheet(tester);
    await _type(tester, '100');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Cover Wed, 11 Nov'), findsNothing);
    // Back.
    await _openSheet(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Cover Wed, 11 Nov'), findsNothing);
    // Swipe down.
    await _openSheet(tester);
    await tester.fling(
      find.text('Cover Wed, 11 Nov'),
      const Offset(0, 400),
      2000,
    );
    await tester.pumpAndSettle();
    expect(find.text('Cover Wed, 11 Nov'), findsNothing);
    expect(_covers(opened.store), isEmpty);
    await _openSheet(tester);
    expect(_fieldText(tester), '300');
  });
}
