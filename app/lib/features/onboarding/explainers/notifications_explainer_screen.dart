import 'package:daily_budget/core/copy/help_copy.dart';
import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/features/onboarding/explainers/disclaimer_screen.dart';
import 'package:daily_budget/features/onboarding/explainers/explainer_scaffold.dart';
import 'package:flutter/material.dart';

/// What the notifications will be (F-005 §2.5, welcome-tour §4). In Phase 1
/// both buttons open the disclaimer and request nothing, also on Android 13+
/// (AC-8). Phase 5 gives Turn on its real request.
class NotificationsExplainerScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    void next() => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const DisclaimerScreen()));
    return ExplainerScaffold(
      icon: Icons.notifications_outlined,
      title: ScreenCopy.notificationsTitle,
      points: const [
        (icon: Icons.donut_large, text: ScreenCopy.notificationsPointWarning),
        (
          icon: Icons.notifications_active_outlined,
          text: ScreenCopy.notificationsPointOver,
        ),
        (
          icon: Icons.bedtime_outlined,
          text: ScreenCopy.notificationsPointSummary,
        ),
        (icon: Icons.tune, text: ScreenCopy.notificationsPointOptional),
      ],
      primary: (
        label: ScreenCopy.turnOnNotifications,
        description: HelpCopy.turnOnNotificationsDescription,
        hint: null,
        onPressed: next,
      ),
      secondary: (
        label: ScreenCopy.notNow,
        description: null,
        hint: HelpCopy.notificationsNotNowHint,
        onPressed: next,
      ),
    );
  }
}
