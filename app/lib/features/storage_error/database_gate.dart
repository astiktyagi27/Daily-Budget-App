import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/features/storage_error/storage_error_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows [child] (the tabs) once the money database is open, the storage
/// error screen when it cannot be opened, and a blank themed frame while it
/// opens (F-007 plan 1.5).
///
/// It sits below the theme and inside the first-screen gate, so the saved
/// theme is in the first frame and the tour never waits for the database
/// (F-002 AC-7, TC-007-34).
class DatabaseGate extends ConsumerWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(appDatabaseProvider)
        .when(
          data: (_) => child,
          error: (error, stackTrace) => StorageErrorScreen(
            onTryAgain: () => ref.invalidate(appDatabaseProvider),
          ),
          // Opening takes well under 100 ms, so there is no spinner to flash.
          loading: () => const Scaffold(),
        );
  }
}
