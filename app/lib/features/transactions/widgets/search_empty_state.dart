import 'package:daily_budget/core/copy/search_copy.dart';
import 'package:daily_budget/core/theme/budget_tokens.dart';
import 'package:daily_budget/core/theme/theme_context.dart';
import 'package:daily_budget/core/widgets/budget_button.dart';
import 'package:daily_budget/core/widgets/empty_state.dart';
import 'package:flutter/material.dart';

/// Which words the no-results state uses (`transactions-search.md` §10).
enum NoResultsKind { search, searchAndFilters, filters }

/// The left-aligned state under the results line when nothing matches: the
/// `search_off` circle, one title (it names the search, so it wraps and is
/// never cut) and one secondary button. No description line.
class SearchEmptyState extends StatelessWidget {
  const new({
    required this.kind,
    required this.query,
    required this.onClear,
    super.key,
  });

  final NoResultsKind kind;

  /// The text searched, quoted in the title of [NoResultsKind.search].
  final String query;
  final VoidCallback onClear;

  static const double _maxTextWidth = 320;

  @override
  Widget build(BuildContext context) {
    final colors = context.budgetColors;
    final title = switch (kind) {
      NoResultsKind.search => SearchCopy.noMatchQuery(query.trim()),
      NoResultsKind.searchAndFilters => SearchCopy.noMatchBoth,
      NoResultsKind.filters => SearchCopy.noMatchFilters,
    };
    final searchOnly = kind == NoResultsKind.search;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BudgetSpacing.space5,
        BudgetSpacing.space8,
        BudgetSpacing.space5,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            label: title,
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: EmptyState.circleSize,
                    height: EmptyState.circleSize,
                    decoration: BoxDecoration(
                      color: colors.neutralSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off,
                      size: EmptyState.iconSize,
                      color: colors.neutral,
                    ),
                  ),
                  const SizedBox(height: BudgetSpacing.space5),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxTextWidth),
                    child: Text(
                      title,
                      style: context.budgetText.title.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: BudgetSpacing.space5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxTextWidth),
            child: BudgetButton.secondary(
              label: searchOnly ? SearchCopy.clearSearch : SearchCopy.clearAll,
              semanticsHint: searchOnly
                  ? SearchCopy.clearSearchHint
                  : SearchCopy.clearAllHint,
              onPressed: onClear,
            ),
          ),
        ],
      ),
    );
  }
}
