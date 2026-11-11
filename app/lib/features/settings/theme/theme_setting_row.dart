import 'package:daily_budget/core/copy/help_copy.dart';
import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/core/theme/theme_choice_provider.dart';
import 'package:daily_budget/core/widgets/budget_list_row.dart';
import 'package:daily_budget/features/settings/theme/theme_names.dart';
import 'package:daily_budget/features/settings/theme/theme_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Theme (settings.md §2.2): label, the current choice as its
/// description, an (i) that explains themes, and a chevron. Tapping the row
/// (anywhere but the (i)) opens the theme picker.
///
/// Screen readers hear `Theme. <current choice>`, button, hint `Opens theme
/// options`; the (i) is a separate item, `More about Theme` (D-032).
class ThemeSettingRow extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ThemeSettingRow> createState() => _ThemeSettingRowState();
}

class _ThemeSettingRowState extends ConsumerState<ThemeSettingRow> {
  final _focusNode = FocusNode(debugLabel: 'ThemeSettingRow');

  /// Ignores a second tap while the picker is open (TC-002-34).
  bool _open = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _openPicker() async {
    if (_open) return;
    _open = true;
    try {
      await showThemePicker(context);
    } finally {
      _open = false;
    }
    if (!mounted) return;
    // Back on the row, whose description now shows the new choice
    // (settings.md §3).
    _focusNode.requestFocus();
    context.findRenderObject()?.sendSemanticsEvent(const FocusSemanticEvent());
  }

  @override
  Widget build(BuildContext context) {
    final choice = ref.watch(themeChoiceProvider);
    return BudgetListRow(
      label: ScreenCopy.themeLabel,
      description: choice.rowDescription,
      leadingIcon: Icons.contrast,
      trailing: const BudgetRowChevron(),
      onTap: _openPicker,
      semanticsHint: HelpCopy.themeRowHint,
      focusNode: _focusNode,
      info: (title: ScreenCopy.themeLabel, body: HelpCopy.themeInfoBody),
    );
  }
}
