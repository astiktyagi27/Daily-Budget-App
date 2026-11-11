import 'package:daily_budget/core/providers/preferences_providers.dart';
import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/data/preferences/preferences_store.dart';
import 'package:daily_budget/domain/preferences/onboarding_stage.dart';
import 'package:daily_budget/features/onboarding/onboarding_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/failing_preferences_store.dart';

const _tourSeen = 'onboarding.tour_seen';
const _finished = 'onboarding.finished';

/// Counts writes and records the stage at the moment of each write.
final class _CountingStore implements PreferencesStore {
  new(this.stageNow);

  final OnboardingStage Function() stageNow;
  final InMemoryPreferencesStore inner = InMemoryPreferencesStore.allowing(
    PreferenceKeys.allowList,
  );
  final writes = <(String, OnboardingStage)>[];

  @override
  bool? readBool(String key) => inner.readBool(key);

  @override
  String? readString(String key) => inner.readString(key);

  @override
  Future<bool> writeBool(String key, {required bool value}) {
    writes.add((key, stageNow()));
    return inner.writeBool(key, value: value);
  }

  @override
  Future<bool> writeString(String key, String value) =>
      inner.writeString(key, value);

  @override
  Future<bool> remove(String key) => inner.remove(key);
}

ProviderContainer _container(PreferencesStore store) => ProviderContainer.test(
  overrides: [preferencesStoreProvider.overrideWithValue(store)],
);

void main() {
  test('TC-005-18 complete tour and finish are idempotent and update the '
      'stage before saving', () async {
    late ProviderContainer container;
    final store = _CountingStore(() => container.read(onboardingProvider));
    container = _container(store);
    final actions = container.read(onboardingActionsProvider);
    expect(actions, same(container.read(onboardingProvider.notifier)));
    expect(container.read(onboardingProvider), OnboardingStage.tour);

    // finish() before the tour is done changes nothing.
    actions.finish();
    expect(container.read(onboardingProvider), OnboardingStage.tour);

    actions
      ..completeTour()
      ..completeTour();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(onboardingProvider), OnboardingStage.explainers);

    actions
      ..finish()
      ..finish()
      ..completeTour();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(onboardingProvider), OnboardingStage.finished);

    // One write per flag, each made after the stage had already changed.
    expect(store.writes, [
      (_tourSeen, OnboardingStage.explainers),
      (_finished, OnboardingStage.finished),
    ]);
  });

  test('TC-005-22 a failed save still advances this session', () async {
    final container = _container(FailingPreferencesStore(writeFails: true));
    container.read(onboardingActionsProvider).completeTour();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(onboardingProvider), OnboardingStage.explainers);
    container.read(onboardingActionsProvider).finish();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(onboardingProvider), OnboardingStage.finished);
  });

  test('TC-005-15 the stage is read from the saved flags', () {
    final container = _container(
      InMemoryPreferencesStore.allowing(PreferenceKeys.allowList, {
        _tourSeen: true,
      }),
    );
    expect(container.read(onboardingProvider), OnboardingStage.explainers);
  });
}
