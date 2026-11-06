import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_view_object.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/patterns/library/lab_catalog_item_preview.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

/// 由目录 index 生成 Lab 详情 preview（与 [LabCatalogItemPreview] 标题一致）。
abstract final class Md3eLabCatalogDetailPreviewData {
  static ComicDetailViewObject comicDetail({required int catalogIndex}) {
    final LabCatalogItemPreview item = LabCatalogItemPreview.forIndex(
      displayTarget: LibraryDisplayTarget.comics,
      index: catalogIndex,
    );
    final int pageCount = 64 + catalogIndex * 8;
    return ComicDetailViewObject(
      title: item.title,
      description: 'Lab 预览：${item.title}。简介由占位数据生成，用于验收目录 → 详情标题一致。',
      pageCount: pageCount,
      publishedLabel:
          '2020-${(catalogIndex % 12 + 1).toString().padLeft(2, '0')}-15',
      authors: <String>[item.listAuthor ?? '作者未知'],
      tags: <String>['Lab', '预览', '漫画'],
      resourceFormat: 'ZIP',
      resourceSizeLabel: '${12 + catalogIndex}.${catalogIndex % 10} MB',
      resourcePath: r'D:\library\lab\' + item.title,
      addedAtLabel: '2024-01-01 12:00',
      updatedAtLabel: '2026-03-01 09:00',
      showSeriesNav: catalogIndex.isEven,
      seriesCatalog: catalogIndex.isEven
          ? <String>['${item.title} 上', '${item.title} 下']
          : const <String>[],
      seriesCurrentIndex: 0,
    );
  }

  static SeriesDetailViewObject seriesDetail({required int catalogIndex}) {
    final LabCatalogItemPreview item = LabCatalogItemPreview.forIndex(
      displayTarget: LibraryDisplayTarget.series,
      index: catalogIndex,
    );
    final int comicCount = 3 + catalogIndex % 8;
    final List<SeriesDetailComicItem> comics =
        List<SeriesDetailComicItem>.generate(comicCount, (int i) {
          return SeriesDetailComicItem(
            title: '${item.title} · 第 ${i + 1} 册',
            pageCount: 160 + i * 12,
            readProgress: i.isEven ? (i % 10) / 10 : null,
          );
        });

    return SeriesDetailViewObject(
      title: item.title,
      serializationStatus: SeriesSerializationStatus.ongoing,
      languages: const <String>['日文'],
      showAgeRestrictionChip: catalogIndex.isOdd,
      volumeCurrent: comics.length,
      volumeTotal: comics.length + 2,
      authors: <String>['Lab 作者 ${catalogIndex % 4 + 1}'],
      tags: <String>['系列', 'Lab', item.subtitle],
      comics: comics,
    );
  }

  static ComicDetailViewObject comicDetailFromSeriesVolume({
    required SeriesDetailViewObject series,
    required int comicIndex,
  }) {
    if (comicIndex < 0 || comicIndex >= series.comics.length) {
      return comicDetail(catalogIndex: 0);
    }
    final SeriesDetailComicItem volume = series.comics[comicIndex];
    return ComicDetailViewObject(
      title: volume.title,
      description: 'Lab 预览：从系列「${series.title}」进入的单册详情。',
      pageCount: volume.pageCount,
      authors: series.authors,
      tags: series.tags,
      showSeriesNav: true,
      seriesCatalog: series.comics
          .map((SeriesDetailComicItem c) => c.title)
          .toList(),
      seriesCurrentIndex: comicIndex,
    );
  }
}
