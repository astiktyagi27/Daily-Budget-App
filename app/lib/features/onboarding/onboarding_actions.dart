/// What the onboarding screens ask of the saved onboarding state (plan F-005
/// §1 step 2). The screens only report what the user did; deciding which
/// screen comes next is the job of the first-screen gate (`AppGate`), which
/// swaps the root page when the stage changes.
///
/// Both calls must be idempotent: a double tap or a swipe plus Skip may call
/// them twice (F-005 AC-13). The app's implementation is
/// `OnboardingNotifier`; tests may use a fake.
abstract interface class OnboardingActions {
  /// Skip (slides 1–3) or Get started (slide 4): the tour is seen, the
  /// explainers come next (AC-4, AC-5).
  void completeTour();

  /// I understand on the disclaimer: onboarding is finished, Home comes next
  /// (AC-10).
  void finish();
}
