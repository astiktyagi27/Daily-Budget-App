import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

final CalendarDate _nov9 = d(2026, 11, 9);

SpendDateLimits get _limits => spendDateLimits(
  month: nov2026,
  firstBudgetedDay: d(2026, 11, 5),
  today: _nov9,
);

List<SpendError> _errors(SpendDraft draft) => draft.validate(_limits);

SpendDraft _draft(String amount) =>
    SpendDraft.forToday(_nov9).copyWith(amountText: amount);

void main() {
  test('TC-009-04 amount problems are named', () {
    SpendProblem? problem(String text) {
      final errors = _errors(_draft(text));
      return errors.isEmpty ? null : errors.single.problem;
    }

    expect(problem(''), SpendProblem.missing);
    expect(problem('0'), SpendProblem.notPositive);
    expect(problem('100000001'), SpendProblem.tooLarge);
    expect(problem('12.345'), SpendProblem.badFormat);
    expect(problem('abc'), SpendProblem.badFormat);
    expect(_errors(_draft('')).single, (
      field: SpendField.amount,
      problem: SpendProblem.missing,
    ));
  });

  test('TC-009-05 valid amounts are stored exactly', () {
    for (final (text, paise) in [
      ('300.50', 30050),
      ('1', 100),
      ('100000000', 10000000000),
      ('250', 25000),
    ]) {
      final draft = _draft(text);
      expect(_errors(draft), isEmpty, reason: text);
      expect(draft.toFields(_limits).amount, p(paise), reason: text);
    }
  });

  test('TC-009-34 one paisa is a valid spend and reads back exactly', () {
    final draft = _draft('0.01');
    expect(_errors(draft), isEmpty);
    final fields = draft.toFields(_limits);
    expect(fields.amount, p(1));
    final edit = SpendDraft.forEdit(
      Spend(id: 1, date: _nov9, amount: p(1), createdAt: 0),
    );
    expect(edit.amountText, '0.01');
  });

  test('TC-009-06 dates run from the month start to today', () {
    expect(_limits, (first: d(2026, 11, 5), last: _nov9));
    SpendProblem? problem(CalendarDate date) {
      final errors = _errors(_draft('100').copyWith(date: date));
      return errors.isEmpty ? null : errors.single.problem;
    }

    expect(problem(d(2026, 11, 4)), SpendProblem.beforeFirstDay);
    expect(problem(d(2026, 11, 5)), isNull);
    expect(problem(_nov9), isNull);
    expect(problem(d(2026, 11, 10)), SpendProblem.afterLastDay);
    expect(problem(d(2026, 12, 4)), SpendProblem.afterLastDay);
    expect(SpendDraft.forToday(_nov9).date, _nov9);
  });

  test('TC-009-07 after a mid-month start only the budgeted days count', () {
    final limits = spendDateLimits(
      month: nov2026,
      firstBudgetedDay: d(2026, 11, 10),
      today: d(2026, 11, 12),
    );
    expect(limits, (first: d(2026, 11, 10), last: d(2026, 11, 12)));
    final draft = _draft('100');
    expect(
      draft.copyWith(date: d(2026, 11, 9)).validate(limits).single.problem,
      SpendProblem.beforeFirstDay,
    );
    expect(draft.copyWith(date: d(2026, 11, 10)).validate(limits), isEmpty);
  });

  test('TC-009-38 an edit follows the same limits', () {
    final limits = spendDateLimits(
      month: nov2026,
      firstBudgetedDay: d(2026, 11, 10),
      today: d(2026, 11, 12),
      editedSpendDate: d(2026, 11, 11),
    );
    expect(limits, (first: d(2026, 11, 10), last: d(2026, 11, 12)));
  });

  test('TC-009-30 a spend dated after today may be edited up to its date', () {
    final nov10 = d(2026, 11, 10);
    final limits = spendDateLimits(
      month: nov2026,
      firstBudgetedDay: d(2026, 11, 5),
      today: nov10,
      editedSpendDate: d(2026, 11, 12),
    );
    expect(limits.last, d(2026, 11, 12));
    final draft = SpendDraft.forEdit(
      Spend(id: 1, date: d(2026, 11, 12), amount: p(5000), createdAt: 0),
    );
    expect(draft.validate(limits), isEmpty);
    // Adding stays limited to today.
    expect(
      spendDateLimits(
        month: nov2026,
        firstBudgetedDay: d(2026, 11, 5),
        today: nov10,
      ).last,
      nov10,
    );
    // Never past the month's end, and a day before the month is clamped up.
    expect(
      spendDateLimits(
        month: nov2026,
        firstBudgetedDay: d(2026, 11, 5),
        today: nov10,
        editedSpendDate: d(2027, 1, 1),
      ).last,
      d(2026, 12, 4),
    );
    expect(
      spendDateLimits(
        month: nov2026,
        firstBudgetedDay: d(2026, 10, 1),
        today: nov10,
      ).first,
      d(2026, 11, 5),
    );
  });

  test('TC-009-03 the checked fields trim the note and drop an empty one', () {
    final draft = _draft('250').copyWith(note: '  Lunch  ');
    expect(draft.toFields(_limits), (
      amount: p(25000),
      date: _nov9,
      note: 'Lunch',
      category: null,
      direction: SpendDirection.spend,
    ));
    expect(_draft('250').toFields(_limits).note, isNull);
    expect(_draft('250').copyWith(note: '   ').toFields(_limits).note, isNull);
    expect(maxNoteLength, 100);
  });

  test('TC-009-03 a draft with problems is never turned into fields', () {
    expect(() => _draft('').toFields(_limits), throwsStateError);
    expect(
      () => _draft('100').copyWith(date: d(2026, 11, 10)).toFields(_limits),
      throwsStateError,
    );
  });

  test('TC-009-05 emoji and Hindi notes are kept exactly', () {
    const note = 'चाय ☕ और 🥟 समोसा';
    expect(_draft('20').copyWith(note: note).toFields(_limits).note, note);
  });

  test('TC-009-07 an edit is pre-filled and only real changes count', () {
    final spend = Spend(
      id: 4,
      date: d(2026, 11, 8),
      amount: p(30050),
      createdAt: at(d(2026, 11, 8), 12),
    );
    final initial = SpendDraft.forEdit(spend, note: 'Groceries');
    expect(
      (initial.amountText, initial.date, initial.note),
      ('300.50', d(2026, 11, 8), 'Groceries'),
    );
    expect(initial.isChangedFrom(initial), isFalse);
    expect(
      initial.copyWith(amountText: '300.5').isChangedFrom(initial),
      isFalse,
    );
    expect(
      initial.copyWith(note: 'Groceries ').isChangedFrom(initial),
      isFalse,
    );
    expect(initial.copyWith(amountText: '270').isChangedFrom(initial), isTrue);
    expect(initial.copyWith(date: _nov9).isChangedFrom(initial), isTrue);
    expect(initial.copyWith(note: 'Milk').isChangedFrom(initial), isTrue);
  });

  test('TC-009-16 a new spend with nothing typed is no change', () {
    final initial = SpendDraft.forToday(_nov9);
    expect(initial.isChangedFrom(SpendDraft.forToday(_nov9)), isFalse);
    expect(initial.copyWith(amountText: '1').isChangedFrom(initial), isTrue);
    expect(initial.copyWith(note: 'x').isChangedFrom(initial), isTrue);
    expect(
      initial.copyWith(date: d(2026, 11, 8)).isChangedFrom(initial),
      isTrue,
    );
    // Unreadable text still counts as typed.
    expect(initial.copyWith(amountText: 'abc').isChangedFrom(initial), isTrue);
  });

  test('TC-016-03 a money back draft becomes an in transaction', () {
    final draft = _draft('500')
        .copyWith(note: 'Amazon return', moneyBack: true);
    expect(draft.toFields(_limits), (
      amount: p(50000),
      date: _nov9,
      note: 'Amazon return',
      category: null,
      direction: SpendDirection.moneyIn,
    ));
    expect(_draft('500').toFields(_limits).direction, SpendDirection.spend);
  });

  test('TC-016-44 a refund never stores a category', () {
    final draft = _draft('500')
        .copyWith(category: SpendCategory.food, moneyBack: true);
    expect(draft.toFields(_limits).category, isNull);
    expect(draft.category, SpendCategory.food, reason: 'kept in the draft');
    final back = draft.copyWith(moneyBack: false);
    expect(back.toFields(_limits).category, SpendCategory.food);
    expect(back.toFields(_limits).direction, SpendDirection.spend);
  });

  test('TC-016-46 converting a categorised spend clears its category', () {
    final spend = Spend(
      id: 4,
      date: _nov9,
      amount: p(25000),
      createdAt: at(_nov9, 12),
      category: SpendCategory.shopping,
    );
    final initial = SpendDraft.forEdit(spend, note: 'Shoes');
    expect(initial.category, SpendCategory.shopping);
    final converted = initial.copyWith(moneyBack: true);
    expect(converted.isChangedFrom(initial), isTrue);
    final fields = converted.toFields(_limits);
    expect((fields.direction, fields.category), (SpendDirection.moneyIn, null));
  });

  test('TC-016-11 direction flips between in and out', () {
    final refund = Spend(
      id: 5,
      date: _nov9,
      amount: p(30000),
      createdAt: at(_nov9, 12),
      direction: SpendDirection.moneyIn,
    );
    final initial = SpendDraft.forEdit(refund);
    expect(initial.moneyBack, isTrue);
    expect(initial.toFields(_limits).direction, SpendDirection.moneyIn);
    final spend = initial.copyWith(moneyBack: false);
    final fields = spend.toFields(_limits);
    expect((fields.direction, fields.category), (SpendDirection.spend, null));
    expect(spend.effectiveCategory, SpendCategory.other);
  });

  test('TC-016-12 turning the switch counts as a change', () {
    final refund = Spend(
      id: 5,
      date: _nov9,
      amount: p(50000),
      createdAt: at(_nov9, 12),
      direction: SpendDirection.moneyIn,
    );
    final initial = SpendDraft.forEdit(refund);
    expect(initial.isChangedFrom(initial), isFalse);
    expect(initial.copyWith(moneyBack: false).isChangedFrom(initial), isTrue);
    // A category picked while money back is on is not stored: no change.
    expect(
      initial.copyWith(category: SpendCategory.food).isChangedFrom(initial),
      isFalse,
    );
  });

  test('TC-015-64 changed compares the effective category', () {
    final spend = Spend(
      id: 4,
      date: _nov9,
      amount: p(25000),
      createdAt: at(_nov9, 12),
    );
    final initial = SpendDraft.forEdit(spend, note: 'Lunch');
    expect(initial.category, isNull);
    expect(initial.effectiveCategory, SpendCategory.other);
    // No category and Other are the same category.
    expect(
      initial.copyWith(category: SpendCategory.other).isChangedFrom(initial),
      isFalse,
    );
    expect(
      initial.copyWith(category: SpendCategory.food).isChangedFrom(initial),
      isTrue,
    );
    final food = SpendDraft.forEdit(
      Spend(
        id: 4,
        date: _nov9,
        amount: p(25000),
        createdAt: at(_nov9, 12),
        category: SpendCategory.food,
      ),
      note: 'Lunch',
    );
    final other = food.copyWith(category: SpendCategory.other);
    expect(other.isChangedFrom(food), isTrue);
    expect(other.toFields(_limits).category, SpendCategory.other);
  });

  test('TC-016-07 a money back has the limits of a spend', () {
    for (final text in ['', '0', '100000001', '12.345', 'abc']) {
      expect(
        _errors(_draft(text).copyWith(moneyBack: true)),
        _errors(_draft(text)),
        reason: text,
      );
    }
    expect(_errors(_draft('500').copyWith(moneyBack: true)), isEmpty);
  });

  test('TC-016-09 a money back date follows the spend date limits', () {
    final draft = _draft('500').copyWith(moneyBack: true);
    expect(
      _errors(draft.copyWith(date: d(2026, 11, 4))).single.problem,
      SpendProblem.beforeFirstDay,
    );
    expect(
      _errors(draft.copyWith(date: d(2026, 11, 10))).single.problem,
      SpendProblem.afterLastDay,
    );
    expect(_errors(draft.copyWith(date: d(2026, 11, 5))), isEmpty);
  });

  test('TC-015-57 a category alone is a change from an empty add', () {
    final initial = SpendDraft.forToday(_nov9);
    expect(
      initial.copyWith(category: SpendCategory.food).isChangedFrom(initial),
      isTrue,
    );
    expect(
      initial.copyWith(category: SpendCategory.other).isChangedFrom(initial),
      isFalse,
    );
  });
}
