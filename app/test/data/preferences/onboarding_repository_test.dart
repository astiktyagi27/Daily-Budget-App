import 'package:daily_budget/data/preferences/in_memory_preferences_store.dart';
import 'package:daily_budget/data/preferences/onboarding_repository.dart';
import 'package:daily_budget/data/preferences/preference_keys.dart';
import 'package:daily_budget/domain/preferences/onboarding_stage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/failing_preferences_store.dart';

const _tourSeen = 'onboarding.tour_seen';
const _finished = 'onboarding.finished';

void main() {
  test('TC-005-15 onboarding keys are registered', () {
    expect(PreferenceKeys.onboardingTourSeen, _tourSeen);
    expect(PreferenceKeys.onboardingFinished, _finished);
    expect(PreferenceKeys.allowList, containsAll([_tourSeen, _finished]));
  });

  test('TC-005-15 flags are saved and read back', () async {
    final store = InMemoryPreferencesStore.allowing(PreferenceKeys.allowList);
    final repository = OnboardingRepository(store);
    expect(repository.read(), OnboardingStage.tour);
    expect(await repository.markTourSeen(), isTrue);
    expect(store.values, {_tourSeen: true});
    expect(repository.read(), OnboardingStage.explainers);
    expect(await repository.markFinished(), isTrue);
    expect(store.values, {_tourSeen: true, _finished: true});
    expect(repository.read(), OnboardingStage.finished);
  });

  test('TC-005-27 wrong-type flags count as not set', () {
    OnboardingStage read(Map<String, Object> values) =>
        OnboardingRepository(InMemoryPreferencesStore(values)).read();
    expect(read({_tourSeen: 'maybe'}), OnboardingStage.tour);
    expect(read({_tourSeen: 7}), OnboardingStage.tour);
    expect(
      read({_tourSeen: true, _finished: 'true'}),
      OnboardingStage.explainers,
    );
    expect(read({_tourSeen: true, _finished: ''}), OnboardingStage.explainers);
    expect(read({_finished: true}), OnboardingStage.finished);
  });

  test('TC-005-22 a failing store never throws', () async {
    final unreadable = OnboardingRepository(
      FailingPreferencesStore(
        readFails: true,
        values: {_tourSeen: true, _finished: true},
      ),
    );
    expect(unreadable.read(), OnboardingStage.tour);
    final unwritable = OnboardingRepository(
      FailingPreferencesStore(writeFails: true),
    );
    expect(await unwritable.markTourSeen(), isFalse);
    expect(await unwritable.markFinished(), isFalse);
  });
}
