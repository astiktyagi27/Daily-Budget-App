import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/day_details/budget_change_text.dart';
import 'package:flutter_test/flutter_test.dart';

// TC-012-27 (salary), TC-012-65 to -71, -73, -74: the words of the `Budget
// changed on this day` line, one test per kind of difference. Wording is the
// month statement's, lower-cased after the colon.

PeriodChange _change(
  PeriodField field, {
  int? before,
  int? after,
  String? name,
}) => (
  field: field,
  name: name,
  before: before == null ? null : Paise(before),
  after: after == null ? null : Paise(after),
);

void main() {
  test('TC-012-27 salary change reads salary before to after', () {
    expect(
      budgetChangeText([
        _change(PeriodField.salary, before: 4000000, after: 3500000),
      ]),
      'salary ₹40,000 → ₹35,000',
    );
  });

  test(
    'TC-012-65 change line for a spending target (changed, set, removed)',
    () {
      expect(
        budgetChangeText([
          _change(PeriodField.target, before: 3000000, after: 2500000),
        ]),
        'spending target ₹30,000 → ₹25,000',
      );
      expect(
        budgetChangeText([_change(PeriodField.target, after: 2500000)]),
        'spending target set to ₹25,000',
      );
      expect(
        budgetChangeText([_change(PeriodField.target, before: 2500000)]),
        'spending target removed',
      );
    },
  );

  test('TC-012-66 change line for money left', () {
    expect(
      budgetChangeText([
        _change(PeriodField.moneyLeft, before: 2490000, after: 2000000),
      ]),
      'money left ₹24,900 → ₹20,000',
    );
  });

  test('TC-012-67 change line for a fixed cost changed keeps its name', () {
    expect(
      budgetChangeText([
        _change(
          PeriodField.fixedCost,
          name: 'Rent',
          before: 1000000,
          after: 1300000,
        ),
      ]),
      'Rent ₹10,000 → ₹13,000',
    );
    expect(
      budgetChangeText([
        _change(
          PeriodField.fixedCost,
          name: 'EMI',
          before: 500000,
          after: 600000,
        ),
      ]),
      'EMI ₹5,000 → ₹6,000',
    );
  });

  test('TC-012-68 change line for a still to pay amount', () {
    expect(
      budgetChangeText([
        _change(
          PeriodField.fixedCostStillToPay,
          name: 'Rent',
          before: 1000000,
          after: 400000,
        ),
      ]),
      'Rent ₹10,000 → ₹4,000',
    );
  });

  test('TC-012-69 change line for a fixed cost added', () {
    expect(
      budgetChangeText([
        _change(PeriodField.fixedCost, name: 'Gym', after: 50000),
      ]),
      'fixed cost added: Gym ₹500',
    );
  });

  test('TC-012-70 change line for a fixed cost removed', () {
    expect(
      budgetChangeText([
        _change(PeriodField.fixedCost, name: 'EMI', before: 500000),
      ]),
      'fixed cost removed: EMI ₹5,000',
    );
  });

  test(
    'TC-012-71 change line for salary and for two changes joined with a dot',
    () {
      expect(
        budgetChangeText([
          _change(PeriodField.salary, before: 4000000, after: 3500000),
          _change(
            PeriodField.fixedCost,
            name: 'Rent',
            before: 1000000,
            after: 1300000,
          ),
        ]),
        'salary ₹40,000 → ₹35,000 · Rent ₹10,000 → ₹13,000',
      );
    },
  );

  test('TC-012-74 change line for a renamed fixed cost (same amount) is a '
      'rename', () {
    expect(
      budgetChangeText([
        _change(PeriodField.fixedCost, name: 'Rent', before: 1000000),
        _change(PeriodField.fixedCost, name: 'House rent', after: 1000000),
      ]),
      'Rent renamed to House rent',
    );
  });

  test('TC-012-73 change line when the changes net to nothing', () {
    expect(budgetChangeText(const []), 'changed and changed back');
  });
}
