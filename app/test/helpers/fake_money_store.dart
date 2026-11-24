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
/// every watcher emit `StorageException(read)`; [readFailsFor] does that for
/// the reads of one month only (a past month that cannot load, F-011
/// TC-011-50). To see a loading state, [readDelay] (every read) and
/// [delayReadsOf] (one month) hold the first emission of each watcher until
/// the test completes the completer (Phase 3 harness, T-308).
final class FakeMoneyStore {
  final List<StoredMonth> months = [];
  final Map<int, List<StoredSpend>> spendsByMonth = {};
  final Map<int, List<Cover>> coversByMonth = {};

  /// Makes the next write fail once, storing nothing.
  bool failNextWrite = false;

  /// Makes every read stream emit a `StorageException(read)`.
  bool readFails = false;

  /// Holds the first emission of every watcher until the test completes it.
  /// Set it before the screen opens; completing it lets the reads through.
  Completer<void>? readDelay;

  final Map<int, Completer<void>> _monthDelays = {};
  final Set<int> _failingMonths = {};

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

  /// Makes every read of month [monthId] (its row, spends and covers) emit a
  /// `StorageException(read)` until called again with `fails: false`. Reads
  /// of other months, and the month index, are not affected.
  void readFailsFor(int monthId, {bool fails = true}) {
    if (fails) {
      _failingMonths.add(monthId);
    } else {
      _failingMonths.remove(monthId);
    }
    notify();
  }

  /// Holds the first emission of every read of month [monthId] until the
  /// returned completer is completed. Call it before the month is read.
  Completer<void> delayReadsOf(int monthId) =>
      _monthDelays[monthId] = Completer<void>();

  void _checkRead(int? monthId) {
    if (readFails || (monthId != null && _failingMonths.contains(monthId))) {
      throw const StorageException(StorageFailureKind.read);
    }
  }

  /// A stream that emits [read] now and after every change. [monthId] says
  /// which month the stream reads, for [readFailsFor] and [delayReadsOf].
  ///
  /// Not an `async*` generator: cancelling one that waits for the next change
  /// would not finish until that change came, and a test that cancels in a
  /// tear-down would hang.
  Stream<T> watch<T>(T Function() read, {int? monthId}) {
    late final StreamController<T> controller;
    StreamSubscription<void>? changes;

    void emit() {
      try {
        _checkRead(monthId);
        controller.add(read());
      } on StorageException catch (error, stackTrace) {
        controller.addError(error, stackTrace);
        unawaited(changes?.cancel());
        unawaited(controller.close());
      }
    }

    Future<void> start() async {
      try {
        _checkRead(monthId);
        await readDelay?.future;
        if (monthId != null) await _monthDelays[monthId]?.future;
      } on StorageException catch (error, stackTrace) {
        controller.addError(error, stackTrace);
        await controller.close();
        return;
      }
      if (!controller.hasListener) return;
      emit();
      if (controller.isClosed) return;
      changes = _changes.stream.listen((_) => emit());
    }

    controller = StreamController<T>(
      onListen: () => unawaited(start()),
      onCancel: () => changes?.cancel(),
    );
    return controller.stream;
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
