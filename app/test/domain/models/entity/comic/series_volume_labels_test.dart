import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:test/test.dart';

Series _series({
  int itemCount = 3,
  int? totalCount,
}) {
  return Series(
    id: 'series-1',
    name: 'Test Series',
    folderPath: '/series',
    totalCount: totalCount,
    items: List<SeriesItem>.generate(
      itemCount,
      (int index) => SeriesItem(
        comicId: 'comic-$index',
        order: index,
      ),
    ),
  );
}

void main() {
  group('Series volume labels', () {
    test('volumeCountLabel always shows actual count only', () {
      expect(_series(totalCount: null).volumeCountLabel, '3 本书');
      expect(_series(totalCount: 12).volumeCountLabel, '3 本书');
      expect(_series(itemCount: 12, totalCount: 10).volumeCountLabel, '12 本书');
    });

    test('volumeProgressLabel is null without planned total', () {
      expect(_series(totalCount: null).volumeProgressLabel, isNull);
      expect(_series(totalCount: 0).volumeProgressLabel, isNull);
    });

    test('volumeProgressLabel shows progress when planned total exists', () {
      expect(
        _series(itemCount: 3, totalCount: 12).volumeProgressLabel,
        '3 / 共 12 本书',
      );
      expect(
        _series(itemCount: 12, totalCount: 10).volumeProgressLabel,
        '12 / 共 10 本书',
      );
    });
  });
}
