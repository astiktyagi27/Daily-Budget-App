import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// Which setup the screen is for (F-008 plan §1). The screen is given one
/// mode object and keeps it, so the controller family is keyed by it.
///
/// Whether a first setup asks for the salary or for the money left is not a
/// mode: it follows the chosen salary day and today (D-034), inside the
/// draft.
sealed class SetupMode {
  const new();
}

/// No month yet: the salary day is chosen on the screen.
final class FirstSetupMode extends SetupMode {
  const new();
}

/// A month after [lastMonth]. Today being its start day gives the pre-filled
/// setup; a later day is a fresh start from today (D-057).
final class NewMonthMode extends SetupMode {
  const new(this.lastMonth);

  final StoredMonth lastMonth;
}

/// **Edit this month**: the saved values of [stored], applied from today
/// (D-037).
final class EditMonthMode extends SetupMode {
  const new(this.stored);

  final StoredMonth stored;
}

/// What the form holds right now.
@immutable
final class MonthSetupState {
  const new({
    required this.draft,
    required this.initial,
    this.isSaving = false,
    this.showErrors = false,
  });

  final SetupDraft draft;

  /// The draft as the screen opened, to tell a change from none.
  final SetupDraft initial;

  /// True from the moment a save starts. A second tap does nothing (AC-10).
  final bool isSaving;

  /// Set once Confirm found a problem: from then on every problem shows.
  final bool showErrors;

  bool get changed => draft.isChangedFrom(initial);

  MonthSetupState copyWith({
    SetupDraft? draft,
    SetupDraft? initial,
    bool? isSaving,
    bool? showErrors,
  }) => MonthSetupState(
    draft: draft ?? this.draft,
    initial: initial ?? this.initial,
    isSaving: isSaving ?? this.isSaving,
    showErrors: showErrors ?? this.showErrors,
  );
}

/// Why the user must choose before saving (D-036, D-043).
enum ShortfallKind { shortfall, zero }

/// What Confirm did (F-008 plan §1.6).
sealed class SubmitOutcome {
  const new();
}

/// Saved; the screen closes.
final class SubmitSaved extends SubmitOutcome {
  const new();
}

/// A field has a problem; [first] is the one to focus.
final class SubmitInvalid extends SubmitOutcome {
  const new(this.first);

  final FieldError first;
}

/// The numbers leave nothing to spend: the user chooses between fixing them
/// and continuing with ₹0 a day.
final class SubmitNeedsChoice extends SubmitOutcome {
  const new({
    required this.kind,
    required this.shortfall,
    required this.basis,
    required this.isEdit,
  });

  final ShortfallKind kind;

  /// How much is missing; ₹0 for [ShortfallKind.zero].
  final Paise shortfall;

  final PreviewBasis basis;

  /// An edit: the sheet says "This change leaves you … short".
  final bool isEdit;
}

/// The storage refused the write; every value stays on screen (AC-11).
final class SubmitFailed extends SubmitOutcome {
  const new(this.error);

  final StorageException error;
}

/// A second tap while saving, or Save changes with nothing changed.
final class SubmitIgnored extends SubmitOutcome {
  const new();
}

/// An edit left open past the end of its month (midnight): there is nothing
/// to save into any more.
final class SubmitMonthEnded extends SubmitOutcome {
  const new();
}

/// A deleted item and where it was, for **Undo**.
typedef RemovedItem = ({int index, DraftItem item});

final NotifierProviderFamily<MonthSetupController, MonthSetupState, SetupMode>
monthSetupControllerProvider = NotifierProvider.autoDispose
    .family<MonthSetupController, MonthSetupState, SetupMode>(
      MonthSetupController.new,
    );

/// The preview card's content, for the draft and the one `todayProvider`
/// value: the screen and Confirm use the same numbers (F-008 AC-7, S4).
final ProviderFamily<SetupPreview, SetupMode> setupPreviewProvider = Provider
    .autoDispose
    .family<SetupPreview, SetupMode>((ref, mode) {
      final draft = ref.watch(
        monthSetupControllerProvider(mode).select((state) => state.draft),
      );
      final today = ref.watch(todayProvider);
      return ref
          .watch(monthSetupControllerProvider(mode).notifier)
          .previewFor(draft, today);
    });

/// Owns the draft of one setup screen: field edits, Undo, the mode a first
/// setup is in, and Confirm (F-008 T-214b). The draft itself is pure Dart
/// (`SetupDraft`); this adds today, the repositories and the outcomes.
class MonthSetupController extends Notifier<MonthSetupState> {
  new(this.mode);

  final SetupMode mode;

  @override
  MonthSetupState build() {
    ref.listen(todayProvider, (_, today) => _todayChanged(today));
    final draft = _openingDraft(ref.read(todayProvider));
    return MonthSetupState(draft: draft, initial: draft);
  }

  SetupDraft _openingDraft(CalendarDate today) => switch (mode) {
    FirstSetupMode() => SetupDraft.firstSetup(today: today),
    NewMonthMode(:final lastMonth) => _newMonthDraft(lastMonth, today),
    EditMonthMode(:final stored) => SetupDraft.forEdit(
      salaryDay: stored.month.salaryDay,
      saved: _valuesInForce(stored, today),
    ),
  };

  // On the new month's start day the last period's numbers are pre-filled;
  // on any later day it is a fresh start from today (D-057).
  SetupDraft _newMonthDraft(StoredMonth lastMonth, CalendarDate today) {
    final salaryDay = lastMonth.month.salaryDay;
    return BudgetMonth.containing(salaryDay, today).start == today
        ? SetupDraft.newMonth(
            salaryDay: salaryDay,
            previous: _valuesInForce(lastMonth, today),
          )
        : SetupDraft.lateStart(salaryDay: salaryDay);
  }

  // The values of the period in force on [today], from the engine (a month
  // that has ended answers with its last period).
  PeriodValues _valuesInForce(StoredMonth stored, CalendarDate today) =>
      computeMonth(
        MonthInput(
          month: stored.month,
          firstBudgetedDay: stored.firstBudgetedDay,
          periods: stored.periods,
          today: today,
        ),
      ).currentPeriod.period.values;

  /// Midnight or a return from the background moved today (F-008 §4): the
  /// form follows it, so the numbers shown are the ones Confirm saves.
  void _todayChanged(CalendarDate today) {
    final draft = state.draft;
    switch (mode) {
      case FirstSetupMode():
        final day = draft.salaryDay;
        if (day != null) {
          state = state.copyWith(draft: draft.chooseSalaryDay(day, today));
        }
      case NewMonthMode(:final lastMonth):
        // A pre-filled setup is only right on the start day; any later day
        // is a fresh start (the typed values are not for that).
        if (draft.kind == SetupKind.full) {
          final fresh = _newMonthDraft(lastMonth, today);
          if (fresh.kind != SetupKind.full) {
            state = state.copyWith(draft: fresh, initial: fresh);
          }
        }
      case EditMonthMode():
        break;
    }
  }

  void _set(SetupDraft draft) => state = state.copyWith(draft: draft);

  void chooseSalaryDay(int day) =>
      _set(state.draft.chooseSalaryDay(day, ref.read(todayProvider)));

  void setSalary(String text) => _set(state.draft.copyWith(salaryText: text));

  void setTargetOn({required bool on}) =>
      _set(state.draft.copyWith(targetOn: on));

  void setTarget(String text) => _set(state.draft.copyWith(targetText: text));

  void setMoneyLeft(String text) =>
      _set(state.draft.copyWith(moneyLeftText: text));

  /// Adds an empty item and returns its key.
  int addItem() {
    final draft = state.draft.addItem();
    _set(draft);
    return draft.items.last.key;
  }

  void renameItem(int key, String name) =>
      _set(state.draft.renameItem(key, name));

  void setItemAmount(int key, String text) =>
      _set(state.draft.setItemAmount(key, text));

  /// Removes the item; keep the result to offer **Undo**.
  RemovedItem removeItem(int key) {
    final index = state.draft.indexOfItem(key);
    final item = state.draft.items[index];
    _set(state.draft.removeItem(key));
    return (index: index, item: item);
  }

  /// Puts a removed item back in its place. False when the list has
  /// meanwhile filled up to the limit.
  bool restoreItem(RemovedItem removed) {
    if (!state.draft.canAddItem) return false;
    _set(state.draft.insertItem(removed.index, removed.item));
    return true;
  }

  /// The preview for [draft] on [today]. An edit passes the engine's budgets
  /// of the budgeted days before today as `earlierBudgets` (S4); it has no
  /// preview once today is outside the month being edited.
  SetupPreview previewFor(SetupDraft draft, CalendarDate today) =>
      switch (mode) {
        EditMonthMode(:final stored) =>
          _canEditOn(stored, today)
              ? draft.preview(
                  today: today,
                  earlierBudgets: _earlierBudgets(stored, today),
                )
              : const PreviewNeedsAmount(),
        FirstSetupMode() || NewMonthMode() => draft.preview(today: today),
      };

  static bool _canEditOn(StoredMonth stored, CalendarDate today) =>
      stored.month.contains(today) && !today.isBefore(stored.firstBudgetedDay);

  // Day budgets do not depend on spends or covers, so the engine runs with
  // the stored periods alone.
  static List<Paise> _earlierBudgets(StoredMonth stored, CalendarDate today) {
    final result = computeMonth(
      MonthInput(
        month: stored.month,
        firstBudgetedDay: stored.firstBudgetedDay,
        periods: stored.periods,
        today: today,
      ),
    );
    return [
      for (final day in result.days)
        if (day.status != DayStatus.notBudgeted && day.date.isBefore(today))
          day.budget!,
    ];
  }

  /// Confirm (**Start my month** / **Save changes**). Reads today again, so
  /// it saves the month containing today at this moment (D-048).
  ///
  /// With a shortfall or a ₹0 spendable it returns [SubmitNeedsChoice] and
  /// saves nothing until called again with [continueAnyway].
  Future<SubmitOutcome> submit({bool continueAnyway = false}) async {
    final current = state;
    if (current.isSaving) return const SubmitIgnored();
    if (mode is EditMonthMode && !current.changed) {
      return const SubmitIgnored();
    }
    final draft = current.draft;
    final problems = draft.validate();
    if (problems.isNotEmpty) {
      state = current.copyWith(showErrors: true);
      return SubmitInvalid(problems.first);
    }
    final today = ref.read(todayProvider);
    final preview = previewFor(draft, today);
    if (preview is! PreviewReady) return const SubmitMonthEnded();
    final outcome = preview.outcome;
    final needsChoice = outcome is! Spread;
    if (needsChoice && !continueAnyway) {
      return SubmitNeedsChoice(
        kind: outcome is Shortfall
            ? ShortfallKind.shortfall
            : ShortfallKind.zero,
        shortfall: preview.shortfall,
        basis: preview.basis,
        isEdit: mode is EditMonthMode,
      );
    }
    state = current.copyWith(isSaving: true);
    try {
      final now = ref.read(nowMillisProvider)();
      final period = BudgetPeriod(
        start: today,
        changedAt: now,
        values: draft.toPeriodValues(),
        continuedWithShortfall: needsChoice,
      );
      final repository = ref.read(monthRepositoryProvider);
      switch (mode) {
        case EditMonthMode(:final stored):
          await repository.addPeriod(stored.id, period);
        case FirstSetupMode() || NewMonthMode():
          await repository.confirmMonth(
            NewMonth(
              month: preview.month,
              firstBudgetedDay: today,
              firstPeriod: period,
              confirmedAt: now,
            ),
          );
      }
    } on StorageException catch (error) {
      state = state.copyWith(isSaving: false);
      return SubmitFailed(error);
    }
    return const SubmitSaved();
  }
}
