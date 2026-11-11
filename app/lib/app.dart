import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/core/theme/budget_theme.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/system_bars.dart';
import 'package:daily_budget/core/theme/theme_choice_provider.dart';
import 'package:daily_budget/features/onboarding/app_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DailyBudgetApp extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DailyBudgetApp> createState() => _DailyBudgetAppState();
}

class _DailyBudgetAppState extends ConsumerState<DailyBudgetApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // MaterialApp sits above its own MediaQuery, so "Remove animations" is read
  // from the platform here and the app rebuilds when it changes.
  @override
  void didChangeAccessibilityFeatures() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final config = themeConfigFor(ref.watch(themeChoiceProvider));
    final animationsOff = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    return MaterialApp(
      title: ScreenCopy.appName,
      themeMode: config.mode,
      theme: config.light,
      darkTheme: config.dark,
      themeAnimationDuration: animationsOff
          ? Duration.zero
          : BudgetMotion.full.base,
      builder: (context, child) => SystemBarsStyle(child: child!),
      // Tour, SMS explainer or Home, from the saved onboarding stage (F-005).
      home: const AppGate(),
    );
  }
}
