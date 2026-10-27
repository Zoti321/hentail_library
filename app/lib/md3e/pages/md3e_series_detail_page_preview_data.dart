import 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';

/// Widgetbook / 预览用示例系列详情。
abstract final class Md3eSeriesDetailPagePreviewData {
  static Md3eSeriesDetailEntry sample() {
    final List<Md3eSeriesDetailComicItem> comics = List<Md3eSeriesDetailComicItem>.generate(
      24,
      (int index) {
        final int volume = index + 1;
        return Md3eSeriesDetailComicItem(
          title: '葬送的芙莉莲 第 $volume 卷',
          pageCount: 180 + index * 4,
          readProgress: index.isEven ? (index % 10) / 10 : null,
        );
      },
    );

    return Md3eSeriesDetailEntry(
      title: '葬送的芙莉莲',
      serializationStatus: Md3eSeriesSerializationStatus.ongoing,
      languages: const <String>['中文', '日文'],
      showAgeRestrictionChip: true,
      volumeCurrent: comics.length,
      volumeTotal: 28,
      parodies: const <String>['迷宫饭'],
      authors: const <String>['山田钟人', 'アベツカサ'],
      characters: const <String>['芙莉莲', '费伦', '修塔尔克'],
      tags: const <String>['奇幻', '冒险', '长篇', '连载中'],
      comics: comics,
      initialPage: 1,
      initialPageSize: 20,
    );
  }
}
