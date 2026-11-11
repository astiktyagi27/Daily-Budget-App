import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/widgets/root_page.dart';
import 'package:daily_budget/core/widgets/tap_cooldown.dart';
import 'package:daily_budget/domain/preferences/onboarding_stage.dart';
import 'package:daily_budget/features/onboarding/explainers/sms_explainer_screen.dart';
import 'package:daily_budget/features/onboarding/onboarding_provider.dart';
import 'package:daily_budget/features/onboarding/tour/tour_screen.dart';
import 'package:daily_budget/features/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The first screen (`MaterialApp.home`, plan F-005 §1 step 3): the tour,
/// the SMS explainer or Home, from the saved onboarding stage. Every stage
/// has a screen, so the app is never blank (AC-15).
///
/// A stage change swaps the root page with a fade and a 16 dp rise
/// (`motionBase`, instant with Remove animations; welcome-tour §2.4, §5), so
/// the tour never stays in the history and I understand fades into Home.
///
/// When onboarding finishes during the session, Home ignores pointers for a
/// double-tap interval: the second tap of a double tap on I understand
/// passes through the closing disclaimer and must not land on the bottom bar
/// (AC-13, D-044). A cold start that is already finished is not delayed.
///
/// During the swap the outgoing page is only a picture: it takes no
/// pointers or keyboard focus, screen readers skip it, and its Back handling
/// is off, so only the incoming page answers (review N9).
class AppGate extends ConsumerStatefulWidget {
  const new({super.key});

  /// How far a new root page rises as it fades in.
  static const double rise = 16;

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> {
  final _homeGuard = TapCooldown();

  @override
  void dispose() {
    _homeGuard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(onboardingProvider, (previous, next) {
      if (next == OnboardingStage.finished &&
          previous != OnboardingStage.finished) {
        _homeGuard.start(
          onEnd: () {
            if (mounted) setState(() {});
          },
        );
      }
    });
    final stage = ref.watch(onboardingProvider);
    final page = switch (stage) {
      OnboardingStage.tour => const TourScreen(),
      OnboardingStage.explainers => const SmsExplainerScreen(),
      OnboardingStage.finished => AbsorbPointer(
        absorbing: _homeGuard.isActive,
        child: const AppShell(),
      ),
    };
    return AnimatedSwitcher(
      duration: BudgetMotion.of(context).base,
      switchInCurve: BudgetMotion.standard,
      switchOutCurve: BudgetMotion.standard,
      transitionBuilder: _fadeAndRise,
      layoutBuilder: _layout,
      child: KeyedSubtree(key: ValueKey(stage), child: page),
    );
  }

  /// The default layout (a centred stack, the incoming page on top), with
  /// the outgoing pages switched off. Each wrapper keeps its page's key, so
  /// the page keeps its state when it turns from current into outgoing.
  static Widget _layout(Widget? current, List<Widget> previous) {
    return Stack(
      alignment: Alignment.center,
      children: [
        for (final page in previous)
          _GatePage(key: page.key, current: false, child: page),
        if (current != null)
          _GatePage(key: current.key, current: true, child: current),
      ],
    );
  }

  static Widget _fadeAndRise(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, AppGate.rise * (1 - animation.value)),
          child: child,
        ),
        child: child,
      ),
    );
  }
}

/// One root page in the gate's stack: an outgoing page ignores pointers,
/// cannot take focus, is hidden from screen readers and lets Back through.
class _GatePage extends StatelessWidget {
  const new({required this.current, required this.child, super.key});

  final bool current;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RootPageScope(
      current: current,
      child: IgnorePointer(
        ignoring: !current,
        child: ExcludeFocus(
          excluding: !current,
          child: ExcludeSemantics(excluding: !current, child: child),
        ),
      ),
    );
  }
}
