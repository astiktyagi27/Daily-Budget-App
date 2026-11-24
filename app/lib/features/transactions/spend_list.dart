import 'package:daily_budget/core/copy/category_copy.dart';
import 'package:daily_budget/core/copy/search_copy.dart';
import 'package:daily_budget/core/copy/transactions_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:daily_budget/core/widgets/category_chip.dart';
import 'package:daily_budget/core/widgets/focus_ring.dart';
import 'package:daily_budget/data/repositories/transaction_repository.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// The Transactions list (`transactions.md` §5, `transactions-search.md`
/// §7): budget months of day groups, newest first. Each day is a heading with
/// the day's total, then one card with a row per entry.
///
/// It is a sliver whose days are built as they scroll into view, so 1,000
/// spends open at once (F-015 AC-16). A month separator is drawn only when
/// more than one month is shown. While [filtering], a day total counts only
/// the shown entries and says so. [editableMonthId] is the one month whose
/// rows open the editor; the others are read-only but keep their category
/// chip (AC-14). [onCategory] is called with the entry whose chip was tapped.
class TransactionListSliver extends StatelessWidget {
  const new({
    required this.sections,
    required this.filtering,
    required this.editableMonthId,
    required this.onOpen,
    required this.onCategory,
    super.key,
  });

  final List<MonthSection> sections;
  final bool filtering;
  final int? editableMonthId;
  final void Function(StoredSpend spend) onOpen;
  final void Function(StoredSpend spend) onCategory;

  @override
  Widget build(BuildContext context) {
    final items = <_ListItem>[
      for (final section in sections) ...[
        if (sections.length > 1) _SeparatorItem(section.month),
        for (final day in section.days)
          _DayItem(day, editable: section.monthId == editableMonthId),
      ],
    ];
    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => switch (items[index]) {
        _SeparatorItem(:final month) => MonthSeparator(month: month),
        _DayItem(:final day, :final editable) => _DaySection(
          day: day,
          filtering: filtering,
          onOpen: editable ? onOpen : null,
          onCategory: onCategory,
        ),
      },
    );
  }
}

sealed class _ListItem {
  const new();
}

final class _SeparatorItem extends _ListItem {
  const new(this.month);

  final BudgetMonth month;
}

final class _DayItem extends _ListItem {
  const new(this.day, {required this.editable});

  final NotedDay day;
  final bool editable;
}

/// `October · 5 Oct – 4 Nov` under a full-width hairline.
class MonthSeparator extends StatelessWidget {
  const new({required this.month, super.key});

  final BudgetMonth month;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: BudgetSpacing.space6),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BudgetSpacing.space5,
            BudgetSpacing.space3,
            BudgetSpacing.space5,
            0,
          ),
          child: Semantics(
            header: true,
            child: Text(
              SearchCopy.monthSeparator(
                formatMonthName(month.start),
                formatRange(month.start, month.end),
              ),
              style: BudgetTypeScale.label.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DaySection extends StatelessWidget {
  const new({
    required this.day,
    required this.filtering,
    required this.onOpen,
    required this.onCategory,
  });

  final NotedDay day;
  final bool filtering;
  final void Function(StoredSpend spend)? onOpen;
  final void Function(StoredSpend spend) onCategory;

  @override
  Widget build(BuildContext context) {
    final onOpen = this.onOpen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DayHeader(group: day.group, filtering: filtering),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BudgetSpacing.space5),
          child: BudgetCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (index, entry) in day.entries.indexed) ...[
                  if (index > 0)
                    const Divider(indent: BudgetSpacing.space5, height: 1),
                  _EntryRow(
                    stored: StoredSpend(spend: entry.spend, note: entry.note),
                    onOpen: onOpen,
                    onCategory: onCategory,
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

/// A spend with its category chip, or a refund with its `Refund` line.
class _EntryRow extends StatelessWidget {
  const new({
    required this.stored,
    required this.onOpen,
    required this.onCategory,
  });

  final StoredSpend stored;
  final void Function(StoredSpend spend)? onOpen;
  final void Function(StoredSpend spend) onCategory;

  @override
  Widget build(BuildContext context) {
    final open = onOpen;
    final spend = stored.spend;
    final onTap = open == null ? null : () => open(stored);
    if (spend.direction == SpendDirection.moneyIn) {
      return SpendRow(
        stored: stored,
        isRefund: true,
        subtitle: SearchCopy.refundWordRow,
        spokenDate: formatFullDate(spend.date),
        onTap: onTap,
      );
    }
    return SpendRow(
      stored: stored,
      category: spend.category ?? SpendCategory.other,
      onCategoryTap: () => onCategory(stored),
      onTap: onTap,
    );
  }
}

String _heading(DayGroup group) => switch (group.label) {
  DayLabel.today => TransactionsCopy.todayTitle,
  DayLabel.yesterday => TransactionsCopy.yesterday,
  DayLabel.other => formatWeekdayDayMonth(group.date),
};

class _DayHeader extends StatelessWidget {
  const new({required this.group, required this.filtering});

  final DayGroup group;
  final bool filtering;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final heading = _heading(group);
    final total = formatRupees(group.total);
    final speech = formatRupeesForSpeech(group.total);
    return Semantics(
      header: true,
      label: filtering
          ? SearchCopy.dayShownSemantics(heading, speech)
          : TransactionsCopy.dayHeaderSemantics(heading, speech),
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
                filtering ? SearchCopy.dayShown(total) : total,
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

/// One spend row (`transactions.md` §5): note, amount, tap to edit. [onTap]
/// null makes it read-only. Public so day details shows the same row (F-012).
class SpendRow extends StatefulWidget {
  const new({
    required this.stored,
    required this.onTap,
    this.subtitle,
    this.isRefund = false,
    this.category,
    this.onCategoryTap,
    this.spokenDate,
    super.key,
  });

  final StoredSpend stored;
  final VoidCallback? onTap;

  /// The category shown as a chip on a second line, with [onCategoryTap]
  /// (the Transactions list, F-015). The chip is its own screen-reader stop
  /// and the row's sentence gains the category: `₹250, Lunch, Food, Monday 9
  /// November`.
  final SpendCategory? category;
  final VoidCallback? onCategoryTap;

  /// For a refund: the date added to its sentence (`Refund, ₹500, Amazon
  /// return, Friday 13 November`); day details leaves it out.
  final String? spokenDate;

  /// A second line under the note in `textSecondary`: `Refund` or `Dated in
  /// the future` (day details, `day-details.md` §3 item 7).
  final String? subtitle;

  /// Money in: the amount reads `+₹500` and the sentence `Refund, ₹500, note`
  /// (F-012 AC-16, AC-19).
  final bool isRefund;

  @override
  State<SpendRow> createState() => _SpendRowState();
}

class _SpendRowState extends State<SpendRow> {
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
    final noteLine = Text(
      hasNote ? note : TransactionsCopy.noNote,
      style: BudgetTypeScale.bodyLarge.copyWith(
        color: hasNote ? colors.textPrimary : colors.textSecondary,
      ),
    );
    final subtitle = widget.subtitle;
    final noteText = subtitle == null
        ? noteLine
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              noteLine,
              Text(
                subtitle,
                style: BudgetTypeScale.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          );
    final amount = widget.isRefund
        ? '+${formatRupees(spend.amount)}'
        : formatRupees(spend.amount);
    final amountStyle = BudgetTypeScale.moneyMedium.copyWith(
      color: colors.textPrimary,
    );
    final amountText = Text(amount, style: amountStyle);

    final chipName = widget.category == null
        ? null
        : CategoryCopy.nameOf(widget.category!);
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
            padding: EdgeInsets.fromLTRB(
              BudgetSpacing.space5,
              BudgetSpacing.space3,
              BudgetSpacing.space5,
              // The chip line below brings its own room.
              chipName == null ? BudgetSpacing.space3 : 0,
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
    final spokenAmount = formatRupeesForSpeech(spend.amount);
    final spokenNote = hasNote ? note : TransactionsCopy.noNote;
    final spokenDate = widget.spokenDate;
    final label = widget.isRefund
        ? (spokenDate == null
              ? TransactionsCopy.refundRowSemantics(spokenAmount, spokenNote)
              : SearchCopy.refundRowSemantics(
                  spokenAmount,
                  spokenNote,
                  spokenDate,
                ))
        : chipName == null
        ? TransactionsCopy.rowSemantics(
            spokenAmount,
            spokenNote,
            formatFullDate(spend.date),
          )
        : SearchCopy.rowSemantics(
            spokenAmount,
            spokenNote,
            chipName,
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
    final row = MergeSemantics(
      child: Semantics(
        button: onTap != null,
        label: label,
        hint: onTap == null ? null : TransactionsCopy.editHint,
        child: tappable,
      ),
    );
    final onCategoryTap = widget.onCategoryTap;
    if (chipName == null || onCategoryTap == null) return row;
    // The chip is a stop of its own under the row; the rest of its line still
    // opens the row.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        Padding(
          padding: const EdgeInsets.only(left: BudgetSpacing.space5),
          child: Row(
            children: [
              CategoryChip(
                name: chipName,
                semanticsLabel: SearchCopy.chipRowSemantics(chipName),
                tooltip: SearchCopy.changeCategoryTooltip,
                onPressed: onCategoryTap,
              ),
              Expanded(
                child: ExcludeSemantics(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    child: const SizedBox(height: CategoryChip.targetHeight),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
