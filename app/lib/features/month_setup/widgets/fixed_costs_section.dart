import 'package:daily_budget/core/copy/month_setup_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/amount_field.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:daily_budget/core/widgets/budget_icon_button.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The text controllers and focus nodes of one fixed-cost row. They live as
/// long as the screen, so an item brought back by **Undo** shows what the
/// user had typed.
final class ItemFields {
  new(DraftItem item)
    : name = TextEditingController(text: item.name),
      amount = TextEditingController(text: item.amountText);

  final TextEditingController name;
  final TextEditingController amount;
  final nameFocus = FocusNode(debugLabel: 'item name');
  final amountFocus = FocusNode(debugLabel: 'item amount');

  void dispose() {
    name.dispose();
    amount.dispose();
    nameFocus.dispose();
    amountFocus.dispose();
  }
}

/// The [ItemFields] of every item the screen has shown, by item key.
final class ItemFieldRegistry {
  final _fields = <(int, int), ItemFields>{};
  int _generation = 0;

  ItemFields of(DraftItem item) =>
      _fields.putIfAbsent((_generation, item.key), () => ItemFields(item));

  /// The fields of the item with [key], if it was ever shown.
  ItemFields? find(int key) => _fields[(_generation, key)];

  /// The draft was replaced (item keys start again): earlier fields are
  /// never handed out again. They are disposed with the screen.
  void startOver() => _generation++;

  void dispose() {
    for (final fields in _fields.values) {
      fields.dispose();
    }
    _fields.clear();
  }
}

/// The messages shown under one item's fields.
typedef ItemErrors = ({String? name, String? amount});

/// The fixed-costs section (`month-setup.md` §4.4, §4.5): header and
/// description, the item card with `+ Add item`, and `Total fixed costs`.
class FixedCostsSection extends StatelessWidget {
  const new({
    required this.header,
    required this.description,
    required this.items,
    required this.registry,
    required this.total,
    required this.canAdd,
    required this.onAdd,
    required this.onRename,
    required this.onAmount,
    required this.onRemove,
    required this.lastField,
    required this.onNext,
    this.errors = const {},
    super.key,
  });

  final String header;
  final String description;
  final List<DraftItem> items;
  final ItemFieldRegistry registry;
  final Paise total;
  final bool canAdd;
  final VoidCallback onAdd;
  final void Function(int key, String name) onRename;
  final void Function(int key, String text) onAmount;
  final ValueChanged<int> onRemove;

  /// The last field of the whole form: its keyboard key is Done, every
  /// other field's is Next (`month-setup.md` §6).
  final FocusNode lastField;

  /// A field's Next key was pressed: moves to the field after it.
  final ValueChanged<FocusNode> onNext;

  /// The problems to show, by item key.
  final Map<int, ItemErrors> errors;

  /// Above this text size the rows stack (`month-setup.md` §13).
  static const double stackAbove = 1.3;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) >
        FixedCostsSection.stackAbove;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            header,
            style: context.budgetText.title.copyWith(color: colors.textPrimary),
          ),
        ),
        const SizedBox(height: BudgetSpacing.space1),
        Text(
          description,
          style: BudgetTypeScale.body.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: BudgetSpacing.space3),
        BudgetCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (items.isNotEmpty) ...[
                if (!stacked) const _Captions(),
                const _AmountHelp(),
              ],
              for (final (index, item) in items.indexed) ...[
                if (index > 0) Divider(height: 1, color: colors.border),
                _ItemRow(
                  key: ValueKey(item.key),
                  item: item,
                  position: index + 1,
                  count: items.length,
                  fields: registry.of(item),
                  stacked: stacked,
                  errors: errors[item.key],
                  onRename: (text) => onRename(item.key, text),
                  onAmount: (text) => onAmount(item.key, text),
                  onRemove: () => onRemove(item.key),
                  lastField: lastField,
                  onNext: onNext,
                ),
              ],
              if (items.isNotEmpty) Divider(height: 1, color: colors.border),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BudgetSpacing.space2,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: BudgetButton.text(
                    label: MonthSetupCopy.addItem,
                    semanticsHint: MonthSetupCopy.addItemHint,
                    onPressed: canAdd ? onAdd : null,
                  ),
                ),
              ),
              if (!canAdd)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BudgetSpacing.space4,
                    0,
                    BudgetSpacing.space4,
                    BudgetSpacing.space3,
                  ),
                  child: Text(
                    MonthSetupCopy.itemLimit,
                    style: BudgetTypeScale.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: BudgetSpacing.space3),
        _TotalLine(total: total),
      ],
    );
  }
}

class _Captions extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final style = BudgetTypeScale.caption.copyWith(
      color: context.budgetColors.textSecondary,
    );
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BudgetSpacing.space4,
          BudgetSpacing.space3,
          BudgetSpacing.space4,
          0,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(MonthSetupCopy.itemName, style: style),
            ),
            const SizedBox(width: BudgetSpacing.space2),
            Expanded(
              flex: 2,
              child: Text(
                MonthSetupCopy.itemAmount,
                style: style,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: BudgetSpacing.touchTarget),
          ],
        ),
      ),
    );
  }
}

class _AmountHelp extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BudgetSpacing.space4,
        BudgetSpacing.space1,
        BudgetSpacing.space4,
        0,
      ),
      child: Text(
        MonthSetupCopy.itemAmountHelp,
        style: BudgetTypeScale.caption.copyWith(
          color: context.budgetColors.textSecondary,
        ),
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  const new({required this.total});

  final Paise total;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final amount = formatRupees(total);
    return Semantics(
      container: true,
      label:
          '${MonthSetupCopy.totalFixedCosts}. ${formatRupeesForSpeech(total)}',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Text(
                MonthSetupCopy.totalFixedCosts,
                style: BudgetTypeScale.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            Text(
              amount,
              style: BudgetTypeScale.moneyMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const new({
    required this.item,
    required this.position,
    required this.count,
    required this.fields,
    required this.stacked,
    required this.errors,
    required this.onRename,
    required this.onAmount,
    required this.onRemove,
    required this.lastField,
    required this.onNext,
    super.key,
  });

  final DraftItem item;
  final int position;
  final int count;
  final ItemFields fields;
  final bool stacked;
  final ItemErrors? errors;
  final ValueChanged<String> onRename;
  final ValueChanged<String> onAmount;
  final VoidCallback onRemove;
  final FocusNode lastField;
  final ValueChanged<FocusNode> onNext;

  @override
  Widget build(BuildContext context) {
    final nameField = _NameField(
      fields: fields,
      position: position,
      count: count,
      showCaption: stacked,
      hasError: errors?.name != null,
      onChanged: onRename,
      lastField: lastField,
      onNext: onNext,
    );
    final amountField = _AmountEntry(
      fields: fields,
      name: item.name,
      position: position,
      showCaption: stacked,
      hasError: errors?.amount != null,
      onChanged: onAmount,
      lastField: lastField,
      onNext: onNext,
    );
    final remove = BudgetIconButton(
      icon: Icons.close,
      iconSize: 20,
      tooltip: MonthSetupCopy.removeTooltip(item.name),
      onPressed: onRemove,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BudgetSpacing.space4,
        BudgetSpacing.space3,
        BudgetSpacing.space1,
        BudgetSpacing.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stacked) ...[
            nameField,
            const SizedBox(height: BudgetSpacing.space2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: amountField),
                remove,
              ],
            ),
          ] else
            Row(
              children: [
                Expanded(flex: 3, child: nameField),
                const SizedBox(width: BudgetSpacing.space2),
                Expanded(flex: 2, child: amountField),
                remove,
              ],
            ),
          if (errors?.name case final message?) _RowError(message),
          if (errors?.amount case final message?) _RowError(message),
        ],
      ),
    );
  }
}

/// Next on every field, Done on the form's last (`month-setup.md` §6).
TextInputAction _keyFor(FocusNode node, FocusNode lastField) =>
    identical(node, lastField) ? TextInputAction.done : TextInputAction.next;

/// Next moves to the field after [node]; Done keeps the default (close the
/// keyboard), so it has no callback.
VoidCallback? _nextFor(
  FocusNode node,
  FocusNode lastField,
  ValueChanged<FocusNode> onNext,
) => identical(node, lastField) ? null : () => onNext(node);

InputDecoration _fieldDecoration(
  BuildContext context, {
  required bool hasError,
  String? prefix,
}) {
  final colors = context.budgetColors;
  return InputDecoration(
    isDense: true,
    prefixText: prefix,
    prefixStyle: BudgetTypeScale.moneyMedium.copyWith(
      color: colors.textSecondary,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: BudgetSpacing.space3,
      vertical: BudgetSpacing.space3,
    ),
    constraints: const BoxConstraints(minHeight: BudgetSpacing.touchTarget),
    // The message is shown under the whole row; the field only needs the
    // error outline.
    error: hasError ? const SizedBox.shrink() : null,
  );
}

class _NameField extends StatelessWidget {
  const new({
    required this.fields,
    required this.position,
    required this.count,
    required this.showCaption,
    required this.hasError,
    required this.onChanged,
    required this.lastField,
    required this.onNext,
  });

  final ItemFields fields;
  final int position;
  final int count;
  final bool showCaption;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final FocusNode lastField;
  final ValueChanged<FocusNode> onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCaption) const _SmallLabel(MonthSetupCopy.itemName),
        Semantics(
          label: MonthSetupCopy.itemNameSemantics(position, count),
          child: TextField(
            controller: fields.name,
            focusNode: fields.nameFocus,
            onChanged: onChanged,
            // Counts characters the way the user sees them (Hindi, emoji),
            // which pure Dart cannot (S5); no counter is shown.
            maxLength: maxItemNameLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: (
              context, {
              required currentLength,
              required isFocused,
              required maxLength,
            }) => null,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: _keyFor(fields.nameFocus, lastField),
            onEditingComplete: _nextFor(fields.nameFocus, lastField, onNext),
            style: BudgetTypeScale.bodyLarge.copyWith(
              color: colors.textPrimary,
            ),
            decoration: _fieldDecoration(context, hasError: hasError),
          ),
        ),
      ],
    );
  }
}

class _AmountEntry extends StatelessWidget {
  const new({
    required this.fields,
    required this.name,
    required this.position,
    required this.showCaption,
    required this.hasError,
    required this.onChanged,
    required this.lastField,
    required this.onNext,
  });

  final ItemFields fields;
  final String name;
  final int position;
  final bool showCaption;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final FocusNode lastField;
  final ValueChanged<FocusNode> onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCaption) const _SmallLabel(MonthSetupCopy.itemAmount),
        Semantics(
          label: MonthSetupCopy.itemAmountSemantics(name, position),
          child: TextField(
            controller: fields.amount,
            focusNode: fields.amountFocus,
            onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.end,
            textInputAction: _keyFor(fields.amountFocus, lastField),
            onEditingComplete: _nextFor(fields.amountFocus, lastField, onNext),
            style: BudgetTypeScale.moneyMedium.copyWith(
              color: colors.textPrimary,
            ),
            decoration: _fieldDecoration(
              context,
              hasError: hasError,
              prefix: AmountField.prefix,
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallLabel extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BudgetSpacing.space1),
      child: ExcludeSemantics(
        child: Text(
          text,
          style: BudgetTypeScale.caption.copyWith(
            color: context.budgetColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _RowError extends StatelessWidget {
  const new(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = context.budgetColors.overspent;
    return Padding(
      padding: const EdgeInsets.only(
        top: BudgetSpacing.space1,
        right: BudgetSpacing.space3,
      ),
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
