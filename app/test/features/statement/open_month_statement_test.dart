import 'package:daily_budget/core/providers/database_providers.dart';
import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/core/theme/budget_theme.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/domain/preferences/theme_choice.dart';
import 'package:daily_budget/features/statement/month_statement_screen.dart';
import 'package:daily_budget/features/statement/open_month_statement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/bundled_fonts.dart';
import '../../helpers/fake_month_repository.dart';
import '../../helpers/fake_savings_repository.dart';
import '../../helpers/fake_transaction_repository.dart';
import '../../helpers/phase3_data.dart';
import '../../helpers/phase3_fixtures.dart';
import '../../support/find_copy.dart';

Future<BuildContext> _pump(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  late BuildContext captured;
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: themeConfigFor(ThemeChoice.light).light,
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return captured;
}

void main() {
  setUpAll(loadBundledFonts);

  testWidgets('TC-014-01 statement launcher opens the statement screen by '
      'default', (tester) async {
    final store = storeFor(fixtureM20);
    final context = await _pump(
      tester,
      overrides: [
        monthRepositoryProvider.overrideWithValue(FakeMonthRepository(store)),
        transactionRepositoryProvider.overrideWithValue(
          FakeTransactionRepository(store),
        ),
        savingsRepositoryProvider.overrideWithValue(
          FakeSavingsRepository(store),
        ),
        clockProvider.overrideWithValue(() => fixtureM20.now),
      ],
    );

    openMonthStatement(context, store.months.last.id);
    await tester.pumpAndSettle();

    expect(find.byType(MonthStatementScreen), findsOneWidget);
    expect(findCopy('Month statement'), findsOneWidget);
    expect(
      findCopy('1 – 30 Nov 2026 · so far (to Fri, 20 Nov)'),
      findsOneWidget,
    );
    // Back returns to the host.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(MonthStatementScreen), findsNothing);
  });

  testWidgets('TC-014-01 statement launcher seam passes the month and period', (
    tester,
  ) async {
    final calls = <(int, CalendarDate?)>[];
    final context = await _pump(
      tester,
      overrides: [
        monthStatementLauncherProvider.overrideWithValue(
          (context, monthId, {scrollToPeriodStart}) =>
              calls.add((monthId, scrollToPeriodStart)),
        ),
      ],
    );

    openMonthStatement(context, 3);
    openMonthStatement(
      context,
      4,
      scrollToPeriodStart: CalendarDate(2026, 11, 13),
    );

    expect(calls, [(3, null), (4, CalendarDate(2026, 11, 13))]);
  });
}
