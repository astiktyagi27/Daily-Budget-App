import 'dart:async';

import 'package:daily_budget/core/copy/category_copy.dart';
import 'package:daily_budget/core/copy/search_copy.dart';
import 'package:daily_budget/core/copy/storage_copy.dart';
import 'package:daily_budget/core/copy/transactions_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/transactions/sheets/category_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True while a category write is running, so a double tap on a category
/// writes once (F-015 plan 7).
bool _writing = false;

/// How long `Moved to Food` with `Undo` stays (F-015 §2.4). The snackbar's
/// timer starts after its 250 ms slide in, so this is gone about six seconds
/// after the change, as for the day-details cover Undo.
const Duration undoWindow = Duration(milliseconds: 5750);

/// Changes the category of one list row (F-015 §2.4, AC-11, AC-12).
///
/// Opens the category sheet; a pick saves at once to that one entry only and
/// shows `Moved to <category>` with `Undo`. Undo restores the previous value,
/// including "no category". Picking the ticked category writes nothing and
/// says nothing. The flow holds the id and the repository, not the row, so
/// Undo still works after the row has left a filtered list (D-082 (4)). A
/// failed write keeps the old value and says `Couldn't save`.
Future<void> changeCategory(
  BuildContext context,
  WidgetRef ref,
  StoredSpend entry,
) async {
  if (_writing) return;
  final repository = ref.read(transactionRepositoryProvider);
  final nowMillis = ref.read(nowMillisProvider);
  final messenger = ScaffoldMessenger.of(context);
  // Read before the first await, like the messenger (D-077 (5), D-089 (3)).
  final screenReader = MediaQuery.accessibleNavigationOf(context);
  final spend = entry.spend;
  final previous = spend.category;
  final note = entry.note ?? TransactionsCopy.noNote;
  final picked = await showCategorySheet(
    context,
    title: SearchCopy.rowSheetTitle(formatRupees(spend.amount), note),
    current: previous ?? SpendCategory.other,
  );
  if (picked == null) return;
  _writing = true;
  try {
    await repository.updateCategory(spend.id, picked, now: nowMillis());
  } on StorageException {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(StorageCopy.saveError)));
    return;
  } finally {
    _writing = false;
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(SearchCopy.moved(CategoryCopy.nameOf(picked))),
        duration: undoWindow,
        // A snackbar with an action stays until dismissed unless told not to;
        // it stays only while a screen reader is on (D-077 (5), D-089 (3)).
        persist: screenReader,
        action: SnackBarAction(
          label: SearchCopy.undo,
          onPressed: () => unawaited(
            _undo(repository, messenger, spend.id, previous, nowMillis),
          ),
        ),
      ),
    );
}

Future<void> _undo(
  TransactionRepository repository,
  ScaffoldMessengerState messenger,
  int id,
  SpendCategory? previous,
  int Function() nowMillis,
) async {
  try {
    await repository.updateCategory(id, previous, now: nowMillis());
  } on StorageException {
    messenger.showSnackBar(
      const SnackBar(content: Text(StorageCopy.saveError)),
    );
  }
}
