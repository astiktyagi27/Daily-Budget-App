import 'package:daily_budget/core/copy/day_details_copy.dart';
import 'package:daily_budget/core/copy/storage_copy.dart';
import 'package:daily_budget/core/copy/transactions_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/day_details_provider.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/amount_field.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/budget_sheet.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What a saved cover hands back: the stored row and the amount, for the
/// snackbar and its Undo.
typedef CoverSaved = ({int coverId, Paise amount});

/// Opens the cover sheet for [date] (F-012 §2.3, design §6). Returns the
/// saved cover, or null when the sheet was cancelled.
Future<CoverSaved?> showCoverSheet(
  BuildContext context, {
  required int monthId,
  required CalendarDate date,
}) => showBudgetSheet<CoverSaved>(
  context: context,
  builder: (context) => CoverSheet(monthId: monthId, date: date),
);

/// The cover form: the pre-filled amount, the caption, the engine's errors
/// and **Cover** / **Cancel** pinned under it. The amount is checked again
/// against the live month when Cover is tapped (the engine refuses a stale
/// one, F-012 §4).
class CoverSheet extends ConsumerStatefulWidget {
  const new({required this.monthId, required this.date, super.key});

  final int monthId;
  final CalendarDate date;

  @override
  ConsumerState<CoverSheet> createState() => _CoverSheetState();
}

class _CoverSheetState extends ConsumerState<CoverSheet> {
  late final TextEditingController _amount;
  bool _saving = false;
  bool _showErrors = false;
  String? _saveError;

  (int, CalendarDate) get _key => (widget.monthId, widget.date);

  DayDetailsView? get _view => ref.read(dayDetailsProvider(_key)).value;

  @override
  void initState() {
    super.initState();
    final offer = _view?.summary.coverOffer;
    _amount = TextEditingController(
      text: offer is CoverAvailable ? amountInputText(offer.max) : '',
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  CoverProblem? _problem(DayDetailsView view) => switch (validateCover(
    view.result,
    widget.date,
    CoverDraft(_amount.text),
  )) {
    CoverOk() => null,
    CoverNotOk(:final problem) => problem,
  };

  String _message(CoverProblem problem, DaySummary day) => switch (problem) {
    CoverProblem.missing ||
    CoverProblem.notPositive => DayDetailsCopy.amountMissing,
    CoverProblem.badFormat => TransactionsCopy.amountBadFormat,
    CoverProblem.tooLarge => TransactionsCopy.amountTooLarge,
    CoverProblem.exceedsPot => DayDetailsCopy.exceedsPot(formatRupees(day.pot)),
    CoverProblem.exceedsOverspend || CoverProblem.notOffered =>
      DayDetailsCopy.exceedsOverspend(formatRupees(day.overspend)),
  };

  Future<void> _cover() async {
    if (_saving) return;
    final view = _view;
    if (view == null) return;
    final problem = _problem(view);
    if (problem != null) {
      setState(() {
        _showErrors = true;
        _saveError = null;
      });
      return;
    }
    final amount = (validateCover(
      view.result,
      widget.date,
      CoverDraft(_amount.text),
    ) as CoverOk).amount;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final stored = await ref
          .read(savingsRepositoryProvider)
          .cover(
            widget.monthId,
            widget.date,
            amount,
            today: ref.read(todayProvider),
            now: ref.read(nowMillisProvider)(),
          );
      if (!mounted) return;
      final id = stored.coverId;
      if (id == null) {
        // The engine refused after all (the month moved under the sheet).
        setState(() {
          _saving = false;
          _showErrors = true;
        });
        return;
      }
      Navigator.of(context).pop<CoverSaved>((coverId: id, amount: amount));
    } on StorageException {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = StorageCopy.saveError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(dayDetailsProvider(_key)).value;
    final colors = context.budgetColors;
    if (view == null) return const SizedBox.shrink();
    final day = view.summary;
    final problem = _showErrors ? _problem(view) : null;
    final caption = coverCaption(
      amountText: _amount.text,
      overspend: day.overspend,
      pot: day.pot,
    );
    final line = day.overspendUnderRupee
        ? DayDetailsCopy.coverLineUnderRupee(formatRupees(day.pot))
        : DayDetailsCopy.coverLine(
            formatRupees(day.overspend),
            formatRupees(day.pot),
          );
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    // With the keyboard up on a short screen (landscape) only Cover stays
    // pinned; Cancel scrolls with the form, so the field keeps its room.
    final tight = inset > 0 && MediaQuery.sizeOf(context).height - inset < 420;
    final cancel = BudgetButton.secondary(
      label: DayDetailsCopy.coverCancel,
      semanticsHint: DayDetailsCopy.coverCancelHint,
      onPressed: _saving ? null : () => Navigator.of(context).pop<CoverSaved>(),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                BudgetSpacing.space5,
                BudgetSpacing.space4,
                BudgetSpacing.space5,
                BudgetSpacing.space4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      DayDetailsCopy.coverTitle(
                        formatWeekdayDayMonth(widget.date),
                      ),
                      style: context.budgetText.title.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: BudgetSpacing.space2),
                  Text(
                    line,
                    style: BudgetTypeScale.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: BudgetSpacing.space4),
                  AmountField(
                    label: DayDetailsCopy.coverAmountLabel,
                    controller: _amount,
                    errorText: problem == null ? null : _message(problem, day),
                    onChanged: (_) => setState(() => _saveError = null),
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: BudgetSpacing.space2),
                    Text(
                      caption == CoverCaption.wholeOverspend
                          ? DayDetailsCopy.wholeOverspend
                          : DayDetailsCopy.wholePot,
                      style: BudgetTypeScale.body.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                  if (_saveError != null) ...[
                    const SizedBox(height: BudgetSpacing.space3),
                    Semantics(
                      liveRegion: true,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              Icons.error_outline,
                              size: 16,
                              color: colors.overspent,
                            ),
                          ),
                          const SizedBox(width: BudgetSpacing.space2),
                          Expanded(
                            child: Text(
                              _saveError!,
                              style: BudgetTypeScale.body.copyWith(
                                color: colors.overspent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (tight) ...[
                    const SizedBox(height: BudgetSpacing.space3),
                    cancel,
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BudgetSpacing.space5,
              0,
              BudgetSpacing.space5,
              BudgetSpacing.space5,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BudgetButton.primary(
                  label: DayDetailsCopy.coverConfirm,
                  semanticsHint: DayDetailsCopy.coverConfirmHint,
                  loading: _saving,
                  onPressed: _cover,
                ),
                if (!tight) ...[
                  const SizedBox(height: BudgetSpacing.space2),
                  cancel,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
