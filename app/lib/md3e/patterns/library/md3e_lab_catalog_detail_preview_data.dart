import 'package:hentai_library/md3e/pages/md3e_comic_detail_entry.dart';
import 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_lab_catalog_item_preview.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

/// 由目录 index 生成 Lab 详情 preview（与 [Md3eLabCatalogItemPreview] 标题一致）。
abstract final class Md3eLabCatalogDetailPreviewData {
  static Md3eComicDetailEntry comicDetail({
    required int catalogIndex,
  }) {
    final Md3eLabCatalogItemPreview item = Md3eLabCatalogItemPreview.forIndex(
      displayTarget: LibraryDisplayTarget.comics,
      index: catalogIndex,
    );
    final int pageCount = 64 + catalogIndex * 8;
    return Md3eComicDetailEntry(
      title: item.title,
      description:
          'Lab 预览：${item.title}。简介由占位数据生成，用于验收目录 → 详情标题一致。',
      pageCount: pageCount,
      publishedLabel: '2020-${(catalogIndex % 12 + 1).toString().padLeft(2, '0')}-15',
      authors: <String>[item.listAuthor ?? '作者未知'],
      tags: <String>['Lab', '预览', '漫画'],
      resourceFormat: 'ZIP',
      resourceSizeLabel: '${12 + catalogIndex}.${catalogIndex % 10} MB',
      resourcePath: r'D:\library\lab\' + item.title,
      addedAtLabel: '2024-01-01 12:00',
      updatedAtLabel: '2026-03-01 09:00',
      showSeriesNav: catalogIndex.isEven,
      seriesCatalog: catalogIndex.isEven
          ? <String>[
              '${item.title} 上',
              '${item.title} 下',
            ]
          : const <String>[],
      seriesCurrentIndex: 0,
    );
  }

  static Md3eSeriesDetailEntry seriesDetail({
    required int catalogIndex,
  }) {
    final Md3eLabCatalogItemPreview item = Md3eLabCatalogItemPreview.forIndex(
      displayTarget: LibraryDisplayTarget.series,
      index: catalogIndex,
    );
    final int comicCount = 3 + catalogIndex % 8;
    final List<Md3eSeriesDetailComicItem> comics =
        List<Md3eSeriesDetailComicItem>.generate(comicCount, (int i) {
          return Md3eSeriesDetailComicItem(
            title: '${item.title} · 第 ${i + 1} 册',
            pageCount: 160 + i * 12,
            readProgress: i.isEven ? (i % 10) / 10 : null,
          );
        });

    return Md3eSeriesDetailEntry(
      title: item.title,
      serializationStatus: Md3eSeriesSerializationStatus.ongoing,
      languages: const <String>['日文'],
      showAgeRestrictionChip: catalogIndex.isOdd,
      volumeCurrent: comics.length,
      volumeTotal: comics.length + 2,
      authors: <String>['Lab 作者 ${catalogIndex % 4 + 1}'],
      tags: <String>['系列', 'Lab', item.subtitle],
      comics: comics,
    );
  }

  static Md3eComicDetailEntry comicDetailFromSeriesVolume({
    required Md3eSeriesDetailEntry series,
    required int comicIndex,
  }) {
    if (comicIndex < 0 || comicIndex >= series.comics.length) {
      return comicDetail(catalogIndex: 0);
    }
    final Md3eSeriesDetailComicItem volume = series.comics[comicIndex];
    return Md3eComicDetailEntry(
      title: volume.title,
      description: 'Lab 预览：从系列「${series.title}」进入的单册详情。',
      pageCount: volume.pageCount,
      authors: series.authors,
      tags: series.tags,
      showSeriesNav: true,
      seriesCatalog: series.comics.map((Md3eSeriesDetailComicItem c) => c.title).toList(),
      seriesCurrentIndex: comicIndex,
    );
  }
}
