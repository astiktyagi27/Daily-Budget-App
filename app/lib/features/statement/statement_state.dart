import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// The statement of one stored month, live (F-014 AC-15): the engine's
/// result for the month turned into typed statement data. Null while the
/// month does not exist.
final ProviderFamily<AsyncValue<MonthStatement?>, int> monthStatementProvider =
    Provider.family<AsyncValue<MonthStatement?>, int>(
      (ref, monthId) => ref
          .watch(monthResultProvider(monthId))
          .whenData((result) => result == null ? null : buildStatement(result)),
    );
