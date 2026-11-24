import 'dart:async';

import 'package:daily_budget/core/copy/day_details_copy.dart';
import 'package:daily_budget/core/copy/storage_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/day_details_provider.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:daily_budget/core/widgets/budget_icon_button.dart';
import 'package:daily_budget/core/widgets/decision_sheet.dart';
import 'package:daily_budget/core/widgets/empty_state.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/day_details/budget_change_text.dart';
import 'package:daily_budget/features/day_details/day_status.dart';
import 'package:daily_budget/features/day_details/widgets/cover_card.dart';
import 'package:daily_budget/features/day_details/widgets/cover_sheet.dart';
import 'package:daily_budget/features/day_details/widgets/figures_card.dart';
import 'package:daily_budget/features/statement/open_month_statement.dart';
import 'package:daily_budget/features/transactions/spend_editor_flow.dart';
import 'package:daily_budget/features/transactions/spend_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One day of a budget month (F-012, `day-details.md`): its figures, the
/// cover with savings, its spends and the way to add one. It adds no money
/// rule: every figure is a [DaySummary] of the engine's result.
class DayDetailsScreen extends ConsumerStatefulWidget {
  const new({required this.monthId, required this.date, super.key});

  final int monthId;

  final CalendarDate date;

  /// Pushes the screen over the current page; back returns to it unchanged
  /// (AC-1).
  static Future<void> open(
    BuildContext context, {
    required int monthId,
    required CalendarDate date,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => DayDetailsScreen(monthId: monthId, date: date),
    ),
  );

  @override
  ConsumerState<DayDetailsScreen> createState() => _DayDetailsScreenState();
}

class _DayDetailsScreenState extends ConsumerState<DayDetailsScreen> {
  /// The widest the content grows, in landscape (`day-details.md` §12).
  static const double _maxWidth = 600;

  (int, CalendarDate) get _key => (widget.monthId, widget.date);

  /// True while a write started here is running, so Undo and Remove cannot
  /// run twice from a double tap.
  bool _writing = false;

  void _snack(String text, {SnackBarAction? action, Duration? duration}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: action,
          // A snackbar with an action stays by default; it times out unless a
          // screen reader is on (design §6, D-077).
          persist: MediaQuery.accessibleNavigationOf(context),
          duration: duration ?? const Duration(seconds: 4),
        ),
      );
  }

  Future<void> _cover() async {
    final saved = await showCoverSheet(
      context,
      monthId: widget.monthId,
      date: widget.date,
    );
    if (saved == null || !mounted) return;
    _snack(
      DayDetailsCopy.coverSnackbar(formatRupees(saved.amount)),
      // The snackbar's timer starts after its 250 ms slide in, so the Undo is
      // gone six seconds after the cover (F-012 AC-21).
      duration: const Duration(milliseconds: 5750),
      action: SnackBarAction(
        label: DayDetailsCopy.undo,
        onPressed: () => unawaited(_undo(saved.coverId)),
      ),
    );
  }

  Future<void> _undo(int coverId) async {
    if (_writing) return;
    _writing = true;
    try {
      await ref.read(savingsRepositoryProvider).removeCovers(widget.monthId, {
        coverId,
      });
      if (mounted) _snack(DayDetailsCopy.coverUndone);
    } on StorageException {
      if (mounted) _snack(StorageCopy.saveError);
    } finally {
      _writing = false;
    }
  }

  Future<void> _remove(DaySummary day) async {
    if (_writing) return;
    final amount = formatRupees(day.covered);
    final remove = await showDecisionSheet<bool>(
      context: context,
      title: DayDetailsCopy.removeTitle,
      paragraphs: [
        DayDetailsCopy.removeBody(amount, formatWeekdayDayMonth(widget.date)),
      ],
      options: const [
        DecisionOption.destructive(
          value: true,
          label: DayDetailsCopy.removeConfirm,
          hint: DayDetailsCopy.removeConfirmHint,
        ),
        DecisionOption(
          value: false,
          label: DayDetailsCopy.keepIt,
          hint: DayDetailsCopy.keepItHint,
        ),
      ],
      dismissValue: false,
    );
    if (!remove || !mounted) return;
    _writing = true;
    try {
      await ref
          .read(savingsRepositoryProvider)
          .removeCovers(widget.monthId, day.coverIds);
      if (mounted) _snack(DayDetailsCopy.coverRemoved);
    } on StorageException {
      if (mounted) _snack(StorageCopy.saveError);
    } finally {
      _writing = false;
    }
  }

  void _reload() {
    ref
      ..invalidate(storedMonthProvider)
      ..invalidate(monthSpendsProvider)
      ..invalidate(monthCoversProvider);
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(dayDetailsProvider(_key));
    return Scaffold(
      // The screen has no input; the cover sheet handles the keyboard itself.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.all(BudgetSpacing.space2),
                child: BudgetIconButton(
                  icon: Icons.arrow_back,
                  tooltip: DayDetailsCopy.back,
                  hint: DayDetailsCopy.backHint,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            Expanded(
              child: switch (view) {
                AsyncError() => SingleChildScrollView(
                  child: EmptyState(
                    icon: Icons.error_outline,
                    title: StorageCopy.loadErrorTitle,
                    description: StorageCopy.loadErrorDescription,
                    action: BudgetButton.primary(
                      label: StorageCopy.tryAgain,
                      semanticsHint: StorageCopy.loadErrorHint,
                      onPressed: _reload,
                    ),
                  ),
                ),
                AsyncData(:final value) => _Body(
                  view: value,
                  date: widget.date,
                  maxWidth: _maxWidth,
                  onCover: () => unawaited(_cover()),
                  onRemove: () => unawaited(_remove(value.summary)),
                ),
                _ => const _Loading(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const new({
    required this.view,
    required this.date,
    required this.maxWidth,
    required this.onCover,
    required this.onRemove,
  });

  final DayDetailsView view;
  final CalendarDate date;
  final double maxWidth;
  final VoidCallback onCover;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.budgetColors;
    final day = view.summary;
    final today = view.result.today;
    final bodyStyle = BudgetTypeScale.body.copyWith(
      color: colors.textSecondary,
    );
    final title = formatWeekdayDayMonth(date);

    if (!day.isBudgeted) {
      return _page(maxWidth, [
        _Header(title: title, status: null, speech: formatFullDate(date)),
        const SizedBox(height: BudgetSpacing.space3),
        Text(
          DayDetailsCopy.notBudgeted(formatDayMonth(day.firstBudgetedDay)),
          style: bodyStyle,
        ),
      ]);
    }

    final status = dayStatusOf(day);
    final speechDate = formatFullDate(date);
    final headerSpeech = day.isLive
        ? DayDetailsCopy.todayHeaderSpeech(speechDate, status.speech)
        : DayDetailsCopy.headerSpeech(speechDate, status.speech);

    final children = <Widget>[
      _Header(title: title, status: status, speech: headerSpeech),
      if (day.isChangeDay)
        _Notice(
          icon: Icons.history,
          text: DayDetailsCopy.budgetChanged(budgetChangeText(day.changes)),
          hint: DayDetailsCopy.budgetChangedHint,
          onTap: () => openMonthStatement(
            context,
            view.monthId,
            scrollToPeriodStart: date,
          ),
        ),
      if (day.isEnded)
        const _Notice(icon: Icons.lock_outline, text: DayDetailsCopy.pastMonth),
      const SizedBox(height: BudgetSpacing.space6),
      FiguresCard(day: day, onRemove: day.canRemoveCover ? onRemove : null),
    ];

    final offer = day.coverOffer;
    if (offer is! CoverNone) {
      children
        ..add(const SizedBox(height: BudgetSpacing.space4))
        ..add(CoverCard(day: day, onCover: onCover));
    } else if (day.isFullyCovered) {
      children
        ..add(const SizedBox(height: BudgetSpacing.space4))
        ..add(CoveredNote(covered: day.covered));
    }

    final rows = view.rows;
    final hasRefund = rows.any(
      (r) => r.spend.direction == SpendDirection.moneyIn,
    );
    if (!day.isUpcoming || rows.isNotEmpty) {
      children
        ..add(const SizedBox(height: BudgetSpacing.space6))
        ..add(
          Semantics(
            header: true,
            child: Text(
              hasRefund
                  ? DayDetailsCopy.spendsAndRefundsHeading
                  : DayDetailsCopy.spendsHeading,
              style: BudgetTypeScale.caption.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        )
        ..add(const SizedBox(height: BudgetSpacing.space2))
        ..add(
          BudgetCard(
            padding: EdgeInsets.zero,
            child: rows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(BudgetSpacing.space4),
                    child: Text(
                      day.isLive
                          ? DayDetailsCopy.nothingSpentToday
                          : DayDetailsCopy.nothingSpent,
                      style: bodyStyle,
                    ),
                  )
                : Column(
                    children: [
                      for (final (index, row) in rows.indexed) ...[
                        if (index > 0)
                          const Divider(
                            indent: BudgetSpacing.space5,
                            height: 1,
                          ),
                        SpendRow(
                          stored: row,
                          isRefund:
                              row.spend.direction == SpendDirection.moneyIn,
                          subtitle: _subtitle(row, today),
                          onTap: day.isEnded
                              ? null
                              : () => unawaited(
                                  openSpendEditor(
                                    context,
                                    ref,
                                    edit: row,
                                    fromDay: date,
                                  ),
                                ),
                        ),
                      ],
                    ],
                  ),
          ),
        );
    }
    if (day.canAddSpend) {
      children
        ..add(const SizedBox(height: BudgetSpacing.space4))
        ..add(
          BudgetButton.secondary(
            label: DayDetailsCopy.addSpend,
            semanticsHint: DayDetailsCopy.addSpendHint,
            icon: Icons.add,
            onPressed: () => unawaited(
              openSpendEditor(context, ref, date: date, fromDay: date),
            ),
          ),
        );
    }
    return _page(maxWidth, children);
  }

  /// `Refund` for money in, `Dated in the future` for a spend after today
  /// (the device date was set back).
  String? _subtitle(StoredSpend row, CalendarDate today) {
    if (row.spend.direction == SpendDirection.moneyIn) {
      return DayDetailsCopy.refund;
    }
    return row.spend.date.isAfter(today)
        ? DayDetailsCopy.datedInTheFuture
        : null;
  }
}

Widget _page(double maxWidth, List<Widget> children) => SingleChildScrollView(
  child: Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BudgetSpacing.space5,
          0,
          BudgetSpacing.space5,
          BudgetSpacing.space8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  ),
);

/// The title and the status line as one heading node: `Wednesday 11
/// November, overspent ₹300`.
class _Header extends StatelessWidget {
  const new({required this.title, required this.status, required this.speech});

  final String title;
  final DayStatusText? status;
  final String speech;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final status = this.status;
    return Semantics(
      header: true,
      label: speech,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: context.budgetText.headline.copyWith(
                color: colors.textPrimary,
              ),
            ),
            if (status != null) ...[
              const SizedBox(height: BudgetSpacing.space2),
              AnimatedSwitcher(
                duration: BudgetMotion.of(context).base,
                layoutBuilder: (current, previous) => Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [...previous, ?current],
                ),
                child: Text(
                  status.mark == null
                      ? status.words
                      : '${status.mark} ${status.words}',
                  key: ValueKey(status.words),
                  style: BudgetTypeScale.moneyMedium.copyWith(
                    fontSize: 18,
                    height: 24 / 18,
                    fontWeight: FontWeight.w600,
                    color: status.tone.color(colors),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// An inline note under the status line: a 16 dp icon and a sentence. With
/// [onTap] the whole line is a 48 dp button with a chevron.
class _Notice extends StatelessWidget {
  const new({required this.icon, required this.text, this.hint, this.onTap});

  final IconData icon;
  final String text;
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final row = Row(
      children: [
        ExcludeSemantics(
          child: Icon(icon, size: 16, color: colors.textSecondary),
        ),
        const SizedBox(width: BudgetSpacing.space2),
        Expanded(
          child: Text(
            text,
            style: BudgetTypeScale.body.copyWith(color: colors.textSecondary),
          ),
        ),
        if (onTap != null)
          ExcludeSemantics(
            child: Icon(
              Icons.chevron_right,
              size: 20,
              color: colors.textSecondary,
            ),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(top: BudgetSpacing.space3),
      child: onTap == null
          ? row
          : Semantics(
              button: true,
              label: text,
              hint: hint,
              excludeSemantics: true,
              onTap: onTap,
              child: InkWell(
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: BudgetSpacing.touchTarget,
                  ),
                  child: row,
                ),
              ),
            ),
    );
  }
}

/// Grey bars while the day loads: never a `₹0` (`day-details.md` §10).
class _Loading extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    Widget bar(double width) => Container(
      width: width,
      height: 16,
      decoration: BoxDecoration(
        color: colors.sunken,
        borderRadius: const BorderRadius.all(Radius.circular(BudgetRadii.xs)),
      ),
    );
    return Semantics(
      label: DayDetailsCopy.loadingSemantics,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.all(BudgetSpacing.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bar(160),
            const SizedBox(height: BudgetSpacing.space3),
            bar(120),
            const SizedBox(height: BudgetSpacing.space6),
            BudgetCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(200),
                  const SizedBox(height: BudgetSpacing.space3),
                  bar(140),
                  const SizedBox(height: BudgetSpacing.space3),
                  bar(180),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
