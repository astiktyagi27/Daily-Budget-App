import 'dart:async';

import 'package:daily_budget/data/repositories/cover_reconciliation.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';

/// The shared in-memory state behind the three fake repositories
/// (F-007 plan 2, `test/helpers/fake_*_repository.dart`). Widget tests use
/// them instead of Drift (look-ahead #5).
///
/// It behaves like the Drift repositories: writes are all or nothing, every
/// write notifies the watchers, and a spend write reconciles the covers with
/// the same [reconcileCovers] the real repository uses.
///
/// Failure modes (F-007 test cases section 0): [failNextWrite] makes the next
/// write throw `StorageException(write)` and store nothing; [readFails] makes
/// every watcher emit `StorageException(read)`.
final class FakeMoneyStore {
  final List<StoredMonth> months = [];
  final Map<int, List<StoredSpend>> spendsByMonth = {};
  final Map<int, List<Cover>> coversByMonth = {};

  /// Makes the next write fail once, storing nothing.
  bool failNextWrite = false;

  /// Makes every read stream emit a `StorageException(read)`.
  bool readFails = false;

  int _nextId = 1;
  final _changes = StreamController<void>.broadcast(sync: true);

  int nextId() => _nextId++;

  /// Tells every watcher that something changed.
  void notify() => _changes.add(null);

  /// Throws when a failure was requested, once.
  void checkWrite() {
    if (failNextWrite) {
      failNextWrite = false;
      throw const StorageException(StorageFailureKind.write);
    }
  }

  /// A stream that emits [read] now and after every change.
  Stream<T> watch<T>(T Function() read) async* {
    if (readFails) {
      throw const StorageException(StorageFailureKind.read);
    }
    yield read();
    await for (final _ in _changes.stream) {
      if (readFails) {
        throw const StorageException(StorageFailureKind.read);
      }
      yield read();
    }
  }

  StoredMonth? monthById(int id) => months.where((m) => m.id == id).firstOrNull;

  MonthInput inputFor(int monthId, CalendarDate today) {
    final stored = monthById(monthId)!;
    return MonthInput(
      month: stored.month,
      firstBudgetedDay: stored.firstBudgetedDay,
      periods: stored.periods,
      today: today,
      spends: [
        for (final s in spendsByMonth[monthId] ?? <StoredSpend>[]) s.spend,
      ],
      covers: coversByMonth[monthId] ?? <Cover>[],
    );
  }

  /// Lowers stored covers like the Drift repository and returns the
  /// reductions (D-040, D-048).
  List<CoverReduction> reconcile(int monthId, CalendarDate today) {
    final reconciliation = reconcileCovers(inputFor(monthId, today));
    final covers = coversByMonth[monthId] ?? [];
    for (final effective in reconciliation.toStore) {
      final index = covers.indexWhere((c) => c.id == effective.coverId);
      final old = covers[index];
      covers[index] = Cover(
        id: old.id,
        day: old.day,
        amount: effective.amount,
        madeAt: old.madeAt,
      );
    }
    return reconciliation.reductions;
  }
}
