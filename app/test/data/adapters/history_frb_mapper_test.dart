import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/adapters/history_frb_mapper.dart';
import 'package:hentai_library/domain/models/models.dart' as entity;
import 'package:hentai_library/src/rust/api/history.dart' as rust;
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

void main() {
  test('mapReadingHistoryDto maps Reading history fields and epoch ms', () {
    final rust.ReadingHistoryDto dto = rust.ReadingHistoryDto(
      comicId: 'c1',
      title: 'Title A',
      lastReadTimeMs: PlatformInt64Util.from(1_700_000_000_000),
      pageIndex: 3,
    );

    final entity.ReadingHistory mapped = mapReadingHistoryDto(dto);

    expect(mapped.comicId, 'c1');
    expect(mapped.title, 'Title A');
    expect(mapped.pageIndex, 3);
    expect(
      mapped.lastReadTime,
      DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000),
    );
  });

  test('mapReadingHistoryDto allows null pageIndex', () {
    final rust.ReadingHistoryDto dto = rust.ReadingHistoryDto(
      comicId: 'c2',
      title: 'Empty page',
      lastReadTimeMs: PlatformInt64Util.from(0),
    );

    expect(mapReadingHistoryDto(dto).pageIndex, isNull);
  });

  test('toReadingHistoryDto round-trips domain Reading history', () {
    final entity.ReadingHistory history = entity.ReadingHistory(
      comicId: 'c3',
      title: 'Round trip',
      lastReadTime: DateTime.fromMillisecondsSinceEpoch(42),
      pageIndex: 1,
    );

    final rust.ReadingHistoryDto dto = toReadingHistoryDto(history);
    final entity.ReadingHistory again = mapReadingHistoryDto(dto);

    expect(again.comicId, history.comicId);
    expect(again.title, history.title);
    expect(again.pageIndex, history.pageIndex);
    expect(again.lastReadTime, history.lastReadTime);
  });

  test('mapPagedReadingHistory uses caller page and pageSize', () {
    final rust.PagedReadingHistoryDto dto = rust.PagedReadingHistoryDto(
      items: <rust.ReadingHistoryDto>[
        rust.ReadingHistoryDto(
          comicId: 'c1',
          title: 'A',
          lastReadTimeMs: PlatformInt64Util.from(10),
        ),
      ],
      totalCount: PlatformInt64Util.from(9),
    );

    final result = mapPagedReadingHistory(dto, 2, 5);

    expect(result.items, hasLength(1));
    expect(result.items.single.comicId, 'c1');
    expect(result.totalCount, 9);
    expect(result.page, 2);
    expect(result.pageSize, 5);
  });
}
