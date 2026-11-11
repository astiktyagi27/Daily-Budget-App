import 'dart:async';

import 'package:daily_budget/core/copy/help_copy.dart';
import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/core/help/nav_tooltip.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/root_page.dart';
import 'package:daily_budget/core/widgets/tap_cooldown.dart';
import 'package:daily_budget/features/onboarding/onboarding_provider.dart';
import 'package:daily_budget/features/onboarding/tour/page_indicator.dart';
import 'package:daily_budget/features/onboarding/tour/tour_slide.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The welcome tour (F-005 §2.2–§2.3, welcome-tour §2): four slides in a
/// `PageView`, the page indicator and Skip above, Next / Get started pinned
/// below. Skip and Get started report `OnboardingActions.completeTour`; the
/// gate then shows the SMS explainer in place of the tour, so the tour is not
/// in the history. Nothing is saved while moving between slides (AC-6).
class TourScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends ConsumerState<TourScreen> {
  final _controller = PageController();

  /// The settled slide, as the indicator and the buttons show it.
  int _page = 0;

  bool _animating = false;
  bool _completed = false;

  /// Runs for a double-tap interval after each accepted Next. With Remove
  /// animations on the page jumps at once, so the animation guard alone
  /// would let a double tap advance twice (AC-13).
  final _nextCooldown = TapCooldown();

  static final int _lastPage = TourSlideData.values.length - 1;

  @override
  void dispose() {
    _nextCooldown.dispose();
    _controller.dispose();
    super.dispose();
  }

  int get _settledPage =>
      _controller.hasClients ? (_controller.page ?? 0).round() : _page;

  /// True while the last Next is still moving the pages, or was tapped
  /// less than a double-tap interval ago.
  bool get _nextInProgress => _animating || _nextCooldown.isActive;

  void _next() {
    if (_nextInProgress) return;
    final target = _settledPage + 1;
    if (target > _lastPage) return;
    _nextCooldown.start();
    _goTo(target);
  }

  /// Get started replaces Next as slide 4 comes in, so the second tap of a
  /// double tap on Next (slide 3) must not land on it.
  void _getStarted() {
    if (_nextInProgress) return;
    _complete();
  }

  void _previous() {
    final target = _settledPage - 1;
    if (target < 0) return;
    _goTo(target);
  }

  void _goTo(int target) {
    final duration = BudgetMotion.of(context).emphasis;
    if (duration == Duration.zero) {
      _controller.jumpToPage(target);
      return;
    }
    _animating = true;
    unawaited(
      _controller
          .animateToPage(
            target,
            duration: duration,
            curve: BudgetMotion.decelerate,
          )
          .whenComplete(() => _animating = false),
    );
  }

  /// Skip or Get started. Reported once per tour, so a swipe plus Skip or a
  /// double tap cannot advance twice (AC-13).
  void _complete() {
    if (_completed) return;
    _completed = true;
    ref.read(onboardingActionsProvider).completeTour();
  }

  @override
  Widget build(BuildContext context) {
    final onLastPage = _page == _lastPage;
    return RootPopScope(
      // Slide 1: back leaves the app. Later slides: back goes one slide back.
      canPop: _page == 0,
      onBack: _previous,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopRow(
                page: _page,
                count: TourSlideData.values.length,
                onSkip: onLastPage ? null : _complete,
              ),
              Expanded(
                // Reading order (welcome-tour §2.4): title, body, position,
                // Next / Get started, Skip.
                child: Semantics(
                  container: true,
                  sortKey: const OrdinalSortKey(1),
                  // No stretch or glow at either end: nothing hints at a
                  // page that is not there (welcome-tour §2.4).
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(overscroll: false),
                    child: PageView(
                      controller: _controller,
                      physics: const ClampingScrollPhysics(),
                      onPageChanged: (page) => setState(() => _page = page),
                      children: [
                        for (final slide in TourSlideData.values)
                          TourSlide(slide: slide),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  BudgetSpacing.space5,
                  BudgetSpacing.space3,
                  BudgetSpacing.space5,
                  BudgetSpacing.space5,
                ),
                child: Semantics(
                  container: true,
                  sortKey: const OrdinalSortKey(3),
                  child: onLastPage
                      ? BudgetButton.primary(
                          key: const ValueKey('getStarted'),
                          label: ScreenCopy.getStarted,
                          semanticsHint: HelpCopy.getStartedHint,
                          onPressed: _getStarted,
                        )
                      : NavTooltip(
                          key: const ValueKey('next'),
                          message: HelpCopy.nextHint,
                          child: BudgetButton.primary(
                            label: ScreenCopy.next,
                            onPressed: _next,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicator on the left, Skip on the right (slides 1–3; the space stays
/// empty on slide 4). At large text the row wraps, indicator above Skip.
class _TopRow extends StatelessWidget {
  const new({required this.page, required this.count, required this.onSkip});

  final int page;
  final int count;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BudgetSpacing.space5,
        BudgetSpacing.space4,
        BudgetSpacing.space5,
        0,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: BudgetSpacing.touchTarget),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: BudgetSpacing.space2,
          children: [
            Semantics(
              container: true,
              sortKey: const OrdinalSortKey(2),
              child: SizedBox(
                height: BudgetSpacing.touchTarget,
                child: Center(
                  widthFactor: 1,
                  child: PageIndicator(index: page, count: count),
                ),
              ),
            ),
            if (onSkip case final onSkip?)
              Semantics(
                container: true,
                sortKey: const OrdinalSortKey(4),
                child: NavTooltip(
                  message: HelpCopy.skipHint,
                  child: BudgetButton.text(
                    label: ScreenCopy.skip,
                    onPressed: onSkip,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
