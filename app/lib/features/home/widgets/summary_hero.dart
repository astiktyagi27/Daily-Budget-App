import 'package:daily_budget/core/copy/home_copy.dart';
import 'package:daily_budget/core/copy/month_setup_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/help/info_button.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_icon_button.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/home/widgets/counting_amount.dart';
import 'package:daily_budget/features/home/widgets/home_layout.dart';
import 'package:flutter/material.dart';

/// The top of the summary card (F-010 §2.2): the `Left this month` overline
/// with its (i) and the ⋮ menu, the hero amount, the progress rule, the day
/// line and the late-start caption.
///
/// A screen reader gets the overline, the hero and the day line as one
/// sentence (`Left this month, ₹19,370. ₹830 a day, 5 November to 4
/// December.`); the (i) and ⋮ stay their own stops. A negative Left reads
/// `Left this month, minus ₹1,200. You're ₹1,200 over for this month.` and
/// the day line is its own node.
class SummaryHero extends StatelessWidget {
  const new({required this.summary, required this.onEdit, super.key});

  final HomeSummary summary;

  /// Opens month edit; null hides the ⋮ menu (the device date is outside
  /// the budgeted days).
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final over = summary.isOver;
    final heroColor = over ? colors.overspent : colors.textPrimary;
    final heroStyle = BudgetTypeScale.moneyHero.copyWith(color: heroColor);

    final spokenStart = _spoken(summary.rangeStart);
    final spokenEnd = _spoken(summary.rangeEnd);
    final dayCopy = HomeCopy.daySpeech(
      formatRupeesForSpeech(summary.dailyBudget),
      spokenStart,
      spokenEnd,
    );
    final heroLabel = over
        ? HomeCopy.overSpeech(
            formatRupeesForSpeech(summary.left),
            formatRupeesForSpeech(-summary.left),
          )
        : HomeCopy.summarySpeech(
            formatRupeesForSpeech(summary.left),
            formatRupeesForSpeech(summary.dailyBudget),
            spokenStart,
            spokenEnd,
          );

    final dayLine = ExcludeSemantics(
      child: Text.rich(
        TextSpan(
          style: BudgetTypeScale.body.copyWith(color: colors.textSecondary),
          children: [
            TextSpan(
              text: formatRupees(summary.dailyBudget),
              style: BudgetTypeScale.body.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            TextSpan(
              // The only break is after the dot; the word joiner stops a break
              // after the en dash inside the range.
              text:
                  unbreakable(
                        HomeCopy.dayLineTail(
                          formatCompactRange(
                            summary.rangeStart,
                            summary.rangeEnd,
                          ),
                        ),
                      )
                      .replaceFirst('\u00A0·\u00A0', '\u00A0· ')
                      .replaceFirst('–\u00A0', '–\u2060\u00A0'),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label: heroLabel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Flexible(
                    child: ExcludeSemantics(
                      child: Text(
                        HomeCopy.leftThisMonth,
                        style: BudgetTypeScale.label.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const InfoButton(
                    label: HomeCopy.leftThisMonth,
                    info: HomeCopy.leftInfo,
                  ),
                  const Spacer(),
                  if (onEdit case final onEdit?) _MoreMenu(onEdit: onEdit),
                ],
              ),
              ExcludeSemantics(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (over) ...[
                        Text(
                          '◆',
                          style: heroStyle.copyWith(fontSize: 14, height: 1),
                        ),
                        const SizedBox(width: BudgetSpacing.space2),
                      ],
                      CountingAmount(amount: summary.left, style: heroStyle),
                    ],
                  ),
                ),
              ),
              if (over)
                Padding(
                  padding: const EdgeInsets.only(top: BudgetSpacing.space1),
                  child: ExcludeSemantics(
                    child: Text(
                      HomeCopy.overCaption(formatRupees(-summary.left)),
                      style: BudgetTypeScale.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              if (!over) const SizedBox(height: BudgetSpacing.space1),
              ExcludeSemantics(child: _ProgressRule(summary.progressPermille)),
              const SizedBox(height: BudgetSpacing.space3),
              if (!over) dayLine,
            ],
          ),
        ),
        if (over) Semantics(container: true, label: dayCopy, child: dayLine),
        if (summary.startedLate) ...[
          const SizedBox(height: BudgetSpacing.space1),
          Text(
            HomeCopy.startedOn(formatDayMonth(summary.rangeStart)),
            style: BudgetTypeScale.body.copyWith(color: colors.textSecondary),
          ),
        ],
      ],
    );
  }

  /// `5 November`, for the screen reader.
  static String _spoken(CalendarDate date) =>
      formatFullDate(date).split(' ').skip(1).join(' ');
}

class _ProgressRule extends StatelessWidget {
  const new(this.permille);

  final int permille;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(BudgetRadii.full)),
      child: SizedBox(
        height: 4,
        child: ColoredBox(
          color: colors.neutralSoft,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: permille / 1000,
              heightFactor: 1,
              child: ColoredBox(color: colors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const new({required this.onEdit});

  final VoidCallback onEdit;

  Future<void> _show(BuildContext context) async {
    final colors = context.budgetColors;
    final button = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );
    final chosen = await showMenu<bool>(
      context: context,
      position: position,
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.border),
        borderRadius: const BorderRadius.all(Radius.circular(BudgetRadii.sm)),
      ),
      items: [
        PopupMenuItem<bool>(
          value: true,
          child: Semantics(
            hint: HomeCopy.editThisMonthHint,
            child: Text(
              MonthSetupCopy.titleEdit,
              style: BudgetTypeScale.label.copyWith(color: colors.textPrimary),
            ),
          ),
        ),
      ],
    );
    if (chosen ?? false) onEdit();
  }

  @override
  Widget build(BuildContext context) => Builder(
    builder: (context) => BudgetIconButton(
      icon: Icons.more_vert,
      tooltip: HomeCopy.more,
      onPressed: () => _show(context),
    ),
  );
}
