import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show NotifierProviderFamily, ProviderFamily;

/// The stored months, newest first, live: what ‹ and › move between (D-074).
/// Missed months leave gaps, so ‹ can jump from Dec to Sep.
final StreamProvider<List<MonthRef>> monthIndexProvider =
    StreamProvider<List<MonthRef>>(
      (ref) => ref.watch(monthRepositoryProvider).watchMonthIndex(),
      retry: _noRetry,
    );

Duration? _noRetry(int retryCount, Object error) => null;

/// Where a month browser stands in the month index: pure, so the limits are
/// checked without a screen. [ids] are the month ids, newest first; [index]
/// is the viewed one (0 = the latest month).
final class MonthBrowse {
  const new({required this.ids, required this.index});

  /// The browse position of [viewedId] in [ids]; an id that is not stored
  /// (or null) means the latest month.
  factory of(List<int> ids, int? viewedId) {
    final found = viewedId == null ? -1 : ids.indexOf(viewedId);
    return MonthBrowse(ids: ids, index: found < 0 ? 0 : found);
  }

  final List<int> ids;

  final int index;

  int get viewedId => ids[index];

  bool get isLatest => index == 0;

  /// ‹ is disabled on the first stored month.
  bool get canGoBack => index < ids.length - 1;

  /// › is disabled on the latest month.
  bool get canGoForward => index > 0;

  int get previousId => ids[index + 1];

  int get nextId => ids[index - 1];
}

/// The month one screen is looking at, remembered while the app runs and set
/// back to the latest month when the day changes (D-074). One instance per
/// consumer (the key), so the calendar, the Dashboard and the statement each
/// remember their own month. The state is a month id; null is the latest.
final NotifierProviderFamily<MonthBrowser, int?, String> monthBrowserProvider =
    NotifierProvider.family<MonthBrowser, int?, String>(MonthBrowser.new);

class MonthBrowser extends Notifier<int?> {
  new(this.consumer);

  /// Which screen owns this instance (`calendar`, `dashboard`, ...).
  final String consumer;

  @override
  int? build() {
    ref.listen(todayProvider, (previous, next) => state = null);
    return null;
  }

  /// Views month [id]; null goes back to the latest month.
  // A setter-style method keeps the call sites readable.
  // ignore: use_setters_to_change_properties
  void view(int? id) => state = id;
}

/// The browse position of consumer `key`, once the month index has loaded.
/// Null when no month is stored.
final ProviderFamily<AsyncValue<MonthBrowse?>, String> monthBrowseProvider =
    Provider.family<AsyncValue<MonthBrowse?>, String>((ref, key) {
      final viewed = ref.watch(monthBrowserProvider(key));
      return ref
          .watch(monthIndexProvider)
          .whenData(
            (months) => months.isEmpty
                ? null
                : MonthBrowse.of([for (final m in months) m.id], viewed),
          );
    });
