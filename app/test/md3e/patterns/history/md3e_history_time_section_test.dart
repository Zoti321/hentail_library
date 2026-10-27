import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/patterns/history/md3e_history_time_section.dart';

void main() {
  final DateTime clock = DateTime(2026, 3, 11, 15); // Wednesday

  test('md3eHistoryTimeSectionFor maps four buckets', () {
    expect(
      md3eHistoryTimeSectionFor(
        DateTime(2026, 3, 11, 9),
        clock,
      ),
      Md3eHistoryTimeSection.today,
    );
    expect(
      md3eHistoryTimeSectionFor(
        DateTime(2026, 3, 10, 20),
        clock,
      ),
      Md3eHistoryTimeSection.yesterday,
    );
    expect(
      md3eHistoryTimeSectionFor(
        DateTime(2026, 3, 9, 12),
        clock,
      ),
      Md3eHistoryTimeSection.thisWeek,
    );
    expect(
      md3eHistoryTimeSectionFor(
        DateTime(2026, 2, 20),
        clock,
      ),
      Md3eHistoryTimeSection.earlier,
    );
  });

  test('groupHistoryByTimeSection omits empty buckets and preserves order', () {
    final List<_Item> items = <_Item>[
      _Item(DateTime(2026, 3, 11)),
      _Item(DateTime(2026, 3, 10)),
      _Item(DateTime(2026, 3, 1)),
    ];
    final List<Md3eHistoryTimeGroup<_Item>> groups = groupHistoryByTimeSection(
      items,
      ( _Item i) => i.at,
      clock: clock,
    );
    expect(groups.length, 3);
    expect(groups[0].section, Md3eHistoryTimeSection.today);
    expect(groups[1].section, Md3eHistoryTimeSection.yesterday);
    expect(groups[2].section, Md3eHistoryTimeSection.earlier);
  });
}

class _Item {
  _Item(this.at);
  final DateTime at;
}
