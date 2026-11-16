import 'package:daily_budget/core/providers/today_provider.dart';
import 'package:daily_budget/data/repositories/month_repository.dart';
import 'package:daily_budget/data/repositories/storage_exception.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:daily_budget/features/month_setup/month_setup_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget/fixtures.dart';
import '../../helpers/fake_money_store.dart';
import '../../helpers/setup_harness.dart';

/// A controller on `store` for `mode`, today = `today`. Dispose the container
/// inside the test.
({
  ProviderContainer container,
  MonthSetupController controller,
  MovableClock clock,
})
_open(FakeMoneyStore store, CalendarDate today, SetupMode mode) {
  final clock = MovableClock(today);
  final container = containerOn(store, clock)
    ..listen(monthSetupControllerProvider(mode), (_, _) {});
  return (
    container: container,
    controller: container.read(monthSetupControllerProvider(mode).notifier),
    clock: clock,
  );
}

/// The E2 entry on a first setup: day 5, salary 40000, Rent 10000, EMI 5000,
/// Subscriptions 100. The suggested items have the keys 0, 1 and 2.
void _enterE2(MonthSetupController c) {
  c
    ..chooseSalaryDay(5)
    ..setSalary('40000')
    ..setItemAmount(0, '10000')
    ..setItemAmount(1, '5000')
    ..setItemAmount(2, '100');
}

BudgetPeriod _only(FakeMoneyStore store) => store.months.single.periods.single;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('first setup', () {
    const mode = FirstSetupMode();

    test(
      'TC-008-16 confirming saves the month and the engine budgets',
      () async {
        final store = FakeMoneyStore();
        final (:container, :controller, clock: _) = _open(
          store,
          d(2026, 11, 5),
          mode,
        );
        _enterE2(controller);

        expect(await controller.submit(), isA<SubmitSaved>());

        final stored = store.months.single;
        expect(stored.month.start, d(2026, 11, 5));
        expect(stored.firstBudgetedDay, d(2026, 11, 5));
        expect(_only(store).start, d(2026, 11, 5));
        expect(_only(store).continuedWithShortfall, isFalse);
        final values = _only(store).values as FullMonthValues;
        expect(values.salary, p(4000000));
        expect(
          [for (final c in values.fixedCosts) c.name],
          ['Rent', 'EMI', 'Subscriptions'],
        );
        expect(budgetPaise(storedResult(store, d(2026, 11, 5))), [
          ...List.filled(30, 83000),
        ]);
        container.dispose();
      },
    );

    test('TC-008-16 a second tap while saving saves nothing more', () async {
      final store = FakeMoneyStore();
      final (:container, :controller, clock: _) = _open(
        store,
        d(2026, 11, 5),
        mode,
      );
      _enterE2(controller);

      final first = controller.submit();
      final second = controller.submit();

      expect(await second, isA<SubmitIgnored>());
      expect(await first, isA<SubmitSaved>());
      expect(store.months, hasLength(1));
      container.dispose();
    });

    test('TC-008-06 the salary is stored to the paisa', () async {
      for (final (typedText, paise) in [
        ('99.50', 9950),
        ('40000', 4000000),
        ('100000000', 10000000000),
      ]) {
        final store = FakeMoneyStore();
        final (:container, :controller, clock: _) = _open(
          store,
          d(2026, 11, 5),
          mode,
        );
        controller
          ..chooseSalaryDay(5)
          ..setSalary(typedText);
        expect(
          await controller.submit(),
          isA<SubmitSaved>(),
          reason: typedText,
        );
        expect(
          (_only(store).values as FullMonthValues).salary,
          p(paise),
          reason: typedText,
        );
        container.dispose();
      }
    });

    test(
      'TC-008-05 a problem is reported first and nothing is saved',
      () async {
        final store = FakeMoneyStore();
        final (:container, :controller, clock: _) = _open(
          store,
          d(2026, 11, 5),
          mode,
        );

        final noDay = await controller.submit() as SubmitInvalid;
        expect(noDay.first.field, FieldId.salaryDay);
        expect(
          container.read(monthSetupControllerProvider(mode)).showErrors,
          isTrue,
        );

        controller.chooseSalaryDay(5);
        final noSalary = await controller.submit() as SubmitInvalid;
        expect(noSalary.first.field, FieldId.salary);
        expect(noSalary.first.problem, FieldProblem.missing);
        expect(store.months, isEmpty);
        container.dispose();
      },
    );

    test(
      'TC-008-17 a failed write keeps every value and can be retried',
      () async {
        final store = FakeMoneyStore();
        final (:container, :controller, clock: _) = _open(
          store,
          d(2026, 11, 5),
          mode,
        );
        _enterE2(controller);
        final before = container.read(monthSetupControllerProvider(mode)).draft;

        store.failNextWrite = true;
        final failed = await controller.submit() as SubmitFailed;

        expect(failed.error.kind, StorageFailureKind.write);
        expect(store.months, isEmpty);
        final state = container.read(monthSetupControllerProvider(mode));
        expect(state.isSaving, isFalse);
        expect(state.draft, same(before));
        expect(await controller.submit(), isA<SubmitSaved>());
        expect(store.months, hasLength(1));
        container.dispose();
      },
    );

    test('TC-008-12 a shortfall asks first, then saves ₹0 days', () async {
      final store = FakeMoneyStore();
      final (:container, :controller, clock: _) = _open(
        store,
        d(2026, 11, 5),
        mode,
      );
      controller
        ..chooseSalaryDay(5)
        ..setSalary('20000')
        ..setItemAmount(0, '15000')
        ..setItemAmount(1, '6000');

      final choice = await controller.submit() as SubmitNeedsChoice;
      expect(choice.kind, ShortfallKind.shortfall);
      expect(choice.shortfall, p(100000));
      expect(choice.basis, PreviewBasis.salary);
      expect(choice.isEdit, isFalse);
      expect(store.months, isEmpty, reason: 'Fix my numbers saves nothing');

      expect(await controller.submit(continueAnyway: true), isA<SubmitSaved>());
      expect(_only(store).continuedWithShortfall, isTrue);
      final result = storedResult(store, d(2026, 11, 20));
      expect(budgetPaise(result), List.filled(30, 0));
      expect(result.totals.shortfall, p(100000));
      container.dispose();
    });

    test(
      'TC-008-13 the shortfall names the target and exactly ₹0 asks too',
      () async {
        final store = FakeMoneyStore();
        final (:container, :controller, clock: _) = _open(
          store,
          d(2026, 11, 5),
          mode,
        );
        controller
          ..chooseSalaryDay(5)
          ..setSalary('20000')
          ..setTargetOn(on: true)
          ..setTarget('19000')
          ..setItemAmount(0, '15000')
          ..setItemAmount(1, '6000');
        final target = await controller.submit() as SubmitNeedsChoice;
        expect(target.basis, PreviewBasis.target);
        expect(target.shortfall, p(200000));

        controller
          ..setTargetOn(on: false)
          ..setItemAmount(1, '5000');
        final zero = await controller.submit() as SubmitNeedsChoice;
        expect(zero.kind, ShortfallKind.zero);
        expect(zero.shortfall, Paise.zero);
        expect(
          await controller.submit(continueAnyway: true),
          isA<SubmitSaved>(),
        );
        final result = storedResult(store, d(2026, 11, 5));
        expect(budgetPaise(result), List.filled(30, 0));
        expect(result.totals.shortfall, Paise.zero);
        container.dispose();
      },
    );

    test('TC-008-14 a first setup on 10 Nov spreads the money left', () async {
      final store = FakeMoneyStore();
      final (:container, :controller, clock: _) = _open(
        store,
        d(2026, 11, 10),
        mode,
      );
      controller.chooseSalaryDay(5);
      expect(
        container.read(monthSetupControllerProvider(mode)).draft.kind,
        SetupKind.midMonth,
      );
      controller.setMoneyLeft('24900');

      expect(await controller.submit(), isA<SubmitSaved>());

      final stored = store.months.single;
      expect(stored.month.start, d(2026, 11, 5));
      expect(stored.firstBudgetedDay, d(2026, 11, 10));
      expect(_only(store).start, d(2026, 11, 10));
      expect(
        (_only(store).values as MidMonthStartValues).moneyLeft,
        p(2490000),
      );
      expect(budgetPaise(storedResult(store, d(2026, 11, 10))), [
        ...List.filled(25, 99600),
      ]);
      container.dispose();
    });

    test(
      'TC-008-15 on 11 Nov the extra paise go to the first 8 days',
      () async {
        final store = FakeMoneyStore();
        final (:container, :controller, clock: _) = _open(
          store,
          d(2026, 11, 11),
          mode,
        );
        controller
          ..chooseSalaryDay(5)
          ..setMoneyLeft('20000');
        expect(await controller.submit(), isA<SubmitSaved>());
        expect(budgetPaise(storedResult(store, d(2026, 11, 11))), [
          ...List.filled(8, 83334),
          ...List.filled(16, 83333),
        ]);
        container.dispose();
      },
    );

    test('TC-008-44 a mid-month shortfall is against the money left', () async {
      final store = FakeMoneyStore();
      final (:container, :controller, clock: _) = _open(
        store,
        d(2026, 11, 10),
        mode,
      );
      controller
        ..chooseSalaryDay(5)
        ..setMoneyLeft('10000');
      final key = controller.addItem();
      controller
        ..renameItem(key, 'Rent')
        ..setItemAmount(key, '12000');

      final choice = await controller.submit() as SubmitNeedsChoice;
      expect(choice.shortfall, p(200000));
      expect(choice.basis, PreviewBasis.moneyLeft);

      expect(await controller.submit(continueAnyway: true), isA<SubmitSaved>());
      final result = storedResult(store, d(2026, 11, 10));
      expect(budgetPaise(result), List.filled(25, 0));
      expect(result.totals.shortfall, p(200000));
      container.dispose();
    });

    test(
      'TC-008-39 confirming after midnight saves the month of today',
      () async {
        final store = FakeMoneyStore();
        final (:container, :controller, :clock) = _open(
          store,
          d(2026, 12, 4),
          mode,
        );
        controller
          ..chooseSalaryDay(5)
          ..setMoneyLeft('500');
        expect(
          container.read(monthSetupControllerProvider(mode)).draft.kind,
          SetupKind.midMonth,
          reason: '4 Dec is the last day of 5 Nov to 4 Dec',
        );

        clock.moveTo(d(2026, 12, 5));
        container.read(todayProvider.notifier).refresh();
        final state = container.read(monthSetupControllerProvider(mode));
        expect(
          state.draft.kind,
          SetupKind.full,
          reason: '5 Dec is a start day',
        );
        expect(state.draft.salaryDay, 5, reason: 'the chosen day is kept');
        expect(state.draft.moneyLeftText, '500', reason: 'typed text is kept');

        controller
          ..setSalary('40000')
          ..setItemAmount(0, '10000')
          ..setItemAmount(1, '5000')
          ..setItemAmount(2, '100');
        expect(await controller.submit(), isA<SubmitSaved>());
        final stored = store.months.single;
        expect(stored.month.start, d(2026, 12, 5));
        expect(stored.month.end, d(2027, 1, 4));
        expect(stored.firstBudgetedDay, d(2026, 12, 5));
        container.dispose();
      },
    );

    test('TC-008-08 a deleted item comes back in the same place', () {
      final store = FakeMoneyStore();
      final (:container, :controller, clock: _) = _open(
        store,
        d(2026, 11, 5),
        mode,
      );
      controller.setItemAmount(1, '5000');
      final removed = controller.removeItem(1);
      List<String> names() => [
        for (final item
            in container.read(monthSetupControllerProvider(mode)).draft.items)
          item.name,
      ];
      expect(names(), ['Rent', 'Subscriptions']);

      expect(controller.restoreItem(removed), isTrue);
      expect(names(), ['Rent', 'EMI', 'Subscriptions']);
      expect(
        container
            .read(monthSetupControllerProvider(mode))
            .draft
            .items[1]
            .amountText,
        '5000',
      );
      container.dispose();
    });

    test('TC-008-09 an item cannot be restored into a full list', () {
      final (:container, :controller, clock: _) = _open(
        FakeMoneyStore(),
        d(2026, 11, 5),
        mode,
      );
      for (var i = 0; i < 27; i++) {
        controller.addItem();
      }
      final removed = controller.removeItem(0);
      controller.addItem();
      expect(
        container.read(monthSetupControllerProvider(mode)).draft.canAddItem,
        isFalse,
      );
      expect(controller.restoreItem(removed), isFalse);
      container.dispose();
    });
  });

  group('a new month', () {
    test('TC-008-19 the start day opens with last months numbers', () async {
      final store = storeWithMonth(values: e2Values(target: 2000000));
      final mode = NewMonthMode(store.months.single);
      final (:container, :controller, clock: _) = _open(
        store,
        d(2026, 12, 5),
        mode,
      );
      final state = container.read(monthSetupControllerProvider(mode));
      expect(state.draft.kind, SetupKind.full);
      expect(state.draft.salaryDay, 5);
      expect(state.draft.salaryText, '40000');
      expect(state.draft.targetOn, isTrue);
      expect(state.draft.targetText, '20000');
      expect(
        [for (final i in state.draft.items) (i.name, i.amountText)],
        [('Rent', '10000'), ('EMI', '5000'), ('Subscriptions', '100')],
      );
      expect(state.changed, isFalse);
      final preview =
          container.read(setupPreviewProvider(mode)) as PreviewReady;
      expect(preview.month.start, d(2026, 12, 5));
      expect(preview.month.length, 31);
      expect(preview.dailyBudget, p(15807));
      expect(store.months, hasLength(1), reason: 'nothing saved until Confirm');

      expect(await controller.submit(), isA<SubmitSaved>());
      expect(store.months, hasLength(2));
      expect(store.months.last.month.start, d(2026, 12, 5));
      container.dispose();
    });

    test('TC-008-56 a late setup starts fresh from today', () async {
      final store = storeWithMonth();
      final mode = NewMonthMode(store.months.single);
      final (:container, :controller, clock: _) = _open(
        store,
        d(2026, 12, 12),
        mode,
      );
      final draft = container.read(monthSetupControllerProvider(mode)).draft;
      expect(draft.kind, SetupKind.midMonth);
      expect(draft.items, isEmpty);
      expect(draft.salaryDay, 5);
      controller.setMoneyLeft('24000');

      expect(await controller.submit(), isA<SubmitSaved>());

      final stored = store.months.last;
      expect(stored.month.start, d(2026, 12, 5));
      expect(stored.firstBudgetedDay, d(2026, 12, 12));
      final result = computeMonth(store.inputFor(stored.id, d(2026, 12, 12)));
      expect(budgetPaise(result), List.filled(24, 100000));
      expect(result.dayOn(d(2026, 12, 11)).status, DayStatus.notBudgeted);
      container.dispose();
    });

    test(
      'TC-008-41 after missed months only the month of today is created',
      () async {
        final store = storeWithMonth(month: oct2026);
        final mode = NewMonthMode(store.months.single);
        final (:container, :controller, clock: _) = _open(
          store,
          d(2026, 12, 20),
          mode,
        );
        controller.setMoneyLeft('16000');

        expect(await controller.submit(), isA<SubmitSaved>());

        expect(store.months, hasLength(2));
        final stored = store.months.last;
        expect(stored.month.start, d(2026, 12, 5));
        expect(stored.firstBudgetedDay, d(2026, 12, 20));
        expect(
          budgetPaise(computeMonth(store.inputFor(stored.id, d(2026, 12, 20)))),
          List.filled(16, 100000),
        );
        container.dispose();
      },
    );

    test(
      'TC-008-39 a pre-filled setup open past its start day becomes fresh',
      () {
        final store = storeWithMonth();
        final mode = NewMonthMode(store.months.single);
        final (:container, controller: _, :clock) = _open(
          store,
          d(2026, 12, 5),
          mode,
        );
        expect(
          container.read(monthSetupControllerProvider(mode)).draft.kind,
          SetupKind.full,
        );

        clock.moveTo(d(2026, 12, 6));
        container.read(todayProvider.notifier).refresh();

        final state = container.read(monthSetupControllerProvider(mode));
        expect(state.draft.kind, SetupKind.midMonth);
        expect(state.draft.items, isEmpty);
        expect(state.changed, isFalse);
        container.dispose();
      },
    );
  });

  group('edit this month', () {
    StoredMonth e2(FakeMoneyStore store) => store.months.single;

    test('TC-008-45 nothing changed is nothing to save', () async {
      final store = storeWithMonth();
      final mode = EditMonthMode(e2(store));
      final (:container, :controller, clock: _) = _open(
        store,
        d(2026, 11, 20),
        mode,
      );
      expect(await controller.submit(), isA<SubmitIgnored>());

      controller.setItemAmount(0, '13000');
      expect(
        container.read(monthSetupControllerProvider(mode)).changed,
        isTrue,
      );
      controller.setItemAmount(0, '10000');
      expect(
        container.read(monthSetupControllerProvider(mode)).changed,
        isFalse,
      );
      expect(await controller.submit(), isA<SubmitIgnored>());
      expect(e2(store).periods, hasLength(1));
      container.dispose();
    });

    test(
      'TC-008-20 raising the rent on 20 Nov recalculates the days left',
      () async {
        final store = storeWithMonth();
        final mode = EditMonthMode(e2(store));
        final (:container, :controller, clock: _) = _open(
          store,
          d(2026, 11, 20),
          mode,
        );
        controller.setItemAmount(0, '13000');
        final preview =
            container.read(setupPreviewProvider(mode)) as PreviewReady;
        expect(preview.dailyBudget, p(63000));
        expect(preview.days, 15);

        expect(await controller.submit(), isA<SubmitSaved>());

        final periods = e2(store).periods;
        expect(periods, hasLength(2));
        expect(periods.first.start, d(2026, 11, 5), reason: 'history is kept');
        expect(periods.last.start, d(2026, 11, 20));
        expect(periods.last.continuedWithShortfall, isFalse);
        expect(budgetPaise(storedResult(store, d(2026, 11, 20))), [
          ...List.filled(15, 83000),
          ...List.filled(15, 63000),
        ]);
        container.dispose();
      },
    );

    test(
      'TC-008-21 a salary of ₹35,000 stores 49,667 then 49,666 paise',
      () async {
        final store = storeWithMonth();
        final mode = EditMonthMode(e2(store));
        final (:container, :controller, clock: _) = _open(
          store,
          d(2026, 11, 20),
          mode,
        );
        controller.setSalary('35000');
        expect(await controller.submit(), isA<SubmitSaved>());
        expect(budgetPaise(storedResult(store, d(2026, 11, 20))), [
          ...List.filled(15, 83000),
          ...List.filled(10, 49667),
          ...List.filled(5, 49666),
        ]);
        container.dispose();
      },
    );

    test(
      'TC-008-46 an edit on the first day respreads the whole month',
      () async {
        final store = storeWithMonth();
        final mode = EditMonthMode(e2(store));
        final (:container, :controller, clock: _) = _open(
          store,
          d(2026, 11, 5),
          mode,
        );
        controller.setItemAmount(0, '13000');
        final preview =
            container.read(setupPreviewProvider(mode)) as PreviewReady;
        expect(preview.dailyBudget, p(73000));
        expect(preview.days, 30);

        expect(await controller.submit(), isA<SubmitSaved>());

        expect(e2(store).periods, hasLength(2), reason: 'first one kept');
        expect(
          budgetPaise(storedResult(store, d(2026, 11, 5))),
          List.filled(30, 73000),
        );
        container.dispose();
      },
    );

    test(
      'TC-008-28 an edit that causes a shortfall asks, then saves ₹0',
      () async {
        final store = storeWithMonth();
        final mode = EditMonthMode(e2(store));
        final (:container, :controller, clock: _) = _open(
          store,
          d(2026, 11, 20),
          mode,
        );
        controller
          ..setTargetOn(on: true)
          ..setTarget('25000');

        final choice = await controller.submit() as SubmitNeedsChoice;
        expect(choice.isEdit, isTrue);
        expect(choice.basis, PreviewBasis.target);
        expect(choice.shortfall, p(255000));
        expect(e2(store).periods, hasLength(1), reason: 'Fix my numbers');

        expect(
          await controller.submit(continueAnyway: true),
          isA<SubmitSaved>(),
        );
        expect(e2(store).periods.last.continuedWithShortfall, isTrue);
        final result = storedResult(store, d(2026, 11, 20));
        expect(budgetPaise(result), [
          ...List.filled(15, 83000),
          ...List.filled(15, 0),
        ]);
        expect(result.totals.shortfall, p(255000));
        container.dispose();
      },
    );

    test(
      'TC-008-47 a failed edit adds no period and keeps the input',
      () async {
        final store = storeWithMonth();
        final mode = EditMonthMode(e2(store));
        final (:container, :controller, clock: _) = _open(
          store,
          d(2026, 11, 20),
          mode,
        );
        controller.setItemAmount(0, '13000');

        store.failNextWrite = true;
        expect(await controller.submit(), isA<SubmitFailed>());

        expect(e2(store).periods, hasLength(1));
        expect(
          container
              .read(monthSetupControllerProvider(mode))
              .draft
              .items
              .first
              .amountText,
          '13000',
        );
        container.dispose();
      },
    );

    test(
      'TC-008-39 an edit open past the end of its month has nothing to save',
      () async {
        final store = storeWithMonth();
        final mode = EditMonthMode(e2(store));
        final (:container, :controller, :clock) = _open(
          store,
          d(2026, 12, 4),
          mode,
        );
        controller.setItemAmount(0, '13000');
        expect(
          container.read(setupPreviewProvider(mode)),
          isA<PreviewReady>(),
          reason: '4 Dec is the last day of the month',
        );

        clock.moveTo(d(2026, 12, 5));
        container.read(todayProvider.notifier).refresh();

        expect(
          container.read(setupPreviewProvider(mode)),
          isA<PreviewNeedsAmount>(),
        );
        expect(await controller.submit(), isA<SubmitMonthEnded>());
        expect(e2(store).periods, hasLength(1));
        container.dispose();
      },
    );

    test(
      'TC-008-20 the money left of a mid-month start is edited as saved',
      () async {
        final store = storeWithMonth(
          values: const MidMonthStartValues(moneyLeft: Paise(2490000)),
          firstBudgetedDay: d(2026, 11, 10),
        );
        final mode = EditMonthMode(e2(store));
        final (:container, :controller, clock: _) = _open(
          store,
          d(2026, 11, 20),
          mode,
        );
        final draft = container.read(monthSetupControllerProvider(mode)).draft;
        expect(draft.kind, SetupKind.midMonth);
        expect(draft.moneyLeftText, '24900');
        controller.setMoneyLeft('26400');
        // 10 days are already budgeted at ₹996, so ₹26,400 - ₹9,960 = ₹16,440
        // is left for the 15 days from 20 Nov: ₹1,096 a day.
        final preview =
            container.read(setupPreviewProvider(mode)) as PreviewReady;
        expect(preview.dailyBudget, p(109600));
        container.dispose();
      },
    );
  });
}
