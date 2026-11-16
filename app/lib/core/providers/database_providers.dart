import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/data/database/database_connection.dart';
import 'package:daily_budget/data/repositories/drift_month_repository.dart';
import 'package:daily_budget/data/repositories/drift_savings_repository.dart';
import 'package:daily_budget/data/repositories/drift_transaction_repository.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/data/repositories/savings_repository.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:logging/logging.dart';

final _log = Logger('database');

/// How the app creates its database. Tests override it to point at a fixture
/// file; the app uses the real file in its private folder.
final databaseOpenerProvider = Provider<AppDatabase Function()>(
  (ref) => openAppDatabase,
);

/// The opened money database, or a [StorageException] when it cannot be
/// opened (F-007 plan 1.5).
///
/// Opening runs a probe query, which is what makes a corrupt file or a newer
/// schema fail here instead of in the middle of a screen. A failure is never
/// retried automatically: the storage error screen's **Try again** invalidates
/// this provider. The file is never deleted or recreated.
///
/// The preferences store is a separate provider, so theme and tour still work
/// when this one fails (F-007 section 4, TC-007-34).
final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final database = ref.watch(databaseOpenerProvider)();
  ref.onDispose(database.close);
  try {
    await database.customSelect('SELECT count(*) FROM budget_months').get();
  } on Object catch (error) {
    final failure = StorageException.from(error, kind: StorageFailureKind.open);
    // Only the kind is logged, never the cause (it can hold a file path).
    _log.warning('database open failed: ${failure.kind.name}');
    await _closeQuietly(database);
    throw failure;
  }
  _log.info('database opened');
  return database;
}, retry: _noRetry);

Future<void> _closeQuietly(AppDatabase database) async {
  try {
    await database.close();
  } on Object {
    // Nothing to do: the open already failed and was logged.
  }
}

/// The opened database. Only read below `DatabaseGate`, which shows the tabs
/// once [appDatabaseProvider] has a value; before that it throws.
AppDatabase _openDatabase(Ref ref) =>
    ref.watch(appDatabaseProvider).requireValue;

final monthRepositoryProvider = Provider<MonthRepository>(
  (ref) => DriftMonthRepository(_openDatabase(ref)),
);

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => DriftTransactionRepository(_openDatabase(ref)),
);

final savingsRepositoryProvider = Provider<SavingsRepository>(
  (ref) => DriftSavingsRepository(_openDatabase(ref)),
);

/// UTC milliseconds since 1970 from the app clock (`clockProvider`), for the
/// `created_at`, `changed_at` and `made_at` columns. Used only for ordering.
/// Read failures are shown on the screen's error state with **Try again**
/// (F-007 section 2.6), not retried silently in the background.
Duration? _noRetry(int retryCount, Object error) => null;

final nowMillisProvider = Provider<int Function()>((ref) {
  final clock = ref.watch(clockProvider);
  return () => clock().millisecondsSinceEpoch;
});

final StreamProviderFamily<StoredMonth?, int> storedMonthProvider =
    StreamProvider.family<StoredMonth?, int>(
      (ref, monthId) => ref.watch(monthRepositoryProvider).watchMonth(monthId),
      retry: _noRetry,
    );

final StreamProviderFamily<List<StoredSpend>, int> monthSpendsProvider =
    StreamProvider.family<List<StoredSpend>, int>(
      (ref, monthId) =>
          ref.watch(transactionRepositoryProvider).watchMonthSpends(monthId),
      retry: _noRetry,
    );

final StreamProviderFamily<List<Cover>, int> monthCoversProvider =
    StreamProvider.family<List<Cover>, int>(
      (ref, monthId) =>
          ref.watch(savingsRepositoryProvider).watchCovers(monthId),
      retry: _noRetry,
    );

/// Every stored fact of one month plus today, as the engine's input. It
/// updates live when the month, a period, a spend or a cover changes
/// (F-007 AC-5). Null while the month does not exist.
final ProviderFamily<AsyncValue<MonthInput?>, int> monthInputProvider =
    Provider.family<AsyncValue<MonthInput?>, int>((ref, monthId) {
      final month = ref.watch(storedMonthProvider(monthId));
      final spends = ref.watch(monthSpendsProvider(monthId));
      final covers = ref.watch(monthCoversProvider(monthId));
      final today = ref.watch(todayProvider);
      if (month case AsyncError(:final error, :final stackTrace)) {
        return AsyncError(error, stackTrace);
      }
      if (spends case AsyncError(:final error, :final stackTrace)) {
        return AsyncError(error, stackTrace);
      }
      if (covers case AsyncError(:final error, :final stackTrace)) {
        return AsyncError(error, stackTrace);
      }
      final stored = month.value;
      final spendList = spends.value;
      final coverList = covers.value;
      if (!month.hasValue || spendList == null || coverList == null) {
        return const AsyncLoading();
      }
      if (stored == null) return const AsyncData(null);
      return AsyncData(
        MonthInput(
          month: stored.month,
          firstBudgetedDay: stored.firstBudgetedDay,
          periods: stored.periods,
          today: today,
          spends: [for (final s in spendList) s.spend],
          covers: coverList,
        ),
      );
    });

/// The engine's output for one month (F-006), recomputed whenever
/// [monthInputProvider] changes. Day budgets are never read from storage.
final ProviderFamily<AsyncValue<MonthResult?>, int> monthResultProvider =
    Provider.family<AsyncValue<MonthResult?>, int>(
      (ref, monthId) => ref
          .watch(monthInputProvider(monthId))
          .whenData((input) => input == null ? null : computeMonth(input)),
    );
