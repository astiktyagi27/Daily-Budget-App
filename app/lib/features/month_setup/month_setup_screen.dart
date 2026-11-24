import 'dart:async';

import 'package:daily_budget/core/copy/month_setup_copy.dart';
import 'package:daily_budget/core/copy/storage_copy.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/action_dock.dart';
import 'package:daily_budget/core/widgets/amount_field.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/budget_icon_button.dart';
import 'package:daily_budget/core/widgets/budget_list_row.dart';
import 'package:daily_budget/core/widgets/budget_sheet.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/month_setup/month_setup_controller.dart';
import 'package:daily_budget/features/month_setup/widgets/discard_sheet.dart';
import 'package:daily_budget/features/month_setup/widgets/fixed_costs_section.dart';
import 'package:daily_budget/features/month_setup/widgets/salary_day_field.dart';
import 'package:daily_budget/features/month_setup/widgets/setup_action_dock.dart';
import 'package:daily_budget/features/month_setup/widgets/setup_preview_card.dart';
import 'package:daily_budget/features/month_setup/widgets/shortfall_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Month setup and **Edit this month** (F-008, `docs/design/screens/
/// month-setup.md`): one scrolling form with a live preview, a pinned daily
/// budget line in portrait and Confirm.
///
/// The form's state is `MonthSetupController`'s draft; this widget keeps the
/// text controllers and focus nodes and forwards edits. It never works out
/// money: every figure comes from the engine through `SetupPreview`.
class MonthSetupScreen extends ConsumerStatefulWidget {
  const new({required this.mode, super.key});

  final SetupMode mode;

  /// Pushes the screen over the tabs.
  static Future<void> open(BuildContext context, SetupMode mode) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => MonthSetupScreen(mode: mode)),
      );

  @override
  ConsumerState<MonthSetupScreen> createState() => _MonthSetupScreenState();
}

class _MonthSetupScreenState extends ConsumerState<MonthSetupScreen> {
  final _registry = ItemFieldRegistry();
  final _scroll = ScrollController();
  final _dayFocus = FocusNode(debugLabel: 'salary day');
  final _salaryFocus = FocusNode(debugLabel: 'salary');
  final _targetFocus = FocusNode(debugLabel: 'target');
  final _moneyLeftFocus = FocusNode(debugLabel: 'money left');
  final _confirmFocus = FocusNode(debugLabel: 'confirm');
  late final TextEditingController _salary;
  late final TextEditingController _target;
  late final TextEditingController _moneyLeft;

  /// True while a Confirm is being handled, from the tap until the sheet or
  /// the save is over: a second tap does nothing (AC-10).
  bool _busy = false;

  SetupMode get _mode => widget.mode;

  MonthSetupController get _controller =>
      ref.read(monthSetupControllerProvider(_mode).notifier);

  @override
  void initState() {
    super.initState();
    final draft = ref.read(monthSetupControllerProvider(_mode)).draft;
    _salary = TextEditingController(text: draft.salaryText);
    _target = TextEditingController(text: draft.targetText);
    _moneyLeft = TextEditingController(text: draft.moneyLeftText);
  }

  @override
  void dispose() {
    _registry.dispose();
    _scroll.dispose();
    for (final node in [
      _dayFocus,
      _salaryFocus,
      _targetFocus,
      _moneyLeftFocus,
      _confirmFocus,
    ]) {
      node.dispose();
    }
    _salary.dispose();
    _target.dispose();
    _moneyLeft.dispose();
    super.dispose();
  }

  /// The controller replaced the whole draft (a pre-filled setup left open
  /// past midnight became a fresh start): show its texts.
  void _draftReplaced() {
    _registry.startOver();
    final draft = ref.read(monthSetupControllerProvider(_mode)).draft;
    _salary.text = draft.salaryText;
    _target.text = draft.targetText;
    _moneyLeft.text = draft.moneyLeftText;
  }

  Future<void> _onBack() async {
    final state = ref.read(monthSetupControllerProvider(_mode));
    if (state.isSaving) return;
    // Back with the keyboard open only closes it (`month-setup.md` §6).
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }
    if (!state.changed) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showDiscardSheet(context);
    if (discard && mounted) Navigator.of(context).pop();
  }

  Future<void> _openDaySheet() async {
    await showBudgetSheet<void>(
      context: context,
      builder: (_) => SalaryDaySheet(mode: _mode),
    );
    if (mounted) _dayFocus.requestFocus();
  }

  void _setTargetOn({required bool on}) {
    _controller.setTargetOn(on: on);
    if (on) _focusAfterFrame(_targetFocus);
  }

  void _addItem() {
    final key = _controller.addItem();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus(_registry.find(key)?.nameFocus);
    });
  }

  void _removeItem(int key) {
    final removed = _controller.removeItem(key);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(MonthSetupCopy.removedMessage(removed.item.name)),
          duration: const Duration(seconds: 6),
          // A snackbar with an action stays until dismissed unless told not
          // to; it stays only while a screen reader is on (design §6, D-077).
          persist: MediaQuery.accessibleNavigationOf(context),
          action: SnackBarAction(
            label: MonthSetupCopy.undo,
            onPressed: () => _controller.restoreItem(removed),
          ),
        ),
      );
  }

  void _focusAfterFrame(FocusNode node) =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus(node);
      });

  /// Gives [node] focus and scrolls it into view.
  void _focus(FocusNode? node) {
    if (node == null) return;
    node.requestFocus();
    final context = node.context;
    if (context != null && context.mounted) {
      Scrollable.ensureVisible(
        context,
        duration: BudgetMotion.of(context).emphasis,
        curve: BudgetMotion.decelerate,
        alignment: 0.1,
      );
    }
  }

  /// Every text field of the form in the order Next walks them.
  List<FocusNode> _fieldOrder(SetupDraft draft) => [
    if (draft.kind == SetupKind.full) ...[
      _salaryFocus,
      if (draft.targetOn) _targetFocus,
    ] else
      _moneyLeftFocus,
    for (final item in draft.items) ...[
      _registry.of(item).nameFocus,
      _registry.of(item).amountFocus,
    ],
  ];

  /// Next on every field, Done on the form's last one.
  TextInputAction _keyFor(SetupDraft draft, FocusNode node) =>
      identical(node, _fieldOrder(draft).last)
      ? TextInputAction.done
      : TextInputAction.next;

  /// Next moves on; Done keeps the default (close the keyboard).
  VoidCallback? _nextFor(SetupDraft draft, FocusNode node) =>
      identical(node, _fieldOrder(draft).last) ? null : () => _focusAfter(node);

  /// The field's Next key: moves to the field after [from], skipping the
  /// buttons between them.
  void _focusAfter(FocusNode from) {
    final order = _fieldOrder(
      ref.read(monthSetupControllerProvider(_mode)).draft,
    );
    final index = order.indexOf(from);
    if (index >= 0 && index + 1 < order.length) _focus(order[index + 1]);
  }

  FocusNode? _nodeFor(FieldError error) => switch (error.field) {
    FieldId.salaryDay => _dayFocus,
    FieldId.salary => _salaryFocus,
    FieldId.target => _targetFocus,
    FieldId.moneyLeft => _moneyLeftFocus,
    FieldId.itemName => _registry.find(error.itemKey!)?.nameFocus,
    FieldId.itemAmount => _registry.find(error.itemKey!)?.amountFocus,
  };

  /// **Fix my numbers**: the first fixed-cost amount, or the money field
  /// when there are no items.
  void _focusFixedCosts() {
    final draft = ref.read(monthSetupControllerProvider(_mode)).draft;
    final first = draft.items.firstOrNull;
    if (first != null) {
      _focus(_registry.find(first.key)?.amountFocus);
      return;
    }
    _focus(
      draft.kind == SetupKind.full
          ? (draft.targetOn ? _targetFocus : _salaryFocus)
          : _moneyLeftFocus,
    );
  }

  Future<void> _confirm() async {
    if (_busy) return;
    _busy = true;
    try {
      await _handle(await _controller.submit());
    } finally {
      _busy = false;
    }
  }

  Future<void> _handle(SubmitOutcome outcome) async {
    if (!mounted) return;
    switch (outcome) {
      case SubmitSaved() || SubmitMonthEnded():
        Navigator.of(context).pop();
      case SubmitInvalid(:final first):
        // Let the errors appear first, then move to the first one.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focus(_nodeFor(first));
        });
      case SubmitFailed():
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text(StorageCopy.saveError)));
      case SubmitIgnored():
        break;
      case final SubmitNeedsChoice need:
        final choice = await showShortfallSheet(context, need);
        if (!mounted) return;
        switch (choice) {
          case ShortfallChoice.fix:
            _focusFixedCosts();
          case ShortfallChoice.dismissed:
            _confirmFocus.requestFocus();
          case ShortfallChoice.continueAnyway:
            await _handle(await _controller.submit(continueAnyway: true));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      monthSetupControllerProvider(_mode).select((s) => s.initial),
      (_, _) => _draftReplaced(),
    );
    final state = ref.watch(monthSetupControllerProvider(_mode));
    final draft = state.draft;
    final today = ref.watch(todayProvider);
    final preview = ref.watch(setupPreviewProvider(_mode));
    final isEdit = _mode is EditMonthMode;
    final problems = state.showErrors ? draft.validate() : const <FieldError>[];
    final docked = ActionDock.fits(context);

    final confirm = BudgetButton.primary(
      label: isEdit ? MonthSetupCopy.confirmEdit : MonthSetupCopy.confirmNew,
      semanticsHint: isEdit
          ? MonthSetupCopy.confirmEditHint
          : MonthSetupCopy.confirmNewHint,
      focusNode: _confirmFocus,
      loading: state.isSaving,
      onPressed: isEdit && !state.changed ? null : () => unawaited(_confirm()),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_onBack());
      },
      child: Scaffold(
        // With the dock the Scaffold must not resize the body itself: the
        // dock is lifted by the keyboard inset instead, and the body ends
        // above it (a snackbar still sits above the dock).
        resizeToAvoidBottomInset: !docked,
        bottomNavigationBar: docked
            ? Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: ActionDock(
                  line: SetupDockLine(
                    preview: preview,
                    draft: draft,
                    isEdit: isEdit,
                  ),
                  action: confirm,
                ),
              )
            : null,
        body: SafeArea(
          bottom: !docked,
          child: SingleChildScrollView(
            controller: _scroll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(onBack: () => unawaited(_onBack())),
                _Gutter(child: _Title(mode: _mode)),
                if (_mode is NewMonthMode && draft.kind == SetupKind.full) ...[
                  const SizedBox(height: BudgetSpacing.space3),
                  const _Gutter(
                    child: _NoticeLine(MonthSetupCopy.prefillNotice),
                  ),
                ],
                const SizedBox(height: BudgetSpacing.space5),
                _Gutter(child: _salaryDay(draft, problems)),
                const SizedBox(height: BudgetSpacing.space5),
                _kindBlock(draft, today, problems),
                const SizedBox(height: BudgetSpacing.space6),
                _Gutter(child: _fixedCosts(draft, problems)),
                const SizedBox(height: BudgetSpacing.space6),
                _Gutter(
                  child: SetupPreviewCard(
                    preview: preview,
                    draft: draft,
                    today: today,
                    isEdit: isEdit,
                  ),
                ),
                if (!docked) ...[
                  const SizedBox(height: BudgetSpacing.space5),
                  _Gutter(child: confirm),
                ],
                const SizedBox(height: BudgetSpacing.space8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _problemText(List<FieldError> problems, FieldId field) {
    for (final error in problems) {
      if (error.field == field) return _message(field, error.problem);
    }
    return null;
  }

  Widget _salaryDay(SetupDraft draft, List<FieldError> problems) {
    final day = draft.salaryDay;
    if (_mode is FirstSetupMode) {
      return SalaryDayField(
        day: day,
        focusNode: _dayFocus,
        onTap: () => unawaited(_openDaySheet()),
        errorText: _problemText(problems, FieldId.salaryDay),
      );
    }
    return SalaryDayFixed(day: day!);
  }

  Widget _kindBlock(
    SetupDraft draft,
    CalendarDate today,
    List<FieldError> problems,
  ) {
    final motion = BudgetMotion.of(context);
    final controller = _controller;
    final block = switch (draft.kind) {
      SetupKind.full => Column(
        key: const ValueKey(SetupKind.full),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Gutter(
            child: AmountField(
              label: MonthSetupCopy.salaryLabel,
              description: MonthSetupCopy.salaryDescription,
              controller: _salary,
              focusNode: _salaryFocus,
              errorText: _problemText(problems, FieldId.salary),
              textInputAction: _keyFor(draft, _salaryFocus),
              onEditingComplete: _nextFor(draft, _salaryFocus),
              onChanged: controller.setSalary,
            ),
          ),
          const SizedBox(height: BudgetSpacing.space3),
          BudgetListRow(
            label: MonthSetupCopy.targetSwitchLabel,
            description: MonthSetupCopy.targetSwitchDescription,
            trailing: Switch(
              value: draft.targetOn,
              onChanged: (on) => _setTargetOn(on: on),
            ),
            onTap: () => _setTargetOn(on: !draft.targetOn),
          ),
          AnimatedSize(
            duration: motion.emphasis,
            curve: BudgetMotion.decelerate,
            alignment: Alignment.topCenter,
            child: draft.targetOn
                ? _Gutter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: BudgetSpacing.space3),
                      child: AmountField(
                        label: MonthSetupCopy.targetLabel,
                        description: MonthSetupCopy.targetDescription,
                        controller: _target,
                        focusNode: _targetFocus,
                        errorText: _problemText(problems, FieldId.target),
                        textInputAction: _keyFor(draft, _targetFocus),
                        onEditingComplete: _nextFor(draft, _targetFocus),
                        onChanged: controller.setTarget,
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
      SetupKind.midMonth => _midMonthBlock(draft, today, problems),
    };
    return AnimatedSwitcher(
      duration: motion.base,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      child: block,
    );
  }

  Widget _midMonthBlock(
    SetupDraft draft,
    CalendarDate today,
    List<FieldError> problems,
  ) {
    final mode = _mode;
    final String label;
    final String description;
    if (mode is EditMonthMode) {
      label = MonthSetupCopy.moneyLeftEditLabel(mode.stored.firstBudgetedDay);
      description = MonthSetupCopy.moneyLeftEditDescription(
        mode.stored.firstBudgetedDay,
      );
    } else {
      label = MonthSetupCopy.moneyLeftLabel;
      description = MonthSetupCopy.moneyLeftDescription;
    }
    final day = draft.salaryDay;
    return Column(
      key: const ValueKey(SetupKind.midMonth),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mode is! EditMonthMode && day != null) ...[
          _Gutter(
            child: _NoticeLine(
              MonthSetupCopy.midMonthNotice(
                today.daysUntil(BudgetMonth.containing(day, today).end) + 1,
              ),
            ),
          ),
          const SizedBox(height: BudgetSpacing.space5),
        ],
        _Gutter(
          child: AmountField(
            label: label,
            description: description,
            controller: _moneyLeft,
            focusNode: _moneyLeftFocus,
            errorText: _problemText(problems, FieldId.moneyLeft),
            textInputAction: _keyFor(draft, _moneyLeftFocus),
            onEditingComplete: _nextFor(draft, _moneyLeftFocus),
            onChanged: _controller.setMoneyLeft,
          ),
        ),
      ],
    );
  }

  Widget _fixedCosts(SetupDraft draft, List<FieldError> problems) {
    final full = draft.kind == SetupKind.full;
    final errors = <int, ItemErrors>{};
    for (final error in problems) {
      final key = error.itemKey;
      if (key == null) continue;
      final old = errors[key] ?? (name: null, amount: null);
      final text = _message(error.field, error.problem);
      errors[key] = error.field == FieldId.itemName
          ? (name: text, amount: old.amount)
          : (name: old.name, amount: text);
    }
    return FixedCostsSection(
      header: full
          ? MonthSetupCopy.fixedCostsHeader
          : MonthSetupCopy.stillToPayHeader,
      description: full
          ? MonthSetupCopy.fixedCostsDescription
          : MonthSetupCopy.stillToPayDescription,
      items: draft.items,
      registry: _registry,
      total: draft.totalFixedCosts,
      canAdd: draft.canAddItem,
      errors: errors,
      onAdd: _addItem,
      onRename: _controller.renameItem,
      onAmount: _controller.setItemAmount,
      onRemove: _removeItem,
      lastField: _fieldOrder(draft).last,
      onNext: _focusAfter,
    );
  }

  /// The F-008 §5 error text for a problem.
  static String _message(FieldId field, FieldProblem problem) =>
      switch ((field, problem)) {
        (FieldId.salaryDay, _) => MonthSetupCopy.salaryDayError,
        (FieldId.salary, FieldProblem.missing) => MonthSetupCopy.salaryMissing,
        (FieldId.salary, FieldProblem.notPositive) =>
          MonthSetupCopy.salaryNotPositive,
        (FieldId.target, FieldProblem.missing) => MonthSetupCopy.targetMissing,
        (FieldId.target, FieldProblem.aboveSalary) =>
          MonthSetupCopy.targetAboveSalary,
        (FieldId.target, FieldProblem.notPositive) =>
          MonthSetupCopy.targetNotPositive,
        (FieldId.moneyLeft, FieldProblem.missing) =>
          MonthSetupCopy.moneyLeftMissing,
        (FieldId.moneyLeft, FieldProblem.notPositive) =>
          MonthSetupCopy.moneyLeftNotPositive,
        (FieldId.itemName, _) => MonthSetupCopy.itemNameMissing,
        (_, FieldProblem.tooLarge) => MonthSetupCopy.tooLarge,
        // Letters, a decimal comma, more than 2 decimals.
        (_, _) => MonthSetupCopy.badFormat,
      };
}

/// The page's side margins; list rows bring their own.
class _Gutter extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: BudgetSpacing.space5),
    child: child,
  );
}

/// The 56 dp top bar: back only, no title text (`month-setup.md` §3).
class _TopBar extends StatelessWidget {
  const new({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: BudgetSpacing.space2),
        child: BudgetIconButton(
          icon: Icons.arrow_back,
          tooltip: MonthSetupCopy.back,
          hint: MonthSetupCopy.backHint,
          onPressed: onBack,
        ),
      ),
    ),
  );
}

class _Title extends StatelessWidget {
  const new({required this.mode});

  final SetupMode mode;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      switch (mode) {
        FirstSetupMode() => MonthSetupCopy.titleFirst,
        NewMonthMode() => MonthSetupCopy.titleNew,
        EditMonthMode() => MonthSetupCopy.titleEdit,
      },
      style: context.budgetText.headline.copyWith(
        color: context.budgetColors.textPrimary,
      ),
    ),
  );
}

/// An inline note: a 16 dp info icon and a `body` line (`month-setup.md` §3).
class _NoticeLine extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Semantics(
      container: true,
      label: text,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(width: BudgetSpacing.space2),
            Expanded(
              child: Text(
                text,
                style: BudgetTypeScale.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
