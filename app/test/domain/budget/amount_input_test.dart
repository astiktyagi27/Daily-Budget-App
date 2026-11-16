import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

// The pure parsing behind TC-008-05, -06, -31, -32 and -34 (plan F-008 §1.3).

/// The paise of [text], or the type name of what it is instead.
Object? _read(String text) => switch (parseAmount(text)) {
  AmountValue(:final paise) => paise,
  final other => other.runtimeType,
};

void main() {
  test('TC-008-05 an empty bad or too precise amount is not a value', () {
    expect(_read(''), AmountEmpty);
    expect(_read('   '), AmountEmpty);
    expect(_read('₹'), AmountEmpty);
    expect(_read('abc'), AmountBadFormat);
    expect(_read('12.345'), AmountTooManyDecimals);
    expect(_read('1.2345'), AmountTooManyDecimals);
    // 0 and 10,00,00,001 are values: the range is the draft's rule.
    expect(_read('0'), p(0));
    expect(_read('100000001'), p(10000000100));
  });

  test('TC-008-06 valid amounts are exact paise', () {
    expect(_read('40000'), p(4000000));
    expect(_read('100000000'), p(10000000000));
    expect(_read('99.50'), p(9950));
    expect(_read('99.5'), p(9950));
    expect(_read('99.05'), p(9905));
    expect(_read('0.01'), p(1));
  });

  test('TC-008-31 pasted amounts are cleaned or refused', () {
    expect(_read('₹40,000'), p(4000000));
    expect(_read('40,000.00'), p(4000000));
    expect(_read(' 40000 '), p(4000000));
    expect(_read('₹ 40 000'), p(4000000));
    expect(_read('40k'), AmountBadFormat);
    expect(_read('4O000'), AmountBadFormat);
    expect(_read('-40000'), AmountBadFormat);
    expect(_read('1.2.3'), AmountBadFormat);
    expect(_read('.'), AmountBadFormat);
  });

  test('TC-008-31 Indian and Western grouping commas are both accepted', () {
    expect(_read('1,00,000'), p(10000000));
    expect(_read('1,000,000'), p(100000000));
    expect(_read('12,34,567'), p(123456700));
    expect(_read('1,234,567'), p(123456700));
    expect(_read('100,000'), p(10000000));
    // Misplaced commas are not grouping.
    expect(_read('4,0000'), AmountBadFormat);
    expect(_read('1,0,000'), AmountBadFormat);
    expect(_read('1234,567'), AmountBadFormat);
    expect(_read(',500'), AmountBadFormat);
    expect(_read('500,'), AmountBadFormat);
  });

  test('TC-008-32 leading zeros decimal comma and bare points', () {
    expect(_read('040000'), p(4000000));
    expect(_read('000'), p(0));
    // A comma is grouping, never a decimal.
    expect(_read('99,50'), AmountBadFormat);
    expect(_read('0.01'), p(1));
    expect(_read('.5'), p(50));
    expect(_read('40000.'), p(4000000));
  });

  test('TC-008-34 amounts above ten crore are values or too large', () {
    expect(_read('100000000.01'), p(10000000001));
    expect(_read('1000000000000'), AmountTooLarge);
    expect(_read('9' * 40), AmountTooLarge);
    // Leading zeros do not count towards the size.
    expect(_read('${'0' * 40}5'), p(500));
    expect(maxAmount, p(10000000000));
  });

  test('TC-008-34 the positive amount rule names each problem', () {
    AmountProblem? problem(String text) =>
        positiveAmountProblem(parseAmount(text));
    expect(problem(''), AmountProblem.missing);
    expect(problem('abc'), AmountProblem.badFormat);
    expect(problem('12.345'), AmountProblem.badFormat);
    expect(problem('0'), AmountProblem.notPositive);
    expect(problem('100000000'), isNull);
    expect(problem('100000000.01'), AmountProblem.tooLarge);
    expect(problem('9' * 40), AmountProblem.tooLarge);
    expect(problem('0.01'), isNull);
  });

  test('TC-008-20 amounts shown in a field read back exactly', () {
    expect(amountInputText(p(25000)), '250');
    expect(amountInputText(p(30050)), '300.50');
    expect(amountInputText(p(1)), '0.01');
    expect(amountInputText(p(9905)), '99.05');
    expect(amountInputText(p(0)), '0');
    for (final value in [0, 1, 99, 100, 101, 9950, 10000000000]) {
      expect(_read(amountInputText(p(value))), p(value), reason: '$value');
    }
  });
}
