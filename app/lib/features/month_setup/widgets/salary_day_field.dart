import 'package:daily_budget/core/copy/month_setup_copy.dart';
import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/help/label_description.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/focus_ring.dart';
import 'package:daily_budget/features/month_setup/month_setup_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The first-month salary day (`month-setup.md` §4.1): a field-styled row
/// that shows the ordinal or `Choose a day` and opens the day sheet.
class SalaryDayField extends StatelessWidget {
  const new({
    required this.day,
    required this.focusNode,
    required this.onTap,
    this.errorText,
    super.key,
  });

  final int? day;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final String? errorText;

  static const double _height = 56;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final error = errorText;
    final value = day == null
        ? MonthSetupCopy.salaryDayPlaceholder
        : formatOrdinal(day!);
    final side = error == null
        ? BorderSide(color: colors.borderStrong)
        : BorderSide(color: colors.overspent, width: 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LabelDescription(
          label: MonthSetupCopy.salaryDayLabel,
          description: MonthSetupCopy.salaryDayDescription,
          info: MonthSetupCopy.salaryDayInfo,
          announce: false,
        ),
        const SizedBox(height: BudgetSpacing.space2),
        Semantics(
          button: true,
          label: MonthSetupCopy.salaryDayLabel,
          value: value,
          hint: MonthSetupCopy.salaryDayOpenHint,
          excludeSemantics: true,
          onTap: onTap,
          child: FocusRing(
            focusNode: focusNode,
            child: Material(
              color: colors.sunken,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(
                  Radius.circular(BudgetRadii.md),
                ),
                side: side,
              ),
              child: InkWell(
                focusNode: focusNode,
                onTap: onTap,
                borderRadius: const BorderRadius.all(
                  Radius.circular(BudgetRadii.md),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: _height),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BudgetSpacing.space4,
                      vertical: BudgetSpacing.space3,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            value,
                            style: BudgetTypeScale.bodyLarge.copyWith(
                              color: day == null
                                  ? colors.textSecondary
                                  : colors.textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.expand_more,
                          size: 24,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (error != null) _SalaryDayError(error),
      ],
    );
  }
}

class _SalaryDayError extends StatelessWidget {
  const new(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = context.budgetColors.overspent;
    return Padding(
      padding: const EdgeInsets.only(top: BudgetSpacing.space1),
      child: Semantics(
        liveRegion: true,
        label: 'Error: $message',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, size: 16, color: color),
            const SizedBox(width: BudgetSpacing.space1),
            Expanded(
              child: Text(
                message,
                style: BudgetTypeScale.body.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The read-only salary day of later months and edits: `Salary day: 5th`
/// with `Set in your first month.` under it, read as one item.
class SalaryDayFixed extends StatelessWidget {
  const new({required this.day, super.key});

  final int day;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final label = MonthSetupCopy.salaryDayFixed(day);
    return Semantics(
      container: true,
      label: LabelDescription.semanticsText(
        label,
        MonthSetupCopy.salaryDayFixedNote,
      ),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: BudgetTypeScale.label.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: BudgetSpacing.space1),
            Text(
              MonthSetupCopy.salaryDayFixedNote,
              style: BudgetTypeScale.body.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// The salary day sheet (`month-setup.md` §4.6): a grid of 1 to 31. A tap
/// selects at once; **Done** closes. Open it with
/// `showBudgetSheet`.
class SalaryDaySheet extends ConsumerWidget {
  const new({required this.mode, super.key});

  final SetupMode mode;

  static const int _days = 31;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = monthSetupControllerProvider(mode);
    final chosen = ref.watch(provider.select((s) => s.draft.salaryDay));
    final controller = ref.read(provider.notifier);
    final colors = context.budgetColors;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final columns = scale > 1.5 ? 5 : 7;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              BudgetSpacing.space5,
              BudgetSpacing.space6,
              BudgetSpacing.space5,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    MonthSetupCopy.salaryDaySheetTitle,
                    style: context.budgetText.title.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: BudgetSpacing.space2),
                Text(
                  MonthSetupCopy.salaryDaySheetDescription,
                  style: BudgetTypeScale.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: BudgetSpacing.space4),
                GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: BudgetSpacing.space1,
                  crossAxisSpacing: BudgetSpacing.space1,
                  childAspectRatio: scale > 1 ? 1 : 1.1,
                  children: [
                    for (var day = 1; day <= _days; day++)
                      _DayChip(
                        day: day,
                        selected: day == chosen,
                        onTap: () => controller.chooseSalaryDay(day),
                      ),
                  ],
                ),
                const SizedBox(height: BudgetSpacing.space3),
                Text(
                  MonthSetupCopy.salaryDaySheetFootnote,
                  style: BudgetTypeScale.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            BudgetSpacing.space5,
            BudgetSpacing.space4,
            BudgetSpacing.space5,
            BudgetSpacing.space5 + MediaQuery.paddingOf(context).bottom,
          ),
          child: BudgetButton.secondary(
            label: ScreenCopy.done,
            semanticsHint: MonthSetupCopy.salaryDaySheetDoneHint,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const new({required this.day, required this.selected, required this.onTap});

  final int day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final shape = RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(BudgetRadii.xs)),
      side: selected
          ? BorderSide(color: colors.focus, width: 2)
          : BorderSide(color: colors.border),
    );
    return Semantics(
      button: true,
      label: MonthSetupCopy.salaryDayChip(day, selected: selected),
      excludeSemantics: true,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: BudgetSpacing.touchTarget,
          minHeight: BudgetSpacing.touchTarget,
        ),
        child: Material(
          color: selected ? colors.accent : colors.surface,
          shape: shape,
          child: InkWell(
            onTap: onTap,
            customBorder: shape,
            child: Center(
              child: Text(
                day >= 29 ? '$day*' : '$day',
                style: BudgetTypeScale.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  color: selected ? colors.onAccent : colors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
