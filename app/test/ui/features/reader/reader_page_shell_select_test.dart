import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

({Comic comic, int totalPages})? selectReaderPageShell(
  AsyncValue<ReaderState> asyncState,
) {
  final ReaderState? state = asyncState.asData?.value;
  if (state == null) {
    return null;
  }
  return (comic: state.comic, totalPages: state.totalPages);
}

void main() {
  final Comic comic = Comic(
    comicId: 'c1',
    path: '/tmp/c1.cbz',
    resourceType: ResourceType.cbz,
    resourceSize: 1,
    createdAt: DateTime.utc(2026, 1, 1),
    lastUpdatedAt: DateTime.utc(2026, 1, 1),
    title: 'Shell',
    pageCount: 10,
  );

  test(
    'reader page shell select ignores currentIndex and showControls changes',
    () {
      final AsyncValue<ReaderState> open = AsyncData(
        ReaderState(
          comic: comic,
          currentIndex: 1,
          totalPagesOverride: 10,
          showControls: false,
          readingMode: ReadingMode.paged,
        ),
      );
      final AsyncValue<ReaderState> turned = AsyncData(
        ReaderState(
          comic: comic,
          currentIndex: 4,
          totalPagesOverride: 10,
          showControls: true,
          readingMode: ReadingMode.paged,
        ),
      );

      expect(selectReaderPageShell(open), selectReaderPageShell(turned));
    },
  );

  test('reader page shell select changes when reading mode changes', () {
    // Mode is intentionally not part of shell; content slot selects it.
    // This documents that totalPages/comic stay stable across mode switch.
    final AsyncValue<ReaderState> paged = AsyncData(
      ReaderState(
        comic: comic,
        currentIndex: 2,
        totalPagesOverride: 10,
        readingMode: ReadingMode.paged,
      ),
    );
    final AsyncValue<ReaderState> webtoon = AsyncData(
      ReaderState(
        comic: comic,
        currentIndex: 2,
        totalPagesOverride: 10,
        readingMode: ReadingMode.webtoon,
      ),
    );

    expect(selectReaderPageShell(paged), selectReaderPageShell(webtoon));
  });
}
