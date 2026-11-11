import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/data/preferences/shared_preferences_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

/// Platform whose store cannot be read at all.
final class _UnreadablePlatform extends InMemorySharedPreferencesAsync {
  new() : super.empty();

  @override
  Future<Map<String, Object>> getPreferences(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) => Future.error(Exception('storage unavailable'));
}

/// Platform that reads normally but fails every write.
final class _WriteFailingPlatform extends InMemorySharedPreferencesAsync {
  new(super.data) : super.withData();

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) => Future.error(Exception('storage full'));

  @override
  Future<bool> setBool(
    String key,
    bool value,
    SharedPreferencesOptions options,
  ) => Future.error(Exception('storage full'));

  @override
  Future<bool> clear(
    ClearPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) => Future.error(Exception('storage full'));
}

void main() {
  const key = PreferenceKeys.themeChoice;
  const flagKey = 'test.flag';
  const allowList = {key, flagKey};

  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);

  test('TC-002-10 adapter round trip survives a new store instance', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    final first = await SharedPreferencesStore.open(allowList: allowList);
    expect(first.readString(key), isNull);
    expect(await first.writeString(key, 'dim'), isTrue);
    expect(await first.writeBool(flagKey, value: true), isTrue);
    expect(first.readString(key), 'dim');

    // A new instance on the same platform is what the next launch sees.
    final second = await SharedPreferencesStore.open(allowList: allowList);
    expect(second.readString(key), 'dim');
    expect(second.readBool(flagKey), isTrue);

    expect(await second.remove(key), isTrue);
    final third = await SharedPreferencesStore.open(allowList: allowList);
    expect(third.readString(key), isNull);
    expect(third.readBool(flagKey), isTrue);
  });

  test('TC-002-10 openPreferencesStore opens the device store', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({key: 'dark'});

    final store = await openPreferencesStore();

    expect(store, isA<SharedPreferencesStore>());
    expect(store.readString(key), 'dark');
  });

  test(
    'TC-002-13 adapter reads missing, wrong-type or unlisted keys as null',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            key: 42,
            flagKey: 'true',
            'not.listed': 'dim',
          });

      final store = await SharedPreferencesStore.open(allowList: allowList);

      expect(store.readString(key), isNull);
      expect(store.readBool(key), isNull);
      expect(store.readBool(flagKey), isNull);
      expect(store.readString('not.listed'), isNull);
      expect(store.readString('missing'), isNull);
    },
  );

  test('TC-002-13 adapter refuses to write unlisted keys', () async {
    final platform = InMemorySharedPreferencesAsync.empty();
    SharedPreferencesAsyncPlatform.instance = platform;

    final store = await SharedPreferencesStore.open(allowList: allowList);

    expect(await store.writeString('not.listed', 'dim'), isFalse);
    expect(await store.writeBool('not.listed', value: true), isFalse);
    expect(await store.remove('not.listed'), isFalse);
    final saved = await platform.getPreferences(
      const GetPreferencesParameters(filter: PreferencesFilters()),
      const SharedPreferencesOptions(),
    );
    expect(saved, isEmpty);
  });

  test(
    'TC-002-14 unreadable store falls back to an empty in-memory store',
    () async {
      SharedPreferencesAsyncPlatform.instance = _UnreadablePlatform();

      final store = await openPreferencesStore();

      expect(store, isA<InMemoryPreferencesStore>());
      expect(store.readString(key), isNull);
      // The fallback still works for the session.
      expect(await store.writeString(key, 'dim'), isTrue);
      expect(store.readString(key), 'dim');
    },
  );

  test('TC-002-36 failed writes return false without throwing', () async {
    SharedPreferencesAsyncPlatform.instance = _WriteFailingPlatform({
      key: 'light',
    });

    final store = await SharedPreferencesStore.open(allowList: allowList);

    expect(await store.writeString(key, 'dim'), isFalse);
    expect(await store.writeBool(flagKey, value: true), isFalse);
    expect(await store.remove(key), isFalse);

    // Nothing reached the device: the next launch still sees the old value.
    final next = await SharedPreferencesStore.open(allowList: allowList);
    expect(next.readString(key), 'light');
    expect(next.readBool(flagKey), isNull);
  });
}
