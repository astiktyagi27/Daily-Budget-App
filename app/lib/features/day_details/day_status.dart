import 'package:daily_budget/core/copy/day_details_copy.dart';
import 'package:daily_budget/core/format/money_format.dart';
import 'package:daily_budget/core/theme/budget_colors.dart';
import 'package:daily_budget/domain/budget/budget.dart';
import 'package:flutter/painting.dart';

/// How a day's status is written (F-012 §2.1, design §3): a mark, the words
/// and the colour token that carries the meaning (never by colour alone).
class DayStatusText {
  const new({
    required this.mark,
    required this.words,
    required this.speech,
    required this.tone,
  });

  /// `●`, `○`, `◆`, or null for `Upcoming` (no mark).
  final String? mark;

  /// `Overspent ₹300`, `Today · ₹410 left`.
  final String words;

  /// What a screen reader says after the date, without the mark:
  /// `overspent ₹300`, `₹410 left`.
  final String speech;

  final DayTone tone;

  /// The words without the `Today · ` lead, for the Day result row
  /// (`₹410 left`).
  String get resultWords =>
      words.startsWith('Today · ') ? words.substring('Today · '.length) : words;
}

/// Which colour token a status uses.
enum DayTone {
  saved,
  onBudget,
  overspent,
  plain;

  Color color(BudgetColors colors) => switch (this) {
    saved => colors.saved,
    onBudget => colors.neutral,
    overspent => colors.overspent,
    plain => colors.textSecondary,
  };
}

/// The status of [day] as the header and the Day result row show it. A
/// not-budgeted day has no status (the screen shows only its note).
DayStatusText dayStatusOf(DaySummary day) {
  final kind = day.resultKind;
  if (kind == null) {
    return const DayStatusText(
      mark: null,
      words: DayDetailsCopy.upcoming,
      speech: 'upcoming',
      tone: DayTone.plain,
    );
  }
  final result = day.result!;
  final shown = formatRupees(result.isNegative ? -result : result);
  final spoken = formatRupeesForSpeech(result.isNegative ? -result : result);
  final live = day.isLive;
  final (mark, tone) = switch (kind) {
    DayResultKind.saved ||
    DayResultKind.savedUnderRupee => ('●', DayTone.saved),
    DayResultKind.onBudget => ('○', DayTone.onBudget),
    DayResultKind.overspent ||
    DayResultKind.overspentUnderRupee => ('◆', DayTone.overspent),
  };
  final (words, speech) = switch ((kind, live)) {
    (DayResultKind.saved, false) => (
      DayDetailsCopy.saved(shown),
      'saved $spoken',
    ),
    (DayResultKind.savedUnderRupee, false) => (
      DayDetailsCopy.savedLessThanRupee,
      'saved less than ₹1',
    ),
    (DayResultKind.onBudget, false) => (DayDetailsCopy.onBudget, 'on budget'),
    (DayResultKind.overspent, false) => (
      DayDetailsCopy.overspent(shown),
      'overspent $spoken',
    ),
    (DayResultKind.overspentUnderRupee, false) => (
      DayDetailsCopy.overspentLessThanRupee,
      'overspent less than ₹1',
    ),
    (DayResultKind.saved, true) => (
      DayDetailsCopy.today(DayDetailsCopy.left(shown)),
      '$spoken left',
    ),
    (DayResultKind.savedUnderRupee, true) => (
      DayDetailsCopy.today(DayDetailsCopy.leftLessThanRupee),
      'less than ₹1 left',
    ),
    (DayResultKind.onBudget, true) => (
      DayDetailsCopy.today(DayDetailsCopy.todayOnBudget),
      'on budget',
    ),
    (DayResultKind.overspent, true) => (
      DayDetailsCopy.today(DayDetailsCopy.todayOverspent(shown)),
      'overspent $spoken',
    ),
    (DayResultKind.overspentUnderRupee, true) => (
      DayDetailsCopy.today(DayDetailsCopy.todayOverspentLessThanRupee),
      'overspent less than ₹1',
    ),
  };
  return DayStatusText(mark: mark, words: words, speech: speech, tone: tone);
}
