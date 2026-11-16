import 'package:daily_budget/core/copy/transactions_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:daily_budget/core/widgets/focus_ring.dart';
import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// The days of the month's spends, newest day first (`transactions.md` §5):
/// a heading with the day's total, then one card with a row per spend.
///
/// It is a sliver whose days are built as they scroll into view, so 500
/// spends open at once (F-009 AC-15). [onOpen] is null for a past month's
/// read-only list.
class SpendListSliver extends StatelessWidget {
  const new({
    required this.spends,
    required this.today,
    required this.onOpen,
    super.key,
  });

  final List<StoredSpend> spends;
  final CalendarDate today;

  /// Called with the tapped spend; null makes every row read-only.
  final void Function(StoredSpend spend)? onOpen;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final stored in spends) stored.spend.id: stored};
    final groups = groupSpendsByDay([for (final s in spends) s.spend], today);
    return SliverList.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) =>
          _DaySection(group: groups[index], byId: byId, onOpen: onOpen),
    );
  }
}

class _DaySection extends StatelessWidget {
  const new({required this.group, required this.byId, required this.onOpen});

  final DayGroup group;
  final Map<int, StoredSpend> byId;
  final void Function(StoredSpend spend)? onOpen;

  @override
  Widget build(BuildContext context) {
    final onOpen = this.onOpen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DayHeader(group: group),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BudgetSpacing.space5),
          child: BudgetCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (index, spend) in group.spends.indexed) ...[
                  if (index > 0)
                    const Divider(indent: BudgetSpacing.space5, height: 1),
                  _SpendRow(
                    stored: byId[spend.id]!,
                    onTap: onOpen == null
                        ? null
                        : () => onOpen(byId[spend.id]!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _heading(DayGroup group) => switch (group.label) {
  DayLabel.today => TransactionsCopy.todayTitle,
  DayLabel.yesterday => TransactionsCopy.yesterday,
  DayLabel.other => formatWeekdayDayMonth(group.date),
};

class _DayHeader extends StatelessWidget {
  const new({required this.group});

  final DayGroup group;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final heading = _heading(group);
    final total = formatRupees(group.total);
    return Semantics(
      header: true,
      label: TransactionsCopy.dayHeaderSemantics(
        heading,
        formatRupeesForSpeech(group.total),
      ),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BudgetSpacing.space5,
            BudgetSpacing.space6,
            BudgetSpacing.space5,
            BudgetSpacing.space2,
          ),
          // At large text the total moves under the heading.
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: BudgetSpacing.space3,
            children: [
              Text(
                heading,
                style: BudgetTypeScale.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                total,
                style: BudgetTypeScale.moneyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpendRow extends StatefulWidget {
  const new({required this.stored, required this.onTap});

  final StoredSpend stored;
  final VoidCallback? onTap;

  @override
  State<_SpendRow> createState() => _SpendRowState();
}

class _SpendRowState extends State<_SpendRow> {
  final _focusNode = FocusNode(debugLabel: 'SpendRow');

  /// The least width the note keeps beside the amount; below it the amount
  /// moves under the note (`transactions.md` §12).
  static const double _minNoteWidth = 120;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final StoredSpend(:spend, :note) = widget.stored;
    final hasNote = note != null && note.isNotEmpty;
    final noteText = Text(
      hasNote ? note : TransactionsCopy.noNote,
      style: BudgetTypeScale.bodyLarge.copyWith(
        color: hasNote ? colors.textPrimary : colors.textSecondary,
      ),
    );
    final amount = formatRupees(spend.amount);
    final amountStyle = BudgetTypeScale.moneyMedium.copyWith(
      color: colors.textPrimary,
    );
    final amountText = Text(amount, style: amountStyle);

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final amountWidth = _textWidth(context, amount, amountStyle);
        final noteWidth =
            constraints.maxWidth -
            2 * BudgetSpacing.space5 -
            BudgetSpacing.space3 -
            amountWidth;
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BudgetSpacing.space5,
              vertical: BudgetSpacing.space3,
            ),
            child: noteWidth < _minNoteWidth
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      noteText,
                      const SizedBox(height: BudgetSpacing.space1),
                      amountText,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: noteText),
                      const SizedBox(width: BudgetSpacing.space3),
                      amountText,
                    ],
                  ),
          ),
        );
      },
    );

    final onTap = widget.onTap;
    final label = TransactionsCopy.rowSemantics(
      formatRupeesForSpeech(spend.amount),
      hasNote ? note : TransactionsCopy.noNote,
      formatFullDate(spend.date),
    );
    final tappable = Material(
      type: MaterialType.transparency,
      child: FocusRing(
        focusNode: _focusNode,
        inside: true,
        child: InkWell(
          focusNode: _focusNode,
          onTap: onTap,
          overlayColor: WidgetStateProperty.fromMap({
            WidgetState.pressed: colors.sunken,
            WidgetState.any: colors.sunken.withValues(alpha: 0),
          }),
          splashFactory: NoSplash.splashFactory,
          child: ExcludeSemantics(child: content),
        ),
      ),
    );
    // One node per row, so the amount, note and date are read together.
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        label: label,
        hint: onTap == null ? null : TransactionsCopy.editHint,
        child: tappable,
      ),
    );
  }

  /// The width [text] takes at the current text size.
  static double _textWidth(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width.ceilToDouble();
  }
}
