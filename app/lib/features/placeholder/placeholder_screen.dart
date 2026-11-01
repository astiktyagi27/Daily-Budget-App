import 'package:flutter/material.dart';

/// Temporary first screen until the real home screen exists (Phase 1).
class PlaceholderScreen extends StatelessWidget {
  const new({super.key});

  static const title = 'Daily Budget App';
  static const status =
      'Setting things up. Your daily budget will appear here soon.';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Scrollable so the layout survives the largest system font (STANDARDS §7).
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  status,
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
