import 'package:daily_budget/domain/preferences/onboarding_stage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TC-005-15 saved flags map to the first screen (F-005 §2.8)', () {
    expect(
      OnboardingStage.fromFlags(tourSeen: false, finished: false),
      OnboardingStage.tour,
    );
    expect(
      OnboardingStage.fromFlags(tourSeen: true, finished: false),
      OnboardingStage.explainers,
    );
    expect(
      OnboardingStage.fromFlags(tourSeen: true, finished: true),
      OnboardingStage.finished,
    );
  });

  test('TC-005-27 finished wins when tour seen is missing', () {
    expect(
      OnboardingStage.fromFlags(tourSeen: false, finished: true),
      OnboardingStage.finished,
    );
  });
}
