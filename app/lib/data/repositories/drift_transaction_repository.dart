import 'package:daily_budget/data/database/app_database.dart';
import 'package:daily_budget/data/repositories/drift_mappers.dart';
import 'package:daily_budget/data/repositories/drift_month_input.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:drift/drift.dart';

/// [TransactionRepository] on the Drift database. Every write, with the cover
/// reconciliation that follows it, is one transaction: all or nothing.
final class DriftTransactionRepository implements TransactionRepository {
  const new(this._db);

  final AppDatabase _db;

  @override
  Stream<List<StoredSpend>> watchMonthSpends(int monthId) {
    final query = _db.select(_db.transactions)
      ..where((t) => t.monthId.equals(monthId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.day),
        (t) => OrderingTerm.desc(t.createdAt),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return guardedStream(
      query.watch().map((rows) => [for (final row in rows) storedSpendOf(row)]),
    );
  }

  @override
  Future<SpendWriteOutcome> add(
    int monthId,
    SpendFields fields, {
    required CalendarDate today,
    required int now,
  }) {
    _validate(fields);
    return guarded(
      StorageFailureKind.write,
      () => _db.transaction(() async {
        final id = await _db
            .into(_db.transactions)
            .insert(
              TransactionsCompanion.insert(
                monthId: monthId,
                day: fields.date,
                amountPaise: fields.amount,
                direction: Value(directionColumn(fields.direction)),
                note: Value(fields.note ?? ''),
                category: Value(fields.category?.key),
                createdAt: now,
                editedAt: now,
              ),
            );
        return SpendWriteOutcome(
          id: id,
          reductions: await reconcileStoredCovers(_db, monthId, today),
        );
      }),
    );
  }

  @override
  Future<SpendWriteOutcome> update(
    int id,
    SpendFields fields, {
    required CalendarDate today,
    required int now,
  }) {
    _validate(fields);
    return guarded(
      StorageFailureKind.write,
      () => _db.transaction(() async {
        final row = await _rowOf(id);
        await (_db.update(
          _db.transactions,
        )..where((t) => t.id.equals(id))).write(
          TransactionsCompanion(
            day: Value(fields.date),
            amountPaise: Value(fields.amount),
            note: Value(fields.note ?? ''),
            direction: Value(directionColumn(fields.direction)),
            category: Value(fields.category?.key),
            editedAt: Value(now),
          ),
        );
        return SpendWriteOutcome(
          id: id,
          reductions: await reconcileStoredCovers(_db, row.monthId, today),
        );
      }),
    );
  }

  @override
  Future<void> updateCategory(
    int id,
    SpendCategory? category, {
    required int now,
  }) {
    return guarded(
      StorageFailureKind.write,
      () => _db.transaction(() async {
        final row = await _rowOf(id);
        if (directionOf(row.direction) == SpendDirection.moneyIn) {
          throw ArgumentError.value(
            id,
            'id',
            'is money in: it has no category',
          );
        }
        await (_db.update(
          _db.transactions,
        )..where((t) => t.id.equals(id))).write(
          TransactionsCompanion(
            category: Value(category?.key),
            editedAt: Value(now),
          ),
        );
      }),
    );
  }

  @override
  Future<SpendWriteOutcome> delete(int id, {required CalendarDate today}) {
    return guarded(
      StorageFailureKind.write,
      () => _db.transaction(() async {
        final row = await _rowOf(id);
        await (_db.delete(
          _db.transactions,
        )..where((t) => t.id.equals(id))).go();
        return SpendWriteOutcome(
          id: id,
          reductions: await reconcileStoredCovers(_db, row.monthId, today),
        );
      }),
    );
  }

  Future<TransactionRow> _rowOf(int id) async {
    final row = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) {
      throw ArgumentError.value(id, 'id', 'is not a stored transaction');
    }
    return row;
  }

  void _validate(SpendFields fields) {
    if (!fields.amount.isPositive) {
      throw ArgumentError.value(
        fields.amount.value,
        'amount',
        'must be above 0',
      );
    }
    if (fields.direction == SpendDirection.moneyIn && fields.category != null) {
      throw ArgumentError.value(
        fields.category,
        'category',
        'money in has no category',
      );
    }
  }
}
