import 'package:daily_budget/core/providers/preferences_providers.dart';
import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';

// `ProviderContainer.test()` disposes the container when the test ends.
void main() {
  test(
    'TC-002-10 preferences provider returns the store opened at startup',
    () {
      final store = InMemoryPreferencesStore();
      final container = ProviderContainer.test(
        overrides: [preferencesStoreProvider.overrideWithValue(store)],
      );

      expect(container.read(preferencesStoreProvider), same(store));
    },
  );

  test('TC-002-10 preferences provider fails fast without the store', () {
    final container = ProviderContainer.test();

    expect(
      () => container.read(preferencesStoreProvider),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.exception,
          'exception',
          isA<StateError>(),
        ),
      ),
    );
  });
}
