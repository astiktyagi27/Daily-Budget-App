import 'dart:async';

import 'package:daily_budget/core/providers/preferences_providers.dart';
import 'package:daily_budget/domain/preferences/onboarding_stage.dart';
import 'package:daily_budget/features/onboarding/onboarding_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The onboarding stage (F-005 §2.8). Read synchronously from the store
/// opened before `runApp`, so the first frame is already the right screen
/// (welcome-tour §7: no flash of Home or of the tour).
final NotifierProvider<OnboardingNotifier, OnboardingStage> onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingStage>(
      OnboardingNotifier.new,
    );

/// The [OnboardingActions] the screens use: the app's [OnboardingNotifier].
/// Tests of a single screen may override it with a fake.
final onboardingActionsProvider = Provider<OnboardingActions>(
  (ref) => ref.watch(onboardingProvider.notifier),
);

class OnboardingNotifier extends Notifier<OnboardingStage>
    implements OnboardingActions {
  @override
  OnboardingStage build() => ref.watch(onboardingRepositoryProvider).read();

  /// Only from the tour. The stage changes first, then "tour seen" is saved,
  /// so a failed save still moves on this session (AC-15). A second call
  /// (double tap, swipe plus Skip) changes and writes nothing (AC-13).
  @override
  void completeTour() {
    if (state != OnboardingStage.tour) return;
    state = OnboardingStage.explainers;
    unawaited(ref.read(onboardingRepositoryProvider).markTourSeen());
  }

  /// Only from the explainers. The stage changes first, then "finished" is
  /// saved; a failed save still reaches Home this session and the flow may
  /// show again next launch (AC-15). A second call does nothing.
  @override
  void finish() {
    if (state != OnboardingStage.explainers) return;
    state = OnboardingStage.finished;
    unawaited(ref.read(onboardingRepositoryProvider).markFinished());
  }
}
