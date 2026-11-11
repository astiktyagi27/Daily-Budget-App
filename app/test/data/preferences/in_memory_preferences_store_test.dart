import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const key = PreferenceKeys.themeChoice;

  test('TC-002-10 in-memory store keeps what was written', () async {
    final store = InMemoryPreferencesStore();

    expect(await store.writeString(key, 'dim'), isTrue);
    expect(await store.writeBool('flag', value: true), isTrue);

    expect(store.readString(key), 'dim');
    expect(store.readBool('flag'), isTrue);
    expect(store.values, {key: 'dim', 'flag': true});

    expect(await store.remove(key), isTrue);
    expect(store.readString(key), isNull);
    expect(store.values, {'flag': true});
  });

  test('TC-002-10 in-memory store copies its seed values', () async {
    final seed = <String, Object>{key: 'light'};
    final store = InMemoryPreferencesStore(seed);

    await store.writeString(key, 'dark');

    expect(seed, {key: 'light'});
    expect(store.readString(key), 'dark');
    expect(() => store.values[key] = 'dim', throwsUnsupportedError);
  });

  test(
    'TC-002-13 in-memory store reads missing or wrong-type values as null',
    () {
      final store = InMemoryPreferencesStore({key: 42, 'flag': 'true'});

      expect(store.readString('missing'), isNull);
      expect(store.readBool('missing'), isNull);
      expect(store.readString(key), isNull);
      expect(store.readBool('flag'), isNull);
    },
  );
}
