import 'package:daily_budget/features/placeholder/placeholder_screen.dart';
import 'package:flutter/material.dart';

class DailyBudgetApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Daily Budget App',
      home: PlaceholderScreen(),
    );
  }
}
