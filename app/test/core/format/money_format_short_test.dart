import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';

// F-011 AC-11 and design system §7.5: the calendar cell short forms.

String _short(int rupees, {int paise = 0}) =>
    formatRupeesShort(Paise(rupees * 100 + paise));

String _shortNegative(int rupees) => formatRupeesShort(Paise(-rupees * 100));

void main() {
  test('TC-011-24 short form table', () {
    const table = <int, String>{
      0: '₹0',
      9999: '₹9,999',
      10000: '₹10k',
      12999: '₹12k',
      99999: '₹99k',
      100000: '₹1L',
      105000: '₹1L',
      110000: '₹1.1L',
      159999: '₹1.5L',
      999999: '₹9.9L',
      1000000: '₹10L',
      1299999: '₹12L',
      9999999: '₹99L',
      10000000: '₹1Cr',
      15000000: '₹1.5Cr',
      99999999: '₹9.9Cr',
      100000000: '₹10Cr',
      123456789: '₹12Cr',
      1000000000: '₹100Cr',
    };
    for (final MapEntry(key: rupees, value: expected) in table.entries) {
      expect(_short(rupees), expected, reason: '$rupees');
    }
  });

  test('TC-011-24 negatives keep the sign, no minus zero', () {
    expect(_shortNegative(1500), '\u2212\u2060₹1,500');
    expect(_shortNegative(12000), '\u2212\u2060₹12k');
    expect(_shortNegative(100000), '\u2212\u2060₹1L');
    expect(_shortNegative(150000), '\u2212\u2060₹1.5L');
    expect(formatRupeesShort(const Paise(-40)), '₹0');
    expect(formatRupeesShort(Paise.zero), '₹0');
  });

  test('TC-011-23 paise are cut, never rounded up', () {
    expect(_short(9999, paise: 99), '₹9,999');
    expect(_short(12999, paise: 99), '₹12k');
    expect(_short(99999, paise: 99), '₹99k');
    expect(_short(159999, paise: 99), '₹1.5L');
  });
}
