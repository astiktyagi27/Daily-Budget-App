import 'package:daily_budget/core/copy/help_copy.dart';
import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/features/onboarding/explainers/explainer_scaffold.dart';
import 'package:daily_budget/features/onboarding/explainers/notifications_explainer_screen.dart';
import 'package:flutter/material.dart';

/// Why the app will read bank SMS (F-005 §2.4, welcome-tour §3). In Phase 1
/// both buttons open the notifications explainer and request nothing: no
/// permission API, no platform call (AC-7). Phase 4 gives Allow its real
/// request.
class SmsExplainerScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    void next() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationsExplainerScreen(),
      ),
    );
    return ExplainerScaffold(
      icon: Icons.sms_outlined,
      title: ScreenCopy.smsTitle,
      points: const [
        (icon: Icons.sms_outlined, text: ScreenCopy.smsPointWhy),
        (icon: Icons.filter_alt_outlined, text: ScreenCopy.smsPointOnlyBank),
        (icon: Icons.phonelink_lock_outlined, text: ScreenCopy.smsPointStays),
      ],
      primary: (
        label: ScreenCopy.allowSms,
        description: HelpCopy.allowSmsDescription,
        hint: null,
        onPressed: next,
      ),
      secondary: (
        label: ScreenCopy.notNow,
        description: null,
        hint: HelpCopy.smsNotNowHint,
        onPressed: next,
      ),
    );
  }
}
