import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

// The pure rules behind the month setup screen (plan F-008 §1.2): the draft,
// its validation order, pre-fill, "changed" and the preview. The widget
// cases of the same IDs run in T-215.

final CalendarDate _nov5 = d(2026, 11, 5);

/// The E2 entry on a first setup: salary day 5, salary 40000, Rent 10000,
/// EMI 5000, Subscriptions 100.
SetupDraft _e2Draft({CalendarDate? today}) {
  var draft = SetupDraft.firstSetup(
    today: today ?? _nov5,
    salaryDay: 5,
  ).copyWith(salaryText: '40000');
  final costs = ['10000', '5000', '100'];
  for (final (i, text) in costs.indexed) {
    draft = draft.setItemAmount(i, text);
  }
  return draft;
}

PreviewReady _ready(SetupPreview preview) {
  expect(preview, isA<PreviewReady>());
  return preview as PreviewReady;
}

/// The day budgets of [ready] as (count, paise) runs, e.g. E1.
List<(int, int)> _runs(PreviewReady ready) {
  final out = <(int, int)>[];
  for (final budget in ready.outcome.budgets) {
    if (out.isNotEmpty && out.last.$2 == budget.value) {
      out[out.length - 1] = (out.last.$1 + 1, budget.value);
    } else {
      out.add((1, budget.value));
    }
  }
  return out;
}

List<Paise> _past(CalendarDate today) => [
  for (final b in budgetsOf(e2Month(today: today), _nov5, today.addDays(-1)))
    b!,
];

void main() {
  test('TC-008-04 a first setup starts with the three suggested items', () {
    final draft = SetupDraft.firstSetup(today: _nov5);
    expect(draft.kind, SetupKind.full);
    expect(draft.salaryDay, isNull);
    expect(
      [for (final item in draft.items) (item.name, item.amountText)],
      [('Rent', ''), ('EMI', ''), ('Subscriptions', '')],
    );
    expect(draft.targetOn, isFalse);
    expect(draft.totalFixedCosts, Paise.zero);
    expect(draft.stillToPay, isEmpty);
    expect(draft.preview(today: _nov5), isA<PreviewNeedsSalaryDay>());
  });

  test('TC-008-05 validate lists the salary problems and the day first', () {
    List<FieldProblem> salaryProblems(String text) => [
      for (final error in _e2Draft().copyWith(salaryText: text).validate())
        error.problem,
    ];
    expect(salaryProblems(''), [FieldProblem.missing]);
    expect(salaryProblems('0'), [FieldProblem.notPositive]);
    expect(salaryProblems('100000001'), [FieldProblem.tooLarge]);
    expect(salaryProblems('12.345'), [FieldProblem.badFormat]);
    expect(salaryProblems('abc'), [FieldProblem.badFormat]);
    expect(salaryProblems('99.50'), isEmpty);

    // Screen order: salary day, salary, target, then each item's name and
    // amount.
    final empty = SetupDraft.firstSetup(today: _nov5).copyWith(targetOn: true);
    final errors = empty.setItemAmount(0, 'x').renameItem(1, ' ').validate();
    expect(
      [for (final e in errors) (e.field, e.problem, e.itemKey)],
      [
        (FieldId.salaryDay, FieldProblem.missing, null),
        (FieldId.salary, FieldProblem.missing, null),
        (FieldId.target, FieldProblem.missing, null),
        (FieldId.itemAmount, FieldProblem.badFormat, 0),
        (FieldId.itemName, FieldProblem.missing, 1),
      ],
    );
  });

  test('TC-008-06 valid salaries are stored exactly', () {
    for (final (text, paise) in [
      ('40000', 4000000),
      ('100000000', 10000000000),
      ('99.50', 9950),
    ]) {
      final draft = _e2Draft().copyWith(salaryText: text);
      expect(draft.validate(), isEmpty, reason: text);
      final values = draft.toPeriodValues() as FullMonthValues;
      expect(values.salary, p(paise), reason: text);
      expect(values.target, isNull);
    }
    // Shown outside the field as whole rupees by the formatter (T-212b);
    // here the exact paise are the draft's output.
    final ready = _ready(
      _e2Draft().copyWith(salaryText: '99.50').preview(today: _nov5),
    );
    expect(ready.baseAmount, p(9950));
  });

  test('TC-008-06 a draft with problems is never turned into values', () {
    expect(
      () => _e2Draft().copyWith(salaryText: '').toPeriodValues(),
      throwsStateError,
    );
  });

  test('TC-008-07 the spending target rules', () {
    final base = _e2Draft().copyWith(salaryText: '40000', targetOn: true);
    FieldProblem? target(String text) {
      final errors = base.copyWith(targetText: text).validate();
      return errors.isEmpty ? null : errors.single.problem;
    }

    expect(target(''), FieldProblem.missing);
    expect(target('40000.01'), FieldProblem.aboveSalary);
    expect(target('100000001'), FieldProblem.aboveSalary);
    expect(target('9' * 40), FieldProblem.aboveSalary);
    expect(target('0'), FieldProblem.notPositive);
    expect(target('abc'), FieldProblem.badFormat);
    expect(target('20000'), isNull);

    final on = base.copyWith(targetText: '20000');
    final noCosts = on
        .setItemAmount(0, '')
        .setItemAmount(1, '')
        .setItemAmount(2, '');
    final ready = _ready(noCosts.preview(today: _nov5));
    expect(ready.basis, PreviewBasis.target);
    expect((ready.baseAmount, ready.spendable), (p(2000000), p(2000000)));
    expect(ready.dailyBudget, p(66667));
    // Switching off removes the target again.
    final off = noCosts.copyWith(targetOn: false);
    expect((off.toPeriodValues() as FullMonthValues).target, isNull);
    expect(_ready(off.preview(today: _nov5)).dailyBudget, p(133334));
    // A target above an empty or bad salary is not compared.
    final noSalary = on.copyWith(salaryText: '', targetText: '999999999');
    expect(
      [for (final e in noSalary.validate()) e.field],
      [FieldId.salary, FieldId.target],
    );
    expect(
      [for (final e in noSalary.validate()) e.problem].last,
      FieldProblem.tooLarge,
    );
  });

  test('TC-008-36 a target equal to the salary is accepted', () {
    final draft = _e2Draft().copyWith(targetOn: true, targetText: '40000');
    expect(draft.validate(), isEmpty);
    final ready = _ready(draft.preview(today: _nov5));
    expect(ready.dailyBudget, p(83000));
    expect(ready.spendable, p(2490000));
  });

  test('TC-008-08 items are added edited deleted and restored in place', () {
    var draft = _e2Draft();
    expect(draft.totalFixedCosts, p(1510000));

    draft = draft.addItem();
    expect(draft.items, hasLength(4));
    expect(draft.items.last.key, 3);
    expect(draft.items.last.name, isEmpty);

    draft = draft.renameItem(3, 'Gym').setItemAmount(3, '1500');
    expect(draft.totalFixedCosts, p(1660000));
    draft = draft.setItemAmount(1, '7000');
    expect(draft.totalFixedCosts, p(1860000));

    final emi = draft.items[1];
    final index = draft.indexOfItem(1);
    draft = draft.removeItem(1);
    expect(draft.items.map((i) => i.name), ['Rent', 'Subscriptions', 'Gym']);
    expect(draft.indexOfItem(1), -1);
    draft = draft.insertItem(index, emi);
    expect(draft.items.map((i) => i.name), [
      'Rent',
      'EMI',
      'Subscriptions',
      'Gym',
    ]);
    expect(draft.totalFixedCosts, p(1860000));

    // A new item after the delete gets a fresh key, never a reused one.
    expect(draft.removeItem(3).addItem().items.last.key, 4);

    final blank = draft.renameItem(0, '  ').validate();
    expect(
      [for (final e in blank) (e.field, e.problem, e.itemKey)],
      [(FieldId.itemName, FieldProblem.missing, 0)],
    );
  });

  test('TC-008-09 at most 30 items', () {
    var draft = _e2Draft();
    while (draft.canAddItem) {
      draft = draft.addItem();
    }
    expect(draft.items, hasLength(30));
    expect(() => draft.addItem(), throwsStateError);
    expect(
      () => draft.insertItem(0, const DraftItem(key: 99)),
      throwsStateError,
    );
    final fewer = draft.removeItem(0);
    expect(fewer.canAddItem, isTrue);
    expect(fewer.insertItem(0, draft.items.first).items, hasLength(30));
  });

  test('TC-008-10 the README examples show the engine day budgets', () {
    final rows = <(SetupDraft, int, int, List<(int, int)>)>[
      // salary only: 10 days of 1,33,334 then 20 of 1,33,333
      (
        _e2Draft()
            .setItemAmount(0, '')
            .setItemAmount(1, '')
            .setItemAmount(2, ''),
        4000000,
        0,
        [(10, 133334), (20, 133333)],
      ),
      (_e2Draft(), 2490000, 1510000, [(30, 83000)]),
      (
        _e2Draft()
            .copyWith(targetOn: true, targetText: '20000')
            .setItemAmount(0, '')
            .setItemAmount(1, '')
            .setItemAmount(2, ''),
        2000000,
        0,
        [(20, 66667), (10, 66666)],
      ),
      (
        _e2Draft().copyWith(targetOn: true, targetText: '20000'),
        490000,
        1510000,
        [(10, 16334), (20, 16333)],
      ),
    ];
    for (final (i, (draft, spendable, fixed, runs)) in rows.indexed) {
      final ready = _ready(draft.preview(today: _nov5));
      expect(ready.month.start, _nov5, reason: 'row ${i + 1}');
      expect(ready.month.end, d(2026, 12, 4), reason: 'row ${i + 1}');
      expect(ready.days, 30);
      expect(ready.spendable, p(spendable), reason: 'row ${i + 1}');
      expect(ready.fixedCosts, p(fixed), reason: 'row ${i + 1}');
      expect(_runs(ready), runs, reason: 'row ${i + 1}');
      expect(ready.outcome, isA<Spread>());
      expect(ready.shortfall, Paise.zero);
    }
    // The shown daily budget is the largest of the spread, rounded down by
    // the formatter later: 1,33,334 → ₹1,333; 16,334 → ₹163.
    expect(
      _ready(_e2Draft().preview(today: _nov5)).dailyBudget.value ~/ 100,
      830,
    );
  });

  test('TC-008-10 an empty salary or target gives no daily budget', () {
    expect(
      _e2Draft().copyWith(salaryText: '').preview(today: _nov5),
      isA<PreviewNeedsAmount>(),
    );
    expect(
      _e2Draft().copyWith(salaryText: 'abc').preview(today: _nov5),
      isA<PreviewNeedsAmount>(),
    );
    expect(
      _e2Draft().copyWith(targetOn: true).preview(today: _nov5),
      isA<PreviewNeedsAmount>(),
    );
    expect(
      _e2Draft()
          .copyWith(targetOn: true, targetText: '50000')
          .preview(today: _nov5),
      isA<PreviewNeedsAmount>(),
    );
    // A bad or empty fixed-cost amount counts as ₹0 in the preview.
    final ready = _ready(
      _e2Draft().setItemAmount(0, 'x').preview(today: _nov5),
    );
    expect(ready.fixedCosts, p(510000));
  });

  test('TC-008-12 fixed costs above the salary are a shortfall', () {
    final s1 = SetupDraft.firstSetup(today: _nov5, salaryDay: 5)
        .copyWith(salaryText: '20000')
        .setItemAmount(0, '15000')
        .setItemAmount(1, '6000');
    final ready = _ready(s1.preview(today: _nov5));
    expect(ready.outcome, isA<Shortfall>());
    expect(ready.shortfall, p(100000));
    expect(ready.dailyBudget, Paise.zero);
    expect(ready.spendable, p(-100000));
    expect((ready.baseAmount, ready.fixedCosts), (p(2000000), p(2100000)));
    expect(ready.basis, PreviewBasis.salary);
    // The draft itself is valid: the shortfall is the user's choice.
    expect(s1.validate(), isEmpty);
  });

  test('TC-008-13 the shortfall names the target and the equal case', () {
    final target = SetupDraft.firstSetup(today: _nov5, salaryDay: 5)
        .copyWith(salaryText: '20000', targetOn: true, targetText: '19000')
        .setItemAmount(0, '21000');
    final a = _ready(target.preview(today: _nov5));
    expect((a.basis, a.shortfall), (PreviewBasis.target, p(200000)));

    final equal = SetupDraft.firstSetup(today: _nov5, salaryDay: 5)
        .copyWith(salaryText: '20000')
        .setItemAmount(0, '15000')
        .setItemAmount(1, '5000');
    final b = _ready(equal.preview(today: _nov5));
    expect(b.outcome, isA<ZeroSpendable>());
    expect(
      (b.shortfall, b.dailyBudget, b.spendable),
      (Paise.zero, Paise.zero, Paise.zero),
    );
  });

  test('TC-008-33 thirty items of ten crore do not overflow', () {
    var draft = SetupDraft.firstSetup(
      today: _nov5,
      salaryDay: 5,
    ).copyWith(salaryText: '100000000');
    while (draft.canAddItem) {
      draft = draft.addItem();
    }
    for (final item in draft.items) {
      draft = draft
          .renameItem(item.key, 'Cost ${item.key}')
          .setItemAmount(item.key, '100000000');
    }
    expect(draft.totalFixedCosts, p(300000000000));
    expect(draft.validate(), isEmpty);
    final ready = _ready(draft.preview(today: _nov5));
    expect(ready.shortfall, p(290000000000));
    expect(ready.dailyBudget, Paise.zero);
  });

  test('TC-008-34 item limits and duplicate names', () {
    final tooBig = _e2Draft().setItemAmount(0, '100000000.01').validate();
    expect(
      [for (final e in tooBig) (e.field, e.problem, e.itemKey)],
      [(FieldId.itemAmount, FieldProblem.tooLarge, 0)],
    );
    expect(
      _e2Draft().setItemAmount(0, '9' * 40).validate().single.problem,
      FieldProblem.tooLarge,
    );
    final ok = _e2Draft().setItemAmount(0, '100000000');
    expect(ok.validate(), isEmpty);
    // Two items with the same name are fine and both kept in order.
    final twin = _e2Draft().renameItem(1, 'Rent');
    expect(twin.validate(), isEmpty);
    final values = twin.toPeriodValues() as FullMonthValues;
    expect(
      [for (final c in values.fixedCosts) c.name],
      ['Rent', 'Rent', 'Subscriptions'],
    );
    // Names are trimmed; an empty amount is ₹0.
    final trimmed = _e2Draft().renameItem(0, ' Rent ').setItemAmount(2, '');
    final costs = (trimmed.toPeriodValues() as FullMonthValues).fixedCosts;
    expect((costs.first.name, costs.last.amount), ('Rent', Paise.zero));
  });

  test('TC-008-35 deleting every fixed cost leaves the whole salary', () {
    final draft = _e2Draft().removeItem(0).removeItem(1).removeItem(2);
    expect(draft.items, isEmpty);
    expect(draft.totalFixedCosts, Paise.zero);
    final ready = _ready(draft.preview(today: _nov5));
    expect(ready.spendable, p(4000000));
    expect(ready.dailyBudget, p(133334));
    expect((draft.toPeriodValues() as FullMonthValues).fixedCosts, isEmpty);
  });

  test('TC-008-14 a mid-month first setup spreads the money left', () {
    final nov10 = d(2026, 11, 10);
    final draft = SetupDraft.firstSetup(today: nov10, salaryDay: 5);
    expect(draft.kind, SetupKind.midMonth);
    // The still-to-pay list starts empty (D-042).
    expect(draft.items, isEmpty);
    expect(draft.stillToPay, isEmpty);
    expect(draft.preview(today: nov10), isA<PreviewNeedsAmount>());

    final ready = _ready(
      draft.copyWith(moneyLeftText: '24900').preview(today: nov10),
    );
    expect(ready.month.start, _nov5);
    expect((ready.from, ready.days), (nov10, 25));
    expect(ready.basis, PreviewBasis.moneyLeft);
    expect(_runs(ready), [(25, 99600)]);
    expect(
      (draft.copyWith(moneyLeftText: '24900').toPeriodValues()
              as MidMonthStartValues)
          .moneyLeft,
      p(2490000),
    );
  });

  test('TC-008-15 mid-month on 11 Nov splits 8 days up and 16 days down', () {
    final nov11 = d(2026, 11, 11);
    final draft = SetupDraft.firstSetup(
      today: nov11,
      salaryDay: 5,
    ).copyWith(moneyLeftText: '20000');
    final ready = _ready(draft.preview(today: nov11));
    expect(ready.days, 24);
    expect(_runs(ready), [(8, 83334), (16, 83333)]);
    // On the start day it is the normal screen.
    expect(
      SetupDraft.firstSetup(today: _nov5, salaryDay: 5).kind,
      SetupKind.full,
    );
  });

  test('TC-008-48 mid-month on the last day of the month', () {
    final dec4 = d(2026, 12, 4);
    final draft = SetupDraft.firstSetup(
      today: dec4,
      salaryDay: 5,
    ).copyWith(moneyLeftText: '500');
    final ready = _ready(draft.preview(today: dec4));
    expect((ready.days, ready.month.end), (1, dec4));
    expect(_runs(ready), [(1, 50000)]);
  });

  test(
    'TC-008-43 the money left must be more than zero and at most 10 crore',
    () {
      final base = SetupDraft.firstSetup(today: d(2026, 11, 10), salaryDay: 5);
      FieldProblem? problem(String text) {
        final errors = base.copyWith(moneyLeftText: text).validate();
        return errors.isEmpty ? null : errors.single.problem;
      }

      expect(problem(''), FieldProblem.missing);
      expect(problem('0'), FieldProblem.notPositive);
      expect(problem('100000001'), FieldProblem.tooLarge);
      expect(problem('abc'), FieldProblem.badFormat);
      expect(problem('0.01'), isNull);
      expect(
        base.copyWith(moneyLeftText: '').validate().single.field,
        FieldId.moneyLeft,
      );
    },
  );

  test(
    'TC-008-44 a mid-month shortfall is measured against the money left',
    () {
      final nov10 = d(2026, 11, 10);
      final draft = SetupDraft.firstSetup(today: nov10, salaryDay: 5)
          .copyWith(moneyLeftText: '10000')
          .addItem()
          .renameItem(3, 'Rent')
          .setItemAmount(3, '12000');
      expect(draft.items.single.name, 'Rent');
      final ready = _ready(draft.preview(today: nov10));
      expect(
        (ready.basis, ready.shortfall),
        (PreviewBasis.moneyLeft, p(200000)),
      );
      expect(ready.fixedCosts, p(1200000));
    },
  );

  test('TC-008-55 the salary day switches the form and keeps typed values', () {
    final nov10 = d(2026, 11, 10);
    var draft = SetupDraft.firstSetup(today: nov10)
        .copyWith(salaryText: '40000', moneyLeftText: '24900')
        .setItemAmount(0, '10000');
    expect(draft.kind, SetupKind.full);

    draft = draft.chooseSalaryDay(5, nov10);
    expect(draft.kind, SetupKind.midMonth);
    expect(_ready(draft.preview(today: nov10)).days, 25);
    draft = draft.chooseSalaryDay(10, nov10);
    expect(draft.kind, SetupKind.full);
    // Both value sets stayed.
    expect((draft.salaryText, draft.moneyLeftText), ('40000', '24900'));
    expect(draft.items.first.amountText, '10000');
    expect(() => draft.chooseSalaryDay(0, nov10), throwsArgumentError);
    expect(() => draft.chooseSalaryDay(32, nov10), throwsArgumentError);
  });

  test('TC-008-23 month lengths on the preview', () {
    final rows = <(int, CalendarDate, CalendarDate, CalendarDate, int)>[
      (31, d(2027, 1, 31), d(2027, 1, 31), d(2027, 2, 27), 28),
      (30, d(2028, 1, 30), d(2028, 1, 30), d(2028, 2, 28), 30),
      (31, d(2027, 2, 28), d(2027, 2, 28), d(2027, 3, 30), 31),
      (29, d(2028, 2, 29), d(2028, 2, 29), d(2028, 3, 28), 29),
    ];
    for (final (day, today, start, end, days) in rows) {
      final draft = SetupDraft.firstSetup(
        today: today,
        salaryDay: day,
      ).copyWith(salaryText: '40000');
      expect(draft.kind, SetupKind.full, reason: today.iso);
      final ready = _ready(draft.preview(today: today));
      expect(
        (ready.month.start, ready.month.end, ready.days),
        (start, end, days),
        reason: today.iso,
      );
    }
  });

  test('TC-008-19 a new month is filled in from last month', () {
    final dec5 = d(2026, 12, 5);
    final last = FullMonthValues(
      salary: p(4000000),
      target: p(2000000),
      fixedCosts: e2Costs(),
    );
    final draft = SetupDraft.newMonth(salaryDay: 5, previous: last);
    expect(draft.kind, SetupKind.full);
    expect(draft.salaryDay, 5);
    expect(
      (draft.salaryText, draft.targetOn, draft.targetText),
      ('40000', true, '20000'),
    );
    expect(
      [for (final item in draft.items) (item.name, item.amountText)],
      [('Rent', '10000'), ('EMI', '5000'), ('Subscriptions', '100')],
    );
    expect(draft.validate(), isEmpty);
    final ready = _ready(draft.preview(today: dec5));
    expect((ready.month.start, ready.month.end), (dec5, d(2027, 1, 4)));
    expect((ready.days, ready.spendable), (31, p(490000)));
    // 4,90,000 ÷ 31 = 15,806 remainder 14: the first 14 days get one more.
    expect(_runs(ready), [(14, 15807), (17, 15806)]);
    // Saved as it was: the same values.
    final back = draft.toPeriodValues() as FullMonthValues;
    expect((back.salary, back.target), (p(4000000), p(2000000)));
  });

  test('TC-008-19 after a mid-month month the salary is empty', () {
    final draft = SetupDraft.newMonth(
      salaryDay: 5,
      previous: MidMonthStartValues(
        moneyLeft: p(2490000),
        fixedCostsStillToPay: [
          const FixedCost(name: 'EMI', amount: Paise(500000)),
        ],
      ),
    );
    expect(draft.kind, SetupKind.full);
    expect((draft.salaryText, draft.targetOn), ('', false));
    expect(
      [for (final item in draft.items) (item.name, item.amountText)],
      [('EMI', '5000')],
    );
    expect(draft.validate().first.field, FieldId.salary);
  });

  test('TC-008-41 a late start is a fresh start with nothing pre-filled', () {
    final dec20 = d(2026, 12, 20);
    final draft = SetupDraft.lateStart(salaryDay: 5);
    expect(draft.kind, SetupKind.midMonth);
    expect(draft.moneyLeftText, isEmpty);
    expect(draft.items, isEmpty);
    final ready = _ready(
      draft.copyWith(moneyLeftText: '16000').preview(today: dec20),
    );
    expect(
      (ready.month.start, ready.month.end, ready.from, ready.days),
      (d(2026, 12, 5), d(2027, 1, 4), dec20, 16),
    );
    expect(_runs(ready), [(16, 100000)]);
  });

  test('TC-008-56 a late start on 12 Dec spreads over 24 days', () {
    final dec12 = d(2026, 12, 12);
    final draft = SetupDraft.lateStart(salaryDay: 5)
        .copyWith(moneyLeftText: '24000');
    final ready = _ready(draft.preview(today: dec12));
    expect((ready.days, ready.month.start), (24, d(2026, 12, 5)));
    expect(_runs(ready), [(24, 100000)]);
    final values = draft.toPeriodValues() as MidMonthStartValues;
    expect(values.moneyLeft, p(2400000));
  });

  test('TC-008-45 a mid-month draft and an empty salary count changes', () {
    final nov10 = d(2026, 11, 10);
    final empty = SetupDraft.firstSetup(today: nov10, salaryDay: 5);
    expect(empty.isChangedFrom(empty), isFalse);
    final typed = empty.copyWith(moneyLeftText: '24900');
    expect(typed.isChangedFrom(empty), isTrue);
    expect(
      typed.copyWith(moneyLeftText: '24900.0').isChangedFrom(typed),
      isFalse,
    );
    // Only the form that is showing counts: the salary text is hidden here.
    expect(empty.copyWith(salaryText: '40000').isChangedFrom(empty), isFalse);
    // On the full form an empty salary is not a typed one.
    final full = SetupDraft.firstSetup(today: _nov5, salaryDay: 5);
    expect(full.isChangedFrom(full.copyWith(salaryText: '1')), isTrue);
    expect(full.copyWith(salaryText: ' ').isChangedFrom(full), isFalse);
  });

  group('edit this month', () {
    final nov20 = d(2026, 11, 20);
    final saved = e2Values();
    SetupDraft initial() => SetupDraft.forEdit(salaryDay: 5, saved: saved);

    test('TC-008-20 raising the rent recalculates the remaining days', () {
      final past = _past(nov20);
      expect(past, hasLength(15));
      final draft = initial().setItemAmount(0, '13000');
      final ready = _ready(draft.preview(today: nov20, earlierBudgets: past));
      expect((ready.from, ready.days), (nov20, 15));
      expect(_runs(ready), [(15, 63000)]);
      expect(ready.outcome.amountToSpread, p(945000));

      // The engine agrees once the new period is saved (the draft's values).
      final month = e2Month(
        today: nov20,
        periods: [period(_nov5, saved), period(nov20, draft.toPeriodValues())],
      );
      expect([
        for (final b in budgetsOf(month, nov20, d(2026, 12, 4))) b!,
      ], ready.outcome.budgets);
      expect(month.dayOn(d(2026, 11, 19)).budget, p(83000));
    });

    test('TC-008-20 the saved values are not a change', () {
      expect(initial().isChangedFrom(initial()), isFalse);
      expect(initial().validate(), isEmpty);
      expect(initial().targetOn, isFalse);
      expect(initial().items.map((i) => i.amountText), [
        '10000',
        '5000',
        '100',
      ]);
      expect(
        initial().setItemAmount(0, '13000').isChangedFrom(initial()),
        isTrue,
      );
    });

    test('TC-008-21 a salary of 35,000 gives 10 days up and 5 down', () {
      final ready = _ready(
        initial()
            .copyWith(salaryText: '35000')
            .preview(today: nov20, earlierBudgets: _past(nov20)),
      );
      expect(_runs(ready), [(10, 49667), (5, 49666)]);
    });

    test('TC-008-28 a target of 25,000 leaves the month short', () {
      final ready = _ready(
        initial()
            .copyWith(targetOn: true, targetText: '25000')
            .preview(today: nov20, earlierBudgets: _past(nov20)),
      );
      expect(ready.outcome, isA<Shortfall>());
      expect(ready.shortfall, p(255000));
      expect(ready.dailyBudget, Paise.zero);
    });

    test('TC-008-40 spends above the new spendable do not stop an edit', () {
      final ready = _ready(
        initial()
            .copyWith(salaryText: '30000')
            .preview(today: nov20, earlierBudgets: _past(nov20)),
      );
      expect(ready.outcome.amountToSpread, p(245000));
      expect(_runs(ready), [(5, 16334), (10, 16333)]);
    });

    test('TC-008-45 changing a value and back is no change', () {
      final changed = initial().setItemAmount(0, '13000');
      final back = changed.setItemAmount(0, '10000');
      expect(back.isChangedFrom(initial()), isFalse);
      // 10000.00 and 10000 are the same value; an empty amount is ₹0.
      expect(
        initial().setItemAmount(0, '10000.00').isChangedFrom(initial()),
        isFalse,
      );
      final zero = initial().setItemAmount(2, '0');
      expect(zero.isChangedFrom(initial().setItemAmount(2, '')), isFalse);
      // Order, names, the target and unparseable text count.
      expect(initial().renameItem(0, 'Flat').isChangedFrom(initial()), isTrue);
      expect(initial().removeItem(0).isChangedFrom(initial()), isTrue);
      expect(
        initial()
            .copyWith(targetOn: true, targetText: '40000')
            .isChangedFrom(initial()),
        isTrue,
      );
      expect(
        initial().copyWith(salaryText: 'x').isChangedFrom(initial()),
        isTrue,
      );
    });

    test('TC-008-46 an edit on the first day supersedes the first period', () {
      final ready = _ready(
        initial().setItemAmount(0, '13000').preview(today: _nov5),
      );
      expect((ready.from, ready.days), (_nov5, 30));
      expect(_runs(ready), [(30, 73000)]);
    });

    test('TC-008-20 editing a mid-month month keeps the money left', () {
      final saved = MidMonthStartValues(moneyLeft: p(2490000));
      final draft = SetupDraft.forEdit(salaryDay: 5, saved: saved);
      expect(draft.kind, SetupKind.midMonth);
      expect(draft.moneyLeftText, '24900');
      expect(draft.items, isEmpty);
      // Edited on 12 Nov: money left is still the money on 10 Nov (D-048),
      // spread over 12 Nov to 4 Dec after 2 days at 99,600.
      final nov12 = d(2026, 11, 12);
      final ready = _ready(
        draft
            .copyWith(moneyLeftText: '26400')
            .preview(today: nov12, earlierBudgets: [p(99600), p(99600)]),
      );
      expect(ready.outcome.amountToSpread, p(2640000 - 199200));
      expect(ready.days, 23);
      expect(
        (draft.copyWith(moneyLeftText: '24900').toPeriodValues()
                as MidMonthStartValues)
            .moneyLeft,
        saved.moneyLeft,
      );
    });
  });
}
