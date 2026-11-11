/// Where the first-run flow stands, which decides the first screen
/// (F-005 §2.8, plan F-005 §1 step 1).
enum OnboardingStage {
  /// Nothing saved: the welcome tour, slide 1.
  tour,

  /// Tour seen, onboarding not finished: the SMS explainer.
  explainers,

  /// Onboarding finished: Home.
  finished;

  /// The F-005 §2.8 table. "Finished" wins, even when "tour seen" is missing
  /// (Gate 1): showing the tour again to someone who finished would be worse
  /// than skipping a flag.
  static OnboardingStage fromFlags({
    required bool tourSeen,
    required bool finished,
  }) {
    if (finished) return OnboardingStage.finished;
    if (tourSeen) return OnboardingStage.explainers;
    return OnboardingStage.tour;
  }
}
