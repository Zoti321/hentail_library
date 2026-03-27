import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/entity/v2/series_item.dart';

part 'library_series.freezed.dart';

/// v2：系列聚合（独立于 Comic，本质上维护归属与顺序）。
@freezed
abstract class LibrarySeries with _$LibrarySeries {
  factory LibrarySeries({
    required String seriesId,
    required String name,
    @Default(<SeriesItem>[]) List<SeriesItem> items,
  }) = _LibrarySeries;

  LibrarySeries._();

  bool containsComic(String comicId) => items.any((e) => e.comicId == comicId);

  /// 将漫画加入系列（若已存在则更新其顺序）。
  LibrarySeries upsertComic(String comicId, {required int order}) {
    final next = <SeriesItem>[
      for (final i in items)
        if (i.comicId != comicId) i,
      SeriesItem(comicId: comicId, order: order),
    ]..sort((a, b) => a.order.compareTo(b.order));
    return copyWith(items: next);
  }

  LibrarySeries removeComic(String comicId) {
    return copyWith(items: items.where((e) => e.comicId != comicId).toList());
  }
}

