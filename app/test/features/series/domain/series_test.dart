import 'package:test/test.dart';
import 'package:hentai_library/features/series/domain/series.dart';
import 'package:hentai_library/features/series/domain/series_item.dart';
import 'package:hentai_library/features/series/domain/value_objects/series_folder_info.dart';
import 'package:hentai_library/features/series/domain/value_objects/series_metadata.dart';
import 'package:hentai_library/features/series/domain/value_objects/series_meta_locks.dart';

void main() {
  test(
    'Series metadata edits preserve its folder, identity and member order',
    () {
      final series = Series(
        id: 'series-1',
        folderInfo: const SeriesFolderInfo(folderPath: '/library/series'),
        metadata: const SeriesMetadata(
          name: 'Original',
          totalCount: 12,
          locks: SeriesMetaLocks(name: true),
        ),
        items: [
          SeriesItem(comicId: 'comic-1', order: 2.5, sortOrderLocked: true),
        ],
      );

      final edited = series.copyWith(
        metadata: series.metadata.copyWith(name: 'Edited', totalCount: null),
      );

      expect(edited.id, 'series-1');
      expect(edited.folderInfo, series.folderInfo);
      expect(edited.name, 'Edited');
      expect(edited.totalCount, isNull);
      expect(edited.locks.name, isTrue);
      expect(edited.items.single.comicId, 'comic-1');
      expect(edited.items.single.order, 2.5);
      expect(edited.items.single.sortOrderLocked, isTrue);
      expect(series.name, 'Original');
      expect(series.totalCount, 12);
    },
  );

  test(
    'Series folder replacement preserves metadata and immutable membership',
    () {
      final series = Series(
        id: 'series-1',
        folderInfo: const SeriesFolderInfo(folderPath: '/library/original'),
        metadata: const SeriesMetadata(
          name: 'Original',
          totalCount: 12,
          locks: SeriesMetaLocks(totalCount: true),
        ),
        items: [SeriesItem(comicId: 'comic-1', order: 4)],
      );

      final moved = series.copyWith(
        folderInfo: const SeriesFolderInfo(folderPath: '/library/replacement'),
      );

      expect(moved.id, 'series-1');
      expect(moved.folderPath, '/library/replacement');
      expect(moved.metadata, series.metadata);
      expect(
        moved.metadata,
        const SeriesMetadata(
          name: 'Original',
          totalCount: 12,
          locks: SeriesMetaLocks(totalCount: true),
        ),
      );
      expect(moved.items.single.order, 4);
      expect(() => moved.items.clear(), throwsUnsupportedError);
      expect(series.folderPath, '/library/original');
    },
  );
}
