import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/features/onboarding/tour/tour_visuals.dart';
import 'package:flutter/material.dart';

/// One tour slide's content and copy (F-005 §5, welcome-tour §2.2).
enum TourSlideData {
  idea(ScreenCopy.slide1Title, ScreenCopy.slide1Body),
  workedOut(ScreenCopy.slide2Title, ScreenCopy.slide2Body),
  saving(ScreenCopy.slide3Title, ScreenCopy.slide3Body),
  privacy(ScreenCopy.slide4Title, ScreenCopy.slide4Body);

  new(this.title, this.body);

  final String title;
  final String body;

  Widget get visual => switch (this) {
    TourSlideData.idea => const TodayVisual(),
    TourSlideData.workedOut => const LedgerVisual(),
    TourSlideData.saving => const SavingsVisual(),
    TourSlideData.privacy => const PrivacyVisual(),
  };
}

/// The scrolling part of a slide (welcome-tour §2.1 rows 2–4): visual card,
/// title (a heading) and body. The page scrolls vertically at large text;
/// horizontal swipes still change slides.
class TourSlide extends StatelessWidget {
  const new({required this.slide, super.key});

  final TourSlideData slide;

  static const double maxBodyWidth = 360;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        BudgetSpacing.space5,
        BudgetSpacing.space2,
        BudgetSpacing.space5,
        BudgetSpacing.space5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TourVisualCard(child: slide.visual),
          const SizedBox(height: BudgetSpacing.space6),
          Semantics(
            header: true,
            child: Text(
              slide.title,
              style: context.budgetText.displayHeadline.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: BudgetSpacing.space3),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxBodyWidth),
              child: Text(
                slide.body,
                style: BudgetTypeScale.bodyLarge.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
