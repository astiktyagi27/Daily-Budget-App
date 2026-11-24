import 'package:daily_budget/core/copy/statement_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/statement/statement_text.dart';
import 'package:daily_budget/features/statement/widgets/working_strip.dart';
import 'package:flutter/material.dart';

/// One period card (design §7): overline, heading, why it started, the
/// values in force, the working strip and the totals for these days.
///
/// With [arrival] (Day details, S-6) the card's fill flashes `accentSoft` to
/// `surface` over 600 ms (not with Remove animations) and the heading takes
/// screen-reader focus.
class PeriodCard extends StatefulWidget {
  const new({required this.period, this.arrival = false, super.key});

  final StatementPeriod period;

  final bool arrival;

  @override
  State<PeriodCard> createState() => _PeriodCardState();
}

class _PeriodCardState extends State<PeriodCard>
    with SingleTickerProviderStateMixin {
  final _headingFocus = FocusNode(debugLabel: 'period heading');
  AnimationController? _flash;

  @override
  void initState() {
    super.initState();
    if (widget.arrival) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _headingFocus.requestFocus();
        final duration = BudgetMotion.of(context).count;
        if (duration == Duration.zero) return;
        _flash = AnimationController(vsync: this, duration: duration)
          ..addListener(() => setState(() {}))
          ..forward();
      });
    }
  }

  @override
  void dispose() {
    _flash?.dispose();
    _headingFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final p = widget.period;
    final flash = _flash;
    final fill = flash == null
        ? colors.surface
        : Color.lerp(
            colors.accentSoft,
            colors.surface,
            BudgetMotion.decelerate.transform(flash.value),
          )!;
    final label = BudgetTypeScale.body.copyWith(color: colors.textSecondary);
    final heading = headingText(p);
    return Card(
      color: fill,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(BudgetSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              container: true,
              header: true,
              label: headingSpeech(p),
              child: Focus(
                focusNode: _headingFocus,
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        StatementCopy.overline(p.index, p.of),
                        style: BudgetTypeScale.caption.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: heading,
                              style: context.budgetText.title.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                            if (p.inProgress)
                              TextSpan(
                                text: ' · ${StatementCopy.inProgress}',
                                style: label,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: BudgetSpacing.space2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.history,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: BudgetSpacing.space2),
                Expanded(
                  child: Text(
                    reasonsText(p.reasons),
                    style: BudgetTypeScale.label.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BudgetSpacing.space3),
            ..._values(p.values),
            const SizedBox(height: BudgetSpacing.space3),
            WorkingStrip(working: p.working),
            const SizedBox(height: BudgetSpacing.space4),
            Text(
              StatementCopy.forTheseDays,
              style: BudgetTypeScale.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
            ..._totals(p.totals),
          ],
        ),
      ),
    );
  }

  List<Widget> _values(PeriodValues values) {
    final costs = fixedCostsOf(values);
    return switch (values) {
      FullMonthValues(:final salary, :final target) => [
        _Line(label: StatementCopy.salaryRow, amount: salary),
        if (target != null)
          _Line(label: StatementCopy.targetRow, amount: target),
        _CostsRow(
          label: StatementCopy.fixedCosts,
          total: values.fixedCostsTotal,
          costs: costs,
        ),
      ],
      MidMonthStartValues(:final moneyLeft) => [
        _Line(label: StatementCopy.moneyLeftRow, amount: moneyLeft),
        _CostsRow(
          label: StatementCopy.stillToPayRow,
          total: values.fixedCostsTotal,
          costs: costs,
        ),
      ],
    };
  }

  List<Widget> _totals(StatementPeriodTotals t) => [
    _Line(label: StatementCopy.budget, amount: t.budget),
    _Line(label: StatementCopy.spent, amount: t.spent),
    if (t.hasRefunds) ...[
      _Line(label: StatementCopy.refunds, amount: -t.refunds),
      _Line(label: StatementCopy.netSpent, amount: t.netSpent),
    ],
    _Line(
      label: StatementCopy.saved,
      amount: t.saved,
      mark: t.saved.wholeRupees > 0 ? StatementCopy.savedMark : null,
      saved: true,
    ),
    _Line(
      label: StatementCopy.overspent,
      amount: t.overspent,
      mark: t.overspent.wholeRupees > 0 ? StatementCopy.overspentMark : null,
    ),
    _Line(label: StatementCopy.covered, amount: t.covered),
  ];
}

/// A label and an amount on one row, no (i) (design §7: only the totals card
/// has them). Stacks above 1.3x text.
class _Line extends StatelessWidget {
  const new({
    required this.label,
    required this.amount,
    this.mark,
    this.saved = false,
  });

  final String label;

  final Paise amount;

  /// `●` or `◆` in front of a Saved or Overspent amount above ₹0.
  final String? mark;

  final bool saved;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final markColor = saved ? colors.saved : colors.overspent;
    final value = Text.rich(
      TextSpan(
        children: [
          if (mark != null)
            TextSpan(
              text: '$mark ',
              style: BudgetTypeScale.label.copyWith(color: markColor),
            ),
          TextSpan(text: formatRupees(amount)),
        ],
      ),
      style: context.budgetText.moneyMedium.copyWith(
        color: mark == null ? colors.textPrimary : markColor,
      ),
    );
    final name = Text(
      label,
      style: BudgetTypeScale.body.copyWith(color: colors.textSecondary),
    );
    return Semantics(
      container: true,
      label: '$label, ${formatRupeesForSpeech(amount)}',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [name, value],
                )
              : Row(
                  children: [
                    Expanded(child: name),
                    const SizedBox(width: BudgetSpacing.space2),
                    value,
                  ],
                ),
        ),
      ),
    );
  }
}

/// `Fixed costs ₹15,100` that opens to its items (AC-8). With no items there
/// is nothing to open, so it is a plain line.
class _CostsRow extends StatefulWidget {
  const new({required this.label, required this.total, required this.costs});

  final String label;

  final Paise total;

  final List<FixedCost> costs;

  @override
  State<_CostsRow> createState() => _CostsRowState();
}

class _CostsRowState extends State<_CostsRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    if (widget.costs.isEmpty) {
      return _Line(label: widget.label, amount: widget.total);
    }
    final colors = context.budgetColors;
    final motion = BudgetMotion.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          button: true,
          expanded: _open,
          label: '${widget.label}, ${formatRupeesForSpeech(widget.total)}',
          hint: _open
              ? StatementCopy.hideFixedCostsHint
              : StatementCopy.showFixedCostsHint,
          onTap: () => setState(() => _open = !_open),
          child: ExcludeSemantics(
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: BudgetSpacing.touchTarget,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.label,
                        style: BudgetTypeScale.body.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      formatRupees(widget.total),
                      style: context.budgetText.moneyMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: motion.base,
                      child: Icon(
                        Icons.expand_more,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_open)
          for (final cost in widget.costs)
            Padding(
              padding: const EdgeInsets.only(
                left: BudgetSpacing.space4,
                bottom: BudgetSpacing.space1,
              ),
              child: Semantics(
                container: true,
                label: '${cost.name}, ${formatRupeesForSpeech(cost.amount)}',
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          cost.name,
                          style: BudgetTypeScale.body.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        formatRupees(cost.amount),
                        style: BudgetTypeScale.body.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
