import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/theme_preference_repository.dart';
import 'package:daily_budget/domain/preferences/theme_choice.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/failing_preferences_store.dart';

const _key = 'theme.choice';

void main() {
  test(
    'TC-002-13 repository reads missing or corrupt theme values as auto',
    () {
      final corrupt = <Object>['blue', '', 'DIM ', 42, true, 'x' * 10000];
      for (final value in corrupt) {
        final repository = ThemePreferenceRepository(
          InMemoryPreferencesStore({_key: value}),
        );
        expect(repository.read(), ThemeChoice.auto, reason: '$value'.trim());
      }
      expect(
        ThemePreferenceRepository(InMemoryPreferencesStore()).read(),
        ThemeChoice.auto,
        reason: 'missing',
      );
      expect(
        ThemePreferenceRepository(InMemoryPreferencesStore({_key: 'dim'}))
            .read(),
        ThemeChoice.dim,
      );
    },
  );

  test('TC-002-14 repository survives a store that throws', () async {
    final repository = ThemePreferenceRepository(
      FailingPreferencesStore(
        readFails: true,
        writeFails: true,
        values: {_key: 'dim'},
      ),
    );

    expect(repository.read(), ThemeChoice.auto);
    expect(await repository.write(ThemeChoice.light), isFalse);
  });

  test('TC-002-36 repository reports whether the save worked', () async {
    final failing = FailingPreferencesStore(writeFails: true);
    expect(
      await ThemePreferenceRepository(failing).write(ThemeChoice.dim),
      isFalse,
    );
    expect(failing.values, isEmpty);

    final store = InMemoryPreferencesStore();
    expect(
      await ThemePreferenceRepository(store).write(ThemeChoice.dim),
      isTrue,
    );
    expect(store.values, {_key: 'dim'});
  });
}
