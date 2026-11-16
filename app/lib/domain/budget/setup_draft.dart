import 'dart:convert';

import 'package:daily_budget/domain/budget/amount_input.dart';
import 'package:daily_budget/domain/budget/budget_month.dart';
import 'package:daily_budget/domain/budget/budget_period.dart';
import 'package:daily_budget/domain/budget/calendar_date.dart';
import 'package:daily_budget/domain/budget/fixed_cost.dart';
import 'package:daily_budget/domain/budget/paise.dart';
import 'package:daily_budget/domain/budget/spread_outcome.dart';

/// At most this many fixed-cost items (F-008 §2.2).
const maxFixedCostItems = 30;

/// The longest item name. The text field enforces it (it counts characters
/// the way the user sees them, which pure Dart cannot); the draft does not
/// count.
const maxItemNameLength = 40;

/// Which set of fields the setup form shows (F-008 plan §1).
enum SetupKind {
  /// Salary, optional target and fixed costs, for a month that starts today
  /// (or an edit of one).
  full,

  /// Money left now and the fixed costs still to pay, from today: the first
  /// setup partway through a month or a late start (D-034, D-057).
  midMonth,
}

/// A field of the setup form, in screen order.
enum FieldId { salaryDay, salary, target, moneyLeft, itemName, itemAmount }

/// What is wrong with a field. The screen maps each pair of field and
/// problem to its F-008 §5 error text.
enum FieldProblem {
  /// Nothing chosen or typed (an empty item amount is never a problem).
  missing,

  /// Letters, a decimal comma or more than 2 decimals.
  badFormat,

  /// ₹0 or less where more than ₹0 is needed.
  notPositive,

  /// More than ₹10 crore.
  tooLarge,

  /// A target above the salary.
  aboveSalary,
}

/// One problem on the form. `itemKey` is set for item fields only.
typedef FieldError = ({FieldId field, FieldProblem problem, int? itemKey});

/// One fixed-cost row as typed. The `key` never changes, so a row keeps its
/// identity while it is edited or restored by Undo.
final class DraftItem {
  const new({required this.key, this.name = '', this.amountText = ''});

  final int key;

  final String name;

  final String amountText;

  DraftItem copyWith({String? name, String? amountText}) => DraftItem(
    key: key,
    name: name ?? this.name,
    amountText: amountText ?? this.amountText,
  );
}

/// What the preview card shows for the draft (F-008 §2.3).
sealed class SetupPreview {
  const new();
}

/// The first setup has no salary day yet: no budget month to show.
final class PreviewNeedsSalaryDay extends SetupPreview {
  const new();
}

/// The salary, target or money left is empty or invalid: no daily budget.
final class PreviewNeedsAmount extends SetupPreview {
  const new();
}

/// Which amount the spendable line starts from.
enum PreviewBasis { salary, target, moneyLeft }

/// A worked-out preview. Every figure is exact paise; the screen formats it.
final class PreviewReady extends SetupPreview {
  const new({
    required this.month,
    required this.from,
    required this.basis,
    required this.baseAmount,
    required this.fixedCosts,
    required this.spendable,
    required this.outcome,
  });

  final BudgetMonth month;

  /// The first day the new values apply: today.
  final CalendarDate from;

  final PreviewBasis basis;

  /// The salary, target or money left the spendable line starts from.
  final Paise baseAmount;

  /// The fixed costs (still to pay, for a mid-month start).
  final Paise fixedCosts;

  /// `baseAmount - fixedCosts`; below ₹0 for a shortfall.
  final Paise spendable;

  /// The day budgets from [from], from the engine's `planPeriod`.
  final SpreadOutcome outcome;

  /// The days from [from] to the month's end, inclusive.
  int get days => from.daysUntil(month.end) + 1;

  /// The first day's budget, the largest of the spread (D-035). ₹0 for a
  /// shortfall or a ₹0 spendable.
  Paise get dailyBudget => outcome.budgets.first;

  /// How much is missing; ₹0 when there is no shortfall.
  Paise get shortfall => switch (outcome) {
    Shortfall(:final amount) => amount,
    Spread() || ZeroSpendable() => Paise.zero,
  };
}

/// The setup form as typed, in pure Dart (F-008 plan §1.2). It keeps the raw
/// text of every field and both value sets, so changing the salary day can
/// switch between [SetupKind]s without losing what was typed. It is
/// immutable: every edit returns a new draft.
final class SetupDraft {
  const new({
    required this.kind,
    this.salaryDay,
    this.salaryText = '',
    this.targetOn = false,
    this.targetText = '',
    this.moneyLeftText = '',
    this.fixedCosts = const [],
    this.stillToPay = const [],
    this.nextKey = 0,
  });

  /// The first setup: Rent, EMI and Subscriptions with empty amounts. The
  /// kind follows [salaryDay] (none chosen: [SetupKind.full]).
  factory firstSetup({required CalendarDate today, int? salaryDay}) =>
      SetupDraft(
        kind: _kindFor(salaryDay, today),
        salaryDay: salaryDay,
        fixedCosts: const [
          DraftItem(key: 0, name: 'Rent'),
          DraftItem(key: 1, name: 'EMI'),
          DraftItem(key: 2, name: 'Subscriptions'),
        ],
        nextKey: 3,
      );

  /// A month set up after its start day (D-057): a fresh start with the
  /// money left, nothing pre-filled.
  factory lateStart({required int salaryDay}) =>
      SetupDraft(kind: SetupKind.midMonth, salaryDay: salaryDay);

  /// A new month that starts today, filled in from the last period (F-008
  /// §2.8, §2.6). After a full period everything is kept; after a mid-month
  /// start the salary is empty and the items are the ones still to pay.
  factory newMonth({required int salaryDay, required PeriodValues previous}) =>
      switch (previous) {
        FullMonthValues() => SetupDraft.forEdit(
          salaryDay: salaryDay,
          saved: previous,
        ),
        MidMonthStartValues(:final fixedCostsStillToPay) => SetupDraft(
          kind: SetupKind.full,
          salaryDay: salaryDay,
          fixedCosts: _itemsOf(fixedCostsStillToPay),
          nextKey: fixedCostsStillToPay.length,
        ),
      };

  /// The saved values of the month, to edit (F-008 §2.9).
  factory forEdit({required int salaryDay, required PeriodValues saved}) =>
      switch (saved) {
        FullMonthValues(:final salary, :final target, :final fixedCosts) =>
          SetupDraft(
            kind: SetupKind.full,
            salaryDay: salaryDay,
            salaryText: amountInputText(salary),
            targetOn: target != null,
            targetText: target == null ? '' : amountInputText(target),
            fixedCosts: _itemsOf(fixedCosts),
            nextKey: fixedCosts.length,
          ),
        MidMonthStartValues(:final moneyLeft, :final fixedCostsStillToPay) =>
          SetupDraft(
            kind: SetupKind.midMonth,
            salaryDay: salaryDay,
            moneyLeftText: amountInputText(moneyLeft),
            stillToPay: _itemsOf(fixedCostsStillToPay),
            nextKey: fixedCostsStillToPay.length,
          ),
      };

  final SetupKind kind;

  /// 1 to 31, or null until chosen (first setup only).
  final int? salaryDay;

  final String salaryText;

  final bool targetOn;

  final String targetText;

  final String moneyLeftText;

  /// The items of the full form.
  final List<DraftItem> fixedCosts;

  /// The items of the mid-month form (D-042); starts empty.
  final List<DraftItem> stillToPay;

  /// The key the next added item gets.
  final int nextKey;

  // A first setup asks for the salary when today is the start day of the
  // month for [salaryDay], otherwise for the money left (D-034).
  static SetupKind _kindFor(int? salaryDay, CalendarDate today) =>
      salaryDay == null ||
          BudgetMonth.containing(salaryDay, today).start == today
      ? SetupKind.full
      : SetupKind.midMonth;

  static List<DraftItem> _itemsOf(List<FixedCost> costs) => [
    for (final (key, cost) in costs.indexed)
      DraftItem(
        key: key,
        name: cost.name,
        amountText: amountInputText(cost.amount),
      ),
  ];

  /// A copy with other field values. Use [chooseSalaryDay] for the day and
  /// the item methods for the lists.
  SetupDraft copyWith({
    String? salaryText,
    bool? targetOn,
    String? targetText,
    String? moneyLeftText,
  }) => SetupDraft(
    kind: kind,
    salaryDay: salaryDay,
    salaryText: salaryText ?? this.salaryText,
    targetOn: targetOn ?? this.targetOn,
    targetText: targetText ?? this.targetText,
    moneyLeftText: moneyLeftText ?? this.moneyLeftText,
    fixedCosts: fixedCosts,
    stillToPay: stillToPay,
    nextKey: nextKey,
  );

  /// The first setup with another salary day. The kind follows it (D-034);
  /// both sets of typed values stay.
  SetupDraft chooseSalaryDay(int day, CalendarDate today) {
    if (day < 1 || day > 31) {
      throw ArgumentError.value(day, 'day', 'must be 1 to 31');
    }
    return SetupDraft(
      kind: _kindFor(day, today),
      salaryDay: day,
      salaryText: salaryText,
      targetOn: targetOn,
      targetText: targetText,
      moneyLeftText: moneyLeftText,
      fixedCosts: fixedCosts,
      stillToPay: stillToPay,
      nextKey: nextKey,
    );
  }

  /// The items of the form that is showing.
  List<DraftItem> get items => switch (kind) {
    SetupKind.full => fixedCosts,
    SetupKind.midMonth => stillToPay,
  };

  bool get canAddItem => items.length < maxFixedCostItems;

  SetupDraft _withItems(List<DraftItem> list, {int? nextKey}) => SetupDraft(
    kind: kind,
    salaryDay: salaryDay,
    salaryText: salaryText,
    targetOn: targetOn,
    targetText: targetText,
    moneyLeftText: moneyLeftText,
    fixedCosts: kind == SetupKind.full ? List.unmodifiable(list) : fixedCosts,
    stillToPay: kind == SetupKind.midMonth
        ? List.unmodifiable(list)
        : stillToPay,
    nextKey: nextKey ?? this.nextKey,
  );

  /// A new empty item at the end; its key is `items.last.key`. Throws a
  /// [StateError] at the limit (the screen disables the button).
  SetupDraft addItem() {
    if (!canAddItem) {
      throw StateError('At most $maxFixedCostItems items.');
    }
    return _withItems([
      ...items,
      DraftItem(key: nextKey),
    ], nextKey: nextKey + 1);
  }

  /// The item with [key] removed. Undo puts it back with [insertItem].
  SetupDraft removeItem(int key) => _withItems([
    for (final item in items)
      if (item.key != key) item,
  ]);

  /// [item] at [index] (Undo of a delete restores the same position).
  SetupDraft insertItem(int index, DraftItem item) {
    if (!canAddItem) {
      throw StateError('At most $maxFixedCostItems items.');
    }
    final list = [...items]..insert(index.clamp(0, items.length), item);
    return _withItems(list);
  }

  /// The position of the item with [key], or -1.
  int indexOfItem(int key) => items.indexWhere((item) => item.key == key);

  SetupDraft renameItem(int key, String name) => _withItems([
    for (final item in items)
      if (item.key == key) item.copyWith(name: name) else item,
  ]);

  SetupDraft setItemAmount(int key, String text) => _withItems([
    for (final item in items)
      if (item.key == key) item.copyWith(amountText: text) else item,
  ]);

  /// The sum of the item amounts that are valid; an empty or invalid one
  /// counts as ₹0 (the form shows this as Total fixed costs).
  Paise get totalFixedCosts => Paise.sum(items.map(_itemAmount));

  static Paise _itemAmount(DraftItem item) =>
      switch (parseAmount(item.amountText)) {
        AmountValue(:final paise) when paise.value <= maxAmount.value => paise,
        _ => Paise.zero,
      };

  // The amount of a field that must be more than ₹0 and at most ₹10 crore.
  static Paise? _positiveAmount(String text) => switch (parseAmount(text)) {
    AmountValue(:final paise)
        when paise.isPositive && paise.value <= maxAmount.value =>
      paise,
    _ => null,
  };

  // The problem of a "more than ₹0" field, or null. With a [ceiling] (the
  // salary), more than it is aboveSalary before tooLarge.
  static FieldProblem? _positiveProblem(String text, {Paise? ceiling}) {
    final parse = parseAmount(text);
    final aboveCeiling = switch (parse) {
      _ when ceiling == null => false,
      AmountTooLarge() => true,
      AmountValue(:final paise) => paise > ceiling!,
      _ => false,
    };
    if (aboveCeiling) return FieldProblem.aboveSalary;
    return switch (positiveAmountProblem(parse)) {
      null => null,
      AmountProblem.missing => FieldProblem.missing,
      AmountProblem.badFormat => FieldProblem.badFormat,
      AmountProblem.notPositive => FieldProblem.notPositive,
      AmountProblem.tooLarge => FieldProblem.tooLarge,
    };
  }

  static FieldProblem? _itemAmountProblem(String text) =>
      switch (parseAmount(text)) {
        AmountEmpty() => null,
        AmountBadFormat() || AmountTooManyDecimals() => FieldProblem.badFormat,
        AmountTooLarge() => FieldProblem.tooLarge,
        AmountValue(:final paise) =>
          paise > maxAmount ? FieldProblem.tooLarge : null,
      };

  /// Every problem, in screen order, so the first one gets focus (F-008
  /// §2.7). Empty when the form can be saved.
  List<FieldError> validate() {
    final errors = <FieldError>[];
    void add(FieldId field, FieldProblem? problem, [int? itemKey]) {
      if (problem != null) {
        errors.add((field: field, problem: problem, itemKey: itemKey));
      }
    }

    if (salaryDay == null) add(FieldId.salaryDay, FieldProblem.missing);
    switch (kind) {
      case SetupKind.full:
        add(FieldId.salary, _positiveProblem(salaryText));
        if (targetOn) {
          add(
            FieldId.target,
            _positiveProblem(targetText, ceiling: _positiveAmount(salaryText)),
          );
        }
      case SetupKind.midMonth:
        add(FieldId.moneyLeft, _positiveProblem(moneyLeftText));
    }
    for (final item in items) {
      if (item.name.trim().isEmpty) {
        add(FieldId.itemName, FieldProblem.missing, item.key);
      }
      add(FieldId.itemAmount, _itemAmountProblem(item.amountText), item.key);
    }
    return List.unmodifiable(errors);
  }

  List<FixedCost> _costs() => [
    for (final item in items)
      FixedCost(name: item.name.trim(), amount: _itemAmount(item)),
  ];

  /// The values to save. Throws a [StateError] when [validate] finds a
  /// problem: nothing is ever fixed silently.
  PeriodValues toPeriodValues() {
    if (validate().isNotEmpty) {
      throw StateError('The draft has problems; call validate() first.');
    }
    return switch (kind) {
      SetupKind.full => FullMonthValues(
        salary: _positiveAmount(salaryText)!,
        target: targetOn ? _positiveAmount(targetText) : null,
        fixedCosts: _costs(),
      ),
      SetupKind.midMonth => MidMonthStartValues(
        moneyLeft: _positiveAmount(moneyLeftText)!,
        fixedCostsStillToPay: _costs(),
      ),
    };
  }

  /// Whether the typed values differ from [initial] (Save changes and the
  /// discard guard). `0` and an empty item amount are the same, and item
  /// keys do not count; the order of the items does.
  bool isChangedFrom(SetupDraft initial) =>
      _signature() != initial._signature();

  String _signature() => jsonEncode([
    kind.name,
    salaryDay,
    if (kind == SetupKind.full) ...[
      _normalised(salaryText),
      targetOn,
      if (targetOn) _normalised(targetText),
    ] else
      _normalised(moneyLeftText),
    for (final item in items)
      [item.name.trim(), _normalised(item.amountText, emptyIsZero: true)],
  ]);

  static String _normalised(String text, {bool emptyIsZero = false}) =>
      switch (parseAmount(text)) {
        AmountValue(:final paise) => '${paise.value}',
        AmountEmpty() when emptyIsZero => '0',
        AmountEmpty() => '',
        _ => 'text:${text.trim()}',
      };

  /// The preview for a form used on [today] (F-008 §2.3, §2.9).
  ///
  /// The budget month is the one containing today. [earlierBudgets] are the
  /// budgets of the days of an edited month before today (from the engine's
  /// result); a new or first setup has none, and its first budgeted day is
  /// today. An empty or invalid fixed-cost amount counts as ₹0 here.
  SetupPreview preview({
    required CalendarDate today,
    List<Paise> earlierBudgets = const [],
  }) {
    final day = salaryDay;
    if (day == null) return const PreviewNeedsSalaryDay();
    final PreviewBasis basis;
    final Paise baseAmount;
    final PeriodValues values;
    switch (kind) {
      case SetupKind.full:
        final salary = _positiveAmount(salaryText);
        if (salary == null) return const PreviewNeedsAmount();
        final target = targetOn ? _positiveAmount(targetText) : null;
        if (targetOn && (target == null || target > salary)) {
          return const PreviewNeedsAmount();
        }
        basis = target == null ? PreviewBasis.salary : PreviewBasis.target;
        baseAmount = target ?? salary;
        values = FullMonthValues(
          salary: salary,
          target: target,
          fixedCosts: _costs(),
        );
      case SetupKind.midMonth:
        final moneyLeft = _positiveAmount(moneyLeftText);
        if (moneyLeft == null) return const PreviewNeedsAmount();
        basis = PreviewBasis.moneyLeft;
        baseAmount = moneyLeft;
        values = MidMonthStartValues(
          moneyLeft: moneyLeft,
          fixedCostsStillToPay: _costs(),
        );
    }
    final month = BudgetMonth.containing(day, today);
    return PreviewReady(
      month: month,
      from: today,
      basis: basis,
      baseAmount: baseAmount,
      fixedCosts: values.fixedCostsTotal,
      spendable: values.spendable,
      outcome: planPeriod(
        month: month,
        firstBudgetedDay: today.addDays(-earlierBudgets.length),
        earlierBudgets: earlierBudgets,
        values: values,
        from: today,
      ),
    );
  }
}
