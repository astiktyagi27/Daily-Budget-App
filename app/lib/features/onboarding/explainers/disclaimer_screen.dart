import 'package:daily_budget/core/copy/help_copy.dart';
import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/features/onboarding/explainers/explainer_scaffold.dart';
import 'package:daily_budget/features/onboarding/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the app can and can't do (F-005 §2.6, welcome-tour §5). One button,
/// no Skip and no other way forward (AC-10). I understand reports
/// `OnboardingActions.finish` and returns to the root page, which the gate
/// has by then turned into Home. Back returns to the notifications explainer
/// (AC-11).
class DisclaimerScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExplainerScaffold(
      icon: Icons.info_outline,
      title: ScreenCopy.disclaimerTitle,
      points: const [
        (
          icon: Icons.account_balance_outlined,
          text: ScreenCopy.disclaimerPointOneAccount,
        ),
        (
          icon: Icons.credit_card_off_outlined,
          text: ScreenCopy.disclaimerPointNoCards,
        ),
        (icon: Icons.edit_outlined, text: ScreenCopy.disclaimerPointDetection),
      ],
      primary: (
        label: ScreenCopy.iUnderstand,
        description: null,
        hint: HelpCopy.iUnderstandHint,
        onPressed: () {
          ref.read(onboardingActionsProvider).finish();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }
}
