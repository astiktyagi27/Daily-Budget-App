import 'dart:async';

import 'package:daily_budget/core/copy/month_setup_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/help/label_description.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';

/// The live preview (F-008 §2.3, `month-setup.md` §5): the budget month, the
/// spendable line and the daily budget, or the shortfall panel, or the edit
/// line. Every figure comes from the engine through `SetupPreview`; this
/// widget only formats and lays it out.
///
/// The daily amount is not counted up while the user types (the design asks
/// for a 600 ms count): AC-7 wants the new number in the same frame.
class SetupPreviewCard extends StatelessWidget {
  const new({
    required this.preview,
    required this.draft,
    required this.today,
    required this.isEdit,
    super.key,
  });

  final SetupPreview preview;
  final SetupDraft draft;
  final CalendarDate today;
  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    final preview = this.preview;
    final ready = preview is PreviewReady ? preview : null;
    return BudgetCard(
      title: MonthSetupCopy.previewTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isEdit) ...[
            _MonthLine(draft: draft, today: today),
            const SizedBox(height: BudgetSpacing.space3),
          ],
          if (ready != null) ...[
            _SpendableLine(preview: ready),
            const SizedBox(height: BudgetSpacing.space3),
          ],
          Divider(height: 1, color: context.budgetColors.border),
          const SizedBox(height: BudgetSpacing.space3),
          _DailyArea(
            preview: preview,
            draft: draft,
            today: today,
            isEdit: isEdit,
          ),
        ],
      ),
    );
  }
}

class _MonthLine extends StatelessWidget {
  const new({required this.draft, required this.today});

  final SetupDraft draft;
  final CalendarDate today;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final day = draft.salaryDay;
    final String value;
    if (day == null) {
      value = MonthSetupCopy.previewNeedsSalaryDay;
    } else {
      final month = BudgetMonth.containing(day, today);
      final partial = draft.kind == SetupKind.midMonth;
      final days = partial ? today.daysUntil(month.end) + 1 : month.length;
      value = MonthSetupCopy.previewMonth(month, days, partial: partial);
    }
    return Semantics(
      container: true,
      label: '${MonthSetupCopy.previewMonthLabel}. $value',
      child: ExcludeSemantics(
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: BudgetSpacing.space3,
          children: [
            Text(
              MonthSetupCopy.previewMonthLabel,
              style: BudgetTypeScale.body.copyWith(color: colors.textSecondary),
            ),
            Text(
              value,
              style: BudgetTypeScale.body.copyWith(color: colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpendableLine extends StatelessWidget {
  const new({required this.preview});

  final PreviewReady preview;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final line = MonthSetupCopy.spendableLine(
      formatRupees(preview.baseAmount),
      formatRupees(preview.fixedCosts),
      formatRupees(preview.spendable),
    );
    final speech = MonthSetupCopy.spendableSpeech(
      formatRupeesForSpeech(preview.baseAmount),
      formatRupeesForSpeech(preview.fixedCosts),
      formatRupeesForSpeech(preview.spendable),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LabelDescription(
          label: MonthSetupCopy.previewSpendableLabel,
          info: MonthSetupCopy.spendableInfo,
        ),
        Semantics(
          container: true,
          label: speech,
          child: ExcludeSemantics(
            child: Text(
              line,
              style: BudgetTypeScale.bodyLarge.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyArea extends StatelessWidget {
  const new({
    required this.preview,
    required this.draft,
    required this.today,
    required this.isEdit,
  });

  final SetupPreview preview;
  final SetupDraft draft;
  final CalendarDate today;
  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final preview = this.preview;
    if (preview is! PreviewReady) {
      return Text(
        draft.kind == SetupKind.midMonth
            ? MonthSetupCopy.previewNeedsMoneyLeft
            : MonthSetupCopy.previewNeedsSalary,
        style: BudgetTypeScale.body.copyWith(color: colors.textSecondary),
      );
    }
    final outcome = preview.outcome;
    if (outcome is Shortfall) {
      final amount = formatRupees(outcome.amount);
      return _Panel(
        fill: colors.overspentSoft,
        color: colors.overspent,
        glyph: '◆',
        statusText: MonthSetupCopy.short(amount),
        reason: isEdit
            ? MonthSetupCopy.editShortfall(amount)
            : MonthSetupCopy.shortfallReason(amount, preview.basis),
        speech:
            '${MonthSetupCopy.aDaySpeech(formatRupeesForSpeech(Paise.zero))}, '
            '${MonthSetupCopy.short(formatRupeesForSpeech(outcome.amount))}.',
      );
    }
    if (outcome is ZeroSpendable) {
      return _Panel(
        fill: colors.neutralSoft,
        color: colors.neutral,
        glyph: '○',
        statusText: MonthSetupCopy.zeroLeft,
        reason: MonthSetupCopy.zeroReason(preview.basis),
        speech: MonthSetupCopy.zeroLeft,
        showZeroDay: false,
      );
    }
    return isEdit
        ? _EditLine(preview: preview, today: today)
        : _DailyBudget(amount: preview.dailyBudget);
  }
}

/// `Daily budget (i)` and the amount in `moneyLarge`.
class _DailyBudget extends StatelessWidget {
  const new({required this.amount});

  final Paise amount;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final text = MonthSetupCopy.aDay(formatRupees(amount));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LabelDescription(
          label: MonthSetupCopy.previewDailyLabel,
          info: MonthSetupCopy.dailyInfo,
        ),
        _PoliteLiveRegion(
          label: MonthSetupCopy.aDaySpeech(formatRupeesForSpeech(amount)),
          child: Text(
            text,
            style: BudgetTypeScale.moneyLarge.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// `From today (20 Nov): ₹630 a day for the 15 days left. …` with the amount
/// in the money style.
class _EditLine extends StatelessWidget {
  const new({required this.preview, required this.today});

  final PreviewReady preview;
  final CalendarDate today;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final amount = formatRupees(preview.dailyBudget);
    final parts = MonthSetupCopy.editLineParts(
      formatDayMonth(today),
      amount,
      preview.days,
    );
    final speech = MonthSetupCopy.editLine(
      formatDayMonth(today),
      formatRupeesForSpeech(preview.dailyBudget),
      preview.days,
    ).replaceAll(' ', ' ');
    final base = BudgetTypeScale.bodyLarge.copyWith(color: colors.textPrimary);
    return _PoliteLiveRegion(
      label: speech,
      child: Text.rich(
        TextSpan(
          style: base,
          children: [
            TextSpan(text: parts.before),
            TextSpan(
              text: parts.amount,
              style: BudgetTypeScale.moneyMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
            TextSpan(text: parts.after),
          ],
        ),
      ),
    );
  }
}

/// The shortfall panel (overspent: `◆`, soft red) or the exactly-zero panel
/// (neutral: `○`). The glyph is a separate widget so the status reads
/// `₹1,000 short` without a symbol; colour never carries the meaning alone.
class _Panel extends StatelessWidget {
  const new({
    required this.fill,
    required this.color,
    required this.glyph,
    required this.statusText,
    required this.reason,
    required this.speech,
    this.showZeroDay = true,
  });

  final Color fill;
  final Color color;
  final String glyph;
  final String statusText;
  final String reason;
  final String speech;
  final bool showZeroDay;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Semantics(
      container: true,
      liveRegion: true,
      label: '$speech $reason',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: const BorderRadius.all(
              Radius.circular(BudgetRadii.md),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(BudgetSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: BudgetSpacing.space3,
                  runSpacing: BudgetSpacing.space1,
                  children: [
                    if (showZeroDay)
                      Text(
                        MonthSetupCopy.shortfallZeroDay,
                        style: BudgetTypeScale.moneyLarge.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          glyph,
                          style: BudgetTypeScale.label.copyWith(
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: BudgetSpacing.space1),
                        Flexible(
                          child: Text(
                            statusText,
                            style: BudgetTypeScale.label.copyWith(
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: BudgetSpacing.space2),
                Text(
                  reason,
                  style: BudgetTypeScale.body.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reads [child] out as a polite live region, but only after the text has
/// been still for a second, so a screen reader is not chatty while the user
/// types (`month-setup.md` §5). The first value is spoken with the screen.
class _PoliteLiveRegion extends StatefulWidget {
  const new({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  State<_PoliteLiveRegion> createState() => _PoliteLiveRegionState();
}

class _PoliteLiveRegionState extends State<_PoliteLiveRegion> {
  static const _quietFor = Duration(seconds: 1);

  late String _spoken = widget.label;
  Timer? _timer;

  @override
  void didUpdateWidget(_PoliteLiveRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label == widget.label) return;
    _timer?.cancel();
    _timer = Timer(_quietFor, () {
      if (mounted) setState(() => _spoken = widget.label);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: _spoken,
      child: ExcludeSemantics(child: widget.child),
    );
  }
}
