import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// The shared frame of a tab (app-shell §2): the title header as the first
/// item of the scrolling page (so it wraps at large text), an optional
/// first-time hint, then the body. Reading order follows the same order.
class TabPage extends StatelessWidget {
  const new({
    required this.title,
    required this.controller,
    required Widget this.body,
    this.hint,
    super.key,
  }) : bodySlivers = null;

  /// A page whose body is its own slivers, so a long list is built lazily
  /// (F-009 AC-15).
  const new slivers({
    required this.title,
    required this.controller,
    required List<Widget> this.bodySlivers,
    this.hint,
    super.key,
  }) : body = null;

  final String title;
  final ScrollController controller;
  final Widget? body;
  final List<Widget>? bodySlivers;

  /// The first-time hint card (F-004, filled in T-118).
  final Widget? hint;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        controller: controller,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                BudgetSpacing.space5,
                BudgetSpacing.space7,
                BudgetSpacing.space5,
                BudgetSpacing.space4,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: context.budgetText.headline.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          if (hint case final hint?) SliverToBoxAdapter(child: hint),
          if (body case final body?) SliverToBoxAdapter(child: body),
          ...?bodySlivers,
          // The bar sits below the page (Scaffold), so this only keeps the
          // last item clear of it.
          const SliverToBoxAdapter(
            child: SizedBox(height: BudgetSpacing.space6),
          ),
        ],
      ),
    );
  }
}
