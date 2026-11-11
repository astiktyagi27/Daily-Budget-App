import 'package:daily_budget/core/providers/preferences_providers.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;

/// Whether the first-time hint [HintId] has been dismissed (F-004 AC-7…AC-9).
/// Read synchronously from the store opened before `runApp`, so a dismissed
/// hint never flashes on the first frame.
final NotifierProviderFamily<HintSeenNotifier, bool, HintId> hintSeenProvider =
    NotifierProvider.family<HintSeenNotifier, bool, HintId>(
      HintSeenNotifier.new,
    );

class HintSeenNotifier extends Notifier<bool> {
  new(this._id);

  final HintId _id;

  @override
  bool build() => ref.watch(hintRepositoryProvider).isSeen(_id);

  /// Hides the hint at once, then saves "seen". Only a dismissal counts as
  /// seen; viewing the tab writes nothing (AC-9). If the save fails the hint
  /// stays hidden for this session and shows again next launch (AC-12). A
  /// second call (double tap on Got it) writes nothing more.
  Future<void> dismiss() async {
    if (state) return;
    state = true;
    await ref.read(hintRepositoryProvider).markSeen(_id);
  }
}
