import 'package:daily_budget/domain/preferences/theme_choice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TC-002-13 stored theme values parse to a choice or auto', () {
    const valid = {
      'auto': ThemeChoice.auto,
      'light': ThemeChoice.light,
      'dark': ThemeChoice.dark,
      'dim': ThemeChoice.dim,
    };
    for (final MapEntry(key: stored, value: choice) in valid.entries) {
      expect(ThemeChoice.fromStorage(stored), choice, reason: stored);
      expect(choice.storageValue, stored);
    }

    final invalid = <String?>[null, 'blue', '', 'DIM ', 'Dim', 'x' * 10000];
    for (final stored in invalid) {
      expect(
        ThemeChoice.fromStorage(stored),
        ThemeChoice.auto,
        reason: stored == null ? 'null' : '${stored.length} chars',
      );
    }
  });
}
