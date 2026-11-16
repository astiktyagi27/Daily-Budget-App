import 'package:daily_budget/core/copy/storage_copy.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/empty_state.dart';
import 'package:flutter/material.dart';

/// Shown instead of the tabs when the database cannot be opened (F-007 AC-8,
/// AC-9; `month-setup.md` section 10.5): full screen, no bottom navigation,
/// the empty-state layout with one Primary button.
///
/// The text never names a file, a code or SQLite (TC-007-45), and the data on
/// the phone is never touched.
class StorageErrorScreen extends StatelessWidget {
  const new({required this.onTryAgain, super.key});

  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: EmptyState(
            icon: Icons.error_outline,
            title: StorageCopy.openErrorTitle,
            description: StorageCopy.openErrorDescription,
            action: BudgetButton.primary(
              label: StorageCopy.tryAgain,
              semanticsHint: StorageCopy.openErrorHint,
              onPressed: onTryAgain,
            ),
          ),
        ),
      ),
    );
  }
}
