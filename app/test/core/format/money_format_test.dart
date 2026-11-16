import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minus sign, then the word joiner, as the formatter writes them.
const _neg = '\u2212\u2060';

void main() {
  test('TC-008-29 money formatter shows whole rupees rounded down with indian '
      'grouping', () {
    const table = <int, String>{
      66667: '₹666',
      133334: '₹1,333',
      83000: '₹830',
      99: '₹0',
      0: '₹0',
      10000000000: '₹10,00,00,000',
      1234567899: '₹1,23,45,678',
      -100000: '$_neg₹1,000',
      -12050: '$_neg₹120',
      // Extra cases of the test file.
      1: '₹0',
      100: '₹1',
      100000: '₹1,000',
      300000000000: '₹3,00,00,00,000',
      -99: '₹0',
    };
    for (final MapEntry(key: paise, value: text) in table.entries) {
      expect(formatRupees(Paise(paise)), text, reason: '$paise paise');
    }
  });

  test('TC-008-29 every grouping boundary and the one paisa steps', () {
    const table = <int, String>{
      99999: '₹999',
      100000: '₹1,000',
      9999999: '₹99,999',
      10000000: '₹1,00,000',
      999999999: '₹99,99,999',
      1000000000: '₹1,00,00,000',
      9999999999: '₹9,99,99,999',
      // One paisa below a whole rupee never rounds up.
      99999999: '₹9,99,999',
      100000000: '₹10,00,000',
      -99999999: '$_neg₹9,99,999',
    };
    for (final MapEntry(key: paise, value: text) in table.entries) {
      expect(formatRupees(Paise(paise)), text, reason: '$paise paise');
    }
    // Rounds toward zero on both sides of zero (D-038).
    expect(formatRupees(const Paise(66667)), '₹666');
    expect(formatRupees(const Paise(-66667)), '$_neg₹666');
    expect(formatRupees(const Paise(-100)), '$_neg₹1');
    expect(formatRupees(const Paise(-199)), '$_neg₹1');
  });

  test('TC-008-29 a negative amount under one rupee has no sign (D-050)', () {
    for (final paise in [-1, -50, -99]) {
      final text = formatRupees(Paise(paise));
      expect(text, '₹0', reason: '$paise paise');
      expect(text, isNot(contains('\u2212')));
    }
  });

  test('TC-008-29 the minus is U+2212 followed by a word joiner', () {
    final text = formatRupees(const Paise(-100000));
    expect(text.codeUnits.take(3), [0x2212, 0x2060, 0x20B9]);
    expect(text, isNot(contains('-')));
  });

  test(
    'TC-008-29 the speech form says minus and has no invisible characters',
    () {
      expect(formatRupeesForSpeech(const Paise(-100000)), 'minus ₹1,000');
      expect(formatRupeesForSpeech(const Paise(83000)), '₹830');
      expect(formatRupeesForSpeech(const Paise(-99)), '₹0');
      expect(formatRupeesForSpeech(const Paise(1234567800)), '₹1,23,45,678');
      for (final paise in [-100000, 83000, -99, 1234567899]) {
        final speech = formatRupeesForSpeech(Paise(paise));
        expect(speech, isNot(contains('\u2060')));
        expect(speech, isNot(contains('\u00A0')));
        expect(speech, isNot(contains('\u2212')));
      }
    },
  );

  test('TC-008-29 the extreme amounts do not overflow', () {
    // 30 items of ten crore (TC-008-33) and the largest int64.
    expect(formatRupees(const Paise(3000000000000)), '₹30,00,00,00,000');
    expect(
      formatRupees(const Paise(9223372036854775807)),
      '₹92,23,37,20,36,85,47,758',
    );
    expect(
      formatRupees(const Paise(-9223372036854775807)),
      '$_neg₹92,23,37,20,36,85,47,758',
    );
  });
}
