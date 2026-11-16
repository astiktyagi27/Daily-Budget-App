import 'package:daily_budget/core/copy/transactions_copy.dart';
import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/features/month_setup/month_setup_controller.dart';
import 'package:daily_budget/features/transactions/month_setup_launcher.dart';
import 'package:daily_budget/features/transactions/spend_editor_screen.dart';
import 'package:daily_budget/features/transactions/transactions_state.dart';
import 'package:daily_budget/features/transactions/widgets/cover_taken_back_sheet.dart';
import 'package:daily_budget/features/transactions/widgets/new_month_blocked_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True while an editor or the new-month sheet is being opened or is open, so
/// a double tap opens one screen (TC-009-42).
final NotifierProvider<_Busy, bool> _busyProvider =
    NotifierProvider<_Busy, bool>(_Busy.new);

class _Busy extends Notifier<bool> {
  @override
  bool build() => false;

  // A setter-style method keeps the guard readable at the call sites.
  // ignore: use_setters_to_change_properties
  void set({required bool value}) => state = value;
}

/// What Add spend and a tapped row do (F-009 AC-2, AC-7, AC-13).
///
/// * Month set up: opens the full-screen editor ([edit] null = add), then
///   shows the cover-taken-back sheet if the save reduced a cover (D-040) and
///   the snackbar.
/// * New month not set up: the decision sheet, with **Set up this month**.
/// * Anything else (no month, date set back): nothing.
Future<void> openSpendEditor(
  BuildContext context,
  WidgetRef ref, {
  StoredSpend? edit,
}) async {
  if (ref.read(_busyProvider)) return;
  final view = ref.read(transactionsViewProvider).value;
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final launchSetup = ref.read(monthSetupLauncherProvider);
  // A snackbar of the last save would sit over the editor's Save button.
  messenger.hideCurrentSnackBar();
  final busy = ref.read(_busyProvider.notifier)..set(value: true);
  try {
    switch (view) {
      case NewMonthView(:final lastMonth):
        final setUp = await showNewMonthBlockedSheet(navigator.context);
        if (setUp && navigator.mounted) {
          launchSetup(navigator.context, NewMonthMode(lastMonth));
        }
      case CurrentMonthView(:final canAdd, :final stored) when canAdd:
        final result = await navigator.push<SpendEditorResult>(
          MaterialPageRoute(
            builder: (_) => SpendEditorScreen(month: stored, editing: edit),
          ),
        );
        if (result == null) return;
        if (result.reductions.isNotEmpty && navigator.mounted) {
          await showCoverTakenBackSheet(navigator.context, result.reductions);
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(switch (result.outcome) {
              SpendEditorOutcome.added => TransactionsCopy.spendAdded,
              SpendEditorOutcome.updated => TransactionsCopy.spendUpdated,
              SpendEditorOutcome.deleted => TransactionsCopy.spendDeleted,
            }),
          ),
        );
      default:
    }
  } finally {
    busy.set(value: false);
  }
}
