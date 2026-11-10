import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';

/// Widgetbook / 预览用示例系列详情。
abstract final class SeriesDetailPagePreviewData {
  static SeriesDetailViewObject sample() {
    final List<SeriesDetailComicItem> comics =
        List<SeriesDetailComicItem>.generate(24, (int index) {
          final int volume = index + 1;
          return SeriesDetailComicItem(
            title: '葬送的芙莉莲 第 $volume 卷',
            pageCount: 180 + index * 4,
            readProgress: index.isEven ? (index % 10) / 10 : null,
          );
        });

    return SeriesDetailViewObject(
      title: '葬送的芙莉莲',
      serializationStatus: SeriesSerializationStatus.ongoing,
      languages: const <String>['日文'],
      showAgeRestrictionChip: true,
      volumeCurrent: comics.length,
      volumeTotal: 28,
      parodies: const <String>['迷宫饭'],
      authors: const <AuthorRef>[
        AuthorRef(id: 201, name: '山田钟人'),
        AuthorRef(id: 202, name: 'アベツカサ'),
      ],
      characters: const <String>['芙莉莲', '费伦', '修塔尔克'],
      tags: const <String>['奇幻', '冒险', '长篇', '连载中'],
      comics: comics,
      initialPage: 1,
      initialPageSize: 20,
    );
  }
}
