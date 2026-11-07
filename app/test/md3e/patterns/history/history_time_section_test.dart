import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_time_grouping.dart';

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

  test('groupHistoryByTimeSection omits empty buckets and preserves order', () {
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
    );
    expect(groups.length, 4);
    expect(groups[0].section, HistoryTimeSection.today);
    expect(groups[1].section, HistoryTimeSection.yesterday);
    expect(groups[2].section, HistoryTimeSection.thisMonth);
    expect(groups[2].items.length, 2);
    expect(groups[3].section, HistoryTimeSection.earlier);
  });
}

class _Item {
  _Item(this.at);
  final DateTime at;
}
