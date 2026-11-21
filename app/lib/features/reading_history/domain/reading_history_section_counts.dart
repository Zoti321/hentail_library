/// Server-side counts for the five reading-history time sections.
class ReadingHistorySectionCounts {
  const ReadingHistorySectionCounts({
    required this.today,
    required this.yesterday,
    required this.thisWeek,
    required this.thisMonth,
    required this.earlier,
  });

  static const ReadingHistorySectionCounts zero = ReadingHistorySectionCounts(
    today: 0,
    yesterday: 0,
    thisWeek: 0,
    thisMonth: 0,
    earlier: 0,
  );

  final int today;
  final int yesterday;
  final int thisWeek;
  final int thisMonth;
  final int earlier;

  int get total => today + yesterday + thisWeek + thisMonth + earlier;

  ReadingHistorySectionCounts copyWith({
    int? today,
    int? yesterday,
    int? thisWeek,
    int? thisMonth,
    int? earlier,
  }) {
    return ReadingHistorySectionCounts(
      today: today ?? this.today,
      yesterday: yesterday ?? this.yesterday,
      thisWeek: thisWeek ?? this.thisWeek,
      thisMonth: thisMonth ?? this.thisMonth,
      earlier: earlier ?? this.earlier,
    );
  }
}
