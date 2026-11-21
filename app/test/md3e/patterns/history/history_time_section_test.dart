import 'package:hentai_library/features/reading_history/domain/reading_history_section_counts.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_time_grouping.dart';
import 'package:test/test.dart';

void main() {
  final DateTime clock = DateTime(2026, 3, 11, 15); // Wednesday

  test('historyTimeSectionFor maps five buckets', () {
    expect(
      historyTimeSectionFor(DateTime(2026, 3, 11, 9), clock),
      HistoryTimeSection.today,
    );
    expect(
      historyTimeSectionFor(DateTime(2026, 3, 10, 20), clock),
      HistoryTimeSection.yesterday,
    );
    expect(
      historyTimeSectionFor(DateTime(2026, 3, 9, 12), clock),
      HistoryTimeSection.thisWeek,
    );
    expect(
      historyTimeSectionFor(DateTime(2026, 3, 5, 12), clock),
      HistoryTimeSection.thisMonth,
    );
    expect(
      historyTimeSectionFor(DateTime(2026, 2, 20), clock),
      HistoryTimeSection.earlier,
    );
  });

  test('groupHistoryByTimeSection keeps five buckets including empty', () {
    final List<_Item> items = <_Item>[
      _Item(DateTime(2026, 3, 11)),
      _Item(DateTime(2026, 3, 10)),
      _Item(DateTime(2026, 3, 5)),
      _Item(DateTime(2026, 3, 1)),
      _Item(DateTime(2025, 12, 1)),
    ];
    final List<HistoryTimeGroup<_Item>> groups = groupHistoryByTimeSection(
      items,
      (_Item i) => i.at,
      clock: clock,
      sectionCounts: const ReadingHistorySectionCounts(
        today: 10,
        yesterday: 2,
        thisWeek: 0,
        thisMonth: 4,
        earlier: 1,
      ),
    );
    expect(groups.length, 5);
    expect(groups[0].section, HistoryTimeSection.today);
    expect(groups[0].totalCount, 10);
    expect(groups[0].items.length, 1);
    expect(groups[1].section, HistoryTimeSection.yesterday);
    expect(groups[2].section, HistoryTimeSection.thisWeek);
    expect(groups[2].items, isEmpty);
    expect(groups[2].totalCount, 0);
    expect(groups[3].section, HistoryTimeSection.thisMonth);
    expect(groups[3].items.length, 2);
    expect(groups[3].totalCount, 4);
    expect(groups[4].section, HistoryTimeSection.earlier);
  });
}

class _Item {
  _Item(this.at);
  final DateTime at;
}
