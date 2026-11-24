import 'package:daily_budget/core/copy/statement_copy.dart';
import 'package:daily_budget/core/format/date_format.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/domain/budget/budget.dart';

// The words of the month statement, built in one place from the typed data of
// `buildStatement` (plan F-014 §1.7): the visible line, the (i) text and the
// screen-reader sentence all come from here, so they cannot drift apart.

const _nbsp = ' ';

/// A visible line broken into chunks. A line wraps only between chunks (the
/// design's ` = `, `, minus ` and ` → ` points); spaces inside a chunk do not
/// break. When a chunk is wider than the space available the screen asks for
/// the relaxed form, where only an operator is kept with its amount.
typedef Chunks = List<String>;

/// A visible line and the sentence a screen reader says for it.
typedef StatementLineText = ({Chunks chunks, String speech});

final _operator = RegExp('(→|=|−|minus) ');

/// [chunks] as one string. Strict: every space inside a chunk is a
/// non-breaking one. Relaxed: only the space after an operator is.
String joinChunks(Chunks chunks, {required bool relaxed}) => chunks
    .map(
      (chunk) => relaxed
          ? chunk.replaceAllMapped(_operator, (m) => '${m[1]}$_nbsp')
          : chunk.replaceAll(' ', _nbsp),
    )
    .join(' ');

/// `1 November`, for a screen reader.
String _spokenDate(CalendarDate date) =>
    formatFullDate(date).split(' ').skip(1).join(' ');

/// `35,000 rupees`, `minus 1,000 rupees` (AC-16 reads whole rupees).
String _rupees(Paise amount) => formatRupeesSpoken(amount);

/// `rent`, but `EMI` stays as it is (a lower-case first letter only when the
/// second one is not a capital).
String _inSentence(String text) {
  final second = text.length > 1 ? text[1] : '';
  final startsWithCapitals = second.toLowerCase() != second;
  return startsWithCapitals ? text : _lowerFirst(text);
}

/// `1 – 30 Nov 2026`: the month's range for the switcher.
String monthRangeText(MonthStatement s) =>
    '${formatCompactRange(s.month.start, s.month.end)} ${s.month.end.year}';

/// ` · so far (to Fri, 20 Nov)` for the current month, else null.
String? soFarSuffixText(MonthStatement s) {
  final soFar = s.soFarTo;
  return soFar == null
      ? null
      : StatementCopy.soFarTo(formatWeekdayDayMonth(soFar));
}

/// `5 Nov – 9 Nov: not budgeted (before you started).`
String? notBudgetedText(MonthStatement s) {
  final range = s.notBudgeted;
  if (range == null) return null;
  return StatementCopy.notBudgeted(
    range.start == range.end
        ? formatDayMonth(range.start)
        : formatCompactRange(range.start, range.end),
  );
}

/// `13 Nov – 30 Nov · 18 days`; one day: `30 Nov · 1 day` (D-081 (4)).
String headingText(StatementPeriod p) => p.days == 1
    ? '${formatDayMonth(p.start)} · ${formatDayCount(p.days)}'
    : '${formatRange(p.start, p.end)} · ${formatDayCount(p.days)}';

/// `Period 2 of 2, 13 November to 30 November, 18 days, in progress`.
String headingSpeech(StatementPeriod p) {
  final dates = p.days == 1
      ? _spokenDate(p.start)
      : '${_spokenDate(p.start)} to ${_spokenDate(p.end)}';
  return [
    StatementCopy.overline(p.index, p.of),
    dates,
    formatDayCount(p.days),
    if (p.inProgress) StatementCopy.inProgress,
  ].join(', ');
}

/// `Month started`, `Salary changed`, `Rent renamed to House rent`, ...
String reasonText(StatementReason reason) => switch (reason) {
  StartedReason(:final partway) =>
    partway ? StatementCopy.monthStartedPartway : StatementCopy.monthStarted,
  ChangedBackReason() => StatementCopy.changedAndBack,
  ChangedReason(:final delta) => switch (delta) {
    ValueDelta(:final field, :final name) => switch (field) {
      PeriodField.salary => StatementCopy.salaryChanged,
      PeriodField.target => StatementCopy.targetChanged,
      PeriodField.moneyLeft => StatementCopy.moneyLeftChanged,
      PeriodField.fixedCost ||
      PeriodField.fixedCostStillToPay => StatementCopy.costChanged(name!),
    },
    CostAdded(:final name, :final amount) => StatementCopy.fixedCostAdded(
      name,
      formatRupees(amount),
    ),
    CostRemoved(:final name, :final amount) => StatementCopy.fixedCostRemoved(
      name,
      formatRupees(amount),
    ),
    CostRenamed(:final from, :final to) => StatementCopy.fixedCostRenamed(
      from,
      to,
    ),
  },
};

/// Several reasons joined with ` · `.
String reasonsText(List<StatementReason> reasons) =>
    reasons.map(reasonText).join(' · ');

String _valueName(ValueDelta delta) => switch (delta.field) {
  PeriodField.salary => StatementCopy.salary,
  PeriodField.target => StatementCopy.spendingTarget,
  PeriodField.moneyLeft => StatementCopy.moneyLeft,
  PeriodField.fixedCost || PeriodField.fixedCostStillToPay => delta.name!,
};

/// One difference as chunks: `Salary ₹40,000` / `→ ₹35,000`.
Chunks _deltaChunks(StatementDelta delta) => switch (delta) {
  ValueDelta(before: null, :final after) => [
    StatementCopy.targetSet(formatRupees(after!)),
  ],
  ValueDelta(after: null) => [StatementCopy.targetRemoved],
  ValueDelta() => [
    '${_valueName(delta)} ${formatRupees(delta.before!)}',
    '→ ${formatRupees(delta.after!)}',
  ],
  CostAdded() ||
  CostRemoved() ||
  CostRenamed() => [reasonText(ChangedReason(delta))],
};

/// The same difference as a screen reader says it: `rent ₹10,000 to
/// ₹13,000`; a fixed cost added, removed or renamed is read as written.
String _deltaSpeech(StatementDelta delta) => switch (delta) {
  ValueDelta(:final before, :final after)
      when before == null || after == null =>
    _inSentence(_deltaChunks(delta).single),
  ValueDelta() =>
    '${_inSentence(_valueName(delta))} ${formatRupeesForSpeech(delta.before!)} '
        'to ${formatRupeesForSpeech(delta.after!)}',
  CostAdded() ||
  CostRemoved() ||
  CostRenamed() => reasonText(ChangedReason(delta)),
};

/// One line of What changed (the date and time are in their own column).
StatementLineText changeLineText(StatementChange change) {
  final daily = change.dailyAfter;
  final values = change.values;
  final Chunks lead;
  final String leadSpeech;
  if (change.kind == StatementChangeKind.later) {
    lead = [];
    for (final (i, delta) in change.deltas.indexed) {
      final parts = _deltaChunks(delta);
      final isLast = i == change.deltas.length - 1;
      lead.addAll([
        ...parts.take(parts.length - 1),
        if (isLast) parts.last else '${parts.last} ·',
      ]);
    }
    leadSpeech = change.deltas.map(_deltaSpeech).join(', ');
  } else {
    final String sentence;
    final String speech;
    switch (values) {
      case FullMonthValues(:final salary):
        final fixed = values.fixedCostsTotal;
        sentence = StatementCopy.startedLine(
          formatRupees(salary),
          formatRupees(fixed),
        );
        speech = StatementCopy.startedLine(
          formatRupeesForSpeech(salary),
          formatRupeesForSpeech(fixed),
        );
      case MidMonthStartValues(:final moneyLeft):
        final stillToPay = values.fixedCostsTotal;
        sentence = StatementCopy.startedPartwayLine(
          formatRupees(moneyLeft),
          formatRupees(stillToPay),
        );
        speech = StatementCopy.startedPartwayLine(
          formatRupeesForSpeech(moneyLeft),
          formatRupeesForSpeech(stillToPay),
        );
    }
    final parts = sentence.split(', ');
    lead = [
      for (final (i, part) in parts.indexed)
        if (i < parts.length - 1) '$part,' else part,
    ];
    leadSpeech = _lowerFirst(speech);
  }

  final date = _spokenDate(change.date);
  final time = change.showTime ? ', ${formatClockTime(change.changedAt)}' : '';
  final String tail;
  final String tailSpeech;
  if (daily == null) {
    tail = StatementCopy.replacedSameDay;
    tailSpeech = 'replaced the same day';
  } else if (change.kind == StatementChangeKind.later) {
    tail = '→ ${StatementCopy.perDay(formatRupees(daily))}';
    tailSpeech =
        '${formatRupeesForSpeech(daily)} a day '
        '${StatementCopy.daysLeft(change.daysLeft)}';
  } else {
    tail = '→ ${StatementCopy.perDay(formatRupees(daily))}';
    tailSpeech = '${formatRupeesForSpeech(daily)} a day';
  }
  final tailChunks = [
    tail,
    if (daily != null && change.kind == StatementChangeKind.later)
      StatementCopy.daysLeft(change.daysLeft),
  ];
  return (
    chunks: [...lead, ...tailChunks],
    speech: '$date$time, $leadSpeech, $tailSpeech',
  );
}

String _lowerFirst(String text) =>
    '${text[0].toLowerCase()}${text.substring(1)}';

/// The working line of a period card (design §7) and its sentence
/// (`35,000 rupees minus 15,100 rupees fixed equals 19,900 rupees, minus ...`).
/// A spread period ends `→ ₹552/day`; a shortfall or zero period ends at the
/// amount, with the panel under it.
StatementLineText workingLineText(StatementWorking w) {
  final fixedWord = w.stillToPay ? 'still to pay' : 'fixed';
  final chunks = <String>[
    '${formatRupees(w.base)} − ${formatRupees(w.fixed)} $fixedWord',
  ];
  final speech = StringBuffer(
    '${_rupees(w.base)} minus ${_rupees(w.fixed)} $fixedWord',
  );
  final overDays = switch (w) {
    SpreadWorking() => ' over ${formatDayCount(w.spreadDays)}',
    ShortfallWorking() || ZeroWorking() => '',
  };
  if (w.alreadyBudgeted.isPositive) {
    chunks
      ..add('= ${formatRupees(w.spendable)},')
      ..add('minus ${formatRupees(w.alreadyBudgeted)} already budgeted');
    speech
      ..write(' equals ${_rupees(w.spendable)}, ')
      ..write('minus ${_rupees(w.alreadyBudgeted)} already budgeted');
  }
  chunks.add('= ${formatRupees(w.amountToSpread)}$overDays');
  speech.write(' equals ${_rupees(w.amountToSpread)}');
  if (w is SpreadWorking) {
    speech.write(
      ', over ${formatDayCount(w.spreadDays)}, ${_rupees(w.daily)} a day',
    );
    chunks.add('→ ${StatementCopy.perDay(formatRupees(w.daily))}');
  }
  return (chunks: chunks, speech: speech.toString());
}

/// The body of the (i) next to the daily budget (AC-13); null when there is
/// no daily budget (shortfall, zero).
String? dailyHelpText(StatementWorking w) {
  if (w is! SpreadWorking) return null;
  final amount = formatRupees(w.amountToSpread);
  final days = formatDayCount(w.spreadDays);
  return w.extraPaiseDays == 0
      ? StatementCopy.dailyEven(amount, days)
      : StatementCopy.dailyUneven(
          amount,
          days,
          w.extraPaiseDays,
          formatRupees(w.daily),
        );
}

/// The text of the shortfall or zero panel under a working line, or null.
({String text, String speech})? panelText(StatementWorking w) => switch (w) {
  SpreadWorking() => null,
  ShortfallWorking(:final underRupee) when underRupee => (
    text: StatementCopy.shortfallUnderRupee,
    speech: 'less than 1 rupee short, 0 rupees a day, continued anyway',
  ),
  ShortfallWorking(:final shortfall) => (
    text: StatementCopy.shortfall(formatRupees(shortfall)),
    speech: '${_rupees(shortfall)} short, 0 rupees a day, continued anyway',
  ),
  ZeroWorking() => (
    text: StatementCopy.zeroLeft,
    speech: '0 rupees left for daily spending, 0 rupees a day',
  ),
};
