import 'package:daily_budget/core/copy/help_copy.dart';
import 'package:daily_budget/core/copy/screen_copy.dart';
import 'package:daily_budget/core/help/first_time_hint.dart';
import 'package:daily_budget/core/theme/budget_text.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_card.dart';
import 'package:daily_budget/domain/preferences/hint_id.dart';
import 'package:daily_budget/features/settings/coming_soon_row.dart';
import 'package:daily_budget/features/settings/theme/theme_setting_row.dart';
import 'package:daily_budget/features/shell/app_tab.dart';
import 'package:daily_budget/features/shell/tab_page.dart';
import 'package:flutter/material.dart';

/// The Settings tab (F-003 AC-5, settings.md §2): three groups of rows in
/// the fixed order Theme, Notifications, Bank account, Salary date,
/// Categories, Privacy & data, How this app works, Disclaimer.
class SettingsTab extends StatelessWidget {
  const new({required this.controller, super.key});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return TabPage(
      title: AppTab.settings.title,
      controller: controller,
      hint: const FirstTimeHint(id: HintId.settings),
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GroupHeader(ScreenCopy.groupGeneral),
          _Group([
            ThemeSettingRow(),
            ComingSoonRow(
              label: ScreenCopy.notificationsLabel,
              description: HelpCopy.notificationsDescription,
              icon: Icons.notifications_outlined,
            ),
          ]),
          _GroupHeader(ScreenCopy.groupMoney),
          _Group([
            ComingSoonRow(
              label: ScreenCopy.bankAccountLabel,
              description: HelpCopy.bankAccountDescription,
              icon: Icons.account_balance_outlined,
            ),
            ComingSoonRow(
              label: ScreenCopy.salaryDateLabel,
              description: HelpCopy.salaryDateDescription,
              icon: Icons.event_outlined,
            ),
            ComingSoonRow(
              label: ScreenCopy.categoriesLabel,
              description: HelpCopy.categoriesDescription,
              icon: Icons.category_outlined,
            ),
          ]),
          _GroupHeader(ScreenCopy.groupPrivacyHelp),
          _Group([
            ComingSoonRow(
              label: ScreenCopy.privacyLabel,
              description: HelpCopy.privacyDescription,
              icon: Icons.lock_outline,
            ),
            ComingSoonRow(
              label: ScreenCopy.howItWorksLabel,
              description: HelpCopy.howItWorksDescription,
              icon: Icons.menu_book_outlined,
            ),
            ComingSoonRow(
              label: ScreenCopy.disclaimerLabel,
              description: HelpCopy.disclaimerDescription,
              icon: Icons.info_outlined,
            ),
          ]),
          SizedBox(height: BudgetSpacing.space8 - BudgetSpacing.space6),
        ],
      ),
    );
  }
}

/// A group heading: `caption` 500 in `textSecondary`, sentence case, read
/// as a heading.
class _GroupHeader extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BudgetSpacing.space5,
        BudgetSpacing.space6,
        BudgetSpacing.space5,
        BudgetSpacing.space2,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: BudgetTypeScale.caption.copyWith(
            fontWeight: FontWeight.w500,
            color: context.budgetColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// A card of rows separated by hairlines inset to the text start.
class _Group extends StatelessWidget {
  const new(this.rows);

  final List<Widget> rows;

  /// Row padding + leading circle + gap (settings.md §2.1).
  static const double _hairlineInset =
      BudgetSpacing.space5 + 40 + BudgetSpacing.space4;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BudgetSpacing.space5),
      child: BudgetCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (final (i, row) in rows.indexed) ...[
              if (i > 0) const Divider(indent: _hairlineInset),
              row,
            ],
          ],
        ),
      ),
    );
  }
}
