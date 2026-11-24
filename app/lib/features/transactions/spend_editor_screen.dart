import 'package:daily_budget/core/copy/money_back_copy.dart';
import 'package:daily_budget/core/copy/storage_copy.dart';
import 'package:daily_budget/core/copy/transactions_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/help/label_description.dart';
import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/action_dock.dart';
import 'package:daily_budget/core/widgets/amount_field.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/budget_icon_button.dart';
import 'package:daily_budget/core/widgets/focus_ring.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/transactions/widgets/category_field.dart';
import 'package:daily_budget/features/transactions/widgets/delete_spend_sheet.dart';
import 'package:daily_budget/features/transactions/widgets/discard_spend_sheet.dart';
import 'package:daily_budget/features/transactions/widgets/money_back_switch.dart';
import 'package:daily_budget/features/transactions/widgets/note_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the editor did, named by what the entry **is after** the write: a
/// refund turned into a spend and saved is `updated`, not `moneyBackUpdated`
/// (D-084 (4), F-016 TC-016-11).
enum SpendEditorOutcome {
  added,
  updated,
  deleted,
  moneyBackAdded,
  moneyBackUpdated,
  moneyBackDeleted,
}

/// What the editor hands back when it closes after a write: what happened,
/// the covers the write took back (D-040), for the tab to explain, and the
/// day the spend was saved on (or deleted from), so a caller can say it moved.
typedef SpendEditorResult = ({
  SpendEditorOutcome outcome,
  List<CoverReduction> reductions,
  CalendarDate date,
});

/// The full-screen Add / Edit spend form (`transactions.md` §8). [editing]
/// null adds a spend, dated [initialDate] when given (day details opens it on
/// its day) and today otherwise; editing ignores [initialDate].
class SpendEditorScreen extends ConsumerStatefulWidget {
  const new({required this.month, this.editing, this.initialDate, super.key});

  final StoredMonth month;
  final StoredSpend? editing;
  final CalendarDate? initialDate;

  @override
  ConsumerState<SpendEditorScreen> createState() => _SpendEditorScreenState();
}

class _SpendEditorScreenState extends ConsumerState<SpendEditorScreen> {
  late final SpendDraft _initial;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  final _amountFocus = FocusNode(debugLabel: 'SpendAmount');
  late CalendarDate _date;
  SpendCategory? _category;
  late bool _moneyBack;
  bool _saving = false;
  bool _showErrors = false;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _initial = editing == null
        ? SpendDraft(date: widget.initialDate ?? ref.read(todayProvider))
        : SpendDraft.forEdit(editing.spend, note: editing.note);
    _date = _initial.date;
    _category = _initial.category;
    _moneyBack = _initial.moneyBack;
    _amount = TextEditingController(text: _initial.amountText);
    _note = TextEditingController(text: _initial.note);
    if (!_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _amountFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  SpendDraft get _draft => SpendDraft(
    date: _date,
    amountText: _amount.text,
    note: _note.text,
    category: _category,
    moneyBack: _moneyBack,
  );

  /// Whether leaving needs a Discard question. On Add the Money back switch
  /// alone is not input (nothing typed, nothing lost); a category picked on
  /// its own is (F-015 §2.6, D-082 (6)).
  bool get _hasUnsaved => _isEdit
      ? _draft.isChangedFrom(_initial)
      : _draft.copyWith(moneyBack: _initial.moneyBack).isChangedFrom(_initial);

  SpendDateLimits get _limits => spendDateLimits(
    month: widget.month.month,
    firstBudgetedDay: widget.month.firstBudgetedDay,
    today: ref.read(todayProvider),
    editedSpendDate: widget.editing?.spend.date,
  );

  void _touch() => setState(() {});

  Future<void> _pickDate() async {
    final limits = _limits;
    DateTime asLocal(CalendarDate d) => DateTime(d.year, d.month, d.day);
    final shown = _date.isBefore(limits.first)
        ? limits.first
        : _date.isAfter(limits.last)
        ? limits.last
        : _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: asLocal(shown),
      firstDate: asLocal(limits.first),
      lastDate: asLocal(limits.last),
      helpText: TransactionsCopy.datePickerHelp,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked == null || !mounted) return;
    setState(() => _date = CalendarDate.fromDateTime(picked));
  }

  Future<void> _save() async {
    if (_saving) return;
    final limits = _limits;
    final draft = _draft;
    if (draft.validate(limits).isNotEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final fields = draft.toFields(limits);
      final repository = ref.read(transactionRepositoryProvider);
      final today = ref.read(todayProvider);
      final now = ref.read(nowMillisProvider)();
      final editing = widget.editing;
      final written = editing == null
          ? await repository.add(
              widget.month.id,
              fields,
              today: today,
              now: now,
            )
          : await repository.update(
              editing.spend.id,
              fields,
              today: today,
              now: now,
            );
      if (!mounted) return;
      Navigator.of(context).pop<SpendEditorResult>((
        outcome: switch ((editing == null, draft.moneyBack)) {
          (true, false) => SpendEditorOutcome.added,
          (true, true) => SpendEditorOutcome.moneyBackAdded,
          (false, false) => SpendEditorOutcome.updated,
          (false, true) => SpendEditorOutcome.moneyBackUpdated,
        },
        reductions: written.reductions,
        date: draft.date,
      ));
    } on StorageException {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSaveError(messenger);
    }
  }

  Future<void> _delete() async {
    final editing = widget.editing;
    if (editing == null || _saving) return;
    final messenger = ScaffoldMessenger.of(context);
    final wasMoneyBack = editing.spend.direction == SpendDirection.moneyIn;
    final confirmed = await showDeleteSpendSheet(
      context,
      amount: editing.spend.amount,
      date: editing.spend.date,
      isMoneyBack: wasMoneyBack,
    );
    if (!confirmed || !mounted) return;
    setState(() => _saving = true);
    try {
      final written = await ref
          .read(transactionRepositoryProvider)
          .delete(editing.spend.id, today: ref.read(todayProvider));
      if (!mounted) return;
      Navigator.of(context).pop<SpendEditorResult>((
        outcome: wasMoneyBack
            ? SpendEditorOutcome.moneyBackDeleted
            : SpendEditorOutcome.deleted,
        reductions: written.reductions,
        date: editing.spend.date,
      ));
    } on StorageException {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSaveError(messenger);
    }
  }

  /// The save failed: say so above the Save button (the input stays).
  void _showSaveError(ScaffoldMessengerState messenger) {
    final docked = ActionDock.fits(context);
    messenger.showSnackBar(
      SnackBar(
        content: const Text(StorageCopy.saveError),
        margin: EdgeInsets.fromLTRB(
          BudgetSpacing.space4,
          0,
          BudgetSpacing.space4,
          docked ? _dockClearance : BudgetSpacing.space4,
        ),
      ),
    );
  }

  /// Room above the pinned dock: its button, padding and the rule.
  static const double _dockClearance = 96;

  String _title(bool moneyBack) => switch ((_isEdit, moneyBack)) {
    (false, false) => TransactionsCopy.addTitle,
    (true, false) => TransactionsCopy.editTitle,
    (false, true) => MoneyBackCopy.addTitle,
    (true, true) => MoneyBackCopy.editTitle,
  };

  String? _amountError(List<SpendError> errors) {
    for (final error in errors) {
      if (error.field != SpendField.amount) continue;
      return switch (error.problem) {
        SpendProblem.missing => TransactionsCopy.amountMissing,
        SpendProblem.notPositive => TransactionsCopy.amountNotPositive,
        SpendProblem.tooLarge => TransactionsCopy.amountTooLarge,
        _ => TransactionsCopy.amountBadFormat,
      };
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final errors = _showErrors ? _draft.validate(_limits) : <SpendError>[];
    final dateError = errors.any((e) => e.field == SpendField.date)
        ? TransactionsCopy.dateOutOfRange
        : null;
    final changed = _hasUnsaved;
    final canSave = !_isEdit || changed;
    final docked = ActionDock.fits(context);
    final moneyBack = _moneyBack;
    final motion = BudgetMotion.of(context);
    final wasMoneyBack =
        widget.editing?.spend.direction == SpendDirection.moneyIn;
    final save = BudgetButton.primary(
      label: _isEdit ? TransactionsCopy.saveChanges : TransactionsCopy.save,
      semanticsHint: _isEdit
          ? TransactionsCopy.saveChangesHint
          : moneyBack
          ? MoneyBackCopy.saveHint
          : TransactionsCopy.saveHint,
      loading: _saving,
      onPressed: canSave ? _save : null,
    );

    return PopScope(
      canPop: !changed || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await showDiscardSpendSheet(
          context,
          isEdit: _isEdit,
          isMoneyBack: moneyBack,
        );
        if (discard && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.all(BudgetSpacing.space2),
                  child: BudgetIconButton(
                    icon: Icons.close,
                    tooltip: TransactionsCopy.closeTooltip,
                    hint: TransactionsCopy.closeScreenHint,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    BudgetSpacing.space5,
                    0,
                    BudgetSpacing.space5,
                    BudgetSpacing.space6 +
                        (docked ? 0 : MediaQuery.paddingOf(context).bottom),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedSwitcher(
                        duration: motion.base,
                        child: Semantics(
                          key: ValueKey(moneyBack),
                          header: true,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              _title(moneyBack),
                              style: context.budgetText.headline.copyWith(
                                color: context.budgetColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: BudgetSpacing.space5),
                      AmountField(
                        label: moneyBack
                            ? MoneyBackCopy.amountLabel
                            : TransactionsCopy.amountLabel,
                        description: moneyBack
                            ? MoneyBackCopy.amountDescription
                            : TransactionsCopy.amountDescription,
                        currencyPrefix: moneyBack
                            ? MoneyBackCopy.amountPrefix
                            : AmountField.prefix,
                        controller: _amount,
                        focusNode: _amountFocus,
                        errorText: _amountError(errors),
                        large: true,
                        onChanged: (_) => _touch(),
                      ),
                      const SizedBox(height: BudgetSpacing.space3),
                      MoneyBackSwitch(
                        value: moneyBack,
                        onChanged: (on) => setState(() => _moneyBack = on),
                      ),
                      const SizedBox(height: BudgetSpacing.space3),
                      _DateField(
                        date: _date,
                        today: today,
                        errorText: dateError,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: BudgetSpacing.space5),
                      NoteField(
                        controller: _note,
                        onChanged: (_) => _touch(),
                        description: moneyBack
                            ? MoneyBackCopy.noteDescription
                            : TransactionsCopy.noteDescription,
                      ),
                      // A refund has no category: the row collapses and the
                      // picked one waits in the draft (F-016 AC-2).
                      AnimatedSize(
                        duration: motion.emphasis,
                        curve: BudgetMotion.decelerate,
                        alignment: Alignment.topCenter,
                        child: moneyBack
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(
                                  top: BudgetSpacing.space5,
                                ),
                                child: CategoryField(
                                  category: _draft.effectiveCategory,
                                  onPicked: (picked) =>
                                      setState(() => _category = picked),
                                ),
                              ),
                      ),
                      if (!docked) ...[
                        const SizedBox(height: BudgetSpacing.space6),
                        save,
                      ],
                      if (_isEdit) ...[
                        const SizedBox(height: BudgetSpacing.space8),
                        BudgetButton.destructive(
                          label: TransactionsCopy.delete,
                          semanticsHint: wasMoneyBack
                              ? MoneyBackCopy.deleteHint
                              : TransactionsCopy.deleteHint,
                          onPressed: _saving ? null : _delete,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (docked) ActionDock(action: save),
            ],
          ),
        ),
      ),
    );
  }
}

/// `Today · Mon, 9 Nov`, `Yesterday · Sun, 8 Nov` or `Sat, 7 Nov`.
String _dateValue(CalendarDate date, CalendarDate today) {
  final day = formatWeekdayDayMonth(date);
  return switch (date.daysUntil(today)) {
    0 => '${TransactionsCopy.todayTitle} · $day',
    1 => '${TransactionsCopy.yesterday} · $day',
    _ => day,
  };
}

class _DateField extends StatefulWidget {
  const new({
    required this.date,
    required this.today,
    required this.errorText,
    required this.onTap,
  });

  final CalendarDate date;
  final CalendarDate today;
  final String? errorText;
  final VoidCallback onTap;

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  final _focusNode = FocusNode(debugLabel: 'SpendDate');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final when = switch (widget.date.daysUntil(widget.today)) {
      0 => 'today, ${formatFullDate(widget.date)}',
      1 => 'yesterday, ${formatFullDate(widget.date)}',
      _ => formatFullDate(widget.date),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const LabelDescription(
          label: TransactionsCopy.dateLabel,
          description: TransactionsCopy.dateDescription,
          announce: false,
        ),
        const SizedBox(height: BudgetSpacing.space2),
        Semantics(
          button: true,
          label: TransactionsCopy.dateSemantics(when),
          hint: TransactionsCopy.dateDescription,
          excludeSemantics: true,
          onTap: widget.onTap,
          child: FocusRing(
            focusNode: _focusNode,
            child: InkWell(
              focusNode: _focusNode,
              onTap: widget.onTap,
              borderRadius: const BorderRadius.all(
                Radius.circular(BudgetRadii.md),
              ),
              child: InputDecorator(
                decoration: InputDecoration(
                  errorText: widget.errorText,
                  suffixIcon: Icon(
                    Icons.calendar_today_outlined,
                    color: colors.textSecondary,
                  ),
                ),
                child: Text(
                  _dateValue(widget.date, widget.today),
                  style: BudgetTypeScale.bodyLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
